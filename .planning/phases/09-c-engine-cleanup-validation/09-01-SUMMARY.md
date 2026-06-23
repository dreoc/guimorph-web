---
phase: 09-c-engine-cleanup-validation
plan: 01
subsystem: c-engine
tags: [tkogl2, msvc, ceng-03, globals, fixed-capacity-arrays]

# Dependency graph
requires:
  - phase: 08-c-engine-deduplication
    provides: marker.c unification, MSVC build baseline, pre-phase8.bak convention
provides:
  - GBL_PTR_MODEL/CONTEXT/CURVE fixed-capacity arrays with documented #define slots
  - GBL_LANDMARK_SET_CAPACITY and GBL_CURVE_SET_CAPACITY renamed capacity macros
  - tkogl2.dll.pre-phase9.bak rollback artifact (D-15)
  - Fresh MSVC tkogl2.dll deployed with Tkogl2_Init export verified
affects: [09-02, 09-03, 09-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fixed-capacity global arrays with GBL_*_SLOTS #defines in tcl_state.h (D-01)"
    - "Pre-phase rollback backup convention: tkogl2.dll.pre-phase9.bak (D-15)"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll.pre-phase9.bak
  modified:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.h
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll

key-decisions:
  - "Numbered GBL_PTR_*_N globals replaced with GBL_PTR_MODEL/CONTEXT/CURVE arrays — behavior preserved including curve-index bug (D-02)"
  - "MSVC build run from Windows PowerShell via VS 2022 dev shell on UNC path (WSL cmake cannot drive VS generator)"
  - "Dead commented assignment ladders removed as CENG-04 prep without reviving as live loops"

patterns-established:
  - "Capacity #defines co-located with array externs in tcl_state.h"
  - "Curve cluster preserves whichCurve==1 and whichCurve==3 both assigning GBL_PTR_CURVE[1] (D-02)"

requirements-completed: [CENG-03]

# Metrics
duration: 35min
completed: 2026-06-22
---

# Phase 9 Plan 01: CENG-03 Globals Array-ification Summary

**Numbered GBL_PTR_* pointer families replaced with documented fixed-capacity arrays; MSVC DLL rebuilt, export verified, and deployed with Jun 22 freshness banner**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-06-22T18:30:00Z
- **Completed:** 2026-06-22T19:10:00Z (all tasks; human smoke approved 2026-06-22)
- **Tasks:** 3/3 complete
- **Files modified:** 5

## Accomplishments

- Pre-Phase-9 deployed DLL backed up as `tkogl2.dll.pre-phase9.bak` (313,344 bytes, D-15)
- Three numbered pointer families array-ified with `GBL_MODEL_SLOTS`, `GBL_CONTEXT_SLOTS`, `GBL_CURVE_SLOTS` capacity defines
- `CONST_25`/`CONST_10` renamed to `GBL_LANDMARK_SET_CAPACITY`/`GBL_CURVE_SET_CAPACITY`; optional `GBL_DELTAS_CAPACITY 1000` added
- MSVC Release build green; `Tkogl2_Init` export confirmed; fresh DLL deployed with `FRESH BUILD Jun 22 2026 19:07:27` banner

## Task Commits

Each automated task was committed atomically:

1. **Task 1: Back up deployed DLL (D-15)** - `ec92da4` (feat)
2. **Task 2: Array-ify numbered global families (CENG-03)** - `e08e588` (feat)
3. **Task 3: Export check, deploy (automated portion)** - `52f0296` (feat)

**Plan metadata:** skipped (orchestrator handles STATE/ROADMAP)

## Files Created/Modified

- `inst/libs/x64/tkogl2.dll.pre-phase9.bak` - D-15 rollback backup of pre-refactor deployed DLL
- `tkogl2/src/tcl_state.h` - Capacity #defines + array externs replacing 16 numbered externs
- `tkogl2/src/tcl_state.c` - Array definitions; `snapshot()` reads `GBL_PTR_MODEL[0]`; dead commented blocks removed
- `tkogl2/src/tcl_dispatch.c` - Curve cluster array-ified with D-02 bug comment; dead ladders removed
- `inst/libs/x64/tkogl2.dll` - Fresh MSVC Release build deployed

## Decisions Made

- Preserved pre-existing curve-index bug verbatim (CURVE_2 double-assign, CURVE_3 read-but-unassigned) per D-02
- `def_ZARF_9.h` left byte-unchanged; `GBL_PTR_TO_A_MODEL` unchanged
- MSVC build executed from Windows VS 2022 dev shell on `\\wsl.localhost\Ubuntu\...` UNC path

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] MSVC build path mismatch**
- **Found during:** Task 2 verification (MSVC build)
- **Issue:** `cmake --build build-msvc` from WSL bash failed — CMakeCache created from Windows UNC path, VS generator unavailable in WSL
- **Fix:** Ran build from Windows PowerShell with VS 2022 Dev Shell loaded
- **Verification:** BUILD_EXIT=0; `tcl_state.c` recompiled; fresh DLL at 19:07:29
- **Committed in:** `52f0296` (Task 3 deploy commit)

**2. [Timing] Task 1 backup after orchestrator pre-edited source**
- **Found during:** Task 1
- **Issue:** Plan requires backup before source edits; orchestrator had already modified `tcl_state.*`/`tcl_dispatch.c`
- **Fix:** Backup taken from deployed `tkogl2.dll` (pre-rebuild, Phase 8-era binary) before MSVC rebuild — correct rollback target
- **Verification:** Backup and source DLL both 313,344 bytes at backup time
- **Committed in:** `ec92da4`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 timing/order)
**Impact on plan:** No behavior change; rollback artifact and build both correct.

## Issues Encountered

- WSL `cmake` cannot drive Visual Studio 17 2022 generator — resolved by Windows-side build per BUILD.md
- MSB8064/MSB8065 casing warnings on CMake stamp dependencies (pre-existing, non-blocking)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CENG-03 source refactor complete; DLL deployed and export-verified
- Task 3 human smoke approved (window open, C13.1.ply render, landmark double-click)
- Ready for 09-02 debug-cruft removal

## Self-Check: PASSED

- FOUND: `tkogl2.dll.pre-phase9.bak`
- FOUND: `tcl_state.h`
- FOUND: commit `ec92da4`
- FOUND: commit `e08e588`
- FOUND: commit `52f0296`
- SUMMARY written at `.planning/phases/09-c-engine-cleanup-validation/09-01-SUMMARY.md`

---
*Phase: 09-c-engine-cleanup-validation*
*Completed: 2026-06-22 (human smoke approved)*
