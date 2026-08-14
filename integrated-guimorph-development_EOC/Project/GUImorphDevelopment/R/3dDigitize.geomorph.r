# Developers to update this function
get_geomorph_date <- function()
{
  .module_banner("geomorph")    # NO OTHER CHANGES MADE TO THIS FILE !
  invisible(NULL)
}

################# main data structure ##############################
#dgtDataList
#dgtDataList[imgId][[1]]: speciman dir
#dgtDataList[imgId][[2]]: font
#dgtDataList[imgId][[3]]: number of landmark

#dgtDataList[1][[4]]: curves
#dgtDataList[imgId][[5]]: template
#dgtDataList[imgId][[6]]: rotation
#dgtDataList[imgId][[7]]: zoom
#dgtDataList[imgId][[8]]: surface file

# Phase 6 (UI-01/UI-02): the Tk GPA tab builder (ui.geomorph, all tk2* widgets),
# the bind/init/updateWidgets S3 methods, the tkmessageBox dialogs and the
# tkgetSaveFile pickers were removed. GPA option flags now travel from the
# browser GPA tab as a bare CSV over the /gpa route into the gpagen option
# tclVars via .gmw_session_to_geomorph_env(); the CSV/RDS export save-name comes
# from the browser field over /savepath (R owns the directory). The GPA/PCA/
# export compute logic below (compute / .build_geomorph_data forwarding) is
# unchanged (DGT-03 parity preserved).

#checks if given int value is not zero, returns boolean
itob <- function(int) {
  if (int == 0) {
    return(FALSE)
  } else {
    return(TRUE)
  }
}

.safe_gpagen_maxiter <- function(raw) {
  parsed <- suppressWarnings(as.numeric(raw))
  if (is.na(parsed) || parsed < 1) {
    return(1)
  }
  as.integer(parsed)
}

# C landmark query can duplicate after specimen switch (queryFromR false negative).
# Prefer C when count matches; fall back to R-side activeDataList[[10]] from openDgt.
.landmarks_for_specimen <- function(e, i) {
  expected <- as.numeric(e$landmarkNum)
  stored   <- e$activeDataList[[i]][[10]]
  # Browser/session path: there is NO native Tk canvas, so calling the C/Tk
  # getLandmark() -> shows() -> tcl("show", ...) SEGFAULTS (an uncatchable
  # C-level crash, so the /gpa try() cannot protect it). The session env already
  # holds every landmark in activeDataList[[i]][[10]]; read it directly.
  if (isTRUE(e$gmw_session_source)) {
    if (!is.null(stored) && is.matrix(stored)) {
      return(stored)
    }
    return(NULL)
  }
  from_c <- getLandmark(i)
  if (!is.null(from_c) && nrow(from_c) == expected) {
    return(from_c)
  }
  if (!is.null(stored) && is.matrix(stored) && nrow(stored) == expected) {
    return(stored)
  }
  from_c
}

# gpagen return uses $coords in geomorph 4.x; legacy code used $coord
.gm_aligned_coords <- function(gm.res) {
  if (!is.null(gm.res$coords)) {
    return(gm.res$coords)
  }
  gm.res$coord
}

.gm_results_or_warn <- function(e) {
  gm.res <- e$gm.results
  if (is.null(gm.res)) {
    gm.res <- get0("gm.results", envir = .GlobalEnv, ifnotfound = NULL)
  }
  if (is.null(gm.res)) {
    # Surfaced browser-side (modal / status), no Tk dialog.
    message("GUImorphWeb: run Compute first.")
    return(NULL)
  }
  gm.res
}

