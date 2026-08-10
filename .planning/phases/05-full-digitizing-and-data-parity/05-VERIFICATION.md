---
phase: 05-full-digitizing-and-data-parity
verified: 2026-08-07T16:42:37Z
status: human_needed
score: 5/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Live browser digitizing interactions (DGT-01/DGT-02): on a display host, launch a viewport, place anchors (green dots), define a curve by clicking three placed landmark dots (first cyan, second blue slider, third completes), display + delete a surface semilandmark, undo, and switch specimens."
    expected: "Anchors render green in a non-raycast group; curve recolor is cyan then blue then commit; overlays follow the correct specimen after a switch and picks land on the newly loaded mesh (BVH rebuilt)."
    why_human: "three.js pointer interaction and multi-mesh visual behavior cannot run in the headless macOS sandbox (no browser/display). R-side routes, session mutations, one-deep undo, and template wiring are unit/source-scan verified (61 + 24 assertions green); only the live visual layer is unverified."
  - test: "Live surface semilandmark COMPUTE end-to-end (DGT-02 / full-workflow): trigger /downsample from the browser against a loaded specimen and confirm the surface cloud is computed and displayed."
    expected: "The TPS warp runs and a THREE.Points surface cloud appears in the viewport."
    why_human: "KNOWN STUB (documented in 05-04-SUMMARY): .gmw_downsample_session reads the raw PLY vertex cloud from rec$specimen (3dDigitize.surface.r:605), but NO serve/route path populates .gmw_session[[token]]$specimens[[cur]]$specimen. Live /downsample currently stop()s and the try()-wrapped route returns a harmless 204 no-op. The transpose contract and headless warp are unit-verified with a SEEDED specimen slot only. Surface DISPLAY of an already-populated cloud works; live surface ACQUISITION does not until the specimen slot is wired."
  - test: "Live browser-driven GPA + .csv/.rds export (DGT-03): on a display host with geomorph installed, run GPA over real multi-specimen session data and export .csv/.rds."
    expected: "geomorph::gpagen runs, result plots route through .gmw_view3d, and .csv/.rds files are written via the existing save()/exportGeomorph()."
    why_human: "The seams reuse geomorph::gpagen and the interactive tkgetSaveFile exporters verbatim; a real GPA + file-dialog export needs a display host with geomorph. Identical-to-native-by-construction is proven structurally (session-vs-active .build_geomorph_data equality + gpagen-forwarding source-scan green)."
  - test: "Live native-GUI-vs-browser dual-path DAT-01 run (corroborating): on a Windows tkogl2 host, save the same session through the native GUI and the browser path; confirm byte-identical .dgt."
    expected: "Both .dgt files are byte-identical (raw md5)."
    why_human: "Needs a Windows tkogl2 host running the native GUI alongside the browser path. The automated R-level write-vs-write byte-identity gate is the PRIMARY proof and PASSES; this is corroborating field evidence."
  - test: "DAT-02 bidirectional -rewrite byte gate + reader-accepts-both-dialects."
    expected: "Opening tests/fixtures/parity/windows-authored-roundtrip.dgt and mac-authored-roundtrip.dgt in GUImorphWeb and re-saving reproduces the authored bytes (per dat-parity-gate-is-a-skip.md); a GUImorphWeb-authored .dgt opens correctly in GUImorph."
    why_human: "The two -rewrite fixtures require a Windows re-save (not present on disk), so the DAT-03 gate skips cleanly. No automated test parses the authored fixtures to prove the reader accepts both dialects. The macOS->Windows leg is an open UPSTREAM dependency in GUImorph. DAT-02 is explicitly [ ] incomplete in REQUIREMENTS.md."
  - test: "CMP-01 native oracle RUNTIME load: on a Windows host with the built tkogl2 engine, confirm .gmw_engine$ok == TRUE after library(GUImorphWeb)."
    expected: ".gmw_engine$ok is a logical scalar TRUE; the native oracle stays loadable through Phase 5 (retired at Phase 6)."
    why_human: "Needs a Windows host with the built tkogl2 engine; headless/tarball skips cleanly. The SOURCE invariant (transport.R and 3dDigitize.main.r never assign/read .gmw_engine) is verified and the skip-if-absent gate is clean everywhere else."
