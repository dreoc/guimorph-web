pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# Source-scan assertions for Plan 06-04: 3dDigitize.main.r must retain its
# data/model + serialization logic while shedding every Tk-chrome widget, every
# native engine verb, and the retired S3 UI generics. Mirrors the source-scan
# style of test-transport.R / test-macos-dialog-shortcuts-parity.R and needs the
# package R/ tree (skips cleanly under R CMD check's lazy-load database).
skip_if_no_pkg_source()

main_file <- file.path(pkg_root, "R", "3dDigitize.main.r")

# Strip comments (full-line and inline) before scanning code, matching the
# plan's `grep -v '^#'`-style acceptance so prose in the kept comments does not
# masquerade as live chrome or engine calls.
main_code <- local({
  src <- readLines(main_file, warn = FALSE)
  sub("#.*$", "", src)
})

test_that("no Tk chrome widgets remain in main.r (T-6-12)", {
  chrome <- "tktoplevel|ttknotebook|tkmenu|ttkprogressbar|tkgrid|tkpack"
  expect_false(any(grepl(chrome, main_code)))
})

test_that("no native engine verbs remain in main.r (T-6-13)", {
  verbs <- "(^|[^._[:alnum:]])(add|set|del|shows)\\("
  expect_false(any(grepl(verbs, main_code)))
})

test_that("retired S3 UI generics are gone from main.r", {
  for (gen in c("ui", "init", "bind", "updateWidgets")) {
    def <- sprintf("^%s\\s*(<-|=)\\s*function", gen)
    expect_false(any(grepl(def, main_code)),
                 info = sprintf("generic definition '%s' should be removed", gen))
    dispatch <- sprintf("UseMethod\\(\\s*[\"']%s[\"']", gen)
    expect_false(any(grepl(dispatch, main_code)),
                 info = sprintf("UseMethod dispatch for '%s' should be removed", gen))
  }
})

test_that("analytical + serialization symbols are preserved (no over-strip, T-6-12)", {
  kept <- c(
    "^read\\.vertex\\.3D\\s*(<-|=)\\s*function",
    "^write\\.vertex\\.3D\\s*(<-|=)\\s*function",
    "^\\.dgt_emit_session_blocks\\s*(<-|=)\\s*function",
    "^\\.gmw_save_session_dgt\\s*(<-|=)\\s*function",
    "^mergeDgt\\s*(<-|=)\\s*function",
    "^refreshTabGating\\s*(<-|=)\\s*function"
  )
  for (pat in kept) {
    expect_true(any(grepl(pat, main_code)),
                info = sprintf("expected kept symbol matching /%s/", pat))
  }
})
