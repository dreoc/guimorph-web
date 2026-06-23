# Requirements: GUImorph Modernization

**Defined:** 2026-06-13
**Core Value:** Researcher can digitize a 3D specimen in the GUI, run `geomorph` analysis end-to-end, and maintain a modular C engine on Windows R.
**Milestone scope:** Full modernization (restore + Option A C rehabilitation)

## v1 Requirements

### Native Build & Runtime

- [x] **BUILD-01**: `tkogl2.dll` builds via CMake + MinGW-w64 from WSL without manual file renames
- [x] **BUILD-02**: Built DLL exports `Tkogl2_Init` (verified via `objdump` or equivalent)
- [x] **RUN-01**: `tcl("load", dll, "Tkogl2")` succeeds in Windows R — ✅ MinGW `build/tkogl2.dll` deployed to `inst/libs/x64/` and loads via `load_all` (2026-06-15)
- [x] **RUN-02**: OpenGL/GLUT runtime dependencies resolve — ✅ GUI opens, PLY load pipeline runs (2026-06-13)

### Package & GUI

- [x] **PKG-01**: `devtools::load_all(".")` loads GUImorph from source via WSL UNC — ✅ 2026-06-13 (26 warnings to triage)
- [x] **PKG-02**: `.onLoad` in `rtkogl.R` loads `inst/libs/x64/tkogl2.dll` without fatal error — ✅ 2026-06-13
- [x] **GUI-01**: `GUImorph()` opens a Tcl/Tk window — ✅ 2026-06-13
- [x] **GUI-02**: User can load a PLY specimen mesh and see it rendered in the 3D viewer — ✅ 2026-06-13 (`C13.1.ply` mesh visible)

### Digitize Workflow

- [x] **DGT-01**: User can place landmarks on the loaded specimen — ✅ 2026-06-15 (double-click on canvas to place; landmarks visible after placement)
- [x] **DGT-02**: User can define curves (semi-landmark splines) on the specimen — ✅ 2026-06-15 (legacy 3-landmark curve bind on C13.1.ply; 1×3 ID matrix; Fit smoke pass)
- [x] **DGT-03**: User can save digitized data to a `.dgt` file — ✅ 2026-06-15 (2-specimen save `test_fresh.dgt`; Curve=1 + LM3=3 ×2)
- [x] **DGT-04**: Saved `.dgt` file reloads with landmarks/curves intact — ✅ 2026-06-15 (same-session `openDgt` reload after Surface=0 + queryFromR fixes)

### Analysis Integration

- [x] **ANAL-01**: Exported digitized coordinates load into at least one `geomorph` analysis function without error — ✅ 2026-06-19 (landmarks-only GPA via `gpagen` on `test_fresh.dgt`, 2 specimens; CSV export via `two.d.array`)
- [x] **ANAL-02**: Breaking `geomorph`/`Morpho` API calls identified and migrated to CRAN 4.6-compatible signatures — ✅ 2026-06-19 (inventory in `05-INVENTORY.md`; HOT-path fixes in 05-02; deferred sites documented)
- [x] **ANAL-03**: Deprecated functions replaced per geomorph 4.x guidance (`procD.lm`/RRPP, `gm.prcomp`, etc.) — ✅ 2026-06-19 (hot-path `gpagen`/`plotAllSpecimens`/`two.d.array` migrated; vendored procD deferred per D-10)

### Developer Environment

- [x] **DEV-01**: `renv` lockfile pins R package versions with documented restore instructions — ✅ 2026-06-19 (`renv.lock`, `.Rprofile`, `renv/` committed; `scripts/init-renv.R`)
- [x] **DEV-02**: `BUILD.md` documents full build-deploy-test cycle (MSVC build → deploy DLL → Windows R test) — ✅ 2026-06-19 (Phase 6 UAT)
- [x] **DEV-03**: Workflow documented for swapping new `tkogl2.dll` into `inst/libs/x64/` — ✅ 2026-06-19 (`scripts/deploy-dll.ps1`; MSVC primary as of 2026-06-23)

### C Engine Rehabilitation (Option A)

