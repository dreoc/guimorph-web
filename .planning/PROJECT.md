# GUImorph Modernization

> **Naming:** **Plan 0–3** = original outline (`.planning/guimorph-modernization-plan.md`). **GSD Phase 1–9** = execution roadmap (`.planning/ROADMAP.md`).

## What This Is

GUImorph is an R package for **3D geometric morphometrics** — researchers load PLY mesh specimens, digitize landmarks, curves, and anchors in a Tk GUI, then export coordinates for statistical shape analysis (`geomorph`, `Morpho`, `Rvcg`, `vegan`). This project **fully modernizes** an ~8-year-old research codebase: restore it on current Windows R, migrate stale dependencies, and **rehabilitate the C/OpenGL engine in place** (Option A) for long-term maintainability without replacing the renderer.

## Core Value

A researcher can open the GUI on Windows R, load a 3D specimen, digitize anatomical landmarks/curves/anchors, run a `geomorph` analysis end-to-end, and maintain the tool via a clean, modular C codebase — all on current toolchains (MSVC build, no Visual Studio IDE required).

## Current State (v1.0 — shipped 2026-06-23)

GUImorph v1.0 delivers the full modernization milestone:

- Windows R 4.6+ GUI operational with MSVC-built `tkogl2.dll`
- Digitize workflow: landmarks, curves, anchors, `.dgt` save/reload
- Analysis: landmarks-only GPA + CSV export on geomorph 4.x
- Contributor docs: `BUILD.md`, `renv.lock`, `deploy-dll.ps1`
- C engine: `tcl_init`, `tcl_dispatch`, `tcl_window`, `tcl_state`, `tcl_log`, `marker.c`

**Archives:** [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md) · [milestones/v1.0-REQUIREMENTS.md](milestones/v1.0-REQUIREMENTS.md) · [MILESTONES.md](MILESTONES.md)

## Next Milestone Goals — v1.1 UI Modernization (defined 2026-06-24)

The runtime works; the **UI controls are still clunky**. This milestone makes GUImorph feel like a modern application **in place on Tk/ttk** (no renderer swap, no `.dgt` format break). Scope confirmed with user: modernize on Tk; workflow streamlining allowed while preserving `.dgt` round-trip.

Six phases (10–15), each mapping to a confirmed pain-point cluster:

- **Phase 10 — Visual chrome & menu cleanup**: themed/unified widgets, resizable centered window, remove developer-only menu items + blank spacers, fix wording/typos.
- **Phase 11 — Direct-manipulation controls**: inline spinboxes for counts (kill modal pop-ups), size sliders, non-modal delete, responsive layout.
- **Phase 12 — In-GUI feedback & status**: status bar + progress; surface console output in the GUI; non-blocking validation instead of modal nags.
- **Phase 13 — Guided workflow & discoverability**: placement hints, transparent/streamlined tab-gating, "specimen N of M" + jump-to.
- **Phase 14 — Keyboard shortcuts & undo**: accelerators for common actions; undo for landmark/anchor placement & deletion.
- **Phase 15 — Curve tab rehabilitation**: re-enable the commented-out curve controls; `.dgt` round-trip; reconcile UI with README.

See [REQUIREMENTS.md](REQUIREMENTS.md) (UX-* + CON-*) and [ROADMAP.md](ROADMAP.md).

## Requirements

### Validated

- ✓ Repository cleanup — Plan 0 (`repo-cleanup` branch): flattened embedded git, comprehensive `.gitignore`, purged VS caches/diagsession (~3 GB → ~55 MB)
- ✓ Native DLL compiles via MSVC + CMake — validated: `build-msvc/Release/tkogl2.dll`, exports `Tkogl2_Init`
- ✓ MSVC DLL deployed — `tkogl2.dll` → `inst/libs/x64/`, Windows R load confirmed
- ✓ Windows R smoke test — `load_all(".")`, `GUImorph()` opens, PLY load pipeline runs (`C13.1.ply`)
- ✓ Windows R 4.6 toolchain available — `winget install RProject.R`, CRAN deps installed to user library
- ✓ Package load + GUI launch — Phase 2 complete (startup OOB fix)
- ✓ Specimen mesh renders in 3D viewer — 2026-06-13: `C13.1.ply` artifact **visible** after load (user confirmed)
- ✓ PLY load pipeline — 2026-06-13: file found, `add specimen` invoked
- ✓ Landmark placement on specimen — 2026-06-15: landmarks **visible** after placement; requires **double-click** on canvas (single-click is pick/select only, not placement)
- ✓ Digitize workflow — v1.0: landmarks, curves, multi-specimen `.dgt` save/reload (Phases 4–5)
- ✓ Analysis round-trip — v1.0: landmarks-only GPA (`gpagen`) + CSV on geomorph 4.x APIs (Phase 5)
- ✓ Reproducible R environment — v1.0: `renv.lock` committed; `BUILD.md` + `deploy-dll.ps1` (Phase 6)
- ✓ C engine modularization — v1.0: five `tcl_*` modules; god file removed from build (Phase 7)
- ✓ Dot/anchor unification — v1.0: unified `marker.c`; anchor `.dgt` round-trip (Phase 8)
- ✓ C engine cleanup — v1.0: array globals, debug removal, Fixtures A+B regression UAT (Phase 9)

