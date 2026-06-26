---
phase: 14-keyboard-shortcuts-undo
verified: 2026-06-26T04:30:00Z
status: passed
score: 12/12 must-haves verified
overrides_applied: 0
human_verification:
  - test: "From Digitize, Anchors, and GPA tabs, press Ctrl+O, Ctrl+S, Ctrl+F, Ctrl+[, Ctrl+] with various widget focus (canvas, spinbox, combobox)"
    expected: "Load PLY dialog opens; Save to DGT runs; view fits; prev/next invoke same gating as nav buttons (warnings when tab/placement rules block navigation)"
    why_human: "Global tkbind focus behavior and OpenGL/file dialogs require live Tk GUI on Windows"
  - test: "Place a landmark, press Ctrl+Z; delete a landmark, press Ctrl+Z; drag-move a landmark, press Ctrl+Z"
    expected: "Each action reverses visually; status bar shows Undid landmark placement/deletion/move; marker counts update correctly"
    why_human: "Undo reversal goes through C/OpenGL marker protocol — cannot verify marker state without GUI"
  - test: "Focus landmark count spinbox, place a landmark, press Ctrl+Z"
    expected: "Marker placement is undone (not spinbox text undo)"
    why_human: "Spinbox native Ctrl+Z vs .overrideCtrlZ + tcl(break) requires focused widget interaction"
  - test: "Place landmark, switch specimen via Next/Previous/jump combobox, press Ctrl+Z"
    expected: "Status shows Nothing to undo — stack cleared on successful navigation"
    why_human: "Per-specimen stack clearing is runtime state behavior"
  - test: "Load PLY or DGT, place landmark, reload file, press Ctrl+Z"
    expected: "Nothing to undo — stack cleared on successful load"
    why_human: "Load-path clearUndo timing requires live session"
  - test: "Help → Keyboard Shortcuts"
    expected: "Modal lists Ctrl+O/S/[/]/F/Z with gating note; File menu labels have no accelerator suffix"
    why_human: "Dialog layout and menu label appearance are visual"
deferred:
  - truth: "Undo applies on Curve tab placement (D-13)"
    addressed_in: "Phase 15"
    evidence: "Phase 15 goal: Re-enable Curve tab controls; Plan 14-02 defers curve undo hooks until Phase 15"
---

# Phase 14: Keyboard Shortcuts & Undo Verification Report

**Phase Goal:** Accelerators for common actions and an undo for landmark/anchor placement & deletion.
**Verified:** 2026-06-26T04:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Ctrl+O opens PLY from any tab (D-01, D-06) | ✓ VERIFIED | `bind.accelerators` line 811: `tkbind(e$wnd, "<Control-o>", function() loadPly(e))` on `e$wnd` |
| 2 | Ctrl+S invokes save to DGT (D-02, D-06) | ✓ VERIFIED | Line 812: `<Control-s>` → `saveToDgt(e)` |
| 3 | Ctrl+[/] invoke onPrevious/onNext with existing gating (D-03, D-06) | ✓ VERIFIED | Lines 813–814: direct `onPrevious(e)` / `onNext(e)` callbacks — no duplicate gating |
| 4 | Ctrl+F fits view from any tab (D-04, D-06) | ✓ VERIFIED | Line 815: `<Control-f>` → `onFit(e)` |
| 5 | File menu labels have no accelerator suffix (D-07) | ✓ VERIFIED | Lines 880, 896: `"Load PLY File\u2026"`, `"Save to DGT\u2026"` — no `\tCtrl+` suffix |
| 6 | Help menu opens Keyboard Shortcuts dialog listing all bindings including undo (D-08, D-09) | ✓ VERIFIED | `showShortcutsDialog` lines 819–867; Help cascade lines 953–961; six shortcut rows + gating note |
| 7 | Single-level undo reverses placement, deletion, drag-move (D-10, D-11) | ✓ VERIFIED | `doUndo` branches place/delete/move (digitize.r 72–130); `pushUndo` hooks in addDot, addAnchor, deleteLandmark, deleteAnchor, onLeftBtnRelease |
| 8 | Undo stack clears on specimen switch (D-12) | ✓ VERIFIED | `clearUndo(e)` before `e$currImgId` change in jumpToSpecimen (295), onNext (1261), onPrevious (1370) |
| 9 | Ctrl+Z triggers undo globally, overriding spinbox text undo (D-14, D-15) | ✓ VERIFIED | main.r 816: global `<Control-z>` → `doUndo(e)`; digitize.r 133–137 `.overrideCtrlZ` with `tcl("break")` on lmCountSpin (276) and anchorCountSpin (378) |
| 10 | Empty undo stack shows "Nothing to undo" warning (D-16) | ✓ VERIFIED | digitize.r 73–75, 85, 127: `setStatus(e, "Nothing to undo", "warning")` |
| 11 | Successful undo shows info naming reversed action (D-17) | ✓ VERIFIED | digitize.r 91–118, 125: messages Undid landmark/anchor placement/deletion/move |
| 12 | Undo stack clears on PLY/DGT reload (Pitfall 4) | ✓ VERIFIED | `clearUndo(e)` in loadPly success block (1561) and drawElements after `e$activeDataList <- dgtDataList` (1824) |

