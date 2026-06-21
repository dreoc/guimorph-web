# Phase 7: C Engine Modularization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-19
**Phase:** 7-c-engine-modularization
**Areas discussed:** Module boundaries, Regression depth, Extraction order, Naming & headers

---

## Module Boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| With window module | drawDots/drawAnchors/drawCurves in `tcl_window.c` | |
| With dispatch module | Draw functions with Tcl handlers in `tcl_dispatch.c` | ✓ |
| Leave in god file | Only extract ROADMAP slices; drawing deferred | |

**User's choice:** Draw functions → `tcl_dispatch.c`

| Option | Description | Selected |
|--------|-------------|----------|
| With dispatch | Logging tied to Tcl command tracing | |
| With state | Logs landmark/anchor snapshots | |
| Separate `tcl_log.c` | Dedicated logging file | ✓ (user correction) |
| Leave in god file | Defer to Phase 9 | |

**User's choice:** Logging → `tcl_log.c` (separate from state; user corrected mid-discussion)

| Option | Description | Selected |
|--------|-------------|----------|
| All in `tcl_state.c` | init, reset, globals together | ✓ |
| Split init/reset | resetContext with window module | |
| Partial state move | Only pointer globals | |

**User's choice:** State/globals → `tcl_state.c`

| Option | Description | Selected |
|--------|-------------|----------|
| Thin shim | `Tkogl2_Init` stays in god file | |
| Init in dispatch | Move registration to `tcl_dispatch.c` | |
| Rename to `tcl_init.c` | Entry point only; drop `_ZARF_9` from init file | ✓ |

**User's choice:** Rename god file to `tcl_init.c`

---

## Regression Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Build + export only | cmake + Tkogl2_Init check per plan | |
| GUI + PLY load | ROADMAP minimum | |
| GUI + PLY + landmark | Double-click landmark after each plan | ✓ |

**User's choice:** Per-step landmark placement smoke

| Option | Description | Selected |
|--------|-------------|----------|
| Landmark only (final) | Same as per-step | |
| Full digitize round-trip | Landmarks + curve + `.dgt` save/reload | ✓ |
| PLY only (final) | Lighter final check | |

**User's choice:** Final 07-03 verification = full digitize round-trip

| Option | Description | Selected |
|--------|-------------|----------|
| smoke-test-findings only | Phase 4–5 pattern | |
| SUMMARY only | Plan summaries | |
| Both | smoke-test-findings + SUMMARY | ✓ |

**User's choice:** Document in both

| Option | Description | Selected |
|--------|-------------|----------|
| Functional only | Same behavior, no diff | |
| Pre-Phase-7 DLL backup | Side-by-side if regression suspected | ✓ |
| Git tag at Phase 6 | Tag baseline commit | |

**User's choice:** Keep pre-Phase-7 DLL backup

---

## Extraction Order

| Option | Description | Selected |
|--------|-------------|----------|
| ROADMAP order | dispatch → window → state | ✓ |
| Window first | WGL isolation first | |
| State first | Globals before handlers | |

**User's choice:** ROADMAP sequence (07-01 dispatch, 07-02 window, 07-03 state)

| Option | Description | Selected |
|--------|-------------|----------|
| Log + init in 07-03 | Bundle with state extraction | ✓ |
| Log in 07-01 | With dispatch handlers | |
| Init rename in 07-01 | Thin entry before handlers move | |

**User's choice:** `tcl_log.c` + `tcl_init.c` rename in 07-03

| Option | Description | Selected |
|--------|-------------|----------|
| CMake each plan | Add sources incrementally | ✓ |
| Single CMake in 07-03 | All at once | |
| Keep god file compiling until end | Dual compile | |

**User's choice:** Update CMakeLists.txt each plan

| Option | Description | Selected |
|--------|-------------|----------|
| God file only | No other `.c` changes | |
| Includes only | Headers/includes in other modules OK | ✓ |
| Minor fixes allowed | Broken includes only | |

**User's choice:** God file + header includes only

---

## Naming & Headers

| Option | Description | Selected |
|--------|-------------|----------|
| Clean names | `tcl_dispatch.c` etc. | ✓ |
| Mixed | New clean; old `_ZARF_9` unchanged | |
| Match existing | `tcl_dispatch_ZARF_9.c` | |

**User's choice:** Clean names for new modules

| Option | Description | Selected |
|--------|-------------|----------|
| Per-module headers | `tcl_dispatch.h`, etc. + `def_ZARF_9.h` for types | ✓ |
| Single `tcl_engine.h` | One shared header | |
| Extend `def_ZARF_9.h` only | No new headers | |

**User's choice:** Per-module headers

| Option | Description | Selected |
|--------|-------------|----------|
| static where possible | Tighten visibility | |
| Minimal change | Preserve current linkage | ✓ |
| Explicit extern | All cross-module in headers | |

**User's choice:** Minimal linkage changes during Phase 7

| Option | Description | Selected |
|--------|-------------|----------|
| BUILD.md each plan | Incremental layout docs | ✓ |
| 07-03 SUMMARY only | Single update | |
| Defer to Phase 9 | ROADMAP 09-03 | |

**User's choice:** Update BUILD.md each plan

---

## Claude's Discretion

- Exact line ranges and move order within each extraction plan
- Header contents granularity (which symbols in module `.h` vs `def_ZARF_9.h`)
- Whether wrapper helpers (`Wrapper_GetIntFromObj`, `tclCmdStep`) split with dispatch or move in 07-03

## Deferred Ideas

- Dot/anchor unification → Phase 8
- GBL_PTR array replacement → Phase 9
- Debug cruft removal → Phase 9
- Rename existing `_ZARF_9` source files → out of scope
- Automated C unit test harness → manual GUI UAT remains primary
