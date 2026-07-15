---
title: "Run Windows MSVC build + render validation for Plan 02-01 (RND-02)"
status: done
priority: high
resolves_phase: 2
created: 2026-07-15
updated: 2026-07-15
resolved: 2026-07-15
owner: eoc
source_plan: 02-01
---

## Resolution (2026-07-15) — windows-render-ok

Built and verified on Windows R 4.6.1. The FRESH BUILD dll loaded, the RND-02
pathname path resolved (`set window id ... frame pathname : .1.2.3` -> valid
HWND via Tk_NameToWindow), a PLY rendered, live surface picks tracked the
cursor, and 6 landmarks placed on-target (off-mesh click correctly rejected by
the inside-specimen guard). No regression vs. the old winfo-id transport.

**How it built (record for Phase 3 / future Windows builds):**
- Tk X11 shim vendored into `include/tk_include/X11/` (Tk 8.6 xlib headers) so
  `<tk.h>` resolves. `TKOGL2_TK_XLIB_INCLUDE` left at its vendored default.
- The vendored `lib/tkstub86.lib` is x86 and unusable for the x64 build, and
  x64 R ships no tk stub lib. So Tk was linked in **direct mode**:
  `TKOGL2_TK_USE_STUBS=OFF`, linking a 4-symbol import lib generated from
  `%R_HOME%\Tcl\bin\tk86.dll`:
  ```
  LIBRARY tk86
  EXPORTS
  Tk_NameToWindow
  Tk_MainWindow
  Tk_MakeWindowExist
  Tk_GetHWND
  ```
  `lib /def:tk86.def /machine:x64 /out:tk86.lib`, then
  `cmake ... -DTKOGL2_TK_USE_STUBS=OFF -DTKOGL2_TK_STUB_LIB=<abs path>\tk86.lib`.
- `tkogl2.dll` now has a load-time dependency on `tk86.dll`, which R's tcltk
  already loads, so it binds at load. Phase 3 (tri-platform build) should decide
  whether to keep direct mode or ship an arch-matched x64 tkstub for stubs mode.

## Context (original)

Plan `02-01` (RND-02, pathname-based Tk drawable resolution) introduces the first
Tk API use in the extension. It could not be built or render-verified on the
Linux authoring box, and it added the Tk X11-shim include dependency above.

New build step (because `#include <tk.h>` now pulls Tk's `<X11/Xlib.h>` shim, which
the vendored `include/tk_include/` does not contain):

- Provide the Tk `X11/` shim on the include path. Either:
  - configure with `-DTKOGL2_TK_XLIB_INCLUDE=<Tcl/Tk include dir containing X11/>`
    (e.g. the Tcl/Tk that ships with R, or a standalone Tcl/Tk 8.6), or
  - drop the Tk 8.6 `xlib/X11/*.h` headers into `include/tk_include/X11/`.
- Confirm `tkstub86.lib` is the x64 variant (only one tk stub lib is vendored; the
  build is x64). If not, supply the x64 `tkstub86.lib`.

Then the standard Windows validation:

- Build post-RND-02 `tkogl2.dll` with MSVC/CMake (`build_deploy_tkogl2.ps1`).
- Redeploy `inst/libs/x64/tkogl2.dll`.
- Launch `GUImorph()` on Windows R (R 4.6.1, Tcl/Tk 8.6).
- Load `test/fixtures/regression.ply`.
- Confirm the mesh renders and is visually unchanged vs. pre-RND-02 (the pathname
  resolution reaches the same HWND the old `winfo id` transport produced).

## Acceptance

- Build + link succeed with no unresolved Tk symbols (Tk_NameToWindow, Tk_GetHWND,
  Tk_MakeWindowExist, Tk_MainWindow, Tk_InitStubs) and no missing `<X11/Xlib.h>`.
- Digitizing viewport renders `regression.ply`, non-blank, unchanged from before.
- Landmark placement still lands on-target (no regression from the drawable change).
- Report back as `windows-render-ok` or with regression details.

## Notes

- This supersedes nothing in `phase-01-windows-validation.md`; both are open. If the
  Phase 1 CMP-01 build has not been run yet, this build covers both (it is strictly
  newer source than the Phase 1 refactor).
- MinGW path: Tk-stub linkage is intentionally NOT wired here (COFF `tkstub86.lib`
  is unreadable by GNU ld); MinGW is non-distributable and deferred to Phase 3.
