<!-- gsd-project-start source:PROJECT.md -->

## Project

**GUImorph**

GUImorph is an R package with a Tcl/Tk graphical interface for **3D geometric morphometrics**: load PLY mesh specimens, digitize landmarks / curves / anchors / surface semilandmarks, run `geomorph` analyses (GPA, PCA, mean shape), and export coordinates. It exists because `geomorph`'s interactive 3D digitizing functions were deprecated when rgl/OpenGL stopped working on modern macOS — GUImorph is an rgl-independent, `geomorph`-native digitizer that keeps that template-based surface-semilandmark workflow alive. It is used by morphometrics researchers.

**Core Value:** A researcher can digitize a 3D specimen and feed the result straight into `geomorph` — the interactive digitizing viewport must render the mesh and place landmarks correctly.

### Constraints

- **Compatibility**: Must keep the Windows build working — macOS support is additive, not a replacement.
- **Tech stack**: R 4.6+, Tcl/Tk, C99 native engine, `geomorph >= 4.1.1`; dependencies pinned via `renv.lock`. macOS build must integrate with the same R/Tcl `.onLoad` loading model (`tcl("load", file, "Tkogl2")`).
- **Dependencies**: On macOS, OpenGL is deprecated by Apple (still present up to current macOS); the chosen rendering path must run on Apple Silicon + Intel Macs and survive Apple's OpenGL deprecation trajectory.
- **Toolchain**: macOS build needs a documented, reproducible toolchain (Xcode command-line tools / CMake) analogous to the Windows MSVC path.
- **Compatibility**: `.dgt` session files and exports must remain cross-platform compatible with the Windows build.

<!-- gsd-project-end -->

<!-- gsd-stack-start source:codebase/STACK.md -->

## Technology Stack

## Languages

- **R** — Package logic, GUI wiring, and all statistical analysis. R sources under `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/` (`3dDigitize.main.r`, `3dDigitize.geomorph.r`, `3dDigitize.digitize.r`, `3dDigitize.surface.r`, `3dDigitize.curve.r`, `rtkogl.R`, `gm_utils.R`).
- **C (C99)** — Native 3D rendering/digitizing engine compiled into `tkogl2.dll`. Sources under `integrated-guimorph-development_EOC/Project/tkogl2/src/` (`tcl_init.c`, `tcl_dispatch.c`, `tcl_window.c`, `tcl_state.c`, `tcl_log.c`, `ogl_ZARF9.c`, `ogl_model_ZARF_9.c`, `ogl_model_ply_ZARF_9.c`, `curve_ZARF_9.c`, `marker.c`, `StatisticsFunction_ZARF_9.c`). Standard set to C99 in `CMakeLists.txt`.
- **Tcl/Tk** — GUI toolkit. R drives Tk widgets via the `tcltk`/`tcltk2` bridge, and the C DLL registers itself as a Tcl extension (`Tkogl2_Init`) that R calls through `tcl(...)` (see `R/rtkogl.R`). GUI event/command strings are pure Tcl.
- **PowerShell** — Build/deploy automation on Windows (`scripts/deploy-dll.ps1`).
- **Python** — Developer tooling only, not shipped (`scripts/extract-tcl-dispatch.py`).

## Runtime

