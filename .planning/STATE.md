---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: Browser Rendering
current_phase: 1
status: planning
stopped_at: Milestone registered, Phase 1 not yet planned
last_updated: "2026-07-22T00:00:00.000Z"
last_activity: 2026-07-22
last_activity_desc: Project split from GUImorph; browser milestone registered
progress:
  total_phases: 6
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
current_phase_name: Result Plots + rgl Demotion
---

# Project State

## Where This Came From

GUImorphWeb was split out of GUImorph on 2026-07-22 as a separate project rather
than a branch. GUImorph's native OpenGL macOS work continues on its own track,
maintained separately. Keeping the two in one repository would have put two
milestones in one GSD state file and put two people in the same
`REQUIREMENTS.md`, so they are separated at the repository level.

The split is deliberate and one-directional. R-layer fixes can be cherry-picked
from `upstream`. Native-engine work is not merged in. Nothing here is expected to
merge back.

## Inherited State

Carried in from GUImorph and treated as working, not re-derived:

- Full R analytical layer, `geomorph` integration, `exportGeomorph()`
- `.dgt` session format, reader, writer, and merge
- Parity test suite and `tests/fixtures/parity/`
- The `tkogl2` native engine, retained through Phase 5 as the Phase 4 picking
  oracle, deleted at Phase 6

Native path validation status at time of split: GUImorph's Windows build was
validated 2026-07-18 on a rebuilt DLL (full workflow, 6-specimen `.dgt`
round-trip, wheel 1 step per notch, portrait ortho verified, 212 live picks, 0
failed). That validation is what makes the engine usable as a reference oracle.

## Open Items Carried In

- **`.dgt` cross-platform parity, macOS to Windows direction** is not closed in
  GUImorph. DAT-02 here depends on it. Track, do not own.
- **NEWS.md and README drifted** through 0.10.0. Reconstructed at split time,
  but the release had no NEWS entry and shipped `exportGeomorph()` undocumented.
  Treat release notes as a gate, not an afterthought.

## Current Position

Milestone registered. No phase planned yet. Phase 1 is the natural entry point:
it touches no acquisition data, cannot corrupt a session, and fixes a live load
failure on current macOS.
