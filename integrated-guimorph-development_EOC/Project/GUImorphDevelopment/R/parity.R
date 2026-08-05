# ---------------------------------------------------------------------------
#  parity.R -- R side of the PICK-03 browser-vs-native picking parity gate.
#
#  Owns three side-effect-free, dependency-free helpers:
#    * .gmw_mean_edge_length()  -- the scale-relative tolerance UNIT (D-01):
#                                  the mean inter-vertex edge length of the mesh.
#    * .gmw_parity_gate()       -- the 95th-percentile Euclidean-distance gate
#                                  (D-02): pass iff p95(dist) <= 1 x mean_edge.
#    * .gmw_read_pick_poses()   -- base-R reader for the pose-record fixture TSV.
#
#  Like view3d.R, this stays JSON-dependency-free (base R + stats/utils only):
#  the pose fixture is a tab-separated file so both a native C capture
#  (fprintf) and R (read.table) can produce/consume it. No JSON parser dep.
#
#  The gate is scale-relative and unit-free by construction (a fraction of the
#  specimen's own mesh resolution), so it holds regardless of the model's units.
#  Tolerance value (1 x mean edge ~ 0.085 units for B7_1_clean.ply) APPROVED
#  2026-08-05 by the user (D-03); the formula is locked.
# ---------------------------------------------------------------------------

#' Mean inter-vertex edge length of a mesh (the D-01 tolerance unit)
#'
#' From an Rvcg / mesh3d mesh (`m$vb` a 4 x V homogeneous vertex matrix,
#' `m$it` a 3 x F 1-based face-index matrix), stack the three edges of every
#' face, take each edge's Euclidean length, and return the mean. Picking cannot
#' be more precise than mesh resolution, so this resolution is the natural unit
#' for the parity tolerance.
#'
#' @param m A mesh with `$vb` (4 x V) and `$it` (3 x F, 1-based) components.
#' @return Single numeric: the mean inter-vertex edge length.
#' @noRd
#' @keywords internal
.gmw_mean_edge_length <- function(m) {
  V <- t(m$vb[1:3, , drop = FALSE])          # V x 3
  it <- t(m$it)                              # F x 3, 1-based
  e <- rbind(it[, c(1, 2)], it[, c(2, 3)], it[, c(3, 1)])
  d <- sqrt(rowSums((V[e[, 1], , drop = FALSE] - V[e[, 2], , drop = FALSE])^2))
  mean(d)
}

#' 95th-percentile browser-vs-native parity gate (D-02)
#'
#' Coerce both inputs to numeric N x 3 matrices, compute the per-row Euclidean
#' distance between the browser-replay coordinate and the native reference
#' coordinate, and gate the 95th percentile of those distances at one mean
#' inter-vertex edge length. The gate is the 95th percentile, not the max,
#' deliberately tolerating the depth-interpolation residual tail near
#' silhouettes / steep depth gradients (D-09).
#'
#' @param browser_xyz N x 3 numeric (browser-replay object coordinates).
#' @param native_xyz  N x 3 numeric (native gluUnProject reference coordinates).
#' @param mean_edge   Single numeric tolerance unit from `.gmw_mean_edge_length`.
#' @return `list(p95, pass, n)`: the 95th-percentile distance, the pass/fail
#'   boolean (`p95 <= 1 * mean_edge`), and the number of compared points.
#' @noRd
#' @keywords internal
.gmw_parity_gate <- function(browser_xyz, native_xyz, mean_edge) {
  browser_xyz <- matrix(as.numeric(as.matrix(browser_xyz)), ncol = 3)
  native_xyz  <- matrix(as.numeric(as.matrix(native_xyz)),  ncol = 3)
  d <- sqrt(rowSums((browser_xyz - native_xyz)^2))
  p95 <- stats::quantile(d, 0.95, names = FALSE)
  list(p95 = p95, pass = isTRUE(p95 <= 1 * mean_edge), n = length(d))
}

#' Read the pose-record fixture TSV (base R, no JSON dependency)
#'
#' The first line is a `#` metadata comment binding the fixture to its specimen
#' (filename + sha256 + engine commit + capture time); `comment.char = "#"`
#' skips it. The remaining tab-separated table carries the fixed pose-record
#' column set, including the browser-replay `brx/bry/brz` columns.
#'
#' @param path Path to the `*_pick_poses.tsv` fixture.
#' @return A data frame with the fixed pose-record columns.
#' @noRd
#' @keywords internal
.gmw_read_pick_poses <- function(path) {
  utils::read.table(path, header = TRUE, sep = "\t", comment.char = "#",
                    stringsAsFactors = FALSE)
}
