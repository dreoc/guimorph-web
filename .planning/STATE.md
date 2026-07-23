---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: Browser Rendering
current_phase: 1
status: executing
stopped_at: "PLT-02 and PLT-03 landed; WEB-00 and PLT-01 remain"
last_updated: "2026-07-23T00:00:00.000Z"
last_activity: 2026-07-23
last_activity_desc: "PLT-02 complete (Morpho removed, fastKmeans reimplemented); reference architecture adopted from landmarking-EOC"
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
milestones in one GSD state file and two people in the same `REQUIREMENTS.md`, so
they are separated at the repository level.

The split is one-directional. R-layer fixes can be cherry-picked from `upstream`.
Native-engine work is not merged in. Nothing here is expected to merge back.

## Inherited State

Carried in from GUImorph and treated as working:

- Full R analytical layer, `geomorph` integration, `exportGeomorph()`
- `.dgt` session format, reader, writer, and merge
- Parity test suite and `tests/fixtures/parity/`
- The `tkogl2` native engine, retained through Phase 5 as the Phase 4 picking
  oracle, deleted at Phase 6

GUImorph's Windows build was validated 2026-07-18 (full workflow, 6-specimen
`.dgt` round-trip, 212 live picks, 0 failed). That is what makes the engine
usable as a reference oracle.

## Reference Architecture

`landmarking-EOC`, the author's Flask + browser 2D landmarking tool, implements
this architecture for the same users. Its decisions are adopted rather than
re-derived: the server owns all state, the browser is a pure view and input
layer, assets are vendored offline, and the URL is printed rather than
auto-opened. See `.planning/research/REFERENCE-ARCHITECTURE.md`.

The most consequential consequence: R keeps the `.dgt` writer, so DAT-01 and
DAT-02 compare one writer against itself rather than two implementations against
each other.

## Phase 1 Progress

**Done.**

- **PLT-02** — Morpho removed from the dependency graph. It hard-imported rgl and
  was used for one function (`fastKmeans`), now reimplemented over Rvcg in
  `R/template_kmeans.R` at exact numerical parity, median 1.4x faster, and
  deterministic under a fixed seed. `vegan` and `parallel` removed as unused.
  `rgl` and `htmlwidgets` demoted to `Suggests` with all call sites guarded.
  geomorph confirmed rgl-free at 4.1.1. Test suite unchanged: 106 pass.
- **PLT-03** — already satisfied by inherited work. `plotPCA` routes through
  `.plot_show()`, stays base-graphics, and the single-component crash was fixed
  in GUImorph 0.10.0 (`a8a6cf0`). Needs verification, not work.

**Remaining.**

- **WEB-00** — vendor three.js and `three-mesh-bvh`, build the widget wrapper.
- **PLT-01** — route `plotspecs` and `plotMeanShape` through that wrapper.

## Open Items

- **Tahoe verification owed.** PLT-02 and PLT-03 cannot be closed on Windows,
  where rgl works. The criterion is that `library(GUImorphWeb)` succeeds and the
  digitizing workflow runs on a host where `library(rgl)` fails.
- **`.dgt` parity gate is a skip, not a pass.** Two of four fixtures are in place;
  the two `-rewrite` halves must be generated. The two platforms do not currently
  write identical bytes (line endings throughout, plus 1e-6 rounding in ten
  lines). See `.planning/todos/pending/dat-parity-gate-is-a-skip.md`.
- **Test suite has been 6-red for a month.** Two tests call functions Austin
  deleted in `2f65039`; four stub `tcltk` via `assignInNamespace`, which R 4.6
  no longer permits. Confirmed pre-existing, unrelated to any browser work.
- **Roxygen debt.** 22 S3 methods need `@exportS3Method`; `@docType "package"` is
  deprecated. Inherited, surfaces as `R CMD check` noise.
- **`iter.max = 100` is too low at low slider counts.** All three template call
  sites pass it; research showed neither implementation converges at k = 500.
  Raising it changes template output, so it needs its own commit and evidence.
