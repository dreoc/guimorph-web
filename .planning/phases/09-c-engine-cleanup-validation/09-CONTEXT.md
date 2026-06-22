# Phase 9: C Engine Cleanup & Validation - Context

**Gathered:** 2026-06-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Final in-place rehabilitation of the `tkogl2` C engine (Option A). Three jobs:
1. **CENG-03** — Replace the numbered globals (`GBL_PTR_*_1..N` shorthand in the roadmap) with arrays; document capacity limits in headers.
2. **CENG-04** — Remove debug cruft: pervasive `printf` tracing, `MAKE_INERT` blocks, and `if(0)` debug toggles.
3. **CENG-05** — Prove no regression: full `load PLY → digitize → save .dgt → reload → analyze` workflow matches the Phase 4–5 baseline.

This is internal cleanup behind the unchanged DLL interface (`Tkogl2_Init` export + R↔Tcl shape-string protocol preserved). **Not** in scope: new capabilities, renderer changes, dynamic-storage redesign, automated test harness, or touching the frozen `def_ZARF_9.h` type layout.

</domain>

<decisions>
## Implementation Decisions

### Globals → Arrays (CENG-03)
- **D-01:** Replace numbered globals with **fixed-capacity static arrays**. Capacity is exposed as a **named `#define` documented in the owning header** — directly satisfies the "limits documented in headers" success criterion.
- **D-02:** **Behavior-preserving** — same effective count and indexing as today. No functional change to how the engine uses these slots; this is a structural rename + array-ification only.
- **D-03:** **Respect the frozen `def_ZARF_9.h` layout** (Phase 8 D-08). `dot_t`/enum stay untouched. Array conversions are localized to the modules that own each global, with `extern` declarations updated in the appropriate header (single-definition + extern convention from Phase 7).
- **D-13:** Rejected dynamic/growable allocation for Phase 9 — adds malloc/realloc failure paths and regression risk for no current need. (See Deferred.)

### Debug Cruft Removal (CENG-04)
- **D-04:** **Remove pure tracing `printf`** outright. **Port any load-bearing diagnostics through `tcl_log.c`** (the Phase 7 logging module) rather than deleting them.
- **D-05:** **Caution on the `openDgt` reload path** — a prior fix interacted with `printf` removal (STATE: "openDgt Surface=0 … `printf`, vacuous NA, `queryFromR`/`e` scope"). Any `printf` near that path is treated as potentially load-bearing and verified before removal.
- **D-06:** **Delete `MAKE_INERT`-wrapped code outright** (remove the dead/broken code, not just the guards). `CODE_FOR_LIBRARY` is the active build mode; `MAKE_INERT` was explicitly documented as "temporary" and "should be removed for a formal release" in `RunTime_Defines_ZARF_9.h`.
- **D-07:** **Delete `if(0)` debug toggles** outright (e.g. `ogl_model_ZARF_9.c:488`).
- **D-08:** **No retained compile-time debug-flag facility** — clean removal over toggles (user chose "balanced," not the "conservative/keep-re-enable" path). `tcl_log.c` is the single surviving diagnostic channel.

### Regression Validation (CENG-05)
- **D-09:** **Full Phase 4–5 round-trip is the bar:** load PLY → digitize landmarks + curves + anchors → save `.dgt` → reload → GPA. The analysis step is explicitly required (success criterion names "analyze").
- **D-10:** **Two fixtures** exercise both the digitize and Phase 8 dedup paths: Phase 4 `test_fresh.dgt` and the Phase 8 anchors+curves `.dgt` (`test_dgt_anchors_curves.dgt`).
- **D-11:** **Manual Windows MSVC GUI UAT** — no automated Tk/OpenGL harness. Append pass/fail results to `.planning/smoke-test-findings.md` (carried-forward UAT pattern).
- **D-12:** **"Identical to baseline" judged by manual visual + functional confirmation**, not an automated before/after output diff (matches prior-phase UAT pattern; user did not request the heavier diff option).

### Build & Docs (09-03)
- **D-14:** Update `BUILD.md` with the **final module-layout table** (`tcl_dispatch` / `tcl_window` / `tcl_state` / `tcl_log` / `tcl_init` + `marker.c` + `curve_ZARF_9.c` + `ogl_*`); **prune obsolete references** to the deleted god file (`tcl_if_ZARF_9.c`) and the reference-only `.vcxproj`. Keep **MSVC-only** build instructions.

### Process / Safety (carried forward)
- **D-15:** **Back up the pre-Phase-9 DLL** before refactoring (parallel to Phase 7 `.pre-phase7.bak` and Phase 8 D-13) so the cleanup is rollback-able.
- **D-16:** **MSVC is the supported build toolchain** — MinGW renders incorrectly (Phase 7/8). All builds and UAT use the MSVC DLL.

