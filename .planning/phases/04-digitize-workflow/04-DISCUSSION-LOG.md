# Phase 4: Digitize Workflow - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 4-Digitize Workflow
**Areas discussed:** Curve definition workflow, `.dgt` round-trip depth, Fix vs document boundary, Validation baseline

---

## Curve Definition Workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Validate legacy workflow only | Curve tab, double-click 3 existing landmarks; middle becomes slider | ✓ |
| Enable dormant UI | Uncomment Set curve count, Set current curve, Compute Curves | |
| You decide | Smallest path satisfying DGT-02 | |

**User's choice:** Validate legacy workflow only

| Option | Description | Selected |
|--------|-------------|----------|
| Landmarks first, then curves | Place ≥3 landmarks on Digitize tab, switch to Curve tab | ✓ |
| Allow placing from Curve tab | Would require code changes | |
| You decide | | |

**User's choice:** Landmarks first, then curves

| Option | Description | Selected |
|--------|-------------|----------|
| One curve minimum | 3 landmarks forming 1 curve satisfies DGT-02 | ✓ |
| Multiple curves | Validate at least 2 curves | |
| You decide | | |

**User's choice:** One curve minimum

| Option | Description | Selected |
|--------|-------------|----------|
| Smoke-test Fit only | Click Fit once, no crash; no deep spline validation | ✓ |
| Skip Fit | Curve placement + visual display enough | |
| Full Fit validation | Verify semi-landmark resampling output | |

**User's choice:** Smoke-test Fit only

---

## `.dgt` Round-Trip Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Landmarks + curves only | Primary verification scope; ignore empty template/surface | ✓ |
| Full legacy format | All sections must round-trip | |
| You decide | | |

**User's choice:** Landmarks + curves only (primary scope)

| Option | Description | Selected |
|--------|-------------|----------|
| GUI menu path | File → Open via `openDgt()` | ✓ |
| Both GUI and R/Tcl | Also validate direct `loadDgt` | |
| You decide | | |

**User's choice:** GUI menu path (`openDgt()`)

| Option | Description | Selected |
|--------|-------------|----------|
| Exclude anchors | Not in DGT requirements | |
| Include if present | If user digitizes anchors, they must round-trip | ✓ |
| You decide | | |

**User's choice:** Include anchors if present during test session

| Option | Description | Selected |
|--------|-------------|----------|
| Single specimen only | C13.1.ply one slot | |
| Multi-specimen | Validate save loop over multiple specimens | ✓ |
| You decide | | |

**User's choice:** Multi-specimen validation required

| Option | Description | Selected |
|--------|-------------|----------|
| Same-session reload | Save then reopen without restarting R | ✓ |
| Cold restart | Quit R, relaunch, open `.dgt` | |
| Both | Same-session and cold restart | |

**User's choice:** Same-session reload

---

## Fix vs Document Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Capture warnings only | Run `warnings()` after `load_all`; fix only if digitize breaks | ✓ |
| Fix blocking warnings | Triage all 26, fix digitize-affecting ones | |
| Fix all 26 | Full warning cleanup in Phase 4 | |

**User's choice:** Capture only

| Option | Description | Selected |
|--------|-------------|----------|
| Leave debug prints | Useful for Phase 4 debugging; Phase 9 cleanup | ✓ |
| Reduce noise | Guard worst offenders in curve/save paths | |
| You decide | | |

**User's choice:** Leave debug prints

| Option | Description | Selected |
|--------|-------------|----------|
| Digitize blockers only | Crashes, silent failures, data loss in curve/save/reload | ✓ |
| UX confusion too | Fix anything like landmark visibility misreport | |
| You decide | | |

**User's choice:** Digitize blockers only

| Option | Description | Selected |
|--------|-------------|----------|
| Update smoke-test-findings.md | Append Phase 4 results and quirks | ✓ |
| VERIFICATION.md only | Formal GSD artifact at plan completion | |
| Both | | |

**User's choice:** Update `.planning/smoke-test-findings.md`

---

## Validation Baseline

| Option | Description | Selected |
|--------|-------------|----------|
| C13.1.ply | Continue Phase 3 validated specimen | ✓ |
| Add second PLY | Validate on different mesh too | |
| You decide | | |

**User's choice:** C13.1.ply (primary)

| Option | Description | Selected |
|--------|-------------|----------|
| Create fresh `.dgt` | Hand-digitize during Phase 4 | ✓ |
| Hunt external golden file | Locate legacy `.dgt` from authors | |
| Both | Fresh plus external if found | |

**User's choice:** Create fresh during Phase 4

| Option | Description | Selected |
|--------|-------------|----------|
| Two specimens, same PLY | Load C13.1.ply twice | |
| Two different PLY files | Two meshes from Folsom collection | ✓ |
| You decide | | |

**User's choice:** Two different PLY files from Folsom collection

| Option | Description | Selected |
|--------|-------------|----------|
| Don't commit `.dgt` | Keep test file local; paths machine-specific | ✓ |
| Commit fixture | Add under tests/fixtures/ | |
| You decide | | |

**User's choice:** Don't commit `.dgt` fixture

---

## Claude's Discretion

None — user made explicit choices for all questions.

## Deferred Ideas

- Enable dormant curve UI buttons (Set curve count, Compute Curves)
- Deep Fit / semi-landmark math validation
- Cold restart `.dgt` reload scenario
- Committed `.dgt` golden fixture in repo
- Fix all 26 `load_all` warnings proactively
- Debug print cleanup (Phase 9)
- Standalone C `loadDgt` Tcl validation path
