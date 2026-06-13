# Developers to update this function
get_digitize_date <- function()
{
  print ("digitize 15 August 2020")
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
#dgtDataList[imgId][[9]]: number of anchor points





#initializes parameters for digital component
init.digitize <- function(e)
{
  e$digData <- list()
  e$dragX <- as.integer(-1)
  e$dragY <- as.integer(-1)
  e$dragDot <- FALSE
  e$landmarkNum <- 5
  e$anchorNum <- 5
  # these variables are populated by a query of the C library code
  # they record the number of landmarks and the anchors resident in the C
  # code data structures for the specified array slice
  # these can be used to prevent adding redundant (duplicate) landmarks and anchors
  # as a result of changing specimens (NEXT / PREVIOUS) after landmarks an danchors have
  # been loaded, say as a result of reading a .dgt file
  e$landmarksPresentInMemory <- 0
  e$anchorsPresentInMemory <- 0

  e$dColor <- c(1, 0, 0)     # initial dot color is RED
  e$daColor <- c(0, 1, 0)    # initial anchor color is GREEN
  if(0)
  {
    print ("3dDigitize init.digitize");
  }
 	set("dot", "labeled", 1)
  set("dot", "alabeled", 1) #toggle for anchor point labels
}



#draw widgets for digitize tab
ui.digitize <- function(e, parent)
{
  digCtlFrame <- ttkframe(parent)
  e$bt <- NULL

  setScaleBtn <-
    ttkbutton(
      digCtlFrame,
      text = "Digitize scale",
      command = function()
        setScale(e)
    )
  e$scaleLabel = tklabel(digCtlFrame, text = 'Scale Factor: not set')

  setLandmarkNumBtn <-
    ttkbutton(
      digCtlFrame,
      text = "Set number of landmarks",
      command = function()
        setLandmarkNum(e)
    )
  loadLandmarkBtn <-
    ttkbutton(
      digCtlFrame,
      text = "Load landmarks",
      command = function()
        loadLandmark(e)
    )

  #e$path <- tclVar("Path:")
  #e$imgPath = tkentry(digCtlFrame, textvariable=e$path, state="disabled")

  fitBtn <-
    ttkbutton(
      digCtlFrame,
      text = "Fit",
      command = function()
        onFit(e)
    )

  e$labelLandmarkVar <- tclVar("1")
  labelLandmark <-
    ttkcheckbutton(
      digCtlFrame,
      text = "Label Landmark",
      variable = e$labelLandmarkVar,
      command = function()
        onLabelLandMark(e)
    )

  e$placeAnchorsVar <- tclVar("0")
  placeAnchors <-
    ttkcheckbutton(
      digCtlFrame,
      text = "Place Anchors",
      variable = e$placeAnchorsVar,
      command = function() {
        onPlaceAnchor(e)
      }
    )
  assign("bt", placeAnchors, envir = e)


  #####################################
  lmSizeAdd <-
    ttkbutton(
      digCtlFrame,
      text = "Landmark Size +",
      command = function()
        onLmSizeAdd(e)
    )
  lmSizeDec <-
    ttkbutton(
      digCtlFrame,
      text = "Landmark Size -",
      command = function()
        onLmSizeDec(e)
    )

  lmColorFrame <- ttkframe(digCtlFrame)
  lmColorBtn <-
    ttkbutton(
      lmColorFrame,
      text = "Landmark Color",
      command = function()
        onLmColorChange(e)
    )
  e$lmColorLabel <-
    tklabel(
      lmColorFrame,
      text = 'aa',
      foreground = '#ff0000',
      background = '#ff0000'
    )
  sapply(list(lmColorBtn, e$lmColorLabel),
         tkpack,
         side = "left",
         padx = 3)

  e$specimenNumLabel <-
    ttklabel(digCtlFrame, text = "Number of Specimens: 0")
  e$landMarkNumLabel <-
    ttklabel(digCtlFrame, text = "Number of Landmarks: 0")

  e$missLandmarkVar <- tclVar("0")
  e$missLandmarkCheBtn <-
    ttkcheckbutton(digCtlFrame,
                   text = "Missing Landmark",
                   variable = e$missLandmarkVar)

  tkpack(ttklabel(digCtlFrame, text = " "), pady = 6)
  sapply(
    list(
      setLandmarkNumBtn,
      loadLandmarkBtn,
      fitBtn,
      lmSizeAdd,
      lmSizeDec,
      lmColorFrame,
      labelLandmark,
      placeAnchors,
      e$specimenNumLabel,
      e$landMarkNumLabel
    ),
    tkpack,
    pady = 3
  )
  return (digCtlFrame)
}





#draw widgets for anchor tab
ui.anchor <- function(e, parent)
{
  anchorCtlFrame <- ttkframe(parent)

  setAnchorNumBtn <-
    ttkbutton(
      anchorCtlFrame,
      text = "Set number of anchors",
      command = function()
        setAnchorNum(e)
    )

  fitBtn <-
    ttkbutton(
      anchorCtlFrame,
      text = "Fit",
      command = function()
        onFit(e)
    )

  e$labelAnchorVar <- tclVar("1")
  labelAnchor <-
    ttkcheckbutton(
      anchorCtlFrame,
      text = "Label Anchors",
      variable = e$labelAnchorVar,
      command = function()
        onLabelAnchor(e)
    )

  e$anchorNumLabel <-
    ttklabel(anchorCtlFrame, text = "Number of Anchors: 0")
  e$specimenNumLabel2 <-
    ttklabel(anchorCtlFrame, text = "Number of Specimen: 0")

  anchorSizeAdd <-
    ttkbutton(
      anchorCtlFrame,
      text = "Anchor Size +",
      command = function()
        onLmSizeAdd(e)
    )
  anchorSizeDec <-
    ttkbutton(
      anchorCtlFrame,
      text = "Anchor Size -",
      command = function()
        onLmSizeDec(e)
    )

  anchorColorFrame <- ttkframe(anchorCtlFrame)
  anchorColorBtn <-
    ttkbutton(
      anchorColorFrame,
      text = "Anchor Color",
      command = function()
        onAnchorColorChange(e)
    )
  e$anchorColorLabel <-
    tklabel(
      anchorColorFrame,
      text = 'aa',
      foreground = '#00ff00',
      background = '#00ff00'
    )
  sapply(
    list(anchorColorBtn, e$anchorColorLabel),
    tkpack,
    side = "left",
    padx = 3
  )

  tkpack(ttklabel(anchorCtlFrame, text = " "), pady = 6)
  sapply(
    list(
      setAnchorNumBtn,
      fitBtn,
      anchorSizeAdd,
      anchorSizeDec,
      anchorColorFrame,
      labelAnchor,
      e$specimenNumLabel2,
      e$anchorNumLabel
    ),
    tkpack,
    pady = 3
  )
  return (anchorCtlFrame)


}





#configures buttons for digitize component
bind.digitize <- function(e)
{
  tkbind(e$canvasFrame, "<MouseWheel>", function(D) {
    zoom(e, D)
  })

  tkbind(e$canvasFrame, "<ButtonPress-1>", function(x, y) {
    onLeftBtnPress(e, x, y)
  })

  tkbind(e$canvasFrame, "<ButtonRelease-1>", function(x, y) {
    onLeftBtnRelease(e, x, y)
  })

  tkbind(e$canvasFrame, "<ButtonPress-3>", function(x, y) {
    deleteLandmark(e, x, y)
  })

  tkbind(e$canvasFrame, "<Motion>", function(x, y) {
    motion(e, x, y)
  }) #motion - events are generated when pointer is moved


  tkbind(e$canvasFrame, "<Double-Button-1>", function(x, y) {
    addDot(e, x, y) #Here is where double clicking calls the addDot function on canvas to place a landmark
  })
}




bind.anchor <- function(e)
{
  tkbind(e$canvasFrame, "<MouseWheel>", function(D) {
    zoom(e, D)
  })

  tkbind(e$canvasFrame, "<ButtonPress-1>", function(x, y) {
    onLeftBtnPress(e, x, y)
  })

  tkbind(e$canvasFrame, "<ButtonRelease-1>", function(x, y) {
    onLeftBtnRelease(e, x, y)
  })

  tkbind(e$canvasFrame, "<ButtonPress-3>", function(x, y) {
    deleteAnchor(e, x, y)
  })

  tkbind(e$canvasFrame, "<Motion>", function(x, y) {
    motion(e, x, y)
  }) #motion - events are generated when pointer is moved

  tkbind(e$canvasFrame, "<Double-Button-1>", function(x, y) {
    addAnchor(e, x, y)
  })
}





#changes color of landmark
onLmColorChange <- function(e)
{
  color <- tcl('tk_chooseColor')
  tkconfigure(
    e$lmColorLabel,
    text = 'aa',
    foreground = tclvalue(color),
    background = tclvalue(color)
  )
  color <- as.integer(gsub("#", "0x", tclvalue(color)))

  r <- as.integer(color / 0x10000)
  g <- as.integer((color %% 0x10000) / 0x100)
  b <- as.integer(color %% 0x100)
  e$dColor <- c(r / 255, g / 255, b / 255)
  set("dot", "dcolor", r / 255, g / 255, b / 255)
}


onAnchorColorChange <- function(e)
{
  color <- tcl('tk_chooseColor')
  tkconfigure(
    e$anchorColorLabel,
    text = 'aa',
    foreground = tclvalue(color),
    background = tclvalue(color)
  )
  color <- as.integer(gsub("#", "0x", tclvalue(color)))

  r <- as.integer(color / 0x10000)
  g <- as.integer((color %% 0x10000) / 0x100)
  b <- as.integer(color %% 0x100)
  e$daColor <- c(r / 255, g / 255, b / 255)
  set("dot", "acolor", r / 255, g / 255, b / 255)
}

#Sets action for dragging dots
onLeftBtnPress <- function(e, x, y)
{
  ##print ("onLeftBtnPress ... ")
  ##print (paste ("active data list : ", e$activeDataList) )
  ##print (paste ("         length  : ", length(e$activeDataList) ))

  if (0 == e$tab)
  {
    print ("e$tab is 0 : DIGITIZE")
  }

  if (1 == e$tab)
  {
    print ("e$tab is 1 : ANCHORS")
  }

  if (2 == e$tab)
  {
    print ("e$tab is 2 : SURFACE")
  }

  if (3 == e$tab)
  {
    print ("e$tab is 3 : CURVES")
  }

  if (4 == e$tab)
  {
    print ("e$tab is 4 : GPA")
  }



  if (length(e$activeDataList) > 0)
  {
    if (e$tab == 1)   ## this means we are on the anchors tab
    {

      ##print ("onLeftBtnPress ... calling set dot selected ... e$tab == 1")
      ##print (paste("  calling set/dot/selected :",x,y))

      result <- set("dot", "selected", x, y)

      ##print("onLeftBtnPress ... result from set dot selected ... ")
      ##print(result)

      if (result)
      {
        e$dragDot <- TRUE
        set(
          "dot",
          "anchorColor",
          as.double(1 / 255),
          as.double(164 / 255),
          as.double(191 / 255)
        )
      }
      else
      {
        e$dragDot <- FALSE
      }
    }
    else
    {

      ##print (paste("e$tab is : ", e$tab))
      ##print ("calling set dot selected ... else ... e$tab is NOT 1")
      ##print (paste("calling set/dot/selected :",x,y))

      result <- set("dot", "selected", x, y)

      ##print(paste ("3dDigitize.digitize line 463 result is : ", result))

      if (TRUE == result)
      {
        e$dragDot <- TRUE
        set("dot", "color", as.double(1 / 255), as.double(164 / 255),  as.double(191 / 255))
      }
      else
      {
        e$dragDot <- FALSE
      }
    }


    # wondering if assigning the drag variables should be conditioned on
    # the starus of e$dragDot
    e$dragX <- as.integer(x)
    e$dragY <- as.integer(y)
    ##print (paste (" line 481 ... drags : ", e$dragX, e$dragY))
  }
  ##print ("onLeftBtnPress ... end ")
}



#assigns chosen color value to selected dot
onLeftBtnRelease <- function(e, x, y)
{
  ##print ("onLeftBtnrelease ... ")
  if (length(e$activeDataList) > 0)
  {
    e$dragX <- as.integer(-1)
    e$dragY <- as.integer(-1)

    if (e$dragDot)
    {
      e$dragDot <- FALSE
      if (e$tab == 1)
      {
        color <- e$daColor
        ##print ("ready to call set dot anchorColor")
        set("dot", "anchorColor", color[1], color[2], color[3])
      }
      else
      {
        ##print ("ready to call set dot color")
        color <- e$dColor
        set("dot", "color", color[1], color[2], color[3])
      }
    }
  }
  ##print ("onLeftBtnrelease ... end ")
}






#Increase landmark or anchor point size
onLmSizeAdd <- function(e)
{
  if (length(e$activeDataList) == 0) {
    return()
  }


  font <- e$activeDataList[[e$currImgId]][[2]]

  if (e$tab == 1)
    set("dot", "anchorRadius", font + 0.001)
  else
    set("dot", "radius", font + 0.001)


  e$activeDataList[[e$currImgId]][[2]] <- font + 0.001
}




#Decrease landmark or anchor point size
onLmSizeDec <- function(e)
{
  if (length(e$activeDataList) == 0) {
    return()
  }

  font <- e$activeDataList[[e$currImgId]][[2]]

  if (e$tab == 1)
    set("dot", "anchorRadius", font - 0.001)
  else
    set("dot", "radius", font - 0.001)


  shows("all")   # 10 JUne 2020 ... this is NOT implemented in the  C code of TCL_If
  e$activeDataList[[e$currImgId]][[2]] <- font - 0.001
}





#draw label for landmark
onLabelLandMark <- function(e)
{
  print("onLabelLandMark")
  if (length(e$activeDataList) == 0)
  {
    return()
  }


  if (tclvalue(e$labelLandmarkVar) == "1")
  {
    print ("Calling set dot labeled 1")
    set("dot", "labeled", 1)
  }
  else
  {
    print ("Calling set dot labeled 0")
    set("dot", "labeled", 0)
  }
}



#draw label for anchor
onLabelAnchor <- function(e)
{
  #print("onLabelLandMark")
  if (length(e$activeDataList) == 0) {
    return()
  }

  if (tclvalue(e$labelAnchorVar) == "1")
  {
    set("dot", "alabeled", 1)
  }
  else
  {
    set("dot", "alabeled", 0)
  }
}




onPlaceAnchor <- function(e)
{
  if (e$activeDataList[[e$currImgId]][[3]] == e$landmarkNum &&
      tclvalue(e$placeAnchorsVar) == "1")
  {
    tcl(e$nb, "tab", 1, state = "normal")
    e$tabState[1] <- 1

    if (e$activeDataList[[e$currImgId]][[9]] != e$anchorNum)
    {
      for (i in 2:4)
      {
        tcl(e$nb, "tab", i, state = "disabled")
        e$tabState[i] <- 0
      }
    }
  }

  else
    return()
}



##
##   10 June 2020 ... why are most of these functions commented out ??

#Grabs user input and turns to first picture
onlandmarkNumOk <- function(e, win)
{
  #get user input value
  e$landmarkNum <- tclvalue(tkget(e$landmarkEntry))

  tkdestroy(win)

  print (paste("line 646 The number of landmarks is set to : ", e$landmarkNum) )


  # # turn to the first picture
  # if(length(e$activeDataList) > 0) {
  # 	e$currImgId <- 1
  # 	showPicture(e)
  # }
}




onanchorNumOk <- function(e, win)
{
  #get user input value
  e$anchorNum <- tclvalue(tkget(e$anchorEntry))

  tkdestroy(win)


  print (paste("line  602 The number of anchors is set to : ",  e$anchorNum) )



  # # turn to the first picture
  # if(length(e$activeDataList) > 0) {
  #     e$currImgId <- 1
  #     showPicture(e)
  # }
}





#Pop up window for setting number of landmarks
setLandmarkNum <- function(e)
{
  win <- tktoplevel()
  tkwm.title(win, "Set Landmark Number")

  entryFrame <- ttkframe(win)
  tkpack(
    entryFrame,
    expand = TRUE,
    fill = "both",
    padx = 5,
    pady = 5
  )
  label = tklabel(entryFrame, text = 'Set landmark Number: ')

  e$landmarkEntry = tkentry(entryFrame, textvariable = tclVar(e$landmarkNum))
  sapply(list(label, e$landmarkEntry),
         tkpack,
         side = "left",
         padx = 6)

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
        onlandmarkNumOk(e, win)
    )

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
}






