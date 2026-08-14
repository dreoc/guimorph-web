pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()

# Plan 06-05 stripped the native digitize handlers (addDot/addAnchor,
# deleteLandmark/deleteAnchor) and their .setMissStatus miss-feedback calls from
# digitize.r; landmark/anchor picking is now server-driven over /pick and
# /anchor, and miss feedback is surfaced browser-side. digitize.r retains only
# the non-Tk data model + .dgt serializers.
test_that("native digitize miss-feedback handlers are gone from digitize.r (UI-02)", {
  digitize_file <- file.path(pkg_root, "R", "3dDigitize.digitize.r")
  src <- readLines(digitize_file, warn = FALSE)
  code <- sub("#.*$", "", src)

  expect_false(any(grepl(".setMissStatus", code, fixed = TRUE)))
  expect_false(any(grepl("(^|[^._[:alnum:]])(add|set|del|shows)\\(", code)))
  expect_true(any(grepl("^read\\.digitize <- function", src)))
  expect_true(any(grepl("^write\\.anchors <- function", src)))
})

# Plan 06-05 removed onSelectCurve (the native curve-selection handler that held
# the "missed a landmark" guard) from curve.r; curve selection is now
# server-driven over /curve. curve.r retains only the .dgt curve serializers.
test_that("native curve-selection handler is gone from curve.r (UI-02)", {
  curve_file <- file.path(pkg_root, "R", "3dDigitize.curve.r")
  src <- readLines(curve_file, warn = FALSE)
  code <- sub("#.*$", "", src)

  expect_false(any(grepl("onSelectCurve", code, fixed = TRUE)))
  expect_false(any(grepl("(^|[^._[:alnum:]])(add|set|del|shows)\\(", code)))
  expect_true(any(grepl("^read\\.curve <- function", src)))
  expect_true(any(grepl("^write\\.curve <- function", src)))
})

test_that("surface template/downsample early exits restore operation state", {
  surface_file <- file.path(pkg_root, "R", "3dDigitize.surface.r")
  src <- readLines(surface_file, warn = FALSE)

  expect_gte(sum(grepl("disableOper\\(e, F\\)", src)), 4)
  expect_true(any(grepl("Build template requires landmarks on the specimen.", src, fixed = TRUE)))
  expect_true(any(grepl("Downsample requires landmarks on the specimen.", src, fixed = TRUE)))
})
