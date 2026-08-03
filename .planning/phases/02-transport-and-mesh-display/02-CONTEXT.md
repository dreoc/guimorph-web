# Phase 2: Transport and Mesh Display - Context

**Gathered:** 2026-07-31
**Status:** Ready for planning

<domain>
## Phase Boundary

R serves a single PLY specimen over an `httpuv` loopback HTTP server; three.js
`PLYLoader` fetches and renders it in the browser with orbit, zoom, and reset
view. Mesh bytes only — never JSON-encoded. No overlays, no picking, no
digitizing (those are Phase 4+).

Delivers WEB-01 (transport) and WEB-02 (render). CMP-01 recurs: native `tkogl2`
oracle must still load.

**Fixed by ROADMAP / REQUIREMENTS / reference architecture — not re-decided
here:** loopback-only bind, unprivileged port, per-session random path/token
guard, PLY served as raw bytes never JSON, `httpuv::randomPort()` primary with
walk-forward-from-preferred backup, server-owns-state / browser-pure-view,
offline vendored bundle. Robust teardown, port-collision error handling, and
browser-launch degradation are **Phase 3 (WEB-04)** — out of scope here.

</domain>

<decisions>
## Implementation Decisions

### Specimen scope
- **D-01:** One specimen per viewport. The Phase 2 R entry point takes a single
  PLY path (or mesh), serves it on one guarded endpoint, and renders it.
- **D-02:** No in-page specimen picker. Multi-specimen switching stays in Phase 5
  (DGT-02) — deliberately not pulled forward. Criterion 4 ("6-specimen set loads
  and orbits") is satisfied by loading each specimen individually, not by a
  switcher UI.

### Mesh appearance
- **D-03:** Solid shaded surface. Reuse the existing `MeshLambertMaterial` +
  ambient/directional lighting already in `view3d.R`'s `GMW_VIEW3D_TEMPLATE`.
  Not wireframe, not points.
- **D-04:** Default mesh color `#cccccc` (gray) on `#ffffff` (white) background —
  matches current `view3d.R` default and inherited rgl look. `side:
  THREE.DoubleSide` retained.

### Claude's Discretion
- Exact R entry function name/signature and endpoint route shape (planner
  decides, following the server-owns-state pattern).
- Whether the Phase 2 page reuses `GMW_VIEW3D_TEMPLATE` verbatim (swapping the
  inlined-geometry block for `fetch(url)` + `PLYLoader`) or forks a mesh-only
  template. Reuse is preferred if clean.
- Bounding-box / camera-framing math is already solved in the template; reuse.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Transport, port, offline, state ownership
- `.planning/research/REFERENCE-ARCHITECTURE.md` — server-owns-state, port
  selection (randomPort primary + walk-forward backup), do-not-auto-open, offline
  by construction, R-side port-probe testing technique. Decisions inherited from
  `landmarking-EOC`, not re-derived.

### Requirements and scope
- `.planning/REQUIREMENTS.md` — WEB-01, WEB-02 (this phase); CMP-01 recurring
  gate; WEB-03/WEB-04 (Phase 3, explicitly out of scope here).
- `.planning/ROADMAP.md` §"Phase 2: Transport and Mesh Display" — success
  criteria, mesh-size risk note, PLY hygiene note.

### Reusable code (Phase 1 output)
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R` —
  `GMW_VIEW3D_TEMPLATE`, `.gmw_view3d()`, `.gmw_bundle_path()`; orbit/zoom/`r`-reset,
  bounding-sphere framing, Lambert mesh material.
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/htmlwidgets/guimorphweb-three.js`
  — vendored classic-script bundle (global `GMW`: THREE, OrbitControls, PLYLoader,
  BVH patches already applied).
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/htmlwidgets/VENDOR-MANIFEST.json`
  — pinned versions.
- `.planning/phases/01-browser-result-plots-rgl-demotion/01-SUMMARY.md` — Phase 1
  outcome; native engine load now non-fatal.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `view3d.R` `GMW_VIEW3D_TEMPLATE`: complete three.js scene (orbit, zoom, `r`
  reset, resize, bounding-sphere auto-frame, Lambert mesh). Phase 2 swaps the
  inlined-geometry block for a `PLYLoader.load(url, ...)` against the httpuv
  endpoint.
- Vendored bundle already exposes `GMW.PLYLoader` — no new JS vendoring needed.
- `.gmw_bundle_path()` resolves the bundle via `system.file()`; reuse for copying
  the script next to the served page.

### Established Patterns
- Delivery shape mirrors `.rgl_show()` / `.plot_show()` — write a page, open it,
  message the path. Keep the same shape so nothing new is asked of the user.
- `htmlwidgets` stays in Suggests; do not reintroduce to Imports.

### Integration Points
- New `httpuv` dependency: currently Imports = geomorph, Rvcg, tcltk, tcltk2
  (post Phase 1). `httpuv` must be added to DESCRIPTION Imports.
- Test fixture: `tests/fixtures/parity/B7_1_clean.ply` (363,283 verts, 30 MB
  ASCII) is the committed worst-case transfer test.

</code_context>

<specifics>
## Specific Ideas

- Worst-case transfer benchmark target: `B7_1_clean.ply` (30 MB ASCII). Roadmap
  default is to serve as-is and only evaluate binary-PLY / Draco fast-path if
  transfer time proves unacceptable on the reference set. (Not selected for deep
  discussion — default stands.)
- PLY hygiene watch (from ROADMAP + PROJECT lessons): NextEngine exports carry
  unreferenced stray verts including origin-null (0,0,0). Confirm the browser
  loader / camera framing does not silently reintroduce them into the bounding
  box. (Not deep-discussed; flagged for planner as a verification concern.)

</specifics>

<deferred>
## Deferred Ideas

- **In-page specimen picker / multi-specimen switcher** — belongs to Phase 5
  (DGT-02). Considered and explicitly deferred.
- **Binary-PLY / Draco compression fast-path** — only if WEB-02 transfer time is
  unacceptable on the reference set (REQUIREMENTS v2/Deferred). Default: serve
  ASCII bytes as-is.
- **Wireframe / point-cloud render toggle** — not needed for read-only Phase 2
  display.

</deferred>

---

*Phase: 2-Transport and Mesh Display*
*Context gathered: 2026-07-31*
