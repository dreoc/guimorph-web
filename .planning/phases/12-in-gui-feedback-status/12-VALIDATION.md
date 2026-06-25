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
| 12-01-T1 helpers + status bar | 12-01 | 1 | UX-FB-01, UX-FB-02 | T-12-01 | N/A (local desktop GUI; program-generated strings) | source-assertion + load | `grep -nE 'setStatus <- function\|busyStart <- function\|busyStop <- function\|e\$statusLabel <- ttklabel\|warning = "#b35900"' R/3dDigitize.main.r` + `load_all` | main.r | ⬜ pending |
| 12-01-T2 env-storage gaps | 12-01 | 1 | UX-FB-03 | T-12-01 | N/A | source-assertion + load | `grep -nE 'e\$nextBtn <- nextBtn\|e\$prevBtn <- prevBtn' R/3dDigitize.main.r` + `grep 'e\$gpaStatusLabel <- ttklabel' R/3dDigitize.geomorph.r` | main.r, geomorph.r | ⬜ pending |
| 12-02-T1 nav modal removal | 12-02 | 2 | UX-FB-03 | T-12-02 | N/A | static grep + load | `test "$(grep -c tkmessageBox R/3dDigitize.main.r)" -le 4` + exact-copy greps | main.r | ⬜ pending |
| 12-02-T2 proactive nav hooks | 12-02 | 2 | UX-FB-03 | T-12-02 | N/A | source-assertion + load | `grep -nF 'if (!is.null(e$nextBtn) && !is.null(e$prevBtn))' R/3dDigitize.digitize.r` | digitize.r | ⬜ pending |
| 12-02-T3 showPicture parity | 12-02 | 2 | UX-FB-01 | T-12-02 | N/A | source-assertion + load | `grep -nF 'setStatus(e, paste0("Specimen ' R/3dDigitize.main.r` | main.r | ⬜ pending |
| 12-03-T1 compute gate modals | 12-03 | 2 | UX-FB-03 | T-12-03 | N/A | static grep + load | `test "$(grep -c tkmessageBox R/3dDigitize.geomorph.r)" -eq 1` + exact-copy greps | geomorph.r | ⬜ pending |
| 12-03-T2 gpagen busy wrap | 12-03 | 2 | UX-FB-02, UX-FB-01 | T-12-03-RE | re-entrancy via `update idletasks` | source-assertion + load | `grep -nF 'Computing GPA alignment for ' R/3dDigitize.geomorph.r` | geomorph.r | ⬜ pending |
| 12-04-T1 PLY determinate loop | 12-04 | 3 | UX-FB-02, UX-FB-01 | T-12-04-RE | re-entrancy via `update idletasks` | source-assertion + load | `grep -nF 'for (i in seq_len(nSpecimens))' R/3dDigitize.main.r` | main.r | ⬜ pending |
| 12-04-T2 PLY load failure | 12-04 | 3 | UX-FB-02 | T-12-04, T-12-04-DoS | inline error + cursor restore | source-assertion + load | `grep -nF 'check the file and try again.' R/3dDigitize.main.r` | main.r | ⬜ pending |

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
