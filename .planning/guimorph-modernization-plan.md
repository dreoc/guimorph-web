# GUImorph Modernization Plan

**Source:** Initial architecture review from agent transcript `e7bdb991-33c4-49a2-ac4b-a1bccd548453` (2026-06-12)  
**Scope:** `integrated-guimorph-development_EOC/` — ~8 years untouched, written as student-era research code

> **Naming:** This document uses **Plan 0–3** for the original four-stage modernization outline. **GSD Phases 1–9** (execution roadmap) live in `.planning/ROADMAP.md` — different numbering, finer granularity.

---

## Original review questions

1. Analyze the structure of the repository and give a run down of the architecture and how it works. Tell me what the tool is intending to do.
2. Identify critical code flaws that need to be addressed.
3. Propose a modernization plan to get it working. The code was broken. Be critical of the code quality.

---

## 1. What the tool is and how it's built

**GUImorph** is an R package that provides a graphical interface for **3D geometric morphometrics** — the workflow where a researcher loads a 3D scan of a specimen (a bone, fossil, skull, etc., as a PLY mesh), places **landmarks** (named anatomical points), **curves** (semi-landmark splines), and **anchors** on it, then feeds those digitized coordinates into statistical shape-analysis packages (`geomorph`, `Morpho`, `Rvcg`, `vegan`).

The `DESCRIPTION` sums it up:

> *"GUI to R programs to digitize in 3D, conduct geometric morphometric analyses and plotting results based on OpenGL and Tk."*

It was written by Erik Otarola-Castillo's group at Purdue; the code under review is the student-era contribution to the C/OpenGL rendering engine.

### Architecture — three stacked layers

The system is a polyglot sandwich. From top to bottom:

#### Layer 1 — R (the application)

Under `Project/GUImorphDevelopment/` and `Project/tkogl2/R/`, ~250 KB of R across seven files:

- `3dDigitize.main.r`
- `.digitize.r`
- `.curve.r`
- `.surface.r`
- `.geomorph.r`
- `geomorph.support.code.r`
- `rtkogl.R`

This builds the Tk window/menus, holds the master data structure (`dgtDataList`, indexed per specimen), reads/writes `.dgt` files, and calls into the statistics packages. The GUI uses an S3-dispatch pattern (`ui`, `init`, `bind`, `updateWidgets` on a `"main"`-classed environment `e`).

#### Layer 2 — Tcl/Tk (the glue)

R's `tcltk`/`tcltk2` talk to a Tk widget. The R functions `add()`, `set()`, `del()`, `shows()` in `rtkogl.R` marshal everything into `tcl("add", shape, arg1, arg2, arg3)` calls — a **stringly-typed command protocol** where `shape` (`"specimen"`, `"dot"`, `"curve"`, `"anchor"`, `"landmark"`, …) selects behavior.

#### Layer 3 — C/OpenGL (the engine)

`Project/tkogl2/src/` is the `tkogl2` Tcl extension DLL — ~300 KB of C across 11 files.

`Tkogl2_Init` (in `tcl_if_ZARF_9.c:4146`) registers the Tcl commands `add`, `show`, `setWindow`, `setSpecimen`, `setDot`, `del`, `loadDgt` that mirror the R-side names one-for-one.

The interesting trick is in `setWindowId` (`tcl_if_ZARF_9.c:582`): it takes the Tk widget's Win32 `HWND`, calls `GetDC` / `ChoosePixelFormat` / `wglCreateContext` / `wglMakeCurrent`, and renders OpenGL directly into the Tk frame. Rendering is **fixed-function OpenGL** (`gluLookAt`, `glLightfv`, GLUT) — the pre-2008 immediate-mode pipeline.

**File split:**

| File(s) | Role |
|---------|------|
| `tcl_if_*` | Command dispatch + window/state (5,581 lines) |
| `ogl_*` | GL setup |
| `ogl_model_*`, `ogl_model_ply_*` | PLY mesh loading + draw |
| `dot_*` | Landmark/anchor lists |
| `curve_*` | Curve splines |
| `StatisticsFunction_*` | Statistics hooks |

