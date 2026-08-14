
# Version derives from DESCRIPTION; no manual update needed
get_curve_date <- function()
{
  .module_banner("curve")
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


# Phase 6 (UI-01/UI-02): the Tk builder (ui.curve) and every native-engine
# handler in this file (onSelectCurve, draw.curves, changeDotColor,
# .redrawAllCurves/.clearAllCurves and the add/set/del/shows bridge) were
# removed. Curve selection and drawing are server-driven over the existing
# /curve route (Phase 5); the "Duplicate landmark" and "missed a landmark"
# guards live browser/route-side now. What remains is the non-Tk curve data
# model: the state initializer and the .dgt curve serializers R still owns.

#initializes parameters for curve component
init.curve <- function(e)
{
	e$curveDotNum <- 0
	e$curveDots <- c()
	e$curveLine<- c()
	e$sliders<-c()
	e$curveBound <- FALSE
}


#loads curve data from .dgt file
read.curve <- function(content)
{
	##print ("file 3dDigitize.curve ... function read.curve")

  ignore.case = TRUE
	startLine <- grep("^Curve=", content, ignore.case)
	if (length(startLine) == 0L)
		return(NULL)
	if (length(startLine) > 1L)
		startLine <- startLine[1L]

	num <- as.integer(sub("Curve=", "", content[startLine], ignore.case = TRUE))

	if (is.na(num) || num == 0L)
	{
	  dbg("No curve data to process")
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
