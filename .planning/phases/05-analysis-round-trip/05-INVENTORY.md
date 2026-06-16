# Phase 5: geomorph / Morpho Call-Site Inventory

**Requirement:** ANAL-02  
**Created:** 2026-06-16  
**Scope:** `R/3dDigitize.*.r`, `R/geomorph.support.code.r`, `R/rtkogl.R`  
**Package:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`  
**geomorph target:** 4.1.0 per `.planning/research/STACK.md`

## Summary Table

| Function | File:Line | Tier | Phase 5 action |
|----------|-----------|------|----------------|
| `geomorph::gpagen` | `3dDigitize.geomorph.r:224` | HOT | fix — verify `max.iter` numeric coercion; ProcD explicit from checkbox |
| `summary` (on gpagen result) | `3dDigitize.geomorph.r:237` | HOT | document — base R `summary()` on gpagen list; no geomorph API change |
| `geomorph::two.d.array` | `3dDigitize.geomorph.r:251` | HOT | fix — input must be `$coords` (`.gm_aligned_coords` helper added) |
| `geomorph::plotAllSpecimens` | `3dDigitize.geomorph.r:264` | HOT | fix — `plot.param` → `plot_param` per geomorph 4.x |
| `getLandmark` | `3dDigitize.main.r:1699` | HOT (bridge) | verify — C/Tcl coordinate extraction before `gpagen`; not geomorph |
| `@import geomorph` | `3dDigitize.main.r:20` | HOT (package) | document — DESCRIPTION/NAMESPACE import; CRAN gpagen used |
| `@import Morpho` | `3dDigitize.main.r:26` | SURFACE | document — surface downsampling only |
| `Morpho::fastKmeans` | `3dDigitize.surface.r:274` | SURFACE | defer — inventory only per D-09 unless GPA UAT blocked |
| `Morpho::fastKmeans` | `3dDigitize.surface.r:290` | SURFACE | defer — inventory only per D-09 |
| `Morpho::fastKmeans` | `3dDigitize.surface.r:361` | SURFACE | defer — inventory only per D-09 |
| `read.ply` (commented) | `3dDigitize.surface.r:246,326,416` | VENDORED-DEFER | document — migrated to `Rvcg::vcgPlyRead` in 2017 |
| Vendored procD / gpagen suite | `geomorph.support.code.r` (~2814 lines) | VENDORED-DEFER | defer — not reachable from landmarks-only GPA per D-10 |
| *(none)* | `rtkogl.R` | — | confirm — no geomorph/Morpho calls |

**Search command used:**

```bash
rg -n 'geomorph::|Morpho::|gpagen|two\.d\.array|plotAllSpecimens|procD\.|read\.ply|fastKmeans' \
  integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/
