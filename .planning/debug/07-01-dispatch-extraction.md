---
status: diagnosed
trigger: "Phase 7 plan 07-01 smoke test failures — black C8.1.ply mesh, cannot place new landmark dots"
created: 2026-06-20T00:00:00Z
updated: 2026-06-20T00:00:00Z
---

## Current Focus

hypothesis: Black mesh is 2026 MinGW build / GL vertex-color path (pre-existing Phase 6), not dispatch extraction regression; dot placement blocked by R landmark quota (3/3) or validateDot if coords bad
test: Code comparison tcl_dispatch vs pre-extraction; trace addDot R quota; A/B DLL recommended
expecting: No functional diff in onDisplay/drawDots/getSpecimenCoordinate/add("dot"); quota silent block when dotNum >= landmarkNum
next_action: Document smoke FAIL in smoke-test-findings.md; user A/B retest

## Symptoms

expected: C8.1.ply loads with vertex colors; double-click places additional landmarks (default quota 5)
actual: Mesh renders black; 3 red dots visible (1,2,3); cannot place new dots via double-click; rotation OK
errors: none reported (silent dot failure possible)
reproduction: Phase 7 smoke after deploy of extracted-dispatch DLL
started: 2026-06-20 Phase 7 07-01 UAT

## Eliminated

- hypothesis: 1227 lines deleted during extraction left god file without onDisplay/dispatch handlers
  evidence: MOVE_RANGES only move chunks to dispatch; gap lines remain in tcl_if_ZARF_9.c (clear_model, snapshot, logging)
  timestamp: 2026-06-20

- hypothesis: duplicate validateDot/onDisplay symbols across TUs
  evidence: single definition each in tcl_dispatch.c only
  timestamp: 2026-06-20

- hypothesis: add("dot") path missing final onDisplay after successful placement
  evidence: falls through to END TCL_CMD_ADD onDisplay() at line 2349
  timestamp: 2026-06-20

## Evidence

- timestamp: 2026-06-20
  checked: tcl_dispatch.c onDisplay, drawDots, getSpecimenCoordinate, add shape "dot"
  found: Logic matches pre-extraction structure; onDisplay calls ogl_drawModel then switch(showModel) for drawDots; getSpecimenCoordinate toggles SPECIMEN mode + onDisplay twice; add("dot") validateDot then dot_add
  implication: No obvious extraction regression in hot paths

- timestamp: 2026-06-20
  checked: 0f12e12 fix — extern GBL_* and resetContext in tcl_dispatch.c
  found: Cross-TU globals declared for dispatch TU
  implication: Link-time/ODR issue addressed post-extraction

- timestamp: 2026-06-20
  checked: addDot in 3dDigitize.digitize.r
  found: Places only when activeDataList[[3]] < landmarkNum; no else-branch warning when quota reached
  implication: 3 dots + landmarkNum=3 → silent double-click no-op

- timestamp: 2026-06-20
  checked: Phase 6 smoke-test-findings 06-02
  found: 2026 MinGW build caused render issues; rollback to 2020 .bak restored mesh visuals
  implication: Black mesh may be build artifact, not dispatch logic change

- timestamp: 2026-06-20
  checked: ogl_drawModel colored path
  found: ogl_disableLight + GL_COLOR_ARRAY when model->color != NULL; unchanged in ogl_model_ZARF_9.c
  implication: Black colored mesh = zero/wrong color data or GL state — investigate with A/B DLL

## Resolution

root_cause: Inconclusive C regression in dispatch extraction; black mesh likely pre-existing 2026 build render issue (Phase 6 documented); dot placement likely R landmark quota at 3/3 or validateDot if picking fails
fix: none applied — no confirmed extraction bug
verification: pending user A/B DLL and console dotNum/landmarkNum check
files_changed: []
