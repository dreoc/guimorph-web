pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()

test_that("shortcut helper is relocated to shell.R with the Command/Ctrl branch", {
  # shortcutLabel was relocated from rtkogl.R to R/shell.R in Plan 06-03 (survivors
  # move before rtkogl.R is deleted in Plan 07). The Tk-only bindPlatformAccelerator
  # helper (which held the <Command-...> tkbind) had no browser analog and was
  # dropped, so its assertion is retired here.
  shell_file <- file.path(pkg_root, "R", "shell.R")
  src <- readLines(shell_file, warn = FALSE)

  expect_true(any(grepl("^shortcutLabel <- function\\(key\\)", src)))
  expect_true(any(grepl("Cmd\\+", src)))
})

test_that("Tk accelerator bindings are removed from main.r", {
  # Plan 06-04 deleted bind.accelerators() and its Tk <Command-...> bindings
  # (bindPlatformAccelerator). Keyboard accelerators are now handled by the
  # browser shell, so main.r must contain no Tk accelerator wiring.
  main_file <- file.path(pkg_root, "R", "3dDigitize.main.r")
  src <- readLines(main_file, warn = FALSE)

  expect_false(any(grepl("bindPlatformAccelerator\\(", src)))
})

test_that("dialogs allow all files and warn on odd extensions", {
  main_file <- file.path(pkg_root, "R", "3dDigitize.main.r")
  src <- readLines(main_file, warn = FALSE)

  expect_true(any(grepl("\\{\\{All files\\} \\*\\}", src)))
  expect_true(any(grepl("\\.warnUnexpectedExtension\\(", src)))
})

test_that("tab gating function remains centralized", {
  # Plan 06-04 kept refreshTabGating but stripped its Tk notebook widget calls
  # and the status-bar side effect ("Surface Sliders and Curves unlocked."); it
  # now computes server-side tab-enable state only.
  main_file <- file.path(pkg_root, "R", "3dDigitize.main.r")
  src <- readLines(main_file, warn = FALSE)

  expect_true(any(grepl("^refreshTabGating <- function\\(e\\)", src)))
})

test_that("curve and surface tabs consume shared shortcut and wheel helpers", {
  # Plan 06-05 removed ui.curve (which held the shortcutLabel("[") description)
  # from curve.r; the "[" / "]" specimen shortcuts are browser accelerators now,
  # so curve.r must no longer host a Tk shortcut builder. The surface tab still
  # consumes the shared wheel helper until Plan 06-06 strips surface.r.
  curve_file <- file.path(pkg_root, "R", "3dDigitize.curve.r")
  curve_src <- readLines(curve_file, warn = FALSE)
  surface_file <- file.path(pkg_root, "R", "3dDigitize.surface.r")
  surface_src <- readLines(surface_file, warn = FALSE)

  expect_false(any(grepl("shortcutLabel", curve_src, fixed = TRUE)))
  expect_true(any(grepl("zoom\\(e, normalizeWheelDelta\\(D\\)\\)", surface_src)))
})
