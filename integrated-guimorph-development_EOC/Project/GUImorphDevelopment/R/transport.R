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

# Package-level, server-owned landmark store: keyed by token -> an n x 3 numeric
# matrix of placed pick coordinates (PICK-01). Kept SEPARATE from .gmw_server
# (same reasoning as .gmw_lifecycle) so ls(.gmw_server) stays purely
# token -> handle and .gmw_stop_token() never mistakes a landmark matrix for a
# live server handle. This is the SINGLE authoritative copy of the landmarks:
# the browser only reports clicks over POST /<token>/pick; R owns the array
# (server-owns-state, research/REFERENCE-ARCHITECTURE.md).
.gmw_picks <- new.env(parent = emptyenv())

# Package-level, server-owned DIGITIZING record: keyed by token -> a list
#   list(specimens = list(<record>, ...), current = <int>,
#        curves = <c x 3 integer matrix>, undo = <entry|NULL>)
# where each per-specimen <record> is
#   list(land = <p x 3 numeric>, anchor = <a x 3 numeric>,
#        surfaces = <s x 3 numeric>, template = <character scalar|NULL>).
# Kept SEPARATE from .gmw_server (same reasoning as .gmw_picks/.gmw_lifecycle)
# so ls(.gmw_server) stays purely token -> handle and .gmw_stop_token() never
# mistakes a session record for a live server handle. This is the SINGLE
# authoritative copy of the whole digitizing state (landmarks, anchors, curves,
# surfaces, template, undo): the browser only reports edits over the loopback
# routes; R owns the record independently of the C engine (tkogl2), which
# Phase 6 deletes (RESEARCH A3). Curves are three landmark INDICES per row, not
# coordinates (RESEARCH Pitfall 5), and are session-scoped -- shared across
# specimens (activeDataList[[1]][[4]], Assumption A7) -- so they live beside
# `current`/`undo` rather than inside a per-specimen record.
.gmw_session <- new.env(parent = emptyenv())

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

#' Build the mixed /pick + /close request handler for one viewport server
#'
#' Returns the per-server \code{call} closure that SUBSUMES
#' \code{.gmw_close_handler}: it is the single \code{call} handler per server and
#' answers both dynamic subpaths. Each server closes over exactly its own
#' \code{token} and, on a pick, writes ONLY \code{.gmw_picks[[token]]} -- never
#' another token's store (cross-token-write guard, T-4-04).
#'
#' On the \code{/pick} branch the raw request body (a bare \code{"x,y,z"} string,
#' NOT JSON -- the project stays JSON-dependency-free, see \code{view3d.R} header)
#' is read with \code{rawToChar(req$rook.input$read())} and parsed with base-R
#' \code{strsplit}/\code{as.numeric}. A row is appended to the server-owned
#' landmark matrix ONLY when the body is exactly three finite numbers
#' (\code{length == 3L && all(is.finite())}); any other body (wrong arity,
#' non-numeric, empty) is silently DROPPED and the array is left unchanged
#' (bounded 3-float payload, no \code{eval}, T-4-02). Both dynamic branches
#' return \code{204}; every other path is a plain \code{404}.
#'
#' Like \code{.gmw_close_handler}, this ONLY pattern-matches the trailing
#' \code{/pick}/\code{/close} on \code{req$PATH_INFO} with \code{grepl}; it NEVER
#' joins the request path to the filesystem via
#' \code{file.path}/\code{normalizePath}/\code{readBin} (path-traversal safety,
#' T-2-02/T-4-01, inherited from Phase 2/3).
#' @param token the per-server token this handler closes over.
#' @return a \code{function(req)} httpuv \code{call} handler.
#' @keywords internal
#' @noRd
.gmw_pick_handler <- function(token) {
  force(token)
  function(req) {
    path <- req$PATH_INFO
    if (grepl("/pick$", path)) {
      # Bare "x,y,z" text body, base-R parse only (no JSON dep). The path is
      # only ever matched with grepl above; it is NEVER joined to the filesystem.
      body <- tryCatch(rawToChar(req$rook.input$read()), error = function(e) "")
      xyz  <- suppressWarnings(as.numeric(strsplit(body, ",", fixed = TRUE)[[1]]))
      if (length(xyz) == 3L && all(is.finite(xyz))) {
        cur <- if (exists(token, envir = .gmw_picks)) get(token, envir = .gmw_picks) else NULL
        assign(token, rbind(cur, matrix(xyz, nrow = 1L)), envir = .gmw_picks)
        dbg(paste0("gmw pick: ", token, " <- ", body))
      }
      return(list(status = 204L, headers = list(), body = ""))
    }
    if (grepl("/close$", path)) {
      later::later(function() .gmw_stop_token(token), 0.5)
      return(list(status = 204L, headers = list(), body = ""))
    }
    list(status = 404L, headers = list("Content-Type" = "text/plain"), body = "")
  }
}

