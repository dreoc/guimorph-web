# Phase 6: Reproducible Dev Environment - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Document and lock the full build → deploy → test → develop cycle before C engine refactoring (Phase 7). Phase 6 delivers DEV-01–03: `renv` lockfile with restore instructions, contributor-facing `BUILD.md` covering native build through Windows R GUI test, DLL deploy workflow, and README quick-start. This phase captures **how contributors set up and verify** the working baseline — not C engine modularization (Phase 7+), not new GUI features, and not fixing backlog UX bugs (999.x).

</domain>

<decisions>
## Implementation Decisions

### renv Scope (DEV-01)
- **D-01:** **renv project root = `GUImorphDevelopment/`** — standard R package layout; matches `load_all(".")` cwd validated in Phases 2–5.
- **D-02:** **Pin DESCRIPTION Imports + workflow extras** — `geomorph`, `Morpho`, `parallel`, `Rvcg`, `tcltk`, `tcltk2`, `vegan` plus `devtools`, `rgl`, `RRPP` (GPA Plot path validated Phase 5).
- **D-03:** **Document minimum R 4.6+** — lockfile tracks package versions; do not fail restore on minor R patch mismatch.
- **D-04:** **`renv::restore()` primary path = Windows R only** — runtime target where GUI and `tkogl2.dll` work; no dual WSL/Windows renv lockfiles.

### Documentation Layout (DEV-02, DEV-03, ROADMAP 06-03)
- **D-05:** **Root `BUILD.md`** — single integrated contributor doc with sections: Prerequisites, Native build, DLL deploy, R environment, Smoke test, Troubleshooting. Link to `integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md` as compile deep-dive.
- **D-06:** **README = brief pointer** — short GitHub-facing summary + 5-step quick-start linking to `BUILD.md`; do not duplicate full instructions inline.
- **D-07:** **Integrated doc structure** — one root `BUILD.md`, not split `DEVELOPMENT.md` / native-only split.
- **D-08:** **README documents inherent GUImorph quirks only** — e.g. double-click landmark placement, pick vs place behavior. Do **not** document WSL/UNC-specific setup paths as contributor defaults. Technical warning triage may reference `BUILD.md`; audit log remains `.planning/smoke-test-findings.md`.

### Contributor Setup Path
- **D-09:** **WSL not required for contributors** — documented default assumes **Windows R + local repo clone** on a normal Windows path. WSL is the maintainer's local choice, not a prerequisite.
- **D-10:** **Document `winget install RProject.R`** — include one-liner for fresh Windows machines in prerequisites.
- **D-11:** **Windows-native MinGW build as primary C build path** — document cmake + MinGW-w64 on Windows (not WSL cross-compile as default). Existing WSL workflow may appear as optional/advanced appendix only if researcher confirms parity.
- **D-12:** **Targeted verification principle** — contributors test the workflow relevant to their change: R-only edits → `load_all` + affected GUI path; C/`tkogl2` edits → rebuild DLL, deploy, then GUI smoke.

### DLL Deploy Workflow (DEV-03)
- **D-13:** **Script + manual fallback** — add `scripts/deploy-dll.ps1` for convenience; `BUILD.md` also documents manual `copy` commands.
- **D-14:** **Auto-backup before swap** — deploy script copies current `inst/libs/x64/tkogl2.dll` to `tkogl2.dll.bak` before overwriting.
- **D-15:** **Deploy `tkogl2.dll` only** — `glut64.dll` already bundled; deploy workflow does not touch GLUT unless explicitly rebuilt.
- **D-16:** **Post-deploy verification = full GUI smoke** — `load_all` + `GUImorph()` + load sample PLY (not export-check alone).

### load_all Warnings (Phase 4 D-10 evolution)
- **D-17:** **Triage + document** — capture `warnings()` after renv baseline; classify HOT (blocks workflow) vs DEFERRED; fix HOT only in Phase 6.
- **D-18:** **User-facing quirks in README** — inherent GUImorph behavior that looks like bugs; technical warning inventory in `BUILD.md` or smoke-test audit log.
- **D-19:** **HOT threshold = blocks workflow** — fix only warnings causing `load_all` failure, missing symbols, or GUI/GPA breakage; defer cosmetic/roxygen/deprecated noise.
- **D-20:** **Capture baseline after first `renv::restore()` + `load_all`** on clean Windows R — establishes post-lockfile warning inventory.

### Carried Forward (prior phases — do not re-decide)
- **Option A** locked — Windows-only runtime, legacy OpenGL/WGL engine.
- Package root `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`; MinGW DLL in `inst/libs/x64/`.
- Phases 1–5 validated: digitize + landmarks-only GPA on `test_fresh.dgt`.
- Double-click landmark placement is expected UX, not a render bug.

