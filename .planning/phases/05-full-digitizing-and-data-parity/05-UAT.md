---
status: testing
phase: 05-full-digitizing-and-data-parity
source: [05-VERIFICATION.md]
started: 2026-08-07T16:45:00Z
updated: 2026-08-07T16:45:00Z
---

## Current Test

number: 1
name: Live browser digitizing interactions (DGT-01/DGT-02)
expected: |
  Anchors render green in a non-raycast group; curve recolor is cyan then blue
  then commit; overlays follow the correct specimen after a switch and picks
  land on the newly loaded mesh (BVH rebuilt).
awaiting: user response

## Tests

### 1. Live browser digitizing interactions (DGT-01/DGT-02)
expected: On a display host, launch a viewport, place anchors (green dots), define a curve by clicking three placed landmark dots (first cyan, second blue slider, third completes), display + delete a surface semilandmark, undo, and switch specimens. Anchors render green in a non-raycast group; curve recolor is cyan→blue→commit; overlays follow the correct specimen after a switch and picks land on the newly loaded mesh (BVH rebuilt).
result: [pending]

### 2. Live surface semilandmark COMPUTE end-to-end (DGT-02 / full-workflow)
expected: Trigger /downsample from the browser against a loaded specimen; the TPS warp runs and a THREE.Points surface cloud appears in the viewport.
result: [pending]
note: KNOWN STUB — `.gmw_downsample_session` reads `rec$specimen` (3dDigitize.surface.r:605) but no serve/route path populates `.gmw_session[[token]]$specimens[[cur]]$specimen`. Live `/downsample` currently no-ops (try()-wrapped 204). Wire the served PLY vertices into the session `specimen` slot before verifying.

### 3. Live browser-driven GPA + .csv/.rds export (DGT-03)
expected: On a display host with geomorph installed, run GPA over real multi-specimen session data and export .csv/.rds. geomorph::gpagen runs, result plots route through .gmw_view3d, and .csv/.rds files are written via the existing save()/exportGeomorph().
result: [pending]

### 4. Live native-GUI-vs-browser dual-path DAT-01 run (corroborating)
expected: On a Windows tkogl2 host, save the same session through the native GUI and the browser path; both .dgt files are byte-identical (raw md5).
result: [pending]
note: The automated R-level write-vs-write byte-identity gate is the PRIMARY proof and already PASSES; this is corroborating field evidence.

### 5. DAT-02 bidirectional -rewrite byte gate + reader-accepts-both-dialects
expected: Opening tests/fixtures/parity/windows-authored-roundtrip.dgt and mac-authored-roundtrip.dgt in GUImorphWeb and re-saving reproduces the authored bytes (per dat-parity-gate-is-a-skip.md); a GUImorphWeb-authored .dgt opens correctly in GUImorph.
result: [pending]
note: The two -rewrite fixtures require a Windows re-save (not present on disk), so the DAT-03 gate skips cleanly. The macOS→Windows leg is an open UPSTREAM dependency. DAT-02 is [ ] incomplete in REQUIREMENTS.md.

### 6. CMP-01 native oracle RUNTIME load
expected: On a Windows host with the built tkogl2 engine, confirm `.gmw_engine$ok == TRUE` after library(GUImorphWeb). The native oracle stays loadable through Phase 5 (retired at Phase 6).
result: [pending]
note: Source invariant (transport.R and 3dDigitize.main.r never assign/read .gmw_engine) is verified; skip-if-absent gate is clean everywhere. Tracked in pick03-windows-parity-capture-owed.md.

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
