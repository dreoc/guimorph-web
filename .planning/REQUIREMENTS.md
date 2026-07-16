# Requirements — Milestone: macOS Cross-Platform Parity

**Goal:** GUImorph runs on macOS with full feature parity to the Windows build. Reuse the R/Tk + geomorph layers and the C draw/pick code; the work concentrates in the native window/context glue, macOS input/DPI behavior, build/load, and the rgl result-plot fallback.

**Source:** `.planning/research/SUMMARY.md` (+ STACK / FEATURES / ARCHITECTURE / PITFALLS), `.planning/PROJECT.md`, `.planning/codebase/`.

---

## v1 Requirements

### Deployment Gate (Aqua-Tk)

- [x] **GATE-01**: An R session on macOS can run against an **Aqua (Cocoa) Tk** (`tk windowingsystem` == `aqua`) and `load` a trivial Aqua Tk C extension — established before any GL work
- [x] **GATE-02**: A documented, reproducible "R + Aqua Tk" configuration for macOS researchers exists (which Tcl/Tk flavor ships and how)

### Rendering Backend (window + context)

- [x] **RND-01**: The native engine's window/context creation is isolated behind a platform seam (`gfx_backend.h`: create / make_current / swap / resize / destroy) with the existing Win32/WGL code moved behind it unchanged
- [x] **RND-02**: The R↔C bridge resolves the Tk drawable by frame **pathname** (not `winfo id`) so the macOS `NSView` is reachable via `Tk_MacOSXGetNSWindowForDrawable` — *verified on Windows R 4.6.1, 2026-07-15 (render + picking + digitizing, no regression)*
- [ ] **RND-03**: A macOS backend creates an `NSOpenGLContext` on Tk's embedded `NSView` using a **legacy 2.1 GL profile** and presents via `[NSOpenGLContext flushBuffer]`
- [ ] **RND-04**: Loading a PLY specimen renders the mesh in the embedded macOS viewport (not blank/black) — "first light"

### Build & Load

- [ ] **BLD-01**: A tri-platform CMake build produces `tkogl2.dylib` on macOS (Mach-O `-dynamiclib`), linking `-framework OpenGL/AppKit/Foundation`, without breaking the Windows MSVC build — *implemented 2026-07-15 (code complete, statically verified: WIN32/APPLE/else CMake + NSGL stub); pending Windows rebuild+regression; macOS `.dylib` build deferred to Phase 4 (no Mac host)*
- [ ] **BLD-02**: `.onLoad` computes the platform library extension (`.dll`/`.dylib`/`.so`) instead of hardcoding `.dll`, and surfaces load failure clearly instead of silently degrading — *implemented 2026-07-15 (code complete, statically verified: `[info sharedlibextension]` + loud `stop()`); pending Windows rebuild*
- [ ] **BLD-03**: The macOS library is built `universal2` (arm64 + x86_64) and the distribution path handles quarantine/library-validation (sign+notarize, or documented `xattr` workaround)
- [ ] **BLD-04**: GLUT dependency removed from the draw path (`glutSolidSphere` → `gluSphere`) so no GLUT is required on macOS — *implemented 2026-07-15 (code complete, statically verified: both spheres → `gluSphere`, glut vestige removed, labels Windows-guarded); pending Windows render regression*

### Input & Picking (macOS behavior)

- [ ] **PICK-01**: The GL viewport and screen→world unproject scale by `backingScaleFactor` (Retina), so the mesh fills the viewport and landmark picks land on-target on HiDPI displays
- [ ] **PICK-02**: Right-click delete works on macOS (handle aqua button-2/3 swap; bind `Button-2` + `Control-Button-1`) across all tabs
- [ ] **PICK-03**: Mouse-wheel zoom/scroll works on macOS (fix `%D` delta `/120` truncation)
- [ ] **PICK-04**: File open/save dialogs work on macOS for `.ply`/`.dgt`/`.pts` (custom extensions selectable; no crash on odd extensions)
- [ ] **PICK-05**: Keyboard accelerators have ⌘ (Cmd) equivalents alongside Ctrl on macOS

