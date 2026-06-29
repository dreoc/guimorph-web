---
status: complete
phase: 11-direct-manipulation-controls
source: 11-01-SUMMARY.md, 11-02-SUMMARY.md, 11-03-SUMMARY.md, 11-04-SUMMARY.md
started: 2026-06-24T00:00:00Z
updated: 2026-06-29T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Live Size Slider Drag
expected: Load a PLY on Digitize tab; drag the size slider; switch to Anchor tab and repeat. Dot/anchor radius changes smoothly while dragging; at default 0.01 the specimen looks identical to pre-phase behavior.
result: pass

### 2. Specimen Switch Widget Sync
expected: Load two specimens with different stored sizes; use Next/Previous navigation. Size slider thumb and spinbox values jump to each specimen's stored size.
result: pass

### 3. Count Floor Clamp
expected: Place 3 landmarks; type 2 in the count spinbox; press Return. Repeat on Anchor tab with placed anchors. Value clamps to placed count (3); no modal window appears.
result: pass

### 4. Immediate Right-Click Delete
expected: Right-click a placed landmark on Digitize tab; then right-click a placed anchor on Anchor tab. Point vanishes immediately; count label decrements; tab gating updates; no confirm window.
result: pass

### 5. Responsive Viewport Resize
expected: Load a PLY; drag the main window edge larger then smaller; observe startup before any resize. GL viewport enlarges/shrinks after drag settles (~150ms); no blank viewport on startup.
result: pass

### 6. .dgt Round-Trip (CON-02)
expected: Load verify_.dgt; change size and count (no deletes); Save to DGT; diff LM3=/AC3= blocks vs original. LM3=/AC3= blocks identical to original.
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None — UAT approved at v1.1 milestone close (2026-06-29).
