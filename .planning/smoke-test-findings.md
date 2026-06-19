# GUImorph Smoke Test Findings

**Date:** 2026-06-13 (initial); **corrected 2026-06-15**  
**Environment:** Windows R, PowerShell, WSL UNC paths  
**DLL loaded:** MinGW `inst/libs/x64/tkogl2.dll` (deployed 2026-06-15)

---

## Correction (2026-06-15)

Initial session reported landmarks "not visible." **Retest confirmed landmarks work** — placement requires **double-click** on the 3D canvas (`addDot` via `<Double-Button-1>` in `bind.digitize`). Single-click triggers pick/select (`set dot selected`), which correctly returns "No dot selected" when no landmark exists at that pixel. **Not a render bug.**

**GSD impact:** DGT-01 validated; 04-01 complete; Phase 4 unblocked. Next: curves (04-02), `.dgt` save/reload (04-03).

---

## Session summary

| Step | Result |
|------|--------|
| `devtools::load_all(".")` | ✅ Success |
| `tkogl2.dll` load via `.onLoad` | ✅ Console confirmation + separator line |
| `GUImorph()` | ✅ Window opened; init tests passed (`setCurveScaleFactor`, `setLabelScaleFactor` → TRUE) |
| Load PLY (`C13.1.ply`) | ✅ Specimen **artifact visible** in 3D viewer (user confirmed) |
| Landmarks on specimen | ✅ **Visible after double-click placement** — initial single-click pick misread as failure (2026-06-15) |
| Startup errors | ✅ Fixed 2026-06-15 — `activeDataList` guards (`02-03`) |
| Package warnings | ⚠️ 26 warnings on `load_all` (not captured) |

---

## What this proves

**Validated (legacy DLL path):**
- Windows R + WSL UNC path works for package load
- Tcl/Tk extension loads; OpenGL stack sufficient to open GUI
- PLY file loads and **specimen mesh displays** in 3D viewer (`C13.1.ply`)

**Not yet validated / open issues:**
- Landmark placement workflow (DGT-01) — ✅ validated 2026-06-15 (double-click)
- Curves (DGT-02) — ✅ validated 2026-06-15 (04-02; see Phase 4 section)
- `.dgt` save (DGT-03) — ✅ validated 2026-06-15 (04-03; `test_fresh.dgt`)
- `.dgt` reload (DGT-04) — ✅ validated 2026-06-15 (04-03; `openDgt` same-session reload)
- geomorph analysis round-trip

---

## Issues to investigate

### 1. Startup `subscript out of bounds` — **FIXED 2026-06-15**

Guards added in `onPlaceAnchor`, `onNext`, `switchTab`, `updateWidgets.*`. See Phase 2 plan 02-03.

### 2. Landmarks "not visible" — **CLOSED: UX, not bug (2026-06-15)**

Initial report: no landmark dots after load; single-click at (360, 164) → `No dot selected`.

**Resolution:** Landmarks appear after **double-click** placement. Single-click is pick/select only (`set dot selected` in C). No code fix required for display path.

### 3. "No dot selected" on single-click — **Expected behavior**

Pick/select when no landmark at cursor — not placement. Use double-click to place (`addDot` in `3dDigitize.digitize.r`).

### 4. 26 warnings on load

Run `warnings()` in R to capture — likely deprecated APIs, missing documentation, or R 4.6 compatibility notices.

---

## Phase 4 — Curve Definition (04-02)

**Date:** 2026-06-15  
**Specimen:** `zips/Folsom 3D models/C13.1.ply`  
**Environment:** Windows R 4.6, WSL UNC paths, MinGW `tkogl2.dll`