---

# Phase 5: Full Digitizing and Data Parity Verification Report

**Phase Goal:** Complete the acquisition workflow in the browser and prove the output bytes are identical to the native path.
**Verified:** 2026-08-07T16:42:37Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

The automated/structural layer of this phase is fully realized: every declared artifact exists, is substantive, is wired, and every Phase-5 test file is green (determinism 6/6, digitizing-session 61, digitizing-view3d 24, surface-flatten 7, gpa-parity 13, export-parity 9, dgt-cross-platform 7 pass + 2 documented skips). The **DAT-01 byte-identity gate — the phase's central "prove the bytes are identical" claim — passes as an automated R-level write-vs-write test.**

What remains is genuinely host-dependent and cannot be exercised in this headless macOS sandbox (loading the package triggers tcltk2/rgl GUI init; there is no browser, no display, and no Windows tkogl2 engine): live three.js interaction (DGT-01/02/03), the DAT-02 bidirectional `-rewrite` byte gate, the live native-vs-browser dual-path DAT-01 corroboration, and the CMP-01 runtime engine load. These are honestly framed as owed manual/external evidence by the plans themselves. One genuine incompleteness — the live surface-compute specimen-slot stub — is called out as a WARNING below.

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | Curve definition (three-click, cyan/red/blue) + anchor placement (DGT-01) | ✓ VERIFIED (structural + R behavior) | `/anchor` (3-float, finite) and `/curve` (3 distinct finite integer indices; malformed/duplicate dropped) routes + one-deep undo unit-tested (test-digitizing-session.R, 61 pass); view3d.R `addAnchorDot` green `0x00ff00` non-raycast group, cyan `THREE.Color(1/255,164/255,191/255)`, blue `(0,0,1)`, `sendBeacon("anchor"/"curve")` source-scanned (test-digitizing-view3d.R, 24 pass). Live visual/pointer feedback → human item 1. |
| 2 | Surface display, delete, undo, multi-specimen switch in browser (DGT-02) | ⚠️ VERIFIED with WARNING | `/delete`/`/undo`/`/specimen` routes + undo inversion + RE-SERVE switch unit-tested; view3d.R `THREE.Points` cloud, delete/undo/specimen beacons, `computeBoundsTree()` rebuild source-scanned; `.gmw_downsample_session` headless warp + `as.vector(t(.))` transpose pinned (test-surface-flatten.R, 7 pass). **WARNING:** live surface COMPUTE is a known stub — no path populates the session `specimen` (raw PLY vertex) slot, so live `/downsample` no-ops (human item 2). Live browser interaction → human item 1. |
| 3 | GPA + .csv/.rds export driven from browser, identical to native (DGT-03) | ✓ VERIFIED (identical-by-construction) | `.gmw_session_to_geomorph_env` populates existing `activeDataList` slots so `compute`/`save`/`exportGeomorph` run unedited; session-vs-active `.build_geomorph_data` equality passes; gpagen-forwarding source-scan unchanged; `.gmw_export_session` dispatch + `c("csv","rds")` allow-list (test-gpa-parity.R 13, test-export-parity.R 9 pass). Live GPA/export run on display host w/ geomorph → human item 3. |
| 4 | Browser .dgt byte-identical to native from same session (DAT-01) | ✓ VERIFIED (R-level automated gate) | "browser save is byte-identical to the canonical writer for identical arrays" PASSES — `.gmw_save_session_dgt` and `saveToDgt` route through ONE `.dgt_emit_session_blocks` serializer; determinism (round-in-R + pinned CRLF) 6/6 pass. Live native-vs-browser dual-path on Windows tkogl2 → human item 4 (corroborating). |
| 5 | Bidirectional .dgt open correctness vs fixtures (DAT-02) | ⚠️ HUMAN NEEDED (honestly gated) | DAT-03 `-rewrite` byte gate SKIPS (Windows re-save fixtures absent on disk); no automated test parses the authored fixtures to prove the reader accepts both dialects; macOS→Windows leg is an open upstream dependency. DAT-02 is `[ ]` incomplete in REQUIREMENTS.md. → human item 5. |
| 6 | Full workflow end-to-end: PLY load, landmarks, curves, surfaces, GPA, export | ⚠️ HUMAN NEEDED | Every component present and unit-tested in isolation, but the composed live run requires a display host; also gated by the surface-compute specimen-slot stub (item 2). → human items 1, 2, 3. |
| 7 | Native oracle still loads (CMP-01; retired after this phase) | ✓ VERIFIED (source invariant) | Source-scan: `transport.R` and `3dDigitize.main.r` never assign/read `.gmw_engine` (asserted in test-digitizing-session.R and test-dgt-cross-platform.R); skip-if-absent runtime gate is clean. Runtime `.gmw_engine$ok == TRUE` on a Windows engine host → human item 6 (deferred per REQUIREMENTS.md). |

