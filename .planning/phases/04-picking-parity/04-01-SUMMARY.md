---
phase: 04-picking-parity
plan: 01
subsystem: api
tags: [httpuv, transport, picking, landmarks, server-owns-state, loopback, base-r]

# Dependency graph
requires:
  - phase: 02-local-transport-and-mesh-display
    provides: ".gmw_serve_mesh mixed httpuv app, token guard, loopback bind, .gmw_server registry"
  - phase: 03-offline-packaging-and-lifecycle
    provides: "/close excludeStaticPath precedent, .gmw_close_handler, .gmw_stop_token teardown"
provides:
  - "Token-guarded POST /<token>/pick route on the existing mixed httpuv app"
  - "Server-owned landmark store .gmw_picks (token -> n x 3 matrix)"
  - ".gmw_pick_handler subsuming the /close branch (single call handler per server)"
  - "R read API: .gmw_picks_get (internal) and exported gmw_picks accessor"
affects: [picking-parity, view3d browser raycast, PICK-02 overlay, PICK-03 record-replay]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Second excludeStaticPath subpath on the same mixed app routes /pick to R"
    - "Handler closes over its own token; writes only .gmw_picks[[token]] (no cross-token write)"
    - "Base-R x,y,z body parse (strsplit + as.numeric); no JSON dependency"
    - "grepl-only PATH_INFO matching; request path never joined to the filesystem (T-2-02)"

key-files:
  created:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-picking-transport.R"
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/NAMESPACE"

key-decisions:
  - "Kept .gmw_close_handler defined (test-transport.R invokes it directly) and added .gmw_pick_handler that subsumes /close; startServer references .gmw_pick_handler."
  - "gmw_picks exported and added to NAMESPACE by hand (roxygen-generated file) so the accessor is a real user entry point without a roxygenize run."
  - "Malformed pick bodies (wrong arity, non-numeric, empty, NA) are silently dropped with a 204; the array is left unchanged (T-4-02)."

patterns-established:
  - "Pick route: second httpuv::excludeStaticPath() /<token>/pick + single .gmw_pick_handler(token) call closure returning 204."
  - "Server-owns-state landmark store .gmw_picks kept separate from .gmw_server (mirrors .gmw_lifecycle)."

requirements-completed: [PICK-01, CMP-01]

coverage:
  - id: D1
    description: "POST /<token>/pick appends a 1x3 row to the server-owned landmark array and returns 204; second pick appends a second row (2x3)."
    requirement: "PICK-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-transport.R#a well-formed pick returns 204 and appends rows (server owns the array)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Malformed pick body (not exactly 3 finite numbers) is dropped: array unchanged, response still 204."
    requirement: "PICK-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-transport.R#malformed pick bodies are dropped: 204 but the stored array is unchanged"
        status: pass
    human_judgment: false
  - id: D3
    description: "Landmark array is retrievable in R via gmw_picks/.gmw_picks_get (server owns state; browser never holds authoritative coordinates)."
    requirement: "PICK-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-transport.R#a well-formed pick returns 204 and appends rows (server owns the array)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Pick handler never joins the request path to the filesystem (T-2-02 preserved); no JSON dependency."
    requirement: "PICK-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-transport.R#the pick route never joins the request path to the filesystem (T-2-02/T-4-01)"
        status: pass
    human_judgment: false
  - id: D5
    description: "transport.R never writes .gmw_engine; the native tkogl2 oracle load path is untouched (CMP-01). Positive .gmw_engine$ok check skips cleanly when the engine is absent."
    requirement: "CMP-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-transport.R#CMP-01: transport.R never writes .gmw_engine; oracle load path untouched"
        status: pass
    human_judgment: false

# Metrics
duration: 12min
completed: 2026-08-05
status: complete
---

# Phase 4 Plan 01: Pick Route + Server-Owned Landmark Store Summary

**Added a token-guarded `POST /<token>/pick` route to the existing mixed httpuv app that stores each browser-reported hit as a row in a server-owned `.gmw_picks` matrix, with an exported `gmw_picks()` R accessor — delivering the R half of PICK-01 while re-asserting CMP-01 (the native oracle load path is untouched).**

