---
phase: 05-full-digitizing-and-data-parity
plan: 05
subsystem: api
tags: [geomorph, gpagen, gpa, export, session, digitizing, parity, tcltk, base-r]

# Dependency graph
requires:
  - phase: 05-full-digitizing-and-data-parity
    provides: "05-02 .gmw_session per-specimen record + /gpa and /export forward-call route seams"
  - phase: 05-full-digitizing-and-data-parity
    provides: "05-04 .gmw_session_to_env pattern (.gmw_downsample_session reads the server-owned session record headlessly)"
provides:
  - ".gmw_session_to_geomorph_env(token, opts): materialises a geomorph analysis env from the session by populating activeDataList[[i]][[10]] (landmarks) / [[1]][[4]] (curves) / [[i]][[8]] (surfaces) + landmarkNum/anchorNum/sliderNum + gpagen option tclVars, so .build_geomorph_data/compute run with ZERO forwarding edits"
  - ".gmw_gpa_session(token, opts): /gpa trigger seam calling compute(e) verbatim"
  - ".gmw_export_session(token, fmt): /export trigger seam, allow-list c(\"csv\",\"rds\"), dispatch to existing save()/exportGeomorph()"
affects: [05-06, 06-native-engine-removal]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Browser-triggered analysis reuses the native pure-R functions verbatim; the ONLY new code is the session->activeDataList read seam (identical-to-native by construction)"
    - "gpagen option fields materialised as tcltk::tclVar so compute()'s tclvalue() forwarding is read unchanged (never edited)"
    - "Export target/path chosen R-side by save()/exportGeomorph(); the /export route carries only an allow-listed format token, never a path"

key-files:
  created: []
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-gpa-parity.R
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-export-parity.R

key-decisions:
  - "Env builder targets the EXISTING activeDataList fallback slots (landmarks -> [[i]][[10]], curves -> [[1]][[4]], surfaces -> [[i]][[8]]) so .build_geomorph_data/compute are reused with zero body edits (RESEARCH Open Question 3 recommended default)"
  - "gpagen options carried as tclVar via opts so compute()'s tclvalue()-based forwarding source-scan stays byte-identical"
  - ".gmw_export_session builds its env with default (curves/surfaces off) opts; csv export reuses the last GPA result via the workspace gm.results fallback in .gm_results_or_warn, rds export rebuilds from the session env"

patterns-established:
  - "Trigger seams are thin: parse/validate -> build env from server-owned session -> call the inherited analytical function; no browser-side geometry, no C-engine coupling"

requirements-completed: [DGT-03]

coverage:
  - id: D1
    description: ".gmw_session_to_geomorph_env populates the same activeDataList slots the native path fills, so the session read path yields the identical .build_geomorph_data output as a hand-populated activeDataList env"
    requirement: "DGT-03"
    verification:
      - kind: unit
        ref: "tests/testthat/test-gpa-parity.R#session read path yields the same .build_geomorph_data as populated activeDataList"
        status: pass
    human_judgment: false
  - id: D2
    description: "The parity-critical gpagen option forwarding in compute() is untouched (the existing source-scan still passes after adding the seams)"
    requirement: "DGT-03"
    verification:
      - kind: unit
        ref: "tests/testthat/test-gpa-parity.R#compute forwards parity-critical gpagen options"
        status: pass
    human_judgment: false
  - id: D3
    description: ".gmw_export_session dispatches only to the existing save()/exportGeomorph() and validates fmt against the allow-list c(\"csv\",\"rds\"); no second serializer, no path from the request"
    requirement: "DGT-03"
    verification:
      - kind: unit
        ref: "tests/testthat/test-export-parity.R#.gmw_export_session dispatches only to save/exportGeomorph with an allow-listed fmt"
        status: pass
    human_judgment: false
  - id: D4
    description: "End-to-end browser GPA run (compute -> gpagen -> result plots) and .csv/.rds file export against real multi-specimen data on a display host"
    verification: []
    human_judgment: true
    rationale: "The seams reuse geomorph::gpagen and the interactive tkgetSaveFile-based exporters; a real GPA + file-dialog export on a display host with geomorph installed cannot be exercised in the headless test sandbox."

# Metrics
duration: 6min
completed: 2026-08-07
status: complete
---

# Phase 5 Plan 05: Browser-Driven GPA and .csv/.rds Export Summary

**GPA (`geomorph::gpagen`) and `.csv`/`.rds` export now run from the browser by reading the server-owned digitizing session into the existing `activeDataList` slots, so `compute`/`save`/`exportGeomorph` execute verbatim — identical-to-native by construction with the gpagen option forwarding untouched.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-08-07T16:18:00Z
- **Completed:** 2026-08-07T16:24:30Z
- **Tasks:** 2
- **Files modified:** 3 (0 created, 3 modified)

