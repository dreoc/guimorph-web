---
phase: 01-aqua-tk-deployment-gate-windows-rendering-seam
verified: 2026-07-13T04:03:01Z
status: human_needed
score: 5/8 must-haves verified
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/8
  gaps_closed:
    - "Core contains no platform window/context tokens outside backend seam (RND-01): HWND typing removed from tcl_window.c/.h; setWindowId now takes void *native_drawable; seam scan over src/ (excluding gfx_backend_wgl.c) is empty."
    - "Unresolved `// TBD ??` debt marker on model_t.count in def_ZARF_9.h resolved with a concrete definition comment."
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Windows MSVC build still works and renders identically (CMP-01)"
    addressed_in: "Phase 2+ recurring Windows checkpoint"
    evidence: "ROADMAP success criteria for phases 2-6 each repeat 'Windows build still works'; backlog item `.planning/todos/pending/phase-01-windows-validation.md` tracks pending D-06 execution."
  - truth: "Both CODE_FOR_LIBRARY and STAND_ALONE_TOOL compile the seam calls"
    addressed_in: "Phase 2+ recurring Windows checkpoint"
    evidence: "The WGL backend is `#ifdef _WIN32` and def_ZARF_9.h includes <windows.h> unconditionally, so the seam/core only compile under the Windows toolchain; the dual-mode compile is part of the deferred CMP-01 Windows validation."
behavior_unverified_items:
  - truth: "macOS command-line R reports aqua and can load Gateext successfully (GATE-01 runtime)"
    test: "Build `test/gate/gateext.dylib`, then run `Rscript test/gate/gate_check.R <built gateext.dylib>` in a configured Aqua CLI R environment."
    expected: "Script exits 0 and prints `gate_check: PASS` after asserting `tk windowingsystem == aqua`, `gate_winsys == aqua`, and a successful Tcl load."
    why_human: "Code artifacts (gate_check.R, gate_ext.c) are present and correct, but no built `build-gate/gateext.dylib` exists in this workspace, so the runtime aqua+load behavior is not exercised here."
human_verification:
  - test: "Build test/gate/gateext.dylib, then run `Rscript test/gate/gate_check.R <path-to-dylib>` in a configured macOS CLI R."
    expected: "Exits 0, prints `gate_check: PASS`, confirms `tk windowingsystem == aqua` and `gate_winsys == aqua`."
    why_human: "Requires a local Aqua-configured R runtime and a built dylib artifact not present in this verification run (GATE-01 runtime proof)."
  - test: "On a Windows MSVC host, rebuild post-seam `inst/libs/x64/tkogl2.dll`, run `GUImorph()`, and load `test/fixtures/regression.ply`."
    expected: "Rendering is non-blank and visually unchanged versus the pre-seam baseline (CMP-01 / D-06)."
    why_human: "Off-box Windows MSVC build + visual eyeball parity cannot be completed on this macOS host; tracked in `.planning/todos/pending/phase-01-windows-validation.md`."
---
# Phase 1: Aqua-Tk Deployment Gate + Windows Rendering Seam Verification Report

**Phase Goal:** Confirm and document a supported "R + Aqua Tk" configuration on macOS, and isolate all native window/context creation behind a platform seam with the existing Win32/WGL code moved behind it unchanged.
**Verified:** 2026-07-13T04:03:01Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure (Plan 01-05)

## Re-Verification Summary

The prior report was `gaps_found` (4/8) with two BLOCKER gaps. Both are now closed in the codebase:

1. **RND-01 seam completeness** — `tcl_window.c`/`tcl_window.h` no longer name any Win32 window/context token. `setWindowId` now takes `void *native_drawable` and forwards it straight to `gfx_create`; the `void*`→`HWND` cast lives only in `gfx_backend_wgl.c` (line 19). The seam scan over `src/` (excluding `gfx_backend_wgl.c`) for `HWND|HDC|HGLRC|SwapBuffers|wgl` is **empty**.
2. **Debt marker** — the bare `// TBD ??` on `model_t.count` in `def_ZARF_9.h` is replaced with a concrete definition (vertex count passed to `glDrawArrays`, three per triangle). `grep TBD def_ZARF_9.h` is empty; no `TBD|FIXME|XXX` remain in any Plan-05-modified file.

