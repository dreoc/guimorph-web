pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()
source(file.path(pkg_root, "R", "3dDigitize.curve.r"), local = FALSE)

test_that("write.curve and read.curve round-trip a 3-column integer matrix", {
  curves <- matrix(c(1, 2, 3, 4, 5, 6), ncol = 3, byrow = TRUE)
  tmp <- tempfile(fileext = ".dgt")
  on.exit(unlink(tmp), add = TRUE)

  write.curve(tmp, curves)
  content <- readLines(tmp, warn = FALSE)
  result <- read.curve(content)

  expect_equal(result, curves)
  expect_type(result, "double")
  expect_equal(ncol(result), 3L)
})

test_that("read.curve returns NULL when Curve= header is absent", {
  content <- c("Landmark= 0", "Specimen= foo")
  expect_null(read.curve(content))
})

test_that("write.curve and read.curve handle empty curve matrix", {
  tmp <- tempfile(fileext = ".dgt")
  on.exit(unlink(tmp), add = TRUE)

  write.curve(tmp, matrix(integer(), nrow = 0, ncol = 3))
  content <- readLines(tmp, warn = FALSE)
  result <- read.curve(content)

  expect_null(result)
})
