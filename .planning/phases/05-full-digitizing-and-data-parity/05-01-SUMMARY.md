---
phase: 05-full-digitizing-and-data-parity
plan: 01
subsystem: testing
tags: [dgt, determinism, byte-parity, crlf, rounding, testthat, R]

# Dependency graph
requires:
  - phase: 04-picking-parity
    provides: ".dgt writer + parity test suite (test-dgt-cross-platform.R) and .byte_signature raw-md5 helper"
provides:
  - "Deterministic .dgt writer: R-decided sixth-decimal rounding + pinned CRLF terminator across the whole file"
  - ".dgt_writeln internal binary-append line writer (single pinned-EOL write path)"
  - "test-dgt-determinism.R: byte-identity, CRLF, and R-rounding contract tests"
affects: [DAT-01, DAT-02, DAT-03, dgt-byte-parity, full-digitizing]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single pinned-EOL write path: all .dgt line emission routes through .dgt_writeln (binary connection, sep=\"\\r\\n\"), mirroring the mergeDgt wb pin"
    - "Round-in-R-before-format: formatC(round(as.numeric(x), 6), ...) so R (not libc) decides the sixth decimal"

key-files:
  created:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-dgt-determinism.R"
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r"

key-decisions:
  - "Adopted todo option (a) 'make it byte-true' (round in R + pin CRLF) over option (b) tolerance — per RESEARCH A2 recommended default"
  - "Pinned terminator is CRLF (\\r\\n), matching the in-repo mergeDgt precedent (3dDigitize.main.r:3455) and the Windows oracle corpus"
  - "Routed saveToDgt header/blank lines (TemplateNumber=/ID=/Template=/blanks) through .dgt_writeln too — a file that is CRLF in blocks but LF in headers is not byte-deterministic"

patterns-established:
  - "Pattern 1: .dgt_writeln is the sole line-emission primitive for the .dgt writer; no bare write()/cat() remains in the write path"
  - "Pattern 2: numeric formatting rounds in R before formatC to keep tie-breaking off the platform C library"

requirements-completed: [DAT-01]

coverage:
  - id: D1
    description: "Identical in-memory arrays serialize to byte-identical .dgt files (determinism)"
    requirement: "DAT-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-dgt-determinism.R#identical arrays write identical bytes"
        status: pass
    human_judgment: false
  - id: D2
    description: ".dgt output is CRLF-terminated across the whole file (no lone LF, CR count == LF count)"
    requirement: "DAT-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-dgt-determinism.R#output is CRLF-terminated"
        status: pass
    human_judgment: false
  - id: D3
    description: "Sixth-decimal rounding is decided by R's round(x,6), not by a bare formatC of the unrounded value"
    requirement: "DAT-01"
    verification:
      - kind: unit
        ref: "tests/testthat/test-dgt-determinism.R#rounding is R-decided"
        status: pass
    human_judgment: false
  - id: D4
    description: "Existing folsom3d writer-format parity test still passes under .dgt_normalize_lines (no regression)"
    verification:
      - kind: unit
        ref: "tests/testthat/test-dgt-cross-platform.R#dgt writer output matches parity fixture"
        status: pass
    human_judgment: false

# Metrics
duration: 9min
completed: 2026-08-07
status: complete
---

# Phase 5 Plan 01: Deterministic .dgt Writer Summary

**The single shared `.dgt` writer now rounds in R and emits a pinned CRLF terminator across the whole file, so byte-identity is a real, testable contract — the hard prerequisite for DAT-01.**

## Performance

- **Duration:** ~9 min
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- `.dgt_format_num` now rounds with `round(as.numeric(x), 6)` before `formatC(format="f", digits=6)`, so R — not the platform C library — decides the sixth decimal.
- Introduced internal `.dgt_writeln(file_name, text)` (`@noRd`), a binary-append (`open="ab"`) line writer with an explicit `sep="\r\n"`, mirroring the `mergeDgt` wb pin at `3dDigitize.main.r:3455`.
- Routed the ENTIRE `.dgt` write path — `.dgt_write_matrix_block` header/rows AND `saveToDgt`'s `TemplateNumber=`/`ID=`/`Template=`/blank separator lines — through `.dgt_writeln`, so no platform-dependent `write()` translation remains.
- Added `test-dgt-determinism.R` (three `test_that` blocks) encoding the DAT-01 prerequisite: identical arrays → identical bytes, CRLF-only termination, R-decided rounding.

## Task Commits

Each task was committed atomically (TDD RED → GREEN):

1. **Task 1: Wave-0 scaffold — failing determinism test** - `49bdd91` (test)
2. **Task 2: Round in R + pin CRLF across the .dgt writer** - `6fd49c3` (feat)

**Plan metadata:** skipped (commit_docs disabled in `.planning/config.json`)

## TDD Gate Compliance
- RED gate: `49bdd91` `test(05-01)` — determinism test committed failing (2 failures on CRLF assertions against the old LF/unrounded writer).
- GREEN gate: `6fd49c3` `feat(05-01)` — writer fix makes all three determinism blocks pass.
- REFACTOR gate: not needed (fix was minimal and clean).

## Files Created/Modified
- `tests/testthat/test-dgt-determinism.R` - New determinism contract test; mirrors the cross-platform test header (local `pkg_root`, `skip_if_no_pkg_source()`, sources `rtkogl.R` + `3dDigitize.main.r`, reuses a raw-md5 `.byte_signature`).
- `R/3dDigitize.main.r` - `.dgt_format_num` rounds before formatting; new `.dgt_writeln` binary-CRLF writer; `.dgt_write_matrix_block` and `saveToDgt` header/blank emissions routed through it.

## Decisions Made
- Chose byte-true determinism (round + pinned CRLF) over a tolerance-based gate, per RESEARCH Assumption A2 (recommended default) and the tracked todo option (a).
- Pinned CRLF (not LF) to match the in-repo `mergeDgt` precedent and GUImorph's Windows oracle corpus. **Documented limitation (not a regression):** re-saving the LF `mac-authored-roundtrip.dgt` will now emit CRLF and will not byte-round-trip — this is the expected `-rewrite` finding (see 05-06 and the todo).

## Deviations from Plan
None - plan executed exactly as written. No new serializer introduced; `.dgt_normalize_lines` untouched; block order, spacing, six-decimal precision, and header keys unchanged.

## Issues Encountered
None. Verification confirmed: determinism test 6/6 pass, cross-platform test 4 pass + 1 expected skip (DAT-03 bidirectional fixtures not yet present).

## Threat Model Coverage
- **T-5-01 (Tampering, `.dgt` byte output, mitigate):** Addressed — deterministic writer makes byte drift detectable by the byte-identity gate rather than hidden by normalization.
- **T-5-02 (Repudiation, low, accept):** Format/precision/block-order unchanged; only rounding + terminator pinned. Existing readers and the normalized fixture test unaffected (verified).
- **T-5-SC (Tampering, package installs, accept):** No packages added this phase.

## Next Phase Readiness
- DAT-01 prerequisite met: the byte gate can no longer be fooled by normalization.
- Follow-on plans (05-02+) can now compare the one writer against itself for `.dgt` byte parity.
- Open: the `-rewrite` bidirectional fixtures (DAT-03) are still needed from Windows/macOS round-trip evidence; that test currently skips cleanly.

## Self-Check: PASSED

- FOUND: `tests/testthat/test-dgt-determinism.R`
- FOUND: `.planning/phases/05-full-digitizing-and-data-parity/05-01-SUMMARY.md`
- FOUND commit `49bdd91` (test, RED gate)
- FOUND commit `6fd49c3` (feat, GREEN gate)

---
*Phase: 05-full-digitizing-and-data-parity*
*Completed: 2026-08-07*
