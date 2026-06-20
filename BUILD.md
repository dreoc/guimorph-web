# Building and developing GUImorph

GUImorph is an R package with a native **Windows DLL** (`tkogl2.dll`) loaded at runtime
via Tcl/Tk. Contributors need **Windows R 4.6+**, a **Windows-native MinGW build** of
`tkogl2`, and a reproducible R library via **renv**.

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
| **MSYS2** (native C build) | `winget install -e --id MSYS2.MSYS2` |

Clone this repository to a **Windows path** (not a WSL-only mount if you can avoid it):

```powershell
git clone <repo-url> C:\dev\GUImorph
cd C:\dev\GUImorph
```

After installing R via winget, restart your terminal so `R` and `Rscript` are on `PATH`.

---

## 2. Native build (Windows — primary)

Open the **MSYS2 UCRT64** shell (Start → MSYS2 UCRT64).

Install the toolchain once:

```bash
pacman -S --needed mingw-w64-ucrt-x86_64-toolchain cmake make
```

Configure and build from the `tkogl2` project directory:

```bash
cd /c/dev/GUImorph/integrated-guimorph-development_EOC/Project/tkogl2
cmake -B build -S . -G "MinGW Makefiles"
cmake --build build -j
```

On success you get **`build/tkogl2.dll`**.

> Do **not** use `cmake/mingw-w64-x86_64.cmake` on Windows — that file is for **WSL
> cross-compile** only (Linux sysroot paths).

---

## 3. DLL deploy (DEV-03)

Deploy **`tkogl2.dll` only** — `glut64.dll` is already bundled under `inst/libs/x64/`.

### Script (recommended)

From the **repo root** in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/deploy-dll.ps1
```

The script:

- Validates `integrated-guimorph-development_EOC/Project/tkogl2/build/tkogl2.dll` exists
- Backs up the current DLL to `inst/libs/x64/tkogl2.dll.bak` before overwrite
- Copies the build artifact to `GUImorphDevelopment/inst/libs/x64/tkogl2.dll`

> **Rollback:** If the viewer is blank after deploy, restore the backup:
> `Copy-Item inst/libs/x64/tkogl2.dll.bak inst/libs/x64/tkogl2.dll -Force`
> Only deploy from `build/` after UAT confirms mesh + `.dgt` render on your machine.

### Manual fallback

```powershell
$Src = "integrated-guimorph-development_EOC/Project/tkogl2/build/tkogl2.dll"
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

## 7. Advanced: WSL cross-compile

Maintainers may cross-compile from WSL using the Linux-host toolchain file. This is **not**
the contributor default.

See **Advanced: WSL Cross-Compile** in
[`tkogl2/BUILD.md`](integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md).

---

*Phase 6 — reproducible dev environment. Last updated: 2026-06-19.*
