# Phase 1 Research: Result Plots + rgl Demotion

**Status:** complete
**Date:** 2026-07-23
**Requirements touched:** PLT-01, PLT-02, PLT-03

## Question

PLT-02 as originally written said "move `rgl` from `Imports` to `Suggests` so the
package loads where rgl cannot." Is that sufficient to make `library(GUImorphWeb)`
succeed on a host where `library(rgl)` fails?

## Finding: no. Morpho was the blocker, not rgl.

Dependency survey of the declared `Imports`:

| Package | Used for | Pulls rgl? |
|---|---|---|
| geomorph | GPA and analysis, heavy | No. Current CRAN `Imports` are graphics, grDevices, stats, utils, jpeg, ape, parallel, ggplot2, plotly |
| Rvcg | `vcgPlyRead`, `vcgKDtree`, `vcgBallPivoting`, `vcgClost` | No. rgl is in Rvcg's **Suggests** |
| **Morpho** | **`fastKmeans` only, 3 call sites** | **Yes. `Imports: Rvcg, rgl (>= 0.100.18), foreach, Matrix, MASS, ...`** |
| vegan | **nothing. Zero call sites in `R/`** | No |
| parallel | **nothing. Zero call sites in `R/`** | No |
| rgl | `.rgl_show`, plus two already-guarded plot functions | itself |
| htmlwidgets | `saveWidget`, only inside `.rgl_show` | No |

`NAMESPACE` declared `import(Morpho)`, a wholesale namespace import, so Morpho
loaded at package load time and took rgl with it. Moving rgl to `Suggests` while
that line stood would have changed nothing.

Two incidental findings: `vegan` and `parallel` are declared and imported
wholesale but have no call sites anywhere in `R/`. Both were removed.

`3dDigitize.geomorph.r` already guarded both rgl plot functions with
`requireNamespace`, so that half of PLT-02 was largely done.

## Decision: reimplement `fastKmeans`, do not vendor it

GUImorphWeb used exactly one Morpho function. Three options were considered.

**Keep Morpho.** Rejected: it is the rgl edge, and the package is carrying an
entire dependency for one function.

**Vendor Morpho's source.** Legally clean (Morpho is GPL-2, this package is
GPL >= 2, with credit and license header preserved) but rejected on two grounds.
GPL-2 has no "or later" clause, so vendoring pins the combined work to GPL-2
exactly and forfeits the upgrade path, which matters given the open-core plan.
And `fastSubsetMeans` is RcppArmadillo with OpenMP, so it reintroduces a compile
step, which is the thing this milestone exists to remove.

**Reimplement.** Chosen. See below: the compiled part of Morpho's function is not
where its speed comes from.

## Why reimplementation does not cost speed

`Morpho::fastKmeans` is an R function. Its expensive step is
`Rvcg::vcgKDtree` (C++) for nearest-centre assignment and `Rvcg::vcgClost` for
projection. Both are Rvcg, already a dependency, rgl-free. The only
Morpho-specific compiled code is `fastSubsetMeans`, 36 lines of RcppArmadillo
computing per-cluster means by looping over k clusters and calling
`find(inds == i)` inside the loop, rescanning the full n-length assignment vector
once per cluster: O(k·n), parallelised with OpenMP.

`base::rowsum` performs the same reduction in one O(n) pass in C.

## Measurements

`scripts/bench-group-means.R`, A6_1_clean.ply, 71014 vertices, median of 5,
inner-looped past Windows timer granularity. Per-call seconds:

| k | rowsum | split+vapply | split.data.frame | Matrix crossprod | vcgKDtree |
|---|---|---|---|---|---|
| 500 | 1.25e-3 | 4.22e-3 (3.4x) | 4.06e-3 (3.3x) | 3.28e-3 (2.6x) | 7.81e-3 |
| 1000 | 1.25e-3 | 5.63e-3 (4.5x) | 5.62e-3 (4.5x) | 3.28e-3 (2.6x) | 7.81e-3 |
| 2000 | 1.33e-3 | 8.75e-3 (6.6x) | 9.06e-3 (6.8x) | 2.73e-3 (2.1x) | 7.97e-3 |

All four means implementations agree exactly (max deviation 0).

`rowsum` is flat in k, the O(n) signature. The list approaches scale with k
because of per-group call overhead. The sparse approach is flat but 2 to 2.6x
slower and would add Matrix as a dependency.

**`vcgKDtree` is 86% of every iteration at all three k.** The means step is 14%
with `rowsum`. Making it free would save 14%; switching to lists would raise it
to 35-53% and slow each iteration by 1.4x to 2x.

End-to-end against `Morpho::fastKmeans`, same seed, `iter.max = 200`:

| k | Morpho (s) | new (s) | speedup | max deviation |
|---|---|---|---|---|
| 500 | 1.36 | 1.08 | 1.26x | 0 |
| 1000 | 1.33 | 0.95 | 1.40x | 0 |
| 2000 | 0.96 | 0.51 | 1.88x | 0 |

Exact numerical parity at every k. Speedup rises with k, consistent with
O(k·n) versus O(n) in the step that differs.

## Two side findings

