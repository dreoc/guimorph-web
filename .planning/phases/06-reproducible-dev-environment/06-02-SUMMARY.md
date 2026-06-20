---
phase: 06-reproducible-dev-environment
plan: 02
subsystem: docs
tags: [BUILD.md, deploy-dll, tkogl2, powershell]

requires:
  - phase: 06-01
    provides: renv baseline and BUILD.md R-environment cross-refs
provides:
  - Root BUILD.md contributor guide
  - scripts/deploy-dll.ps1 with backup-before-swap
  - Restructured tkogl2/BUILD.md (Windows-native primary)
affects: [06-03, contributor-onboarding]

tech-stack:
  added: [deploy-dll.ps1]
  patterns: ["deploy with .bak rollback", "WSL cross-compile optional appendix"]

key-files:
  created:
    - BUILD.md
    - scripts/deploy-dll.ps1
  modified:
    - integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md
    - .planning/smoke-test-findings.md

key-decisions:
  - "MSYS2 native build UAT deferred; maintainer uses WSL cross-compile build in build/"
  - "Do not deploy build/tkogl2.dll until render UAT — inst 2020 DLL is known-good runtime"

patterns-established:
  - "deploy-dll.ps1: RepoRoot from PSScriptRoot, fail-closed if build output missing"

requirements-completed: [DEV-01, DEV-02, DEV-03]

duration: multi-session
completed: 2026-06-19
---

# Phase 6 Plan 02 Summary

**Contributor BUILD.md and deploy-dll.ps1 delivered; deploy script verified with rollback after WSL build regression**

## Performance

- **Tasks:** 3/3 (Task 3 human-verify approved 2026-06-19)
- **Files modified:** 4+

## Accomplishments

- Root `BUILD.md` — prerequisites through troubleshooting, renv, deploy, smoke test
- `scripts/deploy-dll.ps1` — path validation, `.bak` backup, ASCII-safe error messages
- `tkogl2/BUILD.md` — Windows-native MSYS2 primary; WSL cross-compile appendix
- Deploy UAT: script mechanics pass; post-deploy rollback restores working GUI

## Files Created/Modified

- `BUILD.md` — integrated contributor doc
- `scripts/deploy-dll.ps1` — PowerShell deploy helper
- `integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md` — restructured build guide
- `.planning/smoke-test-findings.md` — BUILD UAT + DLL regression notes

## Decisions Made

- WSL `build/tkogl2.dll` (883 KB, Jun 2026) is **not** a safe deploy source until render UAT; maintainer runtime is `inst` 2020 DLL (1.2 MB) restored from `.bak`
- MSYS2 native build UAT (A1) deferred to future session

## Deviations from Plan

Deploy regression discovered during checkpoint: WSL cross-compile artifact loads `.dgt` data but blank viewer. Rollback documented in BUILD.md. Checkpoint 2 approved after restore + GUI confirm.

## Issues Encountered

- Em-dash in `deploy-dll.ps1` throw string broke PowerShell parser — fixed to ASCII hyphen
- Deploy from `build/` swapped working DLL — recovery via `.bak` restore

## User Setup Required

MSYS2 for native Windows C build (documented; not UAT'd this session).

## Next Phase Readiness

DEV-02 and DEV-03 satisfied for docs + deploy workflow. Plan 06-03 (README) already complete.

## Self-Check: PASSED

- deploy-dll.ps1 backup + copy verified
- GUI smoke after rollback approved by user

---
*Phase: 06-reproducible-dev-environment*
*Completed: 2026-06-19*
