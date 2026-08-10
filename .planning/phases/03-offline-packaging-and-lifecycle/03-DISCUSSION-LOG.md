# Phase 3: Offline Packaging and Lifecycle - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-03
**Phase:** 3-Offline Packaging and Lifecycle
**Areas discussed:** Teardown, Concurrent viewports, Browser-launch degradation, Port-occupied UX, Offline self-check

---

## Teardown triggers

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit stop fn | user-callable gmw_close()/gmw_stop() | ✓ |
| R session end | reg.finalizer(.gmw_server, onexit=TRUE) | ✓ |
| Package unload/detach | .onUnload() stop-all | ✓ |
| Browser-tab close | detect tab close, stop that server | ✓ |

**User's choice:** all four triggers.
**Notes:** Initially marked tab-close required while also picking "no server-side detection" — contradiction surfaced and reconciled below.

### Tab-close mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| No detection | rely on explicit stop + session-end finalizer; closed tab leaves idle listener | |
| sendBeacon('/close') | page beacons a dynamic /close route on unload; stops that token | ✓ |
| Heartbeat + idle timeout | page polls, server self-stops after missed beats | |

**User's choice:** sendBeacon('/close') + dynamic /close route beside the static path.
**Notes:** Consequence — httpuv app becomes mixed (staticPaths + call handler), no longer static-only.

### Package unload/detach hook

| Option | Description | Selected |
|--------|-------------|----------|
| Yes | .onUnload() stop-all | ✓ |
| No | rely only on explicit stop + finalizer | |

**User's choice:** Yes.

---

## Concurrent viewports

| Option | Description | Selected |
|--------|-------------|----------|
| One at a time | opening a new viewport stops the previous | |
| Many concurrent | keep every token-keyed server live, torn down independently | ✓ |

**User's choice:** Many concurrent.

### gmw_close() shape

| Option | Description | Selected |
|--------|-------------|----------|
| Both | no-arg = stop all; token arg = stop one | ✓ |
| Stop-all only | always kills every live server | |

**User's choice:** Both.

---

## Browser-launch degradation

| Option | Description | Selected |
|--------|-------------|----------|
| Always print URL first | attempt browseURL, never trust its return, paste-fallback message | ✓ |
| Try to detect failure | wrap browseURL, inspect status (unreliable across platforms) | |

**User's choice:** Always print URL first.

### Firewall prompt

| Option | Description | Selected |
|--------|-------------|----------|
| Message + docs | note prompt may appear, Allow loopback safe; document | ✓ |
| Say nothing | let the OS prompt speak for itself | |

**User's choice:** Message + docs.

### Browser override

| Option | Description | Selected |
|--------|-------------|----------|
| Honor getOption('browser')/R_BROWSER | document built-in mechanism, no new machinery | ✓ |
| No override | print-URL fallback only | |

**User's choice:** Honor the built-in override.

---

## Port-occupied UX

| Option | Description | Selected |
|--------|-------------|----------|
| Expose preferred-port arg | NULL=randomPort, integer=walk-forward from it | ✓ |
| randomPort only | keep prefer/walk-forward internal | |

**User's choice:** Expose the preferred-port arg.

### Error content

| Option | Description | Selected |
|--------|-------------|----------|
| Actionable | name tried range, say free a port or omit arg to auto-pick | ✓ |
| As-is | leave current message | |

**User's choice:** Actionable.

---

## Offline self-check

| Option | Description | Selected |
|--------|-------------|----------|
| Ship gmw_check() | bundle + port + browser + oracle probes, pass/fail lines | |
| Verification-only | manual UAT + test, no user-facing self-check | ✓ |

**User's choice:** Verification-only (WEB-03 stays UAT + smoke test).
**Notes:** If a diagnostic is ever shipped, user preferred the full four-probe scope — recorded as a deferred idea.

---

## Claude's Discretion

- Exact function names/signatures (gmw_close vs gmw_stop, port arg name), /close route shape and token-matching, wording of firewall/paste messages.
- Form of the WEB-03 offline smoke test (harness vs UAT-script split).

## Deferred Ideas

- gmw_check() full four-probe offline diagnostic (bundle/port/browser/oracle) — deferred; WEB-03 verification-only for now.
- Heartbeat / idle-timeout teardown — more crash-robust, more moving parts; not needed Phase 3.
- Reviewed-not-folded todo: dat-parity-gate-is-a-skip.md — phase 5, `.dgt` byte-parity, out of scope here.
