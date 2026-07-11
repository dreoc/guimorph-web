# Developers to update this function
get_rtkogl_date <- function()
{
  dbg("GUImorph 0.9.0 - rtkogl")
}

#calls tkogl2 add function / returns shape object and displays to canvas
add <- function(shape, arg1, arg2, arg3)
{
  #print (shape)
  #print (arg1)
  #print (arg2)

  # first step is to explicitly handle the debugging commands that were added
  # and which are NOT part of the original operations code

  if (shape == "getCompileInformation")
  {
    result <- tclvalue(tcl("add", shape, -1, -2, -3))  # returns a string
    dbg(result)
    return (TRUE)
  }
  else if (shape == "startRecording")
  {
    ## result <- tclvalue(tcl("add", shape, arg1, arg2, 0))
    result <- tcl("add", shape, arg1, arg2, 0)
    dbg(result)
    return (TRUE)
  }
  else if (shape == "endRecording")
  {
    result <- tcl("add", shape, arg1, arg2, 0)
    dbg(result)
    return (TRUE)
  }
  else if (shape == "openLogFile")
  {
    ##result <- tclvalue(tcl("add", shape, arg1, arg2, 0))
    result <- tcl("add", shape, arg1, arg2, 0)
    dbg(result)
    return (TRUE)
  }
  else if (shape == "closeLogFile")
  {
    result <- tcl("add", shape, arg1, arg2, 0)
    dbg(result)
    return (TRUE)
  }
  else if (shape == "logMessage")
  {
    dbg("logMessage ..............")
    dbg(paste ("SHAPE : ",shape))
    dbg(paste ("ARG 1 : ",arg1))
    dbg(paste ("ARG 2 : ",arg2))
    result <- tcl("add", shape, arg1, arg2, 0)
    dbg(paste ("normal result >",result,"<"))
    return (result)
  }
  else if (shape == "initialize")
  {
    result <- tcl("add", shape, arg1, arg2, 0)  # arg1 is the main selector and arg2 is the option applicable to arg1
    dbg(result)
    return (TRUE)
  }
  else if (shape == "rotationAngles")
  {
    ##print (paste ("Rotation Angles x : ", arg1))
    ##print (paste ("Rotation Angles y : ", arg2))
    result <- tcl("add", shape, arg1, arg2, 0)
    ##print(paste ("normal result >",result,"<"))
    return (TRUE)
  }
  else if (shape == "snapshot")   #added 22 may 2020 for developer use ONLY
  {
    result <- tcl("add", shape, arg1, 0, 0)
    return (TRUE)
  }
  else if (shape == "invoke_draw_grid")   #added 22 may 2020 for developer use ONLY
  {
    result <- tcl("add", shape, 0, 0, 0)
    return (TRUE)
  }

  else if (shape == "EraseVertexData" )
  {
    result <- tcl("add", shape, arg1, 0, 0)
    return (TRUE)
  }

  else if (shape == "EraseDownSampleData" )
  {
    result <- tcl("add", shape, arg1, 0, 0)
    return (TRUE)
  }

  else if (shape == "queryFromR")   #added 06 August in developemnt
  {
    # arg1 assignments
    # 1 : query number of landmarks in memory for the specified array slice
    #     a string is returned
    # 2 : query number of landmarks in memory for the specified array slice
    #     a character string that represents a number is returned
    # 3: query number of anchors in memory for the specified array slice
    #     a string is returned
    # 4 : query number of anchors in memory for the specified array slice
    #     a character string that represents a number is returned


    dbg(paste ("add", shape, "arg1",  arg1, "arg2", arg2))
    result <- tclvalue(tcl("add", shape, arg1, arg2, 0))  # arg 1 is an integer for selecting the query arg 2 is the option
    dbg(paste("queryFromR  ... result :", result))

    if (2 == arg1)
    {
      landmarksAlready <- suppressWarnings(as.integer(result))
      if (is.na(landmarksAlready)) landmarksAlready <- 0L
      dbg(paste("landmarks already in C code", landmarksAlready))
    }

    if (4 == arg1)
    {
      anchorsAlready <- suppressWarnings(as.integer(result))
      if (is.na(anchorsAlready)) anchorsAlready <- 0L
      dbg(paste("anchors already in C code", anchorsAlready))
    }


    return (TRUE)
  }
  else if (shape == "messageFromR")   #added 06 August in developemnt
  {
    result <- tcl("add", shape, arg1, 0,0)  # only arg1 used : It should be a string
    return (TRUE)  # TCL_OK is always returned
  }
  else if (shape == "specimen")
  {
    if(0)
    {
      dbg(paste ("function add " , shape , "calling the tcl_if function"))
      dbg(paste( "arg1 : ", arg1))
      dbg(paste( "arg2 : ", arg2))
    }
    result <- tcl("add", shape, arg1, arg2)
    if(1)
    {
      dbg(paste ("add specimen result is :",result))
    }
  }
  else if ( shape == "downsample")
  {
    dbg(paste("add downsample : ", arg1, arg2))
    result <- tcl("add", shape, arg1, arg2,0)
    dbg(paste("add downsample ... result : <", result,">"))
  }
  else if (shape == "InfoLandmarks" )
  {
    # added this capability ... tell tcl_if how many landmark sets,
    # rows, columns and again number of speciments
    dbg("function add InfoLandmarks")
    dbg(shape)
    dbg(arg1)    # number of landmark sets
    dbg(arg2)    # nrows
    dbg(arg3)    # columns
    result <- tcl("add", shape, arg1, arg2, arg3)
  }
  else if (shape == "SetLandmarkIndex" )
  {
    dbg("function add SetLandmarkIndex")
    dbg(shape)
    dbg(arg1)    # which landmark set ... 1 based in R
    result <- tcl("add", shape, arg1, -1, -2)
  }
  else if (shape == "InfoLandmarks_complete" )
  {
    dbg("function add InfoLandmarks_complete")
    dbg(shape)
    dbg(arg1)    # which set of landmarks 1 based in R
    result <- tcl("add", shape, arg1, -1, -2)
  }

  else if (shape == "InfoAnchors" )
  {
    # added this capability ... tell tcl_if how many anchor sets,
    # rows, columns and again number of speciments
    dbg("function add InfoAnchors")
    dbg(shape)
    dbg(arg1)    # number of anchor sets
    dbg(arg2)    # nrows
    dbg(arg3)    # columns
    result <- tcl("add", shape, arg1, arg2, arg3)
  }
  else if (shape == "SetAnchorIndex" )
  {
    dbg("function add SetAnchorIndex")
    dbg(shape)
    dbg(arg1)
    result <- tcl("add", shape, arg1, -1, -2)
  }
  else if (shape == "InfoAnchors_complete" )
  {
    dbg("function add InfoAnchors_complete")
    dbg(shape)
    dbg(arg1)    # which set of landmarks 1 based in R
    result <- tcl("add", shape, arg1, -1, -2)
  }
  else if (shape == "InfoCurves" )
  {
    # added this capability ... tell tcl_if how many curves, curve length,
    # and again number of specimens
    dbg("function add InfoCurves")
    dbg(shape)
    dbg(arg1)    # number of curves
    dbg(arg2)    # curve length
    dbg(arg3)    # number of specimens (again)
    result <- tcl("add", shape, arg1, arg2, arg3)
  }
  else if (shape == "SetCurveIndex" )
  {
    dbg("function add SetCurveIndex")
    dbg(shape)
    dbg(arg1)   # which curve index 1 based
    #print(arg2)
    # print(arg3)
    result <- tcl("add", shape, arg1, -1, -2)
  }
  else if (shape == "InfoCurves_complete" )
  {
    dbg("function add InfoCurves_complete")
    dbg(shape)
    dbg(arg1)    # which curve is complete
    #print(arg2)
    #print(arg3)
    result <- tcl("add", shape, arg1, -1, -2)
  }
  else if (shape == "curve" )
  {
    dbg("function add curve")
    dbg(shape)
    dbg(arg1)
    dbg(arg2)
    dbg(arg3)
    result <- tclvalue(tcl("add", shape, arg1, arg2, arg3))
    dbg(paste("Result from tcl add", result))
    if (startsWith(result, "WARNING"))
    {
      return (FALSE)
    }
    else
    {
      return (TRUE)
    }
  }
  else if (shape == "dot"       ||
           shape == "rawdot"    ||
           shape == "rawanchor" ||
           shape == "landmark"  ||
           shape == "anchor")
  {
    if(0)
    {
      dbg("function add line 215")
      dbg(paste ("Shape : ",shape))
      dbg(paste ("arg1 : ",arg1))
      dbg(paste ("arg2 : ",arg2))
      dbg(paste ("arg3 : ",arg3))
      dbg("------------------------")
    }

    result  <- tclvalue(tcl("add", shape, arg1, arg2, arg3))
    dbg(paste("Result from tcl add", result))
    if (startsWith(result, "WARNING"))
    {
      return (FALSE)
    }
    else
    {
      return (TRUE)
    }
  }
  else if (shape == "setLabelScaleFactor")
  {
    dbg("test case setLabelScaleFactor")
    #print(arg1)
    #print(arg2)
    # print(arg3)
    result <- tcl("add", shape, arg1, arg2, arg3)
    dbg(paste("result : ", result))
    return (TRUE)
  }
  else if (shape == "setCurveScaleFactor")
  {
    #print ("---------------------------------")
    #print ("---------------------------------")
    dbg("test case setCurveScaleFactor")
    #print(arg1)
    #print(arg2)
    #print(arg3)
    result <- tcl("add", shape, arg1, arg2, arg3)
    dbg(paste("result : ", result))
    #print ("---------------------------------")
    #print ("---------------------------------")
    return (TRUE)
  }
  else if (shape == "reset_state")
  {
    dbg("test case reset_state")
    result <- tcl("add", shape, -3, -2, -1)
    dbg(paste("result : ", result))
    return (TRUE)
  }



  else if (shape == "curveSetDotSliderColor")
  {
    result <- tcl("add", shape, arg1, -2, -1)
    dbg(paste("result : ", result))
    return (TRUE)
  }



  else
  {
    dbg(paste("function add unknown shape <", shape,">"))
    dbg("Usage: add specimen path_of_ply")
    dbg("Usage: add dot x y z")
    return(FALSE)
  }
}






