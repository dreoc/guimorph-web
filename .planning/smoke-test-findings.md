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

**Date:** 2026-06-19  
**Environment:** Windows PowerShell, WSL UNC repo path  
**Status:** ⏳ Deploy script verified; GUI smoke after deploy pending user confirm

| Step | Result | Notes |
|------|--------|-------|
| Root `BUILD.md` | ✅ | Committed in `db55a3b` |
| `scripts/deploy-dll.ps1` | ✅ | Fixed ASCII throw string (em-dash broke PS parser); exit 0 |
| Deploy backup `.bak` | ✅ | Prior `inst/libs/x64/tkogl2.dll` (1,242,624 B, 2020) → `tkogl2.dll.bak` |
| Deploy swap | ✅ | WSL MinGW `build/tkogl2.dll` (883,519 B, 2026-06-13) → `inst/libs/x64/` |
| MSYS2 native build UAT (A1) | **DEFERRED** | Maintainer used existing WSL cross-compile artifact (Option B) |
| Post-deploy GUI smoke (D-16) | ✅ **After rollback** | Restored `.bak` (1.2 MB 2020 DLL); mesh + `.dgt` visuals confirmed — user approved Checkpoint 2 |

**Recovery applied:** `Copy-Item tkogl2.dll.bak → tkogl2.dll` — do not deploy `build/tkogl2.dll` until UAT'd for render.

**Deploy command (verified mechanically):**

```powershell
cd \\wsl$\Ubuntu\home\akagi\home\GUImorph
powershell -ExecutionPolicy Bypass -File scripts/deploy-dll.ps1
```

---

## Phase 7 — Dispatch Extraction (07-01)

**Date:** 2026-06-20  
**Specimen:** `zips/Folsom 3D models/C8.1.ply`  
**Environment:** Windows R 4.6, WSL UNC paths, Phase 7 `tcl_dispatch.c` extraction build  
**DLL:** Post-07-01 deploy (commits `d1be586`, `0f12e12`); compare against `inst/libs/x64/tkogl2.dll.pre-phase7.bak`

| Step | Result | Notes |
|------|--------|-------|
| Build + `Tkogl2_Init` export | ✅ | CMake includes `tcl_dispatch.c`; build succeeds per maintainer |
| `devtools::load_all(".")` | ✅ | (assumed — user reached GUI) |
| `GUImorph()` opens | ✅ | Init tests pass |
| Load PLY (`C8.1.ply`) | ⚠️ **FAIL** | Mesh visible but renders **black** (not vertex-colored as with pre-Phase-7 DLL) |
| Double-click landmark placement | ⚠️ **FAIL** | 3 existing red dots (labels 1, 2, 3); **cannot place new dots** |
| Rotation / interaction | ✅ | No crash on rotate |

### Investigation summary (07-01 debugger)

**Dispatch extraction (`tcl_dispatch.c`):** Compared `onDisplay`, `drawDots`, `getSpecimenCoordinate`, and `add("dot")` paths against pre-extraction structure. Handler logic appears verbatim from `tcl_if_ZARF_9.c` via `scripts/extract-tcl-dispatch.py`. Gap line ranges (2991–3152, 4139–5062, 5134–5274) remain in `tcl_if_ZARF_9.c` (logging, snapshot, helpers) — not dropped. Commit `0f12e12` added missing `extern` refs for `GBL_*`, `resetContext`, and curve/model globals in the dispatch TU.

**No confirmed extraction regression** in the digitize hot path. **No code fix applied** pending A/B DLL evidence.

### Black mesh — likely cause

| Hypothesis | Likelihood | Evidence |
|------------|------------|----------|
| **2026 MinGW build render regression** (pre-existing) | **High** | Phase 6 §06-02: 2026 `build/tkogl2.dll` blank/wrong render; **rollback to 2020 `.bak` restored colored mesh** |
| Dispatch `onDisplay` / GL state leak | Low | `onDisplay` body unchanged; `ogl_drawModel` still toggles `ogl_disableLight` + `GL_COLOR_ARRAY` for colored PLY |
| C8.1.ply never had colors | Low | `ogl_model_ply` requires color property for load success; user reports colored mesh with backup DLL |

**Recommended check:** A/B swap `tkogl2.dll` ↔ `tkogl2.dll.pre-phase7.bak` (same PLY, no R code changes). If backup is colored and Phase 7 build is black → **build/render issue**, not dispatch logic.

