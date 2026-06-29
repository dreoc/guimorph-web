# GUImorph Modernization

> **Naming:** **Plan 0–3** = original outline (`.planning/guimorph-modernization-plan.md`). **GSD Phase 1–9** = v1.0 execution roadmap. **GSD Phases 10–15** = v1.1 UI modernization.

## What This Is

GUImorph is an R package for **3D geometric morphometrics** — researchers load PLY mesh specimens, digitize landmarks, curves, and anchors in a Tk GUI, then export coordinates for statistical shape analysis (`geomorph`, `Morpho`, `Rvcg`, `vegan`). This project **fully modernizes** an ~8-year-old research codebase: restore it on current Windows R, migrate stale dependencies, rehabilitate the C/OpenGL engine in place (Option A), and deliver a modern in-app UX on Tk/ttk.

## Core Value

A researcher can open the GUI on Windows R, load a 3D specimen, digitize anatomical landmarks/curves/anchors, run a `geomorph` analysis end-to-end, and maintain the tool via a clean, modular C codebase — all on current toolchains (MSVC build, no Visual Studio IDE required).

## Current State (v1.1 — shipped 2026-06-29)

GUImorph v1.1 delivers the UI modernization milestone on top of v1.0:

- Themed, resizable shell with dev menu gated; consistent ttk widgets
- Direct-manipulation controls: inline spinboxes/sliders, non-modal delete, responsive viewport
- Status bar + progress feedback; non-blocking validation (no modal flow-control gates)
- Guided workflow: placement hints, tab-gating explanations, specimen jump-to
- Keyboard accelerators + single-level undo for placement/delete/drag
- Curve tab fully functional: inline spinboxes, Compute Curves, `.dgt` round-trip, README sync

**Archives:** [v1.1 roadmap](milestones/v1.1-ROADMAP.md) · [v1.1 requirements](milestones/v1.1-REQUIREMENTS.md) · [v1.0 roadmap](milestones/v1.0-ROADMAP.md) · [MILESTONES.md](MILESTONES.md)

<details>
<summary>v1.0 shipped state (2026-06-23)</summary>

- Windows R 4.6+ GUI operational with MSVC-built `tkogl2.dll`
- Digitize workflow: landmarks, curves, anchors, `.dgt` save/reload
- Analysis: landmarks-only GPA + CSV export on geomorph 4.x
- Contributor docs: `BUILD.md`, `renv.lock`, `deploy-dll.ps1`
- C engine: `tcl_init`, `tcl_dispatch`, `tcl_window`, `tcl_state`, `tcl_log`, `marker.c`

</details>

## Next Milestone Goals

TBD — define via `/gsd-new-milestone`. Likely candidates from backlog:

- **999.1** — GPA plot window renders aligned specimens after Compute
- **999.2** — openDgt displays specimen 1 on load (not specimen 2)
- Distribution / plug-and-play packaging (see quick task 260623-l8r assessment)

## Requirements

### Validated

- ✓ Repository cleanup — Plan 0 (`repo-cleanup` branch)
- ✓ Native DLL compiles via MSVC + CMake — `build-msvc/Release/tkogl2.dll`
- ✓ Windows R smoke test — `load_all(".")`, `GUImorph()` opens, PLY load pipeline runs
- ✓ Package load + GUI launch — Phase 2 complete
- ✓ Specimen mesh renders in 3D viewer — `C13.1.ply` visible after load
- ✓ Landmark placement — double-click on canvas to place
- ✓ Digitize workflow — v1.0: landmarks, curves, multi-specimen `.dgt` save/reload
- ✓ Analysis round-trip — v1.0: landmarks-only GPA + CSV on geomorph 4.x
- ✓ Reproducible R environment — v1.0: `renv.lock`, `BUILD.md`, `deploy-dll.ps1`
- ✓ C engine modularization + deduplication + cleanup — v1.0 Phases 7–9

### Validated (v1.1)

