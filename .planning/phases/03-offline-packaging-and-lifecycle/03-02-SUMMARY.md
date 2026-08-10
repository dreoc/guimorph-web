---
phase: 03-offline-packaging-and-lifecycle
plan: 02
subsystem: infra
tags: [httpuv, excludeStaticPath, later, mixed-app, port-selection, browseURL, loopback, testthat]

# Dependency graph
requires:
  - phase: 03-offline-packaging-and-lifecycle
    provides: ".gmw_stop_token(token) registry-driven teardown helper; .gmw_lifecycle flag env; re-scoped no-filesystem-join transport guard (plan 03-01)"
  - phase: 02-transport-and-mesh-display
    provides: ".gmw_serve_mesh() static httpuv loopback listener, .gmw_server token registry, .gmw_pick_port/.gmw_probe_free/.gmw_token"
provides:
  - "Mixed static+call httpuv app: excludeStaticPath() at /<token>/close plus a per-server call handler that returns 204 and defers .gmw_stop_token(token) via later::later (server side of the D-02 tab-close beacon)"
  - ".gmw_close_handler(token) — per-server /close closure factory (pattern-match only, never joins request path to filesystem)"
  - ".gmw_serve_mesh(..., port = NULL) — user preferred-port argument wired to the existing walk-forward selector (D-08)"
  - "Sharpened .gmw_pick_port exhaustion stop(call.=FALSE) naming the tried range through 49151 + omit-port hint (D-09)"
  - "Print-URL-first launch with paste fallback (D-05), one-time .gmw_lifecycle$firewall_noted note (D-06), try()-wrapped browseURL honouring getOption(browser)/R_BROWSER (D-07)"
affects: [03-03-close-beacon, 03-04-offline-smoke]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Mixed httpuv app: static bytes stay on the C++ thread; one excludeStaticPath() subpath is routed to a per-server R call handler"
    - "Deferred teardown from inside a request handler via later::later — return 204 first, never a synchronous stopServer (Pitfall 2)"
    - "Per-server handler closes over its own token, so it pattern-matches the close path and never joins a request path to the filesystem (T-3-01)"
    - "Lifecycle one-shot messaging gated by a flag in .gmw_lifecycle (firewall note), matching the finalizer-registered idiom"

key-files:
  created: []
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport.R"

key-decisions:
  - "Factored the /close closure into an internal .gmw_close_handler(token) factory rather than inlining call = function(req){...}, so the production closure itself is unit-tested (Pitfall 5: a same-process curl cannot reach it) instead of a hand-copied duplicate — within the plan's 'build the call closure the same way the production code does' latitude and CONTEXT's route-shape discretion"
  - "Preferred excludeStaticPath() over staticPathOptions(fallthrough=TRUE) — narrower R surface, exactly one subpath routed to R (RESEARCH Alternatives)"
  - "WEB-04 requirement closure left to the phase gate (mirrors plan 03-01): the automated runtime half is now complete and unit-covered, but the end-to-end browser UAT and CMP-01 display-host load gate are still owed"

patterns-established:
  - "Test the /close route by invoking the production call closure directly with a synthetic req = list(PATH_INFO=...), then draining later after sleeping past the defer (never same-process curl — Pitfall 5)"
  - "Sleep past the later delay before run_now(): run_now returns as soon as ANY ready callback fires, so a bare run_now() can return before a delayed callback is due"

requirements-completed: []  # WEB-04 spans plans 01/02/04 + manual UAT; closure deferred to the phase gate (see Decisions)

