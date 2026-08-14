pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests source the package R/ directly and start real (loopback) httpuv
# servers, so they need the source tree. Skip cleanly under R CMD check's
# installed lazy-load database. See helper-pkg-source.R.
skip_if_no_pkg_source()

# Source ONLY the browser-shell surface: view3d.R (page template), transport.R
# (httpuv server + routes), shell.R (the rewired GUImorphWeb entry + survivors).
# rtkogl.R (the native tkogl2 engine: add/del/set/shows/.gmw_engine/.onLoad) is
# deliberately NOT sourced. Every assertion below therefore runs with the engine
# genuinely absent from the session -- if any boot or route needed an engine verb
# it would error, so a green run is a real UI-02 engine-absent gate.
#
# local = TRUE sources into THIS file's environment (not the global env) so the
# server-owned registries (.gmw_server/.gmw_session) stay isolated to this file
# and never clobber the global-env state sibling suites (e.g. test-transport.R)
# source with local = FALSE.
local_env <- environment()
source(file.path(pkg_root, "R", "view3d.R"),    local = local_env)
source(file.path(pkg_root, "R", "shell.R"),     local = local_env)
source(file.path(pkg_root, "R", "transport.R"), local = local_env)

# .gmw_bundle_path() resolves the vendored JS via system.file(package = ...),
# which returns "" when sourced standalone. Point it at the source-tree bundle so
# .gmw_serve_mesh() can be exercised without an install (its content is
# irrelevant here; it only has to exist to be copied into the served dir).
assign(
  ".gmw_bundle_path",
  function() file.path(pkg_root, "inst", "htmlwidgets", "guimorphweb-three.js"),
  envir = environment(.gmw_serve_mesh)
)

# Extract one top-level function definition's source lines (its `name <- function`
# line up to the line before the next top-level definition). Mirrors the
# source-scan style used across the suite so the audit runs on any OS.
.shell_fn_body <- function(src, name) {
  def_idx <- grep("^[A-Za-z.][A-Za-z0-9._]* <- function", src)
  start   <- grep(paste0("^", gsub(".", "\\.", name, fixed = TRUE), " <- function"), src)
  stopifnot(length(start) == 1L)
  later <- def_idx[def_idx > start]
  end   <- if (length(later)) min(later) - 1L else length(src)
  src[start:end]
}

# A synthetic httpuv req: a trailing PATH_INFO plus a single-shot rook.input
# whose read() yields the raw body bytes (empty for GET routes). Mirrors the
# gmw_shell_req harness in test-transport.R. The httpuv `call` handler cannot be
# serviced by an out-of-process HTTP client while the same R thread blocks on the
# fetch, so the suite drives dynamic routes through the production handler
# directly -- the response is identical to what the listener would return.
gmw_shell_req <- function(path, body = NULL) {
  list(
    PATH_INFO  = path,
    rook.input = list(read = function() {
      if (is.null(body)) raw(0) else charToRaw(body)
    })
  )
}

teardown_all <- function() try(gmw_close(), silent = TRUE)

test_that("GUImorphWeb() boots a loopback browser shell with no native engine", {
  on.exit(teardown_all(), add = TRUE)

  browse <- tempfile("gmw-browse-"); dir.create(browse)
  url <- GUImorphWeb(dir = browse, open = FALSE)

  # Invisible loopback URL of the served viewport.
  expect_match(url, "^http://127[.]0[.]0[.]1:[0-9]+/.+/$")

  token <- sub("^http://127[.]0[.]0[.]1:[0-9]+/(.+)/$", "\\1", url)
  expect_true(token %in% ls(.gmw_server))

  srv  <- get(token, envir = .gmw_server)
  port <- srv$getPort()
  expect_gte(port, 1024L)
  expect_lte(port, 49151L)

  # The engine surface is genuinely absent from this session (rtkogl.R unsourced),
  # yet the shell booted -- the entry needs no native engine (UI-02).
  expect_false(exists(".gmw_engine",         inherits = TRUE))
  expect_false(exists(".gmw_require_engine",  inherits = TRUE))

  # The server-owned browse dir was seeded from the `dir` argument (D-03 picker).
  expect_equal(.gmw_session_browse_dir(token), browse)
})

