# Phase 3: Offline Packaging and Lifecycle - Context

**Gathered:** 2026-08-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the vendored JS inside the installed package and make the viewport
lifecycle reliable on a locked-down lab machine: server launch, browser open,
port selection, and teardown. Delivers WEB-03 (clean offline install opens a
working viewport on Windows + macOS) and WEB-04 (port-collision error handling,
browser-launch degradation, teardown on viewport close / session exit / R
session end). CMP-01 recurs: native `tkogl2` oracle must still load.

**Fixed by ROADMAP / REQUIREMENTS / reference architecture — not re-decided
here:** loopback-only bind; `httpuv::randomPort()` primary port pick with
walk-forward-from-preferred backup; offline vendored bundle (shipped Phase 1 as
WEB-00 — vendoring itself is not re-done here); print the URL first and only then
attempt `browseURL()`; WebGL baseline, WebGPU opportunistic via three.js
automatic fallback (not a dependency); server-owns-state / browser-pure-view.

**Out of scope:** the WEB-00 vendoring toolchain (done Phase 1); picking,
overlays, digitizing (Phase 4+); `.dgt` byte-parity (Phase 5).
</domain>

<decisions>
## Implementation Decisions

### Teardown
- **D-01:** Multiple teardown triggers, all required. A closed listener must
  never orphan.
  - **Explicit stop function** — user-callable `gmw_close()` / `gmw_stop()`.
  - **R session end** — `reg.finalizer(.gmw_server, onexit = TRUE)` so quitting
    R stops every live listener.
  - **Package unload/detach** — `.onUnload()` stops all live servers when the
    namespace unloads (closes the `detach()`-mid-session orphan path).
  - **Browser-tab close** — honored (see D-02), not accepted as unhandled.
- **D-02:** Tab-close detection via `navigator.sendBeacon('/close')` on page
  `unload` + one dynamic `/close` route mounted beside the static path. Closing
  the tab stops that token's server. **Consequence for the planner:** the httpuv
  app is no longer static-only — it becomes a mixed app (`staticPaths` for the
  bundle/specimen/page **plus** a `call`/handler route for `/close`). Keep the
  static byte path exactly as-is (path-traversal safety, T-2-02); the `/close`
  handler only stops the server for its own token.

### Concurrent viewports
- **D-03:** Many concurrent viewports allowed. `.gmw_server` is already
  token-keyed; keep every live server independent. Each is torn down on its own
  by its tab beacon (D-02) or by `gmw_close(token)`. (Multiple viewport windows,
  each still one specimen per viewport — consistent with Phase 2 D-01; this is
  about window count, not in-page specimen switching.)
- **D-04:** `gmw_close()` shape — no argument stops **all** live servers;
  optional `token` argument stops **one**. Covers both single- and multi-viewport
  cleanup and backs the explicit-stop trigger in D-01.

### Browser-launch degradation
- **D-05:** Always print the URL first, then attempt `browseURL()`, and **never
  trust its return value** (it returns 0 on many platforms even when nothing
  opened). Message carries a paste-fallback, e.g. `Viewport: <url> — if it did
  not open, paste this into a browser.` Print-first cannot fail.
- **D-06:** Firewall prompt on first loopback bind — surface a short start-time
  message that a firewall prompt may appear and that allowing loopback-only
  access is safe, and document it. Do not attempt to suppress the OS prompt.
- **D-07:** Honor R's built-in browser override (`getOption("browser")` /
  `R_BROWSER`, which `browseURL()` already consults) for hosts with no/blocked
  default browser. Document it; add no new override machinery.

### Port-occupied UX
- **D-08:** Expose an optional preferred-port argument on the entry function:
  `NULL` → `randomPort()` default; an integer → walk-forward-from-that-port
  backup (already coded in `.gmw_pick_port`). Surfaces the "fixed port allowed
  through a lab firewall" case from REFERENCE-ARCHITECTURE.
- **D-09:** When a supplied preferred port cannot be satisfied (walk-forward
  reaches 49151), keep an actionable clear R-level `stop()` — name the tried
  range and say to free a port or omit the port argument to auto-pick. A clear
  error, never a hang (Criterion 3).

### Offline self-check
- **D-10:** No `gmw_check()` diagnostic shipped in this phase. WEB-03 stays
  verification-only: manual UAT + an automated smoke test proving a clean,
  fully-offline install opens a working viewport on Windows and macOS. (A
  full-scope diagnostic is recorded as a deferred idea below.)

### Claude's Discretion
- Exact function names/signatures (`gmw_close` vs `gmw_stop`, entry-point port
  arg name), the `/close` route shape and token-matching detail, and the precise
  wording of the start-time firewall/paste messages — planner decides, following
  the decisions above and the server-owns-state pattern.
