# Phase 4: Picking Parity - Context

**Gathered:** 2026-08-04
**Status:** Ready for planning

<domain>
## Phase Boundary

A BVH-accelerated raycast against the loaded browser mesh returns a hit
coordinate to R (PICK-01), a placement-only landmark dot renders as overlay
geometry at that coordinate with correct depth under rotation (PICK-02), and the
browser coordinate is proven to match the native `tkogl2` engine's
`gluUnProject` result within a documented, scale-relative tolerance (PICK-03 —
**the milestone gate**). CMP-01 recurs: the native oracle must still load.

**Fixed by ROADMAP / REQUIREMENTS / reference architecture — not re-decided
here:** BVH raycast via the already-vendored, BVH-patched `Mesh.raycast` in the
bundle; server-owns-state / browser-pure-view (R owns the landmark arrays, the
browser only reports interaction); raycasting is resolution-independent, so
HiDPI parity holds with no backing-scale correction (criterion 4); the native
`tkogl2` engine is the parity oracle and its exact commit is recorded in the
fixture (ROADMAP oracle-validity note); build the fixture of known clicks with
recorded native results *before* writing the comparison (ROADMAP expected-cost
note).

**Out of scope:** landmark editing / moving / deleting, curves, anchors, surface
semilandmarks, multi-specimen switching, undo — all Phase 5 (DGT-01/DGT-02).
This phase is placement-only. `.dgt` byte-parity is Phase 5 (DAT). Shell/Tk
replacement is Phase 6 (UI).
</domain>

<decisions>
## Implementation Decisions

### Tolerance (the gate — PICK-03)
- **D-01:** Tolerance is **scale-relative**, stated as a fraction of the
  specimen's **mean inter-vertex edge length** — not an absolute mm value.
  Picking cannot be more precise than mesh resolution, so the resolution is the
  natural unit.
- **D-02:** Gate value: the **95th-percentile** browser-vs-native Euclidean
  distance across all fixture click points must be **≤ 1 × mean inter-vertex
  edge length** (the pick lands within one mesh cell). 95th-percentile, not max,
  deliberately tolerates rare rasterization-edge outliers (see D-09).
- **D-03:** Justification basis: the requirement demands the tolerance be
  justified against **inter-observer digitizing error**. No project-local
  inter-observer number is available, so **research cites published geometric-
  morphometrics inter-observer digitizing error** and shows the ≤ 1-edge gate is
  well inside it. User approves the final number at plan time.

### Parity fixture
- **D-04:** Single **dense** specimen, not the whole reference set:
  **`B7_1_clean.ply`** (363,283 verts, already committed at
  `tests/fixtures/parity/`). It is the worst case, so it also stresses BVH build
  and transfer.
- **D-05:** **Full camera-pose record-and-replay** — parity is only meaningful
  if the browser and the native engine cast the *same* ray. The fixture records,
  per click: the native **modelview + projection + viewport**, the **click pixel
  (x, y)** actually sampled by the engine, **winZ** (depth-buffer sample), the
  resulting native **object coordinate (x, y, z)**, and the **engine commit
  hash**. The browser drives its camera to the recorded pose and raycasts the
  same pixel — apples-to-apples, no human variance.

### Native capture is blocked (gate sequencing)
- **D-06:** Native fixture capture runs **Windows-only** (the validated oracle)
  and **no Windows host is readily available**. Therefore PICK-03 **cannot close
  in this phase** — it is a known, tracked blocker, not a silent gap.
- **D-07:** Sequencing (chosen): **build PICK-01 (raycast → R coordinate),
  PICK-02 (overlay dot), and the full parity harness now** — the pose-record
  schema, the browser camera-replay, the distance / 95th-percentile comparison,
  and the mean-edge-length tolerance calculation — **against a placeholder
  fixture**. PICK-03 stays **formally OPEN**; dropping the real Windows-captured
  fixture in later must close the gate **with no code change**. This bounds the
  loss exactly as the ROADMAP's "decision point" note intends: PICK-01/PICK-02
  ship value even if the gate stays pending.

