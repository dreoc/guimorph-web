# Research Summary: GUImorph Modernization

**Synthesized from:** `.planning/guimorph-modernization-plan.md`, session handoff, R setup findings, and codebase review (2026-06-12/13).

## Stack

| Layer | Current | Modernization path |
|-------|---------|-------------------|
| R GUI | `tcltk`/`tcltk2` + custom S3 dispatch | Keep 8.6 for v1; pin with `renv` |
| Native ext | Custom `tkogl2` DLL (C + WGL + fixed-function GL) | Rebuild via MinGW/CMake (done); runtime validate next |
| Build | Broken MSVC `.vcxproj` | **CMake + MinGW-w64** from WSL → Windows DLL |
| Analysis | `geomorph` 4.x, `Morpho`, `Rvcg`, `vegan` | Migrate API calls incrementally from ~2020 patterns |
| Runtime | Windows R 4.6 (ucrt x64) | Required — HWND/WGL is Windows-only |

**Do NOT use for v1:** Tcl/Tk 9.0 (ABI break), Linux native `.so` (no WGL path), immediate `rgl` swap (Phase 3 decision).

## Table Stakes (must work)

- `tkogl2.dll` loads via `tcl("load", ..., "Tkogl2")` — exports `Tkogl2_Init`
- GUImorph package `.onLoad` succeeds; console shows load confirmation
- "3D GUImorph" Tk window opens
- Load PLY specimen mesh in 3D viewer
- Place landmarks and curves; save `.dgt` file
- Run at least one `geomorph` analysis on exported coordinates

## Differentiators (defer to v2)

- Cross-platform support (requires renderer replacement)
- Modern OpenGL / WebGL UI
- Automated test suite and CI
- C engine modularization (collapse dot/anchor duplication, split god file)

## Architecture

```
R (GUImorphDevelopment) ──tcl("add", shape, ...)──► Tcl interpreter
                                                          │
                                                          ▼
                                              tkogl2.dll (Tkogl2_Init)
                                                          │
                                    WGL context on Tk HWND + fixed-function GL
                                                          │
                                                          ▼
                                              PLY mesh, landmarks, curves
```

**Build order implication:** Native DLL runtime → package load → GUI → digitize → analyze. No point migrating R APIs until DLL + GUI open.

## Watch Out For

| Pitfall | Warning sign | Prevention | Phase |
|---------|--------------|------------|-------|
| WSL UNC path flakiness | Slow/failed `load_all` | Copy repo to `C:\dev\GUImorph` if needed | 1–2 |
| Tcl stub ABI mismatch | `loading tkogl2 failed` on load | Smoke test `tcl("load", ...)` before full GUI | 1 |
| GLUT DLL not found | OpenGL init crash | Ensure `glut64.dll` beside `tkogl2.dll` or on PATH | 1 |
| Stale 2020 DLL vs new build | Old behavior despite C edits | Deploy `build/tkogl2.dll` → `inst/libs/x64/` | 1 |
| `geomorph` API breaks | Errors in `.geomorph.r` on analyze | Inventory calls; migrate one function at a time | 5 |
| Fixed-function GL on RDP/VM | Black/blank 3D view | Test on local Windows desktop first | 2 |

## Confidence

- **High:** Build path (MinGW DLL compiles, correct export)
- **Medium:** Runtime load + GUI launch (not yet tested end-to-end)
- **Low:** Full analyze round-trip on R 4.6 + geomorph 4.1 without API fixes

---
*Research synthesized: 2026-06-13 — from existing planning artifacts, not live web research*
