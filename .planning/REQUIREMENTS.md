# Requirements — Milestone v1.0: Browser Rendering

**Goal:** GUImorphWeb digitizes 3D specimens through a browser surface driven from
R, at full feature parity with GUImorph's native engine, and writes byte-identical
`.dgt` and export files. The native engine is retained only as a parity oracle and
removed at Phase 6.

**Source:** `.planning/PROJECT.md`. Inherited context from the GUImorph macOS
milestone is referenced where it constrains this work, but that milestone's
requirement IDs are not carried forward.

**Stack decisions, fixed up front:** three.js (WebGL baseline, WebGPU
opportunistic via automatic fallback, built-in PLY loader and raycaster),
`three-mesh-bvh` for picking acceleration, `httpuv` for the local server, JS
vendored in `inst/htmlwidgets/`, no CDN, no runtime network.

---

## v1 Requirements

### Result Plots and Dependency Demotion

- [ ] **WEB-00**: three.js and `three-mesh-bvh` are vendored into `inst/htmlwidgets/` with licence files, and a minimal htmlwidget wrapper (scene, camera, orbit, resize, reset view) renders from R with no network access. Owned by Phase 1 because PLT-01 is the first thing that needs it; WEB-02 and PICK-01 reuse the same wrapper
- [ ] **PLT-01**: `plotspecs` (aligned specimens) and `plotMeanShape` render through the WEB-00 widget as point clouds with orbit, zoom, and reset view. Read-only: no picking, no overlay editing. GPA results are small enough to pass as JSON, so this needs no HTTP transport
- [ ] **PLT-02**: `library(GUImorphWeb)` succeeds and the full digitizing workflow runs on a host where `library(rgl)` fails. This requires removing **Morpho**, not just demoting rgl: Morpho hard-imports rgl, was pulled in wholesale by `import(Morpho)`, and was used for exactly one function (`fastKmeans`), now reimplemented over Rvcg in `R/template_kmeans.R`. `rgl` and `htmlwidgets` move to `Suggests` with all call sites guarded; the unused `vegan` and `parallel` imports are dropped. See `.planning/phases/01-browser-result-plots-rgl-demotion/01-RESEARCH.md`
- [ ] **PLT-03**: `plotPCA` works without a native graphics device. It stays base-graphics 2D and is **not** converted to WebGL. The single-component ordination crash was already fixed in 0.10.0 (`a8a6cf0`); do not reopen it

### Transport and Display

- [ ] **WEB-01**: An `httpuv` server started from R binds to loopback on an unprivileged port and serves the PLY as bytes over HTTP, never JSON-encoded, behind a per-session random path or token
- [ ] **WEB-02**: three.js `PLYLoader` fetches and renders the served mesh with orbit, zoom, and reset view, on stock macOS and stock Windows, with no XQuartz, Homebrew, or Tcl/Tk in the render path
- [ ] **WEB-03**: a clean `install.packages()` on a fresh R opens a working viewport with the machine fully offline, on both Windows and macOS (the vendoring itself lands in Phase 1 as WEB-00)
- [ ] **WEB-04**: Port selection, browser launch, and teardown (viewport close, session exit, R session end) are reliable on a managed machine: occupied ports fail with a clear R-level error rather than a hang, no orphaned listener survives, and a missing, misconfigured, or blocked default browser degrades legibly

### Picking

- [ ] **PICK-01**: A BVH-accelerated raycast against the loaded mesh returns a hit coordinate to R at interactive rates on the reference specimens
- [ ] **PICK-02**: Landmark dots render as overlay geometry at returned coordinates with correct depth behavior under rotation
- [ ] **PICK-03**: On the same specimen at the same click position, the browser coordinate matches the native engine's `gluUnProject` result within a documented tolerance, stated in mesh units and justified against inter-observer digitizing error. **This is the milestone gate**

### Digitizing

- [ ] **DGT-01**: Curve definition in the browser with the existing three-click selection and cyan/red/blue feedback, plus anchor placement
- [ ] **DGT-02**: Surface semilandmark display, delete, undo, and multi-specimen switching in the browser
- [ ] **DGT-03**: GPA (`geomorph::gpagen`) and `.csv`/`.rds` export driven from the browser UI, producing results identical to the native path on the same input

### Data Contract

- [ ] **DAT-01**: A `.dgt` written through the browser path is byte-identical to one written through the native path from the same session
- [ ] **DAT-02**: A GUImorph-authored `.dgt` opens correctly in GUImorphWeb, and a GUImorphWeb-authored `.dgt` opens correctly in GUImorph. Verified both directions against `tests/fixtures/parity/`

### Shell and Retirement

- [ ] **UI-01**: Tabs, dialogs, specimen navigation, and status bar reimplemented in the browser shell at parity with the Tk chrome
- [ ] **UI-02**: The complete workflow runs with the native engine uninstalled and absent from the library path
- [ ] **UI-03**: `tkogl2` is deleted from the package, `rgl` is removed from dependencies entirely, and a migration note ships in `NEWS.md` with a pinnable version for users who must stay on the native path

### Recurring Gate

- [ ] **CMP-01**: The retained native engine stays loadable and functional at every phase through Phase 5, so it remains usable as the PICK-03 parity oracle. Deliberately retired at Phase 6

---

## v2 / Deferred

- [ ] Linux (any windowing system) support. The architecture makes it nearly free; scoping and testing are a follow-on milestone
- [ ] WebGPU as a first-class target rather than an opportunistic fallback
- [ ] Draco or binary-PLY compression for large scans, if WEB-02 transfer time proves unacceptable on the reference set

## Out of Scope

- Maintaining or extending the native macOS OpenGL path. That work continues in GUImorph on its own track
- Metal-backed native rendering. Superseded by this architecture
- Rewriting the `geomorph` / `Morpho` / `Rvcg` analysis pipeline. Validated, reused as-is
- Merging this project back into GUImorph. They diverge at the rendering layer by design

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| WEB-00 | Phase 1 | Not started |
| PLT-01 | Phase 1 | Not started — depends on WEB-00 |
| PLT-02 | Phase 1 | Not started |
| PLT-03 | Phase 1 | Not started |
| WEB-01 | Phase 2 | Not started |
| WEB-02 | Phase 2 | Not started |
| WEB-03 | Phase 3 | Not started |
| WEB-04 | Phase 3 | Not started |
| PICK-01 | Phase 4 | Not started |
| PICK-02 | Phase 4 | Not started |
| PICK-03 | Phase 4 | Not started — **milestone gate** |
| DGT-01 | Phase 5 | Not started |
| DGT-02 | Phase 5 | Not started |
| DGT-03 | Phase 5 | Not started |
| DAT-01 | Phase 5 | Not started |
| DAT-02 | Phase 5 | Not started — depends on GUImorph closing its macOS-to-Windows `.dgt` leg |
| UI-01 | Phase 6 | Not started |
| UI-02 | Phase 6 | Not started |
| UI-03 | Phase 6 | Not started |
| CMP-01 | Phase 1 (recurs through Phase 5) | Not started |

**Coverage:** 21/21 v1 requirements mapped, no orphans, no duplicates. CMP-01 is
owned by Phase 1 for mapping but enforced as a "native oracle still works"
success criterion in every phase through Phase 5.

**Dependency outside this project:** DAT-02's GUImorph-to-GUImorphWeb direction
is only as strong as GUImorph's own cross-platform `.dgt` parity, which is closed
Windows to macOS but not macOS to Windows. Track it, do not own it.
