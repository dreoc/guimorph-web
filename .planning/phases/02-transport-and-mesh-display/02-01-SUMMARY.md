---
phase: 02-transport-and-mesh-display
plan: 01
subsystem: ui
tags: [three.js, PLYLoader, webgl, r, sprintf-template, mesh-render]

requires:
  - phase: 01-browser-result-plots-rgl-demotion
    provides: vendored three.js bundle (GMW.PLYLoader export) + GMW_VIEW3D_TEMPLATE + .gmw_view3d delivery shape
provides:
  - ".gmw_view3d_html(clouds, mesh, mesh_url, title, background) — returnable HTML page string builder"
  - "GMW_VIEW3D_TEMPLATE mesh-from-URL branch: async GMW.PLYLoader.load with computed normals, solid #cccccc MeshLambertMaterial (DoubleSide), deferred bounding-sphere framing"
  - "frameScene() JS framing function + IIFE-hoisted dist so reset()/r-key work for cloud and mesh-URL paths"
affects: [02-02, transport, PICK-01, phase-3-packaging]

tech-stack:
  added: []
  patterns:
    - "Parametrize the shared sprintf HTML template (MESH_URL %s slot) instead of forking a mesh-only page"
    - "Async loader render: compute normals + defer camera framing into the onLoad callback"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport-render.R
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R

key-decisions:
  - "Reused GMW_VIEW3D_TEMPLATE via a MESH_URL branch (RESEARCH Open Question 2 / CONTEXT reuse-if-clean) rather than forking a mesh-only template."
  - "Hoisted dist to IIFE scope and moved framing into frameScene() so reset() and the r-key handler resolve dist for both the synchronous cloud/inlined-mesh path and the deferred async PLY path."
  - "Mesh material sets colour + THREE.DoubleSide only; per-vertex scan RGB stays off (NextEngine colour intentionally ignored) per D-03/D-04."
  - "Did NOT mark WEB-02 complete in REQUIREMENTS.md: WEB-02 is shared with 02-02 (which delivers the runnable httpuv viewport) and its browser/orbit/framing UAT is deferred to phase UAT."

patterns-established:
  - "Template reuse: add a %s injection slot + a conditional JS branch to GMW_VIEW3D_TEMPLATE, threaded through the sprintf() call in template order, with every literal % doubled."
  - "Source-scan render test: assert on the HTML string returned by .gmw_view3d_html() (no browser/WebGL), guarded by skip_if_no_pkg_source()."

requirements-completed: [WEB-02]

coverage:
  - id: D1
    description: "Mesh-from-URL branch renders a served PLY as a solid shaded surface: async GMW.PLYLoader.load, geometry.computeVertexNormals(), #cccccc MeshLambertMaterial with THREE.DoubleSide, deferred frameScene() framing."
    requirement: "WEB-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-transport-render.R#mesh-URL branch emits PLYLoader + normals + deferred framing + D-03/D-04 material"
        status: pass
      - kind: unit
        ref: "tests/testthat/test-transport-render.R#framing is deferred, not run synchronously, on the mesh-URL path"
        status: pass
    human_judgment: false
  - id: D2
    description: "The pre-existing PLT-01 point-cloud path still emits THREE.Points through the same template and does not leak a mesh URL."
    requirement: "WEB-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-transport-render.R#point-cloud path is unregressed and carries no mesh URL"
        status: pass
    human_judgment: false
  - id: D3
    description: "In a real browser the served mesh renders shaded (not black), orbit/zoom/r-reset work, and the camera framing is tight on the reference specimens."
    requirement: "WEB-02"
    verification: []
    human_judgment: true
    rationale: "No automated WebGL harness; requires visual UAT on stock macOS/Windows. The runnable viewport is delivered by plan 02-02 (httpuv transport), so this is deferred to phase UAT."

duration: 22 min
completed: 2026-07-31
status: complete
---

# Phase 2 Plan 1: Mesh-from-URL Render Branch Summary

**three.js `PLYLoader` mesh-from-URL branch in `GMW_VIEW3D_TEMPLATE` — computed normals, solid `#cccccc` Lambert DoubleSide surface, and deferred bounding-sphere framing, exposed through a new `.gmw_view3d_html()` string builder.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-07-31T17:40:00Z
- **Completed:** 2026-07-31T18:02:00Z
- **Tasks:** 2
- **Files modified:** 2 (1 modified, 1 created)

## Accomplishments

