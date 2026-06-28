---
quick_id: 260627-w5c
slug: simplify
status: complete
---

# Quick Task 260627-w5c: Simplify curve tab UI

**Completed:** 2026-06-28

## What changed

- Removed Total curves / Current curve spinboxes and Compute Curves button from Curves tab
- Kept description label and Reset view button only
- Removed max-curve enforcement and spinbox sync helpers (`.clampCurve*`, `syncCurveSpinboxes`, `onComputeCurves`)
- Auto-draw on 3rd landmark double-click unchanged; Ctrl+Z curve undo and tab-switch redraw preserved via `.redrawAllCurves` / `.clearAllCurves`
- Status hint simplified to static "Double-click 3 landmarks per curve segment"

## Files modified

- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.curve.r`
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r`

## Deferred (per user)

- UAT-15 doc updates, README, GSD phase artifacts
