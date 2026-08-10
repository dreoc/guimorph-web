# Phase 3: Offline Packaging and Lifecycle - Research

**Researched:** 2026-08-03
**Domain:** R-package lifecycle (finalizers / namespace hooks), `httpuv` mixed static+dynamic apps, loopback server teardown, offline install proof, browser-launch degradation
**Confidence:** HIGH (httpuv API and the mixed-app teardown pattern verified against the installed `httpuv 1.6.17` / `later 1.4.8` / R 4.6.1 with a working loopback test; base-R lifecycle-hook semantics verified against `?reg.finalizer` and `?ns-hooks`)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Teardown**
- **D-01:** Multiple teardown triggers, all required. A closed listener must never orphan.
  - **Explicit stop function** — user-callable `gmw_close()` / `gmw_stop()`.
  - **R session end** — `reg.finalizer(.gmw_server, onexit = TRUE)` so quitting R stops every live listener.
  - **Package unload/detach** — `.onUnload()` stops all live servers when the namespace unloads (closes the `detach()`-mid-session orphan path).
  - **Browser-tab close** — honored (see D-02), not accepted as unhandled.
- **D-02:** Tab-close detection via `navigator.sendBeacon('/close')` on page `unload` + one dynamic `/close` route mounted beside the static path. Closing the tab stops that token's server. **Consequence for the planner:** the httpuv app is no longer static-only — it becomes a mixed app (`staticPaths` for the bundle/specimen/page **plus** a `call`/handler route for `/close`). Keep the static byte path exactly as-is (path-traversal safety, T-2-02); the `/close` handler only stops the server for its own token.

**Concurrent viewports**
- **D-03:** Many concurrent viewports allowed. `.gmw_server` is already token-keyed; keep every live server independent. Each is torn down on its own by its tab beacon (D-02) or by `gmw_close(token)`. (Multiple viewport windows, each still one specimen per viewport — consistent with Phase 2 D-01; this is about window count, not in-page specimen switching.)
- **D-04:** `gmw_close()` shape — no argument stops **all** live servers; optional `token` argument stops **one**. Covers both single- and multi-viewport cleanup and backs the explicit-stop trigger in D-01.

**Browser-launch degradation**
- **D-05:** Always print the URL first, then attempt `browseURL()`, and **never trust its return value** (it returns 0 on many platforms even when nothing opened). Message carries a paste-fallback, e.g. `Viewport: <url> — if it did not open, paste this into a browser.` Print-first cannot fail.
- **D-06:** Firewall prompt on first loopback bind — surface a short start-time message that a firewall prompt may appear and that allowing loopback-only access is safe, and document it. Do not attempt to suppress the OS prompt.
- **D-07:** Honor R's built-in browser override (`getOption("browser")` / `R_BROWSER`, which `browseURL()` already consults) for hosts with no/blocked default browser. Document it; add no new override machinery.

**Port-occupied UX**
- **D-08:** Expose an optional preferred-port argument on the entry function: `NULL` → `randomPort()` default; an integer → walk-forward-from-that-port backup (already coded in `.gmw_pick_port`). Surfaces the "fixed port allowed through a lab firewall" case from REFERENCE-ARCHITECTURE.
- **D-09:** When a supplied preferred port cannot be satisfied (walk-forward reaches 49151), keep an actionable clear R-level `stop()` — name the tried range and say to free a port or omit the port argument to auto-pick. A clear error, never a hang (Criterion 3).

**Offline self-check**
- **D-10:** No `gmw_check()` diagnostic shipped in this phase. WEB-03 stays verification-only: manual UAT + an automated smoke test proving a clean, fully-offline install opens a working viewport on Windows and macOS. (A full-scope diagnostic is recorded as a deferred idea below.)

### Claude's Discretion
- Exact function names/signatures (`gmw_close` vs `gmw_stop`, entry-point port arg name), the `/close` route shape and token-matching detail, and the precise wording of the start-time firewall/paste messages — planner decides, following the decisions above and the server-owns-state pattern.
- Exact form of the WEB-03 offline smoke test (test harness vs UAT script split).

### Deferred Ideas (OUT OF SCOPE)
- **`gmw_check()` offline diagnostic** — a read-only self-check probing: vendored bundle present (`system.file`), a loopback port bindable, browser resolvable, and `tkogl2` oracle load status (CMP-01), printing pass/fail per probe. Considered and deferred for Phase 3 (WEB-03 stays verification-only); if revisited, ship the full four-probe scope.
- **Heartbeat / idle-timeout teardown** — more crash-robust than the `sendBeacon` unload approach, but more moving parts; not needed for Phase 3.
- **`dat-parity-gate-is-a-skip.md`** — `phase: 5`, `.dgt` byte-parity, not offline packaging. Out of scope here.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WEB-03 | A clean `install.packages()` on a fresh R opens a working viewport with the machine fully offline, on Windows and macOS (vendoring itself landed in Phase 1 / WEB-00). | Offline-install/smoke-test technique (§Code Examples "Offline install smoke test"; §Validation Architecture). Bundle already ships in `inst/htmlwidgets/` (verified present). `install.packages(tarball, repos=NULL)` proves no-network install; page has zero external references (offline by construction). |
| WEB-04 | Port selection, browser launch, and teardown reliable on a managed machine: occupied ports fail with a clear R error not a hang; no orphaned listener survives; missing/misconfigured/blocked default browser degrades legibly. | Teardown mapping (§Architecture Pattern 1–4), `httpuv` mixed-app `/close` route (verified), port UX on existing `.gmw_pick_port` (D-08/D-09), browser degradation (D-05/D-06/D-07). |
| CMP-01 | Retained native `tkogl2` oracle stays loadable/functional (recurring gate). | `.onLoad` engine-load path in `rtkogl.R` is untouched by lifecycle work; assert `.gmw_engine$ok` unchanged. Re-run `library()` load gate on a display host (owed from Phase 2). |
</phase_requirements>

