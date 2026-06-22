# Research Summary: GUImorph Modernization

**Synthesized:** 2026-06-13  
**Sources:** Codebase review, planning docs, geomorph 4.1.0 CRAN NEWS, geomorph.assistance vignette  
**Milestone scope:** Full modernization — restore + **Option A: rehabilitate C engine in place**

## Stack

- **Runtime:** Windows R 4.6 (ucrt) + tcltk2 8.6 + geomorph 4.1.0 / Morpho 2.13 / Rvcg 0.25
- **Build:** CMake + MinGW-w64 from WSL → `tkogl2.dll` (proven; runtime pending)
- **Lock:** renv after smoke tests pass
- **C strategy:** Keep WGL + fixed-function OpenGL; modularize in place (no rgl/Shiny swap)

## Table Stakes

1. `tkogl2.dll` loads via Tcl in Windows R
2. GUImorph GUI opens and renders PLY meshes
3. Full digitize workflow (landmarks, curves, `.dgt`)
4. geomorph analysis round-trip on current CRAN
5. Reproducible dev environment (renv + BUILD.md)
6. C engine rehabilitated: split god file, dedup dot/anchor, clean globals

## Differentiators (deferred)

- Cross-platform rendering (requires Option B/C)
- Tcl/Tk 9.0
- Automated CI/test suite

## Architecture

R (Tk GUI) → stringly-typed Tcl protocol → tkogl2.dll (WGL/OpenGL). C rehabilitation happens **behind the same DLL interface** after Phases 1–6 prove the engine works. geomorph migration is isolated to R analysis files.

## Watch Out For

1. **Don't refactor C before GUI works** — Phases 7–9 depend on 1–6
2. **geomorph API inventory first** — deprecated `advanced.procD.lm`, `plotTangentSpace`, RRPP moves
3. **Tcl stub ABI** — highest risk on first runtime load
4. **Dot/anchor unification** — subtle behavioral differences possible
5. **WSL UNC + RDP/GL** — environmental, not code bugs

## User Decisions (confirmed post-init)

| Question | Answer |
|----------|--------|
| Codebase map | Skip — use existing planning docs |
| Milestone scope | **Full modernization** (includes C rehab) |
| Plan 3 fork | **Option A** — rehabilitate C in place (Windows-only) |
| Workflow | YOLO + standard + parallel + all quality agents |
| Research | Yes |

---
*Research complete: 2026-06-13*