- ✓ **Visual chrome & menu cleanup** — UX-MENU-01/02/03 (Phase 10)
- ✓ **Direct-manipulation controls** — UX-CTL-01..04 (Phase 11)
- ✓ **In-GUI feedback & status** — UX-FB-01..03 (Phase 12)
- ✓ **Guided workflow & discoverability** — UX-WF-01..04 (Phase 13)
- ✓ **Keyboard shortcuts & undo** — UX-KEY-01/02 (Phase 14)
- ✓ **Curve tab rehabilitation** — UX-CRV-01/02 (Phase 15)
- ✓ **Constraints** — CON-01/02/03 (no renderer change, `.dgt` round-trip, Windows R 4.6+)

### Active

(None — define next milestone via `/gsd-new-milestone`)

### Out of Scope

- **Option B** — rgl renderer swap (cross-platform via deletion of C engine)
- **Option C** — Shiny/WebGL UI rebuild
- Linux/macOS native port — Option A accepts permanent Windows-only + legacy GL
- Tcl/Tk 9.0 migration — stay on 8.6 stubs for now
- Modern OpenGL core profile / shader pipeline — would be a rewrite
- Full geomorph gmShiny feature parity — migrate only functions GUImorph actually calls
- Visual Studio IDE workflow — replaced by CMake + MSVC Build Tools

## Context

**Architecture (top → bottom):**

1. **R** — `GUImorphDevelopment/` + `tkogl2/R/` (~250 KB): Tk menus, `dgtDataList`, `.dgt` I/O, `geomorph` hooks
2. **Tcl/Tk** — stringly-typed `tcl("add", shape, ...)` protocol in `rtkogl.R`
3. **C/OpenGL** — `tkogl2` DLL: WGL context on Tk widget HWND, fixed-function OpenGL

**Current state:** v1.1 shipped 2026-06-29. Windows R 4.6+ GUI with modern Tk/ttk UX. Known backlog: GPA plot blank (999.1), openDgt specimen order (999.2).

**Milestone strategy:** v1.0 (Phases 1–9) + v1.1 (Phases 10–15) complete. Next milestone TBD via `/gsd-new-milestone`.

## Constraints

- **Platform**: Windows-only for runtime — must use Windows R (not Linux/macOS R)
- **Build**: MSVC primary (`cmake -B build-msvc` on Windows); see `BUILD.md` and `scripts/deploy-dll.ps1`
- **Graphics**: Fixed-function OpenGL + WGL — legacy but retained under Option A
- **Dependencies**: `geomorph` 4.x breaking changes — migrate incrementally with call-site inventory
- **C refactor**: Must preserve `Tkogl2_Init` export and R↔Tcl shape string protocol

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flatten embedded git repo | Single outer repo instead of nested history | ✓ Good — Plan 0 |
| CMake + MSVC over Visual Studio IDE | Broken `.vcxproj`; VS Build Tools + CMake is contributor path | ✓ Good — DLL builds and renders |
| **Option A — rehabilitate C in place** | User chose cheapest path; accepts Windows-only + legacy GL | ✓ Good — v1.0 |
| **Double-click to place landmarks** | Single-click is pick/select; placement is `<Double-Button-1>` | ✓ Good — documented |
| **v1.1: modernize UI in place on Tk/ttk** | Renderer binds C/OpenGL to Tk canvas HWND; framework swap rejected | ✓ Good — v1.1 |
| **v1.1: workflow streamlining allowed** | User OK'd relaxing tab-gating as long as `.dgt` round-trips | ✓ Good — v1.1 |
| Debounced 150ms Configure for GL resize | Prevents resize storm; gates on `e$glBound` | ✓ Good — Phase 11 |
| Single-level undo cleared on nav/load | Prevents stale undo across specimen/file boundaries | ✓ Good — Phase 14 |
| Curve Compute via `.redrawAllCurves` batch path | Unified C protocol; legacy `draw.curves()` not used on Compute | ✓ Good — Phase 15 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

---
*Last updated: 2026-06-29 after v1.1 milestone*
