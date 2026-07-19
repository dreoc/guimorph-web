pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# Extract the source lines of a single top-level function definition (from its
# `name <- function` line up to the line before the next top-level definition,
# or end of file). Mirrors the source-scan style of test-macos-input-core.R so
# the audit runs on any OS without a display.
.fn_body <- function(src, name) {
  def_idx <- grep("^[A-Za-z.][A-Za-z0-9._]* <- function", src)
  start <- grep(paste0("^", gsub(".", "\\.", name, fixed = TRUE), " <- function"), src)
  stopifnot(length(start) == 1L)
  later <- def_idx[def_idx > start]
  end <- if (length(later)) min(later) - 1L else length(src)
  src[start:end]
}

test_that("3-D plot file uses no interactive-selection / snapshot rgl calls (ANL-02)", {
  digitize_file <- file.path(pkg_root, "R", "3dDigitize.geomorph.r")
  src <- readLines(digitize_file, warn = FALSE)

  # None of these are supported in the NULL device; their absence is the
  # ANL-02 audit deliverable. Search as fixed strings for the bare names.
  expect_false(any(grepl("select3d", src, fixed = TRUE)))
  expect_false(any(grepl("rgl.snapshot", src, fixed = TRUE)))
  expect_false(any(grepl("snapshot3d", src, fixed = TRUE)))
})

test_that("plotspecs and plotMeanShape display via .rgl_show(), not rgl.bringtotop directly", {
  digitize_file <- file.path(pkg_root, "R", "3dDigitize.geomorph.r")
  src <- readLines(digitize_file, warn = FALSE)

  # bringtotop must live only inside the rtkogl.R helper, never in the plot bodies.
  expect_false(any(grepl("rgl.bringtotop", src, fixed = TRUE)))

  plotspecs_body <- .fn_body(src, "plotspecs")
  meanshape_body <- .fn_body(src, "plotMeanShape")
  expect_true(any(grepl(".rgl_show(", plotspecs_body, fixed = TRUE)))
  expect_true(any(grepl(".rgl_show(", meanshape_body, fixed = TRUE)))
})

test_that(".rgl_show() helper defines the macOS widget path and the Windows branch", {
  rtkogl_file <- file.path(pkg_root, "R", "rtkogl.R")
  src <- readLines(rtkogl_file, warn = FALSE)

  expect_true(any(grepl("^.rgl_show <- function", src)))

  helper_body <- .fn_body(src, ".rgl_show")
  # macOS branch: NULL device -> WebGL widget written without pandoc, opened in browser.
  expect_true(any(grepl("rglwidget", helper_body, fixed = TRUE)))
  expect_true(any(grepl("saveWidget", helper_body, fixed = TRUE)))
  expect_true(any(grepl("selfcontained = FALSE", helper_body, fixed = TRUE)))
  expect_true(any(grepl("browseURL", helper_body, fixed = TRUE)))
  expect_true(any(grepl("close3d", helper_body, fixed = TRUE)))
  # Windows branch: byte-identical interactive path preserved (CMP-01).
  expect_true(any(grepl("rgl.bringtotop", helper_body, fixed = TRUE)))
})

test_that("options(rgl.useNULL = TRUE) is .isMacOS()-guarded at GUImorph() startup", {
  rtkogl_file <- file.path(pkg_root, "R", "rtkogl.R")
  src <- readLines(rtkogl_file, warn = FALSE)

  guimorph_body <- .fn_body(src, "GUImorph")
  guard_line <- grepl("rgl.useNULL = TRUE", guimorph_body, fixed = TRUE) &
    grepl(".isMacOS()", guimorph_body, fixed = TRUE)
  expect_true(any(guard_line))
})

test_that("plotPCA stays base-graphics (no rgl:: calls)", {
  digitize_file <- file.path(pkg_root, "R", "3dDigitize.geomorph.r")
  src <- readLines(digitize_file, warn = FALSE)

  plotpca_body <- .fn_body(src, "plotPCA")
  expect_false(any(grepl("rgl::", plotpca_body, fixed = TRUE)))
})

test_that("NULL-mode rglwidget -> saveWidget(selfcontained = FALSE) writes a non-empty file", {
  skip_if_not_installed("rgl")
  skip_if_not_installed("htmlwidgets")

  old <- options(rgl.useNULL = TRUE)
  on.exit(options(old), add = TRUE)

  rgl::open3d()
  on.exit(try(rgl::close3d(), silent = TRUE), add = TRUE)
  rgl::points3d(matrix(stats::rnorm(30), ncol = 3))
  rgl::aspect3d("iso")

  w <- rgl::rglwidget()
  f <- tempfile(fileext = ".html")
  htmlwidgets::saveWidget(w, f, selfcontained = FALSE)

  expect_true(file.exists(f))
  expect_gt(file.info(f)$size, 0)
})
