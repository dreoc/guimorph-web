---
phase: 04-picking-parity
plan: 03
subsystem: testing
tags: [testthat, parity, picking, record-replay, mean-edge-length, base-r, tsv, Rvcg]

# Dependency graph
requires:
  - phase: 04-picking-parity
    provides: "04-01: token-guarded POST /<token>/pick route + server-owned .gmw_picks store"
  - phase: 04-picking-parity
    provides: "04-02: window.GMW_REPLAY(pose) browser record-and-replay entry point returning a raw PLY-vertex hit"
provides:
  - "R/parity.R: .gmw_mean_edge_length (D-01 tolerance unit), .gmw_parity_gate (D-02 95th-pct gate), .gmw_read_pick_poses (base-R TSV reader)"
  - "Schema-true PLACEHOLDER pose-record fixture (B7_1_pick_poses.tsv) byte-identical to the real Windows+browser capture (D-07)"
  - "test-picking-parity.R: skip-safe harness proving gate math + plumbing on the placeholder; real-parity block skips (PICK-03 OPEN)"
affects: [PICK-03 real Windows capture drop-in, milestone gate, picking UAT]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scale-relative parity gate: p95(browser-vs-native Euclidean distance) <= 1 x mean inter-vertex edge length (unit-free by construction)"
    - "Native objXYZ vs browser-replay brXYZ compared DIRECTLY from fixture columns — no in-R synthesis of the browser array on the real path"
    - "PLACEHOLDER per-row sentinel drives skip-if-real-fixture-absent; real capture closes the gate with zero code change (D-07)"
    - "Dependency-free base-R fixture I/O (read.table over TSV, comment.char = '#'); no JSON dependency (view3d.R policy)"

key-files:
  created:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/parity.R"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/fixtures/parity/B7_1_pick_poses.tsv"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-picking-parity.R"
  modified: []

key-decisions:
  - "PICK-03 left FORMALLY OPEN (D-06/D-07): the harness is built end-to-end against the placeholder; the real Windows+browser capture closes the gate with genuinely zero code change via the brXYZ columns the harness already reads."
  - "Gate compares native objXYZ against browser-replay brXYZ read straight from the fixture — no in-R synthesis, so real closure needs no code change (W4 drop-in channel)."
  - "Fixture generated deterministically (identity modelview + plausible perspective projection, 6 rows: 4 zero-distance + 2 sub-mean-edge noise) so the 95th-percentile branch is genuinely exercised (Open Question 3)."

patterns-established:
  - "Parity gate math lives in side-effect-free @noRd helpers (view3d.R .gmw_flat/.gmw_faces style); tests source the file directly under skip_if_no_pkg_source()."
  - "Skip-safe harness: every block skips cleanly (pkg source / Rvcg / PLY / real fixture absent) rather than erroring, mirroring test-retina-picking-parity.R."

requirements-completed: []  # PICK-03 stays FORMALLY OPEN this phase (D-06/D-07); harness built and green on the placeholder, gate closes on the real Windows capture drop-in.

