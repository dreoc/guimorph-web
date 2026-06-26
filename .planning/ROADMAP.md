# Roadmap: GUImorph Modernization

## Milestones

- ✅ **v1.0 Modernization** — Phases 1–9 ([archive](milestones/v1.0-ROADMAP.md)) — shipped 2026-06-23
- 🟡 **v1.1 UI Modernization** — Phases 10–15 — in planning (defined 2026-06-24)

## Phases

<details>
<summary>✅ v1.0 Modernization (Phases 1–9) — SHIPPED 2026-06-23</summary>

- [x] Phase 1: Native Runtime Validation (3/3) — 2026-06-15
- [x] Phase 2: Package Load & GUI Launch (3/3) — 2026-06-15
- [x] Phase 3: 3D Viewer Smoke Test (3/3) — 2026-06-15
- [x] Phase 4: Digitize Workflow (3/3) — 2026-06-15
- [x] Phase 5: Analysis Round-Trip (3/3) — 2026-06-19
- [x] Phase 6: Reproducible Dev Environment (3/3) — 2026-06-19
- [x] Phase 7: C Engine Modularization (3/3) — 2026-06-21
- [x] Phase 8: C Engine Deduplication (3/3) — 2026-06-22
- [x] Phase 9: C Engine Cleanup & Validation (4/4) — 2026-06-22

Full phase details: [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)

</details>

### 🟡 v1.1 UI Modernization (Phases 10–15)

> Strategy: modernize in place on Tk/ttk; the C/OpenGL renderer and `.dgt` format are unchanged (CON-01/02/03). Order runs low-risk visual foundation first → controls → feedback → guidance → shortcuts → the more isolated Curve functional work last.

#### Phase 10: Visual Chrome & Menu Cleanup

**Goal:** A clean, themed, end-user-appropriate shell — no developer/diagnostic clutter, consistent widgets, resizable centered window, corrected wording.
**Requirements:** UX-MENU-01, UX-MENU-02, UX-MENU-03
**Why first:** Lowest-risk, high visual payoff, and establishes the theming/layout foundation later phases build on. No logic changes.
**Plans:** 3 (planned 2026-06-24) — [10-01](phases/10-visual-chrome-menu-cleanup/10-01-PLAN.md) File menu cleanup · [10-02](phases/10-visual-chrome-menu-cleanup/10-02-PLAN.md) Themed/resizable/centered shell · [10-03](phases/10-visual-chrome-menu-cleanup/10-03-PLAN.md) Widget unification + wording + smoke UAT

#### Phase 11: Direct-Manipulation Controls

**Goal:** Replace modal/stepper interactions with inline controls — spinbox counts, size slider, non-modal delete, responsive viewport + panel.
**Requirements:** UX-CTL-01, UX-CTL-02, UX-CTL-03, UX-CTL-04
**Depends on:** Phase 10 (layout/theme foundation).
**Plans:** 4 (planned 2026-06-24)

- [x] [11-01](phases/11-direct-manipulation-controls/11-01-PLAN.md) — Live size slider on Digitize + Anchor tabs (UX-CTL-01)
- [x] [11-02](phases/11-direct-manipulation-controls/11-02-PLAN.md) — Inline count spinbox with placed-count floor (UX-CTL-02)
- [x] [11-03](phases/11-direct-manipulation-controls/11-03-PLAN.md) — Non-modal immediate right-click delete (UX-CTL-03)
- [x] [11-04](phases/11-direct-manipulation-controls/11-04-PLAN.md) — Responsive viewport + panel resize, debounced (UX-CTL-04)

#### Phase 12: In-GUI Feedback & Status

**Goal:** A status bar + progress feedback; route key console output to the GUI; make validation non-blocking instead of modal nags.
**Requirements:** UX-FB-01, UX-FB-02, UX-FB-03
**Depends on:** Phase 10 (shell has a place for the status area).**Plans:** 4 plans in 3 waves (planned 2026-06-25)

