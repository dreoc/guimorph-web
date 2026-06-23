# Phase 5: Analysis Round-Trip - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Run `geomorph` analysis on digitized data from Phase 4; fix breaking API calls so ANAL-01–03 pass. Phase 5 restores the **existing GPA tab workflow** (`3dDigitize.geomorph.r` → `gpagen`) on current CRAN geomorph — not new analysis UI, not C engine rehab (Phases 7–9), not semilandmark surface downsampling validation unless it blocks GPA.

</domain>

<decisions>
## Implementation Decisions

### Minimum Analysis (ANAL-01)
- **D-01:** **Landmarks-only GPA** satisfies "at least one analysis runs" — 3 landmarks × 2 specimens, **no** curve/surface sliding checkboxes for Phase 5 smoke test.
- **D-02:** **Two specimens required** — use reloaded `test_fresh.dgt` (C13.1.ply + C8.1.ply); proves multi-specimen GPA on Phase 4 handoff.
- **D-03:** **Keep existing GPA tab defaults** — PrinAxes/ProcD/Proj ON, sliding checkboxes OFF; validate legacy UI as-is. Document `gpagen` ProcD default change from geomorph 4.x if behavior differs; do not redesign UI.

### Validation Path (ANAL-01)
- **D-04:** **GUI GPA tab end-to-end** — Load DGT → GPA tab → Compute → Plot Aligned Specimens → Save Result CSV.
- **D-05:** **Manual Windows R UAT** — same verification pattern as Phase 4; append results to `.planning/smoke-test-findings.md` (D-13 carry-forward).

### Test Data (ANAL-01)
- **D-06:** **Reuse `test_fresh.dgt`** — reload via `openDgt` (Phase 4 validated); no hunt for legacy golden files.
- **D-07:** **Same-session workflow** — `load_all` → `GUImorph()` → Load DGT → GPA in one R session (parallel to Phase 4 D-09).

### API Migration (ANAL-02, ANAL-03)
- **D-08:** **GPA hot path first** — fix what blocks `compute()` / `gpagen` / `plotAllSpecimens` / `save()`; full grep inventory documents remaining call sites for later.
- **D-09:** **Inventory scope: geomorph + Morpho** in active R sources (`3dDigitize.*.r`, `geomorph.support.code.r`); include Morpho `fastKmeans` in surface downsampling path in inventory even if not fixed in Phase 5 unless blocking.

### Vendored geomorph Code
- **D-10:** **Defer unused advanced paths** in `geomorph.support.code.r` (~2700 lines) — keep file; only touch code reachable from GPA hot path; document dead `advanced.procD.lm` vendored helpers as out of scope for Phase 5 execution.
- **D-11:** **No new analysis UI** — GPA tab only; no PCA tab, no `gm.prcomp` GUI button in Phase 5.

### Fix vs Document Boundary (carried from Phase 4)
- **D-12:** **Blocker definition: analysis path failures only** — fix crashes, API errors, or silent GPA failures; UX quirks documented, not code-fixed unless they block Compute.
- **D-13:** **Append Phase 5 findings to smoke-test-findings.md** — GPA UAT pass/fail, API migration notes, warnings if relevant.
- **D-14:** **Do not commit analysis output fixtures** — saved CSV/results stay local (parallel to D-17 for `.dgt`).

### Carried Forward (prior phases — do not re-decide)
- **Option A** locked — rehabilitate legacy R/C engine; no rgl/Shiny rewrite.
- Phase 4 digitize baseline: `test_fresh.dgt`, 3 LM/specimen, 1 curve on specimen 1, `Surface=0`, `openDgt` reload fixed.
- WSL UNC paths for package load; MinGW DLL in `inst/libs/x64/`.
- Leave debug `print()` in analysis paths for Phase 5 debugging (cleanup Phase 9).

