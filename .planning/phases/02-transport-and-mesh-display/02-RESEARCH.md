# Phase 2: Transport and Mesh Display - Research

**Researched:** 2026-07-31
**Domain:** Local HTTP transport of large PLY meshes (R `httpuv`) + browser mesh rendering (three.js `PLYLoader`)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** One specimen per viewport. The Phase 2 R entry point takes a single PLY path (or mesh), serves it on one guarded endpoint, and renders it.
- **D-02:** No in-page specimen picker. Multi-specimen switching stays in Phase 5 (DGT-02). Criterion 4 ("6-specimen set loads and orbits") is satisfied by loading each specimen individually, not by a switcher UI.
- **D-03:** Solid shaded surface. Reuse the existing `MeshLambertMaterial` + ambient/directional lighting already in `view3d.R`'s `GMW_VIEW3D_TEMPLATE`. Not wireframe, not points.
- **D-04:** Default mesh color `#cccccc` (gray) on `#ffffff` (white) background — matches current `view3d.R` default and inherited rgl look. `side: THREE.DoubleSide` retained.

**Fixed by ROADMAP / REQUIREMENTS / reference architecture — not re-decided here:** loopback-only bind, unprivileged port, per-session random path/token guard, PLY served as raw bytes never JSON, `httpuv::randomPort()` primary with walk-forward-from-preferred backup, server-owns-state / browser-pure-view, offline vendored bundle.

### Claude's Discretion
- Exact R entry function name/signature and endpoint route shape (planner decides, following the server-owns-state pattern).
- Whether the Phase 2 page reuses `GMW_VIEW3D_TEMPLATE` verbatim (swapping the inlined-geometry block for `fetch(url)` + `PLYLoader`) or forks a mesh-only template. Reuse is preferred if clean.
- Bounding-box / camera-framing math is already solved in the template; reuse.

### Deferred Ideas (OUT OF SCOPE)
- **In-page specimen picker / multi-specimen switcher** — Phase 5 (DGT-02).
- **Binary-PLY / Draco compression fast-path** — only if WEB-02 transfer time is unacceptable on the reference set. Default: serve ASCII bytes as-is.
- **Wireframe / point-cloud render toggle** — not needed for read-only Phase 2 display.
- **Robust teardown, port-collision error handling, browser-launch degradation** — Phase 3 (WEB-04).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WEB-01 | An `httpuv` server started from R binds to loopback on an unprivileged port and serves the PLY as bytes over HTTP, never JSON-encoded, behind a per-session random path or token | `httpuv::startServer` + `randomPort()` (loopback default, unprivileged range, browser-unsafe ports auto-excluded) + `staticPaths` (C-thread byte serving, never JSON) + random path segment and/or `staticPath(validation=)` header guard — see Standard Stack, Pattern 1, Security Domain |
| WEB-02 | three.js `PLYLoader` fetches and renders the served mesh with orbit, zoom, and reset view, on stock macOS and stock Windows, with no XQuartz/Homebrew/Tcl-Tk in render path | Vendored bundle already exports `GMW.PLYLoader`; reuse `GMW_VIEW3D_TEMPLATE` orbit/zoom/`r`-reset + bounding-sphere framing; move framing into the async load callback; call `geometry.computeVertexNormals()` (see Pattern 2, Pitfalls 1 & 3) |
| CMP-01 | Retained native `tkogl2` oracle stays loadable | Adding `httpuv` to Imports does not touch `.onLoad`; native load already made non-fatal in Phase 1. Verification-only gate — see Validation Architecture |
</phase_requirements>

## Summary

Phase 2 connects two pieces that already exist. On the R side, `httpuv` (CRAN, maintained by Posit; the server engine under `shiny` and `plumber`) starts a background HTTP listener bound to loopback and serves the PLY file's raw bytes. On the browser side, the Phase 1 vendored bundle already exports `GMW.PLYLoader`, so no new JS vendoring is needed — the render page reuses `GMW_VIEW3D_TEMPLATE`, swapping its inlined-geometry block for an async `PLYLoader.load(url, …)` against the httpuv endpoint.

