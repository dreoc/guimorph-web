# Technology Stack

**Analysis Date:** 2026-07-12

## Languages

**Primary:**
- **R** — Package logic, GUI wiring, and all statistical analysis. R sources under `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/` (`3dDigitize.main.r`, `3dDigitize.geomorph.r`, `3dDigitize.digitize.r`, `3dDigitize.surface.r`, `3dDigitize.curve.r`, `rtkogl.R`, `gm_utils.R`).
- **C (C99)** — Native 3D rendering/digitizing engine compiled into `tkogl2.dll`. Sources under `integrated-guimorph-development_EOC/Project/tkogl2/src/` (`tcl_init.c`, `tcl_dispatch.c`, `tcl_window.c`, `tcl_state.c`, `tcl_log.c`, `ogl_ZARF9.c`, `ogl_model_ZARF_9.c`, `ogl_model_ply_ZARF_9.c`, `curve_ZARF_9.c`, `marker.c`, `StatisticsFunction_ZARF_9.c`). Standard set to C99 in `CMakeLists.txt`.

**Secondary:**
- **Tcl/Tk** — GUI toolkit. R drives Tk widgets via the `tcltk`/`tcltk2` bridge, and the C DLL registers itself as a Tcl extension (`Tkogl2_Init`) that R calls through `tcl(...)` (see `R/rtkogl.R`). GUI event/command strings are pure Tcl.
- **PowerShell** — Build/deploy automation on Windows (`scripts/deploy-dll.ps1`).
- **Python** — Developer tooling only, not shipped (`scripts/extract-tcl-dispatch.py`).

## Runtime

**Environment:**
- **R 4.6+ (64-bit), Windows only.** `renv.lock` pins the development R at **4.6.1** (`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/renv.lock`). The GUI and `tkogl2.dll` require Windows (OpenGL is embedded into a Tk widget's HWND via WGL, so no Linux/macOS build).
- Native engine: **Windows x64 DLL** (`tkogl2.dll`), loaded at package load via `tcl("load", file, "Tkogl2")` in `.onLoad` (`R/rtkogl.R`).

**Package Manager:**
- **renv** — R dependency manager. Lockfile: **present and committed** (`renv.lock`). Activated by `.Rprofile` (`source("renv/activate.R")`).
- Repository source: **CRAN** for all locked packages.

## Frameworks

**Core (morphometrics/analysis):**
- **geomorph** `4.1.1` — Geometric morphometrics engine. Used for GPA (`geomorph::gpagen`), PCA (`geomorph::gm.prcomp`), array reshaping (`geomorph::two.d.array`), and specimen plotting. Declared `>= 4.1.1` in `DESCRIPTION`.
- **Morpho** `2.13` — Surface semilandmark placement (`Morpho::fastKmeans` in `R/3dDigitize.surface.r`).
- **Rvcg** `0.25` — PLY mesh reading (`Rvcg::vcgPlyRead`, replaces deprecated `geomorph::read.ply`).
- **RRPP** `2.1.2` — Residual randomization statistics (geomorph dependency; workflow extra per `BUILD.md`).
- **vegan** `2.7-5` — Ordination/ecology stats support.
- **parallel** (base R) — Multi-core Procrustes sliding (GPA "parallel processing" option).

**GUI:**
- **tcltk** (base R) — R↔Tk bridge.
- **tcltk2** `1.6.1` — Extended Tk widgets (`tk2label`, `tk2entry`, `tk2checkbutton`, `tk2spinbox`) used throughout the GUI frames.
- **rgl** `1.3.36` — Secondary OpenGL windows for GPA result plots (aligned specimens, mean shape). Note: the *digitizing* viewport is the native `tkogl2` engine, NOT rgl.

**Testing:**
- **testthat** `3.3.2` — Unit tests under `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/` (e.g. `test-curve-io.R`, `test-undo-helpers.R`, `test-curve-tab-gating.R`). Declared under `Suggests` in `DESCRIPTION`.

**Build/Dev:**
- **devtools** — `devtools::load_all(".")` dev-load workflow (not a runtime Import; installed via `scripts/init-renv.R`).
- **roxygen2** `7.1.1` — Documentation generation (`RoxygenNote` in `DESCRIPTION`; `NAMESPACE` is roxygen-generated).

## Key Dependencies

**Critical:**
- `geomorph 4.1.1` — Without it there is no analysis pipeline; GUImorph exists specifically to keep the deprecated geomorph 3D digitizing workflow alive.
- `tkogl2.dll` (in-repo native artifact) — All 3D rendering/digitizing. Shipped prebuilt at `inst/libs/x64/tkogl2.dll`.
- `Rvcg 0.25` — Mesh I/O; PLY loading path for R-side operations.

**Infrastructure (native link-time, vendored):**
- **Tcl stubs** — `lib/tclstub86_64.lib` (MSVC) / bootstrap TU `src/tcl_stub_bootstrap.c` (MinGW) for `Tcl_InitStubs`.
- **GLUT** — `lib/glut64.lib` + runtime `lib/glut64.dll` (also deployed to `inst/libs/x64/glut64.dll`). Header shim vendored at `third_party/glut_shim/GL/glut.h`.
- **OpenGL / GLU / GDI / User32** — `opengl32`, `glu32`, `gdi32`, `user32` (Windows SDK system import libs; vendored copies also present in `lib/`).

## Configuration

**Environment:**
- No `.env` / secrets model — this is a local desktop app with no external services.
- Runtime debug flag: `options(guimorph.debug=TRUE)` via `GUImorph(debug = TRUE)`, gating the `dbg()` printer (`R/rtkogl.R`).
- renv bootstrap: `.Rprofile` sources `renv/activate.R`; restore with `renv::restore()` from the package root.

**Build:**
- Native build config: `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt` (CMake `>= 3.16`, C99, static MSVC CRT via `CMP0091`/`MultiThreaded`).
- Package metadata: `DESCRIPTION`, `NAMESPACE` (roxygen-generated), `.Rbuildignore`, `GUImorphDevelopment.Rproj`.
- MinGW cross-compile toolchain (advanced/unsupported): `integrated-guimorph-development_EOC/Project/tkogl2/cmake/mingw-w64-x86_64.cmake`.

## Platform Requirements

**Development:**
- Windows 10+, R 4.6+ (64-bit), Git.
- For C changes only: **MSVC** (VS 2022 Build Tools, VCTools workload) + **CMake**. Build with `cmake -B build-msvc -G "Visual Studio 17 2022" -A x64` then `cmake --build build-msvc --config Release`; deploy via `scripts/deploy-dll.ps1`.
- MinGW-w64 builds link but render a black/blank mesh — **not supported for distribution** (`BUILD.md`).

**Production / distribution:**
- Windows x64. End users need only Windows 10+, R 4.6+, and Git — the prebuilt `tkogl2.dll` ships in the repo (`inst/libs/x64/`). Statically-linked CRT means no VC++ redistributable required.
- Not supported: Linux, macOS (rgl/OpenGL digitizing path unavailable; this is the reason GUImorph exists as of geomorph 4.1).

---

*Stack analysis: 2026-07-12*
