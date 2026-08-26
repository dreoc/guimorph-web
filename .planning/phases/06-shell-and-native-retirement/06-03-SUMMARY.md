---
phase: 06-shell-and-native-retirement
plan: 03
subsystem: infra
tags: [entry-point, shell, rtkogl, decapitation-safe, engine-absent, httpuv, R]

# Dependency graph
requires:
  - phase: 06-shell-and-native-retirement
    provides: "Plan 01 .gmw_serve_mesh(dir=) browse_dir seed + shell routes; Plan 02 browser shell chrome"
  - phase: 02-local-transport-and-mesh-display
    provides: ".gmw_serve_mesh loopback httpuv listener (print-first, try-open URL)"
provides:
  - "R/shell.R: the engine-free package shell holding the rewired GUImorphWeb() entry + dbg/.plot_show/.onAttach/.isMacOS + wheel/shortcut helpers"
  - "GUImorphWeb(dir=getwd(), open=TRUE, debug=FALSE) booting the browser shell via .gmw_serve_mesh() with NO .gmw_require_engine()/ui(e)/init(e) (UI-02)"
  - "Trimmed rtkogl.R that is now pure native-engine surface (add/del/set/shows/.gmw_engine/.onLoad/loadDgt), safe for Plan 07 to delete wholesale"
  - "tests/testthat/test-shell-entry.R: the engine-absent boot + workflow-reachability gate"
