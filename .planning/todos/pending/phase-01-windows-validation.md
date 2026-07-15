---
title: "Run Windows MSVC render validation for Plan 01-04"
status: pending
priority: high
resolves_phase: 1
created: 2026-07-12
updated: 2026-07-12
owner: unassigned
source_plan: 01-04
---

## Context

Plan `01-04` requires a Windows-only validation step that cannot run on the current macOS environment:

- Build post-seam `tkogl2.dll` with MSVC/CMake
- Redeploy `inst/libs/x64/tkogl2.dll`
- Launch `GUImorph()` on Windows R
- Load `test/fixtures/regression.ply`
- Confirm rendering matches pre-seam behavior

## Acceptance

- Windows build succeeds with no new seam-related errors
- Render result is visually unchanged and non-blank
- Result is reported back as `windows-render-ok` or with regression details
