# Milestones

## v1.1 — GUImorph UI Modernization

**Shipped:** 2026-06-29  
**Phases:** 6 (18 plans)  
**Requirements:** 18/18 validated (+ 3 constraints)  
**Tag:** `v1.1`

### Delivered

Modernized GUImorph GUI in place on Tk/ttk: themed shell, direct-manipulation controls, in-GUI feedback, guided workflow, keyboard shortcuts/undo, and Curve tab rehabilitation — without changing the C/OpenGL renderer or breaking `.dgt` round-trip.

### Key Accomplishments

1. **Themed shell** — dev menu gated, ttk-unified widgets, resizable centered window (Phase 10)
2. **Direct manipulation** — inline spinboxes/sliders, non-modal delete, responsive viewport (Phase 11)
3. **In-GUI feedback** — status bar, progress indicators, non-blocking validation (Phase 12)
4. **Guided workflow** — placement hints, tab-gating explanations, specimen jump-to (Phase 13)
5. **Keyboard shortcuts & undo** — global accelerators, single-level undo for placement/delete/drag (Phase 14)
6. **Curve tab rehabilitation** — controls re-enabled, `.dgt` round-trip, README sync (Phase 15)

### Archives

- [Roadmap](milestones/v1.1-ROADMAP.md)
- [Requirements](milestones/v1.1-REQUIREMENTS.md)

### Known Deferred Items at Close

Backlog items 999.1 (GPA plot blank) and 999.2 (openDgt specimen order) remain in ROADMAP backlog.

### Timeline

2026-06-24 → 2026-06-29 (execution); archived 2026-06-29

---

## v1.0 — GUImorph Modernization

**Shipped:** 2026-06-23  
**Phases:** 9 (28 plans)  
**Requirements:** 22/22 validated  
**Tag:** `v1.0`

### Delivered

Restored GUImorph on Windows R 4.6+ with full digitize → analyze workflow and modular C/OpenGL engine rehabilitation (Option A).

### Key Accomplishments

1. **Runtime restored** — `tkogl2.dll` builds, deploys, and loads via `load_all` on Windows R
2. **Digitize workflow** — landmarks (double-click), curves, multi-specimen `.dgt` save/reload
3. **Analysis round-trip** — landmarks-only GPA (`gpagen`) + CSV on geomorph 4.x APIs
4. **Contributor onboarding** — `BUILD.md`, `renv.lock`, `deploy-dll.ps1` (MSVC-primary)
5. **C engine rehabilitation** — five `tcl_*` modules + unified `marker.c`; god file removed
6. **Regression validated** — Phase 9 Fixtures A+B full workflow UAT passed

### Archives

- [Roadmap](milestones/v1.0-ROADMAP.md)
- [Requirements](milestones/v1.0-REQUIREMENTS.md)
- [Audit](milestones/v1.0-MILESTONE-AUDIT.md)
- [Phase artifacts](milestones/v1.0-phases/) (04–09)

### Known Deferred Items at Close

4 items acknowledged in STATE.md Deferred Items (see STATE.md)

### Timeline

2026-06-13 → 2026-06-22 (execution); archived 2026-06-23
