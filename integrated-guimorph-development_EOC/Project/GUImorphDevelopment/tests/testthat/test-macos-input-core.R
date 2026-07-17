pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

test_that("normalizeWheelDelta preserves floating wheel input", {
  source(file.path(pkg_root, "R", "rtkogl.R"), local = TRUE)

  expect_equal(normalizeWheelDelta(120), 1)
  expect_equal(normalizeWheelDelta(-30), -0.25)
  expect_equal(normalizeWheelDelta("15"), 0.125)
  expect_equal(normalizeWheelDelta("bad"), 0)
})

test_that("delete helper includes both macOS delete gestures", {
  rtkogl_file <- file.path(pkg_root, "R", "rtkogl.R")
  src <- readLines(rtkogl_file, warn = FALSE)

  expect_true(any(grepl("tkbind(widget, \"<Button-2>\", handler)", src, fixed = TRUE)))
  expect_true(any(grepl("tkbind(widget, \"<Control-Button-1>\", handler)", src, fixed = TRUE)))
})

test_that("digitize bindings use centralized helpers", {
  digitize_file <- file.path(pkg_root, "R", "3dDigitize.digitize.r")
  src <- readLines(digitize_file, warn = FALSE)

  expect_true(any(grepl("zoom\\(e, normalizeWheelDelta\\(D\\)\\)", src)))
  expect_true(any(grepl("bindDeleteGesture\\(e\\$canvasFrame, function\\(x, y\\)", src)))
})
