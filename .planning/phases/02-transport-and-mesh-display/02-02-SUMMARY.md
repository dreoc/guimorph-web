---
phase: 02-transport-and-mesh-display
plan: 02
subsystem: infra
tags: [httpuv, loopback, staticPaths, token-guard, r, transport, renv]

requires:
  - phase: 02-transport-and-mesh-display
    provides: ".gmw_view3d_html(mesh_url=...) HTML builder + vendored three.js bundle (.gmw_bundle_path)"
  - phase: 01-browser-result-plots-rgl-demotion
    provides: "vendored guimorphweb-three.js bundle; .gmw_engine retained-state idiom; dbg()/browseURL delivery idiom"
provides:
  - ".gmw_serve_mesh(ply_path, title, background, open) — Phase 2 entry point: serves one PLY over a loopback token-guarded httpuv static path, opens the viewport, returns the URL invisibly"
  - ".gmw_token() — >=128-bit URL-safe base-R random path segment"
  - ".gmw_pick_port(prefer, probe) / .gmw_probe_free(port) — randomPort primary + injectable walk-forward backup"
  - ".gmw_server package env — retains live httpuv handles against GC for the session"
  - "httpuv in DESCRIPTION Imports and locked in renv.lock (1.6.17)"
affects: [phase-3-packaging, WEB-04, PICK-01, transport, teardown]

tech-stack:
  added: [httpuv]
  patterns:
    - "Server-owns-state loopback transport: startServer(host='127.0.0.1', staticPaths=setNames(list(staticPath(dir)), '/<token>'))"
    - "staticPaths-only serving (no call handler / no PATH_INFO path-joining) for path-traversal safety"
    - "Per-session >=128-bit random path token as the endpoint guard; base-R RNG with documented residual risk"
    - "Retain live server handle in a package env (.gmw_server) so gc() finalizers never stop the listener"
    - "Injectable port-probe (probe=) makes walk-forward port selection unit-testable without binding a socket"
    - "Bounded-timeout fetch helper so a staticPaths-only server (which never answers unmatched paths) cannot hang guard tests"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport.R
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/helper-transport.R
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/renv.lock

key-decisions:
  - "Bound host to the literal 127.0.0.1 and served via httpuv::staticPaths only — never 0.0.0.0, never a call handler that builds a file path from the request path (T-2-02/T-2-03), asserted by source-scan."
  - "Guarded the endpoint with a base-R >=128-bit random path token per RESEARCH Open Question 1 (no openssl/sodium dependency, which would need a decision checkpoint); documented the non-cryptographic-RNG residual risk in the file header (T-2-04)."
  - "Retained each live handle in the .gmw_server env keyed by token so gc() cannot stop the listener (Pitfall 2 / T-2-05); did NOT build teardown/stopServer lifecycle here — that is WEB-04/Phase 3."
  - "Spliced the httpuv lock entry into renv.lock by hand to preserve the file's CRLF line endings; letting renv::snapshot() rewrite it re-serialized the whole file to LF (8043-line pseudo-diff) for a one-package change."
  - "Guard test asserts 'specimen bytes are never returned' via a bounded-timeout fetch rather than a literal 403/404 status: a staticPaths-only app has no call handler and simply does not answer an unmounted path, so refusal manifests as no-response, which is exactly the plan's acceptance criterion."

patterns-established:
  - "Loopback token-guarded static transport: .gmw_serve_mesh stages bundle+page+specimen into a tempdir and serves it under /<token>/ on 127.0.0.1."
  - "Testable non-determinism: inject the port probe (and override .gmw_bundle_path via environment(.gmw_serve_mesh)) so integration behaviour is unit-checkable."

requirements-completed: [WEB-01, WEB-02, CMP-01]

