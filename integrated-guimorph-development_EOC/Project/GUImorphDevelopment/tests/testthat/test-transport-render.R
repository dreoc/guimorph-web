pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect the HTML string produced by the view3d template rather
# than behaviour in a browser, so they need the package R/ source tree. Skip
# cleanly under R CMD check (installed lazy-load database). See
# helper-pkg-source.R.
skip_if_no_pkg_source()
source(file.path(pkg_root, "R", "view3d.R"), local = FALSE)

test_that("mesh-URL branch emits PLYLoader + normals + deferred framing + D-03/D-04 material", {
  h <- .gmw_view3d_html(mesh_url = "specimen.ply")

  expect_length(h, 1L)
  expect_type(h, "character")

  expect_match(h, "GMW.PLYLoader", fixed = TRUE)
  expect_match(h, ".load(", fixed = TRUE)
  expect_match(h, "computeVertexNormals", fixed = TRUE)
  expect_match(h, "frameScene", fixed = TRUE)
  expect_match(h, "MeshLambertMaterial", fixed = TRUE)
  expect_match(h, "THREE.DoubleSide", fixed = TRUE)
  expect_match(h, "#cccccc", fixed = TRUE)
  expect_match(h, "specimen.ply", fixed = TRUE)

  # Scan RGB stays off: no per-vertex colour enabling in the emitted page.
  expect_no_match(h, "vertexColors", fixed = TRUE)
})

test_that("mesh-URL output uses the D-04 white default background", {
  h <- .gmw_view3d_html(mesh_url = "specimen.ply")
  expect_match(h, "#ffffff", fixed = TRUE)
})

test_that("framing is deferred, not run synchronously, on the mesh-URL path", {
  h <- .gmw_view3d_html(mesh_url = "specimen.ply")

  # frameScene appears at least twice: its definition plus the deferred call
  # inside the PLYLoader onLoad callback (the synchronous else-branch call is
  # not taken when MESH_URL is non-empty).
  n <- length(gregexpr("frameScene", h, fixed = TRUE)[[1]])
  expect_gte(n, 2L)

  # The deferred call sits after the PLYLoader().load( entry point.
  load_at <- regexpr("PLYLoader().load(", h, fixed = TRUE)
  expect_gt(load_at, 0L)
  after_load <- substring(h, load_at)
  expect_match(after_load, "frameScene", fixed = TRUE)
})

test_that("point-cloud path is unregressed and carries no mesh URL", {
  coords <- matrix(c(0, 0, 0, 1, 1, 1, 2, 2, 2), ncol = 3, byrow = TRUE)
  h <- .gmw_view3d_html(clouds = list(list(coords = coords)), mesh_url = "")

  expect_match(h, "THREE.Points", fixed = TRUE)
  expect_no_match(h, "specimen.ply", fixed = TRUE)
})
