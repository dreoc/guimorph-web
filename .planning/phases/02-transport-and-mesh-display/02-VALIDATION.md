---
phase: 2
slug: transport-and-mesh-display
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-31
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat (R) |
| **Config file** | tests/testthat.R (if present) — else Wave 0 installs |
| **Quick run command** | `R -q -e 'testthat::test_dir("tests/testthat", filter="transport")'` |
| **Full suite command** | `R CMD check .` (or `devtools::test()`) |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 2-XX-XX | TBD | 0 | WEB-01 | — | httpuv installed + snapshotted | unit | `R -q -e 'requireNamespace("httpuv")'` | ❌ W0 | ⬜ pending |
| 2-XX-XX | TBD | 1 | WEB-01 | T-2-01 | server binds loopback only, unprivileged port | unit | `R -q -e 'testthat::test_dir("tests/testthat", filter="transport")'` | ❌ W0 | ⬜ pending |
| 2-XX-XX | TBD | 1 | WEB-01 | T-2-02 | random-path guard rejects unknown paths | unit | `R -q -e 'testthat::test_dir("tests/testthat", filter="transport")'` | ❌ W0 | ⬜ pending |
| 2-XX-XX | TBD | 1 | WEB-02 | — | PLYLoader renders mesh, orbit/zoom/reset | manual | manual UAT | — | ⬜ pending |
| 2-XX-XX | TBD | 1 | CMP-01 | — | native oracle still loads | unit | `R CMD check .` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. Task IDs finalized by planner.*

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-transport.R` — stubs for WEB-01 (server bind, path guard, PLY-as-bytes)
- [ ] `httpuv` added to DESCRIPTION Imports + `renv::snapshot()` — not yet in renv.lock
- [ ] testthat available (Suggests) if no framework detected

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Mesh renders with orbit/zoom/reset | WEB-02 | GPU render + browser interaction | Load reference specimen, confirm mesh visible (not black), orbit/zoom/reset work |
| 6-specimen set loads on stock macOS | WEB-02 | Needs clean macOS host, no XQuartz/Homebrew/Tcl-Tk | Run render path on stock macOS, load all 6, orbit each |
| 6-specimen set loads on stock Windows | WEB-02 | Needs clean Windows host | Run render path on stock Windows, load all 6, orbit each |
| No stray (0,0,0) vertices in framing | WEB-02 | Visual bounding-box inspection | Confirm camera framing/bbox excludes origin-null points |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