#Pop up window for setting number of anchors
setAnchorNum <- function(e)
{
  win <- tktoplevel()
  tkwm.title(win, "Set Anchor Number")

  entryFrame <- ttkframe(win)
  tkpack(
    entryFrame,
    expand = TRUE,
    fill = "both",
    padx = 5,
    pady = 5
  )
  label = tklabel(entryFrame, text = 'Set anchor Number: ')

  e$anchorEntry = tkentry(entryFrame, textvariable = tclVar(e$anchorNum))
  sapply(list(label, e$anchorEntry),
         tkpack,
         side = "left",
         padx = 6)

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
        onanchorNumOk(e, win)
    )

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
}





#loads landmark file
loadLandmark <- function(e)
{
  fileStr <-
    tclvalue(
      tkgetOpenFile(
        filetypes = "{{landmark file} {.pts}} {{csv file} {.csv}}",
        multiple = FALSE,
        title = "Select landmark file"
      )
    )
  add("landmark", e$currImgId - 1, e$landmarkNum, fileStr)
  e$activeDataList[[e$currImgId]][[3]] <- e$landmarkNum
  tkconfigure(e$landMarkNumLabel,
              text = paste("Number of Landmarks: ", e$landmarkNum))
}





#pop up window to remove selected landmark
deleteLandmark <- function(e, x, y)
{
  #print("delete Dot")
  # turn to the first picture
  if (length(e$activeDataList) == 0) {
    return()
  }


  if (set("dot", "selected", x, y))
  {
    set("dot",
        "color",
        as.double(1 / 255),
        as.double(164 / 255),
        as.double(191 / 255))
    popUpRemoveWindow(e, x, y, 'Do you want to delete this landmark?', "digdot")
  }
}




