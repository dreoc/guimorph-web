# Testing Patterns

**Analysis Date:** 2026-07-12

GUImorph has a **small but real** automated test suite (`testthat`) covering
pure-logic R helpers, plus a **manual GUI smoke-test protocol** documented in
`BUILD.md`. There is **no CI test job, no coverage tooling, and no automated
tests for the C engine or the Tcl bridge**. The bulk of the codebase (GUI
event handling, OpenGL rendering, GPA analysis, PLY/DGT I/O in C) is verified
only by the manual smoke test.

---

## Test Framework

**Runner:**
- `testthat` (declared under `Suggests:` in `DESCRIPTION:21-22`, no version
  pinned). Entry point `tests/testthat.R` uses the standard shim:

```r
library(testthat)
library(GUImorph)
test_check("GUImorph")
```

**Assertion library:** `testthat` expectations (`expect_equal`, `expect_null`,
`expect_type`, `expect_length`, `expect_match`, `expect_true`, `expect_false`,
`expect_invisible`).

**Run Commands:**
```r
devtools::test(".")           # Run all tests (from package root, dev workflow)
devtools::load_all("."); testthat::test_local()   # alternative
R CMD check .                 # Full package check incl. tests
```
Run from the package root
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`. Windows R
4.6+ is required to `library(GUImorph)` because `.onLoad` loads `tkogl2.dll`;
individual test files sidestep this (see below), but `test_check` via
`tests/testthat.R` does load the package.

---

## Test File Organization

**Location:** `tests/testthat/` (separate from `R/`, standard testthat layout).

**Naming:** `test-<topic>.R`. Current files (4):
- `tests/testthat/test-curve-io.R` — `read.curve`/`write.curve` round-trip
- `tests/testthat/test-curve-spinbox.R` — `.clampCurveMax`/`.clampCurveCurrent`
- `tests/testthat/test-curve-tab-gating.R` — `refreshTabGating` tab-enable logic
- `tests/testthat/test-undo-helpers.R` — `doUndo` status messaging

**Structure:**
```
tests/
├── testthat.R              # test_check("GUImorph")
└── testthat/
    └── test-<topic>.R      # one file per unit under test
```
There are **no** `helper-*.R` or `setup-*.R` files; per-file setup is inline.

---

## Test Structure

**Suite organization** — flat `test_that("description", { ... })` blocks, no
nested `describe`. Descriptions are full behavioral sentences:

```r
test_that("write.curve and read.curve round-trip a 3-column integer matrix", {
  curves <- matrix(c(1, 2, 3, 4, 5, 6), ncol = 3, byrow = TRUE)
  tmp <- tempfile(fileext = ".dgt")
  on.exit(unlink(tmp), add = TRUE)

  write.curve(tmp, curves)
  content <- readLines(tmp, warn = FALSE)
  result <- read.curve(content)

  expect_equal(result, curves)
})
```

**Patterns:**
- **Source-the-file-under-test directly** instead of relying on the loaded
  package namespace. Every test computes `pkg_root` from `testthat::test_path()`
  and `source()`s the specific R file:
  ```r
  pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
  source(file.path(pkg_root, "R", "3dDigitize.curve.r"), local = FALSE)
  ```
  (`test-curve-io.R:1-2`, `test-curve-spinbox.R:1-2`, `test-curve-tab-gating.R:1-2`).
  This lets logic tests run without loading `tkogl2.dll`.
- **Temp files + `on.exit(unlink(...), add = TRUE)`** for filesystem round-trips
  (`test-curve-io.R:6-7`).
- **Hand-built fake environments** to stand in for the GUI state object `e`:
  ```r
  e <- new.env(parent = emptyenv())
  e$tabState <- c(1L, 0L, 0L, 0L)
  ```
  (`test-curve-tab-gating.R:6-14`, `test-undo-helpers.R:9`).

---

## Mocking

**Framework:** no dedicated mock package. Two hand-rolled techniques:

**1. Namespace stubbing** — swap `tcltk::tcl` with a no-op, restore via
`on.exit`/`assignInNamespace` (`test-curve-tab-gating.R:4-21`):

```r
.stub_tcl <- function(...) invisible(NULL)

