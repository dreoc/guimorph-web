# Developers to update this function
get_main_date <- function()
{
  print ("Main 15 August 2020")
  print ("Expected library compile information is 14 August 2020  07:59 PM")
}


#' @name GUImorph-package
#' @docType package
#' @aliases GUImorph
#' @title Graphical User Interface for Morphometrics
#' @author Erik Otarola-Castillo
#'
#' @description GUI to R programs to digitize in 3D, conduct geometric morphomteric analyses and plotting results based on OpenGL and Tk widget

#' @import parallel
NULL

#' @import geomorph
NULL

#' @import Rvcg
NULL

#' @import Morpho
NULL

#' @import tcltk
NULL

#' @import tcltk2
NULL

#' @import vegan
NULL

# Active ttk theme (clam is themeable on Windows; vista/xpnative/winnative also valid)
GUIMORPH_THEME <- "clam"

# White panel styles for the center workspace (header, canvas surround, nav bar).
configureGuimorphCenterStyles <- function() {
  bg <- "white"
  tcl("ttk::style", "configure", "Center.TFrame", background = bg, borderwidth = 0)
  tcl("ttk::style", "configure", "Center.TLabel", background = bg)
}

# Developer/diagnostic UI is hidden by default. Opt in with
#   options(guimorph.dev = TRUE)  -or-  set env GUIMORPH_DEV=1
.guimorph_dev_mode <- function() {
  isTRUE(getOption("guimorph.dev", FALSE)) || nzchar(Sys.getenv("GUIMORPH_DEV"))
}

.center_toplevel <- function(wnd) {
  tryCatch({
    tcl("update", "idletasks")
    sw <- as.integer(tkwinfo("screenwidth", wnd))
    sh <- as.integer(tkwinfo("screenheight", wnd))
    ww <- as.integer(tkwinfo("reqwidth", wnd))
    wh <- as.integer(tkwinfo("reqheight", wnd))
    # Cap the window to the visible screen so bottom-docked widgets (the status
    # bar) are never pushed below the screen edge. Setting an explicit WxH also
    # keeps the window from opening at the oversized 1400x1200 request.
    maxw <- as.integer(sw * 0.95)
    maxh <- as.integer(sh * 0.90)
    if (is.na(ww) || ww < 900) ww <- 900L
    if (is.na(wh) || wh < 720) wh <- 720L
    if (ww > maxw) ww <- maxw
    if (wh > maxh) wh <- maxh
    x <- max(0L, (sw - ww) %/% 2L)
    y <- max(0L, (sh - wh) %/% 2L)
    tkwm.geometry(wnd, paste0(ww, "x", wh, "+", x, "+", y))
  }, error = function(err) {
    message("GUImorph: window centering skipped: ", conditionMessage(err))
  })
}

ui <- function(e) {
  UseMethod("ui", e)
}

init <- function(e) {
  UseMethod("init", e)
}

bind <- function(e) {
  UseMethod("bind", e)
}

updateWidgets <- function(e) {
  UseMethod("updateWidgets", e)
}

##gpagen
################# main data structure ##############################
#dgtDataList
#dgtDataList[imgId][[1]]: speciman dir
#dgtDataList[imgId][[2]]: font
#dgtDataList[imgId][[3]]: number of landmark

#dgtDataList[1][[4]]: curves           ## 18 July should this be expanded to have an image index as well

#dgtDataList[imgId][[5]]: template
#dgtDataList[imgId][[6]]: rotation
#dgtDataList[imgId][[7]]: zoom
#dgtDataList[imgId][[8]]: surface file


#loads vertexs from .dgt file
read.vertex.3D <- function(content, key)
{
  x <- 0 #x dimension for building array
  startLines <- grep(key, content, TRUE)

  # startlines are the line numbers containing the text "Surface="
  print ("read.vertex.3D ... line numbers containing 'Surface=' " )
  print (startLines)

  numbers <- sub(key, "", content[startLines], TRUE)


  print("These are the number of surface elements per specimen")
  for (ii in 1:length(numbers))
  {
    print (paste ("Numbers", ii,  numbers[ii] ) )
  }


  # THIS MAY NEED TO BE CHANGED INTO A MAXIMUM COMPUTATION
  for (i in 1:length(numbers))
  {
    if (numbers[i] != "")
    {
      x <- numbers[i]
      #break
    }
  }


  print (paste ("x = ", x))

  # so vetrexs will be ... say [100 by 3 by nSpecimens]

  ## vertexs <-   array(NA, dim = c(as.numeric(x), 3, length(startLines)))
  vertexs <-   array(0, dim = c(as.numeric(x), 3, length(startLines)))
  for (i in 1:length(startLines))
  {
    startNum <- as.numeric(startLines[i])
    endNum <- startNum + as.numeric(numbers[i])
    print(paste ("startNum :", startNum))
    print(paste ("endNum   :", endNum))


    # this test is probably not robust
    if (is.na(endNum) || is.na(startNum))
    {
      print("NA surface data, skipping")
      next
    }

    if (startNum == endNum)
    {
      # then there really is no surface data for this specimen
      # so fill with zeros - that is leave it full of zeros
    }
    else
    {

      tmp <- content[(startNum + 1):endNum]
      ###print (paste ("NON NA ... tmp", tmp))
      vertexs[, , i] <-   matrix(as.numeric(unlist(strsplit(tmp, " "))), ncol = 3, byrow = TRUE)
    }

  }


  if (is.null(vertexs))
  {
    print ("HOW DID THIS HAPPEN ? vertexs is NULL !! ")
  }

  print("read.vertex.3D ... complete")
  print("")
  print("")
  return(vertexs)
}



#writes vertexs to file
write.vertex.3D <- function(content, key, fileName)
{
  leadLine <- paste(key, dim(content)[1], sep = "")
  write(leadLine, fileName, append = TRUE)

  write.table(
    content,
    fileName,
    col.names = FALSE,
    row.names = FALSE,
    sep = " ",
    append = TRUE
  )
}

.STATUS_FG <- c(
  neutral = "#000000",
  info    = "#1a5fb4",
  success = "#2e7d32",
  warning = "#b35900",
  error   = "#c01c28"
)

setStatus <- function(e, text, state = "neutral") {
  tkconfigure(e$statusLabel, text = text,
              foreground = .STATUS_FG[[state]])
}

busyStart <- function(e, text, mode = "indeterminate") {
  setStatus(e, text, "info")
  tkconfigure(e$wnd, cursor = "watch")
  if (mode == "indeterminate") {
    tkconfigure(e$progressBar, mode = "indeterminate")
    tcl(e$progressBar, "start", 20)
  }
  tcl("update", "idletasks")
}

busyStop <- function(e, text = NULL, state = "neutral") {
  tcl(e$progressBar, "stop")
  tkconfigure(e$progressBar, mode = "determinate", value = 0)
  tkconfigure(e$wnd, cursor = "")
  if (!is.null(text)) setStatus(e, text, state)
}

# Single source of truth for Previous/Next availability. Enable/disable is based
# ONLY on whether a neighbouring specimen exists, never on landmark/anchor
# completeness — incomplete counts are surfaced as an inline status warning when
# the user attempts to navigate, so the buttons can never get stuck disabled.
refreshNavButtons <- function(e) {
  if (is.null(e$nextBtn) || is.null(e$prevBtn)) return(invisible())
  n <- length(e$activeDataList)
  if (n == 0) return(invisible())
  tkconfigure(e$prevBtn,
              state = if (e$currImgId > 1) "normal" else "disabled")
  tkconfigure(e$nextBtn,
              state = if (e$currImgId < n) "normal" else "disabled")
  if (!is.null(e$specimenCombo) && length(e$activeDataList) > 0) {
    p <- e$activeDataList[[e$currImgId]][[1]]
    nm <- if (is.null(p) || !nzchar(p)) paste0("specimen ", e$currImgId) else basename(p)
    tclvalue(e$specimenSelectVar) <- paste0(e$currImgId, ": ", nm)
  }
}

populateSpecimenCombo <- function(e) {
  if (is.null(e$specimenCombo)) return(invisible())
  N <- length(e$activeDataList)
  if (N == 0) {
    tkconfigure(e$specimenCombo, values = "", state = "disabled")
    tclvalue(e$specimenSelectVar) <- ""
    return(invisible())
  }
  vals <- vapply(seq_len(N), function(i) {
    p <- e$activeDataList[[i]][[1]]
    nm <- if (is.null(p) || !nzchar(p)) paste0("specimen ", i) else basename(p)
    paste0(i, ": ", nm)
  }, character(1))
  tkconfigure(e$specimenCombo, values = vals, state = "readonly")
  tclvalue(e$specimenSelectVar) <- vals[e$currImgId]
  invisible()
}

jumpToSpecimen <- function(e, id) {
  if (length(e$activeDataList) == 0) return(invisible())
  if (id < 1 || id > length(e$activeDataList) || id == e$currImgId) {
    refreshNavButtons(e); return(invisible())
  }
  if (e$tab != 0) {
    setStatus(e, "Switch to the 3D Digitizing tab to change specimen.", "warning")
    refreshNavButtons(e); return(invisible())
  }
  nCurrLM <- e$activeDataList[[e$currImgId]][[3]]
  if (nCurrLM < as.integer(e$landmarkNum)) {
    setStatus(e,
      paste0("Place all ", e$landmarkNum,
             " landmarks before jumping to another specimen \u2014 ",
             nCurrLM, " of ", e$landmarkNum, " placed."),
      "warning")
    refreshNavButtons(e); return(invisible())
  }
  nCurrA <- e$activeDataList[[e$currImgId]][[9]]
  if (is.null(nCurrA)) nCurrA <- 0
  if (tclvalue(e$placeAnchorsVar) == "1" &&
      nCurrA < as.integer(e$anchorNum)) {
    setStatus(e,
      paste0("Place all ", e$anchorNum,
             " anchors before jumping \u2014 ",
             nCurrA, " of ", e$anchorNum, " placed."),
      "warning")
    refreshNavButtons(e); return(invisible())
  }
  clearUndo(e)
  e$currImgId <- id
  add("specimen", e$activeDataList[[e$currImgId]][[1]], e$currImgId)
  refreshTabGating(e)
  showPicture(e)
  invisible()
}

refreshTabGating <- function(e) {
  if (is.null(e$nb)) return(invisible())
  loaded <- length(e$activeDataList) > 0
  tcl(e$nb, "tab", 1, state = if (loaded) "normal" else "disabled")
  e$tabState[1] <- if (loaded) 1L else 0L
  lmOk <- loaded &&
    as.integer(e$activeDataList[[e$currImgId]][[3]]) == as.integer(e$landmarkNum)
  prev23 <- e$tabState[2:3]
  for (i in c(2L, 3L)) {
    tcl(e$nb, "tab", i, state = if (lmOk) "normal" else "disabled")
    e$tabState[i] <- if (lmOk) 1L else 0L
  }
  tcl(e$nb, "tab", 4, state = if (lmOk) "normal" else "disabled")
  e$tabState[4] <- if (lmOk) 1L else 0L
  if (lmOk && any(prev23 == 0L)) {
    setStatus(e, "Surface Sliders and Curves unlocked.", "success")
  }
  invisible()
}

