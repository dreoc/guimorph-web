# ---------------------------------------------------------------------------
#  transport.R -- WEB-01 loopback transport for the browser viewport
#
#  Starts a background httpuv listener bound to 127.0.0.1 and serves one
#  specimen PLY (plus the vendored three.js bundle and the page written by
#  view3d.R) as raw bytes behind a per-session random path token. The browser
#  page (from .gmw_view3d_html(mesh_url = "specimen.ply")) fetches the mesh
#  same-origin over http://, so PLYLoader is not CORS-blocked. This is the
#  server-side half of the delivery pair with view3d.R (WEB-02).
#
#  Design (inherited from research/REFERENCE-ARCHITECTURE.md, server-owns-state):
#    * Static serving via httpuv::staticPaths -> bytes stream off the libuv/C
#      thread, never JSON-encoded and never through a call() handler that would
#      join a file path from the untrusted request path (path-traversal safety,
#      T-2-02).
#    * host = "127.0.0.1" only, never the wildcard all-interfaces address --
#      the specimen is never exposed to the LAN (T-2-03).
#    * The live server handle is retained in the .gmw_server package env so its
#      finalizer does not stop the listener on gc() (Pitfall 2). Robust teardown,
#      port-collision recovery, and browser-launch degradation are WEB-04/Phase 3
#      and are deliberately NOT built here.
#
#  Token strength (T-2-04, RESEARCH Open Question 1 / Assumption A1): the guard
#  is a >=128-bit base-R random path segment. Its purpose is to stop trivial
#  same-host enumeration of the endpoint; the temp file is already protected by
#  user-level filesystem permissions and the loopback bind. It is generated with
#  base R's sample() over a fixed URL-safe alphabet, which is NOT a cryptographic
#  RNG. Residual risk (a same-user local process guessing a sample() token) is
#  accepted for Phase 2; a CSPRNG (openssl/sodium) is deliberately not added.
# ---------------------------------------------------------------------------

# Gated debug printer. In the assembled package this resolves to the shared
# dbg() from rtkogl.R (sourced earlier in the collation order); the guard only
# defines a fallback when this file is sourced on its own (e.g. in tests), so
# there is never a duplicate definition in the package namespace.
if (!exists("dbg", mode = "function")) {
  dbg <- function(...) if (isTRUE(getOption("guimorph.debug", FALSE))) print(...)
}

# Package-level retained state: holds each live httpuv server handle, keyed by
# its token, so gc() does not run the finalizer and stop the listener for the
# session. Mirrors the .gmw_engine idiom in rtkogl.R.
.gmw_server <- new.env(parent = emptyenv())

#' A URL-safe, >=128-bit random path segment for the per-session guard
#'
#' Returns \code{n} characters drawn uniformly from a 62-symbol URL-safe
#' alphabet (\code{0-9a-zA-Z}). The default \code{n = 32} is well above 128 bits
#' of address space. See the file header for the residual-risk note: this is a
#' base-R generator, not a CSPRNG.
#' @param n number of characters (>= 32 keeps the guard >= 128 bits).
#' @return a length-1 character token matching \code{^[A-Za-z0-9]+$}.
#' @keywords internal
#' @noRd
.gmw_token <- function(n = 32L) {
  alphabet <- c(0:9, letters, LETTERS)
  paste(sample(alphabet, n, replace = TRUE), collapse = "")
}

#' Is a TCP port free on the loopback interface?
#'
#' Opens and immediately closes a server socket on \code{port}; a successful
#' open means the port is free. Injected into \code{.gmw_pick_port} so port
#' selection is unit-testable with a stub (no real socket bound in tests).
#' @param port integer port to probe.
#' @return \code{TRUE} if the port could be bound, else \code{FALSE}.
#' @keywords internal
#' @noRd
.gmw_probe_free <- function(port) {
  con <- tryCatch(serverSocket(as.integer(port)), error = function(e) NULL)
  if (is.null(con)) return(FALSE)
  close(con)
  TRUE
}

#' Choose a loopback port: randomPort primary, walk-forward-from-preferred backup
#'
#' With \code{prefer = NULL} (the default), returns \code{httpuv::randomPort()},
#' which already picks a free, unprivileged, browser-safe port on 127.0.0.1.
#' When \code{prefer} is supplied, walks forward from it using \code{probe}
#' until a free port is found (the REFERENCE-ARCHITECTURE backup).
#' @param prefer optional starting port for the walk-forward backup.
#' @param probe free-port predicate; overridable for testing.
#' @return an integer port.
#' @keywords internal
#' @noRd
.gmw_pick_port <- function(prefer = NULL, probe = .gmw_probe_free) {
  if (is.null(prefer)) return(httpuv::randomPort())
  port <- as.integer(prefer)
  while (!isTRUE(probe(port))) {
    port <- port + 1L
    if (port > 49151L) {
      stop("GUImorphWeb: could not find a free port walking forward from ",
           prefer, ".\n  Free a port in the 1024-49151 range and retry.",
           call. = FALSE)
    }
  }
  port
}

#' Serve one specimen PLY over a loopback, token-guarded httpuv static path
#'
#' The Phase 2 entry point. Copies the vendored bundle, the specimen (as the
#' fixed name \code{specimen.ply}), and the page from
#' \code{.gmw_view3d_html(mesh_url = "specimen.ply")} into a fresh temp dir,
#' mounts it under \code{/<token>} on \code{127.0.0.1:<port>} via
#' \code{httpuv::staticPaths}, retains the handle against gc(), and opens the
#' viewport. One specimen per viewport (D-01); no in-page picker (D-02).
#' @param ply_path path to an existing \code{.ply} file.
#' @param title window/page title.
#' @param background page background colour.
#' @param open when \code{TRUE}, open the URL with \code{utils::browseURL}.
#' @return the served \code{http://127.0.0.1:<port>/<token>/} URL, invisibly.
#' @keywords internal
#' @noRd
.gmw_serve_mesh <- function(ply_path, title = "GUImorphWeb",
                            background = "#ffffff", open = TRUE) {
  if (!file.exists(ply_path)) {
    stop("GUImorphWeb: cannot serve the mesh -- the PLY file was not found.\n",
         "  Looked for: ", ply_path,
         "\n  Pass the path of an existing .ply file to .gmw_serve_mesh().",
         call. = FALSE)
  }

  dir <- tempfile(pattern = "guimorphweb-")
  dir.create(dir)
  file.copy(.gmw_bundle_path(), file.path(dir, "guimorphweb-three.js"))
  file.copy(ply_path, file.path(dir, "specimen.ply"))

  html <- .gmw_view3d_html(mesh_url = "specimen.ply", title = title,
                           background = background)
  writeLines(html, file.path(dir, "index.html"), useBytes = TRUE)

  port  <- .gmw_pick_port()
  token <- .gmw_token()
  server <- httpuv::startServer(
    host = "127.0.0.1", port = port,
    app = list(
      staticPaths = stats::setNames(
        list(httpuv::staticPath(dir)),
        paste0("/", token)
      )
    )
  )
  # Retain the handle for the session so gc() does not stop the listener.
  assign(token, server, envir = .gmw_server)

  url <- sprintf("http://127.0.0.1:%d/%s/", port, token)
  dbg(paste0("gmw serve: ", url))
  message("Viewport: ", url)
  if (isTRUE(open)) utils::browseURL(url)
  invisible(url)
}