No regressions were found in the previously-verified truths. The phase is **not `passed`** only because of outstanding human verification: GATE-01 runtime proof (behavior-unverified, needs a built Aqua dylib) plus the deferred CMP-01 Windows validation.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | macOS R session reaches aqua and loads a trivial Tk extension (GATE-01 runtime) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `gate_check.R` + `gate_ext.c` implement the aqua assertions and Tcl load; runtime skipped because `build-gate/gateext.dylib` is absent in this workspace. Routed to human verification. |
| 2 | Reproducible Aqua-Tk setup is documented for researchers (GATE-02) | ✓ VERIFIED | `docs/AQUA-TK-SETUP.md` present with toolchain/setup, CLI-R caveat, `gate_check.R` proof command, and no-`libX11` self-check. |
| 3 | WGL/HDC/HGLRC/SwapBuffers moved out of core into the backend seam | ✓ VERIFIED | `gfx_backend_wgl.c` (guarded by `#ifdef _WIN32`) owns `HDC`/`HGLRC`/`wgl*`/`SwapBuffers`; static scan finds these tokens nowhere else under `src/`. |
| 4 | Windows build still works and renders identically (CMP-01) | ⏸️ DEFERRED | Off-box MSVC build + D-06 render parity tracked in `.planning/todos/pending/phase-01-windows-validation.md`; recurs as a checkpoint in phases 2-6. |
| 5 | Core contains no platform window/context tokens; only the backend owns them (RND-01) | ✓ VERIFIED (gap closed) | `tcl_window.h` declares `int setWindowId(void *native_drawable);`; `tcl_window.c` builds `(void *)(intptr_t)hwndId` and forwards to `gfx_create`; `<stdint.h>` added; seam scan empty. |
| 6 | Window/context lifecycle ordering is preserved through the seam | ✓ VERIFIED | `setWindowId` calls `gfx_create` → `gfx_make_current` → `ogl_init` in order (tcl_window.c:39-41); `onDisplay` presents via `gfx_swap(g_surface)` (tcl_dispatch.c:3598). |
| 7 | Dead `__linux__` present branch removed | ✓ VERIFIED | `onDisplay` present path is `gfx_swap(g_surface)` only; no `__linux__` occurrence in `tcl_dispatch.c`. |
| 8 | Both CODE_FOR_LIBRARY and STAND_ALONE_TOOL compile the seam calls | ⏸️ DEFERRED | WGL backend is `#ifdef _WIN32` and `def_ZARF_9.h` includes `<windows.h>` unconditionally → core only compiles under the Windows toolchain; dual-mode compile folds into deferred CMP-01 Windows validation. |

**Score:** 5/8 truths verified (1 present, behavior-unverified; 2 deferred to CMP-01 Windows validation)

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases / the pending Windows-validation backlog.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Windows MSVC render parity proof (CMP-01) | Phase 2+ recurring checkpoints | ROADMAP phases 2-6 each include "Windows build still works"; `.planning/todos/pending/phase-01-windows-validation.md` tracks the unresolved off-box run. |
| 2 | Dual-mode (CODE_FOR_LIBRARY / STAND_ALONE_TOOL) seam compile | Phase 2+ recurring checkpoints | Core + WGL backend only compile on the Windows toolchain (`_WIN32` guard + unconditional `<windows.h>`); compile evidence belongs to the deferred CMP-01 Windows run. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | ----------- | ------ | ------- |
| `src/gfx_backend.h` | Platform seam contract | ✓ VERIFIED | Opaque `gfx_surface`, 5 seam functions, no `windows.h` include. |
| `src/gfx_backend_wgl.c` | WGL backend implementation | ✓ VERIFIED | `#ifdef _WIN32`; owns `HDC`/`HGLRC`/`wgl*`/`SwapBuffers` and the `void*`→`HWND` cast (line 19). |
| `src/tcl_window.c` | Seam-neutral core window glue | ✓ VERIFIED (gap closed) | `setWindowId(void *native_drawable)`; `(void *)(intptr_t)hwndId`; `#include <stdint.h>`; no Win32 token. |
| `src/tcl_window.h` | Seam-neutral prototype | ✓ VERIFIED (gap closed) | `int setWindowId(void *native_drawable);` — names no Win32 type. |
| `src/def_ZARF_9.h` | Debt-marker-free header | ✓ VERIFIED (gap closed) | `model_t.count` documented as `glDrawArrays` vertex count; no `TBD`. |
| `test/gate/gate_check.R` | Aqua + load assertion script | ✓ VERIFIED | Present (regression check). |
| `test/gate/gate_ext.c` | Tk-linked trivial extension | ✓ VERIFIED | Present (regression check). |
| `docs/AQUA-TK-SETUP.md` | Reproducible setup documentation | ✓ VERIFIED | Present (regression check). |
| `test/fixtures/regression.ply` | Committed regression fixture | ✓ VERIFIED | Present (regression check). |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `src/tcl_window.c` | `src/gfx_backend_wgl.c` | `g_surface = gfx_create(native_drawable)` + `gfx_make_current(...)` | ✓ WIRED | Core routes creation/current through the seam with a `void*` drawable — no handle type in core. |
| `src/tcl_dispatch.c` | `src/gfx_backend_wgl.c` | `gfx_swap(g_surface)` | ✓ WIRED | Present path uses backend swap only (tcl_dispatch.c:3598). |
| `CMakeLists.txt` | `src/gfx_backend_wgl.c` | `add_library(... gfx_backend_wgl.c ...)` | ✓ WIRED | Backend TU in target sources (CMakeLists.txt:48). |
| `src/tcl_window.c` (id path) | `gfx_create` | `(void *)(intptr_t)hwndId` → `setWindowId` → `gfx_create` | ✓ WIRED | Standard-C pointer-sized widening; behavior-preserving vs the prior handle cast. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `src/tcl_window.c` + `src/tcl_dispatch.c` | `g_surface` | `gfx_create(native_drawable)` result propagated to `gfx_swap` | Yes (pointer flow connected) | ✓ FLOWING |
| `test/gate/gate_check.R` | `winsys`, `gate_winsys` | Tcl interp via `.Tcl("tk windowingsystem")` + loaded `gate_winsys` | Runtime not executed (no dylib) | ⚠️ STATIC CHECK ONLY |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Seam-completeness scan (RND-01) | `grep -REn 'HWND\|HDC\|HGLRC\|SwapBuffers\|wgl' src/ \| grep -v gfx_backend_wgl.c` | empty | ✓ PASS |
| No debt marker in def_ZARF_9.h | `grep -n TBD src/def_ZARF_9.h` | empty | ✓ PASS |
| No debt marker across Plan-05 files | `grep -REn 'TBD\|FIXME\|XXX' tcl_window.c tcl_window.h def_ZARF_9.h` | empty | ✓ PASS |
| Seam-neutral prototype/definition | `grep 'setWindowId(void \*native_drawable)'` in `.c`/`.h` | both present | ✓ PASS |
| Gate/doc/fixture artifacts exist | `test -f` on 4 artifacts | all found | ✓ PASS |
| GATE-01 gate runtime | `Rscript gate_check.R build-gate/gateext.dylib` | skipped (dylib missing) | ? SKIP |