### Cannot place dots — likely cause

| Hypothesis | Likelihood | Evidence |
|------------|------------|----------|
| **R landmark quota** (`dotNum >= e$landmarkNum`) | **High** | `addDot()` in `3dDigitize.digitize.r` silently skips when `activeDataList[[3]] >= landmarkNum`; 3 dots visible + count preset **3** → expected no-op (Phase 4 documented same quirk) |
| C `validateDot` / `getSpecimenCoordinate` regression | Medium | Would print `WARNING : add dot : not inside the specimen` in R console; check console on failed double-click |
| `dot_add` failure in C | Low | Would set Tcl WARNING result; same console signature |

**Recommended check:** On double-click, read R console for `dotNum raw : N -of- M`. If `N >= M`, increase **Set number of landmarks** (default 5) before retest. If WARNING appears, capture log for `validateDot` / `getSpecimenCoordinate`.

### User retest protocol

1. **A/B DLL (primary):**
   ```powershell
   cd \\wsl$\Ubuntu\home\akagi\home\GUImorph\integrated-guimorph-development_EOC\Project\GUImorphDevelopment\inst\libs\x64
   Copy-Item tkogl2.dll tkogl2.dll.phase7-test -Force   # save current
   Copy-Item tkogl2.dll.pre-phase7.bak tkogl2.dll -Force
   ```
   Restart R → `load_all` → `GUImorph()` → load `C8.1.ply` → confirm mesh color.

2. **Landmark quota:** Set landmark count to **5**; with 3 dots placed, double-click should allow dots 4–5 if C path OK.

3. **Restore Phase 7 DLL** after A/B:
   ```powershell
   Copy-Item tkogl2.dll.phase7-test tkogl2.dll -Force
   ```

4. **Optional C log:** `add("openLogFile", -1, 0)` before digitize; inspect `DATA_LOG_FILES/DL_*.txt` for `ADD/SHAPE/DOT`, `validateDot`, `getSpecimenCoordinate`.

### CONFIRMED ROOT CAUSE (2026-06-20, A/B + source diff)

User completed the A/B DLL swap and confirmed:
- **Phase 7 fresh MinGW build** (`tkogl2.dll.phase7-test`, compile banner `15 AUGUST 2020 04:22 PM`) → mesh **black** (PLY via openDgt) / **blank** (PLY via menu load).
- **Pre-Phase-7 `.bak`** (1.24 MB **2020 MSVC-era prebuilt** DLL) → **restores full functionality**.

**The black/blank render is a property of the 2026 MinGW-w64 build pipeline, NOT the dispatch extraction.** This is the same regression Phase 6 §06-02 deferred ("do not deploy `build/tkogl2.dll` until UAT'd for render" — they shipped the 2020 `.bak` as a workaround). The MinGW build (`CMakeLists.txt` + `tcl_stub_bootstrap.c` + `glut_shim`, 883 KB) has **never** been render-validated; the only working DLL is the 2020 MSVC build.

**Dispatch extraction proven faithful:** a line-level content diff of the original god file (5580 lines) against the union of the current `tcl_dispatch.c` + trimmed `tcl_if_ZARF_9.c` shows the union contains **all** original code — the only differences are 4 forward declarations (now in `tcl_dispatch.h`), one duplicated comment, and a redundant `static UT_MY_INTEGER_VALUE` line. No code was dropped, duplicated, or altered. Build links cleanly with library semantics. So the extraction itself does not change runtime behavior.

**Other observations (pre-existing, separately tracked):**
- Blank canvas after `openDgt` + Next/Prev → `999.2-opendgt-first-specimen-display` (there is even a disabled `if(0)` "forcibly switch specimens" patch in `openDgt`).
- "Cannot place dots" with 3/3 → landmark quota full (set count > placed to add more).
- Double `< Previous` / `Next >` buttons → Tk repaint cosmetic; source creates the nav frame once in `ui.main` → `createNavFrame`.

**Implication for Phase 7:** Phase 7 is a pure C refactor whose only verification gate (07-01/02/03 smoke) requires building a render-correct DLL from source. That is **blocked** by the unresolved 2026 MinGW build/render regression. Phase 7 cannot be smoke-verified until the build pipeline produces a working DLL — independent of the (correct) extraction.