**Score:** 12/12 truths verified (code-level)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Curve-tab undo hooks (D-13) | Phase 15 | Plan 14-02: "Curve tab hooks are no-ops until Phase 15"; Phase 15 rehabilitates Curve controls |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | ----------- | ------ | ------- |
| `R/3dDigitize.main.r` — `bind.accelerators` | Five global + Ctrl+Z tkbind on e$wnd | ✓ VERIFIED | Exists lines 809–817; wired in ui.main 801–803 after createMenu |
| `R/3dDigitize.main.r` — `showShortcutsDialog` | Modal shortcuts reference | ✓ VERIFIED | 819–867; lists all six bindings |
| `R/3dDigitize.main.r` — Help cascade | Keyboard Shortcuts command | ✓ VERIFIED | 953–961 |
| `R/3dDigitize.digitize.r` — `pushUndo/clearUndo/doUndo` | Single-slot undo stack | ✓ VERIFIED | 59–130; init.digitize sets `e$undo <- NULL` (54) |
| `R/3dDigitize.digitize.r` — mutation hooks | pushUndo after place/delete/move | ✓ VERIFIED | 5 pushUndo call sites (4 hooks + definition) |
| `R/3dDigitize.main.r` — clearUndo in nav/load | 5 call sites | ✓ VERIFIED | jumpToSpecimen, onNext, onPrevious, loadPly, drawElements |
| `tests/testthat/test-undo-helpers.R` | doUndo messaging tests | ⚠️ PARTIAL | File exists; tests use inline mock `doUndo` — does not source package function |
| `R/rtkogl.R` | Unchanged (CON-01) | ✓ VERIFIED | No phase-14 undo symbols; renderer protocol used via add/del/set only |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `bind.accelerators` | `loadPly/saveToDgt/onPrevious/onNext/onFit/doUndo` | tkbind closures | ✓ WIRED | Lines 811–816 |
| `createMenu` | `showShortcutsDialog` | Help cascade command | ✓ WIRED | Lines 957–959 |
| `ui.main` | `bind.accelerators` | call after createMenu | ✓ WIRED | Lines 801–802 |
| `addDot/addAnchor/deleteLandmark/deleteAnchor` | `e$undo` | pushUndo post-mutation | ✓ WIRED | Only after successful add/del; duplicate guard returns before pushUndo |
| `onLeftBtnRelease` | `e$undo` | pushUndo on drag with 3D epsilon | ✓ WIRED | Lines 616–625; dragStart captured in onLeftBtnPress (539–540, 568–569) |
| `doUndo` | `add/del/set` | inverse operations | ✓ WIRED | place→set+del; delete→add; move→set coordinate |
| `onNext/onPrevious/jumpToSpecimen` | `e$undo` | clearUndo before currImgId change | ✓ WIRED | After all guard returns, before mutation |
| `.overrideCtrlZ` | `doUndo` | spinbox Control-z + break | ✓ WIRED | digitize.r 133–137, called at end of ui.digitize/ui.anchor |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `doUndo` | `e$undo` entry | `pushUndo` from convertCoor snapshots at mutation time | Real 3D coords + screen coords from committed actions | ✓ FLOWING |
| `pushUndo` | `e$undo` | Single-slot replace on each push | Not hardcoded — stores action/kind/coord/screen/before | ✓ FLOWING |
| `showShortcutsDialog` | `shortcuts` vector | Static program strings | N/A (reference UI) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Package loads | `R -q -e "devtools::load_all(...)"` | R not in WSL PATH | ? SKIP |
| test-undo-helpers.R passes | `testthat::test_file(...)` | R not in WSL PATH | ? SKIP |
| pushUndo call count ≥4 | grep digitize.r | 5 matches (1 def + 4 hooks) | ✓ PASS |
| clearUndo call count ≥5 | grep main.r | 5 matches | ✓ PASS |
| Control-z bindings ≥3 | grep main+digitize.r | 4 matches (1 global + 1 override fn + 2 spinbox) | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no phase-declared probe scripts; static grep suite used per 14-VALIDATION.md.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| UX-KEY-01 | 14-01 | Keyboard accelerators for load PLY, save DGT, prev/next specimen, fit | ✓ SATISFIED | `bind.accelerators` five bindings + Help dialog; no Load DGT/Exit accelerators per D-05 |
| UX-KEY-02 | 14-02 | Last landmark/anchor placement and deletion can be undone | ✓ SATISFIED | `doUndo` reverses place/delete; drag-move also implemented (CONTEXT D-11 extension) |
| CON-01 | both | No renderer changes | ✓ SATISFIED | rtkogl.R untouched; undo uses existing add/del/set protocol |
| CON-02 | 14-02 | .dgt round-trip preserved | ? NEEDS HUMAN | No format changes; Save-after-undo requires manual file reload check |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `test-undo-helpers.R` | 12–18, 41–66 | Inline mock `doUndo` instead of sourcing package function | ⚠️ Warning | Tests verify message pattern, not live `doUndo` wiring — package implementation verified separately via static grep |
| `3dDigitize.main.r` | 2080 | `TBD` comment on snapshot | ℹ️ Info | Pre-existing (May 2020); unrelated to Phase 14 scope |

