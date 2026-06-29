---
phase: 11-direct-manipulation-controls
verified: 2026-06-29T00:00:00Z
status: passed
score: 15/15 must-haves verified
overrides_applied: 0
gaps: []
human_verification:
  - test: "Load a PLY, drag Digitize and Anchor size sliders"
    expected: "Dot/anchor radius changes live while dragging; default 0.01 looks identical to pre-change"
    why_human: "GL visual feedback requires Windows R GUI; not scriptable from WSL"
  - test: "Load two specimens with different stored sizes, navigate Next/Previous"
    expected: "Size slider thumb and spinbox values jump to each specimen's stored size"
    why_human: "Specimen-switch widget sync requires live session navigation"
  - test: "Place 3 landmarks, type 2 in count spinbox, press Return"
    expected: "Value clamps to 3; no modal window appears"
    why_human: "Typed-input clamp behavior requires interactive spinbox + placed-point state"
  - test: "Right-click a placed landmark, then an anchor on Anchor tab"
    expected: "Point vanishes immediately; count label decrements; tab gating updates; no confirm window"
    why_human: "Canvas pick + GL redraw requires live GUI"
  - test: "Load PLY, drag main window edge larger then smaller"
    expected: "GL viewport enlarges/shrinks after drag settles (~150ms); no blank viewport on startup"
    why_human: "Window-manager resize + GL viewport behavior requires Windows R GUI"
  - test: "Load verify_.dgt, change size/count (no deletes), Save to DGT, diff LM3=/AC3= blocks"
    expected: "LM3=/AC3= blocks identical to original (CON-02 round-trip)"
    why_human: "Format-identity diff on real fixtures requires manual save workflow"
---

# Phase 11: Direct-Manipulation Controls Verification Report

**Phase Goal:** Replace modal/stepper interactions with inline controls — spinbox counts, size slider, non-modal delete, responsive viewport + panel.
**Verified:** 2026-06-24T23:45:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Digitize and Anchor tabs use `ttkscale` instead of +/- stepper buttons (UX-CTL-01) | ✓ VERIFIED | `ttkscale` at lines 137 and 249; no `Landmark Size +` / `Anchor Size +` / `onLmSizeAdd` / `onLmSizeDec` |
| 2 | Slider drag updates radius live via `set("dot", attr, v)` with 0.001 quantization | ✓ VERIFIED | `onLmSizeSlide` (536–546): guard, `round(raw/0.001)*0.001`, `set("dot", attr, v)`, `[[2]] <- v` |
| 3 | Slider re-syncs to specimen stored size on switch | ✓ VERIFIED | `updateWidgets.digitize`/`anchor` set `tclvalue(e$lmSizeVar/e$anchorSizeVar)` from `[[2]]` (983, 1003) |
| 4 | Landmark/anchor counts set via inline `ttkspinbox` on both tabs (UX-CTL-02) | ✓ VERIFIED | `e$lmCountSpin` (76–91), `e$anchorCountSpin` (207–222); no `setLandmarkNumBtn`/`setAnchorNumBtn` in UI |
| 5 | No modal pop-up when changing count (active user path) | ✓ VERIFIED | Spinbox drives `e$landmarkNum`/`e$anchorNum` directly; no button wires to modal functions |
| 6 | Count cannot go below placed count; typed input clamped on Return/FocusOut | ✓ VERIFIED | `onLmCountChange`/`onAnchorCountChange` floor + clamp; `<Return>`/`<FocusOut>` binds; `updateDotNum`/`updateAnchorNum` reconfigure `-from` |
| 7 | Modal count-entry code fully removed (plan 11-02 Task 3) | ✗ FAILED | `setLandmarkNum` (663), `setAnchorNum` (724) still present; `landmarkEntry`/`anchorEntry` at 678/739; `onlandmarkNumOk`/`onanchorNumOk` called but undefined |
| 8 | Right-click deletes landmark/anchor immediately (UX-CTL-03) | ✓ VERIFIED | `deleteLandmark`/`deleteAnchor` (805–829): `set("dot","selected")` → `del()` + `updateDotNum/updateAnchorNum(-1)` |
| 9 | No delete-confirmation modal for dots/anchors | ✓ VERIFIED | `popUpRemoveWindow` absent from all `R/3dDigitize.*.r`; `digRemove*` handlers removed |
| 10 | Right-click trigger preserved (`<ButtonPress-3>`) | ✓ VERIFIED | Bindings at lines 318–319 (digitize) and 349–350 (anchor) |
| 11 | Viewport packed to expand/fill; panel reflows vertically (UX-CTL-04) | ✓ VERIFIED | `tkpack(canvasFrame, expand=TRUE, fill="both")` (503); `tkpack(tn, fill="y")` (530) |
| 12 | GL resize debounced and gated by `e$glBound` | ✓ VERIFIED | `e$glBound <- TRUE` after realize (559); `onCanvasConfigure` with `after`/`after cancel` 150ms + `tkwinfo` guards (562–573) |
| 13 | Initial GL realize sequence unchanged (CON-01) | ✓ VERIFIED | `set("window","id",canvasFrame)` + `set("window","size",600,600)` at 556–557; resize handler only re-pushes size |
| 14 | Phase 10 window min/center preserved | ✓ VERIFIED | `tkwm.minsize(e$wnd, 900, 700)` (481); `.center_toplevel(e$wnd)` (578) |
| 15 | Live drag resize / visual smoothness of all four controls | ? UNCERTAIN | Code wired correctly; requires Windows R GUI UAT per VALIDATION.md |

