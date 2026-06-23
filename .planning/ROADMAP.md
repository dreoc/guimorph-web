# Roadmap: GUImorph Modernization

## Milestones

- ✅ **v1.0 Modernization** — Phases 1–9 ([archive](milestones/v1.0-ROADMAP.md)) — shipped 2026-06-23

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

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 1–9 | v1.0 | 28/28 | Shipped | 2026-06-23 |

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
*v1.0 archived: 2026-06-23 — start next milestone with `/gsd-new-milestone`*
