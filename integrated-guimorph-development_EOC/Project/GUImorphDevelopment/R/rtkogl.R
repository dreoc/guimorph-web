# Developers to update this function
get_rtkogl_date <- function()
{
  print ("rtlogl 15 August 2020")
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
    print(result)
    return (TRUE)
  }
  else if (shape == "startRecording")
  {
    ## result <- tclvalue(tcl("add", shape, arg1, arg2, 0))
    result <- tcl("add", shape, arg1, arg2, 0)
    print(result)
    return (TRUE)
  }
  else if (shape == "endRecording")
  {
    result <- tcl("add", shape, arg1, arg2, 0)
    print(result)
    return (TRUE)
  }
  else if (shape == "openLogFile")
  {
    ##result <- tclvalue(tcl("add", shape, arg1, arg2, 0))
    result <- tcl("add", shape, arg1, arg2, 0)
    print(result)
    return (TRUE)
  }
  else if (shape == "closeLogFile")
  {
    result <- tcl("add", shape, arg1, arg2, 0)
    print(result)
    return (TRUE)
  }
  else if (shape == "logMessage")
  {
    print ("logMessage ..............")
    print (paste ("SHAPE : ",shape))
    print (paste ("ARG 1 : ",arg1))
    print (paste ("ARG 2 : ",arg2))
    result <- tcl("add", shape, arg1, arg2, 0)
    print(paste ("normal result >",result,"<"))
    return (result)
  }
  else if (shape == "initialize")
  {
    result <- tcl("add", shape, arg1, arg2, 0)  # arg1 is the main selector and arg2 is the option applicable to arg1
    print(result)
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


    print (paste ("add", shape, "arg1",  arg1, "arg2", arg2))
    result <- tclvalue(tcl("add", shape, arg1, arg2, 0))  # arg 1 is an integer for selecting the query arg 2 is the option
    print (paste("queryFromR  ... result :", result))

    if (2 == arg1)
    {
      landmarksAlready <- as.integer(result)
      print (paste ("landmarks already in C code", landmarksAlready))
      e$landmarksPresentInMemory <- as.integer (landmarksAlready)
    }

    if (4 == arg1)
    {
      anchorsAlready <- as.integer(result)
      print (paste ("anchors already in C code", anchorsAlready))
      e$anchorsPresentInMemory <-  as.integer(anchorsAlready)
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
      print (paste ("function add " , shape , "calling the tcl_if function"))
      print (paste( "arg1 : ", arg1))
      print (paste( "arg2 : ", arg2))
    }
    result <- tcl("add", shape, arg1, arg2)
    if(1)
    {
      print(paste ("add specimen result is :",result))
    }
  }
  else if ( shape == "downsample")
  {
    print(paste("add downsample : ", arg1, arg2))
    result <- tcl("add", shape, arg1, arg2,0)
    print(paste("add downsample ... result : <", result,">"))
  }
  else if (shape == "InfoLandmarks" )
  {
    # added this capability ... tell tcl_if how many landmark sets,
    # rows, columns and again number of speciments
    print ("function add InfoLandmarks")
    print(shape)
    print(arg1)    # number of landmark sets
    print(arg2)    # nrows
    print(arg3)    # columns
    result <- tcl("add", shape, arg1, arg2, arg3)
  }
  else if (shape == "SetLandmarkIndex" )
  {
    print ("function add SetLandmarkIndex")
    print(shape)
    print(arg1)    # which landmark set ... 1 based in R
    result <- tcl("add", shape, arg1, -1, -2)
  }
  else if (shape == "InfoLandmarks_complete" )
  {
    print ("function add InfoLandmarks_complete")
    print(shape)
    print(arg1)    # which set of landmarks 1 based in R
    result <- tcl("add", shape, arg1, -1, -2)
  }

  else if (shape == "InfoAnchors" )
  {
    # added this capability ... tell tcl_if how many anchor sets,
    # rows, columns and again number of speciments
    print ("function add InfoAnchors")
    print(shape)
    print(arg1)    # number of anchor sets
    print(arg2)    # nrows
    print(arg3)    # columns
    result <- tcl("add", shape, arg1, arg2, arg3)
  }
  else if (shape == "SetAnchorIndex" )
  {
    print ("function add SetAnchorIndex")
    print(shape)
    print(arg1)
    result <- tcl("add", shape, arg1, -1, -2)
  }
  else if (shape == "InfoAnchors_complete" )
  {
    print ("function add InfoAnchors_complete")
    print(shape)
    print(arg1)    # which set of landmarks 1 based in R
    result <- tcl("add", shape, arg1, -1, -2)
  }
  else if (shape == "InfoCurves" )
  {
    # added this capability ... tell tcl_if how many curves, curve length,
    # and again number of specimens
    print ("function add InfoCurves")
    print(shape)
    print(arg1)    # number of curves
    print(arg2)    # curve length
    print(arg3)    # number of specimens (again)
    result <- tcl("add", shape, arg1, arg2, arg3)
  }
  else if (shape == "SetCurveIndex" )
  {
    print ("function add SetCurveIndex")
    print(shape)
    print(arg1)   # which curve index 1 based
    #print(arg2)
    # print(arg3)
    result <- tcl("add", shape, arg1, -1, -2)
  }
  else if (shape == "InfoCurves_complete" )
  {
    print ("function add InfoCurves_complete")
    print(shape)
    print(arg1)    # which curve is complete
    #print(arg2)
    #print(arg3)
    result <- tcl("add", shape, arg1, -1, -2)
  }
  else if (shape == "curve" )
  {
    print ("function add curve")
    print(shape)
    print(arg1)
    print(arg2)
    print(arg3)
    result <- tclvalue(tcl("add", shape, arg1, arg2, arg3))
    print (paste("Result from tcl add", result))
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
      print ("function add line 215")
      print(paste ("Shape : ",shape))
      print(paste ("arg1 : ",arg1))
      print(paste ("arg2 : ",arg2))
      print(paste ("arg3 : ",arg3))
      print("------------------------")
    }

    result  <- tclvalue(tcl("add", shape, arg1, arg2, arg3))
    print (paste("Result from tcl add", result))
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
    print("test case setLabelScaleFactor")
    #print(arg1)
    #print(arg2)
    # print(arg3)
    result <- tcl("add", shape, arg1, arg2, arg3)
    print (paste("result : ", result))
    return (TRUE)
  }
  else if (shape == "setCurveScaleFactor")
  {
    #print ("---------------------------------")
    #print ("---------------------------------")
    print("test case setCurveScaleFactor")
    #print(arg1)
    #print(arg2)
    #print(arg3)
    result <- tcl("add", shape, arg1, arg2, arg3)
    print (paste("result : ", result))
    #print ("---------------------------------")
    #print ("---------------------------------")
    return (TRUE)
  }
  else if (shape == "reset_state")
  {
    print("test case reset_state")
    result <- tcl("add", shape, -3, -2, -1)
    print (paste("result : ", result))
    return (TRUE)
  }



  else if (shape == "curveSetDotSliderColor")
  {
    result <- tcl("add", shape, arg1, -2, -1)
    print (paste("result : ", result))
    return (TRUE)
  }



  else
  {
    print(paste("function add unknown shape <", shape,">"))
    print("Usage: add specimen path_of_ply")
    print("Usage: add dot x y z")
    return(FALSE)
  }
}






