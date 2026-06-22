---
phase: 8
slug: c-engine-deduplication
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-22
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None automated — manual Windows R GUI UAT (no Tk/OpenGL harness) |
| **Config file** | none |
| **Quick run command** | MSVC build of `tkogl2.dll` + deploy to `inst/libs/x64/` (see BUILD.md) |
| **Full suite command** | Manual Windows R GUI smoke: landmark + anchor place/select/move/delete + `.dgt` round-trip |
| **Estimated runtime** | ~build minutes + manual UAT |

---

## Sampling Rate

- **After every task commit:** MSVC compile must succeed (no warnings/errors regressions)
- **After every plan wave:** Build + deploy DLL; smoke landmark placement still works
- **Before `/gsd-verify-work`:** Full manual UAT (D-10) green + `.dgt` round-trip (D-11)
- **Max feedback latency:** one build+deploy cycle

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-XX-XX | 0X | X | CENG-02 | — | N/A (internal C refactor) | manual + build | MSVC build | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Note: no automated test framework exists for the Tk/OpenGL C engine; verification is build-success + manual GUI UAT. The planner should map each plan to the manual UAT step it is validated by.*

---

## Wave 0 Requirements

- [ ] Confirm MSVC toolchain available (MinGW renders black mesh — unsupported per STATE.md)
- [ ] Capture pre-Phase-8 DLL backup for side-by-side comparison (D-13)

*No automated test framework to install — existing manual UAT harness covers phase behaviors.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Landmark place/select/move/delete unchanged | CENG-02 (D-04) | No automated Tk/OpenGL harness | Windows R GUI: place landmarks, select, move, delete; compare to pre-Phase-8 DLL |
| Anchor place/select/move/delete now correct | CENG-02 (D-03, D-10) | Behavior change to anchors; no harness | Windows R GUI: place anchor, select it, move it, delete it — confirm each acts on anchor's own state |
| `.dgt` round-trip with anchor persistence | CENG-02 (D-11) | File I/O + GUI; no harness | Load PLY → landmarks + curve + anchor → save → same-session `openDgt` reload; confirm anchor reloads |

---

## Validation Sign-Off

- [ ] Each plan maps to its manual UAT verification step
- [ ] Anchor-specific UAT (place+select+move+delete) is explicitly required (D-10)
- [ ] `.dgt` anchor-persistence check included (D-11 — confirmed viable: anchors ARE serialized)
- [ ] Pre-Phase-8 DLL backup captured (D-13)
- [ ] UAT results documented in `.planning/smoke-test-findings.md` (D-12)
- [ ] `nyquist_compliant: true` set once the per-task map is finalized

**Approval:** pending
