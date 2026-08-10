---
phase: 04-picking-parity
plan: 02
subsystem: ui
tags: [three.js, raycast, three-mesh-bvh, picking, landmarks, record-replay, view3d, sprintf]

# Dependency graph
requires:
  - phase: 02-transport-and-mesh-display
    provides: "GMW_VIEW3D_TEMPLATE PLYLoader mesh-from-URL branch, frameScene framing, hoisted dist, .gmw_view3d_html string builder"
  - phase: 03-offline-packaging-and-lifecycle
    provides: "relative-URL sendBeacon('close') idiom (WEB-03 offline-by-construction), test-view3d-beacon.R source-scan pattern"
  - phase: 04-picking-parity
    provides: "04-01: token-guarded POST /<token>/pick route + server-owned .gmw_picks store the browser posts hits to"
provides:
  - "Browser half of PICK-01: eager computeBoundsTree() BVH + pointerdown->raycast handler reporting the mesh-local hit via relative sendBeacon('pick', 'x,y,z')"
  - "PICK-02: sibling overlay THREE.Group + addOverlayDot() drawing a depth-tested red sphere at each placed landmark"
  - "PICK-03 browser half: window.GMW_REPLAY(pose) reproducing a recorded native ray against an identity (raw PLY-vertex) mesh"
  - "Head/body split render in .gmw_view3d_html so the template survives R's 8192-byte sprintf fmt cap"
  - "test-picking-view3d.R source-scan locking all picking wiring + the relative-only pick target"
affects: [04-03 parity harness, PICK-03 real Windows capture drop-in, picking UAT]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pointer pick: canvas.getBoundingClientRect NDC (single Y-flip) -> raycaster.setFromCamera -> intersectObject(pickMesh,false) -> updateWorldMatrix + worldToLocal -> relative sendBeacon('pick')"
    - "Overlay dots live in a sibling THREE.Group (scene.add), never the recentred mesh group, so a non-recursive intersect never re-hits them"
    - "Replay bakes column-major glGetDoublev matrices onto a camera via fromArray with NO transpose, casts an identity mesh -> raw PLY-vertex frame"
    - "sprintf 8192 fmt-cap workaround: sprintf only the parameterised head, unescape %% in the parameter-free JS body, paste"

key-files:
  created:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-picking-view3d.R"
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R"

key-decisions:
  - "Overlay is a sibling group of the mesh group (not a child) so intersectObject(pickMesh,false) can never re-pick a placed dot (T-4-07)."
  - "addOverlayDot uses the WORLD hit (hits[0].point) before worldToLocal mutates the reported clone; the dot sits on the visible surface while R receives the mesh-local coord."
  - "Split .gmw_view3d_html rendering at the `MESH_URL = \"%s\";` boundary: sprintf the tiny head (all %s slots), gsub %%->%% on the parameter-free JS body — the template fmt now exceeds sprintf's 8192-byte cap once the picking JS is added."

patterns-established:
  - "Browser pick: relative sendBeacon('pick', 'x,y,z') mirroring the /close beacon — same-origin, no absolute URL (WEB-03), asserted by source-scan."
  - "Record-replay: matrixAutoUpdate=false + column-major fromArray (no transpose) + identity-mesh raycast for native-comparable PLY-frame hits."

requirements-completed: [PICK-01, PICK-02, PICK-03]

