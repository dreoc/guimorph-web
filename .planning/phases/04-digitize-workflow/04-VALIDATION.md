---
phase: 4
slug: digitize-workflow
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-15
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual smoke UAT + R console inspection (no testthat/pytest) |
| **Config file** | none |
| **Quick run command** | `devtools::load_all(".")`; `warnings()` |
| **Full suite command** | Phase 4 UAT checklist (04-02 + 04-03 + D-10) |
| **Estimated runtime** | ~30–60 minutes (Windows R GUI session) |

---

## Sampling Rate

- **After every task commit:** Run `devtools::load_all(".")` — must succeed without fatal error
- **After every plan wave:** Complete 04-02 or 04-03 UAT checklist once on Windows R
- **Before `/gsd-verify-work`:** Full UAT checklist green; DGT-02–04 TRUE in REQUIREMENTS.md
- **Max feedback latency:** manual (GUI-bound)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-02-01 | 04-02 | 1 | DGT-02 | — | N/A | manual UAT | Curve tab triple double-click select | ❌ W0 | ⬜ pending |
| 04-02-02 | 04-02 | 1 | DGT-02 | — | N/A | manual UAT | Click Fit once — no crash | ❌ W0 | ⬜ pending |
| 04-03-01 | 04-03 | 2 | DGT-03 | T-4-01 | Trusted local `.dgt` only | manual UAT | File → Save to DGT (2 specimens) | ❌ W0 | ⬜ pending |
| 04-03-02 | 04-03 | 2 | DGT-03 | — | N/A | manual | `grep "^Curve=" saved.dgt` | ❌ W0 | ⬜ pending |
| 04-03-03 | 04-03 | 2 | DGT-04 | T-4-01 | Validate numeric parses | manual UAT | File → Load DGT File (same session) | ❌ W0 | ⬜ pending |
| 04-03-04 | 04-03 | 2 | DGT-04 | — | N/A | manual UAT | Re-save after reload; `Curve=` non-zero | ❌ W0 | ⬜ pending |
| 04-03-05 | 04-03 | 2 | D-10 | — | N/A | manual | `warnings()` after `load_all` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.planning/smoke-test-findings.md` — Phase 4 section template (append-only per D-13)
- [ ] Confirm/fix `activeDataList[[1]][[4]]` init and `drawElements` curve assignment before declaring DGT-04
- [ ] No CI/automated GUI driver — accept manual-only with Nyquist justification

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Curve definition via 3 landmark selections | DGT-02 | Tk/OpenGL GUI; no headless driver | Set landmark count=3; place landmarks; Curves tab; triple double-click; Fit once |
| Multi-specimen `.dgt` save | DGT-03 | File dialog + visual confirm | Load 2 Folsom PLYs; digitize; File → Save to DGT |
| Same-session reload round-trip | DGT-04 | GUI menu path only (D-06) | File → Load DGT File; verify landmarks/curves; re-save |
| Capture load_all warnings | D-10 | R session state | Run `warnings()` after `load_all`; log to smoke-test-findings |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (checkpoint tasks use MISSING with manual-only GUI justification)
- [x] Sampling continuity: load_all per auto task; UAT checklist per wave
- [x] Wave 0 covers all MISSING references (smoke-test-findings append, init/drawElements fixes)
- [x] No watch-mode flags
- [x] Feedback latency acceptable for manual GUI UAT (~30–60 min Windows R session)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-15 — manual-only GUI UAT accepted; no headless Tk/OpenGL test harness exists for legacy GUImorph.
