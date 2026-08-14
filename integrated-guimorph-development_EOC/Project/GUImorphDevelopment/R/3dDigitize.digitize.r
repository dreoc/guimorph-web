# Version derives from DESCRIPTION; no manual update needed
get_digitize_date <- function()
{
  .module_banner("digitize")
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


# Phase 6 (UI-01/UI-02): the Tk tab builders (ui.digitize/ui.anchor), the
# Set-Landmark/Anchor-Number toplevels, the tkgetOpenFile landmark loader, the
# tk_chooseColor pickers, and every native-engine draw/pick handler (the
# add/set/del/shows bridge) were removed here. Landmark/anchor interaction is
# now server-driven over the /pick and /anchor routes, and the anchor/landmark
# colour is a browser <input type="color"> value persisted over the Plan-01
# /color route onto the session (see transport.R). What remains below is the
# non-Tk data model: the default colour state and the .dgt landmark/anchor
# serializers that R still owns.


# initializes the digitize data-model state (no Tk widgets, no engine)
init.digitize <- function(e)
{
  e$digData <- list()
  e$landmarkNum <- 5
  e$anchorNum <- 5
  # these variables record the number of landmarks and anchors resident for the
  # specified array slice; used to prevent adding redundant (duplicate)
  # landmarks and anchors when changing specimens after loading a .dgt file
  e$landmarksPresentInMemory <- 0
  e$anchorsPresentInMemory <- 0
  e$lmkLoadedInC <- list()

  # Default colour state kept R-side. The runtime landmark/anchor colour is the
  # browser <input type=color> hex persisted over the /color route (Plan 01).
  e$dColor <- c(1, 0, 0)     # initial dot color is RED
  e$daColor <- c(0, 1, 0)    # initial anchor color is GREEN
  e$undo <- NULL
}




#reads .dgt files
read.digitize <- function(e, content)
{
  dbg("file 3dDigitize.digitize ... function read.digitize")
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
    dbg("line 958")
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
    dbg("line 971")
  }


  dbg(ID)
  if (length(ID) != 0)
  {
    dimnames(coords)[[3]] <- as.list(ID)
  }



  dbg("file 3dDigitize.digitize ... function read.digitize ... end")
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
    dbg("Missing anchors")
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
    dbg( paste( "read.anchors : file name ", ii, ":", ID[ii] ) )
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
