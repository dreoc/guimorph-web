---
phase: 07-c-engine-modularization
plan: 01
subsystem: c-engine
tags: [c, tcl, opengl, cmake, msvc, tkogl2]

requires:
  - phase: 06-build-baseline
    provides: renv baseline, BUILD.md, deploy script
provides:
  - tcl_dispatch.c/h with Tcl handlers and draw pass extracted from god file
  - MSVC-first CMake and BUILD.md toolchain guidance
  - HWND/WGL and PLY render fixes discovered during smoke UAT
affects: [phase-7-07-02, phase-7-07-03]

tech-stack:
  added: []
  patterns:
    - "Incremental CMake: tcl_dispatch.c alongside trimmed tcl_if_ZARF_9.c until 07-03"
    - "MSVC native build as primary tkogl2.dll toolchain on Windows"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.h
  modified:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_if_ZARF_9.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_ZARF9.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ply_ZARF_9.c
    - integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
    - BUILD.md
    - .planning/smoke-test-findings.md

key-decisions:
  - "MSVC is the supported Windows build toolchain; MinGW builds link but render incorrectly"
  - "All-zero PLY vertex colors fall back to lighting path rather than flat black"
  - "PLY scan coloration deferred — shaded fallback acceptable for geometry-only NextEngine scans"
  - "Canvas HWND must be realized (tcl update idletasks) before WGL bind"

patterns-established:
  - "Dispatch extraction verified content-faithful via line diff against pre-extraction god file"

requirements-completed: [CENG-01]

duration: 3d
completed: 2026-06-21
---

# Phase 07 Plan 01: Dispatch Extraction Summary

**Extracted Tcl dispatch and draw pass into `tcl_dispatch.c`; smoke UAT passed after fixing latent HWND, GL lighting, PLY color fallback, and Tk canvas realization bugs.**

## Performance

- **Duration:** ~3 days (includes smoke debugging and MSVC pivot)
- **Completed:** 2026-06-21
- **Tasks:** 3/3 complete
- **Files modified:** 8

## Accomplishments

- Backed up pre-Phase-7 DLL (`tkogl2.dll.pre-phase7.bak`) per D-08
- Extracted Tcl handlers, draw pass, and Wrapper helpers to `tcl_dispatch.c`/`tcl_dispatch.h`
- CMake incremental source add; `Tkogl2_Init` export unchanged
- Smoke UAT passed: PLY load, `.dgt` load, shaded mesh, landmark placement, no UI ghosting
- MSVC-first build documented in `BUILD.md`

## Smoke UAT (2026-06-21)

| Step | Result |
|------|--------|
| `load_all` | ✅ |
| `GUImorph()` | ✅ |
| Load PLY | ✅ Shaded mesh |
| Load `.dgt` | ✅ Both specimens shaded |
| Double-click landmark | ✅ |
| Rotation | ✅ No crash |

Full notes: `.planning/smoke-test-findings.md` § "Phase 7 — Dispatch Extraction (07-01)".

## Fixes Applied During Smoke (kept)

- **HWND truncation** — zero-init + `(HWND)(INT_PTR)hwndId` in `setWindowId`
- **GL_INVALID_ENUM** — `glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, …)` + `glColorMaterial`
- **All-zero PLY colors** — drop color array in loader; use lighting path
- **Tk canvas realization** — `tcl("update","idletasks")` before GL bind in `ui.main`
- **Build freshness** — `COMPILE_INFORMATION` uses `__DATE__`/`__TIME__`

## Deferred

- **PLY vertex coloration** — restore true scan colors when non-zero; current Folsom fixtures are geometry-only (all-zero RGB)
- **MinGW build** — not supported for distribution until render parity with MSVC

## Next

- **07-02:** Extract HWND/WGL + `setWindow` → `tcl_window.c/h`
