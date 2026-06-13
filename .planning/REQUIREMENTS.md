# Requirements: GUImorph Modernization

**Defined:** 2026-06-13
**Core Value:** Researcher can digitize a 3D specimen in the GUI and run `geomorph` analysis end-to-end on Windows R.

## v1 Requirements

### Native Build & Runtime

- [ ] **BUILD-01**: `tkogl2.dll` builds via CMake + MinGW-w64 from WSL without manual file renames
- [ ] **BUILD-02**: Built DLL exports `Tkogl2_Init` (verified via `objdump` or equivalent)
- [ ] **RUN-01**: `tcl("load", dll, "Tkogl2")` succeeds in Windows R with no error string returned
- [ ] **RUN-02**: OpenGL/GLUT runtime dependencies resolve (no missing-DLL crash on load)

### Package & GUI

- [ ] **PKG-01**: `devtools::load_all(".")` loads GUImorph from source via WSL UNC or local copy path
- [ ] **PKG-02**: `.onLoad` in `rtkogl.R` loads `inst/libs/x64/tkogl2.dll` without warning
- [ ] **GUI-01**: `GUImorph()` opens a Tcl/Tk window titled "3D GUImorph"
- [ ] **GUI-02**: User can load a PLY specimen mesh and see it rendered in the 3D viewer

### Digitize Workflow

- [ ] **DGT-01**: User can place landmarks on the loaded specimen
- [ ] **DGT-02**: User can define curves (semi-landmark splines) on the specimen
- [ ] **DGT-03**: User can save digitized data to a `.dgt` file
- [ ] **DGT-04**: Saved `.dgt` file reloads with landmarks/curves intact

### Analysis Integration

- [ ] **ANAL-01**: Exported digitized coordinates load into at least one `geomorph` analysis function without error
- [ ] **ANAL-02**: Breaking `geomorph`/`Morpho` API calls identified and migrated to CRAN 4.6-compatible signatures

### Developer Environment

- [ ] **DEV-01**: `renv` lockfile pins R package versions with documented restore instructions
- [ ] **DEV-02**: `BUILD.md` documents full build-deploy-test cycle (WSL build → copy DLL → Windows R test)
- [ ] **DEV-03**: Workflow documented for swapping new `build/tkogl2.dll` into `inst/libs/x64/`

## v2 Requirements

Deferred until v1 milestone ships.

### Strategic Modernization

- **STRAT-01**: Choose Phase 3 direction — rehabilitate C / swap to `rgl` / rebuild Shiny+WebGL UI
- **STRAT-02**: Cross-platform rendering path (if renderer swapped)
- **STRAT-03**: Tcl/Tk 9.0 migration evaluation

### Quality & Automation

- **QA-01**: Automated smoke test script (R + native load)
- **QA-02**: CI pipeline for MinGW DLL build

## Out of Scope

| Feature | Reason |
|---------|--------|
| Linux/macOS native binary | WGL/HWND engine is Windows-only; needs renderer rewrite |
| `tcl_if_ZARF_9.c` refactor | Accept technical debt for v1; 5,581-line god file still works if build runs |
| Shiny/WebGL UI rebuild | Phase 3 Option C — deferred strategic decision |
| Full `geomorph` feature parity audit | Migrate only functions actually called by GUImorph |
| Visual Studio IDE workflow | Replaced by CMake/MinGW; `.vcxproj` kept as reference only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BUILD-01 | Phase 1 | Pending |
| BUILD-02 | Phase 1 | Pending |
| RUN-01 | Phase 1 | Pending |
| RUN-02 | Phase 1 | Pending |
| PKG-01 | Phase 2 | Pending |
| PKG-02 | Phase 2 | Pending |
| GUI-01 | Phase 2 | Pending |
| GUI-02 | Phase 3 | Pending |
| DGT-01 | Phase 4 | Pending |
| DGT-02 | Phase 4 | Pending |
| DGT-03 | Phase 4 | Pending |
| DGT-04 | Phase 4 | Pending |
| ANAL-01 | Phase 5 | Pending |
| ANAL-02 | Phase 5 | Pending |
| DEV-01 | Phase 6 | Pending |
| DEV-02 | Phase 6 | Pending |
| DEV-03 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-13*
*Last updated: 2026-06-13 after roadmap creation*
