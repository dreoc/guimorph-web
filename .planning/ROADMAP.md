# Roadmap: GUImorph — macOS Cross-Platform Parity

## Overview

This milestone ports GUImorph's native Win32/WGL OpenGL digitizing engine to macOS at full feature parity, without breaking the existing Windows build. The work is a dependency-ordered port of a mature codebase (horizontal layers, not vertical MVP slices): first prove that R can run against an Aqua (Cocoa) Tk and isolate the Windows window/context code behind a platform seam; then make the Tk drawable reachable by pathname; stand up a tri-platform build so Objective-C can compile; implement the macOS NSOpenGL backend until a PLY mesh renders ("first light"); fix Retina picking and macOS input quirks to reach full digitizing/analysis/data parity; and finally restore result-plot rendering via an rgl fallback. Every build phase carries a "Windows build still works" regression checkpoint (macOS is additive, not a replacement).

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Aqua-Tk Deployment Gate + Windows Rendering Seam** - Prove R+Aqua-Tk on macOS and isolate WGL behind a platform seam (Windows CMP-01 validation deferred) (completed 2026-07-13)
- [ ] **Phase 2: Pathname-Based Tk Drawable Resolution** - Reach the native drawable by widget pathname through Tk stubs
- [ ] **Phase 3: Tri-Platform Build + Generalized Load + Drop GLUT** - CMake `.dylib` toolchain, extension-aware `.onLoad`, remove GLUT
- [ ] **Phase 4: macOS NSGL Backend — First Light** - Render a PLY mesh in the embedded macOS viewport (universal2, distributable)
- [ ] **Phase 5: Retina Picking, Input Fixes & Digitizing/Analysis/Data Parity** - Pixel-accurate picking + macOS input + full workflow parity
- [ ] **Phase 6: rgl Result-Plot Fallback on macOS** - GPA/PCA/mean-shape plots via rgl NULL/`rglwidget`

## Phase Details

### Phase 1: Aqua-Tk Deployment Gate + Windows Rendering Seam

**Goal**: Confirm and document a supported "R + Aqua Tk" configuration on macOS, and isolate all native window/context creation behind a platform seam with the existing Win32/WGL code moved behind it unchanged.
**Depends on**: Nothing (first phase)
**Requirements**: GATE-01, GATE-02, RND-01, CMP-01
**Success Criteria** (what must be TRUE):

  1. An R session on macOS reports `tk windowingsystem == aqua` and can `load` a trivial Aqua Tk C extension (X11/XQuartz path ruled out).
  2. A documented, reproducible "R + Aqua Tk" setup exists that a researcher can follow (which Tcl/Tk flavor ships and how to obtain it).
  3. All WGL/HDC/HGLRC/`SwapBuffers` code is moved out of `tcl_window.c`/`onDisplay` into `gfx_backend_wgl.c` behind `gfx_backend.h` (create / make_current / swap / resize / destroy); the core includes only the seam.
  4. Windows build still works: the MSVC `tkogl2.dll` builds and renders a PLY mesh identically to before the seam extraction.

**Plans**: 5/5 plans complete
**Wave 1**

- [x] 01-01-PLAN.md — RND-01: extract WGL window/context code behind the 5-function `gfx_backend.h` seam (`gfx_backend_wgl.c`), behavior-preserving
- [x] 01-02-PLAN.md — GATE-01: Aqua-Tk deployment spike + trivial Tk-linked C extension + scriptable `gate_check.R` assert

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-03-PLAN.md — GATE-02: reproducible R + Aqua Tk setup doc + lock D-01/D-02 distribution decision
- [x] 01-04-PLAN.md — CMP-01: regression fixture committed; off-box Windows MSVC build/render regression deferred to pending backlog

**Gap Closure** *(from 01-VERIFICATION.md — two BLOCKER gaps)*

- [x] 01-05-PLAN.md — RND-01: remove residual `HWND` typing from core (`tcl_window.c`/`.h`) so the seam boundary is complete; resolve the `// TBD ??` debt marker on `model_t.count` in `def_ZARF_9.h` (behavior-preserving)