The single most important transport decision is to serve the mesh (and the HTML page and the JS bundle) through `httpuv`'s **`staticPaths`**, not through a `call` request handler. Static paths are served directly from `httpuv`'s libuv/C background thread without ever entering the R interpreter, so a 30 MB file streams without blocking the R session and without R needing to sit in an event loop. Serving the page itself over `http://127.0.0.1:PORT` (rather than `file://` as in Phase 1) makes the `PLYLoader` fetch same-origin, avoiding CORS entirely. The per-session guard is a high-entropy random URL path segment (satisfying "random path or token"), optionally hardened with `staticPath(validation=)` header matching.

On the render side, three failure modes dominate and all have known fixes: (1) the reference PLYs carry **no vertex normals**, so `geometry.computeVertexNormals()` must be called in the load callback or `MeshLambertMaterial` renders solid black; (2) camera framing (bounding sphere) must move **into the async callback**, because the geometry does not exist when the page first runs; (3) the page must be **same-origin** with the mesh. Transfer performance over loopback is a non-issue — the real cost is JS-side ASCII parse of ~363k vertices, which is acceptable; keep the "serve ASCII as-is" default and defer binary-PLY/Draco.

**Primary recommendation:** R starts an `httpuv` server on `127.0.0.1:randomPort()`, mounts the temp dir (index.html + `guimorphweb-three.js` + specimen.ply) under a random path via `staticPaths`, retains the server handle so it is not garbage-collected, prints and `browseURL()`s `http://127.0.0.1:PORT/<token>/`; the browser page reuses the Phase 1 template with `PLYLoader.load` + `computeVertexNormals()` + deferred bounding-sphere framing.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Start/own HTTP listener, port selection, token | API/Backend (R + `httpuv`) | — | Server owns state (REFERENCE-ARCHITECTURE); R already owns the specimen path |
| Serve PLY bytes (+ page + bundle) | CDN/Static analog (`httpuv` `staticPaths`, libuv C thread) | — | Byte serving off the R thread; never JSON-encode the mesh |
| Loopback bind + random-path/token guard | API/Backend (R) | — | Access control belongs at the server boundary, not the browser |
| Fetch mesh over HTTP | Browser/Client (three.js `FileLoader` via `PLYLoader`) | — | Browser is the pure view; fetches what the server exposes |
| Parse PLY → BufferGeometry | Browser/Client (`PLYLoader`) | — | Handles ASCII/binary, endianness, indices, colors |
| Compute normals, material, lighting | Browser/Client | — | Render concern; geometry has no normals on disk |
| Camera framing, orbit, zoom, reset | Browser/Client (`OrbitControls` + Box3/Sphere) | — | Interaction is view-layer; math already solved in template |
| Keep server alive / teardown | API/Backend (R) | — | Minimal retain-reference here; robust teardown is WEB-04/Phase 3 |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `httpuv` | 1.6.16 (CRAN, 2025-04-16) / 1.6.17 (current refman) | Loopback HTTP server; `startServer`, `randomPort`, `staticPaths`, `staticPath`, `stopServer` | The R HTTP primitive; engine under `shiny`/`plumber`; libuv + http-parser in C. Posit-maintained. `[CITED: rstudio.github.io/httpuv]` |
| three.js `PLYLoader` | r0.185.1 (already vendored, Phase 1) | Fetch + parse PLY (ASCII & binary) into `BufferGeometry` | Official three.js addon; auto-detects format, handles indices/colors. Already in the bundle (`GMW.PLYLoader`). `[VERIFIED: VENDOR-MANIFEST.json exports]` |
| three.js core + `OrbitControls` | r0.185.1 (vendored) | Scene, camera, orbit/zoom, reset | Phase 1 foundation (`GMW_VIEW3D_TEMPLATE`). `[VERIFIED: view3d.R]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `later` / `promises` / `R6` / `Rcpp` | (transitive of `httpuv`) | httpuv's own scheduler/deps | Pulled automatically; add via `renv::snapshot()` |
| `curl` | (Suggests only, tests) | GET the served file in a test to assert byte-identity | Wave 0 transport test (alternative: base `url()`/`readBin`) |
| `openssl` **or** `sodium` | latest | CSPRNG token for the guard path | Only if a cryptographic token is preferred over the base-R fallback (see Security Domain) — flag for user |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `httpuv` `staticPaths` | `httpuv` `call` handler reading the file into `body` | `call` runs on the R main thread via `later::later` (only when R is idle or `service()` is pumped) and forces you to hand-build a file path from `PATH_INFO` — a path-traversal risk. `staticPaths` serves off the C thread and resolves paths safely. **Use `staticPaths`.** |
| Page served over `http://` | Page on `file://` + CORS header on the PLY | `file://`→`http://` fetch is cross-origin (origin `null`); needs `Access-Control-Allow-Origin` and is more fragile. Same-origin http is clean. **Serve the page over http.** |
| `httpuv::randomPort()` | Manual `bind(host, 0)` loop | `randomPort()` already picks an unprivileged, browser-safe, free port on loopback and excludes ports browsers block. **Use it as primary; walk-forward-from-preferred is the documented backup.** |
| ASCII PLY as-is | Binary PLY / Draco | Loopback transfer is sub-second; parse dominates and is acceptable. Deferred by CONTEXT unless proven unacceptable. |