deleteAnchor <- function(e, x, y)
{
  #print("delete Dot")
  # turn to the first picture
  if (length(e$activeDataList) == 0)
  {
    return()
  }


  if (set("dot", "selected", x, y))
  {
    set("dot",
        "anchorColor",
        as.double(1 / 255),
        as.double(164 / 255),
        as.double(191 / 255))
    popUpRemoveWindow(e, x, y, 'Do you want to delete this anchor?', "anchor")
  }
}





#starts to delete landmark
digRemoveDotOk <- function(e, x, y)
{
  msg <- del("dot")
  tkdestroy(e$removeWin)
  updateDotNum(e,-1)
}

#starts deletes anchor
digRemoveAnchorOk <- function(e, x, y)
{
  msg <- del("anchor")
  tkdestroy(e$removeWin)
  updateAnchorNum(e,-1)
}




#cancel to delete landmark
digRemoveDotCancel <- function(e, x, y)
{
  #print("digRemoveDotCancel")
  set("dot", "color", 1, 0, 0)
  tkdestroy(e$removeWin)
}



#cancel to delete anchor
digRemoveAnchorCancel <- function(e, x, y)
{
  #print("digRemoveDotCancel")
  set("dot", "anchorColor", 0, 1, 0)
  tkdestroy(e$removeWin)
}




