---
phase: 06-shell-and-native-retirement
plan: 05
subsystem: ui
tags: [tcltk, tk-strip, engine-verbs, color-picker, dgt-serializer, source-scan, R]

# Dependency graph
requires:
  - phase: 06-shell-and-native-retirement
    provides: "Plan 01 /color route (session #rrggbb storage) + shell routes; Plan 03 engine-free entry (GUImorphWeb no longer ui()/init()-dispatches)"
  - phase: 05-full-digitizing-and-data-parity
    provides: "server-driven /pick /anchor /curve routes + server-owned .gmw_session record"
provides:
  - "3dDigitize.digitize.r stripped to the non-Tk data model: default colour state + .dgt landmark/anchor serializers (read/write.digitize, read/write.anchors); zero Tk dialogs/builders, zero add/set/del/shows engine verbs"
  - "3dDigitize.curve.r stripped to the non-Tk curve data model: init.curve + .dgt curve serializers (read/write.curve); zero ui.curve/Tk scaffolding, zero engine verbs"
  - "Anchor/landmark colour selection retired from tk_chooseColor; the browser <input type=color> hex now persists over the Plan-01 /color route onto the session"
  - "tests/testthat/test-digitize-curve-stripped.R: comment-stripped source-scan guard proving both files are Tk/engine-free and the serializers survive"
