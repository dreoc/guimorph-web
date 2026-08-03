# =====================================================================
# MANUAL UAT  (WEB-03 render + CMP-01 display-host load) -- human-check only
# ---------------------------------------------------------------------
# Neither step below can be automated without CI on real Windows + macOS
# display hosts (human_verify_mode = end-of-phase; D-10 verification-only).
# Run each on a fully-offline stock machine, R started with `--no-init-file`
# (STATE.md: a site-library `renv` makes bare R startup hang under a
# restricted network). Do NOT fabricate an automated pass for either. Sign
# off in .planning/phases/03-offline-packaging-and-lifecycle/03-VALIDATION.md
# (Manual-Only) when all pass. These steps are mirrored there verbatim.
#
# Step A -- WEB-03 offline render UAT (carries the Phase-2 owed render UAT):
#   On a fully-offline stock macOS AND a fully-offline stock Windows:
#     1. Build the tarball (`R CMD build .` or pkgbuild::build()).
#     2. Install it OFFLINE, network physically off:
#          install.packages(<tarball>, repos = NULL, type = "source",
#                           dependencies = FALSE)
#     3. Open a viewport for EACH of the 6 reference specimens; confirm each
#        renders SHADED (not black), orbits, zooms, and `r`-resets.
#     4. Confirm the worst case `B7_1_clean.ply` (~30 MB, 363,283 verts)
#        transfers and frames acceptably (this is the ~30 MB case the fast
#        automated smoke deliberately leaves out -- it uses the ~0.77 MB
#        B12_1_clean.ply fixture).
#     5. Confirm the tab-close beacon stops the server: close the browser tab
#        and verify `httpuv::listServers()` empties for that token; then
#        `gmw_close()` stops all remaining listeners.
#
# Step B -- CMP-01 display-host load gate (owed from Phase 2):
#   On a host WITH a display, `library(GUImorphWeb)` succeeds and
#   `GUImorphWeb:::.gmw_engine$ok` is UNCHANGED by the Phase-3 lifecycle work
#   (the native tkogl2 oracle still loads where the platform supports it). On
#   an unsupported host `.gmw_engine$ok` is FALSE and non-fatal for the browser
#   paths -- that is expected, not a failure of this gate.
# =====================================================================

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
