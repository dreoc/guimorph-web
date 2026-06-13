# Stack Research: GUImorph Modernization

**Domain:** R geometric morphometrics GUI + native OpenGL extension  
**Milestone:** Full modernization (restore + rehabilitate C engine in place)  
**Date:** 2026-06-13

## Recommended Stack (v1 — Option A)

| Layer | Choice | Version / Notes | Confidence |
|-------|--------|-----------------|------------|
| R runtime | Windows R (ucrt) | 4.6.x | High |
| R packages | geomorph, Morpho, Rvcg, vegan, tcltk2 | CRAN 4.6 current (geomorph 4.1.0) | High |
| Package lock | renv | Pin after smoke tests pass | High |
| Build (native) | CMake + MinGW-w64 | Cross-compile from WSL → Windows DLL | High — validated |
| Tcl stubs | Tcl 8.6 | `tcl_stub_bootstrap.c` for MinGW (MSVC `.lib` unreadable by GNU ld) | Medium |
| OpenGL | Fixed-function + WGL | Legacy; required for Option A | High |
| GLUT | Vendored `glut64.dll` + header shim | Only 3 calls used | High |
| GUI | tcltk / tcltk2 | Stay on 8.6; no Tk 9.0 for v1 | High |
| Dev tools | devtools, roxygen2 | Package load from source | High |

## What NOT to Use (v1)

| Alternative | Why excluded |
|-------------|--------------|
| Visual Studio IDE | User workflow is Cursor/WSL; CMake replaces broken `.vcxproj` |
| Tcl/Tk 9.0 | ABI break; stubs incompatible with current extension |
| rgl renderer swap | Option B — user chose Option A (rehabilitate C) |
| Shiny + WebGL | Option C — out of scope for this milestone |
| Linux native `.so` | WGL/HWND engine is Windows-only under Option A |
| Modern OpenGL core profile | Would require full renderer rewrite, not rehabilitation |

## geomorph Ecosystem (2020 → 4.1.0)

Key migration targets for GUImorph R layer:

| Change | Impact on GUImorph |
|--------|-------------------|
| `gpagen` default `ProcD=FALSE` | May change sliding behavior if old code assumed TRUE |
| `advanced.procD.lm`, `procD.allometry`, `nested.update` deprecated | Replace with `procD.lm` + RRPP `anova`/`pairwise` |
| `trajectory.analysis` moved to RRPP | Update imports and call sites |
| `plotTangentSpace` deprecated | Split into `gm.prcomp` + `plotRefToTarget` etc. |
| Permutation computations in RRPP | Ensure RRPP is declared dependency if used |
| geomorph 4.1 plotly for 3D graphics | GUImorph has own Tk/OpenGL viewer — no conflict, but watch deprecated RGL digitizing functions |
| Internal C-code removed from `gpagen` | Pure R — no impact on tkogl2 DLL |

## C Engine Rehabilitation Stack (Phases 7–9)

| Task | Approach |
|------|----------|
| Split god file | Extract command dispatch, window/state, rendering into separate `.c` files |
| Dot/anchor dedup | Unified struct + shared functions (source admits duplication at `def_ZARF_9.h:169`) |
| Globals cleanup | Replace `GBL_PTR_*_1..N` with arrays; document max specimen/curve limits |
| Debug removal | Strip `printf`/`if(0)` toggles; remove `MAKE_INERT` broken-code paths |
| Build | Keep CMake/MinGW; verify no regression after each extraction |

## Rationale

Option A keeps the existing R↔Tcl↔C protocol intact. The MinGW/CMake path is proven. geomorph migration is isolated to the R analysis layer and can proceed incrementally once the GUI runs. C rehabilitation is incremental refactor behind the same DLL interface — no R API changes required.

---
*Stack research: 2026-06-13*
