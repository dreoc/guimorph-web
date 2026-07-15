---
status: testing
phase: 01-aqua-tk-deployment-gate-windows-rendering-seam
source: [01-VERIFICATION.md]
started: 2026-07-13T04:04:49Z
updated: 2026-07-13T04:04:49Z
---

## Current Test

number: 1
name: Aqua gate runtime proof (GATE-01)
expected: |
  Build test/gate/gateext.dylib, then run
  `Rscript test/gate/gate_check.R <path-to-dylib>` in a configured macOS CLI R.
  Script exits 0 and prints `gate_check: PASS`, confirming both
  `tk windowingsystem == aqua` and `gate_winsys == aqua`.
awaiting: user response
awaiting: completed (2026-07-13)

## Tests

### 1. Aqua gate runtime proof (GATE-01)
expected: Build test/gate/gateext.dylib, then run `Rscript test/gate/gate_check.R <path-to-dylib>` in a configured Aqua-Tk macOS CLI R environment. Script exits 0 and prints `gate_check: PASS` (both `tk windowingsystem == aqua` and the loaded `gate_winsys == aqua`).
result: [pass] Built `build-gate/gateext.dylib` and ran `Rscript test/gate/gate_check.R build-gate/gateext.dylib`; exit code 0 and output includes `gate_check: PASS` (with non-fatal Tk/XPC warnings in this host environment).

### 2. Windows render parity (CMP-01)
expected: On a Windows MSVC host (VS 2022 Build Tools v143 + Windows R), rebuild `tkogl2.dll` from post-seam source per BUILD.md (MSVC/CMake, not MinGW), redeploy to `inst/libs/x64/tkogl2.dll`, launch `GUImorph()`, and load `test/fixtures/regression.ply`. Mesh renders identically to the pre-seam baseline (non-blank, non-black; same geometry/orientation/shading) and both build modes compile with no new seam-related warnings/errors.
result: [pending — deferred, tracked in .planning/todos/pending/phase-01-windows-validation.md]

## Summary

total: 2
passed: 1
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
