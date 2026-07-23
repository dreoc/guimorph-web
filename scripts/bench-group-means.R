#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
#  bench-group-means.R
#
#  Two questions, in order of importance:
#
#    1. Where does a k-means iteration actually spend its time? If the kd-tree
#       assignment dominates, optimising the group-means step is wasted effort
#       no matter which implementation wins.
#
#    2. Given that, which group-means implementation is fastest?
#
#  Usage, from the repo root with the package loaded:
#
#      devtools::load_all("integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
#      source("scripts/bench-group-means.R")
#      bench_means("C:/dev/Folsom3D/A6_1_clean.ply", k = c(500, 1000, 2000))
# ---------------------------------------------------------------------------

# --- candidate implementations ---------------------------------------------
# Each takes (x, idx, k, counts) and returns a k x 3 matrix of cluster means.

means_rowsum <- function(x, idx, k, counts) {
  rowsum(x, idx, reorder = TRUE) / counts
}

means_split_vapply <- function(x, idx, k, counts) {
  groups <- split(seq_len(nrow(x)), idx)
  t(vapply(groups, function(i) colMeans(x[i, , drop = FALSE]), numeric(3L)))
}

means_split_df <- function(x, idx, k, counts) {
  t(vapply(split.data.frame(x, idx), colMeans, numeric(3L)))
}

means_sparse <- function(x, idx, k, counts) {
  M <- Matrix::sparseMatrix(i = seq_len(nrow(x)), j = idx, x = 1,
                            dims = c(nrow(x), k))
  as.matrix(Matrix::crossprod(M, x)) / counts
}

CANDIDATES <- list(
  rowsum       = means_rowsum,
  split_vapply = means_split_vapply,
  split_df     = means_split_df,
  sparse       = means_sparse
)

# --- timing helper ----------------------------------------------------------
#
# Takes a zero-argument closure, NOT an expression: an expression argument is a
# promise and would be evaluated once, with every later rep returning the cached
# value. Auto-calibrates an inner repeat count so each measurement clears the
# platform timer granularity (~15 ms on Windows), then reports the median
# per-call time over `reps` measurements.

timeit <- function(f, reps = 5L, min_time = 0.2) {
  m <- 1L
  repeat {
    el <- system.time(for (i in seq_len(m)) f())[["elapsed"]]
    if (el >= min_time || m >= 1e6L) break
    m <- m * 4L
  }
  ts <- numeric(reps)
  for (r in seq_len(reps)) {
    ts[r] <- system.time(for (i in seq_len(m)) f())[["elapsed"]] / m
  }
  stats::median(ts)
}

# --- main -------------------------------------------------------------------

bench_means <- function(ply, k = c(500L, 1000L, 2000L), reps = 5L,
                        seed = 42L, warmup_iters = 5L) {
  stopifnot(file.exists(ply))
  have_matrix <- requireNamespace("Matrix", quietly = TRUE)
  if (!have_matrix) message("Matrix not installed; skipping the sparse candidate.")

  mesh <- Rvcg::vcgPlyRead(ply, updateNormals = TRUE, clean = FALSE)
  x <- t(mesh$vb[1L:3L, , drop = FALSE])
  storage.mode(x) <- "double"
  n <- nrow(x)

  rows <- list()
  for (kk in as.integer(k)) {
    # Produce a realistic mid-run assignment rather than benchmarking against a
    # random one: run a few honest iterations first.
    set.seed(seed)
    centers <- x[sample(seq_len(n))[seq_len(kk)], , drop = FALSE]
    for (i in seq_len(warmup_iters)) {
      idx <- as.integer(Rvcg::vcgKDtree(centers, x, k = 1L, threads = 0)$index)
      counts <- tabulate(idx, nbins = kk)
      if (any(counts == 0L)) break
      centers <- rowsum(x, idx, reorder = TRUE) / counts
    }
    if (any(counts == 0L)) {
      message("k = ", kk, ": empty cluster during warmup, skipping.")
      next
    }

    # Question 1: the assignment step, for context.
    t_tree <- timeit(function() Rvcg::vcgKDtree(centers, x, k = 1L, threads = 0), reps)
    t_tab  <- timeit(function() tabulate(idx, nbins = kk), reps)

    # Question 2: the candidates.
    cands <- CANDIDATES
    if (!have_matrix) cands$sparse <- NULL

    ref <- cands$rowsum(x, idx, kk, counts)
    times <- setNames(numeric(length(cands)), names(cands))
    devs  <- setNames(numeric(length(cands)), names(cands))
    for (nm in names(cands)) {
      f <- cands[[nm]]
      devs[nm]  <- max(abs(unname(f(x, idx, kk, counts)) - unname(ref)))
      times[nm] <- timeit(function() f(x, idx, kk, counts), reps)
    }
    t_base <- times[["rowsum"]]
    for (nm in names(cands)) {
      rows[[length(rows) + 1L]] <- data.frame(
        k = kk, step = nm, seconds = signif(times[[nm]], 3),
        vs_rowsum = signif(times[[nm]] / max(t_base, 1e-9), 2),
        pct_of_iter = signif(100 * times[[nm]] / (t_tree + times[[nm]]), 2),
        max_dev = signif(devs[[nm]], 3),
        stringsAsFactors = FALSE
      )
    }
    rows[[length(rows) + 1L]] <- data.frame(
      k = kk, step = "--vcgKDtree--", seconds = signif(t_tree, 3),
      vs_rowsum = NA_real_,
      pct_of_iter = signif(100 * t_tree / (t_tree + t_base), 2),
      max_dev = NA_real_, stringsAsFactors = FALSE
    )
    rows[[length(rows) + 1L]] <- data.frame(
      k = kk, step = "--tabulate--", seconds = signif(t_tab, 3),
      vs_rowsum = NA_real_, pct_of_iter = NA_real_,
      max_dev = NA_real_, stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  cat("\nvertices:", n, "  reps:", reps,
      "  (per-call times, inner-looped past timer granularity)\n\n")
  print(out, row.names = FALSE)
  cat("\n'pct_of_iter' is that step's share of (assignment + means) for its k.\n")
  cat("If --vcgKDtree-- dominates, the means implementation is not the lever.\n\n")
  invisible(out)
}

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args)) {
    pkg <- "integrated-guimorph-development_EOC/Project/GUImorphDevelopment"
    if (requireNamespace("devtools", quietly = TRUE)) {
      devtools::load_all(pkg, quiet = TRUE)
      bench_means(args[1])
    }
  }
}
