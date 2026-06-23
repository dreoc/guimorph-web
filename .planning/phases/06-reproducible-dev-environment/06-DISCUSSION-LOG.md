# Phase 6: Reproducible Dev Environment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-19
**Phase:** 6-reproducible-dev-environment
**Areas discussed:** renv scope, Docs layout, Contributor setup path, DLL deploy workflow, load_all warnings

---

## renv scope

| Option | Description | Selected |
|--------|-------------|----------|
| Package root | renv in GUImorphDevelopment/; standard R package layout | ✓ |
| Repo root | renv at GUImorph/ top level | |
| You decide | Pick what fits R package conventions | |

| Option | Description | Selected |
|--------|-------------|----------|
| DESCRIPTION Imports only | geomorph, Morpho, parallel, Rvcg, tcltk, tcltk2, vegan | |
| Imports + workflow extras | Add devtools, rgl, RRPP for full GUI + GPA Plot path | ✓ |
| Full snapshot | Capture entire Windows R library | |

| Option | Description | Selected |
|--------|-------------|----------|
| Pin exact R 4.6.x | Strict R version in lockfile | |
| Document minimum R 4.6+ | Package versions locked; flexible R patch | ✓ |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Windows R only | Primary renv::restore() on Windows R | ✓ |
| Windows R + WSL R | Dual lockfiles or dual-restore | |

**Notes:** renv activates at package root; extras cover Phase 5 validated GPA Plot (`rgl`) and dev workflow (`devtools`).

---

## Docs layout

| Option | Description | Selected |
|--------|-------------|----------|
| Root BUILD.md | Repo-level full cycle; tkogl2/BUILD.md as deep-dive link | ✓ |
| Expand tkogl2/BUILD.md only | Add deploy + R to existing native doc | |
| docs/ folder | Separate docs location | |

| Option | Description | Selected |
|--------|-------------|----------|
| Brief pointer README | Short summary + link to BUILD.md | ✓ |
| Full quick-start inline | Complete instructions in README | |
| Replace README academic blurb | Entirely dev-focused README | |

| Option | Description | Selected |
|--------|-------------|----------|
| Integrated root BUILD.md | Single doc with all sections | ✓ |
| Split native + R | BUILD.md + DEVELOPMENT.md | |

**User's choice (troubleshooting):** Do not document WSL-specific quirks in contributor docs. README should list **inherent GUImorph quirks** only (e.g. double-click placement), not machine-specific WSL/UNC setup.

---

## Contributor setup path

| Option | Description | Selected |
|--------|-------------|----------|
| Windows R + local clone | Generic Windows path; WSL not prerequisite | ✓ (custom) |
| Hybrid WSL build + Windows R | Both documented without UNC examples | |
| You decide | | |

**User's choice (custom):** "WSL should not be required. That is just my local dev environment. Just assume user has Windows R and local clone."

| Option | Description | Selected |
|--------|-------------|----------|
| Assume R installed | Prerequisites list R 4.6+ only | |
| Document winget install | winget install RProject.R | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Use bundled DLL | Rebuild C only when changing tkogl2 | |
| Windows-native MinGW build | cmake+MinGW on Windows as primary | ✓ |
| WSL build optional advanced | Default uses inst/libs DLL | |

| Option | Description | Selected |
|--------|-------------|----------|
| load_all + GUImorph() | Minimum quick-start success | |
| Load sample PLY | Verify 3D viewer | |
| BUILD.md checklist | Full section in BUILD.md | |
| Targeted test | Test workflow relevant to the change | ✓ (custom) |

**User's choice (custom):** "Targeted test at whatever the change was."

---

## DLL deploy workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Document manual copy | BUILD.md copy commands only | |
| Add deploy script | scripts/deploy-dll.ps1 | |
| Both | Script + manual fallback | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-backup before swap | tkogl2.dll.bak | ✓ |
| Optional manual backup | Document only | |
| No backup | Git or rebuild | |

| Option | Description | Selected |
|--------|-------------|----------|
| tkogl2.dll only | glut64.dll already bundled | ✓ |
| Both DLLs | Always deploy both | |

| Option | Description | Selected |
|--------|-------------|----------|
| load_all succeeds | .onLoad confirmation | |
| Export check + load_all | objdump + load_all | |
| Full GUI smoke | load_all + GUImorph() + load PLY | ✓ |

---

## load_all warnings

| Option | Description | Selected |
|--------|-------------|----------|
| Capture only | Phase 4 D-10 carry-forward | |
| Triage + document | HOT vs DEFERRED; fix HOT only | ✓ |
| Fix all 26 | Full cleanup in Phase 6 | |

| Option | Description | Selected |
|--------|-------------|----------|
| README inherent quirks | User-facing in README; technical elsewhere | ✓ |
| BUILD.md Troubleshooting only | All triage there | |
| smoke-test-findings only | Audit log only | |

| Option | Description | Selected |
|--------|-------------|----------|
| Blocks workflow only | Fix failures/breakage only | ✓ |
| Deprecation + blockers | Also fix direct geomorph deprecations in our code | |

| Option | Description | Selected |
|--------|-------------|----------|
| After renv restore baseline | First renv::restore + load_all on clean Windows R | ✓ |
| Before and after renv | Compare pre/post lockfile | |

---

## Claude's Discretion

- Windows-native MinGW toolchain details and cmake adaptation from existing WSL-centric BUILD.md
- deploy-dll.ps1 implementation (paths, error handling)
- RRPP direct vs transitive lockfile entry
- README quick-start wording and step count

## Deferred Ideas

- WSL cross-compile as primary contributor path
- Fix all 26 warnings wholesale
- Dual renv for WSL + Windows R
- CI/automated smoke scripts (v2 QA requirements)
