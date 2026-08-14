pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()

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

test_that("plotspecs and plotMeanShape render through the three.js viewport, not rgl", {
  digitize_file <- file.path(pkg_root, "R", "3dDigitize.geomorph.r")
  src <- readLines(digitize_file, warn = FALSE)

  # PLT-01: the whole file is rgl-free. This is stronger than the old assertion,
  # which only required that rgl be reached through a helper.
  expect_false(any(grepl("rgl::", src, fixed = TRUE)))
  expect_false(any(grepl("rgl.bringtotop", src, fixed = TRUE)))

  plotspecs_body <- .fn_body(src, "plotspecs")
  meanshape_body <- .fn_body(src, "plotMeanShape")
  expect_true(any(grepl(".gmw_view3d(", plotspecs_body, fixed = TRUE)))
  expect_true(any(grepl(".gmw_view3d(", meanshape_body, fixed = TRUE)))

  # plotPCA stays base-graphics 2-D through .plot_show() (PLT-03).
  expect_true(any(grepl(".plot_show(", .fn_body(src, "plotPCA"), fixed = TRUE)))
})

test_that(".gmw_view3d() writes a page over the vendored bundle and opens it", {
  view_file <- file.path(pkg_root, "R", "view3d.R")
  expect_true(file.exists(view_file))
  src <- readLines(view_file, warn = FALSE)

  expect_true(any(grepl("^\\.gmw_view3d <- function", src)))

  body <- .fn_body(src, ".gmw_view3d")
  # Copies the vendored bundle beside the page, then opens it. No network, and
  # no htmlwidgets: rgl and htmlwidgets are Suggests, not Imports (PLT-02).
  expect_true(any(grepl("guimorphweb-three.js", body, fixed = TRUE)))
  expect_true(any(grepl("browseURL", body, fixed = TRUE)))
  expect_false(any(grepl("saveWidget", body, fixed = TRUE)))
  expect_false(any(grepl("http", body, fixed = TRUE)))

  # The bundle itself must be committed, with its licences and manifest.
  wd <- file.path(pkg_root, "inst", "htmlwidgets")
  expect_true(file.exists(file.path(wd, "guimorphweb-three.js")))
  expect_true(file.exists(file.path(wd, "VENDOR-MANIFEST.json")))
  expect_true(file.exists(file.path(wd, "LICENSE.three.txt")))
})

test_that("the native engine is retired: no engine file / load path survives (UI-02)", {
  # Plan 06-07 physically removed the native tkogl2 engine. The old test here
  # asserted that a FAILED engine load stayed non-fatal (rtkogl.R's .onLoad
  # recorded status instead of stop()ing). With the engine gone there is no load
  # path left to be fatal or otherwise -- so the invariant inverts from "the load
  # is non-fatal" to "the engine, its file, and its load path are absent". Tokens
  # are built from patterns so this negative gate cannot self-trip on its prose.
  skip_if_no_pkg_source()

  # (i) The engine binding file is gone.
  expect_false(file.exists(file.path(pkg_root, "R", "rtkogl.R")))

  # (ii) No shipped native binary lingers under inst/libs/.
  libs <- list.files(file.path(pkg_root, "inst", "libs"),
                     recursive = TRUE, full.names = FALSE)
  engine_bin <- paste0("tk", "ogl2")   # the compiled engine basename
  glut_bin   <- "glut64"
  expect_false(any(grepl(engine_bin, libs, fixed = TRUE)))
  expect_false(any(grepl(glut_bin,   libs, fixed = TRUE)))

  # (iii) No engine load path / engine env definition survives anywhere in R/.
  onload_tok <- paste0(".", "onLoad")             # the retired engine tcl-load hook
  engine_env <- paste0(".", "gmw_engine")         # the retired status env
  engine_req <- paste0(".", "gmw_require_engine")  # the retired digitizing gate
  r_files <- list.files(file.path(pkg_root, "R"), pattern = "[.][Rr]$",
                        full.names = TRUE)
  for (rf in r_files) {
    code <- sub("#.*$", "", readLines(rf, warn = FALSE))  # strip comments
    expect_false(any(grepl(onload_tok, code, fixed = TRUE)),
                 info = paste("unexpected engine load hook in", basename(rf)))
    expect_false(any(grepl(paste0(engine_env, "$"), code, fixed = TRUE)),
                 info = paste("unexpected engine env read in", basename(rf)))
    expect_false(any(grepl(paste0(engine_env, " <-"), code, fixed = TRUE)),
                 info = paste("unexpected engine env def in", basename(rf)))
    expect_false(any(grepl(engine_req, code, fixed = TRUE)),
                 info = paste("unexpected engine gate in", basename(rf)))
  }
})

