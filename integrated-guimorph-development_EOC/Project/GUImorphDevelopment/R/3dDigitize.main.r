# Version derives from DESCRIPTION; no manual update needed
get_main_date <- function()
{
  .module_banner("main")
  invisible(NULL)
}


#' @name GUImorphWeb-package
#' @docType package
#' @aliases GUImorphWeb-package
#' @title Graphical User Interface for Morphometrics
#' @author Erik Otarola-Castillo
#'
#' @description GUI to R programs to digitize in 3D, conduct geometric morphometric analyses and plotting results based on OpenGL and Tk widget

NULL

#' @import geomorph
NULL

#' @import Rvcg
NULL

NULL

#' @import tcltk
NULL

#' @import tcltk2
NULL

NULL

ui <- function(e) {
  UseMethod("ui", e)
}

init <- function(e) {
  UseMethod("init", e)
}

bind <- function(e) {
  UseMethod("bind", e)
}

updateWidgets <- function(e) {
  UseMethod("updateWidgets", e)
}

##gpagen
################# main data structure ##############################
#dgtDataList
#dgtDataList[imgId][[1]]: speciman dir
#dgtDataList[imgId][[2]]: font
#dgtDataList[imgId][[3]]: number of landmark

#dgtDataList[1][[4]]: curves           ## 18 July should this be expanded to have an image index as well

#dgtDataList[imgId][[5]]: template
#dgtDataList[imgId][[6]]: rotation
#dgtDataList[imgId][[7]]: zoom
#dgtDataList[imgId][[8]]: surface file


#loads vertexs from .dgt file
read.vertex.3D <- function(content, key)
{
  x <- 0 #x dimension for building array
  startLines <- grep(key, content, TRUE)

  # startlines are the line numbers containing the text "Surface="
  dbg("read.vertex.3D ... line numbers containing 'Surface=' " )
  dbg(startLines)

  numbers <- sub(key, "", content[startLines], TRUE)


  dbg("These are the number of surface elements per specimen")
  for (ii in 1:length(numbers))
  {
    dbg(paste ("Numbers", ii,  numbers[ii] ) )
  }


  # THIS MAY NEED TO BE CHANGED INTO A MAXIMUM COMPUTATION
  for (i in 1:length(numbers))
  {
    if (numbers[i] != "")
    {
      x <- numbers[i]
      #break
    }
  }


  dbg(paste ("x = ", x))

  # so vetrexs will be ... say [100 by 3 by nSpecimens]

  ## vertexs <-   array(NA, dim = c(as.numeric(x), 3, length(startLines)))
  vertexs <-   array(0, dim = c(as.numeric(x), 3, length(startLines)))
  for (i in 1:length(startLines))
  {
    startNum <- as.numeric(startLines[i])
    endNum <- startNum + as.numeric(numbers[i])
    dbg(paste ("startNum :", startNum))
    dbg(paste ("endNum   :", endNum))


    # this test is probably not robust
    if (is.na(endNum) || is.na(startNum))
    {
      dbg("NA surface data, skipping")
      next
    }

    if (startNum == endNum)
    {
      # then there really is no surface data for this specimen
      # so fill with zeros - that is leave it full of zeros
    }
    else
    {

      tmp <- content[(startNum + 1):endNum]
      ###print (paste ("NON NA ... tmp", tmp))
      vertexs[, , i] <-   matrix(as.numeric(unlist(strsplit(tmp, " "))), ncol = 3, byrow = TRUE)
    }

  }


  if (is.null(vertexs))
  {
    dbg("HOW DID THIS HAPPEN ? vertexs is NULL !! ")
  }

  dbg("read.vertex.3D ... complete")
  dbg("")
  dbg("")
  return(vertexs)
}



#writes vertexs to file
write.vertex.3D <- function(content, key, fileName)
{
  leadLine <- paste(key, dim(content)[1], sep = "")
  write(leadLine, fileName, append = TRUE)

  write.table(
    content,
    fileName,
    col.names = FALSE,
    row.names = FALSE,
    sep = " ",
    append = TRUE
  )
}