updateStepLabel <- function(e) {
  if (is.null(e$stepLabel)) return(invisible())
  if (length(e$activeDataList) == 0) {
    txt <- "Load specimens to begin"
  } else {
    nDots <- e$activeDataList[[e$currImgId]][[3]]
    target <- as.integer(e$landmarkNum)
    anchorsOn <- tclvalue(e$placeAnchorsVar) == "1"
    nA <- e$activeDataList[[e$currImgId]][[9]]
    if (is.null(nA)) nA <- 0
    if (nDots < target) {
      txt <- paste0("Step 1 of 3 \u2014 Place ", target, " landmarks")
    } else if (anchorsOn && nA < as.integer(e$anchorNum)) {
      txt <- paste0("Step 2 of 3 \u2014 Place ", e$anchorNum, " anchors")
    } else {
      txt <- "Step 3 of 3 \u2014 GPA unlocked for this specimen"
    }
  }
  tkconfigure(e$stepLabel, text = txt, foreground = "#505050")
  invisible()
}

updateCurveHint <- function(e) {
  if (is.null(e$hintLabel)) return(invisible())
  tkconfigure(
    e$hintLabel,
    text = "Double-click 3 landmarks per curve segment \u00b7 Drag to rotate"
  )
  invisible()
}

updateHintLabel <- function(e, tabId = e$tab) {
  if (is.null(e$hintLabel)) return(invisible())
  tabInt <- suppressWarnings(as.integer(tabId))
  if (length(tabInt) != 1L || is.na(tabInt)) return(invisible())
  if (tabInt == 3L) {
    updateCurveHint(e)
    return(invisible())
  }
  HINT_TEXT <- c(
    "0" = "Double-click to place landmark \u00b7 Drag to rotate \u00b7 Right-click to delete",
    "1" = "Double-click to place anchor \u00b7 Drag to rotate \u00b7 Right-click to delete"
  )
  hk <- as.character(tabInt)
  txt <- if (!is.na(HINT_TEXT[hk])) HINT_TEXT[hk] else ""
  tkconfigure(e$hintLabel, text = txt)
  invisible()
}

#initializes parameters for main component
init.main <- function(e)
{
  e$tabState <-   rep(0, 4) #list to indicate state of tab; 1 means enabled, 0 means disabled

  e$activeDataList <- list()
  e$currImgId <- 1
  e$tab <- 0
  e$indicator <- 0 #used to indicate drawing dgt

  e$dgtPath <- ""
  e$dgtFileName <- NULL
  e$dgtcurvestuff <- NULL

  e$label_MPY_SCALE_FACTOR = 1.0
  e$label_ADD_SCALE_FACTOR = 0.0

  e$curve_MPY_SCALE_FACTOR = 1.0
  e$curve_ADD_SCALE_FACTOR = 0.0


  init.digitize(e)
  init.surface(e)
  init.curve(e)
  class(e) <- "digitize"


  add ("setCurveScaleFactor", 1.0, 0.2, 0)   # THIS IS NOT COMPLETE
  add ("setLabelScaleFactor", 1.0, 0.0, 0)

}



#Switch tabs in GUI to display different relevant information
switchTab <- function(e, id)
{
  print (" ")
  print ("3dDigitize.main ... switch tabs line 139")

  numId <- suppressWarnings(as.integer(id))
  if (length(numId) != 1L || is.na(numId)) return(invisible())
  if (numId >= 1 && numId <= 4 && e$tabState[numId] == 0) {
    if (length(e$activeDataList) == 0) {
      setStatus(e, "Load a PLY or DGT file to begin.", "info")
    } else if (numId == 2) {
      nPlaced <- e$activeDataList[[e$currImgId]][[3]]
      if (is.null(nPlaced)) nPlaced <- 0
      target <- as.integer(e$landmarkNum)
      setStatus(e,
        paste0("Place all ", target,
               " landmarks to unlock Surface Sliders \u2014 ",
               nPlaced, " of ", target, " placed."),
        "warning")
    } else if (numId == 3) {
      nPlaced <- e$activeDataList[[e$currImgId]][[3]]
      if (is.null(nPlaced)) nPlaced <- 0
      target <- as.integer(e$landmarkNum)
      setStatus(e,
        paste0("Place all ", target,
               " landmarks to unlock Curves \u2014 ",
               nPlaced, " of ", target, " placed."),
        "warning")
    } else if (numId == 4) {
      nPlaced <- e$activeDataList[[e$currImgId]][[3]]
      if (is.null(nPlaced)) nPlaced <- 0
      target <- as.integer(e$landmarkNum)
      setStatus(e,
        paste0("Place all ", target,
               " landmarks to unlock GPA \u2014 ",
               nPlaced, " of ", target, " placed."),
        "warning")
    } else if (numId == 1) {
      setStatus(e, "Load a specimen to use the Anchors tab.", "info")
    }
    return(invisible())
  }

  updateHintLabel(e, numId)

  if (numId == 0)
  {
    e$tab <- 0
    set("window", "mode", "digitize")

    # use default color from environment e
    set ("dot",  "dcolor",  e$dColor[1],  e$dColor[2],  e$dColor[3])
    set ("dot",  "dotColorRestore", -1, -2, -3)    # numeric arguments not used


    class(e) <- "digitize"
  }
  else if (numId == 1 && e$tabState[1] == 1)
  {
    #anchor tab
    e$tab <- 1
    set("window", "mode", "anchor")
    class(e) <- "anchor"
  }
  else if (numId == 2 && e$tabState[2] == 1)
  {
    print("switched to Surface Sliders Tab")
    e$tab <- 2
    set("window", "mode", "surface")
    class(e) <- "surface"


    if (tclvalue(e$placeAnchorsVar) == "0")
    {
      tkconfigure(e$bt1, state = "disabled")
      print ("have set 'state' to  disabled")
    }
    else
    {
      tkconfigure(e$bt1, state = "normal")
      print ("have set 'state' to  normal")
    }




    if (length(e$activeDataList) > 0) {
    e$activeDataList[[e$currImgId]][[8]] <- 0

    if (e$activeDataList[[e$currImgId]][[8]] == "NULL")
    {
      e$activeDataList[[e$currImgId]][[8]] <- 0
    }

    if (e$activeDataList[[e$currImgId]][[8]] != "NULL")
    {
      vertToDownsample <- as.vector(t(e$activeDataList[[e$currImgId]][[8]]))


      print (paste("Calling to add downsample for image id ",   e$currImgId ))
      print (paste("vertToSample vector length is ", length(vertToDownsample)))

      if(1)
      {
        print ("--------------------------------------------")
        print ("vertices to down sample (vertToDownsample) ")
        print (vertToDownsample)
        print (paste("$currImgId : ", e$currImgId))
        print ("--------------------------------------------")
      }

      print ("3dDigitizeMain line 223 call to add turned off")
      print ("3dDigitizeMain line 223 call to add turned off")
      # turn this OFF ! it causes repetative reloading od already existing data !
      #add("downsample", vertToDownsample, e$currImgId)
    }
    }

    showPicture(e)
  }
  else if (numId == 3 && e$tabState[3] == 1)
  {
    print("switched to CURVE Tab")
    print("---------------------")

    e$tab <- 3
    set("window", "mode", "curve")

    if (length(e$activeDataList) > 0) {
    myNumberOfSpecimens <-length(e$activeDataList)
    print (paste ("Specimen Count :", myNumberOfSpecimens ))
    print (paste ("Current specimen number :", e$currImgId))

    add("SetLandmarkIndex", e$currImgId, -1, -2)

    curves <- e$activeDataList[[1]][[4]]

    if (is.matrix(curves) && nrow(curves) > 0L) {
      .redrawAllCurves(e)
    }
    }




    # from development of dgt file reader
    if (0) #  (e$dgtFileName != "")
    {
      dgtfileName <- e$dgtFileName
      print ("Re-reading and assigning curves")
      rawContent <- scan( file = dgtfileName, what = "char",  sep = "\n", quiet = TRUE   )
      curves <- read.curve(rawContent)
      draw.curves(curves)
    }



    class(e) <- "curve"
    showPicture(e)
    print ("Tab switch to CURVES ... processing complete")
  }
  else if (numId == 4 && e$tabState[4] == 1)
  {
    e$tab <- 4
    set("window", "mode", "geomorph")
    class(e) <- "geomorph"
    showPicture(e)

    #Checks to make sure all landmarks are placed for GPA
    missing <- FALSE
    for (i in 1:length(e$activeDataList))
      if (is.null(getLandmark(i)))
        missing <- TRUE



    if (missing)
      tkconfigure(e$bt2, state = "disabled")
    else
      tkconfigure(e$bt2, state = "normal")


  }
  bind(e)
}



