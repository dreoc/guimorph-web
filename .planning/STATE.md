---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: UI Modernization
status: Ready to execute
stopped_at: Phase 12 context gathered
last_updated: "2026-06-25T22:11:31.776Z"
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 7
  completed_plans: 6
  percent: 50
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-24)

**Core value:** A researcher runs the full digitize → analyze workflow in a GUI that feels modern, gives clear in-app feedback, and doesn't interrupt with modal nags — without changing the C/OpenGL renderer or breaking `.dgt` files.
**Current focus:** v1.1 Phase 11 complete (all 4 plans shipped); ready for Phase 12 — In-GUI Feedback & Status.

## Current Position

Milestone: **v1.1 UI Modernization** — executing  
Phases: 2/6 complete (10, 11 shipped 2026-06-24)  
Requirements: 7/18 validated (+ 3 constraints)  
Previous: **v1.0 ARCHIVED** (2026-06-23) — 9/9 phases, 22/22 reqs, tag `v1.0`

Progress: [█████░░░░░] 50%

## Performance Metrics

**Velocity:**

- Total plans completed: 28 (v1.0)
- Timeline: 2026-06-13 → 2026-06-22 (execution)

## Accumulated Context

### Decisions

- MSVC `tkogl2.dll` deployed to `inst/libs/x64/` — export verified, Windows R load and mesh render confirmed
- Startup OOB on empty `activeDataList` fixed — guards in `onPlaceAnchor`, `onNext`, `switchTab`, `updateWidgets.*` (2026-06-15)
- **Landmark placement requires double-click** on canvas (`addDot` via `<Double-Button-1>`); single-click triggers pick/select — not a display bug (2026-06-15)
- **MSVC is the supported Windows build toolchain** for `tkogl2.dll` (`build-msvc/Release/`); see `BUILD.md`
- Debounced 150ms `<Configure>` handler with `e$glBound` gate re-pushes live GL viewport size via existing `set("window","size")` protocol (2026-06-24)
- **ttkscale size sliders (0.001–0.050, 0.001 grain)** replace +/- steppers on Digitize and Anchor tabs; `onLmSizeSlide` reads linked `tclVar`, quantizes, calls `set("dot",attr,v)`, persists `[[2]]` (2026-06-24)
- **ttkspinbox count controls (1–100, placed-count floor)** replace modal setLandmarkNum/setAnchorNum on Digitize and Anchor tabs; clamp on Return/FocusOut (2026-06-24)
- **Immediate right-click delete** via inline `del()` + `updateDotNum`/`updateAnchorNum`; `popUpRemoveWindow` and `digRemove*` handlers removed (2026-06-24)

### Blockers/Concerns

- 26 warnings on `load_all` — not yet captured (`warnings()`)
- Per-specimen curve bind on specimen switch — future work
- PLY vertex coloration for geometry-only scans — deferred

### Deferred Items

Items acknowledged at milestone close on 2026-06-23:

| Category | Item | Status |
|----------|------|--------|
| debug | 07-01-dispatch-extraction | diagnosed — resolved with MSVC build; archived in milestones/v1.0-phases/ |
| backlog | 999.1 GPA plot blank | deferred |
| backlog | 999.2 openDgt wrong specimen first | deferred |
| process | per-phase VERIFICATION.md missing | deferred |

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 250623-001 | Milestone v1.0 audit tech-debt cleanup | 2026-06-23 | b926ee1 | [250623-001-milestone-tech-debt](./quick/250623-001-milestone-tech-debt/) |
| 260623-l8r | Plug-and-play R package distribution assessment | 2026-06-23 | d5ff92c | [260623-l8r-assess](./quick/260623-l8r-assess/) |

### v1.1 UI Pain Points (source for milestone scope, 2026-06-24)

Identified from GUI source + README "Known quirks":

- Modal pop-ups for trivial input (`setLandmarkNum`/`setAnchorNum` spawn windows; delete confirm window) → Phase 11
- Blocking `tkmessageBox` used as flow control on nav/tab-switch → Phase 12 (UX-FB-03)
- Confusing tab-gating; "Place Anchors" silently changes which tabs unlock → Phase 13
- Double-click-place vs single-click-select invisible to users → Phase 13 (UX-WF-01)
- No status/progress in GUI — state goes to console `print()` only → Phase 12
- Developer-only File-menu items + blank `"  "` spacers exposed to users → Phase 10
- Curve tab half-dead: real buttons commented out (`## tkpack`), only "Fit" shows → Phase 15
- +/− 0.001 size steppers; fixed non-resizable 1400×1200 / 600×600 / 400×670 layout; mixed tk/ttk/tcltk2 widgets; typos ("Number of Specimen", "Select Images to Digitize") → Phases 10–11
- No keyboard shortcuts or undo → Phase 14

## Session Continuity

Last session: 2026-06-25
Stopped at: Phase 12 context gathered
Resume file: .planning/phases/12-in-gui-feedback-status/12-CONTEXT.md