| Step | Result |
|------|--------|
| `loadPly` curve slot `[[4]]` init (`matrix(0×3)`) | ✅ Commit `9d6b647` |
| Set landmark count = 3 | ✅ |
| Double-click 3 landmarks (Digitize tab) | ✅ Curves tab unlocked |
| Double-click 3 landmarks on Curves tab | ✅ `add("curve", 1, 2, 3)` — no R error |
| `activeDataList[[1]][[4]]` | ✅ 1×3 integer matrix (IDs 1, 2, 3) |
| Fit button | ✅ No crash; **no visible change** when view already at default rotation/zoom (see quirks) |
| Dormant curve UI (Set curves number, Compute Curves) | ✅ Not visible (D-01) |

**UAT notes (2026-06-15):** User confirmed landmarks, curve bind, and tab flow work. Two UX observations logged as documentation-only per D-12 (not code fixes in Phase 4):

1. **Curve display is chord segments, not a surface-following spline** — legacy `add("curve", id1, id2, id3)` draws straight red segments between the three selected landmark IDs in order. With landmarks at tip (1), bottom-left (2), and bottom-right (3), the 1→2 segment cuts diagonally across the specimen silhouette. Expected legacy behavior; semi-landmark resampling requires dormant **Compute Curves** (out of scope D-01).
2. **Fit appears to do nothing** when the specimen has not been rotated or zoomed — `onFit()` resets `activeDataList[[imgId]][[6]]` (angles) and `[[7]]` (zoom) to zero (`3dDigitize.main.r`). If already at default, no visible change. D-04 smoke pass: click does not crash or hang.

**Workflow quirks (document, do not fix in Phase 4):**
- Default landmark count is **5** — user must **Set number of landmarks** to 3 before Curves tab unlocks with only 3 placements.
- Curve tab landmark selection requires **double-click** on existing dots (parallel to DGT-01 single-click pick trap).
- Dormant curve management buttons intentionally disabled (D-01).

---

---

## Phase 4 — Save/Reload (04-03)

**Date:** 2026-06-15  
**Specimens:** `C13.1.ply` + `C8.1.ply`  
**Save file:** `zips/Folsom 3D models/test_fresh.dgt` (local only, D-17)

### DGT-03 — Multi-specimen save ✅

| Check | Result |
|-------|--------|
| `saveToDgt` 2-specimen session | ✅ No error dialog |
| `Curve=1` + IDs `1 2 3` | ✅ Lines 1–2 |
| Two `LM3=3` sections | ✅ Lines 1019, 1029 |
| `ID=C13.1.ply` + `ID=C8.1.ply` | ✅ Lines 1025, 1035 |
| `Surface=0` both specimens | ✅ Lines 1027, 1037 |
| Console | `Writing data for : 2 specimens` |

### DGT-04 — Same-session reload ✅

**Validated 2026-06-15** after three blocker fixes (see below). User confirmed: File → Load DGT File → `test_fresh.dgt` completes without error; landmarks and curves restore in same GUImorph session.

| Check | Result |
|-------|--------|
| `openDgt` parses 2 specimens + curves | ✅ |
| `drawElements` loads PLY + landmarks | ✅ (after `queryFromR` / `e` scope fix) |
| `Surface=0` files do not abort reload | ✅ |
| Curves in `activeDataList[[1]][[4]]` | ✅ 1×3 matrix (per D-05: curve on specimen 1 only) |

**Blockers fixed during UAT:**
1. `read.surface` — invalid `printf()`; vacuous `all(is.na())` on `Surface=0` empty array
2. `openDgt` — hard abort on NULL surfaceData
3. `draw.digitize` / `rtkogl.R` — `add("queryFromR")` referenced out-of-scope `e`
4. `drawElements` — landmark probe used `digitize[,,0]` (empty in R) instead of `[,,1]`

### Known multi-specimen UX issues (document only — D-12, out of Phase 4 fix scope)

