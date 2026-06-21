# Phase 7: C Engine Modularization - Research

**Researched:** 2026-06-19
**Domain:** C99 Tcl extension modularization (MinGW DLL, WGL/OpenGL)
**Confidence:** HIGH

## Summary

Phase 7 splits the 5,581-line `tcl_if_ZARF_9.c` god file into five focused translation units while preserving the stable R↔Tcl↔C boundary (`Tkogl2_Init`, eight Tcl commands, unchanged symbol names). The codebase already has a proven CMake/MinGW build and partially modular layout (`dot_ZARF_9.c`, `curve_ZARF_9.c`, `ogl_*.c`); the god file is the sole outlier.

Extraction follows the locked three-plan sequence: **07-01 dispatch** (largest block — `add` ~1,662 lines, `show` ~266 lines, draw pass + `onDisplay`), **07-02 window/WGL** (`setWindowId`, `setWindow` handler, `dc`/dimensions), **07-03 state + log + init rename** (globals cluster, `initialize_state`/`resetContext`, all `simpleLog_*`, thin `tcl_init.c`, remove god file from CMake). Cross-module linkage must mirror the existing pattern in `ogl_model_ply_ZARF_9.c` — `extern` declarations for globals already consumed outside the god file — without aggressive `static`-ification (D-15).

Primary verification is **manual Windows R GUI UAT** per plan (build → export check → PLY load → double-click landmark; final full digitize round-trip). No new external packages; risk concentrates on duplicate/missing symbols at link time and subtle `#ifdef CODE_FOR_LIBRARY` / shared-buffer coupling.

**Primary recommendation:** Move code in the locked ROADMAP order using explicit CMake source additions per plan, one defining `.c` per global group with matching module headers, and per-plan smoke UAT before proceeding — treat link errors and missing `Tkogl2_Init` export as hard gates.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Module Boundaries
- **D-01:** **Draw functions → `tcl_dispatch.c`** — `drawDots`, `drawAnchors`, `drawCurves`, `drawGrid` live with Tcl command handlers that invoke them (`show`, `add`, etc.).
- **D-02:** **Logging → `tcl_log.c`** — `simpleLog_Open`, `simpleLogWriteLandmarksToFile`, `simpleLogWriteAnchorsToFile`, and related logging in a dedicated file separate from state.
- **D-03:** **State/globals → `tcl_state.c`** — `initialize_state`, `resetContext`, `clear_deltas`, `GBL_PTR_MODEL_*`, `GBL_PTR_CONTEXT_*`, `GBL_PTR_CURVE_*`, landmark/curve set globals, and specimen counters together.
- **D-04:** **Entry point → `tcl_init.c`** — rename god file; retain only `Tkogl2_Init` and `Tcl_CreateObjCommand` registration. All other code moves out.

#### Target File Layout (Phase 7 end state)
| File | Responsibility |
|------|----------------|
| `tcl_init.c` | `Tkogl2_Init`, Tcl command registration |
| `tcl_dispatch.c` | Tcl handlers (`add`, `show`, `set`, `setWindow`, `setSpecimen`, `setDot`, `del`, `loadDgt`, etc.) + draw pass functions |
| `tcl_window.c` | `setWindowId`, HWND/WGL setup, window dimensions |
| `tcl_state.c` | Specimen/model state, globals, init/reset |
| `tcl_log.c` | Debug logging helpers |

Existing modules (`dot_ZARF_9.c`, `curve_ZARF_9.c`, `ogl_*.c`) unchanged except `#include`/header updates if needed for linking.

#### Regression Verification
- **D-05:** **Per-plan smoke (07-01, 07-02, 07-03)** — after each extraction: `cmake --build`, verify `Tkogl2_Init` export, launch `GUImorph()`, load PLY (`C13.1.ply`), place at least one landmark (double-click).
- **D-06:** **Final smoke (07-03 completion)** — full digitize round-trip: landmarks + curve + save `.dgt` + same-session reload via `openDgt` (Phase 4 workflow on `test_fresh.dgt` or equivalent fresh session).
- **D-07:** **Document UAT in both** — append pass/fail to `.planning/smoke-test-findings.md` and record technical notes in each plan SUMMARY.
- **D-08:** **Keep pre-Phase-7 DLL backup** — preserve current working `inst/libs/x64/tkogl2.dll` (or tagged build artifact) before first extraction for side-by-side comparison if regression suspected.

