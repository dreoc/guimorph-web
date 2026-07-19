# Roadmap: GUImorph — macOS Cross-Platform Parity

## Overview

This milestone ports GUImorph's native Win32/WGL OpenGL digitizing engine to macOS at full feature parity, without breaking the existing Windows build. The work is a dependency-ordered port of a mature codebase (horizontal layers, not vertical MVP slices): first prove that R can run against an Aqua (Cocoa) Tk and isolate the Windows window/context code behind a platform seam; then make the Tk drawable reachable by pathname; stand up a tri-platform build so Objective-C can compile; implement the macOS NSOpenGL backend until a PLY mesh renders ("first light"); fix Retina picking and macOS input quirks to reach full digitizing/analysis/data parity; and finally restore result-plot rendering via an rgl fallback. Every build phase carries a "Windows build still works" regression checkpoint (macOS is additive, not a replacement).

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Aqua-Tk Deployment Gate + Windows Rendering Seam** - Prove R+Aqua-Tk on macOS and isolate WGL behind a platform seam (Windows CMP-01 validation deferred) (completed 2026-07-13)
- [x] **Phase 2: Pathname-Based Tk Drawable Resolution** - Reach the native drawable by widget pathname through Tk stubs (verified on Windows 2026-07-15) (completed 2026-07-15)
- [x] **Phase 3: Tri-Platform Build + Generalized Load + Drop GLUT** - CMake `.dylib` toolchain, extension-aware `.onLoad`, remove GLUT *(Windows verified 2026-07-16; macOS `.dylib` build in Phase 4)*
- [x] **Phase 4: macOS NSGL Backend — First Light** - Render a PLY mesh in the embedded macOS viewport (universal2, distributable) (completed 2026-07-17)
- [x] **Phase 5: Retina Picking, Input Fixes & Digitizing/Analysis/Data Parity** - Pixel-accurate picking + macOS input + full workflow parity (completed 2026-07-19)
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

**Plans**: 1/1 complete (all three criteria met; criterion 3 verified on Windows R 4.6.1, 2026-07-15)

