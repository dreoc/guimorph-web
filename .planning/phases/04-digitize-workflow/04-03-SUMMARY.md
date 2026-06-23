---
phase: 04-digitize-workflow
plan: 03
subsystem: digitize
tags: [r, tcl-tk, dgt, save-reload, openDgt]

requires:
  - phase: 04-02
    provides: curve bind baseline and loadPly matrix init
provides:
  - drawElements curve restore on openDgt reload
  - openDgt reload path for Surface=0 .dgt files
  - queryFromR landmark count fix in draw.digitize
  - validated multi-specimen save/reload round-trip
affects: [phase-5-geomorph]

tech-stack:
  added: []
  patterns:
    - "saveToDgt writes Curve= header then per-specimen LM3=/ID= sections"
    - "openDgt → read.* → drawElements restores landmarks + curves into activeDataList"

key-files:
  created: []
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.surface.r
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
    - .planning/smoke-test-findings.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "Surface=0 in fresh .dgt is valid — openDgt must not abort on empty surfaces"
  - "Multi-specimen curve overlay on specimen 2 documented as future work (D-12)"

patterns-established:
  - "drawElements assigns read.curve output to activeDataList[[1]][[4]] when curves non-empty"

requirements-completed: [DGT-03, DGT-04]

duration: 90min
completed: 2026-06-15
---

# Phase 04 Plan 03: Save/Reload Summary

**Fixed drawElements curve restore and three openDgt blockers; validated 2-specimen .dgt save and same-session reload.**

## Performance

- **Duration:** ~90 min (includes iterative UAT + blocker fixes)
- **Completed:** 2026-06-15
- **Tasks:** 3/3 complete
- **Files modified:** 6

## Accomplishments

- Re-enabled `drawElements` curve restore (`if(0)` → active guard; matrix slot init)
- Fixed `openDgt` reload for `Surface=0` files (`printf` typo, vacuous NA check, NULL abort)
- Fixed `draw.digitize` landmark load (`e` out of scope in `add/queryFromR`; `digitize[,,1]` indexing)
- Human UAT: `test_fresh.dgt` save (C13.1 + C8.1) and reload confirmed by user

## Task Commits

1. **Task 1: drawElements curve restore** - `cc184b4` (feat)
2. **Task 2: Multi-specimen save (DGT-03)** - human UAT approved 2026-06-15
3. **Task 3: Reload + docs (DGT-04)** - openDgt fixes + documentation (this commit)

## Blockers Fixed During UAT

| Issue | Fix |
|-------|-----|
| `printf` in R `read.surface` | `print()` + nrow guard on empty Surface=0 |
| `openDgt` abort on NULL surfaces | Treat as Surface=0 |
| `object 'e' not found` in `add(queryFromR)` | Query in `draw.digitize`; remove invalid `e$` assign in `rtkogl.R` |
| Empty `digitize[,,0]` landmark probe | Use `digitize[,,1]` (R 1-based) |

## Known Limitations (documented, not fixed)

- Specimen-1 curve redraws on specimen 2 when opening Curves tab (global `activeDataList[[1]][[4]]`)
- Per-specimen curve bind on specimen 2 conflicts with specimen-1 curve state

## Self-Check: PASSED

- DGT-03 and DGT-04 marked complete in REQUIREMENTS.md
- smoke-test-findings.md Phase 4 save/reload section updated
- User confirmed openDgt reload works

## Requirements Completed

- **DGT-03** — multi-specimen `.dgt` save with landmarks + curve
- **DGT-04** — same-session GUI reload restores landmarks and curves
