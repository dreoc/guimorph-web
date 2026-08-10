# Phase 4: Picking Parity - Research

**Researched:** 2026-08-05
**Domain:** Browser raycasting (three.js + three-mesh-bvh) vs. native OpenGL `gluUnProject` coordinate parity; loopback POST transport; geometric-morphometrics tolerance justification
**Confidence:** HIGH (coordinate math, stack, transport, fixture all read from source in-repo; D-03 tolerance basis cited from published literature)

## Summary

Phase 4 adds three things to an already-working mesh viewport: (1) a BVH-accelerated
pointer→raycast that hands a mesh-local hit coordinate back to R over a token-guarded POST
route (PICK-01); (2) an overlay-geometry landmark dot rendered at that coordinate with
correct depth under rotation (PICK-02); and (3) a full record-and-replay parity harness that
proves the browser hit agrees with the native `tkogl2` engine's `gluUnProject` result within a
scale-relative tolerance (PICK-03 — the milestone gate). Because native fixture capture is
Windows-only and no Windows host is available (D-06), PICK-03 is built end-to-end against a
**schema-true placeholder fixture** and left formally OPEN; dropping in the real Windows
capture must close it with zero code change (D-07).

The single make-or-break risk is coordinate-space convention (ROADMAP "expected cost" note).
The research resolves it decisively: the native engine records the **full modelview +
projection + viewport at pick time** (the transform stack is already baked into the captured
`GL_MODELVIEW_MATRIX`), so parity is not "reproduce the native transform math" — it is
"copy the native matrices verbatim into a three.js camera and cast the same pixel." Both
stacks are right-handed, column-major, and camera-looks-down-−Z, so the matrices copy with
**no transpose and no handedness flip**. The only real residual is that the native engine
unprojects a **depth-buffer-interpolated `winZ`** while the browser returns an **exact
ray–triangle intersection**; these differ only near silhouettes and steep depth gradients,
which is exactly why the gate is a 95th-percentile (not a max) and why the outlier tail is
tolerated (D-02/D-09).

**Primary recommendation:** Build the parity harness as *record-replay*: put the entire native
modelview on a three.js `PerspectiveCamera` view matrix (`matrixAutoUpdate = false`), leave the
mesh at identity so `intersection.point` is already in mesh-local (PLY-vertex) space, copy the
native `projection[16]` straight into `camera.projectionMatrix`, and raycast the exact recorded
pixel. Compare the resulting point to the recorded native object coordinate with a Euclidean
distance; gate the 95th percentile at ≤ 1 × mean inter-vertex edge length. For `B7_1_clean.ply`
that gate is ≈ **0.085 model units**, which is **~12–35× tighter** than the 1–3 mm inter-observer
digitizing error established in the literature.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Tolerance (the gate — PICK-03)**
- **D-01:** Tolerance is **scale-relative**, stated as a fraction of the specimen's **mean
  inter-vertex edge length** — not an absolute mm value. Picking cannot be more precise than
  mesh resolution, so the resolution is the natural unit.
- **D-02:** Gate value: the **95th-percentile** browser-vs-native Euclidean distance across all
  fixture click points must be **≤ 1 × mean inter-vertex edge length** (the pick lands within
  one mesh cell). 95th-percentile, not max, deliberately tolerates rare rasterization-edge
  outliers (see D-09).
- **D-03:** Justification basis: the requirement demands the tolerance be justified against
  **inter-observer digitizing error**. No project-local inter-observer number is available, so
  research cites **published geometric-morphometrics inter-observer digitizing error** and shows
  the ≤ 1-edge gate is well inside it. **User approves the final number at plan time.**

**Parity fixture**
- **D-04:** Single **dense** specimen: **`B7_1_clean.ply`** (363,283 verts, committed at
  `tests/fixtures/parity/`). Worst case, so it also stresses BVH build and transfer.
- **D-05:** **Full camera-pose record-and-replay.** The fixture records, per click: native
  **modelview + projection + viewport**, the **click pixel (x, y)** actually sampled by the
  engine, **winZ** (depth-buffer sample), the resulting native **object coordinate (x, y, z)**,
  and the **engine commit hash**. The browser drives its camera to the recorded pose and
  raycasts the same pixel — apples-to-apples, no human variance.

**Native capture is blocked (gate sequencing)**
- **D-06:** Native fixture capture runs **Windows-only** and **no Windows host is readily
  available**. PICK-03 **cannot close in this phase** — a known, tracked blocker.
- **D-07:** Sequencing: **build PICK-01, PICK-02, and the full parity harness now** (pose-record
  schema, browser camera-replay, distance / 95th-percentile comparison, mean-edge-length
  tolerance) **against a placeholder fixture**. PICK-03 stays **formally OPEN**; the real
  Windows-captured fixture must close the gate **with no code change**.

### Claude's Discretion
- **Pick round-trip transport shape** — extend the existing **mixed httpuv app** (the Phase 3
  `/close` route precedent): a **token-guarded POST route** (e.g. `/<token>/pick`). Planner
  chooses the exact route shape, payload, and the R-side receive/return API. A POST route
  matches the established pattern (WebSocket/polling were listed but rejected as heavier).
- **Landmark dot appearance + miss behavior** — planner decides dot color/size, depth behavior
  under rotation (occluded vs always-on-top), and background-click (miss) behavior. Placement-only;
  keep it minimal.
- **Placeholder fixture format + pose-record schema field layout** — planner/researcher decide,
  with the hard constraint that the schema is **identical to the real Windows capture** so the
  drop-in closes the gate without code changes.
- An interim R-side `gluUnProject` self-consistency check and a written native-capture procedure
  were offered and **not selected** — do NOT build them as deliverables.

### Deferred Ideas (OUT OF SCOPE)
- **Real native Windows fixture capture** — blocked (D-06); scheduled separately on the
  validated oracle. PICK-03 stays OPEN until it lands and is dropped into the harness.
- **Interim R-side `gluUnProject` self-consistency check** — offered, not selected.
- **Written native-capture procedure doc** — offered, not selected. The pose-record schema is
  the de-facto spec.
