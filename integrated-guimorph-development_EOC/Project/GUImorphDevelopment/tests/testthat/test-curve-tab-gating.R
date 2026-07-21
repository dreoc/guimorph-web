pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()
source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = FALSE)

.stub_tcl <- function(...) invisible(NULL)

make_gating_e <- function(nLm, landmarkNum) {
  e <- new.env(parent = emptyenv())
  e$nb <- list()
  e$activeDataList <- list(list(".", NULL, nLm))
  e$currImgId <- 1L
  e$landmarkNum <- landmarkNum
  e$tabState <- c(1L, 0L, 0L, 0L)
  e
}

with_stub_tcl <- function(expr) {
  old_tcl <- getFromNamespace("tcl", "tcltk")
  on.exit(assignInNamespace("tcl", old_tcl, "tcltk"), add = TRUE)
  assignInNamespace("tcl", .stub_tcl, "tcltk")
  force(expr)
}

test_that("refreshTabGating returns invisibly when nb is NULL", {
  e <- new.env(parent = emptyenv())
  e$nb <- NULL
  expect_invisible(refreshTabGating(e))
})

test_that("refreshTabGating enables tabs 2-4 when current specimen landmarks complete", {
  e <- make_gating_e(10L, 10L)
  with_stub_tcl(refreshTabGating(e))
  expect_equal(unname(e$tabState[2:4]), c(1L, 1L, 1L))
})

test_that("refreshTabGating keeps tabs 2-4 disabled when landmarks incomplete", {
  e <- make_gating_e(5L, 10L)
  with_stub_tcl(refreshTabGating(e))
  expect_equal(unname(e$tabState[2:4]), c(0L, 0L, 0L))
})
