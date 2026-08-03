pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests source the package R/ and start real (loopback) httpuv servers,
# so they need the source tree. Skip cleanly under R CMD check's installed
# lazy-load database. See helper-pkg-source.R.
skip_if_no_pkg_source()
source(file.path(pkg_root, "R", "view3d.R"), local = FALSE)
source(file.path(pkg_root, "R", "transport.R"), local = FALSE)

# .gmw_bundle_path() resolves the vendored JS via system.file(package = ...),
# which errors when this file is sourced standalone rather than loaded from the
# installed package. Point it at the source-tree bundle so .gmw_serve_mesh() can
# be exercised without an install -- the bundle's content is irrelevant to the
# transport tests; it only has to exist to be copied into the served dir. The
# override is assigned into .gmw_serve_mesh()'s own environment (the globalenv
# that source(local = FALSE) used) so the running function resolves it, not the
# testthat test environment.
assign(
  ".gmw_bundle_path",
  function() file.path(pkg_root, "inst", "htmlwidgets", "guimorphweb-three.js"),
  envir = environment(.gmw_serve_mesh)
)

# ~0.77 MB committed fixture. The ~30 MB B7_1_clean.ply is reserved for the
# manual worst-case UAT (02-VALIDATION.md), not this fast automated suite.
fixture <- file.path(pkg_root, "tests", "fixtures", "parity", "B12_1_clean.ply")

# Start a server on the fixture and hand back the retained handle + token so the
# caller can assert on it and tear it down.
serve_tmp <- function(open = FALSE) {
  url   <- .gmw_serve_mesh(fixture, open = open)
  token <- gmw_url_token(url)
  list(url = url, token = token, srv = get(token, envir = .gmw_server))
}

# Stop the server and drop its retained handle so tests stay isolated and no
# listener leaks across the suite.
teardown_server <- function(s) {
  try(httpuv::stopServer(s$srv), silent = TRUE)
  if (exists(s$token, envir = .gmw_server)) rm(list = s$token, envir = .gmw_server)
}

test_that("server binds 127.0.0.1 on an unprivileged port; source is loopback-only", {
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")
  s <- serve_tmp()
  on.exit(teardown_server(s), add = TRUE)

  port <- s$srv$getPort()
  expect_true(is.numeric(port))
  expect_gte(port, 1024L)
  expect_lte(port, 49151L)
  expect_match(s$url, "^http://127\\.0\\.0\\.1:[0-9]+/")

  # Source-scan the transport for the loopback/no-LAN and no-path-join guards.
  src <- readLines(file.path(pkg_root, "R", "transport.R"), warn = FALSE)
  expect_true(any(grepl("127.0.0.1", src, fixed = TRUE)))
  expect_false(any(grepl("0.0.0.0", src, fixed = TRUE)))
  expect_true(any(grepl("staticPath", src, fixed = TRUE)))

  # Re-scoped from the stale Phase-2 "the token request-path variable never
  # appears" proxy (RESEARCH Pitfall 3): plan 02 legitimately reads the request
  # path in the /close handler, so its mere presence is no longer a violation.
  # The real invariant (V5/T-2-02) is that no request-derived path is ever
  # joined to the filesystem -- so no source line that references the request
  # path may also call file.path()/normalizePath()/readBin().
  reqpath_lines <- grep("PATH_INFO", src, fixed = TRUE, value = TRUE)
  joins_fs <- vapply(reqpath_lines, function(ln) {
    any(vapply(c("file.path", "normalizePath", "readBin"),
               function(fn) grepl(fn, ln, fixed = TRUE), logical(1)))
  }, logical(1))
  expect_false(any(joins_fs))
})

test_that("gmw_close(token) stops one, gmw_close() stops all", {
  skip_if_no_pkg_source()
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")

  s1 <- serve_tmp()
  s2 <- serve_tmp()
  # Guarantee no listener leaks even if an assertion below fails.
  on.exit(gmw_close(), add = TRUE)

  # Stop exactly one token -> the other viewport stays live (D-03/D-04).
  gmw_close(s1$token)
  live <- ls(.gmw_server)
  expect_false(s1$token %in% live)
  expect_true(s2$token %in% live)

  # Stop-all -> the registry AND httpuv's own list agree: no orphan (Pitfall 1).
  gmw_close()
  expect_equal(length(ls(.gmw_server)), 0L)
  expect_equal(length(httpuv::listServers()), 0L)
})

test_that(".onUnload stops all live servers", {
  skip_if_no_pkg_source()
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")

  s <- serve_tmp()
  on.exit(gmw_close(), add = TRUE)

  .onUnload("")
  expect_equal(length(ls(.gmw_server)), 0L)
})

