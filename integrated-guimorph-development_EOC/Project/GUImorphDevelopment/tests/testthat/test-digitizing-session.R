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

# Parse the bare "L=..;A=..;S=.." overlays payload into a named list of flat
# numeric vectors, so a test can assert exactly what the browser would rebuild.
parse_overlays <- function(body) {
  fields <- strsplit(body, ";", fixed = TRUE)[[1]]
  out <- list(L = numeric(0), A = numeric(0), S = numeric(0))
  for (f in fields) {
    eq  <- regexpr("=", f, fixed = TRUE)
    tag <- substr(f, 1L, eq - 1L)
    val <- substr(f, eq + 1L, nchar(f))
    nums <- suppressWarnings(as.numeric(strsplit(val, ",", fixed = TRUE)[[1]]))
    out[[tag]] <- nums[is.finite(nums)]
  }
  out
}

test_that("/overlays re-serves the active specimen's landmark/anchor/surface coords", {
  token <- "TESTTOKEN_overlays"
  reset_session(token)
  on.exit(reset_session(token), add = TRUE)
  handler <- .gmw_digitize_handler(token)

  # A fresh session re-serves 200 with three empty layers.
  resp0 <- handler(make_req(paste0("/", token, "/overlays")))
  expect_equal(resp0$status, 200L)
  ov0 <- parse_overlays(resp0$body)
  expect_length(ov0$L, 0L)
  expect_length(ov0$A, 0L)
  expect_length(ov0$S, 0L)

  # Seed one landmark and one surface row directly; place two anchors via route.
  s <- .gmw_session_get(token)
  s$specimens[[1]]$land     <- rbind(s$specimens[[1]]$land, c(0.1, 0.2, 0.3))
  s$specimens[[1]]$surfaces <- rbind(s$specimens[[1]]$surfaces, c(7, 8, 9))
  assign(token, s, envir = .gmw_session)
  expect_equal(handler(make_req(paste0("/", token, "/anchor"), "1,2,3"))$status, 204L)
  expect_equal(handler(make_req(paste0("/", token, "/anchor"), "4,5,6"))$status, 204L)

  ov <- parse_overlays(handler(make_req(paste0("/", token, "/overlays")))$body)
  expect_equal(ov$L, c(0.1, 0.2, 0.3))            # row-major landmark coords
  expect_equal(ov$A, c(1, 2, 3, 4, 5, 6))         # two anchors, placement order
  expect_equal(ov$S, c(7, 8, 9))                  # surface point cloud
})

test_that("delete then undo round-trips through /overlays (the DGT-02 visual gap)", {
  token <- "TESTTOKEN_overlays_roundtrip"
  reset_session(token)
  on.exit(reset_session(token), add = TRUE)
  handler <- .gmw_digitize_handler(token)

  expect_equal(handler(make_req(paste0("/", token, "/anchor"), "1,2,3"))$status, 204L)
  expect_equal(handler(make_req(paste0("/", token, "/anchor"), "4,5,6"))$status, 204L)

  # Delete the first anchor: /overlays now re-serves only the survivor.
  expect_equal(handler(make_req(paste0("/", token, "/delete"), "anchor,1"))$status, 204L)
  ov_del <- parse_overlays(handler(make_req(paste0("/", token, "/overlays")))$body)
  expect_equal(ov_del$A, c(4, 5, 6))

  # Undo restores the deleted row: /overlays re-serves both again, in order.
  expect_equal(handler(make_req(paste0("/", token, "/undo")))$status, 204L)
  ov_undo <- parse_overlays(handler(make_req(paste0("/", token, "/overlays")))$body)
  expect_equal(ov_undo$A, c(1, 2, 3, 4, 5, 6))
})

test_that("a browser landmark /pick lands in the session land slot and undo drops just it", {
  token <- "TESTTOKEN_pick_land"
  reset_session(token)
  if (exists(token, envir = .gmw_picks)) rm(list = token, envir = .gmw_picks)
  on.exit({
    reset_session(token)
    if (exists(token, envir = .gmw_picks)) rm(list = token, envir = .gmw_picks)
  }, add = TRUE)
  handler <- .gmw_digitize_handler(token)

  # Two picks populate the per-specimen `land` slot in placement order -- this is
  # the store /overlays, delete/undo, and every analytical seam read (the fix for
  # picks vanishing on redraw / "undo does everything").
  expect_equal(handler(make_req(paste0("/", token, "/pick"), "0.1,0.2,0.3"))$status, 204L)
  expect_equal(handler(make_req(paste0("/", token, "/pick"), "0.4,0.5,0.6"))$status, 204L)
  land <- .gmw_session_get(token)$specimens[[1]]$land
  expect_equal(dim(land), c(2L, 3L))
  expect_equal(as.numeric(land[2, ]), c(0.4, 0.5, 0.6))

  # Mirrored into the Phase-4 .gmw_picks store so the replay parity harness is
  # unchanged.
  expect_equal(dim(.gmw_picks_get(token)), c(2L, 3L))

  # /overlays re-serves BOTH landmarks, row-major, in the L layer.
  ov <- parse_overlays(handler(make_req(paste0("/", token, "/overlays")))$body)
  expect_equal(ov$L, c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6))

  # One-deep undo drops ONLY the last pick, not the whole layer.
  expect_equal(handler(make_req(paste0("/", token, "/undo")))$status, 204L)
  ov2 <- parse_overlays(handler(make_req(paste0("/", token, "/overlays")))$body)
  expect_equal(ov2$L, c(0.1, 0.2, 0.3))
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