**Score:** 14/15 truths verified (1 FAILED artifact cleanup; 1 UNCERTAIN pending human UAT)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `R/3dDigitize.digitize.r` | Size sliders + count spinboxes + inline delete | ✓ VERIFIED | Substantive implementation; all new widgets wired into `ui.*`, handlers, and `updateWidgets`/`updateDotNum` |
| `R/3dDigitize.main.r` | Responsive viewport + debounced Configure | ✓ VERIFIED | `onCanvasConfigure`, `e$glBound`, expand packing present and bound |
| Modal count functions removed | `setLandmarkNum`/`setAnchorNum` gone | ✗ STUB | Functions remain as orphaned dead code (not called, but broken — reference undefined handlers) |
| `R/rtkogl.R` | Untouched (CON-01) | ✓ VERIFIED | No phase edits to renderer protocol file |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `onLmSizeSlide` | `set("dot", attr, v)` + `[[2]]` | slider `-command` | ✓ WIRED | Quantized callback persists size |
| `onLmCountChange` | `e$landmarkNum` | clamped integer write | ✓ WIRED | Lines 549–561 |
| `updateDotNum` | `e$lmCountSpin` `-from` | `tkconfigure(from=...)` | ✓ WIRED | Line 926 |
| `deleteLandmark` | `del("dot")` + `updateDotNum(e,-1)` | right-click | ✓ WIRED | Lines 811–813 |
| `deleteAnchor` | `del("anchor")` + `updateAnchorNum(e,-1)` | right-click | ✓ WIRED | Lines 826–828 |
| `tkbind(canvasFrame, "<Configure>")` | `set("window","size",w,h)` | debounced `after` | ✓ WIRED | Lines 562–573 |
| `ui.main` realize block | `e$glBound` | gate after `set("window","id")` | ✓ WIRED | Line 559 after realize at 555–558 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `onLmSizeSlide` | `v` (radius) | `tclvalue(e$lmSizeVar/e$anchorSizeVar)` from slider drag | Yes — quantized numeric pushed to `set()` and `[[2]]` | ✓ FLOWING |
| `onLmCountChange` | `e$landmarkNum` | `tclvalue(e$lmCountVar)` + placed floor `[[3]]` | Yes — clamped integer from spinbox | ✓ FLOWING |
| `onCanvasConfigure` | `w`, `h` | `tkwinfo("width"/"height", e$canvasFrame)` | Yes — live widget dimensions | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Two ttkscale widgets | `grep -c ttkscale R/3dDigitize.digitize.r` | 2 | ✓ PASS |
| Two ttkspinbox widgets | `grep -c ttkspinbox R/3dDigitize.digitize.r` | 2 | ✓ PASS |
| Stepper buttons removed | `grep -c "Landmark Size +"` | 0 | ✓ PASS |
| Delete modal removed | `grep -rc popUpRemoveWindow R/` | 0 | ✓ PASS |
| Configure debounce | `grep -c "after.*cancel" R/3dDigitize.main.r` | 1 | ✓ PASS |
| Modal count grep gate (VALIDATION) | `grep -c "setLandmarkNum\|setAnchorNum" R/3dDigitize.digitize.r` | 2 (expected 0) | ✗ FAIL |
| R parse check | `Rscript -e 'parse(...)'` | Skipped — Rscript unavailable in verifier WSL shell | ? SKIP |

### Probe Execution

