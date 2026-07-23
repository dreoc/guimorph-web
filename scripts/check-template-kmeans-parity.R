#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
#  check-template-kmeans-parity.R
#
#  Compares .template_kmeans_centers() against Morpho::fastKmeans() on real
#  specimens: numerical agreement and wall-clock timing.
#
#  Run from the repo root:
#
#      Rscript scripts/check-template-kmeans-parity.R path/to/spec.ply [more.ply ...]
#
#  Or from an R session with the package loaded:
#
#      devtools::load_all("integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
#      source("scripts/check-template-kmeans-parity.R")
#      run_parity(c("A6_1_clean.ply"), k = c(500, 1000, 2000))
#
#  Requires Morpho installed. That is the point: this is the last check before
#  Morpho leaves the dependency list.
# ---------------------------------------------------------------------------

SEED <- 42L

run_one <- function(ply, k, seed = SEED, iter.max = 100L) {
  stopifnot(file.exists(ply))
  mesh <- Rvcg::vcgPlyRead(ply, updateNormals = TRUE, clean = FALSE)
  nvert <- ncol(mesh$vb)

  # Morpho seeds nothing internally, so seed the caller side to match the
  # initialisation the replacement performs under .with_fixed_seed().
  set.seed(seed)
  t_morpho <- system.time(
    ref <- Morpho::fastKmeans(x = mesh, k = k, iter.max = iter.max,
                              project = TRUE)$centers
  )[["elapsed"]]

  t_new <- system.time(
    new <- .template_kmeans_centers(x = mesh, k = k, iter.max = iter.max,
                                    project = TRUE, seed = seed)
  )[["elapsed"]]

  same_shape <- identical(dim(ref), dim(new))

  # Row-wise comparison assumes both converged to the same cluster ordering,
  # which they should given identical initialisation. If they diverge, fall back
  # to a set comparison: for each reference centre, distance to the nearest new
  # centre. That distinguishes "different order" from "different answer".
  rowwise <- if (same_shape) max(abs(ref - new)) else NA_real_
  # vcgKDtree returns true Euclidean distance, not squared distance.
  nearest <- max(Rvcg::vcgKDtree(new, ref, k = 1)$distance[, 1])

  data.frame(
    specimen   = basename(ply),
    vertices   = nvert,
    k          = k,
    morpho_s   = round(t_morpho, 3),
    new_s      = round(t_new, 3),
    speedup    = round(t_morpho / max(t_new, 1e-9), 2),
    max_rowwise_dev = signif(rowwise, 3),
    max_nearest_dev = signif(nearest, 3),
    stringsAsFactors = FALSE
  )
}

run_parity <- function(plys, k = c(500L, 1000L, 2000L), seed = SEED,
                       iter.max = 100L) {
  if (!requireNamespace("Morpho", quietly = TRUE)) {
    stop("Morpho must be installed to run the parity comparison.")
  }
  grid <- expand.grid(ply = plys, k = k, stringsAsFactors = FALSE)
  out <- do.call(rbind, Map(run_one, grid$ply, grid$k,
                            MoreArgs = list(seed = seed, iter.max = iter.max)))
  rownames(out) <- NULL

  cat("\n")
  print(out, row.names = FALSE)
  cat("\n")

  tol <- 1e-9
  worst <- max(out$max_nearest_dev, na.rm = TRUE)
  if (worst <= tol) {
    cat("PARITY: identical to within", format(tol, scientific = TRUE), "\n")
  } else if (worst <= 1e-6) {
    cat("PARITY: agrees to", signif(worst, 3),
        "- floating-point summation order, acceptable\n")
  } else if (worst <= 1e-2) {
    cat("PARITY: agrees to", signif(worst, 3), "coordinate units.\n",
        " Both are local optima of the same objective from the same start;\n",
        " a difference this size is a different stopping point, not a\n",
        " different answer. Re-run with iter.max = 200 to confirm.\n")
  } else {
    cat("PARITY: DIVERGENT, worst nearest-centre deviation", signif(worst, 3),
        "\n  Compare max_rowwise_dev against max_nearest_dev: if nearest is",
        "\n  small but rowwise is large, only the cluster ordering differs.\n")
  }

  slower <- out[out$speedup < 1, , drop = FALSE]
  if (nrow(slower)) {
    cat("\nSlower than Morpho on", nrow(slower), "of", nrow(out), "cases.\n")
  } else {
    cat("Median speedup:", round(median(out$speedup), 2), "x\n")
  }
  invisible(out)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (!length(args)) {
    cat("usage: Rscript scripts/check-template-kmeans-parity.R spec.ply [...]\n")
    quit(status = 1L)
  }
  pkg <- "integrated-guimorph-development_EOC/Project/GUImorphDevelopment"
  if (requireNamespace("devtools", quietly = TRUE)) {
    devtools::load_all(pkg, quiet = TRUE)
  } else {
    stop("devtools required, or source() this file from a loaded session.")
  }
  run_parity(args)
}
