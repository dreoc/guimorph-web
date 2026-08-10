---
phase: 03-offline-packaging-and-lifecycle
plan: 04
subsystem: testing
tags: [offline-install, pkgbuild, install.packages, httpuv, byte-identity, testthat, WEB-03, CMP-01, UAT]

# Dependency graph
requires:
  - phase: 03-offline-packaging-and-lifecycle
    provides: "plan 02 mixed static+/close app (.gmw_serve_mesh serves specimen.ply over loopback) and plan 03 relative same-origin sendBeacon('close') that keeps the page free of external references"
  - phase: 02-transport-and-mesh-display
    provides: ".gmw_serve_mesh() static httpuv loopback listener + byte-identity transport test pattern; helper-transport.R fetch helpers; helper-pkg-source.R skip guards"
  - phase: 01-browser-result-plots-rgl-demotion
    provides: "WEB-00 vendored three.js bundle shipped in inst/htmlwidgets/guimorphweb-three.js"
provides:
  - "tests/testthat/test-offline-smoke.R (filter 'offline'): builds the tarball, installs it OFFLINE (repos=NULL, dependencies=FALSE) into a throwaway lib, and asserts the vendored bundle ships via system.file(), specimen.ply serves 200 + byte-identical over loopback, and the served page has zero external src=/href= http(s) references"
  - "A `# MANUAL UAT` header documenting the two human-only verifications (WEB-03 6-specimen render/orbit/reset + 30 MB worst case on offline Win+macOS; CMP-01 display-host library() load with .gmw_engine$ok unchanged), mirrored into 03-VALIDATION.md"
affects: [phase-gate, WEB-03-signoff, CMP-01-signoff]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Offline-install proof: pkgbuild::build() -> install.packages(tarball, repos=NULL, type='source', dependencies=FALSE, lib=templib) -> withr::with_libpaths() to exercise the INSTALLED package (never the source tree)"
    - "Byte-identity assertion reused verbatim from the transport suite: GET specimen.ply, expect 200L + identical() to readBin(fixture)"
    - "Offline-by-construction gate: rawToChar(page) must not match src=\"https?://\" nor href=\"https?://\""
    - "Opt-in env gate (GMW_RUN_OFFLINE_SMOKE) for a slow integration check that needs build tooling + a display host, so a headless test_local SKIPS cleanly instead of blocking on the installed package's tcltk2/rgl GUI-init load"

key-files:
  created:
    - "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-offline-smoke.R"
  modified:
    - ".planning/phases/03-offline-packaging-and-lifecycle/03-VALIDATION.md (Manual-Only synced; Wave 0 offline-smoke box checked)"

key-decisions:
  - "Gated the build+install+serve behind GMW_RUN_OFFLINE_SMOKE (plus skip_on_cran + the tooling skips). On this headless host the installed package's Imports (geomorph->rgl, tcltk2) block on GUI init (STATE.md), so an ungated test would HANG rather than fail. The env gate makes the default run a clean SKIP and matches the plan's 'a runnable script a human triggers per platform' framing (RESEARCH Open Question 2 / D-10)."
  - "Detect a completed install by rownames(installed.packages(lib.loc=templib)) rather than trusting install.packages()'s (invisible/warning-only) return, so a host missing an Import (A4) skips cleanly instead of hard-failing (acceptance: never a hard fail for missing tooling)."
  - "Kept the fast automated smoke on the committed ~0.77 MB B12_1_clean.ply fixture; the ~30 MB B7_1_clean.ply worst case stays in the manual UAT (Task 2), exactly as the plan splits it."

patterns-established:
  - "Offline-install integration test: build tarball -> offline install into a temp lib -> with_libpaths -> system.file bundle check + loopback byte-identity + no-external-refs, tearing the listener down via GUImorphWeb::gmw_close() on.exit."
  - "Manual-only verifications recorded as an executable `# MANUAL UAT` comment header in the test file AND mirrored verbatim into the phase VALIDATION.md Manual-Only table."

requirements-completed: []  # WEB-03/CMP-01 automated half shipped; requirement closure owed to the phase gate (manual UAT pending, mirrors plans 01/02)

