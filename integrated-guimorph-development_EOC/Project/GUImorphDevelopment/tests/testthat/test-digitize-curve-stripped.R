pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# Source-scan assertions for Plan 06-05: 3dDigitize.digitize.r and
# 3dDigitize.curve.r must retain their non-Tk landmark/anchor/curve data logic
# (the .dgt serializers) while shedding every Tk dialog/builder and every native
# engine verb. Mirrors the source-scan style of test-main-chrome-stripped.R and
# needs the package R/ tree (skips cleanly under R CMD check's lazy-load db).
skip_if_no_pkg_source()

digitize_file <- file.path(pkg_root, "R", "3dDigitize.digitize.r")
curve_file    <- file.path(pkg_root, "R", "3dDigitize.curve.r")

# Strip comments (full-line and inline) before scanning code so the kept header
# prose (which names the removed tokens for context) cannot self-trip the
# negative gates. The gates therefore reference the tokens by pattern against
# code-only lines, never as literal head-comment snippets.
code_of <- function(path) sub("#.*$", "", readLines(path, warn = FALSE))
digitize_code <- code_of(digitize_file)
curve_code    <- code_of(curve_file)

engine_verbs <- "(^|[^._[:alnum:]])(add|set|del|shows)\\("

test_that("digitize.r has no Tk dialogs/builders (UI-01)", {
  expect_false(any(grepl("tkgetOpenFile", digitize_code, fixed = TRUE)))
  expect_false(any(grepl("tk_chooseColor", digitize_code, fixed = TRUE)))
  expect_false(any(grepl("tktoplevel", digitize_code, fixed = TRUE)))
  expect_false(any(grepl("tkgrid|tkpack", digitize_code)))
  expect_false(any(grepl("ui\\.digitize|ui\\.anchor", digitize_code)))
})

test_that("digitize.r has no native engine verbs (UI-02)", {
  expect_false(any(grepl(engine_verbs, digitize_code)))
})

test_that("curve.r has no Tk builder or tk2 widgets (UI-01)", {
  expect_false(any(grepl("ui\\.curve", curve_code)))
  expect_false(any(grepl("tktoplevel", curve_code, fixed = TRUE)))
  expect_false(any(grepl("tkgrid|tkpack", curve_code)))
  expect_false(any(grepl("tk2", curve_code, fixed = TRUE)))
})

test_that("curve.r has no native engine verbs (UI-02)", {
  expect_false(any(grepl(engine_verbs, curve_code)))
})

test_that("the kept .dgt serializers survive the strip (no over-strip, T-6-15)", {
  expect_true(any(grepl("^read\\.digitize <- function", digitize_code)))
  expect_true(any(grepl("^write\\.digitize <- function", digitize_code)))
  expect_true(any(grepl("^read\\.anchors <- function", digitize_code)))
  expect_true(any(grepl("^write\\.anchors <- function", digitize_code)))
  expect_true(any(grepl("^read\\.curve <- function", curve_code)))
  expect_true(any(grepl("^write\\.curve <- function", curve_code)))
})
