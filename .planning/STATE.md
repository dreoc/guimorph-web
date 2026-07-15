---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 01
current_phase_name: aqua-tk-deployment-gate-windows-rendering-seam
status: verifying
stopped_at: Verification in progress (GATE-01 passed; CMP-01 deferred)
last_updated: "2026-07-13T04:09:30Z"
last_activity: 2026-07-13
last_activity_desc: Phase 01 execution started
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 5
  completed_plans: 5
  percent: 17
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-12)

**Core value:** A researcher can digitize a 3D specimen and feed the result straight into `geomorph` — the interactive digitizing viewport must render the mesh and place landmarks correctly.
**Current focus:** Phase 01 — aqua-tk-deployment-gate-windows-rendering-seam

## Current Position

Phase: 01 (aqua-tk-deployment-gate-windows-rendering-seam) — EXECUTING
Plan: 4 of 4
Status: Plan execution complete; CMP-01 validation deferred to pending backlog
Last activity: 2026-07-13 — Phase 01 verification updated (GATE-01 pass recorded)

Progress: [██████████] 100% plans executed (phase verification pending)

## Performance Metrics

**Velocity:**

- Total plans completed: 2
- Average duration: 6 min
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 2 | 11 min | 6 min |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
| Phase 01 P01 | 2 min | 2 tasks | 6 files |
| Phase 01 P02 | 9 min | 2 tasks | 4 files |
| Phase 01 P03 | 16 min | 2 tasks | 1 files |
| Phase 01 P04 | 8 min | 2 tasks | 3 files |
| Phase 01 P05 | 6 | 2 tasks | 3 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Milestone]: Target macOS first (Linux deferred) — rgl/OpenGL digitizing deprecated there is the origin motivation.
- [Milestone]: Full feature parity target (not an MVP slice) — a partial digitizer isn't useful to researchers.
- [Milestone]: Keep R/Tk + geomorph layers; only rework native windowing/GL glue — analysis + GUI logic are validated.
- [Roadmap]: Native NSOpenGL-behind-a-seam over GLFW/SDL — portable toolkits own their own windows and can't render into a Tk-owned `NSView`.
- [Phase 01 Plan 01]: Keep `ogl_init` in core after `gfx_create`/`gfx_make_current` to preserve lifecycle ordering.
- [Phase 01 Plan 01]: Keep `gfx_destroy` as a no-op stub to avoid behavioral teardown changes in this mechanical refactor.
- [Phase 01 Plan 02]: Use command-line R plus `gate_check.R` as the durable Aqua deployment gate.
- [Phase 01 Plan 02]: Treat package-local D-01 binding as currently infeasible in this environment due mixed Tk runtime collisions.
- [Phase 01]: Locked D-01 (d01-bundled) as explicit distribution path for Plan 01-03.
- [Phase 01]: Retained Plan 02 feasibility caveat and routed bundling hardening requirements to Phase 4 BLD-03.
- [Phase 01]: Phase 01 Plan 04 deferred Windows MSVC render validation to backlog when macOS host could not execute D-06 check. — Continuation accepted from checkpoint: user cannot run Windows validation now; defer tracked in .planning/todos/pending/phase-01-windows-validation.md
- [Phase ?]: [Phase 01 Plan 05]: Use standard-C intptr_t (via <stdint.h>) for the int->native-drawable cast so no Win32 token remains in core; seam boundary complete (RND-01).
- [Phase ?]: [Phase 01 Plan 05]: Resolved model_t.count TBD debt marker with a concrete definition (vertex count for glDrawArrays, three per triangle).

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

- `phase-01-windows-validation.md` — pending Windows MSVC rebuild + D-06 render parity verification for CMP-01.

### Blockers/Concerns

[Issues that affect future work]

- [Phase 1]: Deployment gate is the milestone's gating risk — the native path is dead unless R can run against Aqua (Cocoa) Tk (CRAN R ships X11 Tk; XQuartz GLX is broken on macOS Tahoe). Must be resolved before any GL code.
- [Phase 5]: `.dgt` cross-platform byte compatibility (endianness/fixed-width) unverified — needs a Windows↔macOS round-trip test.
- [Phase 6]: rgl `rglwidget` fallback must be checked against `select3d()`/`rgl.snapshot()` usage in the three plot functions.
- Phase 01 CMP-01 remains open: Windows MSVC render parity validation deferred to .planning/todos/pending/phase-01-windows-validation.md

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Platform | Linux (GLX/X11 or Wayland) support | Deferred to follow-on milestone | 2026-07-12 |
| Rendering | Metal-backed rendering (OpenGL deprecation escape hatch) | Deferred (beyond parity) | 2026-07-12 |
| Rendering | Offscreen FBO + Tk-photo-blit fallback backend | Deferred (only if NSView embedding proves unstable) | 2026-07-12 |
| Security | Unsafe PLY parser hardening | Tracked separately (no v1 requirement) | 2026-07-12 |

## Session Continuity

Last session: 2026-07-13T03:59:41.835Z
Stopped at: Completed 01-04-PLAN.md
Resume file: None
