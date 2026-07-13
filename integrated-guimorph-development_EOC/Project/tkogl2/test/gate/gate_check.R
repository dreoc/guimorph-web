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
stopifnot(identical(winsys, "aqua"))

dylib_path <- resolve_dylib(args[[1]] %||% NULL)
tcl("load", dylib_path, "Gateext")

gate_winsys <- tclvalue(.Tcl("gate_winsys"))
stopifnot(identical(gate_winsys, "aqua"))

cat("gate_check: PASS\n")