#computes shape object data and performs analysis
# shared data assembly: builds the p x k x n array + curve/surface defs.
# Returns NULL if a specimen has the wrong point counts (message already shown).
.build_geomorph_data <- function(e) {
  if (!is.null(e$activeDataList[[1]][[8]]) && !is.null(nrow(e$activeDataList[[1]][[8]]))) e$sliderNum <- nrow(e$activeDataList[[1]][[8]])
  dbg("compute")
  nSpecimen <- length(e$activeDataList)

  coords.lmk <- c()
  coords.lmk <- array(NA, c(as.numeric(e$landmarkNum), 3, nSpecimen))
  coords.anc <- c()
  coords.anc <- array(NA, c(as.numeric(e$anchorNum), 3, nSpecimen))
  #grabs landmarks for ith specimen
  for(i in 1:nSpecimen){
    landmarks <- .landmarks_for_specimen(e, i)
    if(is.null(landmarks) || nrow(landmarks) != as.numeric(e$landmarkNum)) {
      message(paste("GUImorphWeb: incorrect num of landmark for specimen", i))
      return ()
    }
    coords.lmk[,,i] <- landmarks
  }

  #print(paste("start to compute ... ...")
  #print(coords)
  curves <- NULL
  if (itob(tclvalue(e$curves))) {
    curves <- matrix(e$activeDataList[[1]][[4]],ncol=3)
  }
  # when read from .nts file curves are a list and error is given:  Error in x[s[, 3], ] : invalid subscript type 'list'
  # It must be unlisted
  # and re-matrixed as so:
  if (is.list(curves)){
    curves<-matrix(unlist(curves),ncol=3)
  }
  surfaces <- NULL
  if (itob(tclvalue(e$surfaces))) {
    if(itob(tclvalue(e$anchorsSurface))){
      for(i in 1:nSpecimen){
        anchors <- getAnchor(i)
        if(length(anchors) == 0) {
          dbg("No anchors present, cannot use for GPA analysis")
          return()
        }
        if(nrow(anchors) != as.numeric(e$anchorNum)) {
          message(paste("GUImorphWeb: incorrect num of anchor for specimen", i))
          return()
        }
        coords.anc[,,i] <- anchors
      }
      coords.A <- array(NA, dim = c(as.numeric(e$sliderNum) + as.numeric(e$landmarkNum) + as.numeric(e$anchorNum), 3, nSpecimen))
      surfaces <- matrix((as.numeric(e$landmarkNum) + as.numeric(e$anchorNum) + 1):dim(coords.A)[1], ncol=1)
    }
    else {
      coords.A <- array(NA,dim = c(as.numeric(e$sliderNum) + as.numeric(e$landmarkNum),3,nSpecimen))
      surfaces <-matrix((as.numeric(e$landmarkNum) + 1):dim(coords.A)[1],ncol=1)
    }

    for(i in 1:nSpecimen){
      surfaceMatrix <- NULL
      surfaceMatrix <- e$activeDataList[[i]][[8]]
      dim(surfaceMatrix)
      rows <- nrow(surfaceMatrix)
      if(is.null(rows)) {
        coords.A <- array(coords.lmk,dim = c(as.numeric(e$landmarkNum),3,nSpecimen))
        next()
      }
      #this is here because the .nts file written to disk is a composite rbound lmk + surfaces
      # this is not the case when we read in a .dgt file.
      if((rows !=as.numeric(e$sliderNum)) && itob(tclvalue(e$anchorsSurface))){
        surfaceMatrix<-surfaceMatrix[(as.numeric(e$landmarkNum) + as.numeric(e$anchorNum) + 1):nrow(surfaceMatrix),]
      }
      else if(rows !=as.numeric(e$sliderNum)) {
        surfaceMatrix<-surfaceMatrix[(as.numeric(e$landmarkNum) + 1):nrow(surfaceMatrix),]
      }

      if(itob(tclvalue(e$anchorsSurface)) && !anyNA(coords.anc)) {
        coords.A[,,i] <- rbind(coords.lmk[,,i], rbind(coords.anc[,,i],surfaceMatrix))
        surfaces <- matrix((as.numeric(e$landmarkNum) + 1):dim(coords.A)[1], ncol=1)
      }
      else {
        coords.A[,,i]<-as.matrix(rbind(coords.lmk[,,i],surfaceMatrix))
      }
    }
  } else {
      coords.A <- array(coords.lmk,dim = c(as.numeric(e$landmarkNum),3,nSpecimen))
  }

  list(land = coords.A, curves = curves, surfaces = surfaces)
}

