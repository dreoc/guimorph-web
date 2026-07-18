---
title: "DEFECT: PCA (morphospace) crashes when the PCA yields a single component"
status: open
kind: defect
scope: out-of-milestone
milestone: none (NOT part of the macOS port; pre-existing, reproduces on Windows)
priority: medium
severity: crash-no-data-loss
discovered: 2026-07-18
discovered_during: Phase 5 Windows validation
affects: [GPA tab, PCA (morphospace) button]
owner: eoc
---

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