#calls tkogl2 del function / removes specified shape object
del <- function(shape, arg1 = -1, arg2 = -1, arg3 = -1)
{

  # design decision June 2020
  # the function calls to tcl_if MUST provide three arguments
  # for unused arguments in tcl_if pass negative integers
  #
  # The remove-dot / remove-anchor GUI flow deletes the *selected* marker, so it
  # calls del("dot") / del("anchor") with no coordinates. The C `del` command
  # uses objc==2 to mean "delete selected" (dot_del_selected / anchor_del_selected)
  # and objc>2 to mean "delete at coordinate". Passing placeholder negatives would
  # wrongly route to the coordinate path, so the selected-marker calls below omit
  # the extra arguments. arg1..arg3 default to -1 so the diagnostic prints and any
  # coordinate-aware callers still work without an "argument missing" error.


  dbg("function del")
  dbg(shape)
  dbg(arg1)
  dbg(arg2)
  dbg(arg3)

  if (shape == "dot")
  {
    result <- tcl("del", "dot")

  }
  else if (shape == "dots")
  {
    result <- tcl("del","Xdots", arg1, arg2, arg3)

  }
  else if (shape == "anchor")
  {
    result <- tcl("del", "anchor")

  }
  else if (shape == "anchors")
  {
    result <- tcl("del", "xanchors", arg1, -1, -2)

  }
  else if (shape == "specimen")
  {
    result <- tcl("del", shape, arg1, -1, -2)
  }
  else
  {
    dbg("Usage: del dot [...]")
    return(FALSE)
  }
  return(FALSE)
}






