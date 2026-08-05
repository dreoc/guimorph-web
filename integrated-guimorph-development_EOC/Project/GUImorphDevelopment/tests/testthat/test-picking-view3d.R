# Source-scan gate for the picking wiring baked into GMW_VIEW3D_TEMPLATE
# (PICK-01 browser half, PICK-02 overlay, PICK-03 replay; plan 04-02).
#
# Pure source inspection -- no server, no browser, no sourcing of view3d.R. It
# mirrors the readLines + grepl style of test-view3d-beacon.R and lives in its
# own file so it never overlaps the transport plans' test edits. See
# helper-pkg-source.R for the skip-if-source-absent idiom.

test_that("the viewport template wires the pointer pick + eager BVH (PICK-01)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  # Eager BVH build folds the cost into load, not the first click.
  expect_true(any(grepl("computeBoundsTree", src, fixed = TRUE)))
  # Pointer -> raycast pipeline.
  expect_true(any(grepl("pointerdown", src, fixed = TRUE)))
  expect_true(any(grepl("setFromCamera", src, fixed = TRUE)))
  expect_true(any(grepl("intersectObject", src, fixed = TRUE)))
  # World hit converted to the mesh-local (raw PLY-vertex) frame for R, with an
  # explicit world-matrix refresh so a mid-rotation click never reads a stale
  # matrix.
  expect_true(any(grepl("updateWorldMatrix", src, fixed = TRUE)))
  expect_true(any(grepl("worldToLocal", src, fixed = TRUE)))
  # Non-recursive intersect so placed overlay dots are never re-hit (T-4-07).
  expect_true(any(grepl("intersectObject(pickMesh, false)", src, fixed = TRUE)))
})

test_that("the pick report is the same-origin relative target, never absolute (WEB-03)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  # The hit is reported via a RELATIVE sendBeacon("pick", ...) that resolves
  # same-origin to /<token>/pick -- the same offline-by-construction bar
  # test-view3d-beacon.R enforces for /close (T-4-06).
  pick_lines <- grep("sendBeacon(\"pick\"", src, fixed = TRUE, value = TRUE)
  expect_true(length(pick_lines) >= 1)
  # No absolute-URL scheme prefix anywhere in the pick report call.
  expect_false(any(grepl("sendBeacon(\"http", src, fixed = TRUE)))
  expect_false(any(grepl("sendBeacon('http", src, fixed = TRUE)))
})

test_that("placed landmarks draw as depth-tested overlay spheres (PICK-02)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  expect_true(any(grepl("addOverlayDot", src, fixed = TRUE)))
  expect_true(any(grepl("SphereGeometry", src, fixed = TRUE)))
  # depthTest:true occludes a far-side dot under rotation (criterion 2).
  expect_true(any(grepl("depthTest", src, fixed = TRUE)))
  # The overlay is a sibling group added to the scene, not to the mesh `group`.
  expect_true(any(grepl("scene.add(overlay)", src, fixed = TRUE)))
})

test_that("the replay entry point raycasts the raw PLY frame at identity (PICK-03)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  # Global replay hook a manual harness can call.
  expect_true(any(grepl("GMW_REPLAY", src, fixed = TRUE)))
  # Recorded matrices are baked on the camera verbatim: no auto-update, column
  # -major fromArray copy, explicit inverse (Pitfall 3, no transpose).
  expect_true(any(grepl("matrixAutoUpdate", src, fixed = TRUE)))
  expect_true(any(grepl("fromArray", src, fixed = TRUE)))
  expect_true(any(grepl("projectionMatrixInverse", src, fixed = TRUE)))
  # Anti-pattern guard: the replay builds its OWN identity mesh from the loaded
  # geometry and casts against that -- NOT the frameScene()-recentred `group`,
  # or every hit is offset by sphere.center.
  expect_true(any(grepl("new THREE.Mesh(pickMesh.geometry)", src, fixed = TRUE)))
  expect_true(any(grepl("idMesh.position.set(0, 0, 0)", src, fixed = TRUE)))
})