#builds GUI interface for main component
ui.main <- function(e)
{
  #$nb tab $tab -state disabled
  e$wnd <- tktoplevel(width = 1400, height = 1200)
  tktitle(e$wnd) <- "GUImorph - 3D Morphometrics"

  tryCatch(
    tcl("ttk::style", "theme", "use", GUIMORPH_THEME),
    error = function(err) {
      message(
        "GUImorph: theme '", GUIMORPH_THEME,
        "' unavailable; using Tk default"
      )
    }
  )
  configureGuimorphCenterStyles()

  tkwm.minsize(e$wnd, 900, 700)
  e$nb <- NULL

  rightPanel <- ttkframe(e$wnd)
  tn <- ttknotebook(rightPanel, width = 400, height = 670)
  assign("nb", tn, envir = e)
  e$stepLabel <- ttklabel(rightPanel, text = "Load specimens to begin",
                          foreground = "#505050")

  centerFrame <- tkframe(e$wnd, width = 600, height = 670, background = "white")

  titleFrame <- ttkframe(centerFrame, style = "Center.TFrame")
  e$imgPath <- ttklabel(titleFrame, text = "Specimen: \u2014", style = "Center.TLabel")
  tkpack(e$imgPath)
  tkpack(titleFrame, fill = "x")

  e$hintLabel <- ttklabel(centerFrame, text = "",
                          style = "Center.TLabel",
                          foreground = "#505050",
                          anchor = "center", justify = "center")
  tkpack(e$hintLabel, side = "top", fill = "x", padx = 8, pady = c(0, 4))

  canvasFrame <-
    tkframe(
      centerFrame,
      width = 600,
      height = 600,
      background = "white",
      takefocus = 1
    )
  btnFrame <- createNavFrame(e, centerFrame)
  tkpack(canvasFrame, expand = TRUE, fill = "both")
  tkpack(btnFrame, fill = "x")
  e$canvasFrame <- canvasFrame

  tkbind(tn, '<Button-1>', function(W, x, y) {
    id <- tclvalue(tcl(W, "identify", "tab", x, y))
    if (nzchar(id)) switchTab(e, id)
  })

  digitizeFrame <- ui.digitize(e, tn)
  anchorFrame <- ui.anchor(e, tn)
  surfaceFrame <- ui.surface(e, tn)
  gpagenFrame <- ui.geomorph(e, tn)
  curveFrame <- ui.curve(e, tn)

  tkadd(tn, digitizeFrame, text = "3D Digitizing")
  tkadd(tn, anchorFrame, text = "Anchors")
  tkadd(tn, surfaceFrame, text = "Surface Sliders")
  tkadd(tn, curveFrame, text = "Curves")
  tkadd(tn, gpagenFrame, text = "GPA")

  for (i in 1:4) {
    tcl(tn, "tab", i, state = "disabled")
    e$tabState[i] <- 0 #indicate these tabs are disabled
  }

  statusFrame    <- ttkframe(e$wnd)
  sepStatus      <- ttkseparator(e$wnd, orient = "horizontal")

  e$statusLabel  <- ttklabel(statusFrame,
                             text = "Ready \u2014 open a PLY file to begin.",
                             foreground = "#000000")
  e$progressBar  <- ttkprogressbar(statusFrame, mode = "determinate",
                                   length = 160, value = 0)
  e$statusFrame  <- statusFrame

  tkpack(e$progressBar, side = "right", padx = 8, pady = 4)
  tkpack(e$statusLabel, side = "left",  padx = 8, pady = 4, anchor = "w")

  tkpack(sepStatus,   side = "bottom", fill = "x")
  tkpack(statusFrame, side = "bottom", fill = "x")

  tkpack(e$stepLabel, side = "top", fill = "x", padx = 8, pady = 4)
  tkpack(tn, side = "top", fill = "both", expand = TRUE)

  tkpack(centerFrame, side = "left", padx = 6, expand = TRUE, fill = "both")
  tkpack(rightPanel, side = "left", padx = 6, fill = "y")

  print("ui.main ... starting")



  # this feature added so that developers / users know the verson of
  # the C library which they are executing and the R code as well

  result <- add ("getCompileInformation", -1, -2, -3);
  get_main_date()
  get_digitize_date()
  get_surface_date()
  get_rtkogl_date()
  get_curve_date()
  get_geomorph_date()
  get_geomorph_support_date()



  ##print(paste("canvas frame : ", canvasFrame))
  # Ensure the canvas frame's native window (HWND) is fully created and mapped
  # before the C engine binds the OpenGL/WGL context to it. Binding to a
  # not-yet-realized window makes GL render to a stale/wrong surface (blank
  # viewport + ghosted sibling widgets).
  # Full update (not just idletasks) so the resizable, expand/fill canvas reaches
  # its real on-screen pixel size before the GL context binds. The C engine never
  # calls glViewport — the pick path (ogl_getObjCoordinate) flips winY = viewport[3] - y
  # against the viewport frozen at context-creation time. If we bind while the canvas
  # is still at its requested 600x600, placed landmarks land offset (lower) from the
  # cursor once the window expands. Measure the true size and push THAT.
  tcl("update")
  set("window", "id", canvasFrame)
  cw <- as.integer(tkwinfo("width", canvasFrame))
  ch <- as.integer(tkwinfo("height", canvasFrame))
  if (is.na(cw) || cw <= 1) cw <- 600
  if (is.na(ch) || ch <= 1) ch <- 600
  set("window", "size", cw, ch)
  tcl("update", "idletasks")
  e$glBound <- TRUE
  e$resizeAfter <- NULL

  # Push the actual canvas pixel size to the engine so the GL viewport used for
  # picking matches the on-screen canvas (keeps cursor and placed dot aligned).
  pushCanvasSize <- function() {
    w <- as.integer(tkwinfo("width", e$canvasFrame))
    h <- as.integer(tkwinfo("height", e$canvasFrame))
    if (!is.na(w) && !is.na(h) && w > 1 && h > 1) {
      set("window", "size", w, h)
    }
  }

  onCanvasConfigure <- function() {
    if (!isTRUE(e$glBound)) return()
    if (!is.null(e$resizeAfter)) tcl("after", "cancel", e$resizeAfter)
    e$resizeAfter <- tcl("after", 150, pushCanvasSize)
  }
  tkbind(canvasFrame, "<Configure>", onCanvasConfigure)

  # Force one size sync after the window is fully mapped/laid out, so the engine
  # viewport is correct before the first landmark placement — not only after a
  # manual resize fires <Configure>.
  tcl("after", "idle", pushCanvasSize)

  createMenu(e)
  bind.accelerators(e)
  bind.digitize(e)

  .center_toplevel(e$wnd)
}


bind.accelerators <- function(e)
{
  tkbind(e$wnd, "<Control-o>", function() loadPly(e))
  tkbind(e$wnd, "<Control-s>", function() saveToDgt(e))
  tkbind(e$wnd, "<Control-bracketleft>", function() onPrevious(e))
  tkbind(e$wnd, "<Control-bracketright>", function() onNext(e))
  tkbind(e$wnd, "<Control-f>", function() onFit(e))
  tkbind(e$wnd, "<Control-z>", function() doUndo(e))
}

showShortcutsDialog <- function(e)
{
  win <- tktoplevel(parent = e$wnd)
  tkwm.title(win, "Keyboard Shortcuts")
  tkwm.transient(win, e$wnd)
  tkgrab(win)

  contentFrame <- ttkframe(win)
  tkpack(
    contentFrame,
    expand = TRUE,
    fill = "both",
    padx = 10,
    pady = 10
  )

  shortcuts <- c(
    "Ctrl+O    Load PLY File",
    "Ctrl+S    Save to DGT",
    "Ctrl+[    Previous specimen",
    "Ctrl+]    Next specimen",
    "Ctrl+F    Fit view (Curves tab: Reset view button)",
    "Ctrl+Z    Undo last landmark, anchor, or curve segment action"
  )
  for (line in shortcuts) {
    tkpack(
      ttklabel(contentFrame, text = line, anchor = "w"),
      fill = "x",
      pady = 2
    )
  }

  tkpack(
    ttklabel(
      contentFrame,
      text = "Previous/Next shortcuts respect the same tab and placement gating as the nav buttons.",
      wraplength = 360
    ),
    fill = "x",
    pady = c(8, 0)
  )

  btnFrame <- ttkframe(win)
  tkpack(btnFrame, fill = "x", padx = 10, pady = 10)
  tkpack(
    ttkbutton(btnFrame, text = "OK", command = function() tkdestroy(win)),
    side = "right"
  )
}

#configures file menu
createMenu <- function(e)
{
  topMenu <- tkmenu(e$wnd)
  tkconfigure(e$wnd, menu = topMenu)

  fileMenu <- tkmenu(topMenu, tearoff = FALSE)

  tkadd(
    fileMenu,
    "command",
    label = "Load PLY File\u2026",
    command = function()
      loadPly(e)
  )

  tkadd(
    fileMenu,
    "command",
    label = "Load DGT File\u2026",
    command = function()
      openDgt(e)
  )

  tkadd(
    fileMenu,
    "command",
    label = "Save to DGT\u2026",
    command = function()
      saveToDgt(e)
  )

  tkadd(fileMenu, "separator")

  if (.guimorph_dev_mode()) {
    devMenu <- tkmenu(fileMenu, tearoff = FALSE)
    tkadd(
      devMenu,
      "command",
      label = "Execute STARTUP logging commands",
      command = function()
        executeStartUpCommandSequence(e)
    )
    tkadd(
      devMenu,
      "command",
      label = "Execute SHUTDOWN logging commands",
      command = function()
        executeShutDownCommandSequence(e)
    )
    tkadd(
      devMenu,
      "command",
      label = "Send Signal to Log File",
      command = function()
        sendSignalToLogFile(e)
    )
    tkadd(
      devMenu,
      "command",
      label = "Execute predefined commands",
      command = function()
        executePreDefinedCommandSequence(e)
    )
    tkadd(
      devMenu,
      "command",
      label = "Take Snapshot",
      command = function()
        execueTakeSnapShot(e)
    )
    tkadd(fileMenu, "cascade", label = "Developer", menu = devMenu)
    tkadd(fileMenu, "separator")
  }

  tkadd(
    fileMenu,
    "command",
    label = "Exit",
    command = function()
      onExit(e)
  )
  tkadd(topMenu, "cascade", label = "File", menu = fileMenu)

  helpMenu <- tkmenu(topMenu, tearoff = FALSE)
  tkadd(
    helpMenu,
    "command",
    label = "Keyboard Shortcuts",
    command = function()
      showShortcutsDialog(e)
  )
  tkadd(topMenu, "cascade", label = "Help", menu = helpMenu)
}




#Display different loaded specimen
createNavFrame <- function(e, parent) {
  btnFrame <- ttkframe(parent, style = "Center.TFrame")
  prevBtn <-
    ttkbutton(
      btnFrame,
      text = "< Previous",
      command = function()
        onPrevious(e)
    )
  nextBtn <-
    ttkbutton(
      btnFrame,
      text = "Next >",
      command = function()
        onNext(e)
    )

  e$prevBtn <- prevBtn
  e$nextBtn <- nextBtn

  e$specimenSelectVar <- tclVar("")
  e$specimenCombo <- ttkcombobox(btnFrame, state = "disabled", width = 20,
                                 textvariable = e$specimenSelectVar)
  tkbind(e$specimenCombo, "<<ComboboxSelected>>", function() {
    sel <- suppressWarnings(as.integer(tcl(e$specimenCombo, "current")))
    if (!is.na(sel) && sel >= 0) jumpToSpecimen(e, sel + 1L)
  })

  tkpack(
    ttklabel(btnFrame, text = " ", style = "Center.TLabel"),
    expand = TRUE,
    fill = "both",
    side = "left"
  )
  sapply(list(prevBtn, nextBtn),
         tkpack,
         side = "left",
         padx = 6)
  tkpack(e$specimenCombo, side = "left", padx = 8)
  tkpack(
    ttklabel(btnFrame, text = " ", style = "Center.TLabel"),
    expand = TRUE,
    fill = "both",
    side = "left"
  )
  return (btnFrame)
}

onExit <- function(e)
{
  # 10 June 2020 This issue is still under investigation
  #
  #potentially free up any memory, but currently crashes the program
  #del("dots")
  #del("anchors")
  #del("specimens")
  tkdestroy(e$wnd)
}

