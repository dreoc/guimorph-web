---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: ready_to_execute
stopped_at: Phase 7 complete
last_updated: "2026-06-21"
last_activity: 2026-06-21 — Phase 7 complete; CENG-01 validated; digitize round-trip smoke passed
progress:
  total_phases: 9
  completed_phases: 7
  total_plans: 14
  completed_plans: 14
  percent: 78
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-15)

**Core value:** Researcher can digitize a 3D specimen in the GUI, run `geomorph` analysis end-to-end, and maintain a modular C engine on Windows R.
**Current focus:** Phase 08 — c-engine-deduplication

## Current Position

Phase: 07 (c-engine-modularization) — **COMPLETE**
Plan: All 3 plans done (07-01, 07-02, 07-03)
Status: CENG-01 validated — five-module layout; no regression vs Phase 4 baseline
Last activity: 2026-06-21 — final digitize round-trip smoke passed

Progress: [███████░░░] ~78%

## Performance Metrics

**Velocity:**

- Total plans completed: 14
- Average duration: —
- Total execution time: —

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

### Blockers/Concerns

- 26 warnings on `load_all` — not yet captured (`warnings()`)
- Per-specimen curve bind / C curve state on specimen switch — future work (Phase 8+)
- PLY vertex coloration for geometry-only scans (all-zero RGB) — deferred; lighting fallback in place

## Session Continuity

Last session: 2026-06-21
Stopped at: Phase 7 complete
Resume file: `.planning/ROADMAP.md` — Phase 8 (CENG-02)