.dgt_format_num <- function(x) {
  # Round in R (round-half-to-even) BEFORE formatting so R — not the platform
  # C library inside formatC — decides the sixth decimal. This is what makes
  # the sixth-decimal tie deterministic across Windows and macOS (DAT-01).
  formatC(round(as.numeric(x), 6), format = "f", digits = 6)
}

#' @noRd
# Internal binary-append line writer with an explicit, pinned CRLF terminator.
# Opening in binary mode ("ab") disables the platform newline translation that
# a bare write()/cat() would apply, so every line the .dgt writer emits ends in
# exactly "\r\n" regardless of host OS. Mirrors the mergeDgt wb pin below.
.dgt_writeln <- function(file_name, text) {
  con <- file(file_name, open = "ab")
  on.exit(close(con), add = TRUE)
  writeLines(text, con, sep = "\r\n")
  invisible(TRUE)
}

.dgt_write_matrix_block <- function(file_name, header_key, mat) {
  rows <- if (is.null(dim(mat))) 0L else as.integer(nrow(mat))
  .dgt_writeln(file_name, paste0(header_key, rows))
  if (rows > 0L) {
    lines <- apply(mat, 1L, function(row) paste(.dgt_format_num(row), collapse = " "))
    .dgt_writeln(file_name, lines)
  }
  invisible(TRUE)
}

.dgt_normalize_lines <- function(lines) {
  if (length(lines) == 0) {
    return(character(0))
  }
  trimws(gsub("\r$", "", lines))
}

.csv_normalize_lines <- function(lines) {
  if (length(lines) <= 1L) {
    return(lines)
  }
  vals <- strsplit(lines[2], ",", fixed = TRUE)[[1]]
  if (length(vals) < 3L) {
    return(lines)
  }
  vals[1] <- .dgt_format_num(vals[1])
  vals[2] <- .dgt_format_num(vals[2])
  vals[3] <- .dgt_format_num(vals[3])
  c(lines[1], paste(vals, collapse = ","))
}

.rds_payload_signature <- function(payload) {
  tf <- tempfile(fileext = ".rds")
  on.exit(unlink(tf), add = TRUE)
  saveRDS(payload, tf)
  as.character(tools::md5sum(tf))
}

refreshTabGating <- function(e) {
  # Browser shell owns notebook rendering (Plan 06-04): retain the server-side
  # tab-enable state computation but drop the Tk notebook widget calls
  # (tcl tab state) and the status-bar side effect. e$nb remains the
  # "initialized" sentinel guard.
  if (is.null(e$nb)) return(invisible())
  loaded <- length(e$activeDataList) > 0
  e$tabState[1] <- if (loaded) 1L else 0L
  lmOk <- loaded &&
    as.integer(e$activeDataList[[e$currImgId]][[3]]) == as.integer(e$landmarkNum)
  for (i in c(2L, 3L, 4L)) {
    e$tabState[i] <- if (lmOk) 1L else 0L
  }
  invisible()
}

.normalizePathExt <- function(path) {
  tolower(tools::file_ext(path))
}

.warnUnexpectedExtension <- function(path, allowed, action_label) {
  ext <- .normalizePathExt(path)
  if (!nzchar(ext) || ext %in% tolower(allowed)) {
    return(invisible(FALSE))
  }
  # Tk message box removed (Plan 06-04): return the warning text so the browser
  # shell can render it via the reusable modal (/msgack) instead of a native Tk
  # dialog. Callers that ignore the return value simply proceed.
  invisible(paste0(
    action_label, " selected a .", ext, " file. ",
    "GUImorphWeb will still try to process it and validate file contents."
  ))
}