#### Extraction Order & Build
- **D-09:** **ROADMAP sequence** — 07-01 dispatch → 07-02 window → 07-03 state + log + init rename.
- **D-10:** **`tcl_log.c` + `tcl_init.c` rename in 07-03** — bundled with state extraction and final smoke test.
- **D-11:** **Incremental CMake** — add each new source file to `CMakeLists.txt` in the plan that introduces it.
- **D-12:** **Scope boundary** — modify god file and new headers only; no logic changes in `dot_ZARF_9.c`, `curve_ZARF_9.c`, or `ogl_*.c` (include/header updates allowed).

#### Naming & Headers
- **D-13:** **Clean file names** — `tcl_dispatch.c`, `tcl_window.c`, `tcl_state.c`, `tcl_log.c`, `tcl_init.c` (no `_ZARF_9` suffix on new modules).
- **D-14:** **Per-module headers** — `tcl_dispatch.h`, `tcl_window.h`, `tcl_state.h`, `tcl_log.h` for cross-module APIs; keep `def_ZARF_9.h` for shared types/structs.
- **D-15:** **Minimal linkage changes** — preserve current symbol visibility during Phase 7; do not aggressively `static`-ify helpers (tighten in Phase 9).
- **D-16:** **BUILD.md updates each plan** — document new C source layout incrementally as files are added.

#### Carried Forward (prior phases — do not re-decide)
- **Option A** locked — rehabilitate C in place; no rgl/Shiny rewrite.
- Dot/anchor dedup deferred to Phase 8; globals/debug cleanup deferred to Phase 9.
- `Tkogl2_Init` export name and Tcl command set must remain stable.
- R↔Tcl shape string protocol unchanged.
- Manual Windows R GUI UAT is primary verification (no automated Tk/OpenGL harness).
- Landmark placement requires double-click on canvas.
- Phase 6 must complete first — reproducible baseline (`renv`, BUILD.md, deploy workflow) before C refactor.

### Claude's Discretion
- Exact line ranges and move order within each extraction plan.
- Which symbols go in which module header vs remain in `def_ZARF_9.h`.
- Whether `directive` / wrapper helpers split with dispatch or stay until 07-03.
- Specific BUILD.md section structure for file-layout documentation.

### Deferred Ideas (OUT OF SCOPE)
- **Dot/anchor unification** — Phase 8 (`marker.c`); do not merge during Phase 7 even if convenient.
- **GBL_PTR_* array replacement** — Phase 9; keep numbered globals during modularization.
- **Debug removal (`MAKE_INERT`, `if(0)`, printf tracing)** — Phase 9; move with modules but do not delete/toggle.
- **Aggressive `static` linkage tightening** — Phase 9 or post-modularization cleanup.
- **Rename existing `_ZARF_9` modules** — out of scope; only new split files get clean names.
- **Automated C unit tests** — `unit_test_ogl_*` harness exists in god file but manual GUI UAT is primary.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CENG-01 | `tcl_if_ZARF_9.c` split into separate modules (dispatch, window/WGL, state) with no behavior change | Verified god-file line map (below); locked module boundaries D-01–D-04; incremental CMake pattern D-11; cross-TU `extern` precedent in `ogl_model_ply_ZARF_9.c`; per-plan + final manual UAT gates D-05–D-06 |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tcl command dispatch (`add`, `show`, `del`, …) | Native DLL / C extension | — | R calls Tcl; C handlers own shape-string routing and OpenGL redraw orchestration |
| HWND → WGL context setup | Native DLL / C extension | Tcl (`setWindow id`) | Windows-only WGL binding; R passes HWND via Tcl |
| Specimen/model runtime state | Native DLL / C extension | — | In-process globals (`models`, `context`, `GBL_PTR_*`); no R-side mirror |
| Debug file logging | Native DLL / C extension | — | C-side `simpleLog_*` writes local log files; R does not consume |
| DLL load & init | Native DLL export + R `.onLoad` | — | `rtkogl.R` loads `inst/libs/x64/tkogl2.dll`; only `Tkogl2_Init` is exported entry |
| Digitize persistence (`.dgt`) | R application layer | C `loadDgt` command | Save is R-side; C must keep `loadDgt` handler behavior stable |
| Build / deploy artifact | Developer toolchain (CMake/MinGW) | PowerShell deploy script | Produces and swaps `tkogl2.dll`; no runtime service |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| CMake | 3.16+ (project minimum) | Build orchestration | Already in `CMakeLists.txt`; proven Phase 1 path [VERIFIED: codebase] |
| MinGW-w64 (UCRT64 primary) | MSYS2 toolchain | Windows DLL compile | Documented in root `BUILD.md`; WSL cross-compile via `cmake/mingw-w64-x86_64.cmake` [VERIFIED: codebase] |
| Tcl 8.6 stubs | Vendored headers + `tcl_stub_bootstrap.c` | Extension ABI | `USE_TCL_STUBS` + bootstrap avoids unreadable MSVC `tclstub86_64.lib` [VERIFIED: codebase] |
| OpenGL 1.x fixed-function + WGL | System (`opengl32`, `glu32`) | 3D rendering | Option A locked; existing `ogl_*.c` modules [VERIFIED: codebase] |
| GLUT | Vendored `glut64.dll` | 3 GLUT calls | Linked from `lib/glut64.dll` [VERIFIED: codebase] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `def_ZARF_9.h` | In-tree | Shared types, struct defs, existing extern API | All new modules include; extend only for cross-module refs per D-14 |
| `RunTime_Defines_ZARF_9.h` | In-tree | `CODE_FOR_LIBRARY` vs `STAND_ALONE_TOOL` | Preserve `#ifdef` blocks when moving code |
| `objdump` / `dumpbin` | System | Export verification | After every build (`Tkogl2_Init`) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Incremental file extraction (locked) | Big-bang single commit | Violates D-09; harder to bisect regressions |
| New unit-test harness | Manual GUI UAT (locked) | No Tk/OpenGL test infra exists; UAT is project standard |
| `static` internal linkage | Preserve extern visibility (locked D-15) | Premature — Phase 9 owns linkage tightening |

