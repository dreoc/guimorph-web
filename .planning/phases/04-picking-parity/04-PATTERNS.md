# Phase 4: Picking Parity - Pattern Map

**Mapped:** 2026-08-05
**Files analyzed:** 5 (2 modified, 3 new)
**Analogs found:** 5 / 5 (all in-repo; residual net-new math has no analog and is noted)

> Package root: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`
> All line numbers below are from files read this session. Every new file copies
> an existing in-repo analog for its *wiring*; only the coordinate math and the
> TSV schema are net-new (RESEARCH is the source for those, not an analog).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `R/transport.R` (MODIFY: pick route + `.gmw_picks` + R read API) | route/middleware | request-response | `R/transport.R` `.gmw_close_handler` / `.gmw_serve_mesh` (self) | exact |
| `R/view3d.R` (MODIFY: raycast + `computeBoundsTree` + overlay + replay hook in `GMW_VIEW3D_TEMPLATE`) | component (browser JS template) | event-driven | `R/view3d.R` `GMW_VIEW3D_TEMPLATE` PLYLoader callback + beacon (self) | exact |
| `R/parity.R` (NEW: `mean_edge_length`, `parity_gate`, `read_pick_poses`) | utility | transform / batch | `R/view3d.R` pure helpers (`.gmw_flat`, `.gmw_faces`) for style; math net-new | role-match |
| `tests/fixtures/parity/B7_1_pick_poses.tsv` (NEW placeholder) | fixture/config | file-I/O | `tests/fixtures/parity/B12_1_clean.ply` (co-located) | schema net-new |
| `tests/testthat/test-picking-parity.R` (NEW harness) | test | request-response + batch | `test-transport.R` (handler unit), `test-retina-picking-parity.R` (skip idiom), `test-view3d-beacon.R` (source-scan) | exact |
| (optional) R-side pick accessor entry point | route/api | request-response | `gmw_close` export + `.plot_show` delivery shape | role-match |

---

## Pattern Assignments

### `R/transport.R` — pick route + registry + R read API (route, request-response)

**Analog:** `R/transport.R` itself — `.gmw_close_handler` and the mixed-app
`startServer` block. The pick route is a **second excluded subpath** on the same
app; extend the existing `call` handler rather than adding a new server.

**Registry pattern — mirror `.gmw_server` (`transport.R:40-49`):**

```40:49:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
# Package-level retained state: holds each live httpuv server handle, keyed by
# its token, so gc() does not run the finalizer and stop the listener for the
# session. Mirrors the .gmw_engine idiom in rtkogl.R.
.gmw_server <- new.env(parent = emptyenv())

# Package-level lifecycle flags, kept SEPARATE from .gmw_server so that
# ls(.gmw_server) stays purely token -> handle and no bookkeeping key is ever
# mistaken for a live server handle by .gmw_stop_token() (RESEARCH Open
# Question 1). Currently holds `finalizer_registered`; plan 02 adds more.
.gmw_lifecycle <- new.env(parent = emptyenv())
```

→ Add a sibling `.gmw_picks <- new.env(parent = emptyenv())` (token → landmark
matrix). Keep it separate from `.gmw_server` so the server registry stays
purely token→handle (same reasoning as `.gmw_lifecycle`).

**Handler pattern — extend `.gmw_close_handler` (`transport.R:128-137`):** the
new handler must **subsume** the `/close` logic (one `call` handler per server),
adding a `/pick$` branch that reads the body, base-R parses `"x,y,z"`, validates
3 finite numerics, appends to `.gmw_picks[[token]]`, returns 204. NEVER join
`req$PATH_INFO` to the filesystem (T-2-02).

```128:137:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
.gmw_close_handler <- function(token) {
  force(token)
  function(req) {
    if (grepl("/close$", req$PATH_INFO)) {
      later::later(function() .gmw_stop_token(token), 0.5)
      return(list(status = 204L, headers = list(), body = ""))
    }
    list(status = 404L, headers = list("Content-Type" = "text/plain"), body = "")
  }
}
```

→ RESEARCH Pattern 3 gives the exact `/pick` branch: `body <-
rawToChar(req$rook.input$read())`; `xyz <- as.numeric(strsplit(body, ",",
fixed = TRUE)[[1]])`; guard `length(xyz) == 3L && all(is.finite(xyz))`; append
with `rbind`. Rename the closure to `.gmw_pick_handler` (it now owns both
routes) or add the branch in place and keep the name — planner's call.

**Mixed-app mount — extend the `staticPaths`/`excludeStaticPath` set (`transport.R:185-201`):**

```185:201:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
  # Mixed static + one dynamic route (RESEARCH Pattern 2, D-02). The static
  # byte mount stays byte-for-byte as Phase 2 shipped it (its options are
  # unchanged, T-2-02); alongside it, excludeStaticPath() routes exactly the one
  # /<token>/close subpath to R instead of the C++ static thread, and the `call`
  # handler answers it. excludeStaticPath() is preferred over
  # staticPathOptions(fallthrough = TRUE) -- it scopes exactly one subpath to R
  # rather than routing every missing file there (RESEARCH Alternatives).
  server <- httpuv::startServer(
    host = "127.0.0.1", port = port,
    app = list(
      staticPaths = stats::setNames(
        list(httpuv::staticPath(dir), httpuv::excludeStaticPath()),
        c(paste0("/", token), paste0("/", token, "/close"))
      ),
      call = .gmw_close_handler(token)
    )
  )
