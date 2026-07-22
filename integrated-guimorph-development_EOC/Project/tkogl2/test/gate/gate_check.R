`%||%` <- function(a, b) if (!is.null(a)) a else b

args <- commandArgs(trailingOnly = TRUE)
dyn_ext <- .Platform$dynlib.ext
script_file <- sub("^--file=", "", commandArgs(trailingOnly = FALSE)[grep("^--file=", commandArgs(trailingOnly = FALSE))][1] %||% "gate_check.R")
script_dir <- normalizePath(dirname(script_file), winslash = "/", mustWork = FALSE)

resolve_dylib <- function(user_arg = NULL) {
  if (!is.null(user_arg) && nzchar(user_arg)) {
    return(normalizePath(user_arg, winslash = "/", mustWork = TRUE))
  }

  candidates <- c(
    file.path(script_dir, paste0("gateext", dyn_ext)),
    file.path(script_dir, "build", paste0("gateext", dyn_ext)),
    file.path(script_dir, "build", "Release", paste0("gateext", dyn_ext)),
    file.path(script_dir, "build-gate", paste0("gateext", dyn_ext)),
    file.path(script_dir, "build-gate", "Release", paste0("gateext", dyn_ext))
  )

  hit <- candidates[file.exists(candidates)]
  if (length(hit) == 0) {
    stop("Could not find gate extension dylib. Pass explicit path as first argument.", call. = FALSE)
  }

  normalizePath(hit[[1]], winslash = "/", mustWork = TRUE)
}

library(tcltk)

winsys <- tclvalue(.Tcl("tk windowingsystem"))
if (!identical(winsys, "aqua")) {
  message(sprintf(
    paste0(
      "gate_check: FAIL - `tk windowingsystem` returned \"%s\", expected \"aqua\".\n",
      "GUImorph requires an R session linked against an Aqua (Cocoa) Tk, not\n",
      "X11/XQuartz. The interactive OpenGL digitizing viewport cannot embed into\n",
      "an X11 Tk window.\n",
      "See docs/AQUA-TK-SETUP.md for how to obtain an Aqua-Tk R session on macOS."
    ),
    winsys
  ))
  quit(save = "no", status = 1)
}

dylib_path <- resolve_dylib(args[[1]] %||% NULL)
tcl("load", dylib_path, "Gateext")

gate_winsys <- tclvalue(.Tcl("gate_winsys"))
stopifnot(identical(gate_winsys, "aqua"))

cat("gate_check: PASS\n")
