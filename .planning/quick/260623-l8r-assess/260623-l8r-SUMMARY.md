---
quick_id: 260623-l8r
slug: plug-and-play-assessment
status: complete
completed: 2026-06-23
---

# Quick Task 260623-l8r Summary

**Verdict: Not plug-and-play for a typical R user today — contributor-ready on Windows only.**

GUImorph is a valid R package and *can* be installed from the repo, but the current layout targets **maintainers and developers**, not casual `install.packages()` users.

## What works today (Windows)

| Step | Status | Notes |
|------|--------|-------|
| Valid R package structure | ✓ | `DESCRIPTION`, `NAMESPACE`, `R/`, `inst/`, `man/` under `GUImorphDevelopment/` |
| Native DLL load path | ✓ | `.onLoad` in `rtkogl.R` loads `inst/libs/x64/tkogl2.dll` via `tcl("load", ...)` |
| Bundled runtime deps | ✓ | `glut64.dll` + `tkogl2.dll` tracked in git (DLL predates `.gitignore` rule) |
| Dependency lockfile | ✓ | `renv.lock` committed for reproducible contributor restores |
| GUI entry point | ✓ | `GUImorph()` exported; works after `devtools::load_all()` or install |

**Minimum working path (maintainer / power user on Windows):**

```r
# Option A — dev loop (documented in BUILD.md)
setwd(".../GUImorphDevelopment")
renv::restore()
devtools::load_all(".")
GUImorph()

# Option B — install from GitHub subdir (untested in this task; structurally valid)
remotes::install_github(
  "dreoc/GUImorph",
  subdir = "integrated-guimorph-development_EOC/Project/GUImorphDevelopment"
)
library(GUImorph)
GUImorph()
```

## What blocks plug-and-play

### 1. Windows-only runtime (hard blocker for cross-platform)

- `tkogl2.dll` is a Windows PE binary loaded through Tcl/Tk 8.6.
- `PROJECT.md` explicitly scopes Linux/macOS out of v1.0.
- `DESCRIPTION` has no `SystemRequirements: Windows` — CRAN/installers won't warn users.

### 2. Monorepo nesting (discoverability)

- Package lives at `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`, not repo root.
- No end-user `README` with install instructions at repo root or package root.
- Standard `install.packages("GUImorph")` impossible — not on CRAN.

### 3. Build policy vs shipped binary (confusing docs)

- `BUILD.md` states `tkogl2.dll` is gitignored and must be built — **stale relative to git** (DLL is tracked).
- `.gitignore` still lists `tkogl2.dll`; new clones get the committed DLL, but policy says otherwise.
- Rebuilders must run MSVC CMake configure + build (`build-msvc/` is gitignored).

### 4. Dependency install burden

- `Imports`: geomorph, Morpho, Rvcg, vegan, tcltk, tcltk2 — not all trivial on every Windows R setup.
- `renv.lock` is in `.Rbuildignore` (correct for package tarball) but end users get no `Remotes:` or install-time guidance.
- `install_github` does not auto-run `renv::restore()` — user must satisfy Imports manually.

### 5. Package hygiene gaps

- Dev artifacts in package tree: `DATA_LOG_FILES/`, `activedatalist.rds`, multiple `tkogl2.dll.pre-phase*.bak` on disk.
- 26+ warnings on `load_all` (documented, not fixed).
- Known functional bugs deferred: GPA plot blank (999.1), openDgt specimen order (999.2).

### 6. No distribution channel

- No CRAN submission prep (`URL`, `BugReports`, checked examples, `R CMD check` clean).
- No GitHub Release with prebuilt binary zip.
- No R-universe / pak registry config.

## Readiness scorecard

| Audience | Ready? | What they need |
|----------|--------|----------------|
| **Maintainer (you)** | ✓ Yes | Windows R 4.6+, clone, `renv::restore()`, `load_all` or install |
| **Contributor** | ✓ Mostly | Above + `BUILD.md` for C rebuilds; MSVC for DLL changes |
| **R user (plug-and-play)** | ✗ No | No CRAN, no release binary, no install README, Windows-only |
| **Linux/macOS R user** | ✗ No | No native DLL; out of scope for v1.0 |

## Minimum path to plug-and-play (future milestone, not this task)

1. **End-user README** — Windows-only install via `remotes::install_github(..., subdir=...)` + `library(GUImorph); GUImorph()`.
2. **Align DLL policy** — either commit MSVC DLL as release artifact (document it) or ship via GitHub Releases and download on install.
3. **DESCRIPTION metadata** — `SystemRequirements: Windows`, `R (>= 4.6.0)`, `URL`, `BugReports`.
4. **Clean package tree** — remove dev logs/backups from tracked paths; tighten `.gitignore` for `*.pre-phase*.bak`.
5. **Optional:** R-universe or `pak::pkg_install` one-liner; CRAN is unlikely while bundling a custom OpenGL DLL.

## Recommendation

**Do not market v1.0 as plug-and-play.** It is **restored and shippable for Windows researchers who clone the repo and follow `BUILD.md`**. For true plug-and-play, plan a small distribution milestone (README + install path + DLL policy + DESCRIPTION cleanup) — estimate 1 phase, not a code rewrite.

---
*Completed: 2026-06-23*
