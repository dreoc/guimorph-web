---
phase: 03-tri-platform-build-generalized-load-drop-glut
plan: 01
subsystem: infra
tags: [cmake, tri-platform, dylib, nsgl, cocoa, objc, glut-removal, gluSphere, onload, sharedlibextension, bld-01, bld-02, bld-04]

# Dependency graph
requires:
  - phase: 02-pathname-based-tk-drawable-resolution (Plan 01)
    provides: pathname drawable resolution producing an NSWindow* via Tk_MacOSXGetNSWindowForDrawable behind MAC_OSX_TK/__APPLE__; Tk-stub linkage; seam-neutral void* to gfx_create
provides:
  - Tri-platform CMake (WIN32 / APPLE / else-FATAL_ERROR) emitting tkogl2.dylib (Mach-O -dynamiclib) on macOS against -framework OpenGL/AppKit/Foundation, Windows MSVC/MinGW paths preserved
  - Compiling macOS NSGL stub (gfx_backend_nsgl.m) satisfying the gfx_backend.h 5-function seam behind __APPLE__; consumes the RND-02 NSWindow*, stores contentView, defers live NSOpenGLContext to Phase 4
  - Extension-aware, loud-failing .onLoad (BLD-02): computes [info sharedlibextension], searches ext x arch candidates, stop()s with an accurate per-platform message on not-found and on tcl-load failure
  - GLUT removed from the draw path (BLD-04): both glutSolidSphere -> gluSphere on a GLUquadric; glutInitDisplayMode removed; <GL/glut.h> out of the shared header; remaining glutBitmapCharacter labels guarded Windows-only
affects: [phase-04-macos-nsgl-backend, RND-03, RND-04, BLD-03, PICK-01]

# Tech tracking
tech-stack:
  added:
    - "Objective-C toolchain on APPLE (enable_language(OBJC)); NSOpenGL/Cocoa backend TU"
    - "macOS Tcl/Tk stub linkage via TKOGL2_MACOS_TCLTK_PREFIX (Homebrew tcl-tk) + find_library"
    - "OpenGL/AppKit/Foundation frameworks (GLU lives in the OpenGL framework, so gluSphere/gluUnProject need no separate lib)"
  patterns:
    - "Platform branch in CMake keyed off WIN32 / APPLE / else; the gfx backend source, headers, libs, defs, and output suffix are all selected per platform while the common TU set is shared"
    - "Object pointers held as void* with __bridge casts in the .m so the backend compiles under both MRC and ARC (ARC forbids strong ObjC pointers in C structs)"
    - "gluSphere on a reused GLUquadric replaces glutSolidSphere; the single-dot path reuses the quadric the original allocated-then-leaked and now frees it"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/gfx_backend_nsgl.m
  modified:
    - integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt
    - integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h
    - integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_ZARF9.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ZARF_9.c
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R

key-decisions:
  - "Phase 3 is build scaffolding, not rendering: the NSGL backend is a compiling stub (stores contentView, no GL context); Phase 4 is first light. This matches the ROADMAP line between BLD-01 (build) and RND-03/RND-04 (render)."
  - "Emit .dylib via SHARED (-dynamiclib) per the ROADMAP, not a .so bundle (MODULE). tcl('load', <abs path>, ...) loads by path so the file extension only has to match what .onLoad searches for, which BLD-02 makes extension-aware."
  - "Keep GLUT on Windows solely for glutBitmapCharacter numeric labels (guarded #if _WIN32); do not attempt portable labels now. Fully dropping GLUT everywhere would change Windows behavior (label loss) and is out of scope; criterion 3 only requires no-GLUT on macOS."
  - "Swap glutSolidSphere -> gluSphere on BOTH platforms (single code path) rather than #ifdef the sphere; gluSphere is cross-platform GLU and visually identical at slices/stacks 10/10. This also fixes a latent quadric leak in ogl_drawDot."
  - "Remove glutInitDisplayMode outright (vestigial): the engine never creates a GLUT window, so it only set an unused display-mode flag; buffering/depth/RGBA come from the backend pixel format."
  - "Hold macOS object pointers as void* (+__bridge) so the .m builds regardless of whether CMake enables ARC; avoids the ARC 'ObjC pointer in C struct' error without pinning a memory model."
  - "macOS Tcl/Tk location is a cache var (TKOGL2_MACOS_TCLTK_PREFIX, default /opt/homebrew/opt/tcl-tk) with find_library over versioned stub names, mirroring the Windows TKOGL2_TK_* cache-var approach rather than hardcoding a path."
  - "Patch only the canonical package bridge GUImorphDevelopment/R/rtkogl.R for .onLoad; the stale pre-0.9.0 tkogl2/R/rtkogl.R mirror is left untouched (same call as Phase 2)."

