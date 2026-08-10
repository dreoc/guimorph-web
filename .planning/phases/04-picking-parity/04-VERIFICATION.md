---
phase: 04-picking-parity
verified: 2026-08-05T17:25:00Z
status: passed
resolution: "Passed with acknowledged deferrals (user, 2026-08-06). PICK-01/PICK-02 confirmed by live macOS UAT (04-UAT.md Test 2). PICK-03 milestone gate and CMP-01 runtime load deferred to a Windows tkogl2 host and tracked in .planning/todos/pending/pick03-windows-parity-capture-owed.md — see acknowledged_gaps."
score: 3/5 roadmap success criteria code-verified + PICK-01/02 live-UAT-verified; PICK-03 gate + CMP-01 load deferred to Windows (acknowledged). 8/8 automatable must-have checks green.
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "PICK-03 milestone gate — real browser-vs-native parity capture. On a Windows host with the validated tkogl2 oracle, capture native gluUnProject poses (objXYZ + real per-row engine commit hashes) into the pose-record schema, replay each pose in the browser via window.GMW_REPLAY() to fill brXYZ, write the rows into tests/fixtures/parity/B7_1_pick_poses.tsv, and re-run testthat::test_dir(filter='picking-parity')."
    expected: "The real-parity block stops skipping and .gmw_parity_gate(brXYZ, objXYZ, mean_edge)$pass is TRUE — p95(browser-vs-native Euclidean distance) <= 1x mean inter-vertex edge length (~0.085 units on B7_1_clean.ply). Closes PICK-03 with zero code change."
    why_human: "Native gluUnProject capture is Windows-only and no Windows host is available in this environment (D-06). The gate is intentionally, formally OPEN; no automated check can produce the native oracle coordinates."
  - test: "PICK-01/PICK-02 browser UAT (stock macOS + stock Windows, offline). Serve a specimen, open the printed loopback URL, click the loaded mesh, orbit, and click the background."
    expected: "A BVH raycast returns a hit at interactive rates on B7_1_clean.ply (363,283 verts); a red landmark dot lands under the cursor and gmw_picks(token) returns the mesh-local coordinate; the dot is OCCLUDED when rotated behind the mesh (correct depth); a background (miss) click draws nothing and stores no row."
    why_human: "Requires a real browser + display and a loaded specimen; headless CI cannot exercise WebGL raycast rendering or judge interactive rates / visual occlusion."
  - test: "CMP-01 native oracle load on a display host. On a Windows host, run library(GUImorphWeb) and confirm the retained tkogl2 engine loads and renders."
    expected: ".gmw_engine$ok is a logical scalar TRUE; the native oracle still builds and renders (usable as the PICK-03 reference)."
    why_human: "The headless sandbox blocks on the tcltk2/rgl GUI-init and has no native engine; the positive .gmw_engine$ok check skips cleanly rather than running. Runtime load must be confirmed on a display host."
acknowledged_gaps:
  - requirement: PICK-03
    status: deferred
    reason: "Milestone parity gate requires a native gluUnProject capture on a validated Windows tkogl2 oracle; no such host available. Harness is complete and drop-in-ready — closes with zero code change once brXYZ rows land in the fixture."
    closure: ".planning/todos/pending/pick03-windows-parity-capture-owed.md"
  - requirement: CMP-01
    status: deferred
    reason: "Source invariant auto-verified (transport.R never touches .gmw_engine); only the Windows runtime load confirmation (.gmw_engine$ok == TRUE) is owed."
    closure: ".planning/todos/pending/pick03-windows-parity-capture-owed.md"
acknowledged_by: user (/gsd-verify-work 4, 2026-08-06)
---

# Phase 4: Picking Parity Verification Report

