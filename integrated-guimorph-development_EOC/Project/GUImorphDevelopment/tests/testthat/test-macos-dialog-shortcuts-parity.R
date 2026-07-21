pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()

test_that("shortcut helpers include Command equivalents", {
  rtkogl_file <- file.path(pkg_root, "R", "rtkogl.R")
  src <- readLines(rtkogl_file, warn = FALSE)

  expect_true(any(grepl("^shortcutLabel <- function\\(key\\)", src)))
  expect_true(any(grepl("tkbind\\(widget, paste0\\(\"<Command-\", key, \">\"\\), handler\\)", src)))
})

test_that("accelerator map is routed through shared helper", {
  main_file <- file.path(pkg_root, "R", "3dDigitize.main.r")
  src <- readLines(main_file, warn = FALSE)

  expect_true(any(grepl("bindPlatformAccelerator\\(e\\$wnd, \"o\"", src)))
  expect_true(any(grepl("bindPlatformAccelerator\\(e\\$wnd, \"s\"", src)))
  expect_true(any(grepl("bindPlatformAccelerator\\(e\\$wnd, \"bracketleft\"", src)))
  expect_true(any(grepl("bindPlatformAccelerator\\(e\\$wnd, \"bracketright\"", src)))
})

test_that("dialogs allow all files and warn on odd extensions", {
  main_file <- file.path(pkg_root, "R", "3dDigitize.main.r")
  src <- readLines(main_file, warn = FALSE)

  expect_true(any(grepl("\\{\\{All files\\} \\*\\}", src)))
  expect_true(any(grepl("\\.warnUnexpectedExtension\\(", src)))
})

test_that("tab gating function remains centralized", {
  main_file <- file.path(pkg_root, "R", "3dDigitize.main.r")
  src <- readLines(main_file, warn = FALSE)

  expect_true(any(grepl("^refreshTabGating <- function\\(e\\)", src)))
  expect_true(any(grepl("Surface Sliders and Curves unlocked.", src, fixed = TRUE)))
})

test_that("curve and surface tabs consume shared shortcut and wheel helpers", {
  curve_file <- file.path(pkg_root, "R", "3dDigitize.curve.r")
  curve_src <- readLines(curve_file, warn = FALSE)
  surface_file <- file.path(pkg_root, "R", "3dDigitize.surface.r")
  surface_src <- readLines(surface_file, warn = FALSE)

  expect_true(any(grepl("shortcutLabel\\(\"\\[\"\\)", curve_src)))
  expect_true(any(grepl("zoom\\(e, normalizeWheelDelta\\(D\\)\\)", surface_src)))
})
