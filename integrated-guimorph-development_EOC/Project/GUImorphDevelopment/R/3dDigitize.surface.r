
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
#
# Phase 6 (UI-01/UI-02): the Tk surface tab builder (ui.surface), its
# Set-Number-of-Surface-Sliders toplevel, the bind/updateWidgets S3 methods, and
# the now-dead Tk build-template / downsample handlers (buildTemplate,
# buildTemplate1, downSample, disableOper, hidePly, setSurSliderNum, draw.surface)
# were removed with their tkmessageBox dialogs and native add/set engine verbs.
# Surface digitizing now runs headless through the /downsample loopback route
# (.gmw_downsample_session below); this file keeps only the non-Tk headless
# downsample + template/.dgt serializers.

#write sample data to file
write.nts <- function(vertexNum, fileName, vertex)
{
	file.create(fileName, showWarnings=TRUE)
	write(paste("Surface=", vertexNum, sep=""), file = fileName)
	write.table(vertex, file=fileName, row.names=F, col.names=F, append = TRUE)
}


#' Headless surface-semilandmark builder for the browser /downsample route
#'
#' The browser does not compute geometry -- it only triggers this over the
#' 05-02 \code{/downsample} loopback route (\code{.gmw_digitize_handler}
#' forward-calls \code{.gmw_downsample_session(token)}). This runs the SAME TPS
#' template warp + nearest-neighbour pass that the retired \code{downSample}
#' used, but headlessly: no Tk status bar, no message boxes, and -- critically --
#' no \code{add("downsample", ...)} into the native \code{tkogl2} C engine (that
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

  # Same preconditions downSample() enforced, minus the Tk status-bar path.
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
  # branch did (they guarantee topographically significant features).
  fixed <- as.integer(nrow(lmk))
  if (!is.null(anc) && nrow(anc) > 0L) {
    lmk   <- rbind(lmk, as.matrix(anc))
    fixed <- as.integer(nrow(lmk))
  }

  dbg("gmw downsample: warping template (headless)")

  # ---- TPS warp pipeline, verbatim from the retired downSample() -----------
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