# geomorph-native export: a plethodon-style list saved as .rds
exportGeomorph <- function(e) {
  if (is.null(e$activeDataList) || length(e$activeDataList) == 0) {
    message("GUImorphWeb: no specimens to export."); return(invisible())
  }
  gd <- .build_geomorph_data(e)
  if (is.null(gd)) return(invisible())
  n  <- dim(gd$land)[3]
  nm <- tryCatch(names(e$activeDataList), error = function(err) NULL)
  if (is.null(nm) || length(nm) != n || any(!nzchar(nm))) nm <- paste0("specimen_", seq_len(n))
  dimnames(gd$land) <- list(NULL, c("x", "y", "z"), nm)
  gmData <- list(land = gd$land, curves = gd$curves, surfaces = gd$surfaces, specimen.names = nm)

  ## Save-name comes from the browser save-name field over the Plan-01 /savepath
  ## route; R owns the directory (the session browse dir), so the browser can
  ## never steer the write location (T-6-18). An empty save-name keeps the
  ## object in the workspace as gmData (the former Cancel behaviour).
  fileName <- ""
  if (!is.null(e$save_name) && nzchar(e$save_name)) {
    fileName <- file.path(if (!is.null(e$save_dir)) e$save_dir else getwd(),
                          basename(e$save_name))
  }
  objName <- "gmData"
  if (nchar(fileName) > 0) {
    if (length(grep("\\.rds$", fileName, ignore.case = TRUE)) == 0) fileName <- paste0(fileName, ".rds")
    saveRDS(gmData, file = fileName)
    objName <- make.names(tools::file_path_sans_ext(basename(fileName)))
  }

  ## put it into the R workspace (same mechanism compute() uses for gm.results)
  assign(objName, gmData, envir = as.environment(1))

  cat(sprintf("\n# GUImorphWeb -> geomorph : object '%s' is now in your workspace\n", objName))
  cat(sprintf("#   %d specimens, %d points, %d dims  (curves: %s, surfaces: %s)\n",
              n, dim(gd$land)[1], dim(gd$land)[2],
              if (is.null(gd$curves)) "none" else nrow(gd$curves),
              if (is.null(gd$surfaces)) "none" else length(gd$surfaces)))
  if (nchar(fileName) > 0) cat("saved:", fileName, "\n")
  cat(sprintf("Y <- geomorph::gpagen(%s$land, curves = %s$curves, surfaces = %s$surfaces)\n\n", objName, objName, objName))
  invisible(gmData)
}

compute <- function(e) {
  gd <- .build_geomorph_data(e)
  if (is.null(gd)) return(invisible())
  coords.A <- gd$land
  curves   <- gd$curves
  surfaces <- gd$surfaces
  max_iter <- .safe_gpagen_maxiter(tclvalue(e$maxiter))
  if (!is.null(e$statusLabel) && max_iter == 1L) {
    setStatus(e, "Invalid GPA iteration input; using max.iter = 1.", "warning")
  }

  dbg("before gpagen")
  e$gm.results <- geomorph::gpagen(A=coords.A,
                         curves = curves,
                         surfaces = surfaces,
                         max.iter = max_iter,
                         PrinAxes = itob(tclvalue(e$PrinAxes)),
                         ProcD = itob(tclvalue(e$ProcD)),
                         Proj = itob(tclvalue(e$Proj)),
                         print.progress = itob(tclvalue(e$printP)),
                         approxBE = itob(tclvalue(e$approxBE)),
                         Parallel = itob(tclvalue(e$parallel)))


  pos<-1
  envir <- as.environment(pos)
  assign(x = "gm.results", value = e$gm.results, envir = envir)
  summary(e$gm.results)
}

#saves data as .csv
save <- function(e) {
  # Save-name from the browser field over /savepath; R owns the directory. An
  # empty save-name is a no-op (the former Cancel path). (T-6-18)
  filename <- if (!is.null(e$save_name) && nzchar(e$save_name))
    file.path(if (!is.null(e$save_dir)) e$save_dir else getwd(),
              basename(e$save_name)) else ""
  if (nchar(filename)) {
    gm.res <- .gm_results_or_warn(e)
    if (is.null(gm.res)) {
      return()
    }
    aligned <- .gm_aligned_coords(gm.res)
    dfram <- data.frame(
      Csize = gm.res$Csize,
      coords = geomorph::two.d.array(aligned)
    )
    write.csv(dfram, paste(filename, ".csv", sep = ""))
  }
}

#graphs landmarks in xyz plane
plotspecs <- function(e) {
  gm.res <- .gm_results_or_warn(e)
  if (is.null(gm.res)) return()
  aligned   <- .gm_aligned_coords(gm.res)
  consensus <- gm.res$consensus
  ptcex   <- as.numeric(tclvalue(e$ptcex))
  meancex <- as.numeric(tclvalue(e$meancex))
  n <- dim(aligned)[3]
  # rainbow() returns 9-char #RRGGBBAA; THREE.Color only parses #RGB or #RRGGBB.
  cols <- substr(grDevices::rainbow(n), 1L, 7L)
  clouds <- lapply(seq_len(n), function(i) {
    list(coords = aligned[, , i], color = cols[i], size = ptcex * 3)
  })
  clouds[[n + 1L]] <- list(coords = consensus, color = "#ff0000",
                           size = meancex * 4)
  .gmw_view3d(clouds = clouds, title = "Plot Aligned Specimens")
}

