---
phase: 06-shell-and-native-retirement
plan: 04
subsystem: ui
tags: [tcltk, r-package, s3-generics, native-engine, dgt, source-scan, browser-shell]

# Dependency graph
requires:
  - phase: 06-03
    provides: "GUImorphWeb() relocated to shell.R and rewired to boot the browser shell; entry no longer UseMethod-dispatches ui()/init()"
provides:
  - "3dDigitize.main.r stripped of all Tk chrome (window/notebook/menu/nav/status/shortcuts dialog)"
  - "3dDigitize.main.r free of every native engine-verb call site (add/set/del/shows)"
  - "ui/init/bind/updateWidgets S3 generic definitions removed from main.r"
  - "Preserved data/model + serialization surface: read.vertex.3D, write.vertex.3D, .dgt_* helpers, .dgt_emit_session_blocks, .gmw_save_session_dgt, .mdgt_* + mergeDgt, refreshTabGating (server-owned tab state)"
  - "New source-scan guard test-main-chrome-stripped.R"
affects: [06-05, 06-06, 06-07, 06-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Source-scan guard test (readLines + comment-strip + grepl) asserting demolition invariants on a single owned file"
    - "Tk-dialog side effects converted to return-value-for-browser-modal (.warnUnexpectedExtension returns warning text)"
    - "refreshTabGating computes server-owned e$tabState only (no tcl notebook widget calls, no status-bar side effect)"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-main-chrome-stripped.R
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-curve-tab-gating.R
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-macos-dialog-shortcuts-parity.R

key-decisions:
  - "refreshTabGating kept but reduced to server-owned e$tabState computation; the /tabstate route wiring stays in the shell/transport plans (wave-3 file ownership), so no sibling files were touched"
  - ".warnUnexpectedExtension returns the warning text (browser modal renders it) instead of calling tkmessageBox"
  - "Engine-verb removal was implemented by deleting the whole deprecated Tk workflow functions (jumpToSpecimen, switchTab, showPicture, loadPly, saveToDgt, openDgt, addPly, dev-logging, etc.) since they are unreachable once GUImorphWeb() boots the browser (06-03)"
  - "load_all() acceptance verified via headless parse + targeted testthat source-scan; full pkgload::load_all compiles the native rtkogl engine and cannot complete headlessly (same constraint documented in 06-03)"

patterns-established:
  - "Demolition guard test scoped to this plan's single owned file (main.r), never the sibling *.r files"

requirements-completed: [UI-01, UI-02]

coverage:
  - id: D1
    description: "3dDigitize.main.r builds no Tk window/notebook/menu/nav/status/shortcuts chrome"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-main-chrome-stripped.R#no Tk chrome widgets remain in main.r (T-6-12)"
        status: pass
    human_judgment: false
  - id: D2
    description: "No native engine-verb (add/set/del/shows) call sites remain in main.r"
    requirement: "UI-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-main-chrome-stripped.R#no native engine verbs remain in main.r (T-6-13)"
        status: pass
    human_judgment: false
  - id: D3
    description: "ui/init/bind/updateWidgets S3 generic definitions removed from main.r"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-main-chrome-stripped.R#retired S3 UI generics are gone from main.r"
        status: pass
    human_judgment: false
  - id: D4
    description: "Analytical + serialization symbols preserved (read/write.vertex.3D, .dgt serializers, .gmw_save_session_dgt, mergeDgt, refreshTabGating) — no over-strip"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-main-chrome-stripped.R#analytical + serialization symbols are preserved (no over-strip, T-6-12)"
        status: pass
    human_judgment: false

# Metrics
duration: ~45min
completed: 2026-08-14
status: complete
---

# Phase 6 Plan 04: Strip Tk chrome and native engine verbs from 3dDigitize.main.r Summary

**`3dDigitize.main.r` shrank from ~3,010 to 492 lines — all Tk chrome, every add/set/del/shows engine call, and the ui/init/bind/updateWidgets S3 generics are gone, while the data/model, DGT serializers, browser save path, and merge logic remain byte-for-byte intact and guarded by a new source-scan test.**

## Performance

- **Duration:** ~45 min
- **Completed:** 2026-08-14
- **Tasks:** 3 (Task 3 is TDD: RED → GREEN)
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments
- Deleted the entire Tk control surface from main.r: `ui.main` (toplevel/notebook/tabs/status/progress), `createMenu`, `createNavFrame`, `showShortcutsDialog`, `bind.accelerators`, `onExit`, plus the previously-removed status/nav/theme helpers.
- Removed every native engine-verb call site by deleting the unreachable Tk workflow functions (`jumpToSpecimen`, `switchTab`, `showPicture`, `zoom`, `motion`, `onNext/onPrevious/onFit`, `loadPly`, `saveToDgt`, `getLandmark/getAnchor/convertCoor`, dev-logging fns, `loadPlyTest`, `openDgt`, `addPly`, `mergeDgtFiles`).
- Removed the `ui`/`init`/`bind`/`updateWidgets` S3 generic definitions (TDD RED→GREEN).
- Preserved and re-verified the kept surface: `read.vertex.3D`, `write.vertex.3D`, `.dgt_*` writer helpers, `.dgt_emit_session_blocks`, `.gmw_save_session_dgt`, `.mdgt_*` + `mergeDgt`, and `refreshTabGating` (now server-owned tab state only).
- Added `test-main-chrome-stripped.R` (source-scan guard: no chrome, no verbs, no generics, kept symbols present).

## Task Commits

Each task was committed atomically:

1. **Task 1: Strip Tk chrome and UI helpers** - `2ab84b3` (feat)
2. **Task 2: Remove native engine-verb call sites** - `602bb0e` (feat)
3. **Task 3 (TDD RED): failing source-scan for stripped chrome** - `cd014f2` (test)
4. **Task 3 (TDD GREEN): remove ui/init/bind/updateWidgets generics** - `d53c5e0` (feat)

**Plan metadata:** docs commit skipped (`commit_docs: false`).

## Files Created/Modified
- `R/3dDigitize.main.r` - Stripped to data/model + serialization + merge logic; 0 Tk chrome, 0 engine verbs, 0 S3 UI generics.
- `tests/testthat/test-main-chrome-stripped.R` - New source-scan guard (T-6-12 no over-strip, T-6-13 no lingering verbs).
- `tests/testthat/test-curve-tab-gating.R` - Dropped tcltk stubbing (`with_stub_tcl`) since `refreshTabGating` no longer calls `tcl`.
- `tests/testthat/test-macos-dialog-shortcuts-parity.R` - Retired the `bindPlatformAccelerator` accelerator-map assertion (now asserts its absence) and dropped the removed "Surface Sliders and Curves unlocked." status-string assertion.

## Decisions Made
- **refreshTabGating scope:** kept as a server-side `e$tabState` computation; the `/tabstate` route wiring the plan mentions lives in the shell/transport plans (wave-3 disjoint file ownership), so no sibling `.r` files were edited here.
- **Engine-verb removal by whole-function deletion:** the functions holding `add/set/del/shows` are the deprecated Tk workflow, unreachable once `GUImorphWeb()` boots the browser (06-03), so they were removed wholesale rather than partially rewired.
- **load_all verification:** used headless `parse()` + a targeted `testthat::test_file()` run; full `pkgload::load_all()` compiles the native rtkogl C engine and stalls headlessly (documented in 06-03). Parse + source-scan is the equivalent gate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repointed collateral source-scan tests broken by the strip**
- **Found during:** Task 1 and Task 3
- **Issue:** `test-macos-dialog-shortcuts-parity.R` asserted the existence of `bindPlatformAccelerator(...)` calls and the "Surface Sliders and Curves unlocked." status string — both removed by this plan. `test-curve-tab-gating.R` stubbed `tcltk::tcl` (via `assignInNamespace`) for a `refreshTabGating` that no longer calls `tcl` (a pre-existing R 4.6 failure source).
- **Fix:** Retired/inverted the accelerator assertion to assert absence, dropped the removed status-string assertion, and removed the now-unnecessary tcltk stubbing so the gating tests exercise the pure server-side computation.
- **Files modified:** `tests/testthat/test-macos-dialog-shortcuts-parity.R`, `tests/testthat/test-curve-tab-gating.R`
- **Verification:** both files pass (`macos-dialog-shortcuts-parity`: 8 assertions; `curve-tab-gating`: 3 assertions).
- **Committed in:** `2ab84b3` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** Test repointing was required to keep the suite green after the demolition; no scope creep, sibling `.r` files untouched.

## TDD Gate Compliance
- **RED:** `cd014f2` — `test-main-chrome-stripped.R` failed only on the S3-generic assertions (generics still present); chrome/verb/preservation assertions already green after Tasks 1–2.
- **GREEN:** `d53c5e0` — removed the four generics; all 16 assertions pass.
- No REFACTOR commit needed.

## Issues Encountered
- Full `pkgload::load_all()` cannot complete headlessly (native rtkogl compilation). Resolved by using `Rscript` `parse()` + targeted `testthat::test_file()` runs, consistent with 06-03's verification approach. Full `devtools::test()` runs after the wave-3 strip plans merge (per plan verification note).

## Next Phase Readiness
- main.r is now analytical/serialization-only; safe for wave-3 siblings (06-05/06-06) to remove their own `*.main`/tab S3 methods and for 06-07/06-08 to retire `rtkogl.R` and regenerate `NAMESPACE`.
- No blockers.

## Self-Check: PASSED

- Files present: `06-04-SUMMARY.md`, `test-main-chrome-stripped.R`, `3dDigitize.main.r`
- Commits present: `2ab84b3`, `602bb0e`, `cd014f2`, `d53c5e0`

---
*Phase: 06-shell-and-native-retirement*
*Completed: 2026-08-14*