**Score:** 5/7 truths verified (structural/automated); 2 (DAT-02 bidirectional, full-workflow E2E) require human/host evidence. DGT-02 carries a surface-compute WARNING.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `R/3dDigitize.main.r` | `.dgt_format_num` rounds; `.dgt_writeln` pinned CRLF; `.dgt_write_matrix_block`/`saveToDgt` routed through it; `.dgt_emit_session_blocks`; `.gmw_save_session_dgt` | ✓ VERIFIED | `formatC(round(as.numeric(x),6),...)` (L207); binary `open="ab"` + `sep="\r\n"` (L215-219); single shared serializer (L2036) called by both `saveToDgt` (L2024) and `.gmw_save_session_dgt` (L2120). |
| `R/transport.R` | `.gmw_session` env + accessor + undo helpers + `.gmw_digitize_handler` + excludeStaticPath registration | ✓ VERIFIED | `.gmw_session` env (L76), `gmw_session` accessor (L795), undo grammar (L677-745), handler with all 9 route branches (L257-376), 11 excludeStaticPath entries + `call=.gmw_digitize_handler(token)` (L435-449). |
| `R/view3d.R` | anchor green group, curve-by-index cyan/blue, surface THREE.Points, delete/undo/switch, BVH rebuild — all in parameter-free BODY | ✓ VERIFIED | `addAnchorDot` `0x00ff00` (L214-219), `CURVE_CYAN` (L373), 5 sendBeacon targets (L405-509), THREE.Points cloud (L238), `computeBoundsTree()` (L301,496). |
| `R/3dDigitize.surface.r` | `.gmw_downsample_session` headless entry, no C `add("downsample")` from browser path | ⚠️ VERIFIED (data-flow gap) | `.gmw_downsample_session` (L594) reuses TPS warp, returns `.gmw_flat` (L661); no `add("downsample")` in the browser path (legacy sites L554/L862 only). **Reads `rec$specimen` (L605) — a slot no path populates (Level-4 disconnect, see WARNING).** |
| `R/3dDigitize.geomorph.r` | `.gmw_session_to_geomorph_env` + `.gmw_gpa_session` + `.gmw_export_session` | ✓ VERIFIED | L492 / L563 / L583; forwarding to `compute`/`save`/`exportGeomorph` left unedited. |
| `tests/testthat/test-{dgt-determinism,digitizing-session,digitizing-view3d,surface-flatten}.R` | new failing-first scaffolds now green | ✓ VERIFIED | All exist and pass (6 / 61 / 24 / 7). |
| `tests/testthat/test-{gpa-parity,export-parity,dgt-cross-platform}.R` | extended with session-read/byte-identity/CMP-01 blocks | ✓ VERIFIED | Pass 13 / 9 / (7 + 2 documented skips). |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| browser sendBeacon(anchor/curve/delete/undo/specimen) | `.gmw_digitize_handler` branch | grepl suffix → `.gmw_session[[token]]` mutation | ✓ WIRED | Each branch grepl's suffix only, base-R bounded parse, writes only own token; tests assert cross-token isolation + no path-join. |
| `/downsample` route | `.gmw_downsample_session` | forward-call under try() → TPS warp → `.gmw_flat` | ⚠️ PARTIAL | Function wired and returns correct transposed cloud from a seeded slot, but the upstream `specimen` slot is never populated by any serve path → live trigger no-ops. |
| `/gpa` `/export` routes | `.gmw_gpa_session` / `.gmw_export_session` | populate activeDataList slots → `compute`/`save`/`exportGeomorph` | ✓ WIRED | session-vs-active equality test proves the read seam yields identical geomorph data. |
| `/save` route | `.gmw_save_session_dgt` → `.dgt_emit_session_blocks` | same serializer as `saveToDgt` | ✓ WIRED | byte-identity test proves one-writer-vs-itself. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `.gmw_save_session_dgt` | session curves/landmarks/anchors/surfaces | `.gmw_session[[token]]` | Yes (byte-identity test) | ✓ FLOWING |
| `.gmw_session_to_geomorph_env` | activeDataList slots | session record | Yes (equality test) | ✓ FLOWING |
| `.gmw_downsample_session` | `rec$specimen` (raw PLY cloud) | session record | No — slot never populated by a serve path | ⚠️ DISCONNECTED (live); seeded in test |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Deterministic `.dgt` writer (round + pinned CRLF, identical arrays → identical bytes) | `test_file("tests/testthat/test-dgt-determinism.R")` | FAIL 0 / PASS 6 | ✓ PASS |
| DAT-01 browser-save == canonical writer (raw md5) | `test_file("tests/testthat/test-dgt-cross-platform.R")` | FAIL 0 / PASS 7 / SKIP 2 | ✓ PASS |
| Session routes + one-deep undo + isolation + CMP-01 source-scan | `test_file("tests/testthat/test-digitizing-session.R")` | FAIL 0 / PASS 61 | ✓ PASS |
| Surface flatten transpose (row-major pinned, column-major rejected) | `test_file("tests/testthat/test-surface-flatten.R")` | FAIL 0 / PASS 7 | ✓ PASS |
| Session-read == activeDataList `.build_geomorph_data`; gpagen forwarding scan | `test_file("tests/testthat/test-gpa-parity.R")` | FAIL 0 / PASS 13 | ✓ PASS |
| Export dispatch + csv/rds determinism + allow-list | `test_file("tests/testthat/test-export-parity.R")` | FAIL 0 / PASS 9 | ✓ PASS |
| Template source-scan (anchor/curve/surface/delete/undo/switch + HEAD ≤ 8192B) | `test_file("tests/testthat/test-digitizing-view3d.R")` | FAIL 0 / PASS 24 | ✓ PASS |

