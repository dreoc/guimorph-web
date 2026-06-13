# Architecture Research: GUImorph Modernization

**Date:** 2026-06-13

## Current Architecture

```
┌─────────────────────────────────────────────────────────┐
│  R Application (GUImorphDevelopment/)                   │
│  S3 dispatch: ui, init, bind, updateWidgets           │
│  Data: dgtDataList, .dgt I/O, geomorph hooks            │
└────────────────────┬────────────────────────────────────┘
                     │ tcl("add"|"set"|"del"|"show", shape, ...)
┌────────────────────▼────────────────────────────────────┐
│  Tcl Interpreter (tcltk / tcltk2)                       │
│  Stringly-typed shape dispatch                          │
└────────────────────┬────────────────────────────────────┘
                     │ Tcl_LoadExtension → Tkogl2_Init
┌────────────────────▼────────────────────────────────────┐
│  tkogl2.dll (C/OpenGL)                                  │
│  Commands: add, show, setWindow, setSpecimen, setDot,   │
│            del, loadDgt                                 │
│  Rendering: HWND → GetDC → wglCreateContext → GL        │
│  Modules: tcl_if, ogl_*, dot_*, curve_*, ogl_model_ply  │
└─────────────────────────────────────────────────────────┘
```

## Component Boundaries (Option A target state)

| Module | Current | Target |
|--------|---------|--------|
| `tcl_dispatch.c` | Inside 5,581-line god file | Command routing only |
| `tcl_window.c` | Inside god file | HWND/WGL setup, `setWindowId` |
| `tcl_state.c` | Inside god file | Specimen/model state |
| `dot.c` / `anchor.c` | Near-identical duplication | Unified `marker.c` |
| `curve.c` | Separate file | Keep, minor cleanup |
| `ogl*.c` | Separate files | Keep fixed-function pipeline |
| `rtkogl.R` | Mirrors C dispatch | Keep protocol; no rewrite |

## Data Flow

1. **Specimen load:** R → `tcl("add", "specimen", ...)` → C loads PLY → OpenGL display list
2. **Landmark:** R → `tcl("add", "dot", ...)` → C adds to dot list → redraw
3. **Curve:** R → `tcl("add", "curve", ...)` → C spline → redraw
4. **Save:** R writes `.dgt` from `dgtDataList` (R-side)
5. **Analyze:** R reads coordinates → `geomorph::gpagen` etc.

## Build Order (full milestone)

| Stage | Components | Rationale |
|-------|------------|-----------|
| 1–2 | Native DLL + package load | Nothing else testable without this |
| 3–4 | Renderer + digitize | Proves C engine works end-to-end |
| 5 | R analysis layer | Independent of C changes |
| 6 | renv + docs | Lock working state before C refactor |
| 7–9 | C rehabilitation | Refactor behind stable DLL interface |

## Integration Points (do not break during rehab)

- `Tkogl2_Init` export name and Tcl command registration
- R↔Tcl shape strings: `"specimen"`, `"dot"`, `"curve"`, `"anchor"`, `"landmark"`, etc.
- `.onLoad` DLL path resolution in `rtkogl.R`
- `.dgt` file format (R-side; C `loadDgt` must remain compatible)

---
*Architecture research: 2026-06-13*
