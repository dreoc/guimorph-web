# Phase 9: C Engine Cleanup & Validation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-22
**Phase:** 09-c-engine-cleanup-validation
**Areas discussed:** Globals → arrays, Debug-cruft removal, Regression validation, Build docs

---

## Globals → Arrays (CENG-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed-capacity static arrays | Sized to today's hard limits; cap as a named `#define` documented in the header. Lowest risk, behavior-preserving, matches success criterion. | ✓ |
| Dynamic growable allocation | malloc/realloc — removes hard limits but adds allocation/failure paths and regression risk. | |
| Pure rename | Collapse names into an array but keep exact current count/indexing; no capacity rethink. | |

**User's choice:** Fixed-capacity static arrays with documented `#define` limits.
**Notes:** Must respect the frozen `def_ZARF_9.h` layout (Phase 8 D-08); conversions localized per owning module using the Phase 7 definition/extern convention.

---

## Debug-Cruft Removal (CENG-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Balanced | Remove pure tracing `printf`; port load-bearing output via `tcl_log.c`; delete `MAKE_INERT` + `if(0)` dead code outright. | ✓ |
| Aggressive | Delete ALL `printf` and ALL `MAKE_INERT`/`if(0)` blocks, no logging facility retained. | |
| Conservative | Route tracing through `tcl_log.c` behind a compile-time debug flag (keep re-enable ability); delete only clearly-dead `MAKE_INERT`. | |

**User's choice:** Balanced.
**Notes:** Caution flagged on `printf` tied to the `openDgt` reload fix — verify before removing. No retained compile-time debug toggle; `tcl_log.c` is the single surviving diagnostic channel.

---

## Regression Validation (CENG-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Full round-trip | load PLY → digitize LM+curves+anchors → save `.dgt` → reload → GPA, on both `test_fresh.dgt` and the Phase 8 anchors+curves fixture; manual MSVC UAT logged to smoke-test-findings.md. | ✓ |
| Digitize-only | Digitize round-trip without GPA — lighter, skips the analysis path. | |
| Full + diff | Full round-trip plus a documented before/after DLL output comparison. | |

**User's choice:** Full round-trip including the GPA analysis step.
**Notes:** Success criterion explicitly names "analyze," so GPA is required. Two `.dgt` fixtures cover both digitize and Phase 8 dedup paths. Pass/fail judged by manual visual + functional confirmation.

---

## Build Docs (09-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Full refresh | Update BUILD.md with final module-layout table; prune obsolete god-file/`.vcxproj` references; keep MSVC-only instructions. | ✓ |
| Minimal | Just refresh the file list; leave references as-is. | |
| You decide | Use judgment on doc scope. | |

**User's choice:** Full refresh.
**Notes:** Final layout = `tcl_dispatch/window/state/log/init` + `marker.c` + `curve_ZARF_9.c` + `ogl_*`; god file (`tcl_if_ZARF_9.c`) already removed in Phase 7.

---

## Claude's Discretion

- Work ordering within the phase (recommended: globals → debug removal → validation last).
- Exact array capacity values (derive from current numbered-global counts during research).
- Per-`printf` disposition (tracing → delete; error/load-bearing → route through `tcl_log.c`).

## Deferred Ideas

- Dynamic/growable global storage (removing hard limits) — revisit only if a real capacity ceiling is hit.
- Automated smoke-test harness (QA-01, v2) — manual UAT remains primary.
- Capturing the 26 `load_all` warnings — tracked separately.
- Per-specimen curve bind / C curve state on specimen switch — future work.
- PLY vertex coloration for geometry-only scans — deferred (lighting fallback in place).
