# Architecture Research

**Domain:** Cross-platform native windowing/GL glue for an embedded OpenGL viewport in a Tcl/Tk desktop app (R package `tkogl2` engine → macOS parity)
**Researched:** 2026-07-12
**Confidence:** HIGH for platform APIs (verified against Tk source + Apple docs); MEDIUM for sequencing/tradeoff judgment (engineering opinion grounded in the codebase)

> Scope note: this is a **brownfield porting** architecture, not a greenfield domain survey. The recommendation is additive: keep the working Windows/WGL path byte-for-byte, isolate the platform-specific windowing/GL glue behind one small seam, and add a macOS backend behind that seam. The OpenGL **draw** code (`ogl_*`, `marker_*`, `curve_*`) and the **Tcl command bridge** (8 commands) change as little as possible.

---

## Standard Architecture

### System Overview (target state)

```
┌───────────────────────────────────────────────────────────────────────────┐
│                    R GUI / Controller Layer (unchanged)                      │
│  Tk/ttk widgets, canvasFrame, event bindings, S3 dispatch on env `e`         │
│  R/3dDigitize.*.r     R/rtkogl.R  (only .onLoad lib-path + set("window","id")│
│                                    pass a pathname instead of winfo id)      │
└───────────────┬──────────────────────────────────────────────┬─────────────┘
                │ tcl("setWindow"/"add"/...) — SAME 8 commands   │ geomorph (unchanged)
                ▼                                                ▼
┌───────────────────────────────────────┐        ┌──────────────────────────────┐
│   R ↔ C Bridge (rtkogl.R) — unchanged  │        │   Analysis Layer (R pkgs)     │
│   protocol; `set("window","id",frame)` │        │   geomorph / Morpho / Rvcg    │
│   now sends the widget PATHNAME        │        │   (already works on macOS)    │
└───────────────┬───────────────────────┘        └──────────────────────────────┘
                │ Tcl_CreateObjCommand dispatch (8 commands, unchanged)
                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│              Native C / OpenGL Engine  →  tkogl2.dll / tkogl2.so             │
│                                                                              │
│  ┌────────────── PLATFORM-NEUTRAL CORE (compiles everywhere, unchanged) ───┐ │
│  │  tcl_init.c  tcl_dispatch.c  tcl_state.c  tcl_log.c                      │ │
│  │  marker.c  curve_ZARF_9.c                                               │ │
│  │  ogl_ZARF9.c  ogl_model_*.c   ← fixed-function GL draw + picking         │ │
│  │      (gluUnProject / glReadPixels / glOrtho / glRotatef — portable)      │ │
│  └────────────────────────────────────────────┬───────────────────────────┘ │
│                                                │ calls only the seam         │
│  ┌──────────────── NEW SEAM: gfx_backend.h (thin platform interface) ───────┐ │
│  │  gfx_surface_create / _make_current / _swap / _resize / _destroy         │ │
│  └───────┬──────────────────────────┬───────────────────────┬──────────────┘ │
│          ▼                          ▼                        ▼                │
│  gfx_backend_wgl.c          gfx_backend_nsgl.m       gfx_backend_glx.c        │
│  (Windows, from             (macOS, NEW —            (Linux, DEFERRED —       │
│   today's tcl_window.c)      NSOpenGL + NSView)       stub only)              │
│  HDC/HGLRC/HWND              NSOpenGLContext/NSView   GLXContext              │
└───────────────────────────────────────────────────────────────────────────┘
                │ obtains a drawable from Tk (per platform)
                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  Tk drawable acquisition (the crux of the port):                            │
│   Windows: Tk_GetHWND(Tk_WindowId(tkwin))            → HWND                  │
│   macOS:   Tk_MacOSXGetNSWindowForDrawable(              → NSWindow*         │
│               Tk_WindowId(tkwin)) ; [win contentView]   → NSView            │
└───────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Platform-neutral core (`tcl_*`, `marker.c`, `curve_*`, `ogl_*`) | Own mesh/marker/curve state, fixed-function GL drawing, picking, Tcl command handling | Existing C; **no platform `#ifdef`s** — talks only to the seam |
| `gfx_backend.h` (the seam) | Abstract window/context lifecycle: create context bound to a Tk drawable, make current, swap, resize, destroy | Small C header + opaque `gfx_surface` handle; one `.c`/`.m` per platform |
| `gfx_backend_wgl.c` | Windows GL context (extracted verbatim from `tcl_window.c`) | `GetDC`/`ChoosePixelFormat`/`wglCreateContext`/`wglMakeCurrent`/`SwapBuffers` |
| `gfx_backend_nsgl.m` | macOS GL context embedded in the Tk frame's NSView | `NSOpenGLPixelFormat` (legacy 2.1 profile) + `NSOpenGLContext`; `addSubview:`; `flushBuffer` |
| Tk drawable resolver (in `tcl_window.c`) | Turn the widget pathname into a per-platform drawable | `Tk_NameToWindow` → `Tk_WindowId`; branch on platform to HWND / NSView |
| R bridge (`rtkogl.R`) | Marshal GUI intents; select the loadable library per OS; pass frame pathname | `.onLoad` picks `.dll`/`.so`; `set("window","id",frame)` |