with_stub_tcl <- function(expr) {
  old_tcl <- getFromNamespace("tcl", "tcltk")
  on.exit(assignInNamespace("tcl", old_tcl, "tcltk"), add = TRUE)
  assignInNamespace("tcl", .stub_tcl, "tcltk")
  force(expr)
}
```

**2. Inline closure re-definition** — some tests redefine the function under
test *inside the test body*, capturing local fakes (`setStatus`, `del`,
`clearUndo`) via lexical scope, then exercise the copy
(`test-undo-helpers.R:12-25`, `:41-66`, `:100-131`). This tests the *logic
shape* rather than the shipped function; treat it as a smell to migrate toward
sourcing the real function when refactoring `doUndo`.

**3. Source-scanning assertions** — read the R source as text and assert on its
contents rather than behavior (`test-undo-helpers.R:153-161`):

```r
curveSrc <- readLines(curveFile, warn = FALSE)
expect_true(any(grepl("Duplicate landmark in this curve segment", curveSrc, fixed = TRUE)))
expect_false(any(grepl("tkmessageBox", curveSrc, fixed = TRUE)))
```
Used to lock in the "inline status message, no dialog boxes" convention.

**What to mock:** the Tcl/Tk layer (`tcl`, `tkconfigure`, widget calls) — it
requires a live GUI. **What NOT to mock:** pure helpers (`read.curve`,
`.clampCurveMax`, matrix math) — test them directly with real inputs.

---

## Fixtures and Factories

- **No fixture files.** Test data is constructed inline: literal `matrix(...)`
  configurations and small `list()` structures mimicking `e$activeDataList`
  (`test-undo-helpers.R:133-140`).
- **Factory helpers** are defined per-file when repeated, e.g.
  `make_gating_e(nLm, landmarkNum)` builds a minimal gating environment
  (`test-curve-tab-gating.R:6-14`).
- Real `.ply`/`.dgt` sample specimens are **not** part of the test suite; they
  are used only in the manual smoke test.

---

## Coverage

**Requirements:** None enforced. No `covr`, no coverage config, no threshold.

**What IS covered (pure R logic only):**
- Curve serialization round-trip and empty/missing-header edge cases.
- Curve spinbox clamping bounds.
- Tab-gating enable/disable logic.
- Undo status-message wording and undo-stack behavior.

**What is NOT covered:**
- The Tcl bridge dispatchers (`add`, `del`, `set`, `shows`, `show` in
  `R/rtkogl.R`).
- GPA / geomorph analysis, PCA, mean-shape (`R/3dDigitize.geomorph.r`).
- PLY/DGT loading, rendering, digitizing event handlers.
- The **entire C engine** (`tkogl2/src/`). C files declare `ut_*` unit-test
  hooks (`ut_show_dot`, `ut_showCurve`, ... in `src/def_ZARF_9.h:286-296`)
  behind `#ifdef STAND_ALONE_TOOL`, but these are a manual desktop harness, not
  part of any automated build or CI.

---

## Test Types

**Unit Tests:** The only automated type present. Scope: individual pure R
functions, sourced directly and exercised with in-memory inputs; GUI/Tcl
dependencies stubbed.

**Integration Tests:** None automated.

**E2E Tests:** None automated — replaced by the manual GUI smoke test below.

---

## Smoke-Test Approach (primary verification path)

Documented in `BUILD.md` §5. This is how most of GUImorph is actually
validated, since the GUI + native DLL cannot run headless in CI.

**Change-type matrix (`BUILD.md:149-152`):**

| Change type | Verify |
|-------------|--------|
| R-only edits | `devtools::load_all(".")` + exercise the affected GUI path |
| C / `tkogl2` edits | Rebuild DLL → deploy → **full GUI smoke** below |

**Full GUI smoke (post-deploy), from the package root:**
```r
setwd("C:/dev/GUImorph/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
renv::restore()
devtools::load_all(".")
GUImorph()
# Load a sample PLY (bundled test data or local C13.1.ply)
```

**Pass criteria (`BUILD.md:164-169`):**
1. Console shows the `tkogl2` load path from `.onLoad` (no
   `loading tkogl2 failed` warning).
2. The "3D GUImorph" window opens.
3. The specimen mesh renders (not blank/black — the MinGW-build failure mode).

Maintainer UAT history and warning triage live in
`.planning/smoke-test-findings.md` (referenced from `BUILD.md:184`).

---

## Common Patterns

**Filesystem round-trip test:**
```r
tmp <- tempfile(fileext = ".dgt")
on.exit(unlink(tmp), add = TRUE)
write.curve(tmp, curves)
result <- read.curve(readLines(tmp, warn = FALSE))
expect_equal(result, curves)
```

**GUI-logic test without a GUI (stub Tcl, fake `e`):**
```r
e <- make_gating_e(10L, 10L)
with_stub_tcl(refreshTabGating(e))
expect_equal(unname(e$tabState[2:4]), c(1L, 1L, 1L))
```

**Boundary/clamp testing** — enumerate NA, below-min, in-range, above-max
(`test-curve-spinbox.R:4-19`):
```r
expect_equal(.clampCurveCurrent(NA, 5), 1L)
expect_equal(.clampCurveCurrent(10, 5), 5L)
```

**Invisibility / side-effect assertions:** `expect_invisible(refreshTabGating(e))`
for functions that `return(invisible())` early
(`test-curve-tab-gating.R:23-27`).

---

*Testing analysis: 2026-07-12*