### Claude's Discretion
- **Pick round-trip transport shape** — not deep-discussed. Follow
  server-owns-state and extend the existing **mixed httpuv app** (the Phase 3
  `/close` route precedent): a **token-guarded POST route** (e.g. `/<token>/pick`)
  that hands the browser hit coordinate back to R is the natural fit. Planner
  chooses the exact route shape, payload, and the R-side receive/return API.
  WebSocket / polling were listed but a POST route matches the established
  pattern.
- **Landmark dot appearance + miss behavior** — not deep-discussed. Planner
  decides dot color/size, depth behavior under rotation (occluded vs
  always-on-top), and what a click that misses the mesh (background hit) does
  (ignore vs no-op feedback). Placement-only; keep it minimal.
- **Placeholder fixture format + pose-record schema field layout** — planner /
  researcher decide, with the hard constraint that the schema is **identical to
  the real Windows capture** so the drop-in closes the gate without code changes.
- An interim R-side `gluUnProject` self-consistency check and a written native-
  capture procedure were offered and **not selected** — do not build them as
  deliverables (the pose-record schema itself implicitly specifies what to
  capture).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and scope
- `.planning/REQUIREMENTS.md` — PICK-01, PICK-02, PICK-03 (**milestone gate**),
  CMP-01 recurring oracle gate.
- `.planning/ROADMAP.md` §"Phase 4: Picking Parity" — success criteria, the
  "this is the decision point" note (bounded loss), the "expected cost"
  coordinate-space-convention note, and the oracle-validity note (record the
  exact engine commit in the fixture).

### Architecture / inherited decisions
- `.planning/research/REFERENCE-ARCHITECTURE.md` — server-owns-state /
  browser-pure-view; the explicit note that **raycasting is
  resolution-independent** and avoids the Retina backing-pixel defect class
  (directly supports criterion 4).
- `.planning/phases/03-offline-packaging-and-lifecycle/03-CONTEXT.md` — the
  **mixed httpuv app** (`staticPaths` + a `/close` handler route), the `>=128-bit`
  token guard, and the `.gmw_server` token-keyed registry. The pick round-trip
  route extends this app.
- `.planning/phases/02-transport-and-mesh-display/02-CONTEXT.md` — one specimen
  per viewport; the mesh render branch the raycast + overlay attach to.

### Reusable / to-be-extended code
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R`
  — `GMW_VIEW3D_TEMPLATE` (three.js scene, `PerspectiveCamera`, OrbitControls,
  `PLYLoader`, bounding-sphere framing). PICK-01 raycast + PICK-02 overlay group
  are added to this template; the camera-replay for the fixture drives this
  camera.
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R`
  — `.gmw_serve_mesh()`, the mixed-app `/close` route, `.gmw_token()`,
  `.gmw_server` registry. The token-guarded pick POST route is added here.
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/htmlwidgets/guimorphweb-three.js`
  — vendored bundle exposing `GMW.THREE` / `OrbitControls` / `PLYLoader`, with
  the **BVH prototype patches already applied** (`Mesh.raycast` accelerated).
- `integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_ZARF9.c` —
  **the oracle math**: `ogl_getObjCoordinate` reads depth-buffer `winZ` via
  `glReadPixels(GL_DEPTH_COMPONENT)` then `gluUnProject(winX, winY, winZ,
  modelview, projection, viewport, ...)`; `ogl_getWndCoordinate` is the
  `gluProject` inverse. Source of the reference object coords and of exactly
  which matrices / winZ the fixture must record.
- `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c` — the
  native pick dispatch: Tk-point → backing-pixel conversion and the retina
  near-miss window. Shows which pixel is actually fed to `ogl_getObjCoordinate`
  (the fixture must record the sampled pixel, post-conversion, not the raw Tk
  point).
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/fixtures/parity/B7_1_clean.ply`
  — the fixture specimen (D-04).
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-retina-picking-parity.R`
  — existing skip-if-native-source-absent idiom; the parity-harness tests should
  follow the same shape so they skip cleanly when the real fixture is absent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GMW_VIEW3D_TEMPLATE` (`view3d.R`): full three.js scene with camera, orbit,
  framing, and a `PLYLoader` mesh branch — the raycaster and overlay group attach
  here; the fixture replay drives this same `PerspectiveCamera`.
