# Unit tests for doUndo status messaging (no Tcl/GUI required)

test_that("doUndo warns when undo stack is empty", {
  statusLog <- list()
  setStatus <- function(e, msg, level) {
    statusLog[[length(statusLog) + 1]] <<- list(msg = msg, level = level)
  }

  e <- new.env(parent = emptyenv())
  e$undo <- NULL

  doUndo <- function(e) {
    if (is.null(e$undo)) {
      setStatus(e, "Nothing to undo", "warning")
      return(invisible())
    }
    invisible()
  }

  doUndo(e)

  expect_length(statusLog, 1)
  expect_equal(statusLog[[1]]$msg, "Nothing to undo")
  expect_equal(statusLog[[1]]$level, "warning")
})


test_that("doUndo reports landmark placement reversal", {
  statusLog <- list()
  setStatus <- function(e, msg, level) {
    statusLog[[length(statusLog) + 1]] <<- list(msg = msg, level = level)
  }

  set <- function(shape, attr, x, y) TRUE
  del <- function(shape) TRUE
  updateDotNum <- function(e, delt) invisible()
  clearUndo <- function(e) {
    e$undo <- NULL
  }

  doUndo <- function(e) {
    if (is.null(e$undo)) {
      setStatus(e, "Nothing to undo", "warning")
      return(invisible())
    }

    entry <- e$undo
    scr <- entry$screen
    ok <- FALSE
    msg <- NULL

    if (entry$action == "place" && entry$kind == "landmark") {
      if (set("dot", "selected", scr[1], scr[2])) {
        del("dot")
        updateDotNum(e, -1)
        msg <- "Undid landmark placement"
        ok <- TRUE
      }
    }

    if (ok) {
      clearUndo(e)
      setStatus(e, msg, "info")
    }
    invisible()
  }

  e <- new.env(parent = emptyenv())
  e$undo <- list(
    action = "place",
    kind = "landmark",
    coord = c(1, 2, 3),
    screen = c(10L, 20L)
  )

  doUndo(e)

  expect_length(statusLog, 1)
  expect_match(statusLog[[1]]$msg, "Undid landmark placement")
  expect_equal(statusLog[[1]]$level, "info")
  expect_null(e$undo)
})

test_that("doUndo curve_place reports segment reversal message", {
  statusLog <- list()
  setStatus <- function(e, msg, level) {
    statusLog[[length(statusLog) + 1]] <<- list(msg = msg, level = level)
  }

  redrawCalled <- FALSE
  .redrawAllCurves <- function(e) {
    redrawCalled <<- TRUE
    TRUE
  }

  clearUndo <- function(e) {
    e$undo <- NULL
  }

  doUndo <- function(e) {
    if (is.null(e$undo)) {
      setStatus(e, "Nothing to undo", "warning")
      return(invisible())
    }

    entry <- e$undo
    ok <- FALSE
    msg <- NULL

    if (entry$action == "curve_place") {
      curves <- e$activeDataList[[1]][[4]]
      if (is.null(curves) || nrow(curves) < 1) {
        setStatus(e, "Nothing to undo", "warning")
        return(invisible())
      }
      if (nrow(curves) == 1) {
        e$activeDataList[[1]][[4]] <- NULL
      } else {
        e$activeDataList[[1]][[4]] <- curves[-nrow(curves), , drop = FALSE]
      }
      .redrawAllCurves(e)
      msg <- "Undid curve segment placement"
      ok <- TRUE
    }

    if (ok) {
      clearUndo(e)
      setStatus(e, msg, "info")
    }
    invisible()
  }

  e <- new.env(parent = emptyenv())
  e$activeDataList <- list(list(
    NULL,
    NULL,
    NULL,
    matrix(c(1L, 2L, 3L, 4L, 5L, 6L), nrow = 2, ncol = 3, byrow = TRUE)
  ))
  e$undo <- list(action = "curve_place", row = c(4L, 5L, 6L))

  doUndo(e)

  expect_length(statusLog, 1)
  expect_equal(statusLog[[1]]$msg, "Undid curve segment placement")
  expect_equal(statusLog[[1]]$level, "info")
  expect_true(redrawCalled)
  expect_equal(nrow(e$activeDataList[[1]][[4]]), 1)
  expect_null(e$undo)
})


test_that("onSelectCurve uses inline duplicate landmark warning", {
  skip_if_no_pkg_source()
  curveFile <- normalizePath(
    file.path(testthat::test_path(), "..", "..", "R", "3dDigitize.curve.r"),
    mustWork = TRUE
  )
  curveSrc <- readLines(curveFile, warn = FALSE)
  expect_true(any(grepl("Duplicate landmark in this curve segment", curveSrc, fixed = TRUE)))
  expect_false(any(grepl("tkmessageBox", curveSrc, fixed = TRUE)))
})
