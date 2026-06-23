---
phase: 09-c-engine-cleanup-validation
plan: 03
subsystem: c-engine
tags: [tkogl2, msvc, ceng-04, simpleLog, debug-cleanup, dispatch]

# Dependency graph
requires:
  - phase: 09-02
    provides: ogl/geometry D-macro call sites removed; loader trace cleaned
provides:
  - Dead debug-dump functions removed from tcl_state.c (showPoint, ut_show_Model, show_GBL_*)
  - Statistics trace printf removed; simpleLogStatistics is sole statistics dump channel
  - tcl_dispatch trace printf, if(0) made-inert blocks, and D-macro call sites removed
  - D/D1/D2/D3 macro definitions removed from def_ZARF_9.h (types/enums byte-unchanged)
  - MAKE_INERT documentation pruned from RunTime_Defines_ZARF_9.h; CODE_FOR_LIBRARY retained
  - MSVC Release tkogl2.dll deployed (310272 bytes); Tkogl2_Init export verified
affects: [09-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "tcl_log.c/simpleLog is the single surviving diagnostic channel (D-08)"
    - "def_ZARF_9.h type layout frozen; only debug D* macro lines removed"

key-files:
  created: []
  modified:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.h
    - integrated-guimorph-development_EOC/Project/tkogl2/src/StatisticsFunction_ZARF_9.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h
    - integrated-guimorph-development_EOC/Project/tkogl2/src/RunTime_Defines_ZARF_9.h
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll

key-decisions:
  - "Deleted unreferenced showStatistics entirely; simpleLogStatistics already existed as load-bearing equivalent"
  - "Removed development-test printf loop in setSpecimen allocate; kept dummy model setup loop"
  - "STAND_ALONE_TOOL printf blocks left untouched (out of scope per RESEARCH A4)"

requirements-completed: [CENG-04]

# Metrics
duration: 40min
completed: 2026-06-22
---

# Phase 09 Plan 03: State/Dispatch Debug Cleanup Summary

**Removed dead debug-dump functions, dispatch trace/if(0) cruft, and D/MAKE_INERT macro facility; tcl_log/simpleLog is now the sole diagnostic channel with frozen def_ZARF_9.h types intact.**

## Performance

- **Duration:** ~40 min
- **Tasks:** 3/3 complete (human smoke approved 2026-06-22)
- **Files modified:** 6 source/header files + deployed DLL

## Accomplishments

- Deleted unreferenced debug-dump functions (`showPoint`, `ut_show_Model`, `show_GBL_LANDMARK_SET`, `show_GBL_CURVE_SET`) and their `tcl_state.h` prototypes
- Removed `showStatistics` bare-printf trace; `simpleLogStatistics` retained as the load-bearing path
- Cleaned `tcl_dispatch.c`: 3 `if(0)` blocks, 4 trace `printf`, 1 remaining `D1` call site, and duplicate D-macro defs (already absent from prior partial cleanup)
- Removed canonical `D/D1/D2/D3` definitions from `def_ZARF_9.h` without touching type/enum layout
- Pruned `MAKE_INERT` `#undef` and documentation from `RunTime_Defines_ZARF_9.h`; `#define CODE_FOR_LIBRARY` retained
- MSVC Release build green; `Tkogl2_Init` exported; DLL deployed (310272 bytes)

## Task Commits

1. **Task 1: Remove dead debug-dump functions and statistics trace** - `7ec90ac` (feat)
2. **Task 2: Clean dispatch trace, remove D-macros and MAKE_INERT docs** - `a3815f8` (feat)

**Task 3:** MSVC build + deploy (no commit — DLL gitignored)

## Files Created/Modified

- `tcl_state.c` / `tcl_state.h` — debug-dump functions and prototypes removed
- `StatisticsFunction_ZARF_9.c` — `showStatistics` removed (unreferenced trace)
- `tcl_dispatch.c` — trace printf, if(0) blocks, D1 call site removed
- `def_ZARF_9.h` — D/D1/D2/D3 macro definitions removed only
- `RunTime_Defines_ZARF_9.h` — MAKE_INERT docs pruned; CODE_FOR_LIBRARY kept
- `inst/libs/x64/tkogl2.dll` — MSVC Release artifact deployed; prior DLL backed up to `.bak`

## Decisions Made

- Deleted whole unreferenced dump functions (A1 confirmed zero call sites in `src/`)
- Left `STAND_ALONE_TOOL` ALLOCATE/FREE wrapper printf untouched (out of scope)
- `ut_show_Model` prototype remains in `def_ZARF_9.h:296` (pre-existing; no implementation link impact)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- UNC path MSBuild MSB8064/8065 warnings — non-blocking; build succeeded
- PowerShell git commit quoting issue — resolved via WSL git for atomic commits

## User Setup Required

None — DLL deployed. Human smoke required (Task 3 checkpoint).

## Next Phase Readiness

- **09-04** full regression UAT blocked until Task 3 human smoke passes
- Rollback: `inst/libs/x64/tkogl2.dll.bak` or `.pre-phase9.bak`

## Self-Check: PASSED

- FOUND: integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c
- FOUND: integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c
- FOUND: integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h
- FOUND: .planning/phases/09-c-engine-cleanup-validation/09-03-SUMMARY.md
- FOUND: commit 7ec90ac
- FOUND: commit a3815f8

---
*Phase: 09-c-engine-cleanup-validation*
*Completed: 2026-06-22 (code + build; human smoke pending)*
