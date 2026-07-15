---
phase: 02-pathname-based-tk-drawable-resolution
plan: 01
subsystem: infra
tags: [tk-stubs, drawable-resolution, pathname, win32, macos, nsview, rnd-02]

# Dependency graph
requires:
  - phase: 01-aqua-tk-deployment-gate-windows-rendering-seam (Plan 05)
    provides: seam-neutral setWindowId(void *native_drawable) forwarding to gfx_create; fragile int->drawable cast left for replacement here
provides:
  - Pathname-based drawable resolution (Tk_NameToWindow -> Tk_MakeWindowExist -> Tk_WindowId) with a per-platform accessor branch (Tk_GetHWND / Tk_MacOSXGetNSWindowForDrawable)
  - Tk stub linkage in the extension (Tk_InitStubs at load; USE_TK_STUBS + tkstub86.lib) so Tk_* and the platform accessors are callable
  - R bridge passes the frame pathname instead of winfo id; the 32-bit int->pointer cast is gone
  - macOS NSWindow accessor staged behind MAC_OSX_TK/__APPLE__ for the Phase 4 NSGL backend
affects: [phase-03-triplatform-build, phase-04-macos-nsgl-backend, RND-03, RND-04, BLD-01]

# Tech tracking
tech-stack:
  added:
    - "Tk stubs (tkstub86.lib, USE_TK_STUBS, Tk_InitStubs) — first Tk API use in the extension"
  patterns:
    - "Drawable resolution lives in core (tcl_window.c) and branches per platform to produce a seam-neutral void*; the gfx_backend.h 5-function contract is unchanged"
    - "Platform drawable accessor selected by #if _WIN32 / MAC_OSX_TK|__APPLE__ / X11-fallback"

key-files:
  created: []
  modified:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_init.c
    - integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R

key-decisions:
  - "Resolve the drawable in core and branch per platform (RND-02 criterion 1), keeping the accessor selection out of the gfx seam; gfx_create still receives an opaque void*"
  - "Call Tk_MakeWindowExist before Tk_WindowId so the id is valid — the old winfo-id path realized the window as an R-side side effect"
  - "Windows accessor Tk_GetHWND(Tk_WindowId(frame)) is behavior-preserving: it returns the same HWND the old winfo-id transport produced"
  - "Patch only the canonical package bridge GUImorphDevelopment/R/rtkogl.R (owns DESCRIPTION, has the 0.9.0 dbg() helper); leave the stale pre-0.9.0 mirror tkogl2/R/rtkogl.R (still uses raw print()) untouched"
  - "Stage the macOS accessor behind MAC_OSX_TK/__APPLE__ only (dead on the Windows build); macOS build wiring is Phase 3, NSGL backend is Phase 4"
  - "Expose the Tk X11 shim include path as a CMake cache var (TKOGL2_TK_XLIB_INCLUDE) rather than vendoring an unverifiable X11 header pile; <tk.h> pulls <X11/Xlib.h> and the vendored include/tk_include/ has no X11/ subdir"
  - "Defer non-MSVC (MinGW) Tk-stub linkage to Phase 3 — GNU ld cannot read the COFF tkstub86.lib and MinGW is already non-distributable"

patterns-established:
  - "Per-platform drawable accessor branch keyed off _WIN32 / MAC_OSX_TK|__APPLE__, feeding a seam-neutral void* to gfx_create"

requirements-completed: [RND-02]

