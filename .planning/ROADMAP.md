# Roadmap: GUImorphWeb — Browser Rendering

## Overview

This milestone builds GUImorphWeb's browser rendering and interaction layer on top
of GUImorph's existing R analytical layer and `.dgt` format. R keeps file I/O,
downsampling, template warping, GPA, and export. The browser takes mesh display,
orbit, picking, and overlays. A local `httpuv` server serves mesh bytes over
loopback, a bundled three.js htmlwidget renders them, and `three-mesh-bvh`
accelerates raycast picking. Nothing is fetched at runtime, so the package works
offline and still runs entirely from an R session.

The sequencing is front-loaded with low-risk, independently shippable work.
Phases 1 through 3 touch no acquisition data and each fix something real on
current macOS. Phase 4 is the technical gate: browser picking must agree with the
native engine's `gluUnProject` within tolerance. If that gate fails, the milestone
stops there having still delivered result plots, mesh display, and packaging, and
the loss is three phases rather than six.

The native `tkogl2` engine is inherited and retained through Phase 5, not because
it is being maintained, but because it is the only trustworthy source of reference
coordinates for the Phase 4 gate. It is deleted at Phase 6.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Result Plots + rgl Demotion** - Vendor three.js, move the two 3D result plots to a widget, and make `rgl` optional so the package loads where rgl cannot
- [ ] **Phase 2: Transport and Mesh Display** - `httpuv` serves the PLY over loopback; three.js renders and orbits it
- [ ] **Phase 3: Offline Packaging and Lifecycle** - Bundle the JS, select a port, launch the browser, tear down on session end
- [ ] **Phase 4: Picking Parity** - BVH raycast returns hit coordinates matching the native `gluUnProject` result within tolerance
- [ ] **Phase 5: Full Digitizing and Data Parity** - Curves, anchors, surfaces, undo, multi-specimen, GPA and export from the browser, with byte-identical `.dgt`
- [ ] **Phase 6: Shell and Native Retirement** - Replace the Tk chrome, then delete `tkogl2` and drop `rgl`

## Phase Details

### Phase 1: Result Plots + rgl Demotion

**Goal**: Render the two 3D result plots through a bundled three.js htmlwidget, and
make `rgl` an optional dependency so the package loads and runs on a host where
rgl itself cannot load.
**Depends on**: Nothing (first phase)
**Requirements**: WEB-00, PLT-01, PLT-02, PLT-03, CMP-01
**Success Criteria** (what must be TRUE):

  1. three.js and `three-mesh-bvh` are vendored into `inst/htmlwidgets/` with
     licences, and a minimal widget wrapper (scene, camera, orbit, resize, reset)
     renders from R with no network access (WEB-00).
  1b. `plotspecs` (aligned specimens) and `plotMeanShape` render through that
     wrapper as point clouds, with orbit, zoom, and reset view. Read-only.
  2. `library(GUImorphWeb)` succeeds and the full digitizing workflow runs on a
     host where `library(rgl)` fails. Morpho is removed (it hard-imports rgl and
     was used for one function, now reimplemented over Rvcg); `rgl` and
     `htmlwidgets` move to `Suggests` with all call sites guarded; the unused
     `vegan` and `parallel` imports are dropped.
  3. `plotPCA` continues to work without a native device and stays base-graphics
     2D. The single-component ordination crash was fixed in 0.10.0 (`a8a6cf0`)
     and must not regress.
  4. Visual parity: the three.js aligned-specimen and mean-shape output is
     comparable to the inherited rgl output on the same GPA result.
  5. Native oracle still loads (CMP-01): the retained `tkogl2` engine still builds
     and renders on Windows.

**Plans**: TBD

**Note (scope)**: Only two result plots are rgl. `plotPCA` is base graphics
rendered through `.plot_show()`, and the inherited test suite asserts it makes no
`rgl::` calls. Converting it to three.js would break that assertion and apply a
3D renderer to a 2D scatter.

