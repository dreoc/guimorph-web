# Onboarding Summary — GUImorph

**Date:** 2026-07-12
**Type:** Brownfield onboarding (existing R + C/OpenGL package, beta v0.9.0)
**Route:** map-codebase → (ingest-docs: skipped) → new-project → summary

---

## What was created

| Artifact | Location |
|----------|----------|
| Codebase map (7 docs) | `.planning/codebase/` |
| Project context | `.planning/PROJECT.md` |
| Config | `.planning/config.json` |
| Research (5 docs) | `.planning/research/` |
| Requirements (26 v1) | `.planning/REQUIREMENTS.md` |
| Roadmap (6 phases) | `.planning/ROADMAP.md` |
| State | `.planning/STATE.md` |
| Project guide | `.cursor/rules/gsd.md` |

> `.planning/` and `.cursor/` are gitignored in this repo — planning is local-only (`commit_docs: false`).

## What GUImorph is

R + Tcl/Tk + C/OpenGL desktop app for 3D geometric morphometrics: digitize PLY meshes (landmarks/curves/anchors/surface) and run `geomorph` GPA/PCA. Exists because rgl/OpenGL digitizing was deprecated on modern macOS. Currently **Windows-only** (native MSVC `tkogl2.dll`, Win32 HWND + WGL).

## Chosen milestone: macOS cross-platform parity

macOS first (Linux deferred), full feature parity, rendering approach settled by research.

**Key research conclusions:**
- Reuse `ogl_*` draw/pick code + Tcl bridge; replace only WGL/HWND behind a `gfx_backend.h` seam with native `NSView` + `NSOpenGLContext`, **legacy 2.1 GL profile**.
- **Gating risk:** CRAN R uses X11 Tk and XQuartz GLX is broken on macOS Tahoe — the port *requires* R on **Aqua (Cocoa) Tk**. This is Phase 1.
- GLFW/SDL ruled out (own their windows, can't embed in Tk).
- Retina backing-scale conversion gates all landmark picking accuracy.
- rgl result plots need `rgl.useNULL`/`rglwidget` fallback (stale "rgl works on macOS today" assumption corrected).

## Roadmap (6 phases)

1. Aqua-Tk Gate + Rendering Seam
2. Pathname Drawable Resolution
3. Tri-Platform Build + Load + Drop GLUT
4. macOS NSGL Backend — First Light
5. Retina Picking, Input & Parity
6. rgl Result-Plot Fallback

Every phase carries a "Windows build still works" checkpoint. PLY-parser hardening is a parallelizable side-track.

## Config

YOLO mode · standard granularity · parallel execution · local-only planning · research + plan-check + verifier ON · adaptive models · drift-guard ON.

## Next command

`/gsd-plan-phase 1` — plan Phase 1 (Aqua-Tk Gate + Rendering Seam).

Open questions to resolve in Phase 1 planning: which supported R + Aqua-Tk config ships to researchers; confirm the engine is fixed-function via a quick `ogl_*.c` audit.
