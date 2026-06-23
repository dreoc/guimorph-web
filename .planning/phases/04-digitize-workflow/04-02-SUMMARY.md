---
phase: 04-digitize-workflow
plan: 02
subsystem: digitize
tags: [r, tcl-tk, curves, landmarks, dgt]

requires:
  - phase: 04-01
    provides: double-click landmark placement (DGT-01)
provides:
  - loadPly curve slot [[4]] initialized as empty 3-column matrix
  - validated legacy curve bind workflow (3 landmark IDs → 1 curve row)
  - Phase 4 curve smoke findings in smoke-test-findings.md
affects: [04-03 save/reload]

tech-stack:
  added: []
  patterns:
    - "activeDataList[[1]][[4]] stores curve rows as nrow×3 integer landmark ID matrix"
    - "Legacy curve bind: double-click 3 existing landmarks on Curves tab"

key-files:
  created: []
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
    - .planning/smoke-test-findings.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "D-04 Fit smoke pass: no crash required; visible view reset only when rotation/zoom non-zero"
  - "Chord-segment curve display and no-op Fit at default view documented as UX quirks (D-12), not blockers"

patterns-established:
  - "Curve slot [[4]] must be matrix-compatible before onSelectCurve rbind"

requirements-completed: [DGT-02]

duration: 45min
completed: 2026-06-15
---

# Phase 04 Plan 02: Curve Definition Summary

**Fixed loadPly curve slot init and validated legacy 3-landmark curve bind on C13.1.ply with documented UX quirks.**

## Performance

- **Duration:** ~45 min (includes human UAT)
- **Completed:** 2026-06-15
- **Tasks:** 3/3 complete
- **Files modified:** 3

## Accomplishments

- Replaced `list()` with `matrix(nrow = 0, ncol = 3)` for curve slot `[[4]]` in `loadPly` — unblocks first `rbind` in `onSelectCurve`
- Human UAT on Windows R: 3 landmarks, 1 curve row (IDs 1, 2, 3), no crash on bind or Fit
- Documented chord-segment rendering and no-op Fit behavior in smoke-test-findings.md

## Task Commits

1. **Task 1: Fix curve slot [[4]] initialization** - `9d6b647` (feat)
2. **Task 2: Validate curve workflow (DGT-02)** - human UAT approved 2026-06-15 (no separate commit)
3. **Task 3: Document findings + DGT-02** - (this commit)

## Files Created/Modified

- `R/3dDigitize.main.r` — `loadPly` curve slot matrix init
- `.planning/smoke-test-findings.md` — Phase 4 curve section + quirks
- `.planning/REQUIREMENTS.md` — DGT-02 marked complete

## Deviations from Plan

None blocking. User reported:
- Curve draws straight chord segments (expected legacy; Compute Curves dormant per D-01)
- Fit has no visible effect at default view (expected — `onFit` resets angle/zoom to 0)

## Self-Check: PASSED

- loadPly matrix init present
- DGT-02 validated in REQUIREMENTS.md
- smoke-test-findings.md Phase 4 section appended

## Requirements Completed

- **DGT-02** — legacy curve definition via 3 landmark double-clicks on Curves tab