## Summary

Phase 3 is almost entirely **R-side lifecycle plumbing over code that already exists**. Phase 2 shipped a static-only `httpuv` listener (`.gmw_serve_mesh()` in `R/transport.R`) with a token-keyed retained-handle registry (`.gmw_server`), a `randomPort`-primary / walk-forward-backup port picker (`.gmw_pick_port`), an injectable free-port probe (`.gmw_probe_free`), and a print-then-open delivery shape. Phase 3 adds **teardown** (four triggers), converts the app from static-only to **mixed static + one dynamic `/close` route**, **surfaces** the already-coded preferred-port backup as a user argument with a clear exhaustion error, and hardens the **browser-launch** messaging. Nothing new is invented at the transport layer; the risk is concentrated in getting the httpuv threading model and the R lifecycle hooks exactly right.

The single most important verified fact for the planner: **httpuv static paths are served on a background C++ thread and never touch R, while a `call` handler runs on the R main thread via `later::later()`.** This has three consequences. (1) The `/close` route is a real R callback, so it must not be invoked synchronously from the same R process (a same-process `curl` to it starves — R is blocked and the callback never runs; **verified**). (2) A handler must not call `stopServer()` on its own listener synchronously mid-request; schedule the stop with `later::later()` and return `204` first. (3) The existing Phase-2 guard test that scans `transport.R` for the literal string `PATH_INFO` (`test-transport.R:59`) **will break** the moment a `/close` handler reads `req$PATH_INFO`, and must be re-scoped to the real invariant (no request-path → filesystem join).

The second load-bearing fact: **`.onUnload()` does NOT run at normal R-session exit** (verified against `?ns-hooks`: "packages are not detached nor namespaces unloaded at the end of an R session"). So the D-01 trigger split is correct and necessary — `reg.finalizer(onexit=TRUE)` is the *only* session-end hook, and `.onUnload()` covers the separate `unloadNamespace()` / `detach(unload=TRUE)` path.

