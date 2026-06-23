# Phase 5: Analysis Round-Trip - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 05-analysis-round-trip
**Areas discussed:** Minimum analysis, Validation path, Test data, API migration scope, Vendored geomorph code

---

## Minimum Analysis to Validate

| Option | Description | Selected |
|--------|-------------|----------|
| Landmarks-only GPA | 3 LM × 2 specimens, no sliding | ✓ |
| GPA + curve sliding | Enable curve semilandmark sliding | |
| GPA + PCA | Add gm.prcomp path | |

| Option | Description | Selected |
|--------|-------------|----------|
| Two specimens | Use test_fresh.dgt reload | ✓ |
| Single specimen | Minimum debug only | |
| Three+ specimens | Digitize third PLY | |

| Option | Description | Selected |
|--------|-------------|----------|
| Keep GPA tab defaults | PrinAxes/ProcD/Proj ON, sliding OFF | ✓ |
| Minimal gpagen flags | Only required args | |
| Document only | Note ProcD default quirks | |

**User's choice:** Landmarks-only GPA on two specimens with existing UI defaults.

---

## Validation Path

| Option | Description | Selected |
|--------|-------------|----------|
| GUI GPA full path | Compute → Plot → Save CSV | ✓ |
| GUI Compute only | Skip Plot/Save | |
| R console/script only | gpagen outside GUI | |

| Option | Description | Selected |
|--------|-------------|----------|
| Manual Windows R UAT | Log in smoke-test-findings.md | ✓ |
| Automated if possible | Rscript smoke | |
| Both | Auto + human | |

**User's choice:** Full GUI GPA tab workflow with manual Windows R UAT.

---

## Test Data Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse test_fresh.dgt | Phase 4 validated artifact | ✓ |
| Fresh digitize | New session landmarks | |
| Legacy golden files | Hunt original .dgt | |

| Option | Description | Selected |
|--------|-------------|----------|
| Same-session workflow | load_all → GUImorph → Load DGT → GPA | ✓ |
| Cold restart | Quit R and relaunch | |
| Either | Document which used | |

**User's choice:** Reload `test_fresh.dgt` in same R session as digitize handoff.

---

## API Migration Scope

| Option | Description | Selected |
|--------|-------------|----------|
| GPA hot path first | Fix blockers; inventory rest | ✓ |
| Full inventory + fix all | Before phase done | |
| Inventory only in 05-01 | Defer fixes | |

| Option | Description | Selected |
|--------|-------------|----------|
| geomorph + Morpho grep | 3dDigitize.*.r + geomorph.support.code.r | ✓ |
| geomorph only | Ignore Morpho for now | |
| All @import packages | geomorph, Morpho, Rvcg, vegan | |

**User's choice:** Hot-path fixes first; inventory geomorph and Morpho in active R sources.

---

## Vendored geomorph.support.code.r

| Option | Description | Selected |
|--------|-------------|----------|
| Defer unused advanced paths | Keep file; touch GPA path only | ✓ |
| Replace with CRAN 4.x | Swap vendored helpers | |
| Delete unused now | Aggressive cleanup | |

| Option | Description | Selected |
|--------|-------------|----------|
| No new analysis UI | GPA tab only | ✓ |
| Note PCA deferred | Future phase | |
| Minimal PCA helper | If GPA passes early | |

**User's choice:** Defer vendored advanced code; no PCA UI in Phase 5.

---

## Claude's Discretion

- Inventory-first vs UAT-first ordering within plans.
- Specific geomorph 4.x signature updates for `plotAllSpecimens` / `two.d.array`.
- Documentation depth for dead vendored procD code.

## Deferred Ideas

- GPA with curve sliding semilandmarks
- PCA / gm.prcomp analysis tab
- Third specimen for GPA
- Full geomorph.support.code.r replacement or deletion
- Automated GPA test script
- Cold-restart session before analysis
