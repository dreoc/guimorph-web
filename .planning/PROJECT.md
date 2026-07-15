# GUImorph

## What This Is

GUImorph is an R package with a Tcl/Tk graphical interface for **3D geometric morphometrics**: load PLY mesh specimens, digitize landmarks / curves / anchors / surface semilandmarks, run `geomorph` analyses (GPA, PCA, mean shape), and export coordinates. It exists because `geomorph`'s interactive 3D digitizing functions were deprecated when rgl/OpenGL stopped working on modern macOS — GUImorph is an rgl-independent, `geomorph`-native digitizer that keeps that template-based surface-semilandmark workflow alive. It is used by morphometrics researchers.

## Core Value

A researcher can digitize a 3D specimen and feed the result straight into `geomorph` — the interactive digitizing viewport must render the mesh and place landmarks correctly.

## Requirements

### Validated

<!-- Inferred from existing code (brownfield). Windows build, beta v0.9.0. -->

- ✓ Load one or more PLY meshes as a specimen set and render in an embedded OpenGL viewport — existing
- ✓ Digitize fixed landmarks by double-click, with move/delete/undo, labels, colors, missing-landmark marking — existing
- ✓ Place anchors on a dedicated tab (optional workflow) — existing
- ✓ Define curves as 3-landmark-per-segment triplets and compute curve geometry — existing
- ✓ Define surface semilandmarks / template build with downsampling — existing
- ✓ Run Generalized Procrustes Analysis via `geomorph::gpagen` with sliding, principal-axis alignment, tangent-space projection options — existing
- ✓ Plot aligned specimens, PCA morphospace, and reconstructed mean shape — existing
- ✓ Save/load sessions to `.dgt`; add PLY to / merge `.dgt` datasets — existing
- ✓ Export aligned coordinates + centroid size to `.csv` and geomorph-ready `.rds` — existing
- ✓ Tab gating enforces workflow prerequisites (Surface Sliders/Curves/GPA unlock after landmarks complete) — existing
- ✓ Ships a prebuilt MSVC `tkogl2.dll` so Windows end users run without compiling — existing

### Active

<!-- Milestone: cross-platform rendering, macOS first, full feature parity. -->

- [ ] GUImorph launches and renders a PLY mesh in the digitizing viewport on macOS (not blank/black)
- [ ] Landmark/anchor digitizing (double-click place, move, delete, undo) works on macOS
- [ ] Curves and surface-slider workflows work on macOS
- [ ] GPA / PCA / mean-shape analysis and `rgl` result plots work on macOS
- [ ] `.dgt` save/load and `.csv`/`.rds` export work on macOS
- [ ] A reproducible macOS build + load path exists (native library builds and loads via `.onLoad`)
- [ ] Full feature parity with the Windows build on macOS

### Out of Scope

- Linux support this milestone — macOS is the primary pain point (rgl/OpenGL deprecation origin); Linux is a follow-on milestone
- Rewriting the analysis layer — `geomorph`/`Morpho`/`Rvcg` pipeline is validated and reused as-is
- Replacing Tcl/Tk with another GUI toolkit — the R/Tk controller layer stays; only the native windowing/GL glue is in question
- Web/browser version — desktop-only remains the delivery model

## Context

- **Codebase map:** see `.planning/codebase/` (STACK, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, INTEGRATIONS, CONCERNS).
- **Architecture:** layered "R GUI over Tcl/Tk calling into a native C OpenGL DLL". R (`R/3dDigitize.*.r`, `rtkogl.R`) drives Tk widgets and marshals imperative commands over the Tcl bridge (8 commands: `add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`) into `tkogl2.dll`. Analysis delegated to the `geomorph` ecosystem.
- **The portability blocker:** the native engine embeds OpenGL into a Tk frame's window via **Win32 HWND + WGL** (`src/tcl_window.c`). macOS needs a different window/context path (NSOpenGL/CGL or a portable layer such as GLFW/SDL). This native windowing glue — not the OpenGL draw code or the R layer — is the core cross-platform work.
- **Rendering approach undecided:** whether to adopt a portable windowing/GL layer (GLFW/SDL, keep the C engine) or write per-platform native glue (NSOpenGL/CGL) is an open decision — flagged for research.
- **Known concerns** (`.planning/codebase/CONCERNS.md`): unsafe PLY parsing (`strcpy`/`sscanf`/`sprintf`), 3916-line `tcl_dispatch.c`, pervasive `GBL_*` global state, fixed-capacity caps (25 landmark sets, 10 curve sets, 5 model slots), MinGW builds render black/blank (only MSVC supported on Windows), vendored duplicate R sources under `tkogl2/R/`.
- **macOS renders `rgl` result plots today** (rgl still works for static plotting); the gap is the interactive digitizing viewport.

## Constraints

- **Compatibility**: Must keep the Windows build working — macOS support is additive, not a replacement.
- **Tech stack**: R 4.6+, Tcl/Tk, C99 native engine, `geomorph >= 4.1.1`; dependencies pinned via `renv.lock`. macOS build must integrate with the same R/Tcl `.onLoad` loading model (`tcl("load", file, "Tkogl2")`).
- **Dependencies**: On macOS, OpenGL is deprecated by Apple (still present up to current macOS); the chosen rendering path must run on Apple Silicon + Intel Macs and survive Apple's OpenGL deprecation trajectory.
- **Toolchain**: macOS build needs a documented, reproducible toolchain (Xcode command-line tools / CMake) analogous to the Windows MSVC path.
- **Compatibility**: `.dgt` session files and exports must remain cross-platform compatible with the Windows build.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Target macOS first (Linux deferred) | macOS is the origin motivation — rgl/OpenGL digitizing deprecated there | — Pending |
| Full feature parity target (not MVP slice) | A partial digitizer isn't useful to researchers; parity is the bar | — Pending |
| Keep R/Tk + geomorph layers; only rework native windowing/GL glue | Analysis + GUI logic are validated; the blocker is Win32/WGL embedding | — Pending |
| Rendering approach (portable layer vs native NSOpenGL/CGL) TBD via research | Big architectural fork with long-term maintenance implications | — Pending |
| Planning docs local-only (`.planning/` gitignored) | Repo already gitignores `.planning/`; keeps planning out of the public package repo | ✓ Good |

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
*Last updated: 2026-07-12 after initialization*