**Installation:** N/A — no new packages. Add new `.c` files to existing `add_library(tkogl2 SHARED …)` in `CMakeLists.txt`.

**Version verification:** Toolchain versions pinned by Phase 6 `renv`/BUILD docs; CMake minimum `3.16` from project file [VERIFIED: codebase].

## Package Legitimacy Audit

> **N/A** — Phase 7 installs no external packages. Refactor uses in-tree C sources and existing CMake/MinGW stack only.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
R GUImorph()
    │
    ▼
rtkogl.R .onLoad ──► tcl("load", inst/libs/x64/tkogl2.dll, "Tkogl2")
    │
    ▼
tcl_init.c: Tkogl2_Init
    ├── Tcl_InitStubs + Tcl_PkgProvide("Tkogl2", "1.0")
    └── Tcl_CreateObjCommand × 8
            │
            ├─► tcl_dispatch.c handlers (add/show/setSpecimen/…)
            │       ├── read/write tcl_state.c globals
            │       ├── call dot_*/curve_*/ogl_* modules
            │       └── onDisplay() → drawDots/Anchors/Curves/Grid
            │
            ├─► tcl_window.c: setWindow → setWindowId → WGL context (dc)
            │
            └─► tcl_log.c: simpleLog_* (file tracing, optional)