coverage:
  - id: D1
    description: "/<token>/close returns 204 and schedules a stop of its own token only (defers via later, never synchronous); a non-close path returns 404"
    requirement: "WEB-04"
    verification:
      - kind: unit
        ref: "tests/testthat/test-transport.R#/close handler returns 204 and schedules a stop of its own token"
        status: pass
    human_judgment: false
  - id: D2
    description: "Static byte mount kept byte-for-byte (staticPath present, 127.0.0.1 only, no 0.0.0.0); the /close handler never joins req$PATH_INFO to the filesystem (re-scoped guard passes with the new route present)"
    requirement: "WEB-04"
    verification:
      - kind: unit
        ref: "tests/testthat/test-transport.R#server binds 127.0.0.1 on an unprivileged port; source is loopback-only"
        status: pass
    human_judgment: false
  - id: D3
    description: "port = NULL argument wired to .gmw_pick_port(prefer = port); exhaustion raises a clear error naming the tried range (start port + 49151) and the omit-port hint — never a hang"
    requirement: "WEB-04"
    verification:
      - kind: unit
        ref: "tests/testthat/test-transport.R#port exhaustion raises a clear range-naming error, never a hang (D-09)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Launch prints the URL first (paste fallback) before any browser attempt; a failed/blocked browser is swallowed (try, return ignored) and never errors; the firewall note fires at most once per session"
    requirement: "WEB-04"
    verification:
      - kind: unit
        ref: "tests/testthat/test-transport.R#launch prints the URL first and tolerates a failed browser"
        status: pass
      - kind: unit
        ref: "tests/testthat/test-transport.R#the firewall note fires at most once per session (D-06)"
        status: pass
    human_judgment: false
  - id: D5
    description: "End-to-end WEB-04 on a managed machine: a real browser tab close fires the beacon and stops the token's server; a fixed port through a lab firewall serves; a locked-down default browser degrades to the printed URL"
    verification: []
    human_judgment: true
    rationale: "Real-browser tab-close beacon delivery, OS firewall prompts, and blocked default browsers cannot be exercised in-process by the headless test runner; direct-closure + option(browser) unit tests cover the R half (D1/D4). Requires the owed phase-gate UAT on Windows + macOS."

# Metrics
duration: 20min
completed: 2026-08-03
status: complete
---

# Phase 3 Plan 02: Mixed /close App, Port UX, and Browser-Launch Degradation Summary

**Converted the loopback viewport to a mixed static+dynamic httpuv app with a per-token `/close` route that defers `.gmw_stop_token()` via `later`, surfaced the walk-forward port backup as a `port` argument with a range-naming exhaustion error, and hardened the browser launch to print-first and swallow a failed/blocked browser.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-08-03T16:42Z (approx)
- **Completed:** 2026-08-03T17:02Z (approx)
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- **Mixed app + `/close` route (D-02 server side).** `.gmw_serve_mesh` now builds a mixed httpuv app: the Phase-2 `staticPath(dir)` mount is kept byte-for-byte (T-2-02) and joined by `httpuv::excludeStaticPath()` at `/<token>/close`, routed to a per-server `call` handler. The handler is built by a new internal `.gmw_close_handler(token)` factory that captures its own token, `grepl("/close$", req$PATH_INFO)`, schedules `later::later(function() .gmw_stop_token(token), 0.5)`, and returns `204` first — never a synchronous `stopServer` (Pitfall 2), never a filesystem join from the request path (T-3-01). Any other path is a plain `404`.
- **Port UX (D-08/D-09).** Added a `port = NULL` argument that flows straight into `.gmw_pick_port(prefer = port)` (NULL → `randomPort()`, integer → walk-forward), with roxygen documenting the "fixed port through a lab firewall" case. Sharpened the exhaustion `stop(call. = FALSE)` to name the tried range (`from <prefer> through 49151`) and add the actionable "or omit `port` to auto-pick a random one" — a clear error, never a hang.
- **Browser-launch degradation (D-05/D-06/D-07).** The launch block now prints the URL first with a paste fallback (the guaranteed path that cannot fail), emits a one-time firewall note gated by `.gmw_lifecycle$firewall_noted`, and attempts the open only via `try(utils::browseURL(url), silent = TRUE)` with the return value ignored — so a blocked/misconfigured browser degrades to the printed URL rather than erroring. `getOption("browser")`/`R_BROWSER` are honoured with no new machinery (documented in roxygen).
- **Tests.** Added a direct-closure `/close` test (synthetic `req` → 204, own-token stop after draining `later`, 404 on a non-close path), a port-exhaustion test (message names both the start port and 49151 plus the omit hint), a failed-browser degradation test (`options(browser = ...stop...)` swallowed + `Viewport:` message emitted), and a firewall-note-once-per-session test. Transport suite: **67 pass, 0 fail, 0 skip.**

## Task Commits

Each task was committed atomically:

1. **Task 1: Mixed static+/close app with deferred per-token stop** - `d18a906` (feat)
2. **Task 2: Preferred port argument + sharpened D-09 exhaustion error** - `74c6fa5` (feat)
3. **Task 3: Harden browser launch to degrade legibly** - `9db3684` (feat)