test_that("plotPCA stays base-graphics (no rgl:: calls)", {
  digitize_file <- file.path(pkg_root, "R", "3dDigitize.geomorph.r")
  src <- readLines(digitize_file, warn = FALSE)

  plotpca_body <- .fn_body(src, "plotPCA")
  expect_false(any(grepl("rgl::", plotpca_body, fixed = TRUE)))
})

test_that("plotPCA displays via .plot_show(), not a bare native device (crash-on-close fix)", {
  digitize_file <- file.path(pkg_root, "R", "3dDigitize.geomorph.r")
  src <- readLines(digitize_file, warn = FALSE)

  plotpca_body <- .fn_body(src, "plotPCA")
  # Routed through the platform-guarded helper...
  expect_true(any(grepl(".plot_show(", plotpca_body, fixed = TRUE)))
  # ...and no direct native-window open in the plot body (that call now lives
  # only inside .plot_show's Windows branch). Closing a quartz window under Tk's
  # Aqua run loop was the EXC_BAD_ACCESS on close.
  expect_false(any(grepl("dev.new(", plotpca_body, fixed = TRUE)))
})

test_that(".plot_show() helper defines the macOS PNG+browser path and the Windows dev.new branch", {
  # .plot_show (and .isMacOS) were relocated from rtkogl.R to R/shell.R in Plan
  # 06-03 (survivors move before rtkogl.R is deleted in Plan 07).
  shell_file <- file.path(pkg_root, "R", "shell.R")
  src <- readLines(shell_file, warn = FALSE)

  expect_true(any(grepl("^.plot_show <- function", src)))

  helper_body <- .fn_body(src, ".plot_show")
  # macOS branch: temp PNG rendered off-screen, then opened in the browser.
  expect_true(any(grepl(".isMacOS()", helper_body, fixed = TRUE)))
  expect_true(any(grepl("png(", helper_body, fixed = TRUE)))
  expect_true(any(grepl("browseURL", helper_body, fixed = TRUE)))
  # Windows branch: unchanged interactive device (CMP-01).
  expect_true(any(grepl("dev.new()", helper_body, fixed = TRUE)))
})

test_that(".plot_show() on macOS writes a PNG and opens it without a native window", {
  # Exercise the macOS branch on any host: source locally so .plot_show resolves
  # .isMacOS lexically in this frame, then override it to TRUE. Capture the open
  # via the `browser` option (browseURL calls it when it is a function) so no
  # real browser launches and no quartz window is created. (.plot_show/.isMacOS
  # relocated to R/shell.R in Plan 06-03.)
  source(file.path(pkg_root, "R", "shell.R"), local = TRUE)
  .isMacOS <- function() TRUE

  opened <- NULL
  old <- options(browser = function(url, ...) { opened <<- url; invisible(TRUE) })
  on.exit(options(old), add = TRUE)

  .plot_show(function() plot(1:3, 1:3), width = 200, height = 150)

  expect_false(is.null(opened))
  expect_true(file.exists(opened))
  expect_gt(file.info(opened)$size, 0)
  expect_match(opened, "\\.png$")
})