#' @noRd
# The SINGLE .dgt block-emission routine, shared by BOTH the native `saveToDgt`
# path and the browser `.gmw_save_session_dgt` path. Because there is exactly one
# serializer, the two entry points cannot diverge byte-for-byte (DAT-01, threat
# T-5-15). Emits the canonical block sequence through the deterministic
# `.dgt_write_matrix_block` / `.dgt_writeln` helpers from 05-01: `Curve=`, then
# `TemplateNumber=NULL`, then per specimen `LM3=`/`AC3=`/`ID=`/`Template=`(only
# when non-NULL)/`Surface=`. `specimens` is a list of records, each carrying
# `$landmarks`, `$anchors`, `$id`, `$template`, `$surface`.
.dgt_emit_session_blocks <- function(file_name, curves, specimens)
{
  .dgt_write_matrix_block(file_name, "Curve=", curves)
  .dgt_writeln(file_name, "")

  .dgt_writeln(file_name, "TemplateNumber=NULL")
  .dgt_writeln(file_name, "")

  for (sp in specimens)
  {
    .dgt_write_matrix_block(file_name, "LM3=", sp$landmarks)
    .dgt_write_matrix_block(file_name, "AC3=", sp$anchors)
    .dgt_writeln(file_name, paste0("ID=", sp$id))

    if (!is.null(sp$template)) {
      .dgt_writeln(file_name, paste0("Template=", sp$template))
    }
    .dgt_write_matrix_block(file_name, "Surface=", sp$surface)

    .dgt_writeln(file_name, "")
  }

  invisible(TRUE)
}

#' Serialize a browser digitizing session to a .dgt through the canonical writer
#'
#' The browser "Save" seam forward-called by the `/save` route (05-02). Reads the
#' server-owned session record for \code{token} (\code{.gmw_session}, 05-02) and
#' emits the \code{.dgt} through the EXACT same block sequence and helpers as
#' \code{saveToDgt} via the one shared \code{.dgt_emit_session_blocks} routine --
#' there is no second serializer, so for identical in-memory arrays the bytes are
#' identical to the native path (DAT-01, T-5-15). The save target carries no
#' request path (T-5-16): when \code{file} is \code{NULL} the destination is
#' chosen R-side. This path never reads or assigns the native oracle engine env
#' (CMP-01, T-5-17).
#' @param token the per-viewport session token whose session to serialize.
#' @param file destination \code{.dgt} path; \code{NULL} chooses the path R-side.
#' @return invisibly \code{TRUE} on write, \code{FALSE} if no path was chosen.
#' @keywords internal
#' @noRd
.gmw_save_session_dgt <- function(token, file = NULL)
{
  s <- .gmw_session_get(token)
  if (is.null(s)) {
    stop("no digitizing session for this token", call. = FALSE)
  }

  # /save carries no path (T-5-16): the destination is chosen R-side, never from
  # the request body. An explicit `file` (e.g. the byte-parity test) skips the
  # dialog.
  if (is.null(file) || !nzchar(file)) {
    file <- tclvalue(tkgetSaveFile(filetypes = "{{DGT file} {.dgt}} {{All files} *}"))
    if (!nzchar(file)) {
      return(invisible(FALSE))
    }
    if (!nzchar(.normalizePathExt(file))) {
      file <- paste(file, ".dgt", sep = "")
    } else {
      .warnUnexpectedExtension(file, "dgt", "Save session")
    }
  }

  file.create(file, showWarnings = TRUE)
  dbg(paste("Writing browser session to .dgt :", file))

  specimens_out <- list()
  for (i in seq_along(s$specimens))
  {
    rec <- s$specimens[[i]]
    landmarks <- rec$land
    if (is.null(landmarks) || nrow(landmarks) == 0L) {
      next()
    }
    specimens_out[[length(specimens_out) + 1L]] <- list(
      id        = rec$id,
      landmarks = landmarks,
      anchors   = rec$anchor,
      template  = rec$template,
      surface   = rec$surfaces
    )
  }

  # Same ONE serializer the native saveToDgt uses (DAT-01 byte identity).
  .dgt_emit_session_blocks(file, s$curves, specimens_out)
  invisible(TRUE)
}