1. **Specimen-1 curve redrawn on specimen 2** — When switching to specimen 2 and opening the Curves tab, `switchTab` id==3 reads curves from `activeDataList[[1]][[4]]` (always specimen 1) and calls `add("curve", 1, 2, 3)` with `SetCurveIndex` set to current specimen. Result: specimen 1's chord segments overlay on specimen 2's mesh (red dashes across wrong geometry). Logs show `SetCurveIndex 2` but curve IDs still `1 2 3` from global slot `[[1]][[4]]`.
2. **Per-specimen curve bind on specimen 2 is awkward** — Landmark IDs restart at 1 per specimen in C, but R curve matrix is global to specimen 1 slot. Defining a second curve on specimen 2 conflicts with existing curve data from specimen 1. Phase 4 test plan only required curve on specimen 1 (D-05).
3. **Landmark placement precision** — Occasional `not inside the specimen` or `No dot (curve) selected` requires click retry (same as DGT-01 double-click precision).

**Future work:** Per-specimen curve storage in `activeDataList[[specId]][[4]]`, clear C curve state on specimen switch, and/or suppress curve redraw when `currImgId > 1` and no per-specimen curve exists.

---

## Recommended next steps

1. **Phase 5 — geomorph analysis** — ANAL-01 through ANAL-03
2. **Capture warnings** — `warnings()` after `load_all` (D-10)

---

## Console reference (user session)

```
> load_all(".")
ℹ Loading GUImorph
[1] "File 3dDigitize.main ... function .onload"
[1] ".../inst/libs/x64/tkogl2.dll"
[1] "-----------------"
There were 26 warnings (use warnings() to see them)

> GUImorph()
[1] "ui.main ... starting"
... init date strings ...
[1] TRUE

> [1] "LOADPLY : selected  1 specimen files"
[1] "File name  1 is :  //wsl$/Ubuntu/home/akagi/home/GUImorph/zips/Folsom 3D models/C13.1.ply"
[1] "Tested for file existence : there are  1  specimen files found"
[1] "add specimen result is : "
[1] "End of function load ply ... specimen should be displayed"
[1] "set dot selected ... WARNING : No dot (landmark) selected at 360 164"
```

---

## Phase 5 — GPA Round-Trip (05-02)

**Date:** 2026-06-19  
**Fixture:** `zips/Folsom 3D models/test_fresh.dgt` (2 specimens, 3 landmarks each, landmarks-only)  
**Environment:** Windows R 4.6, WSL UNC paths, geomorph 4.x via `@import`

### UAT results

| Step | Result | Notes |
|------|--------|-------|
| Load `test_fresh.dgt` | ✅ | Both specimens (C13.1.ply, C8.1.ply) load |
| Initial specimen display | ⚠️ | C viewer shows specimen 2 until Next→Previous; fixed in code (`showPicture` after openDgt) |
| Landmark visual on specimen 2 | ✅ | Duplicate-landmark bug fixed (`e$lmkLoadedInC` tracker) |
| GPA tab — sliding checkboxes OFF | ✅ | Landmarks-only path (D-01) |
| **Compute** | ✅ | `gpagen` converges (3 LM × 2 specimens, 2 iterations); console summary printed |
| **Plot Aligned Specimens** | ⚠️ | No visible window in UAT session; likely needs `rgl` and/or window behind Tk GUI — `plotspecs()` now surfaces errors via dialog + `open3d`/`bringtotop` |
| **Save Result** | ✅ | `gpa_test.csv` non-empty (Csize + aligned coords for 2 specimens) |

### API fixes applied (05-02)

- `geomorph::gpagen`, `plotAllSpecimens`, `two.d.array` namespace qualification
- `.gm_aligned_coords()` / `.gm_results_or_warn()` for `$coords` vs legacy `$coord`
- `plot.param` → `plot_param`; `as.numeric(max.iter)`
- `.landmarks_for_specimen()` — C-layer duplicate guard + `activeDataList[[10]]` fallback for GPA
- `draw.digitize` — `e$lmkLoadedInC` prevents re-adding landmarks on specimen switch

### Quirks (document only, not fixed in 05-02)

