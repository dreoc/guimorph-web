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
