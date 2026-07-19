---
phase: 6
slug: rgl-result-plot-fallback-on-macos
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-18
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x (R) |
| **Config file** | integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/ |
| **Quick run command** | `R_LIBS_USER=.r-lib R -q -e "testthat::test_file('integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-rgl-fallback-macos.R')"` |
| **Full suite command** | `R_LIBS_USER=.r-lib R -q -e "testthat::test_dir('integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat')"` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick command
- **After every plan wave:** Run the full suite
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 6-01-01 | 01 | 1 | ANL-02 | — | N/A | unit | `testthat::test_file('.../test-rgl-fallback-macos.R')` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `tests/testthat/test-rgl-fallback-macos.R` — stubs for ANL-02 (platform-guarded rgl option + `.rgl_show` helper behavior)

*Automatable portion: the platform-branch logic (option set on macOS, unchanged path on Windows) and helper wiring can be unit-tested with mocked `.isMacOS()`. The actual WebGL render + browser display is manual-only.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Plot Aligned Specimens renders on macOS (no segfault) | ANL-02 | Requires live GL/WebGL + browser display; no headless oracle | Run GUImorph, GPA compute, click Plot Aligned Specimens → widget opens in browser |
| Plot Mean Shape renders on macOS (no segfault) | ANL-02 | Same as above | Click Plot Mean Shape → widget opens in browser |
| PCA (morphospace) still renders on macOS | ANL-02 | base-graphics quartz device; visual | Click PCA (morphospace) → 2-D scatter appears |
| Windows result plots unchanged (CMP-01) | ANL-02 | Off-box Windows host | Interactive rgl window still opens on Windows |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-18 (plan-checker confirmed automated-verify continuity; live renders + off-box Windows are the only manual-only items)
