# Roadmap: GUImorph Modernization

> **Naming:** **GSD Phases 1–9** below are the execution roadmap. The original four-stage outline (**Plan 0–3**) is in `.planning/guimorph-modernization-plan.md`.

## Overview

Full modernization of GUImorph on modern Windows R: validate the MinGW-built native DLL, restore the GUI and digitize workflow, migrate stale `geomorph` APIs, lock a reproducible dev environment, then **rehabilitate the C/OpenGL engine in place** (Option A). Plans 0–1 (repo cleanup + build scaffold) are largely complete; GSD execution continues from runtime validation onward.

## Phases

- [x] **Phase 1: Native Runtime Validation** — Prove `tkogl2.dll` loads and Tcl/OpenGL init works
- [x] **Phase 2: Package Load & GUI Launch** — `load_all` + `GUImorph()` opens the window
- [x] **Phase 3: 3D Viewer Smoke Test** — Load PLY specimen and confirm mesh renders
- [x] **Phase 4: Digitize Workflow** — Landmarks, curves, `.dgt` save/reload
- [x] **Phase 5: Analysis Round-Trip** — `geomorph` analysis + API migration
- [ ] **Phase 6: Reproducible Dev Environment** — `renv`, build docs, DLL deploy workflow
- [x] **Phase 7: C Engine Modularization** — Split `tcl_if` god file into focused modules
- [ ] **Phase 8: C Engine Deduplication** — Unify dot/anchor implementations
- [ ] **Phase 9: C Engine Cleanup & Validation** — Globals, debug removal, regression test

## Phase Details

### Phase 1: Native Runtime Validation
**Goal**: Confirm the MinGW-built `tkogl2.dll` loads in Windows R and Tcl stubs initialize correctly.
**Depends on**: Nothing (build scaffold from prior session)
**Requirements**: BUILD-01, BUILD-02, RUN-01, RUN-02
**Success Criteria** (what must be TRUE):
  1. `cmake --build build` produces `tkogl2.dll` without errors
  2. `tcl("load", dll_path, "Tkogl2")` returns empty string (success) in Windows R
  3. No missing-DLL or stub-init failure on load
  4. `Tkogl2_Init` export confirmed on the deployed DLL
**Plans**: TBD

Plans:
- [x] 01-01: Deploy build DLL to test location and verify export
- [x] 01-02: Windows R Tcl load smoke test
- [x] 01-03: Resolve GLUT/runtime dependency issues if load fails

### Phase 2: Package Load & GUI Launch
**Goal**: Load GUImorph from source and open the main application window.
**Depends on**: Phase 1
**Requirements**: PKG-01, PKG-02, GUI-01
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. `devtools::load_all(".")` completes without fatal errors
  2. Console shows tkogl2 load confirmation from `.onLoad`
  3. `GUImorph()` opens "3D GUImorph" Tcl/Tk window
  4. Window remains responsive (no immediate crash)
**Plans**: TBD

Plans:
- [x] 02-01: `load_all` from WSL UNC path (or local copy fallback)
- [x] 02-02: Wire `inst/libs/x64/tkogl2.dll` to new MinGW build
- [x] 02-03: Launch `GUImorph()` and capture/fix startup errors

### Phase 3: 3D Viewer Smoke Test
**Goal**: Verify the OpenGL renderer displays a specimen mesh.
**Depends on**: Phase 2
**Requirements**: GUI-02
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. User can open/load a sample PLY file from the GUI
  2. Mesh renders in the 3D viewer (not blank/black)
  3. Basic camera navigation works (rotate/zoom if exposed in UI)
**Plans**: TBD

Plans:
- [x] 03-01: Identify bundled or sample PLY test data
- [x] 03-02: Load specimen and verify render pipeline
- [x] 03-03: Fix OpenGL/WGL issues if viewer is blank

### Phase 4: Digitize Workflow
**Goal**: Complete landmark/curve digitization and `.dgt` persistence.
**Depends on**: Phase 3
**Requirements**: DGT-01, DGT-02, DGT-03, DGT-04
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. User can place named landmarks on the specimen
  2. User can define curves on the specimen surface
  3. Digitized session saves to `.dgt` file
  4. Reloading `.dgt` restores landmarks and curves
**Plans**: 3 plans (2 executable: 04-02, 04-03)

Plans:
- [x] 04-01: Landmark placement workflow

**Wave 1**
- [x] 04-02-PLAN.md — Fix curve slot init; validate legacy 3-click curve bind + Fit smoke (DGT-02)

**Wave 2**
- [x] 04-03-PLAN.md — Re-enable drawElements curve restore; multi-specimen save/reload round-trip (DGT-03, DGT-04)

**Cross-cutting constraints:**
- Fix only digitize-path blockers (crashes, silent data loss) — UX quirks documented, not code-fixed (D-12)
- Manual Windows R GUI UAT required — no automated Tk/OpenGL test harness
- Multi-specimen `.dgt` save/reload in same session only (D-08, D-09, D-16)

