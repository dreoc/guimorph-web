# R/shell.R -- the surviving, engine-free package shell.
#
# This file is the "decapitation-safe" home for the symbols that used to live in
# rtkogl.R but are NOT part of the native tkogl2 engine (RESEARCH Landmine 1 /
# Pitfall 1). Relocating them here -- and proving the package loads and boots --
# BEFORE rtkogl.R is deleted (Plan 07) keeps the exported entry point, the
# package-level dbg() that transport.R depends on, .plot_show(), .onAttach(), and
# their helpers alive across the demolition. Nothing here touches the engine.

#' Launch the GUImorphWeb browser digitizing shell
#'
#' Boots the browser-based GUImorphWeb shell: starts a loopback \code{httpuv}
#' listener serving the three.js viewport and digitizing chrome, seeds the
#' server-owned browse directory that the in-page file picker lists and opens
#' from, and prints (and, by default, opens) the viewport URL. Landmarks, curve
#' and surface semilandmarks, GPA, and geomorph-compatible export all run in the
#' browser with no native engine and no Tk window.
#'
#' @param dir Directory the in-page file picker lists \code{.dgt}/\code{.ply}
#'   files from and opens selections within (UI-01/D-03). Defaults to
#'   \code{getwd()}. R -- never the browser -- owns every path: the picker only
#'   ever returns a basename R itself enumerated over this directory.
#' @param open Logical. When \code{TRUE} (the default) the viewport URL is
#'   opened with \code{utils::browseURL} as a convenience; it is always printed
#'   first, so a blocked or headless launch degrades to the printed URL rather
#'   than an error.
#' @param debug Logical. When \code{TRUE}, gated diagnostic output
#'   (\code{options(guimorph.debug = TRUE)}) is printed to the console while the
#'   shell runs.
#'
#' @return The served \code{http://127.0.0.1:<port>/<token>/} URL, invisibly.
#' @export
GUImorphWeb <- function(dir = getwd(), open = TRUE, debug = FALSE) {
  options(guimorph.debug = isTRUE(debug))
  # The browser shell boots into an empty viewport (the retired Tk entry likewise
  # started empty and used "Load PLY"); the user opens a specimen through the
  # in-page file picker over the server-owned `dir`. .gmw_serve_mesh() requires a
  # real PLY to mount, so seed the viewport with a tiny in-process placeholder
  # mesh. This keeps every path R-owned, needs no bundled sample data, and needs
  # no native engine (UI-02) -- the entry no longer requires the engine or builds
  # a Tk window.
  boot_ply <- .gmw_boot_specimen()
  .gmw_serve_mesh(ply_path = boot_ply, dir = dir, open = open)
}

# Write a minimal valid ASCII PLY (a unit tetrahedron) to a tempfile: the
# placeholder mesh the browser shell mounts at boot, before the user opens a real
# specimen through the file picker. Kept tiny and self-contained so GUImorphWeb()
# boots with no bundled sample data and no native engine.
.gmw_boot_specimen <- function() {
  f <- tempfile(pattern = "guimorphweb-boot-", fileext = ".ply")
  writeLines(c(
    "ply", "format ascii 1.0", "element vertex 4",
    "property float x", "property float y", "property float z",
    "element face 4", "property list uchar int vertex_indices", "end_header",
    "0 0 0", "1 0 0", "0 1 0", "0 0 1",
    "3 0 1 2", "3 0 1 3", "3 0 2 3", "3 1 2 3"
  ), f)
  f
}

# gated debug printer: prints only when options(guimorph.debug=TRUE),
# which GUImorphWeb(debug=TRUE) sets. Preserves every debugging note.
dbg <- function(...) if (isTRUE(getOption("guimorph.debug", FALSE))) print(...)

# Package version, read from DESCRIPTION rather than written by hand.
#
# The per-module banners used to hardcode the version string, with a comment
# asking developers to update them. They were missed at the 0.9.0 -> 0.9.1 bump,
# so the startup banner (which reads DESCRIPTION) and the module banners (which
# did not) disagreed. Deriving it removes that class of drift.
#
# topenv() resolves to this package namespace, so this also survives a package
# rename with no further edits.
.pkg_version <- function() {
  nm <- environmentName(topenv(environment()))
  tryCatch(as.character(utils::packageVersion(nm)), error = function(err) "unknown")
}

# Module load banner, e.g. "GUImorphWeb 0.9.1 - curve".
.module_banner <- function(module) {
  dbg(paste0("GUImorphWeb ", .pkg_version(), " - ", module))
}


.isMacOS <- function() {
  identical(tolower(Sys.info()[["sysname"]]), "darwin")
}

# One wheel notch should equal one zoom step on every platform. The platform
# notch size is the only platform-specific constant. Windows delivers %D in
# multiples of 120; macOS trackpads deliver much smaller deltas, which the
# pre-Phase-5 as.integer(D/120) truncated to zero and so killed wheel zoom there.
# Dividing by the platform notch and stepping at a residual of 1 restores the
# pre-merge Windows feel (1 notch = 1 step, was 4) while preserving the macOS
# behaviour calibrated in Phase 5 (D/120 stepping at 0.25 == D/30 stepping at 1).
GBL_WHEEL_NOTCH_WINDOWS <- 120
GBL_WHEEL_NOTCH_MACOS   <- 30

normalizeWheelDelta <- function(D) {
  raw <- suppressWarnings(as.numeric(D))
  if (is.na(raw)) return(0)
  raw / if (.isMacOS()) GBL_WHEEL_NOTCH_MACOS else GBL_WHEEL_NOTCH_WINDOWS
}

shortcutLabel <- function(key) {
  if (.isMacOS()) {
    paste0("Cmd+", key)
  } else {
    paste0("Ctrl+", key)
  }
}

# NOTE: .rgl_show() lived in rtkogl.R. PLT-01 routed both 3-D result plots
# through the three.js viewport (.gmw_view3d in view3d.R), so the rgl
# NULL-device/rglwidget fallback it implemented has no caller and was removed.
# .plot_show() below is still live: plotPCA is base-graphics 2-D and does not
# involve rgl.

# Platform-guarded display for a base-graphics (2-D) plot (e.g. the PCA
# morphospace). Windows keeps the interactive dev.new() window. macOS renders to
# a temp PNG and opens it in the browser instead of a native quartz window: the
# quartz window's close animation commits a Core Animation transaction on the
# same main run loop Tk (Aqua) drives, and the two Cocoa clients over-release the
# animation object during the autorelease-pool drain -> EXC_BAD_ACCESS on close.
# Emitting a file and opening it externally (same pattern as .rgl_show) avoids
# the in-process AppKit window entirely. `draw` is a zero-arg closure that issues
# the plot() / text() calls.
.plot_show <- function(draw, width = 800, height = 600) {
  if (.isMacOS()) {
    f <- tempfile(pattern = "guimorph-plot-", fileext = ".png")
    grDevices::png(f, width = width, height = height)
    ok <- FALSE
    tryCatch({ draw(); ok <- TRUE }, finally = grDevices::dev.off())
    if (ok) utils::browseURL(f)
  } else {
    grDevices::dev.new()
    draw()
  }
}

.onAttach <- function(libname, pkgname) {
  gmv <- tryCatch(as.character(utils::packageVersion("geomorph")), error = function(err) "not found")
  packageStartupMessage(
    "GUImorphWeb ", utils::packageVersion(pkgname), " - browser-based 3D digitizing\n",
    "3D geometric morphometric digitizing for the geomorph ecosystem.\n",
    "Using geomorph ", gmv, "\n",
    "Issues / updates: https://github.com/dreoc/guimorph-web"
  )
}