- [ ] [12-01](phases/12-in-gui-feedback-status/12-01-PLAN.md) — Status API helpers + status bar widgets + env-storage gaps (wave 1) (UX-FB-01/02/03)
- [ ] [12-02](phases/12-in-gui-feedback-status/12-02-PLAN.md) — Nav-gate modal→inline conversion + proactive disable + showPicture parity (wave 2) (UX-FB-03/01)
- [ ] [12-03](phases/12-in-gui-feedback-status/12-03-PLAN.md) — Compute-gate inline conversion + GPA busy feedback (wave 2) (UX-FB-03/02/01)
- [ ] [12-04](phases/12-in-gui-feedback-status/12-04-PLAN.md) — PLY load determinate progress + load failure status (wave 3) (UX-FB-02/01)

#### Phase 13: Guided Workflow & Discoverability

**Goal:** Make the digitize order and placement model obvious — placement hints, transparent/streamlined tab-gating, "specimen N of M" with jump-to.
**Requirements:** UX-WF-01, UX-WF-02, UX-WF-03, UX-WF-04
**Depends on:** Phase 12 (uses the status/feedback surface).
**Plans:** 1/2 plans executed

#### Phase 14: Keyboard Shortcuts & Undo

**Goal:** Accelerators for common actions and an undo for landmark/anchor placement & deletion.
**Requirements:** UX-KEY-01, UX-KEY-02
**Depends on:** Phase 11 (delete/placement paths settled before adding undo).
**Plans:** TBD via `/gsd-plan-phase 14`

#### Phase 15: Curve Tab Rehabilitation

**Goal:** Re-enable the commented-out Curve controls, make curve definition round-trip through `.dgt`, and reconcile UI with the README.
**Requirements:** UX-CRV-01, UX-CRV-02
**Why last:** Most isolated functional work and the only phase touching curve behavior; benefits from the modernized control patterns from Phases 11–14.
**Plans:** TBD via `/gsd-plan-phase 15`

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 1–9 | v1.0 | 28/28 | Shipped | 2026-06-23 |
| 10 | v1.1 | 3/3 | Shipped | 2026-06-24 |
| 11 | v1.1 | 4/4 | Shipped | 2026-06-24 |
| 12 | v1.1 | 0/4 | Planned | — |
| 13 | v1.1 | 1/2 | In Progress|  |
| 14 | v1.1 | 0 | Not started | — |
| 15 | v1.1 | 0 | Not started | — |

## Backlog

Parking-lot items (999.x) — not sequenced; promote with `/gsd-review-backlog` when ready.

### Phase 999.1: GPA plot window opens but nothing rendered (BACKLOG)

**Goal:** Fix Plot Aligned Specimens so aligned landmark geometry is visible after Compute.
**Source:** Phase 5 UAT (2026-06-19) — rgl window opens; canvas appears empty.
**Context:** `plotspecs()` → `geomorph::plotAllSpecimens` on 3×3×2 gpagen `$coords`; Compute + Save CSV work. Suspect rgl/Tk event-loop interaction, plot_param sizing, or geomorph 4.x 3D backend on Windows R 4.6.
**Requirements:** TBD
**Plans:** 0 plans

Plans:

- [ ] TBD (promote with `/gsd-review-backlog` when ready)

### Phase 999.2: openDgt shows second specimen first on load (BACKLOG)

**Goal:** After Load DGT File, GUI should display specimen 1 without Next→Previous workaround.
**Source:** Phase 5 UAT (2026-06-19) — multi-specimen `test_fresh.dgt`; `currImgId` is 1 but viewer shows specimen 2 until user navigates Next then Previous.
**Context:** `drawElements` loads all specimens sequentially; C display ends on last loaded. Attempted fix (`showPicture(e)` after openDgt) did not resolve in user retest.
**Requirements:** TBD
**Plans:** 0 plans

Plans:

- [ ] TBD (promote with `/gsd-review-backlog` when ready)

---
*Roadmap created: 2026-06-13*  
*v1.0 archived: 2026-06-23*  
*v1.1 UI Modernization defined: 2026-06-24 — start execution with `/gsd-plan-phase 10`*
