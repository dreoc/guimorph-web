pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()

test_that("compute forwards parity-critical gpagen options", {
  geomorph_file <- file.path(pkg_root, "R", "3dDigitize.geomorph.r")
  src <- readLines(geomorph_file, warn = FALSE)

  expect_true(any(grepl("geomorph::gpagen\\(A=coords.A", src)))
  expect_true(any(grepl("curves = curves", src, fixed = TRUE)))
  expect_true(any(grepl("surfaces = surfaces", src, fixed = TRUE)))
  expect_true(any(grepl("PrinAxes = itob\\(tclvalue\\(e\\$PrinAxes\\)\\)", src)))
  expect_true(any(grepl("ProcD = itob\\(tclvalue\\(e\\$ProcD\\)\\)", src)))
  expect_true(any(grepl("Proj = itob\\(tclvalue\\(e\\$Proj\\)\\)", src)))
  expect_true(any(grepl("approxBE = itob\\(tclvalue\\(e\\$approxBE\\)\\)", src)))
  expect_true(any(grepl("Parallel = itob\\(tclvalue\\(e\\$parallel\\)\\)", src)))
  expect_true(any(grepl("\\.safe_gpagen_maxiter <- function\\(raw\\)", src)))
  expect_true(any(grepl("max.iter = max_iter", src, fixed = TRUE)))
})

test_that("aligned coordinate accessor supports geomorph 4.x and legacy layouts", {
  source(file.path(pkg_root, "R", "3dDigitize.geomorph.r"), local = TRUE)

  coords_new <- array(1, dim = c(2, 3, 1))
  coords_old <- array(2, dim = c(2, 3, 1))
  expect_identical(.gm_aligned_coords(list(coords = coords_new)), coords_new)
  expect_identical(.gm_aligned_coords(list(coord = coords_old)), coords_old)
})
