# Phase 3: Offline Packaging and Lifecycle - Pattern Map

**Mapped:** 2026-08-03
**Files analyzed:** 6 (2 R source extend, 1 R source precedent-only, 2 tests, 1 NAMESPACE regen)
**Analogs found:** 6 / 6 — every new construct has an in-tree precedent (no invention at the transport layer)

This phase is **extend-in-place lifecycle plumbing**. There are no brand-new source files under `R/`; every capability copies an existing pattern already in `transport.R` / `rtkogl.R` / `view3d.R`. Package root is `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`. All paths below are relative to that root unless shown in full.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `R/transport.R` (EXTEND) | transport / server + lifecycle registry | request-response + event-driven (`/close`) | itself (Phase 2 `.gmw_serve_mesh` + `.gmw_server`) and `R/rtkogl.R` `.onLoad`/`.gmw_engine` | exact (self-extend) |
| `R/view3d.R` (EXTEND: `GMW_VIEW3D_TEMPLATE`) | view template (page JS) | event-driven (browser `pagehide` → beacon) | itself (existing `window.addEventListener` block in the template) | exact (self-extend) |
| `R/rtkogl.R` (READ-ONLY precedent) | package hooks + env-state idiom | n/a | `.onLoad`, `.gmw_engine`, `.onAttach` | precedent source — **DO NOT TOUCH** (CMP-01) |
| `tests/testthat/test-transport.R` (EDIT + ADD) | test | unit (R thread, synthetic `req`) | itself (existing port/guard/open blocks) + `helper-transport.R` | exact (self-extend) |
| `tests/testthat/test-offline-smoke.R` (NEW) | test | integration (offline install + loopback GET) | `test-transport.R` byte-identity block + `helper-transport.R` fetch helpers | role-match |
| `NAMESPACE` (regen) | config | n/a | existing `export(GUImorphWeb)` / `export(loadDgt)` | exact |

## Pattern Assignments

---

### `R/transport.R` (transport + lifecycle registry, request-response + event-driven)

**Analog:** itself (Phase 2 code) plus `R/rtkogl.R` for the package-hook / env-state precedent.

All lifecycle state and hooks live **in `transport.R` beside `.gmw_server`** (RESEARCH §Recommended Project Structure). Do **not** put `.onUnload` in `rtkogl.R` — that file is the CMP-01 gate and must not be touched.

#### (a) Package-env state object — the precedent to mirror for lifecycle flags

Two existing envs establish the idiom. `.gmw_server` is the token→handle registry the four teardown triggers iterate; `.gmw_engine` is the sibling in `rtkogl.R`. RESEARCH Open Question 1 recommends a **separate** `.gmw_lifecycle` env for the finalizer-registered flag so `ls(.gmw_server)` stays purely token→handle.

```40:43:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
# Package-level retained state: holds each live httpuv server handle, keyed by
# its token, so gc() does not run the finalizer and stop the listener for the
# session. Mirrors the .gmw_engine idiom in rtkogl.R.
.gmw_server <- new.env(parent = emptyenv())
```

```498:500:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
.gmw_engine <- new.env(parent = emptyenv())
.gmw_engine$ok  <- FALSE
.gmw_engine$msg <- "the engine was never initialised"
```

**Copy for:** a new `.gmw_lifecycle <- new.env(parent = emptyenv())` to hold `.finalizer_registered` (keeps the registry clean, per Open Question 1).

#### (b) httpuv app construction — static-only → mixed (the D-02 core change)

The existing app is `staticPaths`-only. Phase 3 adds one `excludeStaticPath()` subpath **plus** a `call` handler beside it. Keep the `staticPath(dir)` mount byte-for-byte (T-2-02).

```136:146:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
  server <- httpuv::startServer(
    host = "127.0.0.1", port = port,
    app = list(
      staticPaths = stats::setNames(
        list(httpuv::staticPath(dir)),
        paste0("/", token)
      )
    )
  )
  # Retain the handle for the session so gc() does not stop the listener.
  assign(token, server, envir = .gmw_server)
```

