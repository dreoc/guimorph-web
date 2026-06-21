---
phase: 07-c-engine-modularization
plan: 03
subsystem: c-engine
tags: [c, tcl, modularization, tkogl2]

requires:
  - phase: 07-02
    provides: tcl_window.c extraction baseline
provides:
  - tcl_state.c/h, tcl_log.c/h, tcl_init.c
  - god file eliminated from CMake build
  - five-module tkogl2 layout (CENG-01 complete)
affects: [phase-8-deduplication]

tech-stack:
  added: []
  patterns:
    - "Five tcl_* modules: init, dispatch, window, state, log"
    - "Cross-TU globals via tcl_state.h extern declarations"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_init.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.h
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_log.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_log.h
  modified:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.h
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c
    - integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt
    - BUILD.md
    - .planning/REQUIREMENTS.md
    - .planning/smoke-test-findings.md
  deleted:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_if_ZARF_9.c

key-decisions:
  - "Delete god file entirely rather than keep empty stub"
  - "GBL_RTN_* constants remain in tcl_dispatch.c; extern declared in tcl_dispatch.h"

requirements-completed: [CENG-01]

duration: 2h
completed: 2026-06-21
---

# Phase 07 Plan 03: God File Elimination Summary

**CENG-01 complete: five-module layout validated with full digitize round-trip smoke on Windows MSVC build.**

## Performance

- **Duration:** ~2 h
- **Completed:** 2026-06-21
- **Final UAT:** ✅ Passed (user approved Part A + Part B)

## Accomplishments

- Created `tcl_state.c/h`, `tcl_log.c/h`, `tcl_init.c`
- Deleted `tcl_if_ZARF_9.c`; CMake lists five `tcl_*` modules only
- MinGW link + MSVC deploy smoke: GUI, PLY, landmarks, curve, save/reload all pass
- CENG-01 closed in REQUIREMENTS.md

## Smoke UAT (2026-06-21)

| Part | Result |
|------|--------|
| A — load_all, GUImorph, PLY, landmark | ✅ |
| B — 2-specimen digitize, curve, save, openDgt reload | ✅ |

## Next

- **Phase 8:** dot/anchor deduplication (CENG-02)