**Status (superseded):** Initially blocked by MinGW build regression; resolved 2026-06-21 — see "07-01 smoke gate — PASSED" below.

### CORRECTION + ACTUAL ROOT CAUSE (2026-06-20, MSVC build)

The "build-toolchain regression" framing above was **incomplete**. After making the build
MSVC-native (`CMakeLists.txt`), a fresh MSVC build was produced and tested:

- The C engine works correctly under MSVC — `queryFromR` now returns real counts
  (e.g. `dot slice length for slice [1] is [3]`) and `validateDot` passes. (With the older
  prebuilt `.bak`, `queryFromR` returned empty strings.)
- **Render is still blank** under MSVC (MinGW had rendered a black silhouette).

**True root cause — uninitialized `HWND` (latent UB), `tcl_if_ZARF_9.c` setWindow "id":**
```c
HWND hwnd;                                        // 64-bit, upper 32 bits = stack garbage
Wrapper_GetIntFromObj(interp, objv[2], (int*)&hwnd);  // writes only low 32 bits
...
setWindowId(hwnd);  // -> GetDC(bad handle) -> no GL surface -> blank viewport
```
The Tk window id is a 32-bit Tcl int; HWND is 64-bit on Win64. Only the low 32 bits were
written, leaving the upper 32 uninitialized. This "worked by luck" in the 2020 MSVC build
and (zero-upper-bits) under MinGW, but MSVC 19.37 Release codegen leaves garbage there →
`GetDC` fails → blank. **Fix applied:** zero-init and assign via `(HWND)(INT_PTR)hwndId`.

**Black mesh is partly the data, not a bug:** the Folsom PLYs (`C13.1.ply` etc.) declare
`property uchar red/green/blue` but every vertex color is `0 0 0` (NextEngine geometry-only
scan). `ogl_drawModel` takes the color path → flat-black mesh. A visible *shaded* render
requires falling back to lighting when colors are absent/all-zero (optional follow-up).

**Toolchain note still valid:** MSVC remains the correct build (matches the working DLL);
MinGW additionally mis-renders. But the *blank* was the HWND UB, not the toolchain.

**Misc:** the `15 AUGUST 2020` console banner is a hardcoded `COMPILE_INFORMATION[]` string
literal in `tcl_if_ZARF_9.c`, not the real build date — builds are fresh.

### DEFINITIVE DIAGNOSIS (2026-06-21, GLDIAG instrumentation) — HANDOFF FOR NEW CHAT

Added runtime `printf` diagnostics (tag `GLDIAG`) to `setWindowId` and `onDisplay`. Fresh
MSVC build, deployed, `C13.1.ply` loaded. Console showed:

```
GLDIAG setWindowId: hwnd=0x230BC8 dc=0x15011CAD pf=7 rc=0x30000 makeCurrent=1
                    ver=<4.6.0 Build 32.0.101.7026> renderer=<Intel(R) Iris(R) Xe Graphics>
GLDIAG onDisplay: w=600 h=600 model_amount=1 showModel=2 models=0x.. context=0x..
                  scale=1.000000 count=558732 color=yes glerr=0
GLDIAG draw: vtx0=(-0.2756,0.4266,0.0005) col0=(0.000,0.000,0.000,0.900) drawErr=0
GLDIAG swap: SwapBuffers=1
```

**Conclusion — the C engine and OpenGL are FULLY WORKING:**
- Valid GL 4.6 context (Intel Iris Xe), `makeCurrent=1`.
- Model loaded: `count=558732` verts, sane coords (`vtx0≈(-0.28,0.43,0.0)`), color array present.
- `drawErr=0`, `glerr=0`, `SwapBuffers=1` — the frame renders and presents with no errors.
- Clear color was changed to **gray** for the test, yet the visible viewport **stayed white**.

**ROOT CAUSE (still open): the GL context renders to a surface that is NOT the visible Tk
canvas.** This is an **R/Tk window/compositing problem**, not C, not the build toolchain, not
the 07-01 extraction. The doubled "Specimen Id" label + doubled Previous/Next buttons in the
GUI are the same issue surfacing as Tk repaint ghosting. `ui.main` runs exactly once (single
`"ui.main ... starting"`), so the doubling is a paint artifact, not duplicate widget creation.

