# Phase 1: Aqua-Tk Deployment Gate + Windows Rendering Seam - Pattern Map

**Mapped:** 2026-07-12
**Files analyzed:** 11 (5 new, 5 modified, 1 fixture)
**Analogs found:** 9 / 11 (2 have no analog: PLY fixture, gate-assert script framework)

> All source paths are relative to `integrated-guimorph-development_EOC/Project/tkogl2/` unless noted. R sources live under `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/` (the authoritative tree — NOT the stale `tkogl2/R/` copy).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `src/gfx_backend.h` (NEW) | interface/header | request-response | `src/tcl_window.h` | role-match (header shape) |
| `src/gfx_backend_wgl.c` (NEW) | platform backend / driver | request-response (window+context lifecycle) | `src/tcl_window.c` (`setWindowId`) | exact (code lifted verbatim) |
| `src/tcl_window.c` (MODIFIED) | controller (Tcl cmd) | request-response | itself (self-refactor) | exact |
| `src/tcl_dispatch.c` (MODIFIED) | core draw pass | request-response | itself (`onDisplay`) | exact |
| `src/def_ZARF_9.h` (MODIFIED) | shared header | n/a | itself | exact |
| `CMakeLists.txt` (MODIFIED) | build config | n/a | itself | exact |
| `src/gate_ext.c` (NEW) | Tcl extension init / module | request-response (Tcl command) | `src/tcl_init.c` (`Tkogl2_Init`) | exact (template) |
| gate-assert script (NEW, e.g. `test/gate/gate_check.R`) | test / smoke | request-response | `R/rtkogl.R` `.onLoad` load path | role-match (no test framework exists) |
| gate-ext build recipe (NEW, e.g. `test/gate/CMakeLists.txt` or Makefile) | build config | n/a | `CMakeLists.txt` | role-match |
| GATE-02 setup doc (NEW, README §/standalone) | docs | n/a | `BUILD.md` / `README.md` | role-match |
| PLY fixture (NEW, e.g. `test/fixtures/*.ply`) | test data / fixture | file-I/O | — | **NO ANALOG** (none committed) |

## Pattern Assignments

### `src/gfx_backend.h` (NEW — interface/header, request-response)

**Analog:** `src/tcl_window.h` (include-guard + `extern`/prototype-only header shape). Interface contract itself is specified in `01-RESEARCH.md` §"Pattern 1".

**Header shape to copy** (`tcl_window.h:1-13`):

```1:13:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.h
#pragma once
#ifndef TCL_WINDOW_H
#define TCL_WINDOW_H

#include "def_ZARF_9.h"

extern int width;
extern int height;

int setWindowId(HWND hwnd);
int setWindow(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);

#endif
```

**Critical deviation from analog:** `tcl_window.h` includes `def_ZARF_9.h` (which pulls `<windows.h>` + `HWND`/`HDC`). The seam header MUST NOT — it is the platform-neutral boundary. Use an **opaque handle** and `void*` drawable so no `HWND`/`HDC`/`HGLRC` leaks into core. Exactly 5 functions per D-04 (`create`/`make_current`/`swap`/`resize`/`destroy`). The target contract (from RESEARCH §Pattern 1):

```c
#ifndef GFX_BACKEND_H
#define GFX_BACKEND_H
typedef struct gfx_surface gfx_surface;      /* opaque; defined per-backend .c */
gfx_surface *gfx_create(void *native_drawable);   /* WGL: cast to HWND */
int  gfx_make_current(gfx_surface *s);
void gfx_swap(gfx_surface *s);
void gfx_resize(gfx_surface *s, int w, int h);
void gfx_destroy(gfx_surface *s);
#endif
```

---

### `src/gfx_backend_wgl.c` (NEW — platform backend, window+context lifecycle)

**Analog:** `src/tcl_window.c` `setWindowId` — this is the exact code to move, VERBATIM per D-05.

**Preamble / pragmas to copy** (`tcl_window.c:1-2`) — MSVC warning suppression the whole codebase uses:

```1:2:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c
#pragma warning( disable : 4305)
#pragma warning( disable : 4244)
```

**Core WGL create pattern to MOVE into `gfx_create()` + `gfx_make_current()`** (`tcl_window.c:36-64`):

