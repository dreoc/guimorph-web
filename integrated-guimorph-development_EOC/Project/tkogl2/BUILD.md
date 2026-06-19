# Building `tkogl2.dll` (Windows-native MinGW — primary)

`tkogl2` is the C/OpenGL engine for GUImorph, compiled as a **Windows DLL** and
loaded by Windows R through Tcl/Tk. It is Windows-only by design (it creates an
OpenGL context on a Tk widget's `HWND` via WGL).

**Contributor default:** build natively on Windows with **MSYS2 UCRT64** + MinGW Makefiles.

For the full contributor cycle (prerequisites → deploy → renv → smoke test), see the repo-root
[`BUILD.md`](../../../../BUILD.md).

## 1. Install the toolchain (once)

Open **MSYS2 UCRT64** and run:

```bash
pacman -S --needed mingw-w64-ucrt-x86_64-toolchain cmake make
```

Verify:

```bash
x86_64-w64-mingw32-gcc --version
cmake --version
```

## 2. Configure & build (Windows — primary)

From this directory (`integrated-guimorph-development_EOC/Project/tkogl2`):

```bash
cmake -B build -S . -G "MinGW Makefiles"
cmake --build build -j
```

On success you get **`build/tkogl2.dll`**.

> Do **not** pass `-DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake` on Windows.
> That toolchain file targets **WSL/Linux** sysroot paths (`/usr/x86_64-w64-mingw32`).

Deploy to the R package with the repo-root script:

```powershell
# From repo root (PowerShell)
powershell -ExecutionPolicy Bypass -File scripts/deploy-dll.ps1
```

## What this build does differently from the old Visual Studio project

- Wires up the actual `*_ZARF_9.c` source filenames (the `.vcxproj` still
  referenced the pre-rename names).
- Adds `StatisticsFunction_ZARF_9.c`, which the old project omitted even though
  `tcl_if` references `statisticsVersionPtr`.
- Uses **relative** include/lib paths (no hardcoded `C:\Users\amlut\...`).
- Always builds a `DynamicLibrary` named `tkogl2.dll` (the old Release|x64
  config wrongly built an `Application`).
- Header includes were fixed to canonical case (`<windows.h>`, `<GL/gl.h>`,
  `<GL/glu.h>`) so they resolve on a case-sensitive filesystem.
- Provides a tiny `third_party/glut_shim/GL/glut.h` (MinGW has GL/GLU but not
  GLUT); links the three GLUT symbols against the vendored `glut64.dll`.

## Dependencies

| Library                         | Source                                            |
| ------------------------------- | ------------------------------------------------- |
| `opengl32`, `glu32`, `gdi32`, `user32` | MinGW-w64 (system import libs)              |
| Tcl 8.6 stub                    | **`src/tcl_stub_bootstrap.c`** (compiled into the DLL) |
| GLUT (`glut64.dll`)             | vendored in `lib/`, linked directly               |

> Only the **Tcl** stub is needed — the engine calls no `Tk_*` API (the `HWND`
> arrives from R as an integer), so no Tk stub library is linked.

### Why the Tcl stub is a bootstrap source file

The vendored `lib/tclstub86_64.lib` is an MSVC COFF archive that GNU `ld`
cannot read (`file format not recognized`), and the vendored Tcl *source* can't
be compiled here because its Windows platform headers (`tclWinPort.h`, ...)
were not included in the snapshot. So `src/tcl_stub_bootstrap.c` provides the
stub bootstrap (`Tcl_InitStubs` + `tclStubsPtr`/`tclPlatStubsPtr`) directly,
using only the public `tcl.h`. See that file's header comment for the ABI
rationale (it reads `Interp::stubTable`, whose layout is stable in Tcl 8.6).

> Caveat: this relies on the Tcl 8.6 internal `Interp` ABI (first fields:
> `result`, `freeProc`, `errorLine`, `stubTable`). It should be re-validated
> once we can load the DLL into R and confirm `Tcl_InitStubs` succeeds at
> runtime.

## Fallback

**GLUT** — if linking `glut64.dll` directly fails, regenerate a MinGW import lib:

```bash
cd lib
gendef glut64.dll                                   # -> glut64.def
x86_64-w64-mingw32-dlltool -d glut64.def -l libglut64.a
cmake -B build -S . -G "MinGW Makefiles" \
      -DTKOGL2_GLUT_LIB=$PWD/lib/libglut64.a
cmake --build build -j
```

## Notes

- `build/` is a throwaway directory and is git-ignored.
- The produced `tkogl2.dll` is a release artifact and is **not** committed.
- Functional testing (loading the DLL into R) requires deploy + Windows R smoke;
  see repo-root `BUILD.md`.

---

## Advanced: WSL Cross-Compile

Maintainers with WSL may cross-compile a Windows DLL from Linux using MinGW-w64.
This path is **optional** — not the contributor default.

### Install the WSL toolchain (once)

```bash
sudo apt update
sudo apt install -y mingw-w64 mingw-w64-tools cmake make
```

Verify:

```bash
x86_64-w64-mingw32-gcc --version
cmake --version
```

### Configure & build (WSL)

From this directory:

```bash
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake
cmake --build build -j
```

The toolchain file sets `CMAKE_FIND_ROOT_PATH` to `/usr/x86_64-w64-mingw32` and must
**only** be used on Linux/WSL hosts.

GLUT fallback on WSL:

```bash
cd lib
gendef glut64.dll
x86_64-w64-mingw32-dlltool -d glut64.def -l libglut64.a
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake \
      -DTKOGL2_GLUT_LIB=$PWD/lib/libglut64.a
cmake --build build -j
```

After build, deploy via Windows PowerShell (`scripts/deploy-dll.ps1`) or manual copy to
`GUImorphDevelopment/inst/libs/x64/tkogl2.dll`.