```

---

## 1. GPA Hot Path (`3dDigitize.geomorph.r`)

Landmarks-only GPA (D-01): `compute()` → `gpagen` → `summary` → `plotspecs` / `save`.

| Call | Line | Qualified? | Notes |
|------|------|------------|-------|
| `geomorph::gpagen` | 224 | yes (`geomorph::`) | `A=coords.A`, `curves`/`surfaces` NULL when checkboxes OFF; `max.iter = tclvalue(e$maxiter)` is **character** — coerce in 05-02 if UAT warns |
| `summary(e$gm.results)` | 237 | n/a | Prints gpagen result to console after Compute |
| `geomorph::two.d.array` | 251 | yes | Uses `.gm_aligned_coords()` fallback `$coords` / legacy `$coord` |
| `geomorph::plotAllSpecimens` | 264 | yes | Still passes `plot.param=` — **breaking** in geomorph 4.x (`plot_param`) |

**Global handoff:** `compute()` assigns `e$gm.results` and `gm.results` to `.GlobalEnv` (line 236). `plotspecs()` / `save()` read via `.gm_results_or_warn()`.

**Not on hot path for Phase 5 smoke test:** surface/curve sliding branches in `compute()` (lines 161–221) — keep checkboxes OFF per D-01.

---

## 2. Morpho Surface Path (`3dDigitize.surface.r`)

Per D-09: inventory only unless blocking GPA UAT.

| Call | Line | Context |
|------|------|---------|
| `Morpho::fastKmeans` | 274 | `buildTemplate` — no anchors (`useAnchorVar == "0"`) |
| `Morpho::fastKmeans` | 290 | `buildTemplate` — with anchors (`useAnchorVar == "1"`) |
| `Morpho::fastKmeans` | 361 | `buildTemplate1` — alternate template builder |

All three use current Morpho signature: `fastKmeans(x, k, iter.max, project)`. **No Phase 5 fix required** for landmarks-only GPA.

Historical: commented `read.ply` references (lines 246, 326, 416) — replaced by `Rvcg::vcgPlyRead` per 2017 migration notes.

---

## 3. Bridge Layer (`3dDigitize.main.r`)

| Symbol | Line | Role |
|--------|------|------|
| `@import geomorph` | 20 | Package-level import |
| `@import Morpho` | 26 | Package-level import |
| `ui.geomorph` / GPA tab | 479–486 | Tab wiring; `switchTab` id=4 |
| `getLandmark` | 1699 | C bridge via `shows("landmark", "xyz", id)` — feeds `coords.A` |
| `get_geomorph_date` / `get_geomorph_support_date` | 512–513 | Startup version stamps only |

No direct geomorph function calls in `3dDigitize.main.r` beyond imports and GPA tab setup.

---

## 4. Vendored `geomorph.support.code.r` — DEFERRED (D-10)

~100 function definitions; **2020 fork** vendored into package. **No `3dDigitize.*.r` file calls these symbols** (grep confirmed). Not reachable from landmarks-only GPA tab.

### Function families (representative)

| Family | Examples | geomorph 4.x status |
|--------|----------|---------------------|
| Core GPA helpers | `pGpa`, `.pGpa`, `pGpa.wSliders`, `.pGpa.wSliders` | Superseded by CRAN `gpagen` (pure R since 4.0) |
| Semilandmark sliding | `semilandmarks.slide.tangents.BE`, `semilandmarks.slide.surf.procD`, `semilandmarks.slide.tangents.surf.procD`, … | Internal to vendored GPA; unused by GUI |
| ProcD sliding | `procD.slide`, `.procD.slide`, `BE.slide`, `.BE.slide` | Vendored only |
| procD.fit suite | `procD.fit`, `procD.fit.lm`, `procD.fit.int` | Deprecated pattern; CRAN uses `procD.lm` + RRPP |
| advanced.procD.lm helpers | `single.factor`, `cov.extract`, `ls.means`, `slopes`, `leveler`, `multileveler` | Comments reference `advanced.procD.lm`; **no `advanced.procD.lm` definition** in file — helper comments only |
| SS / permutation | `SS.iter`, `.SS.iter`, `SS.pgls.iter`, `perm.index`, `boot.index` | Future analysis; not GPA tab |
| PLS / TPS / plotting | `pls`, `tps`, `tps2d`, `tps2d3d` | Not called from active GUI paths |
| Utility | `mshape`, `center`, `csize`, `orp`, `two.d.array` (internal copy at line 1026) | Duplicates CRAN geomorph |

**Phase 5 action:** defer — document only; do not refactor or delete (D-10, D-11).

---

## 5. Known API Risks (from STACK.md + codebase review)

| Risk | Source | Impact | 05-02 action |
|------|--------|--------|--------------|
| `gpagen` default `ProcD=FALSE` since geomorph 4.0 | STACK.md | GUImorph checkbox defaults ON (`tclVar(1)`); explicit `ProcD=` passed — behavior preserved when checkbox ON | document in UAT |
| Return field `$coords` not `$coord` | geomorph 4.x gpagen Value | `save()` path | **partially fixed** via `.gm_aligned_coords()` |
| `plot.param` renamed to `plot_param` | geomorph 4.x `plotAllSpecimens` | Plot Aligned Specimens ignores custom sizes | **fix in 05-02** |
| `advanced.procD.lm`, `procD.allometry`, `nested.update` deprecated | STACK.md | Vendored helpers only — not on hot path | defer |
| `plotTangentSpace` deprecated → `gm.prcomp` + plot fns | STACK.md | Not called by GUImorph GUI | defer |
| `max.iter` as character from Tcl entry | `3dDigitize.geomorph.r:227` | Subtle coercion / iteration warnings | fix if UAT fails |
| `plotAllSpecimens` 3D may need `rgl` | geomorph Suggests | Plot step error on Windows R | install `rgl` at UAT if needed |
| Internal C removed from `gpagen` | geomorph 4.0 | Pure R — no tkogl2 interaction | none |

---

## 6. `rtkogl.R`

Confirmed: **no** `geomorph`, `Morpho`, `gpagen`, `two.d.array`, or `plotAllSpecimens` references. OpenGL/Tcl layer is independent of analysis packages.

---

## Downstream: Plan 05-02 Priority

Fix order for GPA UAT (D-08):

1. `plot_param` rename in `plotspecs()` (line 265)
2. Confirm `$coords` / `two.d.array` path in `save()` (lines 248–251)
3. Optional `as.numeric(tclvalue(e$maxiter))` in `gpagen` call (line 227)
4. Windows R UAT: Compute → Plot → Save CSV with `test_fresh.dgt`

Morpho `fastKmeans` and vendored `geomorph.support.code.r` remain **out of scope** unless UAT is blocked.