**Note (the real unblock)**: The inherited macOS fallback routes 3D plots through
`rgl.useNULL = TRUE` plus `rglwidget()`. That design works. The breakage sits
upstream of it: on current macOS `rgl` fails to load at all, and because it is in
`Imports`, package load fails before any fallback can run. PLT-02 is the
requirement that actually unblocks those machines, and it is worth shipping even
if PLT-01 slips.

**Note (context bug class)**: GUImorph carries a fix (`129b42a`) that rebinds the
GL context per frame, because rgl and the native engine share a context on the R
main thread and any rgl plot silently unbound the engine's, producing a black
canvas and total pick failure. Moving result plots off rgl removes the cause. Keep
the per-frame rebind in the retained engine anyway, since the engine is the Phase
4 oracle and must stay trustworthy.

**Note (scope grew after research)**: PLT-02 was written as an rgl demotion. The
dependency survey found Morpho was the actual blocker. `fastKmeans` is
reimplemented in `R/template_kmeans.R` over Rvcg, verified at exact numerical
parity against Morpho at k = 500/1000/2000 with a median 1.4x speedup. Full
evidence in `01-RESEARCH.md`.

**Note (behaviour change deliberately excluded)**: all three template call sites
pass `iter.max = 100`, which research showed is too low to converge at low slider
counts. Raising it changes existing template output, so it is tracked separately
rather than folded into a dependency change.

**Note (vendoring moved here)**: WEB-03 originally owned "vendor three.js
offline." Phase 1 is the first phase that needs it, so it moved here as WEB-00
and Phase 3 keeps only the clean-install and offline verification. The wrapper
built here is reused by WEB-02 (mesh display) and PICK-01 (raycast), so this is
the first increment of Phase 2 rather than a detour before it.

**Note (sequencing, considered and rejected)**: deferring PLT-01 until after the
Phase 4 gate was considered, on the grounds that it is user value rather than
risk reduction. Rejected for two reasons. It shares nearly all its machinery with
WEB-02, differing only in that point clouds need no HTTP transport, so doing it
first builds toward Phase 2 instead of competing with it. And it is the value
that survives if the gate fails: after PLT-02, a machine where rgl cannot load
can digitize but cannot draw 3-D result plots at all, and PLT-01 is what restores
them.

**Why first**: touches zero acquisition data, cannot corrupt a session, fixes a
live load failure, and teaches the stack where mistakes are cheap.

### Phase 2: Transport and Mesh Display

**Goal**: Serve a PLY specimen from R over a local HTTP server and render it in the
browser with orbit, zoom, and reset. No overlays, no picking.
**Depends on**: Phase 1
**Requirements**: WEB-01, WEB-02, CMP-01
**Success Criteria** (what must be TRUE):

  1. An `httpuv` server started from R binds to loopback only, on an unprivileged
     port, and serves the PLY file as bytes over HTTP. The mesh is never
     JSON-encoded.
  2. The served endpoint is guarded by a per-session random path or token, so
     another process on the same host cannot enumerate and read specimen files.
  3. three.js `PLYLoader` fetches and renders the mesh, with orbit, zoom, and
     reset view.
  4. The 6-specimen reference set loads and orbits on stock macOS and stock
     Windows, with no XQuartz, no Homebrew, and no Tcl/Tk in the render path.
  5. Native oracle still loads (CMP-01).

**Plans**: TBD

**Note (risk: mesh size)**: NextEngine scans are large. Serve the file over HTTP
and let the loader stream it. Do not marshal vertices through R-to-JS JSON. If
transfer time is unacceptable on the reference set, evaluate binary PLY fast-path
or Draco before adding complexity elsewhere.

**Note (PLY hygiene)**: NextEngine exports carry unreferenced stray vertices,
including origin-null points at (0,0,0). These already corrupt GPA when captured
as k-means template points. Confirm the browser loader does not silently
reintroduce them into the bounding box or camera framing.

### Phase 3: Offline Packaging and Lifecycle

