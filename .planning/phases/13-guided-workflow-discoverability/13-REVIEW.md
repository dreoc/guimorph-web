---
phase: 13-guided-workflow-discoverability
reviewed: 2026-06-25T22:45:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
  - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r
findings:
  critical: 1
  warning: 3
  info: 1
  total: 5
status: clean
---

# Phase 13: Code Review Report

**Reviewed:** 2026-06-25T22:45:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** clean (CR-01, WR-01–03 resolved in b0e7c6b)

## Summary

Phase 13 adds unified tab gating (`refreshTabGating`), disabled-tab status explanations, a step indicator, placement hints, a jump-to specimen combobox, and specimen counter copy. The PLY load path (`loadPly`) wires gating and combobox population correctly after `e$activeDataList` is set. The DGT load path (`openDgt` → `drawElements`) has a **call-order regression**: `refreshTabGating` and `populateSpecimenCombo` run while `e$activeDataList` is still empty, and are never re-invoked after the list is built — leaving Anchors locked, GPA locked, and the combobox empty/disabled after opening a `.dgt` file. Secondary warnings cover missing gating refresh after `loadLandmark`, unguarded `basename` in `showPicture`, and hint text not updating until the user switches tabs.

## Critical Issues

### CR-01: `drawElements` refreshes gating/combobox before `e$activeDataList` exists (DGT load broken)

**File:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r:1556-1558`
**Issue:** `refreshTabGating(e)`, `populateSpecimenCombo(e)`, and `updateStepLabel(e)` are called immediately after the Place Anchors checkbox block, but `e$activeDataList` is not assigned until line 1744 (after the specimen loop). `openDgt` calls `init.main` first (which clears `e$activeDataList`), so at line 1556 `length(e$activeDataList) == 0`. `refreshTabGating` therefore keeps Anchors and GPA disabled (`loaded <- FALSE`). `populateSpecimenCombo` disables the combobox and clears values. `openDgt` ends with `showPicture(e)`, which calls `updateStepLabel` and `refreshNavButtons` but **not** `refreshTabGating` or `populateSpecimenCombo`, so the wrong state persists for the entire DGT session. This is a regression from the pre-13 anchor-tab enable block, which enabled tab 1 based on anchor data without requiring `activeDataList` length.

**Fix:** Move the three calls to after `e$activeDataList <- dgtDataList` (line 1744), or add a second invocation there / at the end of `openDgt` before `showPicture`:

```r
    e$activeDataList <- dgtDataList

    refreshTabGating(e)
    populateSpecimenCombo(e)
    updateStepLabel(e)

    tkconfigure(e$specimenNumLabel,
                text = paste("Number of Specimens: ", nSpecimens))
```

Remove (or relocate) the premature calls at lines 1556–1558.

## Warnings

### WR-01: `loadLandmark` updates landmark count without refreshing tab gating

**File:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r:778-781`
**Issue:** `loadLandmark` sets `e$activeDataList[[e$currImgId]][[3]] <- e$landmarkNum` directly but does not call `refreshTabGating(e)` or `updateStepLabel(e)`. If loading a landmark file completes the required count, the GPA tab stays disabled until the user navigates or places another point. `updateDotNum` is bypassed, so the unified gating predicate is stale.

**Fix:** After updating `[[3]]`, call `refreshTabGating(e)` and `updateStepLabel(e)` (and optionally align `setStatus` copy with `updateDotNum`).

### WR-02: `showPicture` calls `basename` without a null/empty path guard

**File:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r:959-963`
**Issue:** Neutral status copy uses `basename(e$activeDataList[[e$currImgId]][[1]])` with no guard. `refreshNavButtons` and `populateSpecimenCombo` both handle `is.null(p) || !nzchar(p)`; `showPicture` does not. A specimen entry with a missing path (e.g. after a failed existence check in `drawElements`) will throw when `showPicture` runs.

**Fix:** Mirror the fallback used in `refreshNavButtons`:

```r
    p <- e$activeDataList[[e$currImgId]][[1]]
    nm <- if (is.null(p) || !nzchar(p)) paste0("specimen ", e$currImgId) else basename(p)
    setStatus(e,
      paste0("Specimen ", e$currImgId, " of ", length(e$activeDataList),
             " \u2014 ", nm),
      "neutral")
```

### WR-03: Placement hint not updated on specimen load — only on tab switch

**File:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r:395-401`
**Issue:** `e$hintLabel` text is updated only inside `switchTab`. After `loadPly` or `openDgt`, the user remains on the Digitize tab but the hint stays empty until they click a tab (or click the same tab again, which may not re-fire the binding). UX-WF-01 expects a persistent contextual hint under the canvas.

**Fix:** After successful `loadPly` (and after gating refresh at the end of `drawElements`/`openDgt`), call `switchTab(e, e$tab)` or extract hint-update logic into a small helper and invoke it from `showPicture` / load completion paths.

## Info

### IN-01: Step label "Step 3 — GPA unlocked" shown when Surface/Curves remain locked

**File:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r:331-332`
**Issue:** `updateStepLabel` advances to Step 3 when landmarks are complete (and anchors satisfied if enabled), even though Surface Sliders and Curves tabs stay disabled this phase. Copy is intentional per plan reconciliation note but may confuse users who read "GPA unlocked" while two tabs remain greyed out.

**Fix:** No code change required if product accepts the adapted copy; otherwise narrow Step 3 text to "Ready for GPA" or mention that other tabs are deferred.

---

_Reviewed: 2026-06-25T22:45:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
