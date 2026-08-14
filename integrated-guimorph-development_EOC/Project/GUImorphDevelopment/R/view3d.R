# ---------------------------------------------------------------------------
#  view3d.R -- minimal R wrapper over the vendored three.js bundle (WEB-00)
#
#  Writes a self-contained HTML page next to a copy of
#  inst/htmlwidgets/guimorphweb-three.js and opens it with browseURL(). Same
#  delivery shape as .rgl_show() and .plot_show(), so nothing new is asked of
#  the user, and htmlwidgets stays in Suggests.
#
#  The bundle is a classic script exposing one global (GMW) because three.js
#  ships ES modules only from 0.160 and ES modules are CORS-blocked on file://.
#  See inst/htmlwidgets/VENDOR-MANIFEST.json and scripts/vendor/.
#
#  Coordinates go into the page as flat numeric arrays rather than JSON objects:
#  three.js wants a flat Float32Array anyway, so this avoids both a reshape in
#  JS and a JSON dependency in R.
#
#  Phase 2 (WEB-02) reuses this page structure with the geometry fetched over
#  httpuv instead of inlined, and Phase 4 (PICK-01) adds the raycast. The BVH
#  prototype patches are already live in the bundle.
# ---------------------------------------------------------------------------

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

#' Build the GUImorphWeb three.js viewport page as an HTML string
#'
#' Assembles \code{GMW_VIEW3D_TEMPLATE} into a self-contained page and returns
#' it as a character scalar. Kept separate from \code{.gmw_view3d} so callers
#' that serve the page over HTTP (Phase 2 transport, \code{mesh_url}) can obtain
#' the markup without the file:// tempdir + browseURL delivery.
#'
#' @param clouds list of point layers, each
#'   \code{list(coords = <p x 3 matrix>, color = "#rrggbb", size = <numeric>)}.
#' @param mesh optional inlined mesh \code{list(vertices = <p x 3>,
#'   faces = <3 x f>, color = "#rrggbb", wireframe = <logical>)}.
#' @param mesh_url optional same-origin URL/filename of a PLY to fetch and render
#'   as a solid shaded surface. When non-empty, geometry is loaded asynchronously
#'   via \code{GMW.PLYLoader} and the camera is framed after the load completes.
#' @param title window/page title.
#' @param background page background colour.
#' @return the HTML page as a length-1 character string.
#' @keywords internal
#' @noRd
.gmw_view3d_html <- function(clouds = list(), mesh = NULL, mesh_url = "",
                             title = "GUImorphWeb", background = "#ffffff") {
  cloud_js <- vapply(clouds, function(cl) {
    sprintf("{p:%s,c:'%s',s:%s}",
            .gmw_flat(cl$coords),
            if (is.null(cl$color)) "#000000" else cl$color,
            format(if (is.null(cl$size)) 3 else cl$size))
  }, character(1))
  cloud_js <- paste0("[", paste(cloud_js, collapse = ","), "]")

  mesh_js <- if (is.null(mesh)) "null" else sprintf(
    "{v:%s,f:%s,c:'%s',w:%s}",
    .gmw_flat(mesh$vertices), .gmw_faces(mesh$faces),
    if (is.null(mesh$color)) "#cccccc" else mesh$color,
    if (isTRUE(mesh$wireframe)) "true" else "false")

  # Render note: base-R sprintf caps a single `fmt` string at 8192 bytes. Every
  # %s injection slot lives in the parameterised HEAD (up to and including the
  # `MESH_URL = "%s";` globals line); everything after it is a parameter-free JS
  # BODY whose only format token is the doubled `%%`. Splitting there keeps the
  # sprintf'd fmt tiny (well under the cap even as the JS body grows with the
  # picking wiring) while the byte-for-byte output is identical to a single
  # sprintf over the whole template.
  marker <- 'MESH_URL = "%s";'
  at <- regexpr(marker, GMW_VIEW3D_TEMPLATE, fixed = TRUE)
  cut <- at + attr(at, "match.length")
  head_fmt <- substr(GMW_VIEW3D_TEMPLATE, 1L, cut - 1L)
  body_raw <- substr(GMW_VIEW3D_TEMPLATE, cut, nchar(GMW_VIEW3D_TEMPLATE))
  paste0(
    sprintf(head_fmt, title, background, background, cloud_js, mesh_js, mesh_url),
    gsub("%%", "%", body_raw, fixed = TRUE)
  )
}

#' Render point clouds and an optional mesh in a browser viewport
#'
#' @param clouds list of point layers, each
#'   \code{list(coords = <p x 3 matrix>, color = "#rrggbb", size = <numeric>)}.
#' @param mesh optional \code{list(vertices = <p x 3>, faces = <3 x f>,
#'   color = "#rrggbb", wireframe = <logical>)}.
#' @param title window/page title.
#' @param background page background colour.
#' @return the HTML file path, invisibly.
#' @keywords internal
#' @noRd
.gmw_view3d <- function(clouds = list(), mesh = NULL,
                        title = "GUImorphWeb", background = "#ffffff") {
  dir <- tempfile(pattern = "guimorphweb-")
  dir.create(dir)
  file.copy(.gmw_bundle_path(), file.path(dir, "guimorphweb-three.js"))

  html <- .gmw_view3d_html(clouds = clouds, mesh = mesh, mesh_url = "",
                           title = title, background = background)
  f <- file.path(dir, "index.html")
  writeLines(html, f, useBytes = TRUE)
  utils::browseURL(f)
  message("Viewport: ", f)
  invisible(f)
}

GMW_VIEW3D_TEMPLATE <- '<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>%s</title>
<style>
  html,body{margin:0;height:100%%;overflow:hidden;background:%s;
            font:13px system-ui,sans-serif}
  #c{display:block;width:100%%;height:100%%}
  #h{position:fixed;left:12px;bottom:12px;color:#555;
     background:rgba(255,255,255,.85);padding:6px 9px;border-radius:4px}
  kbd{background:#eee;border:1px solid #ccc;border-radius:3px;padding:0 4px}
  #t{position:fixed;left:12px;top:12px;display:flex;gap:6px;flex-wrap:wrap}
  #t button{font:12px system-ui,sans-serif;padding:3px 8px;border:1px solid #bbb;
     border-radius:4px;background:rgba(255,255,255,.9);cursor:pointer}
  #t button:hover{background:#eef}
  #t .sep{width:1px;background:#ccc;margin:0 2px}
