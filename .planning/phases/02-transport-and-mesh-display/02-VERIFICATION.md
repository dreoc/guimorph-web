---
phase: 02-transport-and-mesh-display
type: verification
status: passed
verified: 2026-08-03
goal: "Serve a PLY specimen from R over a local HTTP server and render it in the browser with orbit, zoom, and reset. No overlays, no picking."
requirements: [WEB-01, WEB-02, CMP-01]
automated_result: passed
human_verification_required: true
human_verification_result: passed
---

# Phase 2 — Goal Verification (transport-and-mesh-display)

## Verdict

**`status: human_needed`** — Every automated must-have is verified against the
real source and the real test suite (44/44 transport assertions green, all
source-level truths confirmed). Nothing automated failed. The phase GOAL cannot
be declared *complete*, however, until the human-only items run on a host with a
display: the in-browser render/orbit/zoom/reset UAT (WEB-02), the 6-specimen
cross-OS load (WEB-02, the explicit phase gate), and the full `library(GUImorphWeb)`
load gate for CMP-01 (headless `tcltk2` GUI init blocks it here). These are
`human_verification`, not gaps — the code that they exercise is present and
source-verified.

---

## Per-Criterion Verdict Table

Criteria are the ROADMAP Phase 2 success criteria (1–5).

| # | Criterion | Requirement | Verdict | Evidence |
|---|-----------|-------------|---------|----------|
| 1 | httpuv binds loopback only, unprivileged port, serves PLY as bytes (never JSON) | WEB-01 | ✅ automated pass | Source: `startServer(host = "127.0.0.1", ...)`; no `0.0.0.0` in `R/transport.R`. Test: `getPort()` in 1024–49151; `curl`-fetched bytes `identical()` to `readBin` of the fixture. |
| 2 | Endpoint guarded by a per-session random path/token | WEB-01 | ✅ automated pass | `.gmw_token()` returns ≥32 URL-safe chars (≥128-bit); served only under `staticPaths` mounted at `/<token>`; guard test: a request without/with wrong token never returns the specimen bytes. `staticPaths`-only (no `PATH_INFO` `call` handler → traversal-safe). |
| 3 | three.js PLYLoader fetches + renders mesh with orbit/zoom/reset | WEB-02 | ⚙️ render logic automated pass · 👤 visual behaviour human_verification | Source `R/view3d.R`: async `PLYLoader().load(MESH_URL, …)`, `computeVertexNormals()`, `MeshLambertMaterial({color:"#cccccc", side:THREE.DoubleSide})`, deferred `frameScene()`; hoisted `dist` so `reset()`/`r`-key work. `test-transport-render.R` asserts these on the emitted HTML. **Actual GPU render (not black), orbit/zoom/reset feel, framing tightness are not machine-checkable here.** |
| 4 | 6-specimen set loads/orbits on stock macOS + Windows, no XQuartz/Homebrew/Tcl-Tk in render path | WEB-02 | 👤 human_verification | Explicit `[MANUAL UAT]` phase gate (02-VALIDATION.md Manual-Only). Requires clean macOS + clean Windows hosts and a live browser + WebGL. Includes the ~30 MB `B7_1_clean.ply` worst-case transfer/parse. |
| 5 | Native oracle still loads (CMP-01) | CMP-01 | ⚙️ httpuv-half automated pass · 👤 full load gate human_verification | httpuv-half verified: `requireNamespace("httpuv")` TRUE, `httpuv` in Imports, `"httpuv"` locked in `renv.lock` (1.6.17); `rtkogl.R` tkogl2 load path untouched. **Full `library(GUImorphWeb)` / `pkgload::load_all()` gate cannot run headless** — `tcltk2` GUI init blocks with no window server (pre-existing, unrelated to httpuv). |

Legend: ✅ automated pass · ⚙️ partial (code verified, behaviour deferred) · 👤 human_verification · ❌ gap.

---

## Requirement-ID Coverage (WEB-01, WEB-02, CMP-01)

All three PLAN-frontmatter requirement IDs are accounted for against
`.planning/REQUIREMENTS.md`:

| Req ID | REQUIREMENTS.md scope | Phase-2 disposition | Automated status | Residual (human) |
|--------|----------------------|---------------------|------------------|------------------|
| **WEB-01** | httpuv loopback, unprivileged port, PLY as bytes never JSON, per-session random path/token guard | Fully in scope (plan 02-02) | ✅ verified (loopback bind, unprivileged port, byte-integrity/non-JSON, token guard, port fallback, retained handle) | none |
| **WEB-02** | PLYLoader fetches + renders with orbit/zoom/reset on stock macOS + Windows, no XQuartz/Homebrew/Tcl-Tk in render path | Render logic (02-01) + server-side delivery (02-02); browser + cross-OS UAT deferred | ⚙️ render logic + delivery verified | 👤 in-browser render/orbit/zoom/reset + 6-specimen cross-OS UAT |
| **CMP-01** | Retained native engine stays loadable/functional (recurring gate through Phase 5) | httpuv addition must not break the load; native path untouched | ⚙️ httpuv-half verified; tkogl2 path source-unchanged | 👤 full `library(GUImorphWeb)` load gate on a display host |