- **Landmark editing / move / delete, curves, anchors, surfaces, multi-specimen, undo** —
  Phase 5 (DGT-01/DGT-02). This phase is **placement-only**. `.dgt` byte-parity is Phase 5.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PICK-01 | BVH-accelerated raycast returns a hit coordinate to R at interactive rates | BVH patches already live in the bundle (`_e.prototype.raycast=sx`); call `geometry.computeBoundsTree()` after PLYLoader load; pointer→NDC→`Raycaster.setFromCamera`; POST hit over token-guarded `/<token>/pick`. See Standard Stack, Pattern 1, Pattern 3. |
| PICK-02 | Landmark dots render as overlay geometry with correct depth under rotation | Add an overlay `THREE.Group`; small `SphereMesh` with `depthTest:true` occludes correctly under rotation (criterion 2). See Pattern 4. |
| PICK-03 | Browser coord matches native `gluUnProject` within a documented, inter-observer-justified tolerance (**milestone gate**) | Record-replay harness (Pattern 2); mean-edge-length tolerance = 0.085 units for B7_1; D-03 citations show gate ≪ 1–3 mm inter-observer error. Placeholder-fixture harness (Pattern 5). |
| CMP-01 | Native `tkogl2` oracle stays loadable (`.gmw_engine$ok`) | `.gmw_engine$ok` in `rtkogl.R:499`; reuse the `test-retina-picking-parity.R` skip-if-absent idiom. See Validation Architecture. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Pointer→ray→mesh hit | Browser (three.js) | — | Raycasting needs the live GPU-loaded geometry + camera; resolution-independent, so it belongs client-side. |
| Hit-coordinate ownership / landmark array | R (server) | — | Server-owns-state (REFERENCE-ARCHITECTURE): R holds the authoritative array; the browser only reports the click. |
| Pick round-trip transport | R↔Browser (loopback httpuv) | — | Token-guarded POST on the existing mixed app; never joins request path to filesystem (T-2-02). |
| Overlay landmark dot render | Browser (three.js) | R (owns data) | The browser draws the visual it just computed; R holds the authoritative coordinate. |
| Parity comparison (distance, percentile, tolerance) | R (harness) | — | R owns the fixture, the mean-edge-length calc, and the pass/fail gate; testthat drives it. |
| Native reference coordinates (oracle) | Native `tkogl2` (Windows) | — | Only trustworthy source of `gluUnProject` reference; recorded into the fixture with its commit hash. |
| Camera-pose replay driver | Browser (three.js) | R (feeds pose) | R reads the fixture and feeds each pose; the browser sets camera matrices + raycasts. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| three.js | 0.185.1 | Raycaster, PerspectiveCamera, BufferGeometry, overlay meshes | Already vendored (WEB-00); the render + pick engine. `[VERIFIED: VENDOR-MANIFEST.json]` |
| three-mesh-bvh | 0.9.13 | `Mesh.raycast` acceleration on 363k-vert meshes | Already vendored, prototype patches applied at bundle time. `[VERIFIED: VENDOR-MANIFEST.json + bundle grep]` |
| httpuv | (locked Import) | Loopback transport for the pick POST route | Phase 2/3 transport server; the pick route extends the same mixed app. `[VERIFIED: transport.R]` |
| later | (transitive via httpuv) | Defer teardown; available for deferred POST handling if needed | Already used by `.gmw_close_handler` fully-qualified, no new import. `[VERIFIED: transport.R]` |
| testthat | 3.3.2 | Parity harness tests with skip-if-absent | Established test framework; mirrors `test-retina-picking-parity.R`. `[VERIFIED: .cursorrules STACK]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| base R (`read.table`/`strsplit`/`utils`) | — | Read the fixture (TSV) and parse POST bodies | Keep the fixture + transport **dependency-free** — the project deliberately avoids a JSON dependency in R (see `view3d.R` header). `[VERIFIED: view3d.R:13-15]` |
| Rvcg | 0.25 | (Optional) compute mean inter-vertex edge length from the mesh in R | Already an Import; `vcgPlyRead` yields `$vb`/`$it` to compute edges. `[CITED: .cursorrules STACK]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| POST `/<token>/pick` | WebSocket / long-poll | Rejected in CONTEXT: heavier, no push need for placement-only; POST matches the `/close` precedent. |
| TSV fixture | JSON / RDS fixture | JSON needs a parser dependency in R; RDS can't be written by the native C/Windows capture. TSV is base-R-readable **and** `fprintf`-writable from C — the only format both ends produce. |
| `worldToLocal` conversion of the hit | Bake modelview onto the camera, mesh at identity | Baking the modelview on the camera makes `intersection.point` already mesh-local — no post-conversion, fewer places for a transform bug (see Pattern 2). |
| New BVH vendoring | — | None needed; BVH already patched into the bundle. |

**Installation:** No new packages. three@0.185.1 + three-mesh-bvh@0.9.13 are already vendored
(Phase 1 / WEB-00); httpuv/later/testthat/Rvcg are already declared. This phase installs nothing.

## Package Legitimacy Audit

> This phase installs **no new external packages**. All JS is pre-vendored and byte-pinned; all R
> packages are already declared dependencies. The audit below records the already-vendored JS for
> completeness.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| three | npm | ~13 yrs | ~1.8M/wk | github.com/mrdoob/three.js | OK | Already vendored (WEB-00), pinned 0.185.1, sha256 in manifest |
| three-mesh-bvh | npm | ~5 yrs | ~200k/wk | github.com/gkjohnson/three-mesh-bvh | OK | Already vendored (WEB-00), pinned 0.9.13 |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none
**New installs this phase:** none — nothing to gate behind a `checkpoint:human-verify`.

## Architecture Patterns

### System Architecture Diagram

