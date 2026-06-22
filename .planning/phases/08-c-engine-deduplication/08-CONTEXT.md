# Phase 8: C Engine Deduplication - Context

**Gathered:** 2026-06-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Collapse the duplicated `dot_*` / `anchor_*` implementations in
`integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c` into a single
shared marker code path (CENG-02). Both families are near-identical copies operating
on parallel globals; the duplication is acknowledged in-source (line ~665: *"all
anchor functions are directly analogous to above dot functions"*). The shared `dot_t`
struct already carries a `type` field (`LANDMARK` / `ANCHOR`).

This phase delivers **behavior-preserving-for-landmarks** deduplication plus a
**deliberate correctness fix for anchors** (the anchor path currently mutates the
wrong selection globals — see decisions). It does **not** replace numbered globals
with arrays (Phase 9 / CENG-03), does **not** remove broad debug cruft such as
`MAKE_INERT` / `if(0)` toggles / pervasive `printf` tracing (Phase 9 / CENG-04), and
does **not** touch curve code. `Tkogl2_Init` export and the Tcl command set stay
stable; the R↔Tcl protocol is unchanged.

</domain>

<decisions>
## Implementation Decisions

### Unification Structure
- **D-01:** **Shared core + thin wrappers.** Implement a single `marker_*` function
  family that takes a marker-set pointer; keep `dot_*` / `anchor_*` as one-line
  wrappers that pass the correct set. **`tcl_dispatch.c` is NOT modified** — all
  existing call sites (`dot_add`/`anchor_add`, `dot_select`/`anchor_select`,
  `drawDots`/`drawAnchors`, `*_del`, `*_color`, `*_move`, `get_*_size_for_slice_index`,
  etc.) keep working through the wrappers. Lowest regression risk.
- **D-02:** **Group per-type state into a `marker_set_t` struct.** Bundle the array
  (`dots`/`anchors`), `slice_id`, `slice_amount`, `selected`, and `selected_id` into
  one struct, with two static instances (e.g. `g_landmarks`, `g_anchors`). The shared
  functions operate on a passed-in `marker_set_t*`. **NOTE:** this is *grouping only* —
  replacing the numbered `GBL_PTR_*` globals with arrays is Phase 9, not here.

### Behavior: Preserve vs Fix
- **D-03:** **Fix the anchor asymmetry (intended outcome, not a regression).** Today
  `anchor_select`, `anchor_move`, and `anchor_color` mutate the **dot** `selected` /
  `selected_id` globals (dot_ZARF_9.c ~lines 1021-1022, 1039, 1058), and `anchor_del`
  lacks some bounds checks `dot_del` has. The unified core uses each set's **own**
  selection state and full bounds checks, so anchors select/move/delete correctly.
  This is a deliberate behavior change for anchors — they are effectively broken today.
- **D-04:** **Landmark behavior must remain identical.** The unified path must produce
  the same observable landmark behavior as today (placement, select, move, delete,
  draw). Landmarks are the validated Phase 4 path — no regression allowed.
- **D-05:** **Trim only the in-loop `select` logging that collapses on merge.** The dot
  `select` path has heavy per-coordinate `IS_IN_RANGE` debug logging the anchor path
  lacks; when the two bodies merge, reduce that noisy in-loop logging. **Scope guard:**
  this is limited to the per-coordinate select logging that naturally disappears on
  merge — broader debug-cruft removal (`MAKE_INERT`, `if(0)` toggles, pervasive
  `printf` tracing) stays in Phase 9 (CENG-04).

### Module Layout
- **D-06:** **New `marker.c` / `marker.h` module** (matches ROADMAP hint). `marker.c`
  holds the shared `marker_*` core, the `marker_set_t` struct, and the absorbed
  `dot_*` / `anchor_*` wrappers.
- **D-07:** **Delete `dot_ZARF_9.c`** once its content is absorbed into `marker.c` —
  same pattern Phase 7 used when it deleted the `tcl_if_ZARF_9.c` god file.
- **D-08:** **Shared types stay in `def_ZARF_9.h`.** `dot_t` and the `LANDMARK`/`ANCHOR`
  enum remain in `def_ZARF_9.h`. The `dot_*`/`anchor_*` function declarations currently
  in `def_ZARF_9.h` should be reconciled with a new `marker.h` (planner's discretion on
  exact split, but cross-module API belongs in `marker.h`).
- **D-09:** **Update `CMakeLists.txt`** to add `marker.c` and drop `dot_ZARF_9.c`,
  incrementally as in Phase 7.

### Verification
- **D-10:** **Anchor-specific UAT is mandatory** (because D-03 changes anchor behavior).
  Manual Windows R GUI UAT must exercise **anchor place + select + move + delete** —
  the exact functions changed — not just landmark placement.
- **D-11:** **`.dgt` regression baseline = full Phase 4 round-trip + anchor persistence.**
  Reuse `test_fresh.dgt`-style flow: load PLY → landmarks + curve → save → same-session
  `openDgt` reload (Phase 7 final-smoke parity). Additionally place an anchor before
  save and confirm it reloads — **conditional on anchors actually being serialized into
  `.dgt`** (see Open Questions). If anchors are not persisted to `.dgt`, drop the
  persistence check and rely on the in-session anchor UAT (D-10).
- **D-12:** **Document UAT** in `.planning/smoke-test-findings.md` and in each plan
  SUMMARY (same convention as Phases 4/5/7).
- **D-13:** **Keep a pre-Phase-8 DLL backup** for side-by-side comparison if a
  regression is suspected (same risk-control pattern as Phase 7's `.pre-phase7.bak`).

### Claude's Discretion
- Exact `marker_set_t` field names and the two instance names.
- Exact split of declarations between `marker.h` and `def_ZARF_9.h`.
- Whether `marker_*` branches on `dot_t.type` internally anywhere, or relies purely on
  the passed-in set (set-pointer approach preferred per D-01/D-02).
- How to consolidate the many near-duplicate accessor variants (`get_dot_slice_id` /
  `get_dot_slice_index`, `dot_size` / `dot_getListLengthAtCurrentSlice` /
  `get_dot_size_for_slice_index`, `dot_get` / `dot_get_dot` / `get_dot_at_index_current_slice`)
  — consolidate where safe, but wrappers must preserve every name dispatch calls.
- Plan splitting across 08-01 (characterize) / 08-02 (implement marker.c) / 08-03
  (remove duplicates + verify), or a tighter split if warranted.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/ROADMAP.md` — Phase 8 goal, plans 08-01–08-03, success criteria, dependency on Phase 7
- `.planning/REQUIREMENTS.md` — CENG-02 definition (and CENG-03/04/05 boundaries deferred to Phase 9)
- `.planning/PROJECT.md` — Option A scope; C-refactor constraints (preserve `Tkogl2_Init`, R↔Tcl protocol)
- `.planning/STATE.md` — current milestone position; accumulated decisions/blockers

### Primary C source (deduplication targets)
- `integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c` — the duplicated `dot_*`/`anchor_*` bodies to unify; duplication acknowledged at ~line 665
- `integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h` — `dot_t` struct + `LANDMARK`/`ANCHOR` enum (~lines 75-92); current `dot_*`/`anchor_*` declarations (~lines 174-181)
- `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c` — call sites that must keep working unchanged (`drawDots`/`drawAnchors`, `add`/`show`/`del`/`set` handlers; anchor calls at ~lines 1431, 1528, 3201, 3349, 3480-3484)
- `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt` — source list (add `marker.c`, drop `dot_ZARF_9.c`)
- `integrated-guimorph-development_EOC/Project/tkogl2/src/curve_ZARF_9.c` — reference only; `curve_addDot(int, dot_t*)` consumes `dot_t` (do NOT modify in this phase)

### Phase 7 modularization handoff
- `.planning/phases/07-c-engine-modularization/07-CONTEXT.md` — five-module `tcl_*` layout, scope-boundary conventions, "no logic change to dot/curve/ogl" (now superseded for dot by this phase)
- `.planning/phases/07-c-engine-modularization/07-03-SUMMARY.md` — god-file deletion pattern (precedent for deleting `dot_ZARF_9.c`); five-module CMake state

### Digitize / analysis verification patterns
- `.planning/phases/04-digitize-workflow/04-CONTEXT.md` — digitize smoke workflow, `test_fresh.dgt`, double-click placement UX
- `.planning/phases/05-analysis-round-trip/05-CONTEXT.md` — manual UAT pattern; append to smoke-test-findings
- `.planning/smoke-test-findings.md` — append Phase 8 UAT results (D-12)

### Build & test data
- `BUILD.md` — build/deploy/test cycle; update file-layout table for `marker.c`
- `zips/Folsom 3D models/C13.1.ply` — per-step PLY smoke (local, do not commit)
- `zips/Folsom 3D models/test_fresh.dgt` — digitize round-trip fixture (local, do not commit)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`dot_t.type` discriminator already exists** (`def_ZARF_9.h` `LANDMARK`/`ANCHOR`
  enum) — `dot_add` sets `type = LANDMARK`, `anchor_add` sets `type = ANCHOR`. The
  unified node already self-identifies; the unification is mainly about collapsing the
  container/accessor logic, not the node type.
- **Phase 7 god-file deletion precedent** — Phase 7 added new `tcl_*` modules and
  deleted the old file from CMake with passing smoke; the same incremental
  add-new-file/delete-old-file pattern applies to `marker.c` vs `dot_ZARF_9.c`.
- **Validated Phase 4 digitize smoke path** — landmarks + curve + `.dgt` save/reload is
  the proven regression harness; reuse for D-11.

### Established Patterns
- **Parallel global state** — `dots`/`anchors` arrays, `dot_slice_id`/`anchor_slice_id`,
  `dot_slice_amount`/`anchor_slice_amount`, `selected`/`anchor_selected` are mirrored
  statics in `dot_ZARF_9.c`. `marker_set_t` (D-02) maps directly onto this shape.
- **Wrapper/alias proliferation** — many duplicate-named accessors exist
  (`get_dot_slice_id` vs `get_dot_slice_index`; `dotGetSelectedIndex` →
  `dot_selected_id`; `dotGetPointerToTheSelectedDot` → `dot_get_selected`). Wrappers
  must preserve every name dispatch/headers reference.
- **Manual GUI UAT only** — no automated Tk/OpenGL harness; Windows R is the runtime
  (Windows-only per Option A). MSVC is the supported Windows build toolchain (MinGW
  builds render incorrectly per STATE.md 2026-06-21).

### Integration Points
- **`tcl_dispatch.c`** is the sole consumer of the `dot_*`/`anchor_*` API — keeping
  those names (D-01) means zero dispatch changes.
- **`curve_ZARF_9.c`** consumes `dot_t*` via `curve_addDot` — `dot_t` layout must not
  change.
- **R load path** — `rtkogl.R` `.onLoad` loads `inst/libs/x64/tkogl2.dll`; export name
  unchanged. Built DLL must be deployed to `inst/libs/x64/` for Windows R UAT.

</code_context>

<specifics>
## Specific Ideas

- User explicitly wants the anchor bugs **fixed** as the natural outcome of dedup
  (not preserved bug-for-bug) — anchors should select/move/delete correctly via their
  own state.
- User wants a real anchor GUI exercise (place + select + move + delete), not just a
  "does it render" check, precisely because the asymmetry fix changes anchor behavior.
- User accepts pulling the in-loop `select` logging trim forward, but the broader debug
  cleanup stays Phase 9.
- Follow Phase 7's deletion precedent: new `marker.c`, delete `dot_ZARF_9.c`.

</specifics>

<deferred>
## Deferred Ideas

- **Numbered globals → arrays** (`GBL_PTR_*_1..N`, and the per-type statics) — Phase 9
  (CENG-03). `marker_set_t` only *groups* state this phase; it does not array-ify the
  numbered globals.
- **Broad debug-cruft removal** (`MAKE_INERT`, `if(0)` toggles, pervasive `printf`
  tracing) — Phase 9 (CENG-04). Only the in-loop select logging that collapses on merge
  is trimmed here (D-05).
- **Aggressive `static` linkage tightening / dead-code removal** (e.g.
  `dot_get_dot` marked "DON'T USE", commented-out old `anchor_select`) — Phase 9 or
  post-rehab cleanup; remove only what is unambiguously dead during unification.
- **Curve deduplication / per-specimen curve bind** — out of scope; curves are a
  separate module (noted as future work in STATE.md).

## Open Questions (for research/planning)
- **Does `.dgt` serialize anchors?** D-11's anchor-persistence check depends on this.
  Researcher/planner must confirm whether anchor data is written to / read from `.dgt`
  (check the `loadDgt` handler and the R-side `.dgt` writer). If not, drop the
  persistence check and rely on in-session anchor UAT (D-10).

</deferred>

---

*Phase: 08-c-engine-deduplication*
*Context gathered: 2026-06-21*
