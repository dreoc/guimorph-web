# Codebase Structure

**Analysis Date:** 2026-07-12

## Directory Layout

```
GUImorph/                                          # repo root
├── README.md                                      # End-user run guide (Windows)
├── BUILD.md                                        # Contributor build/deploy guide
├── scripts/                                        # Maintainer helper scripts
│   ├── deploy-dll.ps1                             # Copy built tkogl2.dll into inst/libs/x64
│   ├── init-renv.R                                # First-time renv bootstrap
│   ├── capture-renv-warnings.R
│   ├── extract-tcl-dispatch.py                    # C dispatch extraction helper
│   └── guimorph-startup.R
├── .planning/                                      # GSD planning artifacts (this map: codebase/)
└── integrated-guimorph-development_EOC/
    ├── Project/
    │   ├── GUImorphDevelopment/                    # ★ THE R PACKAGE ROOT
    │   │   ├── DESCRIPTION                        # Package metadata + Imports
    │   │   ├── NAMESPACE                          # Exports: GUImorph, loadDgt
    │   │   ├── R/                                 # ★ Authoritative R sources
    │   │   │   ├── rtkogl.R                       # R↔C bridge + GUImorph()/.onLoad
    │   │   │   ├── 3dDigitize.main.r              # GUI orchestrator (largest)
    │   │   │   ├── 3dDigitize.digitize.r          # Landmarks + anchors tabs
    │   │   │   ├── 3dDigitize.curve.r             # Curves tab
    │   │   │   ├── 3dDigitize.surface.r           # Surface sliders tab
    │   │   │   ├── 3dDigitize.geomorph.r          # GPA tab (gpagen, PCA, export)
    │   │   │   └── gm_utils.R                     # Procrustes / TPS helpers
    │   │   ├── man/                               # roxygen-generated .Rd docs
    │   │   ├── inst/libs/                         # ★ Shipped native binaries
    │   │   │   ├── x64/tkogl2.dll                 # Prebuilt MSVC engine (committed)
    │   │   │   ├── x64/glut64.dll
    │   │   │   └── i386/glut32.dll
    │   │   ├── tests/testthat/                    # testthat unit tests
    │   │   ├── DATA_LOG_FILES/                    # Runtime diagnostic logs (generated)
    │   │   ├── renv/  renv.lock  .Rprofile        # Reproducible R env
    │   │   ├── startGUI.R                         # Convenience launcher
    │   │   └── GUImorphDevelopment.Rproj
    │   └── tkogl2/                                # ★ NATIVE C/OpenGL ENGINE SOURCES
    │       ├── CMakeLists.txt                     # MSVC/MinGW build
    │       ├── tkogl2.sln / tkogl2.vcxproj        # Visual Studio project
    │       ├── BUILD.md                           # Compile internals
    │       ├── src/                               # ★ Engine C sources + headers
    │       ├── include/{tcl_include,tk_include}/  # Vendored Tcl/Tk headers & sources
    │       ├── lib/                               # Import libs (tclstub86_64.lib, glut64.lib)
    │       ├── third_party/glut_shim/GL/          # GL/GLUT shim
    │       ├── cmake/mingw-w64-x86_64.cmake       # MinGW toolchain (unsupported)
    │       └── R/                                 # ⚠ Legacy DUPLICATE R copies (not shipped)
    └── Standalone/tkogl2_SA/                       # Standalone C test harness (STAND_ALONE_TOOL)
        └── main_Test_ZARF_5.c
```

## Directory Purposes

**`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`:**
- Purpose: The R package root — everything `devtools::load_all(".")` / `install_github(subdir=...)` operates on.
- Contains: `DESCRIPTION`, `NAMESPACE`, `R/`, `man/`, `inst/`, `tests/`, `renv`.
- Key files: `DESCRIPTION`, `NAMESPACE`, `R/rtkogl.R`.

