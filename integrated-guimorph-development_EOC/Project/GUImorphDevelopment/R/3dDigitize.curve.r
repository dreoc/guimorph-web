
# Developers to update this function
get_curve_date <- function()
{
  print ("curve 15 August 2020")
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

# Clamp helpers for curve spinbox validation (testable without Tk)
.clampCurveMax <- function(val) {
  val <- suppressWarnings(as.integer(val))
  if (is.na(val) || val < 1L)
    val <- 1L
  val
}

.clampCurveCurrent <- function(val, maxC) {
  maxC <- .clampCurveMax(maxC)
  val <- suppressWarnings(as.integer(val))
  if (is.na(val) || val < 1L)
    val <- 1L
  if (val > maxC)
    val <- maxC
  val
}

#initializes parameters for curve component
init.curve <- function(e)
{
	e$curveDotNum <- 0
	e$curveDots <- c()
	e$curveLine<- c()
	e$sliders<-c()

	e$curveMaxCurves <- 1L            # 1 based
	e$curveCurrentCurveNumber <- 1L   # 1 based
}

onCurveMaxChange <- function(e) {
  val <- .clampCurveMax(tclvalue(e$curveMaxVar))
  tclvalue(e$curveMaxVar) <- as.character(val)
  e$curveMaxCurves <- val
  onCurveCurrentChange(e)
}

onCurveCurrentChange <- function(e) {
  maxC <- .clampCurveMax(tclvalue(e$curveMaxVar))
  val <- .clampCurveCurrent(tclvalue(e$curveCurrentVar), maxC)
  tclvalue(e$curveCurrentVar) <- as.character(val)
  e$curveCurrentCurveNumber <- val
  add("SetCurveIndex", val, -1, -2)
}

#creates user interface layout for curve component
ui.curve <- function(e, parent)
{
  curveCtlFrame <- ttkframe(parent)

  e$curveDescLabel <- ttklabel(
    curveCtlFrame,
    text = "Define curves by selecting 3 landmarks per segment"
  )
  tkconfigure(e$curveDescLabel, foreground = "#505050")

  e$curveMaxVar <- tclVar("1")
  e$curveMaxRow <- ttkframe(curveCtlFrame)
  tkpack(
    ttklabel(e$curveMaxRow, text = "Total curves:"),
    side = "left",
    padx = c(8, 4)
  )
  e$curveMaxSpin <-
    ttkspinbox(
      e$curveMaxRow,
      from = 1,
      to = 9999,
      increment = 1,
      textvariable = e$curveMaxVar,
      width = 5,
      command = function()
        onCurveMaxChange(e)
    )
  tkpack(e$curveMaxSpin, side = "left", padx = c(0, 8))
  tkbind(e$curveMaxSpin, "<Return>", function() {
    onCurveMaxChange(e)
  })
  tkbind(e$curveMaxSpin, "<FocusOut>", function() {
    onCurveMaxChange(e)
  })

  e$curveCurrentVar <- tclVar("1")
  e$curveCurrentRow <- ttkframe(curveCtlFrame)
  tkpack(
    ttklabel(e$curveCurrentRow, text = "Current curve:"),
    side = "left",
    padx = c(8, 4)
  )
  e$curveCurrentSpin <-
    ttkspinbox(
      e$curveCurrentRow,
      from = 1,
      to = 9999,
      increment = 1,
      textvariable = e$curveCurrentVar,
      width = 5,
      command = function()
        onCurveCurrentChange(e)
    )
  tkpack(e$curveCurrentSpin, side = "left", padx = c(0, 8))
  tkbind(e$curveCurrentSpin, "<Return>", function() {
    onCurveCurrentChange(e)
  })
  tkbind(e$curveCurrentSpin, "<FocusOut>", function() {
    onCurveCurrentChange(e)
  })

  computeCurvesBtn <-
    ttkbutton(
      curveCtlFrame,
      text = "Compute Curves",
      command = function()
        onComputeCurves(e)
    )

  resetViewBtn <-
    ttkbutton(
      curveCtlFrame,
      text = "Reset view",
      command = function()
        onFit(e)
    )

  tkpack(ttklabel(curveCtlFrame, text = " "), pady = 6)
  tkpack(e$curveDescLabel, pady = c(0, 4))
  tkpack(e$curveMaxRow, pady = 3)
  tkpack(e$curveCurrentRow, pady = 3)
  tkpack(computeCurvesBtn, pady = 3)
  tkpack(resetViewBtn, pady = 3)
  .overrideCtrlZ(e$curveMaxSpin, e)
  .overrideCtrlZ(e$curveCurrentSpin, e)

  return (curveCtlFrame)
}


#drag and place landmarks on curve component
bind.curve <- function(e)
{
  #print("bind.curve")
  tkbind(e$canvasFrame, "<ButtonPress-1>", function(x, y) {
    e$dragX <- as.integer(x)
    e$dragY <- as.integer(y)
  })

  tkbind(e$canvasFrame, "<ButtonPress-3>", function(x, y) {
  })
  tkbind(e$canvasFrame, "<Double-Button-1>", function(x, y) {
    onSelectCurve(e, x, y)
  })
}




#loads curve data from .dgt file
read.curve <- function(content)
{
	##print ("file 3dDigitize.curve ... function read.curve")

  ignore.case = TRUE
	startLine <- grep("Curve=", content, ignore.case)
	num <- sub("Curve=", "", content[startLine], ignore.case)

	if (num == 0)
	{
	  print ("No curve data to process")
		return (NULL)
	}

	endLine <- as.numeric(startLine) + as.numeric(num)
	startLine <- startLine + 1
	tmp <- content[startLine:endLine]
	curves <- matrix(as.numeric(unlist(strsplit(tmp, " "))), ncol=3, byrow=TRUE)

	##print("curves ....................................")
  ##print (curves)

	return (curves)
}

#writes the curve data to .dgt file
write.curve <- function(fileName, curves)
{
  if (length(curves) > 0)
  {
    write(paste("Curve=", nrow(curves), sep = ""), fileName, append = TRUE)
  }
  else
  {
    write(paste("Curve=0", sep = ""), fileName, append = TRUE)
  }

  if (length(curves) > 0)
  {
    write.table(
      curves,
      fileName,
      sep = " ",
      col.names = FALSE,
      row.names = FALSE,
      append = TRUE
    )
    write("", fileName, append = TRUE)
  }
}

#display curves to GUI
draw.curves <- function(curves)
{
	print("file 3dDigitize.curve ... function draw.curves line 164")
  print (paste ("curves ... nrows",nrow(curves)))
  print (paste ("curves ... ncols",ncol(curves)))

  print ("This may take a while to compete ! ")
   ## R code shall be 1 based !
	for (j in 1:nrow(curves))
	{
	  print (paste("setting curve number to", j))
	  add ("SetCurveIndex", j, -1,-1)
	  add("curve", curves[j,1], curves[j,2], curves[j,3])
	}
  print("file 3dDigitize.curve ... function draw.curves ... complete")
}



#UI layout dynamic update callback
updateWidgets.curve <- function(e) {

}

#changes rgb values of selected dot to desired color
changeDotColor<-function(e)
{
  print("changeDotColor")
  for(i in 1:3)
  {
    x  <- e$curveDots[[(i - 1) * 3 + 1]]
    y  <- e$curveDots[[(i - 1) * 3 + 2]]
    id <- e$curveDots[[(i - 1) * 3 + 3]]

    if (set("dot", "selected", x, y))
    {
      if (id %in% e$sliders)
      {
        set("dot", "color", 0.0, 0.0, 1.0)
      }
      else
      {
        set("dot", "color", -1.0, -1.0, -1.0)
      }
    }
  }
}


#sets and configures dot on curve
onSelectCurve <- function(e, x, y)
{
  print("file 3dDigitize.curve ... function onSelectCurve line 165")

  print (paste  ("onSelectCurve argument x", x))
  print (paste  ("onSelectCurve argument y", y))

  if (TRUE == set("dot", "selected", x, y))
  {
    id <- -1
    id <- tclvalue(shows("landmark", "id"))
    print (paste("this is the id returned from shows landmark id ", id))

    if (id %in% e$curveLine)
    {
      tkmessageBox(
        title = "Information",
        message = "Duplicate dot in one curve is not allowed",
        icon = "info",
        type = "ok"
      )
      return ()
    }



    e$curveLine <- c(e$curveLine, as.numeric(id))
    e$curveDots <- c(e$curveDots, c(x, y, id))

    print ("onSelectCurve ... e$curveDots ...")
    print (e$curveDots)


    print (paste("line 247 ... e$curveDotNum is ",e$curveDotNum ))
    e$curveDotNum <- e$curveDotNum + 1
    print (paste("line 250 ... e$curveDotNum is ",e$curveDotNum ))




    set("dot","color", as.double(1 / 255),  as.double(164 / 255),   as.double(191 / 255))

    if (e$curveDotNum == 2)
    {
      print ("e$curveDotNum is 2 line 258")
      e$sliders <- c(e$sliders, id)
      print(e$sliders)
    }
    else if (e$curveDotNum == 3)
    {

      print ("e$curveDotNum is 3 line 265")

      #why is this done ??
      set("window", "mode", "digitize")
      changeDotColor(e)

      set("window", "mode", "curve")

      curves <- e$activeDataList[[1]][[4]]
      newCurve <- matrix(e$curveLine, nrow = 1, ncol = 3)
      curves <- rbind(curves, newCurve)
      e$activeDataList[[1]][[4]] <- curves

      print ("existing landmark indices for call to add curve")
      print (paste("e$curveLine[1] ",e$curveLine[1]))
      print (paste("e$curveLine[2] ",e$curveLine[2]))
      print (paste("e$curveLine[3] ",e$curveLine[3]))



      messageToC(paste("Curve points from R", e$curveLine[1], e$curveLine[2], e$curveLine[3]))
      print ("Calling add curve ... ")
      add("curve", e$curveLine[1], e$curveLine[2], e$curveLine[3])

      e$curveDots <- c()
      e$curveDotNum <- 0
      e$curveLine <- c()
    }
  }
  else
  {
    print ("file 3dDigitize curve line 296 : else clause ... false return from set dot selected at line 258")
  }

  print("file 3dDigitize.curve ... function onSelectCurve ... end")
}


#Pop up window for setting the total number of curves
# stuff that was undet development

setCurvesNum <- function(e)
{
  win <- tktoplevel()
  tkwm.title(win, "Set Total Number of Curves")

  entryFrame <- ttkframe(win)
  tkpack(
    entryFrame,
    expand = TRUE,
    fill = "both",
    padx = 5,
    pady = 5
  )
  label = tklabel(entryFrame, text = 'Set total number of curves : ')

  print("line 296")
  ##e$anchorEntry = tkentry(entryFrame, textvariable = tclVar(e$anchorNum))
  ## e$curveEntry  = tkentry(entryFrame, textvariable = tclVar(e$curveNum))
  e$curveMaxCurves <- 0            # 1 based
##  e$curveCurrnetCurveNumber <- 0   # 1 based
  temp  = tkentry(entryFrame, textvariable = tclVar(e$curveMaxCurves))
  e$curveMaxCurves <- temp
  sapply(list(label, e$curveMaxCurves),
         tkpack,
         side = "left",
         padx = 6)

  print("line 323")
  btnFrame <- ttkframe(win)

  tkpack(btnFrame,
         fill = "x",
         padx = 5,
         pady = 5)
  cancelBtn <-
    ttkbutton(
      btnFrame,
      text = "cancel",
      command = function()
        tkdestroy(win)
    )
  okBtn <-
    ttkbutton(
      btnFrame,
      text = "ok",
      command = function()
        onCurveNumOk(e, win)
    )

  print("line 345")

  tkpack(
    ttklabel(btnFrame, text = " "),
    expand = TRUE,
    fill = "y",
    side = "left"
  )
  sapply(list(cancelBtn, okBtn),
         tkpack,
         side = "left",
         padx = 6)

  tkfocus(win)
  print("line 359")
}


#Grabs user input
onCurveNumOk <- function(e, win)
{

  temp <-  tclvalue(tkget(e$curveMaxCurves))
  e$curveMaxCurves <- temp
  print (paste("Total number of curves : ", temp))

  tkdestroy(win)

 print (paste("line 344 The number of curves is set to : ", e$curveMaxCurves) )


}



setCurrentCurvesNum <- function(e)
{
  win <- tktoplevel()
  tkwm.title(win, "Set Current Curve Number")

  entryFrame <- ttkframe(win)
  tkpack(
    entryFrame,
    expand = TRUE,
    fill = "both",
    padx = 5,
    pady = 5
  )
  label = tklabel(entryFrame, text = 'Set current curve number 1 ..... : ')

  print("line 398")


  temp  = tkentry(entryFrame, textvariable = tclVar(e$curveCurrentCurveNumber))
  e$curveCurrentCurveNumber <- temp
  sapply(list(label, temp),
         tkpack,
         side = "left",
         padx = 6)

  print("line 406")
  btnFrame <- ttkframe(win)

  tkpack(btnFrame,
         fill = "x",
         padx = 5,
         pady = 5)
  cancelBtn <-
    ttkbutton(
      btnFrame,
      text = "cancel",
      command = function()
        tkdestroy(win)
    )
  okBtn <-
    ttkbutton(
      btnFrame,
      text = "ok",
      command = function()
        onCurrentCurveNumOk(e, win)
    )

  print("line 428")

  tkpack(
    ttklabel(btnFrame, text = " "),
    expand = TRUE,
    fill = "y",
    side = "left"
  )
  sapply(list(cancelBtn, okBtn),
         tkpack,
         side = "left",
         padx = 6)

  tkfocus(win)
  print("line 442")
}

#Grabs user input
onCurrentCurveNumOk <- function(e, win)
{

  temp <- tclvalue(tkget(e$curveCurrentCurveNumber))
  e$curveCurrentCurveNumber <- temp
  print (paste("Current Curve Number: ", temp))

  tkdestroy(win)

  print (paste("line 461 The current curve number is set to : ",   e$curveCurrentCurveNumber) )


}



onComputeCurves <- function(e)
{
  print ("under construction compute curves")
}

