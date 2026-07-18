---
title: "DEFECT: PCA (morphospace) crashes when the PCA yields a single component"
status: done
kind: defect
scope: out-of-milestone
milestone: none (NOT part of the macOS port; pre-existing, reproduces on Windows)
priority: medium
severity: crash-no-data-loss
discovered: 2026-07-18
resolved: 2026-07-18
discovered_during: Phase 5 Windows validation
affects: [GPA tab, PCA (morphospace) button]
owner: eoc
---

## Resolution (2026-07-18)

Fixed in `3dDigitize.geomorph.r::plotPCA`. Root cause confirmed by reading the code:
the failing `apply(scores, 2, stats::var)` is GUImorph's own line, not geomorph's.
`scores <- pca$x` returns a plain vector when the ordination retains a single
component, because R drops the dimensions of a one-column result. `apply` and the
`ncol(scores) >= 2` test below it both require a `dim` attribute, so the crash
happened before the existing one-axis branch could run.

Changes:
- `scores <- as.matrix(scores)` restores the m x 1 shape, so the author's original
  one-axis branch now works as intended. This is the actual fix.
- `gm.prcomp` wrapped in `tryCatch` with a readable message instead of a raw abort.
- NULL / zero-length scores refused with an explanation.
- Variance percentages guarded against a zero total (identical shapes), which would
  otherwise print NaN.
- Plot dimensions keyed off `nrow(scores)` rather than the specimen count, so a
  mismatch cannot desync the colours and labels.
- The one-axis title no longer hardcodes "2 specimens".

The 2-specimen minimum was deliberate and is retained. A two-specimen ordination has
exactly one axis, which the one-axis branch was written to display.

## Scope note

Not a macOS-port issue and not part of any phase of the macOS milestone. Observed on
Windows, in R, downstream of `geomorph`. Filed as a testing/QA backlog item.

## Symptom

Clicking **PCA (morphospace)** after a GPA run aborts with:

```
Error in apply(scores, 2, stats::var) :
  dim(X) must have a positive length
```

The GUI survives; the plot simply does not appear. Observed at `log3:7835`,
immediately after a mean-shape plot. No data is lost and digitizing continues
normally (85 live picks followed it in the same session).

## Root cause (probable)

`apply(X, 2, ...)` requires `X` to have a `dim` attribute. R drops the dimensions of
a one-column matrix on subsetting unless `drop = FALSE`, so `scores` arrives as a
plain numeric vector and `apply` has no second margin to walk.

That happens when the ordination has only one component to report. With **two
specimens** there is exactly one axis of variation, which matches the session where
this fired. Worth confirming against specimen count before fixing.

## Proposed fix

Guard rather than change the math:

1. Coerce defensively where `scores` is produced or consumed:
   `scores <- as.matrix(scores)` (or subset with `drop = FALSE`).
2. Refuse early with a clear message when the ordination cannot support a
   morphospace plot, e.g. fewer than 3 specimens: "PCA needs at least 3 specimens;
   this dataset has N." That is more useful than a component-count check because it
   names the real precondition in the user's terms.
3. Same guard belongs on **Plot Aligned Specimens** if it consumes the same scores.

## Verification

- 2 specimens: friendly refusal, no error.
- 3+ specimens: plot renders as before.
- Confirm `Plot Mean Shape` is unaffected (it worked fine in the same session).
