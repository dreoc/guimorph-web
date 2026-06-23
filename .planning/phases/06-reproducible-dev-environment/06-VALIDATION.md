---
phase: 6
slug: reproducible-dev-environment
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-19
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — manual Windows R UAT (human smoke) |
| **Config file** | none |
| **Quick run command** | Windows R: `renv::restore(); devtools::load_all(".")` from `GUImorphDevelopment/` |
| **Full suite command** | Full contributor path per BUILD.md: build → deploy → restore → `GUImorph()` → PLY load (+ GPA if R analysis change) |
| **Estimated runtime** | ~5–15 minutes (manual) |

---

## Sampling Rate

- **After every task commit:** Doc review + script dry-run (deploy path resolution); R-only tasks: `load_all` smoke on Windows R if available
- **After every plan wave:** Full BUILD.md walkthrough on Windows (build OR use existing DLL → deploy → restore → GUI)
- **Before `/gsd-verify-work`:** Clean-machine `renv::restore()` + GUI smoke documented in smoke-test-findings.md
- **Max feedback latency:** N/A (manual UAT)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | DEV-01 | — | N/A | manual | Windows R: `renv::restore()` then `nrow(installed.packages())` sanity | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | DEV-01 | — | N/A | doc review | Inspect root `BUILD.md` R Environment section | ❌ W0 | ⬜ pending |
| 06-02-01 | 02 | 2 | DEV-02 | — | N/A | manual UAT | Follow BUILD.md on clean Windows machine | ❌ W0 | ⬜ pending |
| 06-02-02 | 02 | 2 | DEV-03 | T-6-01 | Validate `$Src` exists; fail closed on missing build output | manual + script | `scripts/deploy-dll.ps1` then `load_all` + GUI | ❌ W0 | ⬜ pending |
| 06-02-03 | 02 | 2 | DEV-03 | T-6-01 | Backup before swap | script review | Verify `.bak` created when prior DLL exists | ❌ W0 | ⬜ pending |
| 06-02-04 | 02 | 2 | D-16 | — | N/A | manual UAT | `GUImorph()` + load `C13.1.ply` | ✅ | ⬜ pending |
| 06-03-01 | 03 | 3 | DEV-02 | — | N/A | doc review | README quick-start links to BUILD.md | ❌ W0 | ⬜ pending |
| 06-01-03 | 01 | 1 | D-20 | — | N/A | manual R | `warnings()` after restore + `load_all` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BUILD.md` (repo root) — integrated contributor doc for DEV-02
- [ ] `scripts/deploy-dll.ps1` — DEV-03 with backup (D-14)
- [ ] `GUImorphDevelopment/renv.lock` + scaffolding — DEV-01
- [ ] Warning capture runbook — append to `.planning/smoke-test-findings.md` after first restore baseline
- [ ] Windows-native build UAT note in BUILD.md — confirm MSYS2 path before marking primary

*Wave 0 artifacts are created by this phase's plans — no pre-existing test infrastructure.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| renv restore on clean Windows R | DEV-01 | Requires Windows R + GUI runtime | Install R 4.6+, clone repo, `renv::restore()` from package root |
| Full build-deploy-test cycle | DEV-02 | Native MinGW + Tcl/Tk GUI | Follow BUILD.md end-to-end on Windows |
| Post-deploy GUI smoke | DEV-03 / D-16 | OpenGL/WGL requires Windows desktop | `load_all` + `GUImorph()` + load sample PLY |
| Warning baseline capture | D-20 | Human triage HOT vs DEFERRED | Run `warnings()` after first restore + `load_all` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable for manual UAT
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
