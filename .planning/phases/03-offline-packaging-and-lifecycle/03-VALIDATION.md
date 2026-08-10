---
phase: 3
slug: offline-packaging-and-lifecycle
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-03
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | testthat 3.x (Suggests); `tests/testthat.R` → `test_check("GUImorphWeb")` |
| **Config file** | `tests/testthat.R`; source-tree tests guard with `skip_if_no_pkg_source()` / `skip_if_no_curl()` |
| **Quick run command** | `R --no-init-file -q -e 'testthat::test_local("integrated-guimorph-development_EOC/Project/GUImorphDevelopment", filter="transport")'` |
| **Full suite command** | `R --no-init-file -q -e 'testthat::test_local("integrated-guimorph-development_EOC/Project/GUImorphDevelopment")'` (or `R CMD check`) |
| **Estimated runtime** | ~10–20 s quick (transport); the `offline` smoke test is slower (tarball build + install) and skips without build tooling |

> Use `--no-init-file`: STATE.md notes a site-library `renv` makes bare `R`/`Rscript` hang on startup under a restricted network.

---

## Sampling Rate

- **After every task commit:** Run the quick command (`filter="transport"`; use `filter="beacon"` for plan 03, `filter="offline"` for plan 04 task 1).
- **After every plan wave:** Run the full suite command.
- **Before `/gsd-verify-work`:** Full suite green (modulo the known pre-existing reds below) + WEB-03/CMP-01 manual UAT signed off.
- **Max feedback latency:** ~20 seconds (quick); minutes for the offline smoke test.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | WEB-04, CMP-01 | T-3-03 / T-3-04 | Teardown iterates `.gmw_server` only (no `stopAllServers`); both `stopServer`+`rm` run | unit (source-scan) | `...test_local(filter="transport")` | ✅ (extends) | ⬜ pending |
| 03-01-02 | 01 | 1 | WEB-04, CMP-01 | T-3-04 / — | `gmw_close` empties registry + `listServers()`; lifecycle never writes `.gmw_engine` | unit | `...test_local(filter="transport")` | ❌ W0 (new blocks) | ⬜ pending |
| 03-02-01 | 02 | 2 | WEB-04 | T-3-01 / T-3-02 | `/close` pattern-matches only, defers stop via `later`; no fs-join from request path | unit (direct closure, synthetic req) | `...test_local(filter="transport")` | ❌ W0 (new block) | ⬜ pending |
| 03-02-02 | 02 | 2 | WEB-04 | T-3-06 / — | Port exhaustion → clear `stop()` naming range, never a hang | unit (injected probe) | `...test_local(filter="transport")` | ⚠️ extend existing port test | ⬜ pending |
| 03-02-03 | 02 | 2 | WEB-04 | T-3-05 / — | URL printed first; failed/blocked browser does not error; `getOption("browser")` honored | unit (`expect_message`, browser override) | `...test_local(filter="transport")` | ⚠️ extend existing open test | ⬜ pending |
| 03-03-01 | 03 | 1 | WEB-04 | T-3-07 / T-3-02 | Beacon target relative same-origin `"close"`; `pagehide` not `unload`; no external ref | unit (source-scan) | `...test_local(filter="beacon")` | ❌ W0 (new file) | ⬜ pending |
| 03-03-02 | 03 | 1 | WEB-04 | T-3-07 / — | Source gate asserts beacon tokens present, no `"unload"`, no absolute URL | unit (source-scan) | `...test_local(filter="beacon")` | ❌ W0 (new file) | ⬜ pending |
| 03-04-01 | 04 | 3 | WEB-03 | T-3-07 / T-3-08 | Offline install (`repos=NULL, dependencies=FALSE`) ships+serves bundle; page has no external refs | integration | `...test_local(filter="offline")` | ❌ W0 (new file) | ⬜ pending |
| 03-04-02 | 04 | 3 | WEB-03, CMP-01 | T-3-07 / — | 6-specimen render/orbit + 30 MB worst case; `library()` load + `.gmw_engine$ok` unchanged | manual-only | UAT (human-check) | ❌ (carries Phase-2 owed UAT) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Re-scope the `PATH_INFO` guard assertion in `test-transport.R` (Pitfall 3) **before** plan 02 adds the `/close` handler — done in plan 01 task 2.
- [ ] New teardown blocks in `test-transport.R` (`gmw_close` one/all with `listServers()==0`, `.onUnload`, finalizer-once) + CMP-01 engine-untouched guard — plan 01 task 2.
- [ ] New `/close` direct-closure block (synthetic `req`, never same-process `curl` — Pitfall 5) in `test-transport.R` — plan 02 task 1.
- [ ] New `tests/testthat/test-view3d-beacon.R` (source-scan gate) — plan 03 task 2.
- [x] New `tests/testthat/test-offline-smoke.R` (offline install + serve + byte-identity + no-external-refs; filter `offline`) — plan 04 task 1. Gated behind `GMW_RUN_OFFLINE_SMOKE` so a headless `test_local` skips cleanly instead of blocking on the installed package's `tcltk2`/`rgl` GUI-init load.
- [ ] Optional: `callr`/`processx` (Suggests) only if an out-of-process `/close` socket test is later chosen — NOT needed (direct-closure unit test is the recommended path).