patterns-established:
  - "CMake platform branch (WIN32/APPLE/else) selecting backend source + headers + libs + defs + suffix around a shared common-TU core"
  - "gfx seam extended to a second real backend (NSGL stub) with g_surface still defined once in the shared tcl_window.c"

requirements-implemented: [BLD-01, BLD-02, BLD-04]
requirements-completed: []

coverage:
  - id: D1
    description: "Tri-platform CMake: WIN32 keeps WGL + vendored headers + system libs (MSVC/MinGW preserved); APPLE compiles the .m as OBJC, links frameworks + mac Tcl/Tk stubs, emits .dylib; bare UNIX is FATAL_ERROR; per-platform SUFFIX"
    requirement: "BLD-01"
    verification:
      - kind: static
        ref: "CMakeLists.txt: if(WIN32)/elseif(APPLE)/else(FATAL_ERROR); enable_language(OBJC); gfx_backend_nsgl.m added on APPLE; -framework OpenGL/AppKit/Foundation; find_library tclstub/tkstub under TKOGL2_MACOS_TCLTK_PREFIX; _tkogl2_suffix .dll/.dylib/.so; Windows MSVC/MinGW link blocks intact"
        status: pass
    human_judgment: false
  - id: D2
    description: "macOS NSGL stub satisfies the 5-function gfx seam behind __APPLE__; takes NSWindow*, stores contentView, no live context; g_surface stays defined only in tcl_window.c"
    requirement: "BLD-01"
    verification:
      - kind: static
        ref: "gfx_backend_nsgl.m implements gfx_create/make_current/swap/resize/destroy under #if defined(__APPLE__); void* struct members + __bridge; grep confirms g_surface defined once (tcl_window.c), not in the .m"
        status: pass
    human_judgment: false
  - id: D3
    description: ".onLoad computes [info sharedlibextension], searches ext x arch candidates, and stop()s with an accurate message on not-found and on tcl-load failure (loud, not silent-degrade)"
    requirement: "BLD-02"
    verification:
      - kind: static
        ref: "rtkogl.R .onLoad: tcl('info','sharedlibextension'); candidate loop over unique(c(tcl.ext, .Platform$dynlib.ext, .dll,.dylib,.so)) x archs; stop() on both !nzchar(file) and the tcl('load',...) error handler; invisible()"
        status: pass
    human_judgment: false
  - id: D4
    description: "GLUT gone from the draw path: both glutSolidSphere -> gluSphere with matched gluNewQuadric/gluDeleteQuadric; glutInitDisplayMode removed; <GL/glut.h> out of shared header; only Windows-guarded glutBitmapCharacter remains"
    requirement: "BLD-04"
    verification:
      - kind: static
        ref: "grep: 0 glutSolidSphere calls; gluSphere at both sites; single-dot reuses+frees qobj; downsample creates/reuses/frees dsQobj; glutBitmapCharacter + <GL/glut.h> under #if defined(_WIN32); windows.h/GL headers platform-guarded in def_ZARF_9.h"
        status: pass
    human_judgment: false
  - id: D5
    description: "Windows build still works: MSVC tkogl2.dll builds under the restructured CMake and a PLY renders + landmarks place unchanged across the reworked draw path (CMP-01 recurrence, behavior preservation on-target)"
    requirement: "BLD-01, CMP-01"
    verification:
      - kind: human
        ref: "PENDING: reconfigure MSVC (build-msvc wiped; CMakeLists changed) with -DTKOGL2_TK_USE_STUBS=OFF -DTKOGL2_TK_STUB_LIB=<abs>\\tk86.lib, rebuild, redeploy inst/libs/x64/, confirm a PLY renders and landmarks place. Tracked in .planning/todos/pending/phase-03-windows-validation.md"
        status: pending
    human_judgment: true
    rationale: "The whole CMakeLists, def_ZARF_9.h, and the sphere/label draw path changed, so the Windows regression risk is higher than Phase 2. Must be confirmed on Erik's Windows host before shipping the rebuilt DLL."
  - id: D6
    description: "macOS tkogl2.dylib compiles + links (Mach-O -dynamiclib) against the frameworks and mac Tcl/Tk stubs"
    requirement: "BLD-01"
    verification:
      - kind: human
        ref: "DEFERRED to Phase 4 (no macOS host available). When a Mac is available: cmake -B build-mac -DTKOGL2_MACOS_TCLTK_PREFIX=$(brew --prefix tcl-tk) && cmake --build build-mac. Watch item: [info sharedlibextension] may report .so vs the .dylib we emit; mitigated by the multi-extension search in .onLoad."
        status: pending
    human_judgment: true
    rationale: "The macOS accessor (Tk_MacOSXGetNSWindowForDrawable) and the NSGL backend only compile against the Mac's own Tk 8.7/9.0 aqua headers at build time, not the vendored Windows headers; this cannot be exercised on the Linux authoring host."

