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

## Verification still owed

`geomorph (>= 4.1.1)` is assumed rgl-free on the basis of current CRAN metadata.
Confirm against the installed version before closing the phase:

```r
packageDescription("geomorph")$Imports
packageDescription("geomorph")$Depends
```

If rgl appears there, PLT-02 is still blocked and geomorph needs the same
treatment.