affects: [06-06-dialog-replacements, 06-07-rtkogl-deletion, 06-08-description-namespace]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Strip-to-data/model+serializers: delete the native/Tk interaction handlers wholesale (matching Plan 06-04's main.r strip); keep only the .dgt serializers and non-Tk state init"
    - "Comment-stripped source-scan gate: sub('#.*$','') before grepl so kept header prose naming the removed tokens cannot self-trip the negative gate"
    - "Test-inversion on strip: source-scan tests that asserted the presence of now-deleted native/Tk code are inverted to assert absence (mirrors Plan 06-03's macOS test repointing)"

key-files:
  created:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-digitize-curve-stripped.R"
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.curve.r"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-digitizing-parity-macos.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-macos-input-core.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-macos-dialog-shortcuts-parity.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-undo-helpers.R"

key-decisions:
  - "Strip both files to data/model + serializers only (verbatim-kept read/write.digitize, read/write.anchors, read/write.curve, init.digitize, init.curve), deleting every native-engine/Tk interaction handler — the same posture Plan 06-04 took with main.r, since the browser + transport + session own all interaction now"
  - "Colour wiring: tk_chooseColor removed from digitize.r; the R-side colour state is the /color session slot (Plan 01) fed by the browser <input type=color> (Plan 02). digitize.r keeps only the default e$dColor/e$daColor state; no stub colour accessor was added (there is no surviving R consumer of the native colour path)"
  - "Four pre-existing source-scan tests that asserted the PRESENCE of the deleted native/Tk code (.setMissStatus miss-feedback, onSelectCurve's duplicate-landmark guard, bind.digitize's bindDeleteGesture/tkbind, ui.curve's shortcutLabel) were inverted to assert absence — a Rule 1 fix for breakage this strip directly caused, matching the Plan 06-03 pattern"

patterns-established:
  - "Wave-3 file ownership honoured: only 3dDigitize.digitize.r + 3dDigitize.curve.r + this plan's test file were edited as source; the four inverted tests touch ONLY their digitize/curve assertions, leaving the surface (Plan 06-06) half of the shared-helper test intact"

requirements-completed: [UI-01, UI-02]

coverage:
  - id: D1
    description: "digitize.r carries no Tk dialogs/builders (no tkgetOpenFile, tk_chooseColor, tktoplevel, tkgrid, tkpack, ui.digitize, ui.anchor)"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitize-curve-stripped.R#digitize.r has no Tk dialogs/builders (UI-01)"
        status: pass
    human_judgment: false
  - id: D2
    description: "digitize.r carries no native engine verbs (add/set/del/shows)"
    requirement: "UI-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitize-curve-stripped.R#digitize.r has no native engine verbs (UI-02)"
        status: pass
    human_judgment: false
  - id: D3
    description: "curve.r carries no Tk builder (ui.curve) or tk2* widgets"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitize-curve-stripped.R#curve.r has no Tk builder or tk2 widgets (UI-01)"
        status: pass
    human_judgment: false
  - id: D4
    description: "curve.r carries no native engine verbs (add/set/del/shows)"
    requirement: "UI-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitize-curve-stripped.R#curve.r has no native engine verbs (UI-02)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The kept .dgt serializers (read/write.digitize, read/write.anchors, read/write.curve) survive the strip and still round-trip"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitize-curve-stripped.R#the kept .dgt serializers survive the strip (no over-strip, T-6-15)"
        status: pass
      - kind: unit
        ref: "tests/testthat/test-curve-io.R#write.curve and read.curve round-trip a 3-column integer matrix"
        status: pass
    human_judgment: false
  - id: D6
    description: "Anchor/landmark colour selection uses the browser <input type=color> persisted over the /color route instead of tk_chooseColor; the validated #rrggbb reaches the R-side session colour state"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitize-curve-stripped.R#digitize.r has no Tk dialogs/builders (UI-01) (tk_chooseColor absent)"
        status: pass
      - kind: unit
        ref: "tests/testthat/test-transport.R#POST /color stores a #rrggbb hex and drops a non-hex body (Plan 01)"
        status: pass
    human_judgment: false

# Metrics
duration: 20min
completed: 2026-08-14
status: complete
---

# Phase 6 Plan 05: Digitize + Curve Tk/Engine Strip Summary

**`3dDigitize.digitize.r` (1,259 lines removed) and `3dDigitize.curve.r` (237 lines removed) were stripped to their non-Tk data model — the `.dgt` landmark/anchor/curve serializers plus default colour state — deleting every Tk dialog/builder (`ui.digitize`/`ui.anchor`/`ui.curve`, the Set-Landmark/Anchor-Number toplevels, `tkgetOpenFile`, both `tk_chooseColor` sites) and every native `add`/`set`/`del`/`shows` engine verb, with anchor/landmark colour now flowing browser `<input type=color>` → `/color` (Plan 01) → session (UI-01/UI-02).**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-08-14
- **Tasks:** 3 (+ collateral test inversions)
- **Files modified:** 7 (1 created, 6 modified)

## Accomplishments
- Stripped `3dDigitize.digitize.r` from 1,458 → 213 lines: deleted `ui.digitize`/`ui.anchor`, the Set-Landmark-Number / Set-Anchor-Number `tktoplevel`s, the `tkgetOpenFile` landmark loader, both `tcl('tk_chooseColor')` sites, and every native-engine handler (`addDot`/`addAnchor`, `deleteLandmark`/`deleteAnchor`, `onLeftBtnPress`/`onLeftBtnRelease`, `draw.digitize`/`draw.anchors`, `doUndo`, the colour/label/size setters). Kept the non-Tk data model: `init.digitize` default colour state + the `.dgt` serializers `read.digitize`/`read.anchors`/`write.digitize`/`write.anchors`.
- Stripped `3dDigitize.curve.r` from 322 → 93 lines: deleted `ui.curve`, `bind.curve`, `onSelectCurve`, `draw.curves`, `changeDotColor`, `.redrawAllCurves`/`.clearAllCurves` (all native `add`/`set`/`shows`). Kept `init.curve` + the `.dgt` serializers `read.curve`/`write.curve`; curve selection/drawing remain server-driven over the Phase-5 `/curve` route.
- Retired `tk_chooseColor`: the anchor/landmark colour is now the browser `<input type=color>` `#rrggbb` value posted to the Plan-01 `/color` route and stored on the session; `digitize.r` keeps only the default `e$dColor`/`e$daColor` R-side state.
- Added `tests/testthat/test-digitize-curve-stripped.R` — a comment-stripped source-scan proving both files are free of Tk dialogs/builders and engine verbs, and that the six `.dgt` serializers survive (T-6-15 over-strip guard).
- Inverted four pre-existing source-scan tests that asserted the now-deleted native/Tk code (Rule 1 fix for the breakage this strip caused).

## Task Commits

Each task was committed atomically:

1. **Task 1: Strip Tk builders/dialogs + engine verbs from digitize.r** - `d0b2245` (refactor)
2. **Task 2: Strip Tk builder + engine verbs from curve.r** - `ec87f7c` (refactor)
3. **Collateral: repoint 4 stale digitize/curve source-scan tests** - `c705e2f` (test)
4. **Task 3: Add Tk/engine-free source-scan for both files** - `526076f` (test)

**Plan metadata:** skipped (`commit_docs: false` in `.planning/config.json` — `.planning/` docs are intentionally kept out of git history)

_Note: Task 3 carries `tdd="true"`, but the plan sequences implementation (Tasks 1–2) before the test (Task 3) — identical ordering to Plans 06-01/06-02/06-03/06-04 — so a genuine RED-against-absent-code commit was not possible. The test is a real gate, not a tautology: it references the banned tokens by pattern against comment-stripped code and would fail against the pre-strip 1,458-line file (which held ~104 such call sites). See TDD Gate Compliance below._

## Files Created/Modified
- `R/3dDigitize.digitize.r` — stripped to `get_digitize_date`, `init.digitize` (data-model state, engine `set()` calls removed), and the `read/write.digitize` + `read/write.anchors` serializers; architectural pointer comment records the `/color` colour path.
- `R/3dDigitize.curve.r` — stripped to `get_curve_date`, `init.curve`, and the `read/write.curve` serializers; pointer comment records the `/curve` server-driven path.
- `tests/testthat/test-digitize-curve-stripped.R` (new) — the Tk/engine-free + serializers-survive source-scan gate.
- `tests/testthat/test-digitizing-parity-macos.R` — inverted the two digitize/curve assertions (native miss-feedback + `onSelectCurve` are gone); surface assertion (test 3) untouched for Plan 06-06.
- `tests/testthat/test-macos-input-core.R` — inverted the "digitize bindings use centralized helpers" test to assert the Tk canvas bindings (`bindDeleteGesture`/`tkbind`) are removed.
- `tests/testthat/test-macos-dialog-shortcuts-parity.R` — inverted the curve half (`shortcutLabel` gone from `curve.r`); left the surface `zoom(...normalizeWheelDelta...)` assertion for Plan 06-06.
- `tests/testthat/test-undo-helpers.R` — inverted test 4 to assert `onSelectCurve` moved server-side (and `tkmessageBox` stays absent).

## Decisions Made
- **Strip-to-data/model+serializers, not gut-in-place.** Removing engine verbs from handlers like `addDot`/`onSelectCurve` would leave broken, misleading shells (their control flow is the engine call). Consistent with the phase goal (browser owns interaction; UI-02 engine-absent) and Plan 06-04's main.r strip, the native/Tk handlers were deleted wholesale and only the `.dgt` serializers + non-Tk state init were kept.
- **No stub colour accessor.** The colour wiring (browser input → `/color` → `s$color`) already lives in Plans 01/02; `digitize.r`'s only job was to stop using `tk_chooseColor` and keep the default colour state. Adding a token-keyed session-colour reader in `digitize.r` would be a caller-less stub, so it was omitted (stubs are discouraged); a concise architectural pointer comment documents the `/color` path instead.
- **Kept `read/write.digitize`/`read/write.anchors`/`read/write.curve` byte-identical** — they are the "landmark/anchor/curve DATA logic" the plan protects (T-6-15) and are exercised by `test-curve-io.R` and `test-dgt-cross-platform.R`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Four pre-existing source-scan tests inverted after the strip**
- **Found during:** Task 1/Task 2 (the strip removed code these tests asserted PRESENT)
- **Issue:** `test-digitizing-parity-macos.R` (asserted `.setMissStatus` + 4 call sites in `digitize.r`, and "Curve selection missed a landmark" in `curve.r`), `test-macos-input-core.R` (asserted `zoom(e, normalizeWheelDelta(D))` + `bindDeleteGesture(...)` in `digitize.r`), `test-macos-dialog-shortcuts-parity.R` (asserted `shortcutLabel("[")` in `curve.r`), and `test-undo-helpers.R` test 4 (asserted "Duplicate landmark in this curve segment" in `curve.r`) all assert the presence of native/Tk code that this plan deletes. They inverted to failures — the exact "test inversion" pattern RESEARCH Pitfall 6 flagged and Plan 06-03 handled for its macOS tests.
- **Fix:** Rewrote each affected assertion to assert the code is GONE (and the `.dgt` serializers survive), touching only the digitize/curve halves. The surface half of the shared-helper test (`test-macos-dialog-shortcuts-parity.R` test 5) and surface test (`test-digitizing-parity-macos.R` test 3) were left intact for Plan 06-06.
- **Files modified:** `test-digitizing-parity-macos.R`, `test-macos-input-core.R`, `test-macos-dialog-shortcuts-parity.R`, `test-undo-helpers.R`
- **Verification:** All four filters green (`digitizing-parity-macos`, `macos-input-core`, `macos-dialog-shortcuts-parity`, `undo-helpers`); full suite 128 tests / 0 failed.
- **Committed in:** `c705e2f`

---

**Total deviations:** 1 auto-fixed (Rule 1 bug — test inversions). **Impact:** Necessary to keep the suite green after the strip; no source scope creep (only test assertions changed, and only their digitize/curve halves).

## Issues Encountered
- **`devtools` not installed** (same as Plans 06-01/06-03) — the plan's `devtools::load_all()` / `devtools::test(filter=...)` verifies were run as `testthat::test_dir("tests/testthat", filter=...)` plus a `parse()` sweep over every `R/` file (all parse clean). Bare R hangs under the workspace `renv` activate (known STATE open item), so every run used `Rscript --no-init-file`. `rtk` is not installed on this host (RESEARCH noted the same), so commands ran raw.
- **`rtk` prefix unavailable** — `.cursorrules` asks to prefix commands with `rtk`, but `command -v rtk` returns not-found on this machine (it is a passthrough with zero behaviour change when present), so commands were run without it.

## Pre-existing Failures (not introduced here, out of scope)
- `test-curve-io.R` "handle empty curve matrix" (1 error): `read.curve` calls `dbg("No curve data to process")` on an empty matrix, and `dbg` is undefined when `curve.r` is sourced standalone. `read.curve`/`write.curve` were kept byte-identical, so this is unchanged from before the strip (documented in the 06-03 summary).
- `test-curve-spinbox.R` (2 errors): `.clampCurveMax`/`.clampCurveCurrent` do not exist in `curve.r` (deleted upstream — STATE "2 tests call functions Austin deleted"). Untouched by this plan.

## TDD Gate Compliance
Task 3 carries `tdd="true"`, but the plan sequences the strip (Tasks 1–2) ahead of the test (Task 3), so a genuine RED (failing-against-absent-code) commit was not possible — identical to Plans 06-01/06-02/06-03/06-04. The test is a real gate rather than a tautology: it scans comment-stripped code for the banned tokens and would fail against the pre-strip file (which had ~104 `tk*`/engine call sites). Commit types are `refactor` (Tasks 1–2) and `test` (collateral inversions + Task 3).

## Next Phase Readiness
- **Plan 06-06 (surface.r/geomorph.r strip):** unblocked — `digitize.r`/`curve.r` are done and disjoint. Note the shared-helper test (`test-macos-dialog-shortcuts-parity.R` test 5) and `test-digitizing-parity-macos.R` test 3 still assert the surface tab's `zoom(...normalizeWheelDelta...)` / status strings; 06-06 will need to invert those surface halves when it strips `surface.r` (same test-inversion pattern used here).
- **Plan 06-07 (rtkogl.R deletion):** the digitize/curve files no longer reference the engine verbs `add`/`set`/`del`/`shows`, `messageToC`, `showPicture`, `bindDeleteGesture`, or `.overrideCtrlZ`, removing that many call sites ahead of the wholesale `rtkogl.R` delete.
- **Deferred by design:** live-browser colour UAT (the `<input type=color>` → anchor/curve recolour round-trip) remains part of the phase-end manual gate; the R-side removal + `/color` storage is unit-covered here and in Plan 01.

## Self-Check: PASSED

**Created/modified files:**
- FOUND: `R/3dDigitize.digitize.r`
- FOUND: `R/3dDigitize.curve.r`
- FOUND: `tests/testthat/test-digitize-curve-stripped.R`
- FOUND: `.planning/phases/06-shell-and-native-retirement/06-05-SUMMARY.md`

**Task commits:**
- FOUND: `d0b2245` refactor(06-05): strip Tk builders/dialogs + engine verbs from digitize.r
- FOUND: `ec87f7c` refactor(06-05): strip Tk builder + engine verbs from curve.r
- FOUND: `c705e2f` test(06-05): repoint digitize/curve source-scans to the stripped state
- FOUND: `526076f` test(06-05): add Tk/engine-free source-scan for digitize.r + curve.r

**Gates:** digitize.r + curve.r Tk/engine source-scans = 0; new guard 17/17 pass; full suite 128 tests / 0 failed (3 pre-existing errors, 5 skips).

---
*Phase: 06-shell-and-native-retirement*
*Completed: 2026-08-14*
