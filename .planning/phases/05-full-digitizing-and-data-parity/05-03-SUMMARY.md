---
phase: 05-full-digitizing-and-data-parity
plan: 03
subsystem: ui
tags: [three.js, view3d, digitizing, anchors, curves, surface-cloud, bvh, sendBeacon, offline]

# Dependency graph
requires:
  - phase: 05-full-digitizing-and-data-parity
    provides: "05-02 token-guarded /anchor /curve /delete /undo /specimen loopback routes + .gmw_session server-owned digitizing record"
  - phase: 04-picking-parity
    provides: "view3d.R pointer pick pipeline (worldToLocal raw-PLY frame), addOverlayDot, eager computeBoundsTree BVH, relative sendBeacon('pick') idiom, 8192-byte HEAD/BODY split"
provides:
  - "Browser digitizing view layer in GMW_VIEW3D_TEMPLATE: anchor placement (green non-raycast group), curve-by-index selection with cyan/blue recolor, surface semilandmark THREE.Points cloud, delete/undo/specimen-switch controls"
  - "Specimen-switch mesh reload with computeBoundsTree() BVH rebuild on the new pickMesh (never a stale tree)"
  - "Five new relative sendBeacon targets wired to the 05-02 routes: anchor, curve, delete, undo, specimen"
  - "tests/testthat/test-digitizing-view3d.R source-scan gate (24 assertions)"