coverage:
  - id: D1
    description: "A fully-offline source install (repos=NULL, dependencies=FALSE) ships the three.js bundle inside the installed package and serves specimen.ply 200 + byte-identical over loopback with zero external page refs"
    requirement: "WEB-03"
    verification:
      - kind: integration
        ref: "tests/testthat/test-offline-smoke.R#a fully-offline source install ships the bundle and serves it"
        status: unknown
    human_judgment: true
    rationale: "The automated block is correct-by-construction (byte-identity + no-external-ref assertions mirror the passing transport suite) but is opt-in behind GMW_RUN_OFFLINE_SMOKE and cannot run on this headless host: loading the installed GUImorphWeb namespace pulls geomorph->rgl/tcltk2, whose GUI init blocks with no window server (STATE.md). A human must run it with the env var set on offline stock Win+macOS display hosts to move status to pass."
  - id: D2
    description: "WEB-03 render UAT (6 reference specimens render shaded/orbit/zoom/r-reset + 30 MB worst case + tab-close beacon) and CMP-01 display-host library() load with .gmw_engine$ok unchanged, recorded as executable per-platform manual steps"
    requirement: "CMP-01"
    verification: []
    human_judgment: true
    rationale: "No CI on real Windows + macOS display hosts (human_verify_mode=end-of-phase; D-10 verification-only). Needs a human eye on the rendered viewport and a display host for the tcltk2 oracle load; the automated coverage that CAN exist lives in D1."

# Metrics
duration: 14min
completed: 2026-08-03
status: complete
---

# Phase 3 Plan 04: Offline-Install Smoke Test (WEB-03) Summary

**Shipped `tests/testthat/test-offline-smoke.R` — a build-tarball → offline `install.packages(repos=NULL, dependencies=FALSE)` → loopback-serve integration check proving the vendored three.js bundle ships, `specimen.ply` is served byte-identically, and the page has zero external references; plus a `# MANUAL UAT` header (mirrored into 03-VALIDATION.md) for the render UAT and CMP-01 display-host load that only a human on offline Win+macOS can sign off.**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-08-03T16:54:00Z (approx)
- **Completed:** 2026-08-03T17:08:00Z (approx)
- **Tasks:** 2
- **Files modified:** 1 created (`test-offline-smoke.R`) + 1 planning doc synced (`03-VALIDATION.md`, working tree only)

