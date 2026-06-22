---
phase: 08-c-engine-deduplication
plan: 02
subsystem: c-engine
tags: [c, marker, tkogl2, deduplication, msvc, wrappers]

requires:
  - phase: 08-c-engine-deduplication
    plan: 01
    provides: marker.h contract + pre-phase8 DLL backup
provides:
  - marker.c unified marker_* core + g_landmarks/g_anchors instances
  - all dot_*/anchor_* thin wrappers (zero dispatch changes)
  - CMakeLists.txt builds marker.c instead of dot_ZARF_9.c
affects: [08-03-deploy-uat]

tech-stack:
  added: []
  patterns:
    - "marker_* core takes marker_set_t*; dot/anchor wrappers forward &g_landmarks / &g_anchors"
    - "D-03 anchor bugs fixed by per-set selection state in unified core"
    - "Accessor return contracts preserved per-wrapper (dot_size -1 vs getListLength 0)"

key-files:
  created:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c
  modified:
    - integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt
  deleted:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c

key-decisions:
  - "marker_add stamps node->type from s->node_type (LANDMARK/ANCHOR) not per-call arg"
  - "marker_del_selected NULL-guards s->selected before deref (D-03 BUG-4)"
  - "marker_select uses 0-based id++-after-match; in-loop IS_IN_RANGE logs trimmed (D-05)"
  - "def_ZARF_9.h left unchanged — existing dot_*/anchor_* prototypes satisfied by wrappers"
  - "anchors_selected_id returns raw 0-based value; +1 shift deferred to 08-03 UAT (A1)"

patterns-established:
  - "God-file deletion pattern: marker.c replaces dot_ZARF_9.c in CMake (mirrors Phase 7 tcl_if removal)"
  - "Landmark wrappers preserve exact empty/error return contracts via separate marker_* accessors"

requirements-completed: [CENG-02]

duration: 45min
completed: 2026-06-22
---

# Phase 08 Plan 02: Unified marker.c Implementation Summary

**Unified marker_* core with g_landmarks/g_anchors replaces dot_ZARF_9.c; MSVC Release build links cleanly with all ~50 dispatch wrappers intact.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-22T15:30:00Z
- **Completed:** 2026-06-22T16:15:00Z
- **Tasks:** 3/3 complete
- **Files modified:** 3 (1 created, 1 modified, 1 deleted)

## Accomplishments

- Created `marker.c` (647 lines) with `marker_set_t g_landmarks` / `g_anchors`, full `marker_*` core, and all `dot_*`/`anchor_*`/`get_*`/`*Get*`/`*Set*` wrappers
- D-03 anchor asymmetry fixed by construction: anchor wrappers route `&g_anchors` through shared core with per-set `selected`/`selected_id`
- D-04 landmark behavior preserved via canonical dot bodies; D-05 in-loop select logging trimmed
- CMakeLists.txt swaps `dot_ZARF_9.c` → `marker.c`; `dot_ZARF_9.c` deleted
- MSVC Release build succeeded (`marker.c` compiled; `build-msvc/Release/tkogl2.dll` produced, 312832 bytes)

## Task Commits

| Task | Name | Commit | Status |
|------|------|--------|--------|
| 1 | marker.c skeleton + marker_* core | `49a34c9` | Done |
| 2 | dot/anchor wrappers + def_ZARF_9.h reconcile | `a3a6a0c` | Done |
| 3 | CMake swap, delete dot_ZARF_9.c, MSVC build | `4a24ba7` | Done |

## Files Created/Modified

- `integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c` — unified core + wrappers; `dotVersionPtr` preserved for `tcl_log.c`
- `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt` — `${SRC}/marker.c` in source list
- `integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c` — **deleted** (content absorbed)

## Decisions Made

- `def_ZARF_9.h` required no edits: `dot_t` layout and existing prototypes unchanged (D-08); cross-module `marker_*` API remains in `marker.h`
- `tcl_dispatch.c`, `ogl_model_ply_ZARF_9.c`, `curve_ZARF_9.c` untouched (D-01)
- `anchors_selected_id()` returns raw 0-based core value; potential +1 display shift flagged for 08-03 anchor UAT

## Deviations from Plan

None — plan executed as written.

## Issues Encountered

- Shell output intermittently unavailable from executor host; WSL shell subagent used for git commits and MSVC build
- `dumpbin /exports` on WSL UNC path did not grep `Tkogl2_Init`; build log confirms clean link and `Tkogl2_Init` remains declared in `tcl_init.c` with `DLLEXPORT`

## User Setup Required

None — MSVC toolchain already confirmed in 08-01.

## Next Phase Readiness

- **08-03** unblocked: deploy `build-msvc/Release/tkogl2.dll` to `inst/libs/x64/`, run landmark + anchor GUI UAT (D-10/D-11)
- Anchor behavior change (D-03) requires mandatory anchor place/select/move/delete exercise before marking phase complete

## Self-Check: PASSED

- FOUND: `integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c`
- MISSING: `integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c` (intentionally deleted)
- FOUND: CMakeLists.txt lists `marker.c`, not `dot_ZARF_9.c`
- FOUND: commits `49a34c9`, `a3a6a0c`, `4a24ba7`
- FOUND: MSVC Release build exit 0; `tkogl2.dll` at `build-msvc/Release/tkogl2.dll`

---
*Phase: 08-c-engine-deduplication*
*Completed: 2026-06-22*