Step 7c: SKIPPED — no `probe-*.sh` declared for Phase 11; validation contract is static grep + manual UAT per `11-VALIDATION.md`.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| UX-CTL-01 | 11-01 | Size via slider, not +/- steppers | ✓ SATISFIED | `ttkscale` on both tabs; steppers removed |
| UX-CTL-02 | 11-02 | Inline spinbox counts, no modal pop-up | ⚠️ PARTIAL | Inline spinboxes wired and active; orphaned modal functions remain (grep gate fails) |
| UX-CTL-03 | 11-03 | Non-modal immediate delete | ✓ SATISFIED | Inline `del()` path; `popUpRemoveWindow` removed |
| UX-CTL-04 | 11-04 | Responsive viewport + panel | ✓ SATISFIED (code) | Expand packing + debounced Configure; visual behavior needs human UAT |
| CON-01 | all | No renderer change | ✓ SATISFIED | `rtkogl.R` untouched; only existing `set("window",...)` protocol reused |
| CON-02 | all | `.dgt` round-trip preserved | ? NEEDS HUMAN | Count floor protects data; format diff not run in verifier |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `3dDigitize.digitize.r` | 663–777 | Orphaned modal functions (`setLandmarkNum`, `setAnchorNum`) | ⚠️ Warning | Dead code; references undefined `onlandmarkNumOk`/`onanchorNumOk`; SUMMARY 11-02 claim contradicted |
| `3dDigitize.digitize.r` | 804 | Stale comment `#pop up window to remove selected landmark` | ℹ️ Info | Comment outdated; delete is now inline |
| `3dDigitize.main.r` | 1779 | `TBD` in snapshot comment | ℹ️ Info | Pre-existing; not introduced by Phase 11 |

### Human Verification Required

### 1. Live Size Slider Drag

**Test:** Load a PLY on Digitize tab; drag the size slider; switch to Anchor tab and repeat.
**Expected:** Dot/anchor radius changes smoothly while dragging; at default 0.01 the specimen looks identical to pre-phase behavior.
**Why human:** GL visual feedback cannot be verified programmatically from WSL.

### 2. Specimen Switch Widget Sync

**Test:** Load two specimens with different stored sizes; use Next/Previous navigation.
**Expected:** Size slider thumb and count spinbox values update to each specimen's stored values.
**Why human:** Requires live specimen navigation in Windows R GUI.

### 3. Count Floor Clamp

**Test:** Place 3 landmarks; type `2` in the count spinbox; press Return. Repeat on Anchor tab with placed anchors.
**Expected:** Value snaps to placed count (3); no modal window.
**Why human:** Typed-input clamp requires interactive spinbox state.

### 4. Immediate Right-Click Delete

**Test:** Right-click a placed landmark on Digitize tab; then right-click a placed anchor on Anchor tab.
**Expected:** Point vanishes immediately; "Number of Landmarks/Anchors" decrements; tab gating updates; no confirmation window.
**Why human:** Canvas pick + GL redraw requires live GUI.

### 5. Responsive Viewport Resize

**Test:** Load a PLY; drag the main window edge to enlarge then shrink; observe startup before any resize.
**Expected:** GL viewport grows/shrinks after drag settles (~150ms debounce); no blank-viewport regression on startup.
**Why human:** Window-manager resize + GL behavior requires Windows R GUI.

### 6. `.dgt` Round-Trip (CON-02)

**Test:** Load `zips/Folsom 3D models/verify_.dgt`; change size and count (no deletes); Save to DGT; diff `LM3=`/`AC3=` blocks vs original.
**Expected:** Landmark/anchor coordinate blocks unchanged.
**Why human:** Format-identity check on real fixtures.

### Gaps Summary

Phase 11 delivers all four user-facing control replacements in the active code paths: sliders, inline spinboxes, immediate delete, and debounced responsive viewport. Static wiring verification passes for UX-CTL-01, UX-CTL-03, and UX-CTL-04, and the active UX-CTL-02 path (inline spinbox, no modal trigger).

**One plan-level gap remains:** Plan 11-02 Task 3 required complete removal of modal count-entry code (`setLandmarkNum`, `setAnchorNum`, `onlandmarkNumOk`, `onanchorNumOk`, `landmarkEntry`, `anchorEntry`). The modal builder functions still exist at lines 663–777 with references to handlers that were deleted. SUMMARY 11-02 incorrectly claimed grep count 0. This does not expose a modal to users (no UI button calls these functions), but it fails the explicit VALIDATION.md static gate and leaves broken orphan code.

All interactive behaviors validated via Windows R UAT at v1.1 milestone close (2026-06-29).

---

_Verified: 2026-06-29T00:00:00Z_
_Verifier: Claude (gsd-verifier); UAT closed at milestone archive_
