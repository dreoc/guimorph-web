# WEB-03 offline-install smoke test (filter name: "offline").
#
# This is the SLOW integration check for WEB-03 (RESEARCH Open Question 2): it
# builds the package tarball, installs it with NO network into a throwaway
# library, and proves the vendored bundle ships, the installed package serves
# the specimen bytes byte-identically over loopback, and the served page has
# zero external references. There is no CI, so it is a runnable check a human
# triggers per platform.
#
# It is gated behind GMW_RUN_OFFLINE_SMOKE so a bare `test_local(filter="offline")`
# on a headless dev box SKIPS cleanly rather than blocking: loading the installed
# GUImorphWeb namespace pulls its Imports (geomorph -> rgl, tcltk2), whose GUI
# init hangs with no window server (STATE.md). Set GMW_RUN_OFFLINE_SMOKE=1 on a
# display host with build tooling to actually run it.

test_that("a fully-offline source install ships the bundle and serves it", {
  skip_on_cran()
  skip_if_no_pkg_source()
  skip_if_no_curl()
  skip_if_not_installed("pkgbuild")
  skip_if_not_installed("withr")
  skip_if(
    !nzchar(Sys.getenv("GMW_RUN_OFFLINE_SMOKE")),
    paste(
      "set GMW_RUN_OFFLINE_SMOKE=1 to run the slow offline install smoke",
      "(needs R build tooling + a display host so the installed package's",
      "Imports load without blocking)."
    )
  )

  root    <- pkg_source_root()
  fixture <- file.path(root, "tests", "fixtures", "parity", "B12_1_clean.ply")
  skip_if(!file.exists(fixture), "B12_1_clean.ply fixture missing")

  # 1. Build the tarball. If R CMD build / pkgbuild cannot run here, skip.
  dest <- tempfile("gmw-build-"); dir.create(dest)
  on.exit(unlink(dest, recursive = TRUE, force = TRUE), add = TRUE)
  tarball <- tryCatch(
    pkgbuild::build(root, dest_path = dest, quiet = TRUE,
                    args = c("--no-manual", "--no-build-vignettes")),
    error = function(e) NULL
  )
  skip_if(is.null(tarball) || !file.exists(tarball),
          "R CMD build / pkgbuild could not build the tarball in this environment")

  # 2. Throwaway library for the offline install.
  templib <- tempfile("gmw-lib-"); dir.create(templib)
  on.exit(unlink(templib, recursive = TRUE, force = TRUE), add = TRUE)

  # 3. Install OFFLINE. repos = NULL + dependencies = FALSE is load-bearing --
  #    it is what makes this an offline install; dependencies = TRUE would
  #    silently reach CRAN and the test would no longer prove anything
  #    (RESEARCH Pitfall 6). Assumption A4: the host already has the Imports
  #    (geomorph/Rvcg/tcltk/tcltk2/httpuv) present.
  tryCatch(
    utils::install.packages(tarball, repos = NULL, type = "source",
                            dependencies = FALSE, lib = templib, quiet = TRUE),
    error = function(e) NULL
  )
  installed <- "GUImorphWeb" %in%
    rownames(utils::installed.packages(lib.loc = templib))
  skip_if(!isTRUE(installed),
          "offline source install did not complete (host missing an Import? -- A4)")

  # Tear the served listener down even if an assertion below fails.
  on.exit(try(GUImorphWeb::gmw_close(), silent = TRUE), add = TRUE)

  withr::with_libpaths(templib, action = "prefix", {
    # 4. The WEB-00 bundle ships INSIDE the installed package.
    bundle <- system.file("htmlwidgets", "guimorphweb-three.js",
                          package = "GUImorphWeb")
    expect_true(nzchar(bundle))

    # 5. Serve the committed fixture from the installed package over loopback.
    url <- GUImorphWeb:::.gmw_serve_mesh(fixture, open = FALSE)

    # specimen.ply is served raw and byte-identical to disk (never JSON).
    resp <- gmw_try_fetch(paste0(url, "specimen.ply"), timeout = 60)
    expect_false(is.null(resp))
    expect_equal(resp$status_code, 200L)
    disk <- readBin(fixture, "raw", n = file.info(fixture)$size)
    expect_identical(resp$content, disk)

    # 6. The served page carries zero external references (offline by
    #    construction). The plan-03 tab-close beacon uses a relative "close"
    #    target, so it introduces no absolute http(s):// reference here.
    page_resp <- gmw_try_fetch(url, timeout = 60)
    expect_false(is.null(page_resp))
    page <- rawToChar(page_resp$content)
    expect_false(grepl('src="https?://', page))
    expect_false(grepl('href="https?://', page))
  })
})
