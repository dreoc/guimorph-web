# Phase 2: Transport and Mesh Display - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-31
**Phase:** 2-Transport and Mesh Display
**Areas discussed:** Specimen scope, Mesh appearance

---

## Specimen scope

| Option | Description | Selected |
|--------|-------------|----------|
| One specimen per viewport | R entry takes one PLY path, serves + renders it; multi-specimen switching stays Phase 5/DGT-02 | ✓ |
| Picker for all 6 reference meshes | In-page dropdown/list to switch specimen (pulls multi-specimen work forward) | |

**User's choice:** One specimen per viewport.
**Notes:** Keeps Phase 2 boundary tight; criterion 4 (6-specimen set loads/orbits) met by loading each individually.

---

## Mesh appearance — render style

| Option | Description | Selected |
|--------|-------------|----------|
| Solid shaded surface | Reuse existing Lambert material + lighting from view3d.R | ✓ |
| Wireframe | — | |
| Point cloud | Vertices only, like Phase 1 result plots | |
| Solid + keyboard toggle to wireframe | — | |

**User's choice:** Solid shaded surface.

## Mesh appearance — color + background

| Option | Description | Selected |
|--------|-------------|----------|
| Gray mesh (#cccccc) on white | Matches current view3d.R + rgl default | ✓ |
| Gray mesh on dark/neutral background | Better depth read on shaded surface | |
| Other | — | |

**User's choice:** Gray (#cccccc) on white (#ffffff).

---

## Claude's Discretion

- R entry function name/signature and endpoint route shape.
- Whether to reuse `GMW_VIEW3D_TEMPLATE` verbatim (swap inline geometry for `fetch`+`PLYLoader`) or fork a mesh-only template. Reuse preferred.

## Deferred Ideas

- In-page specimen picker / multi-specimen switcher — Phase 5 (DGT-02).
- Binary-PLY / Draco compression fast-path — only if transfer time unacceptable.
- Wireframe / point-cloud render toggle — not needed for read-only display.