#### Standalone harness

`Standalone/tkogl2_SA/main_Test_ZARF_5.c` bundles the full Tcl + Tk C sources and "stuffs" fake `Tcl_Obj` structures to drive the engine without R — a desktop test rig for developers.

Two build modes are selected by `#ifdef STAND_ALONE_TOOL` vs `#ifdef CODE_FOR_LIBRARY` (see `RunTime_Defines_ZARF_9.h`).

---

## 2. Critical flaws

### A. The build is broken at the most basic level — the project file points at filenames that don't exist

The Visual Studio project lists the original names, but every source file on disk was later renamed with a `_ZARF_9` suffix and never re-added:

```xml
<!-- tkogl2.vcxproj -->
<ClCompile Include="src\curve.c" />
<ClCompile Include="src\dot.c" />
<ClCompile Include="src\ogl.c" />
<ClCompile Include="src\ogl_model.c" />
<ClCompile Include="src\ogl_model_ply.c" />
<ClCompile Include="src\tcl_if.c" />
```

On disk these are `curve_ZARF_9.c`, `dot_ZARF_9.c`, `ogl_ZARF9.c`, `ogl_model_ZARF_9.c`, `ogl_model_ply_ZARF_9.c`, `tcl_if_ZARF_9.c`. MSBuild can't find any of them, so the DLL never builds. This is almost certainly *the* reason "it's broken." (The header references — `def.h`, `main.h`, `RunTime_Defines.h` — are similarly stale.)

### B. Hardcoded absolute paths to a machine that no longer exists

The Release configs hardcode `C:\Users\amlut\Documents\RESEARCH\GUIMORPH\...` for includes and libs, and the Debug `OutDir` points at `C:\Users\amlut\Desktop\Integrated_GUImorph_Development\...`. None of this is relative or portable.

### C. The Release x64 config builds the wrong artifact

It's set to `<ConfigurationType>Application</ConfigurationType>` instead of `DynamicLibrary`. An R/Tcl loadable extension must be a DLL; this config would produce an `.exe` that R can't load.

### D. Platform lock-in to Windows + a Tk internal

The renderer hijacks the Tk widget's `HWND` and creates a WGL context against it. This is Windows-only and depends on grabbing a window handle out of Tk — there's no Linux/macOS path despite the `RunTime_Defines` flirting with `__linux__`. It will never run on a Mac or modern Linux without a rewrite of the windowing layer.

### E. Obsolete graphics and toolchain

Fixed-function OpenGL + GLUT was deprecated ~2008/2009 and is increasingly unsupported by modern drivers (especially under remote desktop, VMs, and macOS, which capped at GL 2.1/4.1). The Tcl/Tk stubs are 8.6-era (`tclstub86`, `tkstub86`); Tcl/Tk 9.0 is now the current line and is not ABI-compatible.

### F. Stale R dependencies

The package pins an 8-year-old ecosystem (`geomorph`, `Morpho`, `Rvcg`, `vegan`, `tcltk2`, `roxygen2 7.1.1`). `geomorph` in particular has had multiple breaking API changes since 2020 (e.g. `gpagen`, plotting, data-frame interfaces). The analysis layer will throw errors against current CRAN versions even if the GUI loads.

### G. Repository hygiene

Committed into the repo:

- A **140 MB** `Report20200218-1041.diagsession`
- The entire `.vs/` cache (~160 MB of `Browse.VC.db`/`.ipch`)
- Prebuilt `.dll`/`.pdb`/`.lib` binaries (the x64 `.pdb` alone is 6.7 MB)
- `.RData`/`.Rhistory`
- Unrelated `.Rproj.user` lecture-notes notebooks

The `.gitignore` was one line. This bloats clones and obscures the actual source.

### H. Fragile by design at the C/Tcl boundary

In standalone mode the code reaches directly into Tcl internals (`objPtr->internalRep.longValue`, `objPtr->bytes`) instead of using the public API — that breaks across Tcl versions. The whole R↔C contract is an untyped string protocol with no schema; a typo in a `shape` string fails silently at runtime.

---

