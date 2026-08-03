# Phase 2: Transport and Mesh Display - Pattern Map

**Mapped:** 2026-07-31
**Files analyzed:** 6 (2 new source, 2 new test/helper, 2 modified)
**Analogs found:** 5 / 6 (renv.lock is a generated lockfile — no code analog)

> All source paths are relative to
> `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`.
> The package name is **GUImorphWeb** (DESCRIPTION line 1); do not confuse with
> the legacy `GUImorph`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `R/transport.R` (NEW) | service (loopback HTTP server + token/port helpers) | file-I/O → static byte serving (request-response) | `R/view3d.R` (`.gmw_view3d` delivery shape + `.gmw_bundle_path`) and `R/rtkogl.R` (`.gmw_engine` package-env retain pattern) | role-match (delivery shape exact; server machinery is new) |
| `R/view3d.R` (MODIFIED) | component (browser render template) | transform / async render | `R/view3d.R` itself (`GMW_VIEW3D_TEMPLATE`, framing math) | exact (self — parametrize existing template) |
| `DESCRIPTION` (MODIFIED) | config (dependency manifest) | — | `DESCRIPTION` Imports block (lines 12-16) | exact |
| `tests/testthat/test-transport.R` (NEW) | test (unit + integration) | request-response (start server, GET, assert bytes) | `tests/testthat/test-curve-io.R` (behavioral, tempfile+on.exit) and `test-rgl-fallback-macos.R` (browser-capture, source-scan) | role-match |
| `tests/testthat/helper-transport.R` (NEW, optional) | test helper | — | `tests/testthat/helper-pkg-source.R` | role-match |
| `renv.lock` (MODIFIED) | config (generated lockfile) | — | — (produced by `renv::snapshot()`) | no analog |

---

## Pattern Assignments

### `R/transport.R` (service, file-I/O → static byte serving)

**Analog A — delivery shape + tempdir + bundle copy + browseURL:** `R/view3d.R` `.gmw_view3d()`
**Analog B — package-level retained-state env:** `R/rtkogl.R` `.gmw_engine`

**Bundle-path resolver to reuse verbatim** (`R/view3d.R` lines 35-44) — copy the
vendored JS next to the served page instead of inlining it:
```r
.gmw_bundle_path <- function() {
  p <- system.file("htmlwidgets", "guimorphweb-three.js",
                   package = utils::packageName())
  if (!nzchar(p)) {
    stop("The three.js bundle is missing from inst/htmlwidgets/. ",
         "Run: cd scripts/vendor && npm install && npm run vendor",
         call. = FALSE)
  }
  p
}
```

**Delivery-shape pattern to mirror** (`R/view3d.R` lines 57-84) — a tempdir is
created, the bundle is copied in, the page is written with `useBytes = TRUE`,
`browseURL()` opens it, `message("Viewport: ", …)` prints it, and the path is
returned invisibly. Phase 2 keeps this exact shape but serves over
`http://127.0.0.1:PORT/<token>/` instead of a `file://` path, and adds the PLY
copy into the same tempdir:
```r
.gmw_view3d <- function(clouds = list(), mesh = NULL,
                        title = "GUImorphWeb", background = "#ffffff") {
  dir <- tempfile(pattern = "guimorphweb-")
  dir.create(dir)
  file.copy(.gmw_bundle_path(), file.path(dir, "guimorphweb-three.js"))
  # ... build page ...
  f <- file.path(dir, "index.html")
  writeLines(html, f, useBytes = TRUE)
  utils::browseURL(f)
  message("Viewport: ", f)
  invisible(f)
}
```
> **Divergence for Phase 2 (from RESEARCH Pattern 1):** the page is served over
> `httpuv` (same-origin `http://`) so the `PLYLoader` fetch is not CORS-blocked.
> `browseURL()` receives the http URL, not the file path. This is the one
> deliberate departure from the `.gmw_view3d` file:// delivery shape and is
> covered by CONTEXT "Claude's Discretion" (route/template shape).

**Retained-state package-env pattern to copy** (`R/rtkogl.R` lines 498-500) — the
`httpuv` server handle MUST be stored in a package-level environment or its
finalizer stops the listener on GC (RESEARCH Pitfall 2). Mirror the `.gmw_engine`
idiom exactly:
```r
.gmw_engine <- new.env(parent = emptyenv())
.gmw_engine$ok  <- FALSE
.gmw_engine$msg <- "the engine was never initialised"
```
Apply as e.g. `.gmw_server <- new.env(parent = emptyenv())` holding the live
server handle(s) so they survive `gc()` for the session.

