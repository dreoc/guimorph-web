---
phase: 15-curve-tab-rehabilitation
verified: 2026-06-29T00:00:00Z
status: passed
score: 16/16 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Place all landmarks on current specimen, switch to Curves tab, double-click 3 landmarks to define one segment, click Compute Curves"
    expected: "Chord lines appear in the 3D viewer; status bar shows busy feedback then success count (e.g. 'Drew 1 curve segment(s).')"
    why_human: "C/OpenGL batch redraw requires Tk + Windows runtime; grep confirms protocol calls but not visual output"
  - test: "Define curve segments, File → Save to DGT, reload via Load DGT File"
    expected: "Curve matrix reloads into session; switching to Curves tab replays segments in viewer"
    why_human: "Full GUI file I/O integration beyond unit-tested read.curve/write.curve helpers"
  - test: "Before landmark completion, click disabled Curves and Surface Sliders tabs"
    expected: "Status bar shows 'Place all N landmarks to unlock … — X of N placed.' with no 'coming in a later update' text"
    why_human: "Notebook disabled-state click behavior requires live Tk session"
  - test: "On Curves tab, place a 3-landmark segment then press Ctrl+Z; repeat until last segment removed"
    expected: "Each undo removes the last triplet from data and refreshes viewer; last-segment undo clears visible chords"
    why_human: "Undo calls .redrawAllCurves which returns early on empty matrix without an explicit C clear — viewer refresh on last undo needs visual confirmation"
  - test: "Compare README §4 and Known quirks against Curves tab widget labels, hint text, and Help → Keyboard Shortcuts dialog"
    expected: "Total curves / Current curve spinboxes, Compute Curves, Reset view, 3-landmark description, and Ctrl+Z curve-segment scope match README"
    why_human: "Visual parity and exact on-screen copy cannot be fully validated by static grep alone"
---

# Phase 15: Curve Tab Rehabilitation Verification Report

**Phase Goal:** Re-enable the commented-out Curve controls, make curve definition round-trip through `.dgt`, and reconcile UI with the README.
**Verified:** 2026-06-26T12:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Curves tab shows inline Total curves / Current curve spinboxes, Compute Curves, Reset view in vertical order | ✓ VERIFIED | `ui.curve()` packs desc label → max row → current row → Compute → Reset (`3dDigitize.curve.r` L70–149); wired via `ui.curve(e, tn)` in `3dDigitize.main.r` L691 |
| 2 | Spinboxes clamp min 1, no practical upper cap; current stays within 1..max | ✓ VERIFIED | `.clampCurveMax`/`.clampCurveCurrent` (L19–34); spinboxes `from=1, to=9999` (L86–87, L112–113); handlers call clamps on Return/FocusOut |
| 3 | Surface Sliders and Curves unlock when current specimen landmarks == landmarkNum | ✓ VERIFIED | `refreshTabGating` `lmOk` predicate on `activeDataList[[currImgId]][[3]]` (main.r L308–314) |
| 4 | Disabled Curves/Surface clicks show landmark progress, not stale messages | ✓ VERIFIED | `switchTab` intercept for tabs 2–3 (main.r L419–436); grep: zero `coming in a later update` in `R/` |
| 5 | GPA tab uses same landmark-complete gate as tabs 2–3 | ✓ VERIFIED | Tab 4 gated by same `lmOk` (main.r L315–316) |
| 6 | Compute Curves runs full C batch redraw with busy progress | ✓ VERIFIED | `.redrawAllCurves` protocol: `initialize` → `InfoCurves` → curve loop → `curveSetDotSliderColor` → `InfoCurves_complete` (curve.r L373–399); `onComputeCurves` wraps with `busyStart`/`busyStop` (L402–421) |
| 7 | Current curve spinbox selects edit index; Compute draws all rows | ✓ VERIFIED | `onCurveCurrentChange` calls `add("SetCurveIndex", val, …)` (L61); `.redrawAllCurves` iterates all rows in `activeDataList[[1]][[4]]` |
| 8 | Entering Curves tab activates bind.curve for double-click placement | ✓ VERIFIED | `switchTab` id==3 calls `bind.curve(e)` (main.r L536); `onSelectCurve` guarded by `e$tab != 3` (curve.r L281) |
| 9 | hintLabel shows curve-specific current-of-max text | ✓ VERIFIED | `updateCurveHint` (main.r L345–356); invoked from `updateHintLabel` on tab 3 and spinbox handlers |
| 10 | Ctrl+Z undoes last curve triplet via matrix row removal and redraw | ✓ VERIFIED | `pushUndo` `curve_place` on triplet complete (curve.r L357); `doUndo` branch pops row and calls `.redrawAllCurves` (digitize.r L127–140); test mocks in `test-undo-helpers.R` |
| 11 | Duplicate landmark in segment shows inline status warning, not modal | ✓ VERIFIED | `setStatus` warning in `onSelectCurve` (curve.r L296–300); grep confirms no `tkmessageBox` in curve.r |
| 12 | README §4 documents spinboxes, Compute, Reset view, 3-landmark workflow | ✓ VERIFIED | README.md L113–116 contains all required strings |
| 13 | README Known quirks reflects landmark-only unlock on current specimen | ✓ VERIFIED | README.md L145–154 |
| 14 | In-app labels, hints, gating messages, shortcuts align with README | ✓ VERIFIED | Curve labels match README intent (curve.r L72–139); gating messages mirror Known quirks pattern (main.r L423–444); shortcuts dialog updated (L827–828) |
| 15 | No README references to modal Set curves buttons | ✓ VERIFIED | grep: no `Set curves (total) number` or `Set Current curve number` in README.md |
| 16 | Curve definition round-trips through `.dgt` | ✓ VERIFIED | `write.curve` on save (main.r L1876–1878); `read.curve` in `openDgt` → `drawElements` stores `dgtDataList[[1]][[4]]` (L2891, L1803); unit test `test-curve-io.R` round-trips matrix |

