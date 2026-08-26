---
phase: 6
slug: shell-and-native-retirement
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-13
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `testthat` (3e); `tests/testthat.R` + `tests/testthat/*` |
| **Config file** | `DESCRIPTION` `Suggests: testthat`; `tests/testthat/helper-*.R` |
| **Quick run command** | `devtools::test(filter = "<name>")` (e.g. `filter = "transport"`) |
| **Full suite command** | `devtools::test()` (or `R CMD check`) |
| **Estimated runtime** | ~30–90 seconds (suite); minutes for `R CMD check` |

---

## Sampling Rate

- **After every task commit:** Run `devtools::test(filter = "<touched area>")`
- **After every plan wave:** Run `devtools::test()` (full suite)
- **Before `/gsd-verify-work`:** Full suite green + `R CMD check` clean of `tcltk`/`tcltk2`/`rgl`
- **Max feedback latency:** ~90 seconds (filtered runs are faster)

---

## Per-Task Verification Map

| Task | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Rewrite engine-presence assertion | 0 | UI-02 | — | N/A | unit | `devtools::test(filter="transport")` | ✅ rewrite `test-transport.R` :121–133 | ⬜ pending |
| Source-scan: deps free of tcltk/tcltk2/rgl/loadDgt; no `inst/libs/tkogl2*` | 0 | UI-03 | — | N/A | source-scan | new test reading DESCRIPTION/NAMESPACE/inst | ❌ W0 | ⬜ pending |
| Source-scan: no engine-verb call sites (`add`/`set`/`del`/`shows`), no `.gmw_engine`/`.gmw_require_engine` | 0 | UI-02 | — | N/A | source-scan | new grep-style source test | ❌ W0 | ⬜ pending |
| `NEWS.md` present with 1.0.0 header + pin 0.10.0 + GUImorph link | 0 | UI-03 | — | N/A | source-scan | new test | ❌ W0 | ⬜ pending |
| New shell routes (`/files`, `/open`, tab/status) parse + dispatch; picker validates selection | 1 | UI-01 | T-6-V5 / T-6-V12 | Selection validated against R-enumerated list; no `file.path(dir, untrusted)` | unit | `devtools::test(filter="transport")` (extend) | ⚠️ extend | ⬜ pending |
| `/open` path-traversal rejection (`..`, absolute, non-member) | 1 | UI-01 | T-6-V12 | Reject out-of-set / traversal paths; loopback-bound only | unit | `devtools::test(filter="transport")` | ⚠️ extend | ⬜ pending |
| Template still splits at `MESH_URL` marker under 8192 cap after tabs/menu added | 1 | UI-01 | — | N/A | unit | `devtools::test(filter="view3d")` | ✅ extend | ⬜ pending |
| Specimen nav RE-SERVE unchanged (A4) | 1 | UI-01 | — | N/A | unit | `devtools::test(filter="digitizing-session")` | ✅ audit | ⬜ pending |
| Package loads + digitize→GPA→save workflow runs with `inst/libs/` and `.onLoad` gone | 2 | UI-02 | — | N/A | integration | new test: assert no `.gmw_engine`/`.onLoad` tcl-load; workflow via routes | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Rewrite `test-transport.R` :121–133 to assert engine **absence** (was: presence).
- [ ] New source-scan test: `DESCRIPTION`/`NAMESPACE` free of `tcltk`/`tcltk2`/`rgl`/`loadDgt`; no `inst/libs/tkogl2*`.
- [ ] New source-scan test: no `add(`/`set(`/`del(`/`shows(` engine-verb call sites; no `.gmw_engine`/`.gmw_require_engine`.
- [ ] New test: `NEWS.md` present with required migration content (1.0.0 header, pin `0.10.0`, GUImorph link).
- [ ] Extend `test-transport.R` for new shell routes (`/files`, `/open`, path-traversal rejection).
- [ ] Retire `test-picking-parity.R`, `test-retina-picking-parity.R`; skip/rewrite the `-rewrite` gate in `test-dgt-cross-platform.R` (D-04) with a documented won't-verify note.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser shell feature parity with Tk chrome (tabs, dialogs, specimen nav, status bar) | UI-01 | Visual/interaction parity across a live browser session cannot be fully asserted headlessly | Launch `GUImorphWeb()`, exercise each tab/menu/dialog/file-open/color-pick/status readout; confirm parity with the retired Tk arrangement |
| Full workflow with the native engine physically uninstalled from the library path | UI-02 | Requires an environment where `tkogl2`/`rgl`/`tcltk` are absent from the R library | Load package in a clean lib without those packages; run PLY load → landmarks → curves → surfaces → GPA → export end-to-end |
| PICK-03 milestone gate + DAT-02 `-rewrite` byte gate | (D-04) | **Won't-verify** — the only oracle (`tkogl2` on Windows) is deleted here and no Windows host was ever available | Documented as a closed limitation; harness was complete and drop-in-ready — the gap is host availability, not code |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-08-13