coverage:
  - id: D1
    description: ".gmw_mean_edge_length computes the mean inter-vertex edge length (the D-01 scale-relative tolerance unit); ~0.085 units on B7_1_clean.ply, and exactly (2+sqrt(2))/3 on a hand-checkable single-triangle mesh."
    requirement: "PICK-03"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-parity.R#.gmw_mean_edge_length equals the mean of a triangle's three edges"
        status: pass
    human_judgment: false
  - id: D2
    description: ".gmw_parity_gate returns pass iff p95(distance) <= 1 x mean_edge (D-02): a tight array passes, a 1-unit-spread array fails, and p95/n are correct."
    requirement: "PICK-03"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-parity.R#.gmw_parity_gate passes a tight array and fails a spread one"
        status: pass
      - kind: unit
        ref: "tests/testthat/test-picking-parity.R#.gmw_parity_gate reports the 95th percentile of the distances"
        status: pass
    human_judgment: false
  - id: D3
    description: ".gmw_read_pick_poses parses the placeholder TSV into the fixed drop-in column set (including brx/bry/brz), skipping the # header comment; nrow >= 4."
    requirement: "PICK-03"
    verification:
      - kind: unit
        ref: "tests/testthat/test-picking-parity.R#.gmw_read_pick_poses parses the placeholder into the fixed columns"
        status: pass
    human_judgment: false
  - id: D4
    description: "Placeholder end-to-end: mean_edge from B7_1_clean.ply via Rvcg, native objXYZ vs browser-replay brXYZ read DIRECTLY from fixture columns, gate returns pass with finite p95."
    requirement: "PICK-03"
    verification:
      - kind: integration
        ref: "tests/testthat/test-picking-parity.R#placeholder harness runs the gate on native objXYZ vs browser brXYZ"
        status: pass
    human_judgment: false
  - id: D5
    description: "PICK-03 milestone gate: real browser-vs-native parity within the approved tolerance. Harness real-parity block runs unchanged once a real Windows+browser capture replaces the PLACEHOLDER sentinel."
    verification:
      - kind: integration
        ref: "tests/testthat/test-picking-parity.R#PICK-03 real-parity gate closes with the real Windows capture (D-07)"
        status: unknown
    human_judgment: true
    rationale: "PICK-03 is FORMALLY OPEN (D-06): native gluUnProject capture is Windows-only and no Windows host is available. The block SKIPS on the placeholder; closing the gate requires a real capture on the validated tkogl2 oracle, then zero code change (D-07)."

# Metrics
duration: 15min
completed: 2026-08-05
status: complete
---

# Phase 4 Plan 03: R Parity Gate + Placeholder Fixture + Skip-Safe Harness Summary

**Built the R side of the PICK-03 picking-parity gate — the scale-relative mean-inter-vertex-edge-length tolerance, the 95th-percentile browser-vs-native distance gate, a base-R pose-record TSV reader, a schema-true PLACEHOLDER fixture, and a skip-safe testthat harness — proving the gate math and plumbing end-to-end while PICK-03 stays FORMALLY OPEN and one real Windows capture away from closing with zero code change.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-08-05
- **Tasks:** 3 completed
- **Files created:** 3 (parity.R, B7_1_pick_poses.tsv, test-picking-parity.R)

## Accomplishments
- `R/parity.R` defines three side-effect-free `@noRd` helpers, base R + `stats`/`utils` only (no JSON dependency): `.gmw_mean_edge_length` (the D-01 tolerance unit — ~0.085 units on `B7_1_clean.ply`, matching RESEARCH), `.gmw_parity_gate` (returns `list(p95, pass, n)` with `pass = p95(dist) <= 1 x mean_edge`, D-02), and `.gmw_read_pick_poses` (`read.table` over the TSV, `comment.char = "#"`).
- `tests/fixtures/parity/B7_1_pick_poses.tsv` is a byte-schema-identical PLACEHOLDER pose record: a `#` metadata comment binding it to `B7_1_clean.ply` (with its sha256) at `engine_commit=PLACEHOLDER`, then the fixed 46-column header `commit, mv00..mv15, pj00..pj15, vp0..vp3, px, py, winz, objx, objy, objz, brx, bry, brz` — native `objXYZ` FOLLOWED by the browser-replay `brXYZ` drop-in channel — and 6 rows (4 zero-distance + 2 sub-mean-edge noise) covering a front-facing centre, near-silhouette, steep-gradient, and axis-aligned sanity pose.
- `tests/testthat/test-picking-parity.R` runs green: unit blocks for mean-edge (hand-checkable triangle), the 95th-percentile gate (tight passes / spread fails / p95 correctness), and the reader; an integration block computing `mean_edge` from the real PLY via Rvcg and gating native `objXYZ` vs browser-replay `brXYZ` read straight from the fixture; and a real-parity block that SKIPS on the PLACEHOLDER sentinel (never fails) and closes PICK-03 unchanged when a real capture drops in.
- The harness header records PICK-03 as FORMALLY OPEN and drop-in-ready (D-06/D-07), and a `# MANUAL UAT` block captures the browser PICK-01/02 checks and the Windows oracle capture procedure.