**Installation:**
```r
# Add to DESCRIPTION Imports, then:
install.packages("httpuv")
renv::snapshot()   # httpuv is NOT yet in renv.lock — this phase adds it
```

**Version verification:** `httpuv` latest is **1.6.16** on the CRAN package page (published 2025-04-16) and **1.6.17** in the current reference manual. `[CITED: cran.r-project.org/package=httpuv]` `[CITED: cran.r-project.org/web/packages/httpuv/refman/httpuv.html]`. Not currently a locked package in `renv.lock` (only referenced as a transitive Import of other packages), so it must be installed and snapshotted. `[VERIFIED: grep "\"Package\": \"httpuv\"" renv.lock → no match]`

## Package Legitimacy Audit

> No **npm** packages are installed this phase — the browser bundle was vendored in Phase 1 (WEB-00) and is committed. The only new dependency is the CRAN package `httpuv`.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `httpuv` | CRAN | ~10+ yrs (first release 2013) | Millions/mo (shiny/plumber dependency) | github.com/rstudio/httpuv | OK | Approved — add to Imports + `renv::snapshot()` |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*The npm `package-legitimacy check` seam targets npm/PyPI/crates and does not cover CRAN; `httpuv` is verified instead via CRAN authorship (Posit/RStudio), long history, and its role as the transport layer under `shiny`. `[CITED: rstudio.github.io/httpuv]`*

## Architecture Patterns

### System Architecture Diagram

```text
  R session (server owns state)
  ┌──────────────────────────────────────────────────────────────┐
  │  .gmw_serve_mesh(ply_path)                                     │
  │    1. token   <- random high-entropy string                   │
  │    2. tmpdir  <- copy(index.html, guimorphweb-three.js,        │
  │                        specimen.ply)                           │
  │    3. port    <- httpuv::randomPort()          # 127.0.0.1     │
  │    4. server  <- startServer("127.0.0.1", port, app=list(     │
  │                     staticPaths = list(                        │
  │                       "/<token>" = staticPath(tmpdir, ...))))  │
  │    5. retain server handle (package env)  # avoid GC finalizer │
  │    6. url <- http://127.0.0.1:PORT/<token>/                    │
  │    7. message(url); browseURL(url)                             │
  └───────────────┬───────────────────────────────┬──────────────┘
        libuv/C thread serves bytes        R thread returns, stays interactive
                  │  (no JSON, no R interp)
                  ▼
  Browser (pure view)  —  same origin http://127.0.0.1:PORT/<token>/
  ┌──────────────────────────────────────────────────────────────┐
  │  index.html loads guimorphweb-three.js (GMW global)            │
  │    scene/camera/lights/OrbitControls  (from GMW_VIEW3D_TEMPLATE)│
  │    GMW.PLYLoader.load("specimen.ply",                          │
  │       onLoad(geometry):                                        │
  │          geometry.computeVertexNormals()   # else black mesh   │
  │          mesh = Mesh(geometry, MeshLambertMaterial(            │
  │                   {color:'#cccccc', side:DoubleSide}))         │
  │          group.add(mesh)                                       │
  │          frameScene()   # Box3→Sphere, DEFERRED to here        │
  │       onProgress(e): show %  (30 MB worst case)                │
  │       onError(e): surface message                             │
  │    orbit / scroll zoom / 'r' reset                             │
  └──────────────────────────────────────────────────────────────┘
```

