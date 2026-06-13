# Roadmap: GUImorph Modernization

## Overview

Restore a working GUImorph on modern Windows R by validating the MinGW-built native DLL, loading the R package, proving the digitize workflow, migrating stale `geomorph` APIs, and documenting a reproducible dev environment. Phases 0–1 (repo cleanup + build scaffold) are largely complete; execution starts at runtime validation.

## Phases

- [ ] **Phase 1: Native Runtime Validation** — Prove `tkogl2.dll` loads and Tcl/OpenGL init works
- [ ] **Phase 2: Package Load & GUI Launch** — `load_all` + `GUImorph()` opens the window
- [ ] **Phase 3: 3D Viewer Smoke Test** — Load PLY specimen and confirm mesh renders
- [ ] **Phase 4: Digitize Workflow** — Landmarks, curves, `.dgt` save/reload
- [ ] **Phase 5: Analysis Round-Trip** — `geomorph` analysis + API migration
- [ ] **Phase 6: Reproducible Dev Environment** — `renv`, build docs, DLL deploy workflow

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
- [ ] 01-01: Deploy build DLL to test location and verify export
- [ ] 01-02: Windows R Tcl load smoke test
- [ ] 01-03: Resolve GLUT/runtime dependency issues if load fails

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
- [ ] 02-01: `load_all` from WSL UNC path (or local copy fallback)
- [ ] 02-02: Wire `inst/libs/x64/tkogl2.dll` to new MinGW build
- [ ] 02-03: Launch `GUImorph()` and capture/fix startup errors

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
- [ ] 03-01: Identify bundled or sample PLY test data
- [ ] 03-02: Load specimen and verify render pipeline
- [ ] 03-03: Fix OpenGL/WGL issues if viewer is blank

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
**Plans**: TBD

Plans:
- [ ] 04-01: Landmark placement workflow
- [ ] 04-02: Curve definition workflow
- [ ] 04-03: `.dgt` save/reload round-trip

### Phase 5: Analysis Round-Trip
**Goal**: Run `geomorph` analysis on exported digitized data; fix breaking API calls.
**Depends on**: Phase 4
**Requirements**: ANAL-01, ANAL-02
**Success Criteria** (what must be TRUE):
  1. Inventory of `geomorph`/`Morpho` functions called by GUImorph is documented
  2. At least one analysis (e.g. GPA, PCA, or plotting) runs on exported coordinates
  3. All identified breaking API calls migrated to CRAN 4.6-compatible code
**Plans**: TBD

Plans:
- [ ] 05-01: Inventory geomorph/Morpho call sites in R sources
- [ ] 05-02: Run first analysis end-to-end on test `.dgt` data
- [ ] 05-03: Migrate remaining breaking API calls

### Phase 6: Reproducible Dev Environment
**Goal**: Document and lock the full build-test-develop cycle for future contributors.
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

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Native Runtime Validation | 0/3 | Not started | - |
| 2. Package Load & GUI Launch | 0/3 | Not started | - |
| 3. 3D Viewer Smoke Test | 0/3 | Not started | - |
| 4. Digitize Workflow | 0/3 | Not started | - |
| 5. Analysis Round-Trip | 0/3 | Not started | - |
| 6. Reproducible Dev Environment | 0/3 | Not started | - |

**Prior work (outside GSD phases):**
- Phase 0 repo cleanup: Complete (2026-06-12)
- Phase 1 build scaffold: Complete — DLL compiles; runtime not yet validated

---
*Roadmap created: 2026-06-13*
