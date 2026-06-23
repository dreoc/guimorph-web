# Phase 5: Analysis Round-Trip - Pattern Map

**Mapped:** 2026-06-15
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| File | Role | Closest Analog | Match |
|------|------|----------------|-------|
| `R/3dDigitize.geomorph.r` | GPA controller | self | exact |
| `R/3dDigitize.main.r` | `getLandmark`/`getAnchor`, GPA tab switch | self (`openDgt` handoff) | exact |
| `R/geomorph.support.code.r` | vendored geomorph helpers | defer — not hot path | reference |
| `R/3dDigitize.surface.r` | Morpho `fastKmeans` | inventory only | partial |
| `.planning/smoke-test-findings.md` | validation log | Phase 4 append pattern | exact |

**Package root:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`

## GPA Hot Path (landmarks-only)

```114:196:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r
compute <- function(e) {
  # ... getLandmark loop → coords.lmk ...
  # when surfaces checkbox OFF:
  coords.A <- array(coords.lmk, dim = c(as.numeric(e$landmarkNum), 3, nSpecimen))
  e$gm.results <- gpagen(A=coords.A, curves = curves, surfaces = surfaces, ...)
  assign(x = "gm.results", value = e$gm.results, envir = envir)
}
```

```1699:1719:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
getLandmark <- function(id) {
  lmkStr <- tclvalue(shows("landmark", "xyz", id))
  # ... matrix parse ...
}
```

## Phase 4 Handoff Pattern

Reuse `test_fresh.dgt` → `openDgt` → `e$activeDataList` populated → GPA tab reads via `getLandmark(i)` — same as post-digitize session without re-placing landmarks.
