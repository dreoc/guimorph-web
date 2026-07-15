<!-- refreshed: 2026-07-12 -->
# Architecture

**Analysis Date:** 2026-07-12

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                    R GUI / Controller Layer (Windows R)                   │
│   Tk/ttk widgets, event bindings, S3 dispatch on env `e` (class "main")   │
│  `R/3dDigitize.main.r`  `R/3dDigitize.digitize.r`  `R/3dDigitize.curve.r` │
│  `R/3dDigitize.surface.r`             `R/3dDigitize.geomorph.r` (GPA tab)  │
└───────────────┬──────────────────────────────────────────┬───────────────┘
                │ tcl(...) command calls                     │ geomorph::gpagen / gm.prcomp
                ▼                                            ▼
┌───────────────────────────────────────┐    ┌──────────────────────────────┐
│        R ↔ C Bridge (marshalling)      │    │   Analysis Layer (R pkgs)     │
│  add / del / set / shows / loadDgt     │    │  geomorph, Morpho, Rvcg,      │
│           `R/rtkogl.R`                  │    │  vegan, parallel + `gm_utils` │
└───────────────┬───────────────────────┘    └──────────────────────────────┘
                │ Tcl_CreateObjCommand dispatch (8 commands)
                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│               Native C / OpenGL Engine — `tkogl2.dll` (MSVC)                │
├─────────────────┬─────────────────┬──────────────────┬─────────────────────┤
│  Tcl init/dispatch │  Window / WGL   │   Markers/Curves │   OpenGL render     │
│ `src/tcl_init.c`   │ `src/tcl_window.c` │ `src/marker.c`  │ `src/ogl_ZARF9.c`  │
│ `src/tcl_dispatch.c`│ (HWND embed)   │ `src/curve_*.c` │ `src/ogl_model_*.c`│
├─────────────────┴─────────────────┴──────────────────┴─────────────────────┤
│  Global state (fixed-capacity arrays/pointers) `src/tcl_state.c`            │
│  Diagnostics/log channel `src/tcl_log.c`   Stats `src/StatisticsFunction_*.c`│
└───────────────────────────────────────────────────────────────────────────┘
                │
                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  Store / Files: `.ply` meshes (in), `.dgt` sessions (in/out),               │
│  `.csv` aligned coords (out), `.rds` geomorph data (out)                    │
└───────────────────────────────────────────────────────────────────────────┘
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

**Overall:** Layered "R GUI over Tcl/Tk calling into a native C OpenGL DLL" — a thin R/Tk presentation + controller layer drives a stateful native rendering/digitizing engine through the Tcl command bridge, while heavy statistical analysis is delegated to the `geomorph` R ecosystem.

**Key Characteristics:**
- **Single shared engine state.** The DLL holds all mesh/marker/curve data in module-level globals (`src/tcl_state.c`); R sends imperative commands and queries results back through `tcl()`.
- **S3 method dispatch in R.** All GUI lifecycle verbs (`ui`, `init`, `bind`, `updateWidgets`) are S3 generics dispatched on an environment `e` of class `"main"` (`R/3dDigitize.main.r:78-92`); per-tab implementations live in each `3dDigitize.*.r` file.
- **Command-string protocol.** R never links to C symbols directly — it calls Tcl commands (`add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`) with a fixed 3-argument convention; unused args are passed as negative integers.
- **Native window embedding.** The OpenGL viewport is rendered into a Tk frame's HWND via WGL rather than through `rgl`.
- **Windows-only, prebuilt DLL.** The runtime `tkogl2.dll` is committed under `inst/libs/x64/`; end users never compile.

## Layers

**R GUI / Controller Layer:**
- Purpose: Build and drive the Tk/ttk interface, manage specimen navigation and tab gating, orchestrate digitizing workflow.
- Location: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.*.r`
- Contains: Tk widget construction, event bindings (`onLeftBtnPress`, `onNext`, `switchTab`, ...), S3 method implementations, `.dgt` session I/O.
- Depends on: R↔C bridge, `tcltk`/`tcltk2`, analysis layer.
- Used by: End user via `GUImorph()`.

**R ↔ C Bridge:**
- Purpose: Translate high-level GUI intents into Tcl command invocations against the DLL.
- Location: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R`
- Contains: `add`, `del`, `set`, `shows`, `loadDgt` wrappers; `.onLoad` (DLL load), `.onAttach` (startup banner), `dbg` gated logger, exported `GUImorph()`.
- Depends on: The loaded `Tkogl2` Tcl package (DLL).
- Used by: All GUI-layer files.