# =====================================================================
#  Merge multiple .dgt files into one dataset.
#  Menu: File > Merge DGT Files...    Console: mergeDgt(inputs, output)
#
#  Offline-safe counterpart to Add PLY: each input .dgt was written while
#  its own landmarks were live in the C engine, so concatenating their
#  text can never disturb another specimen's data. Keeps ONE Curve block
#  and ONE Template block, then appends every specimen body in order.
#  Refuses to write unless the templates match, the curves match, and
#  every specimen agrees on LM3 / AC3 / Surface counts -- the same
#  invariants openDgt() enforces on load.
# =====================================================================

.mdgt_tol <- 1e-6

.mdgt_read <- function(path) sub("\r$", "", readLines(path, warn = FALSE))

.mdgt_keyIdx <- function(lines, key) grep(paste0("^", key), lines, ignore.case = TRUE)

.mdgt_valAfter <- function(line, key) sub(paste0("^", key), "", line, ignore.case = TRUE)

.mdgt_coordRows <- function(lines, start, n) {
  if (n <= 0) return(matrix(numeric(0), ncol = 3))
  body <- lines[(start + 1):(start + n)]
  matrix(as.numeric(unlist(strsplit(trimws(body), "\\s+"))), ncol = 3, byrow = TRUE)
}

.mdgt_split <- function(path) {
  lines <- .mdgt_read(path)
  lm <- .mdgt_keyIdx(lines, "LM3=")
  if (length(lm) == 0)
    stop(sprintf("%s: no 'LM3=' blocks (not a digitized .dgt?)", basename(path)))
  header <- if (lm[1] > 1) lines[1:(lm[1] - 1)] else character(0)
  chunks <- lapply(seq_along(lm), function(k) {
    s <- lm[k]; e <- if (k < length(lm)) lm[k + 1] - 1 else length(lines)
    lines[s:e]
  })
  list(path = path, header = header, chunks = chunks)
}

# Curve/Template blocks compared as RAW TEXT (GUImorphWeb copies them verbatim,
# and the template's first data row is a non-numeric header "V1" "V2" "V3").
.mdgt_rawLines <- function(header, start, n) {
  if (n <= 0) return(character(0))
  trimws(header[(start + 1):(start + n)])
}

.mdgt_curve <- function(header) {
  i <- .mdgt_keyIdx(header, "Curve=")
  if (length(i) == 0) return(list(count = 0L, rows = character(0)))
  n <- as.integer(.mdgt_valAfter(header[i[1]], "Curve=")); if (is.na(n)) n <- 0L
  list(count = n, rows = .mdgt_rawLines(header, i[1], n))
}

.mdgt_template <- function(header) {
  i <- .mdgt_keyIdx(header, "TemplateNumber=")
  if (length(i) == 0)
    return(list(count = 0L, rows = character(0), null = TRUE))
  v <- trimws(.mdgt_valAfter(header[i[1]], "TemplateNumber="))
  if (toupper(v) == "NULL")
    return(list(count = 0L, rows = character(0), null = TRUE))
  m <- as.integer(v)
  list(count = m, rows = .mdgt_rawLines(header, i[1] + 1, m), null = FALSE)
}

.mdgt_counts <- function(chunk) {
  one <- function(key, default = NA_integer_) {
    idx <- .mdgt_keyIdx(chunk, key); if (length(idx) == 0) return(default)
    raw <- trimws(.mdgt_valAfter(chunk[idx[1]], key))
    if (toupper(raw) == "NULL") return(0L)
    v <- suppressWarnings(as.integer(raw)); if (is.na(v)) default else v
  }
  idID <- .mdgt_keyIdx(chunk, "ID=")
  list(LM3 = one("LM3="), AC3 = one("AC3=", 0L), Surface = one("Surface="),
       Template = length(.mdgt_keyIdx(chunk, "Template=")) > 0,
       ID = if (length(idID)) .mdgt_valAfter(chunk[idID[1]], "ID=") else "<no ID>")
}