No unaccounted IDs; no orphans. WEB-01 is fully closable on automated evidence;
WEB-02 and CMP-01 each retain a human-only tail.

---

## Automated Evidence (commands run + results)

Run from `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`
with `--no-init-file` (a renv side-effect otherwise hangs bare R).

**1. Transport + render test suite**
```
R -q --no-init-file -e 'testthat::test_dir("tests/testthat", filter="transport", stop_on_failure=TRUE)'
→ [ FAIL 0 | WARN 0 | SKIP 0 | PASS 44 ]   (exit 0, ~11s)
```
Covers `test-transport-render.R` (17) + `test-transport.R` (27): loopback bind +
unprivileged port + source-scan, byte-integrity (non-JSON), token guard,
port-fallback ordering, browse-open capture (no real browser), handle retention,
and the mesh-URL render branch (PLYLoader + normals + deferred framing + D-03/D-04).

**2. httpuv dependency / CMP-01 httpuv-half**
```
R -q --no-init-file -e 'requireNamespace("httpuv"); read.dcf("DESCRIPTION","Imports"); readLines("renv.lock")'
→ requireNamespace httpuv: TRUE
→ httpuv in Imports:       TRUE
→ httpuv in renv.lock:     TRUE   (version 1.6.17)
```

**3. Source-level truths (read directly)**
- `R/transport.R`: `host = "127.0.0.1"` present; **no** `0.0.0.0` (grep: none);
  serves via `httpuv::staticPath`/`staticPaths` — **no** `call` handler joining
  `PATH_INFO`; `.gmw_token(n = 32L)` over `[0-9a-zA-Z]` (≥128-bit); handle
  retained in `.gmw_server` env against gc().
- `R/view3d.R`: async `PLYLoader().load(...)` branch; `computeVertexNormals()`;
  `MeshLambertMaterial({ color: "#cccccc", side: THREE.DoubleSide })`; deferred
  `frameScene()` (only synchronous when `MESH_URL` empty); `var dist` hoisted to
  IIFE scope; no `vertexColors` enabled on the mesh material.
- `DESCRIPTION`: `httpuv` in `Imports` (after `tcltk2`); `htmlwidgets` still in
  `Suggests` (not reintroduced to Imports).

**4. Claimed key-files exist on disk** — all present:
`R/view3d.R`, `R/transport.R`, `tests/testthat/test-transport.R`,
`tests/testthat/test-transport-render.R`, `tests/testthat/helper-transport.R`,
`DESCRIPTION`, `renv.lock`. Fixtures present: `B12_1_clean.ply` (754K, automated
byte-integrity) and `B7_1_clean.ply` (30M, reserved for manual worst-case UAT).

---

## Human Verification Required

These items are `human_verification` (display/GPU/cross-OS or blocked headless).
They are the remaining gate on the phase GOAL — none is an automated failure.

- [ ] **WEB-02 — In-browser render (visual):** `.gmw_serve_mesh(<ply>)` opens the
      loopback URL; the served mesh renders **shaded, not black**; orbit (drag),
      zoom (scroll), and `r`/reset all work; camera framing is tight with no
      origin-null inflation. *(02-01 coverage D3 / 02-02 coverage D7.)*
- [ ] **WEB-02 — 6-specimen cross-OS load (phase gate):** all 6 reference
      specimens load and orbit on **stock macOS** and **stock Windows** with no
      XQuartz / Homebrew / Tcl-Tk in the render path; the ~30 MB
      `B7_1_clean.ply` worst case transfers/parses acceptably.
- [ ] **CMP-01 — Full load gate on a display host:** run
      `R -q -e 'library(GUImorphWeb)'` (or `pkgload::load_all(".")`) on a machine
      with a window server and confirm it loads with `httpuv` now in Imports and
      the native `tkogl2` oracle load path still functional. *(Blocked headless
      by `tcltk2` GUI init, unrelated to httpuv; httpuv-half already passed.)*

---

## Notes

- The two SUMMARY files' claims match the codebase: `requirements-completed`
  ([WEB-02] for 02-01; [WEB-01, WEB-02, CMP-01] for 02-02) are consistent with
  the source and tests, and the SUMMARYs already flag D3/D6/D7 as
  `human_judgment: true` — this verification agrees with that classification.
- Out-of-scope-for-Phase-2 (correctly deferred, not gaps): robust teardown /
  `stopServer` lifecycle, port-collision recovery UX, browser-launch degradation
  (all WEB-04 / Phase 3); in-page multi-specimen picker (D-02, Phase 5);
  Draco/binary-PLY compression.