**Note**: CMP-01 (Windows-regression checkpoint) is owned here and its "Windows still works" criterion recurs in every phase. Research flag: which supported R + Aqua-Tk config ships to researchers is this milestone's central open question — resolved empirically via the Plan 02 spike. CMP-01 (Plan 04) is off-box (delegated to a Windows maintainer); Plans 01+02 are Wave 1 (parallel, independent workstreams), Plans 03+04 are Wave 2.

### Phase 2: Pathname-Based Tk Drawable Resolution

**Goal**: Resolve the Tk drawable by frame pathname (not `winfo id`) through Tk stubs so the platform-native drawable (HWND on Windows, `NSView` on macOS) is reachable.
**Depends on**: Phase 1
**Requirements**: RND-02
**Success Criteria** (what must be TRUE):

  1. `setWindow "id"` accepts a Tk widget pathname; C resolves `Tk_NameToWindow` → `Tk_WindowId` and branches to the per-platform drawable accessor (`Tk_GetHWND` / `Tk_MacOSXGetNSWindowForDrawable`).
  2. `Tk_InitStubs` + `tkstub` linkage is in place and the R bridge passes the frame pathname instead of `winfo id`.
  3. Windows build still works: the pathname-based resolution reaches the HWND and renders a PLY mesh with no regression (removing the fragile int→HWND cast previously blamed for blank viewports).

**Plans**: TBD

### Phase 3: Tri-Platform Build + Generalized Load + Drop GLUT

**Goal**: Establish the macOS toolchain and loading path so Objective-C Cocoa code can compile, link, and load, without breaking Windows.
**Depends on**: Phase 2
**Requirements**: BLD-01, BLD-02, BLD-04
**Success Criteria** (what must be TRUE):

  1. A tri-platform CMake build (WIN32 / APPLE / UNIX branches) produces a Mach-O `tkogl2.dylib` (`-dynamiclib`) on macOS, linking `-framework OpenGL/AppKit/Foundation` against a stub macOS backend.
  2. `.onLoad` computes the platform library extension via `[info sharedlibextension]` (`.dll`/`.dylib`/`.so`) instead of hardcoding `.dll`, and surfaces load failure loudly instead of silently degrading.
  3. GLUT is removed from the draw path (`glutSolidSphere` → `gluSphere`), so no GLUT dependency is required on macOS.
  4. Windows build still works: the MSVC `tkogl2.dll` builds under the unified CMake and renders unchanged.

**Plans**: TBD

### Phase 4: macOS NSGL Backend — First Light

**Goal**: Implement the Cocoa NSOpenGL backend so a loaded PLY mesh renders (not blank/black) in the embedded macOS viewport, and produce a distributable universal2 artifact.
**Depends on**: Phase 3
**Requirements**: RND-03, RND-04, BLD-03
**Success Criteria** (what must be TRUE):

  1. `gfx_backend_nsgl.m` creates an `NSOpenGLContext` on Tk's embedded `NSView` using a **legacy 2.1 GL profile**, presents via `[NSOpenGLContext flushBuffer]`, and runs all GL/Cocoa work on the main thread inside Tk's event cycle.
  2. Loading a PLY specimen renders the mesh in the embedded macOS digitizing viewport (not blank/black) on both Apple Silicon and Intel Macs.
  3. The library is built `universal2` (arm64 + x86_64) and the distribution path handles quarantine / library validation (sign + notarize, or a documented `xattr` workaround).
  4. Windows build still works: the Windows build renders PLY meshes unchanged.

**Plans**: TBD

### Phase 5: Retina Picking, Input Fixes & Digitizing/Analysis/Data Parity