**Plan metadata:** skipped (commit_docs disabled — `.planning/` changes left in the working tree per project config)

_Note: this plan was not TDD; each task is a single feat commit bundling source + tests._

## Files Created/Modified
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R` - Added `.gmw_close_handler(token)`; converted the app to mixed static+call with `excludeStaticPath()` at `/<token>/close`; added `port = NULL` wired to `.gmw_pick_port(prefer = port)`; sharpened the exhaustion error (D-09); reworked the launch block for print-first + one-time firewall note + `try()`-wrapped `browseURL` (D-05/D-06/D-07); roxygen updated for `@param port`/`@param open`.
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport.R` - Added `/close` direct-closure, port-exhaustion, failed-browser degradation, and firewall-note-once test blocks.

## Decisions Made
- **`.gmw_close_handler(token)` factory instead of an inline `call = function(req){...}`.** Factoring the closure into a named internal lets the test exercise the *real production* closure (Pitfall 5 rules out a same-process curl), rather than a hand-copied duplicate that could drift. This is within the plan's "build the `call` closure the same way the production code does" latitude and CONTEXT's discretion over the `/close` route shape.
- **`excludeStaticPath()` over `staticPathOptions(fallthrough = TRUE)`** — narrower R surface: exactly one subpath is routed to R rather than every missing static file (RESEARCH Alternatives Considered).
- **WEB-04 closure deferred to the phase gate** (mirrors plan 03-01): the automated runtime half of WEB-04 is now complete and unit-covered, but the end-to-end browser tab-close UAT and the CMP-01 display-host `library()` load gate are still owed, so `requirements-completed` is left empty here.

## Deviations from Plan

None - plan executed exactly as written. (Two in-task test corrections were made during Task 1 verification and are Issues Encountered, not scope deviations — see below.)

## Issues Encountered
- **Re-scoped guard tripped on my own roxygen.** The plan-01 re-scoped guard flags any source line containing `PATH_INFO` that *also* names `file.path`/`normalizePath`/`readBin`. My first `.gmw_close_handler` doc comment described the safety property with both on one line, tripping it. Reworded the roxygen so `PATH_INFO` and the filesystem-function names never share a line — the invariant is unchanged, the handler still only pattern-matches.
- **`later::run_now()` returned before the deferred stop was due.** `run_now()` (and even `run_now(1)`) returns as soon as *any* ready callback fires, so it could return before the 0.5s-deferred `.gmw_stop_token` was due, leaving the token present. Fixed the test to `Sys.sleep(0.6)` past the defer, then `run_now()` — deterministically drains the now-due callback. Verified in isolation before finalising.
- **`test_local()` headless hang (pre-existing, from plan 03-01).** `test_local()` runs `load_all`, which attaches `tcltk2` and blocks with no window server. Ran the suite as `testthat::test_dir(<testdir>, filter = "transport", load_package = "none")` (the source tree is sourced directly and every source-touching block is `skip_if_no_pkg_source()`-guarded), exactly as plan 03-01 documented. Not a code defect.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The server side of the D-02 tab-close beacon is live: the page-side `navigator.sendBeacon("close")` hook (already shipped in plan 03-03) now has a real `/close` route to hit, closing the browser-tab teardown trigger end-to-end.
- Plan 03-04 (offline install smoke test, WEB-03) is unblocked — the mixed app serves the same byte-identical specimen path plus the new route, and the page still has zero external references.
- **Owed at the phase gate (not this plan):** the end-to-end browser UAT (real tab-close beacon on Windows + macOS; fixed port through a firewall), and the CMP-01 display-host `library(GUImorphWeb)` load gate carried from Phase 2. WEB-04 requirement closure is deferred until these land.

## Self-Check: PASSED

- Files: `R/transport.R`, `tests/testthat/test-transport.R`, and `03-02-SUMMARY.md` all present.
- Commits: `d18a906` (Task 1), `74c6fa5` (Task 2), `9db3684` (Task 3) all present in git history.
- Tests: transport suite 67 pass / 0 fail / 0 skip via `test_dir(..., load_package = "none")`.
- Doc commit: intentionally skipped (`commit_docs: false`) — `.planning/` SUMMARY/STATE/ROADMAP left uncommitted in the working tree per project config.

---
*Phase: 03-offline-packaging-and-lifecycle*
*Completed: 2026-08-03*
