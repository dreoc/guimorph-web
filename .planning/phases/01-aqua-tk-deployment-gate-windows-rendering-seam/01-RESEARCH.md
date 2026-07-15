# Phase 1: Aqua-Tk Deployment Gate + Windows Rendering Seam - Research

**Researched:** 2026-07-12
**Domain:** (a) R↔Tcl/Tk deployment on macOS — proving/packaging an Aqua (Cocoa) Tk configuration; (b) mechanical extraction of Win32/WGL window/context code behind a C platform seam
**Confidence:** HIGH (seam extraction, code facts, Tk-flavor mechanism) / MEDIUM (bundling feasibility — needs empirical spike on a real Mac)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Target a **bundled prebuilt Aqua Tcl/Tk framework** shipped inside the package as the documented researcher setup — goal is zero manual Tcl/Tk setup for researchers. Rejected: Homebrew `tcl-tk` + R reconfigure (reproducible but pushes setup burden onto the researcher); ActiveTcl.
- **D-02:** The exact bundling mechanics (framework layout, how R's `tcltk`/Tk is pointed at the bundled Aqua Tk, feasibility vs CRAN R's default X11 Tk linkage) remain a **planning research spike** — the spike validates that bundling is viable before it's locked. Bundling has downstream weight: sign/notarize + `universal2` (ties into Phase 4 BLD-03). If the spike shows bundling is infeasible/too costly, fall back to the documented Homebrew-Aqua-Tk path.
- **D-03:** **Commit a throwaway trivial Aqua-Tk C extension** to the repo as a repeatable smoke test that R can `load` an Aqua-backed Tk extension. It doubles as a regression guard for the load path (not a one-time manual check).
- **D-04:** `gfx_backend.h` exposes exactly **5 functions**: `create` / `make_current` / `swap` / `resize` / `destroy`. No speculative extras (drawable-size query, explicit present/clear) — add those only when the macOS backend actually needs them.
- **D-05:** Seam extraction is a **pure mechanical refactor** on the Windows side: move WGL/HDC/HGLRC/`SwapBuffers` code, do not change rendering behavior. Windows selects the WGL backend at compile time (`#ifdef _WIN32` / CMake `WIN32` branch); no macOS code compiles into the Windows build.
- **D-06:** "Renders identically" = **build MSVC `tkogl2.dll` + `load` it + eyeball-render a known PLY mesh**. Pragmatic manual check; no screenshot/pixel-compare baseline infra this phase.

### Claude's Discretion
- Seam file naming/layout beyond `gfx_backend.h` + `gfx_backend_wgl.c` (e.g., where the seam header lives in `src/`).
- Which specific PLY fixture serves as the regression mesh (pick an existing sample already used by the Windows build).
- Exact form/location of the GATE-02 setup doc (README section vs standalone doc) and the trivial-extension test's directory.

### Deferred Ideas (OUT OF SCOPE)
- Homebrew `tcl-tk` + R-reconfigure setup path — kept as the documented fallback if the bundling spike (D-02) shows bundling is infeasible.
- Screenshot/pixel-compare regression baseline — heavier rigor than needed now; revisit if eyeball checks prove insufficient in later phases.
- Seam extras (drawable-size query, explicit present/clear) — add when the macOS NSOpenGL backend (Phase 4) actually needs them.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GATE-01 | R session on macOS reports `tk windowingsystem == aqua` and can `load` a trivial Aqua-Tk C extension (X11/XQuartz ruled out) | Runtime verification command + the Tk-flavor-is-baked-at-R-build-time mechanism (§Deployment Gate); trivial-extension pattern lifted from `Tkogl2_Init` (§Code Examples) |
| GATE-02 | Documented, reproducible "R + Aqua Tk" config researchers can follow | Option space + feasibility ranking (§Deployment Gate Options); bundling spike protocol (§Bundling Spike) |
| RND-01 | Isolate window/context creation behind `gfx_backend.h` (create/make_current/swap/resize/destroy); WGL code moved behind it unchanged | Exact call-site inventory + seam mapping (§Rendering Seam); dual-build-mode preservation (§Common Pitfalls) |
| CMP-01 | Windows build still works (MSVC `tkogl2.dll` builds + renders PLY identically) | Regression procedure + fixture gap + no-Windows-machine-here flag (§Environment Availability, §Validation Architecture) |
</phase_requirements>

## Summary

Phase 1 has two independent workstreams that share no code. **Workstream A (GATE-01/02)** is a *deployment* question, not a coding question: it proves and documents that an R session on macOS can talk to an **Aqua (Cocoa) Tk** and `load` a native Tk C extension. **Workstream B (RND-01/CMP-01)** is a *pure mechanical refactor*: lift the Win32 `HDC`/`HGLRC`/`wglCreateContext`/`wglMakeCurrent`/`SwapBuffers` code out of `tcl_window.c` and `onDisplay()` into a new `gfx_backend_wgl.c` behind a 5-function `gfx_backend.h` seam, changing no rendering behavior, and confirm the MSVC DLL still renders a PLY.

The single highest-impact research finding governs D-01/D-02: **the Tk flavor (aqua vs x11) is fixed at R build/configure time, not selectable at runtime.** R's base `tcltk` package ships as `tcltk.so`, which is *dynamically linked* against a specific `libtk8.6`/`libtcl8.6` (and, on CRAN's macOS build, directly against `libX11`) chosen by `--with-tcl-config`/`--with-tk-config` when R was built `[CITED: R Installation & Administration §C.3.8]`. The CRAN macOS R binary is built against **X11** Tcl/Tk `[CITED: cran.r-project.org/bin/macosx — "Tcl/Tk 8.6.12 X11 libraries"]`. This means **bundling an Aqua Tcl/Tk framework inside the GUImorph package does not, by itself, make a stock CRAN R report `aqua`** — nothing redirects the already-X11-linked `tcltk.so` to the bundled framework. The bundling spike (D-02) must therefore validate a *mechanism* to make R's `tcltk` use the bundled Aqua Tk (rebuild/relink the `tcltk` shared object, or ship a purpose-built R), not merely place a framework on disk. This is the phase's central feasibility risk.

