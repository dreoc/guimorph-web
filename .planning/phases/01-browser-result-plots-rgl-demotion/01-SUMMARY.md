# Phase 1 Summary: Result Plots + rgl Demotion

**Status:** complete (one criterion pending hardware)
**Requirements:** WEB-00, PLT-01, PLT-02, PLT-03, CMP-01
**Verified on:** Windows 11 / R 4.6.1, macOS 26.5.2 arm64 / R 4.6.1

## What shipped

**WEB-00 — vendored browser runtime.** three@0.185.1, its OrbitControls and
PLYLoader addons, and three-mesh-bvh@0.9.13 bundled by `scripts/vendor/` into a
single 807,350-byte classic script at
`inst/htmlwidgets/guimorphweb-three.js`, with both licences and a manifest
recording versions and sha256. Built independently on Node v22 and v24 to
byte-identical output. `R/view3d.R` writes a plain HTML page beside a copy of
the bundle and opens it with `browseURL()`.

**PLT-01 — result plots in the browser.** `plotspecs` and `plotMeanShape` render
through `.gmw_view3d()`. Zero `rgl::` calls remain in
`3dDigitize.geomorph.r`. The dead `.rgl_show()` helper and the
`rgl.useNULL` option were removed with it.

**PLT-02 — Morpho removed.** `Imports` is now geomorph, Rvcg, tcltk, tcltk2.
`Morpho`, `vegan` and `parallel` are gone; `rgl` and `htmlwidgets` moved to
`Suggests` with every call site guarded.

**PLT-03 — inherited.** `plotPCA` already routed through `.plot_show()` and
stays base-graphics 2-D. Verified, not rebuilt.

**Six Folsom PLY specimens** committed to `tests/fixtures/parity/` beside the
`.dgt` files that name them, `.Rbuildignore`d so they never ship in the package.

## Decisions worth remembering

**Classic script, not ES modules.** three.js ships ES modules only from 0.160,
and ES modules are CORS-blocked on `file://`. Bundling to an IIFE is what lets
Phase 1 stay transport-free while the same artifact works unchanged over
`httpuv` from Phase 2. Verified rendering from `file://` on both platforms. BVH
prototype patches are applied at bundle time, so `Mesh.raycast` is already
accelerated when Phase 4 arrives.

**`fastKmeans` reimplemented, not vendored.** Morpho is GPL-2 with no "or later"
clause, so vendoring would pin the combined work to GPL-2 exactly and forfeit
the upgrade path. Its only compiled contribution, `fastSubsetMeans`, is
O(k·n); `base::rowsum` does the same reduction in one O(n) pass. Measured: exact
numerical parity at k = 500/1000/2000, median 1.4x faster, and `vcgKDtree` is
86% of every iteration, so mesh size and not the means step is the lever for
larger scans.

**Native engine load made non-fatal.** `.onLoad` used to `stop()` when
`tkogl2` would not load, correct for GUImorph where the engine *was* the
viewport, wrong here where the browser is. It now records the diagnostic and
defers refusal to `GUImorphWeb()`. This is what let the package load on macOS
despite a `tkogl2.dylib` built against the wrong Tcl major version.

## Corrections made during the phase

**The rgl premise was doubted, wrongly.** Mid-phase, on the evidence of a Mac
*with* XQuartz where rgl loads fine, this work briefly recorded that rgl does
not actually fail to load and that PLT-02 was dependency hygiene rather than a
fix. `otool -L` on `rgl.so` settles it: three of its load-time dependencies live
under `/opt/X11`, so without XQuartz rgl cannot load and neither can any package
importing it. The original premise was correct. Full detail in `01-RESEARCH.md`.

**Two verification scripts reported artefacts as findings.** The parity script
took `sqrt()` of a distance `vcgKDtree` already returns unsquared, inflating
0.021 to 0.146. The benchmark timer took an expression rather than a closure, so
a promise was evaluated once and four of five reps timed a cached value, giving
medians of zero. `check-macos.R` tested `loadedNamespaces()` in a session where
its own earlier step had loaded rgl. All three fixed; worth remembering that a
measurement can fail quietly and still print a number.

## Open

- **PLT-02 needs a Mac without XQuartz.** The linkage predicts `library(rgl)`
  fails and `library(GUImorphWeb)` succeeds there. A prediction with a stated
  mechanism, not an assumption.
- **`tkogl2.dylib` rebuilt against R's Tcl** for macOS digitizing. Austin's,
  independent of Phase 1.
- **DAT-03 parity gate still `skip()`s.** Two `-rewrite` fixtures needed. See
  `.planning/todos/pending/dat-parity-gate-is-a-skip.md`.
- **Six red tests**, pre-existing since `2f65039` (June). Two call deleted
  functions; four stub `tcltk` via `assignInNamespace`, which R 4.6 forbids.
- **`iter.max = 100` too low at low slider counts.** Neither implementation
  converges at k = 500. Raising it changes template output, so it needs its own
  commit and its own evidence.
- **`test-rgl-fallback-macos.R` is a misnomer**, nothing in it concerns rgl.
- **Mean-shape mesh holes** appeared once and resolved; if the cause was the
  flat-shading path then nothing actually changed and it may recur.
