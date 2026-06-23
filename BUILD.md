# Building and developing GUImorph

GUImorph is an R package with a native **Windows DLL** (`tkogl2.dll`) loaded at runtime
via Tcl/Tk. Contributors need **Windows R 4.6+**, a **Windows-native MSVC build** of
`tkogl2`, and a reproducible R library via **renv**.

> **Toolchain note (2026-06):** Build `tkogl2.dll` with **MSVC** (the toolchain that
> produced the original working DLL). MinGW-w64 builds (WSL cross-compile *or* MSYS2
> native) currently link successfully but **render incorrectly** (black/blank mesh), so
> they are not supported for distribution. See `.planning/smoke-test-findings.md`.

> **Important:** `tkogl2.dll` is **gitignored** and not committed. A fresh clone plus
> `renv::restore()` alone does **not** provide a working GUI — you must **build and deploy**
> the DLL (or copy a maintainer-built artifact) before `GUImorph()` can open the 3D viewer.

WSL is **not** required for contributors. The default path below assumes a normal Windows
clone (e.g. `C:\dev\GUImorph`).

For compile internals, see
[`integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md`](integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md).

---

## 1. Prerequisites

| Tool | Install |
|------|---------|
| **Windows 10+** | — |
| **R 4.6+** | `winget install -e --id RProject.R` |
| **Git** | `winget install -e --id Git.Git` |
| **VS Build Tools** (MSVC C compiler) | `winget install -e --id Microsoft.VisualStudio.2022.BuildTools --override "--quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"` |
| **CMake** | `winget install -e --id Kitware.CMake` |

Clone this repository to a **Windows path** (not a WSL-only mount if you can avoid it):

```powershell
git clone <repo-url> C:\dev\GUImorph
cd C:\dev\GUImorph
```

After installing R via winget, restart your terminal so `R` and `Rscript` are on `PATH`.

---

## 2. Native build (Windows — MSVC, primary)

Open a **Developer PowerShell for VS** (or any PowerShell after running the VS
`vcvars64.bat`), then configure and build from the `tkogl2` project directory:

```powershell
cd C:\dev\GUImorph\integrated-guimorph-development_EOC\Project\tkogl2
cmake -B build-msvc -G "Visual Studio 17 2022" -A x64
cmake --build build-msvc --config Release
```

On success the DLL is at **`build-msvc\Release\tkogl2.dll`** (multi-config generators
place output under the config subfolder). All required import libraries
(`tclstub86_64.lib`, `glut64.lib`) and the GL/glut shim are vendored in-tree — no extra
SDK setup beyond VS Build Tools is needed. The CRT is statically linked, so the DLL is
self-contained (no VC++ redistributable required on end-user machines).

> **MinGW is not supported for distribution.** The MinGW-w64 paths (MSYS2 native or the
> WSL cross-compile via `cmake/mingw-w64-x86_64.cmake`) build but render a black/blank
> mesh. Use the MSVC path above.

---

## 3. DLL deploy (DEV-03)

Deploy **`tkogl2.dll` only** — `glut64.dll` is already bundled under `inst/libs/x64/`.

### Script (recommended)