# Metrics
duration: n/a (off-box authoring; Windows verification pending, macOS build deferred to Phase 4)
completed: 2026-07-15 (code)
status: implemented-pending-verification
---

# Phase 3 Plan 01: Tri-Platform Build + Generalized Load + Drop GLUT Summary

**Stands up the macOS toolchain and loading path so the Cocoa/NSOpenGL backend can compile, link, and load, without disturbing the verified Windows build. Tri-platform CMake emits a Mach-O `tkogl2.dylib` against the frameworks; a compiling NSGL stub satisfies the gfx seam (Phase 4 is first light); `.onLoad` is extension-aware and fails loudly; GLUT is gone from the draw path. Code is authored and statically verified — Windows render regression is pending on-box and the macOS `.dylib` build is deferred to Phase 4 (no Mac host).**

## Accomplishments
- **GLUT dropped from the draw path (BLD-04, `ogl_model_ZARF_9.c` / `ogl_ZARF9.c` / `def_ZARF_9.h`):** both `glutSolidSphere` are now `gluSphere` on a `GLUquadric`. `ogl_drawDot` reuses the quadric the original code allocated then leaked (drawing via `gluSphere` and freeing it); the downsample loop creates one quadric, reuses it per dot, and frees it after. Vestigial `glutInitDisplayMode` is removed. `<GL/glut.h>` is out of the shared `def_ZARF_9.h`; the only remaining GLUT is the two `glutBitmapCharacter` numeric-label calls plus a local include, all guarded `#if defined(_WIN32)`. `windows.h` and the GL headers in `def_ZARF_9.h` are now platform-guarded (`<OpenGL/gl.h>`/`<OpenGL/glu.h>` on Apple).
- **macOS NSGL stub (BLD-01, new `gfx_backend_nsgl.m`):** a compiling Cocoa/NSOpenGL backend behind `#if defined(__APPLE__)` implementing the `gfx_backend.h` 5-function seam. `gfx_create` takes the RND-02 `NSWindow*`, stores its `contentView`, and leaves the live `NSOpenGLContext` (legacy 2.1) to Phase 4; `make_current`/`swap` early-return until then. Object pointers are held as `void*` with `__bridge` casts so it builds under MRC or ARC. `g_surface` remains defined once, in the shared `tcl_window.c`.
- **Tri-platform CMake (BLD-01, `CMakeLists.txt`):** restructured to `if(WIN32)` (WGL source + vendored Tcl/Tk headers + X11/glut shims + system libs, with the MSVC and MinGW sub-branches preserved exactly) / `elseif(APPLE)` (`enable_language(OBJC)`, add the `.m`, macOS Tcl/Tk include + stub libs via `TKOGL2_MACOS_TCLTK_PREFIX`, `-framework OpenGL/AppKit/Foundation`, `.dylib` suffix, `USE_TK_STUBS`+`MAC_OSX_TK`) / `else()` `FATAL_ERROR`. The output suffix is per-platform.
- **Generalized, loud load (BLD-02, `GUImorphDevelopment/R/rtkogl.R`):** `.onLoad` computes the Tcl loadable extension from `[info sharedlibextension]` instead of hardcoding `.dll`, searches a small extension x arch candidate set (with `.dylib`/`.so` fallbacks for the macOS Tcl-build nuance), and `stop()`s with an accurate, actionable message on both not-found and tcl-load failure — replacing the old warning-and-continue that left a silently dead viewport.

## Task Commits
Committed atomically on branch `macos-test` (see `git log`).

## Files Created/Modified
- `.../tkogl2/src/gfx_backend_nsgl.m` — NEW: macOS NSGL stub backend (seam behind `__APPLE__`; contentView stored; context in Phase 4).
- `.../tkogl2/CMakeLists.txt` — tri-platform WIN32/APPLE/else; OBJC; frameworks; mac Tcl/Tk stub libs; per-platform suffix.
- `.../tkogl2/src/def_ZARF_9.h` — platform-guard `windows.h` + GL headers; drop `<GL/glut.h>`.
- `.../tkogl2/src/ogl_ZARF9.c` — remove vestigial `glutInitDisplayMode`.
- `.../tkogl2/src/ogl_model_ZARF_9.c` — `gluSphere` x2 (+ quadric create/reuse/free); Windows-guard `glutBitmapCharacter` + local glut include.
- `.../GUImorphDevelopment/R/rtkogl.R` — extension-aware, loud-failing `.onLoad`.

