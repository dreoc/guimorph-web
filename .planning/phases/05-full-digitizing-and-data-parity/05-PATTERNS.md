# Phase 5: Full Digitizing and Data Parity - Pattern Map

**Mapped:** 2026-08-07
**Files analyzed:** 12 (6 R modified/extended, 4 tests new, 2 tests extended; +2 external fixtures with no analog)
**Analogs found:** 10 / 12 (2 fixtures are external round-trip evidence, no code analog)

> No CONTEXT.md exists for this phase. File list derived from RESEARCH.md
> "Recommended Project Structure" + Patterns 1-6. All analogs are IN-REPO files
> this phase extends, per the phase brief. Package root:
> `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `R/transport.R` (session model + `.gmw_session`) | store/model | server-owned state | `R/transport.R` `.gmw_picks` env + `.gmw_picks_get`/`gmw_picks` (58, 371-399) | exact (same file, same idiom) |
| `R/transport.R` (digitizing routes: anchor/curve/delete/undo/specimen/gpa/export) | controller/route | request-response + CRUD | `R/transport.R` `.gmw_pick_handler` (175-197) | exact |
| `R/view3d.R` (anchor/curve/surface overlays, delete/undo/switch UI) | component (browser) | event-driven | `R/view3d.R` `addOverlayDot` (193-200) + `pointerdown` (294-310) + `.gmw_flat` (23-28) | exact |
| `R/3dDigitize.main.r` (`.dgt_write_matrix_block` deterministic; session serialize path) | utility | file-I/O (write) | `.dgt_format_num`/`.dgt_write_matrix_block` (203-215), `saveToDgt` (1931-2026), `mergeDgt` wb pin (3440) | exact (edit-in-place) |
| `R/3dDigitize.geomorph.r` (session-model read source into `.build_geomorph_data`) | service | transform (batch) | `.build_geomorph_data` (203+) + `.landmarks_for_specimen` (162-173) | exact (edit-in-place) |
| `R/3dDigitize.surface.r` (headless `downSample` entry the route calls) | service | transform (file-I/O + geometry) | `downSample` (400-567), flatten at 548 | role-match (reuse + thin entry) |
| `R/parity.R` (OPTIONAL byte-identity helpers) | utility | file-I/O | `test-dgt-cross-platform.R` `.byte_signature` (7-13) | role-match |
| `tests/testthat/test-digitizing-session.R` (NEW) | test | unit (injected `req`) | `test-picking-transport.R` `make_req` + direct-handler (18-50) | exact |
| `tests/testthat/test-surface-flatten.R` (NEW) | test | unit (regression) | `test-curve-io.R` / `.gmw_flat` (view3d.R:23-28) | role-match |
| `tests/testthat/test-dgt-determinism.R` (NEW) | test | unit + byte | `test-dgt-cross-platform.R` (1-73) | exact |
| `tests/testthat/test-digitizing-view3d.R` (NEW) | test | source-scan | `test-picking-view3d.R` (1-52) | exact |
| `tests/testthat/test-dgt-cross-platform.R` (EXTEND) | test | integration (skip-if-absent) | itself (75-91) + `test-retina-picking-parity.R` skip idiom (6-17) | exact |
| `tests/testthat/test-gpa-parity.R` / `test-export-parity.R` (EXTEND) | test | unit/integration | themselves | exact (extend) |
| `tests/fixtures/parity/*-rewrite.dgt` (NEW) | fixture | file (data) | — | **no analog** (external Windows re-save) |

## Pattern Assignments

### `R/transport.R` — server-owned session model (`.gmw_session`) (store, server-owned state)

**Analog:** `.gmw_picks` env + its comment block, `R/transport.R` (58; 51-58).

**Env-declaration pattern** — declare `.gmw_session` as a SIBLING env to `.gmw_server`/`.gmw_picks`/`.gmw_lifecycle`, kept separate so `ls(.gmw_server)` stays purely token→handle:

```51:58:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
# Package-level, server-owned landmark store: keyed by token -> an n x 3 numeric
# matrix of placed pick coordinates (PICK-01). Kept SEPARATE from .gmw_server
# (same reasoning as .gmw_lifecycle) so ls(.gmw_server) stays purely
# token -> handle and .gmw_stop_token() never mistakes a landmark matrix for a
# live server handle. This is the SINGLE authoritative copy of the landmarks:
# the browser only reports clicks over POST /<token>/pick; R owns the array
# (server-owns-state, research/REFERENCE-ARCHITECTURE.md).
.gmw_picks <- new.env(parent = emptyenv())
```

New: `.gmw_session <- new.env(parent = emptyenv())` keyed token → `list(specimens=list(<record>), current=<int>, undo=<entry|NULL>)`; per-specimen record slots `land`/`anchor`/`curves`(indices, session-scoped)/`surfaces`/`template` (RESEARCH Pattern 1).

**Accessor pattern** — mirror the `.gmw_picks_get` internal + `gmw_picks` exported pair (371-399). The exported accessor returns one token's data or, with `NULL`, a named list over all tokens:

```371:399:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
.gmw_picks_get <- function(token) {
  if (exists(token, envir = .gmw_picks)) get(token, envir = .gmw_picks) else NULL
}
...
gmw_picks <- function(token = NULL) {
  if (!is.null(token)) return(.gmw_picks_get(token))
  toks <- ls(.gmw_picks)
  stats::setNames(lapply(toks, .gmw_picks_get), toks)
}
```

Keep new internals `@keywords internal`/`@noRd`; export only a genuine user entry point (mirror `gmw_picks`/`gmw_close` export shape — RESEARCH Project Constraints).

---

### `R/transport.R` — token-guarded digitizing routes (controller/route, request-response + CRUD)

**Analog:** `.gmw_pick_handler`, `R/transport.R` (175-197).

**The route-handler pattern to copy for every new digitizing route** — `grepl` the trailing suffix ONLY (never join `req$PATH_INFO` to the filesystem, T-2-02), read a bare-CSV body with `rawToChar(req$rook.input$read())`, parse with base R, arity+finite-check, mutate only `.gmw_session[[token]]` (cross-token-write guard T-4-04), return `204`; unknown path → `404`:

```175:197:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
.gmw_pick_handler <- function(token) {
  force(token)
  function(req) {
    path <- req$PATH_INFO
    if (grepl("/pick$", path)) {
      # Bare "x,y,z" text body, base-R parse only (no JSON dep). The path is
      # only ever matched with grepl above; it is NEVER joined to the filesystem.
      body <- tryCatch(rawToChar(req$rook.input$read()), error = function(e) "")
      xyz  <- suppressWarnings(as.numeric(strsplit(body, ",", fixed = TRUE)[[1]]))
      if (length(xyz) == 3L && all(is.finite(xyz))) {
        cur <- if (exists(token, envir = .gmw_picks)) get(token, envir = .gmw_picks) else NULL
        assign(token, rbind(cur, matrix(xyz, nrow = 1L)), envir = .gmw_picks)
        dbg(paste0("gmw pick: ", token, " <- ", body))
      }
      return(list(status = 204L, headers = list(), body = ""))
    }
    if (grepl("/close$", path)) {
      later::later(function() .gmw_stop_token(token), 0.5)
      return(list(status = 204L, headers = list(), body = ""))
    }
    list(status = 404L, headers = list("Content-Type" = "text/plain"), body = "")
  }
}
```

For DGT-01 curve route the body is 3 INTEGER indices (`as.integer`, `length==3 && all(is.finite) && length(unique)==3`), append to session `curves` matrix, push `undo=list(action="curve_place", row=idx)` (RESEARCH Code Examples). Anchor route mirrors `/pick` exactly but writes `session$specimens[[cur]]$anchor`, green overlay. Export route: the body carries ONLY a format token validated against an allow-list `c("csv","rds","dgt")` — NEVER a path (RESEARCH Security V5).

**Route-registration pattern** — extend the `excludeStaticPath` map in `.gmw_serve_mesh` (253-264). Each new dynamic subpath gets its own `excludeStaticPath()` entry alongside the static byte mount; the single `call` handler answers all branches:

```253:264:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
  server <- httpuv::startServer(
    host = "127.0.0.1", port = port,
    app = list(
      staticPaths = stats::setNames(
        list(httpuv::staticPath(dir), httpuv::excludeStaticPath(),
             httpuv::excludeStaticPath()),
        c(paste0("/", token), paste0("/", token, "/close"),
          paste0("/", token, "/pick"))
      ),
      call = .gmw_pick_handler(token)
    )
  )
```

PLANNER DECISION (RESEARCH A5): one `excludeStaticPath()` per route vs a single `/edit` route with a verb-in-body. Both preserve the no-path-join invariant.

---

### `R/view3d.R` — browser overlays + interaction (component, event-driven)

**Analog:** `addOverlayDot` (193-200), interactive `pointerdown` (294-310), `.gmw_flat` (23-28), all in `R/view3d.R`.

**Overlay-dot pattern** — anchors reuse this shape with a distinct color (native green `0x00ff00`) and a SECOND `THREE.Group` sibling to `overlay` so anchor dots are never in `intersectObject(pickMesh,false)`:

```193:200:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
  function addOverlayDot(worldPoint){
    var dot = new THREE.Mesh(
      new THREE.SphereGeometry(dist * 0.01, 16, 12),
      new THREE.MeshBasicMaterial({ color: 0xff2222, depthTest: true })
    );
    dot.position.copy(worldPoint);
    overlay.add(dot);
  }
```

**Pointer-pick pattern** — anchor placement copies this verbatim (single Y-flip NDC, BVH `intersectObject(pickMesh,false)`, `updateWorldMatrix` before `worldToLocal` to get the raw PLY-vertex frame, relative `sendBeacon`), changing only the target route:

```294:310:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
  canvas.addEventListener("pointerdown", function(ev){
    if (!pickMesh) return;
    var r = canvas.getBoundingClientRect();
    ndc.x = ((ev.clientX - r.left) / r.width) * 2 - 1;
    ndc.y = -((ev.clientY - r.top) / r.height) * 2 + 1;
    raycaster.setFromCamera(ndc, camera);
    var hits = raycaster.intersectObject(pickMesh, false);
    if (hits.length) {
      addOverlayDot(hits[0].point);
      var p = hits[0].point.clone();
      pickMesh.updateWorldMatrix(true, false);
      pickMesh.worldToLocal(p);
      try { navigator.sendBeacon("pick", p.x + "," + p.y + "," + p.z); } catch(e){}
    }
  });
```

Curve-by-index (DGT-01): on a curve-tab click, find the nearest OVERLAY dot (screen-space threshold) → take its INDEX → recolor cyan `rgb(1/255,164/255,191/255)`; 2nd point → blue slider `(0,0,1)`; on the 3rd, `sendBeacon("curve", i+","+j+","+k)` (RESEARCH Pattern 2). Surface points arrive as an R-flattened cloud (see `.gmw_flat` below); delete = nearest cloud point → `sendBeacon("delete","kind,idx")`.

**Template-injection constraint** — new JS goes in the parameter-free BODY after the `MESH_URL = "%s";` marker; the sprintf'd HEAD must stay under the 8192-byte `fmt` cap (view3d.R:81-96). Source-scan test enforces the wiring (see test analog below).

**Row-major flatten helper** — R sends surface/overlay coords with `.gmw_flat`, which already applies the mandatory transpose (`as.vector(t(m))`) — reuse it, do NOT hand-roll:

```23:28:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
.gmw_flat <- function(m, digits = 6) {
  m <- as.matrix(m)
  v <- as.vector(t(m))
  v[!is.finite(v)] <- 0
  paste0("[", paste(formatC(v, format = "f", digits = digits), collapse = ","), "]")
}
```

---

### `R/3dDigitize.main.r` — deterministic `.dgt` writer (utility, file-I/O write)

**Analog (edit-in-place):** `.dgt_format_num` (203-205), `.dgt_write_matrix_block` (207-215), `saveToDgt` (1931-2026), pinned-EOL precedent in `mergeDgt` (3440).

**Current formatter (the bug — libc tie-breaking decides the 6th decimal):**

```203:215:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
.dgt_format_num <- function(x) {
  formatC(as.numeric(x), format = "f", digits = 6)
}

.dgt_write_matrix_block <- function(file_name, header_key, mat) {
  rows <- if (is.null(dim(mat))) 0L else as.integer(nrow(mat))
  write(paste0(header_key, rows), file_name, append = TRUE)
  if (rows > 0L) {
    lines <- apply(mat, 1L, function(row) paste(.dgt_format_num(row), collapse = " "))
    write(lines, file_name, append = TRUE)
  }
  invisible(TRUE)
}
```

**Fix (DAT-01 prerequisite):** wrap with `round(as.numeric(x), 6)` so R rounding, not libc, decides the 6th decimal, AND pin ONE line terminator instead of `write()`'s platform EOL. The pinned-EOL precedent already in-repo:

```3440:3440:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
  con <- file(output, open = "wb"); writeLines(out, con, sep = "\r\n"); close(con)
```

**Writer call-shape to keep identical for browser Save** — `saveToDgt` (1931-2026) is the ONE serializer; route the browser trigger through the SAME `.dgt_write_matrix_block` calls (`Curve=`, `TemplateNumber=NULL`, per-specimen `LM3=`/`AC3=`/`ID=`/`Template=`/`Surface=`). Do NOT add a second serializer (RESEARCH Anti-Patterns). The one coupling to change: read arrays from the session model instead of `getLandmark(i)`/`getAnchor(i)`:

```2005:2018:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
    .dgt_write_matrix_block(fileName, "LM3=", landmarks)
    .dgt_write_matrix_block(fileName, "AC3=", anchors)
    write(paste0("ID=", specimenId), fileName, append = TRUE)

    if(1)
    {
      dbg(paste("writing surface data"))
      ################### write surface #####################
      tempt <- e$activeDataList[[i]][[5]]
      surface <- e$activeDataList[[i]][[8]]
      if (!is.null(tempt)) {
        write(paste0("Template=", tempt), fileName, append = TRUE)
      }
      .dgt_write_matrix_block(fileName, "Surface=", surface)
    }
```

---

### `R/3dDigitize.geomorph.r` — session-model read source (service, transform/batch)

**Analog (edit-in-place):** `.landmarks_for_specimen` (162-173) + `.build_geomorph_data` (203-220).

**The read-source seam to extend** — `.landmarks_for_specimen` already has a C-primary / `activeDataList[[10]]`-fallback ladder. Add a session-model source (cleanest: populate the same `activeDataList` slots from the session so `compute`/`save`/`exportGeomorph` are reused with zero edits — RESEARCH Open Question 3):

```162:173:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r
.landmarks_for_specimen <- function(e, i) {
  expected <- as.numeric(e$landmarkNum)
  from_c <- getLandmark(i)
  if (!is.null(from_c) && nrow(from_c) == expected) {
    return(from_c)
  }
  stored <- e$activeDataList[[i]][[10]]
  if (!is.null(stored) && is.matrix(stored) && nrow(stored) == expected) {
    return(stored)
  }
  from_c
}
```

**Curves-are-indices contract to preserve** — `.build_geomorph_data` reads curves as a 3-col INDEX matrix from `activeDataList[[1]][[4]]` (session-scoped, shared across specimens). Keep this shape (RESEARCH Pitfall 5):

```224:233:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r
  curves <- NULL
  if (itob(tclvalue(e$curves))) {
    curves <- matrix(e$activeDataList[[1]][[4]],ncol=3)
  }
  # when read from .nts file curves are a list and error is given:  Error in x[s[, 3], ] : invalid subscript type 'list'
  # It must be unlisted
  # and re-matrixed as so:
  if (is.list(curves)){
    curves<-matrix(unlist(curves),ncol=3)
  }
```

`compute` (326+) forwards the gpagen options (`max.iter`, `PrinAxes`, `ProcD`, `Proj`, `approxBE`, `Parallel`, curves/surfaces) — leave forwarding untouched; `test-gpa-parity.R` already asserts it.

---

### `R/3dDigitize.surface.r` — headless downsample entry (service, transform)

**Analog (reuse):** `downSample` (400-567); the mandatory transpose is already at 548.

**The transpose to mirror when sending surfaces to the browser** — `downSample` itself flattens row-major with `as.vector(t(...))`; the browser display path must do the SAME (RESEARCH Pitfall 1):

```548:559:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.surface.r
  vertToDownsample <- as.vector(t(selected.out))
  ##print (vertToDownsample)




  add("downsample", vertToDownsample, e$currImgId)
  file.remove(ntsFile)
  disableOper(e, F)

  e$activeDataList[[e$currImgId]][[5]] <- e$templOrig
  e$activeDataList[[e$currImgId]][[8]] <- sliders
```

Add a thin headless entry the `/downsample` route calls: run the existing TPS warp (unchanged), store `surfaces` in the session record, return `as.vector(t(surfaces[,,id]))` for the cloud. Do NOT call the C `add("downsample", ...)` from the browser path (that re-couples to `tkogl2`).

---

## Shared Patterns

### Server-owns-state (env keyed by token)
**Source:** `.gmw_picks` (transport.R:58), `.gmw_server`/`.gmw_lifecycle` (43-49).
**Apply to:** the new `.gmw_session` env + all route handlers.
- Keep each new package env SEPARATE from `.gmw_server` (token→handle purity).
- R is the single authoritative copy; the browser only reports edits.

### Bounded, JSON-free body parse (input validation, ASVS V5)
**Source:** `.gmw_pick_handler` body branch (transport.R:182-188).
**Apply to:** every new route (anchor/curve/delete/undo/specimen/export).
```r
body <- tryCatch(rawToChar(req$rook.input$read()), error = function(e) "")
xyz  <- suppressWarnings(as.numeric(strsplit(body, ",", fixed = TRUE)[[1]]))
if (length(xyz) == 3L && all(is.finite(xyz))) { ... }   # else silently drop
```
Never `eval`, never treat body/path as a filename; export "fmt" from an allow-list only.

### No path-join on the request path (path-traversal, T-2-02)
**Source:** `grepl("/pick$", path)` (transport.R:179); `.gmw_close_handler` (137-146).
**Apply to:** all new route handlers — `grepl` the suffix only; never `file.path`/`normalizePath`/`readBin` on `req$PATH_INFO`.

### One-deep undo action grammar
**Source:** `pushUndo`/`clearUndo`/`doUndo` (3dDigitize.digitize.r:59-155).
**Apply to:** session-side undo (`.gmw_session[[token]]$undo`). Actions `place`/`delete`/`move`/`curve_place`; `pushUndo` OVERWRITES (one-deep); `clearUndo` on specimen switch.
```59:69:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r
pushUndo <- function(e, entry) {
  e$undo <- entry
}


clearUndo <- function(e) {
  e$undo <- NULL
  e$dragDot <- FALSE
  e$dragX <- -1L
  e$dragY <- -1L
}
```
Delete/undo semantics to mirror (record coord + kind so undo can restore): `deleteLandmark`/`deleteAnchor` (digitize.r:922-965).

### Deterministic file emission (round + pinned EOL)
**Source:** `.dgt_format_num` (main.r:203) + `mergeDgt` wb pin (main.r:3440).
**Apply to:** `.dgt_write_matrix_block` and any browser Save path. `.gitattributes` already marks `*.dgt -text`.

### Debug logging + error style
**Source:** `dbg()` fallback (transport.R:36-38); `stop(..., call.=FALSE)` (transport.R:225-230).
**Apply to:** all new R code — `dbg()` gated printer only (no raw `print`); `stop(call.=FALSE)` for hard failures; handlers return `204`/`404`.

## Test Patterns

### Direct-handler unit test with a synthetic `req` (no live server)
**Source:** `test-picking-transport.R` `make_req` + direct-invocation (18-50).
**Apply to:** `test-digitizing-session.R` — build a synthetic `req`, call the production handler closure directly, assert `204` + session mutation.
```18:24:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-picking-transport.R
make_req <- function(path, body = NULL) {
  raw_body <- if (is.null(body)) raw(0) else charToRaw(body)
  list(
    PATH_INFO  = path,
    rook.input = list(read = function(...) raw_body)
  )
}
```

### Source-scan the template wiring (no browser)
**Source:** `test-picking-view3d.R` (9-26) — `readLines` + `grepl`, `skip_if_no_pkg_source()`.
**Apply to:** `test-digitizing-view3d.R` — assert the new anchor/curve/surface/delete/undo JS + cyan/blue recolor tokens are present in `view3d.R`.

### Byte-identity + `.dgt_normalize_lines` writer test
**Source:** `test-dgt-cross-platform.R` (7-73) — `.byte_signature` md5 helper + writer-vs-fixture.
**Apply to:** `test-dgt-determinism.R` (round + pinned EOL; browser-write == native-write bytes) and the extended cross-platform gate. The DAT-01 assertion:
```299:303:.planning/phases/05-full-digitizing-and-data-parity/05-RESEARCH.md
# .byte_signature() (test-dgt-cross-platform.R:7-13) raw-md5s a file.
expect_identical(.byte_signature(browser_written_dgt),
                 .byte_signature(native_written_dgt))
```

### Skip-if-absent gate (CMP-01 native oracle + owed fixtures)
**Source:** `test-retina-picking-parity.R` `native_src()` + `skip_if(is.na(...))` (6-17); `test-dgt-cross-platform.R` (82-87).
**Apply to:** the CMP-01 load check and the DAT-02 `-rewrite` fixture gate — `skip()` with the reason until the external evidence lands. NEVER touch `rtkogl.R` `.onLoad`/`.gmw_require_engine`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `tests/fixtures/parity/windows-authored-roundtrip-rewrite.dgt` | fixture (data) | file | External Windows re-save evidence; no code to model. Gate stays a documented `skip()` (test-dgt-cross-platform.R:82-87) until produced. |
| `tests/fixtures/parity/mac-authored-roundtrip-rewrite.dgt` | fixture (data) | file | Windows re-save of the mac file; external. Same skip idiom. |

## Metadata

**Analog search scope:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/` (all 11 modules) and `tests/testthat/` (22 files).
**Files scanned:** transport.R, view3d.R, 3dDigitize.main.r, 3dDigitize.curve.r, 3dDigitize.digitize.r, 3dDigitize.surface.r, 3dDigitize.geomorph.r; test-dgt-cross-platform.R, test-picking-transport.R, test-picking-view3d.R, test-retina-picking-parity.R.
**Pattern extraction date:** 2026-08-07