**Primary recommendation:** Mount `/<token>/close` as an `httpuv::excludeStaticPath()` beside the existing token static mount, handle it in a per-server `call` closure that captures its own `token`/handle (so it never parses an untrusted path), schedule teardown via `later::later(stopServer, delay)`, and drive all four D-01 triggers through one shared `.gmw_stop_token()` helper that iterates the existing `.gmw_server` registry (never `stopAllServers()`, which would kill other packages' servers).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Server launch + lifecycle registry | API/Backend (R) | — | `.gmw_server` env owns handles; R starts/stops listeners |
| Port selection + occupied-port error | API/Backend (R) | — | `.gmw_pick_port` / `randomPort` are R; error is an R `stop()` |
| Static byte serving (bundle/specimen/page) | CDN/Static (httpuv C++ thread) | — | `staticPaths` bypass R entirely; keep exactly as-is (T-2-02) |
| `/close` route (tab-close teardown) | API/Backend (R `call` handler) | Browser/Client (fires it) | Runs on R thread via `later`; stops its own token's listener |
| Tab-close detection | Browser/Client (page JS) | API/Backend (receives beacon) | `navigator.sendBeacon` fires from the page on `pagehide` |
| Browser launch + degradation messaging | API/Backend (R) | — | `message()` + `utils::browseURL()`; honors `getOption("browser")` |
| Offline bundle availability | CDN/Static (installed package) | — | `system.file("htmlwidgets", ...)`; shipped by WEB-00, no runtime fetch |
| Native `tkogl2` oracle load (CMP-01) | API/Backend (R `.onLoad`) | — | Untouched by this phase; assert `.gmw_engine$ok` stays true |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `httpuv` | 1.6.17 | Loopback HTTP server; mixed `staticPaths` + `call` app; `stopServer`/`listServers`/`randomPort` | Already a locked Import (Phase 2, WEB-01); the R-ecosystem building block for local servers (used by shiny/plumber) `[VERIFIED: installed pkg + renv.lock]` |
| `later` | 1.4.8 | Schedule the deferred `stopServer()` from inside the `/close` handler; drives httpuv's R-thread callbacks | Hard (transitive) dependency of httpuv — already present, no new Import `[VERIFIED: installed pkg]` |
| base R (`reg.finalizer`, `.onUnload`) | 4.6.1 | Session-end and namespace-unload teardown hooks | Standard R package lifecycle machinery `[VERIFIED: ?reg.finalizer, ?ns-hooks]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `curl` | Suggests (test-only) | Loopback GETs in the smoke/transport tests | Already used by `helper-transport.R`; `skip_if_not_installed("curl")` guards it `[VERIFIED: existing tests]` |
| `callr` / `processx` | optional new Suggests | Out-of-process integration test that actually hits the `/close` route over a socket | Only if an end-to-end `/close` test is wanted; the direct-closure unit test (recommended) needs neither `[ASSUMED]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `excludeStaticPath()` for `/close` | `staticPathOptions(fallthrough = TRUE)` | Both verified working. `fallthrough=TRUE` routes *any* missing static file to R (broader surface, easy to leak a wrong 404 path); `excludeStaticPath()` scopes exactly one subpath to R. Prefer `excludeStaticPath()`. |
| `reg.finalizer` + `.onUnload` split | `.Last.lib` (exported) / `.onDetach` | `.Last.lib`/`.onDetach` fire on `detach()`, not on `q()`; they do not cover session end. The D-01 split (`reg.finalizer(onexit=TRUE)` + `.onUnload`) is the correct one. |
| `sendBeacon` on `pagehide` | XHR/`fetch` with `keepalive` on `unload` | `sendBeacon` is purpose-built for unload-time fire-and-forget POSTs and is the more reliable choice; `unload` itself is the unreliable part (see Pitfall 4). |

**Installation:** No new runtime dependencies. `httpuv` and `later` are already installed/locked; `curl` stays Suggests. (Optionally add `callr` to Suggests only if an out-of-process `/close` test is chosen.)

## Package Legitimacy Audit

No **new** external packages are installed in this phase — all runtime code sits on dependencies already present.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| httpuv | CRAN | mature (Posit) | very high | github.com/rstudio/httpuv | OK | Already an Import (Phase 2) |
| later | CRAN | mature (Posit) | very high | github.com/r-lib/later | OK | Already transitive via httpuv |
| curl | CRAN | mature (Jeroen Ooms) | very high | github.com/jeroen/curl | OK | Already Suggests (test-only) |
| callr | CRAN | mature (r-lib) | very high | github.com/r-lib/callr | OK | Optional; add to Suggests only if used |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```
  R session (main thread)
  ├── .gmw_serve_mesh(ply, port = NULL, open = TRUE)        [entry point — extended]
  │      ├── .gmw_pick_port(prefer = port)                  NULL → randomPort();
  │      │        └── on exhaustion (→49151): stop()  ──────► clear R error (D-09), never a hang
  │      ├── .gmw_token()  → per-session >=128-bit path segment
  │      ├── writes tempdir: guimorphweb-three.js + specimen.ply + index.html
  │      ├── httpuv::startServer("127.0.0.1", port, app)
  │      │        app = list(
  │      │          staticPaths = { "/<token>" : staticPath(dir),          ── served on C++ thread (no R)
  │      │                          "/<token>/close" : excludeStaticPath() } ── routed to R
  │      │          call = function(req){ if PATH_INFO ~ /close$ →
  │      │                     later::later(stop this token, delay); 204 } )
  │      ├── assign(token, server, .gmw_server)             [retained-handle registry, existing]
  │      ├── message("Viewport: <url> — paste if it didn't open")  ── PRINT FIRST (D-05), cannot fail
  │      ├── message(firewall start-time note)              (D-06)
  │      └── tryCatch(utils::browseURL(url)) — return value ignored (D-05/D-07)
  │
  ├── gmw_close(token = NULL)  → iterate .gmw_server, stopServer(), rm()   (D-04, explicit)
  ├── reg.finalizer(.gmw_server, stop-all, onexit = TRUE) → runs at q()    (D-01, session end)
  └── .onUnload(libpath)       → stop-all on unloadNamespace()             (D-01, ns unload)

  Browser tab  ──(pagehide)──► navigator.sendBeacon("<url>close")  ──► /close route ──► server stops (D-02)

  .onLoad(): tcl("load", tkogl2, "Tkogl2") → .gmw_engine$ok   [CMP-01 gate — UNCHANGED this phase]
```

### Recommended Project Structure

No new files required; extend in place (mirrors CONTEXT `canonical_refs`).

```
R/
├── transport.R      # EXTEND: add /close to the app (excludeStaticPath + call),
│                    #   port arg on the entry fn, D-09 error wording, launch
│                    #   messaging, .gmw_stop_token()/gmw_close(), reg.finalizer,
│                    #   .onUnload  (all lifecycle state lives beside .gmw_server)
├── view3d.R         # EXTEND: add the sendBeacon(pagehide) unload hook to
│                    #   GMW_VIEW3D_TEMPLATE (page side of D-02)
└── rtkogl.R         # DO NOT TOUCH the .onLoad engine-load path (CMP-01)
tests/testthat/
├── test-transport.R # EDIT the PATH_INFO guard (see Pitfall 3); add teardown +
│                    #   close-handler + port-UX + degradation tests
└── test-offline-smoke.R  # NEW: offline install/serve/byte-identity smoke (WEB-03)
```

### Pattern 1: Teardown that never orphans — one helper, four triggers

**What:** All four D-01 triggers funnel into a single registry-driven stop so behavior can't drift between them.
**When to use:** Every teardown path.
**Example:**

```r
# Stop one token (or all when token = NULL). Iterates OUR registry only.
# NEVER call httpuv::stopAllServers() — it stops every httpuv server in the
# process, including shiny/plumber servers a user may also be running.
.gmw_stop_token <- function(token = NULL) {
  toks <- if (is.null(token)) ls(.gmw_server) else token
  for (t in toks) {
    srv <- tryCatch(get(t, envir = .gmw_server), error = function(e) NULL)
    if (!is.null(srv)) try(httpuv::stopServer(srv), silent = TRUE)
    if (exists(t, envir = .gmw_server)) rm(list = t, envir = .gmw_server)
  }
  invisible(TRUE)
}

#' @export
gmw_close <- function(token = NULL) .gmw_stop_token(token)   # D-04

# Register ONCE (e.g. lazily on first serve, guarded by a flag in .gmw_server):
# runs at q()/R session end. .onUnload does NOT run at session end, so this is
# the only session-end hook. (verified: ?ns-hooks)
reg.finalizer(.gmw_server, function(e) .gmw_stop_token(NULL), onexit = TRUE)   # D-01

# Namespace unload / detach(unload=TRUE): the separate orphan path.
.onUnload <- function(libpath) .gmw_stop_token(NULL)          # D-01
```

### Pattern 2: Mixed app — static bytes untouched, one dynamic `/close`

**What:** Add exactly one R-handled route beside the static mount, keeping the static byte path byte-for-byte as Phase 2 shipped it. **Verified working** against httpuv 1.6.17.
**When to use:** The D-02 conversion from static-only → mixed.
**Example:**

```r
# Each server is its own listener on its own port with its own token, so the
# handler CLOSES OVER its token/handle — it never joins an untrusted request
# path to the filesystem (preserves T-2-02). It only recognizes the close path.
app <- list(
  staticPaths = stats::setNames(
    list(httpuv::staticPath(dir), httpuv::excludeStaticPath()),
    c(paste0("/", token), paste0("/", token, "/close"))
  ),
  call = function(req) {
    if (grepl("/close$", req$PATH_INFO)) {
      # Do NOT stopServer() synchronously here (see Pitfall 2). Schedule it and
      # return first; sendBeacon ignores the response anyway.
      later::later(function() .gmw_stop_token(token), 0.5)
      return(list(status = 204L, headers = list(), body = ""))
    }
    list(status = 404L, headers = list("Content-Type" = "text/plain"), body = "")
  }
)
```

### Pattern 3: Page-side tab-close beacon (view3d.R)

**What:** Fire a fire-and-forget POST to the token's `/close` when the page goes away.
**When to use:** The page half of D-02, added to `GMW_VIEW3D_TEMPLATE`.
**Example:**

```js
// Prefer pagehide over the (unreliable, deprecated) unload event; add a
// visibilitychange backstop. sendBeacon is same-origin here, so no CORS issue.
function gmwClose(){ try { navigator.sendBeacon("close"); } catch(e){} }
window.addEventListener("pagehide", gmwClose);
document.addEventListener("visibilitychange", function(){
  if (document.visibilityState === "hidden") gmwClose();
});
// "close" resolves relative to the page URL http://127.0.0.1:PORT/<token>/  ->
// http://127.0.0.1:PORT/<token>/close  (same token, no server-side path parsing)
```

### Pattern 4: Port UX — surface the existing backup, error on exhaustion

**What:** Add a `port = NULL` argument that flows straight into the existing `.gmw_pick_port(prefer = port)`; NULL → `randomPort()`, integer → walk-forward. Sharpen the exhaustion `stop()` to name the tried range (D-09).
**Example:**

```r
# .gmw_serve_mesh(ply_path, ..., port = NULL)
port <- .gmw_pick_port(prefer = port)   # existing selector, now user-driven (D-08)

# In .gmw_pick_port, when walk-forward reaches 49151 (D-09):
stop("GUImorphWeb: no free port from ", prefer, " through 49151.\n",
     "  Free a port in that range, or omit `port` to auto-pick a random one.",
     call. = FALSE)
```

### Anti-Patterns to Avoid
- **`httpuv::stopAllServers()` for teardown.** It stops *every* httpuv server in the R process — a user running shiny/plumber alongside would lose those too. Iterate `.gmw_server` and stop only owned handles.
- **Synchronous `stopServer()` inside the `/close` handler.** Tears the socket down before the response flushes (see Pitfall 2). Schedule via `later`.
- **Joining `req$PATH_INFO` to a filesystem path in the `call` handler.** That would reintroduce the traversal risk T-2-02 the static path avoids. The handler must only *pattern-match* the close path, never open a file from it.
- **Relying on `.onUnload()` for session-end cleanup.** It does not fire at `q()`. Session end is `reg.finalizer(onexit=TRUE)` only.
- **Trusting `browseURL()`'s return value.** It returns 0 on many platforms even when nothing opened (D-05). Print first, always.
- **Adding a CDN/external `src`/`href` to the page.** Breaks WEB-03 offline-by-construction.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deferred teardown after responding | A busy-wait / `Sys.sleep` before stopping | `later::later(fn, delay)` | Already loaded (httpuv dep); integrates with httpuv's own R-thread scheduling |
| Free-port selection | A hand-rolled bind/close scan | `httpuv::randomPort()` (primary) + existing `.gmw_pick_port` walk-forward (backup) | randomPort probes up to 20 free unprivileged loopback ports; already coded |
| Session-end / unload cleanup | An `.Last`/`options(error=...)` shim | `reg.finalizer(onexit=TRUE)` + `.onUnload()` | The documented, correct R hooks for exactly these two events |
| Tab-close ping | A polling heartbeat / websocket idle timer | `navigator.sendBeacon()` on `pagehide` | Purpose-built for unload-time; fewer moving parts (explicit CONTEXT decision D-02) |
| Browser override for locked-down hosts | New env var / option machinery | `getOption("browser")` / `R_BROWSER` (already consulted by `browseURL`) | D-07: document, add nothing |

**Key insight:** Every hard part of this phase already has a correct answer in the current tree or in a loaded dependency. The failure mode here is *re-implementing* one of them (a custom port scanner, a custom cleanup hook, a heartbeat) rather than wiring the existing pieces to the four triggers.

## Runtime State Inventory

Not a rename/refactor/migration phase — omitted per format. The one piece of live runtime state that matters (orphaned `httpuv` listeners surviving teardown) is the subject of Pattern 1 and Pitfall 1, and is exercised by the teardown tests in §Validation Architecture.

## Common Pitfalls

### Pitfall 1: An orphaned listener survives a partial teardown
**What goes wrong:** A server is stopped but its handle stays in `.gmw_server` (or vice-versa), so a later stop-all misses it, or `listServers()` still shows it.
**Why it happens:** Stopping and de-registering are two steps; if only one runs, the registry lies.
**How to avoid:** `.gmw_stop_token()` must both `stopServer()` **and** `rm()` the entry, wrapped in `try()` so one bad handle doesn't abort the loop (Pattern 1). Assert `length(ls(.gmw_server)) == 0` **and** `length(httpuv::listServers()) == 0` after stop-all in tests.
**Warning signs:** `httpuv::listServers()` non-empty after `gmw_close()`; a second `.gmw_serve_mesh()` on a fixed port reports "in use."

### Pitfall 2: Stopping the server inside its own request handler resets the connection
**What goes wrong:** Calling `httpuv::stopServer(srv)` synchronously in the `/close` `call` returns a connection reset instead of a clean `204`. **Observed in verification** (client got no response even with a delayed-but-same-tick stop).
**Why it happens:** The handler is mid-request on the R thread; tearing the listener down pulls the socket out from under the in-flight response.
**How to avoid:** `return()` the `204` first and schedule the stop with `later::later(fn, delay)` (delay ~0.3–0.5s). `sendBeacon` ignores the response, so the reset is harmless in production — but scheduling is still the correct, clean pattern.
**Warning signs:** Intermittent "connection reset" in any client that reads the `/close` response.

### Pitfall 3: The Phase-2 `PATH_INFO` guard test breaks the moment `/close` exists
**What goes wrong:** `test-transport.R:59` asserts `expect_false(any(grepl("PATH_INFO", src, fixed = TRUE)))` over `transport.R`. A `/close` handler that reads `req$PATH_INFO` makes that assertion fail — a *healthy* change trips a *stale* guard.
**Why it happens:** The Phase-2 guard used "no `PATH_INFO` anywhere" as a proxy for "the static byte path does not join a request path to the filesystem." Once a legitimate dynamic route exists, the proxy is wrong.
**How to avoid:** Re-scope the guard to the real invariant: assert the `call` handler does **not** `file.path()`/`normalizePath()`/`readBin()` anything derived from `req$PATH_INFO` (i.e. the close handler only pattern-matches and calls `stopServer`). Keep the `0.0.0.0`-absent and `staticPath`-present assertions as-is.
**Warning signs:** A red `test-transport.R` immediately after adding the route, on the PATH_INFO line specifically.

### Pitfall 4: `unload` is an unreliable event; the beacon may not fire
**What goes wrong:** Relying on the `unload` event (as literally named in D-02) can miss tab closes — `unload` is deprecated/unreliable on modern browsers (bfcache, mobile, background discards).
**Why it happens:** Browsers increasingly skip `unload` to preserve the back/forward cache.
**How to avoid:** Fire `sendBeacon` from `pagehide` (and a `visibilitychange → hidden` backstop) rather than `unload`. This honors the D-02 intent (tab-close teardown via `sendBeacon('/close')`) with the reliable event. Also: tab-close is a *best-effort* trigger — `reg.finalizer` and `gmw_close()` are the guarantees, so a missed beacon never orphans past session end.
**Warning signs:** Server still listening after a tab close in a browser with bfcache enabled.

### Pitfall 5: You cannot test the `/close` route with same-process `curl`
**What goes wrong:** A test that does `curl_fetch_memory("<url>/close")` from the serving R process hangs/returns NULL. **Verified.**
**Why it happens:** `call` handlers run on the R main thread via `later`; while R is blocked inside `curl_fetch_memory`, the callback never runs, so the request is never answered. (Static byte paths work in-process because they bypass R on the C++ thread.)
**How to avoid:** Test the `/close` handler by invoking the `call` closure directly with a synthetic `req = list(PATH_INFO = "/<token>/close")` and asserting it returns `204` and schedules/performs the stop. For a true end-to-end socket test, drive the request from a **separate process** (`callr::r_bg`/`processx`). Prefer the direct-closure unit test (no new dependency).
**Warning signs:** A `/close` integration test that never returns.

### Pitfall 6: `install.packages(dependencies=TRUE)` reaches the network during the "offline" smoke test
**What goes wrong:** The smoke test installs the tarball and silently pulls Imports from CRAN, so it isn't proving an *offline* install.
**Why it happens:** Default `install.packages` resolves dependencies from `repos`.
**How to avoid:** Install with `repos = NULL, type = "source", dependencies = FALSE` into a temp lib that already has geomorph/Rvcg/tcltk/tcltk2/httpuv present (they're pre-installed on the target). Assert the vendored bundle resolves via `system.file()` and the served page contains **zero** external `src=`/`href=`/`fetch(<http…>)` references.
**Warning signs:** The smoke test fails when the machine's network is physically off.

## Code Examples

### Register the session-end finalizer exactly once (lazy, on first serve)

```r
# Guard so repeated .gmw_serve_mesh() calls register only one finalizer.
if (!isTRUE(.gmw_server$.finalizer_registered)) {
  reg.finalizer(.gmw_server, function(e) .gmw_stop_token(NULL), onexit = TRUE)
  .gmw_server$.finalizer_registered <- TRUE
}
# NOTE: .finalizer_registered is a reserved key in .gmw_server; make sure
# ls()/iteration in .gmw_stop_token() skips non-server entries (e.g. filter to
# handles, or keep the flag in a separate env) so it isn't treated as a token.
```

### Browser-launch degradation (D-05/D-06/D-07)

```r
# Print FIRST — this line cannot fail and is the guaranteed-correct path.
message("Viewport: ", url,
        "\n  If it did not open, paste that URL into a browser.")
# One-time, start-of-session firewall note (D-06). Loopback binds usually do NOT
# trigger the OS firewall prompt, but managed security suites sometimes do.
message("  (A firewall prompt may appear on first launch; allowing ",
        "loopback-only access is safe.)")
# browseURL already consults getOption("browser") / R_BROWSER (D-07). Attempt it
# for convenience; never trust the return value (D-05).
if (isTRUE(open)) try(utils::browseURL(url), silent = TRUE)
invisible(url)
```

### Offline install smoke test (WEB-03, sketch)

```r
# Build once, install with NO network, prove the bundle ships and serves.
tarball <- pkgbuild::build(pkg_root, dest_path = tempdir())      # or R CMD build
lib <- tempfile("gmw-lib-"); dir.create(lib)
install.packages(tarball, repos = NULL, type = "source",
                 dependencies = FALSE, lib = lib)               # offline install
withr::with_libpaths(lib, {
  expect_true(nzchar(system.file("htmlwidgets", "guimorphweb-three.js",
                                 package = "GUImorphWeb")))       # bundle present
  url <- GUImorphWeb:::.gmw_serve_mesh(fixture, open = FALSE)     # serve loopback
  resp <- curl::curl_fetch_memory(paste0(url, "specimen.ply"))
  expect_equal(resp$status_code, 200L)                           # bytes served
  page <- rawToChar(curl::curl_fetch_memory(url)$content)
  expect_false(grepl('src="https?://|href="https?://', page))    # no external refs
})
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `window.onunload` for teardown pings | `pagehide` + `visibilitychange`, sent via `sendBeacon` | bfcache era (~2019+) | `unload` is unreliable/deprecated; use `pagehide` (Pitfall 4) |
| httpuv static-only vs. Rook `call`-only apps | Single **mixed** app: `staticPaths` (C++ thread) + `call` (R thread) with `excludeStaticPath()` | httpuv 1.4+ static paths | Lets Phase 3 add `/close` without moving the byte path onto the R thread |
| `webbrowser.open` / auto-open as the happy path | Print-URL-first as the guaranteed path, open as convenience | REFERENCE-ARCHITECTURE (adopted) | Managed-machine browser failures degrade to an inconvenience |

**Deprecated/outdated:**
- The `unload` event: avoid; prefer `pagehide`.
- `startDaemonizedServer()` for this use: unnecessary — `startServer()` already runs I/O on a background thread since httpuv 1.4.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Loopback (`127.0.0.1`) binds usually do **not** trigger the Windows/macOS firewall prompt; the D-06 message is precautionary for managed security suites | Pattern (browser degradation), D-06 | Low — the message is advisory either way; wording, not behavior, is affected |
| A2 | `navigator.sendBeacon` + `pagehide`/`visibilitychange` semantics as described (fire-and-forget POST, same-origin OK) | Pattern 3, Pitfall 4 | Low — standard web platform; if a browser misbehaves, finalizer/`gmw_close` still guarantee cleanup |
| A3 | `callr`/`processx` would be the vehicle for an out-of-process `/close` socket test (not verified as installed) | Standard Stack (supporting) | None — recommended path is the direct-closure unit test, which needs no new dep |
| A4 | Target machines already have the Imports (geomorph/Rvcg/tcltk/tcltk2/httpuv) present, so `dependencies=FALSE` offline install is representative | Pitfall 6, smoke test | Medium — if a lab machine lacks an Import, "clean install" must pre-stage it; this is a deployment note, not a code bug |

**Everything else in this research was verified against the installed toolchain or base-R docs (see Sources).**

## Open Questions

1. **Should the finalizer-registration flag live inside `.gmw_server` or a separate env?**
   - What we know: `.gmw_server` is iterated by `.gmw_stop_token()`; a stray `.finalizer_registered` key must not be treated as a server handle.
   - What's unclear: cleanest place to keep it.
   - Recommendation: keep lifecycle flags in a separate small env (e.g. `.gmw_lifecycle`) so `ls(.gmw_server)` stays purely token→handle. Planner's call (Claude's discretion on route/registry detail).

2. **Automated cross-platform WEB-03: CI or manual-per-platform?**
   - What we know: no `.github/workflows` exists; this is a local desktop project.
   - What's unclear: whether to introduce CI now.
   - Recommendation: ship the smoke test as a runnable script/test that a human runs on Windows and macOS (matches D-10 "verification-only" + Phase-2's manual UAT habit); introducing GitHub Actions (`windows-latest`, `macos-latest`) is a reasonable but out-of-scope enhancement.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| R | everything | ✓ | 4.6.1 | — |
| httpuv | server + `/close` route + teardown | ✓ | 1.6.17 | — |
| later | deferred stop, R-thread callbacks | ✓ | 1.4.8 | — |
| curl | loopback GETs in tests | ✓ (Suggests) | installed | `skip_if_not_installed("curl")` |
| vendored three.js bundle | WEB-03 offline viewport | ✓ | in `inst/htmlwidgets/` | — (fail loudly if missing) |
| tkogl2 native engine | CMP-01 gate | platform-dependent | — | `.gmw_engine$ok=FALSE` is non-fatal for browser paths; digitizing refuses via `.gmw_require_engine()` |
| callr/processx | optional out-of-process `/close` test | not verified | — | direct-closure unit test (no dep) |

**Missing dependencies with no fallback:** none for the browser/lifecycle paths.
**Missing dependencies with fallback:** `tkogl2` on a display-less/unsupported host — CMP-01 verification then requires a display host (owed from Phase 2).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `testthat` (Suggests) with `tests/testthat.R` → `test_check("GUImorphWeb")` |
| Config file | `tests/testthat.R`; source-tree tests guard with `skip_if_no_pkg_source()` / `skip_if_no_curl()` |
| Quick run command | `R --no-init-file -q -e 'testthat::test_local("integrated-guimorph-development_EOC/Project/GUImorphDevelopment", filter="transport")'` |
| Full suite command | `R --no-init-file -q -e 'testthat::test_local("integrated-guimorph-development_EOC/Project/GUImorphDevelopment")'` (or `R CMD check`) |

> Use `--no-init-file`: STATE.md notes a site-library `renv` makes bare `R`/`Rscript` hang on startup under a restricted network.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WEB-04 | `gmw_close(token)` stops one; `gmw_close()` stops all; registry + `listServers()` both emptied | unit (R thread) | `...test_local(filter="transport")` | ❌ Wave 0 |
| WEB-04 | `reg.finalizer(onexit=TRUE)` registered once; stop-all callable | unit | same | ❌ Wave 0 |
| WEB-04 | `.onUnload()` stops all live servers | unit | same | ❌ Wave 0 |
| WEB-04 | `/close` handler returns 204 and schedules the correct token's stop (direct closure call, synthetic `req`) | unit | same | ❌ Wave 0 |
| WEB-04 | Port occupied → walk-forward; exhaustion → clear `stop()` naming range (no hang) | unit (injected probe) | same | ⚠️ extend existing port test |
| WEB-04 | Launch prints URL first; `browseURL` failure does not error; honors `options(browser=...)` | unit (`expect_message`, browser override) | same | ⚠️ extend existing open test |
| WEB-03 | Static byte path unchanged: `127.0.0.1`, no `0.0.0.0`, `staticPath` present; served bytes byte-identical | unit | same | ✅ exists (`test-transport.R`) |
| WEB-03 | Offline install from tarball (`repos=NULL, dependencies=FALSE`) ships the bundle and serves it over loopback; page has no external refs | integration | `...test_local(filter="offline")` | ❌ Wave 0 |
| WEB-03 | All 6 specimens render/orbit/reset on Windows + macOS; worst-case 30 MB PLY frames | manual-only | UAT script | ❌ (carries Phase-2 owed UAT) |
| CMP-01 | `library(GUImorphWeb)` loads; `.gmw_engine$ok` unchanged by lifecycle work | manual-only (needs display host) | UAT | ❌ (owed from Phase 2) |

### Sampling Rate
- **Per task commit:** `...test_local(filter="transport")` (fast; static/teardown/port/handler units).
- **Per wave merge:** full `test_local()` (or `R CMD check`).
- **Phase gate:** full suite green (modulo the known pre-existing reds, see Wave 0) + WEB-03/CMP-01 manual UAT signed off before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `tests/testthat/test-offline-smoke.R` — WEB-03 offline install + serve + byte-identity + no-external-refs.
- [ ] Teardown tests (`gmw_close` one/all, finalizer registration, `.onUnload`) — new blocks in `test-transport.R` (or a `test-lifecycle.R`).
- [ ] `/close` handler direct-closure unit test (synthetic `req`) — new block.
- [ ] Re-scope the `PATH_INFO` guard assertion (Pitfall 3) before adding the `call` handler.
- [ ] Optional: `callr`/`processx` (Suggests) only if an out-of-process `/close` socket test is chosen.
- **Known pre-existing reds (STATE.md, do NOT let them mask new failures):** 2 tests call deleted functions; 4 stub `tcltk` via `assignInNamespace` (disallowed on R 4.6). Confirmed unrelated to browser work — scope-check whether to `skip()`/quarantine them so the phase gate reads cleanly, but fixing them is not this phase's job.

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture | yes | Server-owns-state; loopback-only bind; browser is a pure view (REFERENCE-ARCHITECTURE) |
| V2 Authentication | no | No accounts; per-session >=128-bit path token is the access guard (T-2-04) |
| V4 Access Control | yes | `127.0.0.1`-only bind (never `0.0.0.0`); token path segment guards enumeration; `/close` handler stops only its own token's server |
| V5 Input Validation | yes | `/close` `call` must NOT join `req$PATH_INFO` to the filesystem — pattern-match only (T-2-02 preserved) |
| V6 Cryptography | partial | Token is base-R `sample()` (>=128-bit, NOT a CSPRNG) — residual risk explicitly accepted in Phase 2; **do not expand scope here** |
| V12 Files/Resources | yes | Static bytes served from a fresh per-session tempdir via `staticPath`; no request-derived path join |

### Known Threat Patterns for {R + httpuv loopback viewport}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via the new `/close` route | Tampering / Info Disclosure | Handler pattern-matches the close path and calls `stopServer` only; never `file.path`/`readBin` from `req$PATH_INFO` |
| A local process forces a DoS by hitting `/close` | Denial of Service | The route only stops that token's own viewport (the user's own tab already can); loopback-only + token-scoped limits blast radius to one already-owned viewport |
| LAN exposure of the specimen | Info Disclosure | `host = "127.0.0.1"` only; assert absence of `0.0.0.0` (existing guard, keep) |
| Cross-package teardown collateral | Denial of Service | Never `stopAllServers()`; iterate `.gmw_server` and stop only owned handles |
| Orphaned listener leaks a port after crash | DoS (resource) | Four D-01 triggers; `reg.finalizer(onexit=TRUE)` backstops session end |

## Project Constraints (from .cursor/rules/)

`.cursor/rules/gsd.md` is a project-context digest (PROJECT/STACK/CONVENTIONS/ARCHITECTURE) plus GSD workflow enforcement. Actionable directives the planner must honor:

- **Prefix shell commands with `rtk`** (`.cursorrules`) for token savings; raw commands only when debugging. Safe pass-through when no filter exists.
- **Go through a GSD command before file-changing edits** (`/gsd-execute-phase` for planned work) — do not make direct repo edits outside a GSD workflow unless explicitly bypassed.
- **R naming conventions (CONVENTIONS):** keep the file's existing extension (`.R` for `rtkogl.R`/`transport.R`/`view3d.R`); `camelCase` for handlers, `dot.separated` for I/O/S3 constructors, `.gmw_*` for the internal package-env idioms already in use.
- **Error handling:** user-facing errors via clear `stop(..., call. = FALSE)` (matches D-09); `tryCatch` around risky calls (DLL load, `browseURL`); gated `dbg()` printer, never raw `print()`.
- **Exports:** the package deliberately exports very few symbols; `gmw_close`/`gmw_stop` will be new `@export`s — add roxygen and regenerate `NAMESPACE` (currently only `GUImorphWeb`, `loadDgt` exported).
- **Package root:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`.
- **Do not touch the native build / `.onLoad` engine-load path** (CMP-01 recurring gate).

## Sources

### Primary (HIGH confidence)
- Installed `httpuv 1.6.17` — `?startServer` (mixed `staticPaths` + `call`; static served on C++ thread; `excludeStaticPath()`), `args(randomPort)` (`min=1024,max=49151,host="127.0.0.1",n=20`), `staticPathOptions(fallthrough=…)`, exports (`stopServer`/`stopAllServers`/`listServers`). Cross-checked with a working local loopback test (static 200; `/close` stops the listener; same-process curl to `/close` starves).
- Installed base R 4.6.1 — `?reg.finalizer` (`e, f, onexit=FALSE`), `?ns-hooks` (`.onUnload(libpath)`; "packages are not detached nor namespaces unloaded at the end of an R session").
- Installed `later 1.4.8` — available as httpuv's scheduler.
- Repo code: `R/transport.R`, `R/view3d.R`, `R/rtkogl.R`, `tests/testthat/test-transport.R`, `helper-transport.R`, `DESCRIPTION`, `NAMESPACE`, `renv.lock` (httpuv pin 1.6.17).
- `.planning/research/REFERENCE-ARCHITECTURE.md`, `.planning/ROADMAP.md` (Phase 3), `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `03-CONTEXT.md`.

### Secondary (MEDIUM confidence)
- Web-platform behavior of `navigator.sendBeacon` + `pagehide`/`visibilitychange` (standard MDN knowledge; web search disabled in `.planning/config.json`, so not re-fetched this session).

### Tertiary (LOW confidence)
- Firewall-prompt behavior for loopback binds on managed Windows/macOS (A1) — precautionary; message wording only.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every library verified installed at the pinned version; no new deps.
- Architecture (mixed app + teardown): HIGH — `/close` route and self-teardown verified with a live loopback test; lifecycle hooks verified against base-R docs.
- Pitfalls: HIGH — Pitfalls 2, 3, 5 directly observed/verified in-session; 1, 4, 6 follow from verified mechanics.
- Browser/firewall degradation specifics: MEDIUM (A1/A2 depend on unfetched web-platform/OS behavior).

**Research date:** 2026-08-03
**Valid until:** 2026-09-02 (30 days — stable stack; httpuv/base-R APIs are slow-moving)
