---
phase: 09-c-engine-cleanup-validation
plan: 04
subsystem: validation
tags: [uat, ceng-05, smoke-test, build-docs]

requires:
  - phase: 09-03
    provides: fully cleaned C engine DLL deployed
provides:
  - Phase 9 UAT results for Fixture A and Fixture B in smoke-test-findings.md
  - BUILD.md final module-layout table (D-14)
affects: []

key-files:
  created: []
  modified:
    - .planning/smoke-test-findings.md
    - BUILD.md

requirements-completed: [CENG-05]

duration: 30min
completed: 2026-06-22
---

# Phase 09 Plan 04: Full Regression UAT + BUILD.md Summary

**Both fixtures passed manual UAT; Phase 9 acceptance gate satisfied; BUILD.md reflects final cleaned module layout.**

## Performance

- **Duration:** ~30 min (human UAT driven)
- **Tasks:** 3/3 complete
- **Files modified:** 2 (docs only)

## Accomplishments

- Fixture A full round-trip (`test_fresh.dgt`): PLY load → landmarks → curve → save → reload → GPA → CSV — Phase 4-5 baseline parity (D-09)
- Fixture B anchor round-trip (`test_dgt_anchors_curves.dgt`): load → anchor/landmark ops → re-save/reload — Phase 8 baseline parity (D-10)
- `Surface=0` reload does not abort on either fixture (D-05 confirmed post-cleanup)
- Phase 9 section recorded in `smoke-test-findings.md` with date, freshness banner, rollback DLL name
- `BUILD.md` module-layout table updated; `tcl_if_ZARF_9.c` build refs pruned; MSVC-only retained (D-14)

## Task Commits

1. **Task 1: Fixture A UAT + record** — human-approved 2026-06-22
2. **Task 2: Fixture B UAT + record** — human-approved 2026-06-22
3. **Task 3: BUILD.md module layout** — updated during wave 4 execution

## User Setup Required

None.

## Self-Check: PASSED

- FOUND: `.planning/smoke-test-findings.md` Phase 9 section with both fixture tables
- FOUND: `BUILD.md` with `tcl_dispatch`, `tcl_state`, `tcl_log`, `marker` modules listed
- No `tcl_if_ZARF_9.c` as build source in BUILD.md

---
*Phase: 09-c-engine-cleanup-validation*
*Completed: 2026-06-22*