**Phase Goal:** BVH raycast returns hit coordinates matching the native `gluUnProject` result within tolerance (Picking Parity — the technical gate for the milestone).
**Verified:** 2026-08-05T17:25:00Z
**Status:** passed (with acknowledged deferrals — see Acknowledged Gaps)
**Re-verification:** UAT completed 2026-08-06 (04-UAT.md); PICK-01/02 verified live, PICK-03/CMP-01 deferred to Windows by user acknowledgment

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A BVH-accelerated raycast against the loaded mesh returns a hit coordinate to R, at interactive rates on the reference specimens (PICK-01). | ✓ VERIFIED (code) — browser interactive UAT owed | Browser: `view3d.R` eager `computeBoundsTree()` (L249), `pointerdown`→`setFromCamera`→`intersectObject(pickMesh,false)`→`updateWorldMatrix`+`worldToLocal`→relative `sendBeacon("pick", "x,y,z")` (L294-310); source-scan green. R: `.gmw_pick_handler` stores rows in server-owned `.gmw_picks`, `gmw_picks()` accessor; 30 direct-handler assertions green (204 + 1x3→2x3 append, accessor returns array). Interactive rates + live browser click → human. |
| 2 | Placement only: a landmark dot renders as overlay geometry at the returned coordinate, with correct depth behavior under rotation (PICK-02). | ✓ VERIFIED (code) — visual UAT owed | `view3d.R` sibling `overlay` group (`scene.add(overlay)`), `addOverlayDot()` builds `SphereGeometry` + `MeshBasicMaterial({depthTest:true})` at the world hit, drawn only on a hit (L186-200, L302-304); source-scan green. Visual occlusion under rotation → human. |
| 3 | **The gate.** On the same specimen at the same click position, the browser coordinate matches native `gluUnProject` within a documented tolerance, stated in mesh units and justified against inter-observer digitizing error (PICK-03). | ⚠️ HUMAN NEEDED — FORMALLY OPEN (by design) | Full R gate built + behaviorally proven on placeholder: `.gmw_mean_edge_length` (hand-checkable triangle = (2+√2)/3), `.gmw_parity_gate` (p95 ≤ 1× mean_edge, tight/spread/p95 correctness), `.gmw_read_pick_poses`, and placeholder end-to-end run against real `B7_1_clean.ply` via Rvcg — all green. Browser `GMW_REPLAY` present + source-verified. Real browser-vs-native parity requires a Windows tkogl2 capture (D-06); the real-parity block SKIPS. Closes with zero code change via `brXYZ` columns (D-07). |
| 4 | Parity holds on a HiDPI display with no backing-scale correction, since raycasting is resolution-independent. | ⚠️ HUMAN NEEDED | Design is resolution-independent: NDC from `getBoundingClientRect()` ratio (single Y-flip); `GMW_REPLAY` derives NDC by dividing by the recorded backing viewport (scale-free). Retina handling on the native side unit-covered (`test-retina-picking-parity.R` green). Actual HiDPI parity requires the real capture + a HiDPI display. |
| 5 | Native oracle still loads (CMP-01). This is the phase where that matters most. | ✓ VERIFIED (invariant) — runtime load owed | Source-scan green: `transport.R` never assigns `.gmw_engine` (no `.gmw_engine$`/`.gmw_engine <-`); the native load path is untouched. Positive `.gmw_engine$ok` runtime check skips cleanly (namespace/engine absent headless). Runtime load on a display host → human. |