- [x] **CENG-01**: `tcl_if_ZARF_9.c` split into separate modules (dispatch, window/WGL, state, log, init) with no behavior change — validated 2026-06-21 (Phase 7 final smoke)
- [x] **CENG-02**: Dot and anchor implementations unified into shared marker code — ✅ 2026-06-22 (marker.c UAT; anchor .dgt round-trip)
- [x] **CENG-03**: Numbered globals (`GBL_PTR_*_1..N`) replaced with arrays; capacity limits documented — ✅ 2026-06-22 (Phase 9 plan 09-01)
- [x] **CENG-04**: Debug cruft removed (`MAKE_INERT`, `if(0)` toggles, pervasive `printf` tracing) — ✅ 2026-06-22 (Phase 9 plans 09-02/09-03)
- [x] **CENG-05**: Post-rehabilitation DLL passes full digitize smoke test (no regression vs Phase 4 baseline) — ✅ 2026-06-22 (Fixtures A+B UAT)

## v2 Requirements

Deferred until v1 milestone ships.

### Platform & Toolchain

- **PLAT-01**: Cross-platform rendering evaluation (Option B — rgl swap)
- **PLAT-02**: Tcl/Tk 9.0 migration evaluation
- **QA-01**: Automated smoke test script (R + native load)
- **QA-02**: CI pipeline for MinGW DLL build

## Out of Scope

| Feature | Reason |
|---------|--------|
| rgl renderer swap (Option B) | User chose Option A — rehabilitate C in place |
| Shiny/WebGL UI rebuild (Option C) | Rejected for this milestone |
| Linux/macOS native binary | Option A accepts Windows-only |
| Modern OpenGL core profile | Rewrite, not rehabilitation |
| Full `geomorph` feature parity audit | Migrate only functions actually called by GUImorph |
| Visual Studio IDE workflow | Replaced by CMake/MinGW; `.vcxproj` kept as reference only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BUILD-01 | Phase 1 | ✓ Validated 2026-06-13 |
| BUILD-02 | Phase 1 | ✓ Validated 2026-06-13 |
| RUN-01 | Phase 1 | ✓ MinGW DLL deployed 2026-06-15 |
| RUN-02 | Phase 1 | ✓ Validated 2026-06-13 |
| PKG-01 | Phase 2 | ✓ Validated 2026-06-13 |
| PKG-02 | Phase 2 | ✓ Validated 2026-06-13 |
| GUI-01 | Phase 2 | ✓ Validated 2026-06-13 |
| GUI-02 | Phase 3 | ✓ Validated 2026-06-13 |
| DGT-01 | Phase 4 | ✓ Validated 2026-06-15 — double-click to place |
| DGT-02 | Phase 4 | ✓ Validated 2026-06-15 — legacy curve bind + Fit smoke |
| DGT-03 | Phase 4 | ✓ Validated 2026-06-15 — multi-specimen save |
| DGT-04 | Phase 4 | ✓ Validated 2026-06-15 — same-session reload |
| ANAL-01 | Phase 5 | ✓ Validated 2026-06-19 — gpagen + CSV save on test_fresh.dgt |
| ANAL-02 | Phase 5 | ✓ Validated 2026-06-19 — inventory + HOT-path migration closure (05-03) |
| ANAL-03 | Phase 5 | ✓ Validated 2026-06-19 — hot-path CRAN APIs; vendored procD deferred (D-10) |
| DEV-01 | Phase 6 | ✓ Validated 2026-06-19 — renv.lock committed; restore verified |
| DEV-02 | Phase 6 | ✓ Validated 2026-06-19 — BUILD.md contributor guide UAT |
| DEV-03 | Phase 6 | ✓ Validated 2026-06-23 — deploy-dll.ps1 MSVC primary + -Source param |
| CENG-01 | Phase 7 | ✓ Validated 2026-06-21 — five-module layout; digitize round-trip smoke passed |
| CENG-02 | Phase 8 | ✓ Validated 2026-06-22 — marker.c unified; anchor .dgt round-trip |
| CENG-03 | Phase 9 | ✓ Validated 2026-06-22 — GBL_PTR arrays with capacity #defines |
| CENG-04 | Phase 9 | ✓ Validated 2026-06-22 — debug cruft removed; simpleLog only |
| CENG-05 | Phase 9 | ✓ Validated 2026-06-22 — Fixtures A+B full regression UAT |

**Coverage:**
- v1 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-13*
*Last updated: 2026-06-23 — all v1 requirements validated (milestone audit tech-debt sync)*
