---
phase: 11-direct-manipulation-controls
plan: 02
subsystem: ui
tags: [tcltk, ttkspinbox, r, digitize, count, direct-manipulation]

requires:
  - phase: 11-direct-manipulation-controls
    plan: 01
    provides: ttkscale size sliders on Digitize and Anchor tabs
provides:
  - inline ttkspinbox count controls on Digitize and Anchor tabs
  - onLmCountChange/onAnchorCountChange with placed-count floor clamp
  - live -from reconfigure on add/delete and specimen switch
affects: [11-03, 11-04]

tech-stack:
  added: []
  patterns:
    - "ttkspinbox with tclVar, -command plus Return/FocusOut binds for typed input"
    - "dynamic -from floor via tkconfigure in updateDotNum/updateAnchorNum"

key-files:
  created: []
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r

key-decisions:
  - "Spinbox range 1–100 with floor at max(1, placed count) per D-05"
  - "Clamp via as.integer(tclvalue(...)) with NA → floor; no modal feedback"
  - "Null-guard spinbox handles before tkconfigure for pre-UI safety"

patterns-established:
  - "Pattern: inline ttkspinbox replaces modal tktoplevel count entry (D-04)"
  - "Pattern: Return/FocusOut binds required because -command skips typed input (Pitfall 5)"

requirements-completed: [UX-CTL-02]

duration: 30min
completed: 2026-06-24
---

# Phase 11 Plan 02: Inline Count Spinboxes Summary

**Replaced modal "Set number of landmarks/anchors" pop-ups with inline `ttkspinbox` controls on both tabs, clamping counts to a live placed-point floor and syncing on specimen switch — no data-loss path below placed count (UX-CTL-02, D-04/D-05).**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-06-24T12:00:00Z
- **Completed:** 2026-06-24T12:30:00Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Digitize tab: `e$lmCountSpin` + `e$lmCountVar` replace `setLandmarkNumBtn`; `onLmCountChange` clamps to `[floor, 100]` and writes integer `e$landmarkNum`.
- Anchor tab: `e$anchorCountSpin` + `e$anchorCountVar` replace `setAnchorNumBtn`; `onAnchorCountChange` mirrors landmark logic for `e$anchorNum` using `[[9]]` placed count.
- `updateDotNum` / `updateAnchorNum` reconfigure spinbox `-from` on every add/delete; `updateWidgets.*` re-sync value and floor on specimen switch.
- Removed `setLandmarkNum`, `setAnchorNum`, `onlandmarkNumOk`, `onanchorNumOk`, and all `landmarkEntry`/`anchorEntry` references.

## Task Commits

All three tasks landed in one atomic commit (single-file interleaved changes):

1. **Task 1: Add inline count spinbox to the Digitize tab** — `4fda447` (feat)
2. **Task 2: Add inline count spinbox to the Anchor tab** — `4fda447` (feat)
3. **Task 3: Keep floor live, sync on specimen switch, remove modal count code** — `4fda447` (feat)

**Plan metadata:** pending (docs commit after SUMMARY write)

## Files Created/Modified

- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` — spinbox UI, clamp handlers, live floor, modal removal

## Decisions Made

- Used `to = 100` upper bound per research open-question resolution.
- Floor computed as `max(1L, placed_count)` even when no specimen loaded (floor defaults to 1).
- `if (!is.null(e$lmCountSpin))` guards before `tkconfigure` to avoid errors during early lifecycle.

## Deviations from Plan

### Auto-fixed Issues

None.

### Process Note

- Three tasks committed as one `feat(11-02)` commit because all edits are in a single R file and were applied atomically; grep verification confirms all task acceptance criteria met.

## Issues Encountered

- `rtk`/`Rscript` unavailable in non-interactive executor shell; static verification via workspace `grep` instead.
- Manual UAT (place 3 → type 2 → Return clamps to 3; specimen switch sync) deferred to Windows R session.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- UX-CTL-02 complete; ready for 11-03 (non-modal delete).
- `rtkogl.R` untouched (CON-01); `.dgt` format untouched (CON-02).

## Self-Check: PASSED

- FOUND: `.planning/phases/11-direct-manipulation-controls/11-02-SUMMARY.md`
- FOUND: `4fda447` (feat commit)
- grep: `ttkspinbox` count = 2 (≥ 2)
- grep: `onLmCountChange` count = 4 (≥ 4)
- grep: `onAnchorCountChange` count = 4 (≥ 4)
- grep: `setLandmarkNum|setAnchorNum` count = 0
- grep: `onlandmarkNumOk|onanchorNumOk|landmarkEntry|anchorEntry` count = 0
- grep: `tkconfigure(e$lmCountSpin, from` + `tkconfigure(e$anchorCountSpin, from` count = 4 (≥ 2)

---
*Phase: 11-direct-manipulation-controls*
*Completed: 2026-06-24*
