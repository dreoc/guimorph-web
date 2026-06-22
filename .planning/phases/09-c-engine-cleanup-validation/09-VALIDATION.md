---
phase: 9
slug: c-engine-cleanup-validation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-22
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **No automated test framework exists** for the Tk/OpenGL GUI (QA-01 deferred to v2). Validation is
> manual Windows MSVC GUI UAT (D-11/D-12). The "sampling rate" below maps to build/deploy smoke checks
> plus the full manual round-trip recorded in `.planning/smoke-test-findings.md`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — manual Windows R GUI UAT (no Tk/OpenGL harness) |
| **Config file** | none |
| **Quick run command** | MSVC build (`cmake --build build-msvc --config Release`) → deploy DLL → `devtools::load_all(".")` + `GUImorph()` smoke |
| **Full suite command** | Full round-trip UAT × 2 fixtures (`test_fresh.dgt`, `test_dgt_anchors_curves.dgt`) incl. GPA |
| **Estimated runtime** | ~10–20 min manual per full pass |

---

## Sampling Rate

- **After every code-change task commit:** MSVC build must stay green; `Tkogl2_Init` still exported; no new warnings vs Phase 8 baseline.
- **After globals refactor (CENG-03) and after debug-removal (CENG-04):** deploy DLL → `load_all` + `GUImorph()` smoke (window opens, PLY renders, single landmark places).
- **Before `/gsd-verify-work`:** full round-trip UAT (both fixtures) green and recorded in `smoke-test-findings.md`.
- **Max feedback latency:** build/export check seconds; smoke ~2 min; full UAT one manual pass.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-xx | 01 | 1 | CENG-03 | — | N/A (internal cleanup) | build + manual | MSVC build green; `Tkogl2_Init` exported; capacity `#define`s present in `tcl_state.h` | ❌ W0 (manual) | ⬜ pending |
| 09-02-xx | 02 | 2 | CENG-04 | — | Must not weaken `.dgt`/`.ply` parse guards (V5) while deleting nearby `printf` | build + manual | MSVC build green; bare `printf(` count → 0 live trace; load-bearing diagnostics on `simpleLog` | ❌ W0 (manual) | ⬜ pending |
| 09-03-xx | 03 | 3 | CENG-05 | — | N/A | manual UAT | Full round-trip × 2 fixtures matches Phase 4–5 / Phase 8 baseline | ❌ W0 (manual) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- No automated framework to install — QA-01 (smoke-test harness) is explicitly deferred to v2.
- **Existing infrastructure for this phase is the manual UAT pattern** carried forward from Phases 4/5/7/8, recorded in `.planning/smoke-test-findings.md`.
- Pre-UAT gate (D-15): back up the deployed DLL to `inst/libs/x64/tkogl2.dll.pre-phase9.bak` before any refactor so cleanup is rollback-able.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Numbered globals replaced with capacity-`#define`d arrays; same effective count/indexing | CENG-03 | No unit harness; correctness proven by behavior parity in UAT + header inspection | Inspect `tcl_state.h` for capacity `#define`s (`GBL_PTR_MODEL`→5, `GBL_PTR_CONTEXT`→5, `GBL_PTR_CURVE`→6); MSVC build green; `snapshot()` + curve-logging behavior unchanged in UAT |
| Trace `printf` removed; load-bearing diagnostics routed through `tcl_log.c`/`simpleLog`; `MAKE_INERT`/`if(0)` dead blocks deleted | CENG-04 | No harness; D-05 reload-path caution requires manual confirmation | After removal, deploy + reload both fixtures; **`Surface=0` does not abort `openDgt` reload** (D-05 critical). Verify `ERROR: TAG_*` diagnostics still emit via `simpleLog` |
| Fixture A full round-trip: load PLY → place landmarks → curve bind → save → reload → GPA Compute → save CSV | CENG-05 | Tk/OpenGL GUI; no automated render/event harness | Run sampling plan Fixture A table in `09-RESEARCH.md`; every assertion matches Phase 4–5 baseline |
| Fixture B round-trip: load `.dgt` → anchor + landmark place/select/move/delete → re-save → reload | CENG-05 | Exercises Phase 8 dedup'd marker path; manual GUI only | Run sampling plan Fixture B table in `09-RESEARCH.md`; parity with Phase 8 baseline |

*Record both fixture result tables in `.planning/smoke-test-findings.md` with date, DLL freshness banner, and rollback DLL name (`.pre-phase9.bak`). Rollback on failure: `Copy-Item inst/libs/x64/tkogl2.dll.pre-phase9.bak inst/libs/x64/tkogl2.dll`.*

---

## Validation Sign-Off

- [ ] All tasks have a build/export check or a manual UAT instruction (no automated framework available)
- [ ] Sampling continuity: build stays green after every code-change commit; smoke after each requirement
- [ ] Wave 0 covers backup (D-15) and confirms manual-UAT-only posture
- [ ] No watch-mode flags (n/a — no test runner)
- [ ] Full round-trip × 2 fixtures recorded in `smoke-test-findings.md` before phase close
- [ ] `nyquist_compliant: true` set once the manual sampling plan is fully mapped to plan tasks

**Approval:** pending
