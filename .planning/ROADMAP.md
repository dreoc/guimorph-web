# Roadmap: GUImorph Modernization

> **Naming:** **GSD Phases 1–9** below are the execution roadmap. The original four-stage outline (**Plan 0–3**) is in `.planning/guimorph-modernization-plan.md`.

## Overview

Full modernization of GUImorph on modern Windows R: validate the MinGW-built native DLL, restore the GUI and digitize workflow, migrate stale `geomorph` APIs, lock a reproducible dev environment, then **rehabilitate the C/OpenGL engine in place** (Option A). Plans 0–1 (repo cleanup + build scaffold) are largely complete; GSD execution continues from runtime validation onward.

## Phases

- [x] **Phase 1: Native Runtime Validation** — Prove `tkogl2.dll` loads and Tcl/OpenGL init works
- [x] **Phase 2: Package Load & GUI Launch** — `load_all` + `GUImorph()` opens the window
- [x] **Phase 3: 3D Viewer Smoke Test** — Load PLY specimen and confirm mesh renders
- [ ] **Phase 4: Digitize Workflow** — Landmarks, curves, `.dgt` save/reload
- [ ] **Phase 5: Analysis Round-Trip** — `geomorph` analysis + API migration
- [ ] **Phase 6: Reproducible Dev Environment** — `renv`, build docs, DLL deploy workflow
- [ ] **Phase 7: C Engine Modularization** — Split `tcl_if` god file into focused modules
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

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 04-03-PLAN.md — Re-enable drawElements curve restore; multi-specimen save/reload round-trip (DGT-03, DGT-04)

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

**Plans**: TBD

Plans:

- [ ] 05-01: Inventory geomorph/Morpho call sites in R sources
- [ ] 05-02: Run first analysis end-to-end on test `.dgt` data
- [ ] 05-03: Migrate remaining breaking API calls

### Phase 6: Reproducible Dev Environment

**Goal**: Document and lock the full build-test-develop cycle before C refactoring.
**Depends on**: Phase 5
**Requirements**: DEV-01, DEV-02, DEV-03
**Success Criteria** (what must be TRUE):

  1. `renv` lockfile restores working R environment from clean install
  2. `BUILD.md` covers WSL build → DLL deploy → Windows R test
  3. New contributor can follow docs and reach working GUI without tribal knowledge

**Plans**: TBD

Plans:

- [ ] 06-01: Initialize `renv` and pin dependencies
- [ ] 06-02: Update BUILD.md with validated deploy workflow
- [ ] 06-03: Add quick-start section to project README

### Phase 7: C Engine Modularization

**Goal**: Split the 5,581-line `tcl_if_ZARF_9.c` god file into maintainable modules without changing behavior.
**Depends on**: Phase 6 (working baseline locked before refactor)
**Requirements**: CENG-01
**Success Criteria** (what must be TRUE):

  1. God file split into dispatch, window/WGL, and state modules
  2. CMake build succeeds; `Tkogl2_Init` export unchanged
  3. GUI opens and loads PLY after refactor (no regression)

**Plans**: TBD

Plans:

- [ ] 07-01: Extract Tcl command dispatch into `tcl_dispatch.c`
- [ ] 07-02: Extract HWND/WGL window setup into `tcl_window.c`
- [ ] 07-03: Extract specimen/model state into `tcl_state.c`; verify smoke test

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
| 4. Digitize Workflow | 1/2 | In Progress|  |
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
- GSD Phase 4 (digitize): **In progress** — 04-01 landmark placement validated (double-click to place; single-click is pick/select only)
- **Open:** 04-02 curves, 04-03 `.dgt` save/reload; capture 26 warnings

**Strategic decision (locked):** Option A — rehabilitate C engine in place (Windows-only, legacy GL). Options B (rgl) and C (Shiny/WebGL) out of scope.

---
*Roadmap created: 2026-06-13*
*Updated: 2026-06-15 — Phase 3 complete; 04-01 validated (landmarks via double-click, not a render bug)*