.mdgt_rowsEqual <- function(a, b) {
  identical(as.character(a), as.character(b))
}

# public: returns list(ok, errors, summary, output). Writes file iff ok.
mergeDgt <- function(inputs, output) {
  if (length(inputs) < 2)
    return(list(ok = FALSE, errors = "Select at least two .dgt files to merge.",
                summary = NULL, output = output))
  if (!grepl("\\.dgt$", output, ignore.case = TRUE)) output <- paste0(output, ".dgt")

  parsed <- lapply(inputs, .mdgt_split)
  ref <- parsed[[1]]
  refCur <- .mdgt_curve(ref$header)
  refTmp <- .mdgt_template(ref$header)
  first <- .mdgt_counts(ref$chunks[[1]])
  L0 <- first$LM3; A0 <- first$AC3; S0 <- first$Surface
  if (is.na(L0) || is.na(S0))
    return(list(ok = FALSE,
                errors = sprintf("%s: first specimen missing LM3= or Surface=.", basename(ref$path)),
                summary = NULL, output = output))

  errs <- character(0); nTotal <- 0L
  for (pf in parsed) {
    cur <- .mdgt_curve(pf$header); tmp <- .mdgt_template(pf$header)
    if (tmp$null != refTmp$null || tmp$count != refTmp$count || !.mdgt_rowsEqual(tmp$rows, refTmp$rows))
      errs <- c(errs, sprintf(
        "TEMPLATE MISMATCH: %s (%d pts) differs from %s (%d pts). Surface semilandmarks would not be homologous.",
        basename(pf$path), tmp$count, basename(ref$path), refTmp$count))
    if (cur$count != refCur$count || !.mdgt_rowsEqual(cur$rows, refCur$rows))
      errs <- c(errs, sprintf("CURVE MISMATCH: %s (%d pts) differs from %s (%d pts).",
                              basename(pf$path), cur$count, basename(ref$path), refCur$count))
    for (ci in seq_along(pf$chunks)) {
      cc <- .mdgt_counts(pf$chunks[[ci]]); nTotal <- nTotal + 1L
      tag <- sprintf("%s specimen %d (ID=%s)", basename(pf$path), ci, cc$ID)
      if (!identical(cc$LM3, L0)) errs <- c(errs, sprintf("LANDMARK COUNT: %s has LM3=%s, expected %d.", tag, cc$LM3, L0))
      if (!identical(cc$AC3, A0)) errs <- c(errs, sprintf("ANCHOR COUNT: %s has AC3=%s, expected %d.", tag, cc$AC3, A0))
      if (!identical(cc$Surface, S0)) errs <- c(errs, sprintf("SURFACE COUNT: %s has Surface=%s, expected %d.", tag, cc$Surface, S0))
      if (!cc$Template) errs <- c(errs, sprintf("MISSING Template= line in %s.", tag))
    }
  }
  if (refTmp$null)
    errs <- c(errs, sprintf("%s has no template (TemplateNumber=NULL); a merged surface dataset needs a shared template.",
                            basename(ref$path)))

  if (length(errs) > 0)
    return(list(ok = FALSE, errors = errs, summary = NULL, output = output))

  out <- ref$header
  for (pf in parsed) for (chunk in pf$chunks) {
    out <- c(out, chunk)
    if (length(chunk) == 0 || tail(chunk, 1) != "") out <- c(out, "")
  }
  con <- file(output, open = "wb"); writeLines(out, con, sep = "\r\n"); close(con)

  summary <- paste(c(
    sprintf("Merged %d files into:", length(inputs)), output, "",
    sprintf("Specimens: %d", nTotal),
    sprintf("Landmarks: %d   Anchors: %d   Surface: %d", L0, A0, S0),
    sprintf("Template points: %d   Curve points: %d", refTmp$count, refCur$count)),
    collapse = "\n")
  list(ok = TRUE, errors = character(0), summary = summary, output = output)
}

