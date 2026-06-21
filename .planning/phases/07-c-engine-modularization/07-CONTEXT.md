# Phase 7: C Engine Modularization - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Split the 5,581-line `tcl_if_ZARF_9.c` god file into maintainable C modules without changing runtime behavior. Phase 7 delivers structural extraction only — dispatch, window/WGL, state, and logging into separate translation units, with a thin `tcl_init.c` entry point. Requirements CENG-01 must pass.

This phase does **not** unify dot/anchor code (Phase 8), replace numbered globals with arrays (Phase 9), or remove debug cruft (Phase 9). Depends on Phase 6 locking a reproducible dev baseline before the first extraction.

</domain>

<decisions>
## Implementation Decisions

### Module Boundaries
- **D-01:** **Draw functions → `tcl_dispatch.c`** — `drawDots`, `drawAnchors`, `drawCurves`, `drawGrid` live with Tcl command handlers that invoke them (`show`, `add`, etc.).
- **D-02:** **Logging → `tcl_log.c`** — `simpleLog_Open`, `simpleLogWriteLandmarksToFile`, `simpleLogWriteAnchorsToFile`, and related logging in a dedicated file separate from state.
- **D-03:** **State/globals → `tcl_state.c`** — `initialize_state`, `resetContext`, `clear_deltas`, `GBL_PTR_MODEL_*`, `GBL_PTR_CONTEXT_*`, `GBL_PTR_CURVE_*`, landmark/curve set globals, and specimen counters together.
- **D-04:** **Entry point → `tcl_init.c`** — rename god file; retain only `Tkogl2_Init` and `Tcl_CreateObjCommand` registration. All other code moves out.

### Target File Layout (Phase 7 end state)
| File | Responsibility |
|------|----------------|
| `tcl_init.c` | `Tkogl2_Init`, Tcl command registration |
| `tcl_dispatch.c` | Tcl handlers (`add`, `show`, `set`, `setWindow`, `setSpecimen`, `setDot`, `del`, `loadDgt`, etc.) + draw pass functions |
| `tcl_window.c` | `setWindowId`, HWND/WGL setup, window dimensions |
| `tcl_state.c` | Specimen/model state, globals, init/reset |
| `tcl_log.c` | Debug logging helpers |

Existing modules (`dot_ZARF_9.c`, `curve_ZARF_9.c`, `ogl_*.c`) unchanged except `#include`/header updates if needed for linking.

### Regression Verification
- **D-05:** **Per-plan smoke (07-01, 07-02, 07-03)** — after each extraction: `cmake --build`, verify `Tkogl2_Init` export, launch `GUImorph()`, load PLY (`C13.1.ply`), place at least one landmark (double-click).
- **D-06:** **Final smoke (07-03 completion)** — full digitize round-trip: landmarks + curve + save `.dgt` + same-session reload via `openDgt` (Phase 4 workflow on `test_fresh.dgt` or equivalent fresh session).
- **D-07:** **Document UAT in both** — append pass/fail to `.planning/smoke-test-findings.md` and record technical notes in each plan SUMMARY.
- **D-08:** **Keep pre-Phase-7 DLL backup** — preserve current working `inst/libs/x64/tkogl2.dll` (or tagged build artifact) before first extraction for side-by-side comparison if regression suspected.

### Extraction Order & Build
- **D-09:** **ROADMAP sequence** — 07-01 dispatch → 07-02 window → 07-03 state + log + init rename.
- **D-10:** **`tcl_log.c` + `tcl_init.c` rename in 07-03** — bundled with state extraction and final smoke test.
- **D-11:** **Incremental CMake** — add each new source file to `CMakeLists.txt` in the plan that introduces it.
- **D-12:** **Scope boundary** — modify god file and new headers only; no logic changes in `dot_ZARF_9.c`, `curve_ZARF_9.c`, or `ogl_*.c` (include/header updates allowed).

### Naming & Headers
- **D-13:** **Clean file names** — `tcl_dispatch.c`, `tcl_window.c`, `tcl_state.c`, `tcl_log.c`, `tcl_init.c` (no `_ZARF_9` suffix on new modules).
- **D-14:** **Per-module headers** — `tcl_dispatch.h`, `tcl_window.h`, `tcl_state.h`, `tcl_log.h` for cross-module APIs; keep `def_ZARF_9.h` for shared types/structs.
- **D-15:** **Minimal linkage changes** — preserve current symbol visibility during Phase 7; do not aggressively `static`-ify helpers (tighten in Phase 9).
- **D-16:** **BUILD.md updates each plan** — document new C source layout incrementally as files are added.

### Carried Forward (prior phases — do not re-decide)
- **Option A** locked — rehabilitate C in place; no rgl/Shiny rewrite.
- Dot/anchor dedup deferred to Phase 8; globals/debug cleanup deferred to Phase 9.
- `Tkogl2_Init` export name and Tcl command set must remain stable.
- R↔Tcl shape string protocol unchanged.
- Manual Windows R GUI UAT is primary verification (no automated Tk/OpenGL harness).
- Landmark placement requires double-click on canvas.
- Phase 6 must complete first — reproducible baseline (`renv`, BUILD.md, deploy workflow) before C refactor.