### Claude's Discretion
- Exact order of 05-01 inventory vs 05-02 GPA UAT attempts (try UAT first to surface errors, or inventory-first per research — planner decides).
- Whether `plotAllSpecimens` or `two.d.array` need geomorph 4.x signature updates beyond minimal hot-path fix.
- How to document vendored `geomorph.support.code.r` dead code without deleting it.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/ROADMAP.md` — Phase 5 goal, plans 05-01–05-03, success criteria
- `.planning/REQUIREMENTS.md` — ANAL-01, ANAL-02, ANAL-03 definitions
- `.planning/PROJECT.md` — Option A scope, geomorph migration strategy
- `.planning/STATE.md` — Phase 4 completion handoff

### Phase 4 handoff
- `.planning/phases/04-digitize-workflow/04-CONTEXT.md` — digitize decisions, fix-vs-document boundary
- `.planning/phases/04-digitize-workflow/04-02-SUMMARY.md` — curve workflow baseline
- `.planning/phases/04-digitize-workflow/04-03-SUMMARY.md` — save/reload + openDgt fixes
- `.planning/smoke-test-findings.md` — Phase 4 validation; append Phase 5 section here

### Research
- `.planning/research/STACK.md` — geomorph 4.1.0 API changes (`gpagen` ProcD default, deprecated procD helpers)
- `.planning/research/PITFALLS.md` — geomorph API migration without inventory; refactor-before-GUI-works
- `.planning/research/FEATURES.md` — analysis round-trip as table stakes
- `.planning/research/SUMMARY.md` — geomorph inventory-first recommendation

### Primary R source (analysis layer)
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r` — GPA tab UI, `compute()`, `gpagen`, `plotspecs`, `save`
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/geomorph.support.code.r` — vendored procD/gpagen helpers (defer unused)
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` — GPA tab in notebook (`switchTab` id==4), `getLandmark`/`getAnchor` hooks
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.surface.r` — Morpho `fastKmeans` in downsampling (inventory only unless blocking)

### Test data (local, do not commit)
- `zips/Folsom 3D models/test_fresh.dgt` — Phase 4 multi-specimen fixture (user machine)
- `zips/Folsom 3D models/C13.1.ply`, `C8.1.ply` — specimen meshes referenced by `.dgt`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **GPA tab** (`ui.geomorph`, `compute`, `plotspecs`, `save`) — full GUI workflow already wired; Phase 5 validates + fixes API breaks.
- **`getLandmark(i)`** — C-layer coordinate extraction used by `compute()` before `gpagen`.
- **`gpagen()` call** in `compute()` — passes `coords.A`, optional `curves`/`surfaces` from checkboxes; landmarks-only path sets `coords.A <- array(coords.lmk, ...)`.

### Established Patterns
- **Landmarks-only GPA path** — when surface/curve sliding checkboxes OFF, `coords.A` is landmark array only (lines 194–196 in `3dDigitize.geomorph.r`).
- **Results in `e$gm.results`** — assigned to global `gm.results` for `plotspecs()`; `save()` writes CSV via `two.d.array`.
- **Phase 4 data shape** — 3 LM, 2 specimens, curve in `activeDataList[[1]][[4]]` but sliding OFF for Phase 5 test.

### Integration Points
- **Digitize → GPA** — `e$activeDataList`, `e$landmarkNum`, `e$landmarkNum` from digitize session or `openDgt` reload.
- **geomorph CRAN** — `@import geomorph`; `gpagen`, `plotAllSpecimens`, `two.d.array` are hot-path APIs.
- **Vendored support file** — `geomorph.support.code.r` duplicates/forks geomorph internals; not on hot path for landmarks-only GPA unless `gpagen` delegates there.

</code_context>

<specifics>
## Specific Ideas

- User wants full GUI proof: Compute → Plot → Save CSV, not compute-only smoke.
- Prefer building on Phase 4 `test_fresh.dgt` rather than re-digitizing or hunting legacy files.
- Accept documenting (not fixing) vendored advanced procD code and multi-specimen curve overlay quirks from Phase 4.

</specifics>

<deferred>
## Deferred Ideas

- **GPA + curve sliding** — enable "Slide semilandmarks on curves" using specimen-1 curve matrix; future phase or gap plan after landmarks-only GPA passes.
- **PCA (`gm.prcomp`)** — ROADMAP example only; no new UI in Phase 5.
- **Three+ specimens for GPA** — optional stronger test; not required for Phase 5 success.
- **Delete or fully replace `geomorph.support.code.r`** — defer to post-GPA cleanup or C/R rehab phases.
- **Automated Rscript GPA test** — human UAT is primary; automation optional if planner finds low-cost hook.
- **Cold-restart reload before GPA** — out of scope; same-session only per D-07.

</deferred>

---

*Phase: 05-analysis-round-trip*
*Context gathered: 2026-06-15*
