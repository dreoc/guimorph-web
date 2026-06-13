# GUImorph R Setup & Smoke-Test Findings

**Date:** 2026-06-13  
**Scope:** Windows R installation, dependency setup, first attempt to load GUImorph, and related native (`tkogl2`) build status.

---

## Executive summary

| Area | Status |
|------|--------|
| Windows R 4.6.0 installed | ✅ Done (`winget install RProject.R`) |
| WSL UNC path from Windows R | ✅ Works |
| CRAN dependencies for GUImorph | ✅ Installed to user library |
| GUImorph package loaded / GUI launched | ❌ Not yet — package never installed/loaded |
| New MinGW `tkogl2.dll` built in WSL | ✅ Done — exports `Tkogl2_Init` |
| End-to-end GUI smoke test | ⏳ Pending |

**Bottom line:** The R toolchain and dependencies are in place. GUImorph itself was not loaded because step 4 used a placeholder zip path. The next action is `devtools::load_all(".")` followed by `GUImorph()`, optionally swapping in the newly built `tkogl2.dll`.

---

## Environment

| Item | Value |
|------|-------|
| OS | Windows 10/11 + WSL Ubuntu |
| R | 4.6.0 (2026-04-24 ucrt), x86_64-w64-mingw32/x64 |
| R install path | `C:\Program Files\R\R-4.6.0\bin\R.exe` |
| User R library | `C:\Users\akagi\AppData\Local\R\win-library\4.6` |
| Package source dir | `\\wsl.localhost\Ubuntu\home\akagi\home\GUImorph\integrated-guimorph-development_EOC\Project\GUImorphDevelopment` |

GUImorph is a **Windows GUI application** (Tcl/Tk + OpenGL). It must be run from **Windows R**, not WSL/Linux R.

---

## Session log — what worked

### 1. R launches correctly

```
R version 4.6.0 (2026-04-24 ucrt) -- "Because it was There"
Platform: x86_64-w64-mingw32/x64
```

### 2. Working directory set via WSL UNC path

```r
pkg_dir <- "\\\\wsl.localhost\\Ubuntu\\home\\akagi\\home\\GUImorph\\integrated-guimorph-development_EOC\\Project\\GUImorphDevelopment"
setwd(pkg_dir)
getwd()
# => \\wsl.localhost/Ubuntu/home/akagi/home/GUImorph/.../GUImorphDevelopment
```

### 3. CRAN dependencies installed successfully

Prompted to use a personal library (system library not writable). Accepted `yes` for:

- `C:\Users\akagi\AppData\Local\R\win-library\4.6`

All target packages installed without error:

| Package | Version (from CRAN 4.6) |
|---------|-------------------------|
| geomorph | 4.1.0 |
| Morpho | 2.13 |
| Rvcg | 0.25 |
| tcltk2 | 1.6.1 |
| vegan | 2.7-5 |
| devtools | 2.5.2 |
| roxygen2 | 8.0.0 |

Plus ~100 transitive dependencies (ggplot2, rgl, Rcpp, etc.).

---

## Session log — what failed

### 1. Placeholder zip install

```r
install.packages("C:/path/to/GUImorph_....zip", repos = NULL, type = "win.binary")
# Error: zip file 'C:/path/to/GUImorph_....zip' not found
```

This was an example path from setup instructions, not a real file.

### 2. GUImorph not installed

```r
library(GUImorph)
# Error: there is no package called 'GUImorph'

GUImorph()
# Error: could not find function "GUImorph"
```

Expected: the package must be loaded via `devtools::load_all(".")` or installed from a real zip before `library(GUImorph)` / `GUImorph()` work.

### 3. Minor user typos (non-blocking)

- `$$$` at the personal-library prompt — install continued anyway.
- `yyes` — harmless; dependencies had already finished installing.

---

## Available artifacts in the repo

| Artifact | Location | Notes |
|----------|----------|-------|
| Prebuilt GUImorph zip | `zips/GUImorph_1.0.0.08.18.2020.16.28.zip` | Gitignored; present locally |
| Legacy `tkogl2.dll` (2020) | `GUImorphDevelopment/inst/libs/x64/tkogl2.dll` | Bundled with R package |
| Legacy `tkogl2.dll` (2020) | `GUImorphDevelopment/libs/x64/tkogl2.dll` | Alternate copy |
| **New** MinGW `tkogl2.dll` | `Project/tkogl2/build/tkogl2.dll` | Built 2026-06-13 from ZARF_9 sources |

### New DLL validation (objdump)

