# Phase 6: Reproducible Dev Environment - Pattern Map

**Mapped:** 2026-06-19
**Files analyzed:** 11
**Analogs found:** 8 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `GUImorphDevelopment/renv.lock` | config | batch (lock snapshot) | `DESCRIPTION` + RESEARCH Pattern 1 | partial |
| `GUImorphDevelopment/.Rprofile` | config | event-driven (R startup) | RESEARCH Pattern 1 (renv scaffold) | no analog |
| `GUImorphDevelopment/renv/activate.R` | config | event-driven (library bootstrap) | RESEARCH Pattern 1 (renv scaffold) | no analog |
| `GUImorphDevelopment/.Rbuildignore` | config | transform (exclude from tarball) | self (`.Rbuildignore`) | exact |
| `BUILD.md` (repo root) | config/docs | file-I/O (contributor guide) | `tkogl2/BUILD.md` | role-match |
| `scripts/deploy-dll.ps1` | utility | file-I/O (DLL copy + backup) | `.gitignore` deploy policy + RESEARCH Pattern 3 | partial |
| `README.md` | config/docs | file-I/O (quick-start pointer) | self + `.planning/smoke-test-findings.md` quirks | partial |
| `tkogl2/BUILD.md` | config/docs | file-I/O (compile deep-dive) | self | exact |
| `.planning/smoke-test-findings.md` | documentation | transform (append-only) | self (Phase 4–5 sections) | exact |
| `GUImorphDevelopment/DESCRIPTION` | model | CRUD (dependency manifest) | self | exact (reference) |
| `GUImorphDevelopment/R/rtkogl.R` | utility | request-response (DLL load) | self (`.onLoad`) | exact (reference) |

**Canonical package root:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`

---

## Pattern Assignments

### `GUImorphDevelopment/renv.lock` + `.Rprofile` + `renv/activate.R` (config, batch + event-driven)

**Analog:** `DESCRIPTION` (dependency seed) + RESEARCH Pattern 1 (init/snapshot/restore workflow)

No committed renv scaffolding exists in the repo yet. Copy the **workflow order** from RESEARCH, not a hand-rolled lockfile.

**Dependency seed from DESCRIPTION** (lines 9–16):

```9:16:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION
Imports:
    geomorph,
    Morpho,
    parallel,      
    Rvcg,
    tcltk,
    tcltk2,
    vegan
