---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 03
current_phase_name: tri-platform-build-generalized-load-drop-glut
status: implemented-pending-verification
stopped_at: Phase 03 code-complete + statically verified (BLD-01/BLD-02/BLD-04); Windows render regression pending on-box, macOS .dylib build deferred to Phase 04
last_updated: "2026-07-15T00:00:00Z"
last_activity: 2026-07-15
last_activity_desc: Phase 03 authored (tri-platform CMake + NSGL stub + extension-aware .onLoad + GLUT dropped from draw path); static-verified, not yet target-verified
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 7
  completed_plans: 6
  percent: 33
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-12)

**Core value:** A researcher can digitize a 3D specimen and feed the result straight into `geomorph` — the interactive digitizing viewport must render the mesh and place landmarks correctly.
**Current focus:** Phase 03 — tri-platform-build-generalized-load-drop-glut

## Current Position

Phase: 03 (tri-platform-build-generalized-load-drop-glut) — CODE-COMPLETE + statically verified; NOT yet target-verified
Prior: Phase 02 (pathname-based-tk-drawable-resolution) — COMPLETE (verified on Windows 2026-07-15)
Status: BLD-01/BLD-02/BLD-04 authored — tri-platform CMake (WIN32/APPLE/else) emitting tkogl2.dylib against the frameworks; compiling NSGL stub (gfx_backend_nsgl.m; real context Phase 4); extension-aware, loud-failing .onLoad; GLUT dropped from the draw path (gluSphere, vestige removed, labels Windows-guarded). Windows render regression PENDING on-box (whole CMake + draw path changed → higher regression risk); macOS .dylib build DEFERRED to Phase 04 (no Mac host).
Next: (1) Erik rebuilds MSVC tkogl2.dll (reconfigure -DTKOGL2_TK_USE_STUBS=OFF -DTKOGL2_TK_STUB_LIB=...tk86.lib) + render regression → flip BLD-01/02/04 to Complete; then (2) Phase 04 NSGL first light + first macOS build.
Last activity: 2026-07-15 — Phase 03 code authored + static-verified

Progress: [██████████] Phase 02 complete; Phase 03 code-complete (verification pending)

## Performance Metrics

**Velocity:**

- Total plans completed: 2
- Average duration: 6 min
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 2 | 11 min | 6 min |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
| Phase 01 P01 | 2 min | 2 tasks | 6 files |
| Phase 01 P02 | 9 min | 2 tasks | 4 files |
| Phase 01 P03 | 16 min | 2 tasks | 1 files |
| Phase 01 P04 | 8 min | 2 tasks | 3 files |
| Phase 01 P05 | 6 | 2 tasks | 3 files |

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

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

- `phase-01-windows-validation.md` — pending Windows MSVC rebuild + D-06 render parity verification for CMP-01.
- `phase-02-windows-validation.md` — RESOLVED 2026-07-15 (windows-render-ok). Records the Windows build recipe: vendored Tk X11 shim + direct Tk-link mode via an import lib from R's tk86.dll.
- `phase-03-windows-validation.md` — PENDING. Windows MSVC rebuild (reconfigure required; CMakeLists changed) + render regression across the reworked draw path (gluSphere dots, Windows-guarded labels, downsample markers). macOS .dylib build is a separate deferred check (Phase 4).

### Blockers/Concerns

[Issues that affect future work]

- [Phase 1]: Deployment gate is the milestone's gating risk — the native path is dead unless R can run against Aqua (Cocoa) Tk (CRAN R ships X11 Tk; XQuartz GLX is broken on macOS Tahoe). Must be resolved before any GL code.
- [Phase 5]: `.dgt` cross-platform byte compatibility (endianness/fixed-width) unverified — needs a Windows↔macOS round-trip test.
- [Phase 6]: rgl `rglwidget` fallback must be checked against `select3d()`/`rgl.snapshot()` usage in the three plot functions.
- Phase 01 CMP-01 remains open: Windows MSVC render parity validation deferred to .planning/todos/pending/phase-01-windows-validation.md

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Platform | Linux (GLX/X11 or Wayland) support | Deferred to follow-on milestone | 2026-07-12 |
| Rendering | Metal-backed rendering (OpenGL deprecation escape hatch) | Deferred (beyond parity) | 2026-07-12 |
| Rendering | Offscreen FBO + Tk-photo-blit fallback backend | Deferred (only if NSView embedding proves unstable) | 2026-07-12 |
| Security | Unsafe PLY parser hardening | Tracked separately (no v1 requirement) | 2026-07-12 |

## Session Continuity

Last session: 2026-07-13T03:59:41.835Z
Stopped at: Completed 01-04-PLAN.md
Resume file: None