Trace of the primary use case: R copies the mesh + page + bundle into a temp dir, opens a loopback listener, and browses to a token-scoped URL; the browser fetches `specimen.ply` from the same origin, `PLYLoader` parses it, normals are computed, the Lambert mesh is added, and the camera frames the bounding sphere.

### Recommended Project Structure
```
integrated-guimorph-development_EOC/Project/GUImorphDevelopment/
├── R/
│   ├── view3d.R          # existing: GMW_VIEW3D_TEMPLATE, .gmw_view3d(), .gmw_bundle_path()
│   └── transport.R       # NEW (name at planner discretion): .gmw_serve_mesh() + port/token helpers
├── inst/htmlwidgets/
│   └── guimorphweb-three.js   # existing vendored bundle (exports GMW.PLYLoader) — reused as-is
├── DESCRIPTION           # add httpuv to Imports
└── tests/testthat/
    └── test-transport.R  # NEW: port selection, byte-integrity, guard
```

### Pattern 1: httpuv static serving on loopback with a guard (WEB-01)
**What:** Start a background loopback listener; serve the temp dir (page + bundle + mesh) under a random path; keep the handle alive.
**When to use:** The transport core of this phase.
**Example:**
```r
# Source: https://rstudio.github.io/httpuv/reference/startServer.html
#         https://rstudio.github.io/httpuv/reference/randomPort.html
port  <- httpuv::randomPort()                 # 127.0.0.1, unprivileged, browser-safe, free
token <- .gmw_token()                          # high-entropy; see Security Domain
server <- httpuv::startServer(
  host = "127.0.0.1", port = port,
  app = list(
    staticPaths = stats::setNames(
      list(httpuv::staticPath(
        tmpdir,
        # optional hardening: require a matching header (403 otherwise)
        # validation = sprintf('"x-gmw-token" = "%s"', token)
      )),
      paste0("/", token)
    )
  )
)
# CRITICAL: retain `server` (e.g. in a package environment) or its finalizer stops it on GC.
url <- sprintf("http://127.0.0.1:%d/%s/", port, token)
message("Viewport: ", url)
utils::browseURL(url)
```
Notes: `staticPaths` are served "without invoking `call()`" directly off the background thread — no JSON, no R-thread block. `[CITED: rstudio.github.io/httpuv reference/startServer]`. `randomPort(min=1024, max=49151, host="127.0.0.1")` "automatically excludes some ports which are considered unsafe by web browsers." `[CITED: httpuv refman]`

### Pattern 2: PLYLoader render, reusing the Phase 1 template (WEB-02)
**What:** Swap the inlined-geometry block of `GMW_VIEW3D_TEMPLATE` for an async `PLYLoader.load`, compute normals, and defer camera framing into the callback.
**When to use:** The render core of this phase.
**Example:**
```javascript
// Source: https://github.com/mrdoob/three.js/blob/master/examples/webgl_loader_ply.html
var loader = new GMW.PLYLoader();
loader.load("specimen.ply", function (geometry) {
  geometry.computeVertexNormals();                 // no normals on disk -> required for Lambert
  var mesh = new THREE.Mesh(geometry, new THREE.MeshLambertMaterial({
    color: "#cccccc", side: THREE.DoubleSide       // vertexColors left FALSE (ignore scan RGB)
  }));
  group.add(mesh);
  frameScene();                                    // Box3 -> Sphere framing, DEFERRED to here
}, function (e) { /* onProgress: e.loaded / e.total for the 30 MB case */ },
   function (e) { /* onError: surface a legible message */ });
```
The existing bounding-sphere framing math (`view3d.R:146-149`) is reused verbatim inside `frameScene()`; the only change is that it runs after load, not synchronously.

