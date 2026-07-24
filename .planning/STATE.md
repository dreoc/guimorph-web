---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: Browser Rendering
current_phase: 2
status: planning
stopped_at: "Phase 1 complete; Phase 2 not yet planned"
last_updated: "2026-07-23T00:00:00.000Z"
last_activity: 2026-07-24
last_activity_desc: "Phase 1 complete and verified on Windows + macOS; engine load made non-fatal"
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 0
  completed_plans: 0
  percent: 17
current_phase_name: Local Transport + Mesh Display
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

## Phase 1: complete

All four requirements shipped. Full detail in
`.planning/phases/01-browser-result-plots-rgl-demotion/01-SUMMARY.md`.

- **WEB-00** — three.js + three-mesh-bvh vendored as one classic-script bundle
  by the pinned toolchain in `scripts/vendor/`, byte-reproducible across Node
  versions. `R/view3d.R` opens a plain page over it. Renders from `file://` on
  Windows and macOS, which is the constraint the bundling exists for.
- **PLT-01** — both 3-D result plots through the browser; zero `rgl::` calls
  left in `3dDigitize.geomorph.r`.
- **PLT-02** — Morpho removed (it was the only thing pulling rgl into Imports),
  `fastKmeans` reimplemented over Rvcg at exact parity and median 1.4x faster.
  Imports down to geomorph, Rvcg, tcltk, tcltk2.
- **PLT-03** — inherited and verified; `plotPCA` stays base-graphics 2-D.

Two things came out of the macOS run that were not in the plan: the native
engine load is now non-fatal, so a broken `tkogl2.dylib` no longer takes the
browser paths down with it; and `otool -L` on `rgl.so` established *why* rgl is
a hard macOS dependency (three load-time libraries under `/opt/X11`), which
confirmed the premise PLT-02 rests on after it had been wrongly doubted.

## Phase 2: next

**Local Transport + Mesh Display (WEB-01, WEB-02).** `httpuv` serves a PLY over
loopback; three.js `PLYLoader` renders it. Port selection and the
server-owns-state design are inherited from `research/REFERENCE-ARCHITECTURE.md`
rather than re-derived. `B7_1_clean.ply` (363,283 verts, 30 MB ASCII) is
committed and is the worst-case transfer test.

Phase 4 picking parity remains the gate for the whole milestone.

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
