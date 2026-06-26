# Requirements: GUImorph UI Modernization (v1.1)

**Defined:** 2026-06-24
**Core Value:** A researcher can run the full digitize → analyze workflow in a GUI that feels modern, gives clear in-app feedback, and doesn't interrupt with modal nags — all without changing the C/OpenGL renderer or breaking `.dgt` files.
**Milestone scope:** In-place Tk/ttk UI modernization (Strategy: modernize on Tk; keep renderer). Workflow streamlining allowed where `.dgt` round-trip is preserved.

> **v1.0 archived.** Restoration + Option A C-engine rehab requirements are in [milestones/v1.0-REQUIREMENTS.md](milestones/v1.0-REQUIREMENTS.md) (22/22 validated).

## Milestone Constraint (applies to every requirement)

- **CON-01**: No renderer changes — the C/OpenGL `tkogl2.dll` and the R↔Tcl shape-string protocol stay intact. Modernization is R-side Tk/ttk only.
- **CON-02**: `.dgt` files written by v1.0 still load, and files written by v1.1 still match the v1.0 format (round-trip preserved).
- **CON-03**: Windows R 4.6+ remains the only supported runtime.

## v1.1 Requirements

### Visual Chrome & Menu Cleanup (Phase 10) — validated 2026-06-24

- [x] **UX-MENU-01**: Developer/diagnostic File-menu items removed from the end-user menu (logging commands, "Send Signal to Log File", "Execute predefined commands (DEVELOPER ONLY)", "Take Snapshot (DEVELOPER ONLY)") — gated behind a dev toggle or removed.
- [x] **UX-MENU-02**: Blank `"  "` spacer menu entries removed; menu labels use consistent casing/wording.
- [x] **UX-MENU-03**: A consistent ttk theme is applied; classic `tklabel`/`tcltk2` widgets unified to ttk where practical; window is resizable and opens centered; user-facing typos/wording fixed (e.g. "Number of Specimen", "Select Images to Digitize").

### Direct-Manipulation Controls (Phase 11)

- [x] **UX-CTL-01**: Landmark/anchor size is adjusted via a slider/spinbox, not repeated +/− 0.001 steppers.
- [x] **UX-CTL-02**: Landmark and anchor counts are set via an inline spinbox in the tab — no separate modal pop-up window.
- [x] **UX-CTL-03**: Deleting a landmark/anchor does not spawn a modal confirm window (inline action and/or undoable).
- [x] **UX-CTL-04**: The viewport + control panel resize responsively with the window instead of fixed 600×600 / 400×670 geometry.

### In-GUI Feedback & Status (Phase 12)

- [ ] **UX-FB-01**: A persistent status area in the GUI shows the current action and its result; key information currently sent only to the R console is surfaced in the GUI.
- [ ] **UX-FB-02**: Long operations (GPA Compute, PLY load) show progress/busy feedback so the UI never looks frozen.
- [ ] **UX-FB-03**: Routine validation is non-blocking — modal `tkmessageBox` flow-control gates (e.g. "Incorrect number of landmarks", "It's the last specimen", "Please open digitizing tab to switch specimen") are replaced by inline messages and disabled controls.

### Guided Workflow & Discoverability (Phase 13)

- [x] **UX-WF-01**: The placement model is discoverable in-app — an on-screen hint communicates "double-click to place, single-click selects, drag to move".
- [x] **UX-WF-02**: Disabled tabs explain why they're disabled (tooltip / step indicator), so the gating reads as intentional rather than broken.
- [x] **UX-WF-03**: Specimen navigation shows "specimen N of M" and allows jumping directly to a specimen (list/dropdown), not just Previous/Next.
- [x] **UX-WF-04**: Tab-gating / tab-specific placement rules are streamlined or unified where it reduces confusion (allowed per scope), with `.dgt` round-trip preserved (CON-02).

### Keyboard Shortcuts & Undo (Phase 14) — validated 2026-06-26

- [x] **UX-KEY-01**: Keyboard accelerators exist for common actions (load PLY, save DGT, previous/next specimen, fit).
- [x] **UX-KEY-02**: The last landmark/anchor placement, deletion, and drag-move can be undone.

### Curve Tab Rehabilitation (Phase 15)

- [ ] **UX-CRV-01**: The Curve tab's controls are re-enabled and functional (currently `setCurvesNum` / `setCurrentCurvesNum` / `Compute Curves` are commented out, leaving only "Fit").
- [ ] **UX-CRV-02**: Curve definition round-trips through `.dgt`, and the README/in-app text matches the actual controls.

## Out of Scope (this milestone)

| Feature | Reason |
|---------|--------|
| rgl renderer swap (Option B) | Strategy is modernize-on-Tk; keep the C/OpenGL renderer |
| Shiny/Qt/web UI rebuild (Option C) | Out of scope — would require replacing the renderer |
| New analysis features / geomorph parity | UI milestone, not analysis |
| GPA plot blank fix (backlog 999.1) | Renderer/rgl issue, tracked separately in ROADMAP backlog |
| openDgt first-specimen order (backlog 999.2) | Tracked separately in ROADMAP backlog |
| Tcl/Tk 9.0 migration | Stay on 8.6 stubs |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| UX-MENU-01 | Phase 10 | Validated 2026-06-24 |
| UX-MENU-02 | Phase 10 | Validated 2026-06-24 |
| UX-MENU-03 | Phase 10 | Validated 2026-06-24 |
| UX-CTL-01 | Phase 11 | Implemented 2026-06-24 |
| UX-CTL-02 | Phase 11 | Implemented 2026-06-24 |
| UX-CTL-03 | Phase 11 | Implemented 2026-06-24 |
| UX-CTL-04 | Phase 11 | Implemented 2026-06-24 |
| UX-FB-01 | Phase 12 | Pending |
| UX-FB-02 | Phase 12 | Pending |
| UX-FB-03 | Phase 12 | Pending |
| UX-WF-01 | Phase 13 | Complete |
| UX-WF-02 | Phase 13 | Complete |
| UX-WF-03 | Phase 13 | Complete |
| UX-WF-04 | Phase 13 | Complete |
| UX-KEY-01 | Phase 14 | Validated 2026-06-26 |
| UX-KEY-02 | Phase 14 | Validated 2026-06-26 |
| UX-CRV-01 | Phase 15 | Pending |
| UX-CRV-02 | Phase 15 | Pending |

**Coverage:**

- v1.1 requirements: 18 (+ 3 cross-cutting constraints)
- Mapped to phases: 18
- Unmapped: 0

---
*Last updated: 2026-06-26 — UX-KEY-01/02 validated (Phase 14 UAT complete)*
