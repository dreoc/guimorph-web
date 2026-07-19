---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 6
current_phase_name: rgl Result-Plot Fallback on macOS
status: executing
stopped_at: Phase 5 COMPLETE (verification passed; DAT-03 macOS->Windows return leg owner-accepted, Erik confirmation tracked as open todo). Transitioned to Phase 6 (rgl result-plot fallback). Rebuilt arm64 dylib is deployed but UNCOMMITTED pending the universal2/signing decision.
last_updated: "2026-07-19T04:22:26.869Z"
last_activity: 2026-07-19
last_activity_desc: Phase 05 complete, transitioned to Phase 6
progress:
  total_phases: 6
  completed_phases: 5
  total_plans: 14
  completed_plans: 14
  percent: 83
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-12)

**Core value:** A researcher can digitize a 3D specimen and feed the result straight into `geomorph` — the interactive digitizing viewport must render the mesh and place landmarks correctly.
**Current focus:** Phase 05 — retina-picking-input-fixes-digitizing-analysis-data-parity

## Current Position

Phase: 6 — rgl Result-Plot Fallback on macOS
Next (in order):

  1. Pull `311b265` and rebuild + redeploy the macOS `tkogl2.dylib` (carries the three
     engine fixes 129b42a/457895e/763ffca). Do this BEFORE any further macOS testing.
     Verify the loaded binary after copy: `tclvalue(tcl("add", "getCompileInformation", -1, 0, 0))`.

  2. DAT-03 macOS leg — open Erik's `testdgt_6_phase5test.DGT` (6 specimens, Windows-authored,
     uniform 1000-pt surfaces) on the Mac and confirm landmarks, anchors, curves, surfaces intact.

  3. DAT-03 return leg — author a `.dgt` on the Mac and send it to Erik to open on Windows. Closing
     both legs completes Plan 05-04 and Phase 5.
