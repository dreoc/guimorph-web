---
phase: 01-aqua-tk-deployment-gate-windows-rendering-seam
plan: 02
subsystem: deployment-gate
tags: [r, tcltk, aqua, gateext, cmake]
requires:
  - phase: 01-01
    provides: windows rendering seam baseline
provides:
  - aqua gate assertion script for command-line R
  - trivial Tk-linked extension smoke target
  - reproducible gate build recipe for macOS
affects: [01-03, deployment, packaging]
tech-stack:
  added: []
  patterns: [R gate assertions via tcl load, standalone gate extension build]
key-files:
  created:
    - integrated-guimorph-development_EOC/Project/tkogl2/test/gate/gate_check.R
    - integrated-guimorph-development_EOC/Project/tkogl2/test/gate/gate_ext.c
    - integrated-guimorph-development_EOC/Project/tkogl2/test/gate/CMakeLists.txt
    - integrated-guimorph-development_EOC/Project/tkogl2/test/gate/.gitignore
  modified: []
key-decisions:
  - "Keep gate extension minimal and limited to tk windowingsystem query surface."
  - "Treat package-local D-01 binding as currently infeasible in this environment due Tk runtime conflicts."
patterns-established:
  - "Gate scripts should assert both Tk flavor and extension load path."
requirements-completed: [GATE-01]
coverage:
  - id: D1
    description: "Command-line R gate script asserts aqua and Gateext load."
    requirement: "GATE-01"
    verification:
      - kind: integration
        ref: "Rscript integrated-guimorph-development_EOC/Project/tkogl2/test/gate/gate_check.R build-gate/gateext.dylib"
        status: pass
    human_judgment: false
  - id: D2
    description: "Standalone gate extension source and build recipe committed."
    requirement: "GATE-01"
    verification:
      - kind: other
        ref: "test -f gate_ext.c && rg Tk_InitStubs gate_ext.c && test -f CMakeLists.txt"
        status: pass
    human_judgment: false
duration: 9 min
completed: 2026-07-13
status: complete
---

# Phase 1 Plan 2: Aqua Tk deployment gate summary

**A command-line R gate now proves `tk windowingsystem == aqua` and can load a committed Tk-linked `Gateext` dylib via the same Tcl load pathway used by package startup.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-13T00:24:00Z
- **Completed:** 2026-07-13T00:33:04Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added `gate_check.R` to assert Aqua Tk and extension load behavior in command-line R.
- Added minimal `gate_ext.c` with `Tcl_InitStubs` + `Tk_InitStubs` and `gate_winsys`.
- Added standalone `test/gate/CMakeLists.txt` to build `gateext.dylib` on macOS.
- Verified `tcltk.so` has no `libX11` linkage in this environment.

## Task Commits

Each task was committed atomically:

1. **Task 1: Deployment-gate spike + gate script** - `ead9237` (feat)
2. **Task 2: Trivial Tk-linked extension + build recipe** - `97c9d5e` (feat)

## Files Created/Modified
- `integrated-guimorph-development_EOC/Project/tkogl2/test/gate/gate_check.R` - Scriptable Aqua + extension load assertion.
- `integrated-guimorph-development_EOC/Project/tkogl2/test/gate/gate_ext.c` - Minimal Tk-linked Tcl extension exposing `gate_winsys`.
- `integrated-guimorph-development_EOC/Project/tkogl2/test/gate/CMakeLists.txt` - Dedicated gate extension build recipe.
- `integrated-guimorph-development_EOC/Project/tkogl2/test/gate/.gitignore` - Ignores local build output.

## Decisions Made
- Kept the gate extension intentionally narrow (single command, no external input parsing) to satisfy threat mitigations.
- Recorded D-01 package-local feasibility as currently infeasible in this local environment: mixed Tk 8.6/9.0 runtime loading causes duplicate Objective-C class collisions/segfaults in `wish`, so this cannot yet be considered clean-machine safe.
- Used command-line Homebrew R for gate execution because cask R install requires blocked privileged installer flow in this environment.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Recovered from missing runtime/build dependencies**
- **Found during:** Task 1
- **Issue:** `R`, `cmake`, and Aqua `tcl-tk` were unavailable at execution start.
- **Fix:** Installed first-party Homebrew dependencies and continued with command-line validation.
- **Files modified:** None
- **Verification:** `Rscript` gate assertions and CMake build ran successfully.
- **Committed in:** N/A (environment setup)

**2. [Rule 3 - Blocking] Resolved extension build/link failures**
- **Found during:** Task 2
- **Issue:** Initial extension build failed on include/link configuration and Tcl/Tk version conflicts.
- **Fix:** Adjusted include paths, linking strategy, and made stub negotiation version-aware (`TCL_VERSION`/`TK_VERSION`) so `gate_check.R` passes.
- **Files modified:** `test/gate/gate_ext.c`, `test/gate/CMakeLists.txt`
- **Verification:** `Rscript test/gate/gate_check.R build-gate/gateext.dylib` reports `gate_check: PASS`.
- **Committed in:** `97c9d5e`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Core gate objective completed; standalone `wish` smoke flow remains unstable in this host due mixed Tk runtimes, captured as evidence for Plan 03 decisioning.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None.

## Issues Encountered
- Homebrew `tcl-tk` 9.0 emits Tk initialization warnings (`NaN` scaling expression) in this host setup.
- `wish` standalone load verification crashes with duplicate class collisions when both `tcl-tk@8` and `tcl-tk` 9.0 are present; this blocks a clean standalone `wish` proof in this exact environment, but R-based gate proof passes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plan 03 can consume this run's D-01 feasibility finding (package-local risk) and decide D-01 vs D-02 with real evidence.
- Gate artifacts are in place for repeatable regression checks from command-line R.

## Self-Check: PASSED
- Required files exist on disk.
- Task commit hashes `ead9237` and `97c9d5e` exist in git history.