affects: [06-04-native-retirement, 06-07-rtkogl-deletion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Decapitation-safe relocation: move the non-engine survivors (entry point + package-level dbg + plot/attach hooks + helpers) into a surviving file and prove load+boot BEFORE deleting the engine file (RESEARCH Landmine 1)"
    - "Placeholder-mesh boot: GUImorphWeb() writes a tiny in-process tetrahedron PLY so .gmw_serve_mesh() (which requires a mesh) can mount an empty viewport the file picker then populates"
    - "Isolated test sourcing: source package R/ files into the test file's own env (local=env), not the global env, so real-listener suites do not clobber sibling suites' server registries"

key-files:
  created:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/shell.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-shell-entry.R"
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-macos-input-core.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-macos-dialog-shortcuts-parity.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-rgl-fallback-macos.R"

key-decisions:
  - "GUImorphWeb signature resolved to (dir=getwd(), open=TRUE, debug=FALSE) per RESEARCH Open Q1 / D-03; body seeds the server-owned browse dir and boots .gmw_serve_mesh(dir=, open=)"
  - "The entry seeds a tiny in-process placeholder PLY (a unit tetrahedron via .gmw_boot_specimen()) because .gmw_serve_mesh() requires an existing mesh to mount, and transport.R is out of this plan's scope; the browser file picker opens real specimens from `dir`"
  - "dbg/.pkg_version/.module_banner/.isMacOS/normalizeWheelDelta/shortcutLabel/.plot_show/.onAttach relocated verbatim to shell.R; the Tk-only bindPlatformAccelerator/bindDeleteGesture were DROPPED (no browser analog)"
  - ".onAttach banner text updated from \"(beta) - Windows and macOS\" to the 1.0.0 browser-based architecture"
  - "The engine surface (add/del/set/shows/.gmw_engine/.gmw_require_engine/.onLoad/loadDgt) stays in rtkogl.R untouched — Plan 07 deletes it after this engine-absent gate lands"

patterns-established:
  - "Survivor relocation before file deletion: prove devtools/source load + GUImorphWeb boot with the engine file present-but-unused, so the later deletion is a no-behavior-change removal"
  - "Engine-absent gate via unsourced engine: test-shell-entry.R never sources rtkogl.R, so a green boot + full route drive proves the workflow needs no native engine"

requirements-completed: [UI-02]

coverage:
  - id: D1
    description: "GUImorphWeb(dir=<tempdir>, open=FALSE) boots the browser shell, returns a loopback 127.0.0.1 URL invisibly, and binds a live listener with the native engine absent (UI-02)"
    requirement: "UI-02"
    verification:
      - kind: integration
        ref: "tests/testthat/test-shell-entry.R#GUImorphWeb() boots a loopback browser shell with no native engine"
        status: pass
    human_judgment: false
  - id: D2
    description: "The relocated survivors (GUImorphWeb/dbg/.plot_show/.onAttach) live in R/shell.R with exactly one definition each; the GUImorphWeb body contains no .gmw_require_engine/ui(e)/init(e), and rtkogl.R no longer defines them"
    requirement: "UI-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-shell-entry.R#R/shell.R holds the relocated survivors and the entry is engine/Tk-free"
        status: pass
    human_judgment: false
  - id: D3
    description: "The digitize->gpa->save workflow (specimen/pick/anchor/curve/overlays/downsample/gpa/export/save/status/tabstate/files) is reachable end-to-end through the production route handler with the engine surface undefined in-session"
    requirement: "UI-02"
    verification:
      - kind: integration
        ref: "tests/testthat/test-shell-entry.R#digitize->gpa->save workflow is reachable through the shell handler, engine absent"
        status: pass
    human_judgment: false

# Metrics
duration: 35min
completed: 2026-08-14
status: complete
---

# Phase 6 Plan 03: Shell Entry + Native Survivors Relocation Summary

**The non-engine survivors (`GUImorphWeb()`, `dbg()`, `.plot_show()`, `.onAttach()`, and the platform/wheel/shortcut helpers) were relocated out of `rtkogl.R` into a new `R/shell.R`, and `GUImorphWeb()` was rewired to boot the browser shell via `.gmw_serve_mesh()` with no native engine or Tk window — the decapitation-safe precondition (RESEARCH Landmine 1 / UI-02) for deleting `rtkogl.R` in Plan 07.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-08-14
- **Tasks:** 3 (+ collateral test updates)
- **Files modified:** 6 (2 created, 4 modified)

## Accomplishments
- Created `R/shell.R` holding the verbatim-moved `dbg`, `.pkg_version`, `.module_banner`, `.isMacOS`, `normalizeWheelDelta`, `shortcutLabel`, `.plot_show`, and `.onAttach` (banner updated for the 1.0.0 browser architecture), so `transport.R`'s package-level `dbg` dependency and the result-plot/attach hooks survive the Plan-07 deletion of `rtkogl.R`.
- Rewired and moved `GUImorphWeb()` to `shell.R` with the D-03/Open-Q1 signature `GUImorphWeb(dir = getwd(), open = TRUE, debug = FALSE)`; the body sets `guimorph.debug`, seeds the server-owned browse dir, and boots the browser shell via `.gmw_serve_mesh(dir=, open=)` — with `.gmw_require_engine()`, `ui(e)`, and `init(e)` gone (UI-02). The `@export` roxygen is retained.
- Dropped the Tk-only `bindPlatformAccelerator`/`bindDeleteGesture` helpers (no browser analog) and left the entire native engine surface (`add`/`del`/`set`/`shows`/`.gmw_engine`/`.gmw_require_engine`/`.onLoad`/`loadDgt`) in `rtkogl.R` for Plan 07.
- Added `tests/testthat/test-shell-entry.R`: a real UI-02 gate that boots the shell without ever sourcing `rtkogl.R`, asserts the URL/listener, source-scans the relocated entry, and drives the full digitize→gpa→save route chain through the production handler — all green with the engine surface undefined in-session.
- Verified the browser-shell suites stay green and repointed the three source-scan tests that had asserted the survivors lived in `rtkogl.R`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Relocate non-engine survivors rtkogl.R → shell.R** - `3b71e04` (feat)
2. **Task 2: Rewire GUImorphWeb() to boot the browser shell** - `4f9b04a` (feat)
3. **Task 3: Add engine-absent boot + workflow-reachability test** - `d02f0ca` (test)
4. **Task 3 follow-up: isolate test-shell-entry.R sourcing** - `ff22472` (test)
5. **Collateral: repoint macOS source-scan tests to shell.R** - `e93d1c3` (test)

**Plan metadata:** skipped (`commit_docs: false` in `.planning/config.json` — `.planning/` docs are intentionally kept out of git history)

_Note: Task 3 is `tdd="true"`, but the plan orders implementation (Tasks 1–2) before the test (Task 3), so a RED-against-absent-code commit was not possible (same ordering as Plans 06-01/06-02). The test is a real gate rather than a tautology: it boots without sourcing `rtkogl.R`, so it would fail if the entry still called `ui(e)`/`init(e)` (undefined) or `.gmw_require_engine()`. See TDD Gate Compliance below._

## Files Created/Modified
- `R/shell.R` (new) — the engine-free shell: rewired `GUImorphWeb()` + `.gmw_boot_specimen()` placeholder-mesh helper + the relocated survivors and helpers.
- `R/rtkogl.R` — removed the survivors (140 lines) and the old Tk-path `GUImorphWeb()`; left a pointer comment and the untouched native engine surface.
- `tests/testthat/test-shell-entry.R` (new) — boot / source-scan / workflow-reachability gate.
- `tests/testthat/test-macos-input-core.R` — source `shell.R` for `normalizeWheelDelta`/`.isMacOS`; retire the deleted-`bindDeleteGesture` assertion.
- `tests/testthat/test-macos-dialog-shortcuts-parity.R` — assert `shortcutLabel` + Cmd branch in `shell.R`; retire the deleted-`bindPlatformAccelerator` assertion.
- `tests/testthat/test-rgl-fallback-macos.R` — read `.plot_show`/`.isMacOS` from `shell.R`; retire the entry's former `.gmw_require_engine()` gate assertion (UI-02).

## Decisions Made
- **Signature `GUImorphWeb(dir = getwd(), open = TRUE, debug = FALSE)`** (RESEARCH Open Q1 / D-03), booting `.gmw_serve_mesh(dir=, open=)`; the browse dir is seeded server-side for the in-page file picker.
- **Placeholder-mesh boot.** `.gmw_serve_mesh()` requires an existing PLY to mount, and `transport.R` is out of this plan's `files_modified`. Rather than change the transport signature, `GUImorphWeb()` writes a tiny in-process unit-tetrahedron PLY (`.gmw_boot_specimen()`) and mounts it as the empty starting viewport — the user then opens real specimens through the D-03 picker (mirrors how the retired Tk entry started empty and used "Load PLY"). Every path stays R-owned; no bundled sample data and no engine.
- **Drop the Tk-only gesture/accelerator binders.** `bindPlatformAccelerator`/`bindDeleteGesture` are pure `tkbind` wrappers with no browser analog, so they were deleted here rather than relocated (their dead call sites in `3dDigitize.{main,digitize}.r` are removed with the Tk builders in Plan 04).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `.gmw_serve_mesh()` requires a mesh; entry needs a placeholder PLY**
- **Found during:** Task 2 (rewire GUImorphWeb)
- **Issue:** The plan says boot via `.gmw_serve_mesh(dir=, open=)`, but that function's first argument `ply_path` is mandatory and it `stop()`s if the file does not exist. The shell must boot into an empty viewport (Task 2 acceptance boots with `dir = tempdir()`, which contains no PLY), so a mesh must be supplied. `transport.R` is not in this plan's `files_modified`, so making `ply_path` optional there is out of scope.
- **Fix:** Added `.gmw_boot_specimen()` in `shell.R` writing a minimal valid ASCII PLY (unit tetrahedron) to a tempfile; `GUImorphWeb()` passes it as `ply_path`. Preserves the `dir=`/`open=` key link and keeps every path R-owned.
- **Files modified:** `R/shell.R`
- **Verification:** `GUImorphWeb(dir=<tempdir>, open=FALSE)` returns a loopback URL and binds a live 127.0.0.1 listener (test-shell-entry.R boot test, pass).
- **Committed in:** `4f9b04a` (Task 2 commit)

**2. [Rule 1 - Bug] Relocation inverted three existing source-scan tests**
- **Found during:** Task 1/2 (survivor relocation + Tk-helper deletion)
- **Issue:** `test-macos-input-core.R`, `test-macos-dialog-shortcuts-parity.R`, and `test-rgl-fallback-macos.R` asserted that `normalizeWheelDelta`/`.isMacOS`/`shortcutLabel`/`.plot_show` and the deleted `bindPlatformAccelerator`/`bindDeleteGesture` bodies live in `rtkogl.R`, and that `GUImorphWeb()` calls `.gmw_require_engine()`. All of those inverted after the relocation/deletion, breaking the suite (the plan's verification requires the full suite to still run).
- **Fix:** Repointed the assertions to `shell.R` for the relocated symbols; retired the assertions for the two deleted Tk-only helpers and for the entry's former engine gate (UI-02 made the entry engine-independent).
- **Files modified:** `test-macos-input-core.R`, `test-macos-dialog-shortcuts-parity.R`, `test-rgl-fallback-macos.R`
- **Verification:** All three files green (`macos-input-core`, `macos-dialog-shortcuts-parity`, `rgl-fallback-macos` filters).
- **Committed in:** `e93d1c3`

**3. [Rule 1 - Bug] test-shell-entry.R clobbered sibling suites' global state**
- **Found during:** Task 3 (suite-wide run)
- **Issue:** Sourcing the package files with `local = FALSE` rebuilt the global-env `.gmw_server`/`.gmw_session` registries, causing a token-not-found failure in `test-transport.R` when both ran in the same session.
- **Fix:** Source `view3d.R`/`shell.R`/`transport.R` into the test file's own environment (`local = <file env>`), isolating the new suite's server registries.
- **Files modified:** `test-shell-entry.R`
- **Verification:** `shell-entry` + `transport` + `transport-render` all green together.
- **Committed in:** `ff22472`

---

**Total deviations:** 3 auto-fixed (1 blocking, 2 bug). **Impact:** All necessary for correctness and to satisfy the plan's "full suite still runs" verification. The placeholder-mesh boot is the only functional deviation and is confined to `shell.R`; no `transport.R` change and no scope creep.

## Issues Encountered
- **`devtools` not installed** — the plan's `devtools::load_all()` / `devtools::test(filter=...)` verifies were run as `testthat::test_dir("tests/testthat", filter=...)` (sources the `helper-*.R` identically) and source-based symbol checks, which is the same substitution Plans 06-01/06-02 used. Bare R hangs under the workspace `renv` activate (known STATE open item), so all runs used `Rscript --no-init-file`; the GUI-heavy `geomorph`/`tcltk2` packages block headless, so the parity suites were not run here.
- **Real-HTTP route drive infeasible in-process** — httpuv's R `call` handler cannot be serviced while the same R thread blocks on `curl_fetch_memory`, so the workflow-reachability test drives the production handler directly with synthetic reqs (the exact pattern `test-transport.R` uses). The live listener is still exercised by the boot test.

## Pre-existing Failures (not introduced here, out of scope)
- `test-curve-tab-gating.R` (4): `assignInNamespace("tcl", …, "tcltk")` locked-binding errors — R 4.6 forbids the tcltk stub (STATE "4 stub tcltk").
- `test-curve-io.R` (1) and `test-curve-spinbox.R` (2): source only `3dDigitize.curve.r`, whose `read.curve` calls `dbg` and whose spinbox helpers were deleted upstream (STATE "2 tests call functions Austin deleted"). These never sourced `rtkogl.R`/`shell.R`, so the relocation cannot have affected them; confirmed the 06-03 diff touches only `rtkogl.R`, `shell.R`, and the four listed test files.

## TDD Gate Compliance
Task 3 carries `tdd="true"`, but the plan sequences the entry rewrite (Tasks 1–2) ahead of the test (Task 3), so a genuine RED (failing-against-absent-code) commit was not possible — identical to Plans 06-01/06-02. The test is a real engine-absent gate rather than a tautology: it never sources `rtkogl.R`, so the boot would error (and the workflow drive would fail) if the entry still took the Tk/engine path. Commit types are `feat` (Tasks 1–2) and `test` (Task 3 + follow-ups).

## Next Phase Readiness
- **Plan 07 unblocked:** `rtkogl.R` is now pure native-engine surface. `GUImorphWeb()`/`dbg`/`.plot_show`/`.onAttach` and helpers live in `shell.R`; the engine-absent boot + full-workflow gate is green, so deleting `rtkogl.R` + `inst/libs/*` becomes a no-behavior-change removal.
- **Plan 04 (Tk strip):** the dead call sites of the deleted `bindPlatformAccelerator`/`bindDeleteGesture` (in `3dDigitize.{main,digitize}.r`) are removed with the Tk builders; the three repointed macOS source-scan tests will need a further pass when those files change.
- **Deferred by design:** the boot mounts a placeholder tetrahedron; a real first-specimen experience is driven by the browser file picker (Plan 01/02). Live-browser UAT of the shell remains the phase-end manual gate.

---

## Self-Check: PASSED

**Created files:**
- FOUND: `R/shell.R`
- FOUND: `tests/testthat/test-shell-entry.R`
- FOUND: `.planning/phases/06-shell-and-native-retirement/06-03-SUMMARY.md`

**Task commits:**
- FOUND: `3b71e04` feat(06-03): relocate non-engine survivors from rtkogl.R to R/shell.R
- FOUND: `4f9b04a` feat(06-03): rewire GUImorphWeb() to boot the browser shell (drop engine + Tk)
- FOUND: `d02f0ca` test(06-03): add engine-absent boot + workflow-reachability gate
- FOUND: `e93d1c3` test(06-03): repoint macOS source-scan tests to shell.R
- FOUND: `ff22472` test(06-03): isolate test-shell-entry.R sourcing into its own env

---
*Phase: 06-shell-and-native-retirement*
*Completed: 2026-08-14*