**`iter.max = 100` is too low at low slider counts.** At `iter.max = 100` the two
implementations differed by 0.021 coordinate units at k = 500 while agreeing
exactly at k = 1000 and k = 2000. Cause: Morpho's loop is
`while (cnt < iter.max)` with `cnt` starting at 1, so it runs 99 iterations
against this implementation's 100. Neither had converged at k = 500. At
`iter.max = 200` both converge and agree exactly. All three production call sites
pass `iter.max = 100`, so **low slider counts are currently producing
unconverged templates**. Counterintuitive but consistent: fewer, larger clusters
take longer to settle.

**Nothing in the package called `set.seed`.** `fastKmeans` initialises centres by
`sample()`, so digitising the same specimen twice produced a different surface
template. Template construction is now seeded from
`GUIMORPHWEB_TEMPLATE_SEED <- 42L`, with the caller's `.Random.seed` saved and
restored so scripted use is unaffected. The initialisation idiom deliberately
mirrors Morpho's `sample(1:n)[1:k]` rather than the tidier `sample.int(n, k)`,
because the two consume the RNG stream differently; matching it is what let the
parity check assert equality rather than approximation.

## Consequences for the roadmap

- PLT-02 rewritten: it is a Morpho removal, not an rgl demotion.
- **Follow-on, not in this phase:** the lever for large scans is n, not the means
  step. `Rvcg::vcgQEdecim` to a few hundred thousand faces before clustering,
  then `vcgClost` the resulting centres onto the full-resolution original, attacks
  the 86%. Deliberately deferred so PLT-02 stays a dependency change rather than
  a behaviour change.
- **Open question:** raise `iter.max` at the call sites, or leave it. Raising it
  changes existing template output, so it is a behaviour change and belongs in
  its own commit with its own parity evidence.

## Verification (macOS 26.5.2, arm64, R 4.6.1)

### Why rgl is a hard dependency on macOS, mechanically

`otool -L` on the installed `rgl.so`:

```
/opt/X11/lib/libGLU.1.dylib
/opt/X11/lib/libGL.1.dylib
/opt/X11/lib/libX11.6.dylib
/System/Library/Frameworks/GLKit.framework/.../GLKit
```

Three of rgl's shared-library dependencies live under `/opt/X11`, which is
XQuartz. These are ordinary load-time dependencies, so on a Mac without XQuartz
`dyn.load()` cannot resolve them, `library(rgl)` errors, and **any package with
rgl in `Imports` fails to load with it**. That is the failure PLT-02 exists to
remove, and it is structural rather than incidental.

Two distinct macOS behaviours follow, and they were conflated during this work:

| XQuartz | rgl | Effect on a package importing rgl |
|---|---|---|
| absent | cannot load: unresolved `/opt/X11` libraries | package cannot load at all |
| present | loads, then `rgl.init()` fails `GLXBadContext` and falls back to the null device | package loads; interactive 3-D is dead |

The test machine has XQuartz, so it exhibits the second row. It cannot reproduce
the first, which is why PLT-02 could not be closed empirically there. The
`otool` linkage settles it anyway: the first row is a property of how rgl is
built, not a machine-specific accident.

**Correction to the record.** Mid-phase this document's premise was doubted on
the evidence of that XQuartz-equipped Mac, and the removal of Morpho was briefly
described as dependency hygiene rather than a fix for a load failure. The
linkage above shows the original premise was correct. Removing Morpho is
load-bearing: it was the only thing pulling rgl into `Imports`, and with it gone
the package no longer requires XQuartz to load on macOS.

### What the macOS run did verify

- **Package loads with a broken native engine.** `tkogl2.dylib` is built against
  Tcl 9.0 while R 4.6.1's tcltk links a different major version, so the engine
  refuses to load. `.onLoad` previously called `stop()`, which took every
  browser path down with it. It now records the diagnostic and defers refusal to
  `GUImorphWeb()`. The package loads, and result plots, the viewport, GPA and
  export all work without the engine. Pinned by a regression test.
- **`file://` works on macOS.** The viewport opened at
  `file:///private/var/folders/.../index.html` and rendered. This is the
  constraint the classic-script bundle exists for, now confirmed on both
  platforms: three.js ships ES modules only from 0.160, and ES modules are
  CORS-blocked on `file://`.
- **Rvcg reads the PLY fixtures** at full resolution (A6_1: 71014 verts,
  142008 faces), so the Phase 2 mesh path has its input on macOS.
- **geomorph is rgl-free at 4.1.1.** `Imports` is graphics, grDevices, stats,
  utils, jpeg, ape, parallel, ggplot2, plotly; `Depends` is RRPP, R, Matrix.

### Still owed

- **A Mac without XQuartz.** The `otool` linkage predicts `library(rgl)` fails
  and `library(GUImorphWeb)` succeeds there. That is the last empirical step for
  PLT-02, and it is now a prediction with a stated mechanism rather than an
  assumption.
- **`"rgl" %in% loadedNamespaces()` after a clean `load_all`.** The first
  version of `scripts/check-macos.R` tested this in a session where its own
  earlier step had already called `loadNamespace("rgl")`, so it reported a
  failure that was an artefact of the script. Now run in a `callr` subprocess.
- **`tkogl2.dylib` rebuilt against R's Tcl.** Needed for macOS digitizing;
  independent of Phase 1.