**Native C / OpenGL Engine (`tkogl2.dll`):**
- Purpose: Own mesh geometry, rendering, and marker/curve state; execute Tcl commands.
- Location: `integrated-guimorph-development_EOC/Project/tkogl2/src/`
- Contains: Tcl command handlers, WGL/HWND management, OpenGL draw, PLY/`.dgt` model loading, global state, unified markers.
- Depends on: Tcl stubs (`tclstub86_64.lib`), OpenGL/GLUT shim (vendored `third_party/glut_shim`).
- Used by: R via the Tcl command bridge.

**Analysis Layer (R packages):**
- Purpose: Generalized Procrustes Analysis, PCA/morphospace, TPS, mean-shape reconstruction.
- Location: `R/3dDigitize.geomorph.r`, `R/gm_utils.R`
- Contains: `geomorph::gpagen`, `gm.prcomp`, `two.d.array`; local Procrustes helpers (`center`, `csize`, `rotate.mat`, `tps2d3d`).
- Depends on: `geomorph (>= 4.1.1)`, `Morpho`, `Rvcg`, `vegan`, `parallel`, `rgl` (plots only).
- Used by: GPA tab.

## Data Flow

### Primary Workflow: PLY → Digitize → GPA → Export

1. **Load PLY** — `File → Load ply File` → `loadPly(e)` reads one or more `.ply` paths, builds `dgtDataList`, and issues `add("specimen", ...)` (`R/3dDigitize.main.r:1420`).
2. **Mesh into engine** — the `add` Tcl command dispatches to the DLL, which loads mesh geometry into a `model_t` and renders it into the embedded OpenGL viewport (`src/ogl_model_ply_ZARF_9.c`, `src/ogl_ZARF9.c`).
3. **Digitize landmarks** — double-click on the canvas → `onLeftBtnPress`/`addDot(e, x, y)` converts screen coords, then `add("landmark", x, y, z)` (`R/3dDigitize.digitize.r:993`) → `marker_add` stores into `g_landmarks` (`src/marker.c`); OpenGL redraws.
4. **Anchors / curves / surface (optional)** — `addAnchor` → `add("anchor", ...)`; curves defined as 3-landmark triplets per segment → `add("curve", ...)` → `curve_ZARF_9.c`; surface sliders via template build/downsample (`R/3dDigitize.surface.r`).
5. **Assemble geomorph data** — `.build_geomorph_data(e)` collects landmarks/curves/surfaces into a `land[p,k,n]` array plus `curves`/`surfaces` matrices (`R/3dDigitize.geomorph.r`).
6. **Run GPA** — GPA tab `Compute` → `compute(e)` calls `geomorph::gpagen(...)`; result stored in `e$gm.results` and assigned to the global workspace (`R/3dDigitize.geomorph.r:314`).
7. **Visualize** — `Plot Aligned Specimens` (`plotspecs`), `PCA (morphospace)` (`plotPCA`, `gm.prcomp`), `Plot Mean Shape` (`plotMeanShape`) — all open `rgl` windows.
8. **Export** — `Save Result` → `save(e)` writes aligned coords + `Csize` to `.csv`; `exportGeomorph(e)` writes a geomorph-ready `.rds`/workspace object.

### Session Persistence Path

1. `File → Save to DGT` → `saveToDgt(e)` serializes landmarks/anchors/curves/template to a `.dgt` file (`R/3dDigitize.main.r:1860`).
2. `File → Load DGT File` → `openDgt(e)` restores a session; if anchors are present, **Place Anchors** is re-checked and locked, all tabs unlock (`R/3dDigitize.main.r:2700`).
3. `Add PLY to Current DGT` (`addPly`) and `Merge DGT Files` (`mergeDgtFiles`/`mergeDgt`) extend/combine datasets (matching template, curves, and point counts).

**State Management:**
- **R side:** a single `new.env()` `e` of class `"main"` carries all GUI state (`activeDataList`, `dgtDataList`, tab/specimen indices, Tcl variables, `gm.results`). Created in `GUImorph()` (`R/rtkogl.R:399`).
- **C side:** module-level globals in `src/tcl_state.c` (fixed-capacity `GBL_*` arrays, `model_t*`/`context_t*`/`curve_t*` pointer tables, current model index, radii/colors). Reset via `resetContext` / `initialize_state`.

## Key Abstractions

**`e` — GUI state environment (R):**
- Purpose: Central mutable store passed to every GUI function; S3 class `"main"` drives dispatch.
- Examples: `R/rtkogl.R:399-405` (creation), used throughout `R/3dDigitize.*.r`.
- Pattern: Environment-as-object; functions mutate `e$...` in place.