coverage:
  - id: D1
    description: "A pointer click casts a BVH-accelerated ray (eager computeBoundsTree) and POSTs the mesh-local hit as 'x,y,z' to the relative /pick route (PICK-01 browser half)."
    requirement: "PICK-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-view3d.R#the viewport template wires the pointer pick + eager BVH (PICK-01)"
        status: pass
      - kind: unit
        ref: "tests/testthat/test-picking-view3d.R#the pick report is the same-origin relative target, never absolute (WEB-03)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A placed landmark renders as an overlay THREE.Group sphere (SphereGeometry + MeshBasicMaterial depthTest:true) at the hit; a miss draws nothing (PICK-02)."
    requirement: "PICK-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-view3d.R#placed landmarks draw as depth-tested overlay spheres (PICK-02)"
        status: pass
    human_judgment: false
  - id: D3
    description: "window.GMW_REPLAY(pose) copies a recorded modelview + projection onto a camera with no transpose and raycasts the recorded pixel against a mesh at identity, returning a PLY-vertex-frame hit (PICK-03 browser half)."
    requirement: "PICK-03"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-view3d.R#the replay entry point raycasts the raw PLY frame at identity (PICK-03)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Interactive/visual behaviour: clicking the loaded mesh lands a red dot under the cursor, the dot is occluded when rotated behind the mesh, a background click is a silent no-op, and picking runs at interactive rates."
    verification: []
    human_judgment: true
    rationale: "Requires a real browser + display and a loaded specimen; headless CI cannot exercise WebGL raycast rendering. Recorded as manual UAT (plan verification), not run here."

# Metrics
duration: 30min
completed: 2026-08-05
status: complete
---

# Phase 4 Plan 02: Browser Picking, Overlay Dot, and Record-Replay Summary

**Extended `GMW_VIEW3D_TEMPLATE` with the browser half of picking: an eager three-mesh-bvh `computeBoundsTree()` plus a `pointerdown`->raycast handler that reports each mesh-local hit to R over the relative `/pick` route (PICK-01), a sibling-group depth-tested overlay dot (PICK-02), and a `window.GMW_REPLAY(pose)` entry point that reproduces a recorded native ray against an identity mesh (PICK-03) — closing the client side of the picking pipeline against 04-01's server-owned store.**

## Performance

- **Duration:** ~30 min (includes diagnosing the renv `.Rprofile` startup hang and the sprintf fmt-cap fix)
- **Completed:** 2026-08-05
- **Tasks:** 3 completed
- **Files modified:** 2 (view3d.R, new test-picking-view3d.R)

## Accomplishments
- `computeBoundsTree()` now runs eagerly inside the PLYLoader `onLoad` callback (folding the BVH build into load, not the first click), and the created mesh is retained as `pickMesh` for the raycast.
- A `pointerdown` handler computes NDC from `canvas.getBoundingClientRect()` with a single Y-flip, `setFromCamera` + `intersectObject(pickMesh, false)` (non-recursive), then `updateWorldMatrix(true,false)` + `worldToLocal` to hand R the raw PLY-vertex coordinate via `navigator.sendBeacon("pick", "x,y,z")` — a relative, same-origin target mirroring the `/close` beacon.
- A sibling `overlay` `THREE.Group` + `addOverlayDot()` draw a red `SphereGeometry`/`MeshBasicMaterial({depthTest:true})` sphere (radius `dist*0.01`) at the world hit, correctly occluded under rotation; a background miss draws nothing.
- `window.GMW_REPLAY(pose)` bakes the recorded column-major modelview + projection onto a throwaway camera (`matrixAutoUpdate=false`, `fromArray`, no transpose), derives NDC from the recorded backing viewport, and raycasts a fresh **identity** mesh built from the loaded geometry — returning `{x,y,z}` already in the PLY-vertex frame, drop-in-ready for the real Windows pose fixture.
- New `tests/testthat/test-picking-view3d.R` (20 assertions, all green) locks every Task 1-3 wiring marker and asserts the pick report is the relative `"pick"` target, never an absolute URL (WEB-03).

## Task Commits

Each task was committed atomically:

1. **Task 1: Eager BVH + pointer->raycast pick handler in the template** - `685ee07` (feat)
2. **Task 2: Overlay landmark dot with correct depth (PICK-02) + sprintf fmt-cap render fix** - `0c60072` (feat)
3. **Task 3: Record-and-replay entry point + source-scan tests** - `2888c52` (feat)

**Plan metadata:** `commit_docs` is disabled in `.planning/config.json`, so the docs/state commit is intentionally skipped by the SDK.

