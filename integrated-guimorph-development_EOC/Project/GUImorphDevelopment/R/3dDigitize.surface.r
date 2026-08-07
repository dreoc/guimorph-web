
# Version derives from DESCRIPTION; no manual update needed
get_surface_date <- function()
{
  .module_banner("surface")
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
#dgtDataList[imgId][[8]]: surface data

#initializes parameter for surface component
init.surface <- function(e)
{
	#print("surfaceInit")
	e$dragX <- as.integer(-1)
	e$dragY <- as.integer(-1)
	e$sliderNum <- 1000
	e$surOnlyMode <- FALSE
	e$templOrig <- "NULL"
	e$aDimR <- 0
	e$aDimC <- 0
}



#draw other widgets
ui.surface <- function(e, parent)
  {
	#print("ui.surface ")
	surCtlFrame <- ttkframe(parent)
	e$bt1 <- NULL

	fitBtn <- ttkbutton(surCtlFrame, text = "Fit",command = function() onFit(e))
	tkpack(ttklabel(surCtlFrame, text = " "), pady = 6)
	tkpack(fitBtn)

	setSliderNumBtn <- ttkbutton(surCtlFrame, text = "Set number of surface sliders", command = function() setSurSliderNum(e))
	tkpack(setSliderNumBtn)

	e$useAnchorVar <- tclVar("0")
	useAnchor <- ttkcheckbutton(surCtlFrame, text = "Use Anchors for Downsampling", variable = e$useAnchorVar, command = function(){})
	assign("bt1", useAnchor, envir = e)
	tkpack(useAnchor)

	entryFrame1 <- ttkframe(surCtlFrame)
	tmplLabel = tklabel(entryFrame1, text='Current Template: ')
	e$tmplVar <- tclVar("NA")
	e$tmplEntry = tkentry(entryFrame1, textvariable=e$tmplVar, state="readonly", width=35)
	sapply(list(tmplLabel, e$tmplEntry), tkpack, pady = 3)

  buldTemBtn <- ttkbutton(surCtlFrame, text = "Build Template",command = function() buildTemplate(e))
	e$buldTemBtn <- buldTemBtn

	tkpack(ttklabel(surCtlFrame, text = " "), pady = 5)
	sapply(list(entryFrame1, buldTemBtn), tkpack, pady = 3)

	entryFrame2 <- ttkframe(surCtlFrame)
	downsmplLabel = tklabel(entryFrame2, text='Current downsample: ')
	e$downsmplVar <- tclVar("NA")
	e$downsmplEntry = tkentry(entryFrame2, textvariable=e$downsmplVar, state="readonly", width=35)
	sapply(list(downsmplLabel, e$downsmplEntry), tkpack, pady = 3)

	e$downSampleBtn <- ttkbutton(surCtlFrame, text = "Downsample specimen",command = function() downSample(e))

	tkpack(ttklabel(surCtlFrame, text = " "), pady = 5)
	sapply(list(entryFrame2, e$downSampleBtn), tkpack, pady = 3)

	e$switchBtn <- ttkbutton(surCtlFrame, text = "Toggle specimen",command = function() hidePly(e))
	tkpack(ttklabel(surCtlFrame, text = " "), pady = 5)
	tkpack(e$switchBtn)

	return (surCtlFrame)
}


#configures button press for surface component
bind.surface <-function(e)
  {
  tkbind(e$canvasFrame, "<MouseWheel>", function(D) {
    zoom(e, normalizeWheelDelta(D))
  })

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
	tkbind(e$canvasFrame, "<Double-Button-1>", function(x, y) {	})
}




#User interface layout dynamic update callback
updateWidgets.surface <- function(e)
  {
	#print("updateWidgets.surface")

	e$tmplVar <- tclVar(paste("Based on ", e$templOrig))
	tkconfigure(e$tmplEntry , textvariable=e$tmplVar)

	if (length(e$activeDataList) == 0) {
		e$downsmplVar <- tclVar("NA")
		tkconfigure(e$downsmplEntry , textvariable=e$downsmplVar)
		return()
	}

	templ <- e$activeDataList[[e$currImgId]][[5]]
	if(length(templ) == 0) {
		e$downsmplVar <- tclVar("NA")
	}else {
		e$downsmplVar <- tclVar(paste("based on ",  templ))
	}
	tkconfigure(e$downsmplEntry , textvariable=e$downsmplVar)
}




#hides or shows specimen on canvas
hidePly <- function(e)
  {
	#print("hidePly")
	if(e$surOnlyMode) {
		set("window", "mode", "surface")
		e$surOnlyMode <- FALSE
	}
  else
	{
		set("window", "mode", "surfaceonly")
		e$surOnlyMode <- TRUE
	}
}



#Pop up window to configure number of surface sliders
setSurSliderNum <- function(e)
  {
	win <- tktoplevel()
	tkwm.title(win, "Set Number of Surface Sliders")

	entryFrame <- ttkframe(win)
	tkpack(entryFrame, expand = TRUE, fill = "both", padx = 5, pady = 5)
	label = tklabel(entryFrame, text='Set Number of Surface Sliders: ')

  e$sliderEntry = tkentry(entryFrame, textvariable=tclVar(e$sliderNum))
	sapply(list(label, e$sliderEntry), tkpack, side = "left", padx = 6)

	btnFrame <- ttkframe(win)
	tkpack(btnFrame, fill = "x", padx = 5, pady = 5)
	cancelBtn <- ttkbutton(btnFrame, text = "cancel", command = function() tkdestroy(win))
	okBtn <- ttkbutton(btnFrame, text = "ok",command = function() onSliderNumOk(e, win))

	tkpack(ttklabel(btnFrame, text = " "), expand = TRUE, fill = "y", side = "left")
	sapply(list(cancelBtn, okBtn), tkpack, side = "left", padx = 6)

	tkfocus(win)
}



#Initiates to set the number of surface sliders
onSliderNumOk <- function(e, win)
{
  e$sliderNum <- tclvalue(tkget(e$sliderEntry))
	tkdestroy(win)
  dbg(paste("3dDigitize.surface (178)... set surface sliders to : <", e$sliderNum, ">" ))
}



#Enables or disables button for build template and down sample
disableOper<-function(e, state) {
	if (state) {
		tkconfigure(e$buldTemBtn, state="disabled")
		tkconfigure(e$downSampleBtn, state="disabled")
	} else {
		tkconfigure(e$buldTemBtn, state="enabled")
		tkconfigure(e$downSampleBtn, state="enabled")
	}
}



#builds template according to current specimen
buildTemplate <- function(e)
{
  dbg("3dDigitize.surface ... build template .. line 199")
	disableOper(e, T)

	dbg(paste("current image id ... line 202 ", e$currImgId))

	lmk <- getLandmark(e$currImgId)

	dbg(paste("landmarks for image id : ", e$currImgId))

	dbg(lmk)
	if(is.null(lmk))
	{
	  dbg("No landmarks. Downsampling is not allowed.")
    disableOper(e, F)
    if (!is.null(e$statusLabel)) {
      setStatus(e, "Build template requires landmarks on the specimen.", "warning")
    }
	  return ()
	}


	#check anchor toggle and if anchors are present
	anc <- getAnchor(e$currImgId)
	dbg(paste("current image id line 218 : ", e$currImgId))
	dbg("anchors")
	dbg(anc)
	if(is.null(anc))
	{
	    dbg("No anchors. Cannot use in downsampling process.")
	    if(tclvalue(e$useAnchorVar) == "1") {
        disableOper(e, F)
        if (!is.null(e$statusLabel)) {
          setStatus(e, "Build template requested anchors, but no anchors are defined.", "warning")
        }
	        return()
      }
	}
  if (!is.null(anc)) {
	  e$aDimR <- dim(anc)[1]
	  e$aDimC <- dim(anc)[2]
  } else {
    e$aDimR <- 0
    e$aDimC <- 0
  }

	fileName <- e$activeDataList[[e$currImgId]][[1]]
  dbg(paste("Build template (233) ... file name is <", fileName, ">"))



	#### 12.14.2017 changed read ply function from geomorph's read.ply to Rvcg's vcgPlyRead
	# much faster
	spec <- Rvcg::vcgPlyRead(fileName, updateNormals = TRUE, clean = FALSE)
	#spec <- read.ply(fileName, ShowSpecimen = FALSE)

	#surface.sliders<-1000
	specimen <- as.matrix(t(spec$vb)[, -4])

	if(0)
	{
	dbg("line 247 this is specimen")
	dbg(specimen)
	}


	dbg("e$useAnchorVar")
	dbg(e$useAnchorVar)




	#### 12.14.2017 changed kmeans from base kmeans to Morpho::fastKmeans
	#### 2026-07-23 replaced with .template_kmeans_centers (seeded, Rvcg-only, no rgl)
	# much faster


	#if no anchors
	if (tclvalue(e$useAnchorVar) == "0")
	{
	  template <-
	  rbind(
	    lmk,
	    .template_kmeans_centers(
	      x = specimen,
	      k = as.numeric(e$sliderNum),
	      iter.max = 100,
	      project = TRUE
	    )
	  )
	}


	if (tclvalue(e$useAnchorVar) == "1")
	{
	  lmkAnc <- rbind(lmk, anc)
	  template <-
	    rbind(
	      lmkAnc,
	      .template_kmeans_centers(
	        x = specimen,
	        k = as.numeric(e$sliderNum),
	        iter.max = 100,
	        project = TRUE
	      )
	    )
	}


	dbg("ready to write template ... where does it go ?")
	# template <- rbind(lmk,kmeans(x=specimen,centers=e$sliderNum,iter.max=100)$centers)
	write.table(template,file="template.txt",row.names=F,col.names=TRUE)
	e$templatePoints <- template
	disableOper(e, F)

	e$tmplVar <- tclVar(paste("Based on ", basename(fileName)))
	tkconfigure(e$tmplEntry , textvariable=e$tmplVar)

	e$templOrig <- basename(fileName)
	tkmessageBox(title = "Information", message = "Template created", icon = "info", type = "ok")

	dbg("line 305 of surface build template end")
}




#
buildTemplate1 <- function(e)
  {
	#print("buildTemplate")
	fileName <- e$activeDataList[[e$currImgId]][[1]]

	#### 12.14.2017 changed read ply function from geomorph's read.ply to Rvcg's vcgPlyRead
	# much faster
	spec <- Rvcg::vcgPlyRead(fileName, updateNormals = TRUE, clean = FALSE)
	#spec <- read.ply(fileName, ShowSpecimen = FALSE)


	spec.name<-deparse(substitute(spec))
	mesh <- NULL


	if (inherits(spec, "shape3d") == TRUE || inherits(spec, "mesh3d") == TRUE)
	{
		specimen <- scale(as.matrix(t(spec$vb)[,-4]), scale = FALSE)
		spec$vb <- rbind(t(specimen), 1)
		mesh <- spec
		if (is.null(mesh$material)) { mesh$material <- "gray" }
	}
	else if (inherits(spec, "matrix") == FALSE)
	{
		stop ("File is not a shape3d/mesh3d object or xyz matrix")
	}
	else if (inherits(spec, "matrix") == TRUE && dim(spec)[2]==3)
	{
		specimen <- scale(spec, scale = FALSE)
	}
	else
	{
	  stop ("File is not matrix in form: vertices by xyz")
	}


	lmkStr <- tclvalue(shows("specimen", "landmark"))
	lmkV <- strsplit(lmkStr, " ")[[1]]

	rows <- length(lmkV)/3
	lmk = matrix( as.numeric(lmkV), nrow = rows, ncol = 3, byrow = TRUE)
	#sliders <- 1000

	template <- rbind(lmk,.template_kmeans_centers(x=specimen,k=as.numeric(e$sliderNum),iter.max=100,project=TRUE))
	#template <- rbind(lmk,kmeans(x=specimen,centers=e$sliderNum,iter.max=100)$centers)
	write.table(template,file="template.txt",row.names=F,col.names=TRUE)

	e$templOrig <- basename(fileName)
	e$tmplVar <- tclVar(paste("Based on ", e$templOrig))
	tkconfigure(e$tmplEntry , textvariable=e$tmplVar)
}




#write sample data to file
write.nts <- function(vertexNum, fileName, vertex)
{
	file.create(fileName, showWarnings=TRUE)
	write(paste("Surface=", vertexNum, sep=""), file = fileName)
	write.table(vertex, file=fileName, row.names=F, col.names=F, append = TRUE)
}

#Performs downsample for the current specimen
downSample <- function(e)
  {

  dbg("3dDigitze.surface ... downsample ... line 371")
	disableOper(e, T)
  lmk <- getLandmark(e$currImgId)
  dbg("Landmarks (lmk) ")
  dbg(lmk);

  if(is.null(lmk))
  {
    dbg("No landmarks. Downsampling is not allowed.")
    disableOper(e, F)
    if (!is.null(e$statusLabel)) {
      setStatus(e, "Downsample requires landmarks on the specimen.", "warning")
    }
    return ()
  }




  anc <- getAnchor(e$currImgId)

	fixed <- as.integer(dim(lmk)[1])
	aFixed <- as.integer(dim(anc)[1])
	center <- FALSE
	fileName <- e$activeDataList[[e$currImgId]][[1]]

	# This operation could be delegated to the C code to run really fast

	dbg("fileName is")
	dbg(fileName)


	#### 12.14.2017 changed read ply function from geomorph's read.ply to Rvcg's vcgPlyRead
	# much faster
	spec <- Rvcg::vcgPlyRead(fileName, updateNormals = TRUE, clean = FALSE)
	#spec <- read.ply(fileName, ShowSpecimen = FALSE)


	# ?? design issue ... functions should NEVER terminate execution ... is this what happens here ??

	if(length(fixed)==1 && fixed<4) {stop ("Number of fixed points is not sufficient.")}
	#if(length(aFixed)==1 && aFixed<4){stop ("Number of anchors is not sufficient.")}



	spec.name<-deparse(substitute(spec))
  mesh <- NULL
  if (inherits(spec, "shape3d") == TRUE || inherits(spec, "mesh3d") == TRUE)
  {

    if (center == TRUE)
    {
      specimen <- scale(t(spec$vb)[,-4], scale = FALSE)
      spec$vb <- rbind(t(specimen), 1)
    }

    if (center == FALSE)
    {
      specimen <- as.matrix(t(spec$vb)[,-4])
    }
    mesh <- spec
    if (is.null(mesh$material)) { mesh$material <- "gray" }

  }
  else if (inherits(spec, "matrix") == FALSE)
  {
    stop ("File is not a shape3d/mesh3d object or xyz matrix")
  }
  else if (inherits(spec, "matrix") == TRUE && dim(spec)[2]==3)
  {
    if (center == TRUE)    { specimen <- scale(spec, scale = FALSE) }
    if (center == FALSE)   { specimen <- spec }
  }
  else
  {
    stop ("File is not matrix in form: vertices by xyz")
  }




  dbg(paste("surface line 447 ... use anchor ?  ... is NUll ? <", e$useAnchorVar, "> ...<", is.null(anc),  ">"))
  dbg(anc)
  dbg(paste("tclvalue(e$useAnchorVar) ", tclvalue(e$useAnchorVar) ))
  dbg("")
  if(tclvalue(e$useAnchorVar) == 1 && is.null(anc))
  {
      dbg("No anchors placed, cannot use in downsampling process")
      disableOper(e, F)
      if (!is.null(e$statusLabel)) {
        setStatus(e, "Downsample requested anchors, but no anchors are defined.", "warning")
      }
      return()
  }
  else if(tclvalue(e$useAnchorVar) == 1)
  {
      dbg("have landmarks ... this is surface line 459")
      lmk <- rbind(lmk,anc)
      fixed <- fixed + aFixed
  }


  template <- getTemplate(e)
  if (is.null(template)) {
    tkmessageBox(title = "No template",
      message = "No template found. Build a template first, or open a .dgt that carries one.",
      icon = "info", type = "ok"); return()
  }
  #specimen<-center(as.matrix(specimen))
  specimen <- as.matrix(specimen)

  #warping process
  template<-template*(cSize(lmk)/cSize(template[(1:fixed),]))
  template<-template%*%rotate.mat(lmk,template[(1:fixed),]) ###
  cat("\nWarping template\n")
  template.tps<-tps2d3d(template[-(1:fixed),],template[(1:fixed),],lmk)
  spec.surfs<-specimen
  nei<-numeric(dim(template.tps)[1])
  sliders<-matrix(NA,nrow=dim(template.tps)[1],ncol=3)

  dbg("this is line 478")

  #now apply warping to semilandmarks
  for (i in 1:dim(template.tps)[1])
  {
      nei[i]<-which.min(sqrt((template.tps[i,1]-spec.surfs[,1])^2+(template.tps[i,2]-spec.surfs[,2])^2+(template.tps[i,3]-spec.surfs[,3])^2))[1] #3D NN
      sliders[i,]<-spec.surfs[nei[i],]
      spec.surfs<-spec.surfs[-nei[i],]
  }
  dbg("this is line 487")
  selected.out <- rbind(lmk,sliders)

  # why are we saving data to a file and then deleting it ?
  # the data is passed to the C code via the data 'vertToDownsample' ....
  # Actually I think it would be better to have the C code read the file
  # Dave 10 July 2020
  #

  ntsFile <- paste(fileName, ".nts", sep="")
  write.nts(as.numeric(e$sliderNum), ntsFile, selected.out)
  dbg("write to file")
  #write.table(selected.out, file=ntsFile, row.names=F, col.names=F, append = TRUE)

  dbg(paste ("add down sample ... id is ", e$currImgId))

  vertToDownsample <- as.vector(t(selected.out))
  ##print (vertToDownsample)




  add("downsample", vertToDownsample, e$currImgId)
  file.remove(ntsFile)
  disableOper(e, F)

  e$activeDataList[[e$currImgId]][[5]] <- e$templOrig
  e$activeDataList[[e$currImgId]][[8]] <- sliders


  tkmessageBox(title = "Information", message = "Specimen is downsampled", icon = "info", type = "ok")

  dbg(paste("e$templOrig is ", e$templOrig))
  e$downsmplVar <- tclVar(paste("based on ",  e$templOrig))
  tkconfigure(e$downsmplEntry , textvariable=e$downsmplVar)
}


#' Headless surface-semilandmark builder for the browser /downsample route
#'
#' The browser does not compute geometry -- it only triggers this over the
#' 05-02 \code{/downsample} loopback route (\code{.gmw_digitize_handler}
#' forward-calls \code{.gmw_downsample_session(token)}). This runs the SAME TPS
#' template warp + nearest-neighbour pass that \code{downSample} (above) uses,
#' but headlessly: no Tk status bar, no message boxes, and -- critically -- no
#' \code{add("downsample", ...)} into the native \code{tkogl2} C engine (that
#' re-couples acquisition to the engine Phase 6 removes). Landmarks, anchors,
#' template and the specimen point cloud are read from the server-owned session
#' record (\code{.gmw_session[[token]]}), never from \code{activeDataList} /
#' \code{getLandmark}. The resulting s x 3 \code{sliders} array is stored in the
#' record's \code{surfaces} slot, and the browser display cloud is returned as
#' the row-major flatten via \code{.gmw_flat} -- which applies the mandatory
#' \code{as.vector(t(.))} transpose (PROJECT lessons; pinned by
#' \code{test-surface-flatten.R}). The numerical pipeline and its \code{gm_utils}
#' calls (\code{csize}/\code{rotate.mat}/\code{tps2d3d}) are unchanged from
#' \code{downSample}; only \code{PB = FALSE} drops the interactive progress bar.
#'
#' @param token the per-viewport session token whose current specimen to warp.
#' @return the row-major \code{.gmw_flat} surface cloud string, invisibly stored
#'   as \code{surfaces} in the session record for the current specimen.
#' @keywords internal
#' @noRd
.gmw_downsample_session <- function(token) {
  s <- .gmw_session_get(token)
  if (is.null(s)) {
    stop("gmw downsample: no digitizing session for this token.", call. = FALSE)
  }
  cur <- s$current
  rec <- s$specimens[[cur]]

  lmk      <- rec$land
  anc      <- rec$anchor
  template <- rec$template
  specimen <- rec$specimen

  # Same preconditions downSample() enforces, minus the Tk status-bar path.
  if (is.null(lmk) || nrow(lmk) < 4L) {
    stop("gmw downsample: the current specimen needs at least 4 landmarks.",
         call. = FALSE)
  }
  if (is.null(template)) {
    stop("gmw downsample: no template in the session record; build one first.",
         call. = FALSE)
  }
  if (is.null(specimen) || !is.matrix(specimen) || ncol(specimen) != 3L) {
    stop("gmw downsample: the current specimen point cloud is missing from the session.",
         call. = FALSE)
  }

  lmk      <- as.matrix(lmk)
  template <- as.matrix(template)
  specimen <- as.matrix(specimen)

  # Anchors are forced into the fixed set exactly as downSample()'s use-anchor
  # branch does (they guarantee topographically significant features).
  fixed <- as.integer(nrow(lmk))
  if (!is.null(anc) && nrow(anc) > 0L) {
    lmk   <- rbind(lmk, as.matrix(anc))
    fixed <- as.integer(nrow(lmk))
  }

  dbg("gmw downsample: warping template (headless)")

  # ---- TPS warp pipeline, verbatim from downSample() (3dDigitize.surface.r) --
  template <- template * (csize(lmk) / csize(template[(1:fixed), , drop = FALSE]))
  template <- template %*% rotate.mat(lmk, template[(1:fixed), , drop = FALSE])
  template.tps <- tps2d3d(template[-(1:fixed), , drop = FALSE],
                          template[(1:fixed), , drop = FALSE], lmk, PB = FALSE)

  spec.surfs <- specimen
  n <- nrow(template.tps)
  sliders <- matrix(NA_real_, nrow = n, ncol = 3L)
  # Nearest-neighbour of each warped semilandmark onto the specimen, removing
  # the matched vertex each pass so no specimen point is claimed twice.
  for (i in seq_len(n)) {
    nn <- which.min(sqrt((template.tps[i, 1] - spec.surfs[, 1])^2 +
                         (template.tps[i, 2] - spec.surfs[, 2])^2 +
                         (template.tps[i, 3] - spec.surfs[, 3])^2))[1]
    sliders[i, ] <- spec.surfs[nn, ]
    spec.surfs   <- spec.surfs[-nn, , drop = FALSE]
  }
  # --------------------------------------------------------------------------

  # R owns the result: store the s x 3 array in the session record. No
  # activeDataList / Tk / C add() mutation from the browser path.
  s$specimens[[cur]]$surfaces <- sliders
  assign(token, s, envir = .gmw_session)

  # Row-major cloud for the browser (the transpose is mandatory).
  .gmw_flat(sliders)
}





#loads surface data from .dgt file
read.surface <- function(content)
{

  dbg("")
  dbg("")
  dbg("")
  dbg("file 3dDigitize.surface ... function read.surface")
  ignore.case = TRUE

  tmpt <- NULL
  tmpt <-   sub("Template=", "", content[grep("Template=", content, ignore.case)], ignore.case)

  nsurf <- NULL
  nsurf <- sub("Surface=", "", content[grep("Surface=", content, ignore.case)], ignore.case)

  dbg(paste("tmpt  :", tmpt))
  dbg(paste("nsurf :", nsurf))
  dbg(paste("length of nsurf", length(nsurf)))


  for (ii in 1:length(tmpt))
  {
    dbg(paste("Template", ii, tmpt[ii]))
  }


  for (ii in 1:length(nsurf))
  {
    dbg(paste("surf number", ii, nsurf[ii]))
  }



  if (0 == length(nsurf))
  {
    dbg("read.surface : length of nsurf is zero - returning NULL")
    return (NULL)
  }




  # content seems to be the entire file contents
  # print (content)
  surfaces <- read.vertex.3D(content, "Surface=")

  if(0)
  {
    dbg(paste("read.surface ... Surfaces from read.vertex"))
    dbg( surfaces)
  }

  # Surface=0 yields 0-row array; all(is.na()) is vacuously TRUE on empty - not missing data
  if (!is.null(surfaces) && length(surfaces) > 0 && nrow(surfaces) > 0 &&
      all(is.na(surfaces)))
  {
    dbg("read.surface : ALL surfaces NA returning NULL")
    return(NULL)
  }
  else
  {
    dbg("read.surface : have the data ... returning a list")
    dbg("")
    dbg("")
    return(list( template = tmpt, surfaces = surfaces,   sliderNum = nsurf  ))
  }
  return(NULL)
}






#writes surface data to .dgt file
write.surface <- function(fileName, tempt, surface)
{
  dbg("write.surface")
  #write template
  if (!is.null(tempt))
  {
    temptLine <- paste("Template=", tempt, sep = "")
    write(temptLine, fileName, append = TRUE)
  }

  dbg(paste("Length of surface data is", length(surface)))

 # if(length(surface <= 2))
 #  {
 #   print("Caught invalid surface data length")
 #   write("Surface=0", fileName, append = TRUE)
 # }




  #write downsample data
  if (length(surface) >= 2)
  {
    write.vertex.3D(surface, "Surface=", fileName)
  }
  else
  {
    #write("Surface=NULL", fileName, append = TRUE)
    write("Surface=0", fileName, append = TRUE)
  }
}




#writes template data to .dgt file
write.template <- function(fileName, templOrig)
{
  dbg("write.template")
  temptLine <- "TemplateNumber=NULL"
  if (file.exists("template.txt"))
  {
    tgtfile <-
      scan(
        file = "template.txt",
        what = "char",
        sep = "\n",
        quiet = TRUE
      )
    temptLine <- paste("TemplateNumber=", length(tgtfile), sep = "")
    write(temptLine, fileName, append = TRUE)
    write(templOrig, fileName, append = TRUE)
    write(tgtfile, fileName, append = TRUE)
  }
  else
  {
    write(temptLine, fileName, append = TRUE)
  }
  write("", fileName, append = TRUE)
}





#reads template data from .dgt file
# template points: memory first, then template.txt, then NULL
getTemplate <- function(e) {
  if (!is.null(e$templatePoints)) return(e$templatePoints)
  if (file.exists("template.txt"))
    return(as.matrix(read.table("template.txt", header = TRUE)))
  NULL
}

read.template <- function(rawContent)
{
  ##print("read.template")
  ##print(rawContent[3])
  ignore.case = TRUE

  startLines <- grep("TemplateNumber=", rawContent, ignore.case)
  if (length(startLines) == 0)
  {
    dbg("read.template : can not locate template tag 'TemplateNumber=' ")
    return(NULL)
  }


  len <-
    sub("TemplateNumber=", "", rawContent[grep("TemplateNumber=", rawContent, ignore.case)], ignore.case)
  basedLine <- as.numeric(startLines[1]) + 1
  dataStart <- as.numeric(startLines[1]) + 2

  if (len[1] != "NULL")
  {
    ##print("not null")
    fileName <- "template.txt"
    file.create(fileName, showWarnings = TRUE)
    endLine <- basedLine + as.numeric(len[1])
    content <- rawContent[dataStart:endLine]
    ##print(  paste( "startline:",  startLines[1],  "basedLine: ",  basedLine,
    ##    "dataStart: ",  dataStart,  "endline: ",     endLine   )     )
    write(content, fileName, append = TRUE)
    ##print("based")
    ##print(rawContent[basedLine])
    return (rawContent[basedLine])
  }
  return (NULL)
}



#shows sample data on canvas
draw.surface <- function(id, surface)
  {
	dbg(paste("Add surface for  specimen", id, "... ..."))
	dbg(surface)
	add("downsample", surface, id)

}