coverage:
  - id: D1
    description: "httpuv server binds 127.0.0.1 on an unprivileged port (1024-49151); source contains the literal 127.0.0.1 and no all-interfaces bind address (WEB-01 loopback)."
    requirement: "WEB-01"
    verification:
      - kind: integration
        ref: "tests/testthat/test-transport.R#serves on 127.0.0.1 at an unprivileged port and never binds all interfaces"
        status: pass
    human_judgment: false
  - id: D2
    description: "The specimen PLY is served as raw bytes, byte-identical to the file on disk, never JSON-encoded (WEB-01 byte-faithful)."
    requirement: "WEB-01"
    verification:
      - kind: integration
        ref: "tests/testthat/test-transport.R#serves the specimen as raw bytes identical to disk (never JSON)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A request without the token path, or with a wrong token, never returns the specimen bytes (WEB-01 token guard, T-2-01)."
    requirement: "WEB-01"
    verification:
      - kind: integration
        ref: "tests/testthat/test-transport.R#a request without the session token never returns the specimen bytes"
        status: pass
    human_judgment: false
  - id: D4
    description: ".gmw_pick_port walks forward past a busy preferred port (prefer=8080, probe rejecting 8080 -> 8081L) with no socket bound (WEB-01 port selection backup)."
    requirement: "WEB-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-transport.R#.gmw_pick_port walks forward from a busy preferred port without binding"
        status: pass
    human_judgment: false
  - id: D5
    description: ".gmw_serve_mesh copies bundle+page+specimen into a tempdir, opens http://127.0.0.1:PORT/<token>/ via browseURL, and retains the live handle in .gmw_server so it survives gc() (WEB-02 server-side delivery, Pitfall 2)."
    requirement: "WEB-02"
    verification:
      - kind: integration
        ref: "tests/testthat/test-transport.R#opens the loopback token URL via browseURL and retains the handle against gc"
        status: pass
    human_judgment: false
  - id: D6
    description: "httpuv is a declared Import and a locked dependency; requireNamespace('httpuv') is TRUE and the tkogl2 oracle load path is untouched (CMP-01)."
    requirement: "CMP-01"
    verification:
      - kind: automated
        ref: "R -q -e 'stopifnot(requireNamespace(\"httpuv\")); imp<-read.dcf(\"DESCRIPTION\",\"Imports\"); stopifnot(grepl(\"httpuv\",imp)); stopifnot(any(grepl(\"\\\"httpuv\\\"\", readLines(\"renv.lock\"))))'"
        status: pass
    human_judgment: true
    rationale: "requireNamespace + Imports + renv.lock checks pass, but the full library(GUImorphWeb) / pkgload::load_all() load gate could not run in the headless sandbox — tcltk2's GUI init blocks on the macOS window server with no display (pre-existing, unrelated to httpuv). The one-line load gate must be re-run on a host with a display."
  - id: D7
    description: "End-to-end: the served mesh renders shaded (not black), orbit/zoom/r-reset work, and all 6 reference specimens (incl. the ~30 MB B7_1_clean.ply worst case) transfer and frame acceptably on stock macOS and stock Windows (WEB-02 browser UAT)."
    requirement: "WEB-02"
    verification: []
    human_judgment: true
    rationale: "No automated WebGL harness; requires visual UAT on stock macOS/Windows per 02-VALIDATION.md Manual-Only. Now unblocked because .gmw_serve_mesh() delivers the runnable viewport."

duration: 95 min
completed: 2026-07-31
status: complete
---

# Phase 2 Plan 2: Loopback httpuv Transport Summary

**`.gmw_serve_mesh()` starts a background `httpuv` listener bound to `127.0.0.1` on an unprivileged port and serves one specimen PLY (plus the vendored three.js bundle and the 02-01 page) as raw bytes via `staticPaths`, behind a per-session >=128-bit random path token, retaining the live handle in `.gmw_server` against GC.**

## Performance

- **Duration:** ~95 min
- **Started:** 2026-07-31T18:10:00Z
- **Completed:** 2026-07-31T18:10:00Z (approx; see note)
- **Tasks:** 3
- **Files modified:** 5 (2 modified, 3 created)

## Accomplishments