## Performance

- **Duration:** ~12 min
- **Completed:** 2026-08-05
- **Tasks:** 2 completed
- **Files modified:** 3 (transport.R, NAMESPACE, new test file)

## Accomplishments
- `R/transport.R` now defines `.gmw_picks` (an environment, token → `n x 3` landmark matrix), `.gmw_pick_handler`, `.gmw_picks_get`, and an exported `gmw_picks`.
- `.gmw_pick_handler` subsumes the `/close` teardown branch (one `call` handler per server), parses a bare `"x,y,z"` body with base-R string ops (no JSON), accepts only exactly 3 finite numbers, and appends a row to the server-owned store; malformed bodies are silently dropped with a 204.
- The mixed app in `.gmw_serve_mesh` now lists three static-path keys — `/<token>`, `/<token>/close`, `/<token>/pick` — with a second `httpuv::excludeStaticPath()` for `/pick`; the static byte mount is byte-for-byte unchanged.
- New `tests/testthat/test-picking-transport.R` proves: well-formed pick → 204 + row appended (1x3 then 2x3), malformed → 204 + array unchanged, cross-token isolation, `/close` → 204, other → 404, the T-2-02 no-filesystem-join invariant, no JSON dependency, and the CMP-01 oracle gate (30 PASS / 0 FAIL / 1 clean SKIP for the engine-present positive check).

## Task Commits

Each task was committed atomically:

1. **Task 1: Pick route, server-owned registry, and R accessors in transport.R** - `4060eb8` (feat)
2. **Task 2: Unit tests for the pick route + CMP-01 oracle-load gate** - `fb3dff9` (test)

**Plan metadata:** commit_docs is disabled in `.planning/config.json`, so the docs/state commit was intentionally skipped by the SDK.

## Files Created/Modified
- `R/transport.R` - Added `.gmw_picks` store, `.gmw_pick_handler` (subsumes `/close`), `.gmw_picks_get`, exported `gmw_picks`; wired the second `/pick` excludeStaticPath and swapped the `call` handler.
- `NAMESPACE` - Added `export(gmw_picks)`.
- `tests/testthat/test-picking-transport.R` - New direct-handler unit suite + T-2-02 and CMP-01 source-scan/skip-safe gates.

## Decisions Made
- Kept `.gmw_close_handler` defined even though `.gmw_pick_handler` subsumes its logic, because `test-transport.R` invokes `.gmw_close_handler` directly; retiring it would have broken an existing green test. The `startServer` site now references `.gmw_pick_handler`.
- Added `export(gmw_picks)` to the roxygen-generated `NAMESPACE` by hand rather than running `roxygenize` (roxygen2/devtools not required in this environment, and a full re-generate would churn unrelated tags).

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
The plan's verification command `testthat::test_local(filter="picking-transport")` loads the package namespace via pkgload, which triggers the `tcltk2` GUI-init block documented in STATE.md ("headless test_local … hanging on the tcltk2/rgl GUI-init load"). This is a pre-existing environmental limitation, not a defect in this plan. Verification was instead run with `testthat::test_file()` after sourcing `helper-pkg-source.R` — which exercises every assertion in the new file without loading the GUI stack — yielding **30 PASS / 0 FAIL / 1 SKIP** (the CMP-01 positive `.gmw_engine$ok` check skips cleanly when the namespace is not loaded, exactly as specified).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The R half of PICK-01 is complete: R owns the landmark array and `gmw_picks(token)` returns the placed coordinates. The browser-side raycast + `sendBeacon("pick", ...)` (view3d.R), the PICK-02 overlay dot, and the PICK-03 record-replay parity harness remain for subsequent plans (04-02, 04-03).
- CMP-01 remains green: `transport.R` never writes `.gmw_engine`, and the positive oracle check is skip-safe until run on a display host with the native engine loaded.

## Self-Check: PASSED
- FOUND: `R/transport.R`
- FOUND: `tests/testthat/test-picking-transport.R`
- FOUND commit `4060eb8` (Task 1)
- FOUND commit `fb3dff9` (Task 2)

---
*Phase: 04-picking-parity*
*Completed: 2026-08-05*