**httpuv wiring (no existing analog — new machinery, per RESEARCH Pattern 1):**
```r
port  <- httpuv::randomPort()                 # 127.0.0.1, unprivileged, browser-safe
token <- .gmw_token()                          # >=128-bit; see Shared Patterns
server <- httpuv::startServer(
  host = "127.0.0.1", port = port,
  app = list(
    staticPaths = stats::setNames(
      list(httpuv::staticPath(dir)),           # dir = tempdir with page+bundle+ply
      paste0("/", token)
    )
  )
)
url <- sprintf("http://127.0.0.1:%d/%s/", port, token)
message("Viewport: ", url)
utils::browseURL(url)
```
> Use `staticPaths` (off the R thread, safe path resolution), never a `call`
> handler (RESEARCH Anti-Patterns). Bind `127.0.0.1` explicitly, never `0.0.0.0`.

**Error/refusal idiom to follow** (`R/rtkogl.R` lines 505-511) — GUImorphWeb uses
plain `stop(..., call. = FALSE)` with a multi-line actionable message; match that
tone for any transport-side failure surfaced this phase:
```r
.gmw_require_engine <- function() {
  if (isTRUE(.gmw_engine$ok)) return(invisible(TRUE))
  stop("GUImorphWeb: 3D digitizing needs the native tkogl2 engine, which did ",
       "not load.\n  ", .gmw_engine$msg, ...,
       call. = FALSE)
}
```

---

### `R/view3d.R` (component, async render) — MODIFIED

**Analog:** the file itself — parametrize `GMW_VIEW3D_TEMPLATE` rather than fork
(RESEARCH Open Question 2; CONTEXT prefers reuse if clean).

**Template header + globals to keep** (`R/view3d.R` lines 98-118) — the bundle
`<script src="guimorphweb-three.js">`, the `GMW.THREE / GMW.OrbitControls`
globals, renderer, scene, camera, group, and lights are all reused unchanged.
`GMW.PLYLoader` is added to the destructure:
```r
var THREE = GMW.THREE, OrbitControls = GMW.OrbitControls;   # add GMW.PLYLoader
# renderer.setClearColor(new THREE.Color(BG), 1);  scene/camera/group/lights ...
scene.add(new THREE.AmbientLight(0xffffff, 0.75));
var key = new THREE.DirectionalLight(0xffffff, 0.65);
```

**Block to REPLACE** (`R/view3d.R` lines 134-141) — the synchronous inlined-mesh
block is swapped for an async `PLYLoader.load(url, …)`. Note the existing block
already calls `computeVertexNormals()` and uses `MeshLambertMaterial` +
`DoubleSide` + `#cccccc`, which is exactly what D-03/D-04 require — carry these
into the callback:
```r
if (MESH) {
  var g = attr(MESH.v);
  g.setIndex(MESH.f);
  g.computeVertexNormals();
  group.add(new THREE.Mesh(g, new THREE.MeshLambertMaterial({
    color: MESH.c, wireframe: MESH.w, side: THREE.DoubleSide
  })));
}
```
Replacement (RESEARCH Pattern 2) — `vertexColors` stays false (ignore scan RGB):
```javascript
new GMW.PLYLoader().load("specimen.ply", function (geometry) {
  geometry.computeVertexNormals();                 // else black Lambert mesh (Pitfall 1)
  group.add(new THREE.Mesh(geometry, new THREE.MeshLambertMaterial({
    color: "#cccccc", side: THREE.DoubleSide
  })));
  frameScene();                                    // DEFERRED framing (Pitfall 3)
}, function (e) { /* onProgress: e.loaded / e.total — 30 MB worst case */ },
   function (e) { /* onError: surface a legible message */ });
```