coverage:
  - id: D1
    description: "setWindow 'id' resolves a Tk widget pathname via Tk_NameToWindow -> Tk_MakeWindowExist -> Tk_WindowId and branches to the per-platform accessor"
    requirement: "RND-02"
    verification:
      - kind: static
        ref: "grep Tk_NameToWindow/Tk_MakeWindowExist/Tk_GetHWND/Tk_MacOSXGetNSWindowForDrawable in tcl_window.c; no hwndId/int-cast in the id path"
        status: pass
    human_judgment: false
  - id: D2
    description: "Tk_InitStubs runs after Tcl_InitStubs; USE_TK_STUBS + tkstub86.lib linkage present"
    requirement: "RND-02"
    verification:
      - kind: static
        ref: "grep Tk_InitStubs in tcl_init.c; grep USE_TK_STUBS + tkstub86.lib in CMakeLists.txt"
        status: pass
    human_judgment: false
  - id: D3
    description: "R bridge passes the frame pathname (arg1$ID), not winfo id"
    requirement: "RND-02"
    verification:
      - kind: static
        ref: "grep framePath / tcl('setWindow', attr, framePath, ...) in rtkogl.R; no tkwinfo('id', arg1) in the window/id branch"
        status: pass
    human_judgment: false
  - id: D4
    description: "MSVC tkogl2.dll builds + links with the Tk X11 shim on the include path, and a PLY renders unchanged on Windows R (CMP-01 recurrence, behavior preservation on-target)"
    requirement: "RND-02, CMP-01"
    verification:
      - kind: human
        ref: "2026-07-15 Windows R 4.6.1 run: FRESH BUILD dll loaded; 'set window id ... frame pathname : .1.2.3' resolved via Tk_NameToWindow to a valid HWND; B12_1_clean.ply rendered; live surface picks tracked the cursor; 6 landmarks placed (add dot TRUE), off-mesh click correctly rejected by the inside-specimen guard."
        status: pass
    human_judgment: true
    rationale: "Verified on target after switching to direct Tk linkage (TKOGL2_TK_USE_STUBS=OFF) against an import lib generated from x64 R's tk86.dll, since the vendored tkstub86.lib is x86 and R ships no x64 tk stub."

# Metrics
duration: n/a (off-box authoring; verified on Windows 2026-07-15)
completed: 2026-07-15
status: complete
---

# Phase 2 Plan 01: Pathname-Based Tk Drawable Resolution Summary

**Replaces the fragile 32-bit `int`->pointer drawable transport with Tk-API resolution by widget pathname, so the platform-native drawable is obtained through `Tk_NameToWindow` -> `Tk_WindowId` -> a per-platform accessor. Windows path is behavior-preserving; the macOS NSWindow accessor is staged behind a platform guard for Phase 4. Code is authored and statically verified; on-target Windows build+render is deferred off-box (RND-02 / CMP-01).**

## Accomplishments
- **Core resolution (`tcl_window.c`):** the `setWindow` "id" branch now reads a Tk widget pathname, resolves `Tk_NameToWindow(interp, path, Tk_MainWindow(interp))`, forces realization with `Tk_MakeWindowExist`, reads `Tk_WindowId`, and branches: `Tk_GetHWND` on `_WIN32`, `Tk_MacOSXGetNSWindowForDrawable` on `MAC_OSX_TK`/`__APPLE__`, raw `Window` id as an X11 fallback. The result is the same seam-neutral `void *native_drawable` handed to `gfx_create` — the `gfx_backend.h` contract is untouched. NULL pathname and NULL-drawable cases are logged; the historical "always `TCL_OK`" contract for GUI/tab ops is preserved.
- **Stubs (`tcl_init.c`):** added `#include <tk.h>` and `Tk_InitStubs(interp, TK_VERSION, 0)` right after `Tcl_InitStubs`, so `tkStubsPtr`/`tkPlatStubsPtr` are bound before any `Tk_*` stub macro fires.
- **Build (`CMakeLists.txt`):** added `USE_TK_STUBS`, linked the vendored `tkstub86.lib` on MSVC, and exposed the Tk `X11/` shim include path as `TKOGL2_TK_XLIB_INCLUDE` (required because `<tk.h>` pulls `<X11/Xlib.h>` and the vendored `include/tk_include/` ships no `X11/` subdir). Non-MSVC Tk-stub linkage is explicitly deferred to Phase 3.
- **R bridge (`GUImorphDevelopment/R/rtkogl.R`):** `set("window","id", frame)` now passes the frame pathname (`arg1$ID`, string-safe) instead of `tkwinfo("id", arg1)`; the int transport is gone.

## Task Commits
Committed atomically on branch `macos-test` (see `git log`).