### Claude's Discretion
- Exact Windows-native MinGW toolchain packages, cmake flags, and whether existing `cmake/mingw-w64-x86_64.cmake` adapts or needs a Windows-host variant (researcher validates against current `tkogl2/BUILD.md`).
- `deploy-dll.ps1` implementation details (PowerShell vs batch; path resolution from repo root).
- How much of existing WSL-centric `tkogl2/BUILD.md` to retain vs rewrite for D-11.
- Whether `RRPP` is a direct lockfile entry or pulled transitively via `geomorph`.
- README quick-start step count and exact wording.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/ROADMAP.md` — Phase 6 goal, plans 06-01–06-03, success criteria
- `.planning/REQUIREMENTS.md` — DEV-01, DEV-02, DEV-03 definitions
- `.planning/PROJECT.md` — architecture, Option A scope, milestone strategy (renv before C refactor)
- `.planning/STATE.md` — Phase 5 complete handoff; 26 warnings still open

### Research & prior plans
- `.planning/research/STACK.md` — renv pin-after-smoke-tests; Windows R 4.6; devtools
- `.planning/research/ARCHITECTURE.md` — Phase 6 = lock working state before C refactor
- `.planning/guimorph-modernization-plan.md` — Plan 2 (renv + reproducible env) original intent
- `.planning/phases/05-analysis-round-trip/05-CONTEXT.md` — GPA/rgl workflow extras for renv scope
- `.planning/phases/04-digitize-workflow/04-CONTEXT.md` — D-10 warnings capture origin; double-click UX

### Validation & quirks source
- `.planning/smoke-test-findings.md` — Phases 1–5 UAT audit log; source for inherent-quirk extraction (not WSL setup docs)

### Package & native build (primary implementation targets)
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION` — Imports list for renv baseline
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R` — `.onLoad` DLL path (`inst/libs/x64/tkogl2.dll`)
- `integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md` — existing compile doc (WSL-centric; must align with D-11 Windows-native primary)
- `integrated-guimorph-development_EOC/Project/tkogl2/cmake/mingw-w64-x86_64.cmake` — existing cross-compile toolchain file
- `README.md` — update per D-06/D-08 (brief quick-start + inherent quirks)

### Test data (local verification, do not commit)
- `zips/Folsom 3D models/C13.1.ply` — sample PLY for post-deploy GUI smoke (D-16)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`tkogl2/BUILD.md`** — MinGW-w64 cmake workflow, dependency table, Tcl stub bootstrap rationale; starting point for Windows-native variant (D-11).
- **`inst/libs/x64/tkogl2.dll` + `glut64.dll`** — deployed MinGW build; contributors can run R workflow before first C rebuild.
- **`DESCRIPTION` Imports** — renv snapshot seed list; no `Suggests` block today — extras (`devtools`, `rgl`, `RRPP`) added explicitly per D-02.
- **`.onLoad` in `rtkogl.R`** — loads `inst/libs/x64/tkogl2.dll`; deploy target for DEV-03.

### Established Patterns
- **`devtools::load_all(".")` from package root** — validated Phases 2–5; quick-start and renv activation cwd.
- **DLL not committed as build artifact** — `build/tkogl2.dll` is throwaway; `inst/libs/x64/` holds runtime copy (deploy workflow bridges the gap).
- **Manual smoke-test documentation** — `.planning/smoke-test-findings.md` append pattern from Phases 4–5; Phase 6 adds structured warning triage (D-17–D-20).

### Integration Points
- **New root `BUILD.md`** — links down to `tkogl2/BUILD.md`, up from README quick-start, references renv restore + deploy script.
- **`scripts/deploy-dll.ps1`** — new artifact; copies `Project/tkogl2/build/tkogl2.dll` → `GUImorphDevelopment/inst/libs/x64/` with backup (D-13–D-15).
- **renv files in `GUImorphDevelopment/`** — `.Rprofile`, `renv.lock`, `renv/activate.R`; `.Rbuildignore` may need renv entries.

</code_context>

<specifics>
## Specific Ideas

- Contributor docs should read like a normal Windows R project — no WSL/UNC path examples as the default happy path.
- README is the right place for "this looks broken but isn't" GUImorph behavior (double-click to place, etc.).
- Verification should match the change: don't force full digitize→GPA for every R doc edit.
- User's WSL setup is maintainer-local; Phase 6 docs target generic Windows contributors.

</specifics>

<deferred>
## Deferred Ideas

- **WSL cross-compile as primary build path** — user's local workflow only; optional appendix at most (D-09, D-11).
- **Fix all 26 `load_all` warnings** — triage HOT only; bulk cleanup deferred unless blocking (D-19).
- **Dual renv lockfiles (WSL R + Windows R)** — out of scope; Windows R only (D-04).
- **CI pipeline for MinGW build** — QA-02 v2 requirement; not Phase 6.
- **Automated smoke test script (QA-01)** — human-targeted verification principle (D-12) sufficient for Phase 6.
- **Commit `.dgt` or analysis fixtures** — still local-only per Phase 4–5 decisions.

</deferred>

---

*Phase: 06-reproducible-dev-environment*
*Context gathered: 2026-06-19*
