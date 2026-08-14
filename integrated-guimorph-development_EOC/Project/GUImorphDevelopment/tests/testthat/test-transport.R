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

test_that("the native engine is retired and the shell never revives it", {
  skip_if_no_pkg_source()

  # Kept from the pre-retirement gate: transport.R must never write the engine
  # status env. (Once the CMP-01 oracle invariant; now a permanent one.)
  tsrc <- readLines(file.path(pkg_root, "R", "transport.R"), warn = FALSE)
  engine_env <- paste0(".", "gmw_engine")   # pattern-built so this file's prose can't self-trip
  expect_false(any(grepl(paste0(engine_env, "$"),  tsrc, fixed = TRUE)))
  expect_false(any(grepl(paste0(engine_env, " <-"), tsrc, fixed = TRUE)))

  # INVERTED (Plan 06-07): the engine binding file, its shipped binaries, and its
  # load path are GONE. This block used to assert rtkogl.R still carried the
  # native oracle .onLoad; it now asserts the retirement is complete, in the same
  # change as the deletion, so the suite is never left red (Pitfall 6 / T-6-22).
  expect_false(file.exists(file.path(pkg_root, "R", "rtkogl.R")))

  # No shipped native binary lingers under inst/libs/ (tkogl2* / glut64*).
  libs <- list.files(file.path(pkg_root, "inst", "libs"),
                     recursive = TRUE, full.names = FALSE)
  expect_false(any(grepl(paste0("tk", "ogl2"), libs, fixed = TRUE)))
  expect_false(any(grepl("glut64",            libs, fixed = TRUE)))

  # No engine load hook / status env / digitizing gate survives anywhere in R/
  # (comment-stripped so kept prose is not mistaken for live code).
  onload_tok <- paste0(".", "onLoad")
  engine_req <- paste0(".", "gmw_require_engine")
  r_files <- list.files(file.path(pkg_root, "R"), pattern = "[.][Rr]$",
                        full.names = TRUE)
  for (rf in r_files) {
    code <- sub("#.*$", "", readLines(rf, warn = FALSE))
    expect_false(any(grepl(onload_tok, code, fixed = TRUE)),
                 info = paste("engine load hook survives in", basename(rf)))
    expect_false(any(grepl(engine_env, code, fixed = TRUE)),
                 info = paste("engine status env survives in", basename(rf)))
    expect_false(any(grepl(engine_req, code, fixed = TRUE)),
                 info = paste("engine gate survives in", basename(rf)))
  }
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

test_that("/close handler returns 204 and schedules a stop of its own token", {
  skip_if_no_pkg_source()
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")

  # Register a real server so the scheduled stop has a token to remove. The
  # /close route runs on the R main thread via later, so it CANNOT be reached by
  # a same-process curl (RESEARCH Pitfall 5: R is blocked, the callback never
  # runs). Invoke the production `call` closure directly with a synthetic req.
  s <- serve_tmp()
  on.exit(teardown_server(s), add = TRUE)

  handler <- .gmw_close_handler(s$token)

  resp <- handler(list(PATH_INFO = paste0("/", s$token, "/close")))
  expect_equal(resp$status, 204L)
  # 204 returned first; the stop is deferred, not synchronous (Pitfall 2).
  expect_true(s$token %in% ls(.gmw_server))

  # Wait out the ~0.5s defer, then drain the later queue -> the deferred
  # .gmw_stop_token(token) runs and the server is torn down (its own token only).
  # (run_now returns as soon as any ready callback fires, so sleep past the delay
  # first to guarantee ours is due.)
  Sys.sleep(0.6)
  later::run_now()
  expect_false(s$token %in% ls(.gmw_server))

  # Any non-close path is a plain 404 (never a filesystem read of the path).
  miss <- handler(list(PATH_INFO = paste0("/", s$token, "/other")))
  expect_equal(miss$status, 404L)
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

test_that("port exhaustion raises a clear range-naming error, never a hang (D-09)", {
  # Every port reported busy -> walk-forward reaches 49151 and stops with a
  # clear error whose message names BOTH the tried starting port and the 49151
  # ceiling (proving the range is named, and that it errors rather than hangs).
  expect_error(.gmw_pick_port(prefer = 40000L, probe = function(p) FALSE), "40000")
  expect_error(.gmw_pick_port(prefer = 40000L, probe = function(p) FALSE), "49151")
  # Actionable next step: the error points at omitting `port` to auto-pick.
  expect_error(.gmw_pick_port(prefer = 40000L, probe = function(p) FALSE), "omit")
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

test_that("launch prints the URL first and tolerates a failed browser", {
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")

  # A browser override that always errors simulates a blocked/misconfigured
  # default browser. The failure must be swallowed (D-05): serving must not error,
  # and the URL must still be surfaced via a message before the launch attempt.
  old <- options(browser = function(url, ...) stop("no browser"))
  on.exit(options(old), add = TRUE)

  url <- NULL
  expect_message(url <- .gmw_serve_mesh(fixture, open = TRUE), "Viewport: ")

  # The failing browser was swallowed -> a real loopback URL still came back.
  expect_false(is.null(url))
  expect_match(url, "^http://127\\.0\\.0\\.1:[0-9]+/")
  s <- list(token = gmw_url_token(url),
            srv   = get(gmw_url_token(url), envir = .gmw_server))
  on.exit(teardown_server(s), add = TRUE)
})

test_that("the firewall note fires at most once per session (D-06)", {
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")

  # Capture every message emitted while evaluating expr.
  capture_msgs <- function(expr) {
    msgs <- character()
    withCallingHandlers(
      force(expr),
      message = function(m) {
        msgs <<- c(msgs, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    )
    msgs
  }

  # Simulate a fresh session for the flag; restore prior state on exit so sibling
  # tests are unaffected regardless of run order.
  had_flag <- exists("firewall_noted", envir = .gmw_lifecycle)
  old_flag <- if (had_flag) .gmw_lifecycle$firewall_noted else NULL
  if (had_flag) rm("firewall_noted", envir = .gmw_lifecycle)
  on.exit({
    if (had_flag) assign("firewall_noted", old_flag, envir = .gmw_lifecycle)
    else if (exists("firewall_noted", envir = .gmw_lifecycle))
      rm("firewall_noted", envir = .gmw_lifecycle)
  }, add = TRUE)

  s1 <- serve_tmp()
  on.exit(teardown_server(s1), add = TRUE)
  expect_true(isTRUE(.gmw_lifecycle$firewall_noted))   # first serve set the flag

  # A second serve in the same session must NOT emit the firewall note again.
  s2 <- NULL
  msgs2 <- capture_msgs(s2 <- serve_tmp())
  on.exit(teardown_server(s2), add = TRUE)
  expect_false(any(grepl("firewall prompt", msgs2)))
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

# ---------------------------------------------------------------------------
#  Phase-6 browser-shell routes (UI-01): /files, /open, /savepath, /status,
#  /tabstate, /msgack, /color. These exercise the production `call` closure
#  directly with a synthetic req (as the /close test above does) -- a same-
#  process curl cannot reach an R-thread handler while R is blocked in the test.
# ---------------------------------------------------------------------------

# A synthetic httpuv req: a trailing PATH_INFO plus a single-shot rook.input
# whose read() yields the raw body bytes (empty by default, for GET routes).
gmw_shell_req <- function(path, body = NULL) {
  list(
    PATH_INFO  = path,
    rook.input = list(read = function() {
      if (is.null(body)) raw(0) else charToRaw(body)
    })
  )
}

# Seed a fresh, isolated token whose session browse_dir points at `dir`, and
# hand back the token + production handler. rm the token on teardown so the
# .gmw_session registry stays clean across the suite.
gmw_seed_browse <- function(dir) {
  token <- .gmw_token()
  s <- .gmw_session_ensure(token)
  s$browse_dir <- dir
  assign(token, s, envir = .gmw_session)
  list(token = token, handler = .gmw_digitize_handler(token))
}

gmw_drop_token <- function(token) {
  if (exists(token, envir = .gmw_session)) rm(list = token, envir = .gmw_session)
}

test_that("GET /files lists only .dgt/.ply names from browse_dir, newline-joined", {
  skip_if_no_pkg_source()

  bdir <- file.path(tempfile("gmw-browse-"))
  dir.create(bdir)
  on.exit(unlink(bdir, recursive = TRUE), add = TRUE)
  writeLines("ply",  file.path(bdir, "spec.ply"))
  writeLines("dgt",  file.path(bdir, "session.dgt"))
  writeLines("txt",  file.path(bdir, "notes.txt"))   # must be omitted

  b <- gmw_seed_browse(bdir)
  on.exit(gmw_drop_token(b$token), add = TRUE)

  resp <- b$handler(gmw_shell_req(paste0("/", b$token, "/files")))
  expect_equal(resp$status, 200L)
  listed <- strsplit(resp$body, "\n", fixed = TRUE)[[1]]
  expect_setequal(listed, c("spec.ply", "session.dgt"))
  expect_false("notes.txt" %in% listed)
})

test_that("POST /open opens a listed basename but rejects traversal/non-members", {
  skip_if_no_pkg_source()

  bdir <- file.path(tempfile("gmw-browse-"))
  dir.create(bdir)
  on.exit(unlink(bdir, recursive = TRUE), add = TRUE)
  writeLines("ply", file.path(bdir, "spec.ply"))

  b <- gmw_seed_browse(bdir)
  on.exit(gmw_drop_token(b$token), add = TRUE)

  # A listed basename opens: the session records the validated absolute path.
  b$handler(gmw_shell_req(paste0("/", b$token, "/open"), "spec.ply"))
  opened <- .gmw_session_get(b$token)$opened
  expect_identical(opened, file.path(bdir, "spec.ply"))

  # Traversal, absolute path, and an unlisted name each leave the session's
  # opened path UNCHANGED (this is the T-6-02 membership guard, not a tautology:
  # deleting `sel %in% entries` in transport.R makes these three assertions fail).
  b$handler(gmw_shell_req(paste0("/", b$token, "/open"), "../secret"))
  expect_identical(.gmw_session_get(b$token)$opened, opened)
  b$handler(gmw_shell_req(paste0("/", b$token, "/open"), "/etc/passwd"))
  expect_identical(.gmw_session_get(b$token)$opened, opened)
  b$handler(gmw_shell_req(paste0("/", b$token, "/open"), "not-listed.ply"))
  expect_identical(.gmw_session_get(b$token)$opened, opened)
})

test_that("POST /open on a fresh token never opens a traversal selection", {
  skip_if_no_pkg_source()

  bdir <- file.path(tempfile("gmw-browse-"))
  dir.create(bdir)
  on.exit(unlink(bdir, recursive = TRUE), add = TRUE)
  writeLines("ply", file.path(bdir, "spec.ply"))

  b <- gmw_seed_browse(bdir)
  on.exit(gmw_drop_token(b$token), add = TRUE)

  # No prior open -> after only-invalid selections the slot stays NULL.
  b$handler(gmw_shell_req(paste0("/", b$token, "/open"), "../spec.ply"))
  b$handler(gmw_shell_req(paste0("/", b$token, "/open"),
                          file.path(bdir, "spec.ply")))   # absolute, not a member
  expect_null(.gmw_session_get(b$token)$opened)
})

test_that("POST /color stores a #rrggbb hex and drops a non-hex body", {
  skip_if_no_pkg_source()

  b <- gmw_seed_browse(getwd())
  on.exit(gmw_drop_token(b$token), add = TRUE)

  b$handler(gmw_shell_req(paste0("/", b$token, "/color"), "#0a0a0a"))
  expect_identical(.gmw_session_get(b$token)$color, "#0a0a0a")

  # Non-hex bodies are dropped: the stored colour does not change.
  b$handler(gmw_shell_req(paste0("/", b$token, "/color"), "red)"))
  expect_identical(.gmw_session_get(b$token)$color, "#0a0a0a")
  b$handler(gmw_shell_req(paste0("/", b$token, "/color"), "../"))
  expect_identical(.gmw_session_get(b$token)$color, "#0a0a0a")
})

test_that("GET /status returns a parseable bare CSV with a numeric specimen index", {
  skip_if_no_pkg_source()

  b <- gmw_seed_browse(getwd())
  on.exit(gmw_drop_token(b$token), add = TRUE)

  resp <- b$handler(gmw_shell_req(paste0("/", b$token, "/status")))
  expect_equal(resp$status, 200L)
  fields <- strsplit(resp$body, ",", fixed = TRUE)[[1]]
  expect_gte(length(fields), 1L)
  idx <- suppressWarnings(as.integer(fields[1]))
  expect_false(is.na(idx))
  expect_gte(idx, 1L)
})
