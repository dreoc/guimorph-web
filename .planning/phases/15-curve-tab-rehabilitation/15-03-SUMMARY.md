---
phase: 15-curve-tab-rehabilitation
plan: 03
subsystem: docs
tags: [readme, copywriting, curves, tab-gating, ux-crv-02]

requires:
  - phase: 15-curve-tab-rehabilitation
    plan: 02
    provides: Implemented spinboxes, Compute, Reset view, undo, gating messages
provides:
  - "README §4 and Known quirks aligned with shipped Curves UX (D-17–D-20)"
  - "Keyboard shortcuts dialog includes curve segment undo scope (D-19)"
affects: []

tech-stack:
  added: []
  patterns:
    - "README follows implementation for Curves tab copy contract"
    - "Grep parity audit between README and R string literals"

key-files:
  created: []
  modified:
    - README.md
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r

key-decisions:
  - "README landmark-only unlock wording for Surface/Curves/GPA; Anchors unlock on specimen load"
  - "Ctrl+F stays Fit view in shortcuts dialog; parenthetical notes Curves Reset view button (RESEARCH A4)"
  - "In-app curve labels and gating messages already matched README — no R label changes required"

requirements-completed: [UX-CRV-02]

duration: 20min
completed: 2026-06-26
---

# Phase 15 Plan 03: README and In-App Copy Reconciliation Summary

**README §4 and Known quirks document spinbox Curves workflow; keyboard shortcuts dialog synced for curve-segment undo (D-17–D-20)**

## Performance

- **Duration:** 20 min
- **Started:** 2026-06-26T03:00:00Z
- **Completed:** 2026-06-26T03:20:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced README §4 with Total curves / Current curve spinboxes, Compute Curves, Reset view, and simplified 3-landmark-per-segment description (D-17, D-20)
- Updated README Known quirks and workflow intro for v1.1 landmark-only tab gating on current specimen; revised Place Anchors and Fit/Reset view bullets (D-18)
- Grep audit across `R/` found zero stale modal strings; updated Help → Keyboard Shortcuts dialog Ctrl+Z and Ctrl+F lines (D-19)
- **Copy parity: PASS** — `e$curveDescLabel`, spinbox labels, Compute/Reset view buttons, tab 3 hint, and `switchTab` gating messages already matched UI-SPEC; only shortcuts dialog required change

## Task Commits

Each task was committed atomically:

1. **Task 1: README §4 and full v1.1 accuracy pass** - `5f7f26d` (docs)
2. **Task 2: In-app text sync audit and Help dialog update** - `433ae40` (docs)

## Files Created/Modified

- `README.md` — §4 Curves workflow, Known quirks gating, Place Anchors note, Fit/Reset view quirk
- `R/3dDigitize.main.r` — `showShortcutsDialog` Ctrl+Z curve segment scope; Ctrl+F Reset view parenthetical

## Decisions Made

- Left `updateStepLabel` unchanged — curves remain optional outside the 3-step flow (CONTEXT discretion)
- No changes to `3dDigitize.curve.r` labels — plan 01/02 already implemented UI-SPEC exact copy

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Executor shell unavailable for direct git; commits completed via shell subagent on `ui-modernization` branch

## User Setup Required

None - documentation-only changes.

## Next Phase Readiness

- Phase 15 UX-CRV-02 documentation contract complete; manual Windows UAT can verify README against live Curves tab
- `.dgt` curve matrix round-trip unchanged (no format edits this plan)

## Self-Check: PASSED

- FOUND: README.md (Total curves, Compute Curves, Reset view, 3-landmark description)
- FOUND: integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r (curve segment in Ctrl+Z line)
- FOUND: commit 5f7f26d
- FOUND: commit 433ae40

---
*Phase: 15-curve-tab-rehabilitation*
*Completed: 2026-06-26*
