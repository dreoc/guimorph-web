---
phase: 5
slug: full-digitizing-and-data-parity
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-07
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.3.2 (edition 3) |
| **Config file** | `tests/testthat.R` (`test_check("GUImorphWeb")`) + per-file `tests/testthat/test-*.R` |
| **Working directory** | `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/` (R package root) |
| **Quick run command** | `rtk Rscript --no-init-file -e 'testthat::test_file("tests/testthat/test-<file>.R")'` |
| **Full suite command** | `rtk Rscript --no-init-file -e 'devtools::test()'` (pre-existing 6-red per STATE.md Open Items — unrelated to Phase 5; filter to new files if they block) |
| **Estimated runtime** | ~2–10 s per file; full suite ~1–2 min |

> `--no-init-file` avoids the renv `activate.R` startup hang under a restricted network (STATE.md Open Items). Source-scan and direct-handler tests use `skip_if_no_pkg_source()` and need no live server/browser.

---

## Sampling Rate

- **After every task commit:** Run the touched file's quick command (`testthat::test_file(...)`).
- **After every plan wave:** Run the full suite (`devtools::test()`), filtering to the Phase-5 files if the pre-existing reds block.
- **Before `/gsd-verify-work`:** All Phase-5 test files green (or a documented skip for owed external evidence).
- **Max feedback latency:** ~10 s (single-file quick run).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | DAT-01 | T-5-01 | Byte drift is detectable (not normalized away) | unit + byte | `test_file("tests/testthat/test-dgt-determinism.R")` | ❌ W0 | ⬜ pending |
| 05-01-02 | 01 | 1 | DAT-01 | T-5-01 / T-5-02 | R-decided rounding + pinned CRLF for the whole file | unit + byte | `test_file("tests/testthat/test-dgt-determinism.R")` | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 1 | DGT-01, DGT-02, CMP-01 | T-5-03 / T-5-04 / T-5-06 / T-5-08 | No path-join, JSON-free, cross-token isolation, oracle env untouched | unit (injected `req`) + source-scan | `test_file("tests/testthat/test-digitizing-session.R")` | ❌ W0 | ⬜ pending |
| 05-02-02 | 02 | 1 | DGT-01, DGT-02 | T-5-06 | Session mutations + one-deep undo confined to own token | unit (injected `req`) | `test_file("tests/testthat/test-digitizing-session.R")` | ❌ W0 | ⬜ pending |
| 05-02-03 | 02 | 1 | DGT-01, DGT-02 | T-5-03 / T-5-04 / T-5-05 | Suffix-only grepl; bounded base-R parse; /export allow-list; 204/404 | unit (injected `req`) + source-scan | `test_file("tests/testthat/test-digitizing-session.R")` | ❌ W0 | ⬜ pending |
| 05-03-01 | 03 | 2 | DGT-01, DGT-02 | T-5-09 / T-5-10 | Template wiring present; beacons relative same-origin; HEAD ≤ 8192 B | source-scan | `test_file("tests/testthat/test-digitizing-view3d.R")` | ✅ created | ✅ green |
| 05-03-02 | 03 | 2 | DGT-01 | T-5-09 | Anchor group non-raycast; curve-by-index cyan/blue; well-formed beacons | source-scan | `test_file("tests/testthat/test-digitizing-view3d.R")` | ✅ created | ✅ green |
| 05-03-03 | 03 | 2 | DGT-02 | T-5-09 | Surface cloud + delete/undo/specimen; BVH rebuilt on switch | source-scan | `test_file("tests/testthat/test-digitizing-view3d.R")` | ✅ created | ✅ green |
| 05-04-01 | 04 | 2 | DGT-02 | T-5-11 | Row-major `as.vector(t(...))` order pinned; column-major rejected | unit (regression) | `test_file("tests/testthat/test-surface-flatten.R")` | ❌ W0 | ⬜ pending |
| 05-04-02 | 04 | 2 | DGT-02 | T-5-11 / T-5-12 | Reuse TPS warp; no C `add("downsample")` re-coupling | unit | `test_file("tests/testthat/test-surface-flatten.R")` | ❌ W0 | ⬜ pending |
| 05-05-01 | 05 | 2 | DGT-03 | T-5-13 / T-5-14 | Session read == active read; export dispatch allow-listed | unit + source-scan | `test_file("tests/testthat/test-gpa-parity.R"); test_file("tests/testthat/test-export-parity.R")` | ✅ extend | ⬜ pending |
| 05-05-02 | 05 | 2 | DGT-03 | T-5-13 / T-5-14 | gpagen forwarding untouched; fmt allow-list; R-side export path | unit + source-scan | `test_file("tests/testthat/test-gpa-parity.R"); test_file("tests/testthat/test-export-parity.R")` | ✅ extend | ⬜ pending |
| 05-06-01 | 06 | 2 | DAT-01, DAT-02, CMP-01 | T-5-15 / T-5-17 | Write-vs-write byte identity; oracle skip-if-absent; save path no engine env | unit + byte + skip-if-absent | `test_file("tests/testthat/test-dgt-cross-platform.R")` | ✅ extend | ⬜ pending |
| 05-06-02 | 06 | 2 | DAT-01, DAT-02 | T-5-15 / T-5-16 / T-5-17 | One canonical writer (no second serializer); no path from request | unit + byte | `test_file("tests/testthat/test-dgt-cross-platform.R"); test_file("tests/testthat/test-dgt-determinism.R")` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*File Exists: ❌ W0 = failing scaffold created in the plan's Task 1 (Wave-0-within-plan); ✅ extend = existing test file extended.*

