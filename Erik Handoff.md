# Erik Handoff — Phase 1: Aqua-Tk Deployment Gate + Windows Rendering Seam

## Context (plain terms)
The app renders 3D specimens using OpenGL. The code that sets up *where* OpenGL draws was
written entirely for Windows. macOS handles windows and graphics contexts differently, so
that setup code cannot be reused directly.

Phase 1 separated the app into two layers:
- **Core** — the app logic (loading meshes, handling the viewport, drawing).
- **Backend** — the platform-specific code that creates a drawing surface and shows the result.

They communicate only through a small fixed interface (`gfx_backend.h`) with five functions:
create a surface, make it active, present a finished frame (swap), resize, and destroy. The
core knows nothing about the platform underneath. The Windows implementation lives in
`gfx_backend_wgl.c`; a macOS backend (Phase 4) will be a separate file implementing the same
five functions. NOTE: GSD plugin uses "Phases" to break "Milestones" down into actionable tasks. They just live as markdown files with instructions for agents. Let me know if you want to see them. I gitignore then by default to not clog up the repo.

**One shared interface, one backend per platform.** Windows is done; Phases 2–5 build and
refine the macOS backend behind that same interface.

---

## 1. The seam interface (the "wall with 5 doors") — NEW

`integrated-guimorph-development_EOC/Project/tkogl2/src/gfx_backend.h`

```c
#ifndef GFX_BACKEND_H
#define GFX_BACKEND_H

typedef struct gfx_surface gfx_surface;

gfx_surface *gfx_create(void *native_drawable);
int gfx_make_current(gfx_surface *s);
void gfx_swap(gfx_surface *s);
void gfx_resize(gfx_surface *s, int w, int h);
void gfx_destroy(gfx_surface *s);

extern gfx_surface *g_surface;

#endif
```

## 2. The Windows backend (wiring behind the wall) — NEW

`integrated-guimorph-development_EOC/Project/tkogl2/src/gfx_backend_wgl.c`

All Windows-only OpenGL/window code, sealed under `#ifdef _WIN32`. This is the only file
allowed to know about `HWND`, `HDC`, `HGLRC`, `wgl*`, and `SwapBuffers`.

```c
gfx_surface *gfx_create(void *native_drawable)
{
	HWND hwnd = (HWND)native_drawable;
	if (hwnd == NULL) { return NULL; }
	// ... allocates surface, gets device context, sets pixel format ...
	s->rc = wglCreateContext(s->dc);
	// ...
	return s;
}

void gfx_swap(gfx_surface *s)
{
	if (s == NULL) { return; }
	SwapBuffers(s->dc);
}

void gfx_resize(gfx_surface *s, int w, int h)
{
	/* WGL requires no resize update; NSGL will use this seam in Phase 4. */
	(void)s; (void)w; (void)h;
}
```

## 3. Core files updated to use the seam — MODIFIED

**`src/tcl_window.c`** — now calls the 5 seam functions instead of Windows APIs.
`setWindowId` takes a platform-neutral `void *`:

```c
int setWindowId(void *native_drawable)
{
	g_surface = gfx_create(native_drawable);
	gfx_make_current(g_surface);
	ogl_init();
	return TCL_OK;
}
```

The `01-05` gap fix changed the window-id path so no `HWND` type appears in core anymore —
it widens the Tcl int to a pointer safely:

```c
int hwndId = 0;
Wrapper_GetIntFromObj(interp, objv[2], &hwndId);
void *native_drawable = (void *)(intptr_t)hwndId;
```

**`src/tcl_window.h`** — matching declaration: `int setWindowId(void *native_drawable);`

**`src/tcl_dispatch.c`** — the `onDisplay` path now presents frames via `gfx_swap(g_surface)`
and drops a dead Linux branch.

**`src/def_ZARF_9.h`** — Windows headers moved out of core; the `// TBD ??` debt marker on
`model_t.count` replaced with a real definition (vertex count for `glDrawArrays`, three per
triangle).

**`CMakeLists.txt`** — adds `gfx_backend_wgl.c` to the build.

## 4. The deployment gate — macOS "can R even reach Aqua Tk?" test — NEW

**`test/gate/gate_check.R`** — the automated proof script:

```r
library(tcltk)

winsys <- tclvalue(.Tcl("tk windowingsystem"))
stopifnot(identical(winsys, "aqua"))

dylib_path <- resolve_dylib(args[[1]] %||% NULL)
tcl("load", dylib_path, "Gateext")

gate_winsys <- tclvalue(.Tcl("gate_winsys"))
stopifnot(identical(gate_winsys, "aqua"))

cat("gate_check: PASS\n")
```

**`test/gate/gate_ext.c`** — a tiny Tk-linked C extension proving a compiled extension can
load and talk to Aqua Tk (`Tcl_InitStubs` + `Tk_InitStubs`, registers `gate_winsys`).

**`test/gate/CMakeLists.txt`** — macOS-only build for that extension (links Homebrew tcl-tk).

**`test/gate/.gitignore`** — ignores the local build output.

## 5. Documentation — NEW

**`docs/AQUA-TK-SETUP.md`** — the reproducible "install this, run this" setup guide for a
macOS researcher, and it records the locked distribution decision (`d01-bundled`).

## 6. Test fixture — NEW

**`test/fixtures/regression.ply`** — a tiny 4-vertex tetrahedron mesh, committed so there's a
known model to render for the "Windows still works" check.

---

## Summary table

| File | Status | Purpose |
|------|--------|---------|
| `src/gfx_backend.h` | new | The 5-function seam interface |
| `src/gfx_backend_wgl.c` | new | Windows backend behind the seam |
| `src/tcl_window.c` | modified | Core routed through seam; HWND removed |
| `src/tcl_window.h` | modified | `setWindowId(void *)` declaration |
| `src/tcl_dispatch.c` | modified | `onDisplay` uses `gfx_swap`; dead branch removed |
| `src/def_ZARF_9.h` | modified | Win headers out of core; TBD marker resolved |
| `CMakeLists.txt` | modified | Builds the new backend file |
| `test/gate/gate_check.R` | new | Automated Aqua-Tk proof script |
| `test/gate/gate_ext.c` | new | Trivial Tk-linked C extension |
| `test/gate/CMakeLists.txt` | new | Build for the gate extension |
| `test/gate/.gitignore` | new | Ignore local build output |
| `docs/AQUA-TK-SETUP.md` | new | Reproducible macOS setup + decision |
| `test/fixtures/regression.ply` | new | Known mesh for render regression |

All paths are relative to `integrated-guimorph-development_EOC/Project/tkogl2/` except
`CMakeLists.txt` (that project's root).
