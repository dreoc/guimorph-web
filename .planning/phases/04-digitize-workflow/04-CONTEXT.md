# Phase 4: Digitize Workflow - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete landmark/curve digitization and `.dgt` persistence on Windows R using the legacy GUImorph GUI. Phase 4 delivers plans 04-02 (curve definition) and 04-03 (`.dgt` save/reload round-trip), building on validated 04-01 landmark placement (DGT-01). Requirements DGT-02, DGT-03, and DGT-04 must pass. This phase restores existing R/C workflow behavior — not C engine refactoring (Phases 7–9), not geomorph analysis (Phase 5), and not enabling dormant experimental curve UI.

</domain>

<decisions>
## Implementation Decisions

### Curve Definition Workflow (DGT-02)
- **D-01:** Validate the **legacy curve workflow only** — Curve tab, `window mode = curve`, double-click to select 3 existing landmark dot IDs via `onSelectCurve`; do **not** enable dormant UI buttons (`Set curves (total) number`, `Set Current curve number`, `Compute Curves`) commented out in `ui.curve`.
- **D-02:** **Landmarks first, then curves** — user places landmarks on the Digitize tab (double-click `addDot`), switches to Curve tab, then selects 3 landmarks to form a curve. Curve bind does not create new landmarks.
- **D-03:** **One curve minimum** — 3 landmarks forming 1 curve row in `activeDataList[[1]][[4]]` satisfies DGT-02 acceptance.
- **D-04:** **Fit button smoke-test only** — click Fit once to confirm no crash; do not deep-validate semi-landmark spline/resampling math in Phase 4.

### `.dgt` Save/Reload (DGT-03, DGT-04)
- **D-05:** **Primary save/reload verification: landmarks + curves** — Phase 4 success focuses on these sections; empty template/surface sections need not be explicitly tested if unused.
- **D-06:** **Reload via GUI menu** — validate `openDgt()` file-open path in `3dDigitize.main.r`; do not require separate validation of the C-side `loadDgt` Tcl command.
- **D-07:** **Anchors round-trip if present** — anchors are not a Phase 4 requirement to digitize, but if the user places anchors during the test session, saved `.dgt` must restore them on reload.
- **D-08:** **Multi-specimen validation required** — `saveToDgt` multi-specimen loop must be exercised, not single-specimen-only.
- **D-09:** **Same-session reload** — save `.dgt`, then reopen via GUI in the same GUImorph/R session; cold restart reload is out of scope for Phase 4.

### Fix vs Document Boundary
- **D-10:** **26 `load_all` warnings — capture only** — run `warnings()` after `load_all`, log findings; fix only if a warning blocks curve/save/reload workflow.
- **D-11:** **Leave debug `print()` statements** — verbose logging in curve/save paths stays for Phase 4 debugging; cleanup deferred to Phase 9.
- **D-12:** **Blocker definition: digitize path failures only** — fix crashes, silent failures, or data loss in curve/save/reload; UX confusion (like single-click vs double-click) is documentation, not code fix.
- **D-13:** **Document quirks in `.planning/smoke-test-findings.md`** — append Phase 4 validation results and known workflow quirks there.

### Validation Baseline
- **D-14:** **Primary test specimen: `C13.1.ply`** — continue Phase 3 smoke-test mesh from `zips/Folsom 3D models/`.
- **D-15:** **Create fresh `.dgt` during Phase 4** — no hunt for external legacy golden files; hand-digitize during validation.
- **D-16:** **Multi-specimen setup: two different PLY files** — load two meshes from the Folsom collection (including C13.1.ply plus a second specimen) to exercise multi-specimen save/reload.
- **D-17:** **Do not commit `.dgt` fixtures** — test artifacts stay local; embedded absolute/UNC specimen paths are machine-specific.

### Carried Forward (prior phases — do not re-decide)
- Landmarks require **double-click** on canvas (`addDot`); single-click is pick/select only (`set dot selected`).
- **Option A** locked — rehabilitate legacy C/R engine; no rgl/Shiny rewrite.
- WSL UNC paths work for package load and PLY access; MinGW DLL in `inst/libs/x64/`.