**Change to (per RESEARCH Pattern 2):** add `httpuv::excludeStaticPath()` at `/<token>/close` and a `call = function(req){...}` closure that captures `token`, pattern-matches `/close$` on `req$PATH_INFO`, schedules `later::later(function() .gmw_stop_token(token), 0.5)`, and returns `list(status = 204L, headers = list(), body = "")`. The handler must **never** join `req$PATH_INFO` to a filesystem path (V5/T-2-02) — pattern-match only.

#### (c) Port selection + occupied-port error — surface the existing backup (D-08/D-09)

`.gmw_pick_port(prefer, probe)` already implements randomPort-primary + walk-forward-backup with an exhaustion `stop(..., call. = FALSE)`. D-08 wires a user `port=NULL` argument straight into `prefer=`; D-09 sharpens the existing exhaustion message to name the tried range.

```87:99:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
.gmw_pick_port <- function(prefer = NULL, probe = .gmw_probe_free) {
  if (is.null(prefer)) return(httpuv::randomPort())
  port <- as.integer(prefer)
  while (!isTRUE(probe(port))) {
    port <- port + 1L
    if (port > 49151L) {
      stop("GUImorphWeb: could not find a free port walking forward from ",
           prefer, ".\n  Free a port in the 1024-49151 range and retry.",
           call. = FALSE)
    }
  }
  port
}
```

**Copy for:** add `port = NULL` to `.gmw_serve_mesh(...)` and call `port <- .gmw_pick_port(prefer = port)` (line 134 currently calls it with no arg). Keep the exact `stop(..., call. = FALSE)` shape; D-09 wants the wording to also say "omit `port` to auto-pick."

#### (d) `.gmw_probe_free` / `.gmw_token` — reused as-is (no change)

```55:74:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
.gmw_token <- function(n = 32L) {
  alphabet <- c(0:9, letters, LETTERS)
  paste(sample(alphabet, n, replace = TRUE), collapse = "")
}

# ...

.gmw_probe_free <- function(port) {
  con <- tryCatch(serverSocket(as.integer(port)), error = function(e) NULL)
  if (is.null(con)) return(FALSE)
  close(con)
  TRUE
}
```

**Copy for:** nothing new — these are the injectable primitives the port/close tests stub. `.gmw_token()` already generates the per-server token the `/close` handler will close over.

#### (e) Launch messaging (D-05/D-06/D-07) — extend the existing print-then-open block

The current entry point already prints the URL and then opens it. Phase 3 hardens it: keep print-first, add the paste-fallback + firewall note, wrap `browseURL` in `tryCatch`, and ignore its return value.

```148:152:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
  url <- sprintf("http://127.0.0.1:%d/%s/", port, token)
  dbg(paste0("gmw serve: ", url))
  message("Viewport: ", url)
  if (isTRUE(open)) utils::browseURL(url)
  invisible(url)
```

**Analog for the `tryCatch(browseURL)` shape** — `.plot_show()` in `rtkogl.R` already opens externally under a `tryCatch`/`try`:

```923:934:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
.plot_show <- function(draw, width = 800, height = 600) {
  if (.isMacOS()) {
    f <- tempfile(pattern = "guimorph-plot-", fileext = ".png")
    grDevices::png(f, width = width, height = height)
    ok <- FALSE
    tryCatch({ draw(); ok <- TRUE }, finally = grDevices::dev.off())
    if (ok) utils::browseURL(f)
  } else {
    grDevices::dev.new()
    draw()
  }
}
```

**Change to (per RESEARCH §Code Examples "Browser-launch degradation"):** `message("Viewport: ", url, "\n  If it did not open, paste that URL into a browser.")`, a one-time firewall note (D-06), then `if (isTRUE(open)) try(utils::browseURL(url), silent = TRUE)` with the return value ignored (D-05). `browseURL` already consults `getOption("browser")`/`R_BROWSER` (D-07) — add no override machinery.

#### (f) Teardown helper + exported `gmw_close` (D-01/D-04)

No in-tree teardown helper exists yet, but the **test helper** `teardown_server()` is the exact two-step (`stopServer` + `rm`) the production helper must generalize over the whole registry:

```38:41:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/helper-transport.R
teardown_server <- function(s) {
  try(httpuv::stopServer(s$srv), silent = TRUE)
  if (exists(s$token, envir = .gmw_server)) rm(list = s$token, envir = .gmw_server)
}
```