#adds one landmark
addDot <- function(e, x, y)
{
  print(paste("line 908 : function addDot : ", x, y))
  if (length(e$activeDataList) > 0)
  {
    dotNum <- e$activeDataList[[e$currImgId]][[3]]
    print(paste("dotNum raw : ", dotNum+1, "-of- ",  e$landmarkNum ))

    if (dotNum < as.integer(e$landmarkNum))
    {

      coord <- convertCoor(e, x, y)
      ## print (paste ("these are the coordinates generated by R :", coord [1], coord[2], coord[3]))

      ## This is provided for manual capture of digitized points for future testing needs
      print ("LANDMARK : Coordinate Data for post processing use : ")
      print( paste( "x y, X,Y, Z : ", x, y, coord [1], coord[2], coord[3]))


      result <- add("dot", coord[1], coord[2], coord[3])
      print(paste("LINE 929 !  Result from add dot ...", result))

      if (TRUE == result)
      {
        print(coord)
        updateDotNum(e, 1)
      }
      else
      {
        print("WARNING : add dot : not inside the specimen")
      }
    }
  }
  else
  {
    print("WARNING : no specimen opened")
  }
}






#adds one anchor point
addAnchor <- function(e, x, y)
{
  print(paste("line 954 : function addAnchor : ", x, y))
  if (length(e$activeDataList) > 0)
  {
    anchorNum <- e$activeDataList[[e$currImgId]][[9]]
    print(paste("dotNum raw : ", anchorNum+1, "-of- ",  e$anchorNum ))

    if (anchorNum < as.integer(e$anchorNum))
    {
      coord <- convertCoor(e, x, y)

      ## This is provided for manual capture of digitized points for future testing needs
      print ("ANCHOR : Coordinate Data for post processing use : ")
      print( paste( "x y,  X,Y,  Z : ", x, y, coord [1], coord[2], coord[3]))



      if (TRUE == add("anchor", coord[1], coord[2], coord[3]))
      {
        updateAnchorNum(e, 1)
      }
      else
      {
        print("WARNING : place anchor : not inside the specimen")
      }
    }
  }
  else
  {
    print("WARNING : no specimen opened")
  }
}


