pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)

# The tkogl2 C/Objective-C sources live outside the R package, so they are absent
# from a built tarball and from R CMD check. Look in both plausible locations and
# skip rather than error when neither is present.
native_src <- function(file) {
  candidates <- c(
    file.path(pkg_root, "src", "tkogl2", "src", file),
    file.path(pkg_root, "..", "tkogl2", "src", file)
  )
  hit <- candidates[file.exists(candidates)]
  if (length(hit)) normalizePath(hit[1]) else NA_character_
}

test_that("macOS backend uses backing viewport for Retina parity", {
  backend_file <- native_src("gfx_backend_nsgl.m")
  skip_if(is.na(backend_file), "tkogl2 native source not available")
  src <- readLines(backend_file, warn = FALSE)

  expect_true(any(grepl("convertRectToBacking:[view bounds]", src, fixed = TRUE)))
  expect_true(any(grepl("glViewport\\(0, 0, \\(GLsizei\\)backing.size.width", src)))
})

test_that("pick path converts Tk points to backing pixels once", {
  dispatch_file <- native_src("tcl_dispatch.c")
  skip_if(is.na(dispatch_file), "tkogl2 native source not available")
  src <- readLines(dispatch_file, warn = FALSE)

  expect_true(any(grepl("gfx_point_to_backing\\(g_surface, x, y, &sampleX, &sampleY\\)", src)))
  expect_true(any(grepl("ogl_getObjCoordinate\\(sampleX, sampleY", src)))
})

test_that("retina near-miss tolerance window is bounded", {
  dispatch_file <- native_src("tcl_dispatch.c")
  skip_if(is.na(dispatch_file), "tkogl2 native source not available")
  src <- readLines(dispatch_file, warn = FALSE)

  expect_true(any(grepl("#define GBL_RETINA_NEAR_MISS_PX 2", src, fixed = TRUE)))
  expect_true(any(grepl("for \\(oy = -GBL_RETINA_NEAR_MISS_PX;", src)))
  expect_true(any(grepl("for \\(ox = -GBL_RETINA_NEAR_MISS_PX;", src)))
})