From the **repo root** in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/deploy-dll.ps1
```

The script:

- Defaults to MSVC `build-msvc/Release/tkogl2.dll`, then falls back to MinGW `build/tkogl2.dll`
- Accepts an explicit path: `powershell -ExecutionPolicy Bypass -File scripts/deploy-dll.ps1 -Source "path\to\tkogl2.dll"`
- Backs up the current DLL to `inst/libs/x64/tkogl2.dll.bak` before overwrite
- Copies the build artifact to `GUImorphDevelopment/inst/libs/x64/tkogl2.dll`

> **Rollback:** If the viewer is blank after deploy, restore the backup:
> `Copy-Item inst/libs/x64/tkogl2.dll.bak inst/libs/x64/tkogl2.dll -Force`
> Only deploy after UAT confirms mesh + `.dgt` render on your machine.

### Manual fallback

```powershell
# MSVC build output (primary)
$Src = "integrated-guimorph-development_EOC/Project/tkogl2/build-msvc/Release/tkogl2.dll"
$Dest = "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll"
Copy-Item $Dest "$Dest.bak" -ErrorAction SilentlyContinue
Copy-Item $Src $Dest -Force
```

To roll back: copy `tkogl2.dll.bak` back to `tkogl2.dll`.

---

## 4. R environment (DEV-01)

**renv** lives in `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`.

Restore path is **Windows R only** — the GUI and `tkogl2.dll` require Windows.

**Minimum R:** 4.6+. Minor R patch differences during restore are acceptable.

### First-time setup (maintainer / after clone)

From repo root in PowerShell (must `cd` to the repo first — do not run from `C:\Users\akagi`):

```powershell
cd \\wsl$\Ubuntu\home\akagi\home\GUImorph
& "C:\Program Files\R\R-4.6.0\bin\R.exe" --vanilla -f scripts/init-renv.R
```

**Alternative** — from an interactive R session already in the package directory:

```r
setwd("//wsl$/Ubuntu/home/akagi/home/GUImorph/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
source("../../../scripts/init-renv.R")
```

This installs DESCRIPTION Imports plus workflow extras (`devtools`, `rgl`, `RRPP`), runs
`load_all` smoke, then `renv::init()` + `renv::snapshot()`. Commit the generated
`renv.lock`, `.Rprofile`, and `renv/` scaffold files.

### Contributor restore

In R, set working directory to the package root:

```r
setwd("C:/dev/GUImorph/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
renv::restore()
devtools::load_all(".")
```

---

## 5. Smoke test

**Targeted verification (D-12):**

| Change type | Verify |
|-------------|--------|
| R-only edits | `load_all` + affected GUI path |
| C / `tkogl2` edits | Rebuild → deploy → full GUI smoke below |

**Full GUI smoke (post-deploy, D-16):**

```r
setwd("C:/dev/GUImorph/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
renv::restore()
devtools::load_all(".")
GUImorph()
# Load a sample PLY (e.g. bundled test data or local C13.1.ply)
```

Confirm:

1. Console shows `tkogl2` load confirmation from `.onLoad`
2. "3D GUImorph" window opens
3. Specimen mesh renders (not blank/black)

---

## 6. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `tkogl2` load failure | DLL missing or wrong arch | Build + deploy per sections 2–3 |
| `R` not found after winget | PATH not refreshed | Restart terminal; or use full path to `R.exe` |
| `rgl` missing after restore | Lockfile not restored | `renv::restore()` from package root |
| `file.info` / “cannot resolve owner” on `\\wsl$\...` | WSL UNC path metadata (maintainer setup) | **DEFERRED** — harmless; use `C:\dev\GUImorph\...` clone to avoid |
| Landmarks don't appear on click | UX — single-click is pick | **Double-click** canvas to place landmarks |
| 26+ warnings on `load_all` | Pre-renv baseline | See `.planning/smoke-test-findings.md` Phase 6 section |

For maintainer UAT history and warning triage, see `.planning/smoke-test-findings.md`.

---

## C source layout (Phase 9)

Modular `tkogl2` layout after Phase 7 split, Phase 8 marker unification, and Phase 9
globals/debug cleanup. The god file `tcl_if_ZARF_9.c` is **removed from the CMake build**
(not a source file). An orphan `tcl_if_ZARF_9.c.bak` may remain under `src/` and can be
deleted. The reference-only `.vcxproj` is not used for builds — **CMake + MSVC only**.

| File | Responsibility |
|------|----------------|
| `tcl_init.c` | `Tkogl2_Init`; registers 8 Tcl commands (`add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`) |
| `tcl_dispatch.c` | Tcl handlers, draw pass (`drawDots`/`onDisplay`), `Wrapper_Get*` helpers |
| `tcl_window.c` | `setWindowId`, HWND/WGL setup, `dc`/`width`/`height`, `setWindow` |
| `tcl_state.c` | Globals (capacity-`#define`d `GBL_PTR_*` arrays), `initialize_state`, `resetContext`, alloc wrappers |
| `tcl_log.c` | `simpleLog*`, command stream, file writers (the surviving diagnostic channel) |
| `marker.c` | Unified `marker_*` core + `g_landmarks`/`g_anchors` + `dot_*`/`anchor_*` wrappers (Phase 8) |
| `curve_ZARF_9.c` | Curve geometry/state |
| `ogl_ZARF9.c`, `ogl_model_ZARF_9.c`, `ogl_model_ply_ZARF_9.c` | OpenGL init/draw + PLY/`.dgt` model loading |
| `StatisticsFunction_ZARF_9.c` | Vertex statistics |

**Removed from build:** `tcl_if_ZARF_9.c` (god file), `dot_ZARF_9.c` (replaced by `marker.c` in Phase 8).

**Rollback DLL convention:** before Phase 9 refactors, copy deployed DLL to
`inst/libs/x64/tkogl2.dll.pre-phase9.bak` (see Phase 9 plan 09-01).

---

## 7. Advanced: WSL cross-compile

Maintainers may cross-compile from WSL using the Linux-host toolchain file. This is **not**
the contributor default.

See **Advanced: WSL Cross-Compile** in
[`tkogl2/BUILD.md`](integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md).

---

*Phase 9 — C engine cleanup & validation. Last updated: 2026-06-22.*
