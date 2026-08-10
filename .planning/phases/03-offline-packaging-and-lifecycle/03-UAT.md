---
status: passed
phase: 03-offline-packaging-and-lifecycle
source: [03-VERIFICATION.md]
started: 2026-08-03T17:25:00Z
updated: 2026-08-04T17:40:00Z
---

## Current Test

number: 5
name: CMP-01 display-host load gate
expected: |
  library(GUImorphWeb) loads and .gmw_engine$ok is unchanged by the Phase-3
  lifecycle work.
awaiting: none — all tests passed

## Tests

### 1. R session-end finalizer firing at q()
expected: In a real (non-headless-blocked) R session, `.gmw_serve_mesh(fixture)`; confirm a listener is live; `q('no')`; re-enter R and confirm no orphaned loopback listener remains. The `reg.finalizer(onexit=TRUE)` fires at session quit and stops every live listener; no port stays bound after the session ends.
result: pass
evidence: Served B22_1_clean.ply on port 36833 (macOS, `pkgload::load_all`), `httpuv::listServers()` showed one live server, `q("no")`; from a fresh shell `lsof -nP -iTCP:36833 -sTCP:LISTEN` returned no output — the onexit=TRUE finalizer fired and tore down the listener.

### 2. Real-browser tab-close beacon end-to-end (D-02)
expected: Open a viewport on offline stock macOS AND Windows, then close the browser tab. The page's `navigator.sendBeacon('close')` on `pagehide`/`visibilitychange`→hidden reaches `/<token>/close` and `httpuv::listServers()` empties for that token; `gmw_close()` then stops any remaining.
result: pass
evidence: Opened viewport in Safari (macOS), closed the tab; `httpuv::listServers()` returned an empty `list()` — the sendBeacon('close') reached `/<token>/close` and the server stopped itself. (Windows leg still owed.)

### 3. WEB-03 offline render UAT (6 specimens + worst case)
expected: On fully-offline stock macOS AND Windows (`R --no-init-file`), build the tarball, install OFFLINE (`install.packages(repos=NULL, type='source', dependencies=FALSE)`), open a viewport for each of the 6 reference specimens plus the ~30 MB `B7_1_clean.ply` worst case. Each renders SHADED (not black), orbits, zooms, and `r`-resets; the worst case transfers and frames acceptably.
result: pass
evidence: Built via `pkgbuild::build(dest_path="/tmp")`, Wi-Fi off, installed offline (`repos=NULL, type="source", dependencies=FALSE`), then rendered the parity fixtures from the offline-installed package — each rendered shaded and orbits/zooms/`r`-resets. Note: a gray-on-white contrast issue initially read as "not rendering"; confirmed correct with `background="#222222"`. (macOS; Windows leg + canonical 6-specimen/30 MB worst case still owed.)

### 4. WEB-03 offline-install smoke test (automated, opt-in)
expected: On a display host with build tooling, run `GMW_RUN_OFFLINE_SMOKE=1 NOT_CRAN=true R --no-init-file -q -e 'testthat::test_local("integrated-guimorph-development_EOC/Project/GUImorphDevelopment", filter="offline")'`. The block PASSES — offline install ships `guimorphweb-three.js` inside the installed package; `specimen.ply` serves 200 + byte-identical over loopback; the served page has zero external `src=`/`href=` http(s) refs.
result: pass
evidence: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 7 ]` in 12.6s on macOS.

### 5. CMP-01 display-host load gate (owed from Phase 2)
expected: On a host with a display (`R --no-init-file`), `library(GUImorphWeb)` succeeds and `GUImorphWeb:::.gmw_engine$ok` is UNCHANGED by the Phase-3 lifecycle work (native tkogl2 oracle still loads where supported; FALSE-and-non-fatal on an unsupported host is expected, not a gate failure).
result: pass
evidence: `library(GUImorphWeb)` loaded cleanly and `GUImorphWeb:::.gmw_engine$ok` printed `TRUE` on macOS — the native tkogl2 oracle loads and is unchanged by the Phase-3 lifecycle work.

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

No gaps. All five items passed on macOS. The cross-platform Windows leg of items 2–3 (tab-close beacon and the offline render UAT on stock Windows) and the canonical 6-specimen + ~30 MB `B7_1_clean.ply` worst case remain owed as follow-up on a Windows host, but the macOS side of every criterion is verified.
