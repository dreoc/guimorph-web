# Phase 4: Picking Parity -- PICK-03 browser-vs-native parity gate harness.
#
# PICK-03 IS FORMALLY OPEN. Native reference-coordinate capture is Windows-only
# and no Windows host is available (D-06), so this harness runs end-to-end
# against the schema-true PLACEHOLDER fixture (tests/fixtures/parity/
# B7_1_pick_poses.tsv) and proves the gate MATH + plumbing, not real parity.
#
# The real Windows+browser capture drops in with GENUINELY ZERO CODE CHANGE
# (D-07): the browser-replay object coordinate enters through the fixture's
# brXYZ columns this harness already reads. Every block below compares the
# native reference `objXYZ` columns against the browser-replay `brXYZ` columns
# DIRECTLY -- there is no in-R synthesis of the browser array on the real path.
# When a real capture (same columns, real objXYZ/winz/brXYZ, real per-row engine
# commit hashes replacing the PLACEHOLDER sentinel) replaces the placeholder,
# the real-parity block below stops skipping and closes the gate unchanged.
#
# Tolerance (the gate, D-01/D-02): scale-relative, p95(browser-vs-native
# Euclidean distance) <= 1 x mean inter-vertex edge length (~0.085 units for
# B7_1_clean.ply). APPROVED 2026-08-05 by the user (D-03); the formula is locked.
#
# Idioms reused: helper-pkg-source.R skip-if-source-absent (source the @noRd
# helpers), test-retina-picking-parity.R skip-if-fixture-absent, and the
# test-transport.R direct-call unit style.

pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)

skip_if_no_pkg_source()
source(file.path(pkg_root, "R", "parity.R"), local = FALSE)

fixture_path <- file.path(pkg_root, "tests", "fixtures", "parity", "B7_1_pick_poses.tsv")
ply_path     <- file.path(pkg_root, "tests", "fixtures", "parity", "B7_1_clean.ply")

# The fixed pose-record column set -- the drop-in contract (native objXYZ
# reference FOLLOWED by the browser-replay brXYZ columns). Byte-identical to the
# eventual Windows capture header.
expected_cols <- c(
  "commit",
  paste0("mv", sprintf("%02d", 0:15)),
  paste0("pj", sprintf("%02d", 0:15)),
  paste0("vp", 0:3),
  "px", "py", "winz", "objx", "objy", "objz", "brx", "bry", "brz"
)

# --- (a) unit: mean inter-vertex edge length on a tiny hand-checkable mesh ----
test_that(".gmw_mean_edge_length equals the mean of a triangle's three edges", {
  # One right-triangle face: (0,0,0), (1,0,0), (0,1,0).
  # Edges: 1-2 = 1, 2-3 = sqrt(2), 3-1 = 1  ->  mean = (2 + sqrt(2)) / 3.
  m <- list(
    vb = rbind(matrix(c(0, 0, 0,  1, 0, 0,  0, 1, 0), nrow = 3, ncol = 3), 1),
    it = matrix(c(1L, 2L, 3L), nrow = 3, ncol = 1)
  )
  expect_equal(.gmw_mean_edge_length(m), (2 + sqrt(2)) / 3, tolerance = 1e-9)
})

# --- (b) unit: the 95th-percentile distance gate on synthetic arrays ----------
test_that(".gmw_parity_gate passes a tight array and fails a spread one", {
  mean_edge <- 0.085

  # Tight: browser == native -> every distance 0 -> p95 = 0 <= mean_edge.
  native  <- matrix(c(0, 0, 0,  1, 1, 1,  2, 2, 2,  3, 3, 3), ncol = 3, byrow = TRUE)
  browser <- native
  tight <- .gmw_parity_gate(browser, native, mean_edge)
  expect_true(tight$pass)
  expect_equal(tight$p95, 0)
  expect_equal(tight$n, 4L)

  # Spread: a 1-unit offset on every row -> p95 = 1 > mean_edge -> fail.
  spread <- .gmw_parity_gate(native + 1, native, mean_edge)
  expect_false(spread$pass)
  expect_equal(spread$p95, sqrt(3), tolerance = 1e-9)
  expect_equal(spread$n, 4L)
})

test_that(".gmw_parity_gate reports the 95th percentile of the distances", {
  # Distances 0..10 along x; type-7 quantile of 0:10 at 0.95 is 9.5.
  native  <- cbind(0:10, 0, 0)
  browser <- cbind(0, 0, 0)[rep(1, 11), ]
  g <- .gmw_parity_gate(browser, native, mean_edge = 100)
  expect_equal(g$n, 11L)
  expect_equal(g$p95, stats::quantile(0:10, 0.95, names = FALSE), tolerance = 1e-9)
  expect_true(g$pass)  # 9.5 <= 100
})