- Exact form of the WEB-03 offline smoke test (test harness vs UAT script split).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Lifecycle, port, browser-launch, offline, state ownership
- `.planning/research/REFERENCE-ARCHITECTURE.md` — port selection (randomPort
  primary + walk-forward backup), do-not-auto-open / print-URL-first, offline by
  construction, R-side port-probe testing technique, server-owns-state.
  Decisions inherited from `landmarking-EOC`, not re-derived.

### Requirements and scope
- `.planning/REQUIREMENTS.md` — WEB-03, WEB-04 (this phase); CMP-01 recurring
  gate. WEB-00/WEB-01/WEB-02 already delivered.
- `.planning/ROADMAP.md` §"Phase 3: Offline Packaging and Lifecycle" — success
  criteria, deployment-reality note (managed lab machines), WebGPU note.
- `.planning/phases/02-transport-and-mesh-display/02-CONTEXT.md` — Phase 2
  decisions; §domain explicitly defers teardown / port-collision / browser
  degradation to this phase (WEB-04).

### Reusable / to-be-extended code
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R`
  — `.gmw_serve_mesh()`, `.gmw_pick_port()` (randomPort + walk-forward),
  `.gmw_probe_free()`, `.gmw_token()`, `.gmw_server` retained-handle env. This
  is the file Phase 3 extends: add teardown (finalizer/`.onUnload`/`gmw_close`),
  the `/close` route, the preferred-port arg, and the launch messaging.
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R`
  — existing `.onLoad`, the `.gmw_engine` env idiom (mirror for lifecycle state),
  and CMP-01 oracle load status (`.gmw_engine$ok`).
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R`
  — `.gmw_view3d_html()` page template; the `sendBeacon` unload hook (D-02) is
  added here on the page side.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.gmw_server` env (token-keyed retained handles): already the multi-server
  registry D-03/D-04 iterate over for stop-all / stop-one.
- `.gmw_pick_port(prefer, probe)`: randomPort default + walk-forward backup and
  the injectable `probe` predicate already exist — D-08/D-09 surface and
  message them, no new selection logic.
- `.gmw_probe_free()` injectable design + REFERENCE-ARCHITECTURE port-probe
  technique: port-collision behavior is unit-testable without binding a socket.
- `rtkogl.R` `.onLoad` + `.gmw_engine`: precedent for package hooks and a
  package-env state object; `.onUnload` (D-01) is the natural counterpart.

### Established Patterns
- Server-owns-state; static byte serving off the libuv/C thread; loopback-only
  bind; `>=128-bit` token guard. Preserve when adding the `/close` route.
- Delivery shape mirrors `.rgl_show()` / `.plot_show()` — write page, open,
  message the path. Keep the same shape for the launch messaging (D-05).

### Integration Points
- httpuv app moves static-only → mixed (staticPaths + `/close` handler) (D-02).
- New package hook `.onUnload()` and `reg.finalizer(onexit=TRUE)` (D-01).
- New/extended R exports: `gmw_close()`/`gmw_stop()` (D-04) and the entry-point
  preferred-port argument (D-08).
- CMP-01: confirm the native `tkogl2` oracle still loads (`.gmw_engine$ok`) —
  recurring gate.
</code_context>

<specifics>
## Specific Ideas

- Tab-close teardown mechanism is specifically `navigator.sendBeacon` on the
  page `unload` event hitting a `/close` endpoint — chosen over a polling
  heartbeat/idle-timeout for fewer moving parts.
- Preferred-port argument exists to serve the concrete lab case where a single
  fixed loopback port has been allowed through a managed-machine firewall.
- WEB-03 smoke test must run with the machine fully offline (no runtime network)
  and cover both Windows and macOS.
</specifics>

<deferred>
## Deferred Ideas

- **`gmw_check()` offline diagnostic** — a read-only self-check probing: vendored
  bundle present (`system.file`), a loopback port bindable, browser resolvable,
  and `tkogl2` oracle load status (CMP-01), printing pass/fail per probe. Would
  double as the WEB-03 smoke test and turn "the software is broken" into legible
  triage. Considered and deferred for Phase 3 (WEB-03 stays verification-only);
  if revisited, ship the full four-probe scope.
- **Heartbeat / idle-timeout teardown** — more crash-robust than the
  `sendBeacon` unload approach, but more moving parts; not needed for Phase 3.

### Reviewed Todos (not folded)
- **`dat-parity-gate-is-a-skip.md`** — flagged by the todo matcher (keyword
  overlap) but it is `phase: 5`, blocks DAT-01/DAT-02, and concerns `.dgt`
  byte-parity, not offline packaging. Out of scope here; belongs to Phase 5.

</deferred>

---

*Phase: 3-Offline Packaging and Lifecycle*
*Context gathered: 2026-08-03*