```

### Recommended Project Structure

```
integrated-guimorph-development_EOC/Project/tkogl2/src/
├── tcl_init.c          # Tkogl2_Init + command registration (07-03)
├── tcl_dispatch.c      # Tcl handlers + draw pass + onDisplay (07-01)
├── tcl_dispatch.h
├── tcl_window.c        # setWindowId, setWindow handler (07-02)
├── tcl_window.h
├── tcl_state.c         # globals, initialize_state, resetContext (07-03)
├── tcl_state.h
├── tcl_log.c           # simpleLog_*, TclIf_LogCommands (07-03)
├── tcl_log.h
├── def_ZARF_9.h        # shared types (extend minimally)
├── dot_ZARF_9.c        # unchanged logic (D-12)
├── curve_ZARF_9.c      # unchanged logic
├── ogl_*.c             # unchanged logic
└── tcl_stub_bootstrap.c
```

### Verified God-File Region Map

Line ranges from `tcl_if_ZARF_9.c` [VERIFIED: codebase grep, 5581 lines total]:

| Region | Approx. Lines | Target Module | Notes |
|--------|---------------|---------------|-------|
| Version strings + `GBL_*` globals | 31–106 | `tcl_state.c` | Includes `pointerTO_GBL_LANDMARK_SET` / `CURVE_SET` consumed by `ogl_model_ply_ZARF_9.c` |
| Tcl_Obj wrappers | 114–206 | Discretion — dispatch or stay until 07-03 | `#ifdef STAND_ALONE_TOOL` branches inactive under `CODE_FOR_LIBRARY` |
| `TCL_RESULT_*` macros | 298–337 | `tcl_dispatch.c` | Require `interp`; only compiled under `CODE_FOR_LIBRARY` |
| Runtime globals (`models`, `context`, `dc`, …) | 355–385 | Split: `dc`/dims → window; rest → state | `dc` already `extern` in `def_ZARF_9.h:116` |
| `clear_deltas`, `initialize_state`, `resetContext` | 390–580 | `tcl_state.c` | |
| `setWindowId` | 582–610 | `tcl_window.c` | WGL setup calls `ogl_init()` |
| `getRealZ`, draw functions | 619–905 | `tcl_dispatch.c` | D-01 |
| Helpers (`validateDot`, `specimen_del`, …) | 902–1066 | `tcl_dispatch.c` | Used by handlers |
| `add` handler | 1068–2730 | `tcl_dispatch.c` | Largest block |
| `show` handler | 2731–2997 | `tcl_dispatch.c` | |
| `setWindow` handler | 2998–3154 | `tcl_window.c` | Calls `setWindowId`; manages width/height |
| `setSpecimen`, `setDownSample`, `setDot`, `del` | 3155–4106 | `tcl_dispatch.c` | |
| `loadDgt` handler | 4107–4138 | `tcl_dispatch.c` | |
| `Tkogl2_Init` | 4146–4172 | `tcl_init.c` | 8 commands registered; `set`/`directive` declared but **not** registered |
| `simpleLog_*`, `TclIf_LogCommands`, model debug writers | 4176–5173 | `tcl_log.c` | D-02 |
| `onDisplay` | 5063–5133 | `tcl_dispatch.c` | Calls draw_*; `SwapBuffers(dc)` |
| `addDot_NO_TCL`, `addAnchor_NO_TCL` | 5275–5496 | `tcl_dispatch.c` | Used by `loadDgt` path |
| `changeLandmarkDotColor`, `changeDotColorToSlider` | 5503–5579 | `tcl_dispatch.c` | |

### Pattern 1: Incremental CMake Source Addition

**What:** Add each new `.c` to the existing shared library target in the plan that introduces it; remove `tcl_if_ZARF_9.c` only in 07-03.

**When to use:** Every extraction plan (D-11).

**Example:**

```cmake
# integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt
add_library(tkogl2 SHARED
    ${SRC}/tcl_init.c
    ${SRC}/tcl_dispatch.c
    ${SRC}/tcl_window.c
    ${SRC}/tcl_state.c
    ${SRC}/tcl_log.c
    ${SRC}/ogl_ZARF9.c
    # ... existing sources unchanged ...
    ${SRC}/tcl_stub_bootstrap.c
)
```

