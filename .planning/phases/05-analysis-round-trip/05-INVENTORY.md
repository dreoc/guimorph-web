# Phase 5: geomorph / Morpho Call-Site Inventory

**Requirement:** ANAL-02  
**Created:** 2026-06-16  
**Scope:** `R/3dDigitize.*.r`, `R/geomorph.support.code.r`, `R/rtkogl.R`  
**Package:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`  
**geomorph target:** 4.1.0 per `.planning/research/STACK.md`

## Summary Table

| Function | File:Line | Tier | Phase 5 action |
|----------|-----------|------|----------------|
| `geomorph::gpagen` | `3dDigitize.geomorph.r:239` | HOT | **DONE** — `as.numeric(max.iter)`, explicit `ProcD=` (05-02) |
| `summary` (on gpagen result) | `3dDigitize.geomorph.r:252` | HOT | **DONE** — base R `summary()`; no geomorph API change |
| `geomorph::two.d.array` | `3dDigitize.geomorph.r:266` | HOT | **DONE** — `.gm_aligned_coords()` → `$coords` (05-02) |
| `geomorph::plotAllSpecimens` | `3dDigitize.geomorph.r:289` | HOT | **DONE** — `plot_param` per geomorph 4.x (05-02) |
| `getLandmark` | `3dDigitize.main.r:1699` | HOT (bridge) | **DONE (N/A)** — C/Tcl bridge; `.landmarks_for_specimen()` fallback (05-02) |
| `@import geomorph` | `3dDigitize.main.r:20` | HOT (package) | **DONE** — CRAN geomorph 4.x via package import |
| `@import Morpho` | `3dDigitize.main.r:26` | SURFACE | **DEFERRED** — surface downsampling only; not on landmarks-only GPA path |
| `Morpho::fastKmeans` | `3dDigitize.surface.r:274` | SURFACE | **DEFERRED** — surface downsampling only; not on landmarks-only GPA path |
| `Morpho::fastKmeans` | `3dDigitize.surface.r:290` | SURFACE | **DEFERRED** — surface downsampling only; not on landmarks-only GPA path |
| `Morpho::fastKmeans` | `3dDigitize.surface.r:361` | SURFACE | **DEFERRED** — surface downsampling only; not on landmarks-only GPA path |
| `read.ply` (commented) | `3dDigitize.surface.r:246,326,416` | VENDORED-DEFER | **DEFERRED** — migrated to `Rvcg::vcgPlyRead` in 2017 |
| Vendored procD / gpagen suite | `geomorph.support.code.r` (~2814 lines) | VENDORED-DEFER | **DEFERRED** — Phase 5 scope per D-10; reachable when curve/surface sliding GPA enabled |
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
| `geomorph::gpagen` | 239 | yes (`geomorph::`) | `max.iter = as.numeric(tclvalue(...))`; explicit `ProcD=` from checkbox — geomorph 4.x compatible |
| `summary(e$gm.results)` | 252 | n/a | Base R `summary()` on gpagen list; no API migration needed |
| `geomorph::two.d.array` | 266 | yes | `.gm_aligned_coords()` → `$coords` / legacy `$coord` fallback |
| `geomorph::plotAllSpecimens` | 289 | yes | `plot_param=` (geomorph 4.x); `rgl` optional with error dialog |

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

Fix order for GPA UAT (D-08) — **all applied 2026-06-19 (05-02)**:

1. ✅ `plot_param` rename in `plotspecs()` (line 294)
2. ✅ `$coords` / `two.d.array` path in `save()` via `.gm_aligned_coords()` (lines 263–266)
3. ✅ `as.numeric(tclvalue(e$maxiter))` in `gpagen` call (line 242)
4. ✅ Windows R UAT: Compute → Save CSV with `test_fresh.dgt` (Plot quirk documented)

Morpho `fastKmeans` and vendored `geomorph.support.code.r` remain **out of scope** unless UAT is blocked.

---

## Migration Status (2026-06-15)

Re-audit completed 2026-06-19 (plan 05-03). No new calls into vendored `geomorph.support.code.r` (grep confirmed). `summary(e$gm.results)` prints gpagen output without blocking Compute.

| Function | Tier | Status | Reference / note |
|----------|------|--------|------------------|
| `geomorph::gpagen` | HOT | **DONE** | 05-02 — `as.numeric(max.iter)`, `ProcD=` explicit |
| `summary` (gpagen result) | HOT | **DONE** | Base R; no geomorph API change |
| `geomorph::two.d.array` | HOT | **DONE** | 05-02 — `.gm_aligned_coords()` for `$coords` |
| `geomorph::plotAllSpecimens` | HOT | **DONE** | 05-02 — `plot_param`; rgl error dialog |
| `getLandmark` / `.landmarks_for_specimen` | HOT (bridge) | **DONE** | 05-02 — C + `activeDataList[[10]]` fallback |
| `@import geomorph` | HOT (package) | **DONE** | CRAN geomorph 4.x |
| `@import Morpho` | SURFACE | **DEFERRED** | Surface downsampling only; not on landmarks-only GPA path |
| `Morpho::fastKmeans` (×3) | SURFACE | **DEFERRED** | Surface downsampling only; not on landmarks-only GPA path |
| `read.ply` (commented) | VENDORED-DEFER | **DEFERRED** | Replaced by `Rvcg::vcgPlyRead` (2017) |
| Vendored procD / gpagen suite | VENDORED-DEFER | **DEFERRED** | Phase 5 scope per D-10; reachable when curve/surface sliding GPA enabled |
| `rtkogl.R` | — | **N/A** | No geomorph/Morpho calls |

**ANAL-03 scope note:** Hot-path `gpagen` / `plotAllSpecimens` / `two.d.array` / `save()` migrated to geomorph 4.x CRAN APIs. Full vendored `procD.lm` / `advanced.procD.lm` replacement deferred per D-10 — not reachable from landmarks-only GPA tab.