**Primary recommendation:** Run the deployment gate as a genuine spike *first* (install an Aqua Tcl/Tk, get `tk windowingsystem == aqua` under *some* R config, `load` the trivial extension), then decide D-01-vs-fallback based on empirical results — because the "zero-setup bundled framework" ideal is at odds with how R binds Tk. Run Workstream B (seam extraction) fully independently; it is low-risk, well-scoped, and does not touch the gate. The Windows regression (CMP-01) **cannot be executed on this macOS dev machine** (no MSVC/Windows R) and must be delegated to a Windows environment/maintainer.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Prove `tk windowingsystem == aqua` | R runtime + Tcl/Tk build config | Native (C ext load) | The flavor is a property of how R's `tcltk.so` is linked; verified from R via `.Tcl("tk windowingsystem")`. |
| Load a trivial Tk C extension | Native C (DLL/dylib) via Tcl `load` | R `.onLoad` | Mirrors the existing `tcl("load", file, "Tkogl2")` path; the extension is a Tcl-loadable shared lib. |
| Distribute a reproducible Aqua-Tk config | Packaging / build + docs | R install | GATE-02 is a documentation + packaging deliverable, not runtime code. |
| Window/context create + present | Native platform seam (`gfx_backend_wgl.c`) | Core draw (`onDisplay`) | WGL/`HDC`/`HGLRC` are platform-owned; the seam isolates them from the tier-neutral GL draw pass. |
| GL draw pass, viewport, ortho, model transform | Native core (`tcl_dispatch.c` `onDisplay`) | — | Generic OpenGL; stays platform-agnostic and calls the seam only for present/make-current. |

## Standard Stack

This phase installs **no language-registry packages** (no npm/PyPI/crates). Its external dependencies are a C toolchain, a Tcl/Tk distribution flavor, and (for the Windows regression) MSVC + Windows R. "Stack" here = the components the gate and the seam depend on.

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Aqua (Cocoa) Tcl/Tk | 8.6.x (system ships 8.5; prefer 8.6.14+) | The windowing system that must report `aqua`; hosts the trivial C extension | `[CITED: tcltk/tk macosx/README]` Aqua vs X11 are the two macOS Tk builds; only Aqua avoids the broken XQuartz/GLX path. Built with `--enable-aqua --enable-framework`. |
| macOS R (command-line) 4.6+ | 4.6.1 current | Runs `tcltk`, exercises the `load` path | `[CITED: R-admin §C.3.8]` Aqua Tk "will not work with R.APP" — the gate must use **command-line R**, not R.app. |
| Xcode Command Line Tools (Apple Clang) | CLT 15+ (present on this machine) | Compile the trivial Aqua-Tk C extension; `otool`/`install_name_tool`/`lipo` for linkage inspection | `[VERIFIED: local probe]` `clang`, `otool`, `install_name_tool`, `lipo` all present at `/Library/Developer/CommandLineTools`. |
| MSVC (VS 2022 Build Tools) | v143 | Build `tkogl2.dll` for CMP-01 | `[VERIFIED: BUILD.md]` MinGW renders black; **MSVC is the only supported Windows toolchain**. |
| CMake | ≥ 3.16 | Existing build system; adds `gfx_backend_wgl.c` to the target | `[VERIFIED: tkogl2/CMakeLists.txt]` already `cmake_minimum_required(VERSION 3.16)`. |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| Homebrew `tcl-tk` | 8.6.x / 9.x | Fast way to obtain an **Aqua** Tcl/Tk for the spike and the documented fallback | `[CITED: Homebrew Formula/t/tcl-tk.rb]` builds Tk with `--enable-aqua=yes --without-x` → genuine Aqua. This is the D-02 fallback distribution. |
| `Tcl.framework` / `Tk.framework` (Aqua) | 8.6.x | The "prebuilt Aqua framework" D-01 wants to bundle; also the target of `--with-tcl-config`/`--with-tk-config` | `[CITED: R-admin §C.3.8]` documents pointing R at `/Library/Frameworks/{Tcl,Tk}.framework/*Config.sh`. |
| `tclsh` / `wish` (Aqua) | — | Smoke-test `load` of the extension outside R (fastest inner loop) | `[CITED: STACK.md]` `echo 'load ./ext.dylib Pkg' | wish` reproduces the R load path minus R. System `/usr/bin/wish` exists but is old (8.5) `[VERIFIED: local probe]`. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Bundled Aqua framework (D-01) | Homebrew `tcl-tk` + reconfigured/rebuilt R (fallback) | Reproducible and Aqua-correct, but pushes setup onto the researcher (rejected as primary per D-01, kept as fallback per D-02). |
| Bundled Aqua framework (D-01) | ActiveTcl / TclTkAquaBI batteries-included Aqua distro | `[CITED: tcl-lang wiki]` a maintained Aqua distro, but a third-party dependency and still requires making R's `tcltk` link against it — explicitly rejected in D-01. |
| Rebuild R from source against Aqua Tk | Recompile only the base `tcltk` package against Aqua Tcl/Tk and overlay it | Lighter than a full R rebuild; **must be tested in the spike** — whether a rebuilt `tcltk.so` linked to Aqua Tk loads cleanly into a stock CRAN R is the open question. |

**Installation (spike / dev setup on macOS — Apple Silicon):**
```bash
xcode-select --install                         # already present here
brew install tcl-tk                            # Aqua Tk (--enable-aqua --without-x)
brew install --cask r     # or download the CRAN R 4.6.x pkg (command-line R)
brew install cmake                             # not currently installed here
```