#displays the specimen and relevant related information to specimen in canvas
showPicture <- function(e)
{
  if (length(e$activeDataList) == 0) {
    return ()
  }

  imgId <- e$currImgId

  print(paste("showPicture : calling set 'specimen, id' : ", e$currImgId) )
  if (!is.null(e$statusLabel)) {
    p <- e$activeDataList[[e$currImgId]][[1]]
    nm <- if (is.null(p) || !nzchar(p)) paste0("specimen ", e$currImgId) else basename(p)
    setStatus(e,
      paste0("Specimen ", e$currImgId, " of ", length(e$activeDataList),
             " \u2014 ", nm),
      "neutral")
  }
  set("specimen", "id", e$currImgId)


  zoom <- e$activeDataList[[imgId]][[7]]
  angelX <- e$activeDataList[[imgId]][[6]][1]
  angelY <- e$activeDataList[[imgId]][[6]][2]

  set("specimen", "angle", "x", angelX)

  set("specimen", "angle", "y", angelY)

  while (zoom > 0)
  {
    set("specimen", "scale", "in")
    zoom = zoom - 1
  }

  while (zoom < 0)
  {
    set("specimen", "scale", "out")
    zoom = zoom + 1
  }
  updateWidgets(e)
  refreshNavButtons(e)
  updateStepLabel(e)
  updateHintLabel(e)
}



#zoom in or out in canvas
zoom <- function(e, D)
{
  if (length(e$activeDataList))
  {
    imgId <- e$currImgId
    zoomValue <- e$activeDataList[[imgId]][[7]]
    if (D > 0)
    {
      set("specimen", "scale", "in")
      zoomValue <- zoomValue + 1
    }
    else
    {
      set("specimen", "scale", "out")
      zoomValue <- zoomValue - 1
    }
    e$activeDataList[[imgId]][[7]] <- zoomValue
  }
}





#drag dots or rotate specimen
motion <- function(e, x, y)
{
  if (length(e$activeDataList) == 0)
  {
    return()
  }

  if (e$dragX == -1 || e$dragY == -1)
  {
    ##print ("returning from motion drag x|y is -1")
    return()
  }

  ##print("function MOTION ...")
  x <- as.integer(x)
  y <- as.integer(y)

  if (e$dragDot)
  {
    ##print("e$dragDot  ... move it to:" )
    coord <- convertCoor(e, x, y)
    ##print (paste ( "calling : set dot ", coord[1], coord[2], coord[3]) )
    set("dot", "coordinate", coord[1], coord[2], coord[3])
    return()
  }
  else
  {
    ##print ("else ... not e$dragDot")
    ##print("location :" )
    coord <- convertCoor(e, x, y)
    ##print (paste ( "location ", coord[1], coord[2], coord[3]) )
  }

  threshold <- 5
  dx <- abs(e$dragX - x)
  dy <- abs(e$dragY - y)
  if (dx < threshold && dy < threshold)
  {
    return()
  }

  ##print (paste ("dx :", dx, " dy : ", dy))
  imgId <- e$currImgId
  preAngle <- e$activeDataList[[imgId]][[6]]

  if (dx > dy)
  {
    angle <- (x - e$dragX) / 600  * 360
    msg <- set("specimen", "angle", "y", angle)
    currAngle <- preAngle + c(0, angle)
  }
  else
  {
    angle <- (y - e$dragY) / 600 * 360
    msg <- set("specimen", "angle", "x", angle)
    currAngle <- preAngle + c(angle, 0)
  }


  e$dragX <- x
  e$dragY <- y
  e$activeDataList[[imgId]][[6]] <- currAngle

  ##print (paste("Current angle is : ", currAngle[1], currAngle[2]))
}




#show next specimen
onNext <- function(e)
{
  if (length(e$activeDataList) == 0)
  {
    print ("function NEXT 3dDigitizeMain ... length of data list is 0 ... returning")
    return ()
  }

  nCurrA  <- e$activeDataList[[e$currImgId]][[9]]
  nCurrLM <- e$activeDataList[[e$currImgId]][[3]]

  if (is.null(nCurrA))
  {
    nCurrA <- 0
  }

  if(1)
  {
  print(" ")
  print (paste("function onNEXT 3dDigitizeMain line 658"))
  print (paste ("e$currImgId : ", e$currImgId))
  print (paste ("number current anchors      " ,nCurrA))
  print (paste ("number of current landmarks ", nCurrLM))
  }

  if (e$currImgId == length(e$activeDataList))
  {
    setStatus(e,
      paste0("Already at the last specimen (", e$currImgId,
             " of ", length(e$activeDataList), ")."),
      "warning")
    return ()
  }

  if (e$tab == 0)   ## if on the 3dDigitize tab ...
  {
    # by design, when on the digitize tab, the operator MUST place the required number
    # of landmarks on the currently displayed specimen before this code will allow
    # changing the display state to the next specimen
    if (nCurrLM < as.integer(e$landmarkNum))  ## not enough landmarks placed ?
    {
      setStatus(e,
        paste0("Place all ", e$landmarkNum,
               " landmarks before continuing \u2014 ",
               nCurrLM, " of ", e$landmarkNum, " placed."),
        "warning")
      return ()
    }


    if (nCurrA < as.integer(e$anchorNum) &&
        tclvalue(e$placeAnchorsVar) == "1")
    {
      setStatus(e,
        paste0("Place all ", e$anchorNum,
               " anchors before continuing \u2014 ",
               nCurrA, " of ", e$anchorNum, " placed."),
        "warning")
      return()
    }
  }



  if (e$tab == 1)  ## if on the ANCHORS tab
  {
    nCurrA <- e$activeDataList[[e$currImgId]][[9]]
    if (nCurrA < as.integer(e$anchorNum)) {
      setStatus(e,
        paste0("Place all ", e$anchorNum,
               " anchors before continuing \u2014 ",
               nCurrA, " of ", e$anchorNum, " placed."),
        "warning")
      return ()
    }
  }


  # the operator is not on the digitizing tab, say after placing anchors on the
  # currently displayed specimen, then require the operator to switch back to
  # the digitizing tab in preparation for placin the landmarks on the next specimen.
  if (e$tab != 0)  ## again if not on the 3dDigitizing tab
  {
    setStatus(e, "Switch to the 3D Digitizing tab to change specimen.", "warning")
    return()
  }




  clearUndo(e)
  e$currImgId <- e$currImgId + 1


  tkconfigure(e$bt, state = "disabled")

  print (paste("(NEW ?) current image id is : ",e$currImgId ))
  print (paste("e$ indicator is  is ",e$indicator ))

  if (e$indicator == 1)
  {
    if(0)
    {
    print ("ready to call draw.digitize : ")
    print (paste("e$currImgId ", e$currImgId))
    print (paste("e$activeDataList[[e$currImgId]][[1]]  : ", e$activeDataList[[e$currImgId]][[1]]));
    print (paste("e$activeDataList[[e$currImgId]][[10]] : ", e$activeDataList[[e$currImgId]][[10]]))
    }

    draw.digitize(e, e$currImgId, e$activeDataList[[e$currImgId]][[1]], e$activeDataList[[e$currImgId]][[10]])

     if (nCurrA != 0)
     {
      draw.anchors(e, e$currImgId, e$activeDataList[[e$currImgId]][[11]])
     }
  }
  else
  {


    nCurrA  <- e$activeDataList[[e$currImgId]][[9]]
    nCurrLM <- e$activeDataList[[e$currImgId]][[3]]
    if (is.null(nCurrA))
    {
      nCurrA <- 0
    }

    if(0)
    {
      print(" ")
      print (paste("function onNEXT 3dDigitizeMain line 781"))
      print (paste ("e$currImgId : ", e$currImgId))
      print (paste ("number current anchors      " ,nCurrA))
      print (paste ("number of current landmarks ", nCurrLM))
      print (paste ("Arguments for add specimen ", e$activeDataList[[e$currImgId]][[1]], ":" ,e$currImgId ))
    }
    add("specimen", e$activeDataList[[e$currImgId]][[1]], e$currImgId)
  }

  refreshTabGating(e)

  if (e$currImgId == length(e$activeDataList))
  {
    e$indicator <- 0
  }



  showPicture(e)
}



#show the previous specimen
onPrevious <- function(e)
{
  if (length(e$activeDataList) == 0)
  {
    return ()
  }

  if (e$currImgId == 1)
  {
    setStatus(e,
      paste0("Already at the first specimen (1 of ",
             length(e$activeDataList), ")."),
      "warning")
    return ()
  }

  if (e$tab == 0) {
    nCurrLM <- e$activeDataList[[e$currImgId]][[3]]
    if (nCurrLM < as.integer(e$landmarkNum)) {
      setStatus(e,
        paste0("Place all ", e$landmarkNum,
               " landmarks before continuing \u2014 ",
               nCurrLM, " of ", e$landmarkNum, " placed."),
        "warning")
      return()
    }
  }

  if (e$tab == 1) {
    nCurrA <- e$activeDataList[[e$currImgId]][[9]]
    if (nCurrA < as.integer(e$anchorNum)) {
      setStatus(e,
        paste0("Place all ", e$anchorNum,
               " anchors before continuing \u2014 ",
               nCurrA, " of ", e$anchorNum, " placed."),
        "warning")
      return()
    }
  }

  if (e$tab != 0) {
    setStatus(e, "Switch to the 3D Digitizing tab to change specimen.", "warning")
    return()
  }

  clearUndo(e)
  e$currImgId <- e$currImgId - 1
  if (as.integer(e$currImgId) == 1)
  {
    tkconfigure(e$bt, state = "normal")
  }


  add("specimen", e$activeDataList[[e$currImgId]][[1]], e$currImgId)

  refreshTabGating(e)
  showPicture(e)
}


#size specimen to fit canvas
onFit <- function(e)
{
  if (length(e$activeDataList) == 0) {
    return()
  }

  imgId <- e$currImgId
  zoom <- e$activeDataList[[imgId]][[7]]
  angelX <- e$activeDataList[[imgId]][[6]][1]
  angelY <- e$activeDataList[[imgId]][[6]][2]

  ##print ("CALLING SET SPECIMEN")
  ##print ("C----------------------------------------------")

  set("specimen", "angle", "x",-angelX)
  set("specimen", "angle", "y",-angelY)

  while (zoom > 0)
  {
    set("specimen", "scale", "out")
    zoom = zoom - 1
  }

  while (zoom < 0)
  {
    set("specimen", "scale", "in")
    zoom = zoom + 1
  }

  e$activeDataList[[imgId]][[6]] <- c(0, 0)
  e$activeDataList[[imgId]][[7]] <- 0
}




