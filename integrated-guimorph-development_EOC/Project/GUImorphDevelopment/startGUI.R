rm(list=ls())

library(GUImorph)
# test functions
require(tcltk)
require(tcltk2)
require(parallel)
require(geomorph)
require(Rvcg)
require(Morpho)
require(vegan)
#require(gpuR)

path <- getwd()

source(paste(path,"/R/rtkogl.r", sep = ""))
source(paste(path,"/R/3dDigitize.curve.r", sep = ""))
source(paste(path,"/R/3dDigitize.digitize.r", sep = ""))
source(paste(path,"/R/3dDigitize.geomorph.r", sep = ""))
source(paste(path,"/R/3dDigitize.main.r", sep = ""))
source(paste(path,"/R/3dDigitize.surface.r", sep = ""))
source(paste(path,"/R/geomorph.support.code.r", sep = ""))
#digitize3D <-function() {
    e <- new.env()
    class(e) <- "main"
    ui(e)
    init(e)
#}

## RUN THIS BEFORE BUILDING A NEW SOURCE OR BINARY PACKAGE
## IT UPDATES THE DATE IN THE DESCRIPTION AND NAMESPACE
 library("roxygen2")
 library("devtools")
 lines<-readLines(paste(path,"/DESCRIPTION", sep=""))
 lines[4]<-paste("Version: 1.0.0.",format(Sys.time(), "%m.%d.%Y.%H.%M"),sep="")
 lines[5]<-paste("Date: ",Sys.Date(),sep="")
 writeLines(lines, paste(path,"/DESCRIPTION", sep=""))
 document(path)

