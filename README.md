# GUImorph, a Graphical User Interface to R functions to conduct 3D GM
GUImorph, A User-Friendly R Package with a Graphical User Interface to Digitize & Conduct Geometric Morphometric Analyses of 2D and 3D: Landmark-based Geometric Morphometrics (GM) is a prominent approach used to quantify shape variation and its covariation with other variables. We developed GUImorph, the first user-friendly R package featuring a Graphical User Interface (GUI) to (i) digitize 2D landmarks and sliding semi-landmarks, as well as 3D landmarks and sliding curve and surface semi-landmarks and (ii) conduct 2D and 3D GM analyses on landmarks and sliding curve and surface semi-landmarks. GUImorph is easy to use and provides needed tools for paleoanthropologists interested in quantifying the complete shape variation of objects, and in evaluating hypotheses regarding shape co-variation with other variables of interest.

**Platform:** Windows R is required for the GUI and native OpenGL engine. WSL is not required for contributors.

## Quick start

1. Install R 4.6+ and clone this repo to a Windows path.
2. Follow [BUILD.md](BUILD.md) to build and deploy `tkogl2.dll`.
3. Open R with working directory = `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/` and run `renv::restore()`.
4. Run `devtools::load_all(".")` then `GUImorph()`.
5. Load a `.ply` specimen; see **Known behavior** below for UI quirks.

## Known behavior

These are inherent GUImorph behaviors that can look like bugs:

- **Landmarks:** double-click the canvas to place; single-click is pick/select only.
- **Fit button:** may show no visible change if the view is already at default rotation/zoom.
- **Curves:** legacy chord segments between 3 landmark IDs, not surface-following splines.
- **GPA Plot:** may need `rgl`; use Alt+Tab if the plot window opens behind the Tk GUI.

For build troubleshooting and `load_all` warning details, see [BUILD.md](BUILD.md) and `.planning/smoke-test-findings.md` (maintainer audit log).