## 3. Code-quality assessment

It reads like capable-but-undisciplined student code that grew under deadline pressure, and the comments admit it.

### God file

`tcl_if_ZARF_9.c` is 5,581 lines / 166 KB in one translation unit — dispatch, state, window management, drawing, and logging all mixed together.

### Copy-paste duplication, acknowledged in the source

"Dot" and "anchor" are the same concept implemented twice across dozens of near-identical functions. The header literally says so:

```c
// THERE ARE TOO MANY FUNCTIONS ! LOTS OF REPLICATION !
// def_ZARF_9.h:169
```

### Global state everywhere

`GBL_PTR_MODEL_1..5`, `GBL_PTR_CONTEXT_1..5`, `GBL_PTR_CURVE_1..6` are hand-numbered globals instead of arrays; fixed `[25][3]` buffers cap specimens silently; and the magic constants don't even match their use — `CONST_10` is `10` but labels a 25-row curve set (`GBL_CURVE_SET[25][3]`).

### Debugging left in the codebase

Pervasive `printf`/`print()` tracing, `if(0){...}` / `if(1){...}` toggles to switch debug output on and off, and a `MAKE_INERT` preprocessor flag whose stated purpose is "to make broken code inert" rather than fixing or removing it.

### Unsafe macros

`ANGLE_REDUCE` expands to multiple unbraced statements; `FREE`/`D`/`D1` macros that should be inline functions.

### Mirrored stringly-typed dispatch

The giant `if (shape == "...")` chain in `rtkogl.R` is duplicated again in C — two parallel switch ladders that must be kept in lockstep by hand.

### No tests, no CI, no build script

Beyond the broken `.vcxproj`; the only "test" is the manual standalone harness.

None of this is unusual for a research tool written solo as a student — but it's the kind of thing that makes the code hard to revive 8 years later.

---

## 4. Proposed modernization plan

Stage the work so you get something *running* before investing in deeper rewrites. Roughly four plans:

---

### Plan 0 — Triage & repo cleanup

**Effort:** Low  
**Leverage:** High

**Goals:**

- Write a real `.gitignore` (`.vs/`, `*.diagsession`, `*.pdb`, `*.RData`, `*.Rhistory`, `x64/`, `Debug/`, `.Rproj.user/`)
- Purge the 140 MB diagsession and committed binaries from history (`git-filter-repo` if needed)
- Decide whether the prebuilt DLLs should be release artifacts rather than tracked source
- Confirm what actually compiled last — the `inst/libs/x64/tkogl2.dll` is dated 2020 and may still load; worth testing first to establish a known-good baseline

**Why first:** Cleans the repo so every later plan works against real source, not stale artifacts and IDE caches.

---

### Plan 1 — Get the existing DLL building again

**Effort:** Medium  
**Goal:** Smallest path to "working"

**Original plan (Visual Studio path):**

- Fix the `.vcxproj`: update file names to the `_ZARF_9` versions
- Make all include/lib paths relative (`$(ProjectDir)`)
- Set Release|x64 back to `DynamicLibrary`
- Fix the `OutDir`s
- Build against current Tcl/Tk 8.6 stubs
- Confirm the R package loads the freshly built DLL

**Important constraint:** This plan changes **no logic** — it just restores a compile. This is where to start, and it may be most of what "get it working" requires.

**Note:** In follow-on work, Plan 1 was adapted for Cursor (no Visual Studio IDE): MinGW-w64 cross-compile from WSL + CMake. See `integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md`.

**Validation (2026-06-13):** ✅ Complete — compile-only goal met.