# get .ply file
# finds file location and sets up environment, then uses C to load model
loadPly <- function(e)
{
  fileStr <-
    tclvalue(
      tkgetOpenFile(
        filetypes = "{{ply file} {.ply}}",
        multiple = TRUE,
        title = "Select PLY specimen file(s)"
      )
    )

  if (length(grep(pattern = "}", x = fileStr)) > 0)
  {
    imgList <- unlist(strsplit(fileStr, "} ", fixed = FALSE))
    imgList <- gsub(pattern = "}",
                    replacement = "",
                    x = imgList)
    imgList <- gsub(pattern = "\\{",
                    replacement = "",
                    x = imgList)
  }
  else
  {
    imgList <- unlist(strsplit(fileStr, " ", fixed = FALSE))
  }

  if(0) # if multiple files selected ... test is concatenated together
  {
    print (" ")
    print ("Function loadPly 3dDigitizeMain ... line 1152")
    print (paste ("Selected file name is :",fileStr ))
  }

  nSpecimens <- length(imgList)

  if(1)
  {
    messageToC (paste ("LOADPLY : selected ", nSpecimens,"specimen files" ))

    for (i in 1:length(imgList))
    {
      speciName <- imgList[[i]]
      messageToC (paste("File name ", i, "is : ",speciName ))
    }
  }



  if (nSpecimens != 0)
  {
    #initialize dgtDataList
    dgtDataList <- list()

    for (i in 1:length(imgList))
    {
      speciName <- imgList[[i]]
      if (!file.exists(speciName))
      {
        nSpecimens <- nSpecimens - 1
        print(paste(speciName, "doesn't exist. Ignore it!!"))
        next
      }

      #updated to handle anchor points number
      dgtDataList[[length(dgtDataList) + 1]] <-
        list(imgList[[i]], 0.01, 0, matrix(nrow = 0, ncol = 3), "NULL", c(0, 0), 0, "NULL", 0) #last 0 for anchor points num
    }

    print (paste("Tested for file existence : there are ", nSpecimens, " specimen files found"))


    if (nSpecimens > 0)
    {
      init.digitize(e)    #initialize
      for (i in 1:nSpecimens)
      {
        e$digLM[[i]] <- 0
      }


      e$activeDataList <- dgtDataList
      e$digData <- dgtDataList
      e$currImgId <- 1

      tkconfigure(e$specimenNumLabel,
                  text = paste("Number of Specimens: ", nSpecimens))
      tkconfigure(e$specimenNumLabel2,
                  text = paste("Number of Specimens: ", nSpecimens))
      tkconfigure(e$imgPath, text = paste0("Specimen ", e$currImgId, " of ", length(e$activeDataList)))

      if (0)
      {
        print ("loadPly ... 3dDigitize.main ... line 214")
        print (paste ("length (allocate) :", (length(e$activeDataList  ))))
        print (paste ("file name         :", e$activeDataList[[1]][[1]]))
        print( paste ("image number      :", (e$currImgId)))
        print (paste ("Arguments for add function ... load Ply :", e$activeDataList[[1]][[1]], e$currImgId))
      }

      # why are we using the e$ variable here when we know the number as a anumber ?
      # As of 06 August 2020 the C code can handle more than one specimen file.
      # we have allocated memory for 'nSpecimens' in the C code

      nSpecimens <- length(e$activeDataList)
      set("specimen", "allocate", nSpecimens)
      tkconfigure(e$progressBar, mode = "determinate",
                  maximum = as.numeric(nSpecimens), value = 0)
      loadFailed <- FALSE
      for (i in seq_len(nSpecimens)) {
        fname <- e$activeDataList[[i]][[1]]
        setStatus(e, paste0("Loading ", basename(fname),
                            " (", i, " of ", nSpecimens, ")\u2026"), "info")
        tkconfigure(e$wnd, cursor = "watch")
        tcl("update", "idletasks")
        err <- tryCatch({
          add("specimen", fname, i)
          NULL
        }, error = function(err) {
          tkconfigure(e$wnd, cursor = "")
          tkconfigure(e$progressBar, mode = "determinate", value = 0)
          setStatus(e,
            paste0("Could not load ", basename(fname),
                   " \u2014 check the file and try again."),
            "error")
          print(err)
          err
        })
        if (!is.null(err)) {
          loadFailed <- TRUE
          break
        }
        tkconfigure(e$progressBar, value = as.numeric(i))
      }
      if (!loadFailed) {
        tkconfigure(e$wnd, cursor = "")
        s <- if (nSpecimens == 1) "" else "s"
        setStatus(e, paste0("Loaded ", nSpecimens, " specimen", s, "."), "success")
        clearUndo(e)
        tkconfigure(e$progressBar, mode = "determinate", value = 0)
        refreshTabGating(e)
        populateSpecimenCombo(e)
        updateStepLabel(e)
      }
    }
  }

  add("rotationAngles", 0, 0)

  print ("End of function load ply ... specimen should be displayed")
}



# draws elements of specimen when loading .dgt file, such as landmarks,
# surfaces, and curves
drawElements <-  function(e, digitize, surfaceData, curves, anchors)
{
  print(" ")
  print(" ")
  print("file 3dDigitize.main ... function drawElements  line 1127")

  specimens <- dimnames(digitize)[[3]]
  nSpecimens <- dim(digitize)[3]
  e$landmarkNum <- dim(digitize)[1]
  e$anchorNum <- dim(anchors)[1]
  anchorNum <- e$anchorNum
  numberOfLandmarkSets <- e$landmarkNum
if(0)
{
  print ("drawElements line 1262")
  print ("name of the files which contain specimen data")
  print (specimens)      ## n file names where n is the number of specimens
  print ("Integer number of specimens")
  print (nSpecimens)     ## integer number of specimens
  print ("Number of landmarks")
  print (e$landmarkNum)  ## number of landmark sets
  print (numberOfLandmarkSets)
  print ("Number of anchors")
  print (e$anchorNum)
  print (anchorNum)
}


  #if no anchor data read in, set default values
  if (is.null(e$anchorNum))
  {
    print ("No anchor data read from .dgt file : setting default values")
    e$anchorNum <- 5  #maximum number ofanchors to be placed, default to 5 if none
    anchorNum <- 0    # how many anchors are currently placed
  }


  if (length(surfaceData) != 0)
  {
    tmpt <- surfaceData$template
    surfaces <- surfaceData$surfaces
  }
  else
  {
    tmpt <- NULL
    surfaces <- NULL
  }


  if (!anyNA(anchors) && !is.null(anchors))
  {
    print("drawElements ... all anchors detected")
    tclvalue(e$placeAnchorsVar) <- "1"
    tkconfigure(e$bt, state = "disabled")
  }
  else
  {
    print ("drawElements ... missing anchors detected")
    tclvalue(e$placeAnchorsVar) <- "0"
    tkconfigure(e$bt, state = "normal")
  }

  dgtDataList <- list()
  specId <- 1


  if(1)
  {
    print ("line 1207 .... dgtDataList")
    print (dgtDataList)
    print ("specId")
    print (specId)
  }





  print (paste ("drawElements ... 1409 nSpecimens is ", nSpecimens))


  # added this loop as a test to see what is known
  print ("checking for file existence ... I know the names of the files")
  nSpecimensNew = nSpecimens
  for (i in 1:nSpecimens)
  {
    print (paste ("   i is", i))
    print (paste ("   checking for file ...", specimens[[i]] ) )
    if (!file.exists(specimens[[i]]))
    {
      print(paste(specimens[[i]], "doesn't exist. Ignore it!!"))
      print(paste(specimens[[i]], "doesn't exist. Ignore it!!"))
      print(paste(specimens[[i]], "doesn't exist. Ignore it!!"))
      nSpecimensNew <-  nSpecimensNew -1
    }
    else
    {
      print ("   file exists -ok-")
    }
  }
  print ("file existence test complete")
  print (" ")
  if (nSpecimensNew < 1)
  {
    print ("There are no specimen files found  ! terminating operation.")
    return();
  }


  if (nSpecimensNew !=  nSpecimens)
  {
    print("File access / existence error ... quitting ")
    return (FALSE)
  }







  nSpecimens = nSpecimensNew
  messageToC(paste ("drawElements : nSpecimens is ", nSpecimens))

  ##
  ## COMMAND
  ##
  set("window", "mode", "none")

  ##
  ## COMMAND  allocate memory for nSpecimens
  ##
  set("specimen", "allocate", nSpecimens)
  print (paste ("Memory allocated in C library for", nSpecimens, "specimens"))

  e$lmkLoadedInC <- as.list(rep(FALSE, nSpecimens))
  names(e$lmkLoadedInC) <- as.character(seq_len(nSpecimens))

  # we assume that the landmark data is of identical size across the
  # nSpecimens. Element 0 does not exist but the R environment returns
  # the row and column information

  # Use first specimen slice for landmark dimensions (R is 1-based; index 0 is empty)
  landmarks <- digitize[, , 1]
  print ("LINE 1269 landmarks for argument 1 (first specimen)")
  print(landmarks)



  # Tell the tcl_if function the sizes of the anchors and the landmarks
  add("InfoLandmarks", nrow(landmarks), ncol(landmarks), nSpecimens)
  if (!is.null(anchors) && dim(anchors)[3] >= 1 && !anyNA(anchors[, , 1]))
  {
   add("InfoAnchors",  nrow(anchors), ncol(anchors), nSpecimens  )
  }



  for (i in 1:nSpecimens)
  {

    id <-i
    set("specimen", "id", id)
    fileName <- specimens[[id]]

    messageToC (paste("drawElements : specimen  is ", id, "of",nSpecimens ))
    messageToC (paste("drawElements : PLY file fileName is ", fileName))


    ## This action is performed in function draw.digitize
    ## add("specimen",fileName, id)   # load model in


    landmarks <- digitize[, , id]   # singular set of landmark points
    print( paste("landmarks id index ", id))
    print (landmarks)
    draw.digitize(e, id, fileName , landmarks)


    if (!anyNA(anchors[, , i]) && !is.null(anchors))
    {
      anchor <- anchors[, , id]
      print (paste ("anchor id  index",id))
      print ( anchor)
      draw.anchors(e, id, anchor)
    }
    else
    {
      anchor <- NULL
    }







    dgtDataList[[specId]] <-
      list(
        specimens[[i]],
        0.01,
        e$landmarkNum,
        matrix(nrow = 0, ncol = 3),
        tmpt[i],
        c(0, 0),
        0,
        surfaces[, , i],
        anchorNum,
        landmarks,
        anchor
      )

    ## print (paste("for specId", specId))
    ## print (dgtDataList[[specId]])

    specId <- specId + 1

  }   # end of the for loop



if(0)
{
    print (paste ("curves nRows", nrow(curves)))
    print (paste ("curves nCols", ncol(curves)))
    print (paste ("nSpecimens  ", nSpecimens))
}

if (!is.null(curves) && length(curves) > 0 && nrow(curves) > 0)
{
  add("InfoCurves", nrow(curves), ncol(curves), nSpecimens)

  print("ready to draw curves")
  print("ready to draw curves")

  print("ready to draw curves")
  draw.curves(curves)
  dgtDataList[[1]][[4]] <- curves
  e$dgtcurvestuff <- curves

  print("back from  draw curves")
  print("back from  draw curves")
}

    e$activeDataList <- dgtDataList
    clearUndo(e)

    refreshTabGating(e)
    populateSpecimenCombo(e)
    updateStepLabel(e)

# this line makes things look ugly !
#draw.digitize(e, 1, e$activeDataList[[1]][[1]], e$activeDataList[[1]][[10]])
#print ("This is line 1412 and a following line is turned off")
#
#if(0)
#{
 #  if (!is.null(e$activeDataList[[1]][[11]]))
 #  {
 #    draw.anchors(1, e$activeDataList[[1]][[11]])
 #  }
#}

    tkconfigure(e$specimenNumLabel,
                text = paste("Number of Specimens: ", nSpecimens))
    tkconfigure(e$specimenNumLabel2,
                text = paste("Number of Specimens: ", nSpecimens))

    # set to first specimen even if there are multiple specimens
    set("specimen", "id", 1)


    print("file 3dDigitize.main ... function drawElements ... end")
  }




