pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()

test_that("normalizeWheelDelta divides by the platform notch and preserves floats", {
  # normalizeWheelDelta/.isMacOS/GBL_WHEEL_NOTCH_* were relocated from rtkogl.R
  # to R/shell.R in Plan 06-03 (the non-engine survivors move before rtkogl.R is
  # deleted in Plan 07).
  source(file.path(pkg_root, "R", "shell.R"), local = TRUE)

  # One notch = one step on every platform; the notch size is the only
  # platform-specific constant (Windows 120, macOS 30). Assert against the
  # active platform's notch so the test is correct on both.
  notch <- if (.isMacOS()) GBL_WHEEL_NOTCH_MACOS else GBL_WHEEL_NOTCH_WINDOWS

  expect_equal(normalizeWheelDelta(120), 120 / notch)
  expect_equal(normalizeWheelDelta(-30), -30 / notch)
  expect_equal(normalizeWheelDelta("15"), 15 / notch)
  expect_equal(normalizeWheelDelta("bad"), 0)
})

# The bindDeleteGesture helper (and its macOS <Button-2>/<Control-Button-1>
# gestures) was a Tk-only survivor with no browser analog; Plan 06-03 dropped it
# rather than relocating it to shell.R. Its former assertion is retired here. The
# digitize.r call site is dead Tk code removed with the tab builders in Plan 04.

test_that("digitize bindings use centralized helpers", {
  digitize_file <- file.path(pkg_root, "R", "3dDigitize.digitize.r")
  src <- readLines(digitize_file, warn = FALSE)

  expect_true(any(grepl("zoom\\(e, normalizeWheelDelta\\(D\\)\\)", src)))
  expect_true(any(grepl("bindDeleteGesture\\(e\\$canvasFrame, function\\(x, y\\)", src)))
})
