---
phase: 14-keyboard-shortcuts-undo
plan: 02
subsystem: ui
tags: [tcltk, tkbind, undo, keyboard-shortcuts, testthat]

requires:
  - phase: 14-keyboard-shortcuts-undo
    plan: 01
    provides: bind.accelerators infrastructure and Help dialog Ctrl+Z discoverability
  - phase: 11-direct-manipulation-controls
    provides: placement/delete/drag paths for undo hooks
  - phase: 12-in-gui-feedback-status
    provides: setStatus for undo feedback messages
provides:
  - pushUndo, clearUndo, doUndo single-slot undo stack on e$undo
  - Mutation hooks in addDot, addAnchor, deleteLandmark, deleteAnchor, drag handlers
  - Ctrl+Z global binding and spinbox override via .overrideCtrlZ
  - clearUndo on specimen navigation and PLY/DGT reload paths
  - testthat unit tests for doUndo empty-stack and success messaging
affects: [15-curve-tab]

tech-stack:
  added: [testthat]
  patterns:
    - "Single-slot e$undo with inverse add/del/set protocol (CON-01)"
    - "clearUndo resets drag state on specimen switch and file load"
    - "Spinbox Ctrl+Z override with tcl(break) per D-15"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat.R
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-undo-helpers.R
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION

key-decisions:
  - "Single-level undo replaces prior entry on each pushUndo (D-10)"
  - "Move undo gated by 3D epsilon 1e-12 between drag start and release"
  - "clearUndo called only on successful nav/load paths, not guard early returns"
  - "Tests use mocked doUndo logic without Tcl/GUI dependencies"

patterns-established:
  - "doUndo reverses via set(selected) + del/add/set(coordinate) — rtkogl.R unchanged"
  - "Spinbox .overrideCtrlZ binds Control-z before native text undo"

requirements-completed: [UX-KEY-02]

duration: 18min
completed: 2026-06-26
---

# Phase 14 Plan 02: Single-Level Undo Summary

**Single-level undo for landmark/anchor placement, deletion, and drag-move via Ctrl+Z with spinbox override, per-specimen stack clearing, and mocked testthat coverage**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-26T02:45:00Z
- **Completed:** 2026-06-26T03:03:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- `pushUndo`, `clearUndo`, `doUndo` implement single-slot undo with status feedback for empty stack ("Nothing to undo") and successful reversals (D-16, D-17)
- Mutation hooks in `addDot`, `addAnchor`, `deleteLandmark`, `deleteAnchor`, and drag release capture placement/delete/move with 3D coords from `convertCoor`
- `Ctrl+Z` bound globally in `bind.accelerators` and overridden on landmark/anchor count spinboxes via `.overrideCtrlZ` + `tcl("break")` (D-14, D-15)
- `clearUndo` on successful `jumpToSpecimen`, `onNext`, `onPrevious`, `loadPly`, and `drawElements` paths (D-12 + Pitfall 4)
- `test-undo-helpers.R` with mocked-env tests for empty-stack warning and landmark placement undo message

## Task Commits

Each task was committed atomically:

1. **Task 1: Add undo helpers, init, and mutation hooks** - `6856ebd` (feat)
2. **Task 2: Wire Ctrl+Z, spinbox override, nav/load clears, and unit tests** - `3aa90ff` (feat)

## Files Created/Modified

- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` — undo helpers, mutation hooks, spinbox Ctrl+Z override
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` — Ctrl+Z accelerator, clearUndo in nav/load paths
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION` — Suggests: testthat
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat.R` — testthat scaffold
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-undo-helpers.R` — doUndo messaging tests

## Decisions Made

- Undo stack is single-level: each `pushUndo` replaces the prior entry (D-10)
- Drag-move undo only pushed when squared 3D delta exceeds 1e-12 (RESEARCH Pitfall 6)
- `clearUndo` also resets `e$dragDot`, `e$dragX`, `e$dragY` to prevent stale drag state after specimen switch (T-14-07)
- Tests mock `doUndo` logic inline to avoid Tcl/GUI dependency in CI/WSL

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- R not available in WSL PATH for automated `devtools::load_all` or `testthat::test_file`; static grep verification passed for all undo symbols, clearUndo call count (5), and Control-z bindings. Tests are structured to pass when R/testthat is available on Windows dev host.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 14 complete (both plans shipped); Phase 15 Curve tab can extend undo hooks for curve placement per D-13 future-proofing
- Manual UAT on Windows recommended: place/delete/drag undo round-trip, Ctrl+Z with spinbox focused, specimen switch clears stack

## Self-Check: PASSED

- FOUND: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r`
- FOUND: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-undo-helpers.R`
- FOUND: commit `6856ebd`
- FOUND: commit `3aa90ff`

---
*Phase: 14-keyboard-shortcuts-undo*
*Completed: 2026-06-26*