plotPCA <- function(e) {
  gm.res <- .gm_results_or_warn(e)
  if (is.null(gm.res)) return()
  aligned <- .gm_aligned_coords(gm.res)
  n <- dim(aligned)[3]
  if (is.null(n) || is.na(n) || n < 2) {
    message("GUImorphWeb PCA: needs at least 2 specimens.")
    return()
  }

  pca <- tryCatch(geomorph::gm.prcomp(aligned), error = function(err) err)
  if (inherits(pca, "error")) {
    message(paste0("GUImorphWeb PCA: the ordination could not be computed. ",
                   "gm.prcomp reported: ", conditionMessage(pca)))
    return()
  }

  # A GPA-aligned sample of n specimens supports at most n - 1 non-zero components,
  # so two specimens yield exactly one. R drops the dimensions of a single-column
  # result, which left `scores` as a plain vector with no dim attribute; both
  # apply(scores, 2, ...) and ncol(scores) then failed ("dim(X) must have a positive
  # length") before the one-axis branch below could be reached. as.matrix() restores
  # the m x 1 shape, so the branch works as originally intended.
  scores <- pca$x
  if (is.null(scores) || length(scores) == 0L) {
    message("GUImorphWeb PCA: the ordination returned no component scores.")
    return()
  }
  scores <- as.matrix(scores)

  nPC  <- ncol(scores)
  m    <- nrow(scores)   # specimens actually represented in the ordination
  cols <- grDevices::rainbow(m)

  # Percent of total variance per component. Guard the degenerate case where the
  # shapes are identical, which makes the total zero and every ratio NaN.
  vv    <- apply(scores, 2, stats::var)
  total <- sum(vv)
  ve    <- if (is.finite(total) && total > 0) round(100 * vv / total, 1) else rep(NA_real_, nPC)
  lab   <- function(i) if (is.na(ve[i])) paste0("PC", i) else paste0("PC", i, " (", ve[i], "%)")

  # macOS: render to a temp PNG + browser (no native quartz window to crash on
  # close under Tk's Aqua run loop). Windows: unchanged interactive device.
  draw <- function() {
    if (nPC >= 2) {
      plot(scores[, 1], scores[, 2], pch = 19, col = cols, cex = 1.5,
        xlab = lab(1), ylab = lab(2),
        main = "Shape morphospace (PCA)")
      text(scores[, 1], scores[, 2], labels = seq_len(m), pos = 3, cex = 0.9)
    } else {
      plot(scores[, 1], rep(0, m), pch = 19, col = cols, cex = 1.5, yaxt = "n", ylab = "",
        xlab = lab(1),
        main = paste0("Shape PCA (", m, " specimens: one axis)"))
      text(scores[, 1], rep(0, m), labels = seq_len(m), pos = 3, cex = 0.9)
    }
  }
  .plot_show(draw)
}

# ---------------------------------------------------------------------------
#  Browser GPA / export trigger seams (DGT-03)
#
#  The /gpa and /export routes (05-02) forward-call the three functions below.
#  "Identical to native" holds by CONSTRUCTION: compute()/save()/exportGeomorph()
#  and their .build_geomorph_data() assembly are reused VERBATIM; the only new
#  code is where the arrays come from. .gmw_session_to_geomorph_env() reads the
#  server-owned digitizing record (.gmw_session[[token]]) and populates the SAME
#  activeDataList slots the native path fills -- landmarks into [[i]][[10]] (the
#  fallback .landmarks_for_specimen already reads when the C getLandmark is
#  absent/wrong-size), session-scoped curves into [[1]][[4]], surfaces into
#  [[i]][[8]] -- plus landmarkNum/anchorNum/sliderNum and the gpagen option
#  fields as tclVars, so .build_geomorph_data()/compute() run with ZERO edits to
#  their forwarding. The gpagen option forwarding in compute() is left untouched
#  (pinned by the test-gpa-parity.R source-scan). Curves stay session-scoped
#  three-index rows (RESEARCH Pitfall 5 / A7).
# ---------------------------------------------------------------------------