Source: [CITED: https://cmake.org/cmake/help/latest/command/add_library.html] — list sources in `add_library` or add via `target_sources()`; explicit listing preferred over `GLOB`.

### Pattern 2: Cross-Module Global Linkage (Preserve Visibility)

**What:** Define each global in exactly one `.c`; declare `extern` in module header or `def_ZARF_9.h`. Follow existing consumer pattern in `ogl_model_ply_ZARF_9.c`.

**When to use:** Any symbol referenced from multiple translation units (D-15).

**Example:**

```c
// tcl_state.c — definition
model_t* models = NULL;
int model_index = 0;

// tcl_state.h — declaration for other modules
extern model_t* models;
extern int model_index;

// ogl_model_ply_ZARF_9.c — existing consumer pattern (unchanged)
extern int model_index;
extern const float* pointerTO_GBL_LANDMARK_SET;
```

Source: [VERIFIED: codebase] — `ogl_model_ply_ZARF_9.c`, `curve_ZARF_9.c`, `ogl_model_ZARF_9.c` already use `extern` for god-file globals.

### Pattern 3: Tcl Extension Init (Stable Export Surface)

**What:** Keep `int DLLEXPORT Tkogl2_Init(Tcl_Interp* interp)` as the sole R-visible entry; register commands with `Tcl_CreateObjCommand`.

**When to use:** `tcl_init.c` only (D-04).

**Example:**

```c
int DLLEXPORT Tkogl2_Init(Tcl_Interp* interp)
{
    if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) return TCL_ERROR;
    if (Tcl_PkgProvide(interp, "Tkogl2", "1.0") == TCL_ERROR) return TCL_ERROR;
    Tcl_CreateObjCommand(interp, "add", add, 0, 0);
    /* ... 7 more commands — names unchanged ... */
    return TCL_OK;
}
```

Source: [CITED: https://www.tcl-lang.org/doc/howto/winext.tml] — `DLLEXPORT` required for Windows DLL symbol export; [VERIFIED: codebase] — `tcl_if_ZARF_9.c:4146–4168`.

### Anti-Patterns to Avoid

- **Duplicate global definitions:** Defining `models` or `GBL_PTR_MODEL_1` in two `.c` files → link failure or ODR violation. One definition per symbol.
- **Removing god file before 07-03:** Plans 07-01/07-02 compile new modules **alongside** remaining god-file code; delete `tcl_if_ZARF_9.c` from CMake only when all symbols moved.
- **Logic cleanup during move:** Do not delete `printf`, `if(0)`, or `MAKE_INERT` blocks — Phase 9 scope (deferred).
- **Renaming Tcl commands or export:** Breaks `rtkogl.R` `.onLoad` and all R `tcl("add", …)` call sites.
- **Static-ifying shared helpers:** Violates D-15; causes duplicate symbol or broken cross-module calls.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tcl stub linking on MinGW | Custom Tcl API shims | Existing `tcl_stub_bootstrap.c` + `USE_TCL_STUBS` | Already solves MSVC stub lib incompatibility |
| DLL export discovery | Custom loader | Tcl `load` + `DLLEXPORT Tkogl2_Init` | Tcl requires exact init symbol name |
| OpenGL/WGL setup | Reimplement context creation | Move existing `setWindowId` verbatim | WGL pixel-format code is easy to break subtly |
| Module boundary invention | Ad-hoc split by line count | Locked D-01–D-04 boundaries | User decisions already validated in discuss-phase |
| Automated regression | New C unit-test framework | Phase 4/5 manual UAT workflow | No headless Tk/OpenGL harness; project standard |

**Key insight:** Phase 7 is a **structural** refactor — reuse existing patterns (CMake target, stub bootstrap, extern globals) rather than introducing new abstractions.

## Runtime State Inventory

> Refactor phase — all categories explicitly answered.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | In-process C globals: `GBL_PTR_MODEL_1..5`, `GBL_PTR_CONTEXT_1..5`, `GBL_PTR_CURVE_1..6`, `GBL_LANDMARK_SET`, `GBL_CURVE_SET`, `models`, `context`, `deltas[1000][4]`, dot/anchor slice counters | **Code edit only** — move definitions to `tcl_state.c`; preserve names and initialization order; no migration (runtime state, not persisted) |
| **Live service config** | None — no external service stores tkogl2 module layout | None — verified: no n8n/DB/config UI dependencies |
| **OS-registered state** | None — DLL loaded dynamically by R/Tcl; no registry entries or Windows service registration for module names | None — verified |
| **Secrets/env vars** | None tied to C file names; R loads DLL via package path only | None — `rtkogl.R` path unchanged; no env var rename |
| **Build artifacts** | `integrated-guimorph-development_EOC/Project/tkogl2/build/tkogl2.dll`; deployed copy `GUImorphDevelopment/inst/libs/x64/tkogl2.dll`; optional `.bak` from deploy script | **Rebuild + redeploy** after each plan; **backup pre-Phase-7 DLL** per D-08; stale object files cleared by `cmake --build` |

### DLL Export Surface [VERIFIED: codebase]

| Symbol | Role | Phase 7 constraint |
|--------|------|-------------------|
| `Tkogl2_Init` | Sole exported init entry (`DLLEXPORT`) | Must remain exported with identical name |
| All other functions | Internal linkage (default) or implicit DLL exports on MinGW | Do not rename; preserve for cross-TU linking within DLL |

### Tcl Command Registration [VERIFIED: codebase `tcl_if_ZARF_9.c:4159–4168`]

Registered commands (must remain stable): `add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`.

**Not registered (dead declarations):** `set`, `directive` — forward-declared only; safe to move with dispatch but do not register.

### Global State Cross-TU Consumers [VERIFIED: codebase grep]

| Global / pointer | Already `extern` in other modules |
|------------------|-----------------------------------|
| `pointerTO_GBL_LANDMARK_SET`, `pointerTO_GBL_CURVE_SET`, `GBL_*_SET_*` | `ogl_model_ply_ZARF_9.c` |
| `model_index` | `ogl_model_ply_ZARF_9.c` |
| `GBL_INWORK_*_SCALEFACTOR_*` | `curve_ZARF_9.c`, `ogl_model_ZARF_9.c` |
| `dc` | `def_ZARF_9.h` |

Planner must ensure these symbols remain linkable after extraction — add `extern` to `tcl_state.h` or extend `def_ZARF_9.h` minimally.

### Windows R Load Path [VERIFIED: codebase `rtkogl.R:457–482`]

1. `devtools::load_all(".")` → `.onLoad` resolves `inst/libs/x64/tkogl2.dll`
2. `tcl("load", file, "Tkogl2")` — package name **`Tkogl2`** must match `Tcl_PkgProvide` and export prefix
3. No R-side changes in Phase 7

### Deploy Workflow

- Root `BUILD.md` documents `scripts/deploy-dll.ps1` (backup → copy `build/tkogl2.dll` → `inst/libs/x64/`) [VERIFIED: BUILD.md]
- Script referenced but **not present in repo yet** (Phase 6 deliverable) — manual copy remains fallback until Phase 6 completes

## Common Pitfalls

### Pitfall 1: Link-Time Duplicate Symbols

**What goes wrong:** `cmake --build` fails with "multiple definition of `models`" after extraction.

**Why it happens:** Symbol left in god file and copied to new module, or defined in header without `static inline`.

**How to avoid:** Move definition once; leave declaration-only in header; grep for duplicate definitions before each build.

**Warning signs:** Linker errors mentioning `GBL_`, `models`, `buffer`, `simpleLog`.

### Pitfall 2: Missing or Renamed `Tkogl2_Init` Export

**What goes wrong:** R `tcl("load", …)` fails with "cannot find symbol Tkogl2_Init".

**Why it happens:** Init moved to new file without `DLLEXPORT`; wrong function name; god file removed before init migrated.

**How to avoid:** Run export check after every build; keep init in `tcl_init.c` with `#ifdef CODE_FOR_LIBRARY` guard until 07-03 cutover.

**Warning signs:** `objdump -p tkogl2.dll | grep Tkogl2` returns empty.

### Pitfall 3: Shared Buffer / Macro Coupling

**What goes wrong:** Subtle runtime corruption or wrong Tcl results after split.

**Why it happens:** Global `char buffer[1024]` and `messageBuffer[128]` shared across handlers, logging, and draw code; `TCL_RESULT_*` macros allocate via `ALLOCATE_WRAPPER`.

**How to avoid:** Move shared buffers with their primary owner (recommend `tcl_state.c` or keep accessible via extern); do not refactor macro semantics in Phase 7.

**Warning signs:** Garbled Tcl results, log interleaving, landmark placement off-by-one after structurally "clean" split.

### Pitfall 4: `#ifdef STAND_ALONE_TOOL` Fragmentation

**What goes wrong:** Compile errors when standalone blocks split across files without shared declarations.

**Why it happens:** Handlers use dual `#ifdef STAND_ALONE_TOOL` / `TCL_CMD(name)` pattern; `CODE_FOR_LIBRARY` is active per `RunTime_Defines_ZARF_9.h:49`.

**How to avoid:** Preserve ifdef structure verbatim when moving; do not consolidate branches in Phase 7.

**Warning signs:** `interp` undeclared, duplicate `add` function signatures.

### Pitfall 5: Refactoring Before Baseline Locked (Phase 6)

**What goes wrong:** Cannot distinguish refactor regression from pre-existing environment drift.

**Why it happens:** ROADMAP dependency: Phase 6 locks renv + BUILD + deploy workflow.

**How to avoid:** Complete Phase 6 first; tag/backup working DLL (D-08) before first 07-01 commit.

**Warning signs:** Missing deploy script, unpinned R deps, no DLL backup for rollback.

## Code Examples

### CMake: Incremental 07-01 (dispatch only)

```cmake
# After 07-01 — god file still holds window/state/log/init
add_library(tkogl2 SHARED
    ${SRC}/tcl_dispatch.c
    ${SRC}/tcl_if_ZARF_9.c   # remaining code — remove in 07-03
    ${SRC}/ogl_ZARF9.c
    # ... unchanged ...
)
```

### Export Verification (post-build gate)

```bash
# MinGW / WSL cross-build
objdump -p build/tkogl2.dll | grep Tkogl2_Init

# Expected: [Name Tkogl2_Init] or similar export entry
```

Source: [VERIFIED: codebase] — BUILD-02 requirement pattern from Phase 1.

### Module Header Sketch (`tcl_dispatch.h`)

```c
#pragma once
#include "def_ZARF_9.h"

/* Tcl command handlers — registered from tcl_init.c */
int add(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);
int show(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);
/* ... remaining registered handlers ... */

/* Draw pass — called from onDisplay and handlers */
void drawDots(void);
void drawAnchors(void);
void drawCurves(void);
void drawGrid(void);
void onDisplay(void);
```

### Per-Plan Smoke UAT Checklist (D-05)

```
1. cmake --build build -j
2. objdump -p build/tkogl2.dll | grep Tkogl2_Init
3. Deploy DLL to inst/libs/x64/ (script or manual copy)
4. Windows R: devtools::load_all(".")
5. GUImorph() → load C13.1.ply → double-click place ≥1 landmark
6. Append result to .planning/smoke-test-findings.md
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single 5,581-line `tcl_if_ZARF_9.c` | Five modules + existing ogl/dot/curve files | Phase 7 (planned) | Maintainability; same DLL interface |
| MSVC `.vcxproj` | CMake + MinGW | Phase 1 (2026-06) | Cross-compile from WSL; `.vcxproj` reference only |
| Manual DLL copy | `deploy-dll.ps1` (Phase 6) | In progress | Safer swap with backup |

**Deprecated/outdated:**
- **`STAND_ALONE_TOOL` desktop test harness:** Inactive under `CODE_FOR_LIBRARY`; move code but do not enable.
- **Registering `set` / `directive` commands:** Never wired in `Tkogl2_Init`; do not add in Phase 7.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phase 6 completes before Phase 7 execution begins | User Constraints | No reproducible baseline; harder rollback |
| A2 | `scripts/deploy-dll.ps1` will exist after Phase 6 | Runtime State Inventory | Manual deploy still works via BUILD.md |
| A3 | Shared `buffer[1024]` can live in `tcl_state.c` with extern access | Architecture Patterns | Low — linkage only |
| A4 | `TclIf_LogCommands` belongs in `tcl_log.c` per D-02 intent | Module Boundaries | Low — logging vs dispatch borderline |
| A5 | MinGW exports all non-static symbols from DLL | DLL Export Surface | Medium — verify only `Tkogl2_Init` required by R |

## Open Questions (RESOLVED)

1. **Where do `Wrapper_Get*FromObj` helpers land?** — **RESOLVED:** 07-01 moves with dispatch to `tcl_dispatch.c`; extern in `tcl_dispatch.h` for 07-02 consumers.
   - What we know: Used by all handlers; 114–206 lines; `#ifdef STAND_ALONE_TOOL` branches.

2. **Does `clear_model` / `resetModel` belong in state or dispatch?** — **RESOLVED:** 07-03 moves to `tcl_state.c` (state lifecycle owns model reset).
   - What we know: `initialize_state` calls `resetModel`; `clear_model` near logging section (~4628).

3. **Phase 6 completion status at execution time?** — **RESOLVED:** Orchestrator/executor must confirm Phase 6 complete before 07-01; manual deploy fallback documented in VALIDATION.md Wave 0.
   - What we know: ROADMAP lists Phase 6 incomplete; CONTEXT requires baseline first.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| CMake | BUILD-01, all plans | ✓ (validated Phase 1) | ≥3.16 | — |
| MinGW-w64 | Windows DLL build | ✓ (validated Phase 1) | MSYS2 UCRT64 / WSL cross | WSL `cmake/mingw-w64-x86_64.cmake` |
| Windows R 4.6+ | Manual UAT | ✓ (project standard) | 4.6.x | Required — no headless fallback |
| `objdump` / PE tool | Export verify | ✓ (Phase 1) | mingw-w64-tools | `dumpbin` on Windows |
| MSYS2 UCRT64 shell | Primary BUILD.md path | ✓ (documented) | — | WSL cross-compile |
| `scripts/deploy-dll.ps1` | DEV-03 deploy | ✗ (Phase 6 pending) | — | Manual copy per BUILD.md §3 |
| `C13.1.ply` / `test_fresh.dgt` | Smoke UAT | ✓ (local zips, not committed) | — | User-provided fixtures |

**Missing dependencies with no fallback:**
- Windows R GUI session for UAT (WSL cannot run Tcl/Tk GUI)

**Missing dependencies with fallback:**
- `deploy-dll.ps1` — manual `cp build/tkogl2.dll` documented in BUILD.md

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual Windows R GUI UAT (primary); no C unit-test runner in CI |
| Config file | none — `.planning/smoke-test-findings.md` is evidence log |
| Quick run command | Per-plan smoke (D-05): build → export grep → `GUImorph()` → PLY → double-click landmark |
| Full suite command | Final smoke (D-06): full digitize round-trip on `test_fresh.dgt` + append findings |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CENG-01 | God file split; no behavior change | manual GUI | `cmake --build build && objdump -p build/tkogl2.dll \| grep Tkogl2_Init` then Windows R UAT | ❌ Wave 0 — checklist in plans |
| CENG-01 | Landmark placement still works | manual GUI | Double-click landmark on `C13.1.ply` after each plan | ✅ Phase 4 baseline |
| CENG-01 | Full digitize round-trip | manual GUI | Landmarks + curve + save `.dgt` + `openDgt` reload (07-03 only) | ✅ Phase 4 `test_fresh.dgt` workflow |

### Sampling Rate

- **Per task commit:** `cmake --build build -j` (compile gate)
- **Per wave merge:** Export verify + per-plan smoke UAT (D-05)
- **Phase gate:** Final digitize round-trip (D-06) + `smoke-test-findings.md` append (D-07)

### Wave 0 Gaps

- [ ] Pre-Phase-7 DLL backup to tagged path (D-08) — before first extraction
- [ ] `.planning/phases/07-c-engine-modularization/smoke-checklist.md` — optional; at minimum use D-05/D-06 steps in each PLAN.md
- [ ] Confirm Phase 6 complete (renv + BUILD + deploy) — hard gate per ROADMAP dependency
- [ ] Export verify command documented in each plan SUMMARY

*(No automated C test framework — intentional per deferred ideas and project convention)*

## Security Domain

### Applicable ASVS Categories (ASVS L1 — native C extension)

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | N/A — local desktop GUI |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A — single-user local app |
| V5 Input Validation | yes | Existing `Wrapper_GetIntFromObj` / `Wrapper_GetDoubleFromObj` / `validateDot`; preserve when moving handlers |
| V6 Cryptography | no | N/A |
| V10 Malicious Code | partial | No new network surface; avoid introducing dynamic code execution |
| V14 Configuration | partial | DLL path from R package layout only; no secrets in C refactor |

### Known Threat Patterns for C/Tcl/OpenGL Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Buffer overflow via `sprintf` to fixed `buffer[1024]` | Tampering / DoS | Do not change buffer sizes or format strings in Phase 7; defer hardening to Phase 9 |
| Path traversal in PLY/DGT file loads | Elevation / Tampering | Out of scope — existing `ogl_loadModel` / `loadDgt` paths unchanged (D-12) |
| DLL hijacking | Spoofing | Deploy only to `inst/libs/x64/` from trusted build; backup before swap (D-08) |
| Unsafe Tcl result memory (`TCL_DYNAMIC`) | DoS | Preserve existing `TCL_RESULT_*` macro semantics verbatim |

## Project Constraints (from .cursor/rules/)

No `.cursor/rules/` or `.cursorrules` found in project root. No additional project-specific enforcement beyond CONTEXT.md and REQUIREMENTS.md.

## Sources

### Primary (HIGH confidence)
- Codebase: `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_if_ZARF_9.c` — line map, init, globals, handlers
- Codebase: `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt` — build target structure
- Codebase: `integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h`, cross-module `extern` consumers
- Codebase: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R` — load path
- Codebase: `.planning/phases/07-c-engine-modularization/07-CONTEXT.md` — locked decisions

### Secondary (MEDIUM confidence)
- [CMake add_library documentation](https://cmake.org/cmake/help/latest/command/add_library.html) — multi-source shared libraries
- [Tcl Windows extension howto](https://www.tcl-lang.org/doc/howto/winext.tml) — `DLLEXPORT` / DLL symbol export

### Tertiary (LOW confidence)
- Stack Overflow / Google Groups Tcl load threads — confirm init naming only; project uses verified `Tkogl2_Init` from codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — validated CMake/MinGW/Tcl path from Phases 1–5
- Architecture: HIGH — god-file regions mapped with line numbers; locked module boundaries from discuss-phase
- Pitfalls: HIGH — duplicate symbol and export risks documented in `.planning/research/PITFALLS.md` #8 and codebase patterns

**Research date:** 2026-06-19
**Valid until:** 2026-07-19 (stable C refactor domain; 30 days)