**Definitively RULED OUT this session:**
- Dispatch extraction (07-01) — proven content-faithful by line diff.
- MSVC vs MinGW toolchain — MSVC also blank (engine works under both).
- Stale DLL — GLDIAG prints are new code and appear; `glerr` went 1280→0 after a source fix.
- HWND truncation — fixed; context now created fine.
- GL_INVALID_ENUM (1280) — was `glLightModeli(GL_FRONT,...)`; fixed.
- PLY data — colors are genuinely all-zero (black); secondary, mesh would be a black
  silhouette once it actually displays.

**Fixes applied this session (real, keep):**
- `tcl_if_ZARF_9.c` setWindow "id": zero-init HWND, assign via `(HWND)(INT_PTR)hwndId`.
- `ogl_ZARF9.c` `ogl_enableLight`: `glLightModeli(GL_FRONT,...)` → `GL_LIGHT_MODEL_TWO_SIDE`
  + `glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE)` (was GL_INVALID_ENUM).
- `tcl_if_ZARF_9.c`: `COMPILE_INFORMATION` now uses `__DATE__ " " __TIME__` → the console
  banner prints `FRESH BUILD <date> <time>` so DLL freshness is always verifiable.
- `3dDigitize.main.r` `ui.main`: `tcl("update","idletasks")` around `set("window","id",...)`
  to realize the canvas HWND before GL binds (attempt at the window-surface bug).

**Diagnostics still in tree (REMOVE once fixed):**
- Gray clear color in `ogl_ZARF9.c` `ogl_init` (was `glClearColor(1,1,1,0)`).
- `GLDIAG` `printf`s in `setWindowId` (`tcl_if_ZARF_9.c`) and `onDisplay` + draw/swap
  (`tcl_dispatch.c`).

**Next-chat starting hypotheses (R/Tk ↔ GL compositing):**
1. Tk erases the `canvasFrame` background (white) on every `<Expose>`/`<Configure>`,
   overpainting GL. Fix: bind `<Expose>`/`<Configure>` on `canvasFrame` to re-trigger
   `onDisplay` via the existing `add("invoke_on_display", 0,0,0)` shape.
2. Embedding WGL in a plain `tkframe` may need a dedicated child HWND with
   `WS_CLIPCHILDREN`/no background-erase; verify `tkwinfo id canvasFrame` is the real
   drawing surface, not a parent.
3. Diff `ui.main` / canvas construction in `3dDigitize.main.r` history against the era when
   the 2020 `.bak` rendered, to spot a window-setup regression.
4. The 2020 `.bak` may have rendered continuously or owned the window differently — confirm
   whether this source EVER rendered with a fresh build (vs always shipping the `.bak`).

**Build/deploy reference (Windows MSVC, verified working):**
```
cmake --build build-msvc --config Release   # in .../Project/tkogl2
# copy build-msvc/Release/tkogl2.dll -> GUImorphDevelopment/inst/libs/x64/tkogl2.dll
# restart R fully (DLL stays mapped while R runs)
```

### RESOLVED: blank viewport (2026-06-21)

The `tcl("update","idletasks")` calls around `set("window","id", canvasFrame)` in `ui.main`
**fixed the blank viewport.** Confirmed by user: PLY load renders, landmarks can be placed,
and the freshness banner now prints `FRESH BUILD Jun 21 2026 11:39:44` (proves rebuild→deploy
works). Root cause was binding the WGL context to the canvas HWND before Tk had realized the
window; forcing realization first makes GL render into the visible canvas.

### Black mesh = all-zero PLY vertex colors (fix applied 2026-06-21)

Remaining symptom: `load .dgt` renders both specimens flat black. GLDIAG showed
`col0=(0.000,0.000,0.000,0.900)` — the Folsom PLYs declare `uchar red/green/blue` but every
vertex is `0 0 0` (geometry-only NextEngine scans), so the color path draws a black mesh.
**Fix:** `ogl_model_ply_ZARF_9.c` now detects an all-zero color array during vertex read,
frees `model->color`, and leaves it NULL → `ogl_drawModel` uses the lighting path → shaded
visible surface. Also added `glEnable(GL_NORMALIZE)` in `ogl_init` for correct lighting under
model scaling. Pending user confirmation that the mesh now renders shaded (not black).

