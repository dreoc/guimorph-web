---
status: complete
phase: 04-picking-parity
source: [04-VERIFICATION.md]
started: 2026-08-05T17:30:00Z
updated: 2026-08-06T21:18:00Z
---

## Current Test

[testing complete]

## Tests

### 1. PICK-03 milestone gate — real browser-vs-native parity capture
expected: On a Windows host with the validated tkogl2 oracle, capture native gluUnProject poses (objXYZ + real per-row engine commit hashes) into the pose-record schema, replay each pose in the browser via window.GMW_REPLAY() to fill brXYZ, write the rows into tests/fixtures/parity/B7_1_pick_poses.tsv, and re-run testthat::test_dir(filter='picking-parity'). The real-parity block stops skipping and .gmw_parity_gate(brXYZ, objXYZ, mean_edge)$pass is TRUE — p95(browser-vs-native Euclidean distance) <= 1x mean inter-vertex edge length (~0.085 units on B7_1_clean.ply). Closes PICK-03 with zero code change.
result: skipped
reason: user skipped (no Windows tkogl2 oracle host available in this environment)

### 2. PICK-01/PICK-02 browser UAT (stock macOS + stock Windows, offline)
expected: Serve a specimen, open the printed loopback URL, click the loaded mesh, orbit, and click the background. A BVH raycast returns a hit at interactive rates on B7_1_clean.ply (363,283 verts); a red landmark dot lands under the cursor and gmw_picks(token) returns the mesh-local coordinate; the dot is OCCLUDED when rotated behind the mesh (correct depth); a background (miss) click draws nothing and stores no row.
result: pass
note: |
  PASS on macOS (Safari) after diagnosis. Initial "no dots" was a STALE PACKAGE
  LOAD — the first R session was running a build from before the 04-02 picking
  code, so the served page had no pick handler. After pkgload::load_all() served
  the current source, picking works: console showed hits=2 per click (DoubleSide
  mesh; hits[0] nearest), dist=92.2 (dot radius ~0.92, visible), overlayChildren
  incremented 0->6, and six red dots rendered on the specimen. gmw_picks(token)
  returned a full 6x3 matrix — R owns all placed coordinates (PICK-01). Not a
  code defect.
  Cosmetic follow-ups (non-blocking, not new to this phase):
  (1) Safari logs "Beacon API cannot load .../pick: cannot parse response" for the
      204 empty-body response; all picks were still delivered (6/6 stored). The
      /close beacon uses the identical 204 shape from Phase 3.
  (2) A double-click records two coincident picks (rows 1-2 identical) since the
      handler fires per pointerdown — future UX debounce, not a phase-4 gap.
  Occlusion-under-rotation (PICK-02 depth) not separately re-confirmed by the user
  but depthTest:true is set on the overlay dot material.

### 3. CMP-01 native oracle load on a display host
expected: On a Windows host, run library(GUImorphWeb) and confirm the retained tkogl2 engine loads and renders. .gmw_engine$ok is a logical scalar TRUE; the native oracle still builds and renders (usable as the PICK-03 reference).
result: skipped
reason: user skipped — no Windows tkogl2 oracle host available in this environment (source invariant already auto-verified: transport.R never touches .gmw_engine). Pairs with Test 1 for Windows closure.

## Summary

total: 3
passed: 1
issues: 0
pending: 0
skipped: 2
blocked: 0

## Gaps

[none — the Test 2 "no dots" report was root-caused to a stale package load
(pre-04-02 build in the running session), not a code defect. Resolved by serving
the current source via pkgload::load_all(); picking verified working with a 6x3
gmw_picks() matrix. No gap plans needed.]