#save user input to .dgt file including curve data, template data, surface data, and landmarks
saveToDgt <- function(e)
{
  nSpecimen <- length(e$activeDataList)
  if (nSpecimen <= 0)
  {
    tkmessageBox(
      title = "Information",
      message = "Nothing to be saved",
      icon = "info",
      type = "ok"
    )
    return ()
  }

  #select the location
  fileName <- tclvalue(tkgetSaveFile(filetypes = "{DGT {.dgt}}"))
  if (!nchar(fileName)) {
    return ()
  }

  if (length(grep(".dgt", x = fileName)) == 0) {
    fileName <- paste(fileName, ".dgt", sep = "")
  }

  file.create(fileName, showWarnings = TRUE)


  print(paste("Writing digitized data to file :",fileName))


  ################### write curve #####################
  curves <- e$activeDataList[[1]][[4]]
  print(paste("Writing curve data", curves))
  write.curve(fileName, curves)

  ################### write template ####################
  write.template(fileName, e$templOrig)

  print (paste("Writing data for : ", nSpecimen, "specimens"))

  for (i in 1:nSpecimen)
  {
    ################### write landmark #####################
    #specimenId <- e$activeDataList[[i]][[1]] # FOR LATER EOC: NEED a BUTTON that
    # writes file with specific path, with if statement

    #this line adds the file name without path specific to a particular computer
    specimenId <- basename(e$activeDataList[[i]][[1]])
    print (paste("specimen id at line 1585", specimenId))
    print (paste("integer  i is ", i, " this is the specimen id"))

    landmarks <- getLandmark(i)
    anchors <- getAnchor(i)

    print (paste("specimen index & landmarks ", i))
    print (paste("specimen index & anchors   ", i))



    if (is.null(landmarks))
    {
      tkmessageBox(
        title = "Information",
        message = "No data. Nothing to be saved",
        icon = "info",
        type = "ok"
      )
      next()
    }

    write.digitize(fileName, specimenId, landmarks)

    write.anchors(fileName, specimenId, anchors)

    if(1)
    {
      print(paste("writing surface data"))
      ################### write surface #####################
      tempt <- e$activeDataList[[i]][[5]]
      surface <- e$activeDataList[[i]][[8]]
      write.surface(fileName, tempt, surface)
    }

    write("", fileName, append = TRUE)

  }


}




#grabs data for landmark
getLandmark <- function(id)
{
  print(paste("get landmark  line 1485 for id :", id))
  lmkStr <- tclvalue(shows("landmark", "xyz", id))   # keep 1 based indexing in R
  if (lmkStr != "")
  {
    lmkV <- strsplit(lmkStr, " ")[[1]]
    rows <- length(lmkV) / 3
    lmk = matrix(
      as.numeric(lmkV),
      nrow = rows,
      ncol = 3,
      byrow = TRUE
    )
  }
  else
  {
    print (paste("getlandmark line 1500 ... landmark data for id ",id," is null"))
    lmk <- NULL
  }
  return(lmk)
}


#grabs data for anchor
getAnchor <- function(id)
{
  print(paste("get anchor line 1510 for id :", id))

  ancStr <- tclvalue(shows("anchor", "xyz", id))

  if (ancStr != "")
  {
    ancV <- strsplit(ancStr, " ")[[1]]
    rows <- length(ancV) / 3
    anc = matrix(
      as.numeric(ancV),
      nrow = rows,
      ncol = 3,
      byrow = TRUE
    )
  }
  else
  {
    print (paste("getanchor line 1527 ... anchor  data for id ", id," is null"))
    anc <- NULL
  }

  return(anc)
}


#converts coords to numeric
convertCoor <- function(e, x, y) {
  dotStr <- shows("specimen", "xyz", x, y)
  dot <- strsplit(tclvalue(dotStr), " ")
  realDot <-
    c(as.numeric(dot[[1]][1]), as.numeric(dot[[1]][2]), as.numeric(dot[[1]][3]))
  #print(paste("convert ", x, y, "to ",realDot[1], realDot[2], realDot[3]))
  return (realDot)
}






# additional menu options to assist in development
# added 20 May 2020

# added by Anglea for diagnostics
startDataLogging <- function(e)
{
  print ("starting data logging")
  add ("openLogFile", -1, 0)
}

endDataLogging <- function(e)
{
  print ("ending data logging")
  add ("closeLogFile", -4, 0)
}

sendSignalToLogFile <- function(e)
{
  print ("sending signal into the log file")
  add ("logMessage", -23, 0, 0)

}

startCommandRecording <-function(e)
{
  print ("Starting command recording")
  add ("startRecording", -24, 0)
}

endCommandRecording <-function(e)
{
  print ("Ending command recording")
  add("endRecording", -25, 0)
}

nullFunction <-function(e)
{
  # deliberately do nothing
  # print ("this is the null function")
}



executeShutDownCommandSequence <- function (e)
{
  print ("Shut down command sequence")
  add ("closeLogFile", -4, 0)
  add ("endRecording", -25, 0)
}

executeStartUpCommandSequence <- function (e)
{
  print ("Start up command sequence")
  add ("startRecording", -24, 0)
  add ("openLogFile", -1, 0)
}


execueTakeSnapShot <- function(e)
{
  print ("Taking snapshot of tcl_if state")
  add ("snapshot", -1, -2)   # two arguments for use TBD  22 May 2020
}