**Version verification (run during the spike, not assumable):**
```bash
brew info tcl-tk                               # confirm installed version + aqua
echo 'puts [tk windowingsystem]' | "$(brew --prefix tcl-tk)/bin/wish"   # expect: aqua
otool -L "$(brew --prefix tcl-tk)/lib/libtk8.6.dylib" | grep -i x11     # expect: no X11
```

## Package Legitimacy Audit

**Not applicable — this phase installs no npm/PyPI/crates packages.** External dependencies are system/toolchain components (Tcl/Tk, Xcode CLT, MSVC, CMake) obtained from first-party sources.

Provenance of the non-registry dependencies:
| Component | Source | Legitimacy signal | Disposition |
|-----------|--------|-------------------|-------------|
| Aqua Tcl/Tk | tcl-lang.org sources / `/Library/Frameworks` / Homebrew | Canonical upstream; Homebrew formula builds from tcl-lang release tarballs `[CITED: Homebrew formula]` | Approved |
| Homebrew `tcl-tk` | `Homebrew/homebrew-core` | Official core formula, `--enable-aqua` `[CITED]` | Approved (fallback path) |
| Xcode CLT / MSVC / CMake | Apple / Microsoft / Kitware | First-party toolchains | Approved |

No `[SLOP]` or `[SUS]` items. No `checkpoint:human-verify` install gates required for third-party packages.

## Architecture Patterns

### System Architecture — the rendering seam (RND-01)

```
                 R GUI (rtkogl.R)  ──tcl("setWindow","id",<hwnd/pathname>)──┐
                                                                            ▼
   ┌──────────────────────── Native core (platform-neutral) ───────────────────────┐
   │  setWindow (tcl_window.c)          onDisplay() (tcl_dispatch.c:3534)            │
   │   ├─ "id"   → resolve drawable ──┐   ├─ glViewport / glOrtho / glClear          │
   │   ├─ "size" → store w/h, glViewport/glOrtho (generic GL — stays in core)       │
   │   └─ "mode" → showModel                                                          │
   │              │                   │   ├─ glRotate/Scale/Translate + ogl_drawModel│
   │              │ create + make_current + ogl_init()   └─ swap ──────┐              │
   └──────────────┼───────────────────────────────────────────────────┼─────────────┘
                  ▼   (the ONLY window/context calls)                   ▼
   ┌───────────────────────── gfx_backend.h  (5-function seam, D-04) ─────────────────┐
   │  gfx_create(drawable) · gfx_make_current(s) · gfx_swap(s) · gfx_resize(s,w,h)     │
   │  · gfx_destroy(s)                                                                 │
   └───────────────┬───────────────────────────────  #ifdef _WIN32 / CMake WIN32 ─────┘
                   ▼
   ┌──────── gfx_backend_wgl.c (Windows-only; moved VERBATIM from tcl_window.c) ───────┐
   │  owns: HDC dc, HGLRC rc   |  GetDC · ChoosePixelFormat · SetPixelFormat           │
   │  · wglCreateContext · wglMakeCurrent · SwapBuffers(dc) · [wglDeleteContext/ReleaseDC]│
   └───────────────────────────────────────────────────────────────────────────────────┘
```

### Exact code inventory to move (verified against source)

| Item | Current location | Moves to | Notes |
|------|------------------|----------|-------|
| `HDC dc;` global | `tcl_window.c:20`, declared `extern HDC dc;` in `def_ZARF_9.h:112` | Backend-owned state in `gfx_backend_wgl.c` | Remove the `extern HDC dc;` from the platform-neutral header; core must not see `HDC`. |
| `GetDC` + `PIXELFORMATDESCRIPTOR` + `ChoosePixelFormat` + `SetPixelFormat` + `wglCreateContext` | `tcl_window.c:42-58` (`setWindowId`) | `gfx_create()` | The `HGLRC rc` is currently a **leaked local** (never stored, never deleted). |
| `wglMakeCurrent(dc, rc)` | `tcl_window.c:60` | `gfx_make_current()` | Also implicitly done inside create today. |
| `ogl_init()` call | `tcl_window.c:62` | **stays in core** (`setWindow` "id" path), called *after* create+make_current | `ogl_init` is generic GL, not platform — do not pull into the backend. |
| `SwapBuffers(dc)` under `#ifdef _WIN32` | `tcl_dispatch.c:3599` (`onDisplay`) | `gfx_swap()` | The sibling `#elif __linux__ glXSwapBuffers(...)` branch (`:3602`) is **dead code** — `__linux__` is `#undef`'d in `RunTime_Defines_ZARF_9.h:10`. Drop it during extraction. |
| `int width; int height;` globals + `glViewport`/`glOrtho` | `tcl_window.c:22-23`, resize logic in `setWindow` "size" (`:146-162`) | `width`/`height` **stay in core**; `gfx_resize(s,w,h)` added for backends that need it (WGL: no-op/store) | The GL `glViewport`/`glOrtho` are generic — keep in core. On Windows WGL nothing extra is needed on resize, so `gfx_resize` is a near no-op that documents where NSGL's `[ctx update]` will go (Phase 4). |
| Context teardown | **does not exist today** (leak) | `gfx_destroy()` defined; see pitfall | To honor D-05 "change no behavior," `gfx_destroy` may be a defined-but-unwired stub, or wired carefully — see Pitfall 3. |