**Framing math to MOVE into the callback** (`R/view3d.R` lines 143-162) — this
runs synchronously today; it must move inside the load callback (`frameScene()`)
because the geometry does not exist when the page first runs (Pitfall 3). The
math itself is reused verbatim:
```r
var box = new THREE.Box3().setFromObject(group);
var sphere = box.getBoundingSphere(new THREE.Sphere());
var home = sphere.radius > 0 ? sphere.radius : 1;
var dist = home / Math.sin((camera.fov * Math.PI / 180) / 2) * 1.15;
group.position.sub(sphere.center);
# controls + reset() below reads `dist`; keep reset()/'r' keybind wiring intact
```
> `dist` is closed over by `reset()` (lines 155-162) and the `keydown` handler
> (lines 172-174). If framing moves into the async callback, `dist` must be
> hoisted to the outer scope (or `reset()` defined after framing) so orbit/zoom/
> `r`-reset still work — this is the main wiring subtlety of the reuse.

**`sprintf`-template escaping constraint:** `GMW_VIEW3D_TEMPLATE` is an R
`sprintf` string — every literal `%` is doubled (`100%%`, lines 89-91) and `%s`
marks the injection slots filled at lines 77-78. Any new injected value (e.g. the
PLY URL/filename) must be added as a `%s` slot and threaded through the `sprintf`
call; any new literal `%` must be doubled.

---

### `DESCRIPTION` (config) — MODIFIED

**Analog:** existing Imports block (lines 12-16). Add `httpuv` to `Imports`,
keeping the trailing-comma-separated multiline style. `htmlwidgets` stays in
`Suggests` (CONTEXT: do not reintroduce to Imports):
```
Imports:
    geomorph (>= 4.1.1),
    Rvcg,
    tcltk,
    tcltk2,
    httpuv
```
Then `install.packages("httpuv")` + `renv::snapshot()` (RESEARCH: httpuv not yet
in `renv.lock`).

---

### `tests/testthat/test-transport.R` (test) — NEW

**Analog A — behavioral test with tempfile + on.exit teardown:** `test-curve-io.R`
**Analog B — capture `browseURL` without launching + source-scan style:** `test-rgl-fallback-macos.R`

**Behavioral scaffold to mirror** (`test-curve-io.R` lines 1-20) — `pkg_root`,
`skip_if_no_pkg_source()`, `source()` the target R file locally, then
`tempfile()` + `on.exit(unlink(...), add = TRUE)`:
```r
pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
skip_if_no_pkg_source()
source(file.path(pkg_root, "R", "transport.R"), local = FALSE)

test_that("write.curve and read.curve round-trip a 3-column integer matrix", {
  tmp <- tempfile(fileext = ".dgt")
  on.exit(unlink(tmp), add = TRUE)
  # ...
})
```
For the transport server, the on.exit teardown is `httpuv::stopServer(srv)`
(RESEARCH byte-integrity example):
```r
srv <- httpuv::startServer("127.0.0.1", httpuv::randomPort(),
  list(staticPaths = list("/m" = dirname(ply_path))))
on.exit(httpuv::stopServer(srv), add = TRUE)
url  <- sprintf("http://127.0.0.1:%d/m/%s", srv$getPort(), basename(ply_path))
got  <- curl::curl_fetch_memory(url)$content
disk <- readBin(ply_path, "raw", file.info(ply_path)$size)
testthat::expect_identical(got, disk)              # byte-identical, never JSON
```

**Browser-capture pattern to reuse** (`test-rgl-fallback-macos.R` lines 126-144)
— to assert `.gmw_serve_mesh()` opens a URL without launching a real browser,
override the `browser` option (`browseURL` calls it when it is a function) and
`source()` the file locally so helpers resolve lexically:
```r
source(file.path(pkg_root, "R", "rtkogl.R"), local = TRUE)
opened <- NULL
old <- options(browser = function(url, ...) { opened <<- url; invisible(TRUE) })
on.exit(options(old), add = TRUE)
# ... call the entry point ...
expect_false(is.null(opened))
expect_match(opened, "^http://127\\.0\\.0\\.1:")     # transport variant of the assertion
```

**Port-fallback (no-bind) pattern** — inject a probe stub and assert
randomPort-primary / walk-forward-backup ordering without binding a socket
(RESEARCH Code Examples + REFERENCE-ARCHITECTURE technique):
```r
pick_port <- function(prefer = NULL, probe = .gmw_probe_free) { ... }
testthat::expect_equal(pick_port(prefer = 8080, probe = stub), 8081L)
```

