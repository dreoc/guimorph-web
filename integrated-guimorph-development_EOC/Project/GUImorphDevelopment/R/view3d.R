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

  html <- sprintf(GMW_VIEW3D_TEMPLATE, title, background, background,
                  cloud_js, mesh_js)
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
</style></head><body>
<canvas id="c"></canvas>
<div id="h">drag rotate &middot; scroll zoom &middot; <kbd>r</kbd> reset view</div>
<script src="guimorphweb-three.js"></script>
<script>
(function(){
  var THREE = GMW.THREE, OrbitControls = GMW.OrbitControls;
  var BG = "%s", CLOUDS = %s, MESH = %s;

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

  // Frame the whole scene: centre at the bounding-sphere centre and pull the
  // camera back far enough that the sphere fits the vertical FOV. Equivalent to
  // rgl aspect3d("iso") plus an automatic fit.
  var box = new THREE.Box3().setFromObject(group);
  var sphere = box.getBoundingSphere(new THREE.Sphere());
  var home = sphere.radius > 0 ? sphere.radius : 1;
  var dist = home / Math.sin((camera.fov * Math.PI / 180) / 2) * 1.15;
  group.position.sub(sphere.center);

  var controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;

  function reset(){
    camera.position.set(0, 0, dist);
    camera.near = dist / 100; camera.far = dist * 100;
    camera.updateProjectionMatrix();
    controls.target.set(0,0,0);
    controls.update();
  }
  reset();

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
  resize();

  (function loop(){
    requestAnimationFrame(loop);
    controls.update();
    renderer.render(scene, camera);
  })();
})();
</script></body></html>
'
