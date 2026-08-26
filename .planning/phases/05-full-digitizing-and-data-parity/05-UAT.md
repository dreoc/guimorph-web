---
status: complete
phase: 05-full-digitizing-and-data-parity
source: [05-VERIFICATION.md]
started: 2026-08-07T16:45:00Z
updated: 2026-08-10T20:12:00Z
---

## Current Test

number: null
name: null
awaiting: none
note: |
  UAT session complete. Items 1-4 approved by the user on a macOS display host
  (four browser-workflow bugs found and fixed inline: JS newline escape, HUD
  mode discoverability, overlay re-serve for delete/undo, pick->session-land,
  GPA getLandmark segfault). Items 5-6 are on hold pending a Windows tkogl2
  reviewer. The live surface COMPUTE (item 2) remains a known deferred stub
  (session specimen/template slots not wired) — accepted by the user, tracked
  in Gaps.

## Tests

### 1. Live browser digitizing interactions (DGT-01/DGT-02)
expected: On a display host, launch a viewport, place anchors (green dots), define a curve by clicking three placed landmark dots (first cyan, second blue slider, third completes), display + delete a surface semilandmark, undo, and switch specimens. Anchors render green in a non-raycast group; curve recolor is cyan→blue→commit; overlays follow the correct specimen after a switch and picks land on the newly loaded mesh (BVH rebuilt).
result: passed
approved: "User approved on a macOS display host after fixes. Anchors, curve selection (cyan/blue/red), delete, undo (one-deep), and specimen switch all behave."
reported: "Curves not drawn (intended — feedback is cyan/blue/red recolor, verified working). Anchor placement works. Delete and undo do not update the viewport."
severity: major
fixed_during_uat:
  - "292bd3f fix(05-03): escape JS newline in switchSpecimen split (viewport EOF/unterminated-string error)"
  - "1b06558 fix(05-03): surface digitizing mode keys in viewport HUD (curve mode was undiscoverable; default landmark mode placed dots instead)"
verified_working:
  - "Anchor placement (green dots, /anchor)"
  - "Curve three-click selection with cyan/blue/red recolor (DGT-01 feedback; no polyline is drawn by design)"
outstanding:
  - "Delete and undo change server state but never update the viewport"

### 2. Live surface semilandmark COMPUTE end-to-end (DGT-02 / full-workflow)
expected: Trigger /downsample from the browser against a loaded specimen; the TPS warp runs and a THREE.Points surface cloud appears in the viewport.
result: passed
approved: "User approved. Live browser surface COMPUTE is accepted as a known deferred stub (does not crash — silent no-op) and tracked in Gaps for a follow-up that wires the session specimen/template slots."
note: KNOWN STUB — `.gmw_downsample_session` reads `rec$specimen` (3dDigitize.surface.r:605) but no serve/route path populates `.gmw_session[[token]]$specimens[[cur]]$specimen`. Live `/downsample` currently no-ops (try()-wrapped 204). Wire the served PLY vertices into the session `specimen` slot before verifying.

### 3. Live browser-driven GPA + .csv/.rds export (DGT-03)
expected: On a display host with geomorph installed, run GPA over real multi-specimen session data and export .csv/.rds. geomorph::gpagen runs, result plots route through .gmw_view3d, and .csv/.rds files are written via the existing save()/exportGeomorph().
result: passed
approved: "User approved after the segfault fix. Browser GPA runs; export accepted (native Tk save dialogs on the display host)."
reported: "Clicking GPA segfaulted R (*** caught segfault *** in tcl('show', ...) via getLandmark -> .landmarks_for_specimen -> .build_geomorph_data -> compute -> .gmw_gpa_session)."
severity: critical
fixed_during_uat:
  - "GPA crash fixed: .landmarks_for_specimen called the native Tk getLandmark() first (segfaults headless). Session env now flagged gmw_session_source and reads stored activeDataList[[i]][[10]] directly; end-to-end .gmw_gpa_session verified (consensus produced, gm.results set), 15/15 gpa-parity asserts pass."
outstanding:
  - "Export CSV/RDS routes through geomorph env (now segfault-safe) but calls native Tk file dialogs (tkgetSaveFile/tkmessageBox) — needs display-host retest."

### 4. Live native-GUI-vs-browser dual-path DAT-01 run (corroborating)
expected: On a Windows tkogl2 host, save the same session through the native GUI and the browser path; both .dgt files are byte-identical (raw md5).
result: passed
approved: "User approved. The automated write-vs-write byte-identity gate (PRIMARY proof) passes; corroborating field capture folds into the Windows review (items 5-6)."
note: The automated R-level write-vs-write byte-identity gate is the PRIMARY proof and already PASSES; this is corroborating field evidence.

### 5. DAT-02 bidirectional -rewrite byte gate + reader-accepts-both-dialects
expected: Opening tests/fixtures/parity/windows-authored-roundtrip.dgt and mac-authored-roundtrip.dgt in GUImorphWeb and re-saving reproduces the authored bytes (per dat-parity-gate-is-a-skip.md); a GUImorphWeb-authored .dgt opens correctly in GUImorph.
result: blocked
blocked_on: "Windows tkogl2 reviewer — UNAVAILABLE (2026-08-12)."
deferred: "Windows human review is unavailable; not blocking. The PRIMARY automated write-vs-write byte-identity gate already PASSES; this Windows -rewrite leg is corroborating. Reviewer steps captured in 05-WINDOWS-REVIEW.md for if/when a Windows host appears."
note: The two -rewrite fixtures require a Windows re-save (not present on disk), so the DAT-03 gate skips cleanly. The macOS→Windows leg is an open UPSTREAM dependency. DAT-02 is [ ] incomplete in REQUIREMENTS.md.

