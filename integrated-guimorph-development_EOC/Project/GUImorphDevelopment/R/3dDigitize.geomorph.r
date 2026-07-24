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

init.geomorph <- function(e) {

}

#configures gui and initializes values
ui.geomorph <- function(e, parent) {
  ## scrollable container: canvas + vertical scrollbar hosting the control frame
  outer  <- ttkframe(parent)
  canvas <- tkcanvas(outer, borderwidth = 0, highlightthickness = 0)
  vsb    <- ttkscrollbar(outer, orient = "vertical", command = function(...) tkyview(canvas, ...))
  tkconfigure(canvas, yscrollcommand = function(...) tkset(vsb, ...))
  tkpack(vsb, side = "right", fill = "y")
  tkpack(canvas, side = "left", fill = "both", expand = TRUE)

  gpagenCtlFrame <- ttkframe(canvas)
  .cbg <- tryCatch(as.character(tkcget(gpagenCtlFrame, "-background")), error = function(err) "")
  if (length(.cbg) == 0 || !nzchar(.cbg[1])) .cbg <- "#f0f0f0"
  tkconfigure(canvas, background = .cbg)
  tkcreate(canvas, "window", 0, 0, anchor = "nw", window = gpagenCtlFrame)
  tkbind(gpagenCtlFrame, "<Configure>", function() tkconfigure(canvas, scrollregion = tkbbox(canvas, "all")))
  tkbind(canvas, "<MouseWheel>", function(D = 0) {
    delta <- normalizeWheelDelta(D)
    if (delta == 0) return(invisible())
    tkyview(canvas, "scroll", as.integer(-sign(delta)), "units")
  })

  fitBtn <- ttkbutton(gpagenCtlFrame, text = "Fit", command = function() onFit(e))
  tkgrid(fitBtn, row = 0, column = 0, pady = 2)
  e$bt2 <- NULL

  ## ---- GPA options ----
  tkgrid(ttkseparator(gpagenCtlFrame, orient = "horizontal"), row = 1, column = 0, sticky = "ew", pady = 2)
  tkgrid(tk2label(gpagenCtlFrame, text = "GPA options"), row = 2, column = 0, sticky = "w", padx = 4)

  tkgrid(tk2label(gpagenCtlFrame, text = "Maximum GPA iterations"), row = 3, column = 0, sticky = "w", padx = 20)
  e$maxiter <- tclVar(2)
  tkgrid(tk2entry(gpagenCtlFrame, textvariable = e$maxiter, width = "8"), row = 4, column = 0, sticky = "w", padx = 20)

  e$anchorsSurface <- tclVar(0)
  tkgrid(tk2checkbutton(gpagenCtlFrame, text = "Use anchors as surface semilandmarks", variable = e$anchorsSurface), row = 5, column = 0, sticky = "w")
  e$anchorsCurve <- tclVar(0)
  tkgrid(tk2checkbutton(gpagenCtlFrame, text = "Use anchors as curve semilandmarks", variable = e$anchorsCurve), row = 6, column = 0, sticky = "w")
  e$curves <- tclVar(0)
  tkgrid(tk2checkbutton(gpagenCtlFrame, text = "Slide semilandmarks on curves", variable = e$curves), row = 7, column = 0, sticky = "w")
  e$surfaces <- tclVar(0)
  tkgrid(tk2checkbutton(gpagenCtlFrame, text = "Slide semilandmarks on surfaces", variable = e$surfaces), row = 8, column = 0, sticky = "w")
  e$PrinAxes <- tclVar(1)
  tkgrid(tk2checkbutton(gpagenCtlFrame, text = "Align the shape data by principal axes", variable = e$PrinAxes), row = 9, column = 0, sticky = "w")
  e$ProcD <- tclVar(1)
  tkgrid(tk2checkbutton(gpagenCtlFrame, text = "Sliding: Procrustes distance (off = bending energy / TPS)", variable = e$ProcD), row = 10, column = 0, sticky = "w")
  e$Proj <- tclVar(1)
  tkgrid(tk2checkbutton(gpagenCtlFrame, text = "Project into tangent space", variable = e$Proj), row = 11, column = 0, sticky = "w")
  e$printP <- tclVar(1)
  tkgrid(tk2checkbutton(gpagenCtlFrame, text = "Print progress bar", variable = e$printP), row = 12, column = 0, sticky = "w")
  e$parallel <- tclVar(0)
  tkgrid(tk2checkbutton(gpagenCtlFrame, text = "Parallel processing (multi-core sliding)", variable = e$parallel), row = 13, column = 0, sticky = "w")
  e$approxBE <- tclVar(0)
  tkgrid(tk2checkbutton(gpagenCtlFrame, text = "Approximate TPS (faster bending-energy)", variable = e$approxBE), row = 14, column = 0, sticky = "w")

  cmputBtn <- ttkbutton(gpagenCtlFrame, text = "Compute", command = function() compute(e))
  assign("bt2", cmputBtn, envir = e)
  tkgrid(cmputBtn, row = 15, column = 0, pady = 2)

  ## ---- Results ----
  tkgrid(ttkseparator(gpagenCtlFrame, orient = "horizontal"), row = 16, column = 0, sticky = "ew", pady = 2)
  tkgrid(tk2label(gpagenCtlFrame, text = "Results"), row = 17, column = 0, sticky = "w", padx = 4)
  saveBtn <- ttkbutton(gpagenCtlFrame, text = "Save Result", command = function() save(e))
  tkgrid(saveBtn, row = 18, column = 0, pady = 2)
  plotspecsBtn <- ttkbutton(gpagenCtlFrame, text = "Plot Aligned Specimens", command = function() plotspecs(e))
  tkgrid(plotspecsBtn, row = 19, column = 0, pady = 2)
  pcaBtn <- ttkbutton(gpagenCtlFrame, text = "PCA (morphospace)", command = function() plotPCA(e))
  tkgrid(pcaBtn, row = 20, column = 0, pady = 2)

  ## ---- Mean-shape plot ----
  tkgrid(ttkseparator(gpagenCtlFrame, orient = "horizontal"), row = 21, column = 0, sticky = "ew", pady = 2)
  tkgrid(tk2label(gpagenCtlFrame, text = "Mean-shape plot"), row = 22, column = 0, sticky = "w", padx = 4)

  tkgrid(tk2label(gpagenCtlFrame, text = "Point size"), row = 23, column = 0, sticky = "w", padx = 20)
  e$ptcex <- tclVar(.5)
  tkgrid(tk2spinbox(gpagenCtlFrame, from = .1, to = 10, increment = .1, tip = "Point size", textvariable = e$ptcex, width = 5), row = 23, column = 0, sticky = "e")

  tkgrid(tk2label(gpagenCtlFrame, text = "Mean Shape size"), row = 24, column = 0, sticky = "w", padx = 20)
  e$meancex <- tclVar(2)
  tkgrid(tk2spinbox(gpagenCtlFrame, from = .5, to = 10, increment = .1, tip = "Mean Shape size", textvariable = e$meancex, width = 5), row = 24, column = 0, sticky = "e")

  tkgrid(tk2label(gpagenCtlFrame, text = "Radius factor (x spacing)"), row = 25, column = 0, sticky = "w", padx = 20)
  e$bpFactor <- tclVar("2")
  tkgrid(tk2spinbox(gpagenCtlFrame, from = 0.5, to = 10, increment = .1, tip = "Ball-pivot radius = factor x median point spacing. Up for holes, down if faces fuse.", textvariable = e$bpFactor, width = 6), row = 25, column = 0, sticky = "e")

  e$meshWire <- tclVar("0")
  tkgrid(tk2checkbutton(gpagenCtlFrame, text = "Wireframe (off = surface)", variable = e$meshWire), row = 26, column = 0, sticky = "w")
  meanBtn <- ttkbutton(gpagenCtlFrame, text = "Plot Mean Shape", command = function() plotMeanShape(e))
  tkgrid(meanBtn, row = 27, column = 0, pady = 2)

  return(outer)
}

