# Aqua Tk Setup (macOS) — Fresh-Mac Zero-to-Launch Runbook

This is a linear, copy-pasteable runbook that takes a **stock Apple-Silicon Mac
(M1, macOS Tahoe) with nothing but macOS installed** all the way to a passing
Aqua gate and a live `GUImorph()` window. Follow the sections in order. Every
step is paired with the output you should expect, so you can tell immediately if
a step worked.

The whole point of this file: GUImorph's interactive 3D digitizing viewport
embeds OpenGL into a **Tk widget's native Cocoa (Aqua) window**. It cannot embed
into an X11/XQuartz Tk window. So the single most important requirement is an
**R session whose Tcl/Tk is Aqua, not X11** — which comes down to *which R you
install* (see Section 3).

> This milestone (v1.1) is a **source build against a system / Homebrew Tcl/Tk**.
> It is **arm64-only** — that is expected and acceptable. Bundling a private
> Tcl/Tk framework, universal2 / Intel reach, and signing / notarization are all
> out of scope here and handled in a later distribution milestone.

---

## 0. Who this is for

- A fresh **Apple Silicon (M1/M2/M3)** Mac running a current macOS (Tahoe).
- No prior developer tooling assumed — no Homebrew, no R, no Xcode tools.
- You want to build the engine from source and launch `GUImorph()`.

Use **command-line R** (the `R` / `Rscript` binaries in a terminal) for this
flow. Do **not** rely on R.app — the Aqua-Tk gate is validated in terminal R.

---

## 1. Xcode Command Line Tools

Provides `clang`, `make`, and the SDK headers the CMake build needs.

```bash
xcode-select --install       # click through the GUI dialog it opens
```

Verify:

```bash
xcode-select -p
```

Expected output: a path such as `/Library/Developer/CommandLineTools` (or a path
under `/Applications/Xcode.app/...` if you have full Xcode). If it prints an
error instead, the install did not complete — re-run the line above.

---

## 2. Homebrew