## Task Commits

Each task was committed atomically:

1. **Task 1: parity.R — mean edge length, gate math, and fixture reader** - `4739e0d` (feat)
2. **Task 2: schema-true PLACEHOLDER pose-record fixture** - `c9edb44` (test)
3. **Task 3: skip-safe parity harness test + PICK-03 OPEN record** - `1dc7662` (test)

**Plan metadata:** `commit_docs` is disabled in `.planning/config.json`, so the docs/state commit is intentionally skipped by the SDK.

## Files Created/Modified
- `R/parity.R` — new; `.gmw_mean_edge_length`, `.gmw_parity_gate`, `.gmw_read_pick_poses` (base-R, no JSON).
- `tests/fixtures/parity/B7_1_pick_poses.tsv` — new; schema-true PLACEHOLDER pose record (drop-in contract for the real Windows capture).
- `tests/testthat/test-picking-parity.R` — new; skip-safe harness (math + gate + reader + placeholder end-to-end + real-parity skip gate), PICK-03 OPEN header, MANUAL UAT block.

## Decisions Made
- **PICK-03 stays FORMALLY OPEN.** The plan builds the entire gate against the placeholder (D-07); the milestone requirement closes only when the real Windows oracle capture is dropped in. `requirements-completed` is therefore empty and D5 is routed to human judgment.
- **Compare native `objXYZ` against browser-replay `brXYZ` directly from the fixture columns** (no in-R synthesis), so the real capture closes the gate with genuinely zero code change — the browser-replay coordinate enters via the `brXYZ` columns the harness already reads.
- **Fixture generated deterministically** with a small throwaway R generator (not committed): identity modelview, a plausible perspective projection, a realistic `0 0 1200 900` viewport, and a zero-distance/noise row mix so the `quantile(., .95)` branch is exercised.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- Per the 04-01/04-02 precedent, the plan's `testthat::test_local(filter="picking-parity")` loads the package namespace via pkgload and hangs on the `tcltk2`/rgl GUI-init (STATE.md Open Items). Verification instead used `testthat::test_dir("tests/testthat", filter="picking-parity")`, which auto-sources the helpers without loading the GUI stack: the parity harness runs all assertions green with exactly one clean SKIP (the real-parity block, PICK-03 OPEN).
- Bare `Rscript` hangs on the `renv` `.Rprofile` under the restricted sandbox network; all R was run with `Rscript --vanilla` as STATE.md recommends.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The PICK-03 gate is fully built and unit-proven on the placeholder; the only thing owed at the milestone gate is the **real Windows+browser capture** (D-06). Capturing native poses on the validated `tkogl2` oracle, replaying each in the browser via `window.GMW_REPLAY()` to fill `brXYZ`, and writing the rows into `B7_1_pick_poses.tsv` closes PICK-03 with zero code change (the real-parity block stops skipping).
- Owed browser/display UAT for PICK-01/02 (headless CI cannot render WebGL) is recorded in the harness `# MANUAL UAT` block and `04-VALIDATION.md` Manual-Only rows.

## Self-Check: PASSED
- FOUND: `R/parity.R`
- FOUND: `tests/fixtures/parity/B7_1_pick_poses.tsv`
- FOUND: `tests/testthat/test-picking-parity.R`
- FOUND commit `4739e0d` (Task 1)
- FOUND commit `c9edb44` (Task 2)
- FOUND commit `1dc7662` (Task 3)

---
*Phase: 04-picking-parity*
*Completed: 2026-08-05*
