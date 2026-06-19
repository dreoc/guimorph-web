# Initialize renv for GUImorphDevelopment (Phase 6 / Plan 06-01)
#
# Run on Windows R 4.6+ from repo root (PowerShell):
#   cd \\wsl$\Ubuntu\home\akagi\home\GUImorph
#   & "C:\Program Files\R\R-4.6.0\bin\R.exe" --vanilla -f scripts/init-renv.R
#
# Or from an R session already in GUImorphDevelopment/:
#   source("../../../scripts/init-renv.R")

resolve_pkg_root <- function() {
  env <- Sys.getenv("GUIMORPH_PKG_ROOT", unset = "")
  if (nzchar(env) && dir.exists(env)) {
    return(normalizePath(env, winslash = "/"))
  }

  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg)) {
    script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/"))
    repo_root <- normalizePath(file.path(script_dir, ".."), winslash = "/")
    candidate <- file.path(
      repo_root,
      "integrated-guimorph-development_EOC/Project/GUImorphDevelopment"
    )
    if (dir.exists(candidate)) {
      return(candidate)
    }
    stop(
      "Could not find GUImorphDevelopment under repo root: ", repo_root,
      "\nRun from repo root: cd \\\\wsl$\\Ubuntu\\home\\akagi\\home\\GUImorph",
      "\n  & \"C:\\Program Files\\R\\R-4.6.0\\bin\\R.exe\" --vanilla -f scripts/init-renv.R"
    )
  }

  # Sourced interactively — use cwd if it looks like the package root
  cwd <- normalizePath(getwd(), winslash = "/")
  desc <- file.path(cwd, "DESCRIPTION")
  if (file.exists(desc) && any(grepl("^Package:\\s*GUImorph", readLines(desc, n = 5)))) {
    return(cwd)
  }

  stop(
    "Cannot resolve GUImorphDevelopment path.\n",
    "Option A — PowerShell from repo root:\n",
    "  cd \\\\wsl$\\Ubuntu\\home\\akagi\\home\\GUImorph\n",
    "  & \"C:\\Program Files\\R\\R-4.6.0\\bin\\R.exe\" --vanilla -f scripts/init-renv.R\n",
    "Option B — in R after setwd to GUImorphDevelopment/:\n",
    "  source(\"../../../scripts/init-renv.R\")"
  )
}

pkg_root <- resolve_pkg_root()
setwd(pkg_root)
message("Working directory: ", getwd())

extras <- c(
  "geomorph", "Morpho", "Rvcg", "vegan", "tcltk2",
  "devtools", "rgl", "RRPP", "renv"
)

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

message("Installing DESCRIPTION Imports + workflow extras (D-02)...")
install.packages(setdiff(extras, rownames(installed.packages())), repos = "https://cloud.r-project.org")

if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools", repos = "https://cloud.r-project.org")
}

message("Smoke test: devtools::load_all('.') ...")
suppressWarnings(suppressMessages(devtools::load_all(".")))

if (!file.exists(file.path("inst", "libs", "x64", "tkogl2.dll"))) {
  warning("inst/libs/x64/tkogl2.dll missing — deploy DLL before GUI smoke (see BUILD.md)")
} else {
  message("tkogl2.dll present under inst/libs/x64/")
}

if (file.exists("renv.lock")) {
  message("renv.lock already exists — running renv::snapshot() only")
  renv::snapshot()
} else {
  message("Initializing renv (ignored.packages = devtools)...")
  renv::init(settings = list(ignored.packages = "devtools"))
  renv::snapshot()
}

message("Done. Commit renv.lock, .Rprofile, renv/activate.R, renv/settings.dcf")
message("Then run capture-renv-warnings.R in a fresh session for Task 2 baseline.")