executePreDefinedCommandSequence <- function (e)
{

  # this function is intended to be dynamic and changeable at any time
  # at a developers discretion
  # at some future date, the use of pre-determined command sequences to accomplish
  # operator tasks ...



  print ("Predefined command sequence")
  if(1)
  {
  add ("startRecording", -24, 0)
  add ("openLogFile", -1, 0)
  }

  nna <- -1;
  NNA <- -1;
  ##################################################
  ##################################################

  # developers ... implement the code for tests here
  # and turn on/off individual tests and desired
  # use numeric values 0 or 1 ONLY
  #
  # enable only 1 test at a time !!

  test_00 <- 0   # allocate zero ... look at log file
  test_01 <- 0   # simple load of a ply file
  test_02 <- 0   # load a single ply file and place landmarks & anchors
  test_03 <- 0   # load a single ply file using file chooser and place landmarks & anchors

  test_04 <- 0   # WARNING : function return value tests from TCL_if  : WARNING tool may not operate correctly
  test_05 <- 0   # WARNING : CRASHES THE TOOL ! load two ply files, place landmarks & anchors : NOT VIA GUI !
  test_06 <- 0   # WARNING : DOES NOT WORK AS DESIRED load two ply files, place landmarks & anchors : VIA GUI

  test_07 <- 0   # loads a ply file and places landmarks and anchors

  test_08 <- 0  # label test : get labels / dots off the specimen surface

  test_09 <- 0  # query and message to C code from R
  test_10 <- 0  # test for erasing vertex and down sample data  ! READ THE COMMENTS IN THE TEST !
  test_11 <- 1  # invokes graw grid


  if(1 == test_00)
  {
    # tested 05 August 2020
    set ("specimen",  "allocate", 0)
  }

  if(1 == test_01)
  {
    # command sequence for load Ply file
    # tested 05 August 2020
    print ("Executing test_01")
    set ("specimen",  "allocate", 1)
    add ("specimen", "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/A6.1.PLY", 1)
    set ("specimen",  "id", 1)
    print ("test_01 ... complete")
  }

  if(1 == test_02)
  {
    print ("Executing test_02")
    # tested 05 August 2020
    set ("specimen",  "allocate", 1)
    add ("specimen" , "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/A6.1.PLY", 1)
    set ("specimen",  "id", 1)
    set("window", "mode", "digitize")


    # Tell tcl_if about the landmark data, 5 rows, 3 columns, 2 sets
    add ("InfoLandmarks", 5, 3, 2)
    add ("SetLandmarkIndex", 1, nna, nna)
    add ("rawdot", -20.054497, -37.918907, -3.670341);
    add ("rawdot", - 7.808026, -36.100124, -3.915579);
    add ("rawdot", - 5.382958, -26.884939, -4.359759);
    add ("rawdot", - 2.109146, -39.252674, -4.167464);
    add ("rawdot", - 3.32168,  -55.985489, -3.792133);
    print ("NOTE : THE DIGITIZE GUI IS NOT RESPONSIVE !")
    print ("test_02 ... complete")
  }

  if(1 == test_03)
  {
    print ("Executing test_03")
    # tested 05 August 2020

    print ("-------------------------------------")
    print ("PICK ONLY Folsom3D/A6.1.PLY   !!")
    print ("PICK ONLY Folsom3D/A6.1.PLY   !!")

    loadPly(e)

    # Tell tcl_if about the landmark data, 5 rows, 3 columns, 2 sets
    add ("InfoLandmarks", 5, 3, 2)
    add ("SetLandmarkIndex", 1, nna, nna)
    add ("rawdot", -20.054497, -37.918907, -3.670341);
    add ("rawdot", - 7.808026, -36.100124, -3.915579);
    add ("rawdot", - 5.382958, -26.884939, -4.359759);
    add ("rawdot", - 2.109146, -39.252674, -4.167464);
    add ("rawdot", - 3.32168,  -55.985489, -3.792133);
    print ("NOTE : THE DIGITIZE GUI IS MUST BE RESPONSIVE !")
    print ("test_02 ... complete")
  }

  if(0) ## 1 == test_03)
  {
    print ("Executing test_03")
    # This is a test of labeling a specimen .. I discovered that
    # dots can have Z components assigned to negative values based
    # based on where the dot is placed. The labels would them appear behind
    # the 'front' view of the specimen
    # as of 12 June 2020 the C code has been modifed to handle this


    # 12 June 2020 .. .something is missing when I do the next 3 steps
    # ths display is not active to mouse movement
    # so manually load the PLY file

    ##set("specimen",  "allocate", 1)
    ##add("specimen" , "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/A6.1.PLY",  0)
    ##set("window", "mode", "digitize")

    e$landmarkNum <- 7
    print (paste("line 1921 The number of landmarks is set to : ", e$landmarkNum) )


    # these are some points previously digitized on specimen A6.1.PLY

    add ("setLabelScaleFactor", e$label_MPY_SCALE_FACTOR,  e$label_ADD_SCALE_FACTOR, -1)
    add ("setCurveScaleFactor", e$curve_MPY_SCALE_FACTOR,  e$curve_ADD_SCALE_FACTOR, -1)

    add("dot", -0.176000,-0.781000,  0.017218)
    add("dot",  0.190667,-0.363000,  0.020021)
    add("dot",  -0.209000,  0.128333,  0.006686)
    add("dot",   -0.007333,  0.432667,-0.027503)
    add("dot",   0.168667,  0.183333,-0.015137)
    add("dot",   0.216333,-0.198000,  0.010422)
    add("dot",   0.212667,-0.748000,  0.005068)
    print ("test_03 complete")
  }

  if(1 == test_04)
  {
    # tested 05 August 2020
    # This is a test of the function return interface in the C library code.
    # As of 14 July 2020 we are still having run time issues regarding what
    # to return when an operation is other than successful - but not quite and error
    # THIS IS A DEVELOPER FUNCTION : DO NOT EXPECT THIS TOOL TO BEHAVE NICELY

    print ("Predefined sequence test 04 : function returns")
    print ("DO NOT EXPECT THIS TOOL TO BEHAVE NICELY !! ")
    print ("DO NOT EXPECT THIS TOOL TO BEHAVE NICELY !! ")
    result <-     tclvalue(add ("logMessage", -1, -3, 0))
    print (result)
    result <- tclvalue(add ("logMessage", -2, -2, 0))
    print (result)
    result <- tclvalue(add ("logMessage", -3, -1, 0))
    print (result)
    result <- tclvalue(add ("logMessage", -4,  0, 0))
    print (result)


    result <- tclvalue(add ("logMessage", -6,  2, 0))
    print (result)
    result <- tclvalue(add ("logMessage", -7,  3, 0))
    print (result)
    result <- tclvalue(add ("logMessage", -8,  4, 0))
    print (result)
    result <- tclvalue(add ("logMessage", -9,  5, 0))
    print (result)


    result <- tclvalue(add ("logMessage", -10,  0, 0))
    print (result)
    result <- tclvalue(add ("logMessage", -11,  0, 1))
    print (result)
    result <- tclvalue(add ("logMessage", -12,  0, 2))
    print (result)
    result <- tclvalue(add ("logMessage", -13,  0, 3))
    print (result)
    result <- tclvalue(add ("logMessage", -14,  0, 4))
    print (result)
    result <- tclvalue(add ("logMessage", -15,  0, 5))
    print (result)
    result <- tclvalue(add ("logMessage", -16,  0, 6))
    print (result)
    result <- tclvalue(add ("logMessage", -17,  0, 7))
    print (result)
    result <- tclvalue(add ("logMessage", -18,  0, 8))
    print (result)


    if(0)
    {
    print ("This will generate an error ! ")
    print ("------------------------------")
    result <- tclvalue(add ("logMessage", -5,  1, 0))
    print (result)
    }

    print ("DO NOT EXPECT THIS TOOL TO BEHAVE NICELY !! ")
    print ("DO NOT EXPECT THIS TOOL TO BEHAVE NICELY !! ")

    result <-"WHAT IS THIS ! "

    result <-tryCatch(
      {
        add ("logMessage", -5,  1, 0)
      },
      error = function(err)
      {
        message(err)
      }
    )






  }

  if(1 == test_05)
  { # this does not work correctly. There is an equivalent test in the C code stand
    # alone tool which DOES work correctly. The problem here seems to be that
    # by bypassing the R functions, some state variables in R are NOT assigned.
    # use test 7 instead !

    print ("STOP ! THIS CRASHES THE TOOL ! DEVELOPMENT ITEM 05 AUGUST 2020 ")
    print ("Executing test_05")
    set("specimen",  "allocate", 2)
    add ("specimen", "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/A6.1.PLY", 1)
    add ("specimen", "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/B7.1.PLY", 2);
    set ("specimen",  "id", 1)

    # Tell tcl_if about the landmark data, 5 rows, 3 columns, 2 sets
    add ("InfoLandmarks", 5, 3, 2)
    add ("SetLandmarkIndex", 1, nna, nna)
    add ("rawdot", -20.054497, -37.918907, -3.670341);
    add ("rawdot", - 7.808026, -36.100124, -3.915579);
    add ("rawdot", - 5.382958, -26.884939, -4.359759);
    add ("rawdot", - 2.109146, -39.252674, -4.167464);
    add ("rawdot", - 3.32168,  -55.985489, -3.792133);

    add ("SetLandmarkIndex", 2, nna, nna)

    add ("rawdot", -12.235758, -32.720879,  0.714147);
    add ("rawdot", -1.019839,  -33.35817,   0.060274);
    add ("rawdot", -1.911993,  -44.701553, -0.004728);
    add ("rawdot", -8.029779,  -48.142807,  0.080747);
    add ("rawdot", -10.706311, -40.495575,  0.689502);

    set("window", "mode", "digitize")
    print ("NOTE : THE DIGITIZE GUI IS NOT RESPONSIVE !")
    print ("test_05 ... complete")
  }

  if(1 == test_06)
  {
    # again this does not seem to work !
    # 05 August 2020 !


    print ("Executing test_06")
  #  set("specimen",  "allocate", 2)
  #  set ("specimen",  "id", 1)
  #  print ("PICK ONLY FILES A6.1.PLY and B7.1.PLY  ! ")
  #  print ("PICK ONLY FILES A6.1.PLY and B7.1.PLY  ! ")
  #  loadPly(e)



    set ("specimen",  "id", 1)


    # Tell tcl_if about the landmark data, 5 rows, 3 columns, 2 sets
    add ("InfoLandmarks", 5, 3, 2)
    add ("SetLandmarkIndex", 1, nna, nna)
    add ("rawdot", -20.054497, -37.918907, -3.670341);
    add ("rawdot", - 7.808026, -36.100124, -3.915579);
    add ("rawdot", - 5.382958, -26.884939, -4.359759);
    add ("rawdot", - 2.109146, -39.252674, -4.167464);
    add ("rawdot", - 3.32168,  -55.985489, -3.792133);
    e$landmarkNum <- 5


    set ("specimen",  "id", 2)
    add ("SetLandmarkIndex", 2, nna, nna)

    add ("rawdot", -12.235758, -32.720879,  0.714147);
    add ("rawdot", -1.019839,  -33.35817,   0.060274);
    add ("rawdot", -1.911993,  -44.701553, -0.004728);
    add ("rawdot", -8.029779,  -48.142807,  0.080747);
    add ("rawdot", -10.706311, -40.495575,  0.689502);
    e$landmarkNum <- 5
    set("window", "mode", "digitize")

    print ("test_06 ... complete")

  }

  if(1 == test_07)
  {

    # tested 05 August 2020
    print ("Executing test_07 ")


    myFileName <- "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/A6.1.PLY"
    loadPlyTest(e, myFileName)

    #set("specimen",  "allocate", 1)
    #add ("specimen", "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/A6.1.PLY", 1)
    set("specimen",  "id", 1)


    add ("InfoLandmarks", 5, 3, 2)
    add ("SetLandmarkIndex", 1, nna, nna)


    switchTab (e,0)
    onLeftBtnPress (e, 262, 500)
    onLeftBtnRelease (e, 262, 500)
    addDot(e, 262, 500)

    onLeftBtnPress (e, 276, 437)
    onLeftBtnRelease (e, 276, 437)
    addDot(e, 276, 437)

    onLeftBtnPress (e, 291, 368)
    onLeftBtnRelease (e, 291, 368)
    addDot(e, 291, 368)

    onLeftBtnPress (e, 309, 305)
    onLeftBtnRelease  (e, 309, 305)
    addDot(e, 309, 305)

    onLeftBtnPress (e, 329, 257)
    onLeftBtnRelease  (e, 329, 257)
    addDot(e, 329, 257)


   # e$placeAnchorsVar <- tclVar("1")
   # onPlaceAnchor(e)
   # e$tabState[1] <- 1
   # switchTab (e,1)

    addAnchor(e, 302, 499)
    addAnchor(e, 326, 445)
    addAnchor(e, 341, 414)
    addAnchor(e, 349, 373)
    addAnchor(e, 351, 333)
    switchTab (e,1)

    print ("ENABLE PLACE ANCHORS CHECKBOX AND CHANGE TABS TO ANCHORS")
    print ("ENABLE PLACE ANCHORS CHECKBOX AND CHANGE TABS TO ANCHORS")

    print ("test_07 ... complete")
}

  if(1 == test_08)
  {

    # tested 05 August 2020
    print ("Executing test_08 ")




    print ("-------------------------------------")
    print ("PICK ONLY Folsom3D/A6.1.PLY   !!")
    print ("PICK ONLY Folsom3D/A6.1.PLY   !!")
    loadPly(e)


   # myFileName <- "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/A6.1.PLY"
   # loadPlyTest(e, myFileName)

    #set("specimen",  "allocate", 1)
    #add ("specimen", "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/A6.1.PLY", 1)

     set("specimen",  "id", 1)



    add ("setLabelScaleFactor", 1.0,  0.3, nna)   # arg 1 is MYP, arg 2 is ADD

    #add ("setCurveScaleFactor", e$curve_MPY_SCALE_FACTOR,  e$curve_ADD_SCALE_FACTOR, nna)




    add ("InfoLandmarks", 5, 3, 2)
    add ("SetLandmarkIndex", 1, nna, nna)


    switchTab (e,0)
    onLeftBtnPress (e, 262, 500)
    onLeftBtnRelease (e, 262, 500)
    addDot(e, 262, 500)

    onLeftBtnPress (e, 276, 437)
    onLeftBtnRelease (e, 276, 437)
    addDot(e, 276, 437)

    onLeftBtnPress (e, 291, 368)
    onLeftBtnRelease (e, 291, 368)
    addDot(e, 291, 368)

    onLeftBtnPress (e, 309, 305)
    onLeftBtnRelease  (e, 309, 305)
    addDot(e, 309, 305)

    onLeftBtnPress (e, 329, 257)
    onLeftBtnRelease  (e, 329, 257)
    addDot(e, 329, 257)


     e$placeAnchorsVar <- tclVar("1")
     onPlaceAnchor(e)
     e$tabState[1] <- 1
     switchTab (e,1)

    addAnchor(e, 302, 499)
    addAnchor(e, 326, 445)
    addAnchor(e, 341, 414)
    addAnchor(e, 349, 373)
    addAnchor(e, 351, 333)
    switchTab (e,1)


    set ("specimen", "angle", 0, 30)

    print ("test_08 ... complete")
  }

  if(1 == test_09)
  {
    # tested 05 August 2020
    print ("Executing test_09 ")
    add ("queryFromR", 3, 0,0)
    add ("messageFromR", "I'm sorry Dave, I'm afraid I can't do that", 0,0)
    messageToC ( paste("Good morning dave, would you like a slice of ", 3.14159, "?"))
    print ("test_09 ... complete")
  }

  if (1 == test_10)
  {
     # manually load three specimens A1.1_S1, A1.1_S2, A1.1_S3
     # manually place landmarks on all three specimens 1) to the left, 2) to the right, 3 in the center
     # manually downsample specimens 1 and 3 ONLY
     # manually save the data to a .dgt file
     #
     # use this test : invoke erase vertices on specimen 1
     # use this test : invoke erase downsample on specimen 2 and speciman 3
     # use this test : take a snapshot

     add ("EraseVertexData", 1, -1, -2)
     #add ("EraseDownSampleData", 2, -1, -2)
     #add ("EraseDownSampleData", 3, -1, -2)
     add ("Snapshot, -1, -2, -3)")
  }


  if(1 == test_11)
  {
    add ("invoke_draw_grid", 0,0,0)
  }


  ##################################################
  ##################################################
  if (1)
  {
    add ("closeLogFile", -4, 0)
    add("endRecording", -25, 0)
  }
  print ("Predefined command sequence ... end ")

}






