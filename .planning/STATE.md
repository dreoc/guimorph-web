---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: Browser Rendering
status: Ready to plan
stopped_at: Completed 02-02-PLAN.md
last_updated: "2026-08-03T15:07:16.186Z"
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 2
  completed_plans: 3
  percent: 17
current_phase: 2
current_phase_name: Transport and Mesh Display
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

## Phase 2: both plans executed, manual UAT pending

**Local Transport + Mesh Display (WEB-01, WEB-02).** Both plans are executed:
02-01 shipped the three.js `PLYLoader` mesh-from-URL render branch; 02-02 shipped
the transport. `.gmw_serve_mesh()` (`R/transport.R`) starts a background `httpuv`
listener bound to `127.0.0.1` on an unprivileged port and serves one specimen PLY
as raw bytes via `staticPaths`, behind a per-session >=128-bit random path token,
retaining the live handle in `.gmw_server` against GC. Port selection and the
server-owns-state design are inherited from `research/REFERENCE-ARCHITECTURE.md`
rather than re-derived. `httpuv` is now a locked Import.

**Owed before the phase closes:**

- Manual browser UAT (`02-VALIDATION.md`, Manual-Only): all 6 reference specimens
  load and orbit/zoom/`r`-reset shaded (not black) on stock macOS and stock
  Windows; the worst-case `B7_1_clean.ply` (363,283 verts, 30 MB ASCII) transfers
  and frames acceptably. Now unblocked by `.gmw_serve_mesh()`.

- Re-run the CMP-01 `library(GUImorphWeb)` load gate on a host with a display —
  the headless sandbox could not (`tcltk2` GUI init blocks with no window server);
  the `httpuv`-specific half of CMP-01 (importable + Imports + locked) is verified.

- Teardown/port-recovery/browser-degradation are deliberately Phase 3 / WEB-04.

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

- **`renv` installed in site-library (workspace-local side effect).** Installed
  during 02-02 to generate the `httpuv` lock entry; it now makes bare
  `R`/`Rscript` hang on startup under a restricted network (`.Rprofile` →
  `activate.R`). Workaround: run R with `--no-init-file`. No committed file
  changed. Remove the installed `renv` package to restore clean bare-R startup,
  or leave it and use `--no-init-file`. Harmless on a normal networked machine.

- **`iter.max = 100` is too low at low slider counts.** All three template call
  sites pass it; research showed neither implementation converges at k = 500.
  Raising it changes template output, so it needs its own commit and evidence.

## Session

**Last session:** 2026-07-31T18:20:00.000Z
**Stopped at:** Completed 02-02-PLAN.md
**Resume file:** None

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 02 P01 | 22 min | 2 tasks | 2 files |
| Phase 02 P02 | ~95 min | 3 tasks | 5 files (httpuv transport, token guard, tests) |
