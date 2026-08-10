---
phase: 03-offline-packaging-and-lifecycle
verified: 2026-08-03T17:20:00Z
status: passed
uat_resolved: 2026-08-04T17:40:00Z # all 5 human_verification items passed on macOS — see 03-UAT.md
score: 15/15 must-haves verified (11 automated + 4 UAT-confirmed on macOS; Windows leg of items 2-3 owed as follow-up)
behavior_unverified: 1 # R session-end finalizer: registered + body unit-covered, but firing at q() is not exercisable in-process
overrides_applied: 0
behavior_unverified_items:
  - truth: "Quitting R runs the registered reg.finalizer(onexit=TRUE) and stops every live listener."
    test: "In a real (non-headless-blocked) R session: .gmw_serve_mesh(fixture); confirm a listener is live; then q('no'). Re-enter R and confirm no orphaned OS listener remains on the bound loopback port."
    expected: "The onexit finalizer fires at q() and .gmw_stop_token(NULL) tears down every live listener; no port stays bound after the session ends."
    why_human: "onexit=TRUE finalizers only fire on an actual session quit; the test runner cannot exercise q() in-process. Registration-once (D4) and the stop-all body it calls (D1/D2) are unit-covered, so only the q()-firing edge is unproven."
human_verification:
  - test: "R session-end finalizer firing at q() (see behavior_unverified_items)."
    expected: "Quitting R leaves no orphaned loopback listener."
    why_human: "onexit=TRUE cannot be exercised by the in-process test runner."
  - test: "Tab-close beacon end-to-end in a real browser (D-02). Open a viewport on offline stock macOS AND Windows, then close the browser tab."
    expected: "The page's navigator.sendBeacon('close') on pagehide/visibilitychange reaches /<token>/close and httpuv::listServers() empties for that token; gmw_close() then stops any remaining."
    why_human: "sendBeacon delivery on pagehide varies by browser (bfcache/mobile/background discards); only a real-browser tab close proves the wire path. The R /close handler + teardown and the JS hook are unit/source verified; the browser delivery is not."
  - test: "WEB-03 offline render UAT: on fully-offline stock macOS AND Windows (R --no-init-file), build the tarball, install OFFLINE (install.packages(repos=NULL, type='source', dependencies=FALSE)), open a viewport for each of the 6 reference specimens; also the ~30 MB B7_1_clean.ply worst case."
    expected: "Each specimen renders SHADED (not black), orbits, zooms, and r-resets; the ~30 MB worst case transfers and frames acceptably."
    why_human: "No CI on real Win/macOS display hosts; needs a human eye on the rendered viewport (D-10 verification-only)."
  - test: "WEB-03 offline-install smoke (automated, opt-in): on a display host with build tooling run GMW_RUN_OFFLINE_SMOKE=1 NOT_CRAN=true R --no-init-file -q -e 'testthat::test_local(\"integrated-guimorph-development_EOC/Project/GUImorphDevelopment\", filter=\"offline\")'."
    expected: "The block PASSES: offline install ships guimorphweb-three.js inside the installed package; specimen.ply serves 200 + byte-identical over loopback; the served page has zero external src=/href= http(s) refs."
    why_human: "The block is opt-in behind GMW_RUN_OFFLINE_SMOKE and SKIPS on this headless host because loading the installed namespace pulls geomorph->rgl/tcltk2 whose GUI init blocks with no display (STATE.md). Correct-by-construction; needs a display host + build tooling to move to pass."
  - test: "CMP-01 display-host load gate (owed from Phase 2): on a host with a display (R --no-init-file), library(GUImorphWeb); inspect GUImorphWeb:::.gmw_engine$ok."
    expected: "library() succeeds and .gmw_engine$ok is UNCHANGED by the Phase-3 lifecycle work (native tkogl2 oracle still loads where supported; FALSE-and-non-fatal on an unsupported host is expected, not a gate failure)."
    why_human: "tcltk2 GUI init blocks on a headless host; needs a display host. The static proof (transport.R never writes .gmw_engine; rtkogl.R byte-unchanged since Phase 1) is VERIFIED; only the live load is human."
---