### Validated (v1.1)

- ✓ **Visual chrome & menu cleanup** — UX-MENU-01/02/03 (Phase 10, UAT approved 2026-06-24)
- ✓ **Direct-manipulation controls** — UX-CTL-01..04 (Phase 11, shipped 2026-06-24)
- ✓ **In-GUI feedback & status** — UX-FB-01..03 (Phase 12, UAT approved 2026-06-25)
- ✓ **Guided workflow & discoverability** — UX-WF-01..04 (Phase 13, UAT approved 2026-06-26)
- ✓ **Keyboard shortcuts & undo** — UX-KEY-01/02 (Phase 14, UAT approved 2026-06-26)

### Active (v1.1 UI Modernization)

- ◻ **Curve tab rehabilitation** — UX-CRV-01/02 (Phase 15)
- ◻ **Constraints**: no renderer change, `.dgt` round-trip preserved, Windows R 4.6+ only — CON-01/02/03

### Out of Scope

- **Option B** — rgl renderer swap (cross-platform via deletion of C engine)
- **Option C** — Shiny/WebGL UI rebuild
- Linux/macOS native port — Option A accepts permanent Windows-only + legacy GL
- Tcl/Tk 9.0 migration — stay on 8.6 stubs for this milestone
- Modern OpenGL core profile / shader pipeline — would be a rewrite, not rehabilitation
- Full geomorph gmShiny feature parity — migrate only functions GUImorph actually calls
- Visual Studio IDE workflow — replaced by CMake + MSVC Build Tools; `.vcxproj` kept as reference only

## Context

**Architecture (top → bottom):**

1. **R** — `GUImorphDevelopment/` + `tkogl2/R/` (~250 KB): Tk menus, `dgtDataList`, `.dgt` I/O, `geomorph` hooks
2. **Tcl/Tk** — stringly-typed `tcl("add", shape, ...)` protocol in `rtkogl.R`
3. **C/OpenGL** — `tkogl2` DLL: WGL context on Tk widget HWND, fixed-function OpenGL

**Current state (v1.0 shipped 2026-06-22):** Windows R 4.6+ GUI restored; MSVC-built `tkogl2.dll` with modular C engine (`tcl_init`, `tcl_dispatch`, `tcl_window`, `tcl_state`, `tcl_log`, `marker.c`). Contributor docs in `BUILD.md`; `renv.lock` pins R deps. Known backlog: GPA plot blank (999.1), openDgt specimen order (999.2).

**Milestone strategy:** v1.0 Phases 1–9 complete. Option A C rehabilitation delivered. Next milestone TBD via `/gsd-new-milestone`.

**Prior work:** See `.planning/guimorph-modernization-plan.md`, `modernization-session-handoff.md`, `r-guimorph-setup-findings.md`, `.planning/research/`.

## Constraints

- **Platform**: Windows-only for runtime — must use Windows R (not Linux/macOS R)
- **Build**: MSVC primary (`cmake -B build-msvc` on Windows); see `BUILD.md` and `scripts/deploy-dll.ps1`
- **Graphics**: Fixed-function OpenGL + WGL — legacy but retained under Option A
- **Dependencies**: `geomorph` 4.x breaking changes — migrate incrementally with call-site inventory
- **C refactor**: Must preserve `Tkogl2_Init` export and R↔Tcl shape string protocol

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flatten embedded git repo | Single outer repo (`dreoc/GUImorph`) instead of nested history | ✓ Good — Plan 0 |
| CMake + MSVC over Visual Studio IDE | Broken `.vcxproj`; VS Build Tools + CMake is contributor path | ✓ Good — DLL builds and renders |
| **Option A — rehabilitate C in place** | User chose cheapest path; accepts Windows-only + legacy GL | ✓ Good — v1.0 |
| Skip formal codebase map | Detailed architecture review already in `.planning/` | ✓ Good |
| Full modernization milestone | Includes C rehab (Phases 7–9), not just "get it running" | ✓ Good — v1.0 |
| Reject rgl/Shiny swap (Options B/C) | Explicit user choice of Option A | ✓ Good — v1.0 |
| MSVC as sole distribution toolchain | MinGW/WSL cross-compile builds link but render black/blank mesh | ✓ Good — 2026-06-21 |
| **Double-click to place landmarks** | Single-click runs pick/select (`set dot selected`); placement is `<Double-Button-1>` → `addDot` | ✓ Good — documented 2026-06-15 |
| **v1.1: modernize UI in place on Tk/ttk** | Renderer binds C/OpenGL to a Tk canvas HWND; a framework swap (Option C) would mean rewriting the renderer — rejected again | Pending — v1.1 |
| **v1.1: workflow streamlining allowed** | User OK'd relaxing/unifying tab-gating & placement rules as long as `.dgt` round-trips | Pending — v1.1 |

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
*Last updated: 2026-06-24 — v1.1 UI Modernization milestone defined (Phases 10–15)*
