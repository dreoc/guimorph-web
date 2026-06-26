---
status: testing
phase: 13-guided-workflow-discoverability
source: [13-VERIFICATION.md]
started: 2026-06-25
updated: 2026-06-25
---

## Current Test

number: 1
name: Unlock-on-load tab gating
expected: |
  Load a PLY; Anchors tab is enabled immediately without placing landmarks or checking Place Anchors.
  GPA tab remains disabled until all landmarks are placed on the current specimen.
awaiting: user response

## Tests

### 1. Unlock-on-load tab gating
expected: Anchors enabled on load; GPA gated on current-specimen landmark completion
result: [pending]

### 2. Disabled-tab click-to-explain
expected: Clicking disabled tabs shows sentence-case status message without switching tabs
result: [pending]

### 3. Step label progression
expected: Step label above notebook updates through Step 1/2/3 copy as gating state changes
result: [pending]

### 4. Placement hint visibility
expected: Hint shows on Digitize/Anchor tabs (including immediately after load); empty on Surface/Curves/GPA
result: [pending]

### 5. Jump-to combobox navigation
expected: Title shows Specimen N of M; combobox lists index:basename; guards block jump with warning and re-sync
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
