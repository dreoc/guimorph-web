# ---------------------------------------------------------------------------
#  template_kmeans.R -- spatially even k-means sampling for surface templates
#
#  Replaces Morpho::fastKmeans. Morpho is otherwise unused by this package and
#  hard-imports rgl, which cannot load on current macOS; depending on it for one
#  function forced rgl into the load path and took the whole package down with
#  it. See .planning/ROADMAP.md, PLT-02.
#
#  The algorithm follows Morpho::fastKmeans (Stefan Schlager, GPL-2; Schlager
#  2017, "Morpho and Rvcg - Shape Analysis in R", in Statistical Shape and
#  Deformation Analysis, Academic Press). This is an independent
#  reimplementation, not vendored code.
#
#  Performance note. The expensive step is the nearest-centre assignment, which
#  is Rvcg::vcgKDtree (C++) in both implementations. Morpho's only compiled
#  contribution is fastSubsetMeans, which computes per-cluster means by looping
#  over k clusters and rescanning the full assignment vector inside the loop
#  (O(k*n), parallelised with OpenMP). base::rowsum does the same reduction in a
#  single O(n) pass in C, so this version is expected to match or beat it, with
#  the gap widening as k grows. Measured on a 71014-vertex Folsom scan
#  (scripts/bench-group-means.R): rowsum is flat at ~1.25 ms across
#  k = 500/1000/2000, against 4.22/5.63/8.75 ms for split+colMeans and
#  3.28/3.28/2.73 ms for a sparse crossprod. All four agree exactly.
#  vcgKDtree is 86% of each iteration at every k, so mesh size, not the
#  means step, is the lever for larger scans.
#
#  Determinism. Morpho seeds nothing, so digitising a specimen twice produced a
#  different template. Template construction is now seeded from a fixed package
#  default, and the caller's RNG stream is saved and restored so scripted use is
#  unaffected. The initialisation idiom deliberately mirrors Morpho's
#  sample(1:n)[1:k] rather than the tidier sample.int(n, k), because the two
#  consume the RNG stream differently; matching it means a given seed produces
#  the same starting centres under both implementations, which is what makes the
#  parity check in scripts/check-template-kmeans-parity.R meaningful.
# ---------------------------------------------------------------------------

# Fixed seed for surface-template construction. Internal: @noRd keeps roxygen
# from writing a help page for a constant users never call.
#
# Changing this changes every template built afterwards. Templates recorded in
# existing .dgt sessions are unaffected; they store coordinates, not the seed.
#' @noRd
GUIMORPHWEB_TEMPLATE_SEED <- 42L

# Evaluate expr under a fixed seed, leaving the caller's RNG stream untouched.
.with_fixed_seed <- function(seed, expr) {
  genv <- globalenv()
  had <- exists(".Random.seed", envir = genv, inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = genv, inherits = FALSE)
  on.exit({
    if (had) {
      assign(".Random.seed", old, envir = genv)
    } else if (exists(".Random.seed", envir = genv, inherits = FALSE)) {
      rm(".Random.seed", envir = genv)
    }
  }, add = TRUE)
  set.seed(seed)
  expr
}

#' Spatially even k-means sample of a point cloud or mesh
#'
#' Drop-in replacement for the \code{$centers} component of
#' \code{Morpho::fastKmeans}. All three call sites in this package use only that
#' component, so \code{selected} and \code{class} are not computed.
#'
#' @param x numeric matrix of coordinates (1-3 columns), or a \code{mesh3d}.
#' @param k number of clusters. Must be smaller than the number of points.
#' @param iter.max maximum Lloyd iterations per attempt.
#' @param project logical. If \code{x} is a triangular mesh, project the final
#'   centres back onto its surface.
#' @param threads integer passed to Rvcg. 0 lets Rvcg choose.
#' @param seed integer seed. Defaults to \code{GUIMORPHWEB_TEMPLATE_SEED}.
#' @param max.restarts attempts allowed when an initialisation strands an empty
#'   cluster.
#' @return numeric matrix of cluster centres, \code{k} rows by \code{ncol(x)}.
#' @keywords internal
.template_kmeans_centers <- function(x, k, iter.max = 100, project = TRUE,
                                     threads = 0,
                                     seed = GUIMORPHWEB_TEMPLATE_SEED,
                                     max.restarts = 10L) {
  if (!requireNamespace("Rvcg", quietly = TRUE)) {
    stop("Rvcg is required to build a surface template. ",
         "Run install.packages(\"Rvcg\").", call. = FALSE)
  }

  mesh <- NULL
  if (inherits(x, "mesh3d")) {
    mesh <- x
    x <- t(mesh$vb[1L:3L, , drop = FALSE])
  }
  if (!is.matrix(x)) x <- as.matrix(x)
  if (!is.double(x)) storage.mode(x) <- "double"

  origdim <- ncol(x)
  if (!origdim %in% 1L:3L) {
    stop("x must have 1, 2, or 3 columns; got ", origdim, ".", call. = FALSE)
  }
  if (origdim < 3L) x <- cbind(x, matrix(0, nrow(x), 3L - origdim))

  n <- nrow(x)
  k <- abs(as.integer(k))
  if (k >= n) {
    stop("k (", k, ") must be smaller than the number of points (", n, ").",
         call. = FALSE)
  }

  centers <- .with_fixed_seed(seed, {
    found <- NULL
    for (attempt in seq_len(max.restarts)) {
      cur <- x[sample(seq_len(n))[seq_len(k)], , drop = FALSE]
      prev <- integer(n)
      stranded <- FALSE
      for (it in seq_len(iter.max)) {
        idx <- as.integer(
          Rvcg::vcgKDtree(cur, x, k = 1L, threads = threads)$index
        )
        counts <- tabulate(idx, nbins = k)
        if (any(counts == 0L)) { stranded <- TRUE; break }

        # counts has no zeros (checked above), so reorder = TRUE returns
        # rows in cluster order 1..k and counts aligns row-wise.
        cur <- rowsum(x, idx, reorder = TRUE) / counts

        if (identical(idx, prev)) break
        prev <- idx
      }
      if (!stranded) { found <- cur; break }
    }
    if (is.null(found)) {
      stop("Could not place ", k, " non-empty clusters in ", max.restarts,
           " attempts. Reduce the surface-slider count.", call. = FALSE)
    }
    found
  })

  if (!is.null(mesh) && isTRUE(project) && !is.null(mesh$it)) {
    centers <- t(Rvcg::vcgClost(centers, mesh)$vb[1L:3L, , drop = FALSE])
  }

  unname(centers[, seq_len(origdim), drop = FALSE])
}