- BVH-patched `Mesh.raycast` in the vendored bundle: acceleration is already live,
  no new JS vendoring needed for PICK-01.
- `.gmw_server` token registry + mixed-app `/close` route (`transport.R`): the
  browser→R pick channel is a second token-guarded route on the same app.
- `test-retina-picking-parity.R`: skip-if-source-absent pattern reusable for the
  parity harness tests (native fixture may be absent).

### Established Patterns
- Server-owns-state, token-guarded routes, static byte serving off the libuv/C
  thread — the POST pick route must preserve all three (never join a request path
  to the filesystem; T-2-02 path-traversal safety stays intact).
- Delivery shape mirrors `.rgl_show()` / `.plot_show()` — keep it for any new
  R entry point.

### Integration Points
- New token-guarded POST pick route on the mixed httpuv app (`transport.R`).
- `view3d.R` template gains a pointer→raycast handler and an overlay group for
  placement dots.
- New R-side API to receive the browser hit coordinate and hold the landmark
  array (server-owns-state).
- Parity harness: R functions for the pose-record schema, camera-replay driver,
  distance / 95th-percentile comparison, and mean-edge-length tolerance, plus
  testthat coverage that skips when the real fixture is absent.
- CMP-01: confirm the native `tkogl2` oracle still loads (`.gmw_engine$ok`).

</code_context>

<specifics>
## Specific Ideas

- **Oracle math to mirror exactly:** native picks are `glReadPixels(x, winY, ...,
  GL_DEPTH_COMPONENT, GL_FLOAT, &winZ)` then `gluUnProject`. Note the Y flip —
  the engine uses `winY = viewport_height - y`. The fixture must record the pixel
  the engine actually sampled (after the `tcl_dispatch.c` backing-pixel
  conversion), not the raw Tk event point.
- **Expected outlier source (why 95th percentile, D-02/D-09):** the native
  engine unprojects a **depth-buffer-interpolated** winZ; the browser BVH raycast
  returns an **exact triangle intersection**. Near silhouettes and steep depth
  gradients these are slightly different points. Research should confirm this is
  the dominant residual and that it stays under the gate off the tail.
- **Engine commit in the fixture** (ROADMAP oracle-validity note): record the
  exact `tkogl2` commit used to generate reference coords so a later engine
  change cannot silently invalidate the comparison.
- **Placeholder must be schema-true:** the placeholder fixture built this phase
  must be byte-schema-identical to the eventual Windows capture, so swapping in
  real data closes PICK-03 with zero code change (D-07).

</specifics>

<deferred>
## Deferred Ideas

- **Real native Windows fixture capture** — blocked (D-06); no Windows host
  available now. Must be scheduled separately on the validated oracle; PICK-03
  stays OPEN until it lands and is dropped into the harness.
- **Interim R-side `gluUnProject` self-consistency check** — offered, not
  selected. Could pre-validate coordinate-space convention before the real
  fixture arrives; revisit only if axis/sign debugging proves expensive.
- **Written native-capture procedure doc** — offered, not selected. The
  pose-record schema is the de-facto spec; add a prose runbook only if a
  non-author operator ends up running the capture.
- **Landmark editing / move / delete, curves, anchors, surfaces, multi-specimen,
  undo** — Phase 5 (DGT-01/DGT-02). This phase is placement-only.

### Reviewed Todos (not folded)
None — no pending todos matched this phase's scope.

</deferred>

---

*Phase: 4-Picking Parity*
*Context gathered: 2026-08-04*
