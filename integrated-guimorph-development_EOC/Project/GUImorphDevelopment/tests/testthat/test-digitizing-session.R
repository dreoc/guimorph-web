# Phase 5: Full Digitizing and Data Parity -- .gmw_session model + digitizing routes
#
# Unit-level coverage of the per-specimen digitizing record (.gmw_session) and
# the token-guarded loopback routes the browser uses to edit it: /anchor,
# /curve, /delete, /undo, /specimen. Mirrors the test-picking-transport.R
# direct-handler-invocation idiom (no live server, no same-process curl -- the
# route branches run on the R main thread, which a same-process curl can never
# reach). We build a synthetic `req` and call the production
# `.gmw_digitize_handler(token)` closure directly. Source-scans reuse the exact
# T-2-02, JSON-free, and CMP-01 predicates from test-picking-transport.R so the
# new routes are held to the same bar.

pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)

skip_if_no_pkg_source()
source(file.path(pkg_root, "R", "transport.R"), local = FALSE)

# Synthetic httpuv request: a PATH_INFO plus a rook.input whose read() hands back
# the raw bytes of `body`. body = NULL models an empty/absent request body.
make_req <- function(path, body = NULL) {
  raw_body <- if (is.null(body)) raw(0) else charToRaw(body)
  list(
    PATH_INFO  = path,
    rook.input = list(read = function(...) raw_body)
  )
}

# Drop any session state a test seeded, so blocks stay independent.
reset_session <- function(...) {
  for (t in c(...)) if (exists(t, envir = .gmw_session)) rm(list = t, envir = .gmw_session)
}

test_that("a well-formed /anchor returns 204 and appends a row to the current specimen", {
  token <- "TESTTOKEN_anchor_ok"
  reset_session(token)
  on.exit(reset_session(token), add = TRUE)
  handler <- .gmw_digitize_handler(token)

  resp <- handler(make_req(paste0("/", token, "/anchor"), "1,2,3"))
  expect_equal(resp$status, 204L)

  s <- .gmw_session_get(token)
  expect_false(is.null(s))
  cur <- s$specimens[[s$current]]
  expect_true(is.matrix(cur$anchor))
  expect_equal(dim(cur$anchor), c(1L, 3L))
  expect_equal(as.numeric(cur$anchor[1, ]), c(1, 2, 3))

  # A second anchor appends a second row in placement order.
  expect_equal(handler(make_req(paste0("/", token, "/anchor"), "4,5,6"))$status, 204L)
  cur2 <- .gmw_session_get(token)$specimens[[1]]
  expect_equal(dim(cur2$anchor), c(2L, 3L))
  expect_equal(as.numeric(cur2$anchor[2, ]), c(4, 5, 6))
})

test_that("/curve appends a 1x3 INTEGER row for three distinct indices; malformed dropped", {
  token <- "TESTTOKEN_curve_ok"
  reset_session(token)
  on.exit(reset_session(token), add = TRUE)
  handler <- .gmw_digitize_handler(token)

  resp <- handler(make_req(paste0("/", token, "/curve"), "1,2,3"))
  expect_equal(resp$status, 204L)
  cm <- .gmw_session_get(token)$curves
  expect_true(is.matrix(cm))
  expect_true(is.integer(cm))
  expect_equal(dim(cm), c(1L, 3L))
  expect_equal(as.integer(cm[1, ]), c(1L, 2L, 3L))

  # Malformed / duplicate bodies are dropped with 204; the curve matrix is
  # unchanged (curves are three DISTINCT indices, not coordinates).
  before <- .gmw_session_get(token)$curves
  bad <- c(
    "1,2",     # too few indices
    "1,1,2",   # duplicate index
    "a,b,c",   # non-numeric
    "1,2,3,4"  # too many indices
  )
  for (b in bad) {
    resp_bad <- handler(make_req(paste0("/", token, "/curve"), b))
    expect_equal(resp_bad$status, 204L)
    expect_identical(.gmw_session_get(token)$curves, before)
  }
  # An absent body is likewise dropped, not errored.
  expect_equal(handler(make_req(paste0("/", token, "/curve"), NULL))$status, 204L)
  expect_identical(.gmw_session_get(token)$curves, before)
})

test_that("/delete removes the named row and a following /undo restores it", {
  token <- "TESTTOKEN_delete_undo"
  reset_session(token)
  on.exit(reset_session(token), add = TRUE)
  handler <- .gmw_digitize_handler(token)

  # Place two anchors, then delete the first.
  expect_equal(handler(make_req(paste0("/", token, "/anchor"), "1,2,3"))$status, 204L)
  expect_equal(handler(make_req(paste0("/", token, "/anchor"), "4,5,6"))$status, 204L)

  resp_del <- handler(make_req(paste0("/", token, "/delete"), "anchor,1"))
  expect_equal(resp_del$status, 204L)
  after_del <- .gmw_session_get(token)$specimens[[1]]$anchor
  expect_equal(dim(after_del), c(1L, 3L))
  expect_equal(as.numeric(after_del[1, ]), c(4, 5, 6))

  # Undo restores the deleted row at its original position.
  resp_undo <- handler(make_req(paste0("/", token, "/undo"), NULL))
  expect_equal(resp_undo$status, 204L)
  restored <- .gmw_session_get(token)$specimens[[1]]$anchor
  expect_equal(dim(restored), c(2L, 3L))
  expect_equal(as.numeric(restored[1, ]), c(1, 2, 3))
  expect_equal(as.numeric(restored[2, ]), c(4, 5, 6))
})

