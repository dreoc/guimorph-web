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

# Plan 06-06 stripped the Tk surface tab builder (ui.surface), the
# Set-Number-of-Surface-Sliders toplevel, and the now-dead Tk build-template /
# downsample handlers (disableOper/buildTemplate/downSample) with their
# tkmessageBox status dialogs and native add/set engine verbs. Surface
# digitizing is now server-driven over /downsample via .gmw_downsample_session;
# surface.r retains only the non-Tk headless downsample + template/.dgt
# serializers. This inverts the former presence assertion (UI-01/UI-02).
test_that("Tk surface build/downsample handlers are gone from surface.r (UI-01/UI-02)", {
  surface_file <- file.path(pkg_root, "R", "3dDigitize.surface.r")
  src  <- readLines(surface_file, warn = FALSE)
  code <- sub("#.*$", "", src)

  expect_false(any(grepl("disableOper", code, fixed = TRUE)))
  expect_false(any(grepl("tkmessageBox", code, fixed = TRUE)))
  expect_false(any(grepl("(^|[^._[:alnum:]])(add|set|del|shows)\\(", code)))
  # The headless downsample seam + .dgt serializers survive the strip.
  expect_true(any(grepl("^\\.gmw_downsample_session <- function", src)))
  expect_true(any(grepl("^read\\.surface <- function", src)))
  expect_true(any(grepl("^write\\.surface <- function", src)))
})