**Existing infrastructure reused:** `helper-transport.R` (`serve_tmp`, `teardown_server`, `gmw_probe_stub`, `gmw_try_fetch`, `gmw_url_token`, `skip_if_no_curl`) and `helper-pkg-source.R` (`skip_if_no_pkg_source`, `pkg_source_root`) are auto-sourced and cover fixtures/skips for all new blocks.

**Known pre-existing reds (STATE.md — do NOT let them mask new failures):** 2 tests call functions deleted in `2f65039`; 4 stub `tcltk` via `assignInNamespace` (disallowed on R 4.6). Confirmed unrelated to browser/lifecycle work. They fall outside the `transport`/`beacon`/`offline` filters, so the per-task quick runs stay clean; at the phase gate, treat these 6 as a documented carve-out (skip/quarantine is optional and not this phase's job).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 6 reference specimens render shaded (not black), orbit, zoom, `r`-reset on offline stock macOS AND offline stock Windows; worst-case `B7_1_clean.ply` (~30 MB, 363,283 verts) transfers and frames acceptably; tab-close beacon stops the server | WEB-03 | No CI on real Win/macOS display hosts; needs a human eye on the rendered viewport (D-10 verification-only) | On each OS, fully offline, R started with `--no-init-file` (STATE.md: a site-library `renv` hangs bare R startup): (1) build the tarball (`R CMD build .`/`pkgbuild::build()`); (2) install OFFLINE with network physically off — `install.packages(<tarball>, repos=NULL, type="source", dependencies=FALSE)`; (3) open a viewport for EACH of the 6 reference specimens and confirm shaded render (not black) + orbit/zoom/`r`-reset; (4) load `B7_1_clean.ply` (~30 MB) and confirm acceptable framing (the fast automated smoke uses the ~0.77 MB `B12_1_clean.ply` and skips this worst case); (5) close the browser tab and confirm `httpuv::listServers()` empties for that token, then `gmw_close()` stops all remaining. Mirrored verbatim in the `# MANUAL UAT` header of `tests/testthat/test-offline-smoke.R` |
| Tab-close beacon stops that token's server; `gmw_close()` stops all | WEB-04 | Requires a real browser tab-close event (`pagehide`); the automated `/close` test is direct-closure only (Pitfall 5) | Open a viewport, close the tab, confirm `httpuv::listServers()` empties for that token; open several, call `gmw_close()`, confirm all stop |
| `library(GUImorphWeb)` loads and `.gmw_engine$ok` is unchanged by the lifecycle work | CMP-01 | The `tcltk2` GUI init blocks headless; needs a display host (owed from Phase 2) | On a display host, R started with `--no-init-file`: `library(GUImorphWeb)` succeeds; `GUImorphWeb:::.gmw_engine$ok` is unchanged by the Phase-3 lifecycle work (native `tkogl2` oracle still loads where supported; FALSE-and-non-fatal on an unsupported host is expected, not a gate failure). Mirrored in the `# MANUAL UAT` header (Step B) of `tests/testthat/test-offline-smoke.R` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or a Wave 0 dependency (manual-only tasks use `<human-check>` per `human_verify_mode=end-of-phase`)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every code task has a `transport`/`beacon`/`offline` automated command)
- [x] Wave 0 covers all MISSING references (guard re-scope + 4 new test blocks/files)
- [x] No watch-mode flags
- [x] Feedback latency < 20s (quick run)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