Status: Executing Phase 05 (13/14 plans; only 05-04 DAT-03 macOS leg outstanding)
Blocker: DAT-03 bidirectional `.dgt` parity gate (Plan 05-04, non-autonomous). Windows leg PASSED;
  macOS leg pending on this box. Hard prerequisite: pull 311b265 + rebuild dylib first (see Next #1) —
  running DAT-03 against the stale dylib would validate the wrong binary.
Last activity: 2026-07-19 — Phase 05 complete, transitioned to Phase 6

## Phase 05 Windows validation (2026-07-18)

Criterion 5 verified on the rebuilt Windows DLL. Wheel 1 step/notch, portrait canvas
correct, 6-specimen `.dgt` round-trip with uniform 1000-point surfaces, 212 live
picks / 0 failed across 3 rgl mean-shape plots and 5 GPA runs.

### Engine rendering bugs found and fixed (all in milestone)

Validation surfaced three pre-existing engine bugs. All were confirmed against the
source and verified on screen; none were in the R layer, which was sending correct
values throughout.

1. **GL context bound once** (`129b42a`). `gfx_make_current` ran only at
   `setWindow`. `wglMakeCurrent` and `makeCurrentContext` bind per *thread*, so any
   rgl plot on the R main thread silently unbound the engine: black canvas, every
   pick rejected, recoverable only by restarting GUImorph. `onDisplay` now rebinds
   per frame. **Prerequisite for Phase 6**, which runs rgl alongside the engine by
   design. Verified: 3 rgl plots and 5 GPA runs in one session, 212 live picks, 0
   failed.

2. **No redraw after state change** (`457895e`). `TCL_CMD_SHOW` ends with
   `onDisplay()`; `TCL_CMD_ADD` and `setDot` do not. A new curve segment and its
   recoloured landmarks stayed invisible until an unrelated redraw fired. Redraw
   added at the end of the add-curve branch and after `dot_color`/`anchor_color`.

3. **Sticky colour pointer + unbound curve slice** (`763ffca`). Two bugs behind the
   remaining curve-tab symptoms:

   - `drawDots()`/`drawAnchors()` declared their colour pointers outside the dot
     loop and never reset them, so once a dot carried an explicit colour every
     later dot inherited it. On segment (1,2,3) landmark 1 drew red, landmark 2 set
     the pointer blue, and landmark 3 rendered blue despite receiving the
     (-1,-1,-1) restore sentinel.

   - `drawCurves()` read `get_curve_slice_id()` without binding it, unlike
     `drawDots()`/`drawAnchors()` which call `dotSetArrayIndex(model_index)`. The
     add-curve branch loops `curveSetArrayIndex(cc)` over every slice and exits on
     the last one, so a redraw straight afterwards asked for the wrong specimen's
     curve. Another instance of the recurring `models[0]` indexing family.

   Verified 2026-07-18: three segments defined with no tab switch; landmarks 1/3/5
   red, 2/4/6 large blue, all segments drawn immediately.

**Lesson carried forward:** each of these looked like an R bug and was not. The R
debug log (colour values, pick outcomes) ruled the R layer out in every case, and
should be read before theorising about it.

**Grep follow-up (from Erik):** the unbound-curve-slice bug is the `models[0]`
indexing family again — grep for other functions that read a slice index (e.g.
`get_curve_slice_id()`) without first binding it (`curveSetArrayIndex` /
`dotSetArrayIndex`).

### Four unguarded Austin changes had leaked onto Windows — all re-guarded (Erik)

Four Phase 4/5 changes were platform-unguarded and had reached the Windows build.
All handled on Erik's side; Austin's macOS feel is unchanged:

1. **Wheel zoom** — `normalizeWheelDelta` divided by 120 on every platform, so one
   Windows notch became four zoom steps. The platform notch is now the only platform
   constant (120 Windows / 30 macOS) with residual threshold 1. macOS is arithmetically
   identical: D/120 stepping at 0.25 == D/30 stepping at 1.

2. **Retina near-miss retry** — now guarded to macOS at all three sites. Windows was
   paying up to 24 re-renders on a missed click.

3. **Portrait ortho** — verified correct on Windows, left alone.
4. **.dgt write format** — round-trips cleanly on Windows.

### Out-of-milestone defects (filed during validation)

- `defect-pca-single-component.md` — **FIXED 2026-07-18** (`status: done`). PCA
  (morphospace) crashed when the ordination retained a single component; fixed in
  `3dDigitize.geomorph.r::plotPCA` (`scores <- as.matrix(scores)` restores the m×1
  shape). Not a port issue — reproduced on Windows.

- `defect-anchor-template-fixed-block.md` — **OPEN** (`severity: silent-data-corruption`).
  Template/downsample anchor mismatch silently corrupts surface semilandmarks when the
  two disagree on whether anchors sit in the fixed block. Pre-existing Windows behaviour,
  not a port regression. **READ this file before touching that path.** Neither defect
  blocks the milestone.

### Remaining for Phase 5 — DAT-03 (needs both machines)

Windows leg PASSED. Erik is sending `testdgt_6_phase5test.DGT` (6 specimens,
Windows-authored, uniform 1000-point surfaces). Two asks to close the phase:

  1. Confirm it opens correctly on macOS — landmarks, anchors, curves, surfaces intact.
  2. Author a `.dgt` on the Mac and send it back for Erik to open on Windows.

**Process note:** a rebuild whose `copy` step was skipped cost several debugging
cycles. Verify the loaded binary after every rebuild with
`tclvalue(tcl("add", "getCompileInformation", -1, 0, 0))`.

Progress: [█████████░] Phase 05 plans 05-01/02/03 complete, 05-04 open (13/14 plans, 93%). Retina picking authority + macOS input normalization, dialog/shortcut parity, digitizing/anchor/curve/surface + GPA parity all landed and tested. Only DAT-03 macOS leg remains (blocked on 311b265 rebuild).

## Performance Metrics

**Velocity:**

- Total plans completed: 14 (Phase 01: 5, Phase 02: 1, Phase 03: 1)
- Average duration: n/a (Phases 02–03 authored off-box, verified on Windows)
- Total execution time: n/a

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 5 | 41 min | ~8 min |
| 02 | 1 | n/a (off-box) | n/a |
| 03 | 1 | n/a (off-box) | n/a |
| 04 | 3 | - | - |
| 05 | 4 | - | - |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
| Phase 01 P01 | 2 min | 2 tasks | 6 files |
| Phase 01 P02 | 9 min | 2 tasks | 4 files |
| Phase 01 P03 | 16 min | 2 tasks | 1 files |
| Phase 01 P04 | 8 min | 2 tasks | 3 files |
| Phase 01 P05 | 6 | 2 tasks | 3 files |
| Phase 04 P01 | 10min | 3 tasks | 8 files |
| Phase 04 P02 | 4min | 3 tasks | 2 files |
| Phase 05 P03 | 3 min | 2 tasks | 6 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Milestone]: Target macOS first (Linux deferred) — rgl/OpenGL digitizing deprecated there is the origin motivation.
- [Milestone]: Full feature parity target (not an MVP slice) — a partial digitizer isn't useful to researchers.
- [Milestone]: Keep R/Tk + geomorph layers; only rework native windowing/GL glue — analysis + GUI logic are validated.
- [Roadmap]: Native NSOpenGL-behind-a-seam over GLFW/SDL — portable toolkits own their own windows and can't render into a Tk-owned `NSView`.
- [Phase 01 Plan 01]: Keep `ogl_init` in core after `gfx_create`/`gfx_make_current` to preserve lifecycle ordering.
- [Phase 01 Plan 01]: Keep `gfx_destroy` as a no-op stub to avoid behavioral teardown changes in this mechanical refactor.
- [Phase 01 Plan 02]: Use command-line R plus `gate_check.R` as the durable Aqua deployment gate.
- [Phase 01 Plan 02]: Treat package-local D-01 binding as currently infeasible in this environment due mixed Tk runtime collisions.
- [Phase 01]: Locked D-01 (d01-bundled) as explicit distribution path for Plan 01-03.
- [Phase 01]: Retained Plan 02 feasibility caveat and routed bundling hardening requirements to Phase 4 BLD-03.
- [Phase 01]: Phase 01 Plan 04 deferred Windows MSVC render validation to backlog when macOS host could not execute D-06 check. — Continuation accepted from checkpoint: user cannot run Windows validation now; defer tracked in .planning/todos/pending/phase-01-windows-validation.md
- [Phase ?]: [Phase 01 Plan 05]: Use standard-C intptr_t (via <stdint.h>) for the int->native-drawable cast so no Win32 token remains in core; seam boundary complete (RND-01).
- [Phase ?]: [Phase 01 Plan 05]: Resolved model_t.count TBD debt marker with a concrete definition (vertex count for glDrawArrays, three per triangle).
- [Phase 03 Plan 01]: Phase 3 is build scaffolding only — the macOS NSGL backend is a compiling stub (stores contentView, no GL context); first light is Phase 4. Keeps BLD-01 (build) separate from RND-03/RND-04 (render).
- [Phase 03 Plan 01]: Emit .dylib via SHARED (-dynamiclib) per the ROADMAP, not a .so MODULE bundle; tcl('load', <abs path>) loads by path, so the extension only has to match what the now-extension-aware .onLoad searches for.
- [Phase 03 Plan 01]: Swap glutSolidSphere → gluSphere on BOTH platforms (one code path, visually identical at 10/10) rather than #ifdef the sphere; this also fixed a latent quadric leak in ogl_drawDot. Keep GLUT on Windows only for glutBitmapCharacter labels (guarded #if _WIN32) — criterion 3 only requires no-GLUT on macOS, and dropping labels would change Windows behavior.
- [Phase 03 Plan 01]: Hold macOS ObjC object pointers as void* (+__bridge) in gfx_backend_nsgl.m so it compiles under MRC or ARC (ARC forbids strong ObjC pointers in C structs); no memory model is pinned.
- [Phase 03 Plan 01]: macOS Tcl/Tk via cache var TKOGL2_MACOS_TCLTK_PREFIX (default /opt/homebrew/opt/tcl-tk) + find_library over versioned stub names, mirroring the Windows TKOGL2_TK_* approach. Watch item: [info sharedlibextension] may report .so vs the emitted .dylib; mitigated by the multi-extension search in .onLoad.
- [Phase 03 Plan 01]: .onLoad now stop()s loudly on both not-found and tcl-load-failure (was warning-and-continue). If this proves too aggressive for dev tooling, soften the not-found path to packageStartupMessage while keeping the load-failure a stop() (noted in the pending todo).
- [Phase 04]: [Phase 04 Plan 01]: Homebrew tcl-tk 9.x nests tcl.h/tk.h under include/tcl-tk/; CMake APPLE branch must add that subdir or <tk.h> resolves to the SDK X11 tk.h and the build fails.
- [Phase 04]: [Phase 04 Plan 01]: [info sharedlibextension]=.dylib on tcl-tk 9.0.4 (matches emitted ext); Pitfall 7 (.so vs .dylib) is a non-issue on this host; Phase 3 multi-ext .onLoad stays as insurance.
- [Phase 04]: [Phase 04 Plan 01]: Generated build-gate/ and build-mac/ trees (incl .dylibs) are gitignored per Phase 0 policy; Plan 02 deploys the shipped .dylib into inst/libs.
- [Phase 04]: [Phase 04 Plan 01]: Added missing standard headers (stdlib/string/ctype) per TU rather than suppress AppleClang implicit-decl error (implicit int return truncates 64-bit pointers).
- [Phase ?]: [Phase 04 Plan 02]: MRC lifetime discipline in gfx_backend_nsgl.m (no -fobjc-arc): own ctx via +alloc, retain contentView, release both in gfx_destroy.
- [Phase ?]: [Phase 04 Plan 02]: GL_SILENCE_DEPRECATION covers only GL, not AppKit NSOpenGL deprecations; added targeted -Wdeprecated-declarations pragma so the .m compiles clean while a real future removal (an error) stays visible.
- [Phase ?]: [Phase 04 Plan 02]: Direct setView: on Tk's contentView used for first light (A1); child-NSView subview fallback documented in-code but not activated pending Plan 03 live render. Deployed shipped .dylib to inst/libs/tkogl2.dylib (r_arch empty).
- [Phase ?]: .planning/phases/05-retina-picking-input-fixes-digitizing-analysis-data-parity/05-03-SUMMARY.md

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

