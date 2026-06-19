# Capture post-renv warning baseline (Phase 6 / Plan 06-01 Task 2)
#
# Run in a fresh Windows R 4.6+ session after renv::init + commit:
#   setwd(".../GUImorphDevelopment")
#   renv::restore()
#   source("../../scripts/capture-renv-warnings.R")

pkg_root <- getwd()
if (!file.exists(file.path(pkg_root, "renv.lock"))) {
  stop("renv.lock not found — run scripts/init-renv.R first")
}

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

message("renv::restore() ...")
renv::restore()

if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools", repos = "https://cloud.r-project.org")
}

message("devtools::load_all('.') ...")
w <- NULL
withCallingHandlers(
  suppressMessages(devtools::load_all(".")),
  warning = function(w_) {
    w <<- c(w, w_)
    invokeRestart("muffleWarning")
  }
)

out_file <- file.path(
  dirname(pkg_root), "..", "..", "..",
  ".planning", "smoke-test-findings-renv-warnings.txt"
)
out_file <- normalizePath(out_file, mustWork = FALSE)

sink(out_file)
cat("Captured:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n")
cat("Package root:", pkg_root, "\n\n")
if (length(w)) {
  print(w)
} else {
  cat("(no warnings)\n")
}
sink()

message("Warnings written to: ", out_file)
message("Append formatted section to .planning/smoke-test-findings.md (Phase 6 — renv Baseline)")