A stock box has no `brew`. Install it with the official one-liner (this pipes the
official install script from `raw.githubusercontent.com/Homebrew/install` to
bash — you can read the script at <https://brew.sh> first if you like). **Skip
this section if `brew --version` already works.**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then add Homebrew to your PATH for the current shell (Apple Silicon installs to
`/opt/homebrew`):

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

The Homebrew installer also prints these two lines at the end so `brew` is on
PATH in future shells — run them if it tells you to:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
```

Verify:

```bash
brew --version
```

Expected output: `Homebrew 4.x` (any 4.x is fine).

> **No-Homebrew boxes:** Homebrew is the easiest path but not mandatory — the
> build accepts an explicit Tcl/Tk prefix via `-DTKOGL2_MACOS_TCLTK_PREFIX`
> (see Section 9). You still need R and CMake from somewhere, though, so Homebrew
> is strongly recommended.

---

## 3. Install Tcl/Tk, CMake, an Aqua-Tk R, and git

```bash
brew install tcl-tk cmake r git
```

This installs, in one line:

| Formula   | Why                                                                    |
|-----------|------------------------------------------------------------------------|
| `tcl-tk`  | The **Aqua (Cocoa) Tcl/Tk** the engine embeds into (stub libs + `wish`) |
| `cmake`   | Configures and builds `tkogl2.dylib` and the gate (needs ≥ 3.16)       |
| `r`       | **Homebrew R** — the R whose Tk is Aqua (see the critical note below)  |
| `git`     | Clone the repository                                                    |

### CRITICAL: install Homebrew R — **not** CRAN R

Install R via **`brew install r`**, as above. Do **not** install the R from
**CRAN** (`r-project.org`, the `.pkg` installer, or `brew install --cask r`).

Why: CRAN's macOS build links its `tcltk` component against **X11/XQuartz**, so
`tk windowingsystem` reports `x11` and the Aqua gate **fails** — the OpenGL
viewport cannot embed into an X11 Tk window. **Homebrew R** links against
Homebrew's Aqua `tcl-tk`, so `tk windowingsystem` reports `aqua` and the gate
passes. This is the single undocumented assumption that historically made a
"fresh box" setup fail.

Version note: this runbook is deliberately **version-agnostic**. Homebrew's
`tcl-tk` may be 8.6 or 9.x and R may be any recent 4.x — do not hardcode a
version. Everywhere a Tcl/Tk path is needed, use `$(brew --prefix tcl-tk)`.

Verify the toolchain versions:

```bash
brew --prefix tcl-tk        # e.g. /opt/homebrew/opt/tcl-tk
cmake --version             # cmake version 3.16 or newer
R --version                 # R version 4.x (Homebrew build)
which R                     # expect /opt/homebrew/bin/R  (NOT /usr/local/bin/R from CRAN)
```

---

## 4. Confirm you have an Aqua-Tk R (fail fast)

Before building anything, prove your R session is Aqua-linked. This one command
decides the whole flow:

```bash
R --no-save -e 'library(tcltk); cat(tclvalue(.Tcl("tk windowingsystem")), "\n")'
```

Expected output:

```text
aqua
```

- If it prints `aqua` — you are good; continue.
- If it prints `x11` — you are running a CRAN/X11 R. Switch to Homebrew R
  (`brew install r`, then make sure `which R` is `/opt/homebrew/bin/R`) and
  re-run this check. See Troubleshooting (Section 10).
- If `library(tcltk)` errors with "Tcl/Tk support is not available" — your R was
  built without tcltk; use Homebrew R.

---

## 5. Clone the repository

```bash
git clone https://github.com/dreoc/GUImorph.git
cd GUImorph/integrated-guimorph-development_EOC/Project/tkogl2
```

All build commands below are run from this `tkogl2` directory unless noted.

---

## 6. Gate check — the DOC-01 target

This proves your R + Tcl/Tk are Aqua and can load a native Tk extension. It is
the same committed `test/gate/gate_check.R` used as the durable deployment gate.

Build the gate extension:

```bash
cmake -S test/gate -B build-gate
cmake --build build-gate
```

Expected build output ends with a line like:

```text
[100%] Built target gateext
```

> If configure aborts with "no Tcl/Tk stub libraries were found", pass the prefix
> explicitly: `cmake -S test/gate -B build-gate -DTKOGL2_MACOS_TCLTK_PREFIX=$(brew --prefix tcl-tk)`.

Run the automated Aqua gate with command-line R:

```bash
Rscript test/gate/gate_check.R build-gate/gateext.dylib
```

Expected output:

```text
gate_check: PASS
```

What this asserts (all inside `gate_check.R`): `tk windowingsystem == aqua`, a
successful Tcl `load` of the `Gateext` extension, and `gate_winsys == aqua`. If
you instead see `gate_check: FAIL - tk windowingsystem returned "x11"`, you are
on an X11 R — go back to Section 3/4.

**Reaching `gate_check: PASS` here is the DOC-01 success milestone.** The rest of
the runbook builds and launches the full engine (the CMP-02 acceptance).

---

## 7. Build and deploy `tkogl2.dylib` (the engine)

Still from `tkogl2/`. Build the real rendering engine:

```bash
cmake -B build-mac
cmake --build build-mac
```

> Same escape hatch as the gate: add
> `-DTKOGL2_MACOS_TCLTK_PREFIX=$(brew --prefix tcl-tk)` to the `cmake -B build-mac`
> line if Tcl/Tk is not auto-found.

Confirm the architecture (arm64-only is expected):

```bash
lipo -info build-mac/tkogl2.dylib
```

Expected output includes `arm64`, e.g.
`Non-fat file: build-mac/tkogl2.dylib is architecture: arm64`.

Deploy the built engine into the R package's `.onLoad` search path. The correct
target is the `libs/` **root** — `inst/libs/tkogl2.dylib` — **not** `libs/x64/`
(that subdir is where the Windows DLL lives):

```bash
cp build-mac/tkogl2.dylib ../GUImorphDevelopment/inst/libs/tkogl2.dylib
```

The package `.onLoad` computes the Tcl loadable-library extension itself and
searches `libs/<arch>/` then `libs/` root. On macOS `r_arch` is empty, so the
`libs/` root is where it finds `tkogl2.dylib`. If the engine is missing or copied
to the wrong place, `.onLoad` stops **loudly** with a message like:

```text
GUImorph: the tkogl2 rendering engine was not found in the installed package.
Looked for 'tkogl2' with extension(s) ... under libs/... 3D digitizing cannot
work without it. If you built from source, deploy the engine (tkogl2.dylib) into
inst/libs/ and reinstall.
```

If you see that, re-do the `cp` above (this is the most common miss — see
Troubleshooting).

---

## 8. Launch `GUImorph()` (the CMP-02 acceptance)

Move to the R package and restore its dependencies, then load and launch:

```bash
cd ../GUImorphDevelopment
R --no-save -e 'if(!requireNamespace("renv",quietly=TRUE)) install.packages("renv"); renv::restore(); if(!requireNamespace("devtools",quietly=TRUE)) install.packages("devtools"); devtools::load_all("."); GUImorph()'
```

Expected behavior:

- No "tkogl2 rendering engine was not found" stop.
- A Tk window opens.
- Load a `.ply` specimen → the mesh renders in the viewport (not blank/black).

> **`renv::restore()` is the long, most failure-prone step on a fresh box.** It
> compiles the full `geomorph` / `Morpho` / `Rvcg` / `rgl` / `htmlwidgets` set
> from `renv.lock`. Xcode CLT + Homebrew supply the C/C++ compilers; if a
> package needs a Fortran compiler you may also need `brew install gcc` (which
> provides `gfortran`). Budget time here.

### Confirm the loaded binary (avoid the skipped-copy trap)

A rebuild whose deploy `cp` was skipped silently loads a stale engine and costs
debugging cycles. Inside the running R session (after `load_all`), confirm the
binary that is actually loaded:

```r
tclvalue(tcl("add", "getCompileInformation", -1, 0, 0))
```

This prints the compile information string of the deployed engine — verify it
matches the build you just made.

---

## 9. Homebrew-absent / non-default Tcl/Tk prefix

The build is Homebrew-**optional**. If Tcl/Tk is not under the default Homebrew
prefix (Intel Homebrew, a hand-built Tcl/Tk, MacPorts, etc.), pass the prefix
explicitly to **both** the gate and engine configure steps:

```bash
# Homebrew (any prefix, resolved dynamically):
cmake -B build-mac -DTKOGL2_MACOS_TCLTK_PREFIX=$(brew --prefix tcl-tk)

# An arbitrary custom install:
cmake -B build-mac -DTKOGL2_MACOS_TCLTK_PREFIX=/path/to/your/tcl-tk
```

If the prefix has no Tcl/Tk stub libraries, CMake stops with a single actionable
error that names this exact flag — set it to a directory that contains `include/`
and `lib/` for your Tcl/Tk. Prefer `$(brew --prefix tcl-tk)` over any hardcoded
version path so the build stays version-agnostic (works on 8.6 or 9.x).

---

## 10. Troubleshooting

### `tk windowingsystem` prints `x11` (wrong R)

You installed CRAN R (X11/XQuartz Tk) instead of Homebrew R. The gate will fail
with `gate_check: FAIL - tk windowingsystem returned "x11"`. Fix: `brew install r`,
confirm `which R` is `/opt/homebrew/bin/R`, and re-run the Section 4 self-check
until it prints `aqua`. (If Homebrew R ever fails to yield Aqua Tk on your box,
the last-resort fallback is the `sethrfore/r-srf` custom tap built with Aqua Tk —
but the mainline `brew install r` should work.)

### `GUImorph()` stops with "rendering engine was not found"

The `.onLoad` search could not find `tkogl2.dylib`. Almost always this means the
deploy `cp` from Section 7 was skipped or the file was copied to the wrong subdir
(`libs/x64/` is Windows-only). Re-run:

```bash
cp build-mac/tkogl2.dylib ../GUImorphDevelopment/inst/libs/tkogl2.dylib
```

and confirm the loaded binary with `getCompileInformation` (Section 8).

### Gatekeeper / quarantine

A dylib you **compiled locally** carries **no** `com.apple.quarantine` attribute
— that flag is applied to *downloaded* files, not to something you built from
source. So signing / notarization / `xattr` steps are genuinely **not needed**
for this source-build flow (which is why they are deferred to a later
distribution milestone). Only if your box actually reports a quarantine error
should you clear it:

```bash
xattr -dr com.apple.quarantine build-mac/tkogl2.dylib
```

---

## Verification checklist (step → expected output)

This is the same checklist used as the CMP-02 acceptance (UAT) script. Capture
these outputs on a fresh box to prove the runbook works end-to-end.

| Step        | Command                                                              | Expected output                        |
|-------------|----------------------------------------------------------------------|----------------------------------------|
| Xcode CLT   | `xcode-select -p`                                                    | a path under `/Library/Developer/...`  |
| Homebrew    | `brew --version`                                                     | `Homebrew 4.x`                         |
| Toolchain   | `R --version`                                                        | `R version 4.x` (Homebrew build)       |
| Aqua-Tk R   | `R -e 'cat(tclvalue(.Tcl("tk windowingsystem")))'`                   | `aqua`                                 |
| Gate build  | `cmake --build build-gate`                                           | `[100%] Built target gateext`          |
| Gate check  | `Rscript test/gate/gate_check.R build-gate/gateext.dylib`            | `gate_check: PASS`                     |
| Engine arch | `lipo -info build-mac/tkogl2.dylib`                                  | `... architecture: arm64`              |
| Deploy      | `cp build-mac/tkogl2.dylib ../GUImorphDevelopment/inst/libs/tkogl2.dylib` | (no error)                        |
| Launch      | `GUImorph()`                                                         | Tk window opens; PLY renders (screenshot) |

Pass criteria: `tk windowingsystem == aqua`, Tcl `load` succeeds, the gate prints
`gate_check: PASS`, the engine rebuilds as an arm64 `tkogl2.dylib`, and
`GUImorph()` launches with a mesh visible in the viewport.