---

## Recommended Project Structure

```
tkogl2/
├── CMakeLists.txt                 # tri-platform (WIN32 / APPLE / UNIX) selection
├── cmake/
│   └── mingw-w64-x86_64.cmake     # existing (unsupported)
├── src/
│   ├── gfx_backend.h              # NEW — the platform seam (single interface)
│   ├── gfx_backend_wgl.c          # NEW — WGL/HWND code moved out of tcl_window.c
│   ├── gfx_backend_nsgl.m         # NEW — Objective-C NSOpenGL macOS backend
│   ├── gfx_backend_glx.c          # NEW (stub) — Linux, deferred milestone
│   ├── tcl_window.c               # SLIMMED — Tk drawable resolution + setWindow cmd,
│   │                              #           now calls gfx_backend.h (no WGL inline)
│   ├── tcl_init.c  tcl_dispatch.c tcl_state.c tcl_log.c   # platform-neutral (unchanged)
│   ├── marker.c  curve_ZARF_9.c                            # unchanged
│   ├── ogl_ZARF9.c  ogl_model_ZARF_9.c  ogl_model_ply_ZARF_9.c  # draw/pick (tiny change:
│   │                              #  drop glutSolidSphere → gluSphere; remove swap #ifdef)
│   └── def_ZARF_9.h / RunTime_Defines_ZARF_9.h            # config; platform includes gated
└── include/{tcl_include,tk_include}/  # + macOS Tk PRIVATE headers (tkMacOSXInt.h,
                                       #   tkMacOSXPrivate.h) for the NSView accessor
```

R package side:

```
GUImorphDevelopment/
├── R/rtkogl.R                     # .onLoad: choose libs/<arch>/tkogl2.<dll|so> by OS
├── inst/libs/
│   ├── x64/tkogl2.dll             # Windows (committed, unchanged)
│   └── mac/tkogl2.so              # NEW — macOS build artifact (arm64 + x86_64)
```

### Structure Rationale

