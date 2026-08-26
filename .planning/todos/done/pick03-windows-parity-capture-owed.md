---
title: "PICK-03 milestone gate + CMP-01 load owed a Windows capture (deferred from Phase 4)"
status: closed
resolution: wont-verify
closed_by: 06-08
closed_date: 2026-08-14
kind: verification-debt
priority: high
blocks: [PICK-03, CMP-01]
phase: 4
discovered: 2026-08-06
discovered_during: Phase 4 UAT (/gsd-verify-work 4)
owner: eoc
---

## Closure (D-04, Plan 06-08)

Retired **won't-verify**. The native tkogl2 oracle this gate depended on was
deleted when the native engine was removed in Phase 6 (Plan 06-07). No Windows
tkogl2 host capture ever materialized, so the byte-level parity comparison can
never be run. PICK-03 completion is documented in `NEWS.md` (v1.0.0) and locked
by the closed skip in `tests/testthat/test-picking-parity.R`.


## What is deferred

Phase 4 shipped browser picking (PICK-01, PICK-02) verified live on macOS, plus a
complete, drop-in-ready PICK-03 parity harness. Two verification items were
acknowledged as deferred at the user's direction because no Windows `tkogl2`
oracle host was available in this environment:

- **PICK-03 (milestone gate).** The real browser-vs-native parity capture: on a
  validated Windows `tkogl2` host, capture native `gluUnProject` poses and replay
  each in the browser via `window.GMW_REPLAY()`.
- **CMP-01 (runtime load).** Confirm `library(GUImorphWeb)` loads and the retained
  `tkogl2` engine builds/renders (`.gmw_engine$ok == TRUE`) on a Windows/display
  host. The *source invariant* (transport.R never touches `.gmw_engine`) is
  already auto-verified; only the runtime load confirmation is owed.

## What was verified (not deferred)

- **PICK-01 / PICK-02** — PASS on macOS/Safari. BVH raycast returns hits at
  interactive rates on `B7_1_clean.ply` (363,283 verts); red overlay dots render
  under the cursor; `gmw_picks(token)` returned a full 6×3 matrix (R owns the
  coordinates). See `.planning/phases/04-picking-parity/04-UAT.md` Test 2.

## What closes this (zero code change for PICK-03)

On a Windows host with the validated `tkogl2` oracle:

1. Capture native `gluUnProject` poses (`objXYZ` + per-row engine commit hashes)
   into the pose-record schema.
2. Replay each pose in the browser via `window.GMW_REPLAY()` to fill the `brXYZ`
   columns.
3. Write the rows into `tests/fixtures/parity/B7_1_pick_poses.tsv` (replacing the
   PLACEHOLDER rows).
4. Re-run `testthat::test_dir(filter='picking-parity')` — the real-parity block
   stops skipping and `.gmw_parity_gate(brXYZ, objXYZ, mean_edge)$pass` must be
   `TRUE` (p95 browser-vs-native distance ≤ 1× mean edge ≈ 0.085 on B7_1).
5. On the same host, confirm `library(GUImorphWeb)` + `.gmw_engine$ok == TRUE`
   (CMP-01).
6. Re-run `/gsd-verify-work 4` to flip Tests 1 and 3 from skipped to pass.

## Non-blocking cosmetic follow-ups observed during UAT

- Safari logs `Beacon API cannot load .../pick: cannot parse response` for the
  `/pick` `204` empty-body response; all picks were still delivered (6/6 stored).
  The `/close` beacon shares the identical response shape from Phase 3. A tidier
  fix would return a well-formed minimal response from `.gmw_pick_handler`.
- A double-click records two coincident picks (rows 1–2 of the UAT capture were
  identical) because the handler fires once per `pointerdown`. Candidate for a
  future debounce; not a Phase 4 defect.