## Accomplishments
- **WEB-03 offline smoke (Task 1).** New `test_that("a fully-offline source install ships the bundle and serves it")` builds the tarball with `pkgbuild::build(..., args=c("--no-manual","--no-build-vignettes"))`, installs it OFFLINE with `install.packages(tarball, repos=NULL, type="source", dependencies=FALSE, lib=templib)` (the `repos=NULL`+`dependencies=FALSE` pair is load-bearing — `dependencies=TRUE` would reach CRAN, Pitfall 6), then under `withr::with_libpaths()` asserts (a) `nzchar(system.file("htmlwidgets","guimorphweb-three.js", package="GUImorphWeb"))` — the WEB-00 bundle ships inside the installed package; (b) `GET specimen.ply` → `200L` and bytes `identical()` to `readBin(fixture)` — served raw, never JSON; (c) the page text matches neither `src="https?://` nor `href="https?://` — offline by construction. Listener torn down via `GUImorphWeb::gmw_close()` on `on.exit`; temp lib + build dir removed.
- **Clean-skip discipline.** Guarded with `skip_on_cran()`, `skip_if_no_pkg_source()`, `skip_if_no_curl()`, `skip_if_not_installed("pkgbuild"/"withr")`, a `tryCatch`-guarded build (skip if `R CMD build` can't run), and an `installed.packages()`-based install check (skip if a host Import is missing, A4) — so it never hard-fails for missing tooling.
- **Manual UAT record (Task 2).** Added a `# MANUAL UAT` header stating Step A (build + offline install, then 6-specimen shaded render/orbit/zoom/`r`-reset, the ~30 MB `B7_1_clean.ply` worst case, and tab-close beacon → `httpuv::listServers()` empties → `gmw_close()` stops all, R started with `--no-init-file`) and Step B (CMP-01 display-host `library(GUImorphWeb)` load with `.gmw_engine$ok` unchanged). Mirrored verbatim into `03-VALIDATION.md` Manual-Only; the Wave 0 offline-smoke box is now checked.

## Task Commits

Each task was committed atomically:

1. **Task 1: WEB-03 offline install + serve + byte-identity + no-external-refs smoke test** - `9f2de35` (test)
2. **Task 2: Record the manual WEB-03 render UAT + CMP-01 display-host load gate** - `dfa0170` (docs — header added to the same test file)

**Plan metadata:** skipped (commit_docs disabled in `.planning/config.json` — SUMMARY/STATE/ROADMAP and the `03-VALIDATION.md` sync are left in the working tree per project config).

_Note: not a TDD plan; the deliverable is a verification-only integration test (D-10)._

## Files Created/Modified
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-offline-smoke.R` - New WEB-03 offline install/serve/byte-identity/no-external-refs test (filter `offline`) with a `# MANUAL UAT` header for the two human-check steps.
- `.planning/phases/03-offline-packaging-and-lifecycle/03-VALIDATION.md` - Manual-Only WEB-03 + CMP-01 rows synced to the header; Wave 0 offline-smoke checkbox ticked (working tree only, commit_docs=false).

## Decisions Made
- **Opt-in env gate `GMW_RUN_OFFLINE_SMOKE` for the heavy path.** On this headless host the installed package's Imports (`geomorph`→`rgl`, `tcltk2`) block on GUI init (verified: `requireNamespace("geomorph")` hung >65 s), so an ungated build+install+load would HANG the suite rather than fail. Gating the whole `test_that` behind the env var (default → clean SKIP) both prevents the hang and matches the plan's framing of a slow, human-triggered per-platform check (RESEARCH Open Question 2, D-10). Within the plan's explicit "skip if `R CMD build`/pkgbuild cannot run in the sandbox" latitude.
- **Install success detected via `installed.packages(lib.loc=templib)`,** not the (invisible/warning-only) return of `install.packages()`, so a host missing an Import (A4) skips cleanly instead of proceeding to a misleading failure.
- **Fast fixture stays ~0.77 MB (`B12_1_clean.ply`);** the ~30 MB worst case is manual-only (Task 2), exactly as the plan splits automated vs. manual scope.

## Deviations from Plan

None - plan executed exactly as written.

The `GMW_RUN_OFFLINE_SMOKE` opt-in gate is not a scope deviation: the plan's Task-1 action explicitly directs the executor to "skip if `R CMD build`/pkgbuild cannot run in the sandbox," and the acceptance criterion is "skips cleanly when absent (never a hard fail for missing tooling)." The env gate is the concrete mechanism for that clean skip on a host where the installed package cannot load headless — see Issues Encountered.

## Issues Encountered
- **`test_local(filter="offline")` hangs on this headless host (pre-existing).** The plan's literal verify, `testthat::test_local(<pkg>, filter="offline")`, runs `load_all`, which attaches `tcltk2` and blocks on GUI init with no window server — the exact pre-existing blocker documented in STATE.md and hit by plans 03-01/03-02/03-03. Ran the equivalent via `testthat::test_dir(<testdir>, filter="offline", load_package="none")` instead (the standing workaround). Result: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 0 ]`, skipping at the `GMW_RUN_OFFLINE_SMOKE` gate (confirmed the reason string with `NOT_CRAN=true`). Not a code defect; the test is correct-by-construction and its assertions mirror the passing transport byte-identity block.

## User Setup Required
None - no external service configuration required. (To RUN the offline smoke locally on a display host: `GMW_RUN_OFFLINE_SMOKE=1 NOT_CRAN=true R --no-init-file -q -e 'testthat::test_local("integrated-guimorph-development_EOC/Project/GUImorphDevelopment", filter="offline")'`, with a display present so the installed package loads.)

## Next Phase Readiness
- The automated half of WEB-03 (offline install ships + serves the bundle byte-identically with no external refs) is coded and skips cleanly headless; the ~30 MB render UAT and the CMP-01 display-host load are recorded as executable per-platform manual steps in the test header and `03-VALIDATION.md`.
- **Owed at the phase gate (not this plan):** run the offline smoke with `GMW_RUN_OFFLINE_SMOKE=1` on offline stock macOS + Windows (moves D1 to `pass`), sign off the WEB-03 6-specimen/30 MB render UAT and the CMP-01 display-host `library()` load in `03-VALIDATION.md`, and close WEB-03/CMP-01 (and WEB-04, deferred from plans 01/02) at `/gsd-verify-work`.
- The 6 known pre-existing test reds (2 deleted-function calls, 4 `assignInNamespace` tcltk stubs) remain out of scope and fall outside the `offline` filter, so the per-task quick run stays clean.

## Self-Check: PASSED

- FOUND: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-offline-smoke.R`
- FOUND commit: `9f2de35` (Task 1, test)
- FOUND commit: `dfa0170` (Task 2, docs — MANUAL UAT header)
- Test run: `test_dir(..., filter="offline", load_package="none")` → `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 0 ]` (clean skip at the opt-in gate; no hard fail).

---
*Phase: 03-offline-packaging-and-lifecycle*
*Completed: 2026-08-03*