test_that("the session-end finalizer registers exactly once", {
  skip_if_no_pkg_source()
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")

  s1 <- serve_tmp()
  on.exit(teardown_server(s1), add = TRUE)
  s2 <- serve_tmp()
  on.exit(teardown_server(s2), add = TRUE)

  # The lazy finalizer flag lives in .gmw_lifecycle, never in .gmw_server, so
  # the registry stays purely token -> handle across repeated serves.
  expect_true(isTRUE(.gmw_lifecycle$finalizer_registered))
  expect_false("finalizer_registered" %in% ls(.gmw_server))
})

test_that("lifecycle work never touches the tkogl2 engine state", {
  skip_if_no_pkg_source()

  # transport.R must never write the CMP-01 oracle engine env.
  tsrc <- readLines(file.path(pkg_root, "R", "transport.R"), warn = FALSE)
  expect_false(any(grepl(".gmw_engine$", tsrc, fixed = TRUE)))
  expect_false(any(grepl(".gmw_engine <-", tsrc, fixed = TRUE)))

  # rtkogl.R still carries the native oracle load path (proving it was untouched).
  rsrc <- readLines(file.path(pkg_root, "R", "rtkogl.R"), warn = FALSE)
  expect_true(any(grepl(".onLoad", rsrc, fixed = TRUE)))
  expect_true(any(grepl("Tkogl2", rsrc, fixed = TRUE)))
})

test_that("served PLY bytes are byte-identical to disk (raw, never JSON)", {
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")
  skip_if_no_curl()
  s <- serve_tmp()
  on.exit(teardown_server(s), add = TRUE)

  resp <- gmw_try_fetch(paste0(s$url, "specimen.ply"), timeout = 60)
  expect_false(is.null(resp))
  expect_equal(resp$status_code, 200L)

  disk <- readBin(fixture, "raw", n = file.info(fixture)$size)
  expect_identical(resp$content, disk)
})

test_that("a request without the per-session token path is refused, not served", {
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")
  skip_if_no_curl()
  s <- serve_tmp()
  on.exit(teardown_server(s), add = TRUE)

  origin <- gmw_url_origin(s$url)
  disk   <- readBin(fixture, "raw", n = file.info(fixture)$size)

  # A staticPaths-only server never answers a path outside its mount, so these
  # bounded fetches either time out (NULL) or return a non-200 -- in no case may
  # they return the specimen bytes. That "bytes never returned" is the guard.
  served_bytes <- function(resp) !is.null(resp) && identical(resp$content, disk)

  # No token in the path.
  bare <- gmw_try_fetch(paste0(origin, "/specimen.ply"), timeout = 5)
  expect_false(served_bytes(bare))

  # A wrong token.
  wrong <- gmw_try_fetch(paste0(origin, "/", .gmw_token(), "/specimen.ply"), timeout = 5)
  expect_false(served_bytes(wrong))
})

test_that("port selection walks forward from the preferred port (no socket bound)", {
  # Preferred port busy -> next free port, without binding anything.
  expect_identical(.gmw_pick_port(prefer = 8080L, probe = gmw_probe_stub(busy = 8080L)), 8081L)
  expect_identical(.gmw_pick_port(prefer = 8080L, probe = function(p) p != 8080L), 8081L)
  # Two consecutive busy ports -> walk past both.
  expect_identical(.gmw_pick_port(prefer = 9000L, probe = gmw_probe_stub(busy = c(9000L, 9001L))), 9002L)

  # Primary path (prefer = NULL) delegates to httpuv::randomPort(): a free,
  # unprivileged, loopback port. randomPort does not retain the socket.
  p <- .gmw_pick_port()
  expect_true(is.numeric(p))
  expect_gte(p, 1024L)
  expect_lte(p, 49151L)
})

test_that(".gmw_serve_mesh opens the loopback token URL without a real browser", {
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")

  opened <- NULL
  old <- options(browser = function(url, ...) { opened <<- url; invisible(TRUE) })
  on.exit(options(old), add = TRUE)

  s <- serve_tmp(open = TRUE)
  on.exit(teardown_server(s), add = TRUE)

  expect_false(is.null(opened))
  expect_match(opened, "^http://127\\.0\\.0\\.1:[0-9]+/")
  expect_true(grepl(s$token, opened, fixed = TRUE))   # contains the token segment
  expect_identical(opened, s$url)
})

test_that(".gmw_server retains the live server handle against gc()", {
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")
  before <- length(ls(.gmw_server))

  s <- serve_tmp()
  on.exit(teardown_server(s), add = TRUE)

  expect_gt(length(ls(.gmw_server)), before)
  expect_true(s$token %in% ls(.gmw_server))
  expect_false(is.null(s$srv))
  expect_true(is.function(s$srv$getPort))
})