**`.../GUImorphDevelopment/R/`:**
- Purpose: Authoritative R source — GUI, bridge, analysis glue.
- Contains: 7 `.R`/`.r` files (`~7,100` lines; `3dDigitize.main.r` alone is ~3,377).
- Key files: `rtkogl.R` (entry + bridge), `3dDigitize.main.r` (orchestrator).

**`.../GUImorphDevelopment/inst/libs/`:**
- Purpose: Native runtime binaries bundled into the installed package.
- Contains: `x64/tkogl2.dll` (the engine, committed), `x64/glut64.dll`, `i386/glut32.dll`.
- Key files: `x64/tkogl2.dll` — located at runtime by `.onLoad` via `system.file("libs/x64/tkogl2.dll")`.

**`.../Project/tkogl2/src/`:**
- Purpose: Modular C/OpenGL engine sources compiled into `tkogl2.dll`.
- Contains: Tcl init/dispatch, window/WGL, state, markers, curves, OpenGL model/render, statistics, logging, plus `def_ZARF_9.h`/`RunTime_Defines_ZARF_9.h` config headers.
- Key files: `tcl_init.c`, `tcl_dispatch.c`, `tcl_window.c`, `tcl_state.c`, `marker.c`, `curve_ZARF_9.c`, `ogl_ZARF9.c`, `ogl_model_ZARF_9.c`, `ogl_model_ply_ZARF_9.c`, `StatisticsFunction_ZARF_9.c`, `tcl_log.c`, `tcl_stub_bootstrap.c`.

**`.../Project/tkogl2/include/`:**
- Purpose: Vendored Tcl/Tk source and headers used to build/stub-link the extension.
- Contains: `tcl_include/`, `tk_include/` (large third-party trees — not project code).
- Committed: Yes. Do not treat as project sources.

**`.../Project/tkogl2/R/`:**
- Purpose: ⚠ Legacy duplicate of the R sources plus retired `geomorph.support.code.r`.
- Committed: Yes, but **not** the package that runs. Edit the `GUImorphDevelopment/R/` copies instead.

**`Standalone/tkogl2_SA/`:**
- Purpose: Standalone C test harness that compiles the engine with `STAND_ALONE_TOOL` (no Tcl runtime) for isolated debugging.
- Key files: `main_Test_ZARF_5.c`, `tkogl2_SA.sln`.

**`DATA_LOG_FILES/`:**
- Purpose: Runtime diagnostic/command logs emitted by the engine/GUI.
- Generated: Yes. Committed: partially (baseline samples present).

## Key File Locations

**Entry Points:**
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R`: `GUImorph()`, `loadDgt()`, `.onLoad`, `.onAttach`, `add/del/set/shows` bridge.
- `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_init.c`: `Tkogl2_Init` (DLL init, registers 8 Tcl commands).
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/startGUI.R`: convenience launcher.

**Configuration:**
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION`: Imports (`rgl`, `geomorph >= 4.1.1`, `Morpho`, `Rvcg`, `tcltk`, `tcltk2`, `vegan`, `parallel`).
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/renv.lock` + `renv/` + `.Rprofile`: pinned R dependency versions.
- `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt`: native build definition.
- `integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h`, `RunTime_Defines_ZARF_9.h`: compile-time config / build-mode `#define`s.

