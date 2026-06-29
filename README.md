# GUImorph

GUImorph is an R package with a graphical user interface for **3D geometric morphometrics** — load PLY mesh specimens, digitize landmarks, curves, and anchors, then run `geomorph` analyses and export coordinates.

**Platform:** **Windows only.** The GUI requires Windows R 4.6+ and a native OpenGL DLL (`tkogl2.dll`). Linux and macOS are not supported in v1.0.

---

## Running GUImorph (end users)

You do **not** need to compile anything to run GUImorph. The repository ships a prebuilt `tkogl2.dll` under the package `inst/libs/x64/` directory.

### Prerequisites

| Requirement | Install |
|-------------|---------|
| Windows 10+ | — |
| R 4.6+ (64-bit) | `winget install -e --id RProject.R` |
| Git | `winget install -e --id Git.Git` |

Restart your terminal after installing R so `R` is on `PATH`.

### Option A — Clone and run (recommended)

```powershell
git clone https://github.com/dreoc/GUImorph.git C:\dev\GUImorph
cd C:\dev\GUImorph
```

Open **R** (or RStudio) and run:

```r
pkg <- "C:/dev/GUImorph/integrated-guimorph-development_EOC/Project/GUImorphDevelopment"
setwd(pkg)

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
renv::restore()

if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools")
devtools::load_all(".")
GUImorph()
```

### Option B — Install from GitHub

```r
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")

remotes::install_github(
  "dreoc/GUImorph",
  subdir = "integrated-guimorph-development_EOC/Project/GUImorphDevelopment",
  upgrade = "never"
)

library(GUImorph)
GUImorph()
```

After `install_github`, you may still need to run `renv::restore()` from the installed package source directory if dependency versions mismatch — Option A is more predictable for first-time setup.

### First launch checklist

1. Console prints the `tkogl2` load path from `.onLoad` (no `loading tkogl2 failed` warning).
2. The **3D GUImorph** window opens.
3. Load a `.ply` specimen — the mesh renders (not blank/black).

---

## Using GUImorph

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
2. **Set number of landmarks** — enter how many landmarks you will place.
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
4. **Save Result** to export the aligned coordinates to a `.csv`.

### 7. Save and reload your work

- **File → Save to DGT** writes your digitized data to a `.dgt` file.
- **File → Load DGT File** restores a session. If the file contains anchors,
  **Place Anchors** is re-checked automatically and locked, and all tabs open.

---

## Known quirks

These are inherent GUImorph behaviors that can look like bugs:

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
- **GPA Plot** may need the `rgl` package; if the plot opens behind the Tk window,
  use **Alt+Tab** to bring it forward.
- **Load ply** prompt is titled "Select Images to Digitize" and accepts multiple
  files — selecting several creates a specimen set, navigated with Previous/Next.

---

*Modernized release v1.0 — Windows R 4.6+, MSVC-built `tkogl2.dll`, modular C engine.*