### Anti-Patterns to Avoid
- **Serving the mesh through a `call` handler that reads the file and returns it in `body`:** blocks the R thread, requires pumping `service()`, and invites path traversal when building the path from `PATH_INFO`. Use `staticPaths`.
- **JSON-encoding vertices/faces through R→JS:** explicitly forbidden by WEB-01 and the mesh-size risk note. The mesh crosses the boundary only as PLY bytes.
- **Computing the bounding box before the loader callback:** geometry is absent; `Box3.setFromObject` yields an empty/NaN box and the camera lands at the origin on a blank canvas.
- **Opening the page on `file://` while fetching `http://` mesh:** cross-origin; blocked.
- **Enabling `vertexColors: true`:** would paint NextEngine scan RGB instead of the decided `#cccccc`.
- **Binding `0.0.0.0`:** exposes the specimen to the LAN. Bind `127.0.0.1`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Local HTTP server | Raw socket listener | `httpuv::startServer` | libuv/C, battle-tested under shiny |
| Static file serving | `call` handler that reads files | `httpuv` `staticPaths` | Off-thread, safe path resolution, correct headers |
| Free-port selection | Manual `bind(0)` retry loop | `httpuv::randomPort()` | Loopback + unprivileged + browser-safe + free, in one call |
| PLY parsing | Hand parser (R or JS) | three.js `PLYLoader` | ASCII+binary, endianness, indices, colors |
| Content-Type / byte streaming | Manual MIME + chunking | `httpuv` static serving | Handled; `PLYLoader` is content-type agnostic anyway |
| Camera auto-fit | Custom projection math | `Box3`+`Sphere` (already in template) | Solved in `GMW_VIEW3D_TEMPLATE` |
| Guard token randomness | `sample()`-only ad-hoc string | CSPRNG (`openssl`/`sodium`) or documented base-R fallback | Predictable RNG weakens the guard (see Security Domain) |

**Key insight:** Every hard part of this phase already has a blessed implementation — `httpuv` on the R side and the Phase 1 bundle on the browser side. The work is wiring, ordering (async framing), and the guard, not new machinery.

## Common Pitfalls

### Pitfall 1: Black mesh — missing vertex normals
**What goes wrong:** The mesh renders solid black under `MeshLambertMaterial`.
**Why it happens:** The reference PLYs declare only `x,y,z` + `red,green,blue` — **no `nx,ny,nz`** (`[VERIFIED: B12_1_clean.ply header]`). `MeshLambertMaterial` needs normals for lighting.
**How to avoid:** Call `geometry.computeVertexNormals()` in the load callback (the three.js PLY example does exactly this). `[CITED: three.js webgl_loader_ply.html]`
**Warning signs:** Silhouette visible against background but surface uniformly black; switching to `MeshNormalMaterial` shows color.

### Pitfall 2: Server dies unexpectedly — handle garbage-collected
**What goes wrong:** The viewport loads once, then later requests fail / the port frees.
**Why it happens:** `httpuv` server objects stop on finalization; if the R return value isn't retained, GC can stop the listener.
**How to avoid:** Store the server handle in a package-level environment (or return it invisibly and keep it referenced). Robust teardown is Phase 3 (WEB-04); Phase 2 needs only "stays alive for the session."
**Warning signs:** Works immediately after the call, breaks after an unrelated `gc()` or some idle time.

### Pitfall 3: Blank canvas — framing ran before load
**What goes wrong:** Canvas paints the clear color, no mesh, camera seemingly at origin.
**Why it happens:** `PLYLoader.load` is async; the template's synchronous `Box3().setFromObject(group)` runs against an empty group.
**How to avoid:** Move all framing (`box`, `sphere`, `dist`, `group.position.sub(center)`, `reset()`) into the load callback.
**Warning signs:** Console clean, geometry present in `group.children` only after a delay.

### Pitfall 4: CORS block — page and mesh on different origins
**What goes wrong:** `PLYLoader` fetch fails with a CORS error.
**Why it happens:** Page opened from `file://` fetching `http://127.0.0.1:PORT/...`.
**How to avoid:** Serve `index.html` (and the bundle) over the same `httpuv` origin; `browseURL` the http URL. Same-origin, no CORS.
**Warning signs:** DevTools network tab shows the PLY request blocked by CORS policy; origin `null`.

