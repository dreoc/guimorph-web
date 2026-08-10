---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: Browser Rendering
status: Phase 5 executed — human UAT pending
stopped_at: "Phase 5 all 6 plans executed; verification = human_needed (5/7 must-haves, 0 hard blockers). 05-UAT.md persisted. Awaiting display-host/Windows manual UAT: live browser digitizing, live surface-compute (specimen-slot stub), DGT-03 GPA/export run, DAT-01 dual-path, DAT-02 -rewrite gate, CMP-01 runtime load."
last_updated: "2026-08-07T16:45:00.000Z"
progress:
  total_phases: 6
  completed_phases: 3
  total_plans: 16
  completed_plans: 16
  percent: 50
current_phase: 5
current_phase_name: Full Digitizing and Data Parity
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

**Last session:** 2026-08-07T16:34:49.257Z
**Stopped at:** Completed 05-05-PLAN.md — Wave-2 analytical seam: GPA and
`.csv`/`.rds` export driven from the browser. `.gmw_session_to_geomorph_env`
reads the server-owned session into the existing `activeDataList[[i]][[10]]`/
`[[1]][[4]]`/`[[i]][[8]]` slots (+ gpagen option tclVars) so `.build_geomorph_data`/
`compute`/`save`/`exportGeomorph` run verbatim; `/export` allow-lists
`c("csv","rds")` and the path is chosen R-side. compute() forwarding untouched
(test-gpa-parity 13/13 green; test-export-parity 9/9 green). Prior session
context retained below.
macOS (raycast hits at interactive rates, overlay dots, `gmw_picks()` 6×3 matrix).
PICK-03 milestone gate and CMP-01 native load acknowledged as **deferred** to a
Windows `tkogl2` host — tracked in
`.planning/todos/pending/pick03-windows-parity-capture-owed.md`. PICK-03 harness is
drop-in-ready (zero code change to close). Phase 4 marked complete with those two
items open; next is Phase 5.
**Resume file:** None

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 02 P01 | 22 min | 2 tasks | 2 files |
| Phase 02 P02 | ~95 min | 3 tasks | 5 files (httpuv transport, token guard, tests) |
| Phase 03 P01 | ~11 min | 2 tasks | 3 files (teardown machinery, NAMESPACE, tests) |
| Phase 3 P3 | 9min | 2 tasks | 2 files |
| Phase 03 P02 | ~20 min | 3 tasks | 2 files (mixed /close app, port UX, browser degradation) |
| Phase 03 P04 | 14min | 2 tasks | 1 files |
| Phase 04 P01 | 12min | 2 tasks | 3 files |
| Phase 4 P02 | 30min | 3 tasks | 2 files |
| Phase 04 P03 | 15min | 3 tasks | 3 files |
| Phase 05 P01 | 9 min | 2 tasks | 2 files |
| Phase 05 P02 | 8 min | 3 tasks | 3 files |
| Phase 05 P03 | 14min | 3 tasks | 2 files |
| Phase 5 P4 | 3min | 2 tasks | 2 files |
| Phase 05 P05 | 6min | 2 tasks | 3 files (session→geomorph env builder, GPA/export seams, parity tests) |
| Phase 05 P06 | 3min | 2 tasks | 2 files |

## Decisions