#' Build the digitizing route handler for one viewport server
#'
#' Returns the per-server \code{call} closure that is the FULL Phase-5 route
#' surface. Each server closes over exactly its own \code{token} and writes ONLY
#' \code{.gmw_session[[token]]} -- never another token's record (cross-token-write
#' guard, T-5-06). Like \code{.gmw_pick_handler} it ONLY pattern-matches the
#' trailing suffix on \code{req$PATH_INFO} with \code{grepl}; NO branch ever joins
#' the request path to the filesystem via \code{file.path}/\code{normalizePath}/
#' \code{readBin} (path-traversal safety, T-5-03, inherited T-2-02). Every body is
#' a bare CSV string parsed with base R to a bounded, arity- and finiteness-checked
#' vector (no JSON dependency, no \code{eval}); a non-conforming body is silently
#' DROPPED with \code{204}, never errored (T-5-04).
#'
#' Routes (all POST, all \code{204} on the happy path):
#' \itemize{
#'   \item \code{/anchor} "x,y,z" -> append a coordinate row to the current
#'     specimen's anchor array and push a one-deep \code{place} undo.
#'   \item \code{/curve} "i,j,k" -> three DISTINCT finite integer indices ->
#'     append one integer row to the session curves and push a \code{curve_place}
#'     undo; malformed/duplicate bodies dropped.
#'   \item \code{/delete} "kind,idx" (kind in landmark|anchor|surface) -> remove
#'     that row from the current specimen and push a \code{delete} undo carrying
#'     the removed coord+kind+idx so \code{/undo} can reinsert it.
#'   \item \code{/undo} "" -> invert the one-deep entry.
#'   \item \code{/specimen} "n" -> set the current specimen index (growing the
#'     specimen list with empty records as needed) and clear undo (D-A4 re-serve).
#'   \item \code{/downsample}, \code{/gpa}, \code{/export} "fmt", \code{/save} ->
#'     thin branches that parse/validate only and forward-call the seam functions
#'     implemented in 05-04/05/06 (\code{.gmw_downsample_session},
#'     \code{.gmw_gpa_session}/\code{.gmw_export_session},
#'     \code{.gmw_save_session_dgt}); the format token is validated against the
#'     allow-list \code{c("csv","rds","dgt")} and NEVER treated as a filename
#'     (T-5-05, RESEARCH Security V5).
#' }
#' Any \code{/pick} or \code{/close} request is delegated unchanged to
#' \code{.gmw_pick_handler(token)}; any other suffix is a plain \code{404}.
#' @param token the per-server token this handler closes over.
#' @return a \code{function(req)} httpuv \code{call} handler.
#' @keywords internal
#' @noRd
.gmw_digitize_handler <- function(token) {
  force(token)
  ok204 <- list(status = 204L, headers = list(), body = "")
  function(req) {
    path <- req$PATH_INFO

    # Bare CSV text body; base-R parse only (no JSON dep). `path` is only ever
    # matched with grepl below; it is NEVER joined to the filesystem. Read the
    # body at most once (the rook input stream is single-shot).
    read_body <- function() {
      tryCatch(rawToChar(req$rook.input$read()), error = function(e) "")
    }

    # /close still defers to the untouched pick handler (schedules the stop).
    if (grepl("/close$", path)) {
      return(.gmw_pick_handler(token)(req))
    }

    # Landmark placement (browser "landmark" mode). Phase 4 recorded a pick ONLY
    # in .gmw_picks, but Phase 5's session model is the source of truth for every
    # downstream operation -- delete/undo, the /overlays re-serve, and the
    # analytical seams (.gmw_downsample_session/.gmw_gpa_session/
    # .gmw_export_session/.gmw_save_session_dgt) all read the per-specimen `land`
    # slot. So mirror each pick into BOTH stores: append to the active specimen's
    # `land` with a one-deep "place" undo (exactly like /anchor), AND keep the
    # .gmw_picks record so the record/replay parity harness is unchanged.
    if (grepl("/pick$", path)) {
      xyz <- suppressWarnings(as.numeric(strsplit(read_body(), ",", fixed = TRUE)[[1]]))
      if (length(xyz) == 3L && all(is.finite(xyz))) {
        s   <- .gmw_session_ensure(token)
        cur <- s$current
        rec <- s$specimens[[cur]]
        rec$land <- rbind(rec$land, matrix(xyz, nrow = 1L))
        s$specimens[[cur]] <- rec
        s$undo <- list(action = "place", kind = "landmark",
                       specimen = cur, idx = nrow(rec$land))
        assign(token, s, envir = .gmw_session)
        prev <- if (exists(token, envir = .gmw_picks)) get(token, envir = .gmw_picks) else NULL
        assign(token, rbind(prev, matrix(xyz, nrow = 1L)), envir = .gmw_picks)
        dbg(paste0("gmw pick: ", token))
      }
      return(ok204)
    }

    if (grepl("/anchor$", path)) {
      xyz <- suppressWarnings(as.numeric(strsplit(read_body(), ",", fixed = TRUE)[[1]]))
      if (length(xyz) == 3L && all(is.finite(xyz))) {
        s   <- .gmw_session_ensure(token)
        cur <- s$current
        rec <- s$specimens[[cur]]
        rec$anchor <- rbind(rec$anchor, matrix(xyz, nrow = 1L))
        s$specimens[[cur]] <- rec
        s$undo <- list(action = "place", kind = "anchor",
                       specimen = cur, idx = nrow(rec$anchor))
        assign(token, s, envir = .gmw_session)
        dbg(paste0("gmw anchor: ", token))
      }
      return(ok204)
    }

    if (grepl("/curve$", path)) {
      idx <- suppressWarnings(as.integer(strsplit(read_body(), ",", fixed = TRUE)[[1]]))
      # Three DISTINCT finite integer indices; anything else is dropped.
      if (length(idx) == 3L && !anyNA(idx) && all(is.finite(idx)) &&
          length(unique(idx)) == 3L) {
        s <- .gmw_session_ensure(token)
        s$curves <- rbind(s$curves, matrix(as.integer(idx), nrow = 1L))
        storage.mode(s$curves) <- "integer"
        s$undo <- list(action = "curve_place")
        assign(token, s, envir = .gmw_session)
        dbg(paste0("gmw curve: ", token))
      }
      return(ok204)
    }

    if (grepl("/delete$", path)) {
      parts <- strsplit(read_body(), ",", fixed = TRUE)[[1]]
      if (length(parts) == 2L) {
        kind <- parts[1]
        i    <- suppressWarnings(as.integer(parts[2]))
        slot <- .gmw_session_slot(kind)
        if (!is.na(slot) && !is.na(i) && is.finite(i)) {
          s   <- .gmw_session_ensure(token)
          cur <- s$current
          rec <- s$specimens[[cur]]
          m   <- rec[[slot]]
          if (is.matrix(m) && i >= 1L && i <= nrow(m)) {
            coord <- as.numeric(m[i, ])
            rec[[slot]] <- m[-i, , drop = FALSE]
            s$specimens[[cur]] <- rec
            s$undo <- list(action = "delete", kind = kind,
                           specimen = cur, idx = i, coord = coord)
            assign(token, s, envir = .gmw_session)
            dbg(paste0("gmw delete: ", token))
          }
        }
      }
      return(ok204)
    }

    if (grepl("/undo$", path)) {
      .gmw_session_undo(token)
      return(ok204)
    }

    if (grepl("/specimen$", path)) {
      n <- suppressWarnings(as.integer(strsplit(read_body(), ",", fixed = TRUE)[[1]][1]))
      if (length(n) == 1L && !is.na(n) && is.finite(n) && n >= 1L) {
        s <- .gmw_session_ensure(token)
        while (length(s$specimens) < n) {
          s$specimens[[length(s$specimens) + 1L]] <- .gmw_session_empty_record()
        }
        s$current <- as.integer(n)
        s$undo    <- NULL
        assign(token, s, envir = .gmw_session)
        dbg(paste0("gmw specimen: ", token, " -> ", n))
      }
      return(ok204)
    }

    # Overlay re-serve (DGT-02). GET returns the ACTIVE specimen's current
    # landmark/anchor/surface coordinates so the browser can rebuild every
    # overlay layer after a server-side edit (delete/undo) or a specimen switch.
    # Bare, JSON-free text: "L=<flat>;A=<flat>;S=<flat>" where each <flat> is a
    # row-major comma list of the slot matrix (empty slot -> empty after "=").
    # Coordinates are mesh-LOCAL exactly as stored; the client localToWorld's
    # them against the loaded mesh, mirroring the worldToLocal on placement.
    if (grepl("/overlays$", path)) {
      s   <- .gmw_session_ensure(token)
      rec <- s$specimens[[s$current]]
      flat <- function(m) {
        if (is.matrix(m) && nrow(m) > 0L)
          paste(as.vector(t(m)), collapse = ",") else ""
      }
      body <- paste0("L=", flat(rec$land),
                     ";A=", flat(rec$anchor),
                     ";S=", flat(rec$surfaces))
      return(list(status = 200L,
                  headers = list("Content-Type" = "text/plain"),
                  body = body))
    }

    # Thin forward-call branches: parse/validate only. The seam functions land in
    # 05-04/05/06 and are resolved at call time, so a forward reference is fine;
    # wrapping in try() keeps an as-yet-unimplemented seam a harmless 204 no-op.
    if (grepl("/downsample$", path)) {
      try(.gmw_downsample_session(token), silent = TRUE)
      return(ok204)
    }
    if (grepl("/gpa$", path)) {
      try(.gmw_gpa_session(token), silent = TRUE)
      return(ok204)
    }
    if (grepl("/export$", path)) {
      fmt <- strsplit(read_body(), ",", fixed = TRUE)[[1]][1]
      # Allow-list only; the format token is NEVER treated as or joined to a path.
      if (!is.na(fmt) && fmt %in% c("csv", "rds", "dgt")) {
        try(.gmw_export_session(token, fmt), silent = TRUE)
      }
      return(ok204)
    }
    if (grepl("/save$", path)) {
      try(.gmw_save_session_dgt(token, NULL), silent = TRUE)
      return(ok204)
    }

    # -- Phase-6 browser-shell routes (UI-01) --------------------------------
    # R owns the filesystem, the browse directory, and every chosen path. The
    # browser only ever returns a basename R itself enumerated over /files; no
    # branch below joins a request BODY to the filesystem without first checking
    # membership in that server-owned enumeration (T-6-01/T-6-02, D-03).

    # GET /files -- list the server-owned browse dir, .dgt/.ply only, one name
    # per line. list.files() is non-recursive by default (never descends into or
    # lists parents, T-6-01) and returns bare basenames (no directory component).
    if (grepl("/files$", path)) {
      d <- .gmw_session_browse_dir(token)
      names <- list.files(d, pattern = "\\.(dgt|ply)$", ignore.case = TRUE)
      return(list(status = 200L,
                  headers = list("Content-Type" = "text/plain"),
                  body = paste(names, collapse = "\n")))
    }

    # POST /open -- open a file the browser selected from the /files listing.
    # The body is a bare basename. R re-enumerates the SAME server-owned set and
    # records the chosen path ONLY when the selection is a member of it; `..`,
    # absolute paths, and unlisted names are rejected without touching the
    # filesystem (membership check, never file.path(dir, untrusted), T-6-02/D-03).
    # The reader is tryCatch-wrapped so a malformed .dgt surfaces an error instead
    # of crashing the listener (T-6-03). The concrete server-side effect this plan
    # commits to is recording the validated absolute path on the session; the full
    # specimen load into the session record is wired by the browser-shell plan.
    if (grepl("/open$", path)) {
      sel <- strsplit(read_body(), "\n", fixed = TRUE)[[1]][1]
      if (!is.na(sel) && nzchar(sel)) {
        d       <- .gmw_session_browse_dir(token)
        entries <- list.files(d, pattern = "\\.(dgt|ply)$", ignore.case = TRUE)
        if (sel %in% entries) {
          tryCatch({
            s <- .gmw_session_ensure(token)
            s$opened <- file.path(d, sel)     # join happens AFTER membership only
            assign(token, s, envir = .gmw_session)
            dbg(paste0("gmw open: ", token, " <- ", sel))
          }, error = function(e) NULL)
        }
      }
      return(ok204)
    }

    # POST /savepath -- store a bare save-NAME on the session (R still owns the
    # directory, consistent with /save carrying no path, T-6-05). Reject any name
    # carrying a path separator or `..` so the browser can never steer the write
    # location; only a bare basename is retained.
    if (grepl("/savepath$", path)) {
      nm <- strsplit(read_body(), "\n", fixed = TRUE)[[1]][1]
      if (!is.na(nm) && nzchar(nm) &&
          !grepl("[/\\\\]", nm) && !grepl("\\.\\.", nm)) {
        s <- .gmw_session_ensure(token)
        s$save_name <- nm
        assign(token, s, envir = .gmw_session)
        dbg(paste0("gmw savepath: ", token))
      }
      return(ok204)
    }

    # GET /status -- bare CSV of live specimen index, mode, and per-specimen
    # landmark/anchor/surface counts (no JSON). mode defaults to "landmark" until
    # a mode-set route lands in the browser-shell plan.
    if (grepl("/status$", path)) {
      s   <- .gmw_session_ensure(token)
      rec <- s$specimens[[s$current]]
      nrow0 <- function(m) if (is.matrix(m)) nrow(m) else 0L
      mode  <- if (!is.null(s$mode)) s$mode else "landmark"
      body  <- paste(c(s$current, mode,
                       nrow0(rec$land), nrow0(rec$anchor), nrow0(rec$surfaces)),
                     collapse = ",")
      return(list(status = 200L,
                  headers = list("Content-Type" = "text/plain"),
                  body = body))
    }

    # GET /tabstate -- bare CSV of the server-owned tab-gating flags (0/1) for the
    # digitize / anchor / curve-surface / analysis tabs. Derived live from the
    # active specimen's placement counts so the browser can grey unavailable tabs
    # (mirrors the Tk refreshTabGating gating, now server-owned).
    if (grepl("/tabstate$", path)) {
      s   <- .gmw_session_ensure(token)
      rec <- s$specimens[[s$current]]
      nrow0 <- function(m) if (is.matrix(m)) nrow(m) else 0L
      has_land   <- nrow0(rec$land)   > 0L
      has_anchor <- nrow0(rec$anchor) > 0L
      flags <- c(1L,                                   # digitize: always open
                 as.integer(has_land),                 # anchor: after a landmark
                 as.integer(has_land),                 # curve/surface: after a landmark
                 as.integer(has_land && has_anchor))   # analysis: land + anchor
      return(list(status = 200L,
                  headers = list("Content-Type" = "text/plain"),
                  body = paste(flags, collapse = ",")))
    }

    # POST /msgack -- acknowledge a browser modal message. No state to mutate; the
    # ack simply confirms the message was seen (204). Replaces tkmessageBox's
    # blocking OK with a non-blocking, JSON-free beacon.
    if (grepl("/msgack$", path)) {
      dbg(paste0("gmw msgack: ", token))
      return(ok204)
    }

    # POST /color -- store a chosen colour on the session. The body MUST match a
    # strict #rrggbb hex (base-R regex, no eval, no JSON); a non-matching body is
    # dropped and nothing is stored (T-6-05). Replaces tk_chooseColor.
    if (grepl("/color$", path)) {
      hex <- strsplit(read_body(), "\n", fixed = TRUE)[[1]][1]
      if (!is.na(hex) && grepl("^#[0-9a-fA-F]{6}$", hex)) {
        s <- .gmw_session_ensure(token)
        s$color <- hex
        assign(token, s, envir = .gmw_session)
        dbg(paste0("gmw color: ", token, " <- ", hex))
      }
      return(ok204)
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
#' @param open when \code{TRUE}, attempt to open the URL with
#'   \code{utils::browseURL}, which honours \code{getOption("browser")} /
#'   \code{R_BROWSER} on hosts with no/blocked default browser (D-07). The URL is
#'   always printed first (D-05), so a failed or blocked launch degrades to a
#'   message rather than an error.
#' @param port optional preferred loopback port (D-08). \code{NULL} (the default)
#'   auto-picks a random free port via \code{httpuv::randomPort()}; an integer is
#'   the "fixed port allowed through a lab firewall" case -- selection walks
#'   forward from it through the existing \code{.gmw_pick_port} backup, and if no
#'   port is free through 49151 it raises a clear error rather than hanging (D-09).
#' @param dir the server-owned browse directory the shell file picker lists and
#'   opens from (UI-01/D-03). Seeds the session \code{browse_dir}; defaults to
#'   \code{getwd()}. Stored verbatim (un-normalized); \code{/files} enumerates it
#'   and \code{/open} validates a returned basename against that enumeration, so R
#'   -- never the browser -- owns every path. The rewired \code{GUImorphWeb()}
#'   entry (Plan 03) passes this through.
#' @return the served \code{http://127.0.0.1:<port>/<token>/} URL, invisibly.
#' @keywords internal
#' @noRd
.gmw_serve_mesh <- function(ply_path, title = "GUImorphWeb",
                            background = "#ffffff", open = TRUE, port = NULL,
                            dir = getwd()) {
  if (!file.exists(ply_path)) {
    stop("GUImorphWeb: cannot serve the mesh -- the PLY file was not found.\n",
         "  Looked for: ", ply_path,
         "\n  Pass the path of an existing .ply file to .gmw_serve_mesh().",
         call. = FALSE)
  }

  # Capture the browse root BEFORE the served-tempdir local `dir` below shadows
  # the `dir` argument. This is the file picker's server-owned root (UI-01/D-03).
  browse_dir <- dir

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
  # Mixed static + dynamic routes (RESEARCH Pattern 2/3, D-02). The static byte
  # mount stays byte-for-byte as Phase 2 shipped it (its options are unchanged,
  # T-2-02); alongside it, one excludeStaticPath() entry per dynamic subpath
  # routes exactly those subpaths to R instead of the C++ static thread, and the
  # single `call` handler (.gmw_digitize_handler, which subsumes /pick and /close
  # by delegating to .gmw_pick_handler) answers them all. excludeStaticPath() is
  # preferred over staticPathOptions(fallthrough = TRUE) -- it scopes exactly
  # those subpaths to R rather than routing every missing file there (RESEARCH
  # Alternatives). Phase-5 adds the digitizing edit routes (/anchor, /curve,
  # /delete, /undo, /specimen) and the analytical seams (/downsample, /gpa,
  # /export, /save) beside the inherited /pick and /close. Phase-6 (UI-01) adds
  # the browser-shell routes: the D-03 file picker (/files list, /open selection),
  # plus /savepath, /tabstate, /status, /msgack, /color. Each still gets exactly
  # one excludeStaticPath() entry and is answered by .gmw_digitize_handler.
  dyn_suffixes <- c("close", "pick", "anchor", "curve", "delete", "undo",
                    "specimen", "overlays", "downsample", "gpa", "export", "save",
                    "files", "open", "savepath", "tabstate", "status", "msgack",
                    "color")
  static_map <- c(
    list(httpuv::staticPath(dir)),
    lapply(dyn_suffixes, function(x) httpuv::excludeStaticPath())
  )
  server <- httpuv::startServer(
    host = "127.0.0.1", port = port,
    app = list(
      staticPaths = stats::setNames(
        static_map,
        c(paste0("/", token),
          paste0("/", token, "/", dyn_suffixes))
      ),
      call = .gmw_digitize_handler(token)
    )
  )
  # Retain the handle for the session so gc() does not stop the listener.
  assign(token, server, envir = .gmw_server)

  # Seed the server-owned browse directory for this viewport's session (UI-01/
  # D-03). Ensure creates the empty session lazily; we then set browse_dir to the
  # captured `dir` argument (stored verbatim, un-normalized) so /files and /open
  # enumerate/validate against R's own directory, never a browser-supplied path.
  s <- .gmw_session_ensure(token)
  s$browse_dir <- browse_dir
  assign(token, s, envir = .gmw_session)

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

  # PRINT FIRST (D-05): this line cannot fail and is the guaranteed-correct path.
  # browseURL returns 0 on many platforms even when nothing opened, so the URL is
  # always surfaced -- with a paste fallback -- before any launch is attempted.
  message("Viewport: ", url,
          "\n  If it did not open, paste that URL into a browser.")
  # One-time, start-of-session firewall note (D-06), gated by a flag in
  # .gmw_lifecycle so repeated serves do not spam it. Loopback binds usually do
  # NOT trigger the OS prompt, but managed security suites sometimes do; the
  # note never attempts to suppress the OS prompt.
  if (!isTRUE(.gmw_lifecycle$firewall_noted)) {
    message("  (A firewall prompt may appear on first launch; allowing ",
            "loopback-only access is safe.)")
    .gmw_lifecycle$firewall_noted <- TRUE
  }
  # Attempt the open for convenience only: wrapped so it cannot error, and its
  # return value IGNORED (D-05). browseURL already consults getOption("browser")
  # / R_BROWSER (D-07), so a blocked/misconfigured browser degrades to the URL
  # printed above rather than raising -- no new override machinery is added.
  if (isTRUE(open)) try(utils::browseURL(url), silent = TRUE)
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

#' Read the server-owned landmark matrix for one token
#'
#' Internal accessor over the \code{.gmw_picks} store. Returns the current
#' \code{n x 3} landmark matrix for \code{token}, or \code{NULL} when that token
#' has no placed picks yet. R owns this array; the browser never holds the
#' authoritative coordinates (server-owns-state).
#' @param token the per-viewport token whose landmarks to read.
#' @return an \code{n x 3} numeric matrix, or \code{NULL}.
#' @keywords internal
#' @noRd
.gmw_picks_get <- function(token) {
  if (exists(token, envir = .gmw_picks)) get(token, envir = .gmw_picks) else NULL
}

#' Placed landmarks for a GUImorphWeb viewport
#'
#' Returns the landmark coordinates the browser has reported for a viewport, as
#' an \code{n x 3} numeric matrix (one row per placed pick, in placement order).
#' The coordinates are owned by R -- the browser only reports each click over the
#' loopback \code{/<token>/pick} route, and this reads back the authoritative
#' server-side copy. Called with a \code{token} it returns that one viewport's
#' matrix (or \code{NULL} if nothing has been placed yet); called with no
#' argument it returns a named list of every viewport's matrix, keyed by token.
#' @param token optional token identifying a single viewport -- the segment in
#'   its \code{http://127.0.0.1:<port>/<token>/} URL. \code{NULL} (the default)
#'   returns a named list over all viewports with placed landmarks.
#' @return an \code{n x 3} numeric matrix (or \code{NULL}) for a single token; a
#'   named list of such matrices when \code{token} is \code{NULL}.
#' @examples
#' \dontrun{
#' gmw_picks(token)   # the landmarks placed in this viewport
#' gmw_picks()        # every viewport's landmarks, keyed by token
#' }
#' @export
gmw_picks <- function(token = NULL) {
  if (!is.null(token)) return(.gmw_picks_get(token))
  toks <- ls(.gmw_picks)
  stats::setNames(lapply(toks, .gmw_picks_get), toks)
}

# ---------------------------------------------------------------------------
#  Digitizing session model (.gmw_session) -- accessor + one-deep undo grammar
#
#  R holds the single authoritative per-specimen digitizing record. The helpers
#  below own the shape of that record and the inverse of every mutating action.
#  The route handler (.gmw_digitize_handler) is the ONLY writer; these helpers
#  never touch the request path or the filesystem, so the no-path-join invariant
#  (T-2-02) is a property of the handler alone.
# ---------------------------------------------------------------------------

#' An empty single-specimen digitizing record
#'
#' land/anchor/surfaces start as 0x3 numeric matrices (so \code{rbind} of a
#' single 1x3 row yields a well-typed matrix), template is \code{NULL}.
#' @return a per-specimen record list.
#' @keywords internal
#' @noRd
.gmw_session_empty_record <- function() {
  list(
    land     = matrix(numeric(0), nrow = 0L, ncol = 3L),
    anchor   = matrix(numeric(0), nrow = 0L, ncol = 3L),
    surfaces = matrix(numeric(0), nrow = 0L, ncol = 3L),
    template = NULL
  )
}

#' Read the server-owned digitizing session for one token
#'
#' Internal accessor over the \code{.gmw_session} store. Returns the token's
#' session list, or \code{NULL} when that token has no session yet.
#' @param token the per-viewport token whose session to read.
#' @return the session list, or \code{NULL}.
#' @keywords internal
#' @noRd
.gmw_session_get <- function(token) {
  if (exists(token, envir = .gmw_session)) get(token, envir = .gmw_session) else NULL
}

#' Lazily create an empty single-specimen session for an unknown token
#'
#' curves is a 0x3 INTEGER matrix (curves are landmark indices, RESEARCH Pitfall
#' 5); undo is one-deep and starts \code{NULL}. Session-level curves and undo sit
#' beside the specimen list because curves are shared across specimens (A7).
#' \code{browse_dir} is the server-owned directory the shell file picker lists
#' and opens from (UI-01/D-03); it defaults to \code{getwd()} and is reseeded by
#' \code{.gmw_serve_mesh(dir = ...)}. It is a SESSION-level slot (not per-specimen)
#' because one browse root serves every specimen in a viewport. R owns this path;
#' the browser never sends it -- it only returns a basename R itself enumerated.
#' @param token the per-viewport token to initialise.
#' @return the freshly created session list (also stored in \code{.gmw_session}).
#' @keywords internal
#' @noRd
.gmw_session_init <- function(token) {
  s <- list(
    specimens  = list(.gmw_session_empty_record()),
    current    = 1L,
    curves     = matrix(integer(0), nrow = 0L, ncol = 3L),
    undo       = NULL,
    browse_dir = getwd()
  )
  assign(token, s, envir = .gmw_session)
  s
}

#' Return the token's session, creating an empty one on first use
#' @param token the per-viewport token.
#' @return the session list.
#' @keywords internal
#' @noRd
.gmw_session_ensure <- function(token) {
  s <- .gmw_session_get(token)
  if (is.null(s)) s <- .gmw_session_init(token)
  s
}

#' The server-owned browse directory for one token's file picker
#'
#' Returns the session \code{browse_dir} (seeded by \code{.gmw_serve_mesh(dir=)}),
#' falling back to \code{getwd()} for a session that predates the slot or was
#' created lazily by a route before any serve. This is the ONLY directory the
#' \code{/files} listing and \code{/open} membership check ever read (UI-01/D-03):
#' R owns it end to end, so a browser-supplied path can never widen it.
#' @param token the per-viewport token.
#' @return a length-1 directory path string.
#' @keywords internal
#' @noRd
.gmw_session_browse_dir <- function(token) {
  s <- .gmw_session_ensure(token)
  if (!is.null(s$browse_dir)) s$browse_dir else getwd()
}

#' Map a route kind ("landmark"/"anchor"/"surface") to its record slot name
#' @param kind one of "landmark", "anchor", "surface".
#' @return the slot name ("land"/"anchor"/"surfaces"), or \code{NA} if unknown.
#' @keywords internal
#' @noRd
.gmw_session_slot <- function(kind) {
  switch(kind, landmark = "land", anchor = "anchor", surface = "surfaces",
         NA_character_)
}

#' Overwrite the one-deep undo entry for a token (mirrors pushUndo)
#'
#' One-deep by design (matches the Tk \code{pushUndo}/\code{doUndo} grammar in
#' 3dDigitize.digitize.r): a new mutating action always replaces the previous
#' undo entry, so only the most recent action is reversible.
#' @param token the per-viewport token.
#' @param entry an undo entry list (action + fields the inverse needs).
#' @return \code{invisible(TRUE)}.
#' @keywords internal
#' @noRd
.gmw_session_push_undo <- function(token, entry) {
  s <- .gmw_session_ensure(token)
  s$undo <- entry
  assign(token, s, envir = .gmw_session)
  invisible(TRUE)
}

#' Clear the one-deep undo entry for a token (mirrors clearUndo)
#' @param token the per-viewport token.
#' @return \code{invisible(TRUE)}.
#' @keywords internal
#' @noRd
.gmw_session_clear_undo <- function(token) {
  s <- .gmw_session_get(token)
  if (is.null(s)) return(invisible(TRUE))
  s$undo <- NULL
  assign(token, s, envir = .gmw_session)
  invisible(TRUE)
}

#' Invert the one-deep undo entry for a token (mirrors doUndo)
#'
#' Reverses the last recorded action and returns whether anything was undone.
#' Supported actions mirror the Tk grammar: \code{place} (drop the appended
#' row), \code{delete} (reinsert the removed coord at its original index),
#' \code{move} (restore the pre-move coord), and \code{curve_place} (drop the
#' last session curve row). On success the undo entry is cleared (one-deep).
#' @param token the per-viewport token.
#' @return \code{TRUE} if an action was inverted, else \code{FALSE}.
#' @keywords internal
#' @noRd
.gmw_session_undo <- function(token) {
  s <- .gmw_session_get(token)
  if (is.null(s) || is.null(s$undo)) return(FALSE)
  entry <- s$undo
  ok <- FALSE

  if (identical(entry$action, "place")) {
    slot <- .gmw_session_slot(entry$kind)
    spx  <- entry$specimen
    if (!is.na(slot) && !is.null(spx) && spx >= 1L && spx <= length(s$specimens)) {
      m <- s$specimens[[spx]][[slot]]
      if (is.matrix(m) && nrow(m) >= 1L) {
        idx <- if (!is.null(entry$idx)) entry$idx else nrow(m)
        s$specimens[[spx]][[slot]] <- m[-idx, , drop = FALSE]
        ok <- TRUE
      }
    }
  } else if (identical(entry$action, "delete")) {
    slot <- .gmw_session_slot(entry$kind)
    spx  <- entry$specimen
    if (!is.na(slot) && !is.null(spx) && spx >= 1L && spx <= length(s$specimens)) {
      m <- s$specimens[[spx]][[slot]]
      if (!is.matrix(m)) m <- matrix(numeric(0), nrow = 0L, ncol = 3L)
      coord <- matrix(as.numeric(entry$coord), nrow = 1L, ncol = 3L)
      n   <- nrow(m)
      idx <- entry$idx
      if (is.null(idx) || idx > n) {
        m2 <- rbind(m, coord)
      } else {
        upper <- if (idx > 1L) m[seq_len(idx - 1L), , drop = FALSE] else m[0, , drop = FALSE]
        lower <- if (idx <= n) m[idx:n, , drop = FALSE]           else m[0, , drop = FALSE]
        m2 <- rbind(upper, coord, lower)
      }
      s$specimens[[spx]][[slot]] <- m2
      ok <- TRUE
    }
  } else if (identical(entry$action, "move")) {
    slot <- .gmw_session_slot(entry$kind)
    spx  <- entry$specimen
    if (!is.na(slot) && !is.null(spx) && spx >= 1L && spx <= length(s$specimens)) {
      m   <- s$specimens[[spx]][[slot]]
      idx <- entry$idx
      if (is.matrix(m) && !is.null(idx) && idx >= 1L && idx <= nrow(m)) {
        m[idx, ] <- as.numeric(entry$before)
        s$specimens[[spx]][[slot]] <- m
        ok <- TRUE
      }
    }
  } else if (identical(entry$action, "curve_place")) {
    cm <- s$curves
    if (is.matrix(cm) && nrow(cm) >= 1L) {
      s$curves <- cm[-nrow(cm), , drop = FALSE]
      ok <- TRUE
    }
  }

  if (ok) {
    s$undo <- NULL
    assign(token, s, envir = .gmw_session)
  }
  ok
}

#' Digitizing session for a GUImorphWeb viewport
#'
#' Returns the server-owned digitizing record for a viewport: a list with the
#' per-specimen \code{specimens} (each holding \code{land}/\code{anchor}/
#' \code{surfaces}/\code{template}), the \code{current} specimen index, the
#' session-level \code{curves} (an integer matrix of landmark-index triples,
#' shared across specimens), and the one-deep \code{undo} entry. R owns this
#' record -- the browser only reports edits over the loopback
#' \code{/<token>/anchor}, \code{/curve}, \code{/delete}, \code{/undo}, and
#' \code{/specimen} routes, and this reads back the authoritative server-side
#' copy. Called with a \code{token} it returns that one viewport's session (or
#' \code{NULL} if nothing has been edited yet); called with no argument it
#' returns a named list of every viewport's session, keyed by token.
#' @param token optional token identifying a single viewport -- the segment in
#'   its \code{http://127.0.0.1:<port>/<token>/} URL. \code{NULL} (the default)
#'   returns a named list over all viewports with a session.
#' @return the session list (or \code{NULL}) for a single token; a named list of
#'   such lists when \code{token} is \code{NULL}.
#' @examples
#' \dontrun{
#' gmw_session(token)   # this viewport's digitizing record
#' gmw_session()        # every viewport's record, keyed by token
#' }
#' @export
gmw_session <- function(token = NULL) {
  if (!is.null(token)) return(.gmw_session_get(token))
  toks <- ls(.gmw_session)
  stats::setNames(lapply(toks, .gmw_session_get), toks)
}

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
