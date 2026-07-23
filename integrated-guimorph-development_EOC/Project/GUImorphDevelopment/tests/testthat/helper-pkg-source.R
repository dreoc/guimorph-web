# Source-tree access for the inspection tests.
#
# Several tests below assert on the text of the package's own R sources rather
# than on behaviour. That only works against a source tree. Under R CMD check
# only tests/ is copied into <pkg>.Rcheck, and an installed package stores R/ as
# a lazy-load database rather than as .R files, so those paths cannot resolve.
#
# These helpers give one place to locate the source tree and to skip cleanly when
# it is absent, instead of failing a check that is otherwise healthy.

pkg_source_root <- function() {
  root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)
  if (dir.exists(file.path(root, "R"))) root else NA_character_
}

skip_if_no_pkg_source <- function() {
  testthat::skip_if(
    is.na(pkg_source_root()),
    "package R/ source not available (R CMD check installs a lazy-load database)"
  )
}