**Guard/dependency notes for the planner:**
- `curl` is Suggests-only; gate the byte-integrity test with
  `testthat::skip_if_not_installed("curl")` (or use base `url()`/`readBin`).
- Test fixture for the worst-case transfer: `tests/fixtures/parity/B7_1_clean.ply`
  (30 MB); smaller committed fixtures (`B12_1_clean.ply`, `C8_1_clean.ply`) exist
  for fast byte-integrity checks.

---

### `tests/testthat/helper-transport.R` (test helper, optional) — NEW

**Analog:** `helper-pkg-source.R` (lines 11-21) — a helper file defining
`pkg_source_root()` / `skip_if_no_pkg_source()`. Follow the same shape: small
helper functions (start/stop server, port-probe stub) plus a clean `skip_if`
guard, no `test_that` blocks. testthat auto-sources `helper-*.R` before tests.

---

## Shared Patterns

### Package-level retained state (server handle)
**Source:** `R/rtkogl.R` lines 498-500 (`.gmw_engine <- new.env(parent = emptyenv())`)
**Apply to:** `R/transport.R` — retain the `httpuv` server handle in a package env
so GC does not stop the listener (RESEARCH Pitfall 2).

### Vendored-bundle resolution + tempdir delivery shape
**Source:** `R/view3d.R` lines 35-44 (`.gmw_bundle_path`) and 57-84 (`.gmw_view3d`)
**Apply to:** `R/transport.R` — copy `guimorphweb-three.js` (+ page + PLY) into a
`tempfile()`-created dir, then serve/open. Reuse `.gmw_bundle_path()` directly.

### Platform-guarded external display (browseURL)
**Source:** `R/rtkogl.R` lines 923-934 (`.plot_show`), 866-868 (`.isMacOS`)
**Apply to:** `R/transport.R` — `utils::browseURL(url)` + `message("Viewport: …")`
is the established "open externally, tell the user the path" idiom. Do not open a
native window. (Robust browser-launch degradation is WEB-04/Phase 3 — out of scope.)

### Gated debug printing
**Source:** `R/rtkogl.R` line 844 (`dbg <- function(...) if (isTRUE(getOption("guimorph.debug", FALSE))) print(...)`)
**Apply to:** any diagnostic output in `R/transport.R` — route through `dbg()`,
never bare `print()`/`cat()`.

### Source-scan + browser-capture test idioms
**Source:** `tests/testthat/test-rgl-fallback-macos.R` (`.fn_body` scanner lines
11-18; `options(browser=...)` capture lines 134-144); `helper-pkg-source.R`
skip guard.
**Apply to:** `test-transport.R` — for asserting bind host / no-`0.0.0.0` /
`staticPaths` usage via source scan, and for asserting the opened URL without a
real browser launch.

### Coding-style conventions (observed across R/)
- Internal helpers are `.gmw_`-prefixed and `#' @noRd` / `#' @keywords internal`.
- Exported functions get full roxygen with `@export` (e.g. `GUImorphWeb`, lines 397-409).
- `stop(..., call. = FALSE)` with multi-line actionable messages; `packageStartupMessage` for non-fatal load-time notices.
- Namespaced base calls in package code: `utils::browseURL`, `stats::setNames`, `grDevices::png`.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `renv.lock` (add `httpuv`) | config (generated lockfile) | — | Produced by `renv::snapshot()`, not hand-authored; no code pattern to copy. Planner adds an install + snapshot task. |

The **httpuv server machinery itself** (`startServer` / `staticPaths` /
`randomPort` / `stopServer`) has no in-repo analog — this is the genuinely new
code of the phase. The planner should follow RESEARCH.md Pattern 1 (the httpuv
docs excerpts) for that portion; the R-side wiring *around* it (tempdir,
bundle copy, package-env retain, browseURL delivery, dbg, stop idiom) all copies
from the analogs above.

## Metadata

**Analog search scope:** `R/` (view3d.R, rtkogl.R, and 3dDigitize.* via grep),
`tests/testthat/`, `DESCRIPTION`, `tests/testthat.R`.
**Files scanned:** view3d.R, rtkogl.R, DESCRIPTION, testthat.R, helper-pkg-source.R,
test-rgl-fallback-macos.R, test-curve-io.R (+ CONTEXT.md, RESEARCH.md).
**Pattern extraction date:** 2026-07-31