```

→ Add `paste0("/", token, "/pick")` (a second `httpuv::excludeStaticPath()`)
to the `setNames` list, and swap `call = .gmw_pick_handler(token)`.

**R read-API delivery shape — mirror `gmw_close` export + `.plot_show`
(`transport.R:295-296`, `rtkogl.R:923`):** a small accessor returning the
landmark matrix for a token, `@export`ed only if a user entry point is genuinely
needed (else `@noRd`).

```295:296:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
#' @export
gmw_close <- function(token = NULL) .gmw_stop_token(token)
```

**CMP-01 invariant (do NOT regress):** `transport.R` must never write the
`.gmw_engine` env. This is already asserted by `test-transport.R:121-133` — the
new pick code must keep that green.

---

### `R/view3d.R` — raycast + overlay + camera-replay hook (component, event-driven)

**Analog:** `R/view3d.R` `GMW_VIEW3D_TEMPLATE`, specifically the `MESH_URL`
PLYLoader callback and the tab-close beacon block. New JS is added **inside the
existing IIFE**, reusing `THREE`, `camera`, `renderer`, `group`, `dist`.

**PLYLoader callback — where `computeBoundsTree()` goes (`view3d.R:204-209`):**

```204:209:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
    new PLYLoader().load(MESH_URL, function(geometry){
      geometry.computeVertexNormals();
      group.add(new THREE.Mesh(geometry, new THREE.MeshLambertMaterial({
        color: "#cccccc", side: THREE.DoubleSide
      })));
      frameScene();
    }, function(e){
```

→ Insert `geometry.computeBoundsTree();` immediately after
`computeVertexNormals()` (RESEARCH Pitfall 5 — eager build folds BVH cost into
load, not the first click). Retain the returned `THREE.Mesh` in an
IIFE-scope var so the pointer handler can `intersectObject(mesh, false)`.

**Beacon idiom to copy for the pick POST (`view3d.R:237-249`):** the pick
handler mirrors this exact same-origin relative-URL `sendBeacon` shape — the
POST target is the relative token `"pick"`, never an absolute URL (WEB-03 /
offline-by-construction, enforced by `test-view3d-beacon.R:26-29`).

```237:249:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
  // Best-effort tab-close teardown (D-02): fire-and-forget POST to the token
  // /close route when the page goes away, so closing the tab stops that
  // token\'s server. "close" is relative -- it resolves against the page URL
  // (loopback 127.0.0.1:PORT/<token>/) to .../<token>/close (same-origin, same
  // token, no absolute URL, no external reference -- WEB-03). Use pagehide,
  // not the deprecated/unreliable unload event, with a visibilitychange
  // backstop. The finalizer and gmw_close() remain the guarantees, so a
  // missed beacon never orphans past session end.
  function gmwClose(){ try { navigator.sendBeacon("close"); } catch(e){} }
  window.addEventListener("pagehide", gmwClose);
  document.addEventListener("visibilitychange", function(){
    if (document.visibilityState === "hidden") gmwClose();
  });
```

→ Pointer→raycast handler (RESEARCH Pattern 1): compute NDC from
`canvas.getBoundingClientRect()` (single Y-flip), `raycaster.setFromCamera(ndc,
camera)`, `intersectObject(mesh, false)`, then `mesh.updateWorldMatrix(true,
false)` + `worldToLocal(p)` before `navigator.sendBeacon("pick", p.x+","+p.y+","+p.z)`.
`intersectObject(mesh, false)` (non-recursive) avoids also hitting overlay dots.

**Framing-vs-replay caveat (Anti-Pattern):** `frameScene()` at `view3d.R:173-180`
does `group.position.sub(sphere.center)` — the interactive path is recentered.
The **PICK-03 replay path must use the raw PLY-vertex frame** (mesh at identity,
no group offset) or every hit is offset by `sphere.center`. Keep the replay hook
distinct from the interactive framing.

```173:180:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
  function frameScene(){
    var box = new THREE.Box3().setFromObject(group);
    var sphere = box.getBoundingSphere(new THREE.Sphere());
    var home = sphere.radius > 0 ? sphere.radius : 1;
    dist = home / Math.sin((camera.fov * Math.PI / 180) / 2) * 1.15;
    group.position.sub(sphere.center);
    reset();
  }
```

**Overlay dot (PICK-02):** RESEARCH Pattern 4 — a dedicated `THREE.Group`
(`scene.add(overlay)`) holding a small `SphereGeometry` mesh with
`MeshBasicMaterial({depthTest:true})`; size scale-relative to the hoisted `dist`
(`view3d.R:159`). Placeholder-appearance + miss-is-no-op are Claude's discretion.

---

### `R/parity.R` — fixture reader + gate math (utility, transform/batch) — NEW

**Analog (style only):** `R/view3d.R` pure numeric helpers — the file-scope,
side-effect-free, `@noRd` shape.

```23:33:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
# Flat "[x1,y1,z1,x2,...]" from a p x k numeric matrix, row-major.
.gmw_flat <- function(m, digits = 6) {
  m <- as.matrix(m)
  v <- as.vector(t(m))
  v[!is.finite(v)] <- 0
  paste0("[", paste(formatC(v, format = "f", digits = digits), collapse = ","), "]")
}

# Flat 0-based index array from a 3 x f face matrix (Rvcg/mesh3d $it is 1-based).
.gmw_faces <- function(it) {
  paste0("[", paste(as.integer(as.vector(it)) - 1L, collapse = ","), "]")
}
```

**Core math — net-new, take verbatim from RESEARCH Code Examples** (no code
analog exists in-repo): `mean_edge_length(m)` (Rvcg `$vb`/`$it`), `parity_gate(browser_xyz,
native_xyz, mean_edge)` (`stats::quantile(d, 0.95)`), `read_pick_poses(path)`
(`utils::read.table(sep="\t", comment.char="#")` — base R, NO JSON dependency,
per `view3d.R:13-15` header). Gate: `p95 <= 1 * mean_edge` (D-02).

**Conventions to honor** (`.cursor/rules`, RESEARCH Project Constraints):
`dot.separated` naming for file-I/O/module helpers; `dbg()` gated printer, no raw
`print`; keep exports minimal (`@noRd`/`@keywords internal`).

---

### `tests/fixtures/parity/B7_1_pick_poses.tsv` — placeholder fixture (config, file-I/O) — NEW

**Analog:** co-located `tests/fixtures/parity/B12_1_clean.ply` / `B7_1_clean.ply`
(same dir). No content analog — the **schema is the drop-in contract** from
RESEARCH "Pose-Record Schema": header comment line (`# specimen=... sha256=...
engine_commit=... captured=...`) + fixed column order
`commit mv00..mv15 pj00..pj15 vp0..vp3 px py winz objx objy objz`. Populate now
with self-consistent synthetic rows (browser-raycast a few poses, write the hit
as `objXYZ`) so distance≈0 and the harness runs green (RESEARCH Pattern 5). MUST
be byte-schema-identical to the eventual Windows capture (D-07).

---

### `tests/testthat/test-picking-parity.R` — harness (test) — NEW

Three distinct analog idioms combine in this one file:

**(a) Handler unit test — copy `test-transport.R:172-201`** (invoke the `call`
closure directly with a synthetic `req`; do NOT use same-process curl):

```183:200:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport.R
  handler <- .gmw_close_handler(s$token)

  resp <- handler(list(PATH_INFO = paste0("/", s$token, "/close")))
  expect_equal(resp$status, 204L)
  # 204 returned first; the stop is deferred, not synchronous (Pitfall 2).
  expect_true(s$token %in% ls(.gmw_server))
  ...
  # Any non-close path is a plain 404 (never a filesystem read of the path).
  miss <- handler(list(PATH_INFO = paste0("/", s$token, "/other")))
  expect_equal(miss$status, 404L)
```

→ For the pick route, build `req` with `PATH_INFO = ".../pick"` and a
`rook.input$read()` stub returning the raw `"x,y,z"` body; assert the matrix
landed in `.gmw_picks[[token]]` and that a malformed body is dropped.

**(b) Skip-if-native-source-absent — copy `test-retina-picking-parity.R:6-17`**
(the D-07 skip idiom: the real Windows fixture may be absent → skip, never fail):

```6:22:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-retina-picking-parity.R
native_src <- function(file) {
  candidates <- c(
    file.path(pkg_root, "src", "tkogl2", "src", file),
    file.path(pkg_root, "..", "tkogl2", "src", file)
  )
  hit <- candidates[file.exists(candidates)]
  if (length(hit)) normalizePath(hit[1]) else NA_character_
}

test_that("macOS backend uses backing viewport for Retina parity", {
  backend_file <- native_src("gfx_backend_nsgl.m")
  skip_if(is.na(backend_file), "tkogl2 native source not available")
  src <- readLines(backend_file, warn = FALSE)
```

→ Mirror for the *real* pose fixture: `skip_if(<real fixture absent>, ...)` so
PICK-03 skips cleanly on the placeholder; the same test body computes real
distances when the real TSV is dropped in (zero code change, D-07).

**(c) Source-scan (template wiring) — copy `test-view3d-beacon.R:9-30` +
`helper-pkg-source.R`** (grep the emitted `view3d.R`/template for
`computeBoundsTree`, `setFromCamera`, overlay `depthTest`; confirm the pick
target is relative `"pick"`, never `sendBeacon("http`):

```9:22:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-view3d-beacon.R
test_that("the viewport page fires a same-origin tab-close beacon", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  # The reliable-event beacon hook is present.
  expect_true(any(grepl("sendBeacon", src, fixed = TRUE)))
  expect_true(any(grepl("pagehide", src, fixed = TRUE)))
  expect_true(any(grepl("visibilitychange", src, fixed = TRUE)))
```

**CMP-01 test — reuse the engine-load assertion shape** (`test-transport.R:121-133`
already scans that `transport.R` never touches `.gmw_engine`; add a positive
`.gmw_engine$ok` skip-if-absent check mirroring `rtkogl.R:498-511`).

---

## Shared Patterns

### Token-guarded, loopback, no-path-join (all new server code)
**Source:** `R/transport.R:16-21` (loopback bind), `:128-137` (pattern-match
path only), `test-transport.R:66-71` (the enforced invariant).
**Apply to:** the `/pick` handler. Only ever pattern-match `/pick$`; never
`file.path`/`normalizePath`/`readBin` on `req$PATH_INFO` (T-2-02).

```66:71:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport.R
  reqpath_lines <- grep("PATH_INFO", src, fixed = TRUE, value = TRUE)
  joins_fs <- vapply(reqpath_lines, function(ln) {
    any(vapply(c("file.path", "normalizePath", "readBin"),
               function(fn) grepl(fn, ln, fixed = TRUE), logical(1)))
  }, logical(1))
  expect_false(any(joins_fs))
```

### Skip-if-source-absent (all tests touching native src / real fixture / pkg source)
**Sources:** `test-retina-picking-parity.R:6-17` (native src), `helper-pkg-source.R:11-21`
(pkg R/ source under R CMD check), `test-transport.R:6` (`skip_if_no_pkg_source()`).
**Apply to:** every `test-picking-parity.R` block that reads native source, the
real Windows fixture, or the package R/ tree.

```11:21:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/helper-pkg-source.R
pkg_source_root <- function() {
  root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)
  if (dir.exists(file.path(root, "R"))) root else NA_character_
}

skip_if_no_pkg_source <- function() {
  testthat::skip_if(
    is.na(pkg_source_root()),
    "package R/ source not available (R CMD check installs a lazy-load database)"
  )
}
```

### Dependency-free numeric transport (fixture + POST body)
**Source:** `R/view3d.R:13-15` header (no JSON dep by policy); `.gmw_flat`
(`view3d.R:23-28`).
**Apply to:** `R/parity.R` reader (`read.table` TSV) and the `/pick` body parse
(`strsplit(body, ",")`). Base R only — no `jsonlite`.

### Gated debug printer + minimal exports
**Source:** `R/transport.R:36-38` (`dbg` fallback guard); `gmw_close`
(`transport.R:295-296`) export shape; `.plot_show` delivery (`rtkogl.R:923-934`).
**Apply to:** all new R. Use `dbg()` not `print`; `@noRd`/`@keywords internal`
unless a genuine user entry point is needed.

```36:38:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
if (!exists("dbg", mode = "function")) {
  dbg <- function(...) if (isTRUE(getOption("guimorph.debug", FALSE))) print(...)
}
```

---

## No Analog Found

| File / Element | Role | Data Flow | Reason (planner uses RESEARCH, not an analog) |
|----------------|------|-----------|----------------------------------------------|
| Coordinate math in `R/parity.R` (`mean_edge_length`, `parity_gate`) | utility | transform | No parity/geometry math exists in-repo; take verbatim from RESEARCH "Code Examples". |
| Record-replay JS (bake modelview on camera, mesh at identity) in `view3d.R` | component | transform | No replay/raycast harness exists yet; RESEARCH Pattern 2 is the spec. `matrixAutoUpdate=false` + `fromArray` (no transpose) is net-new to this template. |
| `B7_1_pick_poses.tsv` column schema | config | file-I/O | No pose fixture exists; RESEARCH "Pose-Record Schema" table is the drop-in contract (D-05/D-07). |

---

## Metadata

**Analog search scope:** `R/` (transport.R, view3d.R, rtkogl.R), `tests/testthat/`
(test-transport.R, test-retina-picking-parity.R, test-view3d-beacon.R,
helper-transport.R, helper-pkg-source.R), `tests/fixtures/parity/`.
**Files scanned:** 10 (2 modified targets read in full; 5 analog tests/helpers; rtkogl.R targeted reads).
**Pattern extraction date:** 2026-08-05

---

## PATTERN MAPPING COMPLETE

**Phase:** 4 - picking-parity
**Files classified:** 5 (+1 optional R accessor)
**Analogs found:** 5 / 5 (wiring); 3 elements net-new (math + JS replay + TSV schema — sourced from RESEARCH)

### Coverage
- Files with exact analog: 3 (`transport.R`, `view3d.R`, `test-picking-parity.R`)
- Files with role-match analog: 2 (`parity.R` style, optional accessor)
- Files with no analog (net-new elements only): 3 (parity math, replay JS, TSV schema)

### Key Patterns Identified
- The pick route is a **second `excludeStaticPath` subpath** on the existing mixed httpuv app; the `/pick` handler subsumes `/close`, closes over its own token, and NEVER joins `PATH_INFO` to the filesystem (T-2-02, enforced by `test-transport.R`).
- The browser side extends `GMW_VIEW3D_TEMPLATE` in place: `computeBoundsTree()` eager in the PLYLoader callback, a pointer→`setFromCamera`→`intersectObject` handler, a relative-URL `sendBeacon("pick", ...)` mirroring the `/close` beacon, and an overlay `THREE.Group`.
- All new tests reuse three existing idioms: direct-handler-invocation (`test-transport.R`), skip-if-absent (`test-retina-picking-parity.R` + `helper-pkg-source.R`), and template source-scan (`test-view3d-beacon.R`).
- Net-new pieces (parity gate math, record-replay JS, TSV pose schema) have no code analog and come verbatim from RESEARCH; dependency-free base-R I/O is a hard project convention.

### File Created
`.planning/phases/04-picking-parity/04-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can reference the analog files and line ranges above directly in each plan's action section.
