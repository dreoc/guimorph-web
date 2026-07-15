---
phase: 1
slug: aqua-tk-deployment-gate-windows-rendering-seam
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-12
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None (no testthat/pytest/jest exists — VERIFIED CONCERNS.md). Phase-1 checks are: a static grep gate (RND-01), a scriptable `Rscript` assert (GATE-01), and manual/off-box eyeball renders (CMP-01). The committed `gate_check.R` is the one durable automated artifact (D-03). |
| **Config file** | none |
| **Quick run command** | `grep -REn 'HDC\|HGLRC\|SwapBuffers\|wgl' integrated-guimorph-development_EOC/Project/tkogl2/src/ \| grep -v 'gfx_backend_wgl.c'` (must be empty) |
| **Full suite command** | `Rscript integrated-guimorph-development_EOC/Project/tkogl2/test/gate/gate_check.R <gateext.dylib>` (command-line R only) |
| **Estimated runtime** | grep gate < 2s; gate assert < 10s |

---

## Sampling Rate

- **After every task commit:** Run the RND-01 grep gate (fast; catches incomplete seam extraction).
- **After every plan wave:** Run the trivial-extension load assert (`gate_check.R`) once Aqua Tk is set up (GATE-01).
- **Before `/gsd-verify-work`:** Grep gate empty + `gate_check.R` green + GATE-02 doc present.
- **Phase gate:** manual Windows MSVC render (CMP-01, off-box) returns "identical" + command-line R returns `aqua`.
- **Max feedback latency:** ~10 seconds for the on-box automated checks (CMP-01 is off-box, asynchronous).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | RND-01 | T-01-01 | Opaque seam; no Win32 types in neutral header | static | `test -f .../src/gfx_backend.h && grep -Eq 'gfx_create\|gfx_make_current\|gfx_swap\|gfx_resize\|gfx_destroy' .../gfx_backend.h && ! grep -Eq 'windows\.h\|def_ZARF_9\.h' .../gfx_backend.h` | ✅ (created in task) | ⬜ pending |
| 01-01-02 | 01 | 1 | RND-01 | T-01-01 | No platform token leaks into core (incl. comments) | static | `test -z "$(grep -REn 'HDC\|HGLRC\|SwapBuffers\|wgl' .../src/ \| grep -v 'gfx_backend_wgl.c')"` | ✅ (grep gate) | ⬜ pending |
| 01-02-01 | 02 | 1 | GATE-01 | T-02-02 | Command-line R only; no untrusted parse | smoke | `Rscript -e 'library(tcltk); stopifnot(tclvalue(.Tcl("tk windowingsystem"))=="aqua")'` | ✅ (needs Aqua setup) | ⬜ pending |
| 01-02-02 | 02 | 1 | GATE-01 | T-02-01 | Tk_InitStubs linked; single tk-winsys query only | smoke | `Rscript .../test/gate/gate_check.R <dylib>` (asserts `gate_winsys=="aqua"`) | ✅ (created in task) | ⬜ pending |
| 01-03-01 | 03 | 2 | GATE-02 | T-03-02 | Decision grounded in spike, not preference | manual (decision) | (checkpoint:decision — human selects d01/d02) | n/a | ⬜ pending |
| 01-03-02 | 03 | 2 | GATE-02 | T-03-01 | First-party sources only | static | `test -f .../docs/AQUA-TK-SETUP.md && grep -qi 'aqua' ... && grep -q 'gate_check.R' ...` | ✅ (created in task) | ⬜ pending |
| 01-04-01 | 04 | 2 | CMP-01 | T-04-02 | Loader-compatible fixture; parser untouched | static | `test -f .../test/fixtures/regression.ply && head -1 ... \| grep -qi '^ply'` | ✅ (created in task) | ⬜ pending |
| 01-04-02 | 04 | 2 | CMP-01 | T-04-01 | Rebuild DLL from source (no drift) | manual (off-box) | MISSING — off-box Windows MSVC build + eyeball render (D-06); not runnable on macOS | ❌ off-box | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

The Phase-1 validation artifacts are the phase deliverables themselves (created inline within the plans, not a separate Wave 0 plan):

- [x] Trivial Aqua-Tk C extension `gate_ext.c` (D-03) — created in Plan 02 Task 2 (covers GATE-01)
- [x] Scriptable gate assert `gate_check.R` (`Rscript`) — created in Plan 02 (automates GATE-01)
- [x] Static grep seam-completeness gate — shell one-liner, no scaffold needed (automates RND-01 boundary)
- [x] Committed small PLY fixture `test/fixtures/regression.ply` — created in Plan 04 Task 1 (none existed before)
- [x] GATE-02 setup doc `docs/AQUA-TK-SETUP.md` — created in Plan 03 Task 2

*No general test framework is introduced this phase; the trivial extension + gate_check.R is the one durable automated artifact (D-03 intent).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| MSVC `tkogl2.dll` builds + renders PLY identically | CMP-01 | Off-box: no MSVC/Windows R on this macOS dev machine; D-06 is an eyeball check with no pixel-compare infra this phase | Windows maintainer: rebuild DLL from post-seam source (BUILD.md §2), redeploy to `inst/libs/x64/`, `GUImorph()` → load `test/fixtures/regression.ply` → confirm non-blank identical render |
| Distribution path decision (D-01 vs D-02) | GATE-02 | Requires a human judgment call grounded in the spike's package-local feasibility finding | Review 01-02-SUMMARY; select `d01-bundled` or `d02-homebrew` with rationale |
| Aqua-Tk spike reachability (rebuild base tcltk) | GATE-01 | Requires a real Mac with command-line R + Aqua Tcl/Tk (installable via Homebrew/CRAN) | Run RESEARCH §Bundling Spike steps 1–2; confirm `aqua` + `otool -L` shows no libX11 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or a declared manual/off-box `<human-check>` (CMP-01 render + decision checkpoint are the only manual items)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (grep gate + gate_check.R cover both waves on-box)
- [x] Wave 0 covers all MISSING references (all artifacts created inline in plans)
- [x] No watch-mode flags
- [x] Feedback latency < 10s for on-box checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-12
