pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

test_that("macOS backend uses backing viewport for Retina parity", {
  backend_file <- file.path(pkg_root, "..", "tkogl2", "src", "gfx_backend_nsgl.m")
  src <- readLines(backend_file, warn = FALSE)

  expect_true(any(grepl("convertRectToBacking:[view bounds]", src, fixed = TRUE)))
  expect_true(any(grepl("glViewport\\(0, 0, \\(GLsizei\\)backing.size.width", src)))
})

test_that("pick path converts Tk points to backing pixels once", {
  dispatch_file <- file.path(pkg_root, "..", "tkogl2", "src", "tcl_dispatch.c")
  src <- readLines(dispatch_file, warn = FALSE)

  expect_true(any(grepl("gfx_point_to_backing\\(g_surface, x, y, &sampleX, &sampleY\\)", src)))
  expect_true(any(grepl("ogl_getObjCoordinate\\(sampleX, sampleY", src)))
})

test_that("retina near-miss tolerance window is bounded", {
  dispatch_file <- file.path(pkg_root, "..", "tkogl2", "src", "tcl_dispatch.c")
  src <- readLines(dispatch_file, warn = FALSE)

  expect_true(any(grepl("#define GBL_RETINA_NEAR_MISS_PX 2", src, fixed = TRUE)))
  expect_true(any(grepl("for \\(oy = -GBL_RETINA_NEAR_MISS_PX;", src)))
  expect_true(any(grepl("for \\(ox = -GBL_RETINA_NEAR_MISS_PX;", src)))
})