### Pitfall 5: Mis-framed camera from stray/origin-null vertices
**What goes wrong:** Camera pulls too far back or centers oddly.
**Why it happens:** NextEngine exports carry unreferenced stray verts, including `(0,0,0)`, which inflate the bounding box (ROADMAP + PROJECT lessons).
**How to avoid:** The committed reference set is **already cleaned** (`comment cleaned: unreferenced/stray vertices removed` in each header — `[VERIFIED: B12 header]`), so Phase 2's set won't exhibit it. Treat as a **verification concern**: confirm framing is tight on all 6 specimens; document that raw (uncleaned) files would need cleaning upstream. Do not add cleaning logic to the browser loader.
**Warning signs:** A visible gap between the specimen and the framed view; bounding sphere radius much larger than the specimen.

### Pitfall 6: Parse jank on the main thread (informational)
**What goes wrong:** Brief UI freeze while parsing ~363k ASCII verts (B7).
**Why it happens:** `PLYLoader` parses on the main thread; loopback transfer itself is negligible.
**How to avoid:** Acceptable for read-only display; show `onProgress`. Keep ASCII default; binary-PLY/Draco is deferred unless proven unacceptable.
**Warning signs:** Sub-second stall on the largest file only.

## Code Examples

### Byte-integrity check (test): served bytes == file on disk, not JSON
```r
# Source: httpuv startServer/randomPort docs; curl for the client GET
srv <- httpuv::startServer("127.0.0.1", httpuv::randomPort(),
  list(staticPaths = list("/m" = dirname(ply_path))))
on.exit(httpuv::stopServer(srv), add = TRUE)
url  <- sprintf("http://127.0.0.1:%d/m/%s", srv$getPort(), basename(ply_path))
got  <- curl::curl_fetch_memory(url)$content        # raw bytes
disk <- readBin(ply_path, "raw", file.info(ply_path)$size)
testthat::expect_identical(got, disk)               # byte-identical, never JSON
```

