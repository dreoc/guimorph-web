# Stack Research

**Domain:** macOS port of a native C/OpenGL rendering + digitizing engine embedded in a Tk widget, loaded by R via `tcltk`
**Researched:** 2026-07-12
**Confidence:** HIGH (rendering API, R's Tk model, GLFW/SDL embedding limits, Tcl load, Tk stubs) / MEDIUM (deployment path to get R using Aqua Tk; exact GL profile needed depends on the engine's actual GL calls)

---

## TL;DR (the decision)

**Recommended path: native Cocoa glue — replace `tcl_window.c`'s Win32 `HWND`+`WGL` with an `NSView`+`NSOpenGLContext` (CGL under the hood) obtained through Tk's public Aqua accessor `Tk_MacOSXGetNSWindowForDrawable` / `TkMacOSXGetNSViewForDrawable`. Keep the existing `ogl_*` draw code unchanged. This requires the R session to be using an *Aqua (Cocoa) build of Tcl/Tk*, not the X11 Tk that CRAN R ships by default.**

Why not the "portable layer" fork (GLFW/SDL): **GLFW and SDL create and own their own top-level windows; neither can render *into* an existing Tk-owned `NSView` reliably.** They are the wrong tool for "embed a GL surface inside someone else's widget," which is exactly what this engine does (mirroring the Win32 `HWND`-embed model). See "What NOT to Use."

The single most important discovery: **CRAN's R for macOS uses X11 Tk (via XQuartz), and XQuartz's OpenGL/GLX is broken on macOS Tahoe (26).** That X11/GLX path is the *same* dead path that killed rgl/geomorph interactive digitizing on modern macOS. So the port cannot go "through X11" — it must go through native Cocoa Tk. This reframes the milestone: it is as much a *Tcl/Tk-flavor* decision as a *GL-context* decision.

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Apple OpenGL** (system framework `OpenGL.framework`) | 4.1 (Metal-backed) | The GL implementation the existing `ogl_*` engine renders against | Deprecated since macOS 10.14 (2018) but **still present and functional in 2026** on Apple Silicon (M1–M4) and Intel; no removal date announced. Native (non-XQuartz) GL still works — it is XQuartz's GLX that is broken. Keeping OpenGL lets the C draw code be reused as-is. |
| **NSOpenGL / CGL** (`AppKit` + `OpenGL.framework`) | macOS 11+ SDK | Create the GL context and bind it to the Tk widget's `NSView` (the macOS analog of `WGL` + `HWND`) | `NSOpenGLContext` wraps a low-level CGL context and draws into an `NSView`'s drawable — the direct 1:1 replacement for the Win32 device-context/WGL setup in `tcl_window.c`. |
| **Tk (Aqua/Cocoa build)** | 8.6.14+ (prefer **9.0.x**) | The windowing system the engine embeds into | Aqua Tk exposes `Tk_MacOSXGetNSWindowForDrawable` (public stub slot 13) and the `TkMacOSXGetNSViewForDrawable` macro, giving the extension the `NSView` to attach GL to. **X11 Tk does not have these and routes GL through the broken XQuartz/GLX path.** Tk 9.0 has materially better Aqua/Retina (HiDPI) support. |
| **Tcl (matching Aqua build)** | 8.6.14+ / **9.0.x** | Loads the extension and runs the command bridge | Must match the Tk build ABI. The extension loads via `Tcl_InitStubs` exactly as on Windows; only the window/context code changes. |
| **CMake** | ≥ 3.16 (already required) | Build system for the `.dylib` | The project already builds via CMake on Windows; macOS adds an `APPLE` branch. `find_package(OpenGL)` + framework linking is well-trodden. Keeps one build system across platforms. |
| **Xcode Command Line Tools** (Apple Clang) | Xcode 15+/CLT 15+ | Compiler/linker + macOS SDK + frameworks | The reproducible, documented macOS toolchain analog to Windows MSVC. Clang defaults to `arm64` on Apple Silicon; universal (`arm64;x86_64`) builds are a one-line CMake setting. Objective-C(++) support is needed for the `NSView`/`NSOpenGL` glue file (`.m`/`.mm`). |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **Togl (NSOpenGL backend)** | 2.1 / MacPorts `Togl` 6.2.x with `+quartz` | Reference implementation (or drop-in widget) for a Tk OpenGL widget on Aqua | Study `toglNSOpenGL.c` as the canonical pattern for `NSView` + `NSOpenGLContext` + `[ctx setView:]` inside Tk. Consider adopting it wholesale only if replacing the bespoke embed is cheaper than porting `tcl_window.c`. Requires `tk-quartz`. |
| **GLU** (`OpenGL.framework` provides `libGLU`) | system | `gluPerspective`/`gluUnProject`-style helpers if the engine uses them | macOS bundles GLU inside `OpenGL.framework`; no separate lib. If the engine calls GLU (likely, for pick/unproject in digitizing), it's available without vendoring. |
| **freeglut / GLUT** | — | Replace the vendored Windows GLUT shim *only if* GLUT symbols are actually called | macOS has a deprecated `GLUT.framework`, but prefer to **eliminate the GLUT dependency** on macOS — it is deprecated and mostly used for windowing/text the native path already covers. Audit `third_party/glut_shim` usage first. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| **Xcode CLT (`clang`, `ld`, `otool`, `install_name_tool`)** | Compile/link/inspect the `.dylib` | `otool -L tkogl2.dylib` to verify framework linkage; `otool -hv` to confirm Mach-O type; `install_name_tool` to fix `@rpath`/install names if needed. |
| **`tclsh` / `wish` (Aqua build)** | Smoke-test `load` of the extension outside R | `load ./tkogl2.dylib Tkogl2` reproduces the R `.onLoad` path minus R; fastest inner loop. |
| **CMake `-DCMAKE_OSX_ARCHITECTURES`** | Universal2 builds | Set to `"arm64;x86_64"` to match CRAN's universal R; or build `arm64` only if targeting Apple Silicon first. |
| **MacPorts or Homebrew** | Obtain an Aqua Tcl/Tk for dev (`tk +quartz`) | Needed because system/XQuartz Tk won't do; also how `mac.r-project.org` publishes an aqua Tcl/Tk for R. |