# Phase 3: Offline Packaging and Lifecycle Verification Report

**Phase Goal:** Ship the JS inside the package and make server launch, browser open, and teardown reliable on a locked-down machine.
**Verified:** 2026-08-03T17:20:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| T1  | `gmw_close()` stops all live servers; `gmw_close(token)` stops exactly one, leaving other viewports live (D-03/D-04 token independence). | ✓ VERIFIED | `transport.R:267-296`; test "gmw_close(token) stops one, gmw_close() stops all" — **67/0/0 pass** via `test_dir(load_package="none")`. |
| T2  | After stop-all, both `ls(.gmw_server)` and `httpuv::listServers()` are empty (no orphan). | ✓ VERIFIED | `.gmw_stop_token` runs BOTH `stopServer()` and `rm()` each guarded (`transport.R:267-275`); test asserts both length 0 after `gmw_close()`. |
| T3  | `.onUnload()` stops every live listener on namespace unload/detach (D-01). | ✓ VERIFIED | `transport.R:309`; test ".onUnload stops all live servers" passes. |
| T4  | Session-end `reg.finalizer(onexit=TRUE)` registered lazily exactly once; flag in `.gmw_lifecycle`, never in the token registry. | ✓ VERIFIED | `transport.R:211-214`; test "the session-end finalizer registers exactly once" passes; `finalizer_registered` absent from `ls(.gmw_server)`. |
| T5  | Quitting R runs the finalizer and stops every live listener. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Registration + `.gmw_stop_token(NULL)` body are unit-covered (T2/T4), but `onexit=TRUE` firing at `q()` cannot be exercised in-process. → human. |
| T6  | `/<token>/close` returns 204 and schedules a stop of that token's own server only via `later`; non-close path → 404. | ✓ VERIFIED | `.gmw_close_handler` `transport.R:128-137`; test "/close handler returns 204 and schedules a stop of its own token" drains `later` and confirms teardown + 404. |
| T7  | The `/close` handler pattern-matches the request path and never joins it to the filesystem. | ✓ VERIFIED | `grepl("/close$", req$PATH_INFO)` only (`transport.R:131`); re-scoped guard test asserts no `PATH_INFO` line also calls `file.path`/`normalizePath`/`readBin`. |
| T8  | Occupied preferred port walks forward; exhaustion raises a clear error naming the tried range (start..49151) + omit hint — never a hang. | ✓ VERIFIED | `.gmw_pick_port` `transport.R:93-105`; test "port exhaustion raises a clear range-naming error" matches `40000`, `49151`, `omit`; walk-forward tests pass. |
| T9  | Viewport URL printed before any browser attempt; a failed/blocked browser does not error; firewall note fires once/session; `getOption("browser")` honored. | ✓ VERIFIED | `transport.R:219-237`; tests "launch prints the URL first and tolerates a failed browser" + "firewall note fires at most once" + "opens the loopback token URL" all pass. |
| T10 | The viewport page fires `navigator.sendBeacon("close")` on `pagehide` + `visibilitychange`→hidden (not `unload`), relative same-origin, no external ref. | ✓ VERIFIED (source) | `view3d.R:245-249`; beacon source-scan gate **9/0/0 pass** (present: sendBeacon/pagehide/visibilitychange; absent: unload listener, absolute http(s):// / src=/href=). Real-browser delivery → human. |
| T11 | A fully-offline source install (`repos=NULL, dependencies=FALSE`) ships the three.js bundle inside the installed package. | ⚠️ human (present + wired) | `test-offline-smoke.R:51-107` asserts `system.file(... guimorphweb-three.js)` non-empty; bundle confirmed present in source tree (807 KB). Opt-in, SKIPS headless → run on display host. |
| T12 | The installed package serves `specimen.ply` over loopback with 200 + byte-identical content. | ⚠️ human (mechanism verified) | Byte-identity serving is VERIFIED against the source tree (test "served PLY bytes are byte-identical to disk" passes); the installed-package offline variant is opt-in/human. |
| T13 | The served page carries zero external `src=`/`href=` http(s) references (offline by construction). | ✓ VERIFIED (source) | Beacon gate asserts no external ref in the added hook; offline test also asserts page has no `src="https?://"`/`href="https?://"`. |
| T14 | Lifecycle work never writes `.gmw_engine`; the CMP-01 oracle load path in `rtkogl.R` is untouched. | ✓ VERIFIED | `git log` shows `rtkogl.R` last touched in Phase 1 (`96247de`), no Phase-3 commit touches it; source scan finds no `.gmw_engine <-`/`.gmw_engine$` write in `transport.R`; test "lifecycle work never touches the tkogl2 engine state" passes. |
| T15 | On a display host, `library(GUImorphWeb)` loads and `.gmw_engine$ok` is unchanged by the lifecycle work (CMP-01). | ⚠️ human | Static proof VERIFIED (T14); live load blocked by headless `tcltk2` GUI init (STATE.md) → owed display-host gate. |

**Score:** 11/15 truths verified (T5 present, behavior-unverified; T11/T12/T15 routed to human).

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `R/transport.R` | `.gmw_lifecycle`, `.gmw_stop_token`, `gmw_close`, `.onUnload`, lazy `reg.finalizer(onexit=TRUE)`, `.gmw_close_handler`, mixed static+`/close` app, `port` arg, D-09 error, launch messaging | ✓ VERIFIED | All symbols present and wired; `excludeStaticPath` at `/<token>/close` (3 refs incl. doc); `stopAllServers` absent (T-3-03). |
| `NAMESPACE` | `export(gmw_close)` | ✓ VERIFIED | Line 4; roxygen2-equivalent output (roxygen2 absent locally — hand-matched, documented deviation). |
| `R/view3d.R` | `GMW_VIEW3D_TEMPLATE` pagehide/visibilitychange sendBeacon hook | ✓ VERIFIED | `view3d.R:245-249`, relative `"close"` target, no `unload` listener. |
| `tests/testthat/test-transport.R` | re-scoped guard + teardown + `/close` + port + launch + CMP-01 blocks | ✓ VERIFIED | 67 assertions pass, 0 skip. |
| `tests/testthat/test-view3d-beacon.R` | source-scan gate (new file) | ✓ VERIFIED | 9 assertions pass. |
| `tests/testthat/test-offline-smoke.R` | offline install + serve + byte-identity + no-external-refs + `# MANUAL UAT` header | ✓ VERIFIED (present, opt-in) | Skips cleanly headless behind `GMW_RUN_OFFLINE_SMOKE`; MANUAL UAT header present. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `.gmw_stop_token()` | `.gmw_server` registry | iterates `ls(.gmw_server)`, `stopServer()`+`rm()` each entry, never `stopAllServers()` | ✓ WIRED | Registry never lies (Pitfall 1); other packages' listeners untouched (T-3-03). |
| `reg.finalizer(onexit=TRUE)` | session end | only session-end hook; `.onUnload` covers unload | ✓ WIRED | Registration verified; q()-firing → human (T5). |
| `.gmw_close_handler(token)` | `.gmw_stop_token(token)` | `later::later(...,0.5)`, return 204 first (never synchronous) | ✓ WIRED | Test drains `later` and confirms own-token teardown (Pitfall 2). |
| `excludeStaticPath("/<token>/close")` | R `call` handler | mixed app; static byte mount byte-for-byte preserved | ✓ WIRED | `staticPath` present, `0.0.0.0` absent, static options unchanged (T-2-02). |
| page `sendBeacon("close")` | `/<token>/close` route | relative same-origin resolution | ✓ WIRED (source) | Same-origin relative target; real-browser delivery → human (D-02). |
| `port=NULL` | `.gmw_pick_port(prefer=port)` | no new selection logic | ✓ WIRED | `transport.R:183`. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| WEB-04 | 03-01, 03-02, 03-03 | Port selection, browser launch, and teardown reliable on a managed machine | ✓ SATISFIED (automated) / ? human (end-to-end) | T1–T10 automated-verified; end-to-end managed-machine UAT + q() finalizer are human. |
| WEB-03 | 03-04 | Clean offline `install.packages()` opens a working viewport on Win+macOS | ? NEEDS HUMAN | Automated smoke correct-by-construction but opt-in/skips headless; render UAT is human on display hosts. Bundle ships (verified in source tree). |
| CMP-01 | 03-01, 03-04 | Native `tkogl2` oracle stays loadable/functional | ✓ SATISFIED (static) / ? human (live load) | T14 verified (rtkogl.R untouched, no engine write); display-host `library()` load is human. |

All three declared requirement IDs (WEB-03, WEB-04, CMP-01) are accounted for. No orphaned requirements: REQUIREMENTS.md maps exactly these three IDs to Phase 3, and all three appear in plan frontmatter.

_Note (informational):_ REQUIREMENTS.md already flips WEB-04 and CMP-01 to `[x]` and the phase checkbox in ROADMAP.md is `[x]`, while the REQUIREMENTS.md Traceability table still reads "Not started" for the Phase-3 rows — a stale table, not a code gap. WEB-03 remains `[ ]` pending the human UAT.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | none | — | No `TBD`/`FIXME`/`XXX`/`HACK`/`PLACEHOLDER`/"not yet implemented" in any Phase-3 modified file. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Transport teardown/route/port/launch suite | `test_dir("tests/testthat", filter="transport", load_package="none")` | `FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 67` | ✓ PASS |
| Beacon source-scan gate | `test_dir(..., filter="beacon", load_package="none")` | `FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 9` | ✓ PASS |
| Offline-install smoke (opt-in) | `test_dir(..., filter="offline", load_package="none")` | `FAIL 0 \| SKIP 1 \| PASS 0` (clean skip at env gate) | ? SKIP (headless; opt-in — routes to human) |
| Full `test_local` suite | (documented pre-existing block) | hangs on `tcltk2`/`rgl` GUI init | ? SKIP (environmental, per STATE.md — not a phase failure) |

_The headless `test_local` hang is a documented pre-existing environmental block (STATE.md Open Items), not a Phase-3 regression. Source-scanning transport/beacon/offline tests are designed for `test_dir(load_package="none")` and pass green in isolation._

### Human Verification Required

1. **R session-end finalizer at `q()`** — serve, quit R, confirm no orphaned loopback listener remains. (`onexit=TRUE` not exercisable in-process; registration + body are unit-covered.)
2. **Real-browser tab-close beacon (D-02)** — close a viewport tab on offline macOS + Windows; confirm `httpuv::listServers()` empties for that token, then `gmw_close()` stops all remaining.
3. **WEB-03 offline render UAT** — fully-offline stock macOS + Windows, offline-installed tarball, 6 reference specimens render shaded/orbit/zoom/`r`-reset + ~30 MB `B7_1_clean.ply` worst case.
4. **WEB-03 offline-install smoke (automated, opt-in)** — run with `GMW_RUN_OFFLINE_SMOKE=1 NOT_CRAN=true` on a display host with build tooling; expect the block to PASS (bundle ships, serves byte-identical, no external refs).
5. **CMP-01 display-host load gate** — on a display host, `library(GUImorphWeb)` succeeds and `.gmw_engine$ok` is unchanged by the Phase-3 lifecycle work.

### Gaps Summary

No gaps. Every code artifact exists, is substantive, wired, and — for the automated portions — behaviorally proven (transport 67/0/0, beacon 9/0/0). The static CMP-01 proof holds (`rtkogl.R` byte-unchanged since Phase 1; `transport.R` never writes `.gmw_engine`). Teardown never orphans and never touches other packages' listeners (`stopAllServers` absent; both `stopServer`+`rm` run). The `/close` route defers via `later`, returns 204 first, and never joins the request path to the filesystem. Port exhaustion errors clearly rather than hanging. Browser launch prints the URL first and swallows a failed/blocked browser.

The phase is **not `passed`** solely because five behaviors intrinsically require a display host, a real browser, or an actual R quit to prove — exactly the end-of-phase human-check items the plans deferred (`human_verify_mode = end-of-phase`, D-10 verification-only). None is a code defect; all are documented UAT owed on offline Windows + macOS display hosts. Status is therefore `human_needed`.

---

_Verified: 2026-08-03T17:20:00Z_
_Verifier: Claude (gsd-verifier)_
