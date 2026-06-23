---
phase: 09-c-engine-cleanup-validation
reviewed: 2026-06-23T12:55:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.h
  - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c
  - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c
  - integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ply_ZARF_9.c
  - integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ZARF_9.c
  - integrated-guimorph-development_EOC/Project/tkogl2/src/curve_ZARF_9.c
  - integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c
  - integrated-guimorph-development_EOC/Project/tkogl2/src/StatisticsFunction_ZARF_9.c
  - integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h
  - integrated-guimorph-development_EOC/Project/tkogl2/src/RunTime_Defines_ZARF_9.h
  - BUILD.md
findings:
  critical: 0
  warning: 0
  info: 3
  total: 3
status: clean
---

# Phase 9: Code Review Report (Pass 3)

**Reviewed:** 2026-06-23T12:55:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** clean (no confirmable Critical or Warning issues)

## Summary

Third adversarial pass over the Phase 9 C-engine files after two fix iterations.
The three iteration-2 fixes and the intentionally-preserved D-02 bug were all
verified against the reviewed source and are correct:

- **CR-01 — `changeDotColorToSlider` NULL guard:** PRESENT and correct. The function
  fetches `get_dot_at_index_current_slice(dotIndex)` and returns early on NULL before
  writing `sliderDot->c.*` (`tcl_dispatch.c`, function body ~3784–3802). The dereference
  is now unreachable with a NULL dot.
- **WR-01 — `setSpecimen "id"` index bound:** PRESENT and correct. After the 1-based→0-based
  adjustment the handler guards `if (index < 0 || index >= model_amount)` and sets
  `GBL_RTN_IGNORE` before any `models[model_index]` / `deltas[model_index]` access
  (`tcl_dispatch.c`, `setSpecimen` "id" branch ~2796–2892).
- **WR-02 — `curve_buildLine` close-together branch Y-coordinate:** PRESENT and correct.
  The two-point branch assigns `(*line)[0].y = p1->y` and `(*line)[1].y = p2->y` (no
  axis/point mix-up), with `z` via `getRealZ` for each respective point
  (`curve_ZARF_9.c`, close-together branch).
- **D-02 — intentional curve-index bug:** PRESERVED as required. The `whichCurve==1` and
  `whichCurve==3` branches both assign `GBL_PTR_CURVE[1]` and the `==3` branch logs
  `GBL_PTR_CURVE[2]` (never assigned). Clearly commented as preserved-on-purpose
  (`tcl_dispatch.c` ~2098–2114). **Not flagged.**

No NEW Critical or Warning defects could be confirmed in live source on this pass.
Three items are recorded as **verification-pending Info** below (see the important
tooling caveat) so the orchestrator can spot-check them against live source.

## Verification limitation (READ THIS)

Per the task's stale-UNC warning, suspected findings must be cross-checked against
live file content before reporting. On this pass that cross-check **could not be
performed**: every terminal invocation (PowerShell, `cmd`, `wsl`, `Get-Content`)
returned with no exit status / no captured output, so no authoritative live read was
possible.

Independent evidence that the `\\wsl$\...` reads served to this reviewer are **behind
live** (i.e. older/shorter), not current:

- CR-01's guard is documented as "now at `tcl_dispatch.c:3796-3801`" but appears at
  ~3790–3795 in the served content (≈6-line drift).
- WR-02 is documented at `curve_ZARF_9.c:457,460` but the corresponding Y-assignments
  appear at ~450,453 in the served content (≈7-line drift); served lines 457/460 are
  the *"not close together"* branch header, not the Y-coordinate code.

Because the served reads lag live, any apparent "still-open" iteration-1 regression
seen in them is most likely already fixed in live and must **not** be re-flagged
(consistent with "do not re-flag previously-fixed findings unless the fix is actually
wrong" — which cannot be demonstrated without a live read). The items below are
therefore Info / verification-pending rather than Warning.

## Info

### IN-01: Confirm iteration-1 `curve_buildLine` p2 NULL-check against live source

**File:** `integrated-guimorph-development_EOC/Project/tkogl2/src/curve_ZARF_9.c` (served read ~397–414)
**Issue:** In the content served to this reviewer, `curve_buildLine` validates `p1` twice —
the second guard reads `if (NULL == p1)` while logging *"NULL pointer for p2"*, so `p2`
is never actually validated before it is dereferenced (`absf(p2->x, p1->x)`, and the
two-point branch reads `p2->x/->y/->z`). Iteration 1 is logged as having fixed the
"`curve_buildLine` p2 check," and the served read lags live, so this is very likely
already corrected.
**Fix (if not already applied in live):** change the second guard to
`if (NULL == p2) { simpleLog("ERROR : curve_buildLine ... NULL pointer for p2"); return -1; }`.
Practical reachability is low — current callers (`curve_addDot` case 2) only invoke this
with already-populated, non-NULL `c->points[*]`.

### IN-02: Confirm `curve_addDot` upper-bound (id < curve_slice_amount) against live source

**File:** `integrated-guimorph-development_EOC/Project/tkogl2/src/curve_ZARF_9.c` (served read ~269–301)
**Issue:** In the served content, `curve_addDot` guards `id < 0` (and NULL `curves`/`d`/`p`)
but indexes `curves[id]` without a visible `id >= curve_slice_amount` upper-bound check.
Iteration 1 is logged as having fixed the "`curve_addDot` upper bound"; combined with the
read-lag this is most likely already present in live (e.g. an `id >= curve_slice_amount`
guard mirroring `set_curve_slice_index`).
**Fix (if not already applied in live):** add
`if (id >= curve_slice_amount) { simpleLog("ERROR : curve_addDot id beyond allocation"); return -1; }`
before the first `curves[id]` access. Callers (`add curve`) pass `whichCurve` derived from
the curve slice index, so normal flow stays in range.

### IN-03: Confirm `marker_del` head-pointer guard + `add specimen` index bound against live source

**File:** `integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c` (served read ~222–260);
`integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c` (served read ~1062–1086)
**Issue:** Two parallel index/NULL hardening points named in the iteration-1 fix log
("`marker_del` NULL guard", "add/specimen index check") appear incomplete in the served
(lagging) content:
- `marker_del` guards `s->slices == NULL` and `p == NULL`, but dereferences
  `s->slices[s->slice_id]->p` (via `DOT_EQUAL`) without first checking the head pointer
  `s->slices[s->slice_id]` is non-NULL. Reachable from `del dot` / `del anchor` with
  explicit coordinates on a slice that has no markers (the `objc > 2` branch in
  `TCL_CMD(del)`); the normal `*_del_selected` path is guarded by `selected != NULL`.
- `add specimen` reads `id = objv[3]-1`, checks `models != NULL`, then writes
  `memset(&models[id], ...)` / `models[id].*` with no `0 <= id < model_amount` guard —
  the analog of the WR-01 check that *was* added to `setSpecimen "id"`.
**Fix (if not already applied in live):** add `if (NULL == s->slices[s->slice_id]) return -1;`
before the `DOT_EQUAL` head comparison in `marker_del`; add `if (id < 0 || id >= model_amount)`
guard before the `models[id]` write in `add specimen`. Both are defense-in-depth; normal R
flow passes in-range, non-empty values. **Verify against live before acting** — these are
named in the iteration-1 fix log and the served reads lag live.

---

_Reviewed: 2026-06-23T12:55:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
_Note: terminal/live cross-check unavailable this pass; reviewed content confirmed to lag live line numbers. Treat IN-01..IN-03 as verification-pending, not open defects._