## Accomplishments
- `.gmw_session_to_geomorph_env(token, opts)` — builds a disposable geomorph env from `.gmw_session[[token]]`: per-specimen landmarks into `activeDataList[[i]][[10]]` (the `.landmarks_for_specimen` fallback slot), session-scoped curve index rows into `[[1]][[4]]`, surfaces into `[[i]][[8]]`, plus `landmarkNum`/`anchorNum`/`sliderNum` and every gpagen option as a `tclVar` — so `.build_geomorph_data(e)` and `compute(e)` run with zero edits to their forwarding.
- `.gmw_gpa_session(token, opts)` — `/gpa` trigger seam: builds the env and calls the existing `compute(e)` (which forwards all parity-critical gpagen options and stores `gm.results` in the env and the workspace, keeping the result-plot seams routing through `.gmw_view3d`).
- `.gmw_export_session(token, fmt)` — `/export` trigger seam: validates `fmt` against the allow-list `c("csv","rds")` and dispatches `csv` -> `save(e)`, `rds` -> `exportGeomorph(e)`; no second serializer, and the export path is chosen R-side, never taken from the request.
- Parity tests extended: a session-vs-active `.build_geomorph_data` equality block and an `.gmw_export_session` dispatch/allow-list source-scan; the existing gpagen-forwarding scan and `.csv`/`.rds` determinism tests still pass.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend GPA/export parity tests for the session read path** - `cb85d13` (test)
2. **Task 2: Session→geomorph env builder + GPA/export seams (forwarding untouched)** - `a4a14fc` (feat)

_Plan 05-05 Task 2 is `tdd="true"`: Task 1 is the RED scaffold (gpa 1 error + export 3 failures pre-implementation); Task 2 turns it GREEN (gpa 13 passed, export 9 passed, 0 failed/0 error)._

## Files Created/Modified
- `R/3dDigitize.geomorph.r` — added the three `@noRd` trigger seams (`.gmw_session_to_geomorph_env`, `.gmw_gpa_session`, `.gmw_export_session`); `.build_geomorph_data`, `compute`, `save`, `exportGeomorph` bodies unchanged (pure additions, +141 lines).
- `tests/testthat/test-gpa-parity.R` — session-vs-active `.build_geomorph_data` equality block (Tcl-guarded skip; `getLandmark` stubbed NULL to force the `activeDataList[[i]][[10]]` fallback).
- `tests/testthat/test-export-parity.R` — `.gmw_export_session` dispatch + `c("csv","rds")` allow-list scan.

## Decisions Made
- **Read seam only (RESEARCH Open Question 3 default):** the env builder populates the *existing* `activeDataList` fallback slots rather than editing the analytical code, so "identical to native" is the same code on the same input.
- **Options as tclVar:** gpagen option fields are materialised via `tcltk::tclVar` so `compute()`'s `tclvalue()` forwarding is read unchanged and its source-scan stays byte-identical.
- **Export env uses default opts:** `.gmw_export_session` builds its env with curves/surfaces off; `csv` reuses the last GPA result through the `.gm_results_or_warn` workspace fallback, `rds` rebuilds `gmData` from the session env via the untouched `exportGeomorph`.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- Headless Tcl: `.build_geomorph_data`/`compute` read options via bare `tclvalue()`, which needs the Tcl interpreter on the search path. The new gpa-parity block attaches `tcltk` (skips cleanly if unavailable) and stubs the C `getLandmark` to `NULL` so `.landmarks_for_specimen` uses the `activeDataList[[i]][[10]]` fallback — the exact slot the browser path populates. The sandbox emits Tk load warnings but Tcl variable ops work; tests are green.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The Phase-5 analytical seams are complete: `/downsample` (05-04), `/gpa` + `/export` (05-05) all read the server-owned session headlessly with no C-engine coupling. 05-06 (`/save` -> `.gmw_save_session_dgt`) remains to close `.dgt` write-from-browser.
- Runtime GPA + file-dialog export on a display host with `geomorph` installed is the one owed human check (coverage D4) — the seams reuse `geomorph::gpagen` and the interactive `tkgetSaveFile` exporters verbatim, which the headless sandbox cannot exercise.

---
*Phase: 05-full-digitizing-and-data-parity*
*Completed: 2026-08-07*

## Self-Check: PASSED
- Modified files present on disk (3dDigitize.geomorph.r, test-gpa-parity.R, test-export-parity.R, 05-05-SUMMARY.md).
- Both task commits present in git history (cb85d13 test, a4a14fc feat).
- test-gpa-parity.R: 13 passed / 0 failed / 0 error. test-export-parity.R: 9 passed / 0 failed / 0 error.
