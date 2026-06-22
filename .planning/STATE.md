---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: All UAT passed — landmarks, anchors, .dgt round-trip with anchor
stopped_at: Completed 08-02-PLAN.md
last_updated: "2026-06-22T20:13:20.516Z"
last_activity: 2026-06-22
progress:
  total_phases: 11
  completed_phases: 5
  total_plans: 14
  completed_plans: 14
  percent: 45
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-15)

**Core value:** Researcher can digitize a 3D specimen in the GUI, run `geomorph` analysis end-to-end, and maintain a modular C engine on Windows R.
**Current focus:** Phase 08 — c-engine-deduplication

## Current Position

Phase: 9
Plan: Not started
Status: All UAT passed — landmarks, anchors, .dgt round-trip with anchor
Last activity: 2026-06-22

Progress: [████████░░] 89%

## Performance Metrics

**Velocity:**

- Total plans completed: 19
- Average duration: —
- Total execution time: —
- 08-c-engine-deduplication / 02: 45min (3 tasks, 3 files)

## Accumulated Context

### Decisions

- MinGW `build/tkogl2.dll` deployed to `inst/libs/x64/` — export verified, Windows R load confirmed (2026-06-15)
- Startup OOB on empty `activeDataList` fixed — guards in `onPlaceAnchor`, `onNext`, `switchTab`, `updateWidgets.*` (2026-06-15)
- **Landmark placement requires double-click** on canvas (`addDot` via `<Double-Button-1>`); single-click triggers pick/select (`set dot selected`) — not a display bug (2026-06-15)
- WSL UNC paths work for package load and PLY file access
- Legacy 2020 DLL backed up before MinGW swap (`tkogl2.dll.pre-phase7.bak`)
- **Curve slot `[[4]]` must be matrix** for `rbind`/`openDgt` — `list()` init was a blocker (04-02)
- **`openDgt` Surface=0** is valid; reload path fixed (`printf`, vacuous NA, `queryFromR`/`e` scope) (04-03)
- **MSVC is the supported Windows build toolchain** for `tkogl2.dll`; MinGW builds render incorrectly (2026-06-21)
- **PLY all-zero vertex colors** use lighting fallback; true scan coloration deferred (2026-06-21)
- **Canvas HWND realization** required before WGL bind — `tcl("update","idletasks")` in `ui.main` (2026-06-21)
- **Phase 7 modularization:** five `tcl_*` modules replace god file; `tcl_if_ZARF_9.c` deleted from build (2026-06-21)
- **Phase 8 marker unification:** `marker.c` replaces `dot_ZARF_9.c`; anchor wrappers route `&g_anchors` (D-03); `marker_del_selected` NULL guard (2026-06-22)
- **def_ZARF_9.h unchanged** — existing `dot_*`/`anchor_*` prototypes satisfied by wrappers in `marker.c` (2026-06-22)

### Blockers/Concerns

- 26 warnings on `load_all` — not yet captured (`warnings()`)
- Per-specimen curve bind / C curve state on specimen switch — future work (Phase 8+)
- PLY vertex coloration for geometry-only scans (all-zero RGB) — deferred; lighting fallback in place

## Session Continuity

Last session: 2026-06-22
Stopped at: Completed 08-02-PLAN.md
Resume file: None — proceed with 08-03 deploy + UAT
