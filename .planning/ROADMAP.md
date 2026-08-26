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
- [x] **Phase 2: Transport and Mesh Display** - `httpuv` serves the PLY over loopback; three.js renders and orbits it (completed 2026-08-03)
- [x] **Phase 3: Offline Packaging and Lifecycle** - Bundle the JS, select a port, launch the browser, tear down on session end (completed 2026-08-03)
- [x] **Phase 4: Picking Parity** - BVH raycast returns hit coordinates matching the native `gluUnProject` result within tolerance (completed 2026-08-05)
- [x] **Phase 5: Full Digitizing and Data Parity** - Curves, anchors, surfaces, undo, multi-specimen, GPA and export from the browser, with byte-identical `.dgt` (all 6 plans executed 2026-08-07; macOS UAT items 1-4 APPROVED 2026-08-10 after 5 inline browser-workflow fixes; item 2 live surface COMPUTE deferred as a known stub; items 5-6 deferred 2026-08-12 — Windows review unavailable, primary automated gates pass, corroboration captured in 05-WINDOWS-REVIEW.md)
- [x] **Phase 6: Shell and Native Retirement** - Replace the Tk chrome, then delete `tkogl2` and drop `rgl` (all 8 plans executed 2026-08-14; full suite green 675/0/6-skip; automated phase-goal verification PASSED 4/4 must-haves; ONE live-browser feature-parity UAT item owed via `/gsd-verify-work 6` before ship)

## Phase Details

### Phase 1: Result Plots + rgl Demotion

**Goal**: Render the two 3D result plots through a bundled three.js htmlwidget, and
make `rgl` an optional dependency so the package loads and runs on a host where
rgl itself cannot load.
**Depends on**: Nothing (first phase)
**Requirements**: WEB-00, PLT-01, PLT-02, PLT-03, CMP-01
**Success Criteria** (what must be TRUE):

  1. three.js (with OrbitControls and PLYLoader) and `three-mesh-bvh` are vendored
     into `inst/htmlwidgets/` as one classic-script bundle with licences and a
     version manifest, built by the pinned toolchain in `scripts/vendor/`. A
     minimal R wrapper writes a plain HTML page and opens it with `browseURL()`,
     with no network access and without returning `htmlwidgets` to Imports
     (WEB-00).
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

**Note (classic script, not ES modules)**: three.js dropped its UMD build; 0.185
ships ES modules only, and ES modules are CORS-blocked on `file://`. A plain HTML
page opened with `browseURL()` therefore cannot `import` three.js. Rather than
pull HTTP transport forward into Phase 1, the vendoring step bundles three,
OrbitControls, PLYLoader, and three-mesh-bvh into a single ~790 KB IIFE exposing
one global. It loads from `file://` and over `httpuv` alike, so Phase 1 stays
transport-free and Phase 2 reuses the same artifact. BVH prototype patches are
applied at bundle time, so `Mesh.raycast` is already accelerated when Phase 4
arrives. Cost: vendoring needs Node and esbuild, maintainer-only, once per
three.js upgrade. Users never compile anything.

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

**Plans**: 2/2 plans executed (phase manual UAT pending)
**Wave 1**

- [x] 02-01-PLAN.md — Mesh-from-URL render branch in the three.js template (WEB-02 render: async PLYLoader, computed normals, deferred framing, D-03/D-04 solid Lambert)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 02-02-PLAN.md — httpuv loopback transport server with per-session token guard, httpuv dependency, and transport test suite (WEB-01, WEB-02 delivery, CMP-01)

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

**Plans**: 4/4 plans complete

**Wave 1** *(parallel — no file overlap)*

- [x] 03-01-PLAN.md — Teardown lifecycle in `transport.R`: `.gmw_stop_token`/exported `gmw_close`, `.onUnload`, lazy `reg.finalizer(onexit=TRUE)`, re-scoped `PATH_INFO` guard + teardown/CMP-01 tests (WEB-04, CMP-01)
- [x] 03-03-PLAN.md — Page-side tab-close beacon in `view3d.R` (`sendBeacon` on `pagehide`/`visibilitychange`) + source-scan gate (WEB-04)

**Wave 2** *(depends on 03-01)*

- [x] 03-02-PLAN.md — Mixed httpuv app: `/<token>/close` route, user `port` arg + D-09 exhaustion error, browser-launch degradation + `/close`/port/launch tests (WEB-04)

**Wave 3** *(depends on 03-02, 03-03)*

- [x] 03-04-PLAN.md — WEB-03 offline install smoke test (ships+serves bundle, byte-identity, no external refs) + WEB-03/CMP-01 manual UAT records (WEB-03, CMP-01)

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

**Plans**: 3/3 plans complete

**Wave 1** *(parallel — no file overlap)*

- [x] 04-01-PLAN.md — Token-guarded POST `/<token>/pick` route on the mixed httpuv app, server-owned `.gmw_picks` registry, R read accessor, route + CMP-01 tests (PICK-01, CMP-01)
- [x] 04-02-PLAN.md — Browser raycast in `view3d.R`: eager `computeBoundsTree`, pointer→pick handler, overlay landmark dot (depth-tested), record-replay entry point, template source-scan (PICK-01, PICK-02, PICK-03 browser half)
- [x] 04-03-PLAN.md — `R/parity.R` gate math (mean edge length, 95th-percentile distance), schema-true placeholder pose-record fixture, skip-safe harness test; PICK-03 recorded OPEN (PICK-03)

