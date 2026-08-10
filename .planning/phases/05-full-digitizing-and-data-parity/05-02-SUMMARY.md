---
phase: 05-full-digitizing-and-data-parity
plan: 02
subsystem: api
tags: [httpuv, transport, digitizing, session, undo, loopback, base-r]

# Dependency graph
requires:
  - phase: 04-picking-parity
    provides: ".gmw_pick_handler token-guarded /pick route, .gmw_picks server-owned store, excludeStaticPath pattern"
  - phase: 02-local-transport-mesh-display
    provides: ".gmw_serve_mesh loopback static byte mount + token guard"
provides:
  - ".gmw_session package env: token -> list(specimens, current, curves, undo) — single authoritative per-specimen digitizing record"
  - "gmw_session(token=NULL) exported accessor mirroring gmw_picks"
  - "one-deep undo grammar inverting place/delete/move/curve_place"
  - ".gmw_digitize_handler: token-guarded /anchor /curve /delete /undo /specimen routes + thin forward-call branches for /downsample /gpa /export /save"
  - "per-dynamic-subpath excludeStaticPath registration in .gmw_serve_mesh"
affects: [view3d.R, surface.r, geomorph.r, main.r, 05-04, 05-05, 05-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Server-owns-state extended from one landmark matrix to a full per-specimen digitizing record"
    - "Single call handler with grepl suffix branches (no /edit verb-in-body); one excludeStaticPath entry per dynamic subpath"
    - "Curves stored as three DISTINCT landmark INDICES per integer row, session-scoped (shared across specimens)"
    - "Forward-call seams resolved at call time (try-wrapped) so Wave-2 plans never re-touch transport.R"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-digitizing-session.R
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/NAMESPACE

key-decisions:
  - "Route shape: per-route excludeStaticPath() + single grepl-branch call handler (A5 default), matching the Phase-4 /pick precedent"
  - "Multi-specimen switch is RE-SERVE: /specimen sets current index + clears undo + grows the specimen list lazily (A4 default)"
  - "curves is a 0x3 INTEGER matrix beside current/undo (session-scoped, A7); land/anchor/surfaces are per-specimen 0x3 numeric"
  - "Analytical branches (/downsample /gpa /export /save) forward-call not-yet-defined 05-04/05/06 seams under try(), staying a harmless 204 no-op until those plans land"

patterns-established:
  - "Digitizing edit routes are token-closured writers of only .gmw_session[[token]] — cross-token write is impossible"
  - "Bodies are bare CSV parsed with base R to a bounded, arity/finiteness/distinctness-checked vector; non-conforming bodies dropped with 204, never errored"

requirements-completed: [DGT-01, DGT-02, CMP-01]

coverage:
  - id: D1
    description: "/anchor appends a coordinate row to the current specimen's anchor array and pushes a place undo"
    requirement: "DGT-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-session.R#a well-formed /anchor returns 204 and appends a row to the current specimen"
        status: pass
    human_judgment: false
  - id: D2
    description: "/curve appends a 1x3 integer row for three distinct indices; malformed/duplicate bodies dropped"
    requirement: "DGT-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-session.R#/curve appends a 1x3 INTEGER row for three distinct indices; malformed dropped"
        status: pass
    human_judgment: false
  - id: D3
    description: "/delete removes the named row and pushes a one-deep undo that /undo reinserts at its original index"
    requirement: "DGT-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-session.R#/delete removes the named row and a following /undo restores it"
        status: pass
    human_judgment: false
  - id: D4
    description: "/undo inverts place/delete/curve_place; curve undo drops the last curve row"
    requirement: "DGT-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-session.R#/undo inverts a curve placement (drops the last curve row)"
        status: pass
    human_judgment: false
  - id: D5
    description: "/specimen sets the current index and clears the one-deep undo (RE-SERVE switch)"
    requirement: "DGT-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-session.R#/specimen sets the current index and clears the one-deep undo"
        status: pass
    human_judgment: false
  - id: D6
    description: "Cross-token isolation — a handler for token A never mutates token B's session"
    requirement: "DGT-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-session.R#the digitize handler writes only its own token (no cross-token write)"
        status: pass
    human_judgment: false
  - id: D7
    description: "No route joins req$PATH_INFO to the filesystem; no JSON dependency (T-2-02 / T-5-03 / T-5-04)"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-session.R#the digitizing routes never join the request path to the filesystem (T-2-02)"
        status: pass
    human_judgment: false
  - id: D8
    description: "transport.R never assigns the native oracle engine env (CMP-01 invariant preserved)"
    requirement: "CMP-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-session.R#CMP-01: transport.R never assigns the native oracle engine env"
        status: pass
    human_judgment: false
  - id: D9
    description: "Phase-4 /pick and /close behavior unregressed (delegated to untouched .gmw_pick_handler)"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-transport.R (all blocks)"
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-08-07
status: complete
---

# Phase 5 Plan 02: Full Per-Specimen Digitizing Session + Loopback Edit Routes Summary

**R now owns a full per-specimen digitizing record (`.gmw_session`) with a one-deep undo grammar, and answers token-guarded `/anchor` `/curve` `/delete` `/undo` `/specimen` loopback routes (plus thin forward-call branches for the 05-04/05/06 analytical seams) — the single Wave-1 edit to `transport.R` for all of Phase 5.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-08-07T15:42:00Z
- **Completed:** 2026-08-07T15:50:13Z
- **Tasks:** 3
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- `.gmw_session` package env, sibling to `.gmw_picks`/`.gmw_server`, holding the single authoritative digitizing record keyed by token: `list(specimens, current, curves, undo)`.
- Exported `gmw_session(token = NULL)` accessor plus internal lazy init, and a one-deep undo grammar (`place`/`delete`/`move`/`curve_place`) that mirrors the Tk `pushUndo`/`doUndo`/`clearUndo` semantics.
- `.gmw_digitize_handler(token)` registered as the single `call` handler: `/anchor`, `/curve` (three distinct integer indices), `/delete`, `/undo`, `/specimen` (RE-SERVE switch), thin forward-call branches for `/downsample`/`/gpa`/`/export`(allow-listed fmt)/`/save`, `/pick`+`/close` delegated to the untouched `.gmw_pick_handler`, everything else 404.
- Every dynamic subpath registered via its own `httpuv::excludeStaticPath()` beside the byte-for-byte-unchanged static mount.
- All invariants asserted by tests: no-path-join (T-2-02/T-5-03), bounded base-R parse with malformed/duplicate drop (T-5-04), export allow-list (T-5-05), cross-token isolation (T-5-06), CMP-01 oracle-env untouched.

## Task Commits

Each task was committed atomically:

1. **Task 1: Wave-0 scaffold — failing session/route unit tests** - `34cb8bd` (test)
2. **Task 2: .gmw_session model, accessor, and one-deep undo grammar** - `c266355` (feat)
3. **Task 3: Digitizing route handler + excludeStaticPath registration** - `fc302ed` (feat)

_TDD plan: Task 1 is the RED scaffold (8 errors pre-implementation); Tasks 2–3 turn it GREEN (61 passing assertions)._

## Files Created/Modified
- `tests/testthat/test-digitizing-session.R` — direct-handler-invocation unit tests for the session model, undo, all edit routes, delegation, and the T-2-02/JSON-free/CMP-01 source-scans.
- `R/transport.R` — `.gmw_session` env + record helpers + accessor + undo grammar; `.gmw_digitize_handler`; per-subpath `excludeStaticPath` registration and `call = .gmw_digitize_handler(token)`.
- `NAMESPACE` — `export(gmw_session)`.

## Decisions Made
- **Route shape (A5 default):** per-route `excludeStaticPath()` + a single `grepl`-branch `call` handler, matching the Phase-4 `/pick` precedent (simpler handlers, same no-path-join invariant) rather than one `/edit` verb-in-body route.
- **Specimen switch (A4 default):** RE-SERVE — `/specimen` sets `current`, clears undo, and lazily grows the specimen list; one mesh live at a time (D-01).
- **Curves as indices, session-scoped:** `curves` is a `0x3` integer matrix beside `current`/`undo` (shared across specimens, A7); `land`/`anchor`/`surfaces` are per-specimen numeric matrices.
- **Analytical seams forward-called under `try()`:** `/downsample`/`/gpa`/`/export`/`/save` call the not-yet-defined 05-04/05/06 seam functions resolved at call time; wrapping in `try()` keeps an unimplemented seam a harmless `204` no-op so those plans need not re-touch `transport.R`.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None. (The sandbox reset the shell working directory between commands; commands were run with an explicit `cd` into the R package root, which also satisfies the plan's "working directory = R package root" note.)

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The Phase-5 transport surface is complete and frozen for Wave 1: Wave-2 plans (view3d.R, surface.r, geomorph.r, main.r) can build the browser-side edit reporting and mesh reload against these routes without editing `transport.R`.
- Seam functions `.gmw_downsample_session` (05-04), `.gmw_gpa_session`/`.gmw_export_session` (05-05), and `.gmw_save_session_dgt` (05-06) are forward-referenced and must be implemented by those plans; until then their routes are 204 no-ops.
- `gmw_session` is exported in `NAMESPACE` by hand alongside the roxygen `@export` tag; a future `roxygen2::roxygenise()` will reproduce the same line.

---
*Phase: 05-full-digitizing-and-data-parity*
*Completed: 2026-08-07*

## Self-Check: PASSED
- All created/modified files present on disk (test-digitizing-session.R, transport.R, SUMMARY.md).
- All task commits present in git history (34cb8bd, c266355, fc302ed).
- test-digitizing-session.R: 61 passed / 0 failed / 0 errors. test-picking-transport.R: 30 passed / 0 failed / 1 skip (CMP-01 namespace-not-loaded, expected headless).