**Score:** 3/5 success criteria code-verified (SC1, SC2, SC5); SC3 (the milestone gate) and SC4 (HiDPI parity) require human closure. 0 present-behavior-unverified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `R/transport.R` (extended) | `.gmw_picks`, `.gmw_pick_handler`, `.gmw_picks_get`, exported `gmw_picks`; `/pick` excludeStaticPath | ✓ VERIFIED | All present (L58, L175-197, L371-399); mixed app lists 3 static-path keys with two `excludeStaticPath()` and `call = .gmw_pick_handler(token)` (L253-264). Wired + tested. |
| `tests/testthat/test-picking-transport.R` (new) | Pick route + T-2-02 + CMP-01 gate | ✓ VERIFIED | 6 blocks, 30 assertions green, 1 clean skip (engine-present positive check). |
| `R/view3d.R` (extended template) | Eager BVH, pointer pick, overlay dot, `GMW_REPLAY` | ✓ VERIFIED | All wiring present (L245-346); sprintf head/body split renders. Source-scan green. |
| `tests/testthat/test-picking-view3d.R` (new) | Source-scan of all picking wiring | ✓ VERIFIED | All PICK-01/02/03 markers + relative-only pick target asserted; green. |
| `R/parity.R` (new) | Mean edge, 95th-pct gate, TSV reader | ✓ VERIFIED | 3 `@noRd` helpers, base-R only (no JSON); unit + integration blocks green. |
| `tests/fixtures/parity/B7_1_pick_poses.tsv` (new) | Schema-true PLACEHOLDER pose record | ✓ VERIFIED | 46-col header in exact drop-in order; 6 rows, all `commit=PLACEHOLDER`; mix of zero-distance and sub-mean-edge noise rows; objXYZ within B7_1 bbox. |
| `tests/testthat/test-picking-parity.R` (new) | Skip-safe gate harness; PICK-03 OPEN | ✓ VERIFIED | Unit + placeholder-e2e (ran vs real PLY via Rvcg) green; real-parity block SKIPS with PICK-03 OPEN message. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `view3d.R` pointer handler | `/<token>/pick` route | relative `sendBeacon("pick", "x,y,z")` | ✓ WIRED | Relative same-origin target; no absolute URL (asserted by source-scan). |
| `.gmw_pick_handler` | `.gmw_picks[[token]]` | `grepl("/pick$")` → base-R parse → `rbind`/`assign` | ✓ WIRED | Behaviorally proven: 204 + row append; malformed dropped; cross-token isolation. |
| `.gmw_serve_mesh` startServer | `.gmw_pick_handler` | `call = .gmw_pick_handler(token)` + 2× `excludeStaticPath()` | ✓ WIRED | Three static-path keys `/<token>`, `/close`, `/pick`; static byte mount unchanged. |
| harness | `.gmw_parity_gate` | native `objXYZ` vs browser-replay `brXYZ` read directly from fixture columns | ✓ WIRED | No in-R synthesis; drop-in channel for the real capture (zero code change). |
| `GMW_REPLAY` | identity mesh | `new THREE.Mesh(pickMesh.geometry)` at position (0,0,0) | ✓ WIRED | Column-major `fromArray`, no transpose; casts raw PLY-vertex frame (anti-pattern guarded). |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Pick transport unit suite | `test_dir(filter="picking-transport")` | 28 pass / 0 fail / 1 skip | ✓ PASS |
| View3d picking source-scan | `test_dir(filter="picking-view3d")` | all assertions pass / 0 fail | ✓ PASS |
| Parity gate + placeholder e2e (ran vs real B7_1_clean.ply via Rvcg) | `test_dir(filter="picking-parity")` | 17 pass / 0 fail / 1 skip (real-parity OPEN) | ✓ PASS |
| Debt-marker scan (6 modified/created files) | `rg "TBD|FIXME|XXX|HACK|TODO|..."` | no matches | ✓ PASS |

Run with `Rscript --vanilla` + `testthat::test_dir(...)` per STATE.md (full `test_local` hangs on the pre-existing tcltk2/rgl GUI-init + renv `activate.R` block — environmental, not a phase defect).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PICK-01 | 04-01, 04-02 | BVH raycast returns hit coordinate to R at interactive rates | ✓ SATISFIED (code) / human runtime | R round-trip 30 assertions green; browser wiring source-verified; interactive rates → human UAT |
| PICK-02 | 04-02 | Overlay landmark dot with correct depth under rotation | ✓ SATISFIED (code) / human runtime | Overlay source-scan green; visual occlusion → human UAT |
| PICK-03 | 04-02, 04-03 | Browser coordinate matches native `gluUnProject` within tolerance — **milestone gate** | ⚠️ NEEDS HUMAN — FORMALLY OPEN | Gate math + harness + fixture + replay complete and tested on placeholder; real Windows capture owed (D-06/D-07) |
| CMP-01 | 04-01 | Native oracle stays loadable/functional | ✓ SATISFIED (invariant) / human runtime | `transport.R` never touches `.gmw_engine` (source-scan green); runtime load → human on display host |