**Cleanup still owed once render is confirmed good:** revert the gray diagnostic clear color
in `ogl_ZARF9.c` `ogl_init` back to white, and remove the `GLDIAG` `printf`s from
`setWindowId` (`tcl_if_ZARF_9.c`) and `onDisplay`/draw/swap (`tcl_dispatch.c`).

### 07-01 smoke gate — PASSED (2026-06-21)

User confirmed all blocking symptoms resolved after MSVC rebuild + deploy:

| Step | Result | Notes |
|------|--------|-------|
| `devtools::load_all(".")` | ✅ | MSVC `tkogl2.dll`; freshness banner via `__DATE__`/`__TIME__` |
| `GUImorph()` | ✅ | Window opens; no doubled Previous/Next buttons |
| Load PLY (`C13.1.ply`) | ✅ | Shaded mesh visible (not blank/black) |
| Load `.dgt` (2 specimens) | ✅ | Both specimens render shaded (not flat black) |
| Double-click landmark | ✅ | Placement works |
| Rotation / interaction | ✅ | No crash |

**Real fixes kept (beyond dispatch extraction):**
- `tcl_if_ZARF_9.c`: zero-init HWND, assign via `(HWND)(INT_PTR)hwndId` (blank viewport).
- `ogl_ZARF9.c`: `glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, …)` + `glColorMaterial` (was `GL_INVALID_ENUM`); `glEnable(GL_NORMALIZE)`.
- `ogl_model_ply_ZARF_9.c`: drop all-zero vertex color arrays → lighting path for geometry-only scans.
- `3dDigitize.main.r`: `tcl("update","idletasks")` around canvas HWND bind (blank viewport + Tk ghosting).
- `CMakeLists.txt` + `BUILD.md`: MSVC-first build path.

**Diagnostics removed (2026-06-21):** gray clear color and `GLDIAG` printfs reverted/removed after smoke pass.

**Deferred (not blocking 07-01):**
- **PLY vertex coloration** — Folsom PLYs declare `red/green/blue` but store all zeros (NextEngine geometry-only scans). Current behavior: shaded lighting fallback. Future work: preserve/display true scan coloration when present, or document expected appearance for zero-color PLYs.
- MinGW build path — links but renders incorrectly; MSVC remains the supported toolchain.

**Status:** ✅ **07-01 smoke PASSED.** Dispatch extraction validated end-to-end. Proceed to 07-02 (window/WGL extraction).

---

## Phase 7 — Window Extraction (07-02)

**Date:** 2026-06-21  
**Change:** Extract `setWindowId`, `setWindow`, and `dc`/`width`/`height` → `tcl_window.c`/`tcl_window.h`  
**Build:** MSVC rebuild + deploy on Windows

| Step | Result | Notes |
|------|--------|-------|
| `tcl_window.c`/`tcl_window.h` created | ✅ | WGL + setWindow handler moved verbatim |
| God file trimmed | ✅ | No setWindow/setWindowId bodies; dc/width/height defs removed |
| CMake updated | ✅ | `tcl_window.c` added after `tcl_dispatch.c` |
| BUILD.md updated | ✅ | Phase 7 layout includes `tcl_window.c` |
| MinGW/WSL link build | ✅ | Link + `Tkogl2_Init` export verified |
| `load_all` + `GUImorph()` | ✅ | User approved — WGL init via setWindow id branch |
| Load PLY (`C13.1.ply`) | ✅ | Mesh renders |
| Window resize | ✅ | Viewer redraws without crash |
| Double-click landmark | ✅ | Placement works |

**Status:** ✅ **07-02 smoke PASSED.** Window/WGL module validated. Proceed to 07-03 (state/log/init extraction).

---

## Phase 7 — Modularization Complete (07-03)

**Date:** 2026-06-21  
**Change:** Final god-file split — `tcl_state.c`, `tcl_log.c`, `tcl_init.c`; `tcl_if_ZARF_9.c` removed from build  
**Build:** MSVC rebuild + deploy on Windows (MinGW link verified on WSL)

### Module layout (final)

| File | Responsibility |
|------|----------------|
| `tcl_init.c` | `Tkogl2_Init`, 8 Tcl command registrations |
| `tcl_dispatch.c` | Tcl handlers, draw pass, `onDisplay` |
| `tcl_window.c` | `setWindowId`, WGL, `setWindow`, `dc`/`width`/`height` |
| `tcl_state.c` | Globals, `initialize_state`, `resetContext`, alloc wrappers |
| `tcl_log.c` | `simpleLog*`, command stream, debug writers |