## Installation / Build (macOS)

```bash
# 1. Toolchain (reproducible analog of Windows MSVC path)
xcode-select --install                 # Xcode Command Line Tools (Clang + macOS SDK + frameworks)

# 2. An Aqua (Cocoa) Tcl/Tk to build/link against and to run under.
#    Option A (dev): MacPorts
sudo port install tcl tk +quartz Togl +quartz
#    Option B: use the aqua Tcl/Tk that the R macOS toolchain publishes
#    (https://mac.r-project.org/ , /opt/R/arm64/ libs) — matches R builds.

# 3. Configure + build the native engine as a Tcl-loadable dylib
cmake -B build-macos -G "Unix Makefiles" \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build-macos --config Release
# Produces tkogl2.dylib (linked: -framework OpenGL -framework AppKit -framework Foundation
#                                  + Tcl/Tk stubs)

# 4. Verify it loads under a bare Aqua wish before wiring into R
echo 'load ./build-macos/tkogl2.dylib Tkogl2; puts loaded' | wish
```

CMake sketch for the `APPLE` branch (frameworks + Obj-C glue TU):

```cmake
if(APPLE)
  enable_language(OBJC)                       # for tcl_window_macos.m
  find_package(OpenGL REQUIRED)               # OpenGL.framework (GL + GLU)
  target_sources(tkogl2 PRIVATE src/tcl_window_macos.m)
  target_link_libraries(tkogl2 PRIVATE
    "-framework OpenGL" "-framework AppKit" "-framework Foundation"
    ${TCL_STUB_LIBRARY} ${TK_STUB_LIBRARY})
  set_target_properties(tkogl2 PROPERTIES
    PREFIX "" SUFFIX ".dylib"                  # Tcl load wants tkogl2.dylib
    LINK_FLAGS "-Wl,-undefined,dynamic_lookup")# Tcl/Tk symbols resolved at load via stubs
endif()
```

Loading in R stays structurally identical — only the located filename differs:

```r
# .onLoad: system.file("libs/tkogl2.dylib") then tcl("load", file, "Tkogl2")
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Native `NSOpenGL`/CGL glue in `tcl_window.c` | **Adopt Togl (NSOpenGL backend) as the widget** | If the team would rather depend on a maintained Tk-OpenGL widget than maintain bespoke embed code, and can rework the R layer to talk to a Togl widget instead of a raw frame. Adds a runtime dep but offloads the fragile embed. |
| Keep **OpenGL** (reuse `ogl_*`) | **Rewrite renderer in Metal (or via ANGLE/MoltenGL)** | Only if/when Apple actually removes OpenGL (no date announced) or GL 4.1's limits bite. Large rewrite; out of scope for parity milestone. A Metal-backed `CAMetalLayer` in the same `NSView` is the eventual escape hatch. |
| **Aqua Tk 9.0** | **Aqua Tk 8.6.14+** | If the target R build is pinned to Tcl/Tk 8.6 (CRAN currently ships 8.6.12) and rebuilding/relinking to 9.0 is impractical. 8.6 Aqua still exposes the needed `Tk_MacOSXGetNSWindowForDrawable`; you lose the 9.0 HiDPI/Retina improvements. |
| Legacy **GL 2.1** context (fixed-function) | **GL 3.2/4.1 Core profile** | If the engine is (or gets) modernized to shaders + VBOs. macOS Core profiles give more GL features but **remove all fixed-function/immediate-mode calls** — see Pitfall below. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **GLFW** for the embedded viewport | No API to render into an existing `NSView`; GLFW owns its window and its `GLFWContentView` handles events — swapping in a foreign view breaks GLFW's callbacks (confirmed by GLFW maintainers, issues #2031/#2774). Wrong model for "embed inside a Tk frame." | Native `NSOpenGL` bound to Tk's `NSView`. |
| **SDL2/SDL3** for the embedded viewport | `SDL_CreateWindowFrom`/`SDL_CreateWindowWithProperties(COCOA_VIEW_POINTER)` can *wrap* an `NSView` but in practice hijacks the window's `contentView` and mis-sizes sub-views (open SDL issues #12141, #3613); SDL's macOS focus is Metal, GL is de-emphasized. Heavyweight dep for no embedding benefit. | Native `NSOpenGL` bound to Tk's `NSView`. |
| **X11 Tk / XQuartz GLX path** | This is the path CRAN R uses by default and it is **broken on macOS Tahoe (26)** — `GLXBadContext`, the exact failure that killed rgl/geomorph digitizing. No fix expected (XQuartz is unmaintained). | Aqua/Cocoa Tk + native `NSOpenGL`. |
| **Depending on the vendored Windows GLUT shim on macOS** | `GLUT.framework` is deprecated; the shim is Win32-oriented. | Drop GLUT on macOS; use native context creation + GLU (in `OpenGL.framework`) for any unproject helpers. |
| **MinGW-style hand-rolled Tcl stub bootstrap** (the Windows workaround) | Not needed on macOS — Apple Clang links Tcl/Tk stubs cleanly with `-framework`/`-ltclstub`. Don't port that fragility. | Standard `Tcl_InitStubs` + real stub libs. |

## Stack Patterns by Variant

**If the goal is fastest parity with least new code (recommended):**
- Add `src/tcl_window_macos.m` implementing the same functions `tcl_window.c` exposes (create context, resize/reshape, make-current, swap-buffers, teardown), backed by `NSView` + `NSOpenGLContext`.
- `#ifdef __APPLE__` / `_WIN32` split in the window layer only; leave `ogl_*`, markers, dispatch untouched.
- Request a **legacy 2.1 profile** (`NSOpenGLPFAOpenGLProfile = NSOpenGLProfileVersionLegacy`) so the engine's fixed-function/immediate-mode GL keeps working (see Pitfall).
- Requires the R session to run against **Aqua Tk** — document this as a hard runtime prerequisite.

