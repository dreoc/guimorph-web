---
phase: 4
slug: picking-parity
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-05
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat (R) |
| **Config file** | `tests/testthat.R` |
| **Quick run command** | `Rscript -e 'testthat::test_local(filter="picking")'` |
| **Full suite command** | `Rscript -e 'testthat::test_local()'` |
| **Estimated runtime** | ~60 seconds (full suite; quick filter ~5s) |

---

## Sampling Rate

- **After every task commit:** Run `Rscript -e 'testthat::test_local(filter="picking")'`
- **After every plan wave:** Run `Rscript -e 'testthat::test_local()'`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | PICK-01 | T-4-01 | Token-guarded `/pick`; no request-path→FS join (T-2-02) | unit | `Rscript -e '…sys.source("R/transport.R")…'` | ❌ W0 | ⬜ pending |
| 04-01-02 | 01 | 1 | CMP-01, PICK-01 | T-4-04 | `transport.R` never assigns `.gmw_engine`; skip-safe `.gmw_engine$ok` | unit | `testthat::test_local(filter="picking-transport")` | ❌ W0 | ⬜ pending |
| 04-02-01 | 02 | 1 | PICK-01 | — | Eager `computeBoundsTree` after load | source | `Rscript -e '…grepl("computeBoundsTree"…)'` | ✅ | ⬜ pending |
| 04-02-02 | 02 | 1 | PICK-02 | — | Depth-tested overlay dot; correct depth under rotation | source | `Rscript -e '…grepl("addOverlayDot"…)'` | ✅ | ⬜ pending |
| 04-02-03 | 02 | 1 | PICK-03 | — | Record-replay entry point (browser half) | unit | `testthat::test_local(filter="picking-view3d")` | ❌ W0 | ⬜ pending |
| 04-03-01 | 03 | 1 | PICK-03 | — | `.gmw_parity_gate` 95th-pct ≤ 1× mean edge (scale-relative) | unit | `Rscript -e '….gmw_parity_gate(...)…'` | ❌ W0 | ⬜ pending |
| 04-03-02 | 03 | 1 | PICK-03 | — | Pose-record TSV schema identical to real capture (D-07) | unit | `Rscript -e '…read.table(...)…identical(names,exp)'` | ❌ W0 | ⬜ pending |
| 04-03-03 | 03 | 1 | PICK-03 | — | Skip-safe harness; skips when real fixture absent | unit | `testthat::test_local(filter="picking-parity")` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-picking-transport.R` — created in 04-01
- [ ] `tests/testthat/test-picking-view3d.R` — created in 04-02
- [ ] `tests/testthat/test-picking-parity.R` — created in 04-03
- [ ] `tests/fixtures/parity/B7_1_pick_poses.tsv` — schema-true placeholder pose-record (04-03)

*Test files are created in-plan (no MISSING references); reuses `helper-pkg-source.R` skip-if-absent idiom.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Windows native fixture capture | PICK-03 | No Windows host available (D-06); oracle is Windows-only | Capture on validated `tkogl2` oracle, drop TSV into `tests/fixtures/parity/`, gate closes with no code change (D-07). See W4 caveat: document how the browser-replay coordinate enters the real comparison. |
| Browser render + pick + overlay UAT | PICK-01, PICK-02 | Headless sandbox has no display | Executable manual UAT steps (Phase 3 `# MANUAL UAT` precedent), signed off on macOS + Windows |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-08-05