### Phase 5: Analysis Round-Trip
**Goal**: Run `geomorph` analysis on exported digitized data; fix breaking API calls.
**Depends on**: Phase 4
**Requirements**: ANAL-01, ANAL-02, ANAL-03
**Success Criteria** (what must be TRUE):
  1. Inventory of `geomorph`/`Morpho` functions called by GUImorph is documented
  2. At least one analysis (e.g. GPA via `gpagen`, PCA via `gm.prcomp`) runs on exported coordinates
  3. All deprecated API calls migrated (`procD.lm`/RRPP, etc.)
**Plans**: 3 plans

Plans:
- [ ] 05-01-PLAN.md — Inventory geomorph/Morpho call sites; HOT vs DEFERRED classification (ANAL-02)

**Wave 1**
- [x] 05-01-PLAN.md — Grep R sources → `05-INVENTORY.md` (ANAL-02)

**Wave 2**
- [x] 05-02-PLAN.md — Fix GPA hot-path APIs; GUI UAT on `test_fresh.dgt` Compute→Plot→Save (ANAL-01) — **complete 2026-06-19**

**Wave 3**
- [x] 05-03-PLAN.md — Close hot-path migration; mark ANAL-02/03 complete (ANAL-03) — **complete 2026-06-19**

**Cross-cutting constraints:**
- Landmarks-only GPA (3 LM × 2 specimens); sliding checkboxes OFF (D-01)
- GPA hot path first; vendored `geomorph.support.code.r` deferred (D-10)
- Manual Windows R GUI UAT; append to smoke-test-findings.md (D-13)
- Reuse Phase 4 `test_fresh.dgt`; same-session reload (D-06, D-07)

### Phase 6: Reproducible Dev Environment
**Goal**: Document and lock the full build-test-develop cycle before C refactoring.
**Depends on**: Phase 5
**Requirements**: DEV-01, DEV-02, DEV-03
**Success Criteria** (what must be TRUE):
  1. `renv` lockfile restores working R environment from clean install
  2. `BUILD.md` covers WSL build → DLL deploy → Windows R test
  3. New contributor can follow docs and reach working GUI without tribal knowledge
**Plans**: 3 plans

Plans:
- [ ] 06-01-PLAN.md — Initialize renv in GUImorphDevelopment/; snapshot deps; warning baseline + HOT triage (DEV-01)

**Wave 1**
- [ ] 06-01-PLAN.md — renv lockfile, scaffold, restore verification checkpoint (DEV-01)

**Wave 2**
- [ ] 06-02-PLAN.md — Root BUILD.md, deploy-dll.ps1, tkogl2/BUILD.md restructure; deploy UAT checkpoint (DEV-02, DEV-03)

**Wave 3**
- [ ] 06-03-PLAN.md — README quick-start + Known behavior quirks linking to BUILD.md (DEV-02)

**Cross-cutting constraints:**
- renv restore on Windows R only (D-04); WSL not contributor default (D-09)
- Windows-native MSYS2 MinGW primary build path (D-11)
- Warning triage HOT only after renv baseline (D-19)
- deploy-dll.ps1: validate source, repo-root paths, backup before swap (D-14)

### Phase 7: C Engine Modularization
**Goal**: Split the 5,581-line `tcl_if_ZARF_9.c` god file into maintainable modules without changing behavior.
**Depends on**: Phase 6 (working baseline locked before refactor)
**Requirements**: CENG-01
**Success Criteria** (what must be TRUE):
  1. God file split into dispatch, window/WGL, and state modules
  2. CMake build succeeds; `Tkogl2_Init` export unchanged
  3. GUI opens and loads PLY after refactor (no regression)
**Plans**: 3 plans

Plans:

**Wave 1**
- [x] 07-01-PLAN.md — Backup pre-Phase-7 DLL; extract Tcl handlers + draw functions → `tcl_dispatch.c/h`; incremental CMake + BUILD.md (CENG-01)

**Wave 2**
- [x] 07-02-PLAN.md — Extract HWND/WGL + `setWindow` → `tcl_window.c/h`; per-plan smoke (CENG-01)

**Wave 3**
- [x] 07-03-PLAN.md — Extract state → `tcl_state.c`, logging → `tcl_log.c`, init → `tcl_init.c`; remove god file from CMake; final digitize round-trip (CENG-01)

**Cross-cutting constraints:**
- Incremental CMake per plan — god file stays until 07-03 (D-11)
- No logic changes in dot/curve/ogl modules (D-12)
- Manual Windows R GUI UAT; append to smoke-test-findings.md (D-07)
- Per-plan smoke: build + Tkogl2_Init + GUImorph + C13.1.ply + double-click landmark (D-05)
- Final smoke 07-03 only: full digitize round-trip save/reload (D-06)