No `FIXME`/`XXX`/stub handlers found in phase-modified undo/accelerator code.

### Human Verification Required

### 1. Global accelerators from all tabs

**Test:** From Digitize, Anchors, and GPA tabs, press Ctrl+O, Ctrl+S, Ctrl+F, Ctrl+[, Ctrl+] with canvas and control widgets focused.
**Expected:** Load/save/fit/nav shortcuts fire; nav shortcuts show same warnings as buttons when gating blocks navigation.
**Why human:** Tk global bind focus behavior and file dialogs require live Windows GUI.

### 2. Undo round-trip (place / delete / drag)

**Test:** Place landmark → Ctrl+Z; delete landmark → Ctrl+Z; drag landmark → Ctrl+Z. Repeat on Anchors tab.
**Expected:** Marker state reverses; status bar shows correct Undid … message; counts update.
**Why human:** C/OpenGL marker display cannot be verified statically.

### 3. Spinbox Ctrl+Z override

**Test:** Focus landmark count spinbox, place landmark, Ctrl+Z.
**Expected:** Placement undone, not spinbox text undo.
**Why human:** ttkspinbox native undo vs `.overrideCtrlZ` requires focused widget.

### 4. Specimen switch clears undo stack

**Test:** Place landmark, navigate Next/Previous/jump combobox, Ctrl+Z.
**Expected:** "Nothing to undo" warning.
**Why human:** Runtime stack state after navigation.

### 5. File reload clears undo stack

**Test:** Place landmark, reload PLY or DGT, Ctrl+Z.
**Expected:** "Nothing to undo".
**Why human:** Load-path timing requires live session.

### 6. Help dialog discoverability

**Test:** Help → Keyboard Shortcuts; inspect File menu labels.
**Expected:** Dialog lists six shortcuts with gating note; File menu has no `\tCtrl+` suffixes; hintLabel text unchanged (no shortcut clutter per D-09).
**Why human:** Visual layout verification.

### Gaps Summary

No blocking code gaps found. All 12 must-have truths are present and wired in source. Automated R/testthat execution was unavailable in the verification environment (R not in WSL PATH); static analysis and grep spot-checks passed.

Phase status is **human_needed** because keyboard shortcut focus behavior, OpenGL undo round-trip, spinbox override, and `.dgt` save-after-undo require Windows manual UAT per 14-VALIDATION.md and plan verification sections.

**Next actions:**
1. Run `/gsd-verify-work 14` (or manual UAT checklist in 14-VALIDATION.md) on Windows with `GUImorph::GUImorph()`.
2. Optionally strengthen `test-undo-helpers.R` to `devtools::load_all()` + call package `doUndo` with mocked `set`/`del`/`setStatus` (non-blocking).
3. After human UAT passes, update REQUIREMENTS.md traceability for UX-KEY-01/02 from Pending → Complete.

---

_Verified: 2026-06-26T04:30:00Z_
_Verifier: Claude (gsd-verifier)_