- `phase-01-windows-validation.md` — RESOLVED 2026-07-16 (superseded). The Phase 03 Windows rebuild is strictly newer source that already contains the Phase 01 seam; its `windows-render-ok` render regression covers Plan 01-04's parity check.
- `phase-02-windows-validation.md` — RESOLVED 2026-07-15 (windows-render-ok). Records the Windows build recipe: vendored Tk X11 shim + direct Tk-link mode via an import lib from R's tk86.dll.
- `phase-03-windows-validation.md` — RESOLVED 2026-07-16 (windows-render-ok). Restructured CMake rebuilt tkogl2.dll clean; gluSphere dots + downsample markers + Windows labels render; 6-specimen .dgt loaded through the rewritten .onLoad. macOS .dylib build remains a separate Phase 4 check (no Mac host).
- `phase-05-windows-validation.md` — Phase 5 Windows validation record (PASSED 2026-07-18; three engine bugs fixed, four unguarded changes re-guarded).
- `defect-pca-single-component.md` — FIXED 2026-07-18 (out-of-milestone). PCA single-component ordination crash resolved in `plotPCA`.
- `defect-anchor-template-fixed-block.md` — OPEN (out-of-milestone, silent-data-corruption). Template/downsample anchor-in-fixed-block mismatch corrupts surface semilandmarks. Read before touching that path.