#updates real number of landmarks in database after deletion or insertion of landmark
updateDotNum <- function(e, delt)
{
  nDots <- e$activeDataList[[e$currImgId]][[3]]
  nDots <- nDots + delt
  tkconfigure(e$landMarkNumLabel, text = paste("Number of Landmarks: ", nDots))
  e$activeDataList[[e$currImgId]][[3]] <- nDots
  print (paste("Updated number of (landmarks) dots", nDots))


  if (nDots == e$landmarkNum && tclvalue(e$placeAnchorsVar) == "1")
  {
    tcl(e$nb, "tab", 1, state = "normal")
    e$tabState[1] <- 1
  }
  else if (nDots == e$landmarkNum &&
           tclvalue(e$placeAnchorsVar) == "0")
  {
    for (i in 2:4)
    {
      tcl(e$nb, "tab", i, state = "normal")
      e$tabState[i] <- 1
    }
  }

}


updateAnchorNum <- function(e, delt)
{
  nAnchors <- e$activeDataList[[e$currImgId]][[9]]
  nAnchors <- nAnchors + delt
  tkconfigure(e$anchorNumLabel, text = paste("Number of Anchors: ", nAnchors))
  e$activeDataList[[e$currImgId]][[9]] <- nAnchors
  print (paste("Updated number of (anchors) dots", nAnchors))


  if (nAnchors == e$anchorNum)
  {
    for (i in 2:4)
    {
      tcl(e$nb, "tab", i, state = "normal")
      e$tabState[i] <- 1
    }
  }
}



