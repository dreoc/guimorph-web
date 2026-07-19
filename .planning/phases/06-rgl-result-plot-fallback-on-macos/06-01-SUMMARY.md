---
phase: 06-rgl-result-plot-fallback-on-macos
plan: 01
subsystem: ui
tags: [rgl, rglwidget, htmlwidgets, webgl, macos, tcltk, testthat, r]

# Dependency graph
requires:
  - phase: 05-retina-picking-input-fixes-digitizing-analysis-data-parity
    provides: "GL-context-per-frame fix (129b42a) so rgl and the tkogl2 engine coexist in one process"
  - phase: 01-foundation
    provides: ".isMacOS() platform seam in rtkogl.R (wheel/dialog/shortcut parity)"
provides:
  - ".rgl_show() platform-guarded 3-D display helper (macOS WebGL widget / Windows interactive window)"
  - ".isMacOS()-guarded options(rgl.useNULL = TRUE) at GUImorph() startup"
  - "plotspecs + plotMeanShape route display through .rgl_show()"
  - "source-scan audit test proving ANL-02 criterion 2 (no select3d/rgl.snapshot/snapshot3d)"
affects: [phase-06-plan-02, macos-live-render-verify, windows-cmp-01-checkpoint]

# Tech tracking
tech-stack:
  added: [htmlwidgets (promoted transitive rgl dep -> direct Import)]
  patterns:
    - "Platform-guarded display helper: one .isMacOS() branch owns the how-to-show decision; plot functions stay declarative"
    - "Process-global rgl backend option set once, guarded, at GUImorph() startup before any open3d()"
    - "Source-scan testthat audit (readLines + grepl over function bodies) — no display required, passes on any OS"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-rgl-fallback-macos.R
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION

key-decisions:
  - "macOS render path uses htmlwidgets::saveWidget(selfcontained = FALSE) + browseURL + close3d — selfcontained=TRUE errors (pandoc absent on the target box)."
  - "options(rgl.useNULL = TRUE) is set ONLY under .isMacOS(); Windows interactive rgl path stays byte-identical (CMP-01)."
  - "Diverge from ROADMAP criterion 1's literal rgl.printRglwidget = TRUE wording: autoprint is a no-op inside a Tk button callback, so explicit saveWidget + browseURL is the real display mechanism."
  - "plotPCA left untouched (base-graphics quartz already renders on macOS); converting it would add a needless browser round-trip."

patterns-established:
  - "Platform-guarded display helper (.rgl_show) beside the existing .isMacOS() seam."
  - "Guarded startup backend option (rgl.useNULL) set before first open3d()."

requirements-completed: [ANL-02]

coverage:
  - id: D1
    description: "ANL-02 audit: no select3d / rgl.snapshot / snapshot3d in the 3-D plot functions"
    requirement: "ANL-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-rgl-fallback-macos.R#3-D plot file uses no interactive-selection / snapshot rgl calls (ANL-02)"
        status: pass
    human_judgment: false
  - id: D2
    description: "plotspecs + plotMeanShape display via .rgl_show(); rgl.bringtotop only inside the helper"
    requirement: "ANL-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-rgl-fallback-macos.R#plotspecs and plotMeanShape display via .rgl_show(), not rgl.bringtotop directly"
        status: pass
    human_judgment: false
  - id: D3
    description: ".rgl_show() macOS branch builds rglwidget -> saveWidget(selfcontained=FALSE) -> browseURL -> close3d; Windows branch keeps rgl.bringtotop"
    requirement: "ANL-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-rgl-fallback-macos.R#.rgl_show() helper defines the macOS widget path and the Windows branch"
        status: pass
    human_judgment: false
  - id: D4
    description: "options(rgl.useNULL = TRUE) is .isMacOS()-guarded at GUImorph() startup"
    requirement: "ANL-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-rgl-fallback-macos.R#options(rgl.useNULL = TRUE) is .isMacOS()-guarded at GUImorph() startup"
        status: pass
    human_judgment: false
  - id: D5
    description: "NULL-mode rglwidget -> saveWidget(selfcontained=FALSE) writes a non-empty HTML file (the exact mechanism .rgl_show uses)"
    requirement: "ANL-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-rgl-fallback-macos.R#NULL-mode rglwidget -> saveWidget(selfcontained = FALSE) writes a non-empty file"
        status: pass
    human_judgment: false
  - id: D6
    description: "macOS 3-D result plots (Plot Aligned Specimens, Plot Mean Shape) actually render/rotate in a browser; PCA quartz window opens; specimen correctness"
    verification: []
    human_judgment: true
    rationale: "Requires live GL/WebGL + browser display on the Mac; no headless oracle. Deferred to Plan 02 live-render + human-verify."
  - id: D7
    description: "Windows result plots render unchanged (interactive rgl window) — CMP-01"
    verification: []
    human_judgment: true
    rationale: "Off-box Windows host required; the .rgl_show() else-branch is byte-identical rgl.bringtotop(stay = TRUE). Confirmed live at the Plan 02 CMP-01 checkpoint."

# Metrics
duration: 7 min
completed: 2026-07-19
status: complete
---

# Phase 6 Plan 01: rgl Result-Plot Fallback on macOS Summary