### Part A — Per-plan smoke (D-05)

| Step | Result | Notes |
|------|--------|-------|
| Five-module CMake build | ✅ | No `tcl_if_ZARF_9.c`; MinGW link + `Tkogl2_Init` export |
| `load_all` + `GUImorph()` | ✅ | User approved |
| Load PLY (`C13.1.ply`) | ✅ | Mesh renders |
| Double-click landmark | ✅ | Placement works |

### Part B — Full digitize round-trip (D-06)

| Step | Result | Notes |
|------|--------|-------|
| Load 2 specimens or `test_fresh.dgt` | ✅ | User approved |
| 3 landmarks per specimen | ✅ | Double-click |
| Curve bind on specimen 1 | ✅ | 3-landmark IDs |
| Fit click | ✅ | No crash |
| Save `.dgt` | ✅ | Local file |
| Same-session `openDgt` reload | ✅ | Landmarks + curve restore |

**CENG-01 validation:** God file split into five `tcl_*` modules with no regression vs Phase 4 digitize baseline.

**Status:** ✅ **07-03 smoke PASSED. Phase 7 complete.**

---

## Phase 8 — C Engine Deduplication (08-03 UAT)

**Date:** 2026-06-22  
**Specimen / fixture:** `C13.1.ply`; `zips/Folsom 3D models/test_dgt_anchors_curves.dgt` (landmarks + curve + anchor)  
**Environment:** Windows R 4.6, MSVC `tkogl2.dll` (unified `marker.c` build)  
**Rollback:** `inst/libs/x64/tkogl2.dll.pre-phase8.bak` (316,416 B — pre-Phase-8 baseline, D-13)

### Deploy

| Step | Result | Notes |
|------|--------|-------|
| MSVC `build-msvc/Release/tkogl2.dll` → `inst/libs/x64/` | ✅ | Commit `0118a8e`; 312,832 B |
| Pre-Phase-8 backup preserved | ✅ | `tkogl2.dll.pre-phase8.bak` untouched |

### UAT results (D-04, D-03, D-10, D-11)

| Check | Result | Notes |
|-------|--------|-------|
| Landmark place / select / move / delete | ✅ | Parity with pre-Phase-8 baseline (D-04) |
| Anchor place / select / move / delete | ✅ | Selected anchor moves/deletes correctly (D-03/D-10) |
| `.dgt` save → same-session `openDgt` reload | ✅ | Landmarks + curve + **anchor** restore (D-11) |
| Anchor-id +1 discrepancy (A1) | ✅ | Coordinate-based flows correct; no blocking id-getter issue observed |

### Gap fixes applied during UAT (not in original 08-02 scope)

| Issue | Root cause | Fix | Commit |
|-------|------------|-----|--------|
| `del("dot")` / `del("anchor")` error | R `del()` referenced missing `arg1..arg3` | Default args; `tcl("del","dot")` / `tcl("del","anchor")` → `*_del_selected` | `195b568` |
| Moving anchor moved landmark | `setDot coordinate` always called `dot_move`; legacy relied on D-03 asymmetry | Route `anchor_move` when `showModel==ANCHOR` | `220ee51` |
| Selection imprecise (rotation fall-through) | Click reads sphere-surface depth ~radius from stored mesh-center; hit box was equal to draw radius | `GBL_SELECT_TOLERANCE_FACTOR=3.0` on select | `065e895` |
| `.dgt` load: `object 'e' not found` | `draw.anchors` used `e$anchorsPresentInMemory` without `e` param | `draw.anchors(e, id, anchors)` + call-site updates | `45bfeec` |

### CENG-02 validation

- `dot_ZARF_9.c` removed; `marker.c` + thin wrappers serve all dispatched `dot_*` / `anchor_*` names
- Anchor selection uses per-set `g_anchors` state (D-03 fix observable in UAT)
- Landmark behavior preserved (D-04)
- `Tkogl2_Init` exported from MSVC Release build (08-02)

**Status:** ✅ **Phase 8 UAT PASSED.** C engine deduplication complete. Proceed to Phase 9 (numbered globals / debug cleanup).

---
