---
phase: 06-shell-and-native-retirement
plan: 02
subsystem: ui
tags: [view3d, browser-shell, httpuv, file-picker, modal, tabs, menu-bar, status-bar, three.js, R]

# Dependency graph
requires:
  - phase: 06-shell-and-native-retirement
    provides: "Plan 01 loopback shell routes (/files, /open, /savepath, /status, /tabstate, /msgack, /color)"
  - phase: 05-full-digitizing-and-data-parity
    provides: "view3d.R Phase-5 HUD + mode toolbar + switchSpecimen RE-SERVE + /overlays redraw"
provides:
  - "Browser shell chrome in GMW_VIEW3D_TEMPLATE BODY: DOM menu bar, tab strip, status bar, reusable #modal"
  - "File picker modal (single + multi-select) over /files + /open; save-name field over /savepath + /save"
  - "Menu/tab/nav/dialog/color/shortcut wiring driving the Plan-01 routes through the existing fetch()/post() plumbing"
  - "Message-box + color-picker + save-name Tk-dialog replacements (/msgack, /color, /savepath)"
affects: [06-04-native-retirement, 06-05-dialog-replacements, 06-06-dialog-replacements]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shell chrome injected from the parameter-free BODY via a JS-built <style> + document.createElement so the sprintf HEAD stays under the 8192-byte cap"
    - "One reusable #modal (openModal/closeModal) hosts the picker, message box, color prompt, and save-name field"
    - "R-owns-path picker: browser posts only a basename R enumerated over /files; membership enforced server-side"

key-files:
  created: []
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-digitizing-view3d.R"

key-decisions:
  - "All shell chrome (HTML + CSS + JS) is injected from the BODY (after the MESH_URL marker); CSS is added via a JS-created <style> element rather than the HEAD <style> block so head_fmt stays 1870 bytes"
  - "Add PLY and Merge share ONE multi-select checkbox picker + a save-name text field (RESEARCH A5) posting to /open then /savepath (+ /save for Merge) — no native multiple=TRUE chooser"
  - "Specimen prev/next, the <select>, and the [ / ] keys all call the existing switchSpecimen(n) (RE-SERVE A4); the index is never set inline without the mesh re-serve + redraw()"
  - "Status-bar mode readout is client-driven via setMode (mirrors HUD #m); /status only drives the specimen index + counts because the server mode field is a stub default (no mode-set route yet)"
  - "Live counts kept fresh by a 1s /status + /tabstate poll rather than wiring refreshStatus into every mutating call site"

patterns-established:
  - "BODY-injected shell chrome: JS builds <style> + menu/tab/status/modal DOM after the MESH_URL split marker, keeping every %s slot in the tiny parameterised HEAD"
  - "Reusable modal dispatch: openModal(title, bodyHTML, onOk, okLabel) + a single OK/Cancel handler serves every former Tk dialog"

requirements-completed: [UI-01]

coverage:
  - id: D1
    description: "The browser page renders a menu bar, tab strip (digitize/anchor/surface/curve/GPA), status bar, and a reusable modal layer at Tk parity"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-view3d.R#shell chrome renders a tab strip, menu bar, status bar, and modal layer (UI-01)"
        status: pass
    human_judgment: false
  - id: D2
    description: "All shell markup + wiring lives in the parameter-free BODY; head_fmt stays under 8192 bytes with exactly the 6 known %s slots"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-view3d.R#all shell markup + wiring lives in the parameter-free BODY (HEAD under the 8192-byte cap)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Specimen prev/next + <select> reuse the RE-SERVE switchSpecimen/loadSpecimen(url) path (A4 not regressed)"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-view3d.R#specimen nav reuses the RE-SERVE switchSpecimen path (A4 not regressed)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Menu/picker/dialog/color/status actions drive the Plan-01 routes over relative same-origin names, never absolute URLs (T-6-07)"
    requirement: "UI-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-view3d.R#shell actions drive the Plan-01 routes over relative same-origin names (T-6-07)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Each tab/menu/dialog/picker/color/status readout matches Tk parity in a live browser"
    verification: []
    human_judgment: true
    rationale: "Visual/functional feature-parity against the retired Tk chrome is a live-browser judgment; deferred to phase UAT per the plan's Manual verification note."

# Metrics
duration: 18min
completed: 2026-08-14
status: complete
---

# Phase 6 Plan 02: Browser Shell Summary

**The Phase-5 HUD + mode toolbar grown into a full Tk-parity browser shell — a DOM menu bar, five-tab strip, status bar, and a reusable modal (file picker, message box, color picker, save-name field) — all injected from the parameter-free template BODY and driving the Plan-01 loopback routes through the existing fetch()/post() plumbing.**

## Performance

