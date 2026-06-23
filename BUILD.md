# Building and developing GUImorph

GUImorph is an R package with a native **Windows DLL** (`tkogl2.dll`) loaded at runtime
via Tcl/Tk. **End users** can run the GUI without building anything — see [README.md](README.md).

This guide is for **contributors** who change C/OpenGL code or maintain the toolchain.

> **Toolchain note (2026-06):** Build `tkogl2.dll` with **MSVC** (the toolchain that
> produced the original working DLL). MinGW-w64 builds (WSL cross-compile *or* MSYS2
> native) currently link successfully but **render incorrectly** (black/blank mesh), so
> they are not supported for distribution. See `.planning/smoke-test-findings.md`.

> **DLL in the repo:** A prebuilt MSVC `tkogl2.dll` is **committed** under
> `GUImorphDevelopment/inst/libs/x64/` so clones work out of the box. `.gitignore` lists
> `tkogl2.dll` to prevent *new* build artifacts from being accidentally committed, but the
> shipped runtime DLL remains tracked. Rebuild and redeploy only when you change C sources.

**Package root** (all paths below are relative to repo root):

```
integrated-guimorph-development_EOC/Project/GUImorphDevelopment/
```

WSL is **not** required. The default path assumes a normal Windows clone (e.g. `C:\dev\GUImorph`).

For compile internals, see
[`integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md`](integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md).

---

## 1. Prerequisites (contributors)

| Tool | Install | End users need this? |
|------|---------|-------------------|
| **Windows 10+** | — | Yes |
| **R 4.6+** | `winget install -e --id RProject.R` | Yes |
| **Git** | `winget install -e --id Git.Git` | Yes (clone) |
| **VS Build Tools** (MSVC) | `winget install -e --id Microsoft.VisualStudio.2022.BuildTools --override "--quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"` | No — only for C changes |
| **CMake** | `winget install -e --id Kitware.CMake` | No — only for C changes |

```powershell
git clone https://github.com/dreoc/GUImorph.git C:\dev\GUImorph
cd C:\dev\GUImorph
```

After installing R via winget, restart your terminal so `R` and `Rscript` are on `PATH`.

---

## 2. Native build (Windows — MSVC)

Only needed when modifying `tkogl2` C sources. `build-msvc/` is **gitignored** — you must
**configure once** before building.

Open a **Developer PowerShell for VS** (or any PowerShell after running `vcvars64.bat`):

```powershell
cd C:\dev\GUImorph\integrated-guimorph-development_EOC\Project\tkogl2
cmake -B build-msvc -G "Visual Studio 17 2022" -A x64
cmake --build build-msvc --config Release
```

On success the DLL is at **`build-msvc\Release\tkogl2.dll`**. All required import libraries
(`tclstub86_64.lib`, `glut64.lib`) and the GL/glut shim are vendored in-tree — no extra
SDK setup beyond VS Build Tools is needed. The CRT is statically linked, so the DLL is
self-contained (no VC++ redistributable required on end-user machines).

> **MinGW is not supported for distribution.** MinGW-w64 paths (MSYS2 native or WSL
> cross-compile via `cmake/mingw-w64-x86_64.cmake`) build but render a black/blank mesh.
> Use the MSVC path above.

---

## 3. DLL deploy

Deploy **`tkogl2.dll` only** — `glut64.dll` is already bundled under `inst/libs/x64/`.

### Script (recommended)

