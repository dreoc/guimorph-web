# GUImorph Modernization

## What This Is

GUImorph is an R package for **3D geometric morphometrics** — researchers load PLY mesh specimens, digitize landmarks, curves, and anchors in a Tk GUI, then export coordinates for statistical shape analysis (`geomorph`, `Morpho`, `Rvcg`, `vegan`). This project modernizes an ~8-year-old research codebase (student-era C/OpenGL engine + R/Tk app) so it builds, runs, and can be maintained on current Windows R without Visual Studio.

## Core Value

A researcher can open the GUI on Windows R, load a 3D specimen, digitize anatomical landmarks/curves, and run a `geomorph` analysis end-to-end — proving the tool still works and is worth further investment.

## Requirements

### Validated

- ✓ Repository cleanup — Phase 0 (`repo-cleanup` branch): flattened embedded git, comprehensive `.gitignore`, purged VS caches/diagsession (~3 GB → ~55 MB)
- ✓ Native DLL compiles via MinGW-w64 + CMake — Phase 1 scaffold: `tkogl2.dll` exports `Tkogl2_Init` from ZARF_9 sources
- ✓ Windows R 4.6 toolchain available — `winget install RProject.R`, CRAN deps installed to user library

### Active

- [ ] Runtime smoke test: new `tkogl2.dll` loads via Tcl without error
- [ ] GUImorph package loads from source (`devtools::load_all`) and opens "3D GUImorph" window
- [ ] Reproducible R environment (`renv`) with documented dependency versions
- [ ] Digitize workflow: load PLY → place landmarks/curves → export `.dgt`
- [ ] Analysis round-trip: exported data runs at least one `geomorph` analysis call
- [ ] Migrate breaking `geomorph`/`Morpho` API calls to current CRAN versions

### Out of Scope

- Phase 3 strategic rewrite (renderer swap to `rgl`, Shiny/WebGL rebuild, or C engine rehabilitation) — deferred until GUI works and value is proven
- Linux/macOS native port — C engine is Windows HWND/WGL-only; cross-platform requires renderer replacement (v2)
- Tcl/Tk 9.0 migration — stay on 8.6 stubs until GUI is stable
- Automated test suite / CI — nice-to-have after manual smoke tests pass
- Refactoring `tcl_if_ZARF_9.c` god file — maintenance burden accepted for v1

## Context

**Architecture (top → bottom):**

1. **R** — `GUImorphDevelopment/` + `tkogl2/R/` (~250 KB): Tk menus, `dgtDataList`, `.dgt` I/O, `geomorph` hooks
2. **Tcl/Tk** — stringly-typed `tcl("add", shape, ...)` protocol in `rtkogl.R`
3. **C/OpenGL** — `tkogl2` DLL: WGL context on Tk widget HWND, fixed-function OpenGL (deprecated but functional on Windows)

**Prior work (see `.planning/guimorph-modernization-plan.md`, `modernization-session-handoff.md`, `r-guimorph-setup-findings.md`):**

- Original build broken: `.vcxproj` referenced pre-rename filenames (`curve.c` vs `curve_ZARF_9.c`)
- Phase 1 adapted for Cursor/WSL: MinGW cross-compile, `tcl_stub_bootstrap.c`, GLUT shim — see `Project/tkogl2/BUILD.md`
- Windows R deps on CRAN 4.6: geomorph 4.1.0, Morpho 2.13, Rvcg 0.25, tcltk2 1.6.1, vegan 2.7-5
- GUImorph package never loaded in session — placeholder zip path used; next step is `devtools::load_all(".")`

**Known risks:** WSL UNC path I/O flakiness; Tcl stub ABI via bootstrap; GLUT runtime (`glut64.dll`); R 4.6 vs ~2020 package code.

## Constraints

- **Platform**: Windows-only for runtime — must use Windows R, not WSL/Linux R
- **Build**: MinGW-w64 cross-compile from WSL (no Visual Studio IDE dependency)
- **Graphics**: Fixed-function OpenGL + WGL — legacy but required for current C engine
- **Dependencies**: `geomorph` had breaking API changes since 2020 — migrate incrementally
- **Scope**: Restore working tool first; strategic modernization is a separate milestone

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flatten embedded git repo | Single outer repo (`dreoc/GUImorph`) instead of nested history | ✓ Good — Phase 0 |
| MinGW + CMake over Visual Studio | User works in Cursor/WSL; VS project was broken anyway | ✓ Good — DLL builds |
| Untrack build outputs, keep vendored stubs | Reduce repo bloat; keep `tclstub`/`glut` libs needed to link | ✓ Good |
| Defer Phase 3 renderer/UI fork | Can't choose rehabilitate vs `rgl` vs Shiny until GUI runs | — Pending |
| Skip formal codebase map | Detailed architecture review already in `.planning/` | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-13 after GSD project initialization*