- Extracted `.gmw_view3d_html(clouds, mesh, mesh_url, title, background)` as a returnable HTML character scalar; `.gmw_view3d()` now calls it (with `mesh_url = ""`) and keeps its tempdir + bundle-copy + `browseURL()` delivery unchanged. Plan 02-02's `.gmw_serve_mesh()` consumes this builder with `mesh_url = "specimen.ply"`.
- Added a `MESH_URL` `%s` slot to `GMW_VIEW3D_TEMPLATE` and an async `GMW.PLYLoader().load(...)` branch: `computeVertexNormals()` (or the Lambert surface renders black), a solid `#cccccc` `MeshLambertMaterial` with `THREE.DoubleSide` (D-03/D-04), and deferred `frameScene()` framing.
- Refactored framing into a `frameScene()` function and hoisted `dist` to the IIFE scope so `reset()` and the `r`/`R` key handler work for both the synchronous point-cloud/inlined-mesh path and the deferred async mesh-URL path.
- Added `tests/testthat/test-transport-render.R` (17 assertions) proving the mesh-URL branch, D-04 background, deferred framing, and the unregressed `THREE.Points` point-cloud path — no browser/WebGL required.

## Task Commits

Each task was committed atomically:

1. **Task 1: Mesh-from-URL branch + extract `.gmw_view3d_html`** - `d1f4e54` (feat)
2. **Task 2: Source-level render test** - `cffb094` (test)

**Plan metadata:** committed with STATE.md + ROADMAP.md (docs: complete plan)

## Files Created/Modified

- `R/view3d.R` (modified) - Extracted `.gmw_view3d_html()`; parametrized `GMW_VIEW3D_TEMPLATE` with a `MESH_URL` slot + async `PLYLoader` branch; `frameScene()` + hoisted `dist`.
- `tests/testthat/test-transport-render.R` (created) - Source-scan render tests over the HTML string; guarded by `skip_if_no_pkg_source()`.

## Decisions Made

- **Reuse over fork:** parametrized the existing template with a mesh-URL branch (RESEARCH Open Question 2; CONTEXT "reuse if clean") rather than duplicating a mesh-only page.
- **`dist` hoist + `frameScene()`:** the only real wiring subtlety of the reuse — framing must run after async load, but `reset()`/`r`-reset close over `dist`, so `dist` is declared once at IIFE scope and framing is a callable function.
- **Scan RGB off:** material is colour + `DoubleSide` only; `vertexColors` is never enabled (D-04).
- **WEB-02 not marked complete:** WEB-02 is shared with plan 02-02 (which delivers the runnable `httpuv` viewport) and its visual/orbit/framing behaviour is manual UAT. This plan ships and unit-tests the render *logic* half; end-to-end WEB-02 closes after 02-02 + phase UAT.

## Deviations from Plan

None - plan executed exactly as written.

(One tooling note, not a plan deviation: `testthat` was absent from the R library and `renv` could not bootstrap offline, so `testthat` 3.3.2 was installed into the system site-library to run the Task 2 verify. No project dependency was added — `testthat` remains a standard test-only tool.)

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `.gmw_view3d_html(mesh_url = ...)` is ready for plan 02-02 to serve as `index.html` over `httpuv`.
- Ready for 02-02 (transport: `httpuv` server, port/token, `.gmw_serve_mesh()`), which completes the WEB-01/WEB-02/CMP-01 set and enables the deferred WEB-02 browser UAT.

## Self-Check: PASSED

- `[ -f ]` key files: `R/view3d.R` and `tests/testthat/test-transport-render.R` both present on disk.
- `git log --grep="02-01"` returns the two task commits (`d1f4e54`, `cffb094`).
- Task acceptance criteria re-run: `.gmw_view3d_html()` exists and parses; mesh-URL output contains `GMW.PLYLoader`, `computeVertexNormals`, `frameScene`, `MeshLambertMaterial`, `THREE.DoubleSide`, `#cccccc`, `#ffffff`, `specimen.ply`; contains no `vertexColors`; point-cloud output contains `THREE.Points` and no `specimen.ply`; single hoisted `var dist`.
- Plan verification: `source("R/view3d.R"); exists(".gmw_view3d_html")` → TRUE; `testthat::test_dir(filter="transport-render", stop_on_failure=TRUE)` → `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 17 ]`.

---
*Phase: 02-transport-and-mesh-display*
*Completed: 2026-07-31*
