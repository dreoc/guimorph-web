pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()

.byte_signature <- function(path) {
  raw <- readBin(path, what = "raw", n = file.info(path)$size)
  tf <- tempfile(fileext = ".bin")
  on.exit(unlink(tf), add = TRUE)
  writeBin(raw, tf)
  as.character(tools::md5sum(tf))
}

test_that("dgt parity helper functions exist", {
  source(file.path(pkg_root, "R", "rtkogl.R"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.digitize.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.curve.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.surface.r"), local = TRUE)

  expect_true(exists(".dgt_format_num", mode = "function"))
  expect_true(exists(".dgt_write_matrix_block", mode = "function"))
  expect_true(exists(".dgt_normalize_lines", mode = "function"))
})

test_that("dgt writer output matches parity fixture", {
  source(file.path(pkg_root, "R", "rtkogl.R"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.digitize.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.curve.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.surface.r"), local = TRUE)

  # Ships in inst/extdata, so it is reachable from an installed package. During
  # R CMD check only tests/ is copied to the check directory, so system.file() is
  # the only path that resolves there; the source-tree fallback covers
  # devtools::test() against an uninstalled tree.
  fixture <- system.file("extdata", "folsom3d.dgt", package = "GUImorphWeb")
  if (!nzchar(fixture)) {
    fixture <- file.path(pkg_root, "inst", "extdata", "folsom3d.dgt")
  }
  skip_if_not(file.exists(fixture), "folsom3d.dgt fixture not available")
  out <- tempfile(fileext = ".dgt")
  file.create(out)

  curves <- matrix(c(1, 2, 3), nrow = 1, byrow = TRUE)
  landmarks <- matrix(c(
    1, 2, 3,
    -4.5, 6.25, -7.75
  ), ncol = 3, byrow = TRUE)
  anchors <- matrix(c(
    9.5, -1.25, 0.5
  ), ncol = 3, byrow = TRUE)
  surface <- matrix(c(
    0.125, 0.5, 0.875,
    -0.125, -0.5, -0.875
  ), ncol = 3, byrow = TRUE)

  .dgt_write_matrix_block(out, "Curve=", curves)
  write("", out, append = TRUE)
  write("TemplateNumber=NULL", out, append = TRUE)
  write("", out, append = TRUE)
  .dgt_write_matrix_block(out, "LM3=", landmarks)
  .dgt_write_matrix_block(out, "AC3=", anchors)
  write("ID=A6_1_clean.ply", out, append = TRUE)
  write("Template=A6_1_clean.ply", out, append = TRUE)
  .dgt_write_matrix_block(out, "Surface=", surface)
  write("", out, append = TRUE)

  expected <- .dgt_normalize_lines(readLines(fixture, warn = FALSE))
  actual <- .dgt_normalize_lines(readLines(out, warn = FALSE))
  expect_equal(actual, expected)
})

test_that("DAT-03 bidirectional fixture gate is enforceable", {
  parity_dir <- file.path(pkg_root, "tests", "fixtures", "parity")
  windows_authored <- file.path(parity_dir, "windows-authored-roundtrip.dgt")
  windows_rewritten <- file.path(parity_dir, "windows-authored-roundtrip-rewrite.dgt")
  mac_authored <- file.path(parity_dir, "mac-authored-roundtrip.dgt")
  mac_rewritten <- file.path(parity_dir, "mac-authored-roundtrip-rewrite.dgt")

  if (!file.exists(windows_authored) ||
      !file.exists(windows_rewritten) ||
      !file.exists(mac_authored) ||
      !file.exists(mac_rewritten)) {
    skip("Bidirectional DAT-03 byte fixtures are required from Windows/macOS round-trip evidence.")
  }

  expect_identical(.byte_signature(windows_authored), .byte_signature(windows_rewritten))
  expect_identical(.byte_signature(mac_authored), .byte_signature(mac_rewritten))
})