- [Phase ?]: 03-03: viewport page fires navigator.sendBeacon('close') on pagehide + visibilitychange->hidden (relative same-origin target, no unload, no external ref)
- [Phase 3]: 03-02: /close route is a mixed httpuv app — excludeStaticPath() at /<token>/close + a per-server .gmw_close_handler(token) call closure that returns 204 first and defers .gmw_stop_token(token) via later::later (never synchronous stopServer; never joins req$PATH_INFO to the filesystem). Static byte mount kept byte-for-byte.
- [Phase 3]: 03-02: port=NULL arg on .gmw_serve_mesh wired to .gmw_pick_port(prefer=port); exhaustion stop(call.=FALSE) names the tried range through 49151 + omit-port hint (D-09).
- [Phase 3]: 03-02: launch prints URL first with paste fallback (D-05), one-time firewall note gated by .gmw_lifecycle$firewall_noted (D-06), try()-wrapped browseURL with return ignored honouring getOption(browser)/R_BROWSER (D-07).
- [Phase 3]: 03-02: WEB-04 requirement closure deferred to the phase gate — automated runtime half complete + unit-covered, but end-to-end browser UAT and CMP-01 display-host load gate still owed.
- [Phase ?]: 03-04: WEB-03 offline smoke test (test-offline-smoke.R, filter 'offline') builds the tarball, installs OFFLINE (repos=NULL, dependencies=FALSE) into a temp lib, asserts the vendored bundle ships via system.file(), specimen.ply serves 200+byte-identical, and the page has zero external refs; gated behind GMW_RUN_OFFLINE_SMOKE so a headless test_local skips cleanly instead of hanging on the installed package's tcltk2/rgl GUI-init load.
- [Phase ?]: 03-04: WEB-03 render UAT (6-specimen render/orbit/reset + 30 MB worst case + tab-close beacon) and CMP-01 display-host library() load recorded as executable manual steps in the test's # MANUAL UAT header and mirrored into 03-VALIDATION.md; sign-off pending human execution on offline Win+macOS.
- [Phase 4]: 04-01: POST /<token>/pick is a second excludeStaticPath subpath; .gmw_pick_handler subsumes /close, closes over its own token, base-R parses x,y,z (no JSON), stores in server-owned .gmw_picks, never joins PATH_INFO to filesystem (T-2-02).
- [Phase 4]: 04-01: gmw_picks() exported as the R read API over the server-owned landmark store; .gmw_close_handler kept because test-transport.R invokes it directly.
- [Phase 4]: 04-02: browser pick posts the mesh-local worldToLocal hit via relative sendBeacon(pick) mirroring /close; eager computeBoundsTree BVH; intersectObject(pickMesh,false) non-recursive so overlay dots never re-hit
- [Phase 4]: 04-02: GMW_REPLAY bakes column-major glGetDoublev modelview+projection on a camera (matrixAutoUpdate=false, fromArray, no transpose) and raycasts an identity mesh returning a raw PLY-vertex hit
- [Phase 4]: 04-02: .gmw_view3d_html splits render at MESH_URL slot (sprintf head, unescape doubled percent in JS body) because the template fmt exceeds R sprintf 8192-byte cap
- [Phase ?]: 04-03: PICK-03 built end-to-end against a schema-true PLACEHOLDER fixture but left FORMALLY OPEN (D-06/D-07); the real Windows+browser capture closes the gate with zero code change via the brXYZ columns the harness already reads.
- [Phase ?]: 04-03: parity gate is scale-relative — .gmw_parity_gate passes iff p95(browser-vs-native Euclidean distance) <= 1x mean inter-vertex edge length (~0.085 units on B7_1_clean.ply); base-R helpers in R/parity.R, no JSON dependency.
- [Phase ?]: 04-03: harness compares native objXYZ vs browser-replay brXYZ read DIRECTLY from the fixture columns (no in-R synthesis); real-parity block skips on the PLACEHOLDER sentinel until a real capture lands.
- [Phase 5]: 05-01: adopted byte-true .dgt determinism (round in R + pinned CRLF) over tolerance, per RESEARCH A2 default
- [Phase 5]: 05-01: all .dgt line emission routes through internal .dgt_writeln (binary connection, sep=CRLF), mirroring mergeDgt wb pin; saveToDgt header/blank lines included so the whole file is byte-deterministic
- [Phase ?]: 05-02: full .gmw_session per-specimen record + one-deep undo grammar (place/delete/move/curve_place); single grepl-branch .gmw_digitize_handler over per-subpath excludeStaticPath (A5); /specimen is RE-SERVE (A4); curves session-scoped integer index rows (A7); analytical routes forward-call 05-04/05/06 seams under try()
- [Phase ?]: 05-03: browser digitizing view layer in view3d.R BODY — anchor pick (green non-raycast anchors group) -> /anchor; curve-by-index cyan(1/255,164/255,191/255)/blue(0,0,1) -> /curve; surface THREE.Points cloud (display-only, R .gmw_flat); delete/undo/specimen with loadSpecimen computeBoundsTree BVH rebuild (RE-SERVE A4); all in the parameter-free BODY (HEAD 776B < 8192); landmark-mode guard keeps Phase-4 pick unregressed
- [Phase 5]: 05-05: browser GPA/export reuse native compute/save/exportGeomorph verbatim; .gmw_session_to_geomorph_env populates activeDataList[[i]][[10]] (landmarks) / [[1]][[4]] (curves) / [[i]][[8]] (surfaces) + gpagen option tclVars from the session so .build_geomorph_data/compute forwarding is untouched (source-scan still green); /export allow-list c("csv","rds"), export path chosen R-side by save()/exportGeomorph() (T-5-13); DGT-03 complete
- [Phase 05]: 05-06: browser Save routes through ONE shared .dgt serializer (.dgt_emit_session_blocks) reused by saveToDgt so DAT-01 byte-identity is structural (T-5-15); /save carries no path, target chosen R-side (T-5-16); save path never touches .gmw_engine (CMP-01/T-5-17)