## Decisions Made
See `key-decisions` in frontmatter. Load-bearing ones: Phase 3 is build/stub only (render is Phase 4); emit `.dylib` via SHARED per the ROADMAP and lean on the extension-aware `.onLoad` to locate it; keep GLUT on Windows only for labels rather than change Windows behavior; swap the sphere on both platforms (one code path, fixes a leak); hold macOS object pointers as `void*` to stay ARC/MRC-agnostic.

## Deviations from Plan
None in code. The GLUT removal turned out larger than the ROADMAP's one-line `glutSolidSphere -> gluSphere`: three distinct GLUT dependencies existed (the sphere, `glutBitmapCharacter` labels, vestigial `glutInitDisplayMode`). Handled by swapping the sphere, removing the vestige, and Windows-guarding the labels — macOS is GLUT-free, Windows behavior is preserved.

## Issues Encountered
- `[info sharedlibextension]` may report `.so` on some macOS Tcl builds while the ROADMAP asks for a `.dylib` output; if they diverge, a naive single-extension search would miss the file. Mitigated now by the multi-extension candidate search in `.onLoad`; flagged as a Phase 4 watch item once a real Mac build exists.
- The macOS accessor and NSGL backend compile only against the Mac's own aqua Tk headers (Homebrew tcl-tk) at build time; they cannot be exercised on the Linux authoring host, so D6 is deferred to Phase 4.

## User Setup Required
- **On-box Windows rebuild (BLD-01 / CMP-01):** the whole `CMakeLists.txt` and the draw path changed, so wipe `build-msvc` and reconfigure with `-DTKOGL2_TK_USE_STUBS=OFF -DTKOGL2_TK_STUB_LIB=<abs>\tk86.lib` (same direct-Tk-link recipe as Phase 2), rebuild `tkogl2.dll`, redeploy `inst/libs/x64/`, then confirm a PLY renders and landmarks place unchanged. Tracked in `.planning/todos/pending/phase-03-windows-validation.md`.
- **macOS build (deferred, Phase 4):** `brew install tcl-tk`, then `cmake -B build-mac -DTKOGL2_MACOS_TCLTK_PREFIX=$(brew --prefix tcl-tk) && cmake --build build-mac`.

## Next Phase Readiness
- **BLD-01 / BLD-02 / BLD-04 are code-complete and statically verified**; not yet target-verified. Windows render regression is pending on Erik's host; the macOS `.dylib` build is deferred to Phase 4 (no Mac).
- Phase 4 (NSGL first light) fills the stub: build a legacy-2.1 `NSOpenGLContext` on the stored `contentView`, make it current, draw, present via `flushBuffer` (RND-03/RND-04), and takes on `universal2` + notarization (BLD-03).
- The extension-aware `.onLoad` and the `.dylib` toolchain are in place for Phase 4 to load and exercise.

## Self-Check: PASSED (static only)
- FOUND: CMakeLists.txt (WIN32/APPLE/else branches, enable_language(OBJC), gfx_backend_nsgl.m on APPLE, -framework OpenGL/AppKit/Foundation, find_library tclstub/tkstub, .dylib suffix, MAC_OSX_TK, MSVC/MinGW blocks preserved)
- FOUND: gfx_backend_nsgl.m (5 seam functions under __APPLE__, void*+__bridge)
- FOUND: rtkogl.R (.onLoad computes info sharedlibextension, ext x arch candidates, stop() on both failure paths)
- FOUND: ogl_model_ZARF_9.c (gluSphere x2 with matched quadric create/free; glutBitmapCharacter + <GL/glut.h> under #if _WIN32); ogl_ZARF9.c (glutInitDisplayMode removed); def_ZARF_9.h (windows.h/GL guarded, no <GL/glut.h>)
- CONFIRMED: no glutSolidSphere remains; g_surface defined once (tcl_window.c)
- NOT RUN (off-box): MSVC build/render regression (pending todo); macOS .dylib compile/link (deferred to Phase 4)

---
*Phase: 03-tri-platform-build-generalized-load-drop-glut*
*Completed (code): 2026-07-15*
