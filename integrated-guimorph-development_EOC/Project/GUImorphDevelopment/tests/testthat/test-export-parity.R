pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

test_that("export parity helper functions exist", {
  source(file.path(pkg_root, "R", "rtkogl.R"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.main.r"), local = TRUE)

  expect_true(exists(".csv_normalize_lines", mode = "function"))
  expect_true(exists(".rds_payload_signature", mode = "function"))
})

test_that("csv parity normalization is deterministic", {
  source(file.path(pkg_root, "R", "rtkogl.R"), local = TRUE)
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
  source(file.path(pkg_root, "R", "rtkogl.R"), local = TRUE)
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
