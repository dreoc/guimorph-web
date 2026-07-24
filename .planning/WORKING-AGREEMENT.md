# Working Agreement

How Erik and an AI assistant collaborate on this repo. Written at the end of
Phase 1 because every item below was learned the expensive way.

## Erik's environment

| | |
|---|---|
| Primary | Windows 11, PowerShell, repo at `C:\dev\guimorph-web` |
| R | 4.6.1, RGui and RStudio both installed |
| Toolchain | VS 2022 Build Tools (MSVC), CMake 3.28.3, Node v24.18.0 |
| Secondary | macOS 26.5.2, arm64, R 4.6.1, XQuartz installed, repo at `~/dev/guimorph-web` |
| Specimens | Folsom PLYs at `C:\dev\Folsom3D` (also committed under `tests/fixtures/parity/`) |

`Rscript` is **not** on PATH on Windows. See "Improvements worth making" below.

## How work is delivered

The assistant cannot build, run, or test anything on Erik's machines. It works
in a Linux container with no access to R, CRAN, Windows, or macOS. Therefore:

1. The assistant clones the repo in its own container and edits there.
2. It produces a **git patch file** and presents it for download.
3. Erik applies it: `git apply $HOME\Downloads\<name>.patch`
4. Erik runs whatever verification the patch needs and pastes the output back.
5. Only Erik commits and pushes. The assistant never has push access.

### Patch hygiene, learned the hard way

- **Verify the patch applies to the tree Erik actually has**, which is HEAD plus
  any patch already applied but not yet committed. Test with a fresh clone plus
  the same stack of prior patches.
- **Commit intermediate state in the container before diffing.** Generating a
  diff against an uncommitted working tree produces a *cumulative* patch
  containing earlier changes too. This collided three separate times.
- **Match the file's existing line endings.** This repo is mixed: most R sources
  are CRLF in git, `view3d.R` is LF. `git diff` context must match or the patch
  is rejected. Check with `file` or `cat -A` before editing.
- **A patch for a file Erik already has must be a modification diff, not a file
  creation.** If the file is untracked in the container, `git diff --cached`
  emits `new file mode` and application fails with "already exists".
- **When line endings make a patch impractical**, send literal PowerShell
  `.Replace()` edits instead. Include a guard that errors if nothing matched, so
  a silent no-match fails loudly:
  `if ($n -eq $s) { Write-Error "No replacements matched" } else { ... }`

## Shell gotchas

- **cmd.exe treats `#` as an argument.** Never put trailing `#` comments in
  commands written for Erik.
- **`[IO.File]` methods ignore PowerShell's working directory.** .NET keeps its
  own. Always resolve first: `$p = (Resolve-Path "rel\path").Path`
- **`npm` and `Rscript` are not on PATH.** Use `npm.cmd`; invoke R by full path
  or from the GUI.
- **PowerShell blocks `npm.ps1`** under the default execution policy. `npm.cmd`
  sidesteps it without loosening the policy machine-wide.
- **`git apply` reports CRLF as "trailing whitespace"** on every added line.
  Cosmetic; nothing is altered.

## Git hygiene

- **Commit early and often.** Untracked files silently revert, do not appear in
  `git diff`, and do not survive `git checkout -- .`. `view3d.R` lost its
  background fix exactly this way and nobody noticed until a clone was inspected.
- **Verify against the remote, not the local tree.** After any push, confirm by
  cloning fresh. Several "done" states turned out not to be pushed.
- **`.gitattributes` protects fixture bytes.** `*.dgt`, `*.ply`, `*.pts` are
  marked `-text`. Erik's `core.autocrlf=true` corrupted a fixture before this
  existed; the original blob had to be recovered from history.
- **Commit code separately from large binaries** so a real change is not buried
  inside a 48 MB blob.

## Communication

- Terse, lowercase, short sentences. No em-dashes, no filler.
- Honest correction over agreement. State a prediction before running a check so
  it can be falsified. When wrong, say so plainly and say what the evidence was.
- Financial or strategic documents use illustrative parameters Erik populates;
  no invented forecasts.

## The assistant's environment: what it can and cannot do

**Cannot:** run R. The container has no R and its network allowlist blocks CRAN
(403), so `install.packages()` cannot work. Every dependency this project needs
(geomorph, Rvcg, Morpho, rgl, tcltk2) is CRAN-only. It also cannot test Windows
or macOS behaviour, which is where most of this project's bugs live: MinGW
rendering a black mesh, Retina backing-pixel picking, the Tcl 9.0 dylib
mismatch, `[IO.File]` ignoring PowerShell's location.

**Can:** reach the Ubuntu mirrors, npm, PyPI, crates.io, and GitHub. So it can
run Node, install esbuild, and reproduce the three.js vendoring exactly — which
is how the bundle was verified byte-identical across two Node versions.

### Syntax gate (recommended, assistant-side)

Base R installs from the Ubuntu mirror even though CRAN is blocked. It cannot
run any of this project's code, but it *can* parse it, which catches the class
of error that cost time in Phase 1 (unbalanced braces, `sprintf` argument
count mismatches, malformed raw strings).

```bash
apt-get install -y r-base-core          # ~39 packages, once per session
Rscript -e 'invisible(parse("path/to/file.R")); cat("parse OK\n")'
```

Run this on every R file before presenting a patch. It is not a test; a file can
parse and still be wrong. It only removes one failure mode.

## Improvements worth making

**Get `Rscript` onto PATH on Windows.** Highest-leverage change available. Find
it and add the directory permanently:

```powershell
(Get-ChildItem "C:\Program Files\R" -Filter Rscript.exe -Recurse -ErrorAction SilentlyContinue).FullName
[Environment]::SetEnvironmentVariable(
  "Path",
  [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\Program Files\R\R-4.6.1\bin\x64",
  "User")
```

Restart the shell, then verify: `Rscript --version`

With that in place, verification becomes one line in the shell Erik is already
in, instead of a GUI round-trip:

```powershell
Rscript -e "devtools::test('integrated-guimorph-development_EOC/Project/GUImorphDevelopment')"
Rscript -e "devtools::load_all('...'); GUImorphWeb:::.gmw_engine$ok"
Rscript scripts\check-template-kmeans-parity.R C:\dev\Folsom3D\A6_1_clean.ply
```

Note that `R CMD check` and `devtools::test()` still need the package's
dependencies installed, which they are.

**Two caveats on where things are run.** RStudio serves `browseURL()` over its
own HTTP server on `127.0.0.1`, which masks whether `file://` works — so any
browser-path test must run in RGui, Rterm, or Rscript. And `load_all()` does not
replace bindings already present in a live session, so after applying a patch,
verify in a *fresh* R session or the old definition will still be in play.