**Goal**: Ship the JS inside the package and make server launch, browser open, and
teardown reliable on a locked-down machine.
**Depends on**: Phase 2
**Requirements**: WEB-03, WEB-04, CMP-01
**Success Criteria** (what must be TRUE):

  1. A clean `install.packages()` on a fresh R opens a working viewport with the
     machine fully offline, on both Windows and macOS. (The vendoring itself
     landed in Phase 1 as WEB-00.)
  3. Port selection survives a port already in use, and the failure mode is a
     clear R-level error rather than a silent hang.
  4. The server is torn down on viewport close, on session exit, and on R session
     end. No orphaned listener survives.
  5. The launch path degrades legibly when the default browser is missing,
     misconfigured, or blocked, and when a host firewall prompts on first bind.
  6. Native oracle still loads (CMP-01).

**Plans**: TBD

**Note (deployment reality)**: Target users are archaeology and forensics labs,
often on managed machines. A clean `install.packages()` is not the bar. Criteria 3
through 5 exist because firewall prompts, locked default browsers, and proxy
configuration are the realistic failure modes, and each presents to the user as
"the software is broken."

**Note (WebGPU)**: WebGL stays the baseline target. WebGPU is opportunistic only,
through three.js's automatic fallback. Do not make it a dependency here.

### Phase 4: Picking Parity

**Goal**: Return mesh hit coordinates from a browser raycast that agree with the
native engine's unproject result, and render placed landmarks as overlay geometry.
**Depends on**: Phase 3
**Requirements**: PICK-01, PICK-02, PICK-03, CMP-01
**Success Criteria** (what must be TRUE):

  1. A BVH-accelerated raycast against the loaded mesh returns a hit coordinate
     to R, at interactive rates on the reference specimens.
  2. Placement only: a landmark dot renders as overlay geometry at the returned
     coordinate, with correct depth behavior under rotation.
  3. **The gate.** On the same specimen at the same click position, the browser
     coordinate matches the native engine's `gluUnProject` result within a
     documented numeric tolerance, stated in mesh units and justified against
     inter-observer digitizing error.
  4. Parity holds on a HiDPI display with no backing-scale correction, since
     raycasting is resolution-independent.
  5. Native oracle still loads (CMP-01). This is the phase where that matters
     most.

**Plans**: TBD

**Note (this is the decision point)**: If criterion 3 cannot be met, stop here.
Phases 1 through 3 remain shipped and valuable, GUImorph remains the digitizing
path, and the loss is bounded at three phases.

**Note (expected cost)**: The predictable difficulty is coordinate-space
convention between the native engine's model transform and three.js's. Budget time
for sign and axis-order debugging. Build a fixture of known click positions with
recorded native results *before* writing the comparison, not after.

**Note (oracle validity)**: GUImorph's native path was validated on Windows
2026-07-18 (full workflow, 6-specimen `.dgt` round-trip, 212 live picks, 0
failed). Record the exact engine commit used to generate reference coordinates in
the fixture, so a later change cannot silently invalidate the comparison.

### Phase 5: Full Digitizing and Data Parity

**Goal**: Complete the acquisition workflow in the browser and prove the output
bytes are identical to the native path.
**Depends on**: Phase 4
**Requirements**: DGT-01, DGT-02, DGT-03, DAT-01, DAT-02, CMP-01
**Success Criteria** (what must be TRUE):

  1. Curve definition works with the existing three-click selection and the
     cyan/red/blue visual feedback, and anchors can be placed (DGT-01).
  2. Surface semilandmark display, delete, undo, and multi-specimen switching all
     work in the browser (DGT-02).
  3. GPA (`geomorph::gpagen`) and `.csv`/`.rds` export are driven from the browser
     UI and produce results identical to the native path on the same input
     (DGT-03).
  4. A `.dgt` written through the browser path is byte-identical to one written
     through the native path from the same session (DAT-01).
  5. A GUImorph-authored `.dgt` opens correctly here, and a GUImorphWeb-authored
     `.dgt` opens correctly in GUImorph, verified against
     `tests/fixtures/parity/` (DAT-02).
  6. Full workflow end to end: PLY load, landmarks, curves, surfaces, GPA, export.
  7. Native oracle still loads (CMP-01). Retired after this phase.

**Plans**: TBD

**Note (external dependency)**: Criterion 5 is only as strong as GUImorph's own
cross-platform `.dgt` parity, which is closed Windows to macOS but not macOS to
Windows. Track that, do not own it. If it is still open when this phase lands,
state the limitation rather than claiming a contract that is half-proven.