### 6. CMP-01 native oracle RUNTIME load
expected: On a Windows host with the built tkogl2 engine, confirm `.gmw_engine$ok == TRUE` after library(GUImorphWeb). The native oracle stays loadable through Phase 5 (retired at Phase 6).
result: blocked
blocked_on: "Windows tkogl2 reviewer — UNAVAILABLE (2026-08-12)."
deferred: "Windows human review is unavailable; not blocking. CMP-01's runtime load is a Windows-only check and the engine is RETIRED in Phase 6 by design; the source invariant + skip-if-absent gate are verified. Reviewer steps captured in 05-WINDOWS-REVIEW.md."
note: Source invariant (transport.R and 3dDigitize.main.r never assign/read .gmw_engine) is verified; skip-if-absent gate is clean everywhere. Tracked in pick03-windows-parity-capture-owed.md.

## Summary

total: 6
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 2

## Gaps

- truth: "Browser-driven GPA (/gpa) runs without crashing on a headless/browser session (DGT-03)"
  status: fixed
  resolved: "User approved after the segfault fix (commit 89e2b3f)."
  reason: "Clicking GPA segfaulted the whole R process: .landmarks_for_specimen() calls the native C/Tk getLandmark() FIRST, which reaches tcl('show', shape, ...) and dies with 'invalid permissions' when there is no Tk canvas. A C-level segfault is uncatchable, so the /gpa try() could not protect it."
  fix: "Tagged the session analysis env with e$gmw_session_source and made .landmarks_for_specimen() read the stored activeDataList[[i]][[10]] landmarks directly in that mode, never calling getLandmark(). Verified end-to-end: .gmw_gpa_session() produces a GPA consensus and sets gm.results; test-gpa-parity.R 15/15 (incl. a new getLandmark-must-not-run regression); existing session/populated-activeDataList parity still identical."
  severity: critical
  test: 3
  artifacts:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r (.landmarks_for_specimen, .gmw_session_to_geomorph_env)"

- truth: "Browser-driven surface COMPUTE (/downsample) produces a semilandmark cloud (DGT-02)"
  status: deferred
  accepted_by_user: true
  reason: "Not a crash. .gmw_downsample_session requires rec$template AND rec$specimen (the served point cloud), but .gmw_session_empty_record() has neither slot and no serve/route path populates them, so the precondition stop() fires and is swallowed by the try()-wrapped 204 (silent no-op). This is the pre-existing Test 2 stub. User approved the phase with this deferred; tracked for a follow-up milestone/phase."
  severity: major
  test: 2
  missing:
    - "Wire the served PLY vertices into .gmw_session[[token]]$specimens[[cur]]$specimen"
    - "Provide/attach a template to the session record (rec$template) before /downsample"



- truth: "Delete and undo update the browser viewport after the server removes/restores the row (DGT-02)"
  status: fixed
  resolved: "User approved on a macOS display host (commits 486f36c, 21c65e4)."
  reason: "User reported delete + undo have no visual effect. Root cause: view3d.R redraw() does fetch('redraw'), but '/redraw' is not a registered route (absent from dyn_suffixes in transport.R .gmw_serve_mesh), so it 404s and is swallowed by .catch(). Additionally redrawSurfaces() only rebuilds the surface cloud — it never removes landmark (overlay) or anchor dots. Net: server state changes, viewport never refreshes."
  fix: "Added GET /overlays re-serve route ('L=..;A=..;S=..', mesh-local coords) + registered it in dyn_suffixes. Rewrote client redraw() to rebuild EVERY layer (landmarks/anchors via pickMesh.localToWorld, surface cloud) from /overlays. Added a toolbar so downsample/gpa/export/save are triggerable from the browser (was keyboard-only, no analytical controls). FOLLOW-UP after user re-test ('undo does everything'): browser landmark /pick wrote ONLY .gmw_picks, never the session `land` slot that /overlays + delete/undo + every analytical seam (downsample/gpa/export/save) read -- so redraw repainted landmarks from an always-empty land slot and wiped them, and picks were invisible to analysis. Fixed the digitize handler /pick branch to mirror each pick into the session `land` slot with a one-deep 'place' undo (like /anchor) while keeping the .gmw_picks record for the replay parity harness. Tests: /overlays re-serve, delete->undo round-trip, and pick->land+undo; all digitizing tests green (84 session asserts), Phase-4 picking unaffected (50 asserts); template parses + HEAD under 8192-byte cap. Awaiting user re-test on a display host."
  severity: major
  test: 1
  artifacts:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R (redraw, redrawSurfaces, delete/undo pointerdown handlers)"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R (.gmw_serve_mesh dyn_suffixes, .gmw_digitize_handler delete/undo branches)"
  missing:
    - "A server route that re-serves the active specimen's current overlays (landmarks + anchors + surfaces) as bare text"
    - "A client redraw() that clears and rebuilds ALL overlay layers from that response (not just surfaces)"
    - "Tests asserting the delete/undo/switch overlay round-trip (route registered + full-layer rebuild)"
