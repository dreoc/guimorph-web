---
phase: 09-c-engine-cleanup-validation
fixed_at: 2026-06-23T12:35:00Z
review_path: .planning/phases/09-c-engine-cleanup-validation/09-REVIEW.md
iteration: 2
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 9: Code Review Fix Report

**Fixed at:** 2026-06-23T12:35:00Z
**Source review:** `.planning/phases/09-c-engine-cleanup-validation/09-REVIEW.md`
**Iteration:** 2

**Summary:**
- Findings in scope: 3 (CR-01, WR-01, WR-02; Info findings IN-01/IN-02 skipped per `fix_scope: critical_warning`)
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Unguarded NULL dereference in `changeDotColorToSlider`

**Files modified:** `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c`
**Commit:** `e11ab2a`
**Applied fix:** Added `if (NULL == sliderDot)` guard with `simpleLog` error message and early `return` before dereferencing the dot returned by `get_dot_at_index_current_slice(dotIndex)`.

### WR-01: `setSpecimen "id"` lacks specimen-index bound check

**Files modified:** `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c`
**Commit:** `c814bd2`
**Applied fix:** After 1-based→0-based conversion, added `if (index < 0 || index >= model_amount)` guard mirroring the `add`/"specimen" path. On out-of-range index, logs via `sprintf`+`simpleLog` and sets `UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE`; valid indices proceed in an `else` block wrapping the existing body.

### WR-02: `curve_buildLine` close-together branch copies X into Y coordinate

**Files modified:** `integrated-guimorph-development_EOC/Project/tkogl2/src/curve_ZARF_9.c`
**Commit:** `1251b37`
**Applied fix:** Corrected copy-paste bug in the close-together short-circuit branch: `(*line)[0].y = p1->y` and `(*line)[1].y = p2->y` (were incorrectly assigned from `p1->x` / `p2->x`).

---

_Fixed: 2026-06-23T12:35:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