---

## Wave 0 Requirements

New failing-first test scaffolds, each created by its plan's Task 1 before implementation:

- [ ] `tests/testthat/test-dgt-determinism.R` — round + pinned-EOL writer determinism (05-01, DAT-01 prerequisite)
- [ ] `tests/testthat/test-digitizing-session.R` — anchor/curve/delete/undo/specimen route mutations, one-deep undo, cross-token isolation, T-2-02/JSON-free/CMP-01 source-scans (05-02, DGT-01/DGT-02/CMP-01)
- [x] `tests/testthat/test-digitizing-view3d.R` — template source-scan of the new anchor/curve/surface/delete/undo/switch wiring + HEAD 8192-byte cap (05-03, DGT-01/DGT-02) — **green (24 assertions)**
- [ ] `tests/testthat/test-surface-flatten.R` — `as.vector(t(surfaces[,,id]))` transpose regression (05-04, DGT-02, ROADMAP-mandated)

Existing infrastructure extended (no new scaffold needed):

- `tests/testthat/test-gpa-parity.R`, `test-export-parity.R` — session read-path + export dispatch (05-05, DGT-03)
- `tests/testthat/test-dgt-cross-platform.R` — DAT-01 write-vs-write byte identity + CMP-01 skip-if-absent gate; existing DAT-03 `-rewrite` skip gate retained (05-06, DAT-01/DAT-02/CMP-01)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser digitizing interactions (place anchors, define a curve by three placed landmark dots with cyan→blue→complete feedback, display/delete a surface semilandmark, undo, switch specimens) | DGT-01, DGT-02 | Headless sandbox has no browser/display; three.js interaction cannot be automated | On a display host, launch a viewport; confirm anchors render green, curve selection recolors (cyan, then blue slider, third completes), surface cloud displays/deletes, undo restores, and specimen switch reframes overlays + picks land on the new mesh. Record in a `# MANUAL UAT` header (Phase 3/4 pattern). |
| Live native-vs-browser dual-path DAT-01 run | DAT-01 | Requires a Windows `tkogl2` host running the native GUI alongside the browser path in one session (no host available per Phase-4 D-06) | Save the same session through the native GUI path and the browser path; confirm byte-identical `.dgt`. The automated R-level write-vs-write byte test (05-06) is the primary gate; this is corroborating manual UAT. |
| Windows `-rewrite` fixtures un-skip the DAT-02 gate | DAT-02 | Files must be produced by a Windows re-save; external evidence, no code analog | Per `dat-parity-gate-is-a-skip.md`: open `windows-authored-roundtrip.dgt` and `mac-authored-roundtrip.dgt` in GUImorphWeb, Save As `*-rewrite.dgt`, run the suite, commit. Expect the mac LF file NOT to byte-round-trip under pinned CRLF — that is the documented finding, not a regression. |
| GUImorph macOS→Windows `.dgt` leg | DAT-02 | Open upstream dependency in GUImorph; tracked, not owned here | State the half-proven bidirectional contract until GUImorph closes its macOS→Windows parity leg (RESEARCH Assumption A6). |
| CMP-01 native oracle runtime load (`.gmw_engine$ok == TRUE`) | CMP-01 | Needs a Windows host with the built `tkogl2` engine; headless/tarball skips cleanly | On a Windows host, confirm `.gmw_engine$ok` is TRUE after `library(GUImorphWeb)`; the skip-if-absent test asserts the invariant everywhere else. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or a Wave-0 scaffold dependency
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (4 new scaffolds + 3 extended files)
- [x] No watch-mode flags
- [x] Feedback latency < 10s (single-file quick run)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
