---
phase: 7
slug: c-engine-modularization
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-19
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual Windows R GUI UAT (primary); no C unit-test runner in CI |
| **Config file** | none — `.planning/smoke-test-findings.md` is evidence log |
| **Quick run command** | `cmake --build build -j` then per-plan smoke: export grep → `GUImorph()` → PLY → double-click landmark |
| **Full suite command** | Final smoke (07-03): full digitize round-trip on `test_fresh.dgt` + append findings |
| **Estimated runtime** | ~5–15 minutes per manual UAT session |

---

## Sampling Rate

- **After every task commit:** Run `cmake --build build -j` (compile gate)
- **After every plan wave:** Export verify + per-plan smoke UAT (D-05)
- **Before `/gsd-verify-work`:** Final digitize round-trip (D-06) + `smoke-test-findings.md` append (D-07)
- **Max feedback latency:** Manual UAT — same session as plan completion

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-* | 07-01 | 1 | CENG-01 | T-07-01 / — | Preserve Tcl input validation macros | manual | `cmake --build build && objdump -p build/tkogl2.dll \| grep Tkogl2_Init` | ❌ W0 | ⬜ pending |
| 07-02-* | 07-02 | 2 | CENG-01 | — | N/A | manual | Per-plan smoke: PLY load + double-click landmark | ✅ Phase 4 baseline | ⬜ pending |
| 07-03-* | 07-03 | 3 | CENG-01 | T-07-02 / — | DLL deploy to trusted path only | manual | Full digitize round-trip on `test_fresh.dgt` | ✅ Phase 4 workflow | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Pre-Phase-7 DLL backup to tagged path (D-08) — before first extraction
- [ ] Confirm Phase 6 complete (renv + BUILD + deploy) — hard gate per ROADMAP dependency
- [ ] Export verify command documented in each plan SUMMARY

*No automated C test framework — intentional per project convention.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| God file split; no behavior change | CENG-01 | No Tk/OpenGL test harness | Build DLL, verify `Tkogl2_Init` export, launch `GUImorph()`, load `C13.1.ply` |
| Landmark placement | CENG-01 | GUI interaction required | Double-click landmark on canvas after each plan |
| Full digitize round-trip | CENG-01 | Multi-step GUI workflow | Landmarks + curve + save `.dgt` + `openDgt` reload (07-03 only) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: compile gate after every task commit
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Manual UAT checklist in each PLAN.md
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