### Claude's Discretion
- **Work ordering** within the phase (planner decides). Recommended: globals refactor → debug removal → validation last, so the regression UAT exercises the fully-cleaned engine.
- **Exact capacity values** for each array — derive from the current numbered-global counts during research.
- **Per-`printf` disposition** — case-by-case: pure tracing → delete; error/user-facing/load-bearing → route through `tcl_log.c`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/ROADMAP.md` — Phase 9 goal, plans 09-01–09-03, success criteria
- `.planning/REQUIREMENTS.md` — CENG-03, CENG-04, CENG-05 definitions
- `.planning/PROJECT.md` — Option A scope; C-rehab strategy; constraint to preserve `Tkogl2_Init` export + R↔Tcl shape-string protocol
- `.planning/STATE.md` — Phase 8 completion handoff; accumulated C-engine decisions

### Prior phase handoffs
- `.planning/phases/07-c-engine-modularization/07-02-SUMMARY.md` — module split, single-definition-global + `extern`-in-header convention
- `.planning/phases/07-c-engine-modularization/` — full five-module layout; god file removed from CMake (07-03)
- `.planning/phases/08-c-engine-deduplication/` — `marker.c` unification; `def_ZARF_9.h` frozen (D-08); pre-Phase-8 DLL backup (D-13)
- `.planning/smoke-test-findings.md` — prior UAT log; append the Phase 9 regression section here

### C engine source (cleanup targets)
- `integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h` — shared types/externs; **FROZEN** layout (`dot_t`/enum)
- `integrated-guimorph-development_EOC/Project/tkogl2/src/RunTime_Defines_ZARF_9.h` — `CODE_FOR_LIBRARY` / `MAKE_INERT` directive definitions
- `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_log.c` — logging facility; destination for load-bearing diagnostics
- `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c` — engine state (likely numbered-global owner)
- `integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c` — Phase 8 unified dot/anchor sets (`g_landmarks`/`g_anchors`) — array-state precedent
- `integrated-guimorph-development_EOC/Project/tkogl2/src/curve_ZARF_9.c` — ~47 `printf`; curve state
- `integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ply_ZARF_9.c` — ~100 `printf` (PLY loader tracing — biggest target)
- `integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ZARF_9.c` — `if(0)` toggle at line 488; ~17 `printf`
- `integrated-guimorph-development_EOC/Project/tkogl2/src/StatisticsFunction_ZARF_9.c` — ~17 `printf`
- `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt` — module list; MSVC build
- `BUILD.md` — build-deploy-test cycle; update module-layout table (D-14)

### Test data (local, do not commit)
- `zips/Folsom 3D models/test_fresh.dgt` — Phase 4 multi-specimen fixture
- `zips/Folsom 3D models/test_dgt_anchors_curves.dgt` — Phase 8 anchors+curves fixture
- `zips/Folsom 3D models/C13.1.ply`, `C8.1.ply` — specimen meshes referenced by the `.dgt` files

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`tcl_log.c`** (Phase 7 logging module) — the single surviving diagnostic channel; load-bearing `printf` output is ported here rather than deleted.
- **`marker.c`** (`g_landmarks`/`g_anchors`, Phase 8) — already array-backed marker state; precedent/pattern for the numbered-global → array conversion.

### Established Patterns
- **Single-definition globals + `extern` in headers** (Phase 7 convention) — array conversions follow the same definition/declaration split.
- **`CODE_FOR_LIBRARY` build mode** already gates library vs standalone/test code — relevant when removing `MAKE_INERT`/test-only blocks.
- **`def_ZARF_9.h` frozen layout** (Phase 8 D-08) — hard boundary for any header edits.

### Integration Points
- **`Tkogl2_Init` export + R↔Tcl shape-string protocol** must remain byte-for-byte compatible (PROJECT constraint) — cleanup cannot alter the DLL's external surface.
- **`CMakeLists.txt`** module list (MSVC) — touched only if file membership changes; no god file remains.

</code_context>

<specifics>
## Specific Ideas

- The regression bar must include the **analysis step (GPA)**, not just the digitize round-trip.
- User prefers **clean removal** of debug cruft over a retained debug-flag toggle.
- **Flagged caution:** `printf` near the `openDgt` reload path is treated as potentially load-bearing and verified before removal.
- Use **both** the Phase 4 and Phase 8 `.dgt` fixtures so dedup'd anchor/curve paths are covered.

</specifics>

<deferred>
## Deferred Ideas

- **Dynamic/growable global storage** (removing hard capacity limits via malloc/realloc) — out of scope for Phase 9; revisit only if a real capacity ceiling is hit.
- **Automated smoke-test harness** (QA-01, v2) — manual Windows MSVC UAT remains primary for this milestone.
- **Capture the 26 `load_all` warnings** — pre-existing concern tracked separately, not a Phase 9 cleanup target.
- **Per-specimen curve bind / C curve state on specimen switch** — future work noted in STATE blockers.
- **PLY vertex coloration for geometry-only (all-zero RGB) scans** — deferred; lighting fallback already in place.

</deferred>

---

*Phase: 09-c-engine-cleanup-validation*
*Context gathered: 2026-06-22*