#' GUImorph
#' @export
GUImorph <- function(debug = FALSE) {
  options(guimorph.debug = isTRUE(debug))
  e <- new.env()
  class(e) <- "main"
  ui(e)
  invisible(init(e))
}










# As of 06 JUne 2020 it appears that this function is NOT used
# It is provided here as a placeholder with anticipation that
# it will be implemented soon.
# This anticipated capability will be implemented in C with access
# via the tcl_if functions
#

#' loadDGT
#' @export
loadDgt <- function(fileName)
{
  dbg("function loadDgt")
  dbg(fileName)
  result <- tclvalue(tcl("loadDgt", fileName))
  if (startsWith(result, "ERROR"))
  {
    dbg("ERROR return from tcl_if loadDgt function")
    return(FALSE)
  }
  else if (startsWith(result, "SUCCESS"))
  {
    dbg("Success from tcl_if loadDgt")
    return(TRUE)
  }
  else if (startsWith(result, "IGNORE"))
  {
    dbg("IGNORE return from tcl_if loadDgt function")
  }
  else if (startsWith(result, "UNDER_CONSTRUCTION"))
  {
    dbg("UNDER CONSTRUCTION C code in tcl_if (.c) file still in work !")
    return(FALSE)
  }
  else
  {
    dbg("Unknown return value from tcl_if loadDgt")
    dbg(result)
  }
  return(FALSE)
}









