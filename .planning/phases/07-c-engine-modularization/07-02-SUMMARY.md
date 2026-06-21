---
phase: 07-c-engine-modularization
plan: 02
subsystem: c-engine
tags: [c, wgl, hwnd, tkogl2, tcl_window]

requires:
  - phase: 07-01
    provides: tcl_dispatch.c extraction baseline
provides:
  - tcl_window.c/h with setWindowId, setWindow, dc/width/height
  - further trimmed tcl_if_ZARF_9.c (state/log/init only until 07-03)
affects: [phase-7-07-03]

tech-stack:
  added: []
  patterns:
    - "Window globals (dc, width, height) single definition in tcl_window.c; extern via def_ZARF_9.h / tcl_window.h"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.h
  modified:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_if_ZARF_9.c
    - integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt
    - BUILD.md
    - .planning/smoke-test-findings.md

key-decisions:
  - "Keep extern HDC dc in def_ZARF_9.h; width/height extern in tcl_window.h only (D-14)"
  - "TCL_CMD/TCL_RESULT2 macros duplicated in tcl_window.c for setWindow handler (same as pre-extraction god file)"

requirements-completed: [CENG-01]

duration: 1h
completed: 2026-06-21
---

# Phase 07 Plan 02: Window Extraction Summary

**Isolated HWND/WGL setup and the `setWindow` Tcl handler into `tcl_window.c`; smoke UAT passed on Windows MSVC build.**

## Performance

- **Duration:** ~1 h (includes god-file repair after partial extraction)
- **Completed:** 2026-06-21
- **Smoke UAT:** ✅ Passed (user approved 2026-06-21)

## Accomplishments

- Created `tcl_window.c`/`tcl_window.h` with `setWindowId`, `setWindow`, and `dc`/`width`/`height` definitions
- Removed window/WGL code from `tcl_if_ZARF_9.c`; god file now holds state, logging, and `Tkogl2_Init`
- Added `tcl_window.c` to CMakeLists.txt (after `tcl_dispatch.c`)
- Updated BUILD.md Phase 7 layout table
- MinGW WSL link build succeeds; `Tkogl2_Init` export verified
- Windows R smoke passed: GUI, PLY load, resize, landmark placement

## Smoke UAT (2026-06-21)

| Step | Result |
|------|--------|
| `load_all` + `GUImorph()` | ✅ |
| Load PLY | ✅ |
| Window resize | ✅ |
| Double-click landmark | ✅ |

## Next

- **07-03:** extract state → `tcl_state.c`, logging → `tcl_log.c`, init → `tcl_init.c`; remove god file from CMake