**Platform-guarded `.rgl_show()` helper renders 3-D scenes as a browser WebGL widget on macOS (`rglwidget` → `saveWidget(selfcontained = FALSE)` → `browseURL` → `close3d`) while keeping the Windows interactive path byte-identical, with `rgl.useNULL` switched on only under `.isMacOS()` at startup.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-07-19T14:09:00Z
- **Completed:** 2026-07-19T14:16:00Z
- **Tasks:** 3
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments
- Added `.rgl_show()` beside the existing `.isMacOS()` seam in `rtkogl.R`: macOS builds a WebGL widget and opens it in the browser; Windows keeps `rgl.bringtotop(stay = TRUE)` unchanged.
- Set `options(rgl.useNULL = TRUE)` at `GUImorph()` startup **only** under `.isMacOS()`, before `ui(e)`, so the NULL device is in effect before any Results button can call `open3d()`.
- Rewired `plotspecs` and `plotMeanShape` to display via `.rgl_show()`; left `plotPCA` (base-graphics quartz) untouched.
- Promoted `htmlwidgets` from a transitive rgl dependency to a direct `DESCRIPTION` Import (manifest correctness — `.rgl_show()` now calls `htmlwidgets::saveWidget` directly; no install occurs).
- Added `test-rgl-fallback-macos.R`: source-scan audit (ANL-02 criterion 2) + headless NULL-mode `rglwidget` → `saveWidget(selfcontained = FALSE)` smoke test. 17/17 assertions green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Wave-0 testthat file (audit + headless smoke)** — `3577243` (test)
2. **Task 2: `.rgl_show()` helper + guarded `rgl.useNULL` startup** — `c9e677f` (feat)
3. **Task 3: Wire `.rgl_show()` into plot functions + `htmlwidgets` Import** — `2251259` (feat)

**Plan metadata:** SUMMARY/STATE/ROADMAP/REQUIREMENTS commit skipped by design (`commit_docs: false` in `.planning/config.json`).

## Files Created/Modified
- `tests/testthat/test-rgl-fallback-macos.R` — source-scan audit of both 3-D plot functions + `.rgl_show()`/startup-guard checks + headless widget smoke test.
- `R/rtkogl.R` — new `.rgl_show()` platform-guarded display helper; `.isMacOS()`-guarded `options(rgl.useNULL = TRUE)` at `GUImorph()` startup.
- `R/3dDigitize.geomorph.r` — `plotspecs` and `plotMeanShape` now end with `.rgl_show()` instead of a direct `rgl.bringtotop`; `plotPCA` unchanged.
- `DESCRIPTION` — `htmlwidgets` added to `Imports:`.

## Decisions Made
- **`selfcontained = FALSE` is mandatory** — pandoc is absent on the target box, so the `saveWidget`/`print()` default (`TRUE`) errors instead of writing. Verified live in RESEARCH.
- **`rgl.useNULL` guarded to macOS only** — setting it unconditionally would silently break the interactive Windows window (CMP-01 regression).
- **ROADMAP criterion 1 wording reconciled** — the ROADMAP names `rgl.printRglwidget = TRUE`, but autoprint fires only at REPL top-level, **not** inside a Tk button callback. The real, deterministic mechanism is explicit `rglwidget()` → `saveWidget(selfcontained = FALSE)` → `browseURL()`. This is an intentional divergence from the literal criterion text and resolves the plan-checker's warning; `rgl.printRglwidget` is neither required nor relied upon.
- **`plotPCA` untouched** — it is a base-graphics ordination that already renders on macOS via `quartz`; converting it to rgl would add a needless browser round-trip.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- **Pre-existing, out-of-scope full-suite failures (not caused by this plan).** `tests/testthat/test-curve-tab-gating.R` produces 7 failures (`assignInNamespace("tcl", ..., "tcltk")`: *"locked binding of 'tcl' cannot be changed"*). Confirmed pre-existing by an A/B check: the same failures reproduce identically at the pre-phase base commit (`3577243~1`) with none of the Phase 6 changes present. That file sources `3dDigitize.main.r` and does not interact with any file this plan touched. Logged to `.planning/phases/06-rgl-result-plot-fallback-on-macos/deferred-items.md`; not fixed (scope boundary). `test-dgt-cross-platform.R` has 1 intentional skip (DAT-03 byte fixtures pending).

## Test Results
- **New plan test file** (`test-rgl-fallback-macos.R`): `PASS = 17, FAIL = 0, ERROR = 0` — all source-scan audit blocks + the headless widget smoke test green.
- **Full suite** (`testthat::test_dir`): `PASS = 94, FAIL = 7, SKIP = 1`. All 7 failures are the pre-existing `test-curve-tab-gating.R` namespace-lock issue (reproduced at base commit); the 1 skip is the intentional DAT-03 fixture gate. No regressions attributable to this plan.
- **Verification greps:** `rgl.bringtotop` no longer appears in `3dDigitize.geomorph.r` (0 hits); `plotPCA` body has 0 `rgl::` calls; `.rgl_show()` appears in both 3-D plot bodies; `htmlwidgets` present in `DESCRIPTION` Imports.

## User Setup Required
None - no external service configuration required (no new package installs; `rgl`/`htmlwidgets` already on disk).

## Next Phase Readiness
- Display mechanism implemented and unit-verified for its platform-branch logic. **Live macOS render** (widget rotates in browser; PCA quartz opens) and **off-box Windows CMP-01 confirmation** are the remaining manual verifications — both are Plan 02 items.
- No blockers introduced. The GL-context-per-frame prerequisite (Phase 5 `129b42a`) is already in place.

## Self-Check: PASSED

- `test-rgl-fallback-macos.R` — FOUND on disk.
- `R/rtkogl.R` (`.rgl_show` + guarded startup) — FOUND.
- `R/3dDigitize.geomorph.r` (`.rgl_show()` wiring) — FOUND.
- `DESCRIPTION` (`htmlwidgets` Import) — FOUND.
- Commits `3577243`, `c9e677f`, `2251259` — all FOUND in `git log`.

---
*Phase: 06-rgl-result-plot-fallback-on-macos*
*Completed: 2026-07-19*