```
                        ┌─────────────────────────── R session (server owns state) ───────────────────────────┐
                        │                                                                                      │
 pointer click ──▶ browser page (view3d.R template)                     .gmw_server[token]  = httpuv handle    │
 (canvas x,y)          │                                                 .gmw_picks[token]   = landmark array   │
                       ▼                                                          ▲                             │
             NDC = (x/w*2−1, −(y/h*2−1))                                          │ append (server owns data)   │
                       │                                                          │                             │
                       ▼                                                POST /<token>/pick  (text "x,y,z")      │
        Raycaster.setFromCamera(NDC, camera) ──▶ BVH Mesh.raycast ──▶ hit.point (world)                        │
                       │                                    │                     ▲                             │
                       │                                    ▼                     │ excludeStaticPath routes    │
                       │                          overlay Group.add(dot)          │ /pick to the R `call` handler│
                       │                          (PICK-02, local render)         │ (never joins path→FS, T-2-02)│
                       │                                                          │                             │
                       └────────── PICK-03 replay path (harness only) ───────────┘                             │
                                          │                                                                    │
   fixture row ──▶ camera.projectionMatrix = projection[16] (no transpose)                                     │
   (mv,proj,vp,     camera.matrixWorldInverse = modelview[16]; matrixAutoUpdate=false                          │
    px,py,winZ,     mesh at identity  ──▶ Raycaster casts recorded pixel ──▶ hit.point (== mesh-local)         │
    objXYZ,commit)                                     │                                                       │
                                                       ▼                                                       │
                              R: dist = ‖hit − native_objXYZ‖ ;  gate: quantile(dist, .95) ≤ 1·meanEdge        │
                        └──────────────────────────────────────────────────────────────────────────────────────┘

   Native oracle (Windows, tkogl2, BLOCKED this phase — D-06):
     getSpecimenCoordinate → glReadPixels(GL_DEPTH_COMPONENT) winZ → gluUnProject(mv,proj,vp) → objXYZ  ──▶ fixture
```

### Recommended Project Structure
```
R/
├── transport.R      # EXTEND: add /<token>/pick to the mixed app; .gmw_picks registry; R-side pick API
├── view3d.R         # EXTEND: pointer→raycast handler, computeBoundsTree(), overlay Group, camera-replay hook
└── parity.R         # NEW (optional): fixture reader, mean-edge-length, distance/percentile gate helpers
tests/
├── fixtures/parity/
│   ├── B7_1_clean.ply                    # EXISTS (D-04)
│   └── B7_1_pick_poses.tsv               # NEW: placeholder fixture (schema-true; D-07)
└── testthat/
    └── test-picking-parity.R             # NEW: harness tests, skip-if-real-fixture-absent
```

### Pattern 1: BVH-accelerated pointer pick (PICK-01)
**What:** On pointerdown, convert canvas coords to NDC, cast a ray from the camera, take the
nearest hit against the mesh. The bundle already patched `Mesh.prototype.raycast` to the
accelerated path, but acceleration only engages once a bounds tree exists.
**When to use:** The interactive digitizing click.
**Example:**
```javascript
// After PLYLoader load, in view3d.R's mesh-URL callback:
geometry.computeVertexNormals();
geometry.computeBoundsTree();            // <-- REQUIRED to actually accelerate raycast (bundle patch)
var mesh = new THREE.Mesh(geometry, material);

var raycaster = new THREE.Raycaster();
var ndc = new THREE.Vector2();
canvas.addEventListener("pointerdown", function (ev) {
  var r = canvas.getBoundingClientRect();
  // Y-flip: DOM origin is top-left; NDC origin is centre, +Y up.
  ndc.x =  ((ev.clientX - r.left) / r.width)  * 2 - 1;
  ndc.y = -((ev.clientY - r.top)  / r.height) * 2 + 1;
  raycaster.setFromCamera(ndc, camera);
  var hits = raycaster.intersectObject(mesh, false);   // mesh has DoubleSide material already
  if (hits.length) {
    var p = hits[0].point.clone();       // WORLD space
    mesh.updateWorldMatrix(true, false);
    mesh.worldToLocal(p);                // -> mesh-local (raw PLY vertex frame) for R
    navigator.sendBeacon("pick", p.x + "," + p.y + "," + p.z);  // relative URL -> /<token>/pick
    addOverlayDot(hits[0].point);        // PICK-02: draw at the WORLD hit (see Pattern 4)
  }
});
```
Notes: `sendBeacon` mirrors the existing `/close` beacon idiom (relative URL, same-origin, no
external ref). `fetch(..., {method:"POST", keepalive:true})` is an equivalent if a response body
is wanted. `intersectObject(mesh, false)` (non-recursive) avoids also hitting overlay dots.

### Pattern 2: Record-and-replay parity harness (PICK-03) — the gate
**What:** Reproduce the *native ray* exactly by copying the recorded matrices onto a three.js
camera, then compare the browser hit to the recorded native object coordinate.
**When to use:** The PICK-03 harness only (not the interactive path).
**Key idea — bake modelview on the camera, mesh at identity:** `gluUnProject` returns object
coords in the frame the **modelview maps from** (the raw PLY-vertex frame, because the native
capture reads `GL_MODELVIEW_MATRIX` *after* the rotate/scale/translate stack is pushed — see
`getSpecimenCoordinate` in `tcl_dispatch.c:668-676`). If the browser puts that same modelview on
the camera's view matrix and leaves the mesh at identity, `intersection.point` (world space) is
already in the PLY-vertex frame — directly comparable, no `worldToLocal` needed.
**Example:**
```javascript
// pose = one fixture row: mv[16], proj[16], vp[4], px, py (native input pixel), objXYZ
var camera = new THREE.PerspectiveCamera();     // params irrelevant; we overwrite the matrices
camera.matrixAutoUpdate = false;                // stop three.js recomputing from pos/quat/fov

// OpenGL glGetDoublev returns COLUMN-MAJOR [16]; THREE.Matrix4.fromArray is COLUMN-MAJOR.
// => copy verbatim, NO transpose, NO handedness flip (both are right-handed, look down -Z).
camera.projectionMatrix.fromArray(pose.proj);
camera.projectionMatrixInverse.copy(camera.projectionMatrix).invert();
var view = new THREE.Matrix4().fromArray(pose.mv);      // modelview = view matrix (mesh at identity)
camera.matrixWorldInverse.copy(view);
camera.matrixWorld.copy(view).invert();

// NDC from the SAME native input pixel the engine sampled (top-left origin), flip Y once:
var ndc = new THREE.Vector2(
  (pose.px / pose.vp[2]) * 2 - 1,
  -((pose.py / pose.vp[3]) * 2 - 1)
);
var raycaster = new THREE.Raycaster();
raycaster.setFromCamera(ndc, camera);            // uses matrixWorld + projectionMatrixInverse
var hits = raycaster.intersectObject(meshAtIdentity, false);
var browserObj = hits.length ? hits[0].point : null;   // == native object frame
// R then computes ||browserObj - pose.objXYZ||.
```
**Where the residual lives (D-09):** the native `objXYZ` came from a **depth-buffer-interpolated
`winZ`** (`glReadPixels(GL_DEPTH_COMPONENT)` then `gluUnProject`), while `browserObj` is an
**exact ray–triangle intersection**. On flat, front-facing surface these agree to floating-point;
near silhouettes and steep depth gradients they diverge by up to a fraction of a mesh cell. This
is the dominant (and expected) residual and is why the gate is the **95th percentile, not the max**.

