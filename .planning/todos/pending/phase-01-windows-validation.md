---
title: "Run Windows MSVC render validation for Plan 01-04"
status: done
priority: high
resolves_phase: 1
created: 2026-07-12
updated: 2026-07-16
resolved: 2026-07-16
owner: eoc
source_plan: 01-04
---

## Resolution (2026-07-16) — superseded by Phase 03 Windows verification

The Phase 03 Windows rebuild (`phase-03-windows-validation.md`, `windows-render-ok`
2026-07-16) built `tkogl2.dll` from strictly newer source that already includes the
Phase 01 seam extraction (`gfx_backend_wgl.c`) and the Plan 01-05 boundary fix, and
confirmed the mesh renders unchanged (non-blank, landmark dots, labels, on-target
picks) including a 6-specimen `.dgt`. That render regression is a superset of this
Plan 01-04 check, so the seam-extraction render parity (CMP-01 for Phase 01) is
satisfied. No separate pre-seam-vs-post-seam eyeball run is still outstanding.

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
