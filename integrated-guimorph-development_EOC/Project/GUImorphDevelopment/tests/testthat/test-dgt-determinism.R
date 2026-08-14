pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect and exercise package source text; skip when only an
# installed package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()

# Raw-byte md5 signature: no line-ending normalization, so it is sensitive to
# the exact terminator. Copied from test-dgt-cross-platform.R:7-13.
.byte_signature <- function(path) {
  raw <- readBin(path, what = "raw", n = file.info(path)$size)
  tf <- tempfile(fileext = ".bin")
  on.exit(unlink(tf), add = TRUE)
  writeBin(raw, tf)
  as.character(tools::md5sum(tf))
}

test_that("identical arrays write identical bytes", {
  source(file.path(pkg_root, "R", "shell.R"), local = TRUE)  # dbg() lives here since Plan 06-03; rtkogl.R deleted in Plan 06-07
  source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = TRUE)

  mat <- matrix(c(
    1, 2, 3,
    -4.5, 6.25, -7.75,
    1 / 3, 2 / 3, 0.125
  ), ncol = 3, byrow = TRUE)

  f1 <- tempfile(fileext = ".dgt")
  f2 <- tempfile(fileext = ".dgt")
  file.create(f1)
  file.create(f2)
  on.exit(unlink(c(f1, f2)), add = TRUE)

  .dgt_write_matrix_block(f1, "LM3=", mat)
  .dgt_write_matrix_block(f2, "LM3=", mat)

  expect_identical(.byte_signature(f1), .byte_signature(f2))
})

test_that("output is CRLF-terminated", {
  source(file.path(pkg_root, "R", "shell.R"), local = TRUE)  # dbg() lives here since Plan 06-03; rtkogl.R deleted in Plan 06-07
  source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = TRUE)

  mat <- matrix(c(
    1, 2, 3,
    -4.5, 6.25, -7.75
  ), ncol = 3, byrow = TRUE)

  out <- tempfile(fileext = ".dgt")
  file.create(out)
  on.exit(unlink(out), add = TRUE)
  .dgt_write_matrix_block(out, "LM3=", mat)

  raw <- readBin(out, what = "raw", n = file.info(out)$size)
  lf_pos <- which(raw == as.raw(0x0a))
  cr_pos <- which(raw == as.raw(0x0d))

  # There is at least one line break to check.
  expect_gt(length(lf_pos), 0L)
  # Every LF is the second byte of a CR+LF pair (no lone LF).
  expect_true(all(lf_pos > 1L & raw[lf_pos - 1L] == as.raw(0x0d)))
  # CR count equals LF count: no stray CR, every break is exactly one CRLF.
  expect_identical(length(cr_pos), length(lf_pos))
})

test_that("rounding is R-decided", {
  source(file.path(pkg_root, "R", "shell.R"), local = TRUE)  # dbg() lives here since Plan 06-03; rtkogl.R deleted in Plan 06-07
  source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = TRUE)

  # Straightforward six-decimal truncation of a repeating decimal.
  expect_identical(.dgt_format_num(1 / 3), "0.333333")

  # A sixth-decimal tie must be decided by R's round(x, 6), not by whatever the
  # platform C library does inside a bare formatC of the unrounded value.
  tie <- 0.1234565
  expect_identical(
    .dgt_format_num(tie),
    formatC(round(as.numeric(tie), 6), format = "f", digits = 6)
  )
})
