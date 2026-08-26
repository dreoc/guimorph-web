---
phase: 06-shell-and-native-retirement
plan: 06
subsystem: ui
tags: [tk-removal, geomorph, gpa, surface, transport, httpuv, save-path, R]

# Dependency graph
requires:
  - phase: 06-shell-and-native-retirement
    provides: "Plan 01 /gpa /export /savepath /msgack shell routes + .gmw_session store; Plan 03 R/shell.R engine-free entry + .module_banner/dbg survivors"
  - phase: 05-full-digitizing-and-data-parity
    provides: ".gmw_session_to_geomorph_env + .gmw_gpa_session/.gmw_export_session seams; .build_geomorph_data/compute forwarding; .gmw_downsample_session TPS warp"
provides:
  - "3dDigitize.surface.r stripped to the headless .gmw_downsample_session TPS warp + template/.dgt serializers (no ui.surface, no toplevel, no tkmessageBox, no add/set engine verbs)"
  - "3dDigitize.geomorph.r stripped of ui.geomorph tk2* widgets, tkmessageBox dialogs, and tkgetSaveFile pickers; GPA/PCA/export compute logic intact"
  - "transport.R /gpa route accepts a strict fixed-order boolean GPA-options CSV via .gmw_parse_gpaopts() -> .gmw_gpa_session(token, opts) (T-6-17)"
  - "CSV/RDS export save-name flows from the browser field over /savepath (session save_name + R-owned browse dir); /save carries no browser path (T-6-18)"
  - "tests/testthat/test-surface-geomorph-stripped.R source-scan guard"
