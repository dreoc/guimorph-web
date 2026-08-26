---
phase: 06-shell-and-native-retirement
plan: 07
subsystem: infra
tags: [native-retirement, rtkogl, tkogl2, engine-deletion, source-scan, engine-absent, R]

# Dependency graph
requires:
  - phase: 06-shell-and-native-retirement
    provides: "Plan 03 relocated the non-engine survivors (GUImorphWeb/dbg/.plot_show/.onAttach) to R/shell.R; Plans 04-06 removed every add/set/del/shows engine-verb call site"
provides:
  - "R/rtkogl.R deleted: the native tkogl2 engine binding surface (.gmw_engine/.gmw_require_engine/.onLoad tcl-load, add/set/del/shows, get_rtkogl_date, loadDgt) is gone"
  - "Shipped native binaries deleted: inst/libs/tkogl2.dylib, inst/libs/x64/tkogl2.dll, inst/libs/x64/glut64.dll (inst/libs removed)"
  - "The entire sibling integrated-guimorph-development_EOC/Project/tkogl2/ build tree deleted (CMake/MSVC, C/ObjC backends, bundled Tcl/Tk headers, CMP-01 test/gate machinery)"
  - "test-transport.R :121-133 inverted from engine-PRESENCE to engine-ABSENCE in the same change as the deletion"
  - "tests/testthat/test-engine-absent.R: R/-wide engine-verb + engine-env source-scan plus an engine-absent digitize->gpa->save workflow drive (UI-02)"