#loads tkogl2 functions during loading
.onLoad <- function(libname, pkgname)
{
  chname <- "tkogl2"
  file.ext <- .Platform$dynlib.ext #dll file
  dlname <- paste(chname, file.ext, sep = "")

  if (is.character(.Platform$r_arch) && .Platform$r_arch != "")
  {
    path <- file.path("libs", .Platform$r_arch, dlname)
  }
  else
  {
    path <- file.path("libs", dlname)
  }

  file <-
    system.file(path, package = pkgname, lib.loc = libname)[1] #grabs full file name

  dbg("File 3dDigitize.main ... function .onload")
  dbg(file)
  dbg("-----------------")
  tryCatch(
    tcl("load", file, "Tkogl2"),
    error = function(e)
      warning("loading tkogl2 failed", call. = FALSE)
  ) #replace directory with file
}







#calls tkogl2 shows function / returns string value shape object with specified attributes
shows <- function(shape, attr, arg1, arg2)
{
  dbg("function shows ... line 329")
  dbg(paste ("Shape is : ", shape))
  #print(paste ("attr is  : ", attr))     # dave ... need to find out how to determine argument existence

  if (shape == "specimen")
  {
    dbg(paste("attr : " , attr))
    if (attr == "xyz")
    {
      dbg(paste ("arg1 is  : ", arg1) )
      dbg(paste ("arg2 is  : ", arg2) )
      result <- tcl("show", shape, attr, arg1, arg2,0)
      dbg(result)
    }
  }
  else if (shape == "landmark")
  {
    if (attr == "xyz")
    {
      dbg(paste("attr : " , attr))
      result <- tcl("show", shape, attr, arg1,0, 0)
      dbg(paste ("RESULT : <", result, ">"))
      return (result)

    }
    else if (attr == "id")
    {
      dbg(paste("attr : " , attr))
      result <- tcl("show", shape, attr, 0,0, 0)
    }
  }
  else if (shape == "anchor")
  {
    if (attr == "xyz")
    {
      dbg(paste("attr : " , attr))
      result <- tcl("show", "anchor", "xyz", arg1,0,0)
      dbg(paste ("RESULT : <", result, ">"))
    }
    else if (attr == "id")
    {
      dbg(paste("attr : " , attr))
      result <- tcl("show", shape, attr,0,0,0)
    }
  }
  else if (shape == "all")
  {
    ## THIS OPTION IS NOT IMPLEMENTED IN THE CURRENT C CODE
    ## THIS OPTION WAS NOT IMPLEMENTED IN THE LEGACY CODE

    dbg("function show all ... line 337")
    result <- tcl("show", shape)
    dbg(paste("return from tcl_if :", result))

  }
  else
  {
    dbg("Usage: shows specimen [xyz] ...")
    dbg("Usage: shows landmark [reqxyz|id] ...")
    dbg("Usage: shows all")
    return(FALSE)
  }
  return (result)
}



#calls tkogl2 set function / assigns gui object to arg value