### Pattern 3: Token-guarded POST pick route on the mixed httpuv app (PICK-01 transport)
**What:** A second excluded subpath alongside `/close`, handled on the R main thread.
**When to use:** Receiving the browser hit; storing it server-side.
**Example (extends `transport.R`):**
```r
# Registry mirrors .gmw_server: token -> landmark matrix (server owns state).
.gmw_picks <- new.env(parent = emptyenv())

.gmw_pick_handler <- function(token) {
  force(token)
  function(req) {
    path <- req$PATH_INFO
    if (grepl("/pick$", path)) {
      body <- rawToChar(req$rook.input$read())          # NEVER join path to filesystem (T-2-02)
      xyz  <- as.numeric(strsplit(body, ",", fixed = TRUE)[[1]])   # base-R parse, no JSON dep
      if (length(xyz) == 3L && all(is.finite(xyz))) {
        cur <- if (exists(token, .gmw_picks)) get(token, .gmw_picks) else NULL
        assign(token, rbind(cur, matrix(xyz, 1)), envir = .gmw_picks)
      }
      return(list(status = 204L, headers = list(), body = ""))
    }
    if (grepl("/close$", path)) { later::later(function() .gmw_stop_token(token), 0.5)
      return(list(status = 204L, headers = list(), body = "")) }
    list(status = 404L, headers = list("Content-Type" = "text/plain"), body = "")
  }
}
# startServer app: add "/<token>/pick" to the excludeStaticPath set; use .gmw_pick_handler(token)
# as the `call` handler (it subsumes the /close logic).
```
Preserves all three inherited invariants: loopback-only bind, ≥128-bit token guard, and no
`file.path`/`normalizePath`/`readBin` on the request path. R-side read API mirrors
`.plot_show()`/`.rgl_show()` shape (a small exported/`@noRd` accessor returning the array).

### Pattern 4: Overlay landmark dot with correct depth (PICK-02)
**What:** A dedicated overlay `THREE.Group` holding one small mesh per placed landmark.
**When to use:** Rendering placed landmarks; placement-only.
**Example:**
```javascript
var overlay = new THREE.Group(); scene.add(overlay);
function addOverlayDot(worldPoint) {
  var r = dist * 0.01;                                   // scale-relative to framed size
  var dot = new THREE.Mesh(
    new THREE.SphereGeometry(r, 16, 12),
    new THREE.MeshBasicMaterial({ color: 0xff2222, depthTest: true })  // occludes under rotation
  );
  dot.position.copy(worldPoint);
  overlay.add(dot);
}
```
`depthTest:true` gives "correct depth behavior under rotation" (criterion 2): a dot on the far
side is hidden by the mesh. If the planner instead wants always-visible landmarks, set
`depthTest:false` + `renderOrder` high — this is a Claude's-discretion call. A background click
(no hit) should be a silent no-op (placement-only, minimal).

### Pattern 5: Placeholder fixture that closes to real with zero code change (D-07)
**What:** A fixture file **byte-schema-identical** to the eventual Windows capture, populated now
with self-consistent synthetic rows so the harness runs green (validates plumbing, not parity).
**How to make it self-consistent without a native engine:** pick a few camera poses in the
browser, raycast chosen pixels, then write the browser hit **as** the `objXYZ` column and
back-project it to fill `winZ` (via `camera` project). The placeholder therefore yields
distance ≈ 0 — the harness proves it *runs*, computes mean-edge-length, and applies the gate.
When the real TSV (same columns, real native `objXYZ`/`winZ`) is dropped in, the identical
harness computes real distances. The test **skips** (not fails) when the real fixture is marked
absent, using the `test-retina-picking-parity.R` idiom.

### Anti-Patterns to Avoid
- **Transposing the OpenGL matrices into three.js.** Both are column-major; `Matrix4.fromArray`
  is column-major. A transpose here silently rotates every ray and produces plausible-but-wrong
  hits. Verify with a single axis-aligned sanity pose before trusting the percentile.
- **Recentering the mesh in the replay path.** The interactive template does
  `group.position.sub(sphere.center)`; the parity replay must use the **raw PLY vertex frame**
  (mesh at identity, no group offset) or convert consistently, or every hit is offset by
  `sphere.center`.
- **Forgetting `computeBoundsTree()`.** Without it the patched `raycast` falls back to the linear
  path — correct but slow on 363k verts, risking the "interactive rates" clause of PICK-01.
- **Reading a stale world matrix.** Call `mesh.updateWorldMatrix(true,false)` before
  `worldToLocal` (well-documented three.js footgun). `[CITED: threejs discourse 57294]`