_2 skips in test-dgt-cross-platform.R = CMP-01 runtime engine load (namespace not loaded, headless) and the DAT-03 `-rewrite` gate (Windows fixtures absent). Both are documented, expected skips — not failures._

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| DGT-01 | 05-02, 05-03 | Curve (3-click, cyan/red/blue) + anchor placement in browser | ✓ SATISFIED (structural) / ? NEEDS HUMAN (live visual) | Routes + undo + template wiring green; live interaction → human item 1. |
| DGT-02 | 05-02, 05-03, 05-04 | Surface display, delete, undo, multi-specimen switch | ⚠️ SATISFIED w/ WARNING / ? NEEDS HUMAN | Display + delete/undo/switch wired & tested; live surface COMPUTE blocked by specimen-slot stub (item 2); live interaction → human item 1. |
| DGT-03 | 05-05 | GPA + csv/rds export from browser, identical to native | ✓ SATISFIED (by construction) / ? NEEDS HUMAN (live run) | Equality + forwarding + allow-list green; live GPA/export → human item 3. |
| DAT-01 | 05-01, 05-06 | Browser .dgt byte-identical to native from same session | ✓ SATISFIED (R-level gate) / ? NEEDS HUMAN (dual-path) | Automated byte-identity + determinism pass; live dual-path → human item 4. |
| DAT-02 | 05-06 | Bidirectional open correctness vs parity fixtures | ✗ NEEDS HUMAN (honestly gated) | `-rewrite` gate skips (fixtures owed); reader-both-dialects not automated; upstream leg open. `[ ]` in REQUIREMENTS.md. |
| CMP-01 | 05-02, 05-06 | Native oracle stays loadable through Phase 5 | ✓ SATISFIED (source invariant) / ? NEEDS HUMAN (runtime) | No `.gmw_engine` writes in edited files; runtime `.gmw_engine$ok` → human item 6 (deferred). |

