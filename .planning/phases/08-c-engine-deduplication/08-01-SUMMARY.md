---
phase: 08-c-engine-deduplication
plan: 01
subsystem: c-engine
tags: [c, marker, tkogl2, deduplication, msvc]

requires:
  - phase: 07-c-engine-modularization
    provides: five-module tkogl2 layout (tcl_init, dispatch, window, state, log)
provides:
  - marker.h contract (marker_set_t + marker_* core prototypes)
  - tkogl2.dll.pre-phase8.bak rollback baseline (D-13)
affects: [08-02-marker-implementation, 08-03-deploy-uat]

tech-stack:
  added: []
  patterns:
    - "marker_set_t groups per-type slice list + selection state (D-02)"
    - "marker.h header-only contract; marker.c implementation deferred to 08-02"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/marker.h
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll.pre-phase8.bak
  modified: []

key-decisions:
  - "marker_set_t fields: slices, slice_id, slice_count, selected, selected_id, node_type"
  - "marker_add stamps LANDMARK/ANCHOR from s->node_type (not a per-call type arg)"
  - "Added marker_allocate_list and marker_get_with_pid for full wrapper coverage in 08-02"

patterns-established:
  - "marker.h follows tcl_log.h skeleton (#pragma once, MARKER_H guard, def_ZARF_9.h include)"
  - "Behavioral contract documented in header comment with dot_ZARF_9.c line refs (D-03/D-04/D-05)"

requirements-completed: [CENG-02]

duration: 35min
completed: 2026-06-22
---

# Phase 08 Plan 01: Interface Contract + Rollback Baseline Summary

**Pre-Phase-8 DLL backup, marker.h unified API contract, and MSVC toolchain confirmed — 08-02 unblocked.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-06-22T11:15:00Z
- **Completed:** 2026-06-22T12:30:00Z
- **Tasks:** 3/3 complete
- **Files modified:** 2 created + 1 summary

## Accomplishments

- Captured `tkogl2.dll.pre-phase8.bak` (316416 bytes, byte-identical to deployed `tkogl2.dll` via `cmp`)
- Created `marker.h` declaring `marker_set_t` and 22 `marker_*` core prototypes
- Documented D-03 anchor-fix, D-04 landmark-preservation, and D-05 logging-trim contract in header comments
- `def_ZARF_9.h`, `dot_ZARF_9.c`, `tcl_dispatch.c`, `CMakeLists.txt` untouched

## Task Commits

| Task | Name | Commit | Status |
|------|------|--------|--------|
| 1 | Back up pre-Phase-8 DLL (D-13) | `4125c58` | Done |
| 2 | Create marker.h contract | `04750ee` | Done |
| 3 | Confirm MSVC toolchain | — (human gate) | Approved — user built via `guimorph-startup.R` MSVC path with 0 errors |

## Files Created/Modified

- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll.pre-phase8.bak` — rollback/side-by-side baseline before refactor
- `integrated-guimorph-development_EOC/Project/tkogl2/src/marker.h` — `marker_set_t` struct + `marker_*` core API (declarations only)

## Decisions Made

- Used RESEARCH field names (`slices`, `slice_id`, `slice_count`) plus `node_type` for LANDMARK/ANCHOR stamping at add-time
- Added `marker_allocate_list` and `marker_get_with_pid` beyond the plan's minimum list to cover `dotAllocateList`/`dot_get_dot` wrappers in 08-02
- Preserved dot_select 0-based `id++`-after-match convention in contract comments (D-03 BUG-5/6)

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as written for Tasks 1–2.

### Execution Blockers (resolved)

**1. Worktree branch assertion (#2924)** — recovered via sequential commits on `repo-cleanup`.

## Issues Encountered

- Executor environment is the main repo on `repo-cleanup`, not an isolated `worktree-agent-*` worktree as spawn metadata expected
- Shell/PowerShell friction on Windows host; WSL subagent used for verification

## User Setup Required

None — MSVC confirmed 2026-06-22 via `cmake --build build-msvc --config Release` (guimorph-startup.R recompile path).

## Next Phase Readiness

- **08-02** unblocked — implement `marker.c`, swap CMake, delete `dot_ZARF_9.c`
- `marker.h` contract ready; rollback DLL backup on disk

## Self-Check: PASSED

- FOUND: `integrated-guimorph-development_EOC/Project/tkogl2/src/marker.h`
- FOUND: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll.pre-phase8.bak`
- FOUND: task commits `4125c58`, `04750ee`
- FOUND: MSVC human approval (user approved 2026-06-22)

---
*Phase: 08-c-engine-deduplication*
*Completed: 2026-06-22*
