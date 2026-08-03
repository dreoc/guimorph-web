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

# Package-level lifecycle flags, kept SEPARATE from .gmw_server so that
# ls(.gmw_server) stays purely token -> handle and no bookkeeping key is ever
# mistaken for a live server handle by .gmw_stop_token() (RESEARCH Open
# Question 1). Currently holds `finalizer_registered`; plan 02 adds more.
.gmw_lifecycle <- new.env(parent = emptyenv())

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
      stop("GUImorphWeb: no free port from ", prefer, " through 49151.\n",
           "  Free a port in that range, or omit `port` to auto-pick a ",
           "random one.", call. = FALSE)
    }
  }
  port
}

#' Build the /close request handler for one viewport server
#'
#' Returns the per-server \code{call} closure that captures its own \code{token}
#' (each server closes over exactly its own). The closure pattern-matches the
#' trailing \code{/close} on the request path (\code{req$PATH_INFO}) and, on a
#' match, schedules that token's teardown via \code{later::later} and returns
#' \code{204} immediately. It only pattern-matches the path; it NEVER joins the
#' request path to the filesystem via \code{file.path}/\code{normalizePath}/
#' \code{readBin} (V5/T-3-01) -- and it NEVER calls \code{httpuv::stopServer()}
#' synchronously:
#' a synchronous stop resets the in-flight connection (RESEARCH Pitfall 2), so
#' the stop is deferred and the \code{204} flushes first (\code{sendBeacon}
#' ignores the body anyway). Any other path is a plain \code{404}.
#'
#' \code{later::later} is called fully qualified; \code{later} is a transitive
#' \code{httpuv} dependency and needs no new \code{import()} (RESEARCH Standard
#' Stack).
#' @param token the per-server token this handler closes over.
#' @return a \code{function(req)} httpuv \code{call} handler.
#' @keywords internal
#' @noRd
.gmw_close_handler <- function(token) {
  force(token)
  function(req) {
    if (grepl("/close$", req$PATH_INFO)) {
      later::later(function() .gmw_stop_token(token), 0.5)
      return(list(status = 204L, headers = list(), body = ""))
    }
    list(status = 404L, headers = list("Content-Type" = "text/plain"), body = "")
  }
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
#' @param port optional preferred loopback port (D-08). \code{NULL} (the default)
#'   auto-picks a random free port via \code{httpuv::randomPort()}; an integer is
#'   the "fixed port allowed through a lab firewall" case -- selection walks
#'   forward from it through the existing \code{.gmw_pick_port} backup, and if no
#'   port is free through 49151 it raises a clear error rather than hanging (D-09).
#' @return the served \code{http://127.0.0.1:<port>/<token>/} URL, invisibly.
#' @keywords internal
#' @noRd
.gmw_serve_mesh <- function(ply_path, title = "GUImorphWeb",
                            background = "#ffffff", open = TRUE, port = NULL) {
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

  # NULL keeps the randomPort() default; an integer walks forward from it
  # through the existing selector -- no new selection logic (D-08).
  port  <- .gmw_pick_port(prefer = port)
  token <- .gmw_token()
  # Mixed static + one dynamic route (RESEARCH Pattern 2, D-02). The static
  # byte mount stays byte-for-byte as Phase 2 shipped it (its options are
  # unchanged, T-2-02); alongside it, excludeStaticPath() routes exactly the one
  # /<token>/close subpath to R instead of the C++ static thread, and the `call`
  # handler answers it. excludeStaticPath() is preferred over
  # staticPathOptions(fallthrough = TRUE) -- it scopes exactly one subpath to R
  # rather than routing every missing file there (RESEARCH Alternatives).
  server <- httpuv::startServer(
    host = "127.0.0.1", port = port,
    app = list(
      staticPaths = stats::setNames(
        list(httpuv::staticPath(dir), httpuv::excludeStaticPath()),
        c(paste0("/", token), paste0("/", token, "/close"))
      ),
      call = .gmw_close_handler(token)
    )
  )
  # Retain the handle for the session so gc() does not stop the listener.
  assign(token, server, envir = .gmw_server)

  # Register the session-end teardown finalizer exactly once (lazily, on the
  # first serve). reg.finalizer(onexit = TRUE) is the ONLY hook that fires at
  # q() -- .onUnload() does NOT run at R session end (verified ?ns-hooks) -- so
  # this is what guarantees a quit R session leaves no orphaned listener. The
  # flag lives in .gmw_lifecycle, never in .gmw_server, so the registry stays
  # purely token -> handle.
  if (!isTRUE(.gmw_lifecycle$finalizer_registered)) {
    reg.finalizer(.gmw_server, function(e) .gmw_stop_token(NULL), onexit = TRUE)
    .gmw_lifecycle$finalizer_registered <- TRUE
  }

  url <- sprintf("http://127.0.0.1:%d/%s/", port, token)
  dbg(paste0("gmw serve: ", url))
  message("Viewport: ", url)
  if (isTRUE(open)) utils::browseURL(url)
  invisible(url)
}

# ---------------------------------------------------------------------------
#  Teardown (WEB-04) -- a closed listener must never orphan.
#
#  One registry-driven stop helper (.gmw_stop_token) backs three of the four
#  D-01 triggers: the explicit user call gmw_close(), R session end (via the
#  reg.finalizer(onexit = TRUE) registered lazily in .gmw_serve_mesh above), and
#  namespace unload/detach (.onUnload). The fourth trigger -- the browser
#  tab-close /close beacon (D-02) -- lands in plan 02 and reuses this same
#  helper. Teardown iterates .gmw_server ONLY; it never uses httpuv's
#  process-wide stop-all, which would also stop any shiny/plumber listeners a
#  user is running in the same R process (T-3-03).
# ---------------------------------------------------------------------------

#' Stop one live viewport server, or all of them
#'
#' Iterates the token-keyed \code{.gmw_server} registry. With \code{token = NULL}
#' every live listener is stopped; with a token, exactly that one (D-03/D-04 --
#' each viewport is independent, so stopping one leaves the others running). For
#' each entry BOTH \code{httpuv::stopServer()} and \code{rm()} always run, each
#' guarded, so the registry can never lie about what is still live (RESEARCH
#' Pitfall 1). Never uses httpuv's process-wide stop-all (T-3-03) -- that would
#' stop other packages' listeners in the same process.
#' @param token optional single token; \code{NULL} stops all.
#' @return \code{invisible(TRUE)}.
#' @keywords internal
#' @noRd
.gmw_stop_token <- function(token = NULL) {
  toks <- if (is.null(token)) ls(.gmw_server) else token
  for (t in toks) {
    srv <- tryCatch(get(t, envir = .gmw_server), error = function(e) NULL)
    if (!is.null(srv)) try(httpuv::stopServer(srv), silent = TRUE)
    if (exists(t, envir = .gmw_server)) rm(list = t, envir = .gmw_server)
  }
  invisible(TRUE)
}

#' Close the GUImorphWeb viewport server(s)
#'
#' Stops the background loopback listener(s) started for the browser viewport.
#' Called with no argument it stops every live viewport; called with a
#' \code{token} it stops exactly that one and leaves any other viewports
#' running. Each viewport is fully independent (its own port, token, and server
#' handle), so closing one never disturbs another. Teardown also happens
#' automatically when R exits or the package namespace is unloaded, so calling
#' this by hand is optional tidy-up rather than a requirement.
#' @param token optional token identifying a single viewport -- the segment in
#'   its \code{http://127.0.0.1:<port>/<token>/} URL. \code{NULL} (the default)
#'   stops all live viewports.
#' @return \code{invisible(TRUE)}.
#' @examples
#' \dontrun{
#' gmw_close()        # stop every live viewport
#' gmw_close(token)   # stop just the viewport with this token
#' }
#' @export
gmw_close <- function(token = NULL) .gmw_stop_token(token)

#' Package unload hook: stop every live viewport listener
#'
#' Fires on \code{unloadNamespace()} / \code{detach(unload = TRUE)}, closing the
#' detach-mid-session orphan path (D-01). It does NOT run at normal R session
#' end -- that path is covered by the \code{reg.finalizer(onexit = TRUE)}
#' registered in \code{.gmw_serve_mesh} (verified \code{?ns-hooks}). Defined here
#' in transport.R, beside \code{.gmw_server}; it is never added to rtkogl.R,
#' whose \code{.onLoad} engine-load path must stay untouched (CMP-01).
#' @param libpath the library path being unloaded (signature per \code{?ns-hooks}).
#' @keywords internal
#' @noRd
.onUnload <- function(libpath) .gmw_stop_token(NULL)