#updates real values for widgets
updateWidgets.digitize <- function(e)
{
  #print("updateWidgets.digitize ")
  dotNum <- e$activeDataList[[e$currImgId]][[3]]
  tkconfigure(e$landMarkNumLabel, text = paste("Number of Landmarks: ", dotNum))
  tkconfigure(e$imgPath, text = paste("Specimen Id: ", e$activeDataList[[e$currImgId]][[1]]))
}




updateWidgets.anchor <- function(e)
{
  anchorNum <- e$activeDataList[[e$currImgId]][[9]]
  tkconfigure(e$anchorNumLabel, text = paste("Number of Anchors: ", anchorNum))
  tkconfigure(e$imgPath, text = paste("Specimen Id: ", e$activeDataList[[e$currImgId]][[1]]))
}




#reads .dgt files
read.digitize <- function(e, content)
{
  print ("file 3dDigitize.digitize ... function read.digitize")
  ignore.case = TRUE
  lmdata <- grep("LM3=", content, ignore.case)
  nlands <-
    as.numeric(sub("LM3=", "", content[lmdata], ignore.case))
  k <- 3

  if (max(nlands) - min(nlands) != 0)
  {
    stop("Number of landmarks not the same for all specimens.")
  }

  nSpecimen <- length(lmdata)
  nland <- nlands[1]

  startLines <- lmdata + 1
  endLines <- as.numeric(lmdata) + as.numeric(nlands)
  coords <- array(0, c(nland, 3, nSpecimen))

  for (i in 1:nSpecimen)
  {
    tmp <- content[startLines[i]:endLines[i]]
    coords[, , i] <-
      matrix(as.numeric(unlist(strsplit(tmp, " "))), ncol = 3, byrow = TRUE)
  }

  # 5/4/2020 - EOC added conditional statement to check whether .dgt ID (each .ply file)
  # already includes a file path
  # or if the path to the .dgt file needs to be added to each .ply file

  if (grepl("/.", sub("ID=", "", content[grep("ID=", content, ignore.case)], ignore.case)[1])) {
    ID <-
      sub("ID=", "", content[grep("ID=", content, ignore.case)], ignore.case)
  }
  else
  {
    ID <- paste(e$dgtPath, "/",
                sub("ID=", "", content[grep("ID=", content, ignore.case)], ignore.case), sep =
                  "")
    print("line 958")
  }


  if (grepl("/.", sub("ID=", "", content[grep("ID=", content, ignore.case)], ignore.case)[1])) {
    ID <-
      sub("ID=", "", content[grep("ID=", content, ignore.case)], ignore.case)
  }
  else
  {
    ID <- paste(e$dgtPath, "/",
                sub("ID=", "", content[grep("ID=", content, ignore.case)], ignore.case), sep =
                  "")
    print("line 971")
  }


  print(ID)
  if (length(ID) != 0)
  {
    dimnames(coords)[[3]] <- as.list(ID)
  }



  print ("file 3dDigitize.digitize ... function read.digitize ... end")
  return(coords)
}