### Claude's Discretion
None — user made explicit choices for all gray areas.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/ROADMAP.md` — Phase 4 goal, plans 04-02/04-03, success criteria, progress (04-01 complete)
- `.planning/REQUIREMENTS.md` — DGT-01 through DGT-04 definitions and traceability
- `.planning/PROJECT.md` — double-click landmark UX decision, Option A scope, architecture overview
- `.planning/STATE.md` — current position, blockers (26 warnings uncaptured)

### Validation handoff & research
- `.planning/smoke-test-findings.md` — Phase 1–3 smoke results; **append Phase 4 findings here** (D-13)
- `.planning/research/PITFALLS.md` — refactor-before-GUI-works, dot/anchor dedup risks
- `.planning/research/FEATURES.md` — table stakes for curves, `.dgt`, anchors

### Primary R source (digitize workflow)
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.curve.r` — `bind.curve`, `onSelectCurve`, `read.curve`, `write.curve`, `ui.curve`, `onFit`
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` — `bind.digitize`, `addDot` (double-click placement)
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` — `saveToDgt`, `openDgt`, Curve tab switch (`switchTab` id==3), `dgtDataList` structure

### Test data
- `zips/Folsom 3D models/C13.1.ply` — primary validated specimen (Phase 3)
- `zips/Folsom 3D models/` — second PLY for multi-specimen session (D-16)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`onSelectCurve` / `bind.curve`**: Legacy 3-landmark curve definition — selects existing dots, stores row in `activeDataList[[1]][[4]]`, calls `add("curve", id1, id2, id3)` on 3rd selection; middle dot becomes slider (`e$sliders`).
- **`write.curve` / `read.curve`**: `.dgt` curve section I/O (`Curve=N` header + numeric rows).
- **`saveToDgt` / `openDgt`**: Full session persistence; menu-wired in main UI; multi-specimen loop already implemented.
- **`draw.curves` / tab-switch curve restore**: Rebuilds C-side curve display when switching to Curve tab or reloading `.dgt`.

### Established Patterns
- **Tab-driven modes**: Digitize tab uses default mode; Curve tab calls `set("window", "mode", "curve")`.
- **Double-click placement/selection**: Landmarks on Digitize tab; curve point selection on Curve tab — same mouse gesture, different handlers.
- **`dgtDataList` slots**: `[[1]]` specimen path, `[[3]]` landmark count, `[[4]]` curves matrix, `[[11]]` anchors (if used).
- **R↔C protocol**: `add("curve", ...)`, `add("SetCurveIndex", ...)`, `set("dot", "selected", x, y)` — stringly-typed Tcl dispatch via `rtkogl.R`.

### Integration Points
- **File menu**: Save/open `.dgt` hooks in `3dDigitize.main.r` (~lines 553–561).
- **Tab switch id==3**: Curve tab initialization and existing-curve redraw on tab entry.
- **Anchor tab**: Separate `bind.anchor` / `addAnchor` — include in round-trip only if user digitizes anchors during test (D-07).

</code_context>

<specifics>
## Specific Ideas

- User confirmed landmark visibility issue was UX (single-click pick vs double-click place), not a render bug — document similar curve-tab expectations if selection fails.
- Multi-specimen test uses **two different PLY files** from Folsom collection, not duplicate loads of the same mesh.
- Fit button visible in Curve tab UI; other curve management buttons intentionally hidden in legacy code.

</specifics>

<deferred>
## Deferred Ideas

- **Enable dormant curve UI** (`Set curves number`, `Compute Curves`) — user chose legacy-only workflow; belongs in future enhancement, not Phase 4.
- **Deep Fit / spline math validation** — deferred; Phase 4 smoke-test only.
- **Cold restart `.dgt` reload** (quit R, relaunch, open file) — deferred; same-session sufficient.
- **Committed `.dgt` golden fixture** — deferred; paths are machine-specific.
- **Fix all 26 `load_all` warnings** — deferred unless blocking digitize; capture only.
- **Debug print cleanup** — Phase 9 C engine cleanup scope.
- **C-side `loadDgt` standalone validation** — deferred; GUI `openDgt()` is the Phase 4 path.

</deferred>

---

*Phase: 4-Digitize Workflow*
*Context gathered: 2026-06-15*