From the **repo root** in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/deploy-dll.ps1
```

The script:

- Defaults to MSVC `build-msvc/Release/tkogl2.dll`, then falls back to MinGW `build/tkogl2.dll`
- Accepts an explicit path: `powershell -ExecutionPolicy Bypass -File scripts/deploy-dll.ps1 -Source "path\to\tkogl2.dll"`
- Backs up the current DLL to `inst/libs/x64/tkogl2.dll.bak` before overwrite (backup is gitignored)
- Copies the build artifact to `GUImorphDevelopment/inst/libs/x64/tkogl2.dll`

> **Rollback:** If the viewer is blank after deploy, restore the backup:
> `Copy-Item integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll.bak integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll -Force`

### Manual fallback

```powershell
$Src = "integrated-guimorph-development_EOC/Project/tkogl2/build-msvc/Release/tkogl2.dll"
$Dest = "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll"
Copy-Item $Dest "$Dest.bak" -ErrorAction SilentlyContinue
Copy-Item $Src $Dest -Force
```

---

## 4. R environment (renv)

**renv** lives in `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`.
`renv.lock` is committed for reproducible dependency versions.

Restore path is **Windows R only** — the GUI and `tkogl2.dll` require Windows.

**Minimum R:** 4.6+. Minor R patch differences during restore are acceptable.

### Contributor restore (daily workflow)

```r
setwd("C:/dev/GUImorph/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
renv::restore()
devtools::load_all(".")
GUImorph()
```

### First-time renv bootstrap (maintainer only)

Run once when (re)initializing the lockfile — not needed for normal contributors:

```powershell
cd C:\dev\GUImorph
& "C:\Program Files\R\R-4.6.0\bin\R.exe" --vanilla -f scripts/init-renv.R
```

Or from an interactive R session in the package directory:

```r
setwd("C:/dev/GUImorph/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
source("../../../scripts/init-renv.R")
```

This installs DESCRIPTION Imports plus workflow extras (`devtools`, `rgl`, `RRPP`), runs
`load_all` smoke, then `renv::init()` + `renv::snapshot()`. Commit updated `renv.lock`,
`.Rprofile`, and `renv/` scaffold files.

---

## 5. Smoke test

| Change type | Verify |
|-------------|--------|
| R-only edits | `load_all` + affected GUI path |
| C / `tkogl2` edits | Rebuild → deploy → full GUI smoke below |

**Full GUI smoke (post-deploy):**

```r
setwd("C:/dev/GUImorph/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
renv::restore()
devtools::load_all(".")
GUImorph()
# Load a sample PLY (e.g. bundled test data or local C13.1.ply)
```

Confirm:

1. Console shows `tkogl2` load path from `.onLoad` (no failure warning)
2. "3D GUImorph" window opens
3. Specimen mesh renders (not blank/black)

---

## 6. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `loading tkogl2 failed` | DLL missing or wrong arch | Re-clone (DLL is in repo) or rebuild + deploy per §2–3 |
| `build-msvc` not found | Configure step skipped | Run `cmake -B build-msvc ...` before `cmake --build` |
| `R` not found after winget | PATH not refreshed | Restart terminal; or use full path to `R.exe` |
| `rgl` missing after restore | Lockfile not restored | `renv::restore()` from package root |
| `file.info` / “cannot resolve owner” on `\\wsl$\...` | WSL UNC path metadata | Harmless; prefer `C:\dev\GUImorph\...` clone |
| Landmarks don't appear on click | UX — single-click is pick | **Double-click** canvas to place landmarks |
| 26+ warnings on `load_all` | Pre-renv baseline | See `.planning/smoke-test-findings.md` Phase 6 section |

For maintainer UAT history and warning triage, see `.planning/smoke-test-findings.md`.

---

## C source layout (Phase 9)

Modular `tkogl2` layout after Phase 7 split, Phase 8 marker unification, and Phase 9
globals/debug cleanup. The god file `tcl_if_ZARF_9.c` is **removed from the CMake build**
(not a source file). Orphan `*.c.bak` / `*.dll.pre-phase*.bak` files under `src/` or
`inst/libs/x64/` are local rollback artifacts (gitignored) and can be deleted.

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

---

## 7. Advanced: WSL cross-compile

Maintainers may cross-compile from WSL using the Linux-host toolchain file. This is **not**
the contributor default and produces a DLL that **does not render correctly** on Windows.

See **Advanced: WSL Cross-Compile** in
[`tkogl2/BUILD.md`](integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md).

---

*Contributor guide — v1.0. Last updated: 2026-06-23.*