**Score:** 16/16 truths verified (automated); 5 human UAT items pending

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `R/3dDigitize.curve.r` | Spinbox UI, clamp helpers, batch redraw, placement | ✓ VERIFIED | 424 lines; substantive implementations, not stubs |
| `R/3dDigitize.main.r` | Tab gating, switchTab bind, shortcuts sync | ✓ VERIFIED | `refreshTabGating`, `switchTab` intercept, `updateCurveHint` present |
| `R/3dDigitize.digitize.r` | `curve_place` undo branch | ✓ VERIFIED | `doUndo` branch at L127–140 |
| `tests/testthat/test-curve-io.R` | `.dgt` I/O round-trip | ✓ VERIFIED | 2 `test_that` blocks exercising write/read |
| `tests/testthat/test-curve-spinbox.R` | Clamp logic | ✓ VERIFIED | Tests NA/0/-1/overflow cases |
| `tests/testthat/test-curve-tab-gating.R` | Gating predicate | ✓ VERIFIED | Tests lmOk enable/disable for tabs 2–4 |
| `tests/testthat/test-undo-helpers.R` | curve_place undo + duplicate grep | ✓ VERIFIED | Mock undo test + source grep for inline warning |
| `tests/testthat.R` | testthat entrypoint | ✓ VERIFIED | `test_check("GUImorph")` |
| `README.md` | §4 + Known quirks sync | ✓ VERIFIED | Updated curve workflow and gating copy |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `updateDotNum` | `refreshTabGating` | post-placement call | ✓ WIRED | digitize.r L1102 |
| `ui.curve` spinboxes | `onCurveMaxChange` / `onCurveCurrentChange` | Return/FocusOut bindings | ✓ WIRED | curve.r L95–125 |
| `switchTab` | `setStatus` | disabled-tab intercept tabs 2–4 | ✓ WIRED | main.r L416–449 |
| `onComputeCurves` | C engine | `.redrawAllCurves` → `InfoCurves_complete` | ✓ WIRED | curve.r L373–420 |
| `onSelectCurve` | `e$undo` | `pushUndo` curve_place | ✓ WIRED | curve.r L357 |
| `switchTab` id==3 | `bind.curve` | explicit call | ✓ WIRED | main.r L536 |
| `saveToDgt` | `write.curve` | curves from `activeDataList[[1]][[4]]` | ✓ WIRED | main.r L1876–1878 |
| `openDgt` | `read.curve` | `drawElements` populates `[[4]]` | ✓ WIRED | main.r L2891 → L1803 |
| README §4 | `ui.curve` labels | grep parity | ✓ WIRED | Matching Total curves, Compute Curves, Reset view strings |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `onComputeCurves` | `curves` | `e$activeDataList[[1]][[4]]` | Yes — matrix from placement or load | ✓ FLOWING |
| `onSelectCurve` | `curves` | rbind new triplet to `[[4]]` | Yes — landmark IDs from C `shows("landmark","id")` | ✓ FLOWING |
| `saveToDgt` | `curves` | `activeDataList[[1]][[4]]` | Yes — written via `write.curve` | ✓ FLOWING |
| `openDgt` | `curves` | `read.curve(rawContent)` | Yes — parsed from `.dgt` Curve= block | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Curve I/O test exists | `tests/testthat/test-curve-io.R` file read | 2 substantive tests | ✓ PASS (existence) |
| Spinbox clamp test exists | `tests/testthat/test-curve-spinbox.R` file read | 2 substantive tests | ✓ PASS (existence) |
| Gating test exists | `tests/testthat/test-curve-tab-gating.R` file read | 3 substantive tests | ✓ PASS (existence) |
| R test execution | `Rscript -e "testthat::test_file(...)"` | R not available in verifier WSL shell | ? SKIP |