### Digitizing Parity

- [ ] **DIG-01**: Fixed-landmark digitizing on macOS — double-click place, drag-move, delete, undo, labels, colors, missing-landmark marking
- [ ] **DIG-02**: Anchor placement on macOS (dedicated tab, optional workflow)
- [ ] **DIG-03**: Curve definition/compute (3-landmark triplets per segment) on macOS
- [ ] **DIG-04**: Surface sliders / template build with downsampling on macOS
- [ ] **DIG-05**: Tab gating (unlock Surface Sliders/Curves/GPA after landmarks complete) behaves identically on macOS

### Analysis Parity

- [ ] **ANL-01**: GPA (`geomorph::gpagen`) with sliding, principal-axis alignment, and tangent-space options runs on macOS
- [ ] **ANL-02**: Result visualization (aligned specimens, PCA morphospace, mean shape) works on macOS via an rgl fallback (`rgl.useNULL`/`rglwidget`) since interactive XQuartz rgl is broken on current macOS

### Data & Compatibility

- [ ] **DAT-01**: `.dgt` session save/load/merge and add-PLY work on macOS
- [ ] **DAT-02**: `.csv` aligned-coordinate and `.rds` geomorph exports work on macOS
- [ ] **DAT-03**: `.dgt` files and exports are byte-compatible between the Windows and macOS builds (endianness/serialization verified)
- [ ] **CMP-01**: The Windows build continues to work at every phase (each phase has a "Windows still works" checkpoint)

---

## v2 / Deferred

- [ ] Linux (GLX/X11 or Wayland) support — follow-on milestone
- [ ] Metal-backed rendering (OpenGL deprecation escape hatch) — beyond parity
- [ ] Offscreen FBO + Tk-photo-blit rendering fallback — only if native NSGL embedding proves unstable

## Out of Scope

- Rewriting the `geomorph`/`Morpho`/`Rvcg` analysis pipeline — validated, reused as-is
- Replacing Tcl/Tk with another GUI toolkit — only native windowing glue changes
- Web/browser version — desktop-only delivery model

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| GATE-01 | Phase 1 | Complete |
| GATE-02 | Phase 1 | Complete |
| RND-01 | Phase 1 | Complete |
| RND-02 | Phase 2 | Complete (verified on Windows 2026-07-15) |
| RND-03 | Phase 4 | Pending |
| RND-04 | Phase 4 | Pending |
| BLD-01 | Phase 3 | Implemented (code complete 2026-07-15; Windows regression pending, macOS build Phase 4) |
| BLD-02 | Phase 3 | Implemented (code complete 2026-07-15; Windows rebuild pending) |
| BLD-03 | Phase 4 | Pending |
| BLD-04 | Phase 3 | Implemented (code complete 2026-07-15; Windows render regression pending) |
| PICK-01 | Phase 5 | Pending |
| PICK-02 | Phase 5 | Pending |
| PICK-03 | Phase 5 | Pending |
| PICK-04 | Phase 5 | Pending |
| PICK-05 | Phase 5 | Pending |
| DIG-01 | Phase 5 | Pending |
| DIG-02 | Phase 5 | Pending |
| DIG-03 | Phase 5 | Pending |
| DIG-04 | Phase 5 | Pending |
| DIG-05 | Phase 5 | Pending |
| ANL-01 | Phase 5 | Pending |
| ANL-02 | Phase 6 | Pending |
| DAT-01 | Phase 5 | Pending |
| DAT-02 | Phase 5 | Pending |
| DAT-03 | Phase 5 | Pending |
| CMP-01 | Phase 1 (recurs every phase) | Pending |

**Coverage:** 26/26 v1 requirements mapped — no orphans, no duplicates. CMP-01 (Windows-regression checkpoint) is owned by Phase 1 for mapping but enforced as a "Windows build still works" success criterion in every phase.
