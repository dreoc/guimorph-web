# Phase 5: Full Digitizing and Data Parity -- surface flatten transpose regression
#
# DGT-02 surface display sends the s x 3 semilandmark cloud to the browser as a
# flat, ROW-MAJOR numeric array. The transpose is not optional: dropping it
# column-orders the vector and silently scrambles point order, breaking GPA
# correspondence (RESEARCH Pitfall 1; PROJECT "lessons"). This file pins the
# exact `as.vector(t(m))` ordering so a dropped transpose fails the build.
#
# Two blocks:
#   1. `.gmw_flat` (view3d.R) already transposes -- passes immediately.
#   2. `.gmw_downsample_session` (3dDigitize.surface.r) must route its returned
#      cloud through the SAME row-major flatten -- red until Plan 05-04 Task 2.
#
# Mirrors the test-picking-transport.R pkg_root / skip_if_no_pkg_source() /
# source() header idiom (no live server; the production functions are invoked
# directly on the R main thread).

pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)

skip_if_no_pkg_source()

# The row-major flatten helper (.gmw_flat) and the geometric-morphometric TPS
# helpers (csize / rotate.mat / tps2d3d) the downsample warp reuses, plus the
# session model (.gmw_session*) and the headless entry under test.
source(file.path(pkg_root, "R", "view3d.R"),            local = FALSE)
source(file.path(pkg_root, "R", "gm_utils.R"),          local = FALSE)
source(file.path(pkg_root, "R", "transport.R"),         local = FALSE)
source(file.path(pkg_root, "R", "3dDigitize.surface.r"), local = FALSE)

# The package supplies dbg() at load time (rtkogl.R); sourcing bare files does
# not, so provide a no-op shim when it is absent (test-only, harmless).
if (!exists("dbg")) dbg <- function(...) invisible(NULL)

# Drop any session state a test seeded, so blocks stay independent.
reset_session <- function(...) {
  for (t in c(...)) if (exists(t, envir = .gmw_session)) rm(list = t, envir = .gmw_session)
}

# A fixed, deliberately asymmetric matrix: row-major and column-major flattens
# differ, so a dropped transpose cannot masquerade as a pass.
fixed_m <- matrix(c(11, 12, 13,
                    21, 22, 23,
                    31, 32, 33), ncol = 3, byrow = TRUE)

test_that(".gmw_flat emits row-major [x1,y1,z1,...] = as.vector(t(m)), NOT column-major", {
  # formatC with 6 digits is how .gmw_flat renders each scalar; build the exact
  # expected string both ways from the SAME formatter so only ordering differs.
  fmt <- function(v) paste0("[", paste(formatC(v, format = "f", digits = 6),
                                       collapse = ","), "]")
  row_major <- fmt(as.vector(t(fixed_m)))   # 11,12,13,21,22,23,31,32,33
  col_major <- fmt(as.vector(fixed_m))      # 11,21,31,12,22,32,13,23,33

  expect_identical(.gmw_flat(fixed_m), row_major)
  # Teeth: the column-major ordering is a DIFFERENT string and must be rejected.
  expect_false(identical(.gmw_flat(fixed_m), col_major))
})

test_that(".gmw_downsample_session returns the row-major flatten of the stored surfaces (order preserved)", {
  token <- "TESTTOKEN_downsample_flat"
  reset_session(token)
  on.exit(reset_session(token), add = TRUE)

  # Seed a synthetic session: 4 fixed landmarks, a template (fixed rows + 3
  # semilandmark rows), and a specimen point cloud. The headless entry runs the
  # SAME TPS warp / nearest-neighbour logic downSample() uses and stores the
  # resulting s x 3 sliders array in the session's `surfaces` slot.
  set.seed(1)
  land <- matrix(c(0, 0, 0,
                   1, 0, 0,
                   0, 1, 0,
                   0, 0, 1), ncol = 3, byrow = TRUE)
  semis <- matrix(c(0.5, 0.5, 0.0,
                    0.5, 0.0, 0.5,
                    0.0, 0.5, 0.5), ncol = 3, byrow = TRUE)
  template <- rbind(land, semis)                       # 4 fixed + 3 semilandmarks
  specimen <- matrix(runif(60, -1, 2), ncol = 3)       # 20-vertex synthetic mesh

  s <- list(
    specimens = list(list(
      land     = land,
      anchor   = matrix(numeric(0), nrow = 0L, ncol = 3L),
      surfaces = matrix(numeric(0), nrow = 0L, ncol = 3L),
      template = template,
      specimen = specimen
    )),
    current = 1L,
    curves  = matrix(integer(0), nrow = 0L, ncol = 3L),
    undo    = NULL
  )
  assign(token, s, envir = .gmw_session)

  flat <- .gmw_downsample_session(token)

  # The array R now owns for this specimen.
  surf <- gmw_session(token)$specimens[[1]]$surfaces
  expect_true(is.matrix(surf))
  expect_equal(ncol(surf), 3L)
  expect_equal(nrow(surf), nrow(semis))   # one slider per template semilandmark

  # The returned cloud is EXACTLY the row-major flatten of that array...
  expect_identical(flat, .gmw_flat(surf))

  # ...and NOT the column-major flatten -- the transpose is present (surf has
  # >= 2 distinct rows, so the two orderings differ).
  col_major <- paste0("[", paste(formatC(as.vector(surf), format = "f", digits = 6),
                                 collapse = ","), "]")
  expect_false(identical(flat, col_major))
})