**Core Logic:**
- R GUI: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r`.
- Per-tab R: `3dDigitize.digitize.r`, `3dDigitize.curve.r`, `3dDigitize.surface.r`, `3dDigitize.geomorph.r`.
- C engine state: `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c` / `.h`.

**Testing:**
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/`: `test-curve-io.R`, `test-curve-spinbox.R`, `test-curve-tab-gating.R`, `test-undo-helpers.R`.
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat.R`: test runner.

## Naming Conventions

**Files:**
- R GUI modules: `3dDigitize.<area>.r` (mixed `.r`/`.R` extensions — bridge/utils use `.R`, tab modules use `.r`).
- C engine (project): descriptive base names; legacy/domain files carry a `_ZARF_9` suffix (e.g. `curve_ZARF_9.c`, `ogl_model_ply_ZARF_9.c`, `StatisticsFunction_ZARF_9.c`). Newer split modules drop the suffix (`tcl_init.c`, `tcl_dispatch.c`, `tcl_window.c`, `tcl_state.c`, `tcl_log.c`, `marker.c`).
- Headers pair with sources (`tcl_state.h`, `marker.h`, `tcl_window.h`, `tcl_dispatch.h`, `tcl_log.h`).

**Functions / identifiers:**
- R GUI: `camelCase` verbs (`loadPly`, `switchTab`, `addDot`, `drawElements`); S3 generics as `verb.class` (`ui.main`, `init.surface`, `updateWidgets.digitize`); dot-prefixed internals (`.build_geomorph_data`, `.center_toplevel`).
- C globals: `GBL_` prefix, UPPER_SNAKE (`GBL_LANDMARK_SET`, `GBL_PTR_MODEL`); capacity `#define`s `GBL_*_CAPACITY`.
- C functions: `snake_case` (`marker_add`, `resetContext`, `initialize_state`); Tcl command handlers are bare verbs (`add`, `show`, `del`).

**Directories:**
- lowerCamel/PascalCase mix from original layout (`GUImorphDevelopment`, `tkogl2`, `Standalone`); vendored trees `tcl_include`/`tk_include`.

## Where to Add New Code

**New GUI feature / tab behavior:**
- Primary code: the relevant `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.<area>.r`; register lifecycle via the S3 verbs (`ui.<class>`, `init.<class>`, `bind.<class>`, `updateWidgets.<class>`).
- Cross-tab wiring (menu, tabs, navigation, gating): `R/3dDigitize.main.r`.
- Tests: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-<feature>.R`.

**New R↔C command:**
- R side: add a branch in `add`/`set`/`shows`/`del` in `R/rtkogl.R`.
- C side: implement the handler in `src/tcl_dispatch.c` and, if it is a new top-level command, register it in `src/tcl_init.c` via `Tcl_CreateObjCommand`; then rebuild + `scripts/deploy-dll.ps1`.

**New analysis / statistics:**
- geomorph-facing glue: `R/3dDigitize.geomorph.r`; generic math helpers: `R/gm_utils.R`.

**New engine state:**
- Declare in `src/tcl_state.h`, define/initialize in `src/tcl_state.c` (respect fixed-capacity `GBL_*_CAPACITY` limits and add to `initialize_state`/`resetContext`).

**New marker/curve geometry:**
- Markers: `src/marker.c` (extend `marker_*` core, keep `dot_*`/`anchor_*` wrappers). Curves: `src/curve_ZARF_9.c`.

## Special Directories

**`inst/libs/x64/`:**
- Purpose: Ships the prebuilt `tkogl2.dll` + `glut64.dll` so clones run without compiling.
- Generated: `tkogl2.dll` is a build artifact but **committed**; `.gitignore` blocks *new* build copies while keeping the shipped one tracked. `tkogl2.dll.bak` (deploy backup) is gitignored.
- Committed: Yes (the runtime DLLs).

**`tkogl2/include/{tcl_include,tk_include}/`:**
- Purpose: Vendored Tcl/Tk sources/headers for building the extension.
- Generated: No. Committed: Yes. Not project code — do not audit as such.

**`tkogl2/build-msvc/` and `tkogl2/build/`:**
- Purpose: CMake build output (MSVC / MinGW).
- Generated: Yes. Committed: No (gitignored — configure before building per `BUILD.md`).

**`DATA_LOG_FILES/`:**
- Purpose: Runtime command/diagnostic logs.
- Generated: Yes. Committed: Baseline samples only.

**`renv/`:**
- Purpose: renv project library scaffold; `renv.lock` pins versions.
- Generated: Yes (scaffold). Committed: Yes (`renv.lock`, `.Rprofile`, scaffold).

---

*Structure analysis: 2026-07-12*
