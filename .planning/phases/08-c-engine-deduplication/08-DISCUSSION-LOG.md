# Phase 8: C Engine Deduplication - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-21
**Phase:** 08-c-engine-deduplication
**Areas discussed:** Unification structure, Behavior preservation vs fix, Module layout, Anchor verification

---

## Unification structure

### Core shape

| Option | Description | Selected |
|--------|-------------|----------|
| Shared core + thin wrappers | One `marker_*(marker_set_t* set, ...)` family; `dot_*`/`anchor_*` become one-line wrappers; `tcl_dispatch.c` untouched | ✓ |
| Unified API + rewrite dispatch | Replace `dot_*`/`anchor_*` entirely with `marker_*`; update every dispatch call site | |
| Single function + type-discriminator arg | One `marker_add/select/...` branching internally on `dot_t.type` | |

### State model

| Option | Description | Selected |
|--------|-------------|----------|
| `marker_set_t` struct | Bundle array, slice_id, slice_amount, selected, selected_id; two static instances | ✓ |
| Keep existing separate globals | Leave parallel statics; shared functions take pointers to them | |

**User's choice:** Shared core + thin wrappers; group state into a `marker_set_t` struct.
**Notes:** Lowest-regression path — dispatch stays stable. Grouping only; array-ifying the numbered globals remains Phase 9.

---

## Behavior preservation vs fix

### Anchor asymmetry

| Option | Description | Selected |
|--------|-------------|----------|
| Fix asymmetry | Anchors use their own selection state + full bounds checks (technically a behavior change, but anchors are broken today) | ✓ |
| Preserve bug-for-bug | Keep current observable behavior exactly (anchors keep mutating dot selection) | |
| Fix only where it can't regress landmarks | Keep landmark behavior identical; fix anchors only if a workflow needs it | |

### Logging level of shared core

| Option | Description | Selected |
|--------|-------------|----------|
| Keep verbose logging | Shared core keeps existing dot-style per-coordinate logging | |
| Trim noisy per-coordinate logs | Reduce in-loop select logging while unifying | ✓ |

**User's choice:** Fix the anchor asymmetry; trim the noisy in-loop select logging.
**Notes:** Logging trim scoped to the per-coordinate select logging that collapses when the two bodies merge — broader debug-cruft removal (`MAKE_INERT`, `if(0)`, pervasive `printf`) stays Phase 9. Landmark behavior must remain identical.

---

## Module layout

### File location

| Option | Description | Selected |
|--------|-------------|----------|
| New `marker.c` / `marker.h` | Matches ROADMAP hint; clean module consistent with Phase 7 `tcl_*` naming | ✓ |
| Consolidate in place | Keep `dot_ZARF_9.c`; collapse duplicate bodies within it | |

### Wrappers home

| Option | Description | Selected |
|--------|-------------|----------|
| Absorb wrappers into `marker.c`; delete `dot_ZARF_9.c` | One file owns markers end-to-end (Phase 7 god-file precedent) | ✓ |
| Keep `dot_ZARF_9.c` for wrappers | `marker.c` has core; old file keeps wrapper shims | |
| You decide during planning | Planner picks based on include/linker fallout | |

**User's choice:** New `marker.c`/`marker.h`; absorb wrappers; delete `dot_ZARF_9.c`.
**Notes:** `dot_t`/type enum stay in `def_ZARF_9.h`; CMake updated incrementally as in Phase 7.

---

## Anchor verification

### Anchor UAT

| Option | Description | Selected |
|--------|-------------|----------|
| Place + select + move + delete an anchor | Exercises the exact functions changed by the asymmetry fix | ✓ |
| Place anchor only | Lighter; confirms placement renders but not select/move | |
| Figure out anchor workflow first | Unsure how to place anchors in the GUI | |

### `.dgt` baseline

| Option | Description | Selected |
|--------|-------------|----------|
| Full Phase 4 round-trip | Reuse `test_fresh.dgt`: PLY → landmarks + curve → save → reload | |
| Round-trip + verify anchors persist | Also add an anchor before save and confirm reload (if anchors are written to `.dgt`) | ✓ |
| Reload existing baseline `.dgt` only | Just confirm an existing `.dgt` reloads | |

**User's choice:** Anchor place/select/move/delete UAT; round-trip plus anchor-persistence check.
**Notes:** Anchor-persistence check is conditional on `.dgt` actually serializing anchors — flagged as an open question for research/planning. If not serialized, rely on in-session anchor UAT.

---

## Claude's Discretion

- Exact `marker_set_t` field/instance names.
- Split of declarations between `marker.h` and `def_ZARF_9.h`.
- Consolidation of near-duplicate accessor variants (subject to wrappers preserving every dispatch-referenced name).
- Plan splitting across 08-01 / 08-02 / 08-03.

## Deferred Ideas

- Numbered globals → arrays (Phase 9 / CENG-03).
- Broad debug-cruft removal (Phase 9 / CENG-04).
- Aggressive `static` linkage tightening / dead-code removal (Phase 9 / post-rehab).
- Curve deduplication / per-specimen curve bind (separate future work).
