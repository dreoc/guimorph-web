---
phase: 05-full-digitizing-and-data-parity
plan: 04
subsystem: surface
tags: [surface, semilandmarks, tps, downsample, digitizing, session, transpose, base-r]

# Dependency graph
requires:
  - phase: 05-full-digitizing-and-data-parity
    plan: 02
    provides: ".gmw_session per-specimen record + /downsample route forward-calling .gmw_downsample_session(token) under try()"
provides:
  - ".gmw_downsample_session(token): headless surface-semilandmark builder reusing downSample's TPS warp; stores s x 3 surfaces in the session record; returns the row-major .gmw_flat cloud"
  - "test-surface-flatten.R: transpose regression pinning as.vector(t(m)) row-major order and rejecting the column-major mistake"
affects: [view3d.R, 05-05, 05-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Headless reuse of a validated Tk-path geometry routine (downSample) by lifting only its pure-geometry core (csize/rotate.mat/tps2d3d + NN), dropping Tk status bars and the C add() coupling"
    - "Server-owns-state: R computes the surface cloud and owns it in .gmw_session; the browser only triggers over /downsample and displays the returned row-major flatten"
    - "Mandatory transpose (.gmw_flat -> as.vector(t(.))) guarded by a regression test with a negative column-major assertion"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-surface-flatten.R
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.surface.r

key-decisions:
  - "Reused downSample's numerical TPS pipeline verbatim (csize/rotate.mat/tps2d3d + nearest-neighbour), changing only PB=FALSE to drop the interactive progress bar (no Tk, no message boxes)"
  - "The headless entry NEVER calls the C add(\"downsample\", ...) -- that re-couples acquisition to tkogl2 which Phase 6 removes (T-5-12)"
  - "Specimen point cloud is read from a session-record `specimen` slot; the entry stop()s with a clear message when it is absent, keeping the try()-wrapped /downsample route a harmless 204 no-op until the serve path populates it"
  - "The browser display cloud is returned through .gmw_flat, whose as.vector(t(.)) transpose is the single row-major guarantee, pinned by test-surface-flatten.R (T-5-11)"

requirements-completed: [DGT-02]

coverage:
  - id: SF1
    description: ".gmw_flat emits row-major as.vector(t(m)) and rejects the column-major ordering"
    requirement: "DGT-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-surface-flatten.R#.gmw_flat emits row-major [x1,y1,z1,...] = as.vector(t(m)), NOT column-major"
        status: pass
    human_judgment: false
  - id: SF2
    description: ".gmw_downsample_session runs the TPS warp headlessly, stores the s x 3 surfaces in the session, and returns the row-major flatten of that array (point order preserved)"
    requirement: "DGT-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-surface-flatten.R#.gmw_downsample_session returns the row-major flatten of the stored surfaces (order preserved)"
        status: pass
    human_judgment: false

# Metrics
duration: 3min
completed: 2026-08-07
status: complete
---

# Phase 5 Plan 04: Headless Surface Semilandmark Downsample Entry Summary

**`.gmw_downsample_session(token)` runs `downSample`'s validated TPS template warp + nearest-neighbour pass headlessly (no Tk, no C `add()`), reads landmarks/anchors/template/specimen from the server-owned `.gmw_session` record, stores the resulting s x 3 surface array back in that record, and returns the browser cloud through the mandatory row-major `as.vector(t(.))` flatten — with the transpose pinned by a new regression test.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-08-07T16:12:23Z
- **Completed:** 2026-08-07T16:16:00Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- `.gmw_downsample_session(token)` added to `R/3dDigitize.surface.r`: an internal `@noRd` headless surface-semilandmark builder the 05-02 `/downsample` route forward-calls.
- Reuses the exact numerical pipeline `downSample` uses — `csize`/`rotate.mat` template scaling+rotation, `tps2d3d` TPS warp, and the per-point nearest-neighbour-with-removal onto the specimen cloud — with only `PB = FALSE` to silence the interactive progress bar. No Tk status-bar calls, no `tkmessageBox`, no C `add("downsample", ...)` (kept clean for the Phase-6 engine retirement).
- Reads `land`/`anchor`/`template`/`specimen` from `.gmw_session[[token]]`'s current specimen record (never `activeDataList`/`getLandmark`), stores the `sliders` (s x 3) into the record's `surfaces` slot (server-owns-state), and returns `.gmw_flat(sliders)` — the row-major cloud the display expects.
- `tests/testthat/test-surface-flatten.R` pins `.gmw_flat` to `as.vector(t(m))` on a fixed asymmetric matrix, explicitly rejects the column-major `as.vector(m)` ordering, and exercises `.gmw_downsample_session` end-to-end on a synthetic session, asserting the returned cloud is the row-major flatten of the stored surfaces (and not the column-major one).

## Task Commits

Each task was committed atomically (TDD RED → GREEN):

1. **Task 1: Wave-0 scaffold — surface flatten transpose regression** - `1a07eed` (test) — 2 pass (`.gmw_flat` block) + 1 error (`.gmw_downsample_session` not yet defined).
2. **Task 2: Headless .gmw_downsample_session entry (reuse downSample TPS warp)** - `69b0aa6` (feat) — turns the red block green; full file 7/7 pass.

## Files Created/Modified
- `tests/testthat/test-surface-flatten.R` — new regression test: row-major flatten pinned with a negative column-major assertion; a synthetic-session block that runs the headless warp and checks the returned cloud equals `.gmw_flat(surfaces)` and not the column-major ordering. Standard `pkg_root` / `skip_if_no_pkg_source()` / `source()` header; sources `view3d.R` + `gm_utils.R` + `transport.R` + `3dDigitize.surface.r` and shims `dbg()` when absent.
- `R/3dDigitize.surface.r` — `.gmw_downsample_session(token)` added directly below `downSample`, reusing its geometry core and documenting the no-`add()` / server-owns-state contract.

## Decisions Made
- **Reuse verbatim, headless:** the TPS/NN math is lifted unchanged from `downSample` (400-567); only `PB = FALSE` differs, so the surface output stays numerically identical to the validated Tk path.
- **No C re-coupling:** `.gmw_downsample_session` never calls `add("downsample", ...)`; the two legacy `add("downsample")` sites (lines 554, 862) remain the only callers, keeping the browser path free of `tkogl2` (T-5-12).
- **Transpose is the contract:** the browser cloud is returned through `.gmw_flat` (`as.vector(t(.))`); `test-surface-flatten.R` fails on any column-major regression (T-5-11).
- **Specimen source:** the entry reads the specimen vertex cloud from a `specimen` slot on the session record and `stop()`s cleanly if it is missing — see Known Stubs.

## Deviations from Plan
- **[Rule 3 - Blocking] `cSize` → `csize`.** The plan text (and 05-RESEARCH) names the centroid-size helper `cSize`, matching the legacy `downSample` call at line 515. `cSize` (capital S) is **not defined** anywhere in the current GUImorphWeb package — it lived in the retired `geomorph.support.code.r`; the surviving `gm_utils.R` defines the standard `csize` (lowercase). The legacy `downSample` therefore references an undefined symbol on its Tk path, but the browser entry must run. `.gmw_downsample_session` uses the defined `csize`, which is the identical centroid-size computation, so the numerical pipeline is unchanged. No `activeDataList`/Tk behavior was altered. Files: `R/3dDigitize.surface.r`. Commit: `69b0aa6`.

## Known Stubs
- **`specimen` session slot not yet populated by the serve path.** `.gmw_downsample_session` reads the specimen point cloud from `.gmw_session[[token]]$specimens[[cur]]$specimen`. The 05-02 empty record (`land`/`anchor`/`surfaces`/`template`) does not include this slot, and no route/serve path writes it yet, so a live `/downsample` trigger currently `stop()`s and the try()-wrapped route stays a harmless 204 no-op. This is intentional per the 05-02 forward-call seam design: wiring the served PLY vertices into the session record is a downstream concern (surface acquisition trigger, 05-05/05-06 or a small transport addition). This plan's `files_modified` is scoped to `3dDigitize.surface.r` + the test, so populating the slot is deliberately out of scope. The regression test seeds `specimen` directly to exercise the warp.

## Issues Encountered
None blocking. The sandbox resets the shell working directory between some commands; commands were run against the R package root (`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`) with `--no-init-file` to avoid the `renv` activate hang (STATE.md Open Items).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The `/downsample` seam (05-02) now resolves to a real headless warp. Once the serve/acquisition path populates the session `specimen` slot, the browser can trigger surface computation and receive a correctly-transposed cloud with zero further edits to `3dDigitize.surface.r`.
- 05-05/05-06 (GPA / export / save seams) can read the `surfaces` slot this plan populates.

---
*Phase: 05-full-digitizing-and-data-parity*
*Completed: 2026-08-07*

## Self-Check: PASSED
- Created/modified files present on disk: test-surface-flatten.R, R/3dDigitize.surface.r, 05-04-SUMMARY.md.
- Task commits present in git history: 1a07eed (test), 69b0aa6 (feat).
- test-surface-flatten.R: 7 passed / 0 failed / 0 error. test-digitizing-session.R unregressed (61/0/0).