# --- (c) unit: the base-R reader parses the fixed column set -------------------
test_that(".gmw_read_pick_poses parses the placeholder into the fixed columns", {
  skip_if(!file.exists(fixture_path), "placeholder pose fixture absent")
  poses <- .gmw_read_pick_poses(fixture_path)
  expect_identical(names(poses), expected_cols)      # incl. brx/bry/brz
  expect_gte(nrow(poses), 4L)
  expect_true(all(c("brx", "bry", "brz") %in% names(poses)))
})

# --- (d) integration: placeholder end-to-end, native objXYZ vs replay brXYZ ----
test_that("placeholder harness runs the gate on native objXYZ vs browser brXYZ", {
  skip_if(!file.exists(fixture_path), "placeholder pose fixture absent")
  skip_if_not_installed("Rvcg")
  skip_if(!file.exists(ply_path), "B7_1_clean.ply specimen absent")

  poses <- .gmw_read_pick_poses(fixture_path)
  m <- Rvcg::vcgPlyRead(ply_path)
  mean_edge <- .gmw_mean_edge_length(m)
  expect_true(is.finite(mean_edge) && mean_edge > 0)

  # Native reference and browser-replay arrays come STRAIGHT from the fixture
  # columns -- no in-R synthesis of the browser hit (W4 drop-in channel).
  native  <- as.matrix(poses[, c("objx", "objy", "objz")])
  browser <- as.matrix(poses[, c("brx", "bry", "brz")])
  gate <- .gmw_parity_gate(browser, native, mean_edge)

  expect_true(is.finite(gate$p95))
  expect_equal(gate$n, nrow(poses))
  expect_true(gate$pass)   # placeholder distances are sub-mean-edge by construction
})

# --- (e) real-parity gate (D-07): SKIPS on the placeholder, closes on real -----
test_that("PICK-03 real-parity gate closes with the real Windows capture (D-07)", {
  skip_if(!file.exists(fixture_path), "placeholder pose fixture absent")
  poses <- .gmw_read_pick_poses(fixture_path)

  # PICK-03 is OPEN: while every row still carries the PLACEHOLDER sentinel there
  # is no real oracle capture, so this SKIPS (never fails). Dropping in a real
  # capture (real per-row engine commit hashes replacing PLACEHOLDER) lets the
  # identical body below run and close the gate with zero code change.
  skip_if(all(poses$commit == "PLACEHOLDER"),
          "real Windows+browser capture absent; PICK-03 OPEN (D-06)")

  # ---- REAL comparison body (runs UNCHANGED once the sentinel is gone) ----
  skip_if_not_installed("Rvcg")
  skip_if(!file.exists(ply_path), "B7_1_clean.ply specimen absent")
  m <- Rvcg::vcgPlyRead(ply_path)
  mean_edge <- .gmw_mean_edge_length(m)

  # Same DIRECT native-objXYZ-vs-browser-replay-brXYZ comparison as block (d):
  # both arrays are fixture columns, so real closure is genuinely zero-code.
  native  <- as.matrix(poses[, c("objx", "objy", "objz")])
  browser <- as.matrix(poses[, c("brx", "bry", "brz")])
  gate <- .gmw_parity_gate(browser, native, mean_edge)
  expect_true(gate$pass)
})

# ---------------------------------------------------------------------------
# MANUAL UAT (headless CI cannot render WebGL; Phase 3 `# MANUAL UAT` precedent).
# Sign off on stock macOS AND stock Windows, offline:
#   PICK-01/02:
#     1. Serve a specimen and open the printed loopback URL in a browser.
#     2. Click on the loaded mesh: a red landmark dot lands under the cursor and
#        the mesh-local x,y,z is stored server-side (gmw_picks(token) returns it).
#     3. Orbit so the dot rotates behind the mesh: the dot is OCCLUDED (correct
#        depth), not drawn on top.
#     4. Click the background (a miss): nothing is drawn and no row is stored.
#     5. Picking stays interactive on B7_1_clean.ply (363,283 verts) -- the eager
#        computeBoundsTree() BVH keeps the first click instant.
#   PICK-03 (real oracle, Windows-only -- D-06, OPEN):
#     6. Capture native poses on the validated tkogl2 Windows oracle into the
#        pose-record schema (objXYZ from gluUnProject + real per-row engine
#        commit hashes), replay each pose in the browser via window.GMW_REPLAY()
#        to fill brXYZ, and write the rows into B7_1_pick_poses.tsv (same header).
#     7. Re-run testthat::test_local(filter="picking-parity"): the real-parity
#        block above stops skipping and asserts the gate -- closing PICK-03 with
#        no code change.
# ---------------------------------------------------------------------------
