---
title: "Run Windows MSVC rebuild + render regression for Plan 03-01 (BLD-01/BLD-02/BLD-04)"
status: done
priority: high
resolves_phase: 3
created: 2026-07-15
updated: 2026-07-16
resolved: 2026-07-16
owner: eoc
source_plan: 03-01
---

## Resolution (2026-07-16) — windows-render-ok

Verified on Windows R 4.6.1. `cmake --build build-msvc` re-ran configure itself
off the changed CMakeLists (using the cached direct-Tk-link settings from Phase 2,
so no manual reconfigure was needed) and rebuilt `tkogl2.dll` clean: every source
compiled, `gfx_backend_wgl.c` built, `gfx_backend_nsgl.m` was correctly skipped on
Windows, no unresolved Tk symbols. The deployed DLL renders — mesh non-blank,
`gluSphere` landmark dots draw on-click, Windows-guarded numeric labels show,
`gluSphere` downsample markers draw, picks land on-target. A 6-specimen `.dgt` also
loaded through the rewritten `.onLoad` (multi-specimen load + per-specimen surface
restore + tab switching all fine) — a stronger path than a single PLY.

BLD-02 and BLD-04 are complete. BLD-01's Windows half (builds + renders unchanged)
is verified; the macOS `.dylib` actually building is the remaining piece and moves
to Phase 4 (the first Mac build). The loud `.onLoad` `stop()` did not interfere
with `devtools::load_all` (the engine was deployed), so no softening was needed.

## Context (original)

Plan `03-01` reworked the whole `CMakeLists.txt` (tri-platform WIN32/APPLE/else),
`def_ZARF_9.h` (platform-guarded `windows.h` + GL headers, dropped `<GL/glut.h>`),
and the draw path (`glutSolidSphere` -> `gluSphere`; `glutInitDisplayMode`
removed; `glutBitmapCharacter` labels Windows-guarded). None of it is built or
render-verified on the Linux authoring box. The Windows regression surface is
larger than Phase 2 (build system + draw path both changed), so it must be
confirmed on-target before shipping the rebuilt DLL.

## Build step (CMakeLists changed — reconfigure required)

The restructured CMake means a stale `build-msvc` cache can misconfigure. Wipe it
and reconfigure with the same direct-Tk-link recipe Phase 2 verified (the vendored
`tkstub86.lib` is x86; x64 R ships no tk stub, so link an import lib generated from
`%R_HOME%\Tcl\bin\tk86.dll`):

```
Remove-Item -Recurse -Force build-msvc
cmake -S . -B build-msvc -G "Visual Studio 17 2022" -A x64 -DTKOGL2_TK_USE_STUBS=OFF -DTKOGL2_TK_STUB_LIB=<abs path>\tk86.lib
cmake --build build-msvc --config Release
Copy-Item build-msvc\Release\tkogl2.dll ..\GUImorphDevelopment\inst\libs\x64\tkogl2.dll -Force
```

(`build_deploy_tkogl2.ps1` automates the rebuild+deploy; make sure it passes the
two `-D` flags above, or reconfigure once by hand first.) The `tk86.def`/`tk86.lib`
from Phase 2 can be reused if still present.

## Validation

- Launch `GUImorph(debug = TRUE)` on Windows R (R 4.6.1, Tcl/Tk 8.6).
- Load a PLY (e.g. `C:/dev/Folsom3D/B12_1_clean.ply`).
- Confirm the mesh renders (non-blank), landmark dots draw, and numeric labels
  still show next to placed landmarks (the labels are the Windows-guarded
  `glutBitmapCharacter` path; regression check that they survived the header split).
- Confirm the downsample dots (Use Anchors / downsample view) still draw — this
  exercises the second `gluSphere` conversion and the reused quadric.
- Place several landmarks; confirm on-target placement (no regression from the
  build/header changes).

## Acceptance

- Build + link succeed with no unresolved symbols and no missing headers (the
  `gluSphere` swap must not have broken GLU linkage; GLUT still links for labels).
- `gluSphere` dots look identical to the old `glutSolidSphere` dots (slices/stacks
  10/10) — no visual change to landmark or downsample markers.
- Numeric landmark labels still render on Windows.
- Landmark placement lands on-target.
- Report back as `windows-render-ok` (Phase 3) or with regression details.

## Notes

- macOS `.dylib` build is a SEPARATE, DEFERRED check (Phase 4 — no Mac host now):
  `cmake -B build-mac -DTKOGL2_MACOS_TCLTK_PREFIX=$(brew --prefix tcl-tk) && cmake --build build-mac`.
  Watch item: `[info sharedlibextension]` may report `.so` vs the `.dylib` we emit;
  the multi-extension search in `.onLoad` is the mitigation.
- Supersedes nothing in `phase-01/02-windows-validation.md`; this build is strictly
  newer source and covers those if not yet run.
- If the loud `.onLoad` `stop()` proves too aggressive for dev tooling (e.g. it
  aborts `devtools::load_all` when the engine isn't deployed), note it here and we
  can soften the not-found path to a prominent `packageStartupMessage` while keeping
  the tcl-load-failure path a `stop()`.
