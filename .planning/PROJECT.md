# GUImorph Modernization

> **Naming:** **Plan 0–3** = original outline (`.planning/guimorph-modernization-plan.md`). **GSD Phase 1–9** = execution roadmap (`.planning/ROADMAP.md`).

## What This Is

GUImorph is an R package for **3D geometric morphometrics** — researchers load PLY mesh specimens, digitize landmarks, curves, and anchors in a Tk GUI, then export coordinates for statistical shape analysis (`geomorph`, `Morpho`, `Rvcg`, `vegan`). This project **fully modernizes** an ~8-year-old research codebase: restore it on current Windows R, migrate stale dependencies, and **rehabilitate the C/OpenGL engine in place** (Option A) for long-term maintainability without replacing the renderer.

## Core Value

A researcher can open the GUI on Windows R, load a 3D specimen, digitize anatomical landmarks/curves, run a `geomorph` analysis end-to-end, and maintain the tool via a clean, modular C codebase — all on current toolchains without Visual Studio.

## Requirements

### Validated

- ✓ Repository cleanup — Plan 0 (`repo-cleanup` branch): flattened embedded git, comprehensive `.gitignore`, purged VS caches/diagsession (~3 GB → ~55 MB)
- ✓ Native DLL compiles via MinGW-w64 + CMake — validated 2026-06-13: `build/tkogl2.dll` (883 KB PE32+ x64), exports `Tkogl2_Init`
- ✓ MinGW DLL deployed — 2026-06-15: `build/tkogl2.dll` → `inst/libs/x64/tkogl2.dll`, `Tkogl2_Init` verified, Windows R load confirmed
- ✓ Windows R smoke test — 2026-06-13: `load_all(".")`, `GUImorph()` opens, PLY load pipeline runs (`C13.1.ply`); now running MinGW build in `inst/libs/x64/`
- ✓ Windows R 4.6 toolchain available — `winget install RProject.R`, CRAN deps installed to user library
- ✓ Package load + GUI launch — 2026-06-13; Phase 2 complete 2026-06-15 (MinGW DLL, startup OOB fix)
- ✓ Specimen mesh renders in 3D viewer — 2026-06-13: `C13.1.ply` artifact **visible** after load (user confirmed)
- ✓ PLY load pipeline — 2026-06-13: file found, `add specimen` invoked
- ✓ Landmark placement on specimen — 2026-06-15: landmarks **visible** after placement; requires **double-click** on canvas (single-click is pick/select only, not placement)

### Active

- [ ] Reproducible R environment (`renv`) with documented dependency versions
- [ ] Digitize workflow: load PLY → place landmarks/curves → export `.dgt`
- [ ] Analysis round-trip: exported data runs at least one `geomorph` analysis call
- [ ] Migrate breaking `geomorph`/`Morpho` API calls to current CRAN versions
- [ ] Split `tcl_if_ZARF_9.c` god file into focused modules (dispatch, window, state)
- [ ] Unify duplicated dot/anchor C implementations
- [ ] Replace numbered globals (`GBL_PTR_*_1..N`) with arrays; document capacity limits
- [ ] Remove debug cruft (`MAKE_INERT`, pervasive `printf`/`if(0)` toggles)

### Out of Scope

- **Option B** — rgl renderer swap (cross-platform via deletion of C engine)
- **Option C** — Shiny/WebGL UI rebuild
- Linux/macOS native port — Option A accepts permanent Windows-only + legacy GL
- Tcl/Tk 9.0 migration — stay on 8.6 stubs for this milestone
- Modern OpenGL core profile / shader pipeline — would be a rewrite, not rehabilitation
- Full geomorph gmShiny feature parity — migrate only functions GUImorph actually calls
- Visual Studio IDE workflow — replaced by CMake/MinGW; `.vcxproj` kept as reference only

## Context

**Architecture (top → bottom):**

1. **R** — `GUImorphDevelopment/` + `tkogl2/R/` (~250 KB): Tk menus, `dgtDataList`, `.dgt` I/O, `geomorph` hooks
2. **Tcl/Tk** — stringly-typed `tcl("add", shape, ...)` protocol in `rtkogl.R`
3. **C/OpenGL** — `tkogl2` DLL: WGL context on Tk widget HWND, fixed-function OpenGL

**Milestone strategy:** Phases 1–6 restore and de-risk (runtime → GUI → digitize → analyze → renv). Phases 7–9 rehabilitate the C engine behind the same DLL interface. Option A chosen over rgl/Shiny for lowest cost while keeping the custom renderer.

**Prior work:** See `.planning/guimorph-modernization-plan.md`, `modernization-session-handoff.md`, `r-guimorph-setup-findings.md`, `.planning/research/`.

## Constraints

- **Platform**: Windows-only for runtime — must use Windows R, not WSL/Linux R
- **Build**: MinGW-w64 cross-compile from WSL (no Visual Studio IDE dependency)
- **Graphics**: Fixed-function OpenGL + WGL — legacy but retained under Option A
- **Dependencies**: `geomorph` 4.x breaking changes — migrate incrementally with call-site inventory
- **C refactor**: Must preserve `Tkogl2_Init` export and R↔Tcl shape string protocol

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flatten embedded git repo | Single outer repo (`dreoc/GUImorph`) instead of nested history | ✓ Good — Plan 0 |
| MinGW + CMake over Visual Studio | User works in Cursor/WSL; VS project was broken anyway | ✓ Good — DLL builds |
| **Option A — rehabilitate C in place** | User chose cheapest path; accepts Windows-only + legacy GL | — Pending |
| Skip formal codebase map | Detailed architecture review already in `.planning/` | ✓ Good |
| Full modernization milestone | Includes C rehab (Phases 7–9), not just "get it running" | — Pending |
| Reject rgl/Shiny swap (Options B/C) | Explicit user choice of Option A | — Pending |
| **Double-click to place landmarks** | Single-click runs pick/select (`set dot selected`); placement is `<Double-Button-1>` → `addDot` | ✓ Good — documented 2026-06-15 |

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
*Last updated: 2026-06-15 after landmark placement validated (double-click UX)*
