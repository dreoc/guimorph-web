---
phase: 05-retina-picking-input-fixes-digitizing-analysis-data-parity
plan: 04
subsystem: testing
tags: [dgt, serialization, export, cross-platform, parity, macos, windows]
requires:
  - phase: 05-03
    provides: digitizing/anchor/curve/surface + GPA interaction parity
provides:
  - Deterministic `.dgt` save/load/merge and `.csv`/`.rds` export parity checks (DAT-01, DAT-02).
  - Bidirectional `.dgt` byte-compatibility harness with fixture-gated round-trip proof (DAT-03).
  - Windows full-regression checkpoint evidence (off-box, via maintainer) closing the D-16 recurring gate for Phase 5.
affects: [phase-05-verification, phase-06-analysis-plotting]
tech-stack:
  added: []
  patterns: [fixture-gated byte-compare, deterministic serialization ordering/precision]
key-files:
  created:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-dgt-cross-platform.R
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-export-parity.R
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/fixtures/parity/
  modified:
    - integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
    - integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ZARF_9.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ply_ZARF_9.c
key-decisions:
  - "Lock deterministic .dgt serialization ordering/precision so byte-compare is stable across platforms."
  - "Gate DAT-03 bidirectional proof on fixtures; skip cleanly when a direction's evidence is absent rather than false-pass."
  - "Accept Erik's off-box Windows regression report as the D-16 Windows-side evidence for Phase 5."
patterns-established:
  - "Cross-platform parity: author on one OS, rewrite on the other, byte-compare both directions."
requirements-completed: [DAT-01, DAT-02, DAT-03]
coverage:
  - id: D1
    description: "macOS `.dgt` save/load/merge round-trips deterministically against curated fixtures."
    requirement: DAT-01
    verification:
      - kind: unit
        ref: "tests/testthat/test-dgt-cross-platform.R"
        status: pass
    human_judgment: false
  - id: D2
    description: "macOS `.csv`/`.rds` exports match expected parity shape/content."
    requirement: DAT-02
    verification:
      - kind: unit
        ref: "tests/testthat/test-export-parity.R"
        status: pass
    human_judgment: false
  - id: D3
    description: "Windows-authored `.dgt` (testdgt_6_phase5test.DGT, 6 specimens) opens correctly on macOS with landmarks, anchors, curves, and surfaces intact (DAT-03 Windows->macOS leg)."
    requirement: DAT-03
    verification:
      - kind: manual_procedural
        ref: "Live macOS session 2026-07-18: 6 specimens loaded, all four data types verified on-screen"
        status: pass
    human_judgment: true
    rationale: "Visual on-screen verification of a Windows-authored session opening on macOS; no automated oracle for the interactive render."
  - id: D4
    description: "macOS-authored `.dgt` opens on Windows without byte-contract drift (DAT-03 macOS->Windows leg)."
    requirement: DAT-03
    verification:
      - kind: manual_procedural
        ref: "Mac-authored .dgt pushed to maintainer (Erik) 2026-07-18; Windows open/round-trip confirmation pending"
        status: unknown
    human_judgment: true
    rationale: "Return-leg confirmation is off-box and asynchronous — awaiting maintainer's Windows open. Tracked in .planning/todos/pending/dat-03-mac-to-windows-confirmation.md."
  - id: D5
    description: "Windows full digitizing->GPA->export regression shows no workflow regression (D-14/D-15/D-16)."
    requirement: DAT-03
    verification:
      - kind: manual_procedural
        ref: "Erik off-box Windows validation 2026-07-18: full workflow, wheel 1 step/notch, portrait canvas, 6-specimen .dgt round-trip, 212 live picks / 0 failed across 3 rgl plots + 5 GPA runs"
        status: pass
    human_judgment: true
    rationale: "Off-box Windows regression performed by the maintainer; evidence is the validation report, not an automated run on this host."
duration: n/a (checkpoint plan; code Tasks 1-2 executed 2026-07-18, checkpoint resolved 2026-07-18)
completed: 2026-07-18
status: complete
---

# Phase 05 Plan 04: Cross-Platform Data Parity (DAT-01/02/03) Summary

**Deterministic `.dgt`/export parity automation plus a bidirectional byte-compat harness; Windows regression passed off-box and the Windows→macOS round-trip is verified — the macOS→Windows confirmation is delivered and pending the maintainer.**

## Accomplishments
- DAT-01/DAT-02: deterministic `.dgt` save/load/merge + `.csv`/`.rds` export parity checks, fixture-backed and passing on macOS.
- DAT-03: bidirectional byte-compatibility harness that gates on paired round-trip fixtures.
- DAT-03 Windows→macOS leg verified live on macOS (Erik's `testdgt_6_phase5test.DGT`, 6 specimens, uniform 1000-pt surfaces): landmarks, anchors, curves, surfaces all intact.
- D-16 Windows full-regression checkpoint satisfied via Erik's off-box validation report (no workflow regression; required the in-milestone `gfx_make_current`-per-frame fix `129b42a`).

## Task Commits

1. **Task 1: Deterministic save/load/merge + export parity checks (DAT-01, DAT-02)** - `0b3f1f7` (feat)
2. **Task 2: Bidirectional `.dgt` byte-compatibility harness (DAT-03)** - `4968208` (feat)
3. **Task 3: Off-box Windows full-regression checkpoint (D-14/D-15/D-16)** - human-verify checkpoint (no code commit); resolved with maintainer evidence.

## Decisions Made
- Locked deterministic `.dgt` ordering/precision so cross-platform byte-compare is stable.
- The DAT-03 harness skips cleanly when a direction's paired fixtures are absent, rather than false-passing.
- Accepted Erik's off-box Windows validation as the D-16 Windows-side evidence for Phase 5.

## Deviations from Plan
None — Tasks 1-2 executed as written; Task 3 is a human checkpoint resolved with maintainer-supplied Windows evidence.

## Issues Encountered
- Live macOS validation surfaced a stale deployed `.dylib` (predated `129b42a`/`457895e`/`763ffca`); rebuilt + redeployed the arm64 dylib before continuing DAT-03 macOS checks.
- `.dgt` mesh resolution requires the referenced `.ply` files to sit alongside the `.dgt` (paths resolve against the `.dgt` directory); relevant during macOS open testing.

## Known Residual (tracked, non-blocking)
- DAT-03 macOS→Windows leg: the Mac-authored `.dgt` was pushed for the maintainer to open on Windows. Confirmation is asynchronous and still pending. Tracked in `.planning/todos/pending/dat-03-mac-to-windows-confirmation.md`. Phase verification will route this as a human item until Erik confirms.

## Next Phase Readiness
- DAT-01/02 automation-backed; DAT-03 has Windows→macOS proof + Windows regression evidence; macOS→Windows confirmation is the only open item.
- Phase 6 (rgl result-plot fallback) is unblocked from a data-parity standpoint; the result-plot segfault on macOS is Phase 6 scope, not a Phase 5 defect.

## Self-Check: PASSED
- Found: `tests/testthat/test-dgt-cross-platform.R`
- Found: `tests/testthat/test-export-parity.R`
- Found commits: `0b3f1f7`, `4968208`