## a version of the load ply function for use in the testing code
## contained in the executePreDefinedCommandSequence functions
loadPlyTest <- function(e, yourFileName)
{


  fileStr <- yourFileName  #  "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/A6.1.PLY"
  #fileStr <- "A6.1.PLY"
  if (length(grep(pattern = "}", x = fileStr)) > 0)
  {
    imgList <- unlist(strsplit(fileStr, "} ", fixed = FALSE))
    imgList <- gsub(pattern = "}",
                    replacement = "",
                    x = imgList)
    imgList <- gsub(pattern = "\\{",
                    replacement = "",
                    x = imgList)
  }
  else
  {
    imgList <- unlist(strsplit(fileStr, " ", fixed = FALSE))
  }

  if(1)
  {
    print (" ")
    print ("Function loadPly 3dDigitizeMain ... line 1020")
    print (paste ("Selected file name is :",fileStr ))
  }

  nSpecimens <- length(imgList)

  if(1)
  {
    print (paste ("nSpeciments at line 1028 :",nSpecimens ))
    for (i in 1:length(imgList))
    {
      speciName <- imgList[[i]]
      print (paste("File name ", i, "is : ",speciName ))
    }
  }







  if (nSpecimens != 0)
  {
    #initialize dgtDataList
    dgtDataList <- list()

    for (i in 1:length(imgList))
    {
      speciName <- imgList[[i]]
      if (!file.exists(speciName))
      {
        nSpecimens <- nSpecimens - 1
        print(paste(speciName, "doesn't exist. Ignore it!!"))
        next
      }

      #updated to handle anchor points number
      dgtDataList[[length(dgtDataList) + 1]] <-
        list(imgList[[i]], 0.01, 0, matrix(nrow = 0, ncol = 3), "NULL", c(0, 0), 0, "NULL", 0) #last 0 for anchor points num
    }

    print (paste("Tested for file existence : there are ", nSpecimens, " specimen files found"))


    if (nSpecimens > 0)
    {
      init.digitize(e)    #initialize
      for (i in 1:nSpecimens)
      {
        e$digLM[[i]] <- 0
      }


      e$activeDataList <- dgtDataList
      e$digData <- dgtDataList
      e$currImgId <- 1

      tkconfigure(e$specimenNumLabel,
                  text = paste("Number of Specimens: ", nSpecimens))
      tkconfigure(e$specimenNumLabel2,
                  text = paste("Number of Specimens: ", nSpecimens))
      tkconfigure(e$imgPath, text = paste0("Specimen ", e$currImgId, " of ", length(e$activeDataList)))

      if (1)
      {
        print ("loadPly ... 3dDigitize.main ... line 1068")
        print (paste ("length (allocate) :", (length(e$activeDataList  ))))
        print (paste ("file name         :", e$activeDataList[[1]][[1]]))
        print( paste ("image number      :", (e$currImgId)))
        print (paste ("Arguments for add function ... load Ply :", e$activeDataList[[1]][[1]], e$currImgId))
      }

      set("specimen", "allocate", length(e$activeDataList))
      add("specimen", e$activeDataList[[1]][[1]], e$currImgId)
    }
  }

  add("rotationAngles", 0, 0)
  print (" ")
  print ("End of function load ply ... specimen should be displayed")
}

messageToC  <- function(theMessage)
{
  add ("messageFromR", theMessage, 0,0)
  print (theMessage)
}




#load .dgt file
openDgt <- function(e)
{

  print(" ")
  print(" ")
  print(" ")

  init.main(e)

  print (paste("opendgt :  NO provision is made here for picking more than one .dgt file"))



  dgtfileName <- tclvalue(tkgetOpenFile(filetypes = "{DGT {.dgt}}"))

  # if file name is empty ... quit early ....
  if ("" == dgtfileName)
  {
    print ("")
    print ("function openDgt ... no file name ...")
    return(FALSE)
  }

  e$dgtPath <- dirname(dgtfileName)
  e$dgtFileName <- dgtfileName


  if (1)
  {
    print ("")
    print ("function openDgt ... file name is")
    print (dgtfileName)
    print (paste ("e$dgtFileName :", e$dgtFileName))
    print (paste ("e$dgtPath     :", e$dgtPath ))
  }


  rawContent <- scan( file = dgtfileName, what = "char",  sep = "\n", quiet = TRUE   )

  if (0)
  {
    # The rawContent seems to be the entire file contents
    print ("function openDgt ... rawContent")
    print (paste("rawContent length is ", length(rawContent)))
    print (rawContent)
    print (".........................................................")
  }

  ################### read digitize data ##################

  # olddat corresponds to the N lines of text from the file immediately following
  # the text 'LM3= ' in the original file
  olddat <- read.digitize(e, content = rawContent)
  if (1)
  {
    print(".........................................................")
    print ("olddat")
    print (olddat)
    print(".........................................................")
  }



  nSpecimens <- dim(olddat)[3]
  if (1)
  {
    print("nSpecimens")
    print(nSpecimens)
    print(".........................................................")
  }

  if (nSpecimens < 1)
  {
    print ("ERROR ... NO SPECIMENS IN OPEN DG FILE ... returning FLASE")
    return (FALSE)
  }



  ################### read template ##################
  templOrig <- read.template(rawContent)
  if (1)
  {
    print(paste("e$templOrig", e$templOrig))
    print ("template information")
    print (templOrig)
    print(".........................................................")
  }



  ################## read anchor data ####################
  anchors <- read.anchors(rawContent)

  if (0)
  {
    print ("anchors data")
    print (anchors)
    print(".........................................................")

    if (!anyNA(anchors))
    {
      print (anchors)
    }
    else
    {
      print ("there are no anchors")
    }
  }


  print ("Line 2382  ...   if(1)  for sliders")
  sliderNum <- 0
  surfaceData <- NULL

  if (1)
  {
    ################### read surface data ##################
    surfaceData <- read.surface(rawContent)
    print (paste ("length of surface data ", length(surfaceData) ))


    if (is.null(surfaceData))
    {
      print("NULL surface data : treating as Surface=0 (no sliders)")
      surfaceData <- list()
    }


    if (0)
    {
      print("return from reading the surface data")

      for (ii in 1:nSpecimens)
      {

        surfTemp <- surfaceData[ , , ii]
        print (paste ("surface data rows   ", nrow( surfTemp) ))
        print (paste ("surface data columns", ncol( surfTemp) ))
      }

      # print (surfaceData)
      print("........................................................")
    }


    ##eoc 5/04/2020 added this conditional statement in case there is no
    # surface data then sliderNum = 0
    if (length(surfaceData) == 0)
    {
      print ("ZERO length surface data : setting sliderNum to zero")
      sliderNum <- 0
    }


    if (length(surfaceData) != 0)
    {
      tmpt <- surfaceData$template
      surfaces <- surfaceData$surfaces

      ##eoc 4/29/2020 added this line to read the number of surface sliders in the .dgt file
      sliderNum <- as.numeric(surfaceData$sliderNum[1])

      if ((length(tmpt) != nSpecimens) |
          (dim(surfaces)[3] != nSpecimens)) {
        tkmessageBox(
          title = "Error",
          message = "Incorrect format of dgt file",
          icon = "info",
          type = "ok"
        )
        return ()
      }
    }
    else
    {
      tmpt <- NULL
      surfaces <- NULL
    }

    if (0)   # debugging only ...
    {
      print ("")
      print ("")
      print ("")

      print ("post processing of surface data")
      print ("tmpt")
      print (tmpt)

      print ("surfaces")
      print (surfaces)

      print ("sliderNum")
      print (sliderNum)

      print("........................................................")
    }
  }






  ################### read curves data ##################
  curves <- read.curve(rawContent)
  if (1)
  {
   ## print("return from curves")

    # added the following environment variable so
    # that we know if there is curve data when we switch tabs
    # on the gui.

    if(is.null(curves))
    {
      e$dgtcurvestuff <- NULL
    }
    else
    {
      if(1)
      {
        print ("curves")
        print(curves)
        print(paste ("curve nrows", nrow(curves)))
        print(paste ("curve ncols", ncol(curves)))
        for (j in 1:nrow(curves))
        {
          print(paste("curve", curves[j,1], curves[j,2], curves[j,3]))
        }
        print("........................................................")
      }
      e$dgtcurvestuff <- curves
    }
  }


  messageToC(paste ("openDgt : data structures have been read : processing the data"))

  # This is where I commence to tell the C library code about the
  # data as read from the .dgt file

  ################### Add elements ##################
  if (nSpecimens > 0)
  {

    e$templOrig <- templOrig
    e$sliderNum <- sliderNum

    print ("file 3dDigitize.main ... function openDgt ... line 2687")
    print (paste( "number of specimens is ", nSpecimens))

    specimens <- dimnames(olddat)[[3]]
    print (paste("specimens", specimens))
    print (paste("rows ", nrow(specimens)))
    print (paste("cols ", ncol(specimens)))



    messageToC(paste ("openDgt : calling drawElements"))
    drawElements(e, olddat, surfaceData, curves, anchors)
    print ("file 3dDigitize.main ... function openDgt ... back from drawElements .....")

    print(paste("Image id ",e$currImgId) )

    print ("e$activeDataList")
    print (e$activeDataList)
    if (0 == length(e$activeDataList))
    {
      print ("FAIL HERE")
      print ("FAIL HERE")
      return (FALSE)
    }


    #loadDgt  (dgtfileName) #only loads downsample, rest of functionality implemented in R




    class(e) <- "anchor"
    string <- "anchor"
    updateWidgets(e)

    # build string based on which GUI tab is active
    if (e$tab == 0)
    {
      string <- "digitize"
    }
    else if (e$tab == 2)
    {
      string <- "surface"
    }
    else if (e$tab == 3)
    {
      string <- "curve"
    }
    class(e) <- string

    if (1)
    {
      print ("ready to invoke set ... window / mode /string ...")
      print (string)
    }

    set("window", "mode", string)

    updateWidgets(e)

    e$indicator <- 1

    e$currImgId <- 1
    showPicture(e)
  }


  for (ii in 1:nSpecimens)
  {
    sliceID <- ii
    add("queryFromR", 1, sliceID);
    add("queryFromR", 2, sliceID);
    add("queryFromR", 3, sliceID);
    add("queryFromR", 4, sliceID);
  }

  if(0)  # focibly switch specimens so that the display is updated :this is a patch
  {
    set("specimen", "id", 1)
    if (nSpecimens > 1)
    {
      onNext(e)
      onPrevious(e)
    }
    set("specimen", "id", 1)
  }



  print("function openDgt ... completed")
}



