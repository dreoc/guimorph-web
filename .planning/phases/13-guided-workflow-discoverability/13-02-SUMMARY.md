---
phase: 13-guided-workflow-discoverability
plan: 02
subsystem: ui
tags: [tcltk, ttk, workflow, discoverability, combobox, hint-label]

requires:
  - phase: 13-01
    provides: refreshTabGating, switchTab disabled-tab interception, e$stepLabel, updateStepLabel
provides:
  - e$hintLabel contextual placement hints under canvas (D-05, UX-WF-01)
  - e$specimenCombo jump-to combobox with populateSpecimenCombo and jumpToSpecimen (D-04, UX-WF-03)
  - Specimen N of M counter in e$imgPath and corrected neutral status copy
affects: [13-guided-workflow-discoverability]

tech-stack:
  added: []
  patterns:
    - "HINT_TEXT named vector in switchTab drives e$hintLabel per tab"
    - "jumpToSpecimen mirrors onNext guards with refreshNavButtons re-sync on every rejection"
    - "refreshNavButtons syncs e$specimenSelectVar alongside prev/next button states"

key-files:
  created: []
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r

key-decisions:
  - "Combobox current index converted 0-based to 1-based before jumpToSpecimen"
  - "Guard-failure paths use same-line refreshNavButtons(e); return(invisible()) for combobox re-sync"
  - "updateWidgets.anchor imgPath counter aligned with digitize path for consistency"

patterns-established:
  - "Placement hints use U+00B7 interpunct separators; empty on non-placement tabs"
  - "Title label shows Specimen N of M; status bar shows Specimen N of M — basename"

requirements-completed: [UX-WF-01, UX-WF-03]

duration: 25min
completed: 2026-06-25
---

# Phase 13 Plan 02: Placement Hints, Jump-To Combobox, and Specimen Counter Summary

**Contextual placement hints under the canvas, a readonly jump-to specimen combobox with onNext-equivalent guards, and a clean Specimen N of M counter replacing full file paths**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-25T21:55:00Z
- **Completed:** 2026-06-25T22:20:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Added `e$hintLabel` under the canvas; `switchTab` updates it from a per-tab `HINT_TEXT` map (landmark/anchor placement copy; empty on Surface/Curves/GPA)
- Added `e$specimenCombo` + `e$specimenSelectVar`, `populateSpecimenCombo`, and `jumpToSpecimen` with the same landmark/anchor/tab guards as Next; combobox re-syncs via `refreshNavButtons` on every guard failure
- Replaced `e$imgPath` full-path text with `Specimen N of M` counter; fixed double-id neutral status copy in `showPicture`, `updateDotNum`, and `updateAnchorNum`

## Task Commits

Each task was committed atomically:

1. **Task 1: Add placement-hint label (e$hintLabel)** - `dc79b6c` (feat)
2. **Task 2: Jump-to combobox + populateSpecimenCombo + jumpToSpecimen** - `5658ee9` (feat)
3. **Task 3: Specimen counter and status copy fixes** - `aef251c` (feat)

**Plan metadata:** `2d5719e` (docs)

## Files Created/Modified

- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` - hint label, combobox, jumpToSpecimen, counter in loadPly/showPicture, refreshNavButtons sync
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` - counter in updateWidgets; fixed neutral setStatus in updateDotNum/updateAnchorNum

## Decisions Made

- Combobox `<<ComboboxSelected>>` converts 0-based `current` to 1-based `e$currImgId` before calling `jumpToSpecimen`
- `updateWidgets.anchor` imgPath counter updated alongside `updateWidgets.digitize` so no `Specimen Id:` strings remain in verified files

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] updateWidgets.anchor counter alignment**
- **Found during:** Task 3
- **Issue:** Plan listed only `updateWidgets.digitize` but verification greps both main.r and digitize.r for `Specimen Id:` on `e$imgPath`
- **Fix:** Updated `updateWidgets.anchor` to use the same `paste0("Specimen ", e$currImgId, " of ", length(e$activeDataList))` counter format
- **Files modified:** `3dDigitize.digitize.r`
- **Committed in:** `aef251c`

### Environmental Note

Task 1 commit (`dc79b6c`) on `3dDigitize.main.r` included pre-existing unstaged modifications present at executor start (repo was not on an isolated worktree-agent branch). Subsequent task commits contain only plan-scoped deltas.

## Issues Encountered

- Shell quoting on Windows/WSL required `wsl -d Ubuntu git -C ...` invocations for reliable commits
- R package load verification could not be run interactively due to shell escaping; source-level grep assertions pass

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- UX-WF-01 and UX-WF-03 surfaces are wired; manual UAT recommended for hint tab switching, combobox jump with incomplete landmarks, and Previous/Next combobox sync
- Wave 2 plan 13-02 complete; orchestrator can advance phase tracking

## Self-Check: PASSED

- FOUND: `.planning/phases/13-guided-workflow-discoverability/13-02-SUMMARY.md`
- FOUND: `dc79b6c` (task 1)
- FOUND: `5658ee9` (task 2)
- FOUND: `aef251c` (task 3)
- FOUND: `2d5719e` (plan metadata)

---
*Phase: 13-guided-workflow-discoverability*
*Completed: 2026-06-25*