```36:64:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c
int setWindowId(HWND hwnd)
{
	//////#ifdef _WIN32
		/* Grab the HWND from Tcl. */

		/* Setup OpenGL. */
	dc = GetDC(hwnd);


	/* Windows code, setup OpenGL. */
	PIXELFORMATDESCRIPTOR pfd;
	memset(&pfd, 0, sizeof(pfd));
	pfd.nVersion = 1;
	pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
	pfd.iPixelType = PFD_TYPE_RGBA;
	pfd.cColorBits = 24;
	pfd.cDepthBits = 16;
	pfd.iLayerType = PFD_MAIN_PLANE;

	GLuint pixelFormat = ChoosePixelFormat(dc, &pfd);
	SetPixelFormat(dc, pixelFormat, &pfd);

	HGLRC rc = wglCreateContext(dc);

	wglMakeCurrent(dc, rc);

	ogl_init();  // this function returns an integer - but I have yet to investigate what to do on  failure
	return TCL_OK;
}
```

**Extraction mapping** (verified against source; matches RESEARCH §"Exact code inventory"):
- `dc = GetDC(hwnd)` → `HDC` becomes backend-owned state inside `struct gfx_surface` (backend `.c` only).
- `PIXELFORMATDESCRIPTOR` + `ChoosePixelFormat` + `SetPixelFormat` + `wglCreateContext` → body of `gfx_create()`. Store `rc` (`HGLRC`) in the surface struct (today it's a **leaked local** — do NOT "fix" the leak; see Shared Pattern "Behavior-preserving refactor").
- `wglMakeCurrent(dc, rc)` → `gfx_make_current()`. (Today it also runs implicitly inside create — preserve that ordering: create → make_current → `ogl_init`.)
- `ogl_init()` → **STAYS IN CORE** (`tcl_window.c` `setWindowId`/"id" path), called AFTER `gfx_create` + `gfx_make_current`. It is generic GL, not platform.
- `#ifdef _WIN32` guard: wrap the whole `gfx_backend_wgl.c` body so no macOS code compiles into the Windows build (D-05, Pattern 2).

**`gfx_swap()` body** — moved from `tcl_dispatch.c` `onDisplay` (`tcl_dispatch.c:3597-3603`):

```3597:3603:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c
#ifdef _WIN32
	{
		SwapBuffers(dc); //throw that sucker on the main screen
	}
#elif __linux__
	glXSwapBuffers(__glDisplay__, __glWindow__);
#endif
```

`gfx_swap()` = `SwapBuffers(surface->dc)`. **DROP the `#elif __linux__` branch** — `__linux__` is `#undef`'d (`RunTime_Defines_ZARF_9.h:10`), so it never compiled (dead code, Pitfall 6).

---

### `src/tcl_window.c` (MODIFIED — controller, self-refactor)

**Analog:** itself. Replace the `setWindowId` internals with seam calls.

**After extraction** `setWindowId` becomes a thin core wrapper (create + make_current + `ogl_init`). The `HDC dc;` global definition (`tcl_window.c:20`) is REMOVED (moves into the backend). Keep `int width; int height;` in core (`tcl_window.c:22-23`) — they stay per RESEARCH.

**`setWindow` "size" path stays generic** (`tcl_window.c:158-162`) — `glViewport`/`glOrtho` are generic GL, do NOT push into the backend:

```158:162:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c
		float dx = (float)width / height;
		glViewport(0, 0, width, height);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-0.1 * dx, 0.1 * dx, -0.1, 0.1, -2, 2);
```

**Dual-build-mode guard to preserve** (`tcl_window.c:66-70`, Pitfall 4) — the seam calls must compile under BOTH `STAND_ALONE_TOOL` and the `TCL_CMD` library variant:

```66:70:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c
#ifdef STAND_ALONE_TOOL
int setWindow(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[])
# else
TCL_CMD(setWindow)
#endif
```

Add `#include "gfx_backend.h"` alongside the existing include block (`tcl_window.c:9-14`).

---

### `src/tcl_dispatch.c` (MODIFIED — core draw pass, self-refactor)

**Analog:** itself (`onDisplay`, `tcl_dispatch.c:3534-3606`).

**Replace the `#ifdef _WIN32 SwapBuffers(dc)` block** (`tcl_dispatch.c:3594-3603`) with a single seam call:

```3594:3603:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c
	glPopMatrix();
	glFlush();

#ifdef _WIN32
	{
		SwapBuffers(dc); //throw that sucker on the main screen
	}
#elif __linux__
	glXSwapBuffers(__glDisplay__, __glWindow__);
#endif
```

Becomes: `glPopMatrix(); glFlush(); gfx_swap(g_surface);` (the `#ifdef`/`#elif` block collapses to one call). `tcl_dispatch.c` already includes `tcl_window.h` (`tcl_dispatch.c:17`) — add `#include "gfx_backend.h"` in the same block (`tcl_dispatch.c:12-17`). This is the ONLY `SwapBuffers`/`dc` use outside `tcl_window.c` (verified: grep found `SwapBuffers` only at `:3599`).

---

### `src/def_ZARF_9.h` (MODIFIED — shared header)

**Analog:** itself. Remove the `HDC` leak into the platform-neutral header (Pitfall 5).

**Line to REMOVE** (`def_ZARF_9.h:112`):

```110:114:integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h
#define FREE(p) if (p != NULL) {free(p); p = NULL;}

extern HDC dc;

float getRealZ(float x, float y, float z);
```

Delete `extern HDC dc;` ONLY after both consumers (`tcl_window.c` create + `tcl_dispatch.c:3599` swap) are routed through `gfx_*`. Note `def_ZARF_9.h:8` still `#include <windows.h>` — that stays this phase (broad dependency); the seam boundary is about the `HDC`/`HGLRC` symbols, not the Windows include (Phase 2/3 concern).

---

### `CMakeLists.txt` (MODIFIED — build config)

**Analog:** itself. Add the new backend TU to the existing `add_library` source list.

**Source list to extend** (`CMakeLists.txt:44-56`):

```44:56:integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt
add_library(tkogl2 SHARED
    ${SRC}/tcl_init.c
    ${SRC}/tcl_dispatch.c
    ${SRC}/tcl_window.c
    ${SRC}/tcl_state.c
    ${SRC}/tcl_log.c
    ${SRC}/ogl_ZARF9.c
    ${SRC}/ogl_model_ZARF_9.c
    ${SRC}/ogl_model_ply_ZARF_9.c
    ${SRC}/curve_ZARF_9.c
    ${SRC}/marker.c
    ${SRC}/StatisticsFunction_ZARF_9.c
)
```

Add `${SRC}/gfx_backend_wgl.c` to this list (body is `#ifdef _WIN32`, so it's safe to add unconditionally — RESEARCH §Pattern 2). No new link libs needed: `opengl32`/`glu32`/`gdi32`/`user32` already linked for both MSVC and MinGW (`CMakeLists.txt:106-129`). The existing `WGL`/`GetDC` symbols come from `gdi32`+`opengl32`, already present.

---

### `src/gate_ext.c` (NEW — Tcl extension init / module, request-response)

**Analog:** `src/tcl_init.c` `Tkogl2_Init` — the DLL-init template (D-03, RESEARCH §Pattern 3).

**Init pattern to copy** (`tcl_init.c:14-35`):

```14:35:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_init.c
int DLLEXPORT Tkogl2_Init(Tcl_Interp* interp)
{
	if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
		return TCL_ERROR;
	}

	if (Tcl_PkgProvide(interp, "Tkogl2", "1.0") == TCL_ERROR) {
		return TCL_ERROR;
	}

	Tcl_CreateObjCommand(interp, "add", add, 0, 0);
	Tcl_CreateObjCommand(interp, "show", show, 0, 0);
	Tcl_CreateObjCommand(interp, "setWindow", setWindow, 0, 0);
	Tcl_CreateObjCommand(interp, "setSpecimen", setSpecimen, 0, 0);
	Tcl_CreateObjCommand(interp, "setDownSample", setDownSample, 0, 0);
	Tcl_CreateObjCommand(interp, "setDot", setDot, 0, 0);
	Tcl_CreateObjCommand(interp, "del", del, 0, 0);
	Tcl_CreateObjCommand(interp, "loadDgt", loadDgt, 0, 0);

	return TCL_OK;
}
```

**Critical deviation (this is the whole point of the gate):** the real `Tkogl2_Init` calls ONLY `Tcl_InitStubs` — a Tcl-only extension loads under X11 too and proves nothing. `gate_ext.c` MUST also call `Tk_InitStubs(interp, "8.6", 0)` (add `#include <tk.h>`) — linking Tk is what exercises the Aqua-vs-X11 binding. Keep it minimal: one command (`gate_winsys`) that returns `tk windowingsystem` (RESEARCH §Pattern 3):

```c
#include <tcl.h>
#include <tk.h>
static int GateWinsysCmd(ClientData cd, Tcl_Interp *ip, int objc, Tcl_Obj *const objv[]) {
    return Tcl_Eval(ip, "tk windowingsystem");   /* test asserts result == "aqua" */
}
int DLLEXPORT Gateext_Init(Tcl_Interp *interp) {
    if (Tcl_InitStubs(interp, "8.6", 0) == NULL) return TCL_ERROR;
    if (Tk_InitStubs(interp, "8.6", 0)  == NULL) return TCL_ERROR;
    if (Tcl_PkgProvide(interp, "Gateext", "1.0") == TCL_ERROR) return TCL_ERROR;
    Tcl_CreateObjCommand(interp, "gate_winsys", GateWinsysCmd, 0, 0);
    return TCL_OK;
}
```

**Security constraint (RESEARCH §Security V5):** the extension must NOT parse untrusted input — keep it to `tk windowingsystem`. Do not reuse the unsafe PLY parser.

---

### gate-assert script (NEW — test/smoke, e.g. `test/gate/gate_check.R`)

**Analog:** `R/rtkogl.R` `.onLoad` — the `tcl("load", ...)` path the gate must exercise (D-03; the gate script is a standalone mirror of this load path). No test framework exists (RESEARCH §Validation Architecture), so this is a scriptable assert, not a `testthat` test.

**Load path to mirror** (`R/rtkogl.R:492-497`):

```492:497:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
  tryCatch(
    tcl("load", file, "Tkogl2"),
    error = function(e)
      warning("loading tkogl2 failed: ", conditionMessage(e), call. = FALSE)
  )
```

**DLL-name/arch resolution pattern to reuse** for locating the built gate dylib (`R/rtkogl.R:468-481`):

```468:481:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
  chname <- "tkogl2"
  file.ext <- .Platform$dynlib.ext #dll file
  dlname <- paste(chname, file.ext, sep = "")

  candidates <- c(
    if (is.character(.Platform$r_arch) && .Platform$r_arch != "") file.path("libs", .Platform$r_arch, dlname),
    file.path("libs", "x64", dlname),
    file.path("libs", dlname)
  )
  file <- ""
  for (cand in candidates) {
    full <- system.file(cand, package = pkgname, lib.loc = libname)
    if (nzchar(full) && file.exists(full)) { file <- full; break }
  }
```

**Gate assert to write** (from RESEARCH §Code Examples; command-line R only, NOT R.app — Pitfall 2):

```r
library(tcltk)
stopifnot(tclvalue(.Tcl("tk windowingsystem")) == "aqua")   # GATE-01
tcl("load", "/path/to/gateext.dylib", "Gateext")
stopifnot(tclvalue(.Tcl("gate_winsys")) == "aqua")           # proves Tk-linked load path
```

---

### gate-ext build recipe (NEW — build config, e.g. `test/gate/CMakeLists.txt` or Makefile)

**Analog:** `CMakeLists.txt` (project shape: `cmake_minimum_required(VERSION 3.16)`, `project(... C)`, opaque-lib target). But the gate ext is a **macOS `.dylib`** compiled with Apple Clang against Aqua Tcl/Tk headers — a separate, much smaller target than the Windows `tkogl2.dll`. Simplest is a standalone `clang` invocation or tiny CMake/Makefile in the gate test dir. Reuse the CMake header-conventions but link `-framework Tcl -framework Tk` (or the Homebrew Aqua `tcl-tk` libs) instead of the Windows import libs at `CMakeLists.txt:106-114`.

---

### GATE-02 setup doc (NEW — docs, README § or standalone)

**Analog:** `tkogl2/BUILD.md` (existing build/deploy procedure doc) and top-level `README.md`. The doc records the reproducible "R + Aqua Tk" setup + the bundling-spike outcome (D-01 vs D-02 fallback). Match the existing doc voice/structure. Claude's discretion on README-section vs standalone (CONTEXT D-decisions).

---

## Shared Patterns

### Compile-time backend selection (D-05, Pattern 2)
**Source:** `RunTime_Defines_ZARF_9.h` (hard-`#define CODE_FOR_LIBRARY`, `#undef __linux__`) + existing `#ifdef _WIN32` usage.
**Apply to:** `gfx_backend_wgl.c` (whole-body `#ifdef _WIN32`), `CMakeLists.txt` (add file, rely on internal guard).

```1:12:integrated-guimorph-development_EOC/Project/tkogl2/src/RunTime_Defines_ZARF_9.h
#ifndef __RUN_TIME_DEFINES__
#define __RUN_TIME_DEFINES__

// First undefine all known pre processor defines
// This list is current as of 18 May 2020
// DO NOT CORRUPT THE UNDEFINES HERE
//
#undef STAND_ALONE_TOOL
#undef CODE_FOR_LIBRARY 
#undef __linux__
#undef NO_GRAPHICS
#undef STAND_ALONE_OPEN_GL
```

Consequence: `__linux__` swap branch is dead — drop it, don't port it (Pitfall 6). `CODE_FOR_LIBRARY` is force-defined at `:35` — the seam must NOT gate its calls behind `CODE_FOR_LIBRARY`-only blocks; they must compile under `STAND_ALONE_TOOL` too (Pitfall 4).

### Behavior-preserving refactor (D-05 — the governing constraint)
**Source:** RESEARCH §Pitfall 3 + `tcl_window.c:58-60` (leaked `HGLRC rc`, no teardown).
**Apply to:** `gfx_backend_wgl.c`, `tcl_window.c`.
Define `gfx_destroy` per the 5-function contract, but leave it **unwired** (or preserve the current create-without-prior-destroy lifecycle). Adding `wglDeleteContext`/`ReleaseDC` where none existed is a behavior change / scope creep. Track the leak as a follow-up Open Question, do NOT fix it here.

### Static seam-completeness gate (RND-01 verification)
**Source:** RESEARCH §Validation Architecture.
**Apply to:** the whole `src/` tree as a per-commit check.
`grep -REn 'HDC|HGLRC|SwapBuffers|wgl' src/ | grep -v gfx_backend_wgl.c` must be EMPTY after extraction — proves no platform symbol leaked back into core (this is the automated boundary check for RND-01).

### Init boilerplate (Tcl `load` contract)
**Source:** `tcl_init.c:14-33` (`Tcl_InitStubs` + `Tcl_PkgProvide` + `Tcl_CreateObjCommand`).
**Apply to:** `gate_ext.c` (plus mandatory `Tk_InitStubs` — see that file's section).

## No Analog Found

Files with no close match in the codebase (planner should source these fresh):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| PLY fixture (`test/fixtures/*.ply`) | test data | file-I/O | **No `.ply` is committed anywhere** (`[VERIFIED: find -iname '*.ply' → none]`, RESEARCH Open Q2). The plan must source/commit a small PLY (or the Windows maintainer supplies one). Claude's-discretion "pick an existing sample" has nothing to pick. |
| gate-assert as a *framework* test | test | — | No `testthat`/`tests/` exists (RESEARCH §Validation). The assert is a standalone scriptable check, not a framework test — its load-path analog is `.onLoad`, but there is no existing test-harness pattern to copy. |

## Cross-Cutting Notes for the Planner

- **Two independent workstreams, no shared code:** Workstream A (GATE-01/02: `gate_ext.c` + assert script + doc + bundling spike) and Workstream B (RND-01/CMP-01: seam extraction). They can be planned/parallelized independently.
- **CMP-01 is off-box:** the MSVC `tkogl2.dll` build + PLY eyeball render CANNOT run on the macOS dev machine (no MSVC/Windows R). Delegate to a Windows maintainer; treat "Windows still works" as a manual off-box checkpoint (RESEARCH §Environment Availability).
- **D-01 bundling is unproven (A2):** the bundling spike must first prove `aqua` is reachable at all (rebuild base `tcltk` against Aqua Tk), then test the package-local ideal; fall back to the documented Homebrew-Aqua path if infeasible.
- **Rebuild the shipped DLL:** after the seam refactor, the committed `inst/libs/x64/tkogl2.dll` must be rebuilt (MSVC) + redeployed so binary matches source (RESEARCH §Runtime State Inventory, §Security V10/V14).

## Metadata

**Analog search scope:** `integrated-guimorph-development_EOC/Project/tkogl2/src/`, `tkogl2/CMakeLists.txt`, `GUImorphDevelopment/R/`, top-level + `tkogl2/BUILD.md`.
**Files scanned (read in full or targeted):** `tcl_init.c`, `tcl_window.c`, `tcl_window.h`, `def_ZARF_9.h`, `RunTime_Defines_ZARF_9.h`, `CMakeLists.txt`, `rtkogl.R`, `tcl_dispatch.c` (onDisplay/SwapBuffers regions).
**Pattern extraction date:** 2026-07-12
