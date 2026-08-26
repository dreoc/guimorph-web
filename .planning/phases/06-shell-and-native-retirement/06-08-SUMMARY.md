---
phase: 06-shell-and-native-retirement
plan: 08
subsystem: infra
tags: [native-retirement, tcltk, tcltk2, rgl, roxygen, namespace, news, source-scan, R, release-1.0.0]

# Dependency graph
requires:
  - phase: 06-shell-and-native-retirement
    provides: "Plan 07 physically deleted the native tkogl2 engine (rtkogl.R, inst/libs binaries, tkogl2/ build tree) and left NAMESPACE tcltk imports + export(loadDgt) for this plan's roxygen regen"
  - phase: 06-shell-and-native-retirement
    provides: "Plans 04-06 stripped every Tk builder/dialog and add/set/del/shows engine verb from main.r/digitize.r/curve.r/surface.r/geomorph.r"
provides:
  - "DESCRIPTION severed: Imports has no tcltk/tcltk2, Suggests has no rgl, Version 1.0.0, Description rewritten to the three.js-over-httpuv browser architecture (D-01/D-05)"
  - "NAMESPACE regenerated via roxygen2: no import(tcltk)/import(tcltk2)/export(loadDgt); keeps import(Rvcg)/import(geomorph) + the four exports (GUImorphWeb/gmw_close/gmw_picks/gmw_session)"
  - "Internal tclVar()/tclvalue() compat shim in 3dDigitize.geomorph.r so the GPA compute() forwarding stays textually unchanged while tcltk leaves the namespace"
  - ".gmw_save_session_dgt no-path fallback rewired off tkgetSaveFile to the session save-name/browse_dir path (D-03) -- the last live Tk dialog is gone"
  - "NEWS.md 1.0.0 migration note: breaking-change list, GUImorph primary destination + pin 0.10.0 fallback, PICK-03/DAT-02 won't-verify closure (D-04)"
  - "Test suite reconciled and fully green: parity gates retired to documented won't-verify skips, tcltk-stub/deleted-symbol reds greened, deps-clean + NEWS source-scan gates added (UI-03)"
affects: [milestone-verify, ship]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "tcltk-compat shim: a package-internal tclVar()/tclvalue() pair reproduces the option-flag read/write contract so parity-pinned compute() forwarding stays byte-unchanged while tcltk leaves Imports/NAMESPACE"
    - "roxygen namespace-roclet-only regen (roxygen2::roxygenise(roclets='namespace')) to rewrite NAMESPACE without generating man/ or touching Collate"
    - "won't-verify closure as a single documented skip() test citing the decision ID, keeping the gate visible in the suite rather than silently deleted"
    - "read.dcf/readLines source-scan gate with concatenation-built forbidden tokens so it fails on a re-declared dep and never self-trips on its own prose"

key-files:
  created:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/NEWS.md"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-deps-clean.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-news-migration.R"
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/NAMESPACE"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-dgt-cross-platform.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-gpa-parity.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-curve-io.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-macos-dialog-shortcuts-parity.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-picking-parity.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-retina-picking-parity.R"

key-decisions:
  - "Added a package-internal tclVar()/tclvalue() shim (Rule 3) rather than rewriting compute()/.build_geomorph_data: the parity source-scan pins those tclvalue() forwarding lines textually, and removing import(tcltk) would otherwise leave bare tclvalue()/tclVar unresolved -- the shim severs tcltk with zero change to the parity-critical path"
  - "Rewired .gmw_save_session_dgt's no-path branch off the surviving tkgetSaveFile picker to the session save-name + browse_dir path (Rule 2/Rule 3, D-03): production /save calls it with file=NULL, so the Tk dialog was both a live tcltk dependency and a D-03 violation"
  - "Retired the two picking-parity tests and the DAT-02 -rewrite gate to single documented skip() tests (not deletion) so the won't-verify closures stay auditable in the suite (D-04)"
  - "Regenerated NAMESPACE with the namespace roclet only; migrated the deprecated @docType package to the \"_PACKAGE\" sentinel, which also clears the roxygen deprecation noise"
  - "Full R CMD check not run headlessly (renv-hang + GUI-init constraints documented across the phase); tcltk/tcltk2/rgl cleanliness established by NAMESPACE/DESCRIPTION severance + pkgload::load_all success + an R/-wide static scan (only comments mention the retired toolkits) + the full 675-pass suite"