### Pattern 1: Opaque handle owned as a singleton
**What:** `gfx_backend.h` exposes an opaque `typedef struct gfx_surface gfx_surface;` (definition lives only in the backend `.c`). The core holds one `gfx_surface*` (consistent with the engine's existing global-singleton state in `tcl_state.c`).
**When to use:** Everywhere the core previously touched `dc`.
**Example (proposed seam header):**
```c
/* gfx_backend.h — the ONLY window/context interface the core includes */
#ifndef GFX_BACKEND_H
#define GFX_BACKEND_H
typedef struct gfx_surface gfx_surface;      /* opaque; defined per-backend */
gfx_surface *gfx_create(void *native_drawable);   /* WGL: cast to HWND */
int  gfx_make_current(gfx_surface *s);
void gfx_swap(gfx_surface *s);
void gfx_resize(gfx_surface *s, int w, int h);
void gfx_destroy(gfx_surface *s);
#endif
```
Rationale: `void *native_drawable` keeps `HWND`/`HDC`/`NSView*` out of the platform-neutral header (removes the `extern HDC dc;` leak in `def_ZARF_9.h`). The WGL backend casts `native_drawable` back to `HWND`.

### Pattern 2: Compile-time backend selection (D-05)
**What:** `gfx_backend_wgl.c` guards its whole body with `#ifdef _WIN32`; CMake adds it under `if(WIN32)` (or unconditionally, relying on the internal guard). No `#else`/macOS code compiles into the Windows build this phase.
**Example (CMakeLists.txt addition):**
```cmake
add_library(tkogl2 SHARED
    ${SRC}/tcl_init.c
    ...
    ${SRC}/tcl_window.c
    ${SRC}/gfx_backend_wgl.c   # new; body is #ifdef _WIN32
)
```

### Pattern 3: Trivial Aqua-Tk C extension (GATE-01 / D-03)
**What:** A minimal Tcl-loadable shared lib whose only job is to prove the `load` path works against Aqua Tk. Modeled on the real `Tkogl2_Init` (`tcl_init.c`).
**When to use:** As a committed, repeatable smoke test + regression guard.
**Example:**
```c
/* gate_ext.c — proves Tcl load + Tk linkage under Aqua */
#include <tcl.h>
#include <tk.h>
static int GateWinsysCmd(ClientData cd, Tcl_Interp *ip, int objc, Tcl_Obj *const objv[]) {
    /* returns tk windowingsystem so the test can assert == "aqua" */
    return Tcl_Eval(ip, "tk windowingsystem");
}
int DLLEXPORT Gateext_Init(Tcl_Interp *interp) {
    if (Tcl_InitStubs(interp, "8.6", 0) == NULL) return TCL_ERROR;
    if (Tk_InitStubs(interp, "8.6", 0) == NULL)  return TCL_ERROR;   /* proves Tk (not just Tcl) links */
    if (Tcl_PkgProvide(interp, "Gateext", "1.0") == TCL_ERROR) return TCL_ERROR;
    Tcl_CreateObjCommand(interp, "gate_winsys", GateWinsysCmd, 0, 0);
    return TCL_OK;
}
```
Key point: linking `Tk_InitStubs` (not only `Tcl_InitStubs`) is what actually exercises the Tk-flavor binding — a Tcl-only extension would load under X11 too and prove nothing about Aqua.

### Anti-Patterns to Avoid
- **Leaking `HDC`/`HGLRC` into the core:** after extraction the platform-neutral headers (`def_ZARF_9.h`, `tcl_dispatch.h`) must contain no `HDC`/`HWND`/`HGLRC`/`SwapBuffers`. If they do, the seam is incomplete.
- **"Fixing" the context leak as part of the refactor:** D-05 says *change no behavior*. Adding teardown is a behavior change — track it separately (Pitfall 3).
- **Editing the duplicated R sources:** `[VERIFIED: ARCHITECTURE.md]` `tkogl2/R/` is a stale copy; authoritative R is `GUImorphDevelopment/R/`. GATE work touching R (`.onLoad`) goes in the authoritative tree.
- **Testing the gate in R.app:** `[CITED: R-admin §C.3.8]` Aqua Tk "does not work in R.APP" — use command-line R.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting Tk flavor | String-sniffing library paths | `tclvalue(.Tcl("tk windowingsystem"))` in R / `[tk windowingsystem]` in Tcl | `[CITED: R-admin §C.3.8, tcltk/tk README]` the canonical, documented runtime check; returns `aqua`/`x11`. |
| Inspecting what `tcltk.so`/an extension links | Custom parser | `otool -L <file>` | `[CITED: R tcltk unix/zzz.R]` R itself uses `otool -L` at `tcltk` load to detect X11 linkage. |
| Building Aqua Tcl/Tk | Hand-configured build | Homebrew `tcl-tk` or upstream `--enable-aqua --enable-framework` GNUmakefile | `[CITED: tcltk/tk README, Homebrew formula]` well-trodden; the macOS GNUmakefiles wrap the unix build. |
| Relinking a dylib's dependency path | Rebuild everything | `install_name_tool -change old new file` | `[CITED: multiple]` standard macOS relink tool — relevant if the spike tries redirecting `tcltk.so` to a bundled Aqua Tk. |
| Trivial extension init boilerplate | New pattern | Copy `Tkogl2_Init` shape (`tcl_init.c`) | `[VERIFIED: codebase]` `Tcl_InitStubs`+`Tcl_PkgProvide`+`Tcl_CreateObjCommand` is the established, working pattern. |

**Key insight:** The gate is a *configuration/packaging* problem with mature, documented primitives — the risk is not "how to build Aqua Tk" (solved) but "how to make R's pre-linked `tcltk` use it" (the spike).

## Deployment Gate: mechanism, options, and the bundling spike

### The governing mechanism (why D-01 is at risk)
- R's base **`tcltk` package is a compiled shared object (`tcltk.so`)** that is dynamically linked against a specific `libtk8.6`/`libtcl8.6` (and, on CRAN macOS, `libX11`) chosen at R build time via `--with-tcl-config`/`--with-tk-config`. `[CITED: R-admin §C.3.8]`
- The **CRAN macOS R binary is built against X11 Tcl/Tk 8.6.12** (`Tcl/Tk 8.6.12 X11 libraries`, an optional installer component requiring XQuartz). `[CITED: cran.r-project.org/bin/macosx, RMacOSX-FAQ §6]`
- At load, R's `tcltk` runs `otool -L tcltk.so` and, if it sees `libtk*.dylib`/`libX11*.dylib`, checks those files exist — confirming the flavor is **baked into the linked `.so`, not chosen at runtime**. `[CITED: R source src/library/tcltk/R/unix/zzz.R]`
- Therefore **placing an Aqua `Tcl.framework`/`Tk.framework` on disk (or inside the package) does not change what a stock CRAN R's `tcltk.so` loads** — there is no runtime env var that repoints an already-linked X11 `tcltk.so` to Aqua. (`TCLLIBPATH`/`TCL_LIBRARY`/`TK_LIBRARY` affect *script* auto_path, not the linked binary flavor. `[CITED: R-admin]`)

**Consequence for D-01:** "bundle a prebuilt Aqua framework for zero researcher setup" is insufficient on its own. Achieving `aqua` requires an R whose **`tcltk.so` is linked against Aqua Tk**. The spike must find and validate a mechanism to deliver that.

### Option space (ranked by researcher setup burden vs feasibility)

| # | Config | How `aqua` is achieved | Setup burden | Feasibility risk |
|---|--------|------------------------|--------------|------------------|
| A | **Bundle Aqua framework + recompiled `tcltk`** (D-01 ideal) | Ship an Aqua `tcltk` build (`.so` linked to bundled Aqua Tk) that overlays/loads ahead of base `tcltk`; or a package-local relinked `tcltk.so` | Low (goal) | **HIGH — unproven.** Overlaying a base package + `@rpath`/`install_name_tool` redirection to a bundled framework, universal2, sign/notarize. This is what the spike tests. |
| B | Rebuild only base `tcltk` against Aqua Tcl/Tk, reinstall | `R CMD INSTALL` a `tcltk` rebuilt with `TCLTK_LIBS`/`TCLTK_CPPFLAGS` pointing at Aqua framework | Medium (one rebuild step) | MEDIUM — recompiling a base package is doable but non-standard; ABI must match the running R. |
| C | Build/obtain an R configured `--with-tcl-config=.../Tcl.framework --with-tk-config=.../Tk.framework` | R's `tcltk.so` links Aqua Tk at build | High (custom R) | LOW technically, HIGH burden — a bespoke R is a lot to ask of a researcher. `[CITED: R-devel 2003 thread confirms this exact configure recipe]` |
| D | **Homebrew `tcl-tk` (Aqua) + reconfigured/rebuilt R** (documented fallback, D-02) | Same as B/C but sourced from Homebrew Aqua Tk | Medium–High | LOW risk, known-good; this is the deferred fallback if A is infeasible. `[CITED: Homebrew formula = --enable-aqua]` |

### Bundling Spike protocol (what the plan must actually run — D-02)
The spike is empirical and needs a real Mac with command-line R. Suggested ordered probes:
1. **Baseline:** install CRAN R + the X11 Tcl/Tk component; confirm `tclvalue(.Tcl("tk windowingsystem"))` → `x11`. Record `otool -L .../tcltk/libs/tcltk.so`.
2. **Prove `aqua` is reachable at all:** install Homebrew Aqua `tcl-tk`; rebuild/reinstall the base `tcltk` package against it (Option B/D); confirm the check now returns `aqua`. This de-risks everything downstream — if this fails, the whole native port is blocked (escalate).
3. **Prove the load path:** build the trivial extension (D-03) against the Aqua Tcl/Tk headers, `load` it from command-line R (and from bare `wish`), assert `gate_winsys` → `aqua`.
4. **Test the D-01 ideal:** attempt to make the Aqua binding *package-local* (bundled framework + relinked/overlaid `tcltk`), so a researcher needs zero manual Tcl/Tk steps. Measure: does it work on a *clean* machine? Does it survive quarantine + universal2 (ties to Phase 4 BLD-03)?
5. **Decide:** if step 4 is viable → lock D-01 (bundled). If not → fall back to the documented Homebrew-Aqua-Tk path (Option D) as GATE-02's reproducible setup.

**Deliverable framing (GATE-02):** whichever option wins, the output is a reproducible, documented setup a researcher follows, plus the committed trivial extension as its automated proof.

## Runtime State Inventory

> RND-01 is a code-move refactor, not a rename/data migration. All categories checked explicitly.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | **None** — the seam moves in-process C code; no database/datastore keys reference `dc`/`HGLRC` etc. | None |
| Live service config | **None** — no external service embeds the moved symbols. | None |
| OS-registered state | **None** — no scheduled tasks/launchd/services reference the window code. | None |
| Secrets/env vars | **None** — no secret or env var names change. | None |
| Build artifacts / installed packages | The committed `inst/libs/x64/tkogl2.dll` `[VERIFIED: CONCERNS.md]` is a prebuilt binary; after the refactor it must be **rebuilt (MSVC) and redeployed** so the shipped DLL matches the new source layout (CMP-01). CMake source list gains `gfx_backend_wgl.c`. | Rebuild + redeploy DLL per `BUILD.md §2-3`; add file to `CMakeLists.txt`. |

## Common Pitfalls

### Pitfall 1: Assuming a bundled Aqua framework flips the flavor
**What goes wrong:** Ship an Aqua `Tk.framework` in the package, expect `tk windowingsystem == aqua`, still get `x11`.
**Why it happens:** The flavor is linked into R's `tcltk.so` at R build time; a bundled framework on disk is inert unless R's `tcltk` is (re)linked to it. `[CITED: R-admin §C.3.8, R tcltk zzz.R]`
**How to avoid:** Treat D-01 as unproven until the spike shows a working package-local mechanism; otherwise fall back to D-02's Homebrew path.
**Warning signs:** `otool -L tcltk.so` still shows the CRAN X11 `libtk`/`libX11`.

### Pitfall 2: Testing the gate in R.app instead of command-line R
**What goes wrong:** Aqua Tk conflicts with R.app's Cocoa menu; misleading failures.
**Why it happens:** `[CITED: R-admin §C.3.8, RMacOSX-FAQ §6]` "Aqua Tk does not work with R.APP."
**How to avoid:** Run the gate from command-line R (`R` in Terminal), never R.app.

### Pitfall 3: "Fixing" the WGL context leak during the mechanical refactor (D-05 violation)
**What goes wrong:** `setWindowId` currently calls `wglCreateContext` on every `setWindow "id"` and **never** calls `wglDeleteContext`/`ReleaseDC` (`rc` is a leaked local; `dc` is overwritten) `[VERIFIED: tcl_window.c:42-63, no teardown in grep]`. It's tempting to wire `gfx_destroy` to free the old surface before re-create — but that changes behavior.
**Why it happens:** The seam *introduces* a `destroy` slot (D-04) that has no pre-existing counterpart.
**How to avoid:** Keep the refactor behavior-identical: define `gfx_destroy` but either leave it unwired or preserve the current create-without-prior-destroy lifecycle. Log the leak as a follow-up (Open Question), don't fix it here.
**Warning signs:** Reviewer sees a new `wglDeleteContext` call that didn't exist before — that's scope creep past D-05.

### Pitfall 4: Breaking the dual build mode (`CODE_FOR_LIBRARY` / `STAND_ALONE_TOOL`)
**What goes wrong:** `setWindow` has a `#ifdef STAND_ALONE_TOOL` variant and a `TCL_CMD` library variant (`tcl_window.c:66-70`); the seam must compile in both.
**Why it happens:** `[VERIFIED: RunTime_Defines_ZARF_9.h:35]` `CODE_FOR_LIBRARY` is hard-`#define`d; the standalone tool path still exists in `#ifdef`s.
**How to avoid:** Ensure `gfx_backend_wgl.c` and the seam calls work under both defines; don't wrap seam calls in `CODE_FOR_LIBRARY`-only blocks.

### Pitfall 5: Removing `extern HDC dc;` breaks a hidden consumer
**What goes wrong:** `dc` is declared `extern` in `def_ZARF_9.h:112` (widely included). Moving it into the backend could break an unexpected reader.
**How to avoid:** Grep confirms the only `dc` uses are `tcl_window.c` (create) and `tcl_dispatch.c:3599` (`SwapBuffers(dc)`) `[VERIFIED: grep]` — both convert to seam calls. Remove the `extern` only after both are routed through `gfx_*`.

### Pitfall 6: Dead `__linux__` swap branch
**What goes wrong:** Copying `#elif __linux__ glXSwapBuffers(...)` (`tcl_dispatch.c:3602`) into the seam suggests a Linux backend exists.
**Why it happens:** `__linux__` is `#undef`'d (`RunTime_Defines_ZARF_9.h:10`), so it never compiled.
**How to avoid:** Drop the dead branch during extraction; the seam's `gfx_swap` is the single present path.

## Code Examples

### Verify the gate from R (GATE-01)
```r
# command-line R only (NOT R.app)
library(tcltk)
tclvalue(.Tcl("tk windowingsystem"))     # MUST be "aqua"  [CITED: R-admin §C.3.8]
# then prove the native load path:
dyn <- tclvalue(.Tcl("info sharedlibextension"))   # ".dylib" on macOS
tcl("load", "/path/to/gateext.dylib", "Gateext")
tclvalue(.Tcl("gate_winsys"))            # MUST be "aqua"
```

### Inspect the linked Tk flavor (diagnosis)
```bash
otool -L "$(R RHOME)/library/tcltk/libs/tcltk.so" | grep -Ei 'libtk|libX11'
# X11 build shows libX11.*.dylib; an Aqua-linked tcltk.so shows no libX11
```

### onDisplay present, after extraction (RND-01)
```c
/* tcl_dispatch.c onDisplay(): replace the #ifdef _WIN32 SwapBuffers(dc) block */
glPopMatrix();
glFlush();
gfx_swap(g_surface);          /* was: #ifdef _WIN32 SwapBuffers(dc); #elif __linux__ ... */
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Assume runtime Tk-flavor switch via env vars | Flavor is linked at R build time; verify with `[tk windowingsystem]` | Longstanding | Reframes D-01 bundling as a linkage problem, not a file-placement problem. |
| XQuartz X11 Tk for macOS GUI | Aqua (Cocoa) Tk | XQuartz GL/GLX broken on recent macOS | Native path *requires* Aqua Tk (project premise). `[CITED: STACK.md/PITFALLS.md]` |
| Scattered `#ifdef _WIN32` in window code | Single 5-function `gfx_backend.h` seam | This phase | Confines platform code to backend TUs; enables Phase 4 NSGL. |

**Deprecated/outdated:**
- System `/usr/bin/tclsh`/`wish` (Tk 8.5, ~2010) `[VERIFIED: local probe]` — too old; install 8.6.x for the gate. `[CITED: tkdocs install]`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Recompiling only the base `tcltk` package against Aqua Tk (Option B) yields `aqua` without a full R rebuild | Deployment Gate Options | Medium — if false, fallback shifts to Option C/D (custom R); higher researcher burden. Spike step 2 tests this. |
| A2 | A package-local bundled Aqua framework + relinked/overlaid `tcltk` can achieve `aqua` on a clean CRAN R (D-01 ideal) | Bundling Spike | High — if false, D-01 is infeasible and D-02 fallback (Homebrew Aqua) becomes GATE-02. This is the phase's core open question. |
| A3 | `gfx_resize` is effectively a no-op on WGL (viewport/ortho stay generic in core) | Rendering Seam | Low — worst case the seam needs a WGL resize hook; cheap to add. |
| A4 | Removing the dead `__linux__` swap branch has no effect (never compiled) | Pitfall 6 | Low — `__linux__` is `#undef`'d; verified. |
| A5 | The engine is fixed-function (affects later phases, not the seam mechanics) | — | Low for Phase 1 — `[VERIFIED: 19 fixed-function GL calls in ogl_ZARF9.c]` supports it; only matters for Phase 4 profile choice. |

**If empty:** not empty — A2 in particular gates the D-01 decision and must be resolved by the spike before D-01 is locked.

## Open Questions (RESOLVED)

1. **Can the Aqua Tk binding be made package-local (D-01) or must the researcher reconfigure R (D-02)?**
   - What we know: flavor is linked into `tcltk.so` at R build time; Aqua Tk is easy to obtain (Homebrew/upstream).
   - What's unclear: whether a bundled framework + overlaid/relinked `tcltk` works on a clean machine, survives universal2 + quarantine.
   - Recommendation: resolve empirically in the bundling spike (steps 2→4) before locking D-01.
   - **(RESOLVED)** — resolved by Plan 03 Task 1's D-01-vs-D-02 decision gate, grounded in Plan 02 Task 1 spike step 4 (the package-local feasibility finding: bundled-framework + relinked/overlaid `tcltk`, measured against clean-machine/quarantine/universal2). Plan 02 records the finding; Plan 03 makes the decision.
2. **Which PLY fixture is the CMP-01 regression mesh?**
   - What we know: `BUILD.md` references "bundled test data or local `C13.1.ply`."
   - What's unclear: **no `.ply` file is committed anywhere in the repo** `[VERIFIED: find -iname '*.ply' → none]`. Claude's-discretion "pick an existing sample" has nothing to pick.
   - Recommendation: the plan must source/commit a small PLY fixture (or the maintainer supplies one on the Windows machine); do not assume one exists.
   - **(RESOLVED)** — resolved by Plan 04 Task 1: source/commit a fresh small PLY fixture (0 committed today), rather than assuming an existing sample.
3. **Should the WGL context leak be fixed?**
   - What we know: `setWindowId` leaks `HGLRC`/`HDC` on repeated `setWindow "id"`.
   - What's unclear: whether it causes observable issues (probably not for single-session use).
   - Recommendation: out of scope for D-05's pure refactor; track as a follow-up once `gfx_destroy` exists.
   - **(RESOLVED)** — out of scope per D-05 (pure mechanical refactor, change no behavior); tracked as a follow-up once `gfx_destroy` exists.

## Environment Availability

| Dependency | Required By | Available (this machine) | Version | Fallback |
|------------|-------------|--------------------------|---------|----------|
| Xcode Command Line Tools (clang, otool, install_name_tool, lipo) | Build trivial ext; inspect linkage | ✓ | CLT @ `/Library/Developer/CommandLineTools` | — |
| Homebrew | Install Aqua tcl-tk / cmake / R | ✓ | `/opt/homebrew` (Apple Silicon) | — |
| R / Rscript (command-line) | GATE-01 gate proof | ✗ | — | `brew install --cask r` or CRAN pkg |
| CMake | Build engine; add seam file | ✗ | — | `brew install cmake` |
| Homebrew `tcl-tk` (Aqua 8.6+) | GATE spike + fallback | ✗ (not installed) | — | `brew install tcl-tk` |
| `/Library/Frameworks/{Tcl,Tk}.framework` (Aqua) | D-01 bundling target | ✗ | — | build/obtain Aqua framework |
| System `tclsh`/`wish` | quick smoke | ✓ but **Tk 8.5 (too old)** | 8.5 | install 8.6.x |
| **MSVC + Windows R** | **CMP-01 Windows regression** | ✗ (this is macOS) | — | **No fallback on this machine — requires a Windows environment / maintainer** |

**Missing dependencies with no fallback:**
- **Windows toolchain for CMP-01.** The MSVC build + PLY render regression **cannot run on this macOS dev machine**. The plan must delegate CMP-01 to a Windows machine or the maintainer, and treat "Windows still works" as a manual, off-box checkpoint.
- **No committed PLY fixture** for the regression mesh (see Open Question 2).

**Missing dependencies with fallback:**
- R, CMake, Aqua `tcl-tk` — all installable via Homebrew/CRAN during the spike (a spike setup step, not a blocker).

## Validation Architecture

> `workflow.nyquist_validation` is `true` (config.json) — section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | **None exists.** `[VERIFIED: CONCERNS.md]` no `testthat`/`tests/`; C engine has only compiled-out `STAND_ALONE_TOOL` `ut_*` helpers. |
| Config file | none — see Wave 0 |
| Quick run command | (none) — Phase-1 checks are the gate assert + manual DLL render |
| Full suite command | (none) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GATE-01 | `tk windowingsystem == aqua` + `load` trivial ext | smoke (scriptable) | `Rscript -e 'library(tcltk); stopifnot(tclvalue(.Tcl("tk windowingsystem"))=="aqua")'` then `load` the ext and assert `gate_winsys=="aqua"` | ❌ Wave 0 (write the assert script + commit the ext) |
| GATE-02 | Reproducible setup doc | manual | (doc review — a researcher follows it on a clean machine) | ❌ Wave 0 (doc) |
| RND-01 | Seam isolates WGL; core has no `HDC`/`HGLRC`/`SwapBuffers` | static check | `grep -REn 'HDC|HGLRC|SwapBuffers|wgl' src/ | grep -v gfx_backend_wgl.c` → empty | ❌ Wave 0 (grep gate) |
| RND-01 | Compiles unchanged | build | MSVC/CMake build succeeds | n/a (build) |
| CMP-01 | PLY renders identically | manual (D-06) | build MSVC DLL → deploy → `GUImorph()` → load PLY → eyeball | ❌ off-box (Windows) |

### Sampling Rate
- **Per task commit:** the RND-01 grep gate (fast, catches incomplete extraction).
- **Per wave merge:** trivial-extension load assert (GATE-01), once Aqua Tk is set up.
- **Phase gate:** manual Windows MSVC render (CMP-01) + gate returns `aqua`.

### Wave 0 Gaps
- [ ] Trivial Aqua-Tk C extension source + build recipe (`gate_ext.c`, D-03) — covers GATE-01
- [ ] Scriptable gate assertion (`Rscript`/Tcl) — automates GATE-01
- [ ] Static grep gate for seam completeness — automates RND-01 boundary
- [ ] A committed small PLY fixture for CMP-01 (none exists today)
- [ ] GATE-02 setup document (README section or standalone)

*No general test framework is introduced this phase; the trivial extension is the one durable automated artifact (D-03 intent).*

## Security Domain

> `security_enforcement: true`, `security_asvs_level: 1` (config.json). Threat model is LOW (local research desktop tool). This phase adds a trivial extension and moves existing C code.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A (local desktop) |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A |
| V5 Input Validation | limited | The trivial extension must **not** parse untrusted input (keep it to `tk windowingsystem`); do not extend the unsafe PLY parser. |
| V6 Cryptography | no | N/A (signing/notarization is Phase 4 BLD-03, not here) |
| V10/V14 Code integrity & build | yes | Rebuild+redeploy the committed DLL from source (avoid binary/source drift `[VERIFIED: CONCERNS.md]`); on macOS at minimum ad-hoc sign artifacts (deferred to Phase 4). |

### Known Threat Patterns for this phase
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Pre-existing unsafe PLY parser (`strcpy`/`sscanf`/`sprintf`, overflow) `[VERIFIED: CONCERNS.md]` | Tampering / DoS | **Out of scope** — explicitly deferred (STATE.md); the seam refactor must not touch it. Do not regress it either. |
| Committed prebuilt DLL trust anchor | Tampering | Rebuild from source for CMP-01; keep the shipped DLL matched to source. |
| Loading an unsigned dylib on macOS (gate ext) | Elevation/Trust | For the spike, ad-hoc sign or use the documented `xattr` workaround; full sign/notarize is Phase 4. |

## Sources

### Primary (HIGH confidence)
- R Installation & Administration Manual §C.3.8 (Tcl/Tk headers and libraries), §C.1 — `--with-tcl-config`/`--with-tk-config`, Aqua vs X11, R.APP incompatibility, `[tk windowingsystem]` check.
- R source `src/library/tcltk/R/unix/zzz.R` — R uses `otool -L tcltk.so` to detect X11/`libtk` linkage at load (proves flavor is baked at build time).
- CRAN `bin/macosx` + RMacOSX-FAQ §6 — CRAN R ships **Tcl/Tk 8.6.12 X11**, requires XQuartz.
- tcltk/tk `macosx/README` — Aqua vs X11 builds, `--enable-aqua --enable-framework`, `[tk windowingsystem]`.
- Homebrew `Formula/t/tcl-tk.rb` — Tk built `--enable-aqua=yes --without-x` (fallback is genuine Aqua).
- GUImorph codebase (VERIFIED): `tcl_window.c` (WGL create/make-current), `tcl_dispatch.c:3534-3606` (`onDisplay`+`SwapBuffers`), `def_ZARF_9.h` (`extern HDC dc`, `#include <windows.h>`), `RunTime_Defines_ZARF_9.h` (`CODE_FOR_LIBRARY` hard-def, `__linux__` undef), `CMakeLists.txt`, `BUILD.md`, `.planning/codebase/{ARCHITECTURE,CONCERNS}.md`.
- Local environment probe (VERIFIED): clang/otool/install_name_tool/lipo present; R/cmake/Homebrew-tcl-tk absent; system wish is Tk 8.5; no `.ply` committed.

### Secondary (MEDIUM confidence)
- R-devel 2003 thread + AquaReadMe — the `--with-tcl-config=.../Tcl.framework/... TCLTK_LIBS='-framework Tcl -framework Tk'` recipe (Option C).
- tcl-lang wiki (New Tcl/TkAqua FAQ, Stand-Alone apps, TclTkAquaBI), tkdocs install — Aqua distros, `install_name_tool` relink patterns, "install 8.6.x not system 8.5."
- Project research `.planning/research/{STACK,PITFALLS,SUMMARY}.md` — milestone-level HIGH-confidence context reused here.

### Tertiary (LOW confidence)
- Feasibility of package-local Aqua binding (D-01 / A2) — must be validated empirically in the spike.

## Metadata

**Confidence breakdown:**
- Rendering seam (RND-01): HIGH — exact call sites verified in source; mechanical, low-risk.
- Gate mechanism (why bundling is hard): HIGH — R manuals + R source agree flavor is build-time-linked.
- Bundling feasibility (D-01): MEDIUM/LOW — the package-local Aqua binding is unproven; the spike must confirm.
- CMP-01 procedure: HIGH on method (D-06), but blocked off-box (no Windows here) and no fixture committed.

**Research date:** 2026-07-12
**Valid until:** ~2026-08-11 (30 days; R/Tcl/Tk macOS behavior is stable). Re-check if the R major version or macOS release changes the CRAN Tcl/Tk component.
