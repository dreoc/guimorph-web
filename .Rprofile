## Repo-root profile for the guimorph-web RStudio project.
##
## The R package lives three directories down and owns the renv library:
##   integrated-guimorph-development_EOC/Project/GUImorphDevelopment
##
## Opening guimorph-web.Rproj puts the working directory at the repo root, where
## there is no renv/activate.R, so renv would not otherwise engage. This loads
## the package's renv project explicitly.
##
## If this misbehaves, delete this file. The package-level project
## (GUImorphDevelopment.Rproj) activates renv on its own and is unaffected.

local({
  pkg <- file.path(
    "integrated-guimorph-development_EOC", "Project", "GUImorphDevelopment"
  )

  if (!file.exists(file.path(pkg, "renv.lock"))) return(invisible(NULL))
  if (!requireNamespace("renv", quietly = TRUE)) {
    message("renv not installed; root project running against the system library.")
    return(invisible(NULL))
  }

  tryCatch(
    renv::load(pkg),
    error = function(err) {
      message(
        "renv::load() failed at repo root: ", conditionMessage(err), "\n",
        "Falling back to the system library. Open ", pkg,
        "/GUImorphDevelopment.Rproj for a renv-backed session."
      )
    }
  )
})
