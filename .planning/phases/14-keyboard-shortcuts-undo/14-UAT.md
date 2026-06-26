---
status: complete
phase: 14-keyboard-shortcuts-undo
source: [14-VERIFICATION.md]
started: 2026-06-26
updated: 2026-06-26
---

## Current Test

[testing complete]

## Tests

### 1. Global accelerators from all tabs
expected: Load/save/fit/nav shortcuts fire from any tab regardless of widget focus; nav shortcuts show same warnings as buttons when gating blocks navigation.
result: pass

### 2. Undo round-trip (place / delete / drag)
expected: Place landmark → Ctrl+Z; delete landmark → Ctrl+Z; drag landmark → Ctrl+Z. Repeat on Anchors tab. Marker state reverses; status bar shows correct Undid … message; counts update.
result: pass (drag undo fixed: store release screen for re-selection)

### 3. Spinbox Ctrl+Z override
expected: Focus landmark count spinbox, place landmark, Ctrl+Z — placement undone, not spinbox text undo.
result: pass

### 4. Specimen switch clears undo stack
expected: Place landmark, navigate Next/Previous/jump combobox, Ctrl+Z — status shows "Nothing to undo".
result: pass

### 5. File reload clears undo stack
expected: Place landmark, reload PLY or DGT, Ctrl+Z — "Nothing to undo".
result: pass

### 6. Help dialog discoverability
expected: Help → Keyboard Shortcuts lists six shortcuts with gating note; File menu has no accelerator suffixes; hintLabel unchanged.
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