- **Joining the request path to the filesystem** in the pick handler — reopens T-2-02
  path-traversal. Only ever pattern-match the path suffix.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ray–triangle intersection over 363k faces | A custom picker / linear scan | three-mesh-bvh (`computeBoundsTree` + patched `raycast`) | Already vendored; BVH is O(log n) vs O(n); hand-rolled misses degenerate-triangle + numerical edge cases. |
| Screen→object unproject in JS | Manual inverse of `proj·view` | `Raycaster.setFromCamera` + `intersectObject` | three.js already handles NDC, near/far, perspective divide; matches the engine's `gluUnProject` semantics. |
| Matrix inverse / multiply | Hand-written 4×4 math | `THREE.Matrix4.invert()` / `.multiply()` | Correct, column-major, tested. |
| JSON in R for the fixture/transport | Adding jsonlite | base `read.table` + `strsplit` over a TSV / `"x,y,z"` body | The project deliberately stays JSON-dependency-free (view3d.R header); TSV is the only format both C-capture and R-read can produce. |
| Mean inter-vertex edge length | Ad-hoc loops | `Rvcg` mesh `$it` face list → edge distances, or a documented one-pass over faces | Rvcg already loads the PLY; avoids re-parsing 31 MB by hand. |

**Key insight:** Everything numerically hard in this phase already exists — the risk is *wiring
convention* (which matrix, which order, which pixel), not algorithm. Keep the browser thin and
copy matrices verbatim.

## Common Pitfalls

### Pitfall 1: Y-axis flip applied zero or twice
**What goes wrong:** Picks land mirrored vertically, or correct only at the vertical centre.
**Why it happens:** DOM pointer events use a **top-left** origin (+Y down); NDC and OpenGL window
coords use **bottom-left** (+Y up). The native engine flips once: `winY = viewport[3] - y`
(`ogl_ZARF9.c:134`). The browser must flip once in NDC: `ndcY = -(y/h*2 - 1)`.
**How to avoid:** Record in the fixture the pixel **as fed to `ogl_getObjCoordinate`** (the
`sampleX, sampleY` top-left backing pixel — `tcl_dispatch.c:647,676`), NOT the internally-flipped
`winY`. The browser applies its own single flip from that same top-left pixel. Flip in exactly
one place on each side.
**Warning signs:** A parity pass at the image centre but growing error toward top/bottom edges.

### Pitfall 2: Backing-pixel vs Tk-point vs CSS-pixel mismatch
**What goes wrong:** Off-by-`devicePixelRatio` pick offset on HiDPI.
**Why it happens:** The native engine converts Tk points → **backing pixels** once
(`gfx_point_to_backing`, `tcl_dispatch.c:647`) and samples in backing space. The fixture records
the backing pixel. In the browser, `getBoundingClientRect()` gives **CSS** pixels; the renderer
uses `setPixelRatio(devicePixelRatio)`. **But raycasting is resolution-independent** (NDC is
unitless), so as long as NDC is computed from CSS px over CSS size, the ray is identical
regardless of backing scale — this is exactly why criterion 4 holds "with no backing-scale
correction" (REFERENCE-ARCHITECTURE). For the *replay*, divide the recorded backing pixel by the
recorded backing **viewport** (`vp[2],vp[3]`) so the ratio is scale-free.
**Warning signs:** Parity passes on a 1× display but drifts on Retina — means a raw pixel count
leaked into an NDC calc instead of a pixel/size ratio.

### Pitfall 3: Column-major / row-major matrix confusion
**What goes wrong:** Every ray is rotated; hits are plausible but systematically wrong.
**Why it happens:** Assuming OpenGL is row-major (it is column-major) or that `fromArray`
transposes (it does not).
**How to avoid:** Copy `modelview[16]` and `projection[16]` verbatim with `fromArray`. Add one
axis-aligned sanity pose to the fixture whose expected hit is hand-checkable.
**Warning signs:** A constant rotational offset across all clicks with otherwise tight spread.

### Pitfall 4: Depth-interpolation residual mistaken for a bug (D-09)
**What goes wrong:** A few fixture points show larger error than the rest; instinct is to "fix" it.
**Why it happens:** Native `winZ` is depth-buffer-interpolated and quantized; browser is exact
triangle math. Near silhouettes they legitimately differ by up to a mesh cell.
**How to avoid:** Gate the **95th percentile**, not the max (D-02). Document the tail as expected.
**Warning signs:** The outliers cluster on silhouette/edge clicks — expected, not a defect.

### Pitfall 5: `computeBoundsTree` cost on the 30 MB worst case
**What goes wrong:** A visible pause after load, or a first-click stall.
**Why it happens:** Building the BVH on 363k verts / 726k faces is non-trivial; if built lazily on
first raycast it stalls the first click.
**How to avoid:** Build it **eagerly** in the PLYLoader callback right after
`computeVertexNormals()`, before framing, so the cost is folded into load, not the first pick.
**Warning signs:** First pick slow, subsequent picks instant.

## Code Examples

### Compute mean inter-vertex edge length in R (tolerance unit, D-01)
```r
# From an Rvcg mesh (m$vb = 4 x V homogeneous, m$it = 3 x F, 1-based).
mean_edge_length <- function(m) {
  V <- t(m$vb[1:3, , drop = FALSE])
  it <- t(m$it)                                  # F x 3, 1-based
  e <- rbind(it[, c(1, 2)], it[, c(2, 3)], it[, c(3, 1)])
  d <- sqrt(rowSums((V[e[, 1], ] - V[e[, 2], ])^2))
  mean(d)
}
# For tests/fixtures/parity/B7_1_clean.ply this is ~0.085 model units (see Metadata).
```

### Distance + 95th-percentile gate (PICK-03)
```r
parity_gate <- function(browser_xyz, native_xyz, mean_edge) {
  d <- sqrt(rowSums((browser_xyz - native_xyz)^2))
  list(p95 = stats::quantile(d, 0.95, names = FALSE),
       pass = stats::quantile(d, 0.95, names = FALSE) <= 1 * mean_edge,
       n = length(d))
}
```

