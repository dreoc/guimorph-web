#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
#  check-macos.R -- verifies the Phase 1 claims that Windows cannot prove.
#
#  Run from the repo root in a plain R session (NOT RStudio -- RStudio serves
#  browseURL() over its own HTTP server, which hides whether file:// works):
#
#      setwd("~/dev/guimorph-web")
#      source("scripts/check-macos.R")
#
#  Reports six things and states plainly what each one does or does not prove.
# ---------------------------------------------------------------------------

PKG <- "integrated-guimorph-development_EOC/Project/GUImorphDevelopment"

hdr <- function(n, s) cat(sprintf("\n== %d. %s ==\n", n, s))
ok  <- function(...) cat("   PASS  ", ..., "\n", sep = "")
no  <- function(...) cat("   FAIL  ", ..., "\n", sep = "")
inf <- function(...) cat("         ", ..., "\n", sep = "")

results <- list()

# --- 1. environment ---------------------------------------------------------
hdr(1, "Environment")
inf(R.version.string)
inf("platform: ", R.version$platform)
if (Sys.info()[["sysname"]] == "Darwin") {
  inf("macOS:    ", tryCatch(system("sw_vers -productVersion", intern = TRUE),
                             error = function(e) "unknown"))
  inf("arch:     ", Sys.info()[["machine"]])
} else {
  no("Not macOS. This script only means anything on the Tahoe box.")
}
inf("XQuartz:  ", if (file.exists("/Applications/Utilities/XQuartz.app") ||
                      file.exists("/opt/X11")) "present" else "absent")

# --- 2. does rgl load? THE PRECONDITION -------------------------------------
hdr(2, "Can rgl load? (this decides what the rest proves)")
rgl_installed <- requireNamespace("rgl", quietly = TRUE)
rgl_loads <- FALSE
if (!rgl_installed) {
  inf("rgl is not installed. PLT-02 is trivially satisfied but not stressed.")
  inf("For the real test, install rgl and re-run: install.packages(\"rgl\")")
} else {
  rgl_loads <- tryCatch({ loadNamespace("rgl"); TRUE },
                        error = function(e) { inf("rgl load error: ",
                                                  conditionMessage(e)); FALSE })
  if (rgl_loads) {
    inf("rgl LOADS on this machine.")
    inf("So this box is not reproducing the Tahoe failure, and a passing")
    inf("result below does NOT prove PLT-02. It only proves nothing regressed.")
  } else {
    ok("rgl FAILS to load. This is the condition PLT-02 exists for.")
  }
}
results$rgl_loads <- rgl_loads

# --- 3. package loads -------------------------------------------------------
hdr(3, "PLT-02: does GUImorphWeb load?")
loaded <- tryCatch({
  suppressMessages(devtools::load_all(PKG, quiet = TRUE)); TRUE
}, error = function(e) { no("load_all failed: ", conditionMessage(e)); FALSE })
results$loaded <- loaded

if (loaded) {
  ok("GUImorphWeb loaded.")
  pulled_rgl <- "rgl" %in% loadedNamespaces()
  if (pulled_rgl) {
    no("rgl IS in loadedNamespaces() after load. Something still pulls it in.")
    inf("Find it with: sapply(loadedNamespaces(), function(p) ",
        "'rgl' %in% names(getNamespaceInfo(p, 'imports')))")
  } else {
    ok("rgl is NOT in loadedNamespaces(). Nothing pulls it in.")
  }
  results$pulled_rgl <- pulled_rgl

  d <- packageDescription("GUImorphWeb", lib.loc = NULL)
  inf("Imports: ", gsub("\\s+", " ", d$Imports))
}

# --- 4. viewport from file:// ----------------------------------------------
hdr(4, "WEB-00: three.js viewport from file://")
if (loaded) {
  f <- tryCatch({
    set.seed(1)
    GUImorphWeb:::.gmw_view3d(
      clouds = list(
        list(coords = matrix(rnorm(3000), ncol = 3), color = "#3366cc", size = 3),
        list(coords = matrix(rnorm(300),  ncol = 3), color = "#cc0000", size = 6)),
      title = "macOS viewport check")
  }, error = function(e) { no("viewport failed: ", conditionMessage(e)); NULL })
  if (!is.null(f)) {
    ok("Wrote and opened: ", f)
    inf("CHECK BY EYE: white background, two point clouds, drag rotates,")
    inf("scroll zooms, 'r' resets. URL bar must start with file:// -- if it")
    inf("shows 127.0.0.1 you are in RStudio and this test is invalid.")
  }
  results$viewport <- !is.null(f)
}

# --- 5. result plots on real data ------------------------------------------
hdr(5, "PLT-01 / PLT-03: result plots (needs no native engine)")
fx <- file.path(PKG, "tests/fixtures/parity")
ply <- list.files(fx, "\\.ply$", full.names = TRUE)
if (!loaded) {
  inf("skipped, package did not load")
} else if (length(ply) == 0) {
  inf("skipped, no PLY fixtures found in ", fx)
} else {
  m <- tryCatch(Rvcg::vcgPlyRead(ply[1], updateNormals = TRUE, clean = FALSE),
                error = function(e) { no("vcgPlyRead: ", conditionMessage(e)); NULL })
  if (!is.null(m)) {
    ok(basename(ply[1]), ": ", ncol(m$vb), " verts, ", ncol(m$it), " faces")
    inf("Rvcg reads PLY here, so the Phase 2 mesh path has its input.")
  }
  inf("The full plot check needs a GPA result, so drive it from the GUI:")
  inf("  GUImorphWeb()  ->  load a .dgt  ->  GPA  ->  Plot Aligned Specimens")
  inf("Both plots should open in the browser with no rgl involved.")
}

# --- 6. test suite ----------------------------------------------------------
hdr(6, "Regression suite")
if (loaded) {
  inf("6 failures are known and pre-existing (curve-spinbox tests call")
  inf("functions deleted in 2f65039; curve-tab-gating stubs tcltk via")
  inf("assignInNamespace, which R 4.6 forbids). Anything beyond those 6 is new.")
  inf("Run: devtools::test(\"", PKG, "\")")
}

# --- verdict ----------------------------------------------------------------
cat("\n== VERDICT ==\n")
if (isTRUE(results$loaded) && identical(results$pulled_rgl, FALSE)) {
  if (isTRUE(results$rgl_loads)) {
    cat("   PARTIAL. Package loads and never touches rgl, but rgl works on\n")
    cat("   this machine, so the Tahoe failure was not reproduced. PLT-02\n")
    cat("   stays open until run on a box where rgl genuinely cannot load.\n")
  } else {
    cat("   PLT-02 VERIFIED. rgl cannot load here and GUImorphWeb runs anyway.\n")
    cat("   This is the criterion Windows could not prove.\n")
  }
} else {
  cat("   NOT VERIFIED. See failures above.\n")
}
cat("\nWhat this script does NOT cover: full digitizing, which needs the\n")
cat("native tkogl2.dylib. That is a separate question from Phase 1.\n\n")

invisible(results)