### Blockers/Concerns

[Issues that affect future work]

- [Phase 1]: Deployment gate is the milestone's gating risk — the native path is dead unless R can run against Aqua (Cocoa) Tk (CRAN R ships X11 Tk; XQuartz GLX is broken on macOS Tahoe). Must be resolved before any GL code.
- [Phase 5]: `.dgt` cross-platform byte compatibility — Windows leg VERIFIED 2026-07-18; macOS leg (open Windows-authored `.dgt` + author one back) is the only DAT-03 work left. Requires pulling 311b265 + rebuilding the dylib first.
- [Phase 5/6]: BLD-03 is still **arm64-only** — Intel Macs (x86_64/universal2) and Gatekeeper (signing/notarization/`xattr`) are unresolved. Open decision (Erik): does universal2 + distribution hardening belong in Phase 6, or in a dedicated release phase of its own? Not blocking Phase 5/6 functional work.
- [Phase 6]: rgl `rglwidget` fallback must be checked against `select3d()`/`rgl.snapshot()` usage in the three plot functions. The GL-context-per-frame fix (`129b42a`) is a hard prerequisite — Phase 6 puts rgl and the engine in one process by design.
- Phase 01 CMP-01: RESOLVED 2026-07-16 — Windows render parity is covered by the Phase 03 Windows rebuild (strictly newer source incl. the seam; renders unchanged). The recurring CMP-01 checkpoint now only has the macOS side outstanding (Phase 04+).

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Platform | Linux (GLX/X11 or Wayland) support | Deferred to follow-on milestone | 2026-07-12 |
| Rendering | Metal-backed rendering (OpenGL deprecation escape hatch) | Deferred (beyond parity) | 2026-07-12 |
| Rendering | Offscreen FBO + Tk-photo-blit fallback backend | Deferred (only if NSView embedding proves unstable) | 2026-07-12 |
| Security | Unsafe PLY parser hardening | Tracked separately (no v1 requirement) | 2026-07-12 |

## Session Continuity

Last session: 2026-07-18T22:00:00Z
Stopped at: Phase 5 plans 05-01/02/03 executed + committed; 05-04 open at DAT-03. Reviewed Erik's Windows-validation report and synced STATE.
Next: On the Mac — (1) pull `311b265` + rebuild/redeploy `tkogl2.dylib`, verify loaded binary; (2) open `testdgt_6_phase5test.DGT` and confirm parity; (3) author a `.dgt` and send back. That closes Phase 5 → then Phase 6 (rgl result-plot fallback).
Resume file: .planning/phases/05-retina-picking-input-fixes-digitizing-analysis-data-parity/05-CONTEXT.md
