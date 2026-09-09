# GMW_VIEW3D_TEMPLATE is an R single-quoted string that carries the page's
# JavaScript verbatim. R processes escapes inside single-quoted strings exactly
# as it does inside double-quoted ones, so the two-character source sequence
# backslash-quote (\") reaches the browser as a bare quote. Inside a JS
# double-quoted string literal that is a SyntaxError, and a SyntaxError anywhere
# in the inline script aborts the whole script: no renderer, no mesh, no shell
# chrome, no render loop. Only the static HTML (the Phase 5 button row and the
# HUD line) survives.
#
# That is exactly what the Phase 6 live-browser UAT hit on 2026-09-09: 37 lines
# of shell markup added in 06-02 (3136877, 3de51cf) wrote \" where \\" was
# needed, so GUImorphWeb() booted to a white viewport with no File menu. Every
# source-scan test stayed green because none of them execute the JS.
#
# Two guards. The first is base R and always runs against the source tree. The
# second parses the emitted script with node when node is on PATH (it is on the
# maintainer machines; it is not a package dependency) and skips otherwise.

skip_if_no_pkg_source()

view3d_path <- file.path(pkg_source_root(), "R", "view3d.R")

test_that("GMW_VIEW3D_TEMPLATE never carries a single-backslash quote", {
  src <- readLines(view3d_path, warn = FALSE)

  open_line <- grep("^GMW_VIEW3D_TEMPLATE <- '", src)
  expect_length(open_line, 1L)
  close_line <- grep("^'\\s*$", src)
  close_line <- close_line[close_line > open_line][1]
  expect_false(is.na(close_line))

  tpl <- src[open_line:close_line]

  # A backslash-quote NOT itself preceded by a backslash. \\" (which R turns
  # into \" and JS reads as an escaped quote) does not match; \" does.
  bad <- grep('(?<!\\\\)\\\\"', tpl, perl = TRUE)

  expect_length(
    bad, 0L,
    label = paste0(
      "view3d.R lines with a single-backslash quote inside the template: ",
      paste(open_line + bad - 1L, collapse = ", "),
      " (write \\\\\" so the JS receives \\\")"
    )
  )
})

test_that("the emitted inline script parses as JavaScript (node --check)", {
  node <- Sys.which("node")
  skip_if(!nzchar(node), "node not on PATH; JS parse gate skipped")

  env <- new.env()
  sys.source(view3d_path, envir = env)
  html <- env$.gmw_view3d_html(mesh_url = "specimen.ply")

  # The page has two <script> elements: the bundle include and the inline
  # program. Take the last inline block, up to the closing tag before </body>.
  m <- regmatches(html, regexpr("(?s)<script>(.*)</script>\\s*</body>", html, perl = TRUE))
  expect_length(m, 1L)
  js <- sub("(?s)^<script>", "", sub("(?s)</script>\\s*</body>$", "", m, perl = TRUE), perl = TRUE)

  f <- tempfile(fileext = ".js")
  on.exit(unlink(f), add = TRUE)
  writeLines(js, f, useBytes = TRUE)

  out <- suppressWarnings(system2(node, c("--check", shQuote(f)), stdout = TRUE, stderr = TRUE))
  status <- attr(out, "status")
  expect_true(
    is.null(status) || identical(status, 0L),
    label = paste0("node --check failed:\n", paste(out, collapse = "\n"))
  )
})