**Note (surface flattening)**: Flattening surface semilandmarks for display
requires `as.vector(t(surfaces[,,id]))`. Omitting the transpose scrambles point
order. Cover it with a regression test rather than with care.

### Phase 6: Shell and Native Retirement

**Goal**: Replace the Tk chrome, then remove the native engine and its entire build
surface.
**Depends on**: Phase 5
**Requirements**: UI-01, UI-02, UI-03
**Success Criteria** (what must be TRUE):

  1. Tabs, dialogs, specimen navigation, and the status bar are reimplemented in
     the browser shell, at feature parity with the Tk chrome (UI-01).
  2. The complete workflow runs with the native engine uninstalled and absent from
     the library path (UI-02).
  3. `tkogl2` is deleted from the package and `rgl` is removed from dependencies
     entirely (UI-03). CMP-01 is retired here, deliberately.
  4. A migration note ships in `NEWS.md` for users on the native path, with a
     documented version to pin if they need to stay.

**Plans**: TBD

**Note (do not skip criterion 4)**: A third party already installed the GUImorph
Windows binary successfully. Anyone mid-project needs a pinnable version and a
stated path forward before the native engine disappears.

## What Disappears at Phase 6

The tri-platform CMake, MSVC and Rtools, the WGL and NSGL backends, the
`gfx_backend.h` seam, Tcl/Tk version and Aqua/X11 matching, XQuartz, deployment
targets, universal2, notarization, Gatekeeper, the DLL and dylib
commit-and-deploy dance, and the class of defect where the build tree and the
deployed binary disagree.

## What Survives Untouched

Every R analytical path, the `.dgt` format, the parity suite and its fixtures, the
`geomorph` integration and `exportGeomorph()`, and the accumulated lessons from
the three engine defect classes, even though the code carrying them goes.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Result Plots + rgl Demotion | 0/TBD | Not started | - |
| 2. Transport and Mesh Display | 0/TBD | Not started | - |
| 3. Offline Packaging and Lifecycle | 0/TBD | Not started | - |
| 4. Picking Parity | 0/TBD | Not started | - |
| 5. Full Digitizing and Data Parity | 0/TBD | Not started | - |
| 6. Shell and Native Retirement | 0/TBD | Not started | - |

## Notes

- **Hard ordering (non-negotiable):** transport (Phase 2) blocks picking (Phase 4),
  because there is nothing to raycast against until a mesh renders. Picking parity
  (Phase 4) blocks all digitizing parity (Phase 5). Data parity (Phase 5) blocks
  retirement (Phase 6).
- **Shippable stopping points:** Phases 1, 2, and 3 are each independently
  shippable and each fix something real on current macOS. Phase 4 is the gate.
  Phases 5 and 6 are all-or-nothing together, since a half-migrated acquisition
  path is worse than either whole path.
- **Reference architecture:** `landmarking-EOC`, the author's Flask + browser 2D
  landmarking tool, already implements this architecture for the same users. The
  state-ownership, port, offline, browser-launch, and testing decisions are
  inherited from it rather than re-derived. See
  `.planning/research/REFERENCE-ARCHITECTURE.md`.
- **Relationship to GUImorph:** GUImorph's native macOS work continues on its own
  track and is not duplicated, merged, or blocked here. The only thing flowing
  between the projects is the `.dgt` data contract and R-layer fixes, which can be
  cherry-picked from the `upstream` remote.
- **Positioning consequence:** GUImorph's stated differentiator is running entirely
  inside R with no external application and no JSON round-trip. A loopback server
  plus a bundled browser surface preserves the substance of that claim: launched
  from R, offline, native geomorph output, nothing separate to install. It does
  change the mechanism, and public and commercial framing should describe it
  accurately rather than restate the native-GL claim. StereoMorph establishes the
  precedent for browser-based digitizing inside R with this same user base.
- **Deferred:** Linux support, which this architecture makes nearly free but which
  is not scoped here. Metal-backed native rendering, which this architecture makes
  unnecessary.