## Files Created/Modified
- `.../tkogl2/src/tcl_window.c` — pathname resolution + per-platform accessor; `#include <tk.h>`; removed the int->pointer cast.
- `.../tkogl2/src/tcl_init.c` — `#include <tk.h>`; `Tk_InitStubs`.
- `.../tkogl2/CMakeLists.txt` — `USE_TK_STUBS`; MSVC `tkstub86.lib`; `TKOGL2_TK_XLIB_INCLUDE` include path; MinGW deferral note.
- `.../GUImorphDevelopment/R/rtkogl.R` — pass frame pathname to `setWindow`.

## Decisions Made
See `key-decisions` in frontmatter. Key ones: drawable resolution stays in core and branches per platform (criterion 1); `Tk_MakeWindowExist` guarantees a valid id; only the canonical package bridge is patched (the `tkogl2/R/` mirror is stale pre-0.9.0 and left alone); the macOS accessor is dead-code on Windows and lit only under `MAC_OSX_TK`/`__APPLE__`.

## Deviations from Plan
None in code. One environment consequence surfaced during execution: introducing `<tk.h>` adds a Tk `X11/` shim include dependency the vendored header set does not satisfy. Handled via the `TKOGL2_TK_XLIB_INCLUDE` cache var rather than vendoring an unverifiable header pile; flagged as an on-box build step.

## Issues Encountered
- Vendored `tkPlatDecls.h` is Tk 8.6-era and its AQUA section predates `Tk_MacOSXGetNSWindowForDrawable` (only the Carbon `TkMacOSXGetDrawablePort`/`TkMacOSXGetRootControl`). Not a problem: those are the Windows build's reference headers; the macOS branch compiles against the Mac's own Tk >= 8.7/9.0 headers (Homebrew tcl-tk) at Phase 3/4 build time.

## User Setup Required
- **On-box Windows build step (RND-02):** `<tk.h>` needs Tk's `X11/` shim on the include path. Set `-DTKOGL2_TK_XLIB_INCLUDE=<path to a Tcl/Tk include dir containing X11/>` (e.g. R's bundled Tcl/Tk, or a standalone Tcl/Tk 8.6), or drop the Tk 8.6 `xlib/X11/*.h` headers into `include/tk_include/X11/`. Then rebuild MSVC `tkogl2.dll`, redeploy `inst/libs/x64/`, and confirm `regression.ply` renders unchanged.

## Next Phase Readiness
- **RND-02 code is complete and statically verified**; it is NOT yet verified on target. The committed `tkogl2.dll` predates this change and must be rebuilt off-box (Windows MSVC) with the Tk X11 shim on the include path before shipping.
- **Deferred (this phase):** on-box Windows build+link+render (CMP-01 recurrence) — `.planning/todos/pending/phase-02-windows-validation.md`.
- Phase 3 (tri-platform build) can now assume Tk-stub linkage and pathname resolution exist; it owns the `.dylib` toolchain, `.onLoad` extension-awareness, dropping GLUT, and non-MSVC Tk-stub linkage.
- Phase 4 (NSGL backend) will consume the `NSWindow*` produced by the macOS accessor branch and derive the embedded `NSView`.

## Self-Check: PASSED (static only)
- FOUND: tcl_window.c (Tk_NameToWindow, Tk_MakeWindowExist, Tk_GetHWND, Tk_MacOSXGetNSWindowForDrawable, #include <tk.h>); no hwndId/int-cast in id path
- FOUND: tcl_init.c (Tk_InitStubs, #include <tk.h>)
- FOUND: CMakeLists.txt (USE_TK_STUBS, tkstub86.lib, TKOGL2_TK_XLIB_INCLUDE)
- FOUND: rtkogl.R (framePath, tcl("setWindow", attr, framePath, ...)); no tkwinfo("id", ...) in window/id branch
- NOT RUN (off-box): MSVC build/link, Windows render parity — deferred to pending todo

---
*Phase: 02-pathname-based-tk-drawable-resolution*
*Completed (code): 2026-07-15*
