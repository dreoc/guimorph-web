---
status: testing
phase: 05-retina-picking-input-fixes-digitizing-analysis-data-parity
source: [05-VERIFICATION.md]
started: 2026-07-18T23:10:00Z
updated: 2026-07-18T23:10:00Z
---

## Current Test

number: 1
name: DAT-03 macOS->Windows return-leg confirmation
expected: |
  The macOS-authored .dgt (pushed to Erik) opens correctly on Windows —
  landmarks, anchors, curves, and surfaces intact — and round-trips without
  byte-contract drift. This closes the second half of the DAT-03 bidirectional gate
  (the Windows->macOS half is already verified).
awaiting: user response

## Tests

### 1. DAT-03 macOS->Windows return-leg confirmation
expected: Mac-authored .dgt opens on Windows with all data intact and round-trips byte-clean.
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
