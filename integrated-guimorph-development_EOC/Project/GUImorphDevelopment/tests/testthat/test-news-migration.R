pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# UI-03 source-scan gate: the 1.0.0 migration note must ship in NEWS.md with the
# breaking-change guidance for native-path users. Reads NEWS.md directly. See
# helper-pkg-source.R.
skip_if_no_pkg_source()

test_that("NEWS.md ships the 1.0.0 migration note (pin 0.10.0, GUImorph, D-04)", {
  news_path <- file.path(pkg_root, "NEWS.md")
  expect_true(file.exists(news_path))

  news <- readLines(news_path, warn = FALSE)

  # 1.0.0 release header (top-level R NEWS convention).
  expect_true(any(grepl("^#\\s+GUImorphWeb\\s+1\\.0\\.0", news)))

  # Fallback pin target: the last engine-bundling release (D-06).
  expect_true(any(grepl("0.10.0", news, fixed = TRUE)))

  # Primary migration destination: the native GUImorph project (D-07).
  expect_true(any(grepl("GUImorph", news, fixed = TRUE)))
  expect_true(any(grepl("dreoc/GUImorph", news, fixed = TRUE)))

  # PICK-03 / DAT-02 formally closed as won't-verify (D-04).
  expect_true(any(grepl("PICK-03", news, fixed = TRUE)))
  expect_true(any(grepl("DAT-02", news, fixed = TRUE)))
  expect_true(any(grepl("won't-verify", news, fixed = TRUE)))
})