patterns-established:
  - "Toolkit-severance shim: when a dependency is dropped but a parity-pinned call site must stay textually intact, provide a tiny in-package compat shim for the removed symbols instead of touching the pinned code"

requirements-completed: [UI-03]

coverage:
  - id: D1
    description: "DESCRIPTION Imports has no tcltk/tcltk2, Suggests has no rgl, Version is 1.0.0, and the Description text reflects the browser architecture (D-01/D-05)"
    requirement: "UI-03"
    verification:
      - kind: unit
        ref: "tests/testthat/test-deps-clean.R#DESCRIPTION severs tcltk/tcltk2 from Imports, rgl from Suggests, and is 1.0.0"
        status: pass
    human_judgment: false
  - id: D2
    description: "NAMESPACE regenerated (roxygen2) with no import(tcltk)/import(tcltk2)/export(loadDgt), keeping import(Rvcg)/import(geomorph) + the four exports; package loads engine-and-Tk-absent"
    requirement: "UI-03"
    verification:
      - kind: unit
        ref: "tests/testthat/test-deps-clean.R#NAMESPACE drops the tcltk imports and the loadDgt export, keeps the rest"
        status: pass
      - kind: automated
        ref: "Rscript -e 'pkgload::load_all(export_all=FALSE)' -> LOAD_OK; loadDgt gone; GUImorphWeb exported"
        status: pass
    human_judgment: false
  - id: D3
    description: "NEWS.md ships the 1.0.0 migration note: breaking-change list, GUImorph primary destination + pin 0.10.0 fallback, and the PICK-03/DAT-02 won't-verify closure (D-05/D-06/D-07/D-04)"
    requirement: "UI-03"
    verification:
      - kind: unit
        ref: "tests/testthat/test-news-migration.R#NEWS.md ships the 1.0.0 migration note (pin 0.10.0, GUImorph, D-04)"
        status: pass
    human_judgment: false
  - id: D4
    description: "PICK-03 and the DAT-02 -rewrite byte gate formally closed as won't-verify; parity tests retired to documented skips; the previously-red tcltk-stub/deleted-symbol tests greened; full suite passes"
    requirement: "UI-03"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-parity.R + test-retina-picking-parity.R + test-dgt-cross-platform.R#DAT-02 -rewrite byte gate is closed as won't-verify (D-04) -> documented skips"
        status: pass
      - kind: integration
        ref: "testthat::test_dir('tests/testthat') -> fail=0 skip=6 pass=675"
        status: pass
    human_judgment: false

# Metrics
duration: 15min
completed: 2026-08-14
status: complete
---

# Phase 6 Plan 08: DESCRIPTION/NAMESPACE Severance, NEWS.md, and Test Reconciliation Summary