**If the R deployment cannot use Aqua Tk (must stay on CRAN's X11 Tk):**
- There is **no working native-GL embedding path** — X11 Tk gives you an X11 window, and XQuartz GLX is broken on Tahoe.
- Fallbacks are architectural, not stack: (a) ship/require an R built against Aqua Tk (e.g. via `mac.r-project.org` toolchain, or a bundled Tcl/Tk), or (b) render off-thread/off-process and display via a different surface. Flag for deeper research in its own phase.

**If a longer-horizon, deprecation-proof renderer is wanted:**
- Keep the same `NSView` embed, but back it with a `CAMetalLayer` and port `ogl_*` to Metal (or run GL over ANGLE→Metal). Large effort; defer past the parity milestone.

## Version Compatibility

| Component | Compatible With | Notes |
|-----------|-----------------|-------|
| Apple OpenGL 4.1 | Apple Silicon (M1–M4) + Intel, macOS 11–26 | Max GL version on macOS; **no compatibility profile** — only Legacy (2.1) or Core (3.2/4.1). Fixed-function GL requires the Legacy 2.1 context. |
| `Tk_MacOSXGetNSWindowForDrawable` | Aqua Tk 8.6 and 9.0 (public stub slot 13) | Present in both; `TkMacOSXGetNSViewForDrawable` is the macro that yields the `NSView`. **Absent in X11 Tk.** |
| CRAN R 4.6.1 (macOS) | Tcl/Tk **8.6.12 X11** + XQuartz | Default R build is X11 Tk — incompatible with the native path without switching Tk flavor. This is the central compatibility gap. |
| Tcl `load` | `.dylib` (or `.bundle`) | `info sharedlibextension` returns `.dylib`; either Mach-O `MH_DYLIB` or `MH_BUNDLE` loads. Build with `-dynamiclib` → `.dylib`. |
| Universal2 dylib | universal + thin (arm64 / x86_64) R | `-DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"` yields a fat binary loadable by both R builds. |
| `.dgt`/`.csv`/`.rds` files | Windows build | Endianness/format must stay byte-compatible; verify the C serializers are endianness-neutral (both targets are little-endian, so low risk). |

## Key Risks / Pitfalls to Flag for Roadmap

1. **Aqua-Tk prerequisite is the real project pivot** (HIGH). The native path only works if R's `tcltk` is talking to Aqua Tk. CRAN R ships X11 Tk. Determining/packaging the supported "R + Aqua Tk" configuration deserves its own early phase and gates everything else. Verify at runtime with `tclvalue(.Tcl("tk windowingsystem"))` → must be `aqua`, not `x11`.
2. **Fixed-function GL vs Core profile** (MEDIUM). If the 2020-era engine uses `glBegin/glEnd`, matrix stack, `glLight`, etc. (very likely given GLUT usage), macOS must use the **Legacy 2.1 profile**; a Core 3.2/4.1 context will silently no-op those calls (black mesh). This is thematically the same class of bug as the Windows MinGW black-mesh issue — budget for it.
3. **Retina/HiDPI coordinate scaling** (MEDIUM). `NSView` points ≠ pixels on Retina; digitizing pick/unproject math (screen→world in `addDot`) must use backing-store pixel dimensions (`convertRectToBacking:` / `wantsBestResolutionOpenGLSurface`). Wrong scaling = landmarks placed off-cursor.
4. **NSOpenGL itself is deprecated** (LOW, informational). It still compiles/runs; expect deprecation warnings — suppress, don't panic. Removal not announced.
5. **Threading** (LOW–MEDIUM). Cocoa/AppKit view + context work must occur on the main thread; R/Tk already runs single-threaded on the main event loop, so this aligns, but any deferred redraw must dispatch to main.

## Sources

- Apple Developer Forums — "Are OpenGL and OpenCL supported on Apple silicon?" (thread/694866) & thread/725247 — OpenGL deprecated since 10.14, still runs on Apple Silicon, GL 4.1 over Metal, no removal date. **HIGH**
- CRAN *R for macOS* download page + *RMacOSX-FAQ* §6 Tcl/Tk — R 4.6.1 ships **Tcl/Tk 8.6.12 X11**, requires XQuartz; Aqua Tk "does not work in R.app". **HIGH**
- dmurdoch/rgl issue #488, rgl README, geomorph-r-package group thread — XQuartz/GLX OpenGL **broken on macOS Tahoe**, `GLXBadContext`; rgl dropped native Apple GL years ago; only X11/WGL/null backends remain. **HIGH**
- tcltk/tk `tkMacOSXSubwindows.c`, `tkMacOSXPrivate.h` (9.0.3), `tkPlatDecls.h` (9.0.3) — `Tk_MacOSXGetNSWindowForDrawable` public stub (slot 13) + `TkMacOSXGetNSViewForDrawable` macro, Aqua-only. **HIGH**
- Togl (`togl.sourceforge.net`), netgen `Togl2.1/togl.c`, MacPorts `Togl +quartz` — NSOpenGL backend (`TOGL_NSOPENGL`), Tk ≥ 8.6 for Cocoa, `[NSOpenGLContext setView:]` pattern; `tk-quartz`. **HIGH**
- glfw/glfw issues #2031, #2774; GLFW native-access docs — GLFW cannot embed into an existing `NSView`; owns its window/events. **HIGH**
- libsdl-org/SDL issues #12141, #3613; SDL3 `SDL_CreateWindowWithProperties` docs — external-`NSView` embedding hijacks `contentView`/mis-sizes; GL de-emphasized. **HIGH** (that it's unreliable)
- tcltk/tcl `macosx/README`; Tcl wiki "Building an extension for Tcl under Mac OS X"; SO 2339679 — Tcl loads `.dylib` (`MH_DYLIB`) or `.bundle` (`MH_BUNDLE`); `-dynamiclib` + `-framework Tcl/Tk`. **HIGH**

---
*Stack research for: macOS native-GL embedding into Tk for GUImorph's digitizing engine*
*Researched: 2026-07-12*