### Claude's Discretion
- Exact line ranges and move order within each extraction plan.
- Which symbols go in which module header vs remain in `def_ZARF_9.h`.
- Whether `directive` / wrapper helpers split with dispatch or stay until 07-03.
- Specific BUILD.md section structure for file-layout documentation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/ROADMAP.md` — Phase 7 goal, plans 07-01–07-03, success criteria, dependency on Phase 6
- `.planning/REQUIREMENTS.md` — CENG-01 definition
- `.planning/PROJECT.md` — Option A scope, C refactor constraints
- `.planning/STATE.md` — current milestone position

### Architecture & research
- `.planning/research/ARCHITECTURE.md` — target module boundaries (dispatch/window/state)
- `.planning/research/PITFALLS.md` — refactor-before-GUI-works; DLL export surface stability (pitfalls 1, 8)
- `.planning/research/STACK.md` — C engine rehabilitation approach (Phases 7–9)
- `.planning/research/SUMMARY.md` — Phases 1–6 must complete before Phase 7
- `.planning/guimorph-modernization-plan.md` — god file assessment, duplication notes

### Phase handoff & validation
- `.planning/phases/04-digitize-workflow/04-CONTEXT.md` — digitize smoke workflow, `test_fresh.dgt`, double-click UX
- `.planning/phases/05-analysis-round-trip/05-CONTEXT.md` — manual UAT pattern, smoke-test-findings append
- `.planning/smoke-test-findings.md` — append Phase 7 UAT results (D-07)

### Primary C source (modularization targets)
- `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_if_ZARF_9.c` — 5,581-line god file to split
- `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt` — source list to update incrementally
- `integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h` — shared types; extend carefully for cross-module refs

### Unchanged C modules (reference only)
- `integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c`
- `integrated-guimorph-development_EOC/Project/tkogl2/src/curve_ZARF_9.c`
- `integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_ZARF9.c`
- `integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ZARF_9.c`
- `integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ply_ZARF_9.c`

### Build & deploy
- `BUILD.md` — update file layout each plan (D-16)
- `integrated-guimorph-development_EOC/Project/tkogl2/cmake/mingw-w64-x86_64.cmake` — MinGW cross-compile toolchain

### Test data (local, do not commit)
- `zips/Folsom 3D models/C13.1.ply` — per-step PLY smoke
- `zips/Folsom 3D models/test_fresh.dgt` — final digitize round-trip (Phase 4 fixture)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **CMake/MinGW build** — proven path produces `tkogl2.dll` with `Tkogl2_Init` export; incremental source additions are low-risk.
- **Existing module split** — `dot_ZARF_9.c`, `curve_ZARF_9.c`, `ogl_*.c` already separate; god file is the outlier.
- **Phase 4 digitize workflow** — validated smoke path for final regression (landmarks, curve, `.dgt` save/reload).

### Established Patterns
- **`Tkogl2_Init` at line ~4146** — registers 8 Tcl commands: `add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`.
- **`setWindowId` at line ~582** — HWND → WGL context setup; natural window-module boundary.
- **Tcl handlers** — `add` (~1068–2730), `show` (~2731–2997) are largest dispatch blocks; draw functions at ~639–902 sit between window setup and handlers.
- **Global state cluster** — `GBL_PTR_MODEL_1..5`, `GBL_PTR_CONTEXT_1..5`, `GBL_PTR_CURVE_1..6` at file top (~62–106); `initialize_state` at ~404.

### Integration Points
- **R load path** — `rtkogl.R` `.onLoad` loads `inst/libs/x64/tkogl2.dll`; export name must not change.
- **Deploy workflow** — Phase 6 `deploy-dll.ps1` (when complete) swaps built DLL; Phase 7 must keep deploy path working.
- **No R-side changes** — modularization is C-only behind stable Tcl command interface.

</code_context>

<specifics>
## Specific Ideas

- User corrected logging placement: dedicated `tcl_log.c`, not bundled with state.
- User wants stronger regression than ROADMAP minimum — landmark per step, full digitize round-trip at end.
- Pre-Phase-7 DLL backup for rollback comparison, not just git tagging.
- BUILD.md should reflect new layout as each file appears, not deferred to Phase 9.

</specifics>

<deferred>
## Deferred Ideas

- **Dot/anchor unification** — Phase 8 (`marker.c`); do not merge during Phase 7 even if convenient.
- **GBL_PTR_* array replacement** — Phase 9; keep numbered globals during modularization.
- **Debug removal (`MAKE_INERT`, `if(0)`, printf tracing)** — Phase 9; move with modules but do not delete/toggle.
- **Aggressive `static` linkage tightening** — Phase 9 or post-modularization cleanup.
- **Rename existing `_ZARF_9` modules** — out of scope; only new split files get clean names.
- **Automated C unit tests** — `unit_test_ogl_*` harness exists in god file but manual GUI UAT is primary.

</deferred>

---

*Phase: 07-c-engine-modularization*
*Context gathered: 2026-06-19*
