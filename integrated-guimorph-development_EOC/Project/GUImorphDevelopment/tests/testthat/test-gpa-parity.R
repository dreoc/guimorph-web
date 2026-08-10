pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# These tests inspect package source text; skip when only an installed
# package is available. See helper-pkg-source.R.
skip_if_no_pkg_source()

test_that("compute forwards parity-critical gpagen options", {
  geomorph_file <- file.path(pkg_root, "R", "3dDigitize.geomorph.r")
  src <- readLines(geomorph_file, warn = FALSE)

  expect_true(any(grepl("geomorph::gpagen\\(A=coords.A", src)))
  expect_true(any(grepl("curves = curves", src, fixed = TRUE)))
  expect_true(any(grepl("surfaces = surfaces", src, fixed = TRUE)))
  expect_true(any(grepl("PrinAxes = itob\\(tclvalue\\(e\\$PrinAxes\\)\\)", src)))
  expect_true(any(grepl("ProcD = itob\\(tclvalue\\(e\\$ProcD\\)\\)", src)))
  expect_true(any(grepl("Proj = itob\\(tclvalue\\(e\\$Proj\\)\\)", src)))
  expect_true(any(grepl("approxBE = itob\\(tclvalue\\(e\\$approxBE\\)\\)", src)))
  expect_true(any(grepl("Parallel = itob\\(tclvalue\\(e\\$parallel\\)\\)", src)))
  expect_true(any(grepl("\\.safe_gpagen_maxiter <- function\\(raw\\)", src)))
  expect_true(any(grepl("max.iter = max_iter", src, fixed = TRUE)))
})

test_that("aligned coordinate accessor supports geomorph 4.x and legacy layouts", {
  source(file.path(pkg_root, "R", "3dDigitize.geomorph.r"), local = TRUE)

  coords_new <- array(1, dim = c(2, 3, 1))
  coords_old <- array(2, dim = c(2, 3, 1))
  expect_identical(.gm_aligned_coords(list(coords = coords_new)), coords_new)
  expect_identical(.gm_aligned_coords(list(coord = coords_old)), coords_old)
})

# The browser path reads landmarks/curves/surfaces from the server-owned session
# and populates the SAME activeDataList slots the native path fills, so
# .build_geomorph_data runs with zero edits to its forwarding. This block pins
# that equality: an env built by .gmw_session_to_geomorph_env() from a synthetic
# session must yield the identical geomorph data as an env whose
# activeDataList[[i]][[10]] / [[1]][[4]] slots are hand-populated with the same
# arrays. tclvalue()/itob() need the Tcl interpreter; skip cleanly if absent.
test_that("session read path yields the same .build_geomorph_data as populated activeDataList", {
  have_tcltk <- tryCatch({
    suppressWarnings(suppressMessages(library(tcltk)))
    TRUE
  }, error = function(err) FALSE)
  skip_if_not(isTRUE(have_tcltk), "tcltk (Tcl interpreter) not available")

  # Session model helpers (.gmw_session store + .gmw_session_get) live in
  # transport.R; the env builder + .build_geomorph_data + itob live in the
  # geomorph source. Source both into this local scope.
  source(file.path(pkg_root, "R", "transport.R"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.geomorph.r"), local = TRUE)

  # Headless: the native C landmark query is unavailable. Returning NULL forces
  # .landmarks_for_specimen() onto its activeDataList[[i]][[10]] fallback -- the
  # exact slot the browser path populates.
  getLandmark <- function(i) NULL

  land   <- matrix(as.numeric(1:15), nrow = 5, ncol = 3)
  curves <- matrix(c(1L, 2L, 3L, 2L, 3L, 4L), nrow = 2, ncol = 3, byrow = TRUE)

  token <- "gpaparitytoken"
  s <- .gmw_session_init(token)
  s$specimens[[1]]$land <- land
  s$curves <- curves
  storage.mode(s$curves) <- "integer"
  assign(token, s, envir = .gmw_session)

  opts <- list(curves = 1, surfaces = 0)
  e_session <- .gmw_session_to_geomorph_env(token, opts)

  # Hand-populate the same slots the builder targets, from the same arrays.
  e_active <- new.env()
  slot <- vector("list", 10L)
  slot[[10]] <- land
  slot[[4]]  <- curves
  e_active$activeDataList <- list(slot)
  e_active$landmarkNum <- 5
  e_active$anchorNum   <- 0
  e_active$sliderNum   <- 0
  e_active$curves        <- tclVar(1)
  e_active$surfaces      <- tclVar(0)
  e_active$anchorsSurface <- tclVar(0)

  expect_identical(.build_geomorph_data(e_session), .build_geomorph_data(e_active))
})

# Regression for the browser /gpa segfault: .landmarks_for_specimen() used to
# call the native C/Tk getLandmark() FIRST, which crashes headless (tcl("show",
# ...) -> invalid-permissions segfault, uncatchable by the /gpa try()). The
# session env must read its stored landmarks and NEVER touch the native query.
test_that("session read path never calls the native getLandmark (headless segfault guard)", {
  have_tcltk <- tryCatch({
    suppressWarnings(suppressMessages(library(tcltk)))
    TRUE
  }, error = function(err) FALSE)
  skip_if_not(isTRUE(have_tcltk), "tcltk (Tcl interpreter) not available")

  source(file.path(pkg_root, "R", "transport.R"), local = TRUE)
  source(file.path(pkg_root, "R", "3dDigitize.geomorph.r"), local = TRUE)

  # Stand in for the fatal native query: in production this segfaults; here it
  # errors, so any call surfaces as a test failure rather than a silent crash.
  getLandmark <- function(i) stop("native getLandmark must not run in session mode")

  land  <- matrix(as.numeric(1:15), nrow = 5, ncol = 3)
  token <- "gpanotktoken"
  s <- .gmw_session_init(token)
  s$specimens[[1]]$land <- land
  assign(token, s, envir = .gmw_session)

  e <- .gmw_session_to_geomorph_env(token, list())
  expect_true(isTRUE(e$gmw_session_source))
  # Returns the stored landmarks with no call into getLandmark (no error raised).
  expect_identical(.landmarks_for_specimen(e, 1L), land)
})