All 6 declared requirement IDs are accounted for; no orphaned IDs map to Phase 5 in REQUIREMENTS.md.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `R/3dDigitize.surface.r` | 605 | `.gmw_downsample_session` reads `rec$specimen`, a slot no serve path writes | ⚠️ Warning | Live `/downsample` no-ops (try-wrapped 204) until the specimen vertex cloud is wired into the session record; documented Known Stub, not silent. Unit-tested only with a seeded slot. |

No debt markers (TBD/FIXME/XXX) introduced in the phase's modified files. No stub returns in the analytical/serializer paths (both prove real byte/data flow via tests).

### Human Verification Required

See the six `human_verification` items in the frontmatter. In priority order:

1. **Live browser digitizing interactions (DGT-01/DGT-02)** — display host.
2. **Live surface-compute end-to-end (DGT-02)** — WARNING: blocked by the specimen-slot stub; wire the served PLY vertices into `.gmw_session[[token]]$specimens[[cur]]$specimen`, then verify.
3. **Live browser GPA + .csv/.rds export (DGT-03)** — display host with geomorph.
4. **Live native-vs-browser dual-path DAT-01** — Windows tkogl2 host (corroborating; automated gate already passes).
5. **DAT-02 bidirectional `-rewrite` gate + reader-accepts-both-dialects** — Windows re-save fixtures per `dat-parity-gate-is-a-skip.md`.
6. **CMP-01 runtime engine load** — Windows engine host.

### Gaps Summary

No hard BLOCKER gaps: nothing claimed complete is broken, no declared artifact is missing or a stub, all key links except the surface `specimen` slot are wired, and every automated test is green — including the DAT-01 byte-identity gate that anchors the phase goal's "prove the bytes are identical" clause.

The phase does not reach `passed` because its goal ("complete the acquisition workflow in the browser") is inherently behavioral: the live three.js acquisition path (DGT-01/02/03, full E2E), the DAT-02 bidirectional byte gate, the corroborating native-vs-browser DAT-01 run, and the CMP-01 runtime engine load can only be exercised on a display / Windows tkogl2 host, which this headless macOS sandbox is not. These are honestly recorded as owed manual/external evidence by the plans and 05-VALIDATION.md.

One genuine incompleteness is surfaced as a WARNING: live surface semilandmark computation cannot run end-to-end because no path populates the session `specimen` (raw PLY vertex) slot that `.gmw_downsample_session` reads. Surface display of an already-populated cloud and the transpose contract are verified; live surface acquisition is not. Address before signing off DGT-02 / the full-workflow criterion.

---

_Verified: 2026-08-07T16:42:37Z_
_Verifier: Claude (gsd-verifier)_