**`dgtDataList` / `activeDataList` (R):**
- Purpose: Per-specimen digitized data (dir, font, #landmarks, curves, template, rotation, zoom, surface file).
- Examples: Structure documented at `R/3dDigitize.main.r:95-107`; built in `loadPly`, consumed by `.build_geomorph_data`.
- Pattern: List indexed by specimen id.

**`marker_set_t` (C):**
- Purpose: Unified representation for both landmarks (`g_landmarks`) and anchors (`g_anchors`) with per-set selection state.
- Examples: `src/marker.h:33-40`; core `marker_*` ops in `src/marker.c`.
- Pattern: Tagged struct (`node_type` = LANDMARK/ANCHOR) with `dot_*`/`anchor_*` wrappers forwarding to the core.

**`model_t` / `context_t` / `curve_t` (C):**
- Purpose: Mesh model, GL context mirror, and curve geometry handles.
- Examples: pointer tables `GBL_PTR_MODEL[]`, `GBL_PTR_CONTEXT[]`, `GBL_PTR_CURVE[]` in `src/tcl_state.h:29-56`.
- Pattern: Fixed-slot pointer arrays indexed by specimen/curve id.

## Entry Points

**`GUImorph(debug = FALSE)` (R, exported):**
- Location: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R:399`
- Triggers: User call after `library(GUImorph)` / `devtools::load_all`.
- Responsibilities: Set debug option, create `e` env of class `"main"`, call `ui(e)` then `init(e)` to build and initialize the interface.

**`.onLoad(libname, pkgname)` (R):**
- Location: `R/rtkogl.R:466`
- Triggers: Package load.
- Responsibilities: Locate `libs/x64/tkogl2.dll` via `system.file`, `tcl("load", file, "Tkogl2")`; warn if missing/failed.

**`Tkogl2_Init(Tcl_Interp*)` (C, DLL export):**
- Location: `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_init.c:14`
- Triggers: Tcl `load` of the DLL (from `.onLoad`).
- Responsibilities: `Tcl_InitStubs`, `Tcl_PkgProvide("Tkogl2","1.0")`, register 8 `Tcl_CreateObjCommand`s (`add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`).

**`exportGeomorph` / `.build_geomorph_data` (R):**
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

**What happens:** A second, older copy of the R files (`3dDigitize.*.r`, `rtkogl.R`, and the retired `geomorph.support.code.r`) exists under `integrated-guimorph-development_EOC/Project/tkogl2/R/`.
**Why it's wrong:** The shipped/authoritative package sources are under `.../GUImorphDevelopment/R/`. Editing the `tkogl2/R/` copies has no runtime effect and risks divergence.
**Do this instead:** Treat `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/` as the single source of truth for R code.

### Retired god file left in tree

**What happens:** `tcl_if_ZARF_9.c` (and `dot_ZARF_9.c`) may still appear in the source tree but are **removed from the CMake build** (`BUILD.md` §"C source layout").
**Why it's wrong:** Reading/editing them wastes effort — they are not compiled.
**Do this instead:** Only modify the modular files listed in the CMake build; markers live in `src/marker.c`, dispatch in `src/tcl_dispatch.c`.

### Argument placeholders overloaded with meaning

**What happens:** Unused Tcl args are passed as negative integers, and `del` distinguishes behavior by argument count rather than an explicit flag (`R/rtkogl.R:338-390`).
**Why it's wrong:** Adding a placeholder arg to a "delete selected" call silently routes to the coordinate-delete path.
**Do this instead:** Follow the documented convention in `rtkogl.R`; omit trailing args for selected-marker deletes.

## Error Handling

**Strategy:** Defensive R wrappers inspect string return values from the DLL; user-facing failures surface via `tkmessageBox`. DLL load failure degrades gracefully with a `warning` rather than aborting package load.

**Patterns:**
- `tcl(...)` results are compared with `startsWith(result, "WARNING"|"ERROR"|"SUCCESS"|"IGNORE"|"UNDER_CONSTRUCTION")` to branch (`R/rtkogl.R` `add`, `loadDgt`, `set`).
- GPA-order guards: `Plot Aligned Specimens`/`Save Result` call `.gm_results_or_warn(e)` and abort with a message if `Compute` has not run.
- `tryCatch` around DLL `load` in `.onLoad` and window centering in `.center_toplevel`.

## Cross-Cutting Concerns

**Logging:** Gated R debug printer `dbg(...)` prints only when `options(guimorph.debug=TRUE)` (set by `GUImorph(debug=TRUE)`) — `R/rtkogl.R:744`. Native side logs via `simpleLog*` and command-stream/file writers in `src/tcl_log.c`; session logs land in `DATA_LOG_FILES/`.
**Validation:** Tab gating (`refreshTabGating`, `updateStepLabel`) enforces workflow prerequisites before enabling Surface Sliders/Curves/GPA; count checks in `setLandmarkNum`/`setAnchorNum`.
**Authentication:** Not applicable (local desktop app).

---

*Architecture analysis: 2026-07-12*
