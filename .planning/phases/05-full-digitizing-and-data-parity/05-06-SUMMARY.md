---
phase: 05-full-digitizing-and-data-parity
plan: 06
subsystem: digitizing
tags: [dgt, byte-parity, save, session, serializer, testthat, R, DAT-01, CMP-01]

# Dependency graph
requires:
  - phase: 05-full-digitizing-and-data-parity
    provides: "Deterministic .dgt writer (.dgt_write_matrix_block/.dgt_writeln, round-in-R + pinned CRLF) from 05-01"
  - phase: 05-full-digitizing-and-data-parity
    provides: ".gmw_session per-specimen record + /save forward-call seam from 05-02"
provides:
  - ".dgt_emit_session_blocks: the SINGLE .dgt block-emission routine shared by native saveToDgt and browser save"
  - ".gmw_save_session_dgt(token, file): browser Save serializes the server-owned session through that one routine"
  - "DAT-01 write-vs-write byte-identity test (browser save == canonical block sequence for identical arrays)"
  - "CMP-01 re-assertion over the .dgt save path (source-scan + skip-if-absent engine load)"
affects: [DAT-01, DAT-02, CMP-01, dgt-byte-parity, full-digitizing]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "One-writer-vs-itself byte parity: both save entry points call ONE .dgt_emit_session_blocks routine, so divergence is structurally impossible (T-5-15)"
    - "Save target chosen R-side (tkgetSaveFile when file=NULL); the /save request carries no path (T-5-16)"

key-files:
  created: []
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r"
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-dgt-cross-platform.R"

key-decisions:
  - "Factored the shared block-emission out of saveToDgt into .dgt_emit_session_blocks and routed BOTH entry points through it (the plan's preferred option -- guarantees identity, satisfies T-5-15) rather than mirroring the sequence call-for-call"
  - "The saveToDgt refactor is byte-equivalent: it now builds a per-specimen record list (skipping null-landmark specimens with the same message box) then calls the shared routine; block order/spacing/keys unchanged"
  - ".gmw_save_session_dgt reads rec$id/rec$template from the session record; an absent id yields a bare ID= line (paste0 drops NULL), consistent with saveToDgt"
  - "file=NULL routes to an R-side tkgetSaveFile dialog (T-5-16); an explicit path (test / future caller) bypasses the dialog so the byte gate runs headless"

patterns-established:
  - "Pattern: a single .dgt serializer (.dgt_emit_session_blocks) is the sole block-emission path; saveToDgt and .gmw_save_session_dgt are thin adapters that build the record list and delegate"

requirements-completed: [DAT-01, CMP-01]

coverage:
  - id: B1
    description: "Browser .gmw_save_session_dgt produces bytes identical to the canonical block sequence over the same in-memory arrays (one-writer-vs-itself)"
    requirement: "DAT-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-dgt-cross-platform.R#browser save is byte-identical to the canonical writer for identical arrays"
        status: pass
    human_judgment: false
  - id: B2
    description: "The .dgt save path never assigns/reads the native oracle engine env; positive engine check skips cleanly when absent"
    requirement: "CMP-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-dgt-cross-platform.R#CMP-01: the .dgt save path never writes .gmw_engine; native oracle stays loadable or skips cleanly"
        status: pass
    human_judgment: false
  - id: B3
    description: "DAT-02 bidirectional -rewrite byte gate remains a documented skip until the Windows re-save fixtures land"
    requirement: "DAT-02"
    verification:
      - kind: unit
        ref: "tests/testthat/test-dgt-cross-platform.R#DAT-03 bidirectional fixture gate is enforceable"
        status: skip
    human_judgment: true

# Metrics
duration: 3min
completed: 2026-08-07
status: complete
---

# Phase 5 Plan 06: Browser Save Through the Canonical .dgt Writer Summary

**The browser "Save" now serializes the server-owned session through the exact same single `.dgt` serializer as the native `saveToDgt`, so byte-identity (DAT-01) is a structural property proven one-writer-vs-itself at the R level — no second serializer exists.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-08-07T16:30:47Z
- **Completed:** 2026-08-07T16:33:32Z
- **Tasks:** 2
- **Files modified:** 2 (0 created, 2 modified)

## Accomplishments
- Extracted `.dgt_emit_session_blocks(file, curves, specimens)` — the ONE `.dgt` block-emission routine — and routed BOTH the native `saveToDgt` and the new browser path through it, making divergence between the two save entry points structurally impossible (threat T-5-15).
- Refactored `saveToDgt`'s write section to build a per-specimen record list (same null-landmark skip + message box) and delegate to the shared routine — byte-equivalent, block order/spacing/keys unchanged.
- Added `.gmw_save_session_dgt(token, file)` (`@noRd`): reads `.gmw_session[[token]]` (curves + per-specimen land/anchor/id/template/surfaces) and emits the `.dgt` through the same routine and the deterministic `.dgt_write_matrix_block`/`.dgt_writeln` helpers (05-01). `file = NULL` chooses the path R-side via `tkgetSaveFile` (T-5-16, `/save` carries no path); `stop(call. = FALSE)` on a missing session; never touches the native oracle engine env (CMP-01, T-5-17).
- Added the DAT-01 write-vs-write `.byte_signature` equality test (seed a session, write file A via `.gmw_save_session_dgt`, write file B via the same canonical block sequence directly, assert md5 identity) and a CMP-01 skip-if-absent load re-assertion; left the DAT-03 `-rewrite` gate untouched (still a documented skip).

