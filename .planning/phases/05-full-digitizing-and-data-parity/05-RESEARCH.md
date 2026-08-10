# Phase 5: Full Digitizing and Data Parity - Research

**Researched:** 2026-08-07
**Domain:** Browser-driven 3D digitizing (curves, anchors, surface semilandmarks, undo, multi-specimen) over the existing loopback `httpuv`/`.gmw_picks` server-owned-state architecture; `geomorph` GPA + export from the browser; `.dgt` byte-identity and cross-tool round-trip parity
**Confidence:** HIGH for the existing code paths (every claim below traced to in-repo source this session); MEDIUM for the two open external dependencies (Windows native re-save fixtures for DAT-01/DAT-02, GUImorph's macOS→Windows `.dgt` leg) — both are tracked blockers, not unknowns.

## Summary

Phase 5 completes the acquisition workflow in the browser. Phases 2–4 built the transport (`httpuv` loopback, `R/transport.R`), the mesh render + BVH raycast pick (`R/view3d.R`), a server-owned landmark store (`.gmw_picks`), and the parity gate math (`R/parity.R`). Phase 5 extends *exactly this architecture*: curves, anchors, and surface semilandmarks are all more picking-derived data that must flow browser→R over the same token-guarded route pattern, be owned authoritatively by R, and be serialized by the **same** `.dgt` writer the native path uses.

The single most important architectural fact — repeated across STATE.md, the ROADMAP, and confirmed in source — is that **R keeps the `.dgt` writer** (`saveToDgt` → `.dgt_write_matrix_block` in `3dDigitize.main.r`). DAT-01 therefore compares *one writer against itself* (browser-driven session state vs native-driven session state), not two implementations. Byte-identity reduces to two things: (1) route the browser "Save" through the identical writer with no alternate serialization, and (2) make that writer **deterministic** — it currently is not, and that is a hard prerequisite (see the open todo `dat-parity-gate-is-a-skip.md`: CRLF-vs-LF on every line plus ten libc-rounding differences of 1e-6 between the two native platforms). The recommended fix is small and local to `.dgt_write_matrix_block`: `formatC(round(x, 6), format="f", digits=6)` and a pinned line terminator.

The second decisive finding is that the **existing Tk/C digitizing code (`3dDigitize.digitize.r`, `.curve.r`, `.surface.r`) cannot be reused directly by the browser path.** It is coupled at two seams: the Tk GUI (`tkbind`, `tclVar`, `tkmessageBox`, status bar) and the C engine bridge (`add`/`set`/`shows`/`getLandmark`/`getAnchor`/`convertCoor` in `rtkogl.R`). The browser path bypasses both. So Phase 5's core work is to build an **R-side, server-owned digitizing session model** (extending the `.gmw_picks` idiom to a per-specimen record of landmarks + anchors + curves + surfaces + undo) that the browser edits over loopback routes and that both `saveToDgt` and the GPA/export functions read from. GPA (`compute`) and export (`save`/`exportGeomorph`) are otherwise pure R and reused verbatim.

**Primary recommendation:** Model Phase 5 as "extend the Phase 4 server-owned-state pattern to the full digitizing record." Add per-specimen R state (owned by R, keyed by token/specimen), a small set of token-guarded loopback routes (anchor, curve-by-index, delete, undo, build-template/downsample, switch-specimen, gpa, export) using the same JSON-free bare-CSV body convention, and browser-side interaction+overlay rendering. Make `.dgt_write_matrix_block` deterministic first, route browser Save through it, and prove DAT-01 as a byte-identity test over identical in-memory arrays. Cover the `as.vector(t(surfaces[,,id]))` transpose with a regression test. State the DAT-02 macOS→Windows limitation rather than claiming a fully-proven contract.

<phase_requirements>
## Phase Requirements

> No CONTEXT.md exists for this phase — the user opted to continue without `/gsd-discuss-phase`. There are therefore no locked decisions to honor; the areas flagged "PLANNER DECISION" below are open design choices for `gsd-planner`, and the Assumptions Log lists what needs user confirmation at plan time.

| ID | Description | Research Support |
|----|-------------|------------------|
| DGT-01 | Curve definition with the existing three-click selection + cyan/red/blue feedback, plus anchor placement | Curve = 3 **landmark indices** per segment stored in `activeDataList[[1]][[4]]` (`onSelectCurve`, `3dDigitize.curve.r:189-283`); cyan `(1/255,164/255,191/255)`, blue slider `(0,0,1)` recolor sequence. Anchors reuse the pick pattern with a second server-owned store + green dots. See Pattern 2, Pattern 3. |
| DGT-02 | Surface semilandmark display, delete, undo, multi-specimen switching in the browser | Surfaces are R-computed (`downSample` TPS warp, `3dDigitize.surface.r:400-567`), displayed via `as.vector(t(surfaces[,,id]))` flatten (Pitfall 1); delete/undo mirror `doUndo` action grammar (`3dDigitize.digitize.r:72-155`); multi-specimen breaks Phase 2 "one specimen per viewport" (D-01) — see Pattern 4 + Open Question 1. |
| DGT-03 | GPA (`geomorph::gpagen`) + `.csv`/`.rds` export driven from the browser, identical to native | `compute`/`save`/`exportGeomorph` (`3dDigitize.geomorph.r`) are pure R; identical because it is the same code on the same input. Browser adds a trigger route only. Reads landmarks via `getLandmark` today → must read the new session model. See Pattern 5. |
| DAT-01 | Browser-written `.dgt` byte-identical to native-written `.dgt` from the same session | One writer against itself (`saveToDgt`/`.dgt_write_matrix_block`, `3dDigitize.main.r:203-215,1931-2026`). Requires deterministic writer fix (round + pinned EOL) — the open todo. See Pattern 6 + Pitfall 2. |
| DAT-02 | GUImorph↔GUImorphWeb `.dgt` open correctly both directions vs `tests/fixtures/parity/` | Shared reader (`read.digitize`/`read.curve`/`read.surface`/`read.anchors`) and writer. Fixtures exist (`windows-authored-roundtrip.dgt`, `mac-authored-roundtrip.dgt`); two `-rewrite` halves owed. External dep: GUImorph's macOS→Windows leg open. See Pattern 6, Environment Availability. |
| CMP-01 | Native `tkogl2` oracle stays loadable (`.gmw_engine$ok`) — retired AFTER this phase | Never touch `rtkogl.R` `.onLoad`/`.gmw_require_engine` (`rtkogl.R:498-592`). Reuse `test-retina-picking-parity.R` skip-if-absent idiom. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Anchor placement (pointer→ray→hit) | Browser (three.js) | R (owns array) | Same resolution-independent raycast as landmarks (PICK-01); anchors are just a second marker kind. |
| Curve definition (click 3 existing landmark dots) | Browser (three.js) | R (owns curve matrix) | Browser maps clicks to the nearest overlay-dot **index**; R appends the 3-index row. Curve rows are indices, not coordinates. |
| Digitizing session state (landmarks/anchors/curves/surfaces/undo) | R (server) | — | Server-owns-state (REFERENCE-ARCHITECTURE). R is the single authoritative copy; browser only reports edits. Extends `.gmw_picks`. |
| Surface semilandmark computation (template build, TPS downsample) | R (analytical) | — | Pure geometry (`Rvcg`, `gm_utils` TPS); already validated; browser only triggers + displays. |
| Surface semilandmark display / delete | Browser (three.js) | R (owns data) | R flattens `as.vector(t(surfaces[,,id]))` and sends; browser renders/edits and reports deletes. |
| Undo | R (server) | Browser (issues action) | Undo stack mirrors native `doUndo` grammar; R owns it so it survives across viewport events. |
| Multi-specimen switch | R (re-serve mesh + overlays) | Browser (requests switch) | Breaks Phase-2 one-specimen-per-viewport; R must serve the next specimen's bytes + its overlay data. |
| GPA (`gpagen`), PCA, mean shape | R (analytical) | Browser (trigger + result plot) | Pure R (`geomorph`); identical to native by construction. Result plots already route through `.gmw_view3d`. |
| `.csv` / `.rds` / `.dgt` export/write | R (file I/O) | Browser (trigger) | R keeps all file I/O; this is what makes DAT-01 byte-identity a one-writer comparison. |
| Native reference (`.dgt` written by native path; oracle load) | Native `tkogl2` (Windows) | — | DAT-01 native leg + CMP-01; captured to fixtures with the engine still loadable. |

## Standard Stack

This phase installs **no new packages.** Everything needed is already vendored (JS) or declared (R).

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| three.js | 0.185.1 | Raycaster, overlay meshes (anchors/surface points/curve highlight), multi-mesh scene | Already vendored (WEB-00); the render + pick engine. `[VERIFIED: inst/htmlwidgets/VENDOR-MANIFEST.json]` |
| three-mesh-bvh | 0.9.13 | Accelerated raycast on scan-density meshes; re-run per specimen switch | Already vendored, prototype patch applied at bundle time. `[VERIFIED: VENDOR-MANIFEST.json + Phase 4 bundle grep]` |
| httpuv | (locked Import) | Loopback transport; extend the mixed app with new digitizing routes | Phase 2/3/4 transport server. `[VERIFIED: transport.R, DESCRIPTION]` |
| later | (transitive via httpuv) | Deferred teardown; available for any deferred handling | Already used fully-qualified in `.gmw_close_handler`; no new import. `[VERIFIED: transport.R]` |
| geomorph | >= 4.1.1 | `gpagen`, `gm.prcomp`, `two.d.array` — GPA + export | Already an Import; the analysis pipeline, reused verbatim. `[VERIFIED: DESCRIPTION, 3dDigitize.geomorph.r]` |
| Rvcg | 0.25 | PLY read (`vcgPlyRead`), template k-means source, mesh stats | Already an Import; `template_kmeans.R`, `downSample`. `[VERIFIED: DESCRIPTION, 3dDigitize.surface.r:261]` |
| testthat | 3.3.2 (edition 3) | Unit + source-scan + byte-identity + skip-if-absent tests | Established framework; mirrors `test-picking-*`, `test-dgt-cross-platform`. `[VERIFIED: .cursor/rules, tests/testthat/]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| base R (`read.table`/`strsplit`/`writeLines`/`file`) | — | `.dgt` read/write, POST-body parse, deterministic file emission | Keep transport + file I/O **JSON-dependency-free** (deliberate — `view3d.R:13-15` header). `[VERIFIED: transport.R, 3dDigitize.main.r]` |
| geomorph `gm_utils.R` helpers (`tps2d3d`, `rotate.mat`, `cSize`) | in-repo | TPS warp for surface downsample | Already used by `downSample`; no change needed. `[VERIFIED: 3dDigitize.surface.r:515-518]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend `.gmw_picks` server model | Reuse `getLandmark`/`getAnchor` C accessors | Rejected: couples the browser acquisition path to the C engine that Phase 6 deletes; the browser must own state independently of `tkogl2`. |
| Many small routes (`/anchor`, `/curve`, `/delete`, ...) | One `/edit` route with a verb token in the CSV body | PLANNER DECISION. More routes = more `excludeStaticPath` entries but simpler handlers; one route = fewer entries but a dispatch inside the handler. Both preserve the no-path-join invariant. |
| Re-serve mesh bytes on specimen switch | Serve all specimens up front, toggle visibility | PLANNER DECISION (Open Question 1). Re-serve is simplest and matches D-01; toggle avoids re-transfer but holds N meshes in GPU memory. |
| Deterministic writer via `round()`+pinned EOL | Change the contract to numeric-tolerance parity | The todo recommends (a) make it byte-true (preferred, harder to fool) over (b) tolerance. Adopt (a) unless the user overrides. |

**Installation:** none. `three@0.185.1` + `three-mesh-bvh@0.9.13` vendored (WEB-00); `geomorph`/`Rvcg`/`httpuv`/`tcltk`/`tcltk2` declared; `later`/`testthat` transitive/Suggests.

## Package Legitimacy Audit

> This phase installs **no new external packages.** All JS is pre-vendored and byte-pinned (manifest); all R packages are already declared. Audit recorded for completeness.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| three | npm | ~13 yrs | ~1.8M/wk | github.com/mrdoob/three.js | OK | Already vendored (WEB-00), pinned 0.185.1 |
| three-mesh-bvh | npm | ~5 yrs | ~200k/wk | github.com/gkjohnson/three-mesh-bvh | OK | Already vendored (WEB-00), pinned 0.9.13 |
| geomorph / Rvcg / httpuv | CRAN | mature | — | CRAN | OK | Already declared Imports |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.
**New installs this phase:** none — nothing to gate behind a `checkpoint:human-verify`.

## Architecture Patterns

### System Architecture Diagram

```
                ┌───────────────────── R session (server owns ALL digitizing state) ─────────────────────┐
                │                                                                                          │
 pointer/UI ─▶ browser page (view3d.R template)         .gmw_server[token]   = httpuv handle              │
 events        │   • raycast pick (landmark/anchor)      .gmw_session[token]  = per-specimen record:       │
               │   • click existing dot → landmark idx       land[p×3], anchor[a×3], curves[c×3 indices],  │
               │   • request delete / undo / switch          surfaces[s×3] (per specimen), templates, undo │
               ▼                                                          ▲                                 │
   bare-CSV bodies over token-guarded routes  ──────────────────────────┤ append/mutate (R owns data)     │
   POST /<token>/pick     "x,y,z"        (landmark)                       │                                 │
   POST /<token>/anchor   "x,y,z"                                         │  excludeStaticPath routes each  │
   POST /<token>/curve    "i,j,k"        (landmark indices)               │  dynamic subpath to the R       │
   POST /<token>/delete   "kind,idx"                                      │  `call` handler (never joins    │
   POST /<token>/undo     ""                                              │  req path → filesystem, T-2-02) │
   POST /<token>/downsample ""  ; /<token>/gpa "" ; /<token>/export "fmt" │                                 │
   POST /<token>/specimen "n"   (switch)                                  │                                 │
               │                                                          ▼                                 │
               │                        R analytical layer (UNCHANGED, reused verbatim):                    │
               │                          downSample() TPS warp → surfaces[,,id]                            │
               │                          compute() → geomorph::gpagen → gm.results                          │
               │                          save()/exportGeomorph() → .csv/.rds                               │
               │                          saveToDgt() → .dgt_write_matrix_block (DETERMINISTIC fix)         │
               │  ◀── GET /<token>/... (re-serve mesh bytes + flattened overlays on switch/redraw) ──       │
               └──────────────────────────────────────────────────────────────────────────────────────────┘

  DAT-01 proof:  same in-memory arrays ──▶ saveToDgt (browser trigger)  ─┐
                                          saveToDgt (native trigger)    ─┴─▶ byte-identical .dgt  (round+EOL pinned)

  Native oracle (Windows, tkogl2 — CMP-01, retired AFTER this phase):
     add/set/shows/getLandmark/getAnchor ── still loadable; DAT-01 native leg + DAT-02 authored fixtures
```

### Recommended Project Structure
```
R/
├── transport.R      # EXTEND: add digitizing routes to the mixed app; server-owned session
│                    #         model (extends .gmw_picks); R read/mutate API
├── view3d.R         # EXTEND: anchor pick, curve-by-index click, surface-point cloud overlay,
│                    #         delete/undo/switch UI, multi-mesh handling; keep 8192-byte head/body split
├── 3dDigitize.main.r      # EDIT: make .dgt_write_matrix_block deterministic; a saveToDgt path that
│                          #       serializes the browser session model (or a shared serializer both call)
├── 3dDigitize.geomorph.r  # EDIT (minimal): let .build_geomorph_data read the session model, not only getLandmark
├── 3dDigitize.surface.r   # REUSE: downSample()/TPS unchanged; add a headless entry the route can call
└── parity.R               # OPTIONAL EXTEND: byte-identity helpers if not kept in main.r
tests/
├── fixtures/parity/
│   ├── windows-authored-roundtrip.dgt          # EXISTS (DAT-02)
│   ├── mac-authored-roundtrip.dgt              # EXISTS (DAT-02)
│   ├── windows-authored-roundtrip-rewrite.dgt  # OWED (Windows re-save; un-skips the gate)
│   ├── mac-authored-roundtrip-rewrite.dgt      # OWED (Windows re-save of the mac file)
│   └── folsom3d.dgt (inst/extdata)             # EXISTS: canonical writer-format fixture
└── testthat/
    ├── test-digitizing-session.R   # NEW: session-model mutations, curve-by-index, delete/undo
    ├── test-surface-flatten.R      # NEW: as.vector(t(surfaces[,,id])) regression (Pitfall 1)
    ├── test-dgt-determinism.R      # NEW: writer round+EOL determinism (DAT-01 prerequisite)
    ├── test-digitizing-view3d.R    # NEW: source-scan the template wiring (mirror test-picking-view3d.R)
    └── test-dgt-cross-platform.R   # EXTEND: byte-identity now runnable once -rewrite fixtures land
```

### Pattern 1: Server-owned per-specimen digitizing session model (the core)
**What:** Extend the `.gmw_picks` idiom (`transport.R:58`) from "one landmark matrix per token" to a full per-specimen digitizing record. R is the single authoritative copy; the browser holds none of the data authoritatively.
**When to use:** All of DGT-01/02/03 and DAT-01 depend on it.
**Shape:**
```r
# Package env, sibling to .gmw_server / .gmw_picks (kept SEPARATE so ls(.gmw_server)
# stays purely token->handle; same reasoning as .gmw_lifecycle/.gmw_picks).
.gmw_session <- new.env(parent = emptyenv())   # token -> list(specimens = list(<per-specimen record>),
                                               #                current = <int>, undo = <entry|NULL>)
# per-specimen record mirrors the existing activeDataList slots that MATTER for .dgt:
#   land     : p x 3 numeric  (picked landmark coords, raw PLY-vertex frame)
#   anchor   : a x 3 numeric
#   curves   : c x 3 integer  (LANDMARK INDICES, shared across specimens like activeDataList[[1]][[4]])
#   surfaces : s x 3 numeric  (R-computed by downSample)
#   template : scalar/character (Template= line)
```
Notes: the browser pick already reports **mesh-local (raw PLY-vertex)** coordinates via `worldToLocal` (`view3d.R:294-310`), which is the same frame the native `convertCoor`/`gluUnProject` produces and the same frame `.dgt` stores — so picked coords are directly writable with no extra transform. Curves are per-session (not per-specimen) in the existing model (`activeDataList[[1]][[4]]`); preserve that.

### Pattern 2: Curve definition by three landmark indices (DGT-01)
**What:** A curve segment is **three landmark indices**, NOT three coordinates. Native `onSelectCurve` (`3dDigitize.curve.r:189-283`) double-clicks three *already-placed* landmark dots; each click resolves the clicked dot to its landmark id via `set("dot","selected")` + `shows("landmark","id")`, colors it cyan `(1/255, 164/255, 191/255)`, marks the 2nd as the slider (blue `(0,0,1)`), and on the 3rd appends `matrix(c(i,j,k), 1, 3)` to `activeDataList[[1]][[4]]` and pushes an undo entry `list(action="curve_place", row=...)`.
**Browser translation:**
- The browser knows each landmark's overlay-dot position and its **index** (placement order). On a curve-tab click, find the nearest overlay dot (small screen-space threshold), take its index, recolor it cyan.
- After three indices are collected, recolor the middle one blue (the slider), POST `"i,j,k"` to `/<token>/curve`; R validates the three are distinct existing indices and appends the row to the session curve matrix.
- Duplicate-in-segment guard mirrors native (`curveLine` membership check, warns and ignores).
**Feedback colors (keep exact for parity of behavior):** select = cyan `rgb(1,164,191)`; slider (2nd point) = blue `(0,0,255)`; the native "red" is the default landmark dot color (`0xff2222` in the browser overlay, `view3d.R:196`). This is the "cyan/red/blue visual feedback" in the criterion.

### Pattern 3: Anchor placement (DGT-01)
**What:** Anchors are a second marker kind: same raycast+overlay as landmarks, distinct store, distinct color (native green `(0,1,0)`, `3dDigitize.digitize.r:48`), written as the `AC3=` block.
**How:** Reuse the Phase-4 pick handler shape (`view3d.R` pointerdown, `transport.R` `.gmw_pick_handler`) with a `/<token>/anchor` route that appends to `session$specimens[[cur]]$anchor`. Overlay dots in a second `THREE.Group` colored green. Count-gating (max anchor count) mirrors `addAnchor` (`3dDigitize.digitize.r:1067-1111`).

### Pattern 4: Surface semilandmark display, delete, undo, multi-specimen (DGT-02)
**Surfaces are R-computed, browser-displayed.** `downSample` (`3dDigitize.surface.r:400-567`) builds a template (landmarks [+anchors] + k-means centers), warps it with TPS (`tps2d3d`), and nearest-neighbours onto the specimen to produce `sliders` (s×3), stored at `activeDataList[[currImgId]][[8]]`. The browser does **not** compute surfaces; it triggers `downsample`/`build-template` and displays the result as a point cloud.
**Display flatten — MANDATORY transpose (Pitfall 1):** send surface points to the browser as `as.vector(t(surfaces[,,id]))` (row-major `[x1,y1,z1,x2,...]`). `.gmw_flat` in `view3d.R:22-28` already does `as.vector(t(m))`, so a clouds layer is the natural carrier. Omitting the transpose column-orders the flat vector and scrambles point order.
**Delete:** browser click → nearest overlay point → POST `/<token>/delete` `"kind,idx"` → R removes that row from the session array → re-send the cloud. Mirror native delete semantics (`deleteLandmark`/`deleteAnchor`, `3dDigitize.digitize.r:922-965`).
**Undo:** mirror the native `doUndo` action grammar (`3dDigitize.digitize.r:72-155`): actions `place` / `delete` / `move` / `curve_place`, one-deep (`pushUndo` overwrites), cleared on specimen switch (`clearUndo`). Keep it server-side in `.gmw_session[[token]]$undo`.
**Multi-specimen switch:** Phase 2 fixed **one specimen per viewport** (D-01). DGT-02 requires switching. See Open Question 1 — the two viable designs are (a) re-serve the next specimen's mesh bytes + overlays on a `/<token>/specimen` request, or (b) serve all meshes up front and toggle visibility. Recentring differs from the parity/replay path; keep the interactive `group.position.sub(sphere.center)` framing but store/display overlays in the correct frame per specimen.

### Pattern 5: GPA + export driven from the browser (DGT-03)
**What:** `compute` (`geomorph::gpagen`), `save` (`.csv`), `exportGeomorph` (`.rds`), `plotspecs`/`plotPCA`/`plotMeanShape` are **pure R** and produce identical results by construction. The browser adds a trigger route (`/<token>/gpa`, `/<token>/export`).
**The one coupling to fix:** `.build_geomorph_data` (`3dDigitize.geomorph.r:203-288`) reads landmarks via `.landmarks_for_specimen` → `getLandmark(i)` (C engine) with a fallback to `activeDataList[[i]][[10]]`, and curves/surfaces from `activeDataList`. For the browser path, add a source that reads the **session model** (Pattern 1) instead of the C engine — the cleanest is to populate the same `activeDataList` slots from the session, or add a session-aware accessor. Result-plot delivery already routes through `.gmw_view3d` (`3dDigitize.geomorph.r:374-484`), so no new plumbing is needed there. Options (`max.iter`, `PrinAxes`, `ProcD`, `Proj`, `approxBE`, `Parallel`, curves/surfaces toggles) are the parity-critical inputs — `test-gpa-parity.R` already asserts they are forwarded; keep them.

### Pattern 6: `.dgt` byte-identity = one writer, made deterministic (DAT-01 / DAT-02)
**What:** `saveToDgt` (`3dDigitize.main.r:1931-2026`) writes the whole session: `Curve=` block, `TemplateNumber=NULL`, then per specimen `LM3=`/`AC3=`/`ID=`/`Template=`/`Surface=` blocks, via `.dgt_write_matrix_block` which formats with `formatC(as.numeric(x), format="f", digits=6)` (`3dDigitize.main.r:203-215`). The `folsom3d.dgt` fixture shows the exact target format (space-separated, six decimals, blank-line separators).
**Make it deterministic (prerequisite — the open todo `dat-parity-gate-is-a-skip.md`):**
- **Rounding:** wrap the value — `formatC(round(as.numeric(x), 6), format="f", digits=6)` — so R's rounding, not libc tie-breaking, decides the sixth decimal (the todo found 10 lines differing by exactly 1e-6 between the two native platforms).
- **Line terminator:** the writer currently appends with `write()`/`writeLines()` which emit the platform EOL; the merge path already pins `\r\n` via `file(output, open="wb")` (`3dDigitize.main.r:3440`). Pick ONE terminator and pin it in `.dgt_write_matrix_block`/`saveToDgt` so browser-vs-native and cross-platform bytes match. `.gitattributes` already marks `*.dgt -text` so fixtures survive checkout.
**DAT-01 proof:** given identical in-memory arrays, the browser Save and the native Save both call the identical deterministic writer ⇒ byte-identical files. The test writes from one array via the browser-triggered path and compares raw md5 (`.byte_signature`, `test-dgt-cross-platform.R:7-13`) against the native-triggered path.
**DAT-02:** reader (`read.digitize`/`read.curve`/`read.surface`/`read.anchors`) and writer are shared R code, so a GUImorph-authored file opens here and a GUImorphWeb-authored file opens in GUImorph — **as far as GUImorph's own cross-platform parity extends.** The two `-rewrite` fixtures are owed (Windows re-save; see Environment Availability). State the macOS→Windows limitation.

### Anti-Patterns to Avoid
- **Rebuilding the digitizing workflow on the C engine.** The browser path must not call `getLandmark`/`getAnchor`/`add`/`set`; that re-couples acquisition to `tkogl2`, which Phase 6 deletes. Own state in R (Pattern 1).
- **A second `.dgt` serializer for the browser.** Any divergence from `.dgt_write_matrix_block` breaks DAT-01. Route browser Save through the identical writer.
- **Omitting the surface transpose.** `as.vector(surfaces[,,id])` (no `t()`) scrambles point order silently. Always `as.vector(t(...))` and cover it with a regression test (the ROADMAP note is explicit).
- **Storing curves as coordinates.** Curves are landmark **indices**; storing coordinates breaks `geomorph`'s `curves` argument and `.dgt` semantics.
- **Joining the request path to the filesystem** in any new route handler — reopens T-2-02 path traversal. Only ever `grepl` the path suffix (inherited invariant, `transport.R:175-197`).
- **Exceeding the 8192-byte `sprintf` fmt cap** in `.gmw_view3d_html`. New template JS goes in the parameter-free BODY after the `MESH_URL = "%s";` marker (`view3d.R:81-96`); keep injections in the HEAD.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GPA / Procrustes | A custom aligner | `geomorph::gpagen` (existing `compute`) | Validated pipeline; DGT-03 requires identical-to-native output. |
| TPS surface warp / downsample | A new warp | Existing `downSample` + `gm_utils` `tps2d3d`/`rotate.mat`/`cSize` | Already validated; reuse verbatim. |
| Ray–triangle pick over scan meshes | A custom picker | three-mesh-bvh (`computeBoundsTree` + patched `raycast`) | Already vendored; O(log n); Phase-4 proven. Re-run `computeBoundsTree` per specimen switch. |
| `.dgt` read/write | A browser-side serializer | R `saveToDgt`/`read.*` (shared) | One-writer byte-identity is the whole DAT-01 architecture. |
| JSON in R for transport | Add `jsonlite` | base `strsplit`/`as.numeric` over `"x,y,z"` bodies | Project stays JSON-dependency-free (`view3d.R` header); Phase-4 precedent. |
| Mean-shape mesh reconstruction | Hand-rolled meshing | `Rvcg::vcgBallPivoting` (existing `plotMeanShape`) | Already wired through `.gmw_view3d`. |

**Key insight:** Almost everything numerically hard already exists in the R layer and is reused unchanged. Phase 5's real work is (1) an R-side server-owned session model the browser edits, (2) browser interaction + overlay rendering for anchors/curves/surfaces/delete/undo/switch, and (3) making the shared writer deterministic. The risk is *wiring and state ownership*, not algorithms.

## Common Pitfalls

### Pitfall 1: Surface flatten without the transpose (scrambled point order)
**What goes wrong:** Surface semilandmarks render in the wrong positions / wrong order; GPA correspondence silently breaks.
**Why it happens:** `surfaces[,,id]` is a p×3 (points × xyz) matrix. `as.vector(m)` is column-major → `[x1,x2,...,xp,y1,...]`; the C `downsample` command and three.js want row-major `[x1,y1,z1,x2,...]`, which is `as.vector(t(m))`.
**How to avoid:** Always `as.vector(t(surfaces[,,id]))` (as `showPicture`/`drawElements` do, `3dDigitize.main.r:1100,1846`; `.gmw_flat` already does it). **Cover with a regression test** (`test-surface-flatten.R`) — the ROADMAP note demands a test, not care.
**Warning signs:** Surface points look "smeared" or transposed vs the mesh; GPA results shift when surfaces are enabled.

### Pitfall 2: Non-deterministic `.dgt` writer (CRLF + libc rounding)
**What goes wrong:** DAT-01/DAT-02 byte tests fail (or the gate silently `skip()`s and reports green — the current state).
**Why it happens:** platform EOL differences on every line, plus libc float→decimal tie-breaking differing by 1e-6 in ~10 of ~6000 lines (documented in the todo).
**How to avoid:** `formatC(round(x, 6), ...)` and a pinned line terminator in the writer; keep `.gitattributes *.dgt -text`.
**Warning signs:** `.byte_signature` md5 mismatch that vanishes under `.dgt_normalize_lines` (which strips CR + trims) — that gap is exactly the bug.

### Pitfall 3: Reusing the parity/replay recentring in the interactive path
**What goes wrong:** Overlays land offset by the bounding-sphere center after a specimen switch.
**Why it happens:** The interactive path recentres geometry (`group.position.sub(sphere.center)`, `view3d.R:214-221`); the Phase-4 replay path deliberately uses the raw PLY frame at identity. Mixing them offsets hits/overlays.
**How to avoid:** Keep interactive picks in the recentred group (existing `worldToLocal` already yields raw PLY-vertex coords); when switching specimens, re-frame and re-place overlays consistently in that specimen's frame.
**Warning signs:** First specimen correct, subsequent specimens' dots offset by a constant.

### Pitfall 4: Multi-specimen state bleed / stale BVH
**What goes wrong:** Wrong specimen's overlays shown, or picks miss after a switch.
**Why it happens:** one-viewport assumption (D-01); a single `pickMesh`/BVH is reused without rebuild.
**How to avoid:** On switch, load the new mesh, `computeBoundsTree()` again (eager, Phase-4 Pitfall 5), and load that specimen's overlays from the session model. Clear undo on switch (native `clearUndo`).
**Warning signs:** picks land on the previous specimen's geometry; overlays don't change with the specimen.

### Pitfall 5: Curve indices vs coordinates / cross-specimen curve scope
**What goes wrong:** Curves fail in `gpagen` or don't round-trip through `.dgt`.
**Why it happens:** storing coordinates instead of indices, or making curves per-specimen when the model is per-session (`activeDataList[[1]][[4]]`).
**How to avoid:** Store 3 integer indices per segment; keep curves session-scoped (shared across specimens), matching the existing model and `.build_geomorph_data` (`3dDigitize.geomorph.r:225-233`).
**Warning signs:** `gpagen` "invalid subscript" errors; curve block empty or wrong after reload.

## Code Examples

### Deterministic `.dgt` number formatting (DAT-01 prerequisite)
```r
# EDIT of .dgt_format_num (3dDigitize.main.r:203-205): round in R, then format,
# so libc tie-breaking never decides the sixth decimal.
.dgt_format_num <- function(x) {
  formatC(round(as.numeric(x), 6), format = "f", digits = 6)
}
# And pin the terminator where blocks are written, e.g. open the file wb and
# writeLines(..., sep = "\n") consistently (mirror the merge path,
# 3dDigitize.main.r:3440, which already does file(output, open="wb") + "\r\n").
```

### Server-owned session mutation over a token-guarded route (mirrors `.gmw_pick_handler`)
```r
# Extends transport.R's mixed app. Same invariants: grepl the suffix only, never
# join req path to FS; bare-CSV body, base-R parse, no JSON.
.gmw_curve_handler_branch <- function(token, req) {          # inside the per-token call handler
  if (grepl("/curve$", req$PATH_INFO)) {
    body <- tryCatch(rawToChar(req$rook.input$read()), error = function(e) "")
    idx  <- suppressWarnings(as.integer(strsplit(body, ",", fixed = TRUE)[[1]]))
    if (length(idx) == 3L && all(is.finite(idx)) && length(unique(idx)) == 3L) {
      s <- get(token, envir = .gmw_session)
      s$curves <- rbind(s$curves, matrix(idx, 1L, 3L))       # curves are per-session indices
      s$undo   <- list(action = "curve_place", row = idx)
      assign(token, s, envir = .gmw_session)
    }
    return(list(status = 204L, headers = list(), body = ""))
  }
  NULL
}
```

### Flatten surfaces for browser display (Pitfall 1 — the mandated transpose)
```r
# surfaces[,,id] is p x 3. as.vector(t(.)) is the ONLY correct row-major flatten.
flat_surface <- function(surfaces, id) as.vector(t(surfaces[, , id]))
# .gmw_flat(surfaces[,,id]) is equivalent and reuses the existing helper (view3d.R:22).
```

### Byte-identity assertion (DAT-01, reusing the existing helper)
```r
# .byte_signature() (test-dgt-cross-platform.R:7-13) raw-md5s a file.
expect_identical(.byte_signature(browser_written_dgt),
                 .byte_signature(native_written_dgt))
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| C-engine-owned digitizing state (`GBL_*` globals, `getLandmark`) | R server-owned state (`.gmw_picks` → session model) | Phase 4→5 | Acquisition decoupled from `tkogl2` ahead of its Phase-6 deletion. |
| Tk canvas + `tkbind` interaction | Browser three.js + loopback POST routes | Phase 4→5 | No Tk/C in the acquisition path; matches REFERENCE-ARCHITECTURE. |
| `.dgt` writer implicitly platform-dependent (CRLF + libc rounding) | Deterministic writer (explicit round + pinned EOL) | Phase 5 (this) | Makes byte-identity a real, testable contract (todo item (a)). |
| One specimen per viewport (D-01) | Multi-specimen switch in one viewport | Phase 5 (this) | Required by DGT-02; PLANNER DECISION on re-serve vs toggle. |

**Deprecated/outdated:**
- Do not reintroduce `Morpho` (removed in Phase 1; `fastKmeans` reimplemented in `template_kmeans.R`).
- Do not route result plots through `rgl` (Phase 1 moved them to `.gmw_view3d`).
- `loadDgt` (the C `.dgt` reader stub in `rtkogl.R:444`) is a placeholder — `.dgt` reading is done in R (`openDgt`); do not revive the C path.

## Runtime State Inventory

> Phase 5 is feature work, not a rename/migration. There is no persisted external state to migrate. Recorded explicitly per the protocol:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `.dgt`/`.csv`/`.rds` files on disk are user documents, not app-managed state. In-session state lives in R (`activeDataList`; new `.gmw_session`) and C globals (native path only). | None — new session model is created fresh per viewport; no migration. |
| Live service config | None — the only "service" is the per-viewport loopback `httpuv` listener, created/destroyed per session. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | None — no secrets model (`.cursor/rules` STACK: "No `.env`/secrets"). Only `options(guimorph.debug)`. | None. |
| Build artifacts | The prebuilt `tkogl2` engine (`inst/libs/`) — untouched this phase (CMP-01), deleted in Phase 6. | None this phase. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| three.js + three-mesh-bvh (vendored) | DGT-01/02 overlays + picking | ✓ | 0.185.1 / 0.9.13 | — |
| httpuv + later | new digitizing routes | ✓ | locked Import | — |
| geomorph | DGT-03 GPA + export | ✓ | >= 4.1.1 | — |
| Rvcg | template/downsample, mean-shape | ✓ | 0.25 | — |
| `windows-/mac-authored-roundtrip.dgt` | DAT-02 fixtures | ✓ | committed | — |
| **`*-rewrite.dgt` (re-save halves)** | **DAT-01/DAT-02 un-skip the gate** | ✗ | — | **Windows re-save (todo steps); gate stays a documented skip until then** |
| **Native `tkogl2` on Windows** | DAT-01 native-write leg; CMP-01 load | ✗ (no Windows host per Phase 4 D-06) | — | write-vs-write byte test at the R level; CMP-01 skip-if-absent idiom |
| Browser + display host | manual DGT-01/02 UAT | ✗ (headless sandbox) | — | executable manual UAT steps (Phase 3/4 `# MANUAL UAT` + VALIDATION.md pattern) |
| GUImorph macOS→Windows `.dgt` parity | DAT-02 (one direction) | ✗ (external, open upstream) | — | **state the limitation; do not claim a fully-proven bidirectional contract** |

**Missing dependencies with no fallback:** none that block building this phase's code. Two closures are external/tracked: the `-rewrite` fixtures (Windows re-save) and GUImorph's macOS→Windows leg.
**Missing dependencies with fallback:** Windows native oracle → R-level write-vs-write byte test + skip-if-absent; display host → manual UAT recorded as executable steps.

## Validation Architecture

`workflow.nyquist_validation: true` → this section applies.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat 3.3.2 (edition 3) |
| Config file | `tests/testthat.R` + per-file `test-*.R` |
| Quick run command | `Rscript -e 'testthat::test_file("tests/testthat/test-dgt-determinism.R")'` |
| Full suite command | `Rscript -e 'devtools::test()'` (note: suite is pre-existing 6-red — STATE.md Open Items; do not attribute to Phase 5) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DGT-01 | Curve route appends 3 distinct indices; duplicates/malformed dropped | unit (handler w/ injected `req`) | `test_file("tests/testthat/test-digitizing-session.R")` | ❌ Wave 0 |
| DGT-01 | Anchor route appends coord to session; count-gated | unit | same | ❌ Wave 0 |
| DGT-01 | Template wires anchor pick + curve-by-index click + cyan/blue recolor | source-scan (grep template) | `test_file("tests/testthat/test-digitizing-view3d.R")` | ❌ Wave 0 |
| DGT-02 | Surface flatten uses `as.vector(t(...))` (order preserved) | unit (regression) | `test_file("tests/testthat/test-surface-flatten.R")` | ❌ Wave 0 |
| DGT-02 | Delete removes correct row; undo restores (place/delete/curve_place) | unit | `test-digitizing-session.R` | ❌ Wave 0 |
| DGT-02 | Specimen switch loads correct overlays + rebuilds BVH | source-scan + unit (session current-index) | `test-digitizing-view3d.R` / `test-digitizing-session.R` | ❌ Wave 0 |
| DGT-03 | `.build_geomorph_data` reads session model; gpagen options forwarded | unit + existing source-scan | `test-gpa-parity.R` (extend) | ✅ (extend) |
| DGT-03 | Export routes trigger `save`/`exportGeomorph`; identical output | integration | `test-export-parity.R` (extend) | ✅ (extend) |
| DAT-01 | Deterministic writer: round + pinned EOL; browser-write == native-write bytes | unit + byte-identity | `test-dgt-determinism.R` + `test-dgt-cross-platform.R` | partial (extend) |
| DAT-02 | Authored↔rewrite byte gate; reader accepts both dialects | integration (skip-if-absent) | `test-dgt-cross-platform.R` | ✅ (skips until `-rewrite` fixtures land) |
| CMP-01 | `.gmw_engine$ok` TRUE when native present; skip when absent | unit (skip-if-absent) | reuse `test-retina-picking-parity.R` idiom | reuse |

### Sampling Rate
- **Per task commit:** `test_file(...)` for the touched test.
- **Per wave merge:** `devtools::test()` (filter to new files if the pre-existing reds block — they are unrelated per STATE.md).
- **Phase gate:** new digitizing/session/determinism/flatten tests green; DAT-01 byte test green; DAT-02 gate green **or** documented skip with the `-rewrite`/upstream reason; CMP-01 recorded (load deferred to a Windows host per the standing Phase-4 todo).

### Wave 0 Gaps
- [ ] `tests/testthat/test-digitizing-session.R` — curve-by-index, anchor, delete, undo, specimen-index session mutations
- [ ] `tests/testthat/test-surface-flatten.R` — `as.vector(t(surfaces[,,id]))` regression (Pitfall 1)
- [ ] `tests/testthat/test-dgt-determinism.R` — writer round + pinned-EOL determinism (DAT-01 prerequisite)
- [ ] `tests/testthat/test-digitizing-view3d.R` — source-scan the new template wiring (mirror `test-picking-view3d.R`)
- [ ] `tests/fixtures/parity/windows-authored-roundtrip-rewrite.dgt` + `mac-authored-roundtrip-rewrite.dgt` — Windows re-save (un-skips `test-dgt-cross-platform.R`)
- [ ] Extend `test-gpa-parity.R` / `test-export-parity.R` for the session-model read path

## Security Domain

`security_enforcement: true`, ASVS level 1. This phase adds several untrusted-input boundaries — each new browser→R route body — all extending the Phase-4 pick boundary.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Local loopback; the ≥128-bit path token is the only guard (inherited, `transport.R`). |
| V3 Session Management | no | No sessions; per-viewport token in the URL path. |
| V4 Access Control | yes | `host = "127.0.0.1"` only (T-2-03); per-token path; unknown token → 404. Handlers close over their own token (no cross-token write, T-4-04). |
| V5 Input Validation | **yes** | Every route body parsed with base R to a bounded numeric/integer vector of exact expected arity; anything else dropped. Never `eval`, never treat a body/path as a filename. Export "fmt" restricted to an allow-list (`csv`/`rds`/`dgt`), never joined to a path from the request. |
| V6 Cryptography | no | No new crypto; token generator unchanged (base-R `sample()`, residual risk already accepted). |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via request path | Tampering | Only `grepl` the suffix (`/curve$` etc.); never `file.path`/`normalizePath`/`readBin` on `req$PATH_INFO` (T-2-02, inherited). |
| Malformed/oversized route body | DoS/Tampering | Bounded, arity-checked numeric/integer parse; drop non-conforming bodies (Phase-4 precedent). |
| Save/export path injection | Tampering | Export target chosen R-side via existing `tkgetSaveFile`/known dir; the route carries only a format token from an allow-list, never a path. |
| Cross-token write | Tampering | Handler closes over its own token; writes only `.gmw_session[[token]]`. |
| LAN exposure | Info disclosure | Loopback-only bind (inherited). |
| Stopping other packages' listeners | DoS | Teardown iterates `.gmw_server` only (T-3-03, inherited). |

## Project Constraints (from .cursor/rules/)
- **GSD workflow enforcement:** repo edits go through a GSD command (`/gsd-execute-phase` for this planned work); no direct edits outside the workflow.
- **R package root:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`; C engine root `.../tkogl2/`. Keep the existing extension convention (`.r` for the legacy `3dDigitize.*` modules, `.R` for `transport.R`/`view3d.R`/`parity.R`/`rtkogl.R`).
- **Naming:** `camelCase` for GUI/action handlers; `dot.separated` for file-I/O/module constructors (`read.curve`, `write.surface`, `.dgt_write_matrix_block`); `.gmw_*` for the browser transport/session layer.
- **Error handling (R):** user-facing errors surfaced inline (status bar) in the Tk path; `stop(call.=FALSE)` for hard R-level failures (mirror `.gmw_serve_mesh`). Bridge/handler functions return `TRUE`/`FALSE` or `204`/`404`.
- **Logging:** `dbg()` gated printer only; no raw `print`.
- **Exports:** keep the surface minimal; new internals `@noRd`/`@keywords internal` unless a genuine user entry point is needed (mirror `gmw_close`/`gmw_picks` export shape).
- **CMP-01 non-negotiable:** never touch the `rtkogl.R` `.onLoad`/`.gmw_require_engine` engine-load path; the native oracle must stay loadable through Phase 5 (retired in Phase 6).
- **JSON-free:** no `jsonlite`; bare-CSV bodies + base-R parse (view3d.R header).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | DAT-01 means "same in-memory session state serialized by the identical writer yields identical bytes" (one writer vs itself), per STATE.md/ROADMAP; browser and native picks need not be numerically equal | Summary, Pattern 6 | If DAT-01 instead demands equal *picks* across the two engines, that is PICK-03's (deferred) concern and would over-scope Phase 5. Confirm framing at plan time. |
| A2 | Making the writer deterministic (todo option (a): explicit round + pinned EOL) is the accepted resolution over changing the contract to tolerance (option (b)) | Pattern 6, Pitfall 2 | If the user prefers (b), the byte tests become tolerance/structure assertions instead. **User decision needed.** |
| A3 | The browser acquisition path should own state in R (extend `.gmw_picks`), not reuse the C engine accessors | Pattern 1, Anti-Patterns | If the planner instead bridges through `getLandmark`/`getAnchor`, acquisition stays coupled to `tkogl2` and Phase 6 retirement gets harder. Strongly grounded in STATE.md but is a design choice. |
| A4 | Multi-specimen switch is delivered by re-serving mesh bytes + overlays per `/<token>/specimen` request (vs serve-all-and-toggle) | Pattern 4, Open Question 1 | Re-serve re-transfers a 30 MB worst-case mesh on each switch; toggle avoids that but holds N meshes in GPU memory. **Planner decision.** |
| A5 | The route surface (separate routes vs one verb-in-body route) is JSON-free bare-CSV over the mixed httpuv app | Pattern 1/2, Standard Stack Alternatives | Either shape works; both preserve the no-path-join invariant. **Planner decision.** |
| A6 | GUImorph's macOS→Windows `.dgt` leg is still open at Phase-5 landing (per ROADMAP note) | DAT-02, Environment Availability | If GUImorph closes it first, DAT-02 can claim full bidirectionality; otherwise state the half-proven limitation. Track, do not own. |
| A7 | Curves remain session-scoped (`activeDataList[[1]][[4]]`), shared across specimens | Pattern 2/5, Pitfall 5 | If per-specimen curves are wanted, the data model and `.build_geomorph_data` change. Matches existing behavior. |

**User confirmation needed at plan time:** A1 (DAT-01 framing), A2 (byte-true vs tolerance contract), A4/A5 (multi-specimen + route shape design choices — normally CONTEXT.md, absent here).

## Open Questions (RESOLVED)

> All three resolved at plan time (no CONTEXT.md; recommended defaults adopted as stated assumptions the user may override). Cross-referenced to the plans that implement them.

1. **Multi-specimen in one viewport: re-serve or toggle?**
   - What we know: Phase 2 fixed one specimen per viewport (D-01); DGT-02 needs switching; BVH must be rebuilt per mesh; overlays are per-specimen; curves are session-scoped.
   - What's unclear: re-serve mesh bytes on switch (simple, re-transfers up to 30 MB) vs serve-all-and-toggle (no re-transfer, N× GPU memory).
   - Recommendation: default to **re-serve** (simplest, matches D-01, one mesh live at a time); add a `/<token>/specimen "n"` route that re-serves bytes + that specimen's flattened overlays. Planner confirms.
   - **RESOLVED: re-serve (Assumption A4).** The `/<token>/specimen` route sets the current index, clears undo, and returns the target mesh URL + flattened overlays (05-02); the browser loads that mesh and rebuilds the BVH on switch (05-03). Not serve-all-and-toggle.

2. **DAT-01 "from the same session" mechanics.**
   - What we know: R keeps the writer; both triggers call it; identical arrays ⇒ identical bytes.
   - What's unclear: whether the test drives a live native GUI + browser viewport in one process, or asserts at the R level that both save entry points serialize identical in-memory arrays byte-for-byte.
   - Recommendation: implement the **R-level write-vs-write byte test** (deterministic writer, one array, two entry points) as the primary automated gate; treat any live dual-path run as manual UAT. Confirm at plan time.
   - **RESOLVED: R-level write-vs-write byte test is the primary automated gate; the live native-GUI-vs-browser dual-path run is manual UAT (05-06).** `.gmw_save_session_dgt` reuses the one canonical deterministic writer, and `test-dgt-cross-platform.R` asserts `.byte_signature` equality over identical arrays.

3. **Where does the browser session model meet `.build_geomorph_data`?**
   - What we know: `.build_geomorph_data` reads `getLandmark` (C) + `activeDataList` (curves/surfaces).
   - What's unclear: populate `activeDataList` slots from the session model, or add a session-aware accessor branch.
   - Recommendation: populate the existing `activeDataList` slots from the session model so `compute`/`save`/`exportGeomorph` are reused with zero edits beyond the read source — smallest change, preserves `test-gpa-parity.R`.
   - **RESOLVED: populate the existing `activeDataList` slots from the session model (05-05).** `.gmw_session_to_geomorph_env` writes landmarks into `activeDataList[[i]][[10]]`, curves into `[[1]][[4]]`, surfaces into `[[i]][[8]]`, so `.build_geomorph_data`/`compute` run with zero forwarding edits and `test-gpa-parity.R` still passes.

## Sources

### Primary (HIGH confidence — read from source in-repo this session)
- `R/transport.R` — mixed httpuv app, `excludeStaticPath`, `.gmw_pick_handler`, `.gmw_server`/`.gmw_picks`/`.gmw_lifecycle` env idiom, token, teardown, security invariants.
- `R/view3d.R` — `GMW_VIEW3D_TEMPLATE`, `.gmw_flat` (transpose), PLYLoader callback, `computeBoundsTree`, pointer pick + `worldToLocal` (mesh-local frame), overlay group, 8192-byte head/body split, `GMW_REPLAY`.
- `R/parity.R` — `.gmw_mean_edge_length`, `.gmw_parity_gate`, `.gmw_read_pick_poses` (base-R, JSON-free).
- `R/3dDigitize.main.r` — `saveToDgt`, `.dgt_write_matrix_block`/`.dgt_format_num`/`.dgt_normalize_lines`/`.csv_normalize_lines`, `openDgt`, `drawElements`, `read.vertex.3D`/`write.vertex.3D`, `mergeDgt` (pinned `\r\n`), `getLandmark`/`getAnchor`/`convertCoor`, `activeDataList` slot layout.
- `R/3dDigitize.curve.r` — `onSelectCurve` (3-index selection, cyan/blue recolor), `read.curve`/`write.curve`, `.redrawAllCurves`/`.clearAllCurves`.
- `R/3dDigitize.surface.r` — `buildTemplate`, `downSample` (TPS warp), `read.surface`/`write.surface`/`write.nts`, `getTemplate`, surface `[[8]]` slot.
- `R/3dDigitize.digitize.r` — `addDot`/`addAnchor`, `deleteLandmark`/`deleteAnchor`, `doUndo`/`pushUndo`/`clearUndo` action grammar, `.placeIsDuplicate`.
- `R/3dDigitize.geomorph.r` — `.build_geomorph_data`, `compute` (gpagen options), `save` (.csv), `exportGeomorph` (.rds), `plotspecs`/`plotPCA`/`plotMeanShape` via `.gmw_view3d`.
- `R/rtkogl.R` — `add`/`set`/`shows`/`del` bridge, `.gmw_engine`/`.gmw_require_engine`/`.onLoad` (CMP-01), `.plot_show`.
- `tests/testthat/test-dgt-cross-platform.R`, `test-gpa-parity.R`, `test-export-parity.R`, `test-curve-io.R`, `test-picking-view3d.R` — byte-signature helper, source-scan + skip-if-absent idioms.
- `tests/fixtures/parity/` (`*-authored-roundtrip.dgt`, `reference-export.csv`), `inst/extdata/folsom3d.dgt` (canonical writer format), `.gitattributes` (`*.dgt -text`).
- `.planning/todos/pending/dat-parity-gate-is-a-skip.md` — the byte-identity blocker (CRLF + 1e-6 rounding), fix options (a)/(b), `-rewrite` fixtures owed.
- `.planning/STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `config.json`, `.cursor/rules/gsd.md` — architecture, decisions, workflow toggles, conventions.
- `.planning/phases/04-picking-parity/04-RESEARCH.md` — Phase-4 patterns this phase extends (route shape, overlay, BVH, JSON-free transport, skip idiom).

### Secondary (MEDIUM confidence)
- three.js Raycaster / overlay docs: `intersection.point` world-space; DoubleSide to hit back faces; `updateWorldMatrix` before `worldToLocal`. `[CITED: threejs.org/docs Raycaster; discourse 57294 — via Phase-4 research]`

### Tertiary (LOW confidence)
- None load-bearing this phase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — nothing new to install; all versions read from manifest/DESCRIPTION.
- Architecture (session model, transport extension, writer determinism, GPA/export reuse): HIGH — every claim traced to in-repo source this session.
- `.dgt` byte-identity path: HIGH on the fix (round + pinned EOL, documented in the todo); MEDIUM on final closure (needs Windows re-save fixtures — external).
- DAT-02 bidirectionality: MEDIUM — one direction gated by GUImorph's own open macOS→Windows leg (external, tracked).
- Multi-specimen + route-shape designs: MEDIUM — no CONTEXT.md; framed as planner decisions with recommended defaults.

**Research date:** 2026-08-07
**Valid until:** ~2026-09-07 (stable stack; three/BVH pinned; R analytical layer inherited and stable). Re-check the two external items (`-rewrite` fixtures; GUImorph macOS→Windows leg) before claiming DAT-01/DAT-02 fully closed.