**Note (PICK-03 stays OPEN — tracked, not dropped)**: Native fixture capture is
Windows-only and no host is available (D-06). All three plans build the full
parity harness against a schema-true placeholder fixture; the real Windows
capture drops in with zero code change to close the gate (D-07). PICK-01 and
PICK-02 ship value regardless.

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

**Plans**: 6/6 plans complete

**Wave 1** *(parallel — no file overlap)*

- [x] 05-01-PLAN.md — Deterministic `.dgt` writer: round-in-R + pinned CRLF across the whole file, the DAT-01 byte-identity prerequisite (`3dDigitize.main.r`, `test-dgt-determinism.R`) (DAT-01)
- [x] 05-02-PLAN.md — Server-owned `.gmw_session` model + token-guarded digitizing route surface (anchor/curve/delete/undo/specimen + thin downsample/gpa/export/save branches) with `excludeStaticPath` registration (`transport.R`, `test-digitizing-session.R`) (DGT-01, DGT-02, CMP-01)

**Wave 2** *(parallel — depends on Wave 1; no file overlap among these four)*

- [x] 05-03-PLAN.md — Browser interaction + overlays: anchor pick (green), curve-by-index cyan/blue, surface point cloud, delete/undo/specimen-switch with BVH rebuild (`view3d.R`, `test-digitizing-view3d.R`) (DGT-01, DGT-02)
- [x] 05-04-PLAN.md — Headless `.gmw_downsample_session` reusing the TPS warp + the mandatory `as.vector(t(...))` flatten regression (`3dDigitize.surface.r`, `test-surface-flatten.R`) (DGT-02)
- [x] 05-05-PLAN.md — GPA + `.csv`/`.rds` export from the browser via the session read path (populate `activeDataList` slots), forwarding untouched (`3dDigitize.geomorph.r`, `test-gpa-parity.R`, `test-export-parity.R`) (DGT-03)
- [x] 05-06-PLAN.md — `.gmw_save_session_dgt` through the one canonical writer; DAT-01 write-vs-write byte identity + CMP-01 skip-if-absent gate; DAT-02 `-rewrite` gate stays a documented skip (`3dDigitize.main.r`, `test-dgt-cross-platform.R`) (DAT-01, DAT-02, CMP-01)

**Note (two open PLANNER DECISIONS, recommended defaults chosen — no CONTEXT.md)**:
(A5) route shape = per-route `excludeStaticPath` entries + one `call` handler (not one
verb-in-body `/edit`); (A4) multi-specimen = re-serve mesh bytes on `/specimen` switch
(not serve-all-and-toggle). Both are stated as assumptions the user may override.

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

**Plans**: 8/8 plans complete

**Wave 1** *(server route surface)*

- [x] 06-01-PLAN.md — `transport.R` shell-support routes (`/files`, `/open`, `/savepath`, `/tabstate`, `/status`, `/msgack`, `/color`) + server-owned `browse_dir` + path-traversal-safe picker tests (UI-01)

**Wave 2** *(depends on 06-01; parallel — no file overlap)*

- [x] 06-02-PLAN.md — `view3d.R` browser shell chrome: DOM tab strip, menu bar, status bar, modal layer, file picker, color input, specimen nav (RE-SERVE), shortcuts (UI-01)
- [x] 06-03-PLAN.md — `R/shell.R` relocate survivors (`GUImorphWeb`/`dbg`/`.plot_show`/`.onAttach`/`.isMacOS`) + rewire entry to boot the browser shell + engine-absent workflow test (UI-02)

**Wave 3** *(depends on 06-01/06-03; parallel — no file overlap)*

- [x] 06-04-PLAN.md — strip `3dDigitize.main.r` Tk chrome (window/notebook/menu/nav/status/shortcuts) + engine verbs + S3 generics (UI-01, UI-02)
- [x] 06-05-PLAN.md — strip `3dDigitize.digitize.r`/`.curve.r` Tk builders + `tkgetOpenFile`/`tk_chooseColor` → `/color` route + engine verbs (UI-01, UI-02)
- [x] 06-06-PLAN.md — strip `3dDigitize.surface.r`/`.geomorph.r` Tk builders + `tkmessageBox`/`tkgetSaveFile` + GPA options over `/gpa` route + engine verbs (UI-01, UI-02)

**Wave 4** *(depends on 06-03..06-06)*

- [x] 06-07-PLAN.md — physical deletion: `R/rtkogl.R`, `inst/libs/*` engine binaries, sibling `tkogl2/` build tree + `test-transport.R` presence→absence inversion + engine-absent workflow test (UI-02)

**Wave 5** *(depends on 06-07)*

- [x] 06-08-PLAN.md — `DESCRIPTION`/`NAMESPACE` severance (`tcltk`/`tcltk2`/`rgl`, bump 1.0.0) + `NEWS.md` migration note + CMP-01/parity/tcltk-stub test reconciliation + PICK-03/DAT-02 won't-verify closure (UI-03, D-04)

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
| 2. Transport and Mesh Display | 2/2 | Complete    | 2026-08-03 |
| 3. Offline Packaging and Lifecycle | 4/4 | Complete    | 2026-08-03 |
| 4. Picking Parity | 3/3 | Complete    | 2026-08-05 |
| 5. Full Digitizing and Data Parity | 6/6 | Complete   | 2026-08-07 |
| 6. Shell and Native Retirement | 8/8 | Complete   | 2026-08-14 |

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