No orphaned requirements — all four phase-4 IDs (PICK-01, PICK-02, PICK-03, CMP-01) are declared in plan frontmatter and mapped in REQUIREMENTS.md (CMP-01 is the recurring native-oracle gate enforced each phase through Phase 5).

### Anti-Patterns Found

None. No `TBD`/`FIXME`/`XXX`/`HACK`/`TODO` or "not yet implemented" markers in any modified/created file. The `PLACEHOLDER` token in the fixture and harness is an intentional, documented skip sentinel (drives the PICK-03 real-parity skip gate), not a debt marker.

### Human Verification Required

1. **PICK-03 milestone gate — real Windows+browser parity capture.** Capture native `gluUnProject` poses on the validated tkogl2 Windows oracle (objXYZ + real per-row engine commit hashes), replay each via `window.GMW_REPLAY()` to fill `brXYZ`, drop the rows into `tests/fixtures/parity/B7_1_pick_poses.tsv`, and re-run the parity harness.
   - Expected: real-parity block stops skipping; `p95(browser-vs-native) <= 1× mean edge` passes. Closes PICK-03 with zero code change.
2. **PICK-01/PICK-02 browser UAT** (macOS + Windows, offline): click→red dot under cursor, `gmw_picks(token)` returns the coord, dot occluded under rotation, miss is a no-op, picking stays interactive on the 363k-vert worst case.
3. **CMP-01 native oracle load** on a display host: `library(GUImorphWeb)` and `.gmw_engine$ok` TRUE.

### Gaps Summary

No code gaps. Every artifact the phase promised exists, is substantive, is wired end-to-end, and passes its automatable tests (unit + source-scan + placeholder integration against the real specimen). The phase deliberately ships PICK-01 and PICK-02 value plus the *complete, drop-in-ready* PICK-03 harness, while the milestone gate itself (PICK-03) remains **formally OPEN** because native `gluUnProject` capture is Windows-only and no such host exists in this environment (D-06). This is an environment/oracle-availability limitation surfaced for human closure — not a defect in the delivered code — so the status is `human_needed` rather than `gaps_found`. Closing PICK-03 requires the human-run Windows capture; per the harness design it then closes with genuinely zero code change (D-07).

### Acknowledged Gaps (user-accepted deferrals, 2026-08-06)

The user reviewed the `human_needed` result during `/gsd-verify-work 4` and elected
to proceed, recording the two Windows-only items as deferred rather than blocking
the milestone. They are tracked (not dropped) so they resurface in `/gsd-progress`
and `/gsd-audit-uat`.

| Requirement | Deferred item | Why deferred | Closure |
|-------------|---------------|--------------|---------|
| PICK-03 | Real browser-vs-native parity capture (the milestone gate) | Native `gluUnProject` capture is Windows-only; no validated `tkogl2` host available. Harness is complete and drop-in-ready. | Windows capture → fill `brXYZ` in `B7_1_pick_poses.tsv` → re-run `picking-parity` (zero code change). Tracked in `.planning/todos/pending/pick03-windows-parity-capture-owed.md`. |
| CMP-01 | Native-oracle runtime load (`.gmw_engine$ok == TRUE`) | Windows/display host required; source invariant (`transport.R` never touches `.gmw_engine`) already auto-verified. | `library(GUImorphWeb)` on a Windows host during the same PICK-03 capture session. Same todo. |

**Verified live and NOT deferred:** PICK-01 and PICK-02 (browser picking) — see `04-UAT.md` Test 2 (macOS/Safari: raycast hits at interactive rates, overlay dots render, `gmw_picks()` returned a 6×3 matrix).

---

_Verified: 2026-08-05T17:25:00Z (initial); UAT + acknowledged deferrals 2026-08-06_
_Verifier: Claude (gsd-verifier); UAT + acknowledgment via /gsd-verify-work 4_