- **Plot** may require `install.packages("rgl")` on Windows R; Alt+Tab if rgl window opens behind GUImorph
- **openDgt initial view** was last-loaded specimen until `showPicture(e)` pin to specimen 1
- ProcD checkbox defaults ON (legacy `tclVar(1)`); explicit `ProcD=` passed to `gpagen` — behavior preserved
- Phase 4 curve overlay on specimen 1 only (D-05/D-12); curve chord segments on Digitize tab unchanged

### Migration closure (05-03)

**Date:** 2026-06-19  
**Scope:** ANAL-02 + ANAL-03 closure per D-08/D-10

| Item | Status |
|------|--------|
| HOT-path `gpagen` / `two.d.array` / `plotAllSpecimens` | ✅ Migrated to geomorph 4.x (05-02) |
| `summary(e$gm.results)` | ✅ Base R; no blocking warnings |
| Vendored `geomorph.support.code.r` procD suite | **DEFERRED** — not reachable from landmarks-only GPA (D-10) |
| Morpho `fastKmeans` (×3) | **DEFERRED** — surface downsampling only; GPA UAT not blocked |
| No new vendored-code call sites | ✅ Grep confirmed |

**Inventory:** `.planning/phases/05-analysis-round-trip/05-INVENTORY.md` — Migration Status section updated.

---

## Phase 6 — renv Baseline + Warning Triage (06-01)

**Date:** 2026-06-19  
**Environment:** Windows R 4.6.0 (ucrt), repo on WSL UNC path (`\\wsl$\Ubuntu\...`)  
**Status:** ✅ Checkpoint 1 approved — renv in sync; GUI + `.dgt` load validated

| Step | Result | Notes |
|------|--------|-------|
| `renv::init()` + implicit snapshot | ✅ | R 4.6.0 recorded in lockfile; geomorph, rgl, RRPP pinned |
| `renv::restore()` (fresh session) | ✅ | In sync |
| `devtools::load_all(".")` | ✅ | tkogl2.dll loads |
| `GUImorph()` + specimen `.dgt` load | ✅ | User confirmed |
| Warning HOT/DEFERRED triage | ✅ | 26 warnings — all DEFERRED (see below) |

### Warning inventory (post-renv baseline, D-20)

**Count:** 26  
**Classification:** **All DEFERRED** — no HOT warnings (D-19)

| # | Source | Message pattern | HOT/DEFERRED | Rationale |
|---|--------|-----------------|--------------|-----------|
| 1–14, 22–26 | `file.info(path)` on package root | `cannot resolve owner of file '\\wsl$\...'`: Incorrect function | DEFERRED | WSL UNC metadata quirk; `load_all` succeeds |
| 15–21 | `file.info(file)` on `R/*.R` | Same UNC owner-resolution error per source file | DEFERRED | devtools/roxygen path scan over UNC; no missing symbols |

**HOT:** none — workflow not blocked (`load_all`, tkogl2, GUI, `.dgt` all pass).

**Contributor note (D-09):** These warnings are **maintainer-local** to WSL UNC paths. Contributors on a normal Windows clone (`C:\dev\GUImorph\...`) are unlikely to see them. Do not fix in Phase 6.

**Artifacts to commit:** `renv.lock`, `.Rprofile`, `renv/activate.R`, `renv/settings.dcf` (if present). Do not commit `renv/library/`.

---

## Phase 6 — BUILD.md UAT (06-02)

**Date:** 2026-06-19 (pending human UAT)  
**Status:** ⏳ Docs + deploy script written; MSYS2 native build UAT not yet run

| Step | Result | Notes |
|------|--------|-------|
| Root `BUILD.md` | ✅ | Prerequisites through troubleshooting + WSL appendix link |
| `scripts/deploy-dll.ps1` | ✅ | RepoRoot resolution, Src validation, `.bak` backup |
| `tkogl2/BUILD.md` restructure | ✅ | Windows-native primary; WSL cross-compile appendix |
| MSYS2 native build UAT (A1) | ⏳ | Human verify per plan 06-02 Task 3 |
| deploy + GUI smoke after deploy | ⏳ | Human verify per D-16 |