**Copy for `.gmw_stop_token(token = NULL)`** (RESEARCH Pattern 1): iterate `ls(.gmw_server)` when `token` is NULL else the single token; `get()` each handle under `tryCatch`, `try(httpuv::stopServer(srv))`, then `rm()` the entry — both steps always run so no orphan survives (Pitfall 1). **Never** `httpuv::stopAllServers()` (kills other packages' servers). Export `gmw_close <- function(token = NULL) .gmw_stop_token(token)`.

#### (g) Package hooks — `.onUnload` + `reg.finalizer`

`.onLoad` and `.onAttach` are the in-tree namespace-hook precedents (signature `function(libname, pkgname)` / `function(libname, pkgname)`).

```513:514:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
.onLoad <- function(libname, pkgname)
{
```

```936:944:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
.onAttach <- function(libname, pkgname) {
  gmv <- tryCatch(as.character(utils::packageVersion("geomorph")), error = function(err) "not found")
  packageStartupMessage(
    "GUImorphWeb ", utils::packageVersion(pkgname), " (beta) - Windows and macOS\n",
    "3D geometric morphometric digitizing for the geomorph ecosystem.\n",
    "Using geomorph ", gmv, "\n",
    "Issues / updates: https://github.com/dreoc/guimorph-web"
  )
}
```

**Copy for (RESEARCH Pattern 1):** add `.onUnload <- function(libpath) .gmw_stop_token(NULL)` **in `transport.R`** (beside `.gmw_server`). Register `reg.finalizer(.gmw_server, function(e) .gmw_stop_token(NULL), onexit = TRUE)` **once**, lazily on first serve, guarded by a flag in the separate `.gmw_lifecycle` env (RESEARCH §Code Examples "Register the session-end finalizer exactly once"). `.onUnload` does **not** fire at `q()` — the finalizer is the only session-end hook; do not conflate them.

---

### `R/view3d.R` — `GMW_VIEW3D_TEMPLATE` (view template, event-driven page JS)

**Analog:** the existing event-listener block already in the same template.

The page already registers `resize` and `keydown` listeners in the IIFE. The D-02 `sendBeacon` hook is the same shape — add `pagehide` + `visibilitychange` listeners next to these. Note the template is a `sprintf` string, so literal `%` must stay escaped as `%%` (see `100%%`, `Loading mesh " + pct + "%%"` already in-file).

```232:236:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
  window.addEventListener("resize", resize);
  window.addEventListener("keydown", function(e){
    if (e.key === "r" || e.key === "R") reset();
  });
  resize();
```

**Copy for (RESEARCH Pattern 3):** add beside the listeners above —

```js
function gmwClose(){ try { navigator.sendBeacon("close"); } catch(e){} }
window.addEventListener("pagehide", gmwClose);
document.addEventListener("visibilitychange", function(){
  if (document.visibilityState === "hidden") gmwClose();
});
```

`"close"` resolves relative to the page URL `http://127.0.0.1:PORT/<token>/` → `.../<token>/close` (same token, same-origin POST, no CORS, no server-side path parsing). Use `pagehide`, **not** `unload` (Pitfall 4). Adding this changes no external `src=`/`href=` (WEB-03 offline-by-construction preserved).

---

### `R/rtkogl.R` — READ-ONLY precedent (CMP-01 gate)

**Do not modify.** Referenced only for the `.onLoad` engine-load path and `.gmw_engine$ok`, which Phase 3 must leave untouched. CMP-01 verification asserts `.gmw_engine$ok` is unchanged by lifecycle work.

```505:511:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
.gmw_require_engine <- function() {
  if (isTRUE(.gmw_engine$ok)) return(invisible(TRUE))
  stop("GUImorphWeb: 3D digitizing needs the native tkogl2 engine, which did ",
       "not load.\n  ", .gmw_engine$msg,
       "\n  Result plots and the browser viewport do not need it and still work.",
       call. = FALSE)
}
```

---

### `tests/testthat/test-transport.R` (EDIT + ADD unit tests)

**Analog:** itself + `helper-transport.R`. Same-process `curl` **cannot** reach the `/close` route (Pitfall 5) — test the handler by invoking the `call` closure directly with a synthetic `req`.

#### (a) Re-scope the `PATH_INFO` guard (Pitfall 3 — MUST edit before adding `/close`)

The Phase-2 guard fails the moment the `/close` handler reads `req$PATH_INFO`:

```54:60:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport.R
  # Source-scan the transport for the loopback/no-LAN and no-path-join guards.
  src <- readLines(file.path(pkg_root, "R", "transport.R"), warn = FALSE)
  expect_true(any(grepl("127.0.0.1", src, fixed = TRUE)))
  expect_false(any(grepl("0.0.0.0", src, fixed = TRUE)))
  expect_true(any(grepl("staticPath", src, fixed = TRUE)))
  expect_false(any(grepl("PATH_INFO", src, fixed = TRUE)))
```

**Change to:** keep the `127.0.0.1`-present, `0.0.0.0`-absent, and `staticPath`-present assertions. Replace line 59 with the real invariant: the `call` handler does not `file.path()`/`normalizePath()`/`readBin()` anything derived from `req$PATH_INFO` (RESEARCH Pitfall 3). `PATH_INFO` may now appear; a filesystem join from it may not.

#### (b) Test-fixture patterns to copy — `serve_tmp` / `teardown_server` / probe stub

```30:41:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/helper-transport.R
serve_tmp <- function(open = FALSE) {
  url   <- .gmw_serve_mesh(fixture, open = open)
  token <- gmw_url_token(url)
  list(url = url, token = token, srv = get(token, envir = .gmw_server))
}

teardown_server <- function(s) {
  try(httpuv::stopServer(s$srv), silent = TRUE)
  if (exists(s$token, envir = .gmw_server)) rm(list = s$token, envir = .gmw_server)
}
```

The port walk-forward test already shows the injected-probe pattern (no socket bound) that the D-09 exhaustion test extends:

```99:105:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport.R
test_that("port selection walks forward from the preferred port (no socket bound)", {
  # Preferred port busy -> next free port, without binding anything.
  expect_identical(.gmw_pick_port(prefer = 8080L, probe = gmw_probe_stub(busy = 8080L)), 8081L)
  expect_identical(.gmw_pick_port(prefer = 8080L, probe = function(p) p != 8080L), 8081L)
  # Two consecutive busy ports -> walk past both.
  expect_identical(.gmw_pick_port(prefer = 9000L, probe = gmw_probe_stub(busy = c(9000L, 9001L))), 9002L)
```

The browser-override test shows the `options(browser=...)` capture pattern for the D-05/D-07 messaging test:

```114:128:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport.R
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
```

**Copy for the new blocks (RESEARCH §Validation Architecture Wave 0):**
- `gmw_close(token)` stops one, `gmw_close()` stops all — assert both `length(ls(.gmw_server)) == 0` **and** `length(httpuv::listServers()) == 0` after stop-all (Pitfall 1).
- `reg.finalizer` registered once (flag in `.gmw_lifecycle`); stop-all callable.
- `.onUnload()` stops all live servers.
- `/close` handler: build the `call` closure, invoke with synthetic `req = list(PATH_INFO = "/<token>/close")`, assert it returns `204` and schedules/performs the stop of that token (Pitfall 5 — never same-process `curl`).
- D-09 exhaustion: `.gmw_pick_port(prefer = ..., probe = function(p) FALSE)` → `expect_error(...)` naming the range (extend the existing port test).
- D-05 messaging: `expect_message(...)` for URL-first + `browseURL` failure does not error.

Guard every source-touching block with `skip_if_no_pkg_source()` / `skip_if_no_curl()` as the file already does (lines 6, 64).

---

### `tests/testthat/test-offline-smoke.R` (NEW — WEB-03 integration)

**Analog:** the byte-identity block in `test-transport.R` + `helper-transport.R` fetch helpers.

```62:74:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport.R
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
```

**Copy for (RESEARCH §Code Examples "Offline install smoke test", Pitfall 6):** build the tarball, `install.packages(tarball, repos = NULL, type = "source", dependencies = FALSE, lib = <templib>)` (the `dependencies = FALSE` is load-bearing — otherwise CRAN is reached and it is not an offline test), then assert `system.file("htmlwidgets","guimorphweb-three.js", package="GUImorphWeb")` is non-empty, serve the fixture, GET `specimen.ply` (expect 200 + byte-identity), and GET the page asserting **no** `src="http(s)://` / `href="http(s)://` external refs. Skip cleanly when build tooling / curl is absent (mirror the existing `skip_if_*` habit). Filter name `offline` (`test_local(filter="offline")`).

---

### `NAMESPACE` (regen)

**Analog:** the existing exports.

```1:8:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/NAMESPACE
# Generated by roxygen2: do not edit by hand

export(GUImorphWeb)
export(loadDgt)
import(Rvcg)
import(geomorph)
import(tcltk)
import(tcltk2)
```

**Copy for:** add `#' @export` roxygen above `gmw_close` in `transport.R` (mirroring `GUImorphWeb`/`loadDgt` roxygen in `rtkogl.R` at lines 397-408 / 434-443) and regenerate — this adds `export(gmw_close)`. `NAMESPACE` says "do not edit by hand"; regen via roxygen2 (Config/roxygen2/version 8.0.0 in DESCRIPTION). No new `import()` — `httpuv`/`later` already covered (httpuv is an Import; `later` is transitive, called fully-qualified `later::later`).

## Shared Patterns

### Error handling — clear `stop(..., call. = FALSE)`
**Source:** `R/transport.R:92-96` (`.gmw_pick_port`), `R/transport.R:118-123` (`.gmw_serve_mesh` missing-file), `R/rtkogl.R:505-511` (`.gmw_require_engine`).
**Apply to:** D-09 port-exhaustion error, any new user-facing failure. Always `call. = FALSE`, prefix `"GUImorphWeb: "`, give an actionable next step. Matches `.cursor/rules/` CONVENTIONS.

### Gated debug printer `dbg()`
**Source:** `R/rtkogl.R:844` (canonical) + the standalone-source fallback guard `R/transport.R:36-38`.
**Apply to:** all diagnostics in new code — never raw `print()`. `dbg()` prints only under `options(guimorph.debug=TRUE)`.

### Package-env state + namespace hooks
**Source:** `.gmw_server` (`transport.R:43`), `.gmw_engine` (`rtkogl.R:498-500`), `.onLoad`/`.onAttach` (`rtkogl.R:513`, `936`).
**Apply to:** `.gmw_lifecycle` flag env, `.onUnload`, `reg.finalizer` — all authored in `transport.R`, never in `rtkogl.R`.

### `tryCatch`/`try` around risky external calls
**Source:** `.plot_show` browseURL (`rtkogl.R:923-934`), `.onLoad` DLL load (`rtkogl.R:574-590`), `.gmw_probe_free` socket (`transport.R:70`).
**Apply to:** the D-05 `browseURL`, the `/close` handle `get()`/`stopServer()`, so one bad handle never aborts stop-all.

### Deferred stop — `later::later`, never `Sys.sleep`
**Source:** none in-tree (new); `later` is httpuv's own scheduler (RESEARCH §Don't Hand-Roll).
**Apply to:** the `/close` handler — return `204` first, `later::later(fn, ~0.5)` the `stopServer` (Pitfall 2: synchronous stop resets the socket).

## No Analog Found

Every construct maps to an in-tree precedent. Two constructs are **new to this repo** but come from a loaded dependency / standard web platform rather than a codebase analog — the planner should follow RESEARCH, not search the tree:

| Construct | Role | Data Flow | Source to follow |
|-----------|------|-----------|------------------|
| `later::later(stopServer, delay)` deferred teardown | transport (R-thread callback) | event-driven | RESEARCH Pattern 2 / Pitfall 2 (httpuv dep, no in-tree use yet) |
| `navigator.sendBeacon` on `pagehide` | view (page JS) | event-driven | RESEARCH Pattern 3 / Pitfall 4 (standard web platform) |

## Metadata

**Analog search scope:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/` (10 files), `tests/testthat/` (17 files), `NAMESPACE`, `DESCRIPTION`.
**Files scanned in full:** `R/transport.R`, `R/rtkogl.R`, `R/view3d.R`, `tests/testthat/test-transport.R`, `tests/testthat/helper-transport.R`, `tests/testthat/helper-pkg-source.R`, `NAMESPACE`, `DESCRIPTION`.
**Pattern extraction date:** 2026-08-03