- **WEB-01 transport + guard.** `R/transport.R` starts `httpuv::startServer(host = "127.0.0.1", ...)` serving a tempdir via `staticPaths` mounted only at `/<token>/`. The specimen is served as raw bytes (byte-identical to disk, never JSON); a request missing or carrying the wrong token never returns the specimen. `.gmw_token()` produces a >=32-char (>=128-bit) URL-safe base-R random segment.
- **WEB-02 server-side delivery.** `.gmw_serve_mesh(ply_path)` copies `guimorphweb-three.js`, writes `index.html` from `.gmw_view3d_html(mesh_url = "specimen.ply")` (the 02-01 builder), copies the specimen to `specimen.ply`, picks a port, starts the guarded server, retains the handle in `.gmw_server`, `message()`s the URL, and opens `http://127.0.0.1:PORT/<token>/` via `browseURL()`.
- **Port selection.** `.gmw_pick_port()` returns `httpuv::randomPort()` by default; with `prefer` it walks forward using an injectable `probe`, which keeps selection unit-testable without binding a socket.
- **CMP-01 (partial).** `httpuv` added to DESCRIPTION `Imports` (after `tcltk2`, htmlwidgets left in `Suggests`) and locked in `renv.lock` (1.6.17); `requireNamespace("httpuv")` is TRUE. The full `library()` load gate is deferred (headless sandbox — see Deviations).
- **Test suite.** `tests/testthat/test-transport.R` (6 tests, 27 assertions) + `helper-transport.R` cover loopback bind + unprivileged port + source-scan, byte-integrity, token guard, port fallback ordering, browse-open capture (no real browser), and handle retention. `filter="transport"` (this suite + 02-01's render suite) runs green in ~11s.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add httpuv to Imports and lock it** - `65a57a2` (build)
2. **Task 2: Implement `R/transport.R`** - `0cdef04` (feat)
3. **Task 3: Transport test suite + helper** - `107975d` (test)

**Plan metadata:** committed with STATE.md + ROADMAP.md (docs: complete plan)

## Files Created/Modified

- `R/transport.R` (created) - `.gmw_serve_mesh`, `.gmw_token`, `.gmw_pick_port`, `.gmw_probe_free`, and the `.gmw_server` retained-state env.
- `tests/testthat/test-transport.R` (created) - Integration + unit transport suite.
- `tests/testthat/helper-transport.R` (created) - Bounded-timeout fetch + URL-parse + probe-stub helpers (no `test_that`).
- `DESCRIPTION` (modified) - `httpuv` added to `Imports`.
- `renv.lock` (modified) - `httpuv` 1.6.17 CRAN entry spliced in (CRLF preserved).

## Decisions Made

- **Loopback + staticPaths only.** Bound the literal `127.0.0.1`, served via `httpuv::staticPaths` with no `call` handler — so there is no code path that joins the request path onto the filesystem (T-2-02 traversal, T-2-03 interface). Both are asserted by source-scan.
- **Base-R >=128-bit token, no crypto dep.** Per RESEARCH Open Question 1, the default guard is a base-R `sample()` token with a documented residual-risk note; adding `openssl`/`sodium` would require a decision checkpoint and was deliberately avoided (T-2-04).
- **Retain handle, defer teardown.** Each handle is stored in `.gmw_server` keyed by token so a finalizer cannot stop the listener during the session (Pitfall 2). Robust teardown / port-collision recovery / browser degradation are explicitly WEB-04 / Phase 3 and were not built here.
- **Manual renv.lock splice.** `renv::snapshot()` rewrites the entire lockfile from CRLF to LF, turning a one-package add into an ~8000-line pseudo-diff. The `httpuv` entry was extracted from the snapshot output and spliced in at the correct alphabetical position with CRLF preserved, so the diff is only the new block.

## Deviations from Plan

### Auto-fixed / adapted issues

**1. [Environment - Blocking] CMP-01 `pkgload::load_all()` gate could not run headless.**
- **Found during:** Task 1 (verify) and again at closeout.
- **Issue:** The Task 1 verify command ends with `pkgload::load_all(".")`. That hangs in the headless sandbox because `tcltk2` (an unconditional Import inherited from Phase 1) blocks on macOS window-server init when no display is present — unrelated to `httpuv`.
- **Fix:** Verified the `httpuv`-specific half of CMP-01 that *can* run headless — `requireNamespace("httpuv")` TRUE, `httpuv` in `Imports`, `"httpuv"` in `renv.lock` — and source-scanned that the `tkogl2` load path in `rtkogl.R` is untouched. The full `library()`/`load_all()` load gate is flagged for a host with a display (coverage D6, `human_judgment: true`).
- **Verification:** `requireNamespace` + DESCRIPTION + renv.lock checks pass.
- **Committed in:** `65a57a2` (Task 1).

**2. [Test design] Guard test asserts "bytes never returned" via bounded timeout, not a literal 403/404.**
- **Found during:** Task 3.
- **Issue:** The plan suggests asserting a 403/404 for the un-tokened request. But a `staticPaths`-only app (correctly) has no `call` handler, so httpuv does not answer an unmounted path at all — an infinite-timeout `curl_fetch_memory` hangs forever.
- **Fix:** Added `gmw_try_fetch(url, timeout)` in `helper-transport.R` (bounded `timeout_ms`, returns `NULL` on error/timeout) and asserted the specimen bytes are never returned for a missing/wrong token. This is exactly the plan's stated acceptance criterion ("the bytes are NOT returned").
- **Verification:** Guard test passes; suite completes in ~11s instead of hanging.
- **Committed in:** `107975d` (Task 3).

---

**Total deviations:** 2 (1 environment-blocking gate deferred, 1 test-design adaptation). No scope creep; both preserve the plan's intent and acceptance criteria.

## Issues Encountered

- **`renv` side-effect install.** Producing a proper `renv.lock` entry required installing `renv` into the site-library; that now makes bare `R`/`Rscript` hang on `.Rprofile`'s `activate.R` under the sandbox's network allowlist. Worked around by running every R command with `--no-init-file` (system-library fallback, where `httpuv`/`testthat` live). `renv.lock`, `activate.R`, and `.Rprofile` are unchanged. See "User Setup Required".
- **`.gmw_bundle_path` scope in tests.** The test override initially landed in the wrong environment; fixed by assigning it into `environment(.gmw_serve_mesh)` so the sourced function resolves the source-tree bundle.
- **Source-scan false positive.** The no-`0.0.0.0` assertion tripped on a header comment; the comment was reworded to avoid the literal string while keeping the meaning.

## User Setup Required

None for the package itself — `httpuv` is a standard CRAN Import; no external service, account, or secret.

One environment cleanup item for whoever runs R next in this workspace: a `renv` package was installed into the site-library during this plan (to generate the lock entry) and it makes bare `R`/`Rscript` hang on startup under a restricted network. Either remove that installed `renv` package, or invoke R with `--no-init-file`. This does not affect a normal machine (renv activates fine with network) and touches no committed file.

## Next Phase Readiness

- `.gmw_serve_mesh()` delivers the runnable loopback viewport, which **unblocks the deferred WEB-02 browser UAT** (02-01 D3 + this plan's D7) and the phase manual UAT in `02-VALIDATION.md` (all 6 specimens incl. the ~30 MB `B7_1_clean.ply` worst case, both OSes).
- **Deferred to Phase 3 / WEB-04 (by design):** robust teardown / `stopServer` lifecycle on viewport close and session end, port-collision recovery UX, and browser-launch degradation. `.gmw_server` currently only retains handles for the session.
- **Owed:** re-run the CMP-01 `library(GUImorphWeb)` load gate on a host with a display (headless sandbox could not, due to `tcltk2`).

## Self-Check: PASSED

- Key files present: `R/transport.R`, `tests/testthat/test-transport.R`, `tests/testthat/helper-transport.R`.
- `git log --grep="02-02"` returns three task commits (`65a57a2`, `0cdef04`, `107975d`).
- Task 2 acceptance: `source("R/transport.R")` parses; `.gmw_serve_mesh/.gmw_pick_port/.gmw_token/.gmw_probe_free` + `.gmw_server` exist; `.gmw_token()` >=32 chars, `^[A-Za-z0-9]+$`, differs across calls; source contains `127.0.0.1`, no all-interfaces address; uses `staticPath(s)`, no `PATH_INFO` path-joining; `.gmw_pick_port(8080, probe=\p p!=8080L) == 8081L`.
- Plan verification: `testthat::test_dir("tests/testthat", filter="transport", stop_on_failure=TRUE)` → green, `transport-render` 17 + `transport` 27 assertions, exit 0, ~11s.

---
*Phase: 02-transport-and-mesh-display*
*Completed: 2026-07-31*