### Read the pose-record fixture (base R, no JSON dependency)
```r
# Header comment binds fixture to specimen + engine commit; read.table skips it.
read_pick_poses <- function(path) {
  utils::read.table(path, header = TRUE, sep = "\t", comment.char = "#",
                    stringsAsFactors = FALSE)
}
```

## Pose-Record Schema (D-05 / D-07) — the drop-in contract

A single tab-separated file, `B7_1_pick_poses.tsv`, **one row per click**, fixed column order.
The placeholder written this phase and the real Windows capture MUST share this exact header so
the swap needs no code change.

```
# specimen=B7_1_clean.ply  specimen_sha256=<hex>  engine_commit=<git-sha>  captured=<iso8601>
commit  mv00 mv01 ... mv15  pj00 pj01 ... pj15  vp0 vp1 vp2 vp3  px  py  winz  objx objy objz
```

| Field(s) | Count | Source (native) | Notes |
|----------|-------|-----------------|-------|
| `commit` | 1 | engine git SHA per row | ROADMAP oracle-validity note; per-row so a mixed-commit fixture is detectable. |
| `mv00..mv15` | 16 | `glGetDoublev(GL_MODELVIEW_MATRIX)` (`ogl_ZARF9.c:123`) | **Column-major**, captured *after* the rotate/scale/translate push (`tcl_dispatch.c:668-673`). |
| `pj00..pj15` | 16 | `glGetDoublev(GL_PROJECTION_MATRIX)` (`ogl_ZARF9.c:124`) | Column-major. |
| `vp0..vp3` | 4 | `glGetIntegerv(GL_VIEWPORT)` (`ogl_ZARF9.c:125`) | `x,y,width,height` in backing pixels. |
| `px,py` | 2 | `sampleX,sampleY` fed to `ogl_getObjCoordinate` (`tcl_dispatch.c:676`) | Backing pixel, **top-left origin** (pre-`winY`-flip). |
| `winz` | 1 | `glReadPixels(GL_DEPTH_COMPONENT)` (`ogl_ZARF9.c:153`) | Depth-buffer sample in [0,1]; not consumed by the browser, but needed to regenerate `objXYZ` and to audit the residual. |
| `objx,objy,objz` | 3 | `gluUnProject(...)` outputs (`ogl_ZARF9.c:155`) | The reference coordinate, in the **PLY-vertex frame**. This is what the browser hit is compared against. |

Binding metadata (specimen filename + sha256 + engine commit) lives in the header comment line so
a later engine change or a wrong specimen cannot silently pass. A meaningful fixture needs a
spread of clicks: front-facing centre, near-silhouette, steep-gradient, and at least one
axis-aligned sanity pose (Pitfall 3).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `THREE.Projector.unprojectVector` + manual Raycaster | `raycaster.setFromCamera(ndc, camera)` | three r70+ | The r65-era StackOverflow snippets are stale; use `setFromCamera`. |
| Linear `Mesh.raycast` | BVH `acceleratedRaycast` via prototype patch | three-mesh-bvh | Required for interactive picks on scan-density meshes; already patched in the bundle. |
| three.js UMD build | ESM-only from 0.160 → project vendors an IIFE | 0.160 | Why the bundle exists; irrelevant to picking but constrains how JS is added. |

**Deprecated/outdated:**
- `Projector`/`unprojectVector`: removed; do not reintroduce.
- Any per-vertex color usage: intentionally off in the material (`view3d.R:199-207`); picking
  doesn't need it.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `B7_1_clean.ply` model units are millimetres (NextEngine convention), so mean edge ≈ 0.085 mm | Metadata / D-03 | If units are not mm, the *absolute* mm comparison to 1–3 mm inter-observer error weakens — but the **scale-relative** argument (mean edge = 0.14% of the specimen's largest extent) holds regardless. The gate itself (D-01/D-02) is unit-free by construction. |
| A2 | The native `objXYZ` is in the raw PLY-vertex frame (modelview captured includes the full model transform) | Pattern 2 | If a further transform sits between capture and unproject, the browser must apply it too. Grounded in `tcl_dispatch.c:668-676` reading, but only a live Windows capture confirms it — hence the axis-aligned sanity pose. |
| A3 | `glGetDoublev` returns column-major and copies to `Matrix4.fromArray` with no transpose | Pattern 2 / Pitfall 3 | A transpose would rotate every ray; the sanity pose catches it before trusting the percentile. |
| A4 | The mean-edge gate (~0.085 units) is achievable given the depth-interpolation residual | D-02/D-09 | Cannot be *proven* until the real Windows fixture lands (D-06). This is the open gate PICK-03 tracks; the harness is built to measure it, not assume it. |
| A5 | POST `"x,y,z"` text body is sufficient (no JSON) for the pick round trip | Pattern 3 | If richer payloads are later needed (Phase 5 curves/anchors), the format extends; placement-only is fine with 3 numbers. |

**User confirmation needed at plan time:** A1 (final tolerance number wording), A4 (accept that
PICK-03 ships OPEN with the harness green on the placeholder).

## Open Questions (RESOLVED)

1. **Are B7_1 units millimetres?**
   - What we know: coords span ~23.8 × 56.4 × 4.6; NextEngine scans are typically mm.
   - What's unclear: no unit field in the PLY header.
   - Recommendation: state the tolerance **scale-relatively** (D-01) as the primary claim; cite the
     mm figure as a secondary, clearly-labelled illustration. Robust either way.
   - RESOLVED: gate is scale-relative (D-01/D-02, ≤ 1× mean edge). mm figure is illustrative only;
     the claim holds regardless of A1. No blocker.

2. **Does the native modelview include any transform the browser must mirror beyond identity?**
   - What we know: `getSpecimenCoordinate` pushes rotate/scale/translate then reads the modelview,
     so the captured matrix already contains them.
   - What's unclear: whether `onDisplay()` (called just before) alters the matrix stack further.
   - Recommendation: the record-replay design is immune (it copies the *captured* matrix);
     confirm with the axis-aligned sanity pose when the real fixture arrives.
   - RESOLVED: record-replay copies the captured matrix verbatim, so it is immune by construction.
     Sanity-pose confirmation deferred to real-fixture drop-in (inside PICK-03 OPEN envelope).