```
build/tkogl2.dll: PE32+ executable (DLL) (console) x86-64, for MS Windows
Export: Tkogl2_Init   (exact symbol R/Tcl expects for tcl("load", ..., "Tkogl2"))
```

Build details:

- Toolchain: MinGW-w64 cross-compile from WSL (`x86_64-w64-mingw32-gcc`)
- Build system: `Project/tkogl2/CMakeLists.txt` + `cmake/mingw-w64-x86_64.cmake`
- Tcl stub: self-contained `src/tcl_stub_bootstrap.c` (replaces unreadable MSVC `tclstub86_64.lib`)
- One cosmetic warning fixed post-build: `extern` + initializer on `curveVersionPtr` in `curve_ZARF_9.c`

**Not yet validated at runtime:** `Tcl_InitStubs` success, OpenGL rendering, full GUI workflow.

---

## How GUImorph loads the native extension

On `library(GUImorph)` or `devtools::load_all(".")`, `.onLoad` in `R/rtkogl.R`:

1. Resolves `inst/libs/x64/tkogl2.dll` (64-bit R)
2. Calls `tcl("load", file, "Tkogl2")`
3. On failure → warning: `loading tkogl2 failed`

Success indicator in the R console:

```
File 3dDigitize.main ... function .onload
[path to tkogl2.dll]
-----------------
```

Then `GUImorph()` should open a Tcl/Tk window titled **"3D GUImorph"**.

---

## Recommended next steps

### Step A — Load GUImorph from source (fastest)

In Windows R, with `setwd()` already pointing at `GUImorphDevelopment`:

```r
library(devtools)
load_all(".")
GUImorph()
```

### Step B — Or install from the real prebuilt zip

```r
zip_path <- "//wsl.localhost/Ubuntu/home/akagi/home/GUImorph/zips/GUImorph_1.0.0.08.18.2020.16.28.zip"
install.packages(zip_path, repos = NULL, type = "win.binary")
library(GUImorph)
GUImorph()
```

### Step C — Test the new MinGW DLL before full GUI

Copy or symlink the new build into the package:

```
Project/tkogl2/build/tkogl2.dll
  → GUImorphDevelopment/inst/libs/x64/tkogl2.dll
```

Minimal load test in R:

```r
library(tcltk)
dll <- "//wsl.localhost/Ubuntu/home/akagi/home/GUImorph/integrated-guimorph-development_EOC/Project/tkogl2/build/tkogl2.dll"
tcl("load", dll, "Tkogl2")   # empty string = success
```

Then run Step A.

### Step D — Developer workflow (live R edits)

Match `startGUI.R`: after `load_all(".")`, source the `R/*.r` files and call `ui(e); init(e)`.

---

## Risks and open questions

| Risk | Detail | Mitigation |
|------|--------|------------|
| WSL path I/O | Reading package/DLL over `\\wsl.localhost\` can be slow or flaky | Copy repo to `C:\dev\GUImorph` if issues appear |
| Stale 2020 DLL vs new build | Prebuilt zip / `inst/libs` may not include ZARF_9 C changes | Deploy `build/tkogl2.dll` before testing C edits |
| Tcl stub ABI | `tcl_stub_bootstrap.c` reads `Interp::stubTable` without full `tclInt.h` | Validate with `tcl("load", ...)` smoke test |
| GLUT runtime | Links against vendored `glut64.dll` | Ensure DLL is on PATH or beside `tkogl2.dll` |
| R 4.6 vs package age | GUImorph last released ~2020 | Watch for deprecation warnings; deps already on 4.6 |

---

## Phase checklist

| Milestone | Status |
|-----------|--------|
| Install Windows R | ✅ |
| Install CRAN dependencies | ✅ |
| Set working directory to package | ✅ |
| Load/install GUImorph package | ❌ |
| Load `tkogl2.dll` via Tcl | ⏳ |
| Launch "3D GUImorph" GUI | ⏳ |
| Build new `tkogl2.dll` (MinGW) | ✅ |
| Verify `Tkogl2_Init` export | ✅ |
| Runtime load + GUI end-to-end | ⏳ |

---

## References

- Package entry point: `GUImorphDevelopment/R/rtkogl.R` → `GUImorph()`
- Dev launcher: `GUImorphDevelopment/startGUI.R`
- Native build docs: `Project/tkogl2/BUILD.md`
- VS legacy build (optional): `Project/tkogl2/tkogl2.sln` (Debug \| x64 → `inst/libs/x64/`)
