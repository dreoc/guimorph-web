---
phase: 12
slug: in-gui-feedback-status
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-25
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — R package (`tcltk` GUI); no automated UI harness |
| **Config file** | none |
| **Quick run command** | `R CMD check` / `devtools::load_all()` source-parse + targeted `grep` source assertions |
| **Full suite command** | `R -q -e 'devtools::load_all(".")'` (package loads without error) + manual UAT |
| **Estimated runtime** | ~30 seconds (load_all) |

---

## Sampling Rate

- **After every task commit:** Source assertion (`grep` for helper signature / converted call site) + `devtools::load_all()` parses clean
- **After every plan wave:** `devtools::load_all()` green; manual smoke of the changed surface
- **Before `/gsd-verify-work`:** Package loads clean and the UAT checklist below is walked
- **Max feedback latency:** ~30 seconds (source assertions are instant; load_all ~30s)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {to be filled by planner} | — | — | UX-FB-0X | — | N/A (local desktop GUI) | source-assertion | `grep` / `load_all` | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] No new test framework — `tcltk` GUI has no automated UI harness; verification is source-assertion + manual UAT.

*Existing infrastructure (R `devtools::load_all` parse + source grep) covers the automatable slice; visual behavior is manual-only (see below).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Status bar paints current action + result | UX-FB-01 | Visual Tk rendering; no UI test harness | Launch GUI, place a landmark, observe bottom status bar text updates |
| Progressbar visible during GPA Compute / multi-file PLY load | UX-FB-02 | Requires blocking-call timing + visual paint | Run Compute on a multi-specimen set; confirm indeterminate bar paints before freeze; load multi-file PLY, confirm determinate "{i} of {N}" |
| Nav/compute gates non-blocking (inline + disabled buttons, no modal) | UX-FB-03 | Interactive flow-control; visual | Trigger each former modal gate; confirm warning-foreground status + disabled button instead of a pop-up |

*Sampling boundary: source assertions prove the helpers/call-site conversions exist; the visual/timing behaviors are manual UAT.*

---

## Validation Sign-Off

- [ ] All tasks have a source-assertion verify or a manual-UAT entry
- [ ] Sampling continuity: no 3 consecutive tasks without automated (source-assertion) verify
- [ ] Wave 0 covers all MISSING references (none — no framework install)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