#calls tkogl2 del function / removes specified shape object
del <- function(shape, arg1, arg2, arg3)
{

  # design decision June 2020
  # the function calls to tcl_if MUST provide three arguments
  # for unused arguments in tcl_if pass negative integers


  print("function del")
  print(shape)
  print(arg1)
  print(arg2)
  print(arg3)

  if (shape == "dot")
  {
    result <- tcl("del", "dot", arg1, arg2, arg3)

  }
  else if (shape == "dots")
  {
    result <- tcl("del","Xdots", arg1, arg2, arg3)

  }
  else if (shape == "anchor")
  {
    result <- tcl("del", "anchor" ,arg1, arg2, arg3)

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
    print("Usage: del dot [...]")
    return(FALSE)
  }
  return(FALSE)
}






#' GUImorph
#' @export
GUImorph <- function() {
  e <- new.env()
  class(e) <- "main"
  ui(e)
  init(e)
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
  print("function loadDgt")
  print(fileName)
  result <- tclvalue(tcl("loadDgt", fileName))
  if (startsWith(result, "ERROR"))
  {
    print("ERROR return from tcl_if loadDgt function")
    return(FALSE)
  }
  else if (startsWith(result, "SUCCESS"))
  {
    print("Success from tcl_if loadDgt")
    return(TRUE)
  }
  else if (startsWith(result, "IGNORE"))
  {
    print("IGNORE return from tcl_if loadDgt function")
  }
  else if (startsWith(result, "UNDER_CONSTRUCTION"))
  {
    print("UNDER CONSTRUCTION C code in tcl_if (.c) file still in work !")
    return(FALSE)
  }
  else
  {
    print ("Unknown return value from tcl_if loadDgt")
    print(result)
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
    path <- file.path("libs", .Platform$r_arc, dlname)
  }
  else
  {
    path <- file.path("libs", dlname)
  }

  file <-
    system.file(path, package = pkgname, lib.loc = libname)[1] #grabs full file name

  print("File 3dDigitize.main ... function .onload")
  print(file)
  print("-----------------")
  tryCatch(
    tcl("load", file, "Tkogl2"),
    error = function(e)
      warning("loading tkogl2 failed", call. = FALSE)
  ) #replace directory with file
}