### Phase 8: C Engine Deduplication
**Goal**: Collapse the duplicated dot/anchor implementations acknowledged in source comments.
**Depends on**: Phase 7
**Requirements**: CENG-02
**Success Criteria** (what must be TRUE):
  1. Shared marker struct/functions replace parallel dot/anchor code paths
  2. Landmark and anchor placement both work in GUI
  3. Existing `.dgt` files from Phase 4 baseline reload correctly
**Plans**: TBD

Plans:
- [ ] 08-01: Characterize dot vs anchor behavioral differences
- [ ] 08-02: Implement unified `marker.c` with type discriminator
- [ ] 08-03: Remove duplicated functions; verify digitize round-trip

### Phase 9: C Engine Cleanup & Validation
**Goal**: Replace numbered globals, remove debug cruft, and prove no regression across full workflow.
**Depends on**: Phase 8
**Requirements**: CENG-03, CENG-04, CENG-05
**Success Criteria** (what must be TRUE):
  1. `GBL_PTR_*_1..N` replaced with arrays; limits documented in headers
  2. `MAKE_INERT`, `if(0)` debug toggles, and pervasive `printf` tracing removed
  3. Full workflow passes: load PLY → digitize → save `.dgt` → analyze — identical to Phase 4–5 baseline
**Plans**: TBD

Plans:
- [ ] 09-01: Replace numbered globals with arrays; document capacity limits
- [ ] 09-02: Remove debug cruft and unsafe macros where practical
- [ ] 09-03: Full regression smoke test; update BUILD.md for new file layout

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → … → 9

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Native Runtime Validation | 3/3 | Complete | 2026-06-15 |
| 2. Package Load & GUI Launch | 3/3 | Complete | 2026-06-15 |
| 3. 3D Viewer Smoke Test | 3/3 | Complete | 2026-06-15 |
| 4. Digitize Workflow | 3/3 | Complete | 2026-06-15 |
| 5. Analysis Round-Trip | 0/3 | Not started | - |
| 6. Reproducible Dev Environment | 0/3 | Not started | - |
| 7. C Engine Modularization | 0/3 | Not started | - |
| 8. C Engine Deduplication | 0/3 | Not started | - |
| 9. C Engine Cleanup & Validation | 0/3 | Not started | - |

**Prior work (outside GSD phases):**
- Plan 0 repo cleanup: Complete (2026-06-12)
- Plan 1 (compile): Complete — validated 2026-06-13
- GSD Phase 1 (runtime): **Complete** — MinGW `build/tkogl2.dll` deployed to `inst/libs/x64/`, `Tkogl2_Init` verified, Windows R load confirmed (2026-06-15)
- GSD Phase 2 (package/GUI): **Complete** — `load_all`, MinGW DLL wired, startup OOB fixed (`activeDataList` guards) — 2026-06-15
- GSD Phase 3 (viewer): **Complete** — mesh visible (`C13.1.ply`); landmark placement confirmed during viewer use (2026-06-15)
- GSD Phase 4 (digitize): **Complete** — DGT-01–04 validated; openDgt reload fixes for Surface=0 + queryFromR (2026-06-15)
- **Open:** capture 26 warnings (D-10); multi-specimen curve overlay documented for future work

**Strategic decision (locked):** Option A — rehabilitate C engine in place (Windows-only, legacy GL). Options B (rgl) and C (Shiny/WebGL) out of scope.

## Backlog

Parking-lot items (999.x) — not sequenced; promote with `/gsd-review-backlog` when ready.

### Phase 999.1: GPA plot window opens but nothing rendered (BACKLOG)

**Goal:** Fix Plot Aligned Specimens so aligned landmark geometry is visible after Compute.
**Source:** Phase 5 UAT (2026-06-19) — rgl window opens; canvas appears empty.
**Context:** `plotspecs()` → `geomorph::plotAllSpecimens` on 3×3×2 gpagen `$coords`; Compute + Save CSV work. Suspect rgl/Tk event-loop interaction, plot_param sizing, or geomorph 4.x 3D backend on Windows R 4.6.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with `/gsd-review-backlog` when ready)

### Phase 999.2: openDgt shows second specimen first on load (BACKLOG)

**Goal:** After Load DGT File, GUI should display specimen 1 without Next→Previous workaround.
**Source:** Phase 5 UAT (2026-06-19) — multi-specimen `test_fresh.dgt`; `currImgId` is 1 but viewer shows specimen 2 until user navigates Next then Previous.
**Context:** `drawElements` loads all specimens sequentially; C display ends on last loaded. Attempted fix (`showPicture(e)` after openDgt) did not resolve in user retest.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with `/gsd-review-backlog` when ready)

---
*Roadmap created: 2026-06-13*
*Updated: 2026-06-15 — Phase 4 complete (DGT-01–04 validated)*
