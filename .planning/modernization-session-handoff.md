# GUImorph Modernization — Session Handoff

**Restored from agent transcript:** `e7bdb991-33c4-49a2-ac4b-a1bccd548453`  
**Raw transcript (full conversation):**  
`C:\Users\akagi\.cursor\projects\wsl-Ubuntu-home-akagi-home-GUImorph\agent-transcripts\e7bdb991-33c4-49a2-ac4b-a1bccd548453\e7bdb991-33c4-49a2-ac4b-a1bccd548453.jsonl`

**Started:** 2026-06-12 — architecture review & modernization plan  
**Last activity:** 2026-06-13 — Phase 1 MinGW build scaffold; R install question at end

Use `@.planning/modernization-session-handoff.md` in a new agent chat to continue this work.

---

## What GUImorph is

R package for **3D geometric morphometrics**: load PLY meshes, digitize landmarks/curves/anchors in a Tk GUI, export to `geomorph` / `Morpho` / `Rvcg` / `vegan`.

**Stack (top → bottom):**

1. **R** — `Project/GUImorphDevelopment/` + `Project/tkogl2/R/` (GUI, data, stats hooks)
2. **Tcl/Tk** — stringly-typed `tcl("add", shape, ...)` protocol in `rtkogl.R`
3. **C/OpenGL** — `tkogl2` DLL (`tcl_if_ZARF_9.c` etc.): WGL on Tk widget `HWND`, fixed-function OpenGL

**Hard constraint:** C engine is **Windows-only** (HWND/WGL). Cross-compile Windows DLL from WSL with MinGW-w64; do not expect a native Linux `.so`.

---

## Modernization roadmap (agreed)

| Phase | Goal | Status |
|-------|------|--------|
| **0** | Repo cleanup: flatten embedded git, purge VS caches, `.gitignore` | ✅ Done (committed on `repo-cleanup`) |
| **1** | Get `tkogl2.dll` building again without Visual Studio (MinGW + CMake) | 🟡 Scaffold done; build validated in follow-on R chat |
| **2** | Reproducible R env (`renv`), GUI launch, dependency migration | ⏳ Not started |
| **3** | Strategic fork: rehabilitate C / swap renderer (`rgl`) / rebuild UI | ⏳ Decision deferred |

---

## Phase 0 — completed decisions & results

**User decisions:**

- **Flatten** embedded repo (delete inner `.git`, track source in outer `dreoc/GUImorph`)
- **Untrack only outputs we produce** (`tkogl2.dll/.lib/.exp/.pdb`, `*.obj`); keep vendored stub/GLUT libs
- **Keep** `.sln` / `.vcxproj*` as build reference (no longer using VS IDE)

**Results:**

- Repo ~3.0 GB → ~55 MB
- Removed `.vs/`, `x64/`, `Debug/`, 140 MB `.diagsession`, embedded 2020 `.git`
- Comprehensive `.gitignore` at repo root
- Branch: `repo-cleanup`, remote: `git@github.com:dreoc/GUImorph.git`
- 676 source files tracked; prebuilt 2020 `tkogl2.dll` kept on disk but gitignored under `inst/libs/`

---

## Phase 1 — completed work

**Build target chosen:** MinGW-w64 cross-compile in WSL → Windows `tkogl2.dll` (user runs commands; R not required for compile-only phase).

**Key findings driving the build:**

- Old `.vcxproj` references pre-rename filenames (`curve.c` vs `curve_ZARF_9.c`) → build was broken
- Extension uses **only `Tcl_*`** + `Tcl_InitStubs`; **no `Tk_*`** — only Tcl stub needed
- MSVC `tclstub86_64.lib` unreadable by GNU `ld` → added `src/tcl_stub_bootstrap.c`
- MinGW has GL/GLU but not GLUT → `third_party/glut_shim/GL/glut.h` + link vendored `glut64.dll`
- GLUT usage: `glutInitDisplayMode`, `glutBitmapCharacter`, `glutSolidSphere` only

**Files created/modified in Phase 1:**

| Path | Purpose |
|------|---------|
| `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt` | CMake build |
| `integrated-guimorph-development_EOC/Project/tkogl2/cmake/mingw-w64-x86_64.cmake` | Cross-compile toolchain |
| `integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md` | Build instructions |
| `integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h` | Header case fixes (`<windows.h>`, `<GL/gl.h>`) |
| `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_stub_bootstrap.c` | Tcl 8.6 stub bootstrap for MinGW |
| `integrated-guimorph-development_EOC/Project/tkogl2/third_party/glut_shim/` | Minimal GLUT header shim |

**Build commands:**

```bash
cd integrated-guimorph-development_EOC/Project/tkogl2
sudo apt install -y mingw-w64 mingw-w64-tools cmake make   # once
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake
cmake --build build -j
# → build/tkogl2.dll
```

---

## Where the lost chat stopped

Last user messages in the original session:

1. Terminal output validation during Phase 1 build iterations
2. **"are you able to install R on my windows env from your sandbox"**

Follow-on work happened in a **separate chat** (`b0ee6d08-...`): Windows R installed via winget, CRAN deps installed, findings recorded in `.planning/r-guimorph-setup-findings.md`. MinGW `tkogl2.dll` build succeeded (exports `Tkogl2_Init`).

---

## Next steps (pick up here)

1. **Runtime smoke test** — Windows R:
   ```r
   dll <- "\\\\wsl.localhost\\Ubuntu\\home\\akagi\\home\\GUImorph\\integrated-guimorph-development_EOC\\Project\\tkogl2\\build\\tkogl2.dll"
   library(tcltk)
   tcl("load", dll, "Tkogl2")
   ```
2. **Load GUImorph package:**
   ```r
   setwd("\\\\wsl.localhost\\Ubuntu\\home\\akagi\\home\\GUImorph\\integrated-guimorph-development_EOC\\Project\\GUImorphDevelopment")
   devtools::load_all(".")
   GUImorph()
   ```
3. Optionally copy new `build/tkogl2.dll` → `inst/libs/x64/` before testing
4. **Phase 2:** pin R deps with `renv`, verify digitize→analyze round-trip

---

## Critical flaws identified (original review)

- Broken `.vcxproj` filename mismatch (`_ZARF_9` rename never updated project file)
- Hardcoded `C:\Users\amlut\...` paths
- Release|x64 built Application instead of DynamicLibrary
- Windows/WGL-only; fixed-function OpenGL deprecated
- Stale R package APIs (`geomorph` etc., ~2020)
- 5,581-line god file `tcl_if_ZARF_9.c`, massive dot/anchor duplication
- No tests/CI; stringly-typed R↔C protocol

---

## Related artifacts

- `.planning/r-guimorph-setup-findings.md` — R install & first load attempt (separate chat)
- `.gitignore` — Phase 0 policy
- `integrated-guimorph-development_EOC/Project/tkogl2/build.log` — build output log (if present)