- **Duration:** ~18 min
- **Completed:** 2026-08-14
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- Injected the shell chrome — `#menubar` (File: Load PLY/DGT, Add PLY, Save, Export CSV/RDS, Merge; Help), `#tabs` (digitize/anchor/surface/curve/GPA), `#status` (specimen `<select>`, prev/next, mode, land/anchor/surface counts, color input), and a reusable `#modal` — entirely from the BODY after the `MESH_URL = "%s";` marker, so `head_fmt` stays 1870 bytes (well under the 8192-byte sprintf cap).
- Added a reusable modal (`openModal`/`closeModal`) that hosts the D-03 file picker, the message box, the color prompt, and the save-name field — one container replaces every scattered Tk dialog.
- Wired File→Load DGT/PLY to `fetch("files")` → selectable list → `post("open", sel)` → `redraw()`; Add PLY / Merge to the same picker with a checkbox multi-select + save-name field (RESEARCH A5) posting `/open` then `/savepath` (and `/save` for Merge).
- Reused the existing `switchSpecimen(n)` RE-SERVE path (A4) for prev/next, the `<select>`, and the `[`/`]` keys; added Ctrl/Cmd+S → `post("save")`; replaced `tkmessageBox` with the modal (`/msgack`) and `tk_chooseColor` with `<input type="color">` → `/color`.
- Kept `#status` counts and tab-gating live via a 1s `/status` + `/tabstate` poll; extended `test-digitizing-view3d.R` with shell-markup, HEAD-cap (6-slot), RE-SERVE, and relative-route tests. `view3d` suite green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tab strip, menu bar, status bar, modal layer in the BODY** - `3136877` (feat)
2. **Task 2: Wire menu/tab/nav/dialog/color/shortcut actions to the Plan-01 routes** - `3de51cf` (feat)
3. **Task 3: Extend view3d tests (shell markup + HEAD cap + RE-SERVE)** - `f18244b` (test)

**Plan metadata:** skipped (`commit_docs: false` in `.planning/config.json` — `.planning/` docs are intentionally kept out of git history)

## Files Created/Modified
- `R/view3d.R` — Added a `buildShell()` IIFE (JS-built `<style>` + `#menubar`/`#tabs`/`#status`/`#modal` DOM), `openModal`/`closeModal`, menu-dropdown toggling, and a shell-wiring block (picker `openPicker`/`openMultiPicker`, `showMessage`, menu-item handlers, tab gating via `/tabstate`, specimen nav via `switchSpecimen`, color `/color`, `[`/`]` + Ctrl/Cmd+S keys, and a `refreshStatus` poll). Added one line to `setMode` to mirror the mode into `#st-mode`. All additions live after the `MESH_URL = "%s";` marker.
- `tests/testthat/test-digitizing-view3d.R` — Four new `test_that` blocks: shell chrome renders; all shell markup/wiring stays in the BODY with `head_fmt` < 8192 bytes and exactly 6 `%s` slots; RE-SERVE `switchSpecimen`/`loadSpecimen(url)` preserved and used by nav; shell actions use relative Plan-01 route names, never absolute URLs.

## Decisions Made
- **Shell chrome is injected from the BODY, CSS included.** The existing DOM (canvas, `#t` toolbar, `#h` HUD) sits in the parameterised HEAD region (before the marker), so adding markup there would grow `head_fmt`. Instead the menu/tab/status/modal DOM and their CSS are built by JS after the marker (a `document.createElement("style")` for the CSS), leaving `head_fmt` byte-identical at 1870 bytes.
- **Add PLY and Merge share one multi-select picker + save-name field** (resolves RESEARCH Open Question 3 / A5). A checkbox list plus a `Save as` text field posts each chosen basename to `/open` then the bare name to `/savepath` (Merge additionally posts `/save`), rather than a native `multiple = TRUE` chooser — consistent with server-owns-path.
- **Specimen nav never sets the index inline.** Prev/next, the `<select>`, and `[`/`]` all call the unchanged `switchSpecimen(n)` so the mesh RE-SERVE + BVH rebuild + `redraw()` always run (A4 / RESEARCH Pitfall 4).
- **Client-owned mode readout.** `#st-mode` is updated by `setMode` (mirroring HUD `#m`); `/status` only drives the specimen index + counts, because the server `/status` mode field is a documented stub default until a mode-set route lands.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- `devtools` is not installed in this environment, so the plan's `devtools::test(filter="view3d")` verify command was run as the equivalent `testthat::test_dir("tests/testthat", filter="view3d")` (sources the `helper-*.R` files identically). Bare R hangs under the workspace `renv` activate (known STATE open item), so every run used `Rscript --no-init-file` as prescribed.

## TDD Gate Compliance
Task 3 carries `tdd="true"`, but the plan sequences the shell implementation (Tasks 1–2) ahead of the tests (Task 3), so a genuine RED (failing-against-absent-code) commit was not possible — the same ordering as Plan 06-01. The new tests are real guards rather than tautologies: the HEAD-cap test asserts `head_fmt` < 8192 bytes AND exactly 6 `%s` slots AND that shell tokens (`menubar`, `openModal`, `openPicker`, `fetch("status")`) are ABSENT from the HEAD fmt, so it fails the moment any shell markup or slot is mistakenly added to the HEAD. Commit types are `feat` (Tasks 1–2) and `test` (Task 3).

## Next Phase Readiness
- The browser page is now a complete shell at Tk parity, so Plans 04–06 can retire the Tk chrome (`ui.main`/`ui.digitize`/`ui.anchor`/`ui.surface`/`ui.curve`/`ui.geomorph`), the `tkmessageBox`/`tk_chooseColor`/`tkgetOpenFile`/`tkgetSaveFile` dialogs, and finally the native engine, with the browser control surface already in place.
- Deferred by design: the full server-side specimen load on `/open` and a mode-set route feeding `/status` (both owned by later plans); the live-browser feature-parity UAT (D5) for the phase UAT.

## Self-Check: PASSED

- Files: `06-02-SUMMARY.md`, `R/view3d.R`, `tests/testthat/test-digitizing-view3d.R` all present.
- Commits present on branch `main`: `3136877` (feat), `3de51cf` (feat), `f18244b` (test).
- Final metadata commit skipped: `commit_docs: false` — `.planning/` docs intentionally left uncommitted.

---
*Phase: 06-shell-and-native-retirement*
*Completed: 2026-08-14*