#calls tkogl2 shows function / returns string value shape object with specified attributes
shows <- function(shape, attr, arg1, arg2)
{
  print("function shows ... line 329")
  print(paste ("Shape is : ", shape))
  #print(paste ("attr is  : ", attr))     # dave ... need to find out how to determine argument existence

  if (shape == "specimen")
  {
    print(paste("attr : " , attr))
    if (attr == "xyz")
    {
      print(paste ("arg1 is  : ", arg1) )
      print(paste ("arg2 is  : ", arg2) )
      result <- tcl("show", shape, attr, arg1, arg2,0)
      print (result)
    }
  }
  else if (shape == "landmark")
  {
    if (attr == "xyz")
    {
      print(paste("attr : " , attr))
      result <- tcl("show", shape, attr, arg1,0, 0)
      print (paste ("RESULT : <", result, ">"))
      return (result)

    }
    else if (attr == "id")
    {
      print(paste("attr : " , attr))
      result <- tcl("show", shape, attr, 0,0, 0)
    }
  }
  else if (shape == "anchor")
  {
    if (attr == "xyz")
    {
      print(paste("attr : " , attr))
      result <- tcl("show", "anchor", "xyz", arg1,0,0)
      print (paste ("RESULT : <", result, ">"))
    }
    else if (attr == "id")
    {
      print(paste("attr : " , attr))
      result <- tcl("show", shape, attr,0,0,0)
    }
  }
  else if (shape == "all")
  {
    ## THIS OPTION IS NOT IMPLEMENTED IN THE CURRENT C CODE
    ## THIS OPTION WAS NOT IMPLEMENTED IN THE LEGACY CODE

    print ("function show all ... line 337")
    result <- tcl("show", shape)
    print (paste("return from tcl_if :", result))

  }
  else
  {
    print("Usage: shows specimen [xyz] ...")
    print("Usage: shows landmark [reqxyz|id] ...")
    print("Usage: shows all")
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
    print ("function ... set at line 541")
    print( paste ("Shape : ", shape) )
    print( paste ("attr  : ", attr )  )
    print("------------------")
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
      print(arg1)
      result <- tcl("setWindow", attr, arg1, 0, 0, 0)
      print(paste("set window mode ... result : <", result, ">"))
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
        print (shape)
        print (attr)
        print(arg1)
        print("Now calling the setSpecimen function if tcl_if")
      }
      result <- tclvalue(tcl("setSpecimen", attr, arg1, 0, 0))
      if(0)
      {
        print(paste("set specimen ", attr, "... result : <", result,">"))
      }

    }
    else if (attr == "move")
    {
      print(arg1)
      print(arg2)
      print(arg3)
      result <- tcl("setSpecimen", attr, arg1, arg2, arg3)
      print (paste ("set specimen ",attr, " ... result : <", result,">"))
    }
    else if (attr == "angle")
    {
      if(0)
      {
        print (paste("rtkolg : set specimen angle", arg1, arg2))
        #print(arg1)
        #print(arg2)
      }

      # example return string : 'Rotate: 0.000000 -8.400000 0.000000'
      result <- tclvalue(tcl("setSpecimen", attr, arg1, arg2, 0))      ## returns a string
      if(0)
      {
         print (paste ("set specimen angle ... result : <", result,">"))
      }
    }
    else
    {
      print(paste("shape specimen ...Not supported attribute", attr))
    }
  }
  else if (shape == "downsample")
  {
    print ("set downsample")
    print(arg1)
    print(arg2)
    result <- tcl("set DownSample", attr, arg1, arg2, 0)
    print (paste ("set DownSample ... result : <", result,">"))

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
      print (paste("set dot selected : arg_1", arg1))
      print (paste("set dot selected : arg_2", arg2))
      result <-  tclvalue(tcl("setDot", attr, arg1, arg2, 0))    ## possible return of a string !

      print(paste ("set dot selected ... result : ", result))
      if (startsWith(result, "WARNING"))
      {
        print (paste("---------", result, "---------") )
        return (FALSE)
      }
      else
      {
        print (paste("---- GOT DOT ----") )
        print (paste("---- GOT DOT ----") )
        return (TRUE)
      }
    }
    else if (attr == "dotColorRestore")
    {
      ##fucntion arguments arg1, arg2, arg3 and NOT used
      result <- tclvalue(tcl("setDot", attr, arg1, arg2, arg3))
      print (paste ("set dot ", attr,  "... result : ", result))
      return (TRUE)
    }
    else if (attr == "coordinate"  ||
             attr == "dcolor"      ||
             attr == "acolor"      ||
             attr == "anchorColor" ||
             attr == "color")
    {
      print(arg1)
      print(arg2)
      print(arg3)
      result <- tclvalue(tcl("setDot", attr, arg1, arg2, arg3))
      print (paste ("set dot ", attr,  "... result : ", result))
      return (TRUE)
    }

  }
  else
  {
    print("Usage: set window [id|size]")
    print("Usage: set specimen [amount|id|scale|angle]")
    print("Usage: set dot [selected|coordinate|color|dcolor|labeled|radius]")
    return(FALSE)
  }
  return(TRUE)
}