</style></head><body>
<canvas id="c"></canvas>
<div id="t">
  <button id="btn-l" type="button">Landmark</button>
  <button id="btn-a" type="button">Anchor</button>
  <button id="btn-c" type="button">Curve</button>
  <button id="btn-d" type="button">Delete</button>
  <button id="btn-u" type="button">Undo</button>
  <span class="sep"></span>
  <button id="btn-ds" type="button">Downsample</button>
  <button id="btn-gpa" type="button">GPA</button>
  <button id="btn-csv" type="button">Export CSV</button>
  <button id="btn-rds" type="button">Export RDS</button>
  <button id="btn-save" type="button">Save .dgt</button>
</div>
<div id="h">drag rotate &middot; scroll zoom &middot; <kbd>r</kbd> reset &middot;
  <kbd>l</kbd> landmark &middot; <kbd>a</kbd> anchor &middot; <kbd>c</kbd> curve (click 3 landmarks) &middot;
  <kbd>d</kbd> delete &middot; <kbd>u</kbd> undo &middot; mode: <b id="m">landmark</b></div>
<script src="guimorphweb-three.js"></script>
<script>
(function(){
  var THREE = GMW.THREE, OrbitControls = GMW.OrbitControls, PLYLoader = GMW.PLYLoader;
  var BG = "%s", CLOUDS = %s, MESH = %s, MESH_URL = "%s";

  var canvas = document.getElementById("c");
  var renderer = new THREE.WebGLRenderer({canvas:canvas, antialias:true});
  renderer.setPixelRatio(window.devicePixelRatio || 1);
  // Canvas covers the page, so the CSS background never shows; the clear
  // colour is what paints. Default white, matching rgl.
  renderer.setClearColor(new THREE.Color(BG), 1);
  var scene = new THREE.Scene();
  var camera = new THREE.PerspectiveCamera(45, 1, 0.01, 5000);
  var group = new THREE.Group();
  scene.add(group);
  scene.add(new THREE.AmbientLight(0xffffff, 0.75));
  var key = new THREE.DirectionalLight(0xffffff, 0.65);
  key.position.set(1,1,1);
  camera.add(key);
  scene.add(camera);

  function attr(flat){
    var g = new THREE.BufferGeometry();
    g.setAttribute("position",
      new THREE.BufferAttribute(new Float32Array(flat), 3));
    return g;
  }

  var controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;

  // Camera pull-back distance from framing. Hoisted to the IIFE scope so that
  // reset() and the r-key handler resolve it whether framing runs synchronously
  // (point-cloud / inlined-mesh path) or is deferred into the async PLY load
  // callback (mesh-URL path).
  var dist = 1;

  // Picking state (PICK-01 browser half). pickMesh is populated once the PLY
  // load callback runs; the pointer handler must no-op until then. The
  // raycaster + reusable NDC vector are hoisted so no allocation happens per
  // click. RESEARCH Pattern 1.
  var pickMesh = null;
  var raycaster = new THREE.Raycaster();
  var ndc = new THREE.Vector2();

  // Overlay for placed landmarks (PICK-02). A dedicated group, sibling to the
  // mesh `group`, so its dots are NEVER part of intersectObject(pickMesh, false)
  // and can never be re-picked or shift a subsequent hit (T-4-07).
  var overlay = new THREE.Group();
  scene.add(overlay);

  // Draw a placed landmark at the WORLD-space hit so it sits on the visible
  // surface. depthTest:true means a dot on the far side is occluded by the mesh
  // under rotation (PICK-02 criterion 2). Radius is scaled from the framed size
  // (`dist`) so it reads consistently across specimens.
  function addOverlayDot(worldPoint){
    var dot = new THREE.Mesh(
      new THREE.SphereGeometry(dist * 0.01, 16, 12),
      new THREE.MeshBasicMaterial({ color: 0xff2222, depthTest: true })
    );
    dot.position.copy(worldPoint);
    overlay.add(dot);
  }

  // Digitizing mode (05-03, DGT-01/02). Default "landmark" keeps the Phase-4
  // pick untouched; keys switch to anchor/curve/delete and back. R owns every
  // edit; the browser only reports over the same relative loopback routes the
  // pick already uses.
  var mode = "landmark";

  // Anchor overlay (DGT-01). A SECOND group, sibling to `overlay`, added to the
  // scene and NEVER passed to intersectObject(pickMesh, false) -- a green anchor
  // dot is never a raycast target and can never shift a landmark hit (T-4-07).
  var anchors = new THREE.Group();
  scene.add(anchors);

  // Green anchor dot (native anchor colour 0x00ff00), same depth-tested sphere
  // as addOverlayDot so it occludes correctly under rotation.
  function addAnchorDot(worldPoint){
    var dot = new THREE.Mesh(
      new THREE.SphereGeometry(dist * 0.01, 16, 12),
      new THREE.MeshBasicMaterial({ color: 0x00ff00, depthTest: true })
    );
    dot.position.copy(worldPoint);
    anchors.add(dot);
  }

  // Surface semilandmark cloud (05-03, DGT-02). R computes the surfaces
  // (downSample TPS warp, 05-04) and delivers them PRE-FLATTENED row-major via
  // .gmw_flat; the browser only DISPLAYS them as a THREE.Points layer in its own
  // group and never recomputes them. Kept sibling to overlay/anchors and out of
  // intersectObject so a surface point is never a mesh-raycast target.
  var surfaces = new THREE.Group();
  scene.add(surfaces);
  var surfacePts = null;

  function addSurfaceCloud(flat){
    var g = new THREE.BufferGeometry();
    g.setAttribute("position",
      new THREE.BufferAttribute(new Float32Array(flat), 3));
    surfacePts = new THREE.Points(g, new THREE.PointsMaterial({
      color: 0xff8800, size: 3, sizeAttenuation: false
    }));
    surfaces.add(surfacePts);
  }

  // Replace the surface cloud from a bare-CSV "x1,y1,z1,x2,..." R response
  // (JSON-free, the same .gmw_flat wire shape R already emits for clouds).
  function redrawSurfaces(csv){
    surfaces.clear();
    surfacePts = null;
    var nums = (csv || "").split(",").map(Number)
                 .filter(function(x){ return isFinite(x); });
    if (nums.length >= 3) addSurfaceCloud(nums);
  }

  function reset(){
    camera.position.set(0, 0, dist);
    camera.near = dist / 100; camera.far = dist * 100;
    camera.updateProjectionMatrix();
    controls.target.set(0,0,0);
    controls.update();
  }

  // Frame the whole scene: centre at the bounding-sphere centre and pull the
  // camera back far enough that the sphere fits the vertical FOV. Equivalent to
  // rgl aspect3d("iso") plus an automatic fit. Called after geometry is present
  // -- synchronously for clouds/inlined mesh, deferred for the mesh-URL path.
  function frameScene(){
    var box = new THREE.Box3().setFromObject(group);
    var sphere = box.getBoundingSphere(new THREE.Sphere());
    var home = sphere.radius > 0 ? sphere.radius : 1;
    dist = home / Math.sin((camera.fov * Math.PI / 180) / 2) * 1.15;
    group.position.sub(sphere.center);
    reset();
  }

  CLOUDS.forEach(function(cl){
    var g = attr(cl.p);
    group.add(new THREE.Points(g, new THREE.PointsMaterial({
      color: cl.c, size: cl.s, sizeAttenuation: false
    })));
  });

  if (MESH) {
    var g = attr(MESH.v);
    g.setIndex(MESH.f);
    g.computeVertexNormals();
    group.add(new THREE.Mesh(g, new THREE.MeshLambertMaterial({
      color: MESH.c, wireframe: MESH.w, side: THREE.DoubleSide
    })));
  }

  if (MESH_URL) {
    // Async fetch of a served PLY (same-origin, avoids CORS). The reference
    // meshes carry no vertex normals, so compute them in the callback or the
    // Lambert surface renders black. Scan RGB is intentionally ignored: the
    // material sets colour + DoubleSide only (per-vertex scan colour stays
    // off). Framing is deferred to here: the geometry is absent at first paint.
    new PLYLoader().load(MESH_URL, function(geometry){
      geometry.computeVertexNormals();
      // Eager BVH build: engages the bundle\'s patched accelerated raycast and
      // folds the build cost into load, not the first click (RESEARCH Pitfall 5).
      geometry.computeBoundsTree();
      // Retain the mesh so the pointer handler can raycast it. Kept in the
      // recentred `group` for interactive framing; the replay path (GMW_REPLAY)
      // builds its own identity mesh from this geometry instead.
      pickMesh = new THREE.Mesh(geometry, new THREE.MeshLambertMaterial({
        color: "#cccccc", side: THREE.DoubleSide
      }));
      group.add(pickMesh);
      frameScene();
    }, function(e){
      // onProgress: e.loaded / e.total (the 30 MB worst case streams here).
      if (e && e.lengthComputable) {
        var pct = Math.round((e.loaded / e.total) * 100);
        document.getElementById("h").textContent = "Loading mesh " + pct + "%%";
      }
    }, function(e){
      // onError: surface a legible message in the HUD instead of failing silent.
      var msg = (e && e.message) ? e.message : String(e);
      document.getElementById("h").textContent = "Failed to load mesh: " + msg;
    });
  } else {
    frameScene();
  }

  function resize(){
    var w = canvas.clientWidth, h = canvas.clientHeight;
    if (!w || !h) return;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  }
  window.addEventListener("resize", resize);
  window.addEventListener("keydown", function(e){
    if (e.key === "r" || e.key === "R") reset();
  });

  // Interactive pick (PICK-01 browser half). On pointerdown, cast a
  // BVH-accelerated ray through the clicked pixel and, on a hit, report the
  // mesh-LOCAL (raw PLY-vertex) coordinate to R. NDC uses the canvas rect with
  // a SINGLE Y-flip (RESEARCH Pitfall 1). intersectObject(pickMesh, false) is
  // non-recursive so placed overlay dots are never re-hit (T-4-07). worldToLocal
  // is preceded by an explicit updateWorldMatrix so a mid-rotation click never
  // reads a stale matrix (RESEARCH anti-pattern). The report mirrors the /close
  // beacon: navigator.sendBeacon("pick", ...) is a RELATIVE target that resolves
  // same-origin to /<token>/pick -- no absolute URL, no external ref (WEB-03).
  canvas.addEventListener("pointerdown", function(ev){
    if (!pickMesh || mode !== "landmark") return;
    var r = canvas.getBoundingClientRect();
    ndc.x = ((ev.clientX - r.left) / r.width) * 2 - 1;
    ndc.y = -((ev.clientY - r.top) / r.height) * 2 + 1;
    raycaster.setFromCamera(ndc, camera);
    var hits = raycaster.intersectObject(pickMesh, false);
    if (hits.length) {
      // Draw the dot at the world hit (visible surface) before worldToLocal
      // mutates the reported clone. A miss draws nothing -- silent no-op.
      addOverlayDot(hits[0].point);
      var p = hits[0].point.clone();
      pickMesh.updateWorldMatrix(true, false);
      pickMesh.worldToLocal(p);
      try { navigator.sendBeacon("pick", p.x + "," + p.y + "," + p.z); } catch(e){}
    }
  });

  // Anchor placement + curve-by-index selection (05-03, DGT-01). Active only in
  // the anchor / curve modes; the landmark path above owns "landmark". Anchor
  // mode is the pick pipeline VERBATIM (single Y-flip NDC, intersectObject(
  // pickMesh, false), updateWorldMatrix before worldToLocal to recover the raw
  // PLY-vertex frame) reporting to /anchor instead of /pick. Curve mode never
  // raycasts the mesh: it resolves the click to the NEAREST existing landmark
  // overlay dot INDEX (placement order == overlay.children order), recolours the
  // first pick cyan and the second blue (the slider), and on the third distinct
  // index reports i,j,k to /curve and resets (RESEARCH Pattern 2).
  var CURVE_CYAN = new THREE.Color(1/255,164/255,191/255);
  var CURVE_BLUE = new THREE.Color(0,0,1);            // 2nd point == slider
  var curveSel = [];

  function nearestOverlayIndex(ev){
    var r = canvas.getBoundingClientRect();
    var v = new THREE.Vector3();
    var best = -1, bestD2 = 24 * 24;                  // ~24px screen threshold
    for (var i = 0; i < overlay.children.length; i++){
      v.copy(overlay.children[i].position).project(camera);
      var sx = (v.x * 0.5 + 0.5) * r.width;
      var sy = (-v.y * 0.5 + 0.5) * r.height;
      var dx = sx - (ev.clientX - r.left), dy = sy - (ev.clientY - r.top);
      var d2 = dx * dx + dy * dy;
      if (d2 < bestD2){ bestD2 = d2; best = i; }
    }
    return best;
  }

  canvas.addEventListener("pointerdown", function(ev){
    if (mode === "anchor"){
      if (!pickMesh) return;
      var r = canvas.getBoundingClientRect();
      ndc.x = ((ev.clientX - r.left) / r.width) * 2 - 1;
      ndc.y = -((ev.clientY - r.top) / r.height) * 2 + 1;
      raycaster.setFromCamera(ndc, camera);
      var hits = raycaster.intersectObject(pickMesh, false);
      if (hits.length){
        addAnchorDot(hits[0].point);
        var p = hits[0].point.clone();
        pickMesh.updateWorldMatrix(true, false);
        pickMesh.worldToLocal(p);
        try { navigator.sendBeacon("anchor", p.x + "," + p.y + "," + p.z); } catch(e){}
      }
      return;
    }
    if (mode === "curve"){
      var idx = nearestOverlayIndex(ev);
      if (idx < 0 || curveSel.indexOf(idx) !== -1) return;
      curveSel.push(idx);
      var dot = overlay.children[idx];
      if (curveSel.length === 1) dot.material.color.copy(CURVE_CYAN);
      else if (curveSel.length === 2) dot.material.color.copy(CURVE_BLUE);
      if (curveSel.length === 3){
        var ijk = curveSel[0] + "," + curveSel[1] + "," + curveSel[2];
        try { navigator.sendBeacon("curve", ijk); } catch(e){}
        curveSel = [];
      }
    }
  });

  // Single mode setter shared by the keyboard shortcuts and the toolbar buttons.
  // Entering curve mode clears any half-finished 3-click selection; the live
  // "mode:" readout in the HUD is kept in sync so the active mode is discoverable.
  function setMode(m){
    mode = m;
    if (m === "curve") curveSel = [];
    var mi = document.getElementById("m"); if (mi) mi.textContent = mode;
    // Keep the shell status-bar mode readout (06-02) in sync with the HUD #m.
    var sm = document.getElementById("st-mode"); if (sm) sm.textContent = mode;
  }

  // Mode keys: (a)nchor, (c)urve, (l)andmark, (d)elete; (u)ndo fires at once.
  // Sibling to the r-key reset above.
  window.addEventListener("keydown", function(e){
    if (e.key === "a" || e.key === "A") setMode("anchor");
    else if (e.key === "c" || e.key === "C") setMode("curve");
    else if (e.key === "l" || e.key === "L") setMode("landmark");
    else if (e.key === "d" || e.key === "D") setMode("delete");
    else if (e.key === "u" || e.key === "U") doUndo();
  });

  // Delete + undo + specimen switch (05-03, DGT-02). R owns all state; the
  // browser reports edits over the relative loopback routes and re-reads the
  // re-served overlays. Screen-space distance of a WORLD position to the click.
  function screenDist2(ev, worldPos){
    var r = canvas.getBoundingClientRect();
    var v = worldPos.clone().project(camera);
    var sx = (v.x * 0.5 + 0.5) * r.width, sy = (-v.y * 0.5 + 0.5) * r.height;
    var dx = sx - (ev.clientX - r.left), dy = sy - (ev.clientY - r.top);
    return dx * dx + dy * dy;
  }

  // Delete mode: click resolves the nearest editable marker across the landmark,
  // anchor, and surface layers to its kind + INDEX and reports it to /delete; R
  // removes that row (one-deep undo) and the layer is re-served/redrawn.
  canvas.addEventListener("pointerdown", function(ev){
    if (mode !== "delete") return;
    var best = { kind: null, idx: -1, d2: 24 * 24 };
    var i, p = new THREE.Vector3();
    for (i = 0; i < overlay.children.length; i++){
      var dL = screenDist2(ev, overlay.children[i].position);
      if (dL < best.d2) best = { kind: "landmark", idx: i, d2: dL };
    }
    for (i = 0; i < anchors.children.length; i++){
      var dA = screenDist2(ev, anchors.children[i].position);
      if (dA < best.d2) best = { kind: "anchor", idx: i, d2: dA };
    }
    if (surfacePts){
      var pos = surfacePts.geometry.getAttribute("position");
      for (i = 0; i < pos.count; i++){
        p.set(pos.getX(i), pos.getY(i), pos.getZ(i));
        surfacePts.localToWorld(p);
        var dS = screenDist2(ev, p);
        if (dS < best.d2) best = { kind: "surface", idx: i, d2: dS };
      }
    }
    if (best.idx >= 0){
      try { navigator.sendBeacon("delete", best.kind + "," + best.idx); } catch(e){}
      redraw();
    }
  });

  // Pull one "tag=flat" field out of the "L=..;A=..;S=.." overlays payload.
  function fieldOf(txt, tag){
    var parts = (txt || "").split(";");
    for (var i = 0; i < parts.length; i++){
      var eq = parts[i].indexOf("=");
      if (eq > 0 && parts[i].substring(0, eq) === tag)
        return parts[i].substring(eq + 1);
    }
    return "";
  }
  function parseFlat(s){
    return (s || "").split(",").map(Number)
             .filter(function(x){ return isFinite(x); });
  }

  // Rebuild ONE dot layer (landmark or anchor) from a row-major list of
  // mesh-LOCAL coords. Convert to world through the loaded pickMesh so a
  // re-served dot lands exactly where placement put it (placement reports
  // worldToLocal of the pick, so localToWorld is its exact inverse).
  function rebuildDotLayer(grp, nums, colorHex){
    grp.clear();
    if (pickMesh) pickMesh.updateWorldMatrix(true, false);
    var n = nums.length - (nums.length % 3);
    for (var k = 0; k < n; k += 3){
      var v = new THREE.Vector3(nums[k], nums[k + 1], nums[k + 2]);
      if (pickMesh) pickMesh.localToWorld(v);
      var dot = new THREE.Mesh(
        new THREE.SphereGeometry(dist * 0.01, 16, 12),
        new THREE.MeshBasicMaterial({ color: colorHex, depthTest: true }));
      dot.position.copy(v);
      grp.add(dot);
    }
  }

  // Re-read the ACTIVE specimen\'s overlays ("L=..;A=..;S=..", JSON-free) from
  // the /overlays re-serve route and rebuild EVERY layer, so server-side edits
  // (delete/undo) and specimen switches are reflected in the viewport. A missing
  // route or transport error leaves the current layers untouched.
  function redraw(){
    fetch("overlays", { method: "GET" }).then(function(r){ return r.text(); })
      .then(function(txt){
        rebuildDotLayer(overlay, parseFlat(fieldOf(txt, "L")), 0xff2222);
        rebuildDotLayer(anchors, parseFlat(fieldOf(txt, "A")), 0x00ff00);
        surfaces.clear(); surfacePts = null;
        var sf = parseFlat(fieldOf(txt, "S"));
        if (sf.length >= 3){
          if (pickMesh) pickMesh.updateWorldMatrix(true, false);
          var world = [];
          for (var k = 0; k + 2 < sf.length; k += 3){
            var v = new THREE.Vector3(sf[k], sf[k + 1], sf[k + 2]);
            if (pickMesh) pickMesh.localToWorld(v);
            world.push(v.x, v.y, v.z);
          }
          addSurfaceCloud(world);
        }
      }).catch(function(){});
  }

  function doUndo(){
    try { navigator.sendBeacon("undo", ""); } catch(e){}
    redraw();
  }

  // Load a re-served specimen mesh and rebuild the BVH on the NEW pickMesh; the
  // old mesh/BVH is discarded so a switch never raycasts a stale tree (Pitfall
  // 4). Overlays are cleared and re-placed for the incoming specimen.
  function loadSpecimen(url){
    if (pickMesh){ group.remove(pickMesh); pickMesh = null; }
    overlay.clear(); anchors.clear(); surfaces.clear(); surfacePts = null;
    new PLYLoader().load(url, function(geometry){
      geometry.computeVertexNormals();
      geometry.computeBoundsTree();
      pickMesh = new THREE.Mesh(geometry, new THREE.MeshLambertMaterial({
        color: "#cccccc", side: THREE.DoubleSide
      }));
      group.add(pickMesh);
      frameScene();
    });
  }

  // Specimen switch (RE-SERVE, A4): report the target index to /specimen, then
  // load the returned mesh URL (first CSV line of the re-serve response) and
  // redraw the overlays for the incoming specimen.
  function switchSpecimen(n){
    try { navigator.sendBeacon("specimen", String(n)); } catch(e){}
    fetch("specimen", { method: "POST", body: String(n) })
      .then(function(r){ return r.text(); })
      .then(function(txt){
        var url = (txt || "").split("\\n")[0];
        if (url) loadSpecimen(url);
        redraw();
      }).catch(function(){});
  }
  window.GMW_SWITCH_SPECIMEN = switchSpecimen;

  // Toolbar wiring (DGT-02/DGT-03). The mode buttons mirror the keyboard
  // shortcuts; the analytical buttons POST to the same loopback routes R already
  // owns (/downsample, /gpa, /export, /save) and then redraw() re-reads the
  // re-served overlays so a computed surface cloud appears without a reload.
  function on(id, fn){
    var el = document.getElementById(id); if (el) el.addEventListener("click", fn);
  }
  function post(route, body){
    return fetch(route, { method: "POST", body: (body == null ? "" : String(body)) })
             .catch(function(){});
  }
  on("btn-l",  function(){ setMode("landmark"); });
  on("btn-a",  function(){ setMode("anchor"); });
  on("btn-c",  function(){ setMode("curve"); });
  on("btn-d",  function(){ setMode("delete"); });
  on("btn-u",  function(){ doUndo(); });
  on("btn-ds", function(){ post("downsample").then(redraw); });
  on("btn-gpa", function(){ post("gpa").then(redraw); });
  on("btn-csv", function(){ post("export", "csv"); });
  on("btn-rds", function(){ post("export", "rds"); });
  on("btn-save", function(){ post("save"); });

  // ===== Browser shell: menu bar / tab strip / status bar / modal (06-02) =====
  // The full Tk-parity chrome is injected from the parameter-free BODY (after
  // the MESH_URL marker) so the sprintf HEAD stays under the 8192-byte cap. The
  // DOM clones the #t toolbar idiom; its CSS is added as a <style> element built
  // here rather than in the HEAD <style> block for the same 8192-byte reason.
  // Every literal percent is doubled (%%) because the BODY is un-escaped once by
  // gsub("%%","%") after the split. buildShell only creates structure; the route
  // wiring lives in the shell-wiring block below.
  (function buildShell(){
    var css = [
      "#menubar{position:fixed;left:0;top:0;right:0;height:28px;display:flex;",
        "align-items:center;gap:2px;padding:0 6px;background:#f4f4f6;",
        "border-bottom:1px solid #ccc;font:13px system-ui,sans-serif;z-index:20}",
      ".menu{position:relative}",
      ".menu>button{background:none;border:0;padding:4px 10px;cursor:pointer;font:inherit}",
      ".menu>button:hover{background:#e2e2ea}",
      ".menu .items{display:none;position:absolute;left:0;top:100%%;min-width:150px;",
        "background:#fff;border:1px solid #bbb;box-shadow:0 2px 6px rgba(0,0,0,.15);z-index:21}",
      ".menu.open .items{display:block}",
      ".menu .items button{display:block;width:100%%;text-align:left;border:0;",
        "background:none;padding:6px 12px;cursor:pointer;font:inherit}",
      ".menu .items button:hover{background:#eef}",
      "#tabs{position:fixed;left:0;top:28px;right:0;height:30px;display:flex;gap:2px;",
        "padding:2px 6px 0;background:#ececf0;border-bottom:1px solid #ccc;z-index:19}",
      "#tabs button{border:1px solid #bbb;border-bottom:0;border-radius:5px 5px 0 0;",
        "background:#dcdce2;padding:4px 12px;cursor:pointer;font:12px system-ui,sans-serif}",
      "#tabs button.active{background:#fff;font-weight:600}",
      "#tabs button:disabled{color:#aaa;cursor:not-allowed;background:#e6e6ea}",
      "#status{position:fixed;left:0;right:0;bottom:0;height:24px;display:flex;",
        "align-items:center;gap:16px;padding:0 10px;background:#f4f4f6;",
        "border-top:1px solid #ccc;color:#333;font:12px system-ui,sans-serif;z-index:20}",
      "#status button{font:11px system-ui,sans-serif;padding:1px 7px;cursor:pointer}",
      "#modal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.35);",
        "z-index:50;align-items:center;justify-content:center}",
      "#modal.open{display:flex}",
      "#modal .box{background:#fff;border-radius:8px;min-width:300px;max-width:80vw;",
        "max-height:80vh;overflow:auto;box-shadow:0 8px 30px rgba(0,0,0,.3)}",
      "#modal h3{margin:0;padding:12px 16px;border-bottom:1px solid #eee;font:600 14px system-ui}",
      "#modal .mbody{padding:12px 16px}",
      "#modal .mfoot{padding:10px 16px;border-top:1px solid #eee;text-align:right}",
      "#modal .mfoot button{padding:5px 14px;margin-left:6px;cursor:pointer}",
      "#modal ul.picker{list-style:none;margin:0;padding:0;max-height:40vh;overflow:auto}",
      "#modal ul.picker li{padding:5px 8px;cursor:pointer;border-radius:4px}",
      "#modal ul.picker li:hover{background:#eef}",
      "#modal ul.picker li.sel{background:#dde7ff}",
      "#modal input[type=text]{width:100%%;box-sizing:border-box;padding:5px 7px;margin-top:8px}",
      "#t{top:64px}"
    ].join("");
    var st = document.createElement("style");
    st.textContent = css;
    document.head.appendChild(st);

    var bar = document.createElement("div");
    bar.id = "menubar";
    bar.innerHTML =
      "<div class=\"menu\" id=\"menu-file\">" +
        "<button type=\"button\">File</button>" +
        "<div class=\"items\">" +
          "<button type=\"button\" id=\"mi-load-ply\">Load PLY</button>" +
          "<button type=\"button\" id=\"mi-load-dgt\">Load DGT</button>" +
          "<button type=\"button\" id=\"mi-add-ply\">Add PLY</button>" +
          "<button type=\"button\" id=\"mi-save\">Save</button>" +
          "<button type=\"button\" id=\"mi-export-csv\">Export CSV</button>" +
          "<button type=\"button\" id=\"mi-export-rds\">Export RDS</button>" +
          "<button type=\"button\" id=\"mi-merge\">Merge</button>" +
        "</div>" +
      "</div>" +
      "<div class=\"menu\" id=\"menu-help\">" +
        "<button type=\"button\">Help</button>" +
        "<div class=\"items\">" +
          "<button type=\"button\" id=\"mi-help\">About and Shortcuts</button>" +
        "</div>" +
      "</div>";
    document.body.appendChild(bar);

    var tabs = document.createElement("div");
    tabs.id = "tabs";
    tabs.innerHTML =
      "<button type=\"button\" data-tab=\"digitize\" data-mode=\"landmark\">Digitize</button>" +
      "<button type=\"button\" data-tab=\"anchor\" data-mode=\"anchor\">Anchor</button>" +
      "<button type=\"button\" data-tab=\"surface\">Surface</button>" +
      "<button type=\"button\" data-tab=\"curve\" data-mode=\"curve\">Curve</button>" +
      "<button type=\"button\" data-tab=\"gpa\">GPA</button>";
    document.body.appendChild(tabs);

    var status = document.createElement("div");
    status.id = "status";
    status.innerHTML =
      "<span>Specimen <select id=\"sp-select\"></select></span>" +
      "<button type=\"button\" id=\"sp-prev\">&#9664; Prev</button>" +
      "<button type=\"button\" id=\"sp-next\">Next &#9654;</button>" +
      "<span>Mode: <b id=\"st-mode\">landmark</b></span>" +
      "<span>L:<b id=\"st-land\">0</b> A:<b id=\"st-anchor\">0</b> S:<b id=\"st-surface\">0</b></span>" +
      "<span style=\"margin-left:auto\">Color <input type=\"color\" id=\"st-color\" value=\"#ff2222\"></span>";
    document.body.appendChild(status);

    var modal = document.createElement("div");
    modal.id = "modal";
    modal.innerHTML =
      "<div class=\"box\">" +
        "<h3 id=\"modal-title\">Title</h3>" +
        "<div class=\"mbody\" id=\"modal-body\"></div>" +
        "<div class=\"mfoot\">" +
          "<button type=\"button\" id=\"modal-cancel\">Cancel</button>" +
          "<button type=\"button\" id=\"modal-ok\">OK</button>" +
        "</div>" +
      "</div>";
    document.body.appendChild(modal);
  })();

  // Reusable modal (replaces every Tk dialog). openModal renders a title, body
  // HTML, and an OK callback; the file picker, message box, color prompt, and
  // save-name field all render into this one container. A null onOk makes OK a
  // plain acknowledge button (message box).
  var modalOk = null;
  function openModal(title, bodyHTML, onOk, okLabel){
    document.getElementById("modal-title").textContent = title;
    document.getElementById("modal-body").innerHTML = bodyHTML;
    var okBtn = document.getElementById("modal-ok");
    okBtn.textContent = okLabel || "OK";
    modalOk = (typeof onOk === "function") ? onOk : null;
    document.getElementById("modal").classList.add("open");
  }
  function closeModal(){
    document.getElementById("modal").classList.remove("open");
    modalOk = null;
  }
  on("modal-ok", function(){ var f = modalOk; closeModal(); if (f) f(); });
  on("modal-cancel", closeModal);

  // Menu dropdowns: clicking a top-level menu button toggles its own list and
  // closes the others; a click anywhere else closes all of them.
  function closeAllMenus(){
    var open = document.querySelectorAll(".menu.open");
    for (var i = 0; i < open.length; i++) open[i].classList.remove("open");
  }
  (function wireMenuToggles(){
    var tops = document.querySelectorAll(".menu>button");
    for (var i = 0; i < tops.length; i++){
      (function(b){
        b.addEventListener("click", function(e){
          e.stopPropagation();
          var m = b.parentNode, wasOpen = m.classList.contains("open");
          closeAllMenus();
          if (!wasOpen) m.classList.add("open");
        });
      })(tops[i]);
    }
  })();
  document.addEventListener("click", closeAllMenus);

  // ---- Shell wiring (06-02): menus, tabs, specimen nav, dialogs, shortcuts ----
  // Every action drives the Plan-01 routes through the existing fetch()/post()
  // plumbing with RELATIVE same-origin route names (no absolute URLs, no JSON),
  // so the offline / server-owns-path invariants hold (T-6-07). R enumerates the
  // files; the browser returns only a basename R itself listed (T-6-06) and adds
  // no path logic of its own -- membership is enforced server-side.
  function esc(s){
    return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  }
  function setText(id, v){ var el = document.getElementById(id); if (el) el.textContent = v; }

  // File picker: fetch the R-enumerated /files listing and render it as a
  // single-select list. onChoose receives the chosen basename, which is posted
  // to /open (R re-validates membership before opening, T-6-06).
  function openPicker(title, okLabel, onChoose){
    fetch("files").then(function(r){ return r.text(); }).then(function(txt){
      var names = (txt || "").split("\\n").filter(function(x){ return x.length > 0; });
      if (!names.length){
        openModal(title, "<p>No .dgt or .ply files in the browse directory.</p>", null, "OK");
        return;
      }
      var rows = names.map(function(n){
        return "<li data-name=\"" + esc(n) + "\">" + esc(n) + "</li>";
      }).join("");
      var sel = null;
      openModal(title, "<ul class=\"picker\">" + rows + "</ul>", function(){
        if (sel) onChoose(sel);
      }, okLabel);
      var lis = document.querySelectorAll("#modal-body li");
      for (var i = 0; i < lis.length; i++){
        (function(li){
          li.addEventListener("click", function(){
            for (var j = 0; j < lis.length; j++) lis[j].classList.remove("sel");
            li.classList.add("sel");
            sel = li.getAttribute("data-name");
          });
        })(lis[i]);
      }
    }).catch(function(){});
  }

  // Multi-select picker + save-name field (RESEARCH A5): the shared modal for
  // Add PLY and Merge. onCommit receives the array of checked basenames and the
  // (optional) bare save-name, both routed R-side (/open, /savepath) -- the
  // browser never joins a path.
  function openMultiPicker(title, okLabel, onCommit){
    fetch("files").then(function(r){ return r.text(); }).then(function(txt){
      var names = (txt || "").split("\\n").filter(function(x){ return x.length > 0; });
      if (!names.length){
        openModal(title, "<p>No .dgt or .ply files in the browse directory.</p>", null, "OK");
        return;
      }
      var rows = names.map(function(n){
        return "<li><label><input type=\"checkbox\" value=\"" + esc(n) + "\"> " +
               esc(n) + "</label></li>";
      }).join("");
      var body = "<ul class=\"picker\">" + rows + "</ul>" +
                 "<input type=\"text\" id=\"pick-save\" placeholder=\"Save as (name, optional)\">";
      openModal(title, body, function(){
        var boxes = document.querySelectorAll("#modal-body input[type=checkbox]:checked");
        var chosen = [];
        for (var i = 0; i < boxes.length; i++) chosen.push(boxes[i].value);
        var nameEl = document.getElementById("pick-save");
        var name = nameEl ? nameEl.value : "";
        if (chosen.length) onCommit(chosen, name);
      }, okLabel);
    }).catch(function(){});
  }

  // Reusable message box (replaces tkmessageBox): a modal whose OK acks /msgack.
  function showMessage(title, text){
    openModal(title, "<p>" + esc(text) + "</p>", function(){ post("msgack"); }, "OK");
  }
  window.GMW_MESSAGE = showMessage;

  // File menu -> the Plan-01 routes.
  on("mi-load-ply", function(){
    openPicker("Load PLY", "Open", function(name){
      post("open", name).then(function(){ redraw(); refreshStatus(); });
    });
  });
  on("mi-load-dgt", function(){
    openPicker("Load DGT", "Open", function(name){
      post("open", name).then(function(){ redraw(); refreshStatus(); });
    });
  });
  on("mi-add-ply", function(){
    openMultiPicker("Add PLY", "Add", function(chosen, name){
      var seq = Promise.resolve();
      chosen.forEach(function(n){ seq = seq.then(function(){ return post("open", n); }); });
      if (name) seq = seq.then(function(){ return post("savepath", name); });
      seq.then(function(){ redraw(); refreshStatus(); });
    });
  });
  on("mi-merge", function(){
    openMultiPicker("Merge", "Merge and Save", function(chosen, name){
      var seq = Promise.resolve();
      chosen.forEach(function(n){ seq = seq.then(function(){ return post("open", n); }); });
      if (name) seq = seq.then(function(){ return post("savepath", name); });
      seq.then(function(){ return post("save"); })
         .then(function(){ redraw(); refreshStatus(); });
    });
  });
  on("mi-save", function(){
    openModal("Save",
      "<input type=\"text\" id=\"save-name\" placeholder=\"File name (optional)\">",
      function(){
        var el = document.getElementById("save-name");
        var nm = el ? el.value : "";
        var go = nm ? post("savepath", nm).then(function(){ return post("save"); })
                    : post("save");
        go.then(function(){ refreshStatus(); });
      }, "Save");
  });
  on("mi-export-csv", function(){ post("export", "csv"); });
  on("mi-export-rds", function(){ post("export", "rds"); });
  on("mi-help", function(){
    var msg = "<p>GUImorphWeb browser shell.</p><ul>" +
      "<li><b>l</b> / <b>a</b> / <b>c</b> / <b>d</b> &mdash; landmark / anchor / curve / delete</li>" +
      "<li><b>u</b> &mdash; undo &middot; <b>r</b> &mdash; reset view</li>" +
      "<li><b>[</b> / <b>]</b> &mdash; previous / next specimen</li>" +
      "<li><b>Ctrl/Cmd+S</b> &mdash; save</li></ul>";
    openModal("Help", msg, function(){ post("msgack"); }, "OK");
  });

  // Color picker (replaces tk_chooseColor): the native <input type=color> emits
  // a #rrggbb value posted verbatim to /color (R re-validates the hex, T-6-08).
  (function(){
    var ci = document.getElementById("st-color");
    if (ci) ci.addEventListener("change", function(){ post("color", ci.value); });
  })();

  // Tab strip: clicking a tab sets its digitizing mode (where applicable) and
  // marks it active; /tabstate greys tabs whose prerequisites are unmet.
  function selectTab(name){
    var btns = document.querySelectorAll("#tabs button");
    for (var i = 0; i < btns.length; i++)
      btns[i].classList.toggle("active", btns[i].getAttribute("data-tab") === name);
  }
  (function wireTabs(){
    var btns = document.querySelectorAll("#tabs button");
    for (var i = 0; i < btns.length; i++){
      (function(b){
        b.addEventListener("click", function(){
          if (b.disabled) return;
          var m = b.getAttribute("data-mode");
          if (m) setMode(m);
          selectTab(b.getAttribute("data-tab"));
        });
      })(btns[i]);
    }
    selectTab("digitize");
  })();
  function refreshTabState(){
    fetch("tabstate").then(function(r){ return r.text(); }).then(function(txt){
      var f = (txt || "").split(",").map(Number);
      var map = { digitize: f[0], anchor: f[1], surface: f[2], curve: f[2], gpa: f[3] };
      var btns = document.querySelectorAll("#tabs button");
      for (var i = 0; i < btns.length; i++){
        var t = btns[i].getAttribute("data-tab");
        btns[i].disabled = (map[t] === 0);
      }
    }).catch(function(){});
  }

  // Specimen navigation: prev/next buttons and the <select> all route through
  // the existing switchSpecimen(n) (RE-SERVE, A4) -- the index is NEVER set
  // inline without the mesh re-serve + redraw(). curSpecimen tracks the live
  // server index reported by /status.
  var curSpecimen = 1;
  function populateSpecimenSelect(n){
    var sel = document.getElementById("sp-select");
    if (!sel) return;
    var want = Math.max(n, sel.options.length, 1);
    if (sel.options.length !== want){
      sel.innerHTML = "";
      for (var i = 1; i <= want; i++){
        var o = document.createElement("option");
        o.value = String(i); o.textContent = String(i);
        sel.appendChild(o);
      }
    }
    sel.value = String(n);
  }
  on("sp-prev", function(){ if (curSpecimen > 1) switchSpecimen(curSpecimen - 1); });
  on("sp-next", function(){ switchSpecimen(curSpecimen + 1); });
  (function(){
    var sel = document.getElementById("sp-select");
    if (sel) sel.addEventListener("change", function(){
      switchSpecimen(Number(sel.value));
    });
  })();

  // Keyboard parity: [ / ] step specimens (RE-SERVE), Ctrl/Cmd+S saves. Added as
  // a sibling keydown listener so the existing mode-key handler is untouched.
  window.addEventListener("keydown", function(e){
    if (e.key === "[") { e.preventDefault(); if (curSpecimen > 1) switchSpecimen(curSpecimen - 1); }
    else if (e.key === "]") { e.preventDefault(); switchSpecimen(curSpecimen + 1); }
    else if ((e.ctrlKey || e.metaKey) && (e.key === "s" || e.key === "S")) {
      e.preventDefault(); post("save");
    }
  });

  // Live status readout: pull the server-owned specimen index + counts from
  // /status and the tab-gating flags from /tabstate. Called once at boot and on
  // a light poll so counts stay live after every mutating action (pick, anchor,
  // delete, undo, specimen switch, compute) without wiring each call site.
  function refreshStatus(){
    fetch("status").then(function(r){ return r.text(); }).then(function(txt){
      var p = (txt || "").split(",");
      if (p.length >= 5){
        curSpecimen = Number(p[0]) || 1;
        setText("st-land", p[2]);
        setText("st-anchor", p[3]);
        setText("st-surface", p[4]);
        populateSpecimenSelect(curSpecimen);
      }
    }).catch(function(){});
    refreshTabState();
  }
  refreshStatus();
  setInterval(refreshStatus, 1000);

  // Record-and-replay entry point (PICK-03 browser half). A manual parity
  // harness calls window.GMW_REPLAY(pose) with a recorded native camera:
  //   pose = { mv:[16], proj:[16], vp:[x,y,w,h], px, py }.
  // The recorded OpenGL modelview + projection are copied VERBATIM onto a
  // throwaway camera -- no transpose, no handedness flip: glGetDoublev and
  // Matrix4.fromArray are both column-major (RESEARCH Pitfall 3). The recorded
  // pixel is turned into NDC by dividing by the recorded backing viewport, so
  // the ratio is scale-free (Pitfall 2), with a single Y-flip. The ray is cast
  // against a mesh at IDENTITY built from the loaded geometry -- NOT the
  // frameScene()-recentred `group`, or every hit is offset by sphere.center
  // (anti-pattern). The returned {x,y,z} is therefore already in the raw
  // PLY-vertex frame, directly comparable to the native gluUnProject object
  // coordinate. Kept completely separate from the interactive framing.
  window.GMW_REPLAY = function(pose){
    if (!pickMesh) return null;
    var cam = new THREE.PerspectiveCamera();
    cam.matrixAutoUpdate = false;
    cam.projectionMatrix.fromArray(pose.proj);
    cam.projectionMatrixInverse.copy(cam.projectionMatrix).invert();
    var view = new THREE.Matrix4().fromArray(pose.mv);
    cam.matrixWorldInverse.copy(view);
    cam.matrixWorld.copy(view).invert();
    var rndc = new THREE.Vector2();
    rndc.x = (pose.px / pose.vp[2]) * 2 - 1;
    rndc.y = -((pose.py / pose.vp[3]) * 2 - 1);
    var idMesh = new THREE.Mesh(pickMesh.geometry);
    idMesh.position.set(0, 0, 0);
    idMesh.updateMatrixWorld(true);
    var rc = new THREE.Raycaster();
    rc.setFromCamera(rndc, cam);
    var hits = rc.intersectObject(idMesh, false);
    return hits.length
      ? { x: hits[0].point.x, y: hits[0].point.y, z: hits[0].point.z }
      : null;
  };

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
  resize();

  (function loop(){
    requestAnimationFrame(loop);
    controls.update();
    renderer.render(scene, camera);
  })();
})();
</script></body></html>
'