**Goal**: Make picking pixel-accurate on Retina and fix macOS input quirks so the full digitizing, analysis-compute, and data/session workflows reach parity with the Windows build.
**Depends on**: Phase 4
**Requirements**: PICK-01, PICK-02, PICK-03, PICK-04, PICK-05, DIG-01, DIG-02, DIG-03, DIG-04, DIG-05, ANL-01, DAT-01, DAT-02, DAT-03
**Success Criteria** (what must be TRUE):

  1. On a HiDPI/Retina display the mesh fills the viewport and landmark picks land on-target — `glViewport` and screen→world unproject scale by `backingScaleFactor` (PICK-01, the prerequisite for all picking-based digitizing parity).
  2. Fixed-landmark digitizing (place / drag-move / delete / undo / labels / colors / missing), anchors, curves, surface sliders, and tab gating all work on macOS — including right-click delete (aqua button 2/3 swap; `Button-2` + `Control-Button-1`) and wheel zoom/scroll (fixed `%D`/120 truncation) across every tab.
  3. File open/save dialogs work for `.ply`/`.dgt`/`.pts` (custom extensions selectable, no crash on odd extensions), ⌘ accelerators work alongside Ctrl, and GPA (`geomorph::gpagen`) with sliding, principal-axis alignment, and tangent-space options runs on macOS.
  4. `.dgt` save/load/merge and `.csv`/`.rds` export work on macOS, and `.dgt` files/exports are byte-compatible with Windows-authored files (endianness/serialization round-trip verified both directions).
  5. Windows build still works: the full digitizing → GPA → export workflow runs unchanged on the Windows build.

**Plans**: TBD
**Note**: Research flag (partial): `.dgt` endianness / fixed-width serialization for the Windows↔macOS round-trip and native file-panel UTType behavior need verification during planning.

### Phase 6: rgl Result-Plot Fallback on macOS

**Goal**: Make GPA/PCA/mean-shape result plots render on macOS via an rgl NULL/`rglwidget` fallback, since interactive XQuartz rgl is broken on current macOS.
**Depends on**: Phase 5
**Requirements**: ANL-02
**Success Criteria** (what must be TRUE):

  1. Aligned-specimen, PCA morphospace, and mean-shape plots render on macOS via `options(rgl.useNULL = TRUE, rgl.printRglwidget = TRUE)` → `rglwidget()` (WebGL) instead of failing on broken XQuartz GLX.
  2. Plot functions are audited so they do not rely on `select3d()` / `rgl.snapshot()` (unsupported in NULL mode), or those usages are replaced.
  3. Windows build still works: result plots render unchanged on the Windows build.

**Plans**: TBD
**Note**: Research flag: verify the `rglwidget` path is adequate and does not break `select3d`/snapshot usage in the three plot functions. This phase corrects PROJECT.md's stale "macOS renders rgl plots today" assumption.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Aqua-Tk Gate + Rendering Seam | 5/5 | Complete   | 2026-07-13 |
| 2. Pathname Drawable Resolution | 0/TBD | Not started | - |
| 3. Tri-Platform Build + Load + Drop GLUT | 0/TBD | Not started | - |
| 4. macOS NSGL Backend — First Light | 0/TBD | Not started | - |
| 5. Retina Picking, Input & Parity | 0/TBD | Not started | - |
| 6. rgl Result-Plot Fallback | 0/TBD | Not started | - |

## Notes

- **Hard ordering (non-negotiable):** the Aqua-Tk deployment gate (Phase 1) blocks all GL work; the seam must exist before any backend (1 → 2 → 3 → 4); Retina-correct picking (PICK-01, Phase 5) blocks all picking-based digitizing parity.
- **Deferred / out of milestone:** Offscreen FBO + Tk-photo-blit fallback backend (v2 escape hatch behind the same seam), Linux (GLX/X11) support, Metal-backed rendering.
- **Side-track (not a v1 requirement):** hardening the unsafe PLY parser (`strcpy`/`sscanf`/`sprintf`) under clang ASan/UBSan is parallelizable and independent of the port spine. It maps to no v1 requirement and is intentionally kept out of the port's blast radius; track separately if pursued.