read.anchors <- function(content)
{
  ignore.case <- TRUE
  acdata <- grep("AC3=", content, ignore.case)
  nanchors <- as.numeric(sub("AC3=", "", content[acdata], ignore.case))

  if (anyNA(nanchors))
  {
    #make more robust
    print("Missing anchors")
    return()
  }
  else
  {
    if (max(nanchors) - min(nanchors) != 0)
    {
      stop("Number of anchors not the same for all specimens.")
    }
  }

  nSpecimen <- length(acdata)
  nanchor <- nanchors[1]

  startLines <- acdata + 1
  endLines <- as.numeric(acdata) + as.numeric(nanchors)
  coords <- array(0, c(nanchor, 3, nSpecimen))

  for (i in 1:nSpecimen)
  {
    tmp <- content[startLines[i]:endLines[i]]
    coords[, , i] <-
      matrix(as.numeric(unlist(strsplit(tmp, " "))), ncol = 3, byrow = TRUE)
  }

  ID <- sub("ID=", "", content[grep("ID=", content, ignore.case)], ignore.case)
  #print(paste ("File names associated with anchors is ", ID))
  if (length(ID) != 0)
  {
    dimnames(coords)[[3]] <- as.list(ID)
  }

  for (ii in 1:(length(ID)) )
  {
    print ( paste( "read.anchors : file name ", ii, ":", ID[ii] ) )
  }

  return(coords)
}





