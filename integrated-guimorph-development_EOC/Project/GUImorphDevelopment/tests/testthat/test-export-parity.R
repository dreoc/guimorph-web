pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()

test_that("export parity helper functions exist", {
  source(file.path(pkg_root, "R", "shell.R"), local = TRUE)  # dbg() lives here since Plan 06-03; rtkogl.R deleted in Plan 06-07
  source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = TRUE)

  expect_true(exists(".csv_normalize_lines", mode = "function"))
  expect_true(exists(".rds_payload_signature", mode = "function"))
})

test_that("csv parity normalization is deterministic", {
  source(file.path(pkg_root, "R", "shell.R"), local = TRUE)  # dbg() lives here since Plan 06-03; rtkogl.R deleted in Plan 06-07
  source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = TRUE)

  fixture <- file.path(pkg_root, "tests", "fixtures", "parity", "reference-export.csv")
  expect_true(file.exists(fixture))

  raw <- c(
    "\"Csize\",\"coords.1\",\"coords.2\"",
    "1.5000001,0.123456789,-0.987654321"
  )
  expect_equal(.csv_normalize_lines(raw), readLines(fixture, warn = FALSE))
})

test_that("rds payload signature is stable", {
  source(file.path(pkg_root, "R", "shell.R"), local = TRUE)  # dbg() lives here since Plan 06-03; rtkogl.R deleted in Plan 06-07
  source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = TRUE)

  land <- array(c(
    1, 2, 3,
    4, 5, 6
  ), dim = c(2, 3, 1))
  dimnames(land) <- list(NULL, c("x", "y", "z"), "specimen_1")
  payload <- list(
    land = land,
    curves = matrix(c(1, 2, 2), nrow = 1),
    surfaces = matrix(3, nrow = 1),
    specimen.names = "specimen_1"
  )

  sig <- .rds_payload_signature(payload)
  expect_match(sig, "^[a-f0-9]{32}$")
})

# The /export trigger seam must reuse the existing exporters verbatim -- no
# second serializer -- and its only request-borne argument is a format token
# validated against the allow-list c("csv","rds"); the export path is chosen
# R-side by save()/exportGeomorph(), never taken from the request (T-5-13).
test_that(".gmw_export_session dispatches only to save/exportGeomorph with an allow-listed fmt", {
  geomorph_file <- file.path(pkg_root, "R", "3dDigitize.geomorph.r")
  src <- readLines(geomorph_file, warn = FALSE)

  expect_true(any(grepl("\\.gmw_export_session <- function", src)))
  # Dispatches to the existing exporters (no new serializer introduced).
  expect_true(any(grepl("save(e)", src, fixed = TRUE)))
  expect_true(any(grepl("exportGeomorph(e)", src, fixed = TRUE)))
  # Format token validated against the allow-list (tolerate optional spacing).
  expect_true(any(grepl('c\\("csv",\\s*"rds"\\)', src)))
})