```

**Workflow extras to install before snapshot** (D-02, not in DESCRIPTION today):

```r
install.packages(c(
  "geomorph", "Morpho", "Rvcg", "vegan", "tcltk2",
  "devtools", "rgl", "RRPP", "renv"
))
```

**Init/snapshot pattern** (from RESEARCH Pattern 1 — run on Windows R after full smoke):

```r
setwd("C:/path/to/repo/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
devtools::load_all(".")
GUImorph()  # PLY + optional GPA path before lock

renv::init(settings = list(ignored.packages = "devtools"))
renv::snapshot()
```

**Restore pattern for BUILD.md** (contributor path):

```r
setwd("C:/path/to/repo/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
renv::restore()
devtools::load_all(".")
```

**Files to commit** (renv collaborating vignette, echoed in RESEARCH): `renv.lock`, `.Rprofile`, `renv/activate.R`, `renv/settings.dcf` (if created). Do **not** commit `renv/library/`.

**`.Rprofile` scaffold** (standard renv output — planner generates via `renv::init()`, do not hand-write):

```r
source("renv/activate.R")
```

---

### `GUImorphDevelopment/.Rbuildignore` (config, transform)

**Analog:** self

**Existing pattern** (lines 1–2):

```1:2:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/.Rbuildignore
^.*\.Rproj$
^\.Rproj\.user$
```

**Add after `renv::init()` scaffold** (renv packages vignette — auto-added by scaffold; verify present):

```
^renv$
^renv\.lock$
```

Keep existing entries; append renv lines only if scaffold did not run.

---

### `BUILD.md` (repo root) (config/docs, file-I/O)

**Analog:** `integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md`

Copy the **section structure and tone** from the existing compile doc: title + one-line scope, numbered prerequisites, numbered build steps, dependency table, notes/fallback, link-out to deep-dive.

**Doc header + scope pattern** (lines 1–6):

```1:6:integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md
# Building `tkogl2.dll` (MinGW-w64 cross-compile from WSL)

`tkogl2` is the C/OpenGL engine for GUImorph, compiled as a **Windows DLL** and
loaded by Windows-R through Tcl/Tk. It is Windows-only by design (it creates an
OpenGL context on a Tk widget's `HWND` via WGL), so we cross-compile a Windows
DLL from WSL using MinGW-w64 rather than building a Linux `.so`.
```

Root `BUILD.md` should mirror this clarity but cover the **full contributor cycle** (D-05): Prerequisites → Native build → DLL deploy → R environment → Smoke test → Troubleshooting → link to `tkogl2/BUILD.md`.

**Numbered build steps pattern** (lines 8–31):

```8:31:integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md
## 1. Install the toolchain (once)

```bash
sudo apt update
sudo apt install -y mingw-w64 mingw-w64-tools cmake make
```

Verify:

```bash
x86_64-w64-mingw32-gcc --version
cmake --version
```

## 2. Configure & build

From this directory (`integrated-guimorph-development_EOC/Project/tkogl2`):

```bash
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake
cmake --build build -j
```

On success you get **`build/tkogl2.dll`**.
```

Root doc **Primary Native Build** section replaces WSL commands with MSYS2 UCRT64 (RESEARCH Pattern 2):

```bash
pacman -S --needed mingw-w64-ucrt-x86_64-toolchain cmake make
cd /c/path/to/GUImorph/integrated-guimorph-development_EOC/Project/tkogl2
cmake -B build -S . -G "MinGW Makefiles"
cmake --build build -j
```

**Dependency table pattern** (lines 47–53):

```47:53:integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md
## Dependencies

| Library                         | Source                                            |
| ------------------------------- | ------------------------------------------------- |
| `opengl32`, `glu32`, `gdi32`, `user32` | MinGW-w64 (system import libs)              |
| Tcl 8.6 stub                    | **`src/tcl_stub_bootstrap.c`** (compiled into the DLL) |
| GLUT (`glut64.dll`)             | vendored in `lib/`, linked directly               |
```

Reuse for Prerequisites (R 4.6+, MSYS2, winget one-liners per D-10).

**Notes / artifact policy pattern** (lines 86–91):

```86:91:integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md
## Notes

- `build/` is a throwaway directory and is git-ignored.
- The produced `tkogl2.dll` is a release artifact and is **not** committed.
- Functional testing (loading the DLL into R) is a later step once R is
  installed; this stage only proves the engine compiles and links.
```

Root `BUILD.md` must state explicitly: **`tkogl2.dll` is gitignored** — clone + `renv::restore()` alone does not provide the DLL (RESEARCH Pitfall 1).

**Prerequisites one-liner** (D-10, from RESEARCH):

```powershell
winget install -e --id RProject.R
winget install -e --id MSYS2.MSYS2
```

**Smoke test pattern** (from validated workflow in `.planning/PROJECT.md` lines 19–20):

```
build/tkogl2.dll → inst/libs/x64/tkogl2.dll → devtools::load_all(".") → GUImorph() → load PLY
```

**Targeted verification** (D-12): document two paths — R-only edits need `load_all` + affected GUI path; C edits need rebuild → deploy → full GUI smoke.

---

### `scripts/deploy-dll.ps1` (utility, file-I/O)

**Analog:** RESEARCH Pattern 3 + `.gitignore` deploy policy

No `.ps1` files exist in the repo. Do **not** copy `scripts/guimorph-startup.R` (WSL UNC `setwd` — maintainer-local anti-pattern per D-08/D-09).

**Git policy — deploy target path** (lines 66–74):

```66:74:.gitignore
# Release artifacts WE build (do NOT track).
# Named explicitly so vendored third-party .dll/.lib are still tracked.
# ===========================================================================
tkogl2.dll
tkogl2_old.dll
tkogl2.lib
tkogl2.exp
tkogl2.pdb
*.pdb
```

**Deploy path mapping** (from PROJECT.md + CONTEXT):

| Source | Destination |
|--------|-------------|
| `integrated-guimorph-development_EOC/Project/tkogl2/build/tkogl2.dll` | `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll` |

**Do not deploy** `glut64.dll` (D-15) — only `tkogl2.dll`; `glut64.dll` stays tracked in `inst/libs/x64/`.

**Core script pattern** (RESEARCH Pattern 3 — copy structure):

```powershell
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Src  = Join-Path $RepoRoot "integrated-guimorph-development_EOC/Project/tkogl2/build/tkogl2.dll"
$DestDir = Join-Path $RepoRoot "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64"
$Dest = Join-Path $DestDir "tkogl2.dll"
$Backup = Join-Path $DestDir "tkogl2.dll.bak"

if (-not (Test-Path $Src)) { throw "Build output not found: $Src" }
if (Test-Path $Dest) { Copy-Item -Path $Dest -Destination $Backup -Force }
Copy-Item -Path $Src -Destination $Dest -Force
```

**Manual fallback for BUILD.md** (same RESEARCH section):

```powershell
Copy-Item -Force `
  integrated-guimorph-development_EOC/Project/tkogl2/build/tkogl2.dll `
  integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll
```

**Post-deploy verification** (D-16): `load_all` + `GUImorph()` + load sample PLY — not export-check alone.

---

### `README.md` (config/docs, file-I/O)

**Analog:** self (minimal) + `.planning/smoke-test-findings.md` (quirks inventory)

**Existing README** — keep title/description block; add quick-start + quirks only (D-06/D-08):

```1:2:README.md
# GUImorph, a Graphical User Interface to R functions to conduct 3D GM
GUImorph, A User-Friendly R Package with a Graphical User Interface to Digitize & Conduct Geometric Morphometric Analyses of 2D and 3D: Landmark-based Geometric Morphometrics (GM) is a prominent approach used to quantify shape variation and its covariation with other variables. We developed GUImorph, the first user-friendly R package featuring a Graphical User Interface (GUI) to (i) digitize 2D landmarks and sliding semi-landmarks, as well as 3D landmarks and sliding curve and surface semi-landmarks and (ii) conduct 2D and 3D GM analyses on landmarks and sliding curve and surface semi-landmarks. GUImorph is easy to use and provides needed tools for paleoanthropologists interested in quantifying the complete shape variation of objects, and in evaluating hypotheses regarding shape co-variation with other variables of interest.
```

**Quick-start outline** (RESEARCH — 5 steps, link to BUILD.md, no inline duplication):

```markdown
1. Install R 4.6+ and clone this repo to a Windows path.
2. Follow [BUILD.md](BUILD.md) to build and deploy `tkogl2.dll`.
3. Open R in `GUImorphDevelopment/` and run `renv::restore()`.
4. Run `devtools::load_all(".")` then `GUImorph()`.
5. Load a `.ply` specimen; see **Known behavior** below for UI quirks.
```

**Known behavior quirks** (from smoke-test-findings — D-08, document only):

| Quirk | Source |
|-------|--------|
| Double-click canvas to place landmarks; single-click is pick/select | smoke-test lines 11–12, 53–61 |
| Fit button may show no visible change at default rotation/zoom | smoke-test lines 82–88 |
| Curves are chord segments between 3 landmark IDs, not splines | smoke-test lines 87–88 |
| GPA Plot may need `rgl`; Alt+Tab if plot window behind Tk GUI | Phase 5 section |

**Anti-pattern:** Do not document WSL/UNC paths or `scripts/guimorph-startup.R` as contributor defaults.

---

### `tkogl2/BUILD.md` (config/docs update, file-I/O)

**Analog:** self — restructure, do not replace wholesale

**Keep:** dependency table, Tcl stub rationale, GLUT fallback, notes on `build/` throwaway.

**Change for D-11:**
1. Add **Windows-native MSYS2 UCRT64** as primary `## 2. Configure & build` (no `-DCMAKE_TOOLCHAIN_FILE`).
2. Move existing WSL cross-compile block to **Advanced: WSL Cross-Compile** appendix with explicit toolchain file:

```1:6:integrated-guimorph-development_EOC/Project/tkogl2/cmake/mingw-w64-x86_64.cmake
# CMake toolchain file: cross-compile a Windows x86_64 DLL from WSL/Linux
# using the MinGW-w64 toolchain.
#
# Usage:
#   cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake
```

**Warning:** Linux-only sysroot (line 21) — must not be used on Windows:

```20:21:integrated-guimorph-development_EOC/Project/tkogl2/cmake/mingw-w64-x86_64.cmake
# Where the target environment lives (MinGW sysroot).
set(CMAKE_FIND_ROOT_PATH /usr/${TOOLCHAIN_PREFIX})
```

Update `CMakeLists.txt` header comment (lines 6–14) in a later task if it still says WSL-only — currently documents WSL path only:

```6:14:integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt
# This is a WINDOWS DLL (the engine embeds OpenGL into a Tk widget's HWND via
# WGL, so it cannot build as a native Linux .so). The supported build path is
# a MinGW-w64 cross-compile from WSL/Linux:
#
#   sudo apt install mingw-w64 mingw-w64-tools cmake
#   cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake
#   cmake --build build -j
#
# Produces: build/tkogl2.dll  (loaded by Windows-R via `tcl("load", ..., "Tkogl2")`)
```

---

### `GUImorphDevelopment/R/rtkogl.R` (reference — deploy target)

**Analog:** self (`.onLoad` — no changes expected in Phase 6)

**DLL resolution path** (lines 457–482):

```457:482:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
.onLoad <- function(libname, pkgname)
{
  chname <- "tkogl2"
  file.ext <- .Platform$dynlib.ext #dll file
  dlname <- paste(chname, file.ext, sep = "")

  if (is.character(.Platform$r_arch) && .Platform$r_arch != "")
  {
    path <- file.path("libs", .Platform$r_arch, dlname)
  }
  else
  {
    path <- file.path("libs", dlname)
  }

  file <-
    system.file(path, package = pkgname, lib.loc = libname)[1] #grabs full file name

  print("File 3dDigitize.main ... function .onload")
  print(file)
  print("-----------------")
  tryCatch(
    tcl("load", file, "Tkogl2"),
    error = function(e)
      warning("loading tkogl2 failed", call. = FALSE)
  ) #replace directory with file
}
```

Deploy script must place DLL at `inst/libs/x64/tkogl2.dll` so `system.file("libs/x64/tkogl2.dll", ...)` resolves. Failure symptom: `warning("loading tkogl2 failed")` at line 481.

**Console confirmation pattern** (smoke-test lines 152–158):

```
[1] ".../inst/libs/x64/tkogl2.dll"
[1] "-----------------"
There were 26 warnings (use warnings() to see them)
```

---

### `.planning/smoke-test-findings.md` (documentation, append-only)

**Analog:** self (Phase 4–5 append pattern)

**Append structure** (from 04-PATTERNS):

```markdown
## Phase 6 — renv Baseline + Warning Triage (06-01)

**Date:** YYYY-MM-DD
**Environment:** Windows R 4.6+, normal Windows path (not WSL default)
**Lockfile:** GUImorphDevelopment/renv.lock (first snapshot)

| Step | Result |
|------|--------|
| `renv::restore()` | ✅/❌ |
| `devtools::load_all(".")` | ✅/❌ |
| `warnings()` captured | ✅ count + classification |
| HOT fixes applied | list or "none" |
```

**Warning triage pattern** (RESEARCH Pattern 4):

```r
devtools::load_all(".")
w <- warnings()
# HOT: load_all error, missing symbol, tkogl2 load failure, gpagen failure
# DEFERRED: roxygen, deprecated API, documentation gaps
```

Append only — do not rewrite Phase 1–5 sections (same rule as Phase 4 PATTERNS line 524).

---

## Shared Patterns

### Windows R development cwd
**Source:** validated Phases 2–5 + `scripts/guimorph-startup.R` (path only — use normal Windows path in docs)
**Apply to:** renv init, restore, BUILD.md smoke test, README quick-start

```r
setwd("C:/path/to/repo/integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
devtools::load_all(".")
```

### DLL build → deploy → load chain
**Source:** `.planning/PROJECT.md` + `rtkogl.R` `.onLoad`
**Apply to:** BUILD.md, deploy-dll.ps1, tkogl2/BUILD.md notes

```
tkogl2/build/tkogl2.dll  --deploy-->  GUImorphDevelopment/inst/libs/x64/tkogl2.dll  --.onLoad-->  tcl("load", ..., "Tkogl2")
```

### Git artifact policy
**Source:** `.gitignore`
**Apply to:** BUILD.md prerequisites, deploy script, contributor expectations

- **Tracked:** `inst/libs/x64/glut64.dll` (vendored)
- **Not tracked:** `tkogl2.dll` anywhere (pattern `tkogl2.dll`), `build/` dirs, `renv/library/`

### Contributor doc voice
**Source:** `tkogl2/BUILD.md`
**Apply to:** root BUILD.md, README Known behavior

- Numbered sections with verify steps
- Explicit "what this proves" / notes
- Windows-first paths; WSL/UNC optional appendix only
- No maintainer-local scripts as templates

### Smoke-test documentation
**Source:** `.planning/smoke-test-findings.md`
**Apply to:** Phase 6 warning baseline (D-20), README quirks (D-18), BUILD.md troubleshooting

- Session summary tables with ✅/⚠️/❌
- Separate **Validated** vs **Not yet validated**
- Console snippets for reproducibility
- UX quirks marked "document only — not code fix"

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `GUImorphDevelopment/.Rprofile` | config | event-driven | No renv project in repo; use `renv::init()` scaffold output |
| `GUImorphDevelopment/renv/activate.R` | config | event-driven | Generated by renv; do not hand-author |
| `scripts/deploy-dll.ps1` | utility | file-I/O | No PowerShell scripts in repo; follow RESEARCH Pattern 3 + `.gitignore` paths |

Planner should use RESEARCH.md Patterns 1–4 for these files when no codebase analog exists.

---

## Metadata

**Analog search scope:** repo root, `scripts/`, `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`, `integrated-guimorph-development_EOC/Project/tkogl2/`, `.planning/`, `.gitignore`
**Files scanned:** ~25 (docs, R package config, C build, planning artifacts)
**Pattern extraction date:** 2026-06-19
