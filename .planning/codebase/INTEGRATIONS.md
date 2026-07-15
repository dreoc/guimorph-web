# External Integrations

**Analysis Date:** 2026-07-12

GUImorph is a **local, offline Windows desktop application**. It has **no external
APIs, cloud services, databases, authentication providers, or webhooks**. All
"integrations" are (a) R packages consumed at runtime, (b) native libraries linked
into `tkogl2.dll`, and (c) on-disk file formats it reads and writes.

## APIs & External Services

**None.** No HTTP clients, REST/GraphQL calls, SDKs for cloud providers, or
telemetry were found. The only network reference is the project's GitHub repo
(`https://github.com/dreoc/GUImorph`) surfaced in the startup banner
(`R/rtkogl.R` `.onAttach`) and used for source distribution via
`remotes::install_github` (`README.md`).

## Consumed R Packages (runtime dependencies)

Declared in `DESCRIPTION` Imports; versions pinned in `renv.lock`.

**Analysis / morphometrics:**
- **geomorph** `4.1.1` — Core analysis. Called for:
  - `geomorph::gpagen(...)` — Generalized Procrustes Analysis (`R/3dDigitize.geomorph.r`)
  - `geomorph::gm.prcomp(aligned)` — PCA / morphospace (`R/3dDigitize.geomorph.r`)
  - `geomorph::two.d.array(aligned)` — coordinate reshaping for export
  - specimen/mean-shape plotting helpers
- **Morpho** `2.13` — `Morpho::fastKmeans(...)` for surface semilandmark template construction (`R/3dDigitize.surface.r`).
- **Rvcg** `0.25` — `Rvcg::vcgPlyRead(fileName, updateNormals = TRUE, clean = FALSE)` for PLY mesh reading on the R side (`R/3dDigitize.surface.r`; replaced deprecated `geomorph::read.ply` in 2017).
- **RRPP** `2.1.2` — statistical backbone pulled in via geomorph.
- **vegan** `2.7-5` — ordination support.
- **parallel** (base R) — optional multi-core Procrustes sliding during GPA.

**GUI:**
- **tcltk** (base R) + **tcltk2** `1.6.1` — the entire GUI (menus, tabs, spinboxes, dialogs) and the `tcl(...)` bridge that drives the native engine.
- **rgl** `1.3.36` — opens separate OpenGL windows to plot GPA results (aligned specimens, mean shape). Distinct from the native digitizing viewport.

## Native Library Integrations (linked into `tkogl2.dll`)

Configured in `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt`;
import libs vendored under `integrated-guimorph-development_EOC/Project/tkogl2/lib/`.

- **OpenGL** (`opengl32`, `glu32`) — 3D mesh rendering (`src/ogl_ZARF9.c`, `src/ogl_model_ZARF_9.c`).
- **GLUT / freeglut** — display-mode setup (`glutInitDisplayMode`), linked via `lib/glut64.lib`, runtime `lib/glut64.dll` (deployed to `inst/libs/x64/glut64.dll`). Header shim: `third_party/glut_shim/GL/glut.h`.
- **WGL + GDI/User32** (`gdi32`, `user32`) — embeds the GL context into a Tk widget HWND (`src/tcl_window.c`), the Windows-only mechanism.
- **Tcl stubs** — `lib/tclstub86_64.lib` (MSVC) or `src/tcl_stub_bootstrap.c` (MinGW) so the DLL registers Tcl commands (`add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`) via `Tkogl2_Init` (`src/tcl_init.c`).

**R ↔ native bridge:** the package loads the DLL with `tcl("load", file, "Tkogl2")`
in `.onLoad` (`R/rtkogl.R`), searching `libs/<arch>/`, `libs/x64/`, then `libs/`.

## Data Storage

**Databases:** None.

**File Storage:** Local filesystem only. No cloud/object storage.

**Caching:** None. (`renv/` provides package-install caching at dev time only.)

## File Formats (read/written)

**PLY (Polygon File Format) — input meshes:**
- Extension: `.ply` / `.PLY` (case-insensitive match; mixed case not handled — `src/ogl_model_ply_ZARF_9.c`).
- R-side read: `Rvcg::vcgPlyRead` (`R/3dDigitize.surface.r`).
- C-side parse: manual `fopen`/header scan in `src/ogl_model_ply_ZARF_9.c` (reads `element vertex`, `element face`, vertex colors, bounding box; geometry-only NextEngine PLYs supported).
- Loaded via **File → Load ply File** (`R/3dDigitize.main.r`, `tkgetOpenFile` filter `{{ply file} {.ply}}`).

**DGT — native session format (read/write):**
- Extension: `.dgt`. Custom text format holding landmarks, anchors, curves, template, and surface semilandmarks.
- Parsed with tagged blocks: `LM3=`, `CURVES=`, `ANCHORS=`, template markers (`PLY_ATTR_GET_INT("LM3=", ...)` in `src/ogl_model_ply_ZARF_9.c`; block scanning in `R/3dDigitize.main.r`, `R/3dDigitize.curve.r`, `R/3dDigitize.surface.r`).
- Operations: **Save to DGT**, **Load DGT File**, **Add PLY to Current DGT**, **Merge DGT Files** (`R/3dDigitize.main.r`). Merge requires matching template/curve/point counts.

**CSV — analysis export:**
- **GPA tab → Save Result** writes aligned coordinates via `write.csv(dfram, paste(filename, ".csv"))` (`R/3dDigitize.geomorph.r`).

**RDS — geomorph object export:**
- Save dialog offers `{{geomorph RDS} {.rds}}` for the raw geomorph result (`R/3dDigitize.geomorph.r`).

## Authentication & Identity

Not applicable — single-user local desktop tool, no accounts or auth.

## Monitoring & Observability

**Error Tracking:** None (no external service).

**Logs:** Local text logging only.
- C engine diagnostic channel: `simpleLog*` writers in `src/tcl_log.c`.
- Downsample/data logs written to `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DATA_LOG_FILES/` (e.g. `a1_1_ds_*.txt`, `CMMDS_DL_*.txt`).
- R-side gated debug printer `dbg()` (active only under `GUImorph(debug = TRUE)`; `R/rtkogl.R`).

## CI/CD & Deployment

**Hosting:** N/A (desktop package distributed via GitHub source).

**CI Pipeline:** None detected — no `.github/` workflows in the repo.

**Distribution:**
- Clone-and-run or `remotes::install_github("dreoc/GUImorph", subdir = "integrated-guimorph-development_EOC/Project/GUImorphDevelopment")` (`README.md`).
- Prebuilt `tkogl2.dll` committed to `inst/libs/x64/` so clones work without a C toolchain.
- DLL rebuild/deploy: `scripts/deploy-dll.ps1` (copies `build-msvc/Release/tkogl2.dll` → `inst/libs/x64/`, with `.bak` rollback).
- renv bootstrap: `scripts/init-renv.R`.

## Environment Configuration

**Required env vars:** None.

**Runtime options:** `options(guimorph.debug=)` toggled by `GUImorph(debug=TRUE)`.

**Secrets location:** None — no secrets, tokens, or credentials in the project.

## Webhooks & Callbacks

**Incoming:** None.

**Outgoing:** None.

---

*Integration audit: 2026-07-12*
