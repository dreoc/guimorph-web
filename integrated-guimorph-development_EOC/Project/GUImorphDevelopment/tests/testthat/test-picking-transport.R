# Phase 4: Picking Parity -- POST /<token>/pick transport + CMP-01 oracle gate
#
# Unit-level coverage of the token-guarded pick route added to the mixed httpuv
# app. Mirrors the test-transport.R direct-handler-invocation idiom (no live
# server, no same-process curl -- the /pick and /close branches run on the R main
# thread, which a same-process curl can never reach; RESEARCH Pitfall 5). We
# build a synthetic `req` and call the production `.gmw_pick_handler(token)`
# closure directly. Source-scans reuse the exact T-2-02 and CMP-01 predicates
# from test-transport.R so the new route is held to the same bar.

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

test_that("a well-formed pick returns 204 and appends rows (server owns the array)", {
  token <- "TESTTOKEN_pick_ok"
  if (exists(token, envir = .gmw_picks)) rm(list = token, envir = .gmw_picks)
  on.exit(if (exists(token, envir = .gmw_picks)) rm(list = token, envir = .gmw_picks),
          add = TRUE)
  handler <- .gmw_pick_handler(token)

  # First pick -> 204 and a 1x3 numeric row lands in the server-owned store.
  resp <- handler(make_req(paste0("/", token, "/pick"), "1,2,3"))
  expect_equal(resp$status, 204L)
  m <- .gmw_picks_get(token)
  expect_true(is.matrix(m))
  expect_equal(dim(m), c(1L, 3L))
  expect_equal(as.numeric(m[1, ]), c(1, 2, 3))

  # Second well-formed pick appends a second row (2x3), placement order kept.
  resp2 <- handler(make_req(paste0("/", token, "/pick"), "4,5,6"))
  expect_equal(resp2$status, 204L)
  m2 <- .gmw_picks_get(token)
  expect_equal(dim(m2), c(2L, 3L))
  expect_equal(as.numeric(m2[2, ]), c(4, 5, 6))

  # The exported user accessor returns the same server-owned array.
  expect_identical(gmw_picks(token), m2)
})

test_that("malformed pick bodies are dropped: 204 but the stored array is unchanged", {
  token <- "TESTTOKEN_pick_bad"
  if (exists(token, envir = .gmw_picks)) rm(list = token, envir = .gmw_picks)
  on.exit(if (exists(token, envir = .gmw_picks)) rm(list = token, envir = .gmw_picks),
          add = TRUE)
  handler <- .gmw_pick_handler(token)

  # Seed one good row so we can prove the malformed bodies leave it untouched.
  expect_equal(handler(make_req(paste0("/", token, "/pick"), "7,8,9"))$status, 204L)
  before <- .gmw_picks_get(token)

  bad_bodies <- c(
    "1,2",       # too few numbers
    "1,2,3,4",   # too many numbers
    "a,b,c",     # non-numeric token
    "1,,3"       # missing middle -> NA, not finite
  )
  for (b in bad_bodies) {
    resp <- handler(make_req(paste0("/", token, "/pick"), b))
    expect_equal(resp$status, 204L)                 # dropped, never errored
    expect_identical(.gmw_picks_get(token), before) # array unchanged
  }

  # An absent body (read() returns 0 bytes) is likewise dropped, not errored.
  resp_empty <- handler(make_req(paste0("/", token, "/pick"), NULL))
  expect_equal(resp_empty$status, 204L)
  expect_identical(.gmw_picks_get(token), before)
})

test_that("the pick handler writes only its own token (no cross-token write, T-4-04)", {
  tok_a <- "TESTTOKEN_iso_a"
  tok_b <- "TESTTOKEN_iso_b"
  for (t in c(tok_a, tok_b)) if (exists(t, envir = .gmw_picks)) rm(list = t, envir = .gmw_picks)
  on.exit({
    for (t in c(tok_a, tok_b)) if (exists(t, envir = .gmw_picks)) rm(list = t, envir = .gmw_picks)
  }, add = TRUE)

  handler_a <- .gmw_pick_handler(tok_a)
  expect_equal(handler_a(make_req(paste0("/", tok_a, "/pick"), "1,2,3"))$status, 204L)

  # tok_a's handler stored under tok_a only; tok_b's store is still empty.
  expect_equal(dim(.gmw_picks_get(tok_a)), c(1L, 3L))
  expect_null(.gmw_picks_get(tok_b))
})

test_that("the subsumed /close branch still returns 204; any other suffix is 404", {
  token <- "TESTTOKEN_close"
  handler <- .gmw_pick_handler(token)

  # /close is answered by the same closure (it subsumes .gmw_close_handler). It
  # schedules a deferred stop for a token with no registered server -- a harmless
  # no-op; drain the later queue so nothing leaks into sibling tests.
  resp_close <- handler(make_req(paste0("/", token, "/close")))
  expect_equal(resp_close$status, 204L)
  Sys.sleep(0.6)
  later::run_now()

  # Any other path is a plain 404 (never a filesystem read of the request path).
  resp_other <- handler(make_req(paste0("/", token, "/other")))
  expect_equal(resp_other$status, 404L)
})

test_that("the pick route never joins the request path to the filesystem (T-2-02/T-4-01)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_root, "R", "transport.R"), warn = FALSE)

  # Same invariant predicate as test-transport.R:66-71: no source line that
  # references the request path (PATH_INFO) may also call a filesystem
  # join/normalize/raw-read primitive.
  reqpath_lines <- grep("PATH_INFO", src, fixed = TRUE, value = TRUE)
  joins_fs <- vapply(reqpath_lines, function(ln) {
    any(vapply(c("file.path", "normalizePath", "readBin"),
               function(fn) grepl(fn, ln, fixed = TRUE), logical(1)))
  }, logical(1))
  expect_false(any(joins_fs))

  # The body is parsed with base-R string ops only -- no JSON dependency.
  expect_false(any(grepl("jsonlite", src, fixed = TRUE)))
  expect_false(any(grepl("fromJSON", src, fixed = TRUE)))
  expect_false(any(grepl("toJSON", src, fixed = TRUE)))
})

test_that("CMP-01: transport.R never writes .gmw_engine; oracle load path untouched", {
  skip_if_no_pkg_source()

  # (i) Source-scan (mirror test-transport.R:121-133): the pick code must not
  # regress the CMP-01 invariant -- transport.R never assigns the oracle engine.
  tsrc <- readLines(file.path(pkg_root, "R", "transport.R"), warn = FALSE)
  expect_false(any(grepl(".gmw_engine$", tsrc, fixed = TRUE)))
  expect_false(any(grepl(".gmw_engine <-", tsrc, fixed = TRUE)))

  # (ii) Positive check: when the package namespace is already loaded, the native
  # engine status env exposes a logical scalar .gmw_engine$ok (rtkogl.R:498-511).
  # Skip cleanly otherwise (headless / tarball / engine absent), mirroring the
  # test-retina-picking-parity.R skip-if-absent idiom. isNamespaceLoaded is used
  # instead of asNamespace() so this never triggers a tcltk2 GUI-init load.
  if (!isNamespaceLoaded("GUImorphWeb")) skip("GUImorphWeb namespace not loaded")
  eng <- tryCatch(get(".gmw_engine", envir = asNamespace("GUImorphWeb")),
                  error = function(e) NULL)
  if (is.null(eng) || !exists("ok", envir = eng, inherits = FALSE)) {
    skip("native tkogl2 engine not available")
  }
  expect_true(is.logical(eng$ok))
  expect_length(eng$ok, 1L)
})