test_that("R/shell.R holds the relocated survivors and the entry is engine/Tk-free", {
  skip_if_no_pkg_source()

  ssrc <- readLines(file.path(pkg_root, "R", "shell.R"), warn = FALSE)
  # Single definition of each survivor lives in shell.R now.
  expect_true(any(grepl("^GUImorphWeb <- function", ssrc)))
  expect_true(any(grepl("^dbg <- function",         ssrc)))
  expect_true(any(grepl("^.plot_show <- function",  ssrc)))
  expect_true(any(grepl("^.onAttach <- function",   ssrc)))

  # The rewired entry boots the browser shell and no longer takes the Tk path.
  entry <- .shell_fn_body(ssrc, "GUImorphWeb")
  expect_false(any(grepl(".gmw_require_engine", entry, fixed = TRUE)))
  expect_false(any(grepl("ui(e)",  entry, fixed = TRUE)))
  expect_false(any(grepl("init(e)", entry, fixed = TRUE)))
  expect_true(any(grepl(".gmw_serve_mesh", entry, fixed = TRUE)))

  # ...and rtkogl.R is gone entirely (Plan 06-07), so it cannot redefine any of
  # the survivors: the single definition of each now lives only in shell.R.
  expect_false(file.exists(file.path(pkg_root, "R", "rtkogl.R")))
})

test_that("digitize->gpa->save workflow is reachable through the shell handler, engine absent", {
  on.exit(teardown_all(), add = TRUE)

  # A live listener is bound by the boot (test above); here we drive the same
  # production route handler the listener installs, since httpuv's R `call`
  # handler cannot be serviced by an in-process fetch (see gmw_shell_req note).
  browse <- tempfile("gmw-browse-"); dir.create(browse)
  token <- .gmw_token()
  s <- .gmw_session_ensure(token)
  s$browse_dir <- browse
  assign(token, s, envir = .gmw_session)
  on.exit(if (exists(token, envir = .gmw_session)) rm(list = token, envir = .gmw_session),
          add = TRUE)
  handler <- .gmw_digitize_handler(token)

  # Drive the full digitize -> gpa -> save workflow, in order. Each returns 200
  # (GET reads) or 204 (writes); none touches a native engine verb
  # (add/set/del/shows) -- those are not even defined in this session. A route
  # that reached for the engine would error here rather than answer cleanly.
  ok <- function(suffix, body = NULL)
    handler(gmw_shell_req(paste0("/", token, "/", suffix), body))$status

  expect_true(ok("specimen", "1")            %in% c(200L, 204L))  # select specimen 1
  expect_true(ok("pick",     "0.1,0.2,0.3")  %in% c(200L, 204L))  # place a landmark
  expect_true(ok("anchor",   "0.4,0.5,0.6")  %in% c(200L, 204L))  # place an anchor
  expect_true(ok("curve",    "0,1,2")        %in% c(200L, 204L))  # add a curve row
  expect_true(ok("overlays")                 %in% c(200L, 204L))  # GET overlay re-serve
  expect_true(ok("downsample")               %in% c(200L, 204L))  # surface downsample seam
  expect_true(ok("gpa")                      %in% c(200L, 204L))  # GPA seam
  expect_true(ok("export",   "csv")          %in% c(200L, 204L))  # export seam
  expect_true(ok("save")                     %in% c(200L, 204L))  # save .dgt seam
  expect_true(ok("status")                   %in% c(200L, 204L))  # HUD status read
  expect_true(ok("tabstate")                 %in% c(200L, 204L))  # tab-gating read
  expect_true(ok("files")                    %in% c(200L, 204L))  # picker listing

  # The workflow completed with the engine surface never defined in this session.
  expect_false(exists(".gmw_engine",        inherits = TRUE))
  expect_false(exists(".gmw_require_engine", inherits = TRUE))

  # The session recorded the digitizing edits (proof the routes did real work,
  # not just answer 204 blindly).
  s <- .gmw_session_ensure(token)
  expect_equal(s$current, 1L)
  expect_equal(nrow(s$specimens[[1L]]$land),   1L)
  expect_equal(nrow(s$specimens[[1L]]$anchor), 1L)
  expect_equal(nrow(s$curves), 1L)
})
