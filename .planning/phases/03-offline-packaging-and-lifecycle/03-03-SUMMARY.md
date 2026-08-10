---
phase: 03-offline-packaging-and-lifecycle
plan: 03
subsystem: ui
tags: [three.js, sendBeacon, pagehide, visibilitychange, httpuv, lifecycle, testthat]

# Dependency graph
requires:
  - phase: 02-transport-and-mesh-display
    provides: "GMW_VIEW3D_TEMPLATE viewport page served over loopback httpuv at http://127.0.0.1:PORT/<token>/"
  - phase: 03-offline-packaging-and-lifecycle
    provides: "plan 02 /<token>/close route + .gmw_stop_token teardown that the beacon triggers"
provides:
  - "Page-side (browser) half of the D-02 tab-close teardown: navigator.sendBeacon('close') on pagehide + visibilitychange->hidden"
  - "Dedicated source-scan test gating the beacon hook (own file, parallel-safe)"
affects: [03-04-offline-smoke, offline-packaging, teardown]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Relative same-origin sendBeacon target ('close') so no absolute URL / external reference is introduced (WEB-03)"
    - "pagehide + visibilitychange->hidden as the reliable unload-time event pair (never the deprecated unload event)"
    - "Dedicated per-hook source-scan test file to avoid contention with transport-plan edits (parallel-safe)"

key-files:
  created:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-view3d-beacon.R"
  modified:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R"

key-decisions:
  - "Beacon target is the relative string 'close' (resolves same-origin to .../<token>/close), never an absolute http(s):// URL — preserves WEB-03 offline-by-construction."
  - "Used pagehide with a visibilitychange->hidden backstop instead of the deprecated/unreliable unload event (Pitfall 4)."
  - "Kept the beacon test in its own file (test-view3d-beacon.R) so it never overlaps the transport plans' edits to test-transport.R."

patterns-established:
  - "Page tab-close beacon: gmwClose() wraps navigator.sendBeacon('close') in try/catch, registered on pagehide + visibilitychange->hidden."
  - "Source-scan gate asserting presence (sendBeacon/pagehide/visibilitychange) and absence (unload listener, external http(s):// / src=/href=)."

requirements-completed: [WEB-04]

coverage:
  - id: D1
    description: "Viewport page fires navigator.sendBeacon('close') on pagehide and on visibilitychange->hidden, using a relative same-origin target and no unload listener."
    requirement: "WEB-04"
    verification:
      - kind: unit
        ref: "tests/testthat/test-view3d-beacon.R#the viewport page fires a same-origin tab-close beacon"
        status: pass
    human_judgment: false
  - id: D2
    description: "Closing the browser tab actually reaches plan 02's /<token>/close route and stops that token's live httpuv server end-to-end in a real browser."
    verification: []
    human_judgment: true
    rationale: "sendBeacon fire-and-forget behavior on pagehide/visibilitychange varies by browser (bfcache, mobile, background discards); only a real-browser tab close on Windows/macOS proves the wire path. The finalizer + gmw_close() remain the guarantees, so a missed beacon never orphans past session end."

# Metrics
duration: 9min
completed: 2026-08-03
status: complete
---

# Phase 3 Plan 03: Viewport Tab-Close Beacon Summary

**Added the browser half of the D-02 tab-close teardown — `navigator.sendBeacon("close")` fired from `GMW_VIEW3D_TEMPLATE` on `pagehide` + `visibilitychange`→hidden, a relative same-origin target that reaches plan 02's `/<token>/close` route with no external reference, gated by a dedicated source-scan test.**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-08-03T16:34:00Z
- **Completed:** 2026-08-03T16:43:00Z
- **Tasks:** 2
- **Files modified:** 2 (1 modified, 1 created)