test_that("/undo inverts a curve placement (drops the last curve row)", {
  token <- "TESTTOKEN_curve_undo"
  reset_session(token)
  on.exit(reset_session(token), add = TRUE)
  handler <- .gmw_digitize_handler(token)

  expect_equal(handler(make_req(paste0("/", token, "/curve"), "1,2,3"))$status, 204L)
  expect_equal(handler(make_req(paste0("/", token, "/curve"), "4,5,6"))$status, 204L)
  expect_equal(nrow(.gmw_session_get(token)$curves), 2L)

  expect_equal(handler(make_req(paste0("/", token, "/undo"), NULL))$status, 204L)
  cm <- .gmw_session_get(token)$curves
  expect_equal(nrow(cm), 1L)
  expect_true(is.integer(cm))
  expect_equal(as.integer(cm[1, ]), c(1L, 2L, 3L))
})

test_that("/specimen sets the current index and clears the one-deep undo", {
  token <- "TESTTOKEN_specimen"
  reset_session(token)
  on.exit(reset_session(token), add = TRUE)
  handler <- .gmw_digitize_handler(token)

  # Seed an undo-able action so we can prove the switch clears it.
  expect_equal(handler(make_req(paste0("/", token, "/anchor"), "1,2,3"))$status, 204L)
  expect_false(is.null(.gmw_session_get(token)$undo))

  resp <- handler(make_req(paste0("/", token, "/specimen"), "2"))
  expect_equal(resp$status, 204L)
  s <- .gmw_session_get(token)
  expect_equal(s$current, 2L)
  expect_true(is.null(s$undo))
  # After the switch there is nothing to undo (undo returns FALSE / is a no-op).
  expect_false(.gmw_session_undo(token))
})

test_that("the digitize handler writes only its own token (no cross-token write)", {
  tok_a <- "TESTTOKEN_iso_a5"
  tok_b <- "TESTTOKEN_iso_b5"
  reset_session(tok_a, tok_b)
  on.exit(reset_session(tok_a, tok_b), add = TRUE)

  handler_a <- .gmw_digitize_handler(tok_a)
  expect_equal(handler_a(make_req(paste0("/", tok_a, "/anchor"), "1,2,3"))$status, 204L)

  # tok_a's handler stored under tok_a only; tok_b's session is untouched.
  expect_equal(dim(.gmw_session_get(tok_a)$specimens[[1]]$anchor), c(1L, 3L))
  expect_null(.gmw_session_get(tok_b))
})

test_that("/pick and /close are delegated to the untouched pick handler; other suffix 404", {
  token <- "TESTTOKEN_delegate"
  reset_session(token)
  on.exit(reset_session(token), add = TRUE)
  handler <- .gmw_digitize_handler(token)

  # /pick delegates to .gmw_pick_handler -> writes .gmw_picks, returns 204.
  if (exists(token, envir = .gmw_picks)) rm(list = token, envir = .gmw_picks)
  on.exit(if (exists(token, envir = .gmw_picks)) rm(list = token, envir = .gmw_picks), add = TRUE)
  resp_pick <- handler(make_req(paste0("/", token, "/pick"), "1,2,3"))
  expect_equal(resp_pick$status, 204L)
  expect_equal(dim(.gmw_picks_get(token)), c(1L, 3L))

  # /close delegates too; drain the deferred later::later stop it schedules.
  resp_close <- handler(make_req(paste0("/", token, "/close")))
  expect_equal(resp_close$status, 204L)
  Sys.sleep(0.6)
  later::run_now()

  # Any other suffix is a plain 404 (never a filesystem read of the path).
  resp_other <- handler(make_req(paste0("/", token, "/nope")))
  expect_equal(resp_other$status, 404L)
})

test_that("exported gmw_session() reads back the server-owned record", {
  token <- "TESTTOKEN_accessor"
  reset_session(token)
  on.exit(reset_session(token), add = TRUE)
  handler <- .gmw_digitize_handler(token)

  expect_equal(handler(make_req(paste0("/", token, "/anchor"), "1,2,3"))$status, 204L)
  expect_identical(gmw_session(token), .gmw_session_get(token))
  all_sessions <- gmw_session()
  expect_true(token %in% names(all_sessions))
})

test_that("the digitizing routes never join the request path to the filesystem (T-2-02)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_root, "R", "transport.R"), warn = FALSE)

  # Same invariant predicate as test-picking-transport.R: no source line that
  # references the request path (PATH_INFO) may also call a filesystem
  # join/normalize/raw-read primitive.
  reqpath_lines <- grep("PATH_INFO", src, fixed = TRUE, value = TRUE)
  joins_fs <- vapply(reqpath_lines, function(ln) {
    any(vapply(c("file.path", "normalizePath", "readBin"),
               function(fn) grepl(fn, ln, fixed = TRUE), logical(1)))
  }, logical(1))
  expect_false(any(joins_fs))

  # The bodies are parsed with base-R string ops only -- no JSON dependency.
  expect_false(any(grepl("jsonlite", src, fixed = TRUE)))
  expect_false(any(grepl("fromJSON", src, fixed = TRUE)))
  expect_false(any(grepl("toJSON", src, fixed = TRUE)))
})

test_that("CMP-01: transport.R never assigns the native oracle engine env", {
  skip_if_no_pkg_source()
  tsrc <- readLines(file.path(pkg_root, "R", "transport.R"), warn = FALSE)
  expect_false(any(grepl(".gmw_engine$", tsrc, fixed = TRUE)))
  expect_false(any(grepl(".gmw_engine <-", tsrc, fixed = TRUE)))
})
