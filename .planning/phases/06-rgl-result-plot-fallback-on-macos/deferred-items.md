# Phase 06 — Deferred / Out-of-Scope Items

Discoveries logged during execution that are **not** caused by this phase's changes
(scope boundary: only auto-fix issues directly caused by the current task).

## Pre-existing test failures (unrelated to Phase 6)

- **`tests/testthat/test-curve-tab-gating.R` — 7 failures** (`assignInNamespace("tcl", ..., "tcltk")`:
  *"locked binding of 'tcl' cannot be changed"*).
  - **Root cause:** the test stubs the `tcl` binding in the sealed `tcltk` namespace via
    `assignInNamespace`; on this R build the binding is locked, so tests 2–4 error.
  - **Confirmed pre-existing:** reproduced identically at the pre-phase base commit
    (`3577243~1`) with none of the Phase 6 changes present — test 1 passes, tests 2 & 3
    error. Phase 6 touches `rtkogl.R` (`.rgl_show` + startup option),
    `3dDigitize.geomorph.r` (plot tails), `DESCRIPTION`, and the new rgl test file; none
    interact with `test-curve-tab-gating.R` (which sources `3dDigitize.main.r`).
  - **Disposition:** out of scope for Phase 6. Do not fix here.

- **`tests/testthat/test-dgt-cross-platform.R` — 1 skip** (intentional): bidirectional
  DAT-03 byte fixtures required from Windows/macOS round-trip evidence (Phase 5 / DAT-03).