- **One seam, many backends.** `gfx_backend.h` is the *only* file the core includes for windowing; each platform is one translation unit. Adding Linux later = one more `.c`, zero core edits.
- **Draw code stays platform-neutral.** `ogl_*` uses only portable GL (glOrtho, glRotatef, gluUnProject, glReadPixels). The only non-portable calls today are `SwapBuffers`/`glXSwapBuffers` (move behind the seam) and `glutSolidSphere` (replace with a GLU quadric to drop the GLUT dependency on macOS, where Apple's GLUT is deprecated/awkward to link).
- **`tcl_window.c` becomes the Tk-drawable resolver + the `setWindow` command handler**, delegating all GL to the seam. This localizes the one genuinely platform-divergent decision (how to get a drawable from Tk).
- **macOS backend is `.m` (Objective-C).** NSOpenGL/NSView require the Cocoa runtime; the `.m` file is the *only* Objective-C in the tree, keeping the C core clean.

---

## Architectural Patterns

### Pattern 1: Thin platform seam (opaque handle + function set) — RECOMMENDED

**What:** A minimal C interface that every platform implements; the core owns an opaque `gfx_surface*` and never sees `HDC`/`NSOpenGLContext`.

**When to use:** The primary approach — it isolates the exact layer that differs (window+context) while leaving draw/pick/state untouched.

**Trade-offs:** (+) Smallest possible blast radius; Windows behavior is preserved by construction (its code just moves). (+) Draw code and Tcl bridge essentially unchanged. (−) Requires disciplined removal of the existing `#ifdef _WIN32` swap logic from `onDisplay`.

**Example (the interface shape):**
```c
/* gfx_backend.h — the entire platform boundary */
typedef struct gfx_surface gfx_surface;   /* opaque; defined per backend */

/* tk_drawable is the platform token already resolved in tcl_window.c:
   HWND on Windows, NSView* on macOS. w/h are BACKING pixels. */
int  gfx_surface_create (gfx_surface **out, void *tk_drawable, int w, int h);
int  gfx_make_current   (gfx_surface *s);   /* wglMakeCurrent / [ctx makeCurrentContext] */
void gfx_swap_buffers   (gfx_surface *s);   /* SwapBuffers(dc) / [ctx flushBuffer]        */
void gfx_resize         (gfx_surface *s, int w, int h);
void gfx_surface_destroy(gfx_surface *s);
```
```c
/* onDisplay() end — replaces the current #ifdef _WIN32 / __linux__ block */
glFlush();
gfx_swap_buffers(g_surface);   /* one call, no platform #ifdef in draw code */
```

### Pattern 2: Uniform Tk-drawable resolution via the widget pathname — RECOMMENDED

**What:** Instead of R sending `winfo id` (an HWND integer that is **meaningless on macOS**), R sends the frame's Tk pathname; C resolves it with Tk stubs and branches per platform.

**When to use:** Mandatory for macOS — `winfo id` on the Mac "has no meaning outside Tk" (returns an internal MacDrawable pointer, often negative). The real NSView is reachable only via Tk's private accessor.

**Trade-offs:** (+) Removes the fragile 32-bit-int→HWND cast that the code already blames for blank viewports (`tcl_window.c:97-105`). (+) One code path for both platforms. (−) The extension must now also initialize **Tk** stubs (`Tk_InitStubs`) and link `tkstub`, and on macOS include Tk **private** headers.

**Example:**
```c
/* tcl_window.c — setWindow "id" handler (cross-platform) */
Tk_Window tkwin = Tk_NameToWindow(interp, pathName, Tk_MainWindow(interp));
Drawable  d     = Tk_WindowId(tkwin);
#if defined(_WIN32)
    void *native = (void *)Tk_GetHWND(d);                       /* HWND   */
#elif defined(__APPLE__)
    NSWindow *w  = Tk_MacOSXGetNSWindowForDrawable(d);          /* public C fn */
    void *native = (void *)[w contentView];                      /* NSView */
#endif
gfx_surface_create(&g_surface, native, width, height);
```

### Pattern 3: Offscreen FBO + Tk photo blit — VIABLE FALLBACK (not primary)

**What:** Render into an offscreen framebuffer on a view-less context (CGL on macOS), `glReadPixels` the color buffer, and push it into a Tk `photo` image via `Tk_PhotoPutBlock`; a Tk canvas/label displays it. **No native-window embedding at all.**

**When to use:** As a documented escape hatch if NSView embedding proves unstable across Tk 8.6/9.0, or if a future Tk drops the private accessor. Also the natural Linux/headless path.

**Trade-offs:**
- (+) Maximally portable — identical on every platform; **no Tk private headers, no embedding fragility**. Picking still works (depth readback on the FBO is actually cleaner).
- (+) Sidesteps the whole Tk-drawable/NSView problem — a real answer to "can we avoid native-window embedding?" → **Yes, technically.**
- (−) Per-frame CPU readback + RGBA conversion + Tk image copy is slower than a GPU buffer swap. Fine for click-to-place digitizing and occasional rotate; noticeably laggier than native for continuous drag-rotate of a dense mesh.
- (−) Pushes churn into the **R GUI layer** (swap the GL frame for an image widget) and adds a new pixel-transport path to the bridge — i.e. it changes *more* of the bridge/GUI than native embedding does, which cuts against the "minimize churn to draw code + Tcl bridge" goal.
- (−) You still need a GL context; "no window" ≠ "no context." macOS needs a CGL/NSOpenGL pbuffer/FBO context.

**Verdict:** Keep it in the back pocket. Recommend native NSGL embedding as primary because it leaves the R side and the bridge essentially untouched; adopt offscreen-blit only if embedding stability forces it (or as the eventual unify-all-platforms play).

### Pattern 4: Request the legacy (2.1) GL profile on macOS — REQUIRED for this engine

**What:** macOS offers only two profile families: a **legacy/compatibility profile (OpenGL 2.1)** that includes the full fixed-function pipeline, and **core profiles (3.2 / up to 4.1)** that do **not** support `glBegin`, `glOrtho`, `glRotatef`, `gluUnProject`, immediate mode, etc. GUImorph is entirely fixed-function.

**When to use:** Always, on the macOS backend — request `NSOpenGLProfileVersionLegacy`. A core-profile context would compile but render nothing (the exact "black viewport" failure mode).

**Trade-offs:** (+) Zero draw-code rewrite — the fixed-function pipeline just works. (−) Caps you at GL 2.1 on macOS, but the engine needs nothing newer. Survives Apple's deprecation (OpenGL is deprecated since 10.14 but **still present on Apple Silicon + Intel**, capped at 4.1, no announced removal).

---

## Data Flow

### Context creation

```
R ui(): build canvasFrame → tcl("update") → set("window","id", canvasFrame)
      → tcl("setWindow","id", <frame pathname>)
C setWindow:  Tk_NameToWindow → Tk_WindowId → [platform] resolve drawable
      WGL : hwnd = Tk_GetHWND(d); GetDC; ChoosePixelFormat; wglCreateContext; wglMakeCurrent
      NSGL: view = [Tk_MacOSXGetNSWindowForDrawable(d) contentView];
            pf = NSOpenGLPixelFormat(legacy 2.1, doublebuffer, depth);
            ctx = NSOpenGLContext(pf); child = ToglNSView; [view addSubview:child];
            [ctx setView:child]; [ctx makeCurrentContext];
      → ogl_init()
R : set("window","size", w, h) → glViewport / glOrtho
      (macOS: multiply w,h by [view backingScaleFactor] → BACKING pixels)
```

### Draw

```
any Tcl handler → onDisplay():
   glClear; glPushMatrix; rotate/scale/translate(context[model_index]);
   ogl_drawModel(); switch(showModel){ drawDots / drawAnchors / drawCurves / downsample };
   glPopMatrix; glFlush;
   gfx_swap_buffers(g_surface)      ← WGL: SwapBuffers(dc)  |  NSGL: [ctx flushBuffer]
```

### Picking (double-click → 3D landmark) — platform-agnostic once context is current

```
R onLeftBtnPress(x,y) → add("landmark", x, y, -) → C ogl_getObjCoordinate(x,y):
   gfx_make_current(g_surface);
   glGet MODELVIEW / PROJECTION / VIEWPORT;
   winY = viewport[3] - y;            ← MUST be in BACKING pixels on macOS (retina)
   glReadPixels(x, winY, 1,1, GL_DEPTH_COMPONENT, ...);
   gluUnProject(winX,winY,winZ, ...) → objX,objY,objZ → marker_add(&g_landmarks)
```

The pick path is **identical across platforms** — this is why isolating only window/context (not draw/pick) is the right cut line. The single macOS-specific hazard is DPI scale (see Anti-Patterns).

---

## Backend / Portability Matrix (repurposed "scaling" section)

| Backend | Status this milestone | Context API | Drawable source | Library linkage |
|---------|-----------------------|-------------|-----------------|-----------------|
| Windows / WGL | Keep working (extract, don't rewrite) | `wglCreateContext` | `Tk_GetHWND(Tk_WindowId)` | `opengl32 glu32 gdi32 user32`, Tcl+Tk stubs |
| macOS / NSGL | **Build (primary target)** | `NSOpenGLContext` (legacy 2.1) | `Tk_MacOSXGetNSWindowForDrawable` → `contentView` | `-framework OpenGL -framework AppKit -framework Foundation`; Tk private headers |
| macOS / offscreen-blit | Fallback only | `CGLCreateContext` + FBO | none (view-less) | `-framework OpenGL`; `Tk_PhotoPutBlock` |
| Linux / GLX | **Deferred** (next milestone) | `glXCreateContext` | X11 window id (`winfo id` works) | `GL GLU X11` |

### Priorities

1. **First risk:** getting *any* correct pixels on macOS → solved by NSGL legacy-profile embedding.
2. **Second risk:** landmark/cursor alignment under retina scaling → handle `backingScaleFactor` in viewport + pick.
3. **Third risk:** Tk-version drift of the private NSView accessor → mitigated by the offscreen-blit fallback existing behind the same seam.

---

## Anti-Patterns

### Anti-Pattern 1: Passing `winfo id` and casting to a native handle on macOS

**What people do:** Reuse the Windows path — send `tkwinfo("id", frame)` and cast to a window handle.
**Why it's wrong:** On macOS `winfo id` returns an internal Tk MacDrawable pointer with "no meaning outside Tk" (frequently a negative int). Casting it yields garbage → black/blank viewport or crash.
**Do this instead:** Send the widget **pathname**; in C resolve `Tk_WindowId` and call `Tk_MacOSXGetNSWindowForDrawable(...)` → `[contentView]`.

### Anti-Pattern 2: Requesting a core (3.2/4.1) profile for fixed-function code

**What people do:** Ask for "modern OpenGL" on macOS to look future-proof.
**Why it's wrong:** Core profiles remove `glBegin`/`glOrtho`/`glRotatef`/`gluUnProject`/immediate mode — every call this engine makes. Renders nothing.
**Do this instead:** Request `NSOpenGLProfileVersionLegacy` (2.1). It carries the full fixed-function pipeline the engine relies on.

### Anti-Pattern 3: Ignoring the retina backing-scale factor

**What people do:** Use point sizes for `glViewport` and for the `viewport[3] - y` pick flip.
**Why it's wrong:** With `wantsBestResolutionOpenGLSurface`, the framebuffer is 2× the point size; mismatched units place landmarks offset from the cursor — the exact class of bug already documented for Windows resize (`3dDigitize.main.r:723-734`).
**Do this instead:** Multiply width/height and mouse coords by `[view backingScaleFactor]` (or disable best-resolution surface to force 1:1). Keep `set("window","size",...)` in backing pixels.

### Anti-Pattern 4: Scattering `#ifdef __APPLE__` through the draw/dispatch code

**What people do:** Sprinkle platform conditionals across `onDisplay`, `tcl_dispatch.c`, `ogl_*`.
**Why it's wrong:** Recreates the god-file problem the codebase already fought (Phase 7-9 modular split); every future platform multiplies the conditionals.
**Do this instead:** Confine all platform code to `gfx_backend_*.{c,m}` + the drawable resolver in `tcl_window.c`. Core files stay `#ifdef`-free.

### Anti-Pattern 5: Keeping the `glutSolidSphere` dependency on macOS

**What people do:** Link Apple's GLUT.framework to satisfy the two `glutSolidSphere` calls.
**Why it's wrong:** Apple's GLUT is deprecated and awkward to link; it drags a whole framework in for one primitive.
**Do this instead:** Replace `glutSolidSphere(r,10,10)` with a `gluSphere` on a cached `gluNewQuadric()` (both are in GLU, already linked). Contained ~2-line change in `ogl_model_ZARF_9.c`.

---

## Integration Points

### External / platform boundaries

| Boundary | Integration Pattern | Notes |
|----------|---------------------|-------|
| Tk frame ↔ GL context | `Tk_MacOSXGetNSWindowForDrawable` (macOS) / `Tk_GetHWND` (Win) | macOS needs Tk **private** headers (`tkMacOSXInt.h`, `tkMacOSXPrivate.h`); Apple's Tk framework omits them — vendor them (as done for `tcl_include`/`tk_include`). Requires Tk ≥ 8.6. |
| Extension ↔ Tcl/Tk | `Tcl_InitStubs` (+ add `Tk_InitStubs`) | Currently only Tcl stubs are used; drawable resolution needs Tk stubs → link `tkstub`. |
| R ↔ loadable library | `.onLoad` → `tcl("load", file, "Tkogl2")` | Generalize the hardcoded `libs/x64/tkogl2.dll` to pick `.so` on macOS by `Sys.info()[["sysname"]]`; ship under `inst/libs/mac/`. |
| Prior art | **Togl 2.x** (`TOGL_NSOPENGL`) | Reference implementation of exactly this: a `ToglNSView : NSView` bound to an `NSOpenGLContext`, Tk ≥ 8.6. Validates the NSGL approach and is a source to mine for retina/resize handling. |

### CMake structuring (tri-platform)

```cmake
add_library(tkogl2 SHARED
    ${SRC}/tcl_init.c ${SRC}/tcl_dispatch.c ${SRC}/tcl_window.c ${SRC}/tcl_state.c
    ${SRC}/tcl_log.c  ${SRC}/ogl_ZARF9.c ${SRC}/ogl_model_ZARF_9.c
    ${SRC}/ogl_model_ply_ZARF_9.c ${SRC}/curve_ZARF_9.c ${SRC}/marker.c
    ${SRC}/StatisticsFunction_ZARF_9.c)

if(WIN32)
    target_sources(tkogl2 PRIVATE ${SRC}/gfx_backend_wgl.c)
    target_link_libraries(tkogl2 PRIVATE opengl32 glu32 gdi32 user32 ${TCL_STUB} ${TK_STUB})
    set_target_properties(tkogl2 PROPERTIES PREFIX "" SUFFIX ".dll")
elseif(APPLE)
    enable_language(OBJC)
    target_sources(tkogl2 PRIVATE ${SRC}/gfx_backend_nsgl.m)
    target_include_directories(tkogl2 PRIVATE ${SRC}/../include/tk_macosx_private)
    target_link_libraries(tkogl2 PRIVATE
        "-framework OpenGL" "-framework AppKit" "-framework Foundation" ${TCL_STUB} ${TK_STUB})
    set_target_properties(tkogl2 PROPERTIES PREFIX "" SUFFIX ".so")   # R loads .so on macOS
    set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")                       # universal
else() # UNIX (deferred)
    target_sources(tkogl2 PRIVATE ${SRC}/gfx_backend_glx.c)
    target_link_libraries(tkogl2 PRIVATE GL GLU X11 ${TCL_STUB} ${TK_STUB})
endif()
```

---

## Suggested Build Order (dependency-ordered — for the roadmapper)

> Each step ends with a **checkpoint that proves Windows still works**, honoring the "additive, don't break Windows" constraint.

1. **Extract the seam (Windows-only, zero behavior change).** Add `gfx_backend.h`; move all WGL/HDC/HGLRC/`SwapBuffers` code out of `tcl_window.c`/`onDisplay` into `gfx_backend_wgl.c`; route the core through the seam. **Depends on:** nothing. **Checkpoint:** rebuilt Windows DLL renders identically. *De-risks the abstraction before any macOS code exists.*

2. **Unify Tk-drawable resolution + add Tk stubs.** Change `setWindow "id"` to accept a pathname; resolve `Tk_NameToWindow`/`Tk_WindowId`; derive HWND via `Tk_GetHWND`; add `Tk_InitStubs`, link `tkstub`; update R `set("window","id",frame)` to pass the pathname. **Depends on:** 1. **Checkpoint:** Windows still renders (now via the pathname path). *Removes the fragile int→HWND cast and is the prerequisite for reaching an NSView.*

3. **Tri-platform CMake + R loader + drop GLUT.** Add `WIN32/APPLE/UNIX` branches, framework linkage, `.so` naming, universal `CMAKE_OSX_ARCHITECTURES`; vendor Tk private headers; generalize `.onLoad` lib path; replace `glutSolidSphere`→`gluSphere`. **Depends on:** 1. **Checkpoint:** macOS build *compiles* (with a stub backend) and Windows unaffected. *Establishes the toolchain before writing Cocoa code.*

4. **macOS NSGL backend — first light.** Implement `gfx_backend_nsgl.m`: legacy-2.1 `NSOpenGLPixelFormat`, `NSOpenGLContext`, child `NSView` via `[contentView addSubview:]`, `makeCurrent`, `flushBuffer`; handle `backingScaleFactor` in create/resize. **Depends on:** 2, 3. **Checkpoint:** a PLY mesh renders (not black) in the digitizing viewport on macOS.

5. **macOS interaction + parity hardening.** DPI-correct picking (`viewport[3]-y` in backing pixels), landmark place/move/delete/undo, anchors, curves, surface sliders, resize; verify `.dgt` save/load and `.csv`/`.rds` export are byte-compatible with Windows. **Depends on:** 4. **Checkpoint:** full digitizing workflow parity on macOS.

6. **(Optional) Offscreen-blit fallback backend.** Only if NSView embedding proves unstable across Tk versions: implement CGL+FBO+`Tk_PhotoPutBlock` behind the same seam. **Depends on:** 1 (seam). **Checkpoint:** documented, switchable escape hatch.

**Ordering rationale:** the seam must exist before any backend (1 before 4); the NSView is unreachable without pathname-based drawable resolution (2 before 4); Cocoa code cannot compile/link without the CMake+framework scaffolding (3 before 4); interaction correctness is only meaningful after first light (5 after 4); the portable fallback is decoupled and last (6).

---

## Sources

- Tk source, `macosx/tkMacOSXSubwindows.c` — `Tk_MacOSXGetNSWindowForDrawable(Drawable)` returns the `NSWindow*`; `[win contentView]` → NSView; `TkMacOSXGetNSViewForDrawable`. (github.com/tcltk/tk) — **HIGH**
- Tk private headers `tkMacOSXPrivate.h` / `tkMacOSXInt.h` — macro/accessor surface; `MacDrawable` layout (fossies.org tk9.0.3 docs) — **HIGH**
- Tk manual + cefpython #308 — `winfo id` on macOS "has no meaning outside Tk" (often negative) — **HIGH**
- Togl 2.1 `togl.c` (`TOGL_NSOPENGL`) + MacPorts `x11/Togl` Portfile — working NSOpenGL/NSView Tk-embedding prior art; requires Tk ≥ 8.6; `-DTOGL_NSOPENGL`, `-framework OpenGL` — **HIGH**
- Apple Developer Forums + Ars Technica (2024) — OpenGL deprecated since macOS 10.14, still available on Apple Silicon (native arm64 + Rosetta), capped at **OpenGL 4.1**, no removal date; core profiles lack fixed-function → use legacy 2.1 — **HIGH**
- GUImorph codebase: `tcl_window.c` (WGL seam + int→HWND-cast bug note), `tcl_dispatch.c:3534-3603` (`onDisplay` swap `#ifdef`), `ogl_ZARF9.c:112-150` (pick), `ogl_model_ZARF_9.c:239,381` (`glutSolidSphere`), `rtkogl.R:591-616` + `3dDigitize.main.r:717-759` (drawable handoff, resize/offset), `CMakeLists.txt` — **HIGH**

---
*Architecture research for: cross-platform native windowing/GL glue (macOS parity for the tkogl2 engine)*
*Researched: 2026-07-12*