## Task Commits

Each task was committed atomically (TDD RED -> GREEN):

1. **Task 1: DAT-01 write-vs-write byte identity + CMP-01 gate (failing)** - `ae61d71` (test)
2. **Task 2: .gmw_save_session_dgt via the one canonical serializer** - `5af885e` (feat)

**Plan metadata:** skipped (commit_docs disabled in `.planning/config.json`)

## TDD Gate Compliance
- RED gate: `ae61d71` `test(05-06)` — DAT-01 block committed failing (errors: `.gmw_save_session_dgt` not yet defined); CMP-01 skips cleanly.
- GREEN gate: `5af885e` `feat(05-06)` — the shared serializer + browser save turn DAT-01 green with no regression to the folsom3d fixture, DAT-03 skip, or the 05-01 determinism suite.
- REFACTOR gate: not needed as a separate commit — the saveToDgt refactor is part of the GREEN change and is byte-equivalent.

## Files Created/Modified
- `R/3dDigitize.main.r` — new `.dgt_emit_session_blocks` shared serializer; `saveToDgt` refactored to build a record list + delegate; new `.gmw_save_session_dgt(token, file)` browser save seam.
- `tests/testthat/test-dgt-cross-platform.R` — DAT-01 write-vs-write byte-identity block + CMP-01 skip-if-absent block; DAT-03 gate unchanged.

## Decisions Made
- Chose the plan's preferred **one-shared-routine** design over call-for-call mirroring: both save paths now call `.dgt_emit_session_blocks`, which is the strongest form of the T-5-15 mitigation (the two paths cannot diverge because there is only one serializer).
- `.gmw_save_session_dgt` reads `rec$id`/`rec$template` from the session record; the current `.gmw_session` empty record (owned by 05-02, not modified here) has no `id` field, so real sessions emit a bare `ID=` line until an id is wired — the byte gate is unaffected because both A and B read the same seeded value.
- Kept the `/save` seam signature `(token, file = NULL)`; the route (05-02) still calls it as `.gmw_save_session_dgt(token, NULL)` under `try()`, so an unimplemented dialog stays a harmless 204 on a headless host.

## Deviations from Plan
None - plan executed as written. The shared-routine factoring is the plan's explicitly preferred option; no new number formatting, terminator, or block layout was introduced; `transport.R` and `rtkogl.R` were not touched.

## Issues Encountered
None affecting the outcome. (The sandbox resets the shell working directory between commands; every command was run with an explicit `cd` into the R package root, which also satisfies the plan's "working directory = R package root" note.)

## Stated Limitations (NOT claimed closed)
- **DAT-02 `-rewrite` fixtures owed:** the bidirectional byte gate (`test-dgt-cross-platform.R` DAT-03 block) remains a `skip()` until the Windows/macOS re-save fixtures land — tracked in `.planning/todos/pending/dat-parity-gate-is-a-skip.md`.
- **mac LF round-trip:** under the pinned-CRLF writer (05-01), re-saving the LF `mac-authored-roundtrip.dgt` emits CRLF and will not byte-round-trip — the documented finding, not a regression.
- **DAT-02 macOS->Windows leg** is an open UPSTREAM dependency; the contract is half-proven, not fully bidirectional.
- **Live native-GUI vs browser dual-path DAT-01 run** needs a Windows `tkogl2` host and is recorded as manual UAT (05-VALIDATION.md); the R-level write-vs-write byte test is the automated gate. CMP-01's runtime `.gmw_engine$ok` confirmation likewise needs a display/engine host and skips cleanly headless.

## Threat Model Coverage
- **T-5-15 (Tampering, second .dgt serializer divergence, mitigate):** Addressed — a single `.dgt_emit_session_blocks` routine is the sole block emitter; DAT-01 byte test proves the browser path == canonical bytes.
- **T-5-16 (Tampering, save path injection, mitigate):** Addressed — `/save` carries no path; the destination is chosen R-side (`tkgetSaveFile`), never from the request body.
- **T-5-17 (Tampering, CMP-01 oracle load path, mitigate):** Addressed — the save path never reads/assigns `.gmw_engine`; source-scan + skip-if-absent load check assert it; `rtkogl.R` untouched.
- **T-5-SC (Tampering, package installs, accept):** No packages added this phase.

## Next Phase Readiness
- DAT-01 is proven at the R level (one writer vs itself); Phase 6 can retire the native oracle after the owed Windows dual-path run + `-rewrite` fixtures close DAT-02 and the manual DAT-01/CMP-01 evidence.
- The `/save`, `/gpa`, and `/export` browser seams are now all implemented; the Phase-5 transport surface is complete.

## Self-Check: PASSED

- FOUND: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` (`.gmw_save_session_dgt`, `.dgt_emit_session_blocks`)
- FOUND: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-dgt-cross-platform.R` (DAT-01 + CMP-01 blocks)
- FOUND: `.planning/phases/05-full-digitizing-and-data-parity/05-06-SUMMARY.md`
- FOUND commit `ae61d71` (test, RED gate)
- FOUND commit `5af885e` (feat, GREEN gate)

---
*Phase: 05-full-digitizing-and-data-parity*
*Completed: 2026-08-07*
