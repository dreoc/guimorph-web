pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# Source-scan guard for Plan 06-06 (UI-01/UI-02): 3dDigitize.surface.r and
# 3dDigitize.geomorph.r must retain their analytical / serialization logic while
# shedding every Tk builder, dialog, and native engine verb, and transport.R
# must carry the GPA option flags over a /gpa-family route. Mirrors the
# readLines + grepl + comment-strip idiom of test-main-chrome-stripped.R /
# test-transport.R and needs the package R/ tree (skips cleanly under R CMD
# check's lazy-load database). Forbidden tokens are built from patterns so the
# negative gates cannot self-trip on this file's own prose.
skip_if_no_pkg_source()

surface_file  <- file.path(pkg_root, "R", "3dDigitize.surface.r")
geomorph_file <- file.path(pkg_root, "R", "3dDigitize.geomorph.r")
transport_file <- file.path(pkg_root, "R", "transport.R")

# Strip full-line and inline comments before scanning code so kept prose does
# not masquerade as live Tk chrome / dialogs / engine calls.
code_of <- function(path) sub("#.*$", "", readLines(path, warn = FALSE))

# Native engine verbs bridged by the (deleted) rtkogl.R: add/set/del/shows.
engine_verbs <- "(^|[^._[:alnum:]])(add|set|del|shows)\\("

test_that("surface.r is Tk builder / dialog / engine-verb free (UI-01/UI-02)", {
  code <- code_of(surface_file)

  ui_builder <- paste0("ui", ".", "surface")   # the deleted Tk tab builder
  msgbox     <- paste0("tk", "messageBox")      # the deleted message dialog
  toplevel   <- paste0("tk", "toplevel")        # the deleted slider-count window

  expect_false(any(grepl(ui_builder, code, fixed = TRUE)))
  expect_false(any(grepl(msgbox,     code, fixed = TRUE)))
  expect_false(any(grepl(toplevel,   code, fixed = TRUE)))
  expect_false(any(grepl(engine_verbs, code)))

  # No over-strip: the headless downsample seam (with its mandatory transpose)
  # and the template / .dgt serializers survive.
  src <- readLines(surface_file, warn = FALSE)
  expect_true(any(grepl("^\\.gmw_downsample_session <- function", src)))
  expect_true(any(grepl("as.vector(t(", src, fixed = TRUE)))
  expect_true(any(grepl("^read\\.surface <- function", src)))
  expect_true(any(grepl("^write\\.surface <- function", src)))
})

test_that("geomorph.r is Tk builder / tk2* / dialog / engine-verb free (UI-01/UI-02)", {
  code <- code_of(geomorph_file)

  ui_builder <- paste0("ui", ".", "geomorph")   # the deleted Tk GPA tab builder
  tk2widget  <- paste0("tk", "2[a-z]+")          # tk2label/entry/spinbox/checkbutton
  msgbox     <- paste0("tk", "messageBox")       # the deleted message dialogs
  savefile   <- paste0("tk", "getSaveFile")      # the deleted save-file pickers

  expect_false(any(grepl(ui_builder, code, fixed = TRUE)))
  expect_false(any(grepl(tk2widget,  code)))
  expect_false(any(grepl(msgbox,     code, fixed = TRUE)))
  expect_false(any(grepl(savefile,   code, fixed = TRUE)))
  expect_false(any(grepl(engine_verbs, code)))

  # No over-strip: the compute / assembly / export logic survives, and the
  # parity-critical gpagen forwarding in compute() is byte-unchanged.
  src <- readLines(geomorph_file, warn = FALSE)
  expect_true(any(grepl("^\\.build_geomorph_data <- function", src)))
  expect_true(any(grepl("^compute <- function", src)))
  expect_true(any(grepl("geomorph::gpagen(A=coords.A", src, fixed = TRUE)))
  expect_true(any(grepl("^\\.gmw_session_to_geomorph_env <- function", src)))
})

test_that("transport.R carries GPA option flags over a /gpa-family route", {
  code <- code_of(transport_file)
  # A /gpa route branch exists and a strict CSV parser feeds its options.
  expect_true(any(grepl("/gpa", code, fixed = TRUE)))
  expect_true(any(grepl("\\.gmw_parse_gpaopts", code)))
  # The GPA seam is called with the parsed option list (not the bare token only).
  expect_true(any(grepl(".gmw_gpa_session(token, opts)", code, fixed = TRUE)))
})
