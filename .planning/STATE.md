---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 05
current_phase_name: retina-picking-input-fixes-digitizing-analysis-data-parity
status: executing
stopped_at: Phase 5 Windows validation COMPLETE (criterion 5 verified 2026-07-18); Plan 05-04 open, blocked on DAT-03 bidirectional gate (needs Austin's Mac)
last_updated: "2026-07-18T00:00:00Z"
last_activity: 2026-07-18
last_activity_desc: Phase 05 Windows validation passed on rebuilt DLL; GL context rebind fix (129b42a) verified against rgl; two out-of-milestone defects filed
progress:
  total_phases: 6
  completed_phases: 4
  total_plans: 14
  completed_plans: 13
  percent: 67
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-12)

**Core value:** A researcher can digitize a 3D specimen and feed the result straight into `geomorph` — the interactive digitizing viewport must render the mesh and place landmarks correctly.
**Current focus:** Phase 05 — retina-picking-input-fixes-digitizing-analysis-data-parity

## Current Position

Phase: 05 (retina-picking-input-fixes-digitizing-analysis-data-parity) — EXECUTING
Next: Phase 04 Plan 03 — live first light: run a GUImorph() session, confirm GL_VERSION is legacy 2.1 (no Core Profile), render the tetrahedron smoke fixture then a real specimen (RND-04/D-08), and confirm the mesh fills the full Retina canvas (D-05 viewport).
Status: Executing Phase 05
Blocker: RESOLVED — the NSGL seam now creates a real legacy-2.1 NSOpenGLContext, presents via flushBuffer, and the deployed arm64 tkogl2.dylib loads in a fresh aqua R session. Empirical residue for Plan 03: layer-backed contentView setView: (A1/Pitfall 2) — child-NSView subview fallback is documented in-code and ready if the viewport is blank.
Last activity: 2026-07-18 — Phase 05 Windows validation PASSED

## Phase 05 Windows validation (2026-07-18)

Criterion 5 verified on the rebuilt Windows DLL. Wheel 1 step/notch, portrait canvas
correct, 6-specimen `.dgt` round-trip with uniform 1000-point surfaces, 212 live
picks / 0 failed across 3 rgl mean-shape plots and 5 GPA runs.

Found and fixed in milestone: `gfx_make_current` was bound once at `setWindow` and
never again, so rgl plots stole the GL context (black canvas, all picks rejected).
`onDisplay` now rebinds per frame (`129b42a`). Prerequisite for Phase 6.

Filed out of milestone: `defect-anchor-template-fixed-block.md` (template/downsample
anchor mismatch silently corrupts surface semilandmarks) and
`defect-pca-single-component.md` (PCA crashes on a single-component ordination).

Remaining for Phase 5: DAT-03 bidirectional `.dgt` parity, needs Austin's Mac.
Windows-side artifact `testdgt_6_phase5test.DGT` is ready to send.

**Process note:** a rebuild whose `copy` step was skipped cost several debugging
cycles. Verify the loaded binary after every rebuild with
`tclvalue(tcl("add", "getCompileInformation", -1, 0, 0))`.

Progress: [█████████░] Phase 04 Plan 02 of 3 done (9/10 plans, 90%); RND-03 context lifecycle wired + GL_VERSION guard, BLD-03 arm64 dylib rebuilt/deployed/loadable (universal2/signing deferred); live render confirmed in Plan 03

## Performance Metrics

**Velocity:**

- Total plans completed: 10 (Phase 01: 5, Phase 02: 1, Phase 03: 1)
- Average duration: n/a (Phases 02–03 authored off-box, verified on Windows)
- Total execution time: n/a

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 5 | 41 min | ~8 min |
| 02 | 1 | n/a (off-box) | n/a |
| 03 | 1 | n/a (off-box) | n/a |
| 04 | 3 | - | - |

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

### Blockers/Concerns

[Issues that affect future work]

- [Phase 1]: Deployment gate is the milestone's gating risk — the native path is dead unless R can run against Aqua (Cocoa) Tk (CRAN R ships X11 Tk; XQuartz GLX is broken on macOS Tahoe). Must be resolved before any GL code.
- [Phase 5]: `.dgt` cross-platform byte compatibility (endianness/fixed-width) unverified — needs a Windows↔macOS round-trip test.
- [Phase 6]: rgl `rglwidget` fallback must be checked against `select3d()`/`rgl.snapshot()` usage in the three plot functions.
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

Last session: 2026-07-17T20:13:03.018Z
Stopped at: Phase 5 context gathered
Next: Phase 04 (macos-nsgl-backend-first-light) — requires a macOS host for the first Mac build (BLD-01 macOS `.dylib`) and NSGL first light (RND-03/RND-04, BLD-03).
Resume file: .planning/phases/05-retina-picking-input-fixes-digitizing-analysis-data-parity/05-CONTEXT.md