## Accomplishments
- `GMW_VIEW3D_TEMPLATE` now defines `gmwClose()` (a `try/catch`-wrapped `navigator.sendBeacon("close")`) registered on `window` `pagehide` and on `document` `visibilitychange` when `document.visibilityState === "hidden"`.
- The beacon target is the relative token `"close"` — it resolves same-origin against the page URL to `.../<token>/close`, adding no absolute URL, no `src=`/`href=`, and no server-side path parsing (WEB-03 preserved).
- Uses the reliable `pagehide` event with a `visibilitychange` backstop; the deprecated/unreliable `unload` event is not registered (Pitfall 4).
- New dedicated source-scan test `test-view3d-beacon.R` asserts the hook's presence and the offline-by-construction absences; kept in its own file so it never touches `test-transport.R` (parallel-safe with plan 01).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the pagehide/visibilitychange sendBeacon hook to GMW_VIEW3D_TEMPLATE** - `40f7bb7` (feat)
2. **Task 2: Source-scan gate for the beacon hook** - `f7a8985` (test)

**Plan metadata:** skipped (commit_docs disabled in `.planning/config.json`)

## Files Created/Modified
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R` - Added the `gmwClose()` beacon helper + `pagehide`/`visibilitychange` listeners beside the existing resize/keydown block in `GMW_VIEW3D_TEMPLATE`.
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-view3d-beacon.R` - New source-scan gate for the beacon hook.

## Decisions Made
- Beacon target kept as the relative string `"close"` (Claude's discretion per CONTEXT / RESEARCH Pattern 3) rather than any absolute URL, so it works for every token and introduces no external reference.
- `pagehide` + `visibilitychange`→hidden chosen over `unload` (RESEARCH Pitfall 4 / State of the Art: `unload` is deprecated/unreliable in the bfcache era).
- The explanatory comment in the template describes the loopback resolution as `loopback 127.0.0.1:PORT/<token>/` (no `http://` scheme) so the WEB-03 source-scan for absolute `http(s)://` references stays unambiguous.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Verification command `test_local(filter="beacon")` hangs on this host; ran the equivalent in isolation**
- **Found during:** Task 2 (Source-scan gate)
- **Issue:** The plan's automated verify, `testthat::test_local(<pkg>, filter="beacon")`, loads the full package, which triggers `tcltk2` GUI initialization that blocks indefinitely on this headless host — a pre-existing environment issue already documented in STATE.md ("Test suite... `tcltk2` GUI init blocks with no window server"), unrelated to this change.
- **Fix:** Ran the identical pure source-scan test in isolation without loading the package: `testthat::test_file("test-view3d-beacon.R")` after sourcing `helper-pkg-source.R` from the `tests/testthat` directory. Result: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ]`. Task 1's inline source assertion also passed (`OK`).
- **Files modified:** none (verification-only workaround)
- **Verification:** 9/9 assertions green in isolation; no test logic changed.
- **Committed in:** n/a (no code change)

---

**Total deviations:** 1 (1 blocking — verification-environment workaround only)
**Impact on plan:** None to the deliverable. The test passes exactly as authored; only the full-package harness invocation was substituted with an equivalent isolated run because of a pre-existing, documented headless `tcltk2` hang. No scope creep.

## Issues Encountered
- `test_local` (full-package load) hangs on `tcltk2` GUI init on this headless host — see the deviation above. This is the same pre-existing blocker recorded in STATE.md; the pure source-scan test itself is unaffected and passes in isolation.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The browser half of D-02 is in place and reaches plan 02's `/<token>/close` route; combined with the plan-01 finalizer and `gmw_close()`, all four D-01 teardown triggers now have their code paths.
- Plan 03-04's offline smoke test is the end-to-end backstop for external references and the offline-install proof (WEB-03).
- Outstanding (carried, not introduced here): the full test suite still cannot run cleanly on a headless host due to the documented `tcltk2` GUI-init hang and the known pre-existing reds; a display host is owed for CMP-01 / full-suite verification.

## Self-Check: PASSED

- FOUND: `R/view3d.R`
- FOUND: `tests/testthat/test-view3d-beacon.R`
- FOUND: `.planning/phases/03-offline-packaging-and-lifecycle/03-03-SUMMARY.md`
- FOUND commit: `40f7bb7` (Task 1)
- FOUND commit: `f7a8985` (Task 2)

---
*Phase: 03-offline-packaging-and-lifecycle*
*Completed: 2026-08-03*
