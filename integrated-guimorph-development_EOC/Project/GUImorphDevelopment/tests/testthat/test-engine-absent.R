pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# UI-02 engine-retirement gate (Plan 06-07). Two proofs:
#   (1) a comment-stripped source-scan of the WHOLE R/ tree showing no native
#       engine-verb call (add/set/del/shows) and no engine-env definition
#       (.gmw_engine / .gmw_require_engine) survives anywhere, and
#   (2) an integration drive booting the browser shell in a temp dir and running
#       the digitize -> gpa -> save workflow with the native engine genuinely
#       absent from the session (rtkogl.R deleted; inst/libs binaries gone).
# Mirrors the readLines + comment-strip + grepl idiom of
# test-surface-geomorph-stripped.R and the boot/route-drive idiom of
# test-shell-entry.R. Forbidden tokens are pattern-built so the negative gates
# cannot self-trip on this file's own prose.
skip_if_no_pkg_source()

# Strip full-line and inline comments before scanning so kept prose is never
# mistaken for live engine code.
code_of <- function(path) sub("#.*$", "", readLines(path, warn = FALSE))

# The native engine verbs the (deleted) rtkogl.R bridged into tkogl2: a bare
# add(/set(/del(/shows( call not preceded by an identifier char (so setNames,
# offset, reset, etc. never match).
engine_verbs <- "(^|[^._[:alnum:]])(add|set|del|shows)\\("

r_files <- list.files(file.path(pkg_root, "R"), pattern = "[.][Rr]$",
                      full.names = TRUE)

test_that("no native engine verb (add/set/del/shows) call survives anywhere in R/", {
  # A real gate: reintroducing any add(/set(/del(/shows( engine call into any R/
  # file fails this scan. rtkogl.R being gone is what makes the whole tree clean.
  offenders <- character(0)
  for (rf in r_files) {
    if (any(grepl(engine_verbs, code_of(rf)))) offenders <- c(offenders, basename(rf))
  }
  expect_identical(offenders, character(0))
})

test_that("no engine env / gate definition survives anywhere in R/ (UI-02)", {
  engine_env <- paste0(".", "gmw_engine")          # the retired status env
  engine_req <- paste0(".", "gmw_require_engine")   # the retired digitizing gate
  onload_tok <- paste0(".", "onLoad")               # the retired engine tcl-load hook

  for (rf in r_files) {
    code <- code_of(rf)
    expect_false(any(grepl(engine_env, code, fixed = TRUE)),
                 info = paste("engine env survives in", basename(rf)))
    expect_false(any(grepl(engine_req, code, fixed = TRUE)),
                 info = paste("engine gate survives in", basename(rf)))
    expect_false(any(grepl(onload_tok, code, fixed = TRUE)),
                 info = paste("engine load hook survives in", basename(rf)))
  }

  # And the engine binding file itself is gone.
  expect_false(file.exists(file.path(pkg_root, "R", "rtkogl.R")))
})

# --------------------------------------------------------------------------
# Integration: boot the shell + drive the full workflow, engine absent (UI-02).
# --------------------------------------------------------------------------

# Source ONLY the browser-shell surface into THIS file's environment (never the
# global env, so the server-owned .gmw_server/.gmw_session registries stay
# isolated from sibling suites). rtkogl.R does not exist to be sourced -- every
# route below therefore runs with the engine genuinely absent.
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

# A synthetic httpuv req: a trailing PATH_INFO plus a single-shot rook.input
# whose read() yields the raw body bytes (empty for GET routes). The httpuv `call`
# handler cannot be serviced by an in-process HTTP client while the same R thread
# blocks on the fetch, so the workflow is driven through the production handler
# directly -- the response is identical to what the live listener would return.
gmw_shell_req <- function(path, body = NULL) {
  list(
    PATH_INFO  = path,
    rook.input = list(read = function() {
      if (is.null(body)) raw(0) else charToRaw(body)
    })
  )
}

teardown_all <- function() try(gmw_close(), silent = TRUE)

test_that("GUImorphWeb() boots the shell with the native engine absent (UI-02)", {
  on.exit(teardown_all(), add = TRUE)

  browse <- tempfile("gmw-browse-"); dir.create(browse)
  url <- GUImorphWeb(dir = browse, open = FALSE)

  # A live loopback listener bound with no native engine in the session.
  expect_match(url, "^http://127[.]0[.]0[.]1:[0-9]+/.+/$")
  token <- sub("^http://127[.]0[.]0[.]1:[0-9]+/(.+)/$", "\\1", url)
  expect_true(token %in% ls(.gmw_server))

  # The engine surface is genuinely undefined in this session.
  expect_false(exists(paste0(".", "gmw_engine"),         inherits = TRUE))
  expect_false(exists(paste0(".", "gmw_require_engine"),  inherits = TRUE))
})

test_that("digitize -> gpa -> save workflow runs with inst/libs absent (UI-02)", {
  on.exit(teardown_all(), add = TRUE)

  # Seed an isolated session whose browse dir is a fresh temp dir, then drive the
  # production route handler the live listener installs.
  browse <- tempfile("gmw-browse-"); dir.create(browse)
  token <- .gmw_token()
  s <- .gmw_session_ensure(token)
  s$browse_dir <- browse
  assign(token, s, envir = .gmw_session)
  on.exit(if (exists(token, envir = .gmw_session)) rm(list = token, envir = .gmw_session),
          add = TRUE)
  handler <- .gmw_digitize_handler(token)

  ok <- function(suffix, body = NULL)
    handler(gmw_shell_req(paste0("/", token, "/", suffix), body))$status

  # PLY-load (specimen select) -> landmark -> anchor -> curve -> overlays ->
  # downsample -> GPA -> export -> save -> status/tabstate/files. None of these
  # may reach a native engine verb: those symbols are not defined in this
  # session, so a route that did would error rather than answer cleanly.
  expect_true(ok("specimen", "1")           %in% c(200L, 204L))
  expect_true(ok("pick",     "0.1,0.2,0.3") %in% c(200L, 204L))
  expect_true(ok("anchor",   "0.4,0.5,0.6") %in% c(200L, 204L))
  expect_true(ok("curve",    "0,1,2")       %in% c(200L, 204L))
  expect_true(ok("overlays")                %in% c(200L, 204L))
  expect_true(ok("downsample")              %in% c(200L, 204L))
  expect_true(ok("gpa")                     %in% c(200L, 204L))
  expect_true(ok("export",   "csv")         %in% c(200L, 204L))
  expect_true(ok("save")                    %in% c(200L, 204L))
  expect_true(ok("status")                  %in% c(200L, 204L))
  expect_true(ok("tabstate")                %in% c(200L, 204L))
  expect_true(ok("files")                   %in% c(200L, 204L))

  # The engine surface was never defined during the entire workflow.
  expect_false(exists(paste0(".", "gmw_engine"),        inherits = TRUE))
  expect_false(exists(paste0(".", "gmw_require_engine"), inherits = TRUE))

  # Proof the routes did real work (not just answered blindly): the session holds
  # the digitizing edits.
  s <- .gmw_session_ensure(token)
  expect_equal(s$current, 1L)
  expect_equal(nrow(s$specimens[[1L]]$land),   1L)
  expect_equal(nrow(s$specimens[[1L]]$anchor), 1L)
  expect_equal(nrow(s$curves), 1L)
})
