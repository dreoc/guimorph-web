---
phase: 08-c-engine-deduplication
plan: 03
subsystem: c-engine
tags: [c, marker, tkogl2, uat, dgt, msvc]

requires:
  - phase: 08-c-engine-deduplication
    plan: 02
    provides: unified marker.c MSVC build
provides:
  - deployed unified-marker MSVC tkogl2.dll in inst/libs/x64/
  - Phase 8 UAT sign-off (landmarks, anchors, .dgt round-trip with anchor)
  - gap fixes for delete, anchor-move dispatch, selection tolerance, draw.anchors scope
affects: [09-c-engine-cleanup]

tech-stack:
  added: []
  patterns:
    - "UAT gap fixes: minimal dispatch/R patches when dedup exposes latent bugs"
    - "Selection grab tolerance 3x draw radius (sphere-surface vs mesh-center offset)"

key-files:
  created: []
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll
    - .planning/smoke-test-findings.md
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r

key-decisions:
  - "GBL_SELECT_TOLERANCE_FACTOR=3.0 — grab box wider than drawn sphere; marker visual size unchanged"
  - "setDot coordinate dispatches anchor_move when showModel==ANCHOR (required after D-03 per-set selection)"
  - "del(dot)/del(anchor) call tcl with no coords for selected-marker delete path"
  - "draw.anchors(e, id, anchors) — e required for anchorsPresentInMemory guard on .dgt reload"

patterns-established:
  - "Phase 8 UAT documented in smoke-test-findings.md with rollback reference tkogl2.dll.pre-phase8.bak"

requirements-completed: [CENG-02]

duration: 90min
completed: 2026-06-22
---

# Phase 08 Plan 03: Deploy + UAT Summary

**Unified-marker MSVC DLL deployed; landmark parity, anchor select/move/delete, and .dgt round-trip with anchor validated after UAT gap fixes.**

## Performance

- **Duration:** ~90 min (includes UAT gap-fix iterations)
- **Started:** 2026-06-22T16:30:00Z
- **Completed:** 2026-06-22T20:10:00Z
- **Tasks:** 3/3 complete
- **Files modified:** 6 (deploy + gap fixes + docs)

## Accomplishments

- Deployed MSVC `build-msvc/Release/tkogl2.dll` to `inst/libs/x64/` (`0118a8e`)
- UAT passed: landmark place/select/move/delete unchanged (D-04)
- UAT passed: anchor place/select/move/delete on intended anchor (D-03/D-10)
- UAT passed: `.dgt` save → same-session `openDgt` restores landmarks + curve + anchor (D-11)
- Pre-Phase-8 rollback artifact `tkogl2.dll.pre-phase8.bak` preserved (D-13)
- Phase 8 entry appended to `smoke-test-findings.md` (D-12)

## Task Commits

| Task | Name | Commit(s) | Status |
|------|------|-----------|--------|
| 1 | Deploy unified-marker DLL | `0118a8e` | Done |
| 2 | GUI UAT (landmark + anchor + .dgt) | — (human) | Approved 2026-06-22 |
| 3 | Record UAT in smoke-test-findings | (this summary) | Done |

## UAT Gap Fixes (during checkpoint)

| Issue | Fix | Commit |
|-------|-----|--------|
| `del("dot")` / `del("anchor")` missing-arg error | Default args; tcl del with no coords → `*_del_selected` | `195b568` |
| Moving anchor moved landmark | `setDot coordinate` routes `anchor_move` when `ANCHOR==showModel` | `220ee51` |
| Imprecise marker selection (rotation fall-through) | Selection grab tolerance 3× draw radius | `065e895` |
| `.dgt` load: `object 'e' not found` in `draw.anchors` | Add `e` as first parameter; update call sites | `45bfeec` |

## Decisions Made

- Selection tolerance widened deliberately (3×) — not a D-04 regression; improves click reliability without enlarging drawn markers
- One minimal `tcl_dispatch.c` change required for D-03 move fix (coordinate handler was hardcoded to `dot_move`)
- R-only `draw.anchors` scope fix — no DLL rebuild for that gap

## Deviations from Plan

### Auto-fixed Issues

Four UAT-discovered gaps fixed inline before `.dgt` round-trip could pass (see table above). All were latent bugs exposed by the first real anchor `.dgt` reload and per-set anchor selection state.

## Issues Encountered

- Initial UAT: delete R lazy-eval error; anchor move hit wrong marker set
- Second UAT: selection flakiness from sphere-surface vs mesh-center depth offset
- Third UAT: `draw.anchors` missing `e` parameter on `.dgt` anchor reload

## User Setup Required

None.

## Next Phase Readiness

- **Phase 9** unblocked — numbered globals cleanup, debug cruft removal
- Rollback: `tkogl2.dll.pre-phase8.bak` if landmark regression suspected

## Self-Check: PASSED

- FOUND: deployed `inst/libs/x64/tkogl2.dll` matches MSVC build
- FOUND: `tkogl2.dll.pre-phase8.bak` intact
- FOUND: UAT approved — landmarks, anchors, `.dgt` round-trip with anchor
- FOUND: Phase 8 entry in `smoke-test-findings.md`

---
*Phase: 08-c-engine-deduplication*
*Completed: 2026-06-22*