#' Build a geomorph analysis env from a server-owned digitizing session
#'
#' Materialises a plain environment \code{e} that \code{.build_geomorph_data(e)}
#' and \code{compute(e)} accept unchanged: the per-specimen landmarks are placed
#' in \code{activeDataList[[i]][[10]]}, the session-scoped curve index rows in
#' \code{activeDataList[[1]][[4]]}, per-specimen surfaces in
#' \code{activeDataList[[i]][[8]]}, and \code{landmarkNum}/\code{anchorNum}/
#' \code{sliderNum} are derived from the record. The gpagen option fields
#' (\code{maxiter}, \code{curves}, \code{surfaces}, \code{anchorsSurface},
#' \code{PrinAxes}, \code{ProcD}, \code{Proj}, \code{printP}, \code{approxBE},
#' \code{parallel}) are set as \code{tclVar}s carrying the values from
#' \code{opts}, in the exact form \code{tclvalue()} in \code{compute}/
#' \code{.build_geomorph_data} reads them -- so no forwarding line is edited.
#' No \code{activeDataList}/Tk/C-engine mutation happens; the env is disposable.
#' @param token the per-viewport session token to read.
#' @param opts named list of gpagen options; missing keys take native defaults.
#' @return a fresh environment ready for \code{.build_geomorph_data}/\code{compute}.
#' @keywords internal
#' @noRd
.gmw_session_to_geomorph_env <- function(token, opts = list()) {
  s <- .gmw_session_get(token)
  if (is.null(s)) {
    stop("gmw gpa/export: no digitizing session for this token.", call. = FALSE)
  }
  specs <- s$specimens
  nSpec <- length(specs)
  if (nSpec < 1L) {
    stop("gmw gpa/export: the session has no specimens.", call. = FALSE)
  }

  e <- new.env()

  # Populate the existing activeDataList slots from the session record. Each
  # specimen entry is a 10-slot list so the [[4]]/[[8]]/[[10]] indices the
  # analytical code reads resolve; unused slots stay NULL.
  adl <- vector("list", nSpec)
  for (i in seq_len(nSpec)) {
    slot <- vector("list", 10L)
    land_i <- specs[[i]]$land
    if (!is.null(land_i)) slot[[10]] <- as.matrix(land_i)
    surf_i <- specs[[i]]$surfaces
    if (!is.null(surf_i) && nrow(as.matrix(surf_i)) > 0L) slot[[8]] <- as.matrix(surf_i)
    adl[[i]] <- slot
  }
  # Curves are session-scoped (shared across specimens) -> activeDataList[[1]][[4]].
  if (!is.null(s$curves) && nrow(as.matrix(s$curves)) > 0L) {
    adl[[1]][[4]] <- s$curves
  }
  e$activeDataList <- adl

  e$landmarkNum <- if (!is.null(specs[[1]]$land)) nrow(as.matrix(specs[[1]]$land)) else 0L
  e$anchorNum   <- if (!is.null(specs[[1]]$anchor)) nrow(as.matrix(specs[[1]]$anchor)) else 0L
  e$sliderNum   <- if (!is.null(specs[[1]]$surfaces)) nrow(as.matrix(specs[[1]]$surfaces)) else 0L

  # gpagen option fields as tclVars, exactly as compute()/.build_geomorph_data()
  # read them via tclvalue(). Defaults mirror the native GPA-tab tclVar seeds.
  optv <- function(key, default) {
    v <- if (!is.null(opts[[key]])) opts[[key]] else default
    tcltk::tclVar(v)
  }
  e$maxiter        <- optv("maxiter", 2)
  e$curves         <- optv("curves", 0)
  e$surfaces       <- optv("surfaces", 0)
  e$anchorsSurface <- optv("anchorsSurface", 0)
  e$anchorsCurve   <- optv("anchorsCurve", 0)
  e$PrinAxes       <- optv("PrinAxes", 1)
  e$ProcD          <- optv("ProcD", 1)
  e$Proj           <- optv("Proj", 1)
  e$printP         <- optv("printP", 0)
  e$approxBE       <- optv("approxBE", 0)
  e$parallel       <- optv("parallel", 0)
  e$statusLabel    <- NULL

  # CSV/RDS export save-name comes from the browser field over the Plan-01
  # /savepath route; R owns the directory (the session browse dir). save() and
  # exportGeomorph() read these two slots instead of the retired Tk save picker,
  # so /save-family writes carry no browser-chosen path (T-6-18).
  e$save_name <- if (!is.null(s$save_name)) s$save_name else NULL
  e$save_dir  <- if (!is.null(s$browse_dir)) s$browse_dir else getwd()

  # Marks this env as the browser/session read path so .landmarks_for_specimen
  # (and any other native-query fallback) NEVER calls into the Tk canvas, which
  # would segfault headless. Landmarks live in activeDataList[[i]][[10]].
  e$gmw_session_source <- TRUE

  e
}