## Files Created/Modified
- `R/view3d.R` - Added `pickMesh`/`raycaster`/`ndc` state, eager `computeBoundsTree()`, the `pointerdown` pick handler, the `overlay` group + `addOverlayDot()`, and `window.GMW_REPLAY(pose)`; split `.gmw_view3d_html` rendering into a sprintf'd head + `%%`-unescaped JS body.
- `tests/testthat/test-picking-view3d.R` - New source-scan suite (skip-safe via `skip_if_no_pkg_source()`) covering all picking wiring and the relative-only pick target.

## Decisions Made
- Kept the interactive `pickMesh` inside the recentred `group` (so `frameScene()` framing is unchanged) but gave `GMW_REPLAY` its own identity mesh — the interactive and replay paths never share a transform, honouring the RESEARCH anti-pattern that a `frameScene()`-recentred group offsets every replay hit by `sphere.center`.
- Overlay dots are a sibling group and drawn from the world hit; the reported coordinate is a separate `worldToLocal`-converted clone, so the visible dot and the R-side value can never diverge.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Split template rendering to survive R's 8192-byte sprintf fmt cap**
- **Found during:** Task 2 (overlay dot)
- **Issue:** Adding the picking JS pushed `GMW_VIEW3D_TEMPLATE` past 8192 bytes; base-R `sprintf` errors `'fmt' length exceeds maximal format length 8192`, so `.gmw_view3d_html` no longer rendered — a hard blocker that Task 3's `GMW_REPLAY` would only worsen. The plan's own acceptance criterion requires the template to `sprintf`-render.
- **Fix:** `.gmw_view3d_html` now splits the template at the `MESH_URL = "%s";` boundary: the small parameterised head (all six `%s` slots) is `sprintf`-rendered, and the parameter-free JS body has its doubled `%%` unescaped via `gsub("%%","%")`, then the two are pasted. Output is byte-for-byte identical to a single `sprintf`; every literal `%` in source stays doubled.
- **Files modified:** `R/view3d.R`
- **Verification:** Re-rendered the mesh-URL, point-cloud, and inlined-mesh paths under `Rscript --vanilla`; confirmed `%%`->`%` in both CSS (`height:100%`) and JS (`Loading mesh %`), correct `MESH_URL`/title/background/cloud injection, and all picking markers present. `nchar` grows cleanly past the old cap.
- **Committed in:** `0c60072` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix is a mechanical, behaviour-preserving change to the render mechanism forced by a base-R limit; output HTML is unchanged and no schema/architecture changed. No scope creep.

## Issues Encountered
- Bare `Rscript` hangs on startup: the package `.Rprofile` sources `renv/activate.R`, which blocks trying to bootstrap `renv` over the sandbox-restricted network (a known workspace-local side effect noted in STATE.md Open Items). All R verification was run with `Rscript --vanilla` to bypass the init file, exactly as STATE.md recommends.
- Per the 04-01 precedent, `testthat::test_local()` loads the package namespace and hangs on the `tcltk2`/rgl GUI-init; verification instead used `testthat::test_file("test-picking-view3d.R")` after sourcing `helper-pkg-source.R`, yielding **20 PASS / 0 FAIL / 0 SKIP** (source present in the working tree).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The browser picking pipeline is complete client-side: interactive clicks POST mesh-local hits to 04-01's `/pick` store, landmarks render with correct depth, and `GMW_REPLAY` is ready for 04-03's parity harness and the real Windows pose capture (zero code change on drop-in).
- Owed at the phase gate: browser/display UAT (D4 above) — click lands a dot under the cursor, occlusion under rotation, miss is a no-op — which headless CI cannot run.

## Self-Check: PASSED
- FOUND: `R/view3d.R`
- FOUND: `tests/testthat/test-picking-view3d.R`
- FOUND commit `685ee07` (Task 1)
- FOUND commit `0c60072` (Task 2)
- FOUND commit `2888c52` (Task 3)

---
*Phase: 04-picking-parity*
*Completed: 2026-08-05*