affects: [06-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Decapitation-safe deletion: survivors relocated (Plan 03) + call sites removed (Plans 04-06) FIRST, so deleting the engine file/binaries/tree is a no-behavior-change removal proven by an engine-absent boot"
    - "Presence->absence test inversion in the SAME plan as the deletion so the suite is never left red (Pitfall 6 / T-6-22)"
    - "R/-wide comment-stripped source-scan with pattern-built forbidden tokens so the negative gate cannot self-trip on its own prose"

key-files:
  created:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-engine-absent.R"
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-export-parity.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-dgt-determinism.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-dgt-cross-platform.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-rgl-fallback-macos.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-shell-entry.R"

key-decisions:
  - "Verified rtkogl.R was pure engine surface (survivors already in shell.R, no engine-verb callers left) before deleting; only get_rtkogl_date/add/del/set/shows/loadDgt/.gmw_engine/.gmw_require_engine/.onLoad remained"
  - "NAMESPACE export(loadDgt) + tcltk/tcltk2 imports left untouched: NAMESPACE regen is deliberately Plan 08 scope (a dangling export is a load_all warning, not an error, and the source-based test suite never exercises namespace loading)"
  - "Six collateral test files that hard-referenced rtkogl.R (source()/readLines()) were reconciled in this plan (Rule 1) so the deletion leaves the suite green"

patterns-established:
  - "Engine-retirement gate: a comment-stripped R/-wide scan proves no add/set/del/shows call and no .gmw_engine/.gmw_require_engine/.onLoad definition survives anywhere, paired with an engine-absent workflow drive"

requirements-completed: [UI-02]

coverage:
  - id: D1
    description: "R/rtkogl.R, the inst/libs engine binaries, and the sibling tkogl2/ build tree are physically deleted; the remaining R/ tree parses cleanly with the engine absent"
    requirement: "UI-02"
    verification:
      - kind: automated
        ref: "Rscript --no-init-file -e 'for (f in list.files(\"R\",\"[.][Rr]$\",full.names=TRUE)) parse(f)' -> PARSE_OK, rtkogl.R present: FALSE"
        status: pass
      - kind: unit
        ref: "tests/testthat/test-engine-absent.R#no engine env / gate definition survives anywhere in R/ (UI-02)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The digitize->gpa->save workflow boots and runs with the native engine (rtkogl.R + inst/libs binaries) absent from the session (UI-02)"
    requirement: "UI-02"
    verification:
      - kind: integration
        ref: "tests/testthat/test-engine-absent.R#digitize -> gpa -> save workflow runs with inst/libs absent (UI-02)"
        status: pass
      - kind: integration
        ref: "tests/testthat/test-shell-entry.R#digitize->gpa->save workflow is reachable through the shell handler, engine absent"
        status: pass
    human_judgment: false
  - id: D3
    description: "test-transport.R :121-133 asserts engine ABSENCE (file gone, no inst/libs binary, no engine load path in R/) and stays green through the deletion"
    requirement: "UI-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-transport.R#the native engine is retired and the shell never revives it"
        status: pass
    human_judgment: false

# Metrics
duration: 7min
completed: 2026-08-14
status: complete
---

# Phase 6 Plan 07: Native Engine Retirement (rtkogl.R + binaries + tkogl2 tree) Summary

**The native tkogl2 engine was physically removed — `R/rtkogl.R`, the shipped `inst/libs` binaries (`tkogl2.dylib`/`tkogl2.dll`/`glut64.dll`), and the entire sibling `tkogl2/` build tree are deleted; the package parses and the digitize→GPA→save workflow boots and runs with the engine genuinely absent (UI-02), and the transport suite's engine-presence block was inverted to assert absence in the same change so the suite never went red.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-08-14T15:31:25Z
- **Completed:** 2026-08-14T15:38:27Z
- **Tasks:** 3 (+ collateral test reconciliation)
- **Files modified:** 7 (1 created, 6 modified) + 355 deletions (rtkogl.R, 3 binaries, tkogl2/ tree)

## Accomplishments
- Verified `rtkogl.R` was pure native-engine surface (survivors relocated in Plan 03, every `add`/`set`/`del`/`shows` call site removed in Plans 04–06), then deleted it along with the `inst/libs` engine binaries and the whole `integrated-guimorph-development_EOC/Project/tkogl2/` CMake/MSVC/C/ObjC build tree (355 files removed via `git rm`).
- Confirmed the package still loads engine-absent: all remaining `R/` files parse, and the browser-shell boot + full digitize→gpa→save route drive run with `.gmw_engine`/`.gmw_require_engine` genuinely undefined in-session (UI-02).
- Inverted `test-transport.R` :121–133 from asserting `rtkogl.R` still carried `.onLoad`/`Tkogl2` to asserting the engine file, its binaries, and its load path are all gone — in the same change as the deletion (Pitfall 6 / T-6-22).
- Added `test-engine-absent.R`: an R/-wide comment-stripped source-scan (no `add`/`set`/`del`/`shows` call, no `.gmw_engine`/`.gmw_require_engine`/`.onLoad` definition) plus an engine-absent workflow drive.
- Reconciled the collateral test files that hard-referenced the now-deleted `rtkogl.R` so the deletion leaves the suite green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Delete rtkogl.R, engine binaries, tkogl2/ tree** - `891eb74` (feat)
2. **Deviation: reconcile collateral tests broken by the deletion** - `9c520a0` (test)
3. **Task 2: Invert test-transport.R :121–133 to assert engine absence** - `eb093d6` (test)
4. **Task 3: Add test-engine-absent.R (R/-wide scan + engine-absent workflow)** - `6ec3bf7` (test)
5. **Deviation follow-up: drop test-shell-entry.R readLines(rtkogl.R)** - `e1e9f47` (test)

**Plan metadata:** docs commit skipped (`commit_docs: false` in `.planning/config.json` — `.planning/` docs are intentionally kept out of git history).

_Note: Tasks 2 and 3 carry `tdd="true"`, but the plan orders the deletion (Task 1) before the tests, so a genuine RED-against-present-code commit was not possible (same ordering as Plans 06-01/03/06). Both tests are real gates rather than tautologies: the transport block asserts `!file.exists(rtkogl.R)` (would fail if the file still existed), and the engine-absent scan uses the proven add/set/del/shows regex that catches a reintroduced engine call. See TDD Gate Compliance below._

## Files Created/Modified
- **Deleted** `R/rtkogl.R` — the native tkogl2 engine binding surface.
- **Deleted** `inst/libs/tkogl2.dylib`, `inst/libs/x64/tkogl2.dll`, `inst/libs/x64/glut64.dll` (now-empty `inst/libs` removed).
- **Deleted** the entire `integrated-guimorph-development_EOC/Project/tkogl2/` tree (CMakeLists/cmake, `.sln`/`.vcxproj`, `src/`, `include/` bundled Tcl/Tk, `test/gate/` CMP-01 machinery, stale sibling `R/` copies, `BUILD.md`/`docs`/`lib`/`deltas.txt`).
- `tests/testthat/test-engine-absent.R` (new) — R/-wide engine source-scan + engine-absent workflow drive.
- `tests/testthat/test-transport.R` — :121–133 inverted to engine absence.
- `tests/testthat/test-export-parity.R`, `test-dgt-determinism.R`, `test-dgt-cross-platform.R` — `source(rtkogl.R)` → `source(shell.R)` (they only needed `dbg()`, relocated to shell.R in Plan 03).
- `tests/testthat/test-rgl-fallback-macos.R` — inverted the "failed engine load is non-fatal" test (which read `rtkogl.R`) to assert engine absence.
- `tests/testthat/test-shell-entry.R` — replaced the `readLines(rtkogl.R)` survivor-non-duplication check with `expect_false(file.exists(rtkogl.R))`.

## Decisions Made
- **NAMESPACE left untouched.** `export(loadDgt)` (now dangling) plus the `tcltk`/`tcltk2` imports stay until Plan 08's roxygen regen — the plan explicitly scopes NAMESPACE to 06-08. A dangling export is a `load_all()` warning, not an error, and the source-based test suite never loads the namespace, so nothing goes red.
- **`git rm` for the binaries and tree, file-delete tool for `rtkogl.R`.** Deletions are tracked (355 staged `D` entries, no stray additions).
- **Collateral test reconciliation belongs in this plan.** Six test files hard-referenced `rtkogl.R`; leaving them would crash the suite the moment the file was deleted, violating the "never leave the suite red" invariant (T-6-22). They were repointed/inverted as Rule 1 deviations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Six collateral test files hard-referenced the deleted `rtkogl.R`**
- **Found during:** Task 1 (deletion) — grep of `tests/` for `rtkogl.R`/`tkogl2` references.
- **Issue:** `test-export-parity.R`, `test-dgt-determinism.R`, `test-dgt-cross-platform.R` `source(rtkogl.R)` (only for the `dbg()` that Plan 03 moved to `shell.R`); `test-rgl-fallback-macos.R` and `test-shell-entry.R` `readLines(rtkogl.R)`. All become hard errors ("cannot open file") the moment `rtkogl.R` is deleted, breaking the suite (T-6-22).
- **Fix:** Repointed the three `source(rtkogl.R)` → `source(shell.R)`; inverted the `test-rgl-fallback-macos.R` engine-load test to assert engine absence (no `rtkogl.R`, no `inst/libs` binary, no `.onLoad`/`.gmw_engine`/`.gmw_require_engine` in `R/`); replaced the `test-shell-entry.R` survivor-non-duplication `readLines` with `expect_false(file.exists(rtkogl.R))`.
- **Files modified:** `test-export-parity.R`, `test-dgt-determinism.R`, `test-dgt-cross-platform.R`, `test-rgl-fallback-macos.R`, `test-shell-entry.R`.
- **Verification:** filters `export-parity`, `dgt-determinism`, `dgt-cross-platform`, `rgl-fallback-macos`, `shell-entry` all green (only pre-existing CMP-01/DAT-03 skips).
- **Committed in:** `9c520a0` (four files) and `e1e9f47` (`test-shell-entry.R`).

---

**Total deviations:** 1 auto-fixed (Rule 1 bug, spanning six test files). **Impact:** Necessary to honor the plan's "the suite never goes red through the deletion" invariant; test-only reconciliation directly caused by Task 1, no production scope creep.

## Issues Encountered
- **`devtools` not installed** — the plan's `devtools::load_all()` / `devtools::test(filter=…)` verifies were run as `Rscript --no-init-file -e 'parse(...)'` load/parse smoke plus `testthat::test_dir("tests/testthat", filter=…)` (sources the `helper-*.R` identically), the same substitution Plans 06-01/03/04/05/06 used. Bare R hangs under the workspace `renv` activate (known STATE open item), so all runs used `--no-init-file`.
- **Full-suite run avoided** — the GUI-heavy `tcltk`/`geomorph` parity suites block headless (documented across the phase). All deletion-affected suites were run individually and are green.

## Pre-existing Failures (not introduced here, out of scope)
- **`test-macos-dialog-shortcuts-parity.R:58`** asserts `3dDigitize.surface.r` still contains a `zoom(e, normalizeWheelDelta(D))` wheel binding. Plan 06-06 stripped that Tk handler from `surface.r`; this parity assertion (last touched in 06-04) was not repointed then, so it has been red since the 06-06 surface strip. Plan 06-07 does not touch `surface.r` or this test, so it is out of scope. Logged in `.planning/phases/06-shell-and-native-retirement/deferred-items.md` for Plan 08 (or a 06-06 follow-up) to repoint.
- STATE's long-standing reds (`test-curve-tab-gating` ×4 tcltk locked-binding; `test-curve-io`/`test-curve-spinbox` calling deleted functions) are unchanged by this plan and never sourced `rtkogl.R`/`shell.R`.

## TDD Gate Compliance
Tasks 2 and 3 carry `tdd="true"`, but the plan sequences the deletion (Task 1) ahead of the tests, so a genuine RED (failing-against-present-code) commit was not possible — identical ordering to Plans 06-01/03/06. Both tests are real gates: the transport block asserts `!file.exists(rtkogl.R)` (would fail if the file still existed), and `test-engine-absent.R` uses the proven `add|set|del|shows\(` regex that already catches engine calls elsewhere in the phase. Commit types are `feat` (Task 1) and `test` (Tasks 2–3 + deviations).

## Next Phase Readiness
- **Plan 08 unblocked:** the engine is physically gone, so 06-08 can now sever `tcltk`/`tcltk2`/`rgl` from `DESCRIPTION`, drop `export(loadDgt)` and the tcltk imports from `NAMESPACE` (roxygen regen), bump to 1.0.0, ship the `NEWS.md` migration note, and reconcile the remaining CMP-01/parity/tcltk-stub tests + PICK-03/DAT-02 won't-verify closures (UI-03, D-04).
- **Deferred:** the `test-macos-dialog-shortcuts-parity.R:58` stale surface wheel/zoom assertion (see Pre-existing Failures) should be repointed in Plan 08.

## Self-Check: PASSED

**Created files:**
- FOUND: `tests/testthat/test-engine-absent.R`
- FOUND: `.planning/phases/06-shell-and-native-retirement/06-07-SUMMARY.md`
- FOUND: `.planning/phases/06-shell-and-native-retirement/deferred-items.md`

**Deletions verified gone:**
- GONE: `R/rtkogl.R`
- GONE: `inst/libs/` (engine binaries)
- GONE: `integrated-guimorph-development_EOC/Project/tkogl2/`

**Task commits:**
- FOUND: `891eb74` feat(06-07): remove native tkogl2 engine (rtkogl.R, binaries, build tree)
- FOUND: `9c520a0` test(06-07): reconcile collateral tests broken by rtkogl.R deletion
- FOUND: `eb093d6` test(06-07): invert test-transport.R engine block to assert absence
- FOUND: `6ec3bf7` test(06-07): add test-engine-absent.R (R/-wide scan + engine-absent workflow)
- FOUND: `e1e9f47` test(06-07): drop test-shell-entry.R readLines(rtkogl.R) after deletion

---
*Phase: 06-shell-and-native-retirement*
*Completed: 2026-08-14*