3. **Placeholder distance target: zero or synthetic-noise?**
   - What we know: a zero-distance placeholder proves plumbing; a small-noise placeholder also
     exercises the percentile path.
   - Recommendation (planner's call): include at least a couple of synthetic-noise rows so the
     `quantile(...,.95)` branch is genuinely exercised, plus zero-distance rows for the happy path.
   - RESOLVED: planner chose a mix — zero-distance rows plus synthetic-noise rows (04-03 Task 2)
     so the 95th-percentile branch is exercised.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| three.js (vendored bundle) | PICK-01/02 raycast + overlay | ✓ | 0.185.1 | — |
| three-mesh-bvh (vendored) | PICK-01 acceleration | ✓ | 0.9.13 | linear raycast (correct, slower) |
| httpuv + later | Pick POST transport | ✓ | locked Import | — |
| B7_1_clean.ply fixture | PICK-03 harness | ✓ | 31 MB, 363,283 verts | — |
| Rvcg | mean-edge-length calc | ✓ | 0.25 | one-pass R over faces |
| **Native `tkogl2` on Windows** | **PICK-03 real reference coords** | ✗ | — | **placeholder fixture (D-07); PICK-03 stays OPEN** |
| A browser + display host | manual PICK-01/02 UAT | ✗ (headless sandbox) | — | executable manual UAT steps, mirror Phase 3 pattern |

**Missing dependencies with no fallback:** none that block *this phase's* deliverables.
**Missing dependencies with fallback:**
- Windows native oracle → placeholder fixture; PICK-03 formally OPEN (the intended, tracked
  outcome per D-06/D-07 and the ROADMAP "decision point" note).
- Display host → manual UAT recorded as executable steps (Phase 3 precedent: `# MANUAL UAT`
  header + VALIDATION.md), signed off later on macOS + Windows.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2 (edition 3) |
| Config file | `tests/testthat.R` + per-file `test-*.R` (existing) |
| Quick run command | `Rscript -e 'testthat::test_file("tests/testthat/test-picking-parity.R")'` |
| Full suite command | `Rscript -e 'devtools::test()'` (note: suite is pre-existing 6-red — see STATE.md Open Items; do not attribute to Phase 4) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PICK-01 | Pick POST route stores an `x,y,z` hit; malformed body rejected; path never joined to FS | unit (httpuv handler, injected `req`) | `test_file("tests/testthat/test-picking-parity.R")` (route cases) | ❌ Wave 0 |
| PICK-01 | `computeBoundsTree` called + raycast wired in template | source-scan (grep the emitted HTML/template, mirror `test-offline-smoke`/beacon scan) | same | ❌ Wave 0 |
| PICK-02 | Overlay group + dot with `depthTest` present in template | source-scan | same | ❌ Wave 0 |
| PICK-03 | mean-edge-length calc correct on a tiny known mesh | unit | same | ❌ Wave 0 |
| PICK-03 | distance + 95th-percentile gate math correct on synthetic arrays | unit | same | ❌ Wave 0 |
| PICK-03 | end-to-end harness runs on placeholder fixture and passes; **skips** when real fixture absent | integration (skip-if-absent) | same | ❌ Wave 0 |
| PICK-01/02 | Interactive pick + overlay on real browser | manual-only (headless can't render) | `# MANUAL UAT` steps + VALIDATION.md | ❌ Wave 0 |
| CMP-01 | `.gmw_engine$ok` TRUE when native present; skip when absent | unit (skip-if-absent) | same | reuse idiom |

### Sampling Rate
- **Per task commit:** `test_file("tests/testthat/test-picking-parity.R")`
- **Per wave merge:** `devtools::test()` (filter to new file if the pre-existing reds block; they
  are unrelated — STATE.md)
- **Phase gate:** new parity file green on the placeholder; PICK-03 recorded OPEN with rationale.

### Wave 0 Gaps
- [ ] `tests/testthat/test-picking-parity.R` — covers PICK-01 route, PICK-03 math + harness, CMP-01
- [ ] `tests/fixtures/parity/B7_1_pick_poses.tsv` — schema-true placeholder (D-07)
- [ ] `R/parity.R` (optional) — `mean_edge_length`, `parity_gate`, `read_pick_poses` helpers
- [ ] Skip idiom: mark the real-fixture path absent (e.g. a sentinel column/flag or a `_REAL`
      filename) so the harness skips cleanly, exactly like `test-retina-picking-parity.R`

*(Existing test infrastructure covers the framework; all Phase-4 coverage is net-new.)*

## Security Domain

`security_enforcement: true`, ASVS level 1. This phase adds one untrusted input boundary: the
`POST /<token>/pick` body from the browser.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Local loopback; the ≥128-bit path token is the only guard (inherited). |
| V3 Session Management | no | No sessions; per-viewport token in the URL path. |
| V4 Access Control | yes | Loopback bind (`127.0.0.1` only) + per-token path; a pick to an unknown token is a 404 (no registry entry). |
| V5 Input Validation | **yes** | Parse the `"x,y,z"` body with base R; require exactly 3 finite numerics; drop otherwise. Never `eval`, never treat as a path. |
| V6 Cryptography | no | No new crypto; token generator unchanged (base-R `sample()`, residual risk already accepted in transport.R). |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via request path | Tampering | Only pattern-match `/pick$`/`/close$`; never `file.path`/`normalizePath`/`readBin` on `req$PATH_INFO` (T-2-02, inherited). |
| Malformed / oversized POST body | DoS / Tampering | Length-check the parsed numeric vector; ignore non-conforming bodies; bounded 3-float payload. |
| LAN exposure of the pick endpoint | Info disclosure | `host = "127.0.0.1"` only (T-2-03, inherited). |
| Cross-token write | Tampering | Handler closes over its own `token`; writes only `.gmw_picks[[token]]`. |
| Stopping other packages' listeners | DoS | Teardown iterates `.gmw_server` only, never httpuv process-wide stop (T-3-03, inherited). |

## Project Constraints (from .cursor/rules/)
- **GSD workflow enforcement:** repo edits go through a GSD command (`/gsd-execute-phase` for this
  planned work); do not edit outside the workflow.
- **R package root:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`; C engine
  root `.../tkogl2/`. Keep the existing file-extension convention (`.r` vs `.R`) of the file edited.
- **Naming:** `camelCase` for GUI/action handlers, `dot.separated` for file-I/O/module
  constructors, `.gmw_*`/`.onLoad` idioms for the browser transport layer.
- **Error handling (R):** user-facing errors surfaced inline via the status bar; `stop(call.=FALSE)`
  for hard R-level failures (mirror `.gmw_serve_mesh`).
- **Logging:** `dbg()` gated printer (silent unless `options(guimorph.debug=TRUE)`); no raw `print`.
- **Exports:** keep the surface minimal; new internal helpers `@noRd`/`@keywords internal` unless a
  user entry point is genuinely needed (mirror `gmw_close` export shape).
- **CMP-01 non-negotiable:** never touch the `rtkogl.R` `.onLoad` engine-load path; the native
  oracle must stay loadable through Phase 5.

## Sources

### Primary (HIGH confidence — read from source in-repo this session)
- `tkogl2/src/ogl_ZARF9.c` — `ogl_getObjCoordinate`: winY flip, `glReadPixels(GL_DEPTH_COMPONENT)`,
  `gluUnProject`; matrices via `glGetDoublev`/`glGetIntegerv`.
- `tkogl2/src/tcl_dispatch.c` — `getSpecimenCoordinate` (transform push before capture, backing-pixel
  sample), `GBL_RETINA_NEAR_MISS_PX`, context rebind before pick.
- `R/view3d.R` — `GMW_VIEW3D_TEMPLATE`, PLYLoader callback, framing, beacon idiom.
- `R/transport.R` — mixed httpuv app, `excludeStaticPath`, `.gmw_close_handler`, `.gmw_server`,
  token, teardown, security invariants.
- `R/rtkogl.R` — `.gmw_engine$ok` / `.gmw_require_engine` (CMP-01), `.plot_show` API shape.
- `inst/htmlwidgets/VENDOR-MANIFEST.json` + bundle grep — three 0.185.1, three-mesh-bvh 0.9.13,
  `Gt.prototype.computeBoundsTree` / `_e.prototype.raycast=sx` patches confirmed.
- `tests/fixtures/parity/B7_1_clean.ply` header + computed edge stats (this session).
- `tests/testthat/test-retina-picking-parity.R` — skip-if-absent idiom.

### Secondary (MEDIUM confidence — official docs / verified community)
- three.js Raycaster docs: `intersection.point` is world-space; `intersectObject` requires
  DoubleSide to hit back faces. `[CITED: threejs.org/docs Raycaster]`
- three.js `worldToLocal` + `updateWorldMatrix` stale-matrix footgun.
  `[CITED: threejs discourse 57294; SO 21350647/30035375]`

### Tertiary (LOW confidence — none load-bearing)
- General web synthesis on inter-observer error magnitude (corroborated by the primary papers below).

### D-03 tolerance literature (published, cited)
- Shearer et al. 2017, *PLOS ONE* 12(11): "Evaluating causes of error in landmark-based data
  collection using scanners" — inter-observer error ≫ intra-observer; ≈ pairwise Procrustes
  differences among 10 macaques; scanner type has minimal influence.
  `[CITED: doi.org/10.1371/journal.pone.0187452]`
- Robinson & Terhune 2017, *Am. J. Phys. Anthropol.* — error combining 3D data from multiple
  sources; inter-observer dominates. `[CITED: gc.cuny.edu Robinson-Terhune-2017]`
- Fruciano et al. / Barbeito-Andrés (MRI 3D landmarks) 2018, *PLOS ONE*: inter-operator absolute
  errors averaged **1–3 mm**; Maudgil et al. and Chollet et al. reported **1–2 mm**.
  `[CITED: doi.org/10.1371/journal.pone.0197675]`
- "Sharing is caring?" 2017, *Ecol. Evol.* 7: measurement error can rival biological signal;
  reduced by excluding hard-to-digitize landmarks. `[CITED: doi.org/10.1002/ece3.3256]`
- μCT 3DGM error 2019, *J. Anat.*: measurement error ~6.75% of realistic-study variance;
  inter-observer exceeds intra when observers are inexperienced.
  `[CITED: doi.org/10.1111/joa.12999]`

## Metadata

**Fixture measurements (computed this session, `B7_1_clean.ply`):**
- 363,283 verts / 726,478 faces (matches D-04).
- Bounding box: 23.772 × 56.381 × 4.632 model units; diagonal ≈ 61.362.
- **Mean inter-vertex edge length ≈ 0.0850 units** (median 0.0836, p95 0.1096, min 0.018, max 0.283).
- Mean edge ≈ **0.14% of the bbox diagonal**.
- **Gate (D-02) ≈ 0.085 units.** If units are mm (A1), that is ~**12–35× tighter** than the
  1–3 mm inter-observer error in the literature — i.e. browser-vs-native discrepancy is far below
  the smallest error a human digitizer contributes. Scale-relatively, the gate is one mesh cell,
  which is the finest distinction the mesh can represent.

**Confidence breakdown:**
- Standard stack: HIGH — versions read from the pinned manifest; nothing new to install.
- Architecture (coordinate math, transport, overlay): HIGH — every claim traced to in-repo source.
- Pitfalls: HIGH — derived directly from the native code (Y-flip, backing pixel, depth interp).
- Tolerance justification (D-03): MEDIUM-HIGH — literature well-established; the *absolute* mm
  framing depends on A1 (unit assumption), the scale-relative framing does not.
- PICK-03 closure: intentionally OPEN (D-06/D-07) — the harness is built and verifiable; the real
  reference data is the tracked blocker.

**Research date:** 2026-08-05
**Valid until:** ~2026-09-05 (stable stack; three/BVH pinned by manifest, literature is settled)
