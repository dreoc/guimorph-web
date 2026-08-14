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
  source(file.path(pkg_root, "R", "shell.R"), local = TRUE)  # dbg() lives here since Plan 06-03; rtkogl.R deleted in Plan 06-07
  source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.digitize.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.curve.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.surface.r"), local = TRUE)

  expect_true(exists(".dgt_format_num", mode = "function"))
  expect_true(exists(".dgt_write_matrix_block", mode = "function"))
  expect_true(exists(".dgt_normalize_lines", mode = "function"))
})

test_that("dgt writer output matches parity fixture", {
  source(file.path(pkg_root, "R", "shell.R"), local = TRUE)  # dbg() lives here since Plan 06-03; rtkogl.R deleted in Plan 06-07
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

test_that("browser save is byte-identical to the canonical writer for identical arrays", {
  # DAT-01 as one-writer-vs-itself: the browser Save path (.gmw_save_session_dgt)
  # must emit bytes identical to the canonical saveToDgt block sequence run over
  # the SAME in-memory arrays. Because R keeps the single .dgt writer (RESEARCH
  # Pattern 6 / Assumption A1), there is no second serializer to diverge -- this
  # test proves the browser trigger reuses the identical block sequence + helpers.
  #
  # NOTE: the live native-GUI-vs-browser dual-path DAT-01 run needs a Windows
  # tkogl2 host and is recorded as manual UAT (05-VALIDATION.md); this R-level
  # write-vs-write byte test is the automated gate.
  source(file.path(pkg_root, "R", "shell.R"), local = TRUE)  # dbg() lives here since Plan 06-03; rtkogl.R deleted in Plan 06-07
  source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.digitize.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.curve.r"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.surface.r"), local = TRUE)
  source(file.path(pkg_root, "R", "transport.R"), local = TRUE)

  # One in-memory array set: curves as a 3-index integer row, plus a single
  # specimen's landmarks / anchors / surface / template / id.
  curves    <- matrix(c(1L, 2L, 3L), nrow = 1L, byrow = TRUE)
  landmarks <- matrix(c(
    1, 2, 3,
    -4.5, 6.25, -7.75
  ), ncol = 3, byrow = TRUE)
  anchors   <- matrix(c(9.5, -1.25, 0.5), ncol = 3, byrow = TRUE)
  surface   <- matrix(c(
    0.125, 0.5, 0.875,
    -0.125, -0.5, -0.875
  ), ncol = 3, byrow = TRUE)
  template  <- "A6_1_clean.ply"
  id        <- "A6_1_clean.ply"

  # Seed a session token with those arrays via the 05-02 session store.
  token <- "TESTTOKEN_dat01_byte_identity"
  if (exists(token, envir = .gmw_session)) rm(list = token, envir = .gmw_session)
  on.exit(if (exists(token, envir = .gmw_session)) rm(list = token, envir = .gmw_session),
          add = TRUE)
  assign(token, list(
    specimens = list(list(
      land     = landmarks,
      anchor   = anchors,
      surfaces = surface,
      template = template,
      id       = id
    )),
    current = 1L,
    curves  = curves,
    undo    = NULL
  ), envir = .gmw_session)

  # File A: the browser save path serializes the session record.
  fileA <- tempfile(fileext = ".dgt")
  on.exit(unlink(fileA), add = TRUE)
  .gmw_save_session_dgt(token, fileA)

  # File B: the SAME canonical block sequence called directly over the identical
  # arrays (Curve=, TemplateNumber=NULL, then per-specimen LM3=/AC3=/ID=/
  # Template=/Surface=), through the SAME deterministic .dgt_writeln helper.
  fileB <- tempfile(fileext = ".dgt")
  on.exit(unlink(fileB), add = TRUE)
  file.create(fileB)
  .dgt_write_matrix_block(fileB, "Curve=", curves)
  .dgt_writeln(fileB, "")
  .dgt_writeln(fileB, "TemplateNumber=NULL")
  .dgt_writeln(fileB, "")
  .dgt_write_matrix_block(fileB, "LM3=", landmarks)
  .dgt_write_matrix_block(fileB, "AC3=", anchors)
  .dgt_writeln(fileB, paste0("ID=", id))
  .dgt_writeln(fileB, paste0("Template=", template))
  .dgt_write_matrix_block(fileB, "Surface=", surface)
  .dgt_writeln(fileB, "")

  expect_identical(.byte_signature(fileA), .byte_signature(fileB))
})

test_that("CMP-01: the .dgt save path never writes .gmw_engine; native oracle stays loadable or skips cleanly", {
  skip_if_no_pkg_source()

  # (i) Source-scan (mirror test-picking-transport.R:134-142): the browser save
  # path must not regress the CMP-01 invariant -- 3dDigitize.main.r never assigns
  # or reads the native oracle engine env.
  msrc <- readLines(file.path(pkg_root, "R", "3dDigitize.main.r"), warn = FALSE)
  expect_false(any(grepl(".gmw_engine$", msrc, fixed = TRUE)))
  expect_false(any(grepl(".gmw_engine <-", msrc, fixed = TRUE)))

  # (ii) Positive check: when the package namespace is already loaded, the native
  # engine status env exposes a logical scalar .gmw_engine$ok (rtkogl.R). Skip
  # cleanly otherwise (headless / tarball / engine absent), mirroring the
  # test-retina-picking-parity.R skip-if-absent idiom. isNamespaceLoaded avoids a
  # tcltk2 GUI-init load.
  if (!isNamespaceLoaded("GUImorphWeb")) skip("GUImorphWeb namespace not loaded")
  eng <- tryCatch(get(".gmw_engine", envir = asNamespace("GUImorphWeb")),
                  error = function(e) NULL)
  if (is.null(eng) || !exists("ok", envir = eng, inherits = FALSE)) {
    skip("native tkogl2 engine not available")
  }
  expect_true(is.logical(eng$ok))
  expect_length(eng$ok, 1L)
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