#' Run GPA from the browser through the session read path
#'
#' Trigger seam for the \code{/gpa} route (05-02). Builds the analysis env from
#' the session and calls the existing \code{compute(e)} VERBATIM, which forwards
#' every parity-critical gpagen option and stores the result in
#' \code{e$gm.results} and the workspace \code{gm.results} (so the result-plot
#' seams -- \code{plotspecs}/\code{plotPCA}/\code{plotMeanShape}, all routing
#' through \code{.gmw_view3d} -- keep working unchanged). Output is identical to
#' the native path by construction.
#' @param token the per-viewport session token.
#' @param opts named list of gpagen options forwarded to the env builder.
#' @return the \code{gm.results} object, invisibly.
#' @keywords internal
#' @noRd
.gmw_gpa_session <- function(token, opts = list()) {
  e <- .gmw_session_to_geomorph_env(token, opts)
  dbg(paste0("gmw gpa: ", token))
  compute(e)
  invisible(e$gm.results)
}

#' Export the session GPA/coordinate data from the browser
#'
#' Trigger seam for the \code{/export} route (05-02). \code{fmt} is validated
#' against the allow-list \code{c("csv","rds")} and is NEVER treated as a path;
#' the export target is chosen R-side by the existing exporters. \code{"csv"}
#' dispatches to \code{save(e)} (aligned-coordinate CSV of the last GPA result)
#' and \code{"rds"} to \code{exportGeomorph(e)} (geomorph-native list). No second
#' serializer is introduced -- both exporters are reused verbatim (T-5-13/T-5-14).
#' @param token the per-viewport session token.
#' @param fmt one of \code{"csv"} or \code{"rds"}; anything else is rejected.
#' @return the value of the dispatched exporter, invisibly.
#' @keywords internal
#' @noRd
.gmw_export_session <- function(token, fmt) {
  if (!(length(fmt) == 1L && !is.na(fmt) && fmt %in% c("csv", "rds"))) {
    stop("gmw export: format must be one of c(\"csv\", \"rds\").", call. = FALSE)
  }
  e <- .gmw_session_to_geomorph_env(token, list())
  dbg(paste0("gmw export: ", token, " fmt=", fmt))
  if (identical(fmt, "csv")) {
    invisible(save(e))
  } else {
    invisible(exportGeomorph(e))
  }
}

plotMeanShape <- function(e) {
  gm.res <- .gm_results_or_warn(e)
  if (is.null(gm.res)) return()
  if (!requireNamespace("Rvcg", quietly = TRUE)) {
    message("GUImorphWeb mean shape: needs Rvcg. Run install.packages(\"Rvcg\").")
    return()
  }
  M <- as.matrix(gm.res$consensus)
  factor <- suppressWarnings(as.numeric(tclvalue(e$bpFactor)))
  if (is.na(factor) || factor <= 0) factor <- 2
  spacing <- stats::median(Rvcg::vcgKDtree(M, M, k = 2)$distance[, 2])
  r <- factor * spacing
  cat(sprintf("Mean-shape mesh: spacing %.4f, factor %.2f, radius %.4f\n", spacing, factor, r))
  mesh <- try(Rvcg::vcgBallPivoting(M, radius = r, clustering = 0.2, angle = pi / 2), silent = TRUE)
  if (inherits(mesh, "try-error") || is.null(mesh$it) || ncol(mesh$it) == 0) {
    message(sprintf("GUImorphWeb mean shape: no faces at radius %.4f. Raise the factor for holes, lower it if faces fuse.", r))
    return()
  }
  wire <- as.character(tclvalue(e$meshWire)) == "1"
  .gmw_view3d(
    clouds = list(list(coords = M, color = "#ff0000", size = 4)),
    mesh = list(vertices  = t(mesh$vb[1L:3L, , drop = FALSE]),
                faces     = mesh$it,
                color     = if (wire) "#000000" else "#d3d3d3",
                wireframe = wire),
    title = "Plot Mean Shape")
}