#writes data to .dgt file
write.digitize <- function(fileName, Id, landmarks, anchors)
{
  lmline <- paste("LM3=", nrow(landmarks), sep = "")
  write(lmline, fileName, append = TRUE)
  write.table(
    landmarks,
    fileName,
    col.names = FALSE,
    row.names = FALSE,
    append = TRUE
  )
}

write.anchors <- function(fileName, Id, anchors)
{
  acline <- paste("AC3=", nrow(anchors), sep = "")
  write(acline, fileName, append = TRUE)
  if (length(anchors) != 0)
    write.table(
      anchors,
      fileName,
      col.names = FALSE,
      row.names = FALSE,
      append = TRUE
    )
  else
    write("NULL", fileName, append = TRUE)
  idline <- paste("ID=", Id, sep = "")
  write(idline, fileName, append = TRUE)
}

# displays specimen and landmark in canvas
# specimen numbers are 1 based !
draw.digitize <- function(e, id, specimen, landmarks)
{

  sliceID <- id
  add("queryFromR", 1, sliceID);
  add("queryFromR", 2, sliceID);


  if (0 == e$landmarksPresentInMemory)
  {

    print ("file 3dDigitize.digitize ... function draw.digitize ... line 1229" )
    print( paste("specimen id is ", id))

    print (paste("loading PLY file for specimen ", id))
    add("specimen", specimen, id)   # load model in

    # we must set the specimen after load ing the PLY file data
    # and tcl_if.c knows min/max values

    set("specimen", "id", id)

    #print (paste("landmark nRows", nrow(landmarks)))
    #print (paste("landmark nCols", ncol(landmarks)))

    #print(paste("Adding landmark for specimen ", id))



    add("SetLandmarkIndex", id, -1, -2)
    for (j in 1:nrow(landmarks))
    {
      print (paste("index j", j, "landmarks", landmarks[j, 1], landmarks[j, 2], landmarks[j, 3] ))
      add("rawdot", landmarks[j, 1], landmarks[j, 2], landmarks[j, 3])
    }
    add("InfoLandmarks_complete", 1, -1, -2)
  }
  else
  {
    print ("landmarks already loaded in memory ... skipped adding more landmarks")
  }


  add("queryFromR", 1, sliceID);
  add("queryFromR", 2, sliceID);
  print ("file 3dDigitize.digitize ... function draw.digitize ...  end line 1257" )

}




# This function still in work ??
#
draw.anchors <- function(id, anchors)
{
  if (!anyNA(anchors))
  {



    if (0 == e$anchorsPresentInMemory)
    {
      print (paste("Anchor rows this specimen ", nrow(anchors)))
      add("SetAnchorIndex", id, 0,0)
      messageToC( paste("function draw.anchors : id ", id))
      for (j in 1:nrow(anchors))
      {
        print (paste("index j", j, "anchor points", anchors[j, 1], anchors[j, 2], anchors[j, 3] ))
        add("rawanchor", anchors[j, 1], anchors[j, 2], anchors[j, 3])
      }
      add("InfoAnchors_complete", 0, 0,0)
    }
    else
    {
      print ("anchors already loaded in memory ... skipped adding more anchors")
    }
  }
  else
  {
    print("Missing anchors")
    return()
  }
  return()
}

