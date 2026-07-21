pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()
source(file.path(pkg_root, "R", "3dDigitize.curve.r"), local = FALSE)

test_that(".clampCurveMax enforces minimum of 1", {
  expect_equal(.clampCurveMax(NA), 1L)
  expect_equal(.clampCurveMax(0), 1L)
  expect_equal(.clampCurveMax(-1), 1L)
  expect_equal(.clampCurveMax(1), 1L)
  expect_equal(.clampCurveMax(9999), 9999L)
})

test_that(".clampCurveCurrent stays within 1..max", {
  expect_equal(.clampCurveCurrent(NA, 5), 1L)
  expect_equal(.clampCurveCurrent(0, 5), 1L)
  expect_equal(.clampCurveCurrent(-1, 5), 1L)
  expect_equal(.clampCurveCurrent(3, 5), 3L)
  expect_equal(.clampCurveCurrent(10, 5), 5L)
  expect_equal(.clampCurveCurrent(9999, 5), 5L)
})