### Port-selection fallback (test, no binding) — REFERENCE-ARCHITECTURE technique
```r
# Inject the port-probe; assert randomPort primary, walk-forward backup, without binding.
pick_port <- function(prefer = NULL, probe = .gmw_probe_free) { ... }
# probe stub returns FALSE for the preferred port, TRUE for prefer+1
testthat::expect_equal(pick_port(prefer = 8080, probe = stub), 8081L)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| three.js UMD build usable directly | ES-modules-only from r0.160 | 2023 | Bundle exists (Phase 1) to expose classic-script `GMW`; unchanged here |
| `THREE.Geometry` + `computeFaceNormals` | `BufferGeometry` + `computeVertexNormals` | r0.125+ | `PLYLoader` returns `BufferGeometry`; call `computeVertexNormals` |
| `httpuv` `call`-only serving | `staticPaths` (off-thread static serving) | httpuv 1.4+ | Enables non-blocking large-file serving from R |

**Deprecated/outdated:**
- `geometry.computeFaceNormals()` on a legacy `Geometry` — not applicable; `PLYLoader` yields `BufferGeometry`.

## Runtime State Inventory

*Not applicable — Phase 2 is additive (new server + render page), not a rename/refactor/migration. No stored keys, service configs, OS registrations, secrets, or build artifacts embed a renamed string. (Verified: the only dependency change is adding `httpuv` to Imports/renv.lock.)*

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A high-entropy random URL path segment is sufficient to satisfy "another process on the same host cannot enumerate and read specimen files" for ASVS L1, without a cryptographic RNG | Security Domain | If a stronger token is required, use `openssl::rand_bytes`; otherwise residual risk is a same-user local process guessing a base-R `sample()` token (mitigated by ≥128-bit length + loopback + temp-dir filesystem perms) |
| A2 | Loopback transfer of the 30 MB `B7_1_clean.ply` is fast enough that binary-PLY/Draco stays deferred | Summary / Stack | If parse+transfer is unacceptable on the reference set, revisit binary PLY per REQUIREMENTS v2/Deferred |
| A3 | Serving the HTML page over http (not file://) is acceptable as a delivery-shape change from Phase 1 | Architecture Patterns | CONTEXT grants discretion on template/route shape; if the user wants file:// retained, add an ACAO header on the PLY instead |
| A4 | `httpuv` `staticPaths` sets an adequate `Content-Type` for `.ply` (and `PLYLoader` is content-type agnostic regardless) | Don't Hand-Roll | Low — `PLYLoader` reads bytes/text and auto-detects format |

**If a claim here becomes load-bearing, confirm with the user before locking it in a plan.**

## Open Questions (RESOLVED)

1. **Token strength: base-R vs. crypto dep?**
   - What we know: The guard's purpose is to stop trivial same-host enumeration of the HTTP endpoint; the temp file is already protected by user-level filesystem permissions.
   - What's unclear: Whether the user wants a cryptographic token (adds `openssl`/`sodium`) or accepts a documented base-R fallback.
   - Recommendation: Default to a ≥128-bit token; prefer `openssl::rand_bytes` if a crypto dep is acceptable. Flag in the plan as `checkpoint:human-verify` only if a crypto dep would be added.
   - **— RESOLVED:** Plan 02-02 Task 2 adopts the base-R ≥128-bit path token (`.gmw_token`, ≥32 hex/base62 chars via `sample()`) with a documented residual-risk note; no `openssl`/`sodium` dependency and no decision checkpoint. Cryptographic RNG deferred (T-2-04, disposition `mitigate` via ≥128-bit length + loopback + temp-dir filesystem perms).

2. **Reuse `GMW_VIEW3D_TEMPLATE` verbatim vs. fork a mesh-only template?**
   - What we know: CONTEXT prefers reuse if clean; the only real change is async load + deferred framing.
   - What's unclear: Whether the point-cloud path should stay in the same template.
   - Recommendation: Parametrize the existing template (mesh-from-URL branch) rather than duplicating; planner's call.
   - **— RESOLVED:** Plan 02-01 parametrizes the existing `GMW_VIEW3D_TEMPLATE` (mesh-from-URL branch via `.gmw_view3d_html(mesh_url=...)`) rather than forking a mesh-only template; 02-02 calls it with `mesh_url = "specimen.ply"`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `httpuv` | WEB-01 transport | ✗ (not in renv.lock) | 1.6.16/1.6.17 target | None — must `install.packages("httpuv")` + `renv::snapshot()` |
| three.js bundle (`GMW.PLYLoader`) | WEB-02 render | ✓ (Phase 1) | three 0.185.1 | — |
| R | both | ✓ | 4.6.1 (renv) | — |
| Default web browser | WEB-02 | ✓ (assumed) | — | Print URL (REFERENCE-ARCHITECTURE); robust degradation is WEB-04/Phase 3 |
| Node.js | — | not needed at runtime | — | Bundle is committed; only needed to re-vendor |

**Missing dependencies with no fallback:**
- `httpuv` — blocking for WEB-01. Planner must include an install + `renv::snapshot()` + DESCRIPTION-Imports task.

**Missing dependencies with fallback:**
- None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `testthat` (edition 3) |
| Config file | `tests/testthat.R` + per-file `tests/testthat/test-*.R` |
| Quick run command | `R -q -e 'devtools::test(filter="transport")'` |
| Full suite command | `R -q -e 'devtools::test()'` (or `R CMD check`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WEB-01 | Server binds loopback + unprivileged port | unit | `devtools::test(filter="transport")` (assert host `127.0.0.1`, port in 1024–49151) | ❌ Wave 0 |
| WEB-01 | Served bytes are byte-identical to the file, not JSON | integration | as above (start server, GET via `curl`, `expect_identical` vs `readBin`) | ❌ Wave 0 |
| WEB-01 | Guard: wrong/absent token → not served (403/404) | integration | as above (GET without token path/header) | ❌ Wave 0 |
| WEB-01 | Port fallback order (randomPort primary, walk-forward backup) | unit | inject probe stub, assert order without binding | ❌ Wave 0 |
| WEB-02 | 6 specimens load, orbit/zoom/reset render correctly | manual UAT | browser, both OSes (no automated WebGL harness) | manual |
| WEB-02 | Camera framing tight; no stray-vertex inflation | manual UAT | visual check on all 6 | manual |
| CMP-01 | Native `tkogl2` still loads; `library()` succeeds | smoke | `R -q -e 'library(GUImorphWeb)'` after adding httpuv | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `devtools::test(filter="transport")`
- **Per wave merge:** `devtools::test()`
- **Phase gate:** transport suite green + manual WEB-02 UAT on macOS and Windows before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `tests/testthat/test-transport.R` — covers WEB-01 (bind, byte-integrity, guard, port fallback)
- [ ] `tests/testthat/helper-transport.R` (optional) — start/stop server helper, probe stub for port fallback
- [ ] `httpuv` install + `renv::snapshot()` + DESCRIPTION Imports — prerequisite for any transport test
- [ ] Note: 6 pre-existing red tests are unrelated to Phase 2 (deleted-function calls + `assignInNamespace` under R 4.6); do not conflate with new transport tests.

## Security Domain

**ASVS Level 1; `security_enforcement: true`.** Threat surface: a local loopback HTTP server exposing specimen files to any process on the same host.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1/V4 Access Control | yes | Bind `127.0.0.1` only (no LAN); per-session random path/token; optional `staticPath(validation=)` header match |
| V5 Input Validation | yes | Use `staticPaths` (safe path resolution) — do not build file paths from `PATH_INFO`; prevents `../` traversal |
| V2 Authentication | partial | Bearer-style token guard (random path / header), not user auth |
| V6 Cryptography | conditional | Token generation — prefer a CSPRNG (`openssl`/`sodium`); never hand-roll crypto |
| V9 Communications | no | Loopback only; TLS not applicable for `127.0.0.1` |
| V3 Session Management | no | No sessions/cookies in Phase 2 |

### Known Threat Patterns for R httpuv loopback + browser

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Another local process enumerates the port and reads specimens | Information Disclosure | Loopback bind + high-entropy random path/token; short-lived per-session server |
| Path traversal (`GET /../../secret`) | Tampering / Info Disclosure | Serve via `staticPaths` (resolves within the mounted dir); never join paths from `PATH_INFO` in a `call` handler |
| LAN exposure by binding all interfaces | Info Disclosure | Explicit `host = "127.0.0.1"` (never `0.0.0.0`) |
| Predictable token from a weak RNG | Spoofing | ≥128-bit token from a CSPRNG; documented base-R fallback with residual risk noted (A1) |
| Orphaned listener / port leak | Denial of Service | Retain handle now; robust teardown is WEB-04/Phase 3 (out of scope, but note the finalizer-GC pitfall) |

## Sources

### Primary (HIGH confidence)
- `httpuv` reference (startServer, randomPort, staticPath, staticPathOptions, stopServer) — `https://rstudio.github.io/httpuv/` and CRAN refman `https://cran.r-project.org/web/packages/httpuv/refman/httpuv.html` — API shape, static-path threading, randomPort range/loopback/browser-safe exclusions, `validation` header guard
- three.js PLY example `https://github.com/mrdoob/three.js/blob/master/examples/webgl_loader_ply.html` — `PLYLoader.load` + `computeVertexNormals` pattern
- Codebase (VERIFIED via read/grep): `R/view3d.R` (template, framing, bundle path), `inst/htmlwidgets/VENDOR-MANIFEST.json` (PLYLoader exported, three 0.185.1), `scripts/vendor/entry.js`, `DESCRIPTION` (Imports), `tests/fixtures/parity/*.ply` (ASCII, no normals, pre-cleaned, B7=30 MB), `renv.lock` (httpuv not locked)

### Secondary (MEDIUM confidence)
- CRAN package page `https://cran.r-project.org/package=httpuv` — version 1.6.16 published 2025-04-16
- three.js community threads confirming missing-normals → black Lambert/Phong mesh (StackOverflow 28544873, 33973202)

### Tertiary (LOW confidence)
- None load-bearing.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `httpuv` API confirmed against official docs; `PLYLoader` confirmed present in the vendored bundle
- Architecture: HIGH — server-owns-state inherited from adopted REFERENCE-ARCHITECTURE; async-framing/CORS/normals ordering confirmed against three.js example
- Pitfalls: HIGH — normals, GC finalizer, async framing, and CORS are all confirmed; stray-vertex is a documented verification concern with pre-cleaned fixtures
- Security: MEDIUM-HIGH — controls are standard; token-strength choice (crypto dep vs base-R) is an open decision (A1)

**Research date:** 2026-07-31
**Valid until:** 2026-08-30 (stable stack; `httpuv` and vendored three.js are pinned)
