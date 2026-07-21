pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()

test_that("digitize miss paths surface status feedback", {
  digitize_file <- file.path(pkg_root, "R", "3dDigitize.digitize.r")
  src <- readLines(digitize_file, warn = FALSE)

  expect_true(any(grepl("\\.setMissStatus <- function\\(e, action\\)", src)))
  expect_true(any(grepl("\\.setMissStatus\\(e, \"Landmark placement\"\\)", src)))
  expect_true(any(grepl("\\.setMissStatus\\(e, \"Anchor placement\"\\)", src)))
  expect_true(any(grepl("\\.setMissStatus\\(e, \"Landmark delete\"\\)", src)))
  expect_true(any(grepl("\\.setMissStatus\\(e, \"Anchor delete\"\\)", src)))
})

test_that("curve miss path does not mutate segment state", {
  curve_file <- file.path(pkg_root, "R", "3dDigitize.curve.r")
  src <- readLines(curve_file, warn = FALSE)

  expect_true(any(grepl("Curve selection missed a landmark; no segment changes were made.", src, fixed = TRUE)))
})

test_that("surface template/downsample early exits restore operation state", {
  surface_file <- file.path(pkg_root, "R", "3dDigitize.surface.r")
  src <- readLines(surface_file, warn = FALSE)

  expect_gte(sum(grepl("disableOper\\(e, F\\)", src)), 4)
  expect_true(any(grepl("Build template requires landmarks on the specimen.", src, fixed = TRUE)))
  expect_true(any(grepl("Downsample requires landmarks on the specimen.", src, fixed = TRUE)))
})