| Criterion (original VS plan) | CMake/MinGW equivalent | Status |
|------------------------------|------------------------|--------|
| Fix `.vcxproj` `_ZARF_9` filenames | All 7 `*_ZARF_9.c` + `tcl_stub_bootstrap.c` in `CMakeLists.txt` | ✅ |
| Relative include/lib paths | `${CMAKE_CURRENT_SOURCE_DIR}` / `${SRC}` | ✅ |
| Release\|x64 → `DynamicLibrary` | `add_library(tkogl2 SHARED …)` → `tkogl2.dll` | ✅ |
| Tcl 8.6 stubs | `src/tcl_stub_bootstrap.c` (MinGW can't read MSVC `.lib`) | ✅ |
| Confirm R package loads DLL | **Not in compile plan** — pending Windows R `tcl("load", …)` smoke test | ⏳ |

Fresh build output: `build/tkogl2.dll` — 883,519 bytes, PE32+ x86-64, export `[0] Tkogl2_Init`. Runtime deps: `OPENGL32`, `GLU32`, `GDI32`, `USER32`, `glut64.dll`.

---

### Plan 2 — De-risk the dependencies (R side)

**Effort:** Medium–High  
**Goal:** Reproducible, testable R environment

**Steps:**

1. Stand up a reproducible environment with `renv` pinned to versions near 2020
2. Verify the GUI launches and a digitize → analyze round-trip works
3. Migrate the `geomorph`/`Morpho` calls forward to current CRAN APIs one function at a time
4. Decide the support target for Tcl/Tk:
   - Stay on 8.6 (lower risk), or
   - Move to 9.0 (bigger lift, ABI break)

**Why after Plan 1:** No point migrating R APIs until the native DLL loads and the GUI actually opens.

**Suggested verification:**

- Load a PLY specimen
- Place landmarks/curves
- Export `.dgt` data
- Run at least one `geomorph` analysis call end-to-end

---

### Plan 3 — Strategic modernization (the real decision)

**Effort:** High (depends on chosen path)  
**Goal:** Long-term maintainability and portability

The honest question is whether to *rehabilitate* the C engine or *replace* it. The fixed-function-OpenGL-into-an-HWND approach is a dead end for portability — it can't move off Windows, and modern drivers are dropping immediate mode.

**Three realistic options, in rough order of cost:**

#### Option A — Rehabilitate in place

- Keep the C engine
- Modularize `tcl_if` (split file, collapse dot/anchor duplication, replace numbered globals with arrays)
- Accept permanent Windows-only + legacy-GL status

**Tradeoff:** Cheapest, but you're maintaining 2008-era tech.

#### Option B — Swap the renderer (recommended effort-to-value)

- Keep the R/Tk app
- Replace the custom C OpenGL extension with an existing R 3D viewer (`rgl`, which `geomorph`/`Morpho` already use, or `Rvcg` mesh tooling)
- Could delete most of the C code entirely and gain cross-platform support

**Tradeoff:** Likely the best effort-to-value trade.

#### Option C — Rebuild the front end

- If the goal is longevity, a `shiny` + WebGL (e.g. `three.js` / `rgl`-in-browser) app would be portable and maintainable
- From-scratch UI rewrite

**Tradeoff:** Most work, but most future-proof UI.

**Decision point:** Input is needed before committing to Plan 3 since it's the expensive fork in the road.

---

## 5. Open items to sharpen the plan

These were identified but not yet verified at the time of the original review:

1. **Try loading the existing 2020 DLL** with current R to see if anything runs at all (establishes the real starting point)
2. **Read the GUI files end-to-end** (`3dDigitize.digitize.r`, `.curve.r`, `.surface.r`) to map the full feature set and find where `geomorph` is actually called
3. **Inventory exactly which `geomorph`/`Morpho` functions are used** so the API-migration work in Plan 2 can be quantified

---

## Plan summary

| Plan | Name | Primary deliverable |
|------|------|---------------------|
| **0** | Triage & repo cleanup | Clean git repo, real `.gitignore`, baseline DLL test |
| **1** | Restore the build | Compiling `tkogl2.dll` that R can load |
| **2** | De-risk R dependencies | `renv`, GUI launch, digitize→analyze round-trip, API migration |
| **3** | Strategic modernization | Rehabilitate C / swap renderer / rebuild UI (choose one) |

---

## Related documents

- `.planning/modernization-session-handoff.md` — session state and progress after Plan 0/1 work
- `.planning/r-guimorph-setup-findings.md` — Windows R install and first load attempt
- `integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md` — Plan 1 MinGW/CMake build instructions
