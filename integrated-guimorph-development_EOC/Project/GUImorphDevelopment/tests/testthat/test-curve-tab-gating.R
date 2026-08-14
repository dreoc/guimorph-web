pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()
source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = FALSE)

# Plan 06-04 stripped the Tk notebook widget calls (tcl tab state) from
# refreshTabGating; the browser shell owns notebook rendering. The function now
# computes server-side tab-enable state only, so no tcltk stubbing is required.

make_gating_e <- function(nLm, landmarkNum) {
  e <- new.env(parent = emptyenv())
  e$nb <- list()
  e$activeDataList <- list(list(".", NULL, nLm))
  e$currImgId <- 1L
  e$landmarkNum <- landmarkNum
  e$tabState <- c(1L, 0L, 0L, 0L)
  e
}

test_that("refreshTabGating returns invisibly when nb is NULL", {
  e <- new.env(parent = emptyenv())
  e$nb <- NULL
  expect_invisible(refreshTabGating(e))
})

test_that("refreshTabGating enables tabs 2-4 when current specimen landmarks complete", {
  e <- make_gating_e(10L, 10L)
  refreshTabGating(e)
  expect_equal(unname(e$tabState[2:4]), c(1L, 1L, 1L))
})

test_that("refreshTabGating keeps tabs 2-4 disabled when landmarks incomplete", {
  e <- make_gating_e(5L, 10L)
  refreshTabGating(e)
  expect_equal(unname(e$tabState[2:4]), c(0L, 0L, 0L))
})