# since this function signature accompdates up to 3 arguments
# all calls into the tcl_if .c code shall provide three arguments
#
set <- function(shape, attr, arg1, arg2, arg3)
{
  if(0)
  {
    dbg("function ... set at line 541")
    dbg( paste ("Shape : ", shape) )
    dbg( paste ("attr  : ", attr )  )
    dbg("------------------")
  }


  if (shape == "window")
  {
    if (attr == "id")
    {
      id <- tkwinfo("id", arg1)
      ##print (paste("id is : ", id))
      result <- tcl("setWindow", attr, id, -1, -2, -3)
      ##print(paste("set window id ... result : <", result,">"))
      return (TRUE)

    }
    else if (attr == "mode")
    {
      dbg(arg1)
      result <- tcl("setWindow", attr, arg1, 0, 0, 0)
      dbg(paste("set window mode ... result : <", result, ">"))
      return (TRUE)

    }
    else if (attr == "size")
    {
      ##print(arg1)
      ##print(arg2)
      result <- tclvalue(tcl("setWindow", attr, arg1, arg2, -1))   ## string returned
      #print(paste("set window size ... result : <", result,">"))
    }
  }
  else if (shape == "specimen")
  {
    if (attr == "scale" || attr == "allocate" || attr == "id")
    {
      if(0)
      {
        dbg(shape)
        dbg(attr)
        dbg(arg1)
        dbg("Now calling the setSpecimen function if tcl_if")
      }
      result <- tclvalue(tcl("setSpecimen", attr, arg1, 0, 0))
      if(0)
      {
        dbg(paste("set specimen ", attr, "... result : <", result,">"))
      }

    }
    else if (attr == "move")
    {
      dbg(arg1)
      dbg(arg2)
      dbg(arg3)
      result <- tcl("setSpecimen", attr, arg1, arg2, arg3)
      dbg(paste ("set specimen ",attr, " ... result : <", result,">"))
    }
    else if (attr == "angle")
    {
      if(0)
      {
        dbg(paste("rtkolg : set specimen angle", arg1, arg2))
        #print(arg1)
        #print(arg2)
      }

      # example return string : 'Rotate: 0.000000 -8.400000 0.000000'
      result <- tclvalue(tcl("setSpecimen", attr, arg1, arg2, 0))      ## returns a string
      if(0)
      {
         dbg(paste ("set specimen angle ... result : <", result,">"))
      }
    }
    else
    {
      dbg(paste("shape specimen ...Not supported attribute", attr))
    }
  }
  else if (shape == "downsample")
  {
    dbg("set downsample")
    dbg(arg1)
    dbg(arg2)
    result <- tcl("set DownSample", attr, arg1, arg2, 0)
    dbg(paste ("set DownSample ... result : <", result,">"))

  }
  else if (shape == "dot")
  {
    if (attr == "labeled"      ||
        attr == "radius"       ||
        attr == "anchorRadius" ||
        attr == "alabeled")
    {
      ## In the C code, these options ONLY return tcl_ok  06 August 2020
      ##print (paste ("setDot ... attr ", attr, " arg1 ", arg1))
      result <- tclvalue(tcl("setDot", attr, arg1, -2, -1))
      ##print (paste("set dot labeled ... result :", result))
      return (TRUE)

    }
    else if (attr == "selected")
    {
      dbg(paste("set dot selected : arg_1", arg1))
      dbg(paste("set dot selected : arg_2", arg2))
      result <-  tclvalue(tcl("setDot", attr, arg1, arg2, 0))    ## possible return of a string !

      dbg(paste ("set dot selected ... result : ", result))
      if (startsWith(result, "WARNING"))
      {
        dbg(paste("---------", result, "---------") )
        return (FALSE)
      }
      else
      {
        dbg(paste("---- GOT DOT ----") )
        dbg(paste("---- GOT DOT ----") )
        return (TRUE)
      }
    }
    else if (attr == "dotColorRestore")
    {
      ##fucntion arguments arg1, arg2, arg3 and NOT used
      result <- tclvalue(tcl("setDot", attr, arg1, arg2, arg3))
      dbg(paste ("set dot ", attr,  "... result : ", result))
      return (TRUE)
    }
    else if (attr == "coordinate"  ||
             attr == "dcolor"      ||
             attr == "acolor"      ||
             attr == "anchorColor" ||
             attr == "color")
    {
      dbg(arg1)
      dbg(arg2)
      dbg(arg3)
      result <- tclvalue(tcl("setDot", attr, arg1, arg2, arg3))
      dbg(paste ("set dot ", attr,  "... result : ", result))
      return (TRUE)
    }

  }
  else
  {
    dbg("Usage: set window [id|size]")
    dbg("Usage: set specimen [amount|id|scale|angle]")
    dbg("Usage: set dot [selected|coordinate|color|dcolor|labeled|radius]")
    return(FALSE)
  }
  return(TRUE)
}




# gated debug printer: prints only when options(guimorph.debug=TRUE),
# which GUImorph(debug=TRUE) sets. Preserves every debugging note.
dbg <- function(...) if (isTRUE(getOption("guimorph.debug", FALSE))) print(...)

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "GUImorph ", utils::packageVersion(pkgname), " (beta) - Windows only\n",
    "3D geometric morphometric digitizing for the geomorph ecosystem.\n",
    "Issues / updates: https://github.com/dreoc/GUImorph"
  )
}
