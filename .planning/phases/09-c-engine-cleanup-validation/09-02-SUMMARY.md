---
phase: 09-c-engine-cleanup-validation
plan: 02
subsystem: c-engine
tags: [c, tkogl2, simpleLog, debug-cleanup, msvc]

requires:
  - phase: 09-01
    provides: array-ified GBL_PTR globals and MSVC baseline DLL
provides:
  - Loader/geometry trace printf removed from ply/model/curve/marker sources
  - TAG_* parse errors routed through simpleLog in ogl_loadDgtModel
  - if(0) debug toggles and D-macro call sites removed from geometry files
  - MSVC Release build deployed to inst/libs/x64/tkogl2.dll (311808 bytes)
affects: [phase-9-09-03, phase-9-09-04]

tech-stack:
  added: []
  patterns:
    - "D-05 guard: preserve sscanf/strstr/strncmp/FLAG_READ_SURFACES in ogl_loadDgtModel while deleting adjacent trace printf"

key-files:
  created: []
  modified:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ply_ZARF_9.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ZARF_9.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/curve_ZARF_9.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll

key-decisions:
  - "TAG_* error paths use single simpleLog call (removed duplicate printf pairs)"
  - "Fixed pre-existing simpleLog(buffer) bug in TAG_SURF path — now logs formatted ogl_buffer"

requirements-completed: [CENG-04]

duration: 45min
completed: 2026-06-22
---

# Phase 09 Plan 02: Loader/Geometry Debug Cleanup Summary

**Removed trace printf and dead if(0) debug blocks from ply loader and geometry draw paths; TAG_* parse errors now use simpleLog; MSVC DLL rebuilt and deployed.**

## Performance

- **Duration:** ~45 min
- **Tasks:** 3/3 complete (human D-05 reload smoke approved 2026-06-22)
- **Files modified:** 4 source files + deployed DLL

## Accomplishments

- Deleted all active `printf` trace calls from `ogl_model_ply_ZARF_9.c` (128 lines net removed in Task 1)
- Ported TAG_LM/TAG_ANCH/TAG_SURF error messages to `simpleLog`; preserved D-05 parse guards unchanged
- Removed if(0) file-dump block and per-vertex debug toggles in `ogl_loadDownSampleModel`
- Removed if(0) toggles in `ogl_model_ZARF_9.c`, `curve_ZARF_9.c`, `marker.c`; deleted commented D3 macro sites
- MSVC Release build succeeded; `Tkogl2_Init` export verified; DLL deployed (311808 bytes)

## Task Commits

1. **Task 1: Ply loader trace cleanup** - `2952378` (feat)
2. **Task 2: Geometry if(0) and D-macro cleanup** - `80c2799` (feat)

**Task 3:** MSVC build + deploy (no commit — DLL gitignored)

## Files Created/Modified

- `ogl_model_ply_ZARF_9.c` — trace printf removed; TAG_* errors → simpleLog; if(0) blocks deleted; unused `time.h` removed
- `ogl_model_ZARF_9.c` — ogl_drawLine if(0) block and D3 comments removed
- `curve_ZARF_9.c` — z-scale if(0) debug wrappers simplified
- `marker.c` — dead if(0) curve_slice_index block removed
- `inst/libs/x64/tkogl2.dll` — MSVC Release artifact deployed

## Decisions Made

- Single `simpleLog` per TAG_* error (was duplicated printf pairs)
- Fixed `simpleLog(buffer)` → `simpleLog(ogl_buffer)` in TAG_SURF nSurfaces log (pre-existing bug adjacent to cleanup)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TAG_SURF logged wrong buffer**
- **Found during:** Task 1 (TAG_SURF error port)
- **Issue:** `sprintf(ogl_buffer, ...)` followed by `simpleLog(buffer)` logged stale line content
- **Fix:** Changed to `simpleLog(ogl_buffer)`
- **Files modified:** `ogl_model_ply_ZARF_9.c`
- **Committed in:** `2952378`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Correctness fix within edited lines; no scope creep.

## Issues Encountered

- `cmake` not on default PATH — used VS 2022 bundled CMake successfully
- UNC path MSBuild warnings (MSB8064/8065) — non-blocking; build succeeded

## User Setup Required

None — DLL already deployed to `inst/libs/x64/tkogl2.dll`.

## Next Phase Readiness

- **09-03** can proceed after D-05 human reload smoke passes on both fixtures
- Rollback: restore `inst/libs/x64/tkogl2.dll.bak` or `.pre-phase9.bak` if mesh/reload regresses

## Self-Check: PASSED

- FOUND: integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ply_ZARF_9.c
- FOUND: integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ZARF_9.c
- FOUND: integrated-guimorph-development_EOC/Project/tkogl2/src/curve_ZARF_9.c
- FOUND: integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c
- FOUND: .planning/phases/09-c-engine-cleanup-validation/09-02-SUMMARY.md
- FOUND: commit 2952378
- FOUND: commit 80c2799

---
*Phase: 09-c-engine-cleanup-validation*
*Completed: 2026-06-22 (code + build; human smoke pending)*
