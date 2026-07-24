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

test_that("a failed native engine load does not abort package load", {
  # Found on macOS 26.5.2: tkogl2.dylib is built against Tcl 9.0 while R 4.6.1's
  # tcltk links a different major version, so the engine will not load. .onLoad
  # used to stop() there, which took the browser paths down with it even though
  # they need no native engine. The failure is now deferred to the one entry
  # point that does need it.
  rtkogl_file <- file.path(pkg_root, "R", "rtkogl.R")
  src <- readLines(rtkogl_file, warn = FALSE)

  onload_body <- .fn_body(src, ".onLoad")
  expect_false(any(grepl("stop(", onload_body, fixed = TRUE)))
  expect_true(any(grepl("packageStartupMessage", onload_body, fixed = TRUE)))
  expect_true(any(grepl(".gmw_engine$ok", onload_body, fixed = TRUE)))

  # Digitizing, and only digitizing, refuses when the engine is absent.
  expect_true(any(grepl(".gmw_require_engine()",
                        .fn_body(src, "GUImorphWeb"), fixed = TRUE)))
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
  rtkogl_file <- file.path(pkg_root, "R", "rtkogl.R")
  src <- readLines(rtkogl_file, warn = FALSE)

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
  # real browser launches and no quartz window is created.
  source(file.path(pkg_root, "R", "rtkogl.R"), local = TRUE)
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