### Probe Execution

| Probe | Command | Result | Status |
| ----- | ------- | ------ | ------ |
| N/A | probe discovery (`scripts/**/probe-*.sh`) | no probe scripts found | SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| `GATE-01` | `01-02-PLAN.md` | R+aqua gate + trivial extension load | ? NEEDS HUMAN | Code artifacts complete; runtime `gate_check: PASS` not reproduced (no built dylib in this run). |
| `GATE-02` | `01-03-PLAN.md` | Documented reproducible setup | ✓ SATISFIED | `docs/AQUA-TK-SETUP.md` includes setup + verification flow. |
| `RND-01` | `01-01-PLAN.md`, `01-05-PLAN.md` | Window/context seam isolation | ✓ SATISFIED | Seam scan empty; `setWindowId(void *native_drawable)`; backend owns the `void*`→`HWND` cast. Gap closed by Plan 05. |
| `CMP-01` | `01-04-PLAN.md` | Windows still works checkpoint | ⏸️ DEFERRED | Documented deferral in `.planning/todos/pending/phase-01-windows-validation.md`; recurs each phase. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | — | — | None. Prior BLOCKER `// TBD ??` in `def_ZARF_9.h` resolved (comment now defines `model_t.count`). |

### Human Verification Required

#### 1. Aqua gate runtime proof (GATE-01)

**Test:** Build `test/gate/gateext.dylib`, then run `Rscript test/gate/gate_check.R <path-to-dylib>` in a configured macOS CLI R.
**Expected:** Exits 0, prints `gate_check: PASS`, confirms `tk windowingsystem == aqua` and `gate_winsys == aqua`.
**Why human:** Requires a local Aqua-configured R runtime and a built dylib not present in this verification run.

#### 2. Windows render parity (CMP-01)

**Test:** On a Windows MSVC host, rebuild + redeploy `inst/libs/x64/tkogl2.dll`, run `GUImorph()`, load `test/fixtures/regression.ply`.
**Expected:** Rendering is non-blank and visually unchanged versus the pre-seam baseline.
**Why human:** Off-box Windows + visual D-06 eyeball check cannot be completed here; tracked as a documented deferral.

### Gaps Summary

**No blocking gaps remain.** Both prior BLOCKERs are closed in the codebase: the RND-01 seam boundary is now complete (no Win32 window/context token anywhere under `src/` except `gfx_backend_wgl.c`; `setWindowId` is seam-neutral), and the `// TBD ??` debt marker on `model_t.count` is resolved with a concrete definition. All previously-verified truths still hold (no regressions).

The phase resolves to **human_needed** rather than `passed` because two runtime proofs cannot be exercised in this static, macOS-only verification: GATE-01's aqua+load behavior (needs a built Aqua dylib) and CMP-01's Windows MSVC render parity (off-box, documented deferral). Neither is a code failure — the artifacts are present and correctly wired.

---

_Verified: 2026-07-13T04:03:01Z_
_Verifier: Claude (gsd-verifier)_
