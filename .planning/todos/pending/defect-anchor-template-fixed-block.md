---
title: "DEFECT: template/downsample anchor mismatch silently corrupts surface semilandmarks"
status: open
kind: defect
scope: out-of-milestone
milestone: none (NOT part of the macOS port; pre-existing Windows behaviour)
priority: high
severity: silent-data-corruption
discovered: 2026-07-18
discovered_during: Phase 5 Windows validation (workflow exercise, not a port regression)
affects: [surface semilandmarks, template warp, GPA input, .dgt contents]
owner: eoc
---

## Scope note

This is **not** a macOS-port issue and does not belong to any phase of the macOS
milestone. It predates the port, reproduces entirely on Windows, and is unrelated
to every Phase 1-6 deliverable. Confirmed by diffing `3dDigitize.geomorph.r` and
`3dDigitize.surface.r` across the Phase 4/5 merge (`258bbfe..a98769a`): those
commits touched wheel normalization, a `max.iter` guard, and status warnings only.
The array assembly and the surface point accounting are untouched, original code.

Filed here as a testing/QA backlog item so the macOS work is not blocked by it.

## Symptom

`Compute` on the GPA tab fails with:

```
Error in coords.A[, , i] <- as.matrix(rbind(coords.lmk[, , i], surfaceMatrix)) :
  number of items to replace is not a multiple of replacement length
```

Reproduced with 2 specimens, 6 landmarks, 10 anchors, 1000 requested sliders.
Specimen 1 carried 1000 surface points, specimen 2 carried 990.

## Root cause

The template records no contract about its own layout. `buildTemplate` and
`downSample` each independently consult the live `useAnchorVar` checkbox, and
nothing detects when they disagree.

`buildTemplate` is correctly additive. Both branches request the full count:

```r
# anchors off -> nrow = landmarks + sliderNum
template <- rbind(lmk, fastKmeans(x = specimen, k = sliderNum, ...)$centers)
# anchors on  -> nrow = landmarks + anchors + sliderNum
template <- rbind(rbind(lmk, anc), fastKmeans(x = specimen, k = sliderNum, ...)$centers)
```

Anchors never displace k-means points. `k = sliderNum` either way.

`downSample` then splits the template using a fixed-block size derived from the
checkbox at that moment, not from the template:

```r
else if (tclvalue(e$useAnchorVar) == 1) {
  lmk   <- rbind(lmk, anc)
  fixed <- fixed + aFixed          # 6 -> 16
}
...
template.tps <- tps2d3d(template[-(1:fixed),], template[(1:fixed),], lmk)
```

Template built with anchors OFF (6 fixed + 1000 k-means = 1006 rows), then
downsampled with anchors ON (`fixed = 16`), yields `template[-(1:16),]` = 990
sliders. Ten k-means points are consumed off the front of the template as if they
were anchors.

## Why this is worse than a count mismatch

The same wrong `fixed` also drives the warp reference:

```r
template <- template * (cSize(lmk) / cSize(template[(1:fixed),]))
template <- template %*% rotate.mat(lmk, template[(1:fixed),])
template.tps <- tps2d3d(template[-(1:fixed),], template[(1:fixed),], lmk)
```

With `fixed = 16` against a 6-fixed template, reference rows 7-16 are arbitrary
k-means centres paired against hand-placed anchors. Centroid-size scaling,
rotation, and the TPS are all computed from a bogus correspondence. The affected
specimen's surface points are **misplaced, not merely miscounted**, and are written
to `.dgt` with no marker distinguishing them from valid data.

## Why a cross-specimen count check is not sufficient

If every specimen is downsampled with the *same* mismatched setting, all of them
lose the same 10 points, all counts agree, `gpagen` runs clean, and every specimen
was warped against a corrupt reference. Consistent misuse is silent. The 2026-07-18
failure was loud only because the setting changed between specimens.

The guard therefore belongs at the template/downsample boundary. A count check is
a backstop, not the fix.

## Proposed fix

1. **Template owns its layout.** Record the fixed-row count at build time:
   ```r
   e$templatePoints  <- template
   e$templateFixed   <- nrow(lmk)            # 6, or 16 with anchors
   e$templateSliders <- as.numeric(e$sliderNum)
   ```
2. **`downSample` reads `fixed` from the template**, never from the checkbox, and
   refuses on disagreement with a directional message:
   - template has anchors, checkbox off -> "This template includes N anchors.
     Enable Use Anchors, or rebuild the template."
   - template has no anchors, checkbox on -> "This template was built without
     anchors. Uncheck Use Anchors, or rebuild the template."
3. **Cross-specimen surface-count check before `gpagen`**, naming the offending
   specimen. Backstop for legacy files.
4. **UI:** once a template exists, the Surface tab anchor checkbox should lock or
   display the template's actual contract ("Template: A6_1_clean.ply, 6 landmarks
   + 10 anchors fixed, 1000 sliders"). Changing it requires rebuilding the template
   and re-downsampling every specimen; the UI should say so.

The GPA tab's `anchorsSurface` / `anchorsCurve` stay freely toggleable. Those are
per-analysis decisions, not per-dataset ones.

## Persistence / DAT-03 sequencing

Items 1-3 are in-session and cost nothing. A template reconstructed from a `.dgt`
carries no record of whether anchors were in the fixed block, so persisting it
implies a format field, which collides with the open DAT-03 byte-compatibility
gate. Two options, try the first:

- Derive it: `nfixed = nrow(template) - sliderNum`, if the slider count returned by
  `getTemplate` is trustworthy. No format change.
- Add the field and fold it into DAT-03 verification, since that format is being
  re-verified anyway.

## Related, lower stakes

`write.nts(as.numeric(e$sliderNum), ntsFile, selected.out)` writes the requested
slider count as the declared header while `selected.out` may hold a different
number. Same root cause, temp-file only.

## Data hygiene

Existing `.dgt` files written under a mismatched setting carry misplaced surface
coordinates and look normal. Quick screen: compare the `Surface=` counts across
specimens within one file. Unequal counts mean the file is suspect; equal counts
that disagree with the slider number entered are also a flag.

## Explicitly not the fix

Do not pad or truncate surface matrices to force counts to agree. Silent repair is
what produced this.