- **R 4.6+ (64-bit), Windows only.** `renv.lock` pins the development R at **4.6.1** (`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/renv.lock`). The GUI and `tkogl2.dll` require Windows (OpenGL is embedded into a Tk widget's HWND via WGL, so no Linux/macOS build).
- Native engine: **Windows x64 DLL** (`tkogl2.dll`), loaded at package load via `tcl("load", file, "Tkogl2")` in `.onLoad` (`R/rtkogl.R`).
- **renv** — R dependency manager. Lockfile: **present and committed** (`renv.lock`). Activated by `.Rprofile` (`source("renv/activate.R")`).
- Repository source: **CRAN** for all locked packages.

## Frameworks

- **geomorph** `4.1.1` — Geometric morphometrics engine. Used for GPA (`geomorph::gpagen`), PCA (`geomorph::gm.prcomp`), array reshaping (`geomorph::two.d.array`), and specimen plotting. Declared `>= 4.1.1` in `DESCRIPTION`.
- **Morpho** `2.13` — Surface semilandmark placement (`Morpho::fastKmeans` in `R/3dDigitize.surface.r`).
- **Rvcg** `0.25` — PLY mesh reading (`Rvcg::vcgPlyRead`, replaces deprecated `geomorph::read.ply`).
- **RRPP** `2.1.2` — Residual randomization statistics (geomorph dependency; workflow extra per `BUILD.md`).
- **vegan** `2.7-5` — Ordination/ecology stats support.
- **parallel** (base R) — Multi-core Procrustes sliding (GPA "parallel processing" option).
- **tcltk** (base R) — R↔Tk bridge.
- **tcltk2** `1.6.1` — Extended Tk widgets (`tk2label`, `tk2entry`, `tk2checkbutton`, `tk2spinbox`) used throughout the GUI frames.
- **rgl** `1.3.36` — Secondary OpenGL windows for GPA result plots (aligned specimens, mean shape). Note: the *digitizing* viewport is the native `tkogl2` engine, NOT rgl.
- **testthat** `3.3.2` — Unit tests under `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/` (e.g. `test-curve-io.R`, `test-undo-helpers.R`, `test-curve-tab-gating.R`). Declared under `Suggests` in `DESCRIPTION`.
- **devtools** — `devtools::load_all(".")` dev-load workflow (not a runtime Import; installed via `scripts/init-renv.R`).
- **roxygen2** `7.1.1` — Documentation generation (`RoxygenNote` in `DESCRIPTION`; `NAMESPACE` is roxygen-generated).

## Key Dependencies

- `geomorph 4.1.1` — Without it there is no analysis pipeline; GUImorph exists specifically to keep the deprecated geomorph 3D digitizing workflow alive.
- `tkogl2.dll` (in-repo native artifact) — All 3D rendering/digitizing. Shipped prebuilt at `inst/libs/x64/tkogl2.dll`.
- `Rvcg 0.25` — Mesh I/O; PLY loading path for R-side operations.
- **Tcl stubs** — `lib/tclstub86_64.lib` (MSVC) / bootstrap TU `src/tcl_stub_bootstrap.c` (MinGW) for `Tcl_InitStubs`.
- **GLUT** — `lib/glut64.lib` + runtime `lib/glut64.dll` (also deployed to `inst/libs/x64/glut64.dll`). Header shim vendored at `third_party/glut_shim/GL/glut.h`.
- **OpenGL / GLU / GDI / User32** — `opengl32`, `glu32`, `gdi32`, `user32` (Windows SDK system import libs; vendored copies also present in `lib/`).

## Configuration

- No `.env` / secrets model — this is a local desktop app with no external services.
- Runtime debug flag: `options(guimorph.debug=TRUE)` via `GUImorph(debug = TRUE)`, gating the `dbg()` printer (`R/rtkogl.R`).
- renv bootstrap: `.Rprofile` sources `renv/activate.R`; restore with `renv::restore()` from the package root.
- Native build config: `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt` (CMake `>= 3.16`, C99, static MSVC CRT via `CMP0091`/`MultiThreaded`).
- Package metadata: `DESCRIPTION`, `NAMESPACE` (roxygen-generated), `.Rbuildignore`, `GUImorphDevelopment.Rproj`.
- MinGW cross-compile toolchain (advanced/unsupported): `integrated-guimorph-development_EOC/Project/tkogl2/cmake/mingw-w64-x86_64.cmake`.

## Platform Requirements

- Windows 10+, R 4.6+ (64-bit), Git.
- For C changes only: **MSVC** (VS 2022 Build Tools, VCTools workload) + **CMake**. Build with `cmake -B build-msvc -G "Visual Studio 17 2022" -A x64` then `cmake --build build-msvc --config Release`; deploy via `scripts/deploy-dll.ps1`.
- MinGW-w64 builds link but render a black/blank mesh — **not supported for distribution** (`BUILD.md`).
- Windows x64. End users need only Windows 10+, R 4.6+, and Git — the prebuilt `tkogl2.dll` ships in the repo (`inst/libs/x64/`). Statically-linked CRT means no VC++ redistributable required.
- Not supported: Linux, macOS (rgl/OpenGL digitizing path unavailable; this is the reason GUImorph exists as of geomorph 4.1).

<!-- gsd-stack-end -->

<!-- gsd-conventions-start source:CONVENTIONS.md -->

## Conventions

- R package root: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`
- C engine root: `integrated-guimorph-development_EOC/Project/tkogl2/` (sources in `src/`)

## Naming Patterns

### R

- GUI modules use a legacy dot-separated, lowercase-`.r` scheme:
- Newer/utility modules use `.R` (capital): `gm_utils.R`, `rtkogl.R`.
- Extension is inconsistent (`.r` vs `.R`) — keep the existing extension of the
- `camelCase` for GUI/action handlers and helpers: `setStatus`, `busyStart`,
- `dot.separated` for file I/O and S3-style module constructors:
- `snake_case` for a few legacy tag/date helpers: `get_main_date`,

### C

- `snake_case` (preferred/modern): `marker_add`, `dot_select`,
- `camelCase` (legacy): `dotAllocateList`, `dotGetArraySize`,

### The `marker_* / dot_* / anchor_*` wrapper convention (C)

## Code Style

### R

### C

#pragma warning( disable : 4305)
#pragma warning( disable : 4244)
#include "RunTime_Defines_ZARF_9.h"
#include "def_ZARF_9.h"

## Import Organization

### R

### C

## Error Handling

### R

- **Boolean returns:** bridge functions return `TRUE`/`FALSE` to signal
- **String-sentinel checks:** Tcl string results are inspected with
- **`tryCatch` for hard failures:** DLL load and window centering wrap risky
- **User-facing errors:** surfaced **inline** through the status bar via
- `suppressWarnings(as.integer(...))` + `is.na` fallback for parsing values

### C

- Functions returning `int` return **negative (intent `-1`) on error**, `0` or
- Functions returning pointers return **`NULL` on error**, a valid pointer
- **All integer arguments must be `>= 0`** to be valid; negatives are rejected.
- Every pointer argument is NULL-guarded at function entry before use (see the

## Logging

### R — `dbg()` (gated debug printer)

- `dbg()` replaces raw `print()` and is silent unless
- Legacy `print(...)`/`##print(...)` calls are commented out throughout rather
- Startup banner is emitted from `.onAttach` via `packageStartupMessage`
- User status is separate from debug logging: use `setStatus`/`busyStart`/

### C — `simpleLog()` (file diagnostic channel)

- `simpleLog(const char* msg)` timestamps and appends one line to a log file
- **No-op when no file is open** — returns `-1` silently, so `simpleLog` calls
- **Idiom:** `sprintf` into a shared file-static `char buffer[128]` then pass it
- **Message prefixes** encode severity by string convention:
- A second channel, `commandStream_*` (`src/tcl_log.c:270-479`), records raw Tcl

## Comments

- **R:** module files open with a `#dgtDataList` layout comment documenting the
- **C:** block comments (`/* ... */`) with `====` banners separate sections
- Comments frequently explain *why* / historical intent, not just *what*.

## Function & Module Design

- **R exports:** only `GUImorph` and `loadDgt` are exported (`NAMESPACE:3-4`,
- **R module shape:** each GUI tab/module provides `init.*`, `ui.*`, `bind.*`
- **C module shape:** one responsibility per file (see the table in
- **Tcl command surface:** exactly 8 commands are registered

<!-- gsd-conventions-end -->

<!-- gsd-architecture-start source:ARCHITECTURE.md -->

## Architecture

## System Overview

```text

```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| GUI orchestrator | Toplevel window, menu, tabs, navigation, specimen state, save/load | `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` |
| Digitizing/anchors tab | Place/move/delete landmarks and anchors, undo, labels, colors | `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` |
| Curves tab | Define/compute curves (3 landmarks per segment), curve I/O | `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.curve.r` |
| Surface sliders tab | Template build, downsample, surface semilandmark I/O | `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.surface.r` |
| GPA tab | Build geomorph data, `gpagen`, PCA, mean shape, export | `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r` |
| R↔C bridge | Marshal GUI actions into `tcl()` calls to DLL commands | `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R` |
| GM helpers | Procrustes/linear-algebra + TPS utilities | `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/gm_utils.R` |
| DLL entry / command registry | `Tkogl2_Init`; registers 8 Tcl commands | `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_init.c` |
| Tcl dispatch | Command handlers, draw pass, `Wrapper_Get*` marshalling helpers | `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c` |
| Window/GL context | HWND/WGL setup, device context, viewport sizing | `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c` |
| Global state | Fixed-capacity `GBL_*` arrays, model/context pointers, reset | `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c` |
| Markers | Unified `marker_*` core + landmark/anchor wrappers | `integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c` |
| Curves (C) | Curve geometry/state | `integrated-guimorph-development_EOC/Project/tkogl2/src/curve_ZARF_9.c` |
| OpenGL render + model I/O | GL init/draw + PLY / `.dgt` model loading | `integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_ZARF9.c`, `.../ogl_model_ZARF_9.c`, `.../ogl_model_ply_ZARF_9.c` |
| Vertex statistics | Mesh vertex stats | `integrated-guimorph-development_EOC/Project/tkogl2/src/StatisticsFunction_ZARF_9.c` |
| Diagnostics | `simpleLog*`, command stream, file writers | `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_log.c` |

## Pattern Overview

- **Single shared engine state.** The DLL holds all mesh/marker/curve data in module-level globals (`src/tcl_state.c`); R sends imperative commands and queries results back through `tcl()`.
- **S3 method dispatch in R.** All GUI lifecycle verbs (`ui`, `init`, `bind`, `updateWidgets`) are S3 generics dispatched on an environment `e` of class `"main"` (`R/3dDigitize.main.r:78-92`); per-tab implementations live in each `3dDigitize.*.r` file.
- **Command-string protocol.** R never links to C symbols directly — it calls Tcl commands (`add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`) with a fixed 3-argument convention; unused args are passed as negative integers.
- **Native window embedding.** The OpenGL viewport is rendered into a Tk frame's HWND via WGL rather than through `rgl`.
- **Windows-only, prebuilt DLL.** The runtime `tkogl2.dll` is committed under `inst/libs/x64/`; end users never compile.

## Layers

- Purpose: Build and drive the Tk/ttk interface, manage specimen navigation and tab gating, orchestrate digitizing workflow.
- Location: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.*.r`
- Contains: Tk widget construction, event bindings (`onLeftBtnPress`, `onNext`, `switchTab`, ...), S3 method implementations, `.dgt` session I/O.
- Depends on: R↔C bridge, `tcltk`/`tcltk2`, analysis layer.
- Used by: End user via `GUImorph()`.
- Purpose: Translate high-level GUI intents into Tcl command invocations against the DLL.
- Location: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R`
- Contains: `add`, `del`, `set`, `shows`, `loadDgt` wrappers; `.onLoad` (DLL load), `.onAttach` (startup banner), `dbg` gated logger, exported `GUImorph()`.
- Depends on: The loaded `Tkogl2` Tcl package (DLL).
- Used by: All GUI-layer files.
- Purpose: Own mesh geometry, rendering, and marker/curve state; execute Tcl commands.
- Location: `integrated-guimorph-development_EOC/Project/tkogl2/src/`
- Contains: Tcl command handlers, WGL/HWND management, OpenGL draw, PLY/`.dgt` model loading, global state, unified markers.
- Depends on: Tcl stubs (`tclstub86_64.lib`), OpenGL/GLUT shim (vendored `third_party/glut_shim`).
- Used by: R via the Tcl command bridge.
- Purpose: Generalized Procrustes Analysis, PCA/morphospace, TPS, mean-shape reconstruction.
- Location: `R/3dDigitize.geomorph.r`, `R/gm_utils.R`
- Contains: `geomorph::gpagen`, `gm.prcomp`, `two.d.array`; local Procrustes helpers (`center`, `csize`, `rotate.mat`, `tps2d3d`).
- Depends on: `geomorph (>= 4.1.1)`, `Morpho`, `Rvcg`, `vegan`, `parallel`, `rgl` (plots only).
- Used by: GPA tab.

## Data Flow

### Primary Workflow: PLY → Digitize → GPA → Export

### Session Persistence Path

- **R side:** a single `new.env()` `e` of class `"main"` carries all GUI state (`activeDataList`, `dgtDataList`, tab/specimen indices, Tcl variables, `gm.results`). Created in `GUImorph()` (`R/rtkogl.R:399`).
- **C side:** module-level globals in `src/tcl_state.c` (fixed-capacity `GBL_*` arrays, `model_t*`/`context_t*`/`curve_t*` pointer tables, current model index, radii/colors). Reset via `resetContext` / `initialize_state`.

## Key Abstractions

- Purpose: Central mutable store passed to every GUI function; S3 class `"main"` drives dispatch.
- Examples: `R/rtkogl.R:399-405` (creation), used throughout `R/3dDigitize.*.r`.
- Pattern: Environment-as-object; functions mutate `e$...` in place.
- Purpose: Per-specimen digitized data (dir, font, #landmarks, curves, template, rotation, zoom, surface file).
- Examples: Structure documented at `R/3dDigitize.main.r:95-107`; built in `loadPly`, consumed by `.build_geomorph_data`.
- Pattern: List indexed by specimen id.
- Purpose: Unified representation for both landmarks (`g_landmarks`) and anchors (`g_anchors`) with per-set selection state.
- Examples: `src/marker.h:33-40`; core `marker_*` ops in `src/marker.c`.
- Pattern: Tagged struct (`node_type` = LANDMARK/ANCHOR) with `dot_*`/`anchor_*` wrappers forwarding to the core.
- Purpose: Mesh model, GL context mirror, and curve geometry handles.
- Examples: pointer tables `GBL_PTR_MODEL[]`, `GBL_PTR_CONTEXT[]`, `GBL_PTR_CURVE[]` in `src/tcl_state.h:29-56`.
- Pattern: Fixed-slot pointer arrays indexed by specimen/curve id.

## Entry Points

- Location: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R:399`
- Triggers: User call after `library(GUImorph)` / `devtools::load_all`.
- Responsibilities: Set debug option, create `e` env of class `"main"`, call `ui(e)` then `init(e)` to build and initialize the interface.
- Location: `R/rtkogl.R:466`
- Triggers: Package load.
- Responsibilities: Locate `libs/x64/tkogl2.dll` via `system.file`, `tcl("load", file, "Tkogl2")`; warn if missing/failed.
- Location: `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_init.c:14`
- Triggers: Tcl `load` of the DLL (from `.onLoad`).
- Responsibilities: `Tcl_InitStubs`, `Tcl_PkgProvide("Tkogl2","1.0")`, register 8 `Tcl_CreateObjCommand`s (`add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`).
- Location: `R/3dDigitize.geomorph.r:279`
- Triggers: GPA tab actions.
- Responsibilities: Bridge from digitized GUI data into `geomorph`-native arrays and objects.

## Architectural Constraints

- **Platform:** Windows-only. GUI requires Windows R 4.6+ and the native `tkogl2.dll`; Linux/macOS unsupported in beta (v0.9.0). See `README.md`.
- **Single native window/context:** OpenGL rendering targets one HWND/WGL device context managed in `src/tcl_window.c` (`dc`/`width`/`height`); markers/mesh share one global GL state.
- **Fixed-capacity global state:** Storage is statically bounded — `GBL_LANDMARK_SET_CAPACITY 25`, `GBL_CURVE_SET_CAPACITY 10`, `GBL_MODEL_SLOTS 5`, `GBL_DELTAS_CAPACITY 1000` (`src/tcl_state.h:12-17`). Exceeding capacity is a hard limit, not dynamic growth.
- **Module-level singletons:** Nearly all engine state (models, context, markers, colors, radii, rotation angles) lives in `src/tcl_state.c` globals — the engine is effectively a singleton per R session.
- **Fixed argument protocol:** Every `tcl()` call into the DLL passes 3 arguments; unused ones are negative-integer placeholders (`R/rtkogl.R` `set`/`add`/`del`). `del` additionally uses `objc` count to distinguish "delete selected" vs "delete at coordinate" (`R/rtkogl.R:338-390`).
- **Dual build modes:** C sources compile either as the R/Tcl library (`CODE_FOR_LIBRARY`) or the standalone test tool (`STAND_ALONE_TOOL`) via `#ifdef` (see `Wrapper_Get*` in `src/tcl_dispatch.c:25-65`).
- **Toolchain:** Distributed DLL must be MSVC-built; MinGW builds link but render black/blank (`BUILD.md`).

## Anti-Patterns

### Duplicated legacy R sources under `tkogl2/R/`

### Retired god file left in tree

### Argument placeholders overloaded with meaning

## Error Handling

- `tcl(...)` results are compared with `startsWith(result, "WARNING"|"ERROR"|"SUCCESS"|"IGNORE"|"UNDER_CONSTRUCTION")` to branch (`R/rtkogl.R` `add`, `loadDgt`, `set`).
- GPA-order guards: `Plot Aligned Specimens`/`Save Result` call `.gm_results_or_warn(e)` and abort with a message if `Compute` has not run.
- `tryCatch` around DLL `load` in `.onLoad` and window centering in `.center_toplevel`.

## Cross-Cutting Concerns

<!-- gsd-architecture-end -->

<!-- gsd-skills-start source:skills/ -->

## Project Skills

| Skill | Description | Path |
|-------|-------------|------|
| cavecrew | > Decision guide for delegating to caveman-style subagents. Tells the main thread WHEN to spawn `cavecrew-investigator` (locate code), `cavecrew-builder` (1-2 file edit), or `cavecrew-reviewer` (diff review) instead of doing the work inline or using vanilla `Explore`. Subagent output is caveman-compressed so the tool-result injected back into main context is ~60% smaller — main context lasts longer across long sessions. Trigger: "delegate to subagent", "use cavecrew", "spawn investigator/builder/reviewer", "save context", "compressed agent output". | `.agents/skills/cavecrew/SKILL.md` |
| caveman | > Ultra-compressed communication mode. Cuts output tokens 65% (measured) by speaking like caveman while keeping full technical accuracy. Supports intensity levels: lite, full (default), ultra, wenyan-lite, wenyan-full, wenyan-ultra. Use when user says "caveman mode", "talk like caveman", "use caveman", "less tokens", "be brief", or invokes /caveman. Also auto-triggers when token efficiency is requested. | `.agents/skills/caveman/SKILL.md` |
| caveman-commit | > Ultra-compressed commit message generator. Cuts noise from commit messages while preserving intent and reasoning. Conventional Commits format. Subject ≤50 chars, body only when "why" isn't obvious. Use when user says "write a commit", "commit message", "generate commit", "/commit", or invokes /caveman-commit. Auto-triggers when staging changes. | `.agents/skills/caveman-commit/SKILL.md` |
| caveman-compress | > Compress natural language memory files (CLAUDE.md, todos, preferences) into caveman format to save input tokens. Preserves all technical substance, code, URLs, and structure. Compressed version overwrites the original file. Human-readable backup saved as FILE.original.md. Trigger: /caveman-compress FILEPATH or "compress memory file" | `.agents/skills/caveman-compress/SKILL.md` |
| caveman-help | > Quick-reference card for all caveman modes, skills, and commands. One-shot display, not a persistent mode. Trigger: /caveman-help, "caveman help", "what caveman commands", "how do I use caveman". | `.agents/skills/caveman-help/SKILL.md` |
| caveman-review | > Ultra-compressed code review comments. Cuts noise from PR feedback while preserving the actionable signal. Each comment is one line: location, problem, fix. Use when user says "review this PR", "code review", "review the diff", "/review", or invokes /caveman-review. Auto-triggers when reviewing pull requests. | `.agents/skills/caveman-review/SKILL.md` |
| caveman-stats | > Show real token usage and estimated savings for the current session. Reads directly from the Claude Code session log — no AI estimation. Triggers on /caveman-stats. Output is injected by the mode-tracker hook; the model itself does not compute the numbers. | `.agents/skills/caveman-stats/SKILL.md` |
<!-- gsd-skills-end -->

<!-- gsd-workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- gsd-workflow-end -->

<!-- gsd-profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- gsd-profile-end -->