affects: [06-07-rtkogl-deletion, 06-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GPA options over a route: browser posts a bare fixed-order CSV; .gmw_parse_gpaopts() coerces to a strict, bounded 0/1 option set fed to the existing gpagen option tclVars via .gmw_session_to_geomorph_env() -- compute()/.build_geomorph_data forwarding byte-unchanged"
    - "Save-name via /savepath: exporters read e$save_name + e$save_dir (session browse dir) instead of tkgetSaveFile; R owns the directory, browser owns only a sanitized basename"
    - "tkmessageBox -> message(): non-Tk console/log surface that keeps every early-exit return() path intact so browser-side modals can render the text"

key-files:
  created:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-surface-geomorph-stripped.R"
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.surface.r"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-digitizing-parity-macos.R"

key-decisions:
  - "Extended the EXISTING /gpa route rather than adding /gpaopts (RESEARCH Open Q2): one route carries both the trigger and the option flags; an empty/malformed body -> list() so native defaults hold and the shell-entry workflow drive stays unregressed"
  - "GPA-options wire format is a fixed-order 11-field CSV (maxiter + 10 strict 0/1 booleans); base-R parse, no eval, no path -- the only sink is the existing gpagen option tclVars (T-6-17)"
  - "Deleted the now-dead Tk buildTemplate/buildTemplate1/downSample handlers wholesale rather than partially stripping them; the headless .gmw_downsample_session (05-04) already reproduces their TPS warp + as.vector(t(.)) flatten"
  - "save()/exportGeomorph() read e$save_name (from /savepath) joined to R-owned e$save_dir via basename() only; empty save-name is the former Cancel no-op path (T-6-18)"
  - "tkmessageBox sites inside KEPT functions (.gm_results_or_warn/.build_geomorph_data/plotPCA/plotMeanShape/exportGeomorph) became message() + unchanged return(), so no compute forwarding line moved"

patterns-established:
  - "Route-carried option flags: strict fixed-order CSV parser (.gmw_parse_gpaopts) -> opts list -> existing session-env tclVars, leaving the compute path byte-identical"
  - "Test inversion on strip: a pre-existing source-scan that pinned removed Tk behavior is repointed from presence to absence (same pattern as 06-03/06-05)"

requirements-completed: [UI-01, UI-02]

coverage:
  - id: D1
    description: "3dDigitize.surface.r has no ui.surface Tk builder, no Set-Number-of-Surface-Sliders toplevel, no tkmessageBox, and no add/set/del/shows engine verb; the headless downsample TPS warp + as.vector(t(.)) flatten and .dgt serializers are intact"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-surface-geomorph-stripped.R#surface.r is Tk builder / dialog / engine-verb free (UI-01/UI-02)"
        status: pass
      - kind: unit
        ref: "tests/testthat/test-surface-flatten.R#.gmw_downsample_session returns the row-major flatten of the stored surfaces (order preserved)"
        status: pass
    human_judgment: false
  - id: D2
    description: "3dDigitize.geomorph.r has no ui.geomorph tk2* widgets, no tkmessageBox, and no tkgetSaveFile; GPA/PCA/export compute logic and the parity-critical compute() gpagen forwarding are byte-unchanged"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-surface-geomorph-stripped.R#geomorph.r is Tk builder / tk2* / dialog / engine-verb free (UI-01/UI-02)"
        status: pass
      - kind: unit
        ref: "tests/testthat/test-gpa-parity.R#compute forwards parity-critical gpagen options"
        status: pass
      - kind: unit
        ref: "tests/testthat/test-gpa-parity.R#session read path yields the same .build_geomorph_data as populated activeDataList"
        status: pass
    human_judgment: false
  - id: D3
    description: "GPA option flags travel from the browser over /gpa as a strict bare CSV into the gpagen option tclVars via .gmw_session_to_geomorph_env, without changing .build_geomorph_data/compute forwarding"
    requirement: "UI-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-surface-geomorph-stripped.R#transport.R carries GPA option flags over a /gpa-family route"
        status: pass
      - kind: integration
        ref: "tests/testthat/test-shell-entry.R#digitize->gpa->save workflow is reachable through the shell handler, engine absent"
        status: pass
    human_judgment: false
  - id: D4
    description: "GPA CSV/RDS export save-name uses the browser field + /savepath while R owns the directory (/save carries no browser path); export parity holds"
    requirement: "UI-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-export-parity.R#.gmw_export_session dispatches only to save/exportGeomorph with an allow-listed fmt"
        status: pass
    human_judgment: false

# Metrics
duration: 15min
completed: 2026-08-14
status: complete
---

# Phase 6 Plan 06: Surface + Geomorph Tk Strip / GPA-options-over-a-route Summary

**`3dDigitize.surface.r` and `3dDigitize.geomorph.r` were stripped of every Tk tab builder, dialog, and native `add`/`set` engine verb, leaving only the headless `.gmw_downsample_session` TPS warp + `.dgt`/template serializers (surface) and the untouched GPA/PCA/export compute path (geomorph); the browser GPA option flags now travel as a strict fixed-order boolean CSV over the `/gpa` route into the existing gpagen option tclVars, and the export save-name flows over `/savepath` with R owning the directory.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-08-14
- **Tasks:** 3 (+ 1 deviation test inversion)
- **Files modified:** 5 (1 created, 4 modified)

## Accomplishments
- Deleted `ui.surface` + the Set-Number-of-Surface-Sliders `tktoplevel`, the `bind`/`init`/`updateWidgets` S3 methods, and the now-dead Tk `buildTemplate`/`buildTemplate1`/`downSample`/`disableOper`/`hidePly`/`draw.surface` handlers with their `tkmessageBox` dialogs and `add`/`set` engine verbs — keeping the headless `.gmw_downsample_session` (with its mandatory `as.vector(t(.))` flatten) and the template/`.dgt` serializers.
- Deleted `ui.geomorph` (all `tk2label`/`tk2entry`/`tk2spinbox`/`tk2checkbutton` GPA-option widgets) + the `bind`/`init`/`updateWidgets` S3 methods; replaced the `tkmessageBox` sites inside kept functions with `message()` and the `tkgetSaveFile` pickers with the browser save-name path — GPA/PCA/export compute logic left intact.
- Extended the existing `transport.R` `/gpa` branch with `.gmw_parse_gpaopts()`: a strict, fixed-order 11-field CSV (positive-integer `maxiter` + ten `0/1` booleans) parsed with base R (no `eval`, no path) and forwarded as `opts` to `.gmw_gpa_session(token, opts)` → the existing gpagen option tclVars via `.gmw_session_to_geomorph_env()`, leaving `.build_geomorph_data`/`compute` forwarding byte-unchanged (T-6-17).
- Routed the CSV/RDS export save-name through `e$save_name`/`e$save_dir` (seeded in `.gmw_session_to_geomorph_env` from the session `save_name` + R-owned `browse_dir`); `save()`/`exportGeomorph()` join only a `basename()` so the browser can never steer the write location (T-6-18).
- Added `test-surface-geomorph-stripped.R` (comment-filtered source-scan asserting both files are Tk/engine-free and the `/gpa`-family route carries the flags) and inverted the stale surface block in `test-digitizing-parity-macos.R`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Strip Tk builder/dialogs/engine verbs from 3dDigitize.surface.r** - `d3b6281` (feat)
2. **Task 2: Strip Tk from geomorph.r + carry GPA options over /gpa route (transport.R)** - `0c16114` (feat)
3. **Deviation: invert surface source-scan (test-digitizing-parity-macos.R)** - `58f94f1` (test)
4. **Task 3: Add Tk/engine-free source-scan test (test-surface-geomorph-stripped.R)** - `7eb8cdd` (test)

**Plan metadata:** skipped (`commit_docs: false` in `.planning/config.json` — `.planning/` docs are intentionally kept out of git history)

_Note: Task 3 carries `tdd="true"`, but the plan orders implementation (Tasks 1–2) before the test (Task 3), so a RED-against-absent-code commit was not possible (same ordering as Plans 06-01/06-03/06-05). The test is a real guard rather than a tautology: it comment-filters then asserts the deleted `ui.surface`/`ui.geomorph`/`tk2*`/`tkmessageBox`/`tkgetSaveFile`/engine-verb tokens are gone AND that the headless downsample seam + gpagen forwarding survive, so it would fail on either an incomplete strip or an over-strip. See TDD Gate Compliance below._

## Files Created/Modified
- `R/3dDigitize.surface.r` — reduced to `get_surface_date`, `write.nts`, the headless `.gmw_downsample_session`, and the surface/template `.dgt` serializers (`read.surface`/`write.surface`/`write.template`/`getTemplate`/`read.template`).
- `R/3dDigitize.geomorph.r` — removed `ui.geomorph`/`bind`/`init`/`updateWidgets`; `tkmessageBox` → `message()`; `tkgetSaveFile` → `e$save_name`/`e$save_dir`; added `save_name`/`save_dir` seeding in `.gmw_session_to_geomorph_env`; `compute`/`.build_geomorph_data` forwarding unchanged.
- `R/transport.R` — new `.gmw_parse_gpaopts()` helper; `/gpa` branch parses the CSV and forwards `opts` to `.gmw_gpa_session(token, opts)`.
- `tests/testthat/test-surface-geomorph-stripped.R` (new) — the Tk/engine-free + `/gpa`-route source-scan.
- `tests/testthat/test-digitizing-parity-macos.R` — surface block repointed from presence to absence (Rule 1 deviation).

## Decisions Made
- **Extended `/gpa`, not a new `/gpaopts` (RESEARCH Open Q2 resolved here).** One route carries both the compute trigger and the option flags; the empty-body path yields `list()` so native gpagen defaults hold and the `test-shell-entry.R` workflow drive (`ok("gpa")` with no body) stays green.
- **Fixed-order 11-field boolean CSV** (`maxiter,curves,surfaces,anchorsSurface,anchorsCurve,PrinAxes,ProcD,Proj,printP,parallel,approxBE`): a wrong field count returns `list()`; each boolean is `1L` only when exactly `"1"`; base-R parse, no `eval`, no path — the flags reach only the existing gpagen option tclVars (T-6-17).
- **Deleted the Tk `downSample`/`buildTemplate` wholesale** rather than partially stripping them: `.gmw_downsample_session` already reproduces their TPS warp + nearest-neighbour pass headlessly, so partial stripping would leave dead, Tk-coupled code.
- **Save-name over `/savepath` with R-owned directory** (T-6-18): `save()`/`exportGeomorph()` join `e$save_dir` (the session `browse_dir`) with `basename(e$save_name)`; an empty save-name preserves the former "keep in workspace as `gmData`" / no-op behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Inverted the stale surface source-scan in test-digitizing-parity-macos.R**
- **Found during:** Task 1 (surface.r strip)
- **Issue:** `test-digitizing-parity-macos.R` asserted that surface.r STILL contained `disableOper(e, F)` (≥4×) and the "Build template requires landmarks…"/"Downsample requires landmarks…" status strings — all of which live in the Tk `buildTemplate`/`downSample`/`disableOper` handlers this plan removes (UI-01/UI-02). Left unchanged the block would fail the suite.
- **Fix:** Repointed the block from presence to absence — assert no `disableOper`/`tkmessageBox`/engine verb in comment-filtered code, and assert the headless `.gmw_downsample_session` + `read.surface`/`write.surface` serializers survive (mirrors the 06-03/06-05 inversion pattern).
- **Files modified:** `tests/testthat/test-digitizing-parity-macos.R`
- **Verification:** `testthat::test_dir(filter="digitizing-parity-macos")` green (14/14).
- **Committed in:** `58f94f1`

---

**Total deviations:** 1 auto-fixed (1 bug). **Impact:** Necessary to keep the suite green after the mandated strip; a test-only inversion directly caused by Task 1, no production scope creep.

## Issues Encountered
- **`devtools` not installed** — the plan's `devtools::test(filter=…)` / `devtools::load_all()` verifies were run as `testthat::test_dir("tests/testthat", filter=…)` (sources the `helper-*.R` identically) plus `Rscript -e 'parse(f)'` load/parse smoke checks, the same substitution Plans 06-01/06-03/06-05 used. Bare R hangs under the workspace `renv` activate (known STATE open item), so all runs used `Rscript --no-init-file`.
- **macOS Tcl GUI-init noise** — `test-gpa-parity` loads `tcltk` for `tclvalue()`/`itob()`, which emits `Connection Invalid`/`hiservices-xpcservice` warnings to stderr on headless macOS. These are harmless — the block completed with 0 failures.

## TDD Gate Compliance
Task 3 carries `tdd="true"`, but the plan sequences the strip (Tasks 1–2) ahead of the source-scan (Task 3), so a genuine RED (failing-against-absent-code) commit was not possible — identical to Plans 06-01/06-03/06-05. The test is a real two-sided gate rather than a tautology: it fails on an incomplete strip (any residual `ui.surface`/`ui.geomorph`/`tk2*`/`tkmessageBox`/`tkgetSaveFile`/engine verb) AND on an over-strip (missing `.gmw_downsample_session`, `compute` gpagen forwarding, or the serializers). Commit types are `feat` (Tasks 1–2) and `test` (deviation + Task 3).

## Next Phase Readiness
- **Plan 07 (rtkogl deletion):** surface.r and geomorph.r are now free of `add`/`set`/`del`/`shows`, so deleting the engine bridge in `rtkogl.R` is a no-behavior-change removal for these two files.
- **Deferred by design:** live-browser UAT of the GPA options panel and the save-name modal remains the phase-end manual gate; the `tclvalue()`-heavy parity blocks can only run on a display host.

---

## Self-Check: PASSED

**Created files:**
- FOUND: `tests/testthat/test-surface-geomorph-stripped.R`
- FOUND: `.planning/phases/06-shell-and-native-retirement/06-06-SUMMARY.md`

**Task commits:**
- FOUND: `d3b6281` feat(06-06): strip Tk builder/dialogs/engine verbs from 3dDigitize.surface.r
- FOUND: `0c16114` feat(06-06): strip Tk from geomorph.r, carry GPA options over /gpa route
- FOUND: `58f94f1` test(06-06): invert surface source-scan to assert Tk build/downsample removed
- FOUND: `7eb8cdd` test(06-06): add Tk/engine-free source-scan for surface.r + geomorph.r + /gpa route

---
*Phase: 06-shell-and-native-retirement*
*Completed: 2026-08-14*
