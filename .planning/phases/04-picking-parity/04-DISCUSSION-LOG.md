# Phase 4: Picking Parity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-04
**Phase:** 4-Picking Parity
**Areas discussed:** Parity fixture, Tolerance (gate)

---

## Gray-area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Pick round-trip transport | Browser click hit-coord → R (POST /pick vs WebSocket vs poll) | |
| Parity fixture | Specimens, click count, native capture on Windows oracle | ✓ |
| Tolerance value + basis | Numeric gate in mesh units, justified vs inter-observer error | ✓ |
| Landmark dot appearance + miss behavior | Dot color/size, depth, background-hit behavior | |
| Oracle mismatch framing | Depth-buffer winZ unproject vs exact triangle intersect | |

**User's choice:** Parity fixture + Tolerance. Rest → Claude/planner discretion + research.

---

## Tolerance (the gate — PICK-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Absolute mm | One fixed number across all specimens | |
| Fraction of mean edge length | Scale-relative per specimen; resolution floor | ✓ |
| Fraction of bbox diagonal | Scale-relative to specimen size | |
| Tie to real inter-observer number | Gate well inside a measured value | |

**User's choice:** Fraction of mean inter-vertex edge length.

| Pass rule | Description | Selected |
|-----------|-------------|----------|
| Max error < tol | Every point must pass (strict) | |
| 95th percentile < tol | Tolerate rare rasterization-edge outliers | ✓ |
| Median < tol, max reported | Softer | |

**User's choice:** 95th percentile < tolerance.

| Tolerance number | Description | Selected |
|------------------|-------------|----------|
| ≤ 0.5 × mean edge | Tight, sub-resolution | |
| ≤ 1 × mean edge | Within one mesh cell; resolution floor | ✓ |
| Defer number to research | Research picks + justifies vs literature | |

**User's choice:** ≤ 1 × mean inter-vertex edge length.

| Inter-observer cross-check | Description | Selected |
|----------------------------|-------------|----------|
| No project number | Research cites published GM inter-observer error | ✓ |
| Have one | User supplies value + source | |

**User's choice:** No local number — research cites published GM inter-observer digitizing error.
**Notes:** User approves the final justified number at plan time.

---

## Parity fixture

| Coverage | Description | Selected |
|----------|-------------|----------|
| All 6 specimens, landmark-set points | Real digitizing positions | |
| One specimen, dense grid | Fast gate iteration | ✓ |
| Worst + one clean | Stress + baseline | |
| All 6, dense | Max coverage, most labor | |

**User's choice:** One representative specimen, dense grid.

| Which specimen | Description | Selected |
|----------------|-------------|----------|
| B7_1_clean.ply | 363k-vert worst case, already committed | ✓ |
| Smaller clean specimen | Faster capture/iterate | |
| Research picks by geometry | Curvature range, clean topology | |

**User's choice:** B7_1_clean.ply.

| Fixture rigor | Description | Selected |
|---------------|-------------|----------|
| Record full native camera pose | modelview+proj+viewport+pixel+winZ+objcoord+commit; browser replays, raycasts same pixel | ✓ |
| Compare object-space only | Pick same feature by eye each side | |
| Recommend defensible one | — | |

**User's choice:** Full camera-pose record-and-replay.

| Native capture availability | Description | Selected |
|-----------------------------|-------------|----------|
| Windows available now | Capture during this phase | |
| Available but later | Separate manual step; gate open until captured | |
| Not readily available | Flag as risk/blocker | ✓ |

**User's choice:** Blocked — no Windows host readily available. PICK-03 cannot close this phase.

---

## Gate sequencing (given the blocker)

| Option | Description | Selected |
|--------|-------------|----------|
| Build harness now | PICK-01 + PICK-02 + full parity harness vs placeholder fixture; PICK-03 stays open; real fixture drop-in closes it, no code change | ✓ |
| Interim self-consistency check | R-side gluUnProject over recorded matrices to pre-validate coordinate convention | |
| Hold entire phase | Wait for Windows machine; no partial value | |
| Written capture procedure | Runbook for unattended fixture generation | |

**User's choice:** Build harness now (only).
**Notes:** Self-consistency check, hold, and written procedure all declined.

---

## Claude's Discretion

- Pick round-trip transport shape (token-guarded POST route extending the mixed
  httpuv `/close` app, following server-owns-state).
- Landmark dot appearance (color/size), depth behavior under rotation, and
  click-misses-mesh behavior.
- Placeholder fixture format + pose-record schema layout (must be schema-identical
  to the real Windows capture).

## Deferred Ideas

- Real native Windows fixture capture — blocked; scheduled separately.
- Interim R-side gluUnProject self-consistency check — offered, declined.
- Written native-capture procedure doc — offered, declined.
- Landmark editing/move/delete, curves, anchors, surfaces, multi-specimen, undo —
  Phase 5 (DGT).