#configures user button actions
bind.geomorph <-function(e) {
  tkbind(e$canvasFrame, "<ButtonPress-1>", function(x, y) {
    if(length(e$activeDataList) > 0) {
      e$dragX <- as.integer(x)
      e$dragY <- as.integer(y)
    }
  })

  tkbind(e$canvasFrame, "<ButtonRelease-1>", function(x, y) {
    if(length(e$activeDataList) > 0) {
      e$dragX <- as.integer(-1)
      e$dragY <- as.integer(-1)
    }
  })

  #tkbind(e$canvasFrame, "<Motion>", function(x, y) {motion.surface(e, x, y)})

  tkbind(e$canvasFrame, "<ButtonPress-3>", function(x, y) { })
  tkbind(e$canvasFrame, "<Double-Button-1>", function(x, y) {    })
}

updateWidgets.geomorph <- function(e) {

}

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
  from_c <- getLandmark(i)
  if (!is.null(from_c) && nrow(from_c) == expected) {
    return(from_c)
  }
  stored <- e$activeDataList[[i]][[10]]
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
    tkmessageBox(
      title = "Information",
      message = "Run Compute first",
      icon = "info",
      type = "ok"
    )
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
      tkmessageBox(title = "Information", message = paste("Incorrect num of landmark for specimen", i), icon = "info", type = "ok")
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
          tkmessageBox(title = "Information", message = paste("Incorrect num of anchor for specimen", i), icon = "info", type = "ok")
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
    tkmessageBox(title = "Information", message = "No specimens to export.", icon = "info", type = "ok"); return(invisible())
  }
  gd <- .build_geomorph_data(e)
  if (is.null(gd)) return(invisible())
  n  <- dim(gd$land)[3]
  nm <- tryCatch(names(e$activeDataList), error = function(err) NULL)
  if (is.null(nm) || length(nm) != n || any(!nzchar(nm))) nm <- paste0("specimen_", seq_len(n))
  dimnames(gd$land) <- list(NULL, c("x", "y", "z"), nm)
  gmData <- list(land = gd$land, curves = gd$curves, surfaces = gd$surfaces, specimen.names = nm)

  ## ask for the file first, so the workspace object can take the file's name
  fileName <- tclvalue(tkgetSaveFile(filetypes = "{{geomorph RDS} {.rds}}",
                                     title = "Save .rds (Cancel = keep in workspace as gmData)"))
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
  filename <- tclvalue(tkgetSaveFile())
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
    tkmessageBox(title = "PCA", message = "PCA needs at least 2 specimens.", icon = "info", type = "ok")
    return()
  }

  pca <- tryCatch(geomorph::gm.prcomp(aligned), error = function(err) err)
  if (inherits(pca, "error")) {
    tkmessageBox(title = "PCA",
      message = paste0("The ordination could not be computed.\n\ngm.prcomp reported: ",
                       conditionMessage(pca)),
      icon = "error", type = "ok")
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
    tkmessageBox(title = "PCA",
      message = "The ordination returned no component scores, so there is nothing to plot.",
      icon = "info", type = "ok")
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

plotMeanShape <- function(e) {
  gm.res <- .gm_results_or_warn(e)
  if (is.null(gm.res)) return()
  if (!requireNamespace("Rvcg", quietly = TRUE)) {
    tkmessageBox(title = "Mean shape",
      message = "Needs Rvcg. Run install.packages(\"Rvcg\").",
      icon = "error", type = "ok"); return()
  }
  M <- as.matrix(gm.res$consensus)
  factor <- suppressWarnings(as.numeric(tclvalue(e$bpFactor)))
  if (is.na(factor) || factor <= 0) factor <- 2
  spacing <- stats::median(Rvcg::vcgKDtree(M, M, k = 2)$distance[, 2])
  r <- factor * spacing
  cat(sprintf("Mean-shape mesh: spacing %.4f, factor %.2f, radius %.4f\n", spacing, factor, r))
  mesh <- try(Rvcg::vcgBallPivoting(M, radius = r, clustering = 0.2, angle = pi / 2), silent = TRUE)
  if (inherits(mesh, "try-error") || is.null(mesh$it) || ncol(mesh$it) == 0) {
    tkmessageBox(title = "Mean shape",
      message = sprintf("No faces at radius %.4f. Raise the factor for holes, lower it if faces fuse.", r),
      icon = "warning", type = "ok")
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