affects: [05-04, 05-05, 05-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Digitizing mode toggle (landmark/anchor/curve/delete) gating separate pointerdown listeners; landmark pick guarded to landmark mode so Phase-4 wiring is unregressed"
    - "Anchors and surface points live in dedicated scene-sibling groups NEVER passed to intersectObject(pickMesh,false) — overlays can never be re-hit (T-4-07)"
    - "Curve segment = three landmark INDICES resolved from nearest overlay dot (placement order == overlay.children order), not coordinates"
    - "Edit writes are fire-and-forget relative sendBeacon; response-bearing reads (specimen re-serve, post-edit redraw) use relative same-origin fetch, both JSON-free bare-CSV"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-digitizing-view3d.R
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R

key-decisions:
  - "Mode is a BODY-level var toggled by keys (a/c/l/d); the existing landmark pointerdown early-returns unless mode==landmark, keeping Phase-4 pick behavior byte-identical in the default mode"
  - "Curve/anchor/delete each get their own pointerdown listener rather than branching the existing one, so the three tasks stay atomic and the Phase-4 handler is edited only by a one-line mode guard"
  - "Cyan is new THREE.Color(1/255,164/255,191/255) and the blue slider is new THREE.Color(0,0,1), matching native onSelectCurve recolor exactly"
  - "Surfaces are display-only THREE.Points fed by an R .gmw_flat bare-CSV string (redrawSurfaces); the browser never recomputes surfaces"
  - "Specimen switch is RE-SERVE (A4): sendBeacon('specimen',n) records the switch, a fetch retrieves the new mesh URL, loadSpecimen() reloads + computeBoundsTree() rebuilds the BVH and re-places overlays"
  - "Post-edit redraw and specimen re-serve reads target relative same-origin fetch seams (redraw, specimen) that R answers; an unimplemented seam 404s harmlessly, mirroring 05-02's forward-call route pattern"

patterns-established:
  - "Second/third overlay groups (anchors, surfaces) are scene siblings kept out of the raycast set — the T-4-07 non-recursive-intersect invariant generalizes from landmarks to every marker kind"
  - "New template JS lives entirely in the parameter-free BODY after the MESH_URL marker; the sprintf HEAD stays at 776 bytes (cap 8192)"
  - "Single-quoted R template string forbids apostrophes in JS comments — reword to avoid, do not rely on escaping"

requirements-completed: [DGT-01, DGT-02]

coverage:
  - id: D1
    description: "Anchor placement raycasts the mesh and reports the mesh-local hit to /anchor, drawing a green (0x00ff00) dot in a second `anchors` group that is never an intersectObject target"
    requirement: "DGT-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-view3d.R#anchor placement wires a green non-raycast overlay group (DGT-01)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Curve mode resolves a click to the nearest existing landmark overlay dot INDEX, recolors point 1 cyan (1/255,164/255,191/255) and point 2 blue (0,0,1), and on the third distinct index posts i,j,k to /curve"
    requirement: "DGT-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-view3d.R#curve mode resolves clicks to landmark indices with cyan/blue recolor (DGT-01)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Surface semilandmarks arrive as an R-flattened bare-CSV point cloud and render as a THREE.Points layer in a dedicated `surfaces` group (display-only)"
    requirement: "DGT-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-view3d.R#surface semilandmarks render as a THREE.Points cloud layer (DGT-02)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Delete/undo/specimen controls post to /delete, /undo, /specimen; specimen switch loads the re-served mesh URL and rebuilds the BVH via computeBoundsTree() on the new pickMesh"
    requirement: "DGT-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-view3d.R#delete/undo/specimen controls post to their routes and rebuild the BVH (DGT-02)"
        status: pass
    human_judgment: false
  - id: D5
    description: "All new digitizing JS lives in the parameter-free BODY; the sprintf'd HEAD stays under the 8192-byte cap and the template assembles without a sprintf error"
    verification:
      - kind: unit
        ref: "tests/testthat/test-digitizing-view3d.R#all digitizing JS stays in the parameter-free BODY (HEAD under the 8192-byte sprintf cap)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Phase-4 interactive pick + overlay + replay wiring unregressed by the mode guard"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-view3d.R (all blocks)"
        status: pass
    human_judgment: false
  - id: D7
    description: "End-to-end browser digitizing UAT: place anchors (green), define a curve by three placed dots (cyan→blue→complete), display/delete a surface point, undo, and switch specimens with overlays following the correct specimen and picks landing on the new mesh"
    requirement: "DGT-01, DGT-02"
    verification: []
    human_judgment: true
    rationale: "three.js pointer interaction and multi-mesh visual behavior cannot run in the headless sandbox (no browser/display); recorded as an executable Manual-Only step in 05-VALIDATION.md."

# Metrics
duration: 14min
completed: 2026-08-07
status: complete
---

# Phase 5 Plan 03: Browser Digitizing View Layer (Anchors, Curves, Surfaces, Delete/Undo/Switch) Summary

**The `view3d.R` template now drives the full acquisition workflow in the browser — green non-raycast anchors, curve-by-landmark-index with cyan/blue feedback, a display-only surface THREE.Points cloud, and delete/undo/specimen-switch controls (with a per-switch BVH rebuild) — all reporting over the 05-02 loopback routes inside the 776-byte sprintf HEAD.**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-08-07T15:54:00Z
- **Completed:** 2026-08-07T16:08:00Z
- **Tasks:** 3
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- `addAnchorDot(worldPoint)` draws green `0x00ff00` dots into a new `anchors` `THREE.Group` that is a scene sibling and never a raycast target; anchor mode reuses the Phase-4 pick pipeline verbatim (single Y-flip NDC → `intersectObject(pickMesh,false)` → `updateWorldMatrix` → `worldToLocal`) reporting to `/anchor`.
- Curve mode resolves a click to the nearest overlay dot INDEX via `nearestOverlayIndex`, recolors point 1 cyan and point 2 blue (the slider), and posts `i,j,k` to `/curve` on the third distinct index, then resets.
- `addSurfaceCloud`/`redrawSurfaces` render R-flattened surface semilandmarks as a `THREE.Points` layer in a dedicated `surfaces` group (display-only — never recomputed in the browser).
- Delete mode resolves the nearest landmark/anchor/surface marker to `kind,idx` and posts `/delete`; `doUndo` posts `/undo`; `switchSpecimen` posts `/specimen`, loads the re-served mesh URL, and `loadSpecimen` rebuilds the BVH with `computeBoundsTree()` on the new `pickMesh` while clearing + re-placing overlays (Pitfall 4 — never a stale tree).
- Source-scan gate `test-digitizing-view3d.R` (24 assertions) is green; the Phase-4 `test-picking-view3d.R` (20 assertions) remains green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Wave-0 scaffold — failing template source-scan** - `55b4d92` (test)
2. **Task 2: Anchor pick (green group) + curve-by-index cyan/blue recolor** - `2b638bc` (feat)
3. **Task 3: Surface point cloud + delete/undo/specimen-switch UI** - `e35e031` (feat)

_TDD-style: Task 1 is the RED scaffold (15 failed / 9 passed pre-implementation); Tasks 2–3 turn it GREEN (24 passing assertions)._

## Files Created/Modified
- `tests/testthat/test-digitizing-view3d.R` — source-scan (readLines + grepl, `skip_if_no_pkg_source()`) asserting the anchor green non-raycast group, curve cyan/blue recolor, five new sendBeacon targets, a THREE.Points surface layer, the specimen-switch `computeBoundsTree` rebuild, and the reconstructed 8192-byte HEAD cap.
- `R/view3d.R` — all additions in the parameter-free template BODY: `mode` toggle + mode keys, `anchors` group + `addAnchorDot`, anchor/curve `pointerdown` listener + `nearestOverlayIndex` + cyan/blue colors, `surfaces` group + `addSurfaceCloud`/`redrawSurfaces`, delete `pointerdown` listener, `redraw`/`doUndo`/`loadSpecimen`/`switchSpecimen`, and a one-line `mode !== "landmark"` guard on the existing pick handler.

## Decisions Made
- **Mode-guarded pick, separate listeners:** the existing landmark `pointerdown` gets a one-line `mode !== "landmark"` early-return; anchor/curve and delete each get their own listener. Keeps the three tasks atomic and Phase-4 pick behavior byte-identical in the default mode.
- **Curve = indices, exact native colors:** cyan `THREE.Color(1/255,164/255,191/255)`, blue slider `THREE.Color(0,0,1)`, resolved from the nearest overlay dot index (placement order), matching `onSelectCurve`.
- **Surfaces display-only:** fed by an R `.gmw_flat` bare-CSV string; the browser renders `THREE.Points` and never recomputes surfaces.
- **RE-SERVE specimen switch (A4):** `sendBeacon('specimen',n)` records the switch; a relative `fetch('specimen')` returns the new mesh URL; `loadSpecimen` reloads and rebuilds the BVH. Post-edit redraws use a relative `fetch('redraw')` re-serve seam that R fills (05-04) — a 404 until then is harmless, mirroring 05-02's forward-call route pattern.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unescaped apostrophes in JS comments closed the single-quoted R template string**
- **Found during:** Task 3 (surface + delete/undo/specimen wiring)
- **Issue:** Two new JS comments (`specimen's`) contained apostrophes inside the single-quoted `GMW_VIEW3D_TEMPLATE <- '...'` R string, prematurely terminating the string and raising an R parse error (`unexpected symbol`) that would have broken any load/source of `view3d.R` — not just the template assembly.
- **Fix:** Reworded both comments to drop the apostrophe (matching the file's existing escape-avoidance style), then verified `sys.source("R/view3d.R")` + `.gmw_view3d_html(mesh_url=...)` assembles cleanly (19,871-byte page, 776-byte HEAD, no leftover `%s`).
- **Files modified:** `R/view3d.R`
- **Verification:** template assembles without error; both source-scan test files green.
- **Committed in:** `e35e031` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The apostrophe fix was necessary for correctness (the package R file must parse). No scope creep; all wiring is exactly as planned.

## Issues Encountered
- The sandbox did not honor the shell `working_directory`, so verify commands were run with an explicit `cd` into the R package root (also satisfies the plan's "working directory = R package root" note). `--no-init-file` was used throughout to avoid the renv `activate.R` startup hang (STATE.md Open Items).

## User Setup Required
None - no external service configuration required.

## Known Stubs
- **Post-edit redraw / specimen re-serve read seams (`fetch('redraw')`, `fetch('specimen')` response body):** the browser issues the reads, but the R side that answers them with flattened overlays + the re-served mesh URL lands in 05-04 (downsample/surface re-serve) and builds on the 05-02 `/specimen` handler. Until then these fetches 404 harmlessly and the current layers are left intact. This is intentional and consistent with 05-02's forward-call route seams; the plan scopes 05-03 to the pure view/input layer.

## Next Phase Readiness
- The browser digitizing view layer is complete and frozen: 05-04 (surface downsample/flatten) can deliver the surface cloud CSV and the re-serve overlay payloads the `redraw`/`switchSpecimen` fetches consume, without editing `view3d.R`.
- Browser DGT-01/DGT-02 end-to-end interaction is recorded as an executable Manual-Only UAT in `05-VALIDATION.md` (place anchors, define a curve, display/delete a surface point, undo, switch specimens) — sign-off pending a display host.

---
*Phase: 05-full-digitizing-and-data-parity*
*Completed: 2026-08-07*

## Self-Check: PASSED
- All created/modified files present on disk (test-digitizing-view3d.R, view3d.R, 05-03-SUMMARY.md).
- All task commits present in git history (55b4d92, 2b638bc, e35e031).
- test-digitizing-view3d.R: 24 passed / 0 failed. test-picking-view3d.R: 20 passed / 0 failed (Phase-4 wiring unregressed).