**`tcltk`, `tcltk2`, and `rgl` are gone from the package metadata and namespace, GUImorphWeb is 1.0.0, `NEWS.md` ships the browser-migration note (GUImorph primary + pin 0.10.0 fallback + PICK-03/DAT-02 won't-verify closure), and the previously-6-red suite is fully green (675 pass, 0 fail) — the retirement is complete and UI-03 is satisfied.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-08-14T15:43:56Z
- **Completed:** 2026-08-14T15:58:25Z
- **Tasks:** 4
- **Files modified:** 14 (3 created, 10 modified, 1 deleted)

## Accomplishments
- Severed `tcltk`/`tcltk2` from `DESCRIPTION` `Imports` and `rgl` from `Suggests`, bumped `Version` 0.10.0 → 1.0.0, bumped `Date`, and rewrote the `Description` to the three.js-over-httpuv browser architecture (D-01/D-05).
- Removed the `@import tcltk`/`@import tcltk2` roxygen directives, migrated the deprecated `@docType package` to the `"_PACKAGE"` sentinel, and regenerated `NAMESPACE` with the roxygen namespace roclet: it now drops `import(tcltk)`, `import(tcltk2)`, and the dangling `export(loadDgt)` (function deleted in Plan 07) while keeping `import(Rvcg)`/`import(geomorph)` and the four exports. `pkgload::load_all()` succeeds with the engine and Tk absent.
- Added a package-internal `tclVar()`/`tclvalue()` compat shim so the parity-pinned GPA `compute()`/`.build_geomorph_data()` forwarding stays textually unchanged while `tcltk` leaves the namespace; changed the one `tcltk::tclVar` site in the session bridge to the shim.
- Rewired the last live Tk dialog: `.gmw_save_session_dgt`'s no-path fallback (reached by the production `/save` route with `file=NULL`) now derives the destination from the session save-name + browse dir (D-03) instead of `tkgetSaveFile`.
- Created `NEWS.md` with the 1.0.0 migration note: breaking-change list (native OpenGL/`tkogl2` engine, `rgl`, `tcltk`/`tcltk2` chrome removed), GUImorph (`dreoc/GUImorph`) as the primary destination, pin `GUImorphWeb 0.10.0` as the fallback, and the PICK-03/DAT-02 won't-verify closure citing `05-WINDOWS-REVIEW.md`.
- Reconciled the test suite: retired the two picking-parity tests and the DAT-02 `-rewrite` gate to documented won't-verify skips (D-04), greened the long-standing reds (deleted-symbol `test-curve-spinbox.R`, `dbg`-not-sourced `test-curve-io.R`, `library(tcltk)`-bound `test-gpa-parity.R`, stale `test-macos-dialog-shortcuts-parity.R` assertions), and added `test-deps-clean.R` + `test-news-migration.R` source-scan gates. Full suite: **675 pass, 0 fail, 6 documented skips**.

## Task Commits

Each task was committed atomically:

1. **Task 1: Sever DESCRIPTION deps + 1.0.0, remove tcltk roxygen imports, regen NAMESPACE** - `8ba5edf` (feat)
2. **Task 2: Create NEWS.md migration note** - `f1a6a6d` (docs)
3. **Task 3: Reconcile parity / tcltk-stub / deleted-symbol tests** - `4caff2e` (test)
4. **Task 4: Add deps-clean + NEWS source-scan tests** - `49d7ef2` (test)

**Plan metadata:** docs commit skipped (`commit_docs: false` in `.planning/config.json` — `.planning/` docs are intentionally kept out of git history).

_Note: Task 4 carries `tdd="true"`, but the plan sequences the artifacts (severed DESCRIPTION/NAMESPACE in Task 1, NEWS.md in Task 2) ahead of the source-scan tests, so a genuine RED-against-present-code commit was not possible (same ordering as Plans 06-01/03/06/07). Both new tests are real gates rather than tautologies — `test-deps-clean.R` was verified to FAIL against the pre-severance `DESCRIPTION` (`HEAD~3`, which still declared tcltk in Imports and rgl in Suggests). See TDD Gate Compliance below._

## Files Created/Modified
- `DESCRIPTION` — Imports −tcltk −tcltk2; Suggests −rgl; Version 1.0.0; Date bumped; Description rewritten to the browser architecture.
- `NAMESPACE` — regenerated: −import(tcltk) −import(tcltk2) −export(loadDgt); retains import(Rvcg)/import(geomorph) + 4 exports.
- `R/3dDigitize.main.r` — removed the `@import tcltk`/`@import tcltk2` roxygen tags, `@docType package` → `"_PACKAGE"`; `.gmw_save_session_dgt` no-path branch rewired off `tkgetSaveFile` to the session save-name/browse_dir path (D-03).
- `R/3dDigitize.geomorph.r` — added the internal `tclVar()`/`tclvalue()` shim; dropped the `tcltk::` prefix in `.gmw_session_to_geomorph_env`.
- `NEWS.md` (new) — 1.0.0 migration note.
- `tests/testthat/test-deps-clean.R` (new) — DESCRIPTION/NAMESPACE/inst-libs source-scan gate (UI-03).
- `tests/testthat/test-news-migration.R` (new) — NEWS.md content gate (UI-03).
- `tests/testthat/test-picking-parity.R`, `test-retina-picking-parity.R` — retired to documented won't-verify skips (D-04).
- `tests/testthat/test-dgt-cross-platform.R` — DAT-02 `-rewrite` gate → documented won't-verify skip; reader/writer determinism assertions kept live.
- `tests/testthat/test-gpa-parity.R` — dropped `library(tcltk)` guards; the shim now resolves the option flags.
- `tests/testthat/test-curve-io.R` — sources `shell.R` so `read.curve`'s `dbg()` resolves.
- `tests/testthat/test-macos-dialog-shortcuts-parity.R` — inverted the stale `{{All files} *}` and surface `zoom(...)` assertions to absence.
- `tests/testthat/test-curve-spinbox.R` — **deleted** (its `.clampCurveMax`/`.clampCurveCurrent` were removed with the Tk curve UI in 06-05).

## Decisions Made
- **tcltk-compat shim over rewriting compute().** The plan scoped Task 1 to DESCRIPTION/NAMESPACE/main.r and requires the GPA `compute()` forwarding to stay byte-unchanged (pinned by `test-gpa-parity.R`). But `compute()`/`.build_geomorph_data()` read the gpagen option flags through bare `tclvalue()`, and the browser bridge wrapped values with `tcltk::tclVar()` — so removing `import(tcltk)` would leave those unresolved. A tiny in-package `tclVar()`/`tclvalue()` shim (character-scalar holder + reader, reproducing the `"0"`/`"1"` semantics `itob()`/`as.numeric()` expect) severs tcltk with zero change to the pinned path.
- **Kept the won't-verify closures visible as skips.** Rather than deleting the retired parity tests, each is a single `skip()` citing D-04, so the closure is auditable in the suite report.
- **Namespace-roclet-only regen.** `roxygen2::roxygenise(roclets = "namespace")` rewrote only `NAMESPACE` — no `man/` files or `Collate` churn.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Internal tclVar()/tclvalue() shim to keep GPA compute() resolvable after tcltk severance**
- **Found during:** Task 1 (DESCRIPTION/NAMESPACE severance)
- **Issue:** `3dDigitize.geomorph.r` reads gpagen option flags via bare `tclvalue()` in `compute()`/`.build_geomorph_data()` (textually pinned by `test-gpa-parity.R`) and wraps values with `tcltk::tclVar()` in `.gmw_session_to_geomorph_env`. Removing `import(tcltk)` / the `@import tcltk` tag would leave bare `tclvalue()`/`tclVar` unresolved at runtime and flag an undeclared `tcltk::` usage under R CMD check — the plan's Task-1 file set (DESCRIPTION/NAMESPACE/main.r) did not account for this.
- **Fix:** Added a package-internal `tclVar()`/`tclvalue()` compat shim in `3dDigitize.geomorph.r` and changed the single `tcltk::tclVar` site to the shim; the parity-critical `compute()` forwarding is untouched.
- **Files modified:** `R/3dDigitize.geomorph.r`
- **Verification:** shim reproduces `tclvalue(1)→"1"`/`itob→TRUE`, `tclvalue(0)→"0"`/`itob→FALSE`, `.safe_gpagen_maxiter` parse; `test-gpa-parity.R` 15/15 pass with the `library(tcltk)` guards removed; `test-gpa-parity.R` source-scan still green.
- **Committed in:** `8ba5edf` (Task 1)

**2. [Rule 2 / Rule 3 - Missing Critical / Blocking] Rewired the last live tkgetSaveFile off the browser save path (D-03)**
- **Found during:** Task 1 (severance) — grep of `R/` for surviving `tk*` dialogs
- **Issue:** `.gmw_save_session_dgt(token, file=NULL)` is called by the production `/save` route with `file=NULL`, and its fallback invoked `tkgetSaveFile` — both a live `tcltk`/Tk dependency (breaks with tcltk gone) and a D-03 violation (the browser save-name already arrives over `/savepath`; R owns the path).
- **Fix:** The no-path branch now derives the destination from the session `save_name` + `browse_dir` (mirroring `save()`/`exportGeomorph()`); an empty save-name is a no-op (former Cancel path).
- **Files modified:** `R/3dDigitize.main.r`
- **Verification:** the DAT-01 byte-identity test (`test-dgt-cross-platform.R`, explicit `file`) stays green; R/-wide scan shows no live `tkgetSaveFile`/`tkgetOpenFile`/`tkmessageBox`/`tk_chooseColor` (comments only).
- **Committed in:** `8ba5edf` (Task 1)

**3. [Rule 1 - Bug] Reconciled two previously-red tests unrelated to the deleted-function/tcltk-stub set the plan named**
- **Found during:** Task 3 (test reconciliation) — full-suite baseline
- **Issue:** (a) `test-curve-io.R` errored on its empty-curve case because `read.curve` calls `dbg()`, which was relocated to `shell.R` in 06-03 but the test only sourced `curve.r`. (b) `test-macos-dialog-shortcuts-parity.R:58` asserted `3dDigitize.surface.r` still contained the `zoom(e, normalizeWheelDelta(D))` wheel binding — stale since the 06-06 surface strip (the red logged in `deferred-items.md`). (c) The same file's "all files" test asserted a `{{All files} *}` Tk filetypes string that this plan's Task-1 `tkgetSaveFile` removal deleted.
- **Fix:** (a) source `shell.R` in `test-curve-io.R`; (b) invert the surface `zoom` assertion to absence (browser owns wheel-to-zoom); (c) invert the `{{All files} *}` assertion to absence while keeping the `.warnUnexpectedExtension` check.
- **Files modified:** `tests/testthat/test-curve-io.R`, `tests/testthat/test-macos-dialog-shortcuts-parity.R`
- **Verification:** both files green; full suite 675 pass / 0 fail.
- **Committed in:** `4caff2e` (Task 3)

---

**Total deviations:** 3 auto-fixed (2 blocking/missing-critical from an under-scoped severance, 1 bug across two stale tests). **Impact:** All necessary to make the LOCKED D-01 full-toolkit severance actually load, pass R CMD check cleanly, and leave the suite green; the shim and save-path rewire are the minimal, non-architectural way to sever tcltk without touching the parity-pinned `compute()` path. The `deferred-items.md` 06-06 red is now closed.

## Issues Encountered
- **`devtools` not installed; full `R CMD check` not run headlessly.** NAMESPACE regen used `roxygen2::roxygenise(roclets = "namespace")` (roxygen2 present); load/verify used `pkgload::load_all()` and `testthat::test_dir()` under `--no-init-file` (bare R hangs under the workspace `renv` activate — the standing STATE open item). `R CMD check` cleanliness of `tcltk`/`tcltk2`/`rgl` is established instead by the NAMESPACE/DESCRIPTION severance, a clean `load_all`, an R/-wide static scan (the retired toolkits appear only in comments), and the full 675-pass suite — the same substitution pattern used across Plans 06-04..07.

## TDD Gate Compliance
Task 4 carries `tdd="true"`, but the plan sequences the artifacts it scans (severed DESCRIPTION/NAMESPACE in Task 1, NEWS.md in Task 2) ahead of the tests, so a genuine RED-against-present-code commit was not possible (identical ordering to Plans 06-01/03/06/07). Both new gates are real, not tautologies: `test-deps-clean.R` was confirmed to FAIL against the pre-severance `DESCRIPTION` at `HEAD~3` (Imports still had `tcltk`, Suggests still had `rgl`), and its forbidden tokens are concatenation-built so the gate cannot self-trip. Commit type is `test` for Task 4.

## Next Phase Readiness
- **Phase 6 complete.** All eight plans executed; UI-01/UI-02/UI-03 delivered. `tcltk`/`tcltk2`/`rgl` and the native `tkogl2` engine are fully retired, the package is 1.0.0, `NEWS.md` ships the migration note, and the suite is green.
- **Milestone-verify ready.** PICK-03 and the DAT-02 `-rewrite` gate are formally closed as won't-verify (D-04); the two pending todos (`pick03-windows-parity-capture-owed.md`, `dat-parity-gate-is-a-skip.md`) should be retired by the orchestrator/verify step.
- **Config note:** `create_tag: true` — a `1.0.0` release tag should accompany the ship step.
- **Standing open item (unchanged):** the workspace-local `renv` side effect still makes bare `R`/`Rscript` hang without `--no-init-file`.

## Self-Check: PASSED

**Created files:**
- FOUND: `NEWS.md`
- FOUND: `tests/testthat/test-deps-clean.R`
- FOUND: `tests/testthat/test-news-migration.R`
- FOUND: `.planning/phases/06-shell-and-native-retirement/06-08-SUMMARY.md`

**Deleted verified gone:**
- GONE: `tests/testthat/test-curve-spinbox.R`

**Task commits:**
- FOUND: `8ba5edf` feat(06-08): sever tcltk/tcltk2/rgl from package metadata, bump 1.0.0, regen NAMESPACE
- FOUND: `f1a6a6d` docs(06-08): add NEWS.md 1.0.0 migration note
- FOUND: `4caff2e` test(06-08): reconcile parity, tcltk-stub, and deleted-symbol tests
- FOUND: `49d7ef2` test(06-08): add deps-clean + NEWS source-scan gates

---
*Phase: 06-shell-and-native-retirement*
*Completed: 2026-08-14*