### Probe Execution

Step 7c: SKIPPED — no phase-declared probes or `scripts/*/tests/probe-*.sh` for this UI phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| UX-CRV-01 | 15-01, 15-02 | Re-enable functional Curve tab controls | ✓ SATISFIED | Inline spinboxes, Compute, bind.curve, undo, gating — modal handlers removed |
| UX-CRV-02 | 15-01, 15-03 | `.dgt` round-trip + README/in-app text match | ✓ SATISFIED | I/O wired + tests; README §4/Known quirks updated; shortcuts synced |

**Orphaned requirements:** None — both UX-CRV-01 and UX-CRV-02 appear in plan frontmatter and are covered above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `3dDigitize.main.r` | 2067 | `TBD` in comment (pre-2020 snapshot line) | ℹ️ Info | Pre-existing; not introduced by Phase 15 |
| `3dDigitize.main.r` | 552–557 | `dgtcurvestuff` path still calls legacy `draw.curves()` on tab switch | ⚠️ Warning | Parallel path alongside `.redrawAllCurves`; may cause duplicate draw on loaded `.dgt` — needs human UAT |
| `3dDigitize.digitize.r` | 138 | `doUndo` calls `.redrawAllCurves` after clearing last row | ⚠️ Warning | Empty-matrix early return shows warning without explicit C clear — last-segment undo viewer state uncertain |

### Human Verification Required

### 1. Compute Curves 3D drawing

**Test:** Place all landmarks, define a curve segment (3 double-clicks), click Compute Curves.
**Expected:** Chord lines render in viewer; busy status then success message with segment count.
**Why human:** C/OpenGL rendering cannot be validated by static analysis.

### 2. Full `.dgt` save/load round-trip

**Test:** Define curves, save DGT, reload in fresh session.
**Expected:** Curve data persists; Curves tab replays segments on entry.
**Why human:** End-to-end file + GUI integration beyond unit tests.

### 3. Disabled-tab gating messages

**Test:** Click Curves/Surface tabs before landmark completion.
**Expected:** Inline landmark progress messages; no stale "coming later" copy.
**Why human:** Tk notebook disabled-click behavior.

### 4. Ctrl+Z curve undo (including last segment)

**Test:** Place segment(s), Ctrl+Z repeatedly until none remain.
**Expected:** Data row removed each undo; viewer reflects remaining or cleared chords.
**Why human:** `.redrawAllCurves` empty-state path may not clear C viewer — edge case needs visual check.

### 5. README ↔ live UI parity

**Test:** Open Curves tab and Help → Keyboard Shortcuts; compare to README §4 and Known quirks.
**Expected:** Labels, hints, and shortcut text match documented workflow.
**Why human:** Visual confirmation of copy alignment.

### Gaps Summary

Human UAT completed at v1.1 milestone close (2026-06-29). All five scenarios passed (see 15-UAT.md).

---

_Verified: 2026-06-29T00:00:00Z_
_Verifier: Claude (gsd-verifier); UAT closed at milestone archive_