- [x] 02-01-PLAN.md — RND-02: R bridge passes frame pathname; `tcl_window.c` resolves `Tk_NameToWindow` → `Tk_MakeWindowExist` → `Tk_WindowId` → per-platform accessor (`Tk_GetHWND` / `Tk_MacOSXGetNSWindowForDrawable`). Verified on Windows (render + picking + 6 landmarks). Built in direct Tk-link mode (import lib from R's tk86.dll); x64 tkstub for stubs mode deferred to Phase 3.

**Note**: Criterion 3 (Windows renders unchanged) is the recurring CMP-01 checkpoint and is off-box (no MSVC/Windows host available). Introducing `<tk.h>` adds one on-box build dependency — the Tk `X11/` shim on the include path (`TKOGL2_TK_XLIB_INCLUDE`) — captured in the pending todo.

### Phase 3: Tri-Platform Build + Generalized Load + Drop GLUT

**Goal**: Establish the macOS toolchain and loading path so Objective-C Cocoa code can compile, link, and load, without breaking Windows.
**Depends on**: Phase 2
**Requirements**: BLD-01, BLD-02, BLD-04
**Success Criteria** (what must be TRUE):

  1. A tri-platform CMake build (WIN32 / APPLE / UNIX branches) produces a Mach-O `tkogl2.dylib` (`-dynamiclib`) on macOS, linking `-framework OpenGL/AppKit/Foundation` against a stub macOS backend.
  2. `.onLoad` computes the platform library extension via `[info sharedlibextension]` (`.dll`/`.dylib`/`.so`) instead of hardcoding `.dll`, and surfaces load failure loudly instead of silently degrading.
  3. GLUT is removed from the draw path (`glutSolidSphere` → `gluSphere`), so no GLUT dependency is required on macOS.
  4. Windows build still works: the MSVC `tkogl2.dll` builds under the unified CMake and renders unchanged.

**Plans**:

- [x] 03-01-PLAN.md — BLD-01/BLD-02/BLD-04: tri-platform CMake (WIN32/APPLE/else) emitting `tkogl2.dylib` against `-framework OpenGL/AppKit/Foundation`; compiling NSGL stub (`gfx_backend_nsgl.m`, real context in Phase 4); extension-aware, loud-failing `.onLoad` (`[info sharedlibextension]` + `stop()`); GLUT dropped from the draw path (`gluSphere`, vestige removed, labels Windows-guarded). **Windows verified 2026-07-16** (rebuild renders unchanged incl. 6-specimen `.dgt`); macOS `.dylib` build lands in Phase 4 (first Mac build).

### Phase 4: macOS NSGL Backend — First Light

**Goal**: Implement the Cocoa NSOpenGL backend so a loaded PLY mesh renders (not blank/black) in the embedded macOS viewport, and produce a distributable universal2 artifact.
**Depends on**: Phase 3
**Requirements**: RND-03, RND-04, BLD-03
**Success Criteria** (what must be TRUE):

  1. `gfx_backend_nsgl.m` creates an `NSOpenGLContext` on Tk's embedded `NSView` using a **legacy 2.1 GL profile**, presents via `[NSOpenGLContext flushBuffer]`, and runs all GL/Cocoa work on the main thread inside Tk's event cycle.
  2. Loading a PLY specimen renders the mesh in the embedded macOS digitizing viewport (not blank/black) on both Apple Silicon and Intel Macs.
  3. The library is built `universal2` (arm64 + x86_64) and the distribution path handles quarantine / library validation (sign + notarize, or a documented `xattr` workaround).
  4. Windows build still works: the Windows build renders PLY meshes unchanged.

**Plans**: 3/3 plans complete

**Wave 1**

- [x] 04-01-PLAN.md — BLD-03 (arm64 env): install Aqua Tk toolchain (D-09), pass the committed Aqua gate (`gate_check: PASS`, closes GATE-01 runtime proof), and produce the first clean arm64 `tkogl2.dylib` from the Phase 3 stub (closes the pending macOS BLD-01 build)

**Wave 2** *(depends on 04-01)*

- [x] 04-02-PLAN.md — RND-03/RND-04/BLD-03: fill `gfx_backend_nsgl.m` with a legacy-2.1 `NSOpenGLContext` (create/attach `setView:`, make-current + GL_VERSION legacy guard, `flushBuffer` present, Retina viewport via `convertRectToBacking:`), rebuild + static-verify the arm64 dylib (`MH_DYLIB`/`arm64`), deploy where `.onLoad` searches

**Wave 3** *(depends on 04-02)*

- [x] 04-03-PLAN.md — RND-03/RND-04: first-light manual acceptance in a live `GUImorph()` session (tetrahedron smoke → real specimen, D-08), confirm legacy GL_VERSION + Retina fill; child-`NSView` fallback ready if the layer-backed direct attach is blank

**Note**: BLD-03 is only PARTIALLY addressed here (arm64 build only). universal2 x86_64, signing, notarization, and the `xattr` quarantine workaround are DEFERRED to a later distribution step (D-06, D-07) and do not block phase closure. Verification is build/static automation + a manual/visual live-session render (no unit-test harness for the native GL path). CMP-01 (Windows still works) is off-box — only `gfx_backend_nsgl.m` changes.

### Phase 5: Retina Picking, Input Fixes & Digitizing/Analysis/Data Parity

**Goal**: Make picking pixel-accurate on Retina and fix macOS input quirks so the full digitizing, analysis-compute, and data/session workflows reach parity with the Windows build.
**Depends on**: Phase 4
**Requirements**: PICK-01, PICK-02, PICK-03, PICK-04, PICK-05, DIG-01, DIG-02, DIG-03, DIG-04, DIG-05, ANL-01, DAT-01, DAT-02, DAT-03
**Success Criteria** (what must be TRUE):

  1. On a HiDPI/Retina display the mesh fills the viewport and landmark picks land on-target — `glViewport` and screen→world unproject scale by `backingScaleFactor` (PICK-01, the prerequisite for all picking-based digitizing parity).
  2. Fixed-landmark digitizing (place / drag-move / delete / undo / labels / colors / missing), anchors, curves, surface sliders, and tab gating all work on macOS — including right-click delete (aqua button 2/3 swap; `Button-2` + `Control-Button-1`) and wheel zoom/scroll (fixed `%D`/120 truncation) across every tab.
  3. File open/save dialogs work for `.ply`/`.dgt`/`.pts` (custom extensions selectable, no crash on odd extensions), ⌘ accelerators work alongside Ctrl, and GPA (`geomorph::gpagen`) with sliding, principal-axis alignment, and tangent-space options runs on macOS.
  4. `.dgt` save/load/merge and `.csv`/`.rds` export work on macOS, and `.dgt` files/exports are byte-compatible with Windows-authored files (endianness/serialization round-trip verified both directions).
  5. Windows build still works: the full digitizing → GPA → export workflow runs unchanged on the Windows build. **VERIFIED 2026-07-18** — rebuilt Windows DLL: full workflow, 6-specimen `.dgt` round-trip (uniform 1000-point surfaces), wheel = 1 step/notch, portrait canvas correct, 212 live picks / 0 failed across 3 rgl plots. Required one new in-milestone fix, `gfx_make_current` per frame (`129b42a`).

**Plans**: 4/4 plans complete
**Wave 1**

- [x] 05-01-PLAN.md — Retina coordinate authority + core macOS input normalization (PICK-01/02/03)

**Wave 2** *(depends on 05-01)*

- [x] 05-02-PLAN.md — Dialog/shortcut parity + tab-gating stability (PICK-04/05, DIG-05)

**Wave 3** *(depends on 05-01, 05-02)*

- [x] 05-03-PLAN.md — Landmark/anchor/curve/surface interaction parity + GPA compute parity (DIG-01/02/03/04, ANL-01)

**Wave 4** *(depends on 05-03)*

- [x] 05-04-PLAN.md — `.dgt` + export compatibility hardening and cross-platform byte-parity gate (DAT-01/02/03)

**Note**: DAT-03 remains a blocking bidirectional parity gate requiring off-box Windows evidence (D-16 recurring checkpoint). Windows-side artifact is ready: `testdgt_6_phase5test.DGT` (6 specimens, uniform surface counts) is verified locally and can go to Austin as-is; the return leg needs a macOS-authored `.dgt` opened on Windows.

**Note (GL context, `129b42a`)**: `gfx_make_current` was only ever called at `setWindow`. `wglMakeCurrent` and `-[NSOpenGLContext makeCurrentContext]` bind per *thread*, so any rgl plot on the R main thread silently unbound the engine's context: black canvas, every pick rejected, recoverable only by restarting GUImorph. `onDisplay` now rebinds per frame. This is a **prerequisite for Phase 6**, which puts rgl and the engine in the same process by design.

### Phase 6: rgl Result-Plot Fallback on macOS

**Goal**: Make GPA/PCA/mean-shape result plots render on macOS via an rgl NULL/`rglwidget` fallback, since interactive XQuartz rgl is broken on current macOS.
**Depends on**: Phase 5
**Requirements**: ANL-02
**Success Criteria** (what must be TRUE):

  1. Aligned-specimen, PCA morphospace, and mean-shape plots render on macOS via `options(rgl.useNULL = TRUE, rgl.printRglwidget = TRUE)` → `rglwidget()` (WebGL) instead of failing on broken XQuartz GLX.
  2. Plot functions are audited so they do not rely on `select3d()` / `rgl.snapshot()` (unsupported in NULL mode), or those usages are replaced.
  3. Windows build still works: result plots render unchanged on the Windows build.

**Plans**: 1/2 plans executed

**Wave 1**

- [x] 06-01-PLAN.md — ANL-02: add platform-guarded `.rgl_show()` helper (macOS `rglwidget()`→`saveWidget(selfcontained=FALSE)`→`browseURL()`→`close3d()`; Windows unchanged `rgl.bringtotop`) + `.isMacOS()`-guarded `options(rgl.useNULL=TRUE)` at startup, wire into `plotspecs`/`plotMeanShape`, promote `htmlwidgets` in DESCRIPTION, add `test-rgl-fallback-macos.R` (source-scan audit + headless widget smoke)

**Wave 2** *(depends on 06-01)*

- [ ] 06-02-PLAN.md — ANL-02/CMP-01: human-verify checkpoints — live macOS render of aligned-specimen + mean-shape widgets and PCA quartz window; off-box Windows result-plot regression

**Note**: Research (06-RESEARCH.md, HIGH/verified live) resolved the flag: neither 3-D plot function uses `select3d`/`rgl.snapshot`/`snapshot3d`, so ANL-02 criterion 2 is already satisfied (the audit test keeps it true). `plotPCA` is base-graphics via quartz — it needs a live confirmation, not an `rglwidget` rewrite (ROADMAP's "PCA via rglwidget" framing is a mismatch). Only `plotspecs` and `plotMeanShape` get the widget fallback. No new package installs. This phase corrects PROJECT.md's stale "macOS renders rgl plots today" assumption.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Aqua-Tk Gate + Rendering Seam | 5/5 | Complete   | 2026-07-13 |
| 2. Pathname Drawable Resolution | 1/1 | Complete   | 2026-07-15 |
| 3. Tri-Platform Build + Load + Drop GLUT | 1/1 | Complete (Windows verified; macOS `.dylib` build in Phase 4) | 2026-07-16 |
| 4. macOS NSGL Backend — First Light | 3/3 | Complete    | 2026-07-17 |
| 5. Retina Picking, Input & Parity | 4/4 | Complete    | 2026-07-19 |
| 6. rgl Result-Plot Fallback | 1/2 | In Progress|  |

## Notes

- **Hard ordering (non-negotiable):** the Aqua-Tk deployment gate (Phase 1) blocks all GL work; the seam must exist before any backend (1 → 2 → 3 → 4); Retina-correct picking (PICK-01, Phase 5) blocks all picking-based digitizing parity.
- **Deferred / out of milestone:** Offscreen FBO + Tk-photo-blit fallback backend (v2 escape hatch behind the same seam), Linux (GLX/X11) support, Metal-backed rendering.
- **Side-track (not a v1 requirement):** hardening the unsafe PLY parser (`strcpy`/`sscanf`/`sprintf`) under clang ASan/UBSan is parallelizable and independent of the port spine. It maps to no v1 requirement and is intentionally kept out of the port's blast radius; track separately if pursued.
