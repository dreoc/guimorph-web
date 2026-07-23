# GUImorphWeb

GUImorphWeb is an R package with a graphical user interface for **3D geometric morphometrics** — load PLY mesh specimens, digitize landmarks, curves, and anchors, then run `geomorph` analyses and export coordinates.

> **Current state.** This repository was split from
> [GUImorph](https://github.com/dreoc/GUImorph) on 2026-07-22 to build a browser
> rendering path. **No browser code has landed yet.** What runs today is the
> native OpenGL engine inherited from GUImorph, documented below. The browser
> migration is a six-phase milestone tracked in `.planning/ROADMAP.md`. Until
> Phase 6, the native engine is retained deliberately, because Phase 4 needs it
> as a picking-accuracy reference.
>
> GUImorph's native macOS work continues on its own track and is not duplicated
> here.

**Platform:** Windows and macOS (arm64). The native GUI requires R 4.6+ and a
platform OpenGL library (`tkogl2.dll` / `tkogl2.dylib`). Linux is not supported
by the native engine; the browser path in this milestone makes it nearly free,
but it is not scoped or tested.

## Why GUImorphWeb

As of **geomorph 4.1**, the interactive 3D digitizing functions (`digit.fixed`,
`digitsurface`, `buildtemplate`) are **deprecated**, because rgl and OpenGL are no
longer supported on current macOS. GUImorph answered that by writing its own
native OpenGL engine. That works, and it is what ships here today.

It also inherits the problem it was built to escape. Apple retired OpenGL in
10.14 and has removed more of it in every release since. On current macOS `rgl`
cannot load at all, and because it sits in `Imports`, it takes the whole package
down with it. Maintaining a native GL engine across two platforms costs a
tri-platform CMake build, MSVC and Rtools, two windowing backends, Tcl/Tk version
matching, and a signing and notarization pipeline.

GUImorphWeb moves rendering and interaction to a browser surface driven from R.
R keeps file I/O, downsampling, template warping, GPA, and export. A local
`httpuv` server serves mesh bytes over loopback, three.js renders them, and
`three-mesh-bvh` accelerates picking. Nothing is fetched at runtime, so it still
works offline with nothing separate to install. `StereoMorph` already does
browser-based 2D digitizing inside R for this same user base, so the pattern is
established.

The `.dgt` format and every R analytical path carry over unchanged.

---

## Running GUImorphWeb (end users)

You do **not** need to compile anything to run the native engine. The repository ships a prebuilt `tkogl2.dll` under the package `inst/libs/x64/` directory, inherited from GUImorph.

### Prerequisites

| Requirement | Install |
|-------------|---------|
| Windows 10+ | — |
| R 4.6+ (64-bit) | `winget install -e --id RProject.R` |
| Git | `winget install -e --id Git.Git` |

Restart your terminal after installing R so `R` is on `PATH`.

### Option A — Clone and run (recommended)

```powershell
git clone https://github.com/dreoc/guimorph-web.git C:\dev\guimorph-web
cd C:\dev\guimorph-web
```

Open **R** (or RStudio) and run:

```r
pkg <- "C:/dev/guimorph-web/integrated-guimorph-development_EOC/Project/GUImorphDevelopment"
setwd(pkg)

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
renv::restore()

if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools")
devtools::load_all(".")
GUImorphWeb()
```

### Option B — Install from GitHub

```r
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")

remotes::install_github(
  "dreoc/guimorph-web",
  subdir = "integrated-guimorph-development_EOC/Project/GUImorphDevelopment",
  upgrade = "never"
)

library(GUImorphWeb)
GUImorphWeb()
```

After `install_github`, you may still need to run `renv::restore()` from the installed package source directory if dependency versions mismatch — Option A is more predictable for first-time setup.

### First launch checklist

1. A startup banner shows the version; no `loading tkogl2 failed` warning.
   The console is quiet by default — run `GUImorphWeb(debug = TRUE)` for verbose diagnostics.
2. The digitizing window opens.
3. Load a `.ply` specimen — the mesh renders (not blank/black).

---

## Using GUImorphWeb

The window has a 3D viewport on the left and a set of tabs on the right:
**3D Digitizing**, **Anchors**, **Surface Sliders**, **Curves**, and **GPA**.
At startup only the **3D Digitizing** tab is active — the others stay disabled
(grayed out) until you meet each tab's prerequisites (see Known quirks). This
is intentional, to keep you from running later steps on incomplete data.

A typical end-to-end session looks like this:

### 1. Load specimens

- **File → Load ply File** and select one or more `.ply` meshes.
- Selecting multiple files loads them as a specimen set; the title bar shows the
  current **Specimen Id** and the right panel shows **Number of Specimens**.
- The first specimen renders in the viewport. Rotate/zoom with the mouse to
  orient it.

### 2. Digitize landmarks (3D Digitizing tab)

1. *(Optional)* **Digitize scale** — set a scale factor for the specimen.
2. **Fixed landmarks** — enter how many fixed landmarks you will place
   (the labeled box at the top of the tab).
3. **Double-click** the mesh to drop each landmark in order. The
   **Number of Landmarks** counter increments as you go.
   - Single-click is *pick/select only* — it does not place a point.
   - Click and drag an existing landmark to reposition it.
   - **Label Landmark** toggles the numeric labels on/off.
   - **Missing Landmark** marks the next index as missing if a point can't be placed.
   - **Landmark Size +/-** and **Landmark Color** adjust appearance.
4. When the placed count reaches the number you set, **Surface Sliders**,
   **Curves**, and **GPA** unlock for the current specimen.

> **Want anchors too?** Tick **Place Anchors** *before* you finish landmarks,
> then digitize on the **Anchors** tab. Anchors are optional for unlocking
> Surface Sliders, Curves, and GPA, but if the box is checked you must finish
> anchors before switching to another specimen.

### 3. Place anchors (Anchors tab — optional)

- **Set number of anchors**, then **double-click** the mesh to place them, same
  as landmarks. **Label Anchors** toggles their labels.

### 4. Curves and surface sliders (optional)

- **Curves tab:** Set **Total curves** and **Current curve** with the spinboxes, then
  **double-click** three landmarks per segment on the mesh. Click **Compute Curves**
  to draw all segments. Use **Reset view** to restore the default camera.
  Define curves by selecting 3 landmarks per segment (landmark-ID triplets, not splines).
- **Surface Sliders tab:** define surface semilandmarks for sliding.

### 5. Move between specimens

- Use **< Previous** and **Next >** below the viewport to step through a
  multi-specimen set. Each specimen keeps its own landmarks/anchors.

### 6. Run the analysis (GPA tab)

1. Choose options — max GPA iterations, whether to use anchors as curve/surface
   semilandmarks, sliding, principal-axis alignment, tangent-space projection, etc.
2. **Compute** to run the Generalized Procrustes Analysis (`geomorph::gpagen`).
3. **Plot Aligned Specimens** to visualize the aligned configuration
   (you must **Compute** first).
4. **PCA (morphospace)** plots PC1/PC2 of the aligned coordinates; **Plot Mean
   Shape** reconstructs and renders the consensus surface (Radius factor /
   Wireframe controls adjust the surface).
5. **Save Result** to export the aligned coordinates to a `.csv`.

### 7. Save and reload your work

- **File → Save to DGT** writes your digitized data to a `.dgt` file.
- **File → Add PLY to Current DGT** adds new specimens to an open dataset
  without dropping the ones already digitized.
- **File → Merge DGT Files** combines two or more `.dgt` files into one dataset
  (their template, curves, and per-specimen point counts must match).
- **File → Load DGT File** restores a session. If the file contains anchors,
  **Place Anchors** is re-checked automatically and locked, and all tabs open.

---

## Known quirks

These are inherent GUImorphWeb behaviors that can look like bugs:

- **Tabs are disabled until prerequisites are met.** Only the **3D Digitizing**
  tab is active at startup. **Surface Sliders**, **Curves**, and **GPA** unlock once
  you finish placing all landmarks on the **current specimen**. The **Anchors** tab
  unlocks when specimens are loaded.
- **Placement is tab-specific.** You can only place **landmarks** while on the
  **3D Digitizing** tab, and **anchors** while on the **Anchors** tab.
- **Place Anchors** enables the anchor workflow and step indicator, and requires
  finishing anchors before switching specimens when checked. It does not block
  **Surface Sliders**, **Curves**, or **GPA** — those unlock when landmarks are
  complete on the current specimen.
- **Double-click to place; single-click selects.** Single-click is pick/select
  only. Click and drag to move a landmark/anchor.
- **Fit / Reset view** may show no visible change if the view is already at the
  default rotation/zoom. The Curves tab labels this button **Reset view**; other
  tabs use **Fit** (Ctrl+F runs the same action everywhere).
- **GPA order matters:** **Plot Aligned Specimens** and **Save Result** require a
  successful **Compute** first (otherwise you'll see "Run Compute first").
- **GPA plots** open in a separate `rgl` window; if it opens behind the Tk
  window, use **Alt+Tab** to bring it forward. On current macOS `rgl` may fail
  to load entirely. Phase 1 of the browser milestone replaces these plots with a
  three.js widget and makes `rgl` optional.
- **Load ply** prompt is titled "Select Images to Digitize" and accepts multiple
  files — selecting several creates a specimen set, navigated with Previous/Next.

---

*GUImorphWeb 0.10.0. Native engine inherited from GUImorph, Windows and macOS arm64. Browser rendering path not yet implemented; see `.planning/ROADMAP.md`.*
