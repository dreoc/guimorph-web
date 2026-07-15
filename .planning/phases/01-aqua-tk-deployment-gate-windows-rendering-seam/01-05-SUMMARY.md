---
phase: 01-aqua-tk-deployment-gate-windows-rendering-seam
plan: 05
subsystem: infra
tags: [opengl, win32, wgl, platform-seam, refactor, c99, intptr_t]

# Dependency graph
requires:
  - phase: 01-aqua-tk-deployment-gate-windows-rendering-seam (Plan 01)
    provides: gfx_backend seam (opaque gfx_surface, gfx_create(void *native_drawable), 5-function contract) with WGL backend
provides:
  - Seam-complete core - no Win32 window/context token (HWND/HDC/HGLRC/SwapBuffers/wgl) anywhere under src/ except gfx_backend_wgl.c
  - Seam-neutral setWindowId(void *native_drawable) forwarding straight to gfx_create
  - Resolved model_t.count debt marker with concrete definition
affects: [phase-02-rendering, RND-02, pathname-refactor, macos-nsgl-backend]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Core hands the backend a seam-neutral void* native drawable; the void*->HWND cast lives only in gfx_backend_wgl.c"
    - "32-bit Tcl int widened to pointer-sized native drawable via standard-C (void *)(intptr_t) cast (no Win32 pointer-sized typedef in core)"

key-files:
  created: []
  modified:
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c
    - integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.h
    - integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h

key-decisions:
  - "Use standard-C intptr_t (via <stdint.h>) instead of the Win32 INT_PTR typedef so the int->drawable cast carries no platform token in core"
  - "Preserve the exact (void *)(intptr_t)hwndId widening semantics — behavior-preserving; the fragile int cast is fully replaced by pathname resolution in Phase 2 (RND-02), not here"
  - "Resolve model_t.count debt marker with a concrete definition (vertex count for glDrawArrays) rather than a follow-up reference, since usage is unambiguous"

patterns-established:
  - "Seam boundary completeness: platform window/context tokens confined to the single backend translation unit; enforced by grep gate over src/ excluding gfx_backend_wgl.c"

requirements-completed: [RND-01]

coverage:
  - id: D1
    description: "Core contains no platform window/context token (HWND/HDC/HGLRC/SwapBuffers/wgl) outside the backend seam"
    requirement: "RND-01"
    verification:
      - kind: automated_ui
        ref: "grep -REn 'HWND|HDC|HGLRC|SwapBuffers|wgl' integrated-guimorph-development_EOC/Project/tkogl2/src/ | grep -v 'gfx_backend_wgl.c' (empty)"
        status: pass
    human_judgment: false
  - id: D2
    description: "setWindowId is seam-neutral (void *native_drawable) in header and source and forwards to gfx_create with lifecycle order preserved"
    requirement: "RND-01"
    verification:
      - kind: automated_ui
        ref: "grep setWindowId(void *native_drawable) in tcl_window.c/.h + gfx_create->gfx_make_current->ogl_init order"
        status: pass
    human_judgment: false
  - id: D3
    description: "No unresolved TBD debt marker remains in def_ZARF_9.h; model_t.count preserved and documented"
    verification:
      - kind: automated_ui
        ref: "! grep -n 'TBD' def_ZARF_9.h && grep -q 'int count;' def_ZARF_9.h"
        status: pass
    human_judgment: false
  - id: D4
    description: "Windows MSVC build + render parity of the refactored source (behavior preservation on-target)"
    verification: []
    human_judgment: true
    rationale: "Off-box MSVC build + visual render check (CMP-01/D-06) cannot run on this macOS host; tracked in .planning/todos/pending/phase-01-windows-validation.md"

# Metrics
duration: 6min
completed: 2026-07-13
status: complete
---

# Phase 1 Plan 05: Windows Rendering Seam Gap Closure Summary

**Behavior-preserving refactor closing two BLOCKER verification gaps: HWND typing removed from core (setWindowId now takes a seam-neutral void *native_drawable), and the bare `// TBD ??` debt marker on model_t.count resolved with a concrete definition.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-07-13T03:56:00Z
- **Completed:** 2026-07-13T04:02:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Eliminated every `HWND` occurrence from core (`tcl_window.c`, `tcl_window.h`) — the seam-completeness scan over `src/` (excluding `gfx_backend_wgl.c`) is now empty, satisfying RND-01's strict seam truth.
- `setWindowId` now accepts a seam-neutral `void *native_drawable` and forwards straight to `gfx_create` -> `gfx_make_current` -> `ogl_init` (lifecycle order unchanged); the `setWindow` "id" path builds the drawable via a standard-C `(void *)(intptr_t)hwndId` cast, with `<stdint.h>` added so no Win32 pointer-sized typedef leaks into core.
- Resolved the unresolved `// TBD ??` debt marker on `model_t.count` in `def_ZARF_9.h` with a concrete definition (vertex count passed to `glDrawArrays`, three per triangle), removing the last BLOCKER anti-pattern flagged in 01-VERIFICATION.md.

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove HWND typing from core** - `309a7e4` (refactor)
2. **Task 2: Resolve TBD debt marker on model_t.count** - `ff51566` (docs)

## Files Created/Modified
- `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c` - `setWindowId` takes `void *native_drawable`; id path builds drawable via `(void *)(intptr_t)hwndId`; added `<stdint.h>`; reworded id-cast comment to drop the HWND token.
- `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.h` - `setWindowId` prototype changed to `int setWindowId(void *native_drawable);`.
- `integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h` - replaced bare `// TBD ??` on `model_t.count` with a concrete definition comment (comment-only).

## Decisions Made
- Used standard-C `intptr_t` (via `<stdint.h>`) instead of the Win32 `INT_PTR` typedef so the int->drawable widening carries no platform token in core.
- Preserved the exact `(void *)(intptr_t)hwndId` widening semantics — behavior-preserving per D-05; the fragile int cast is deliberately left for full replacement by pathname resolution in Phase 2 (RND-02).
- Resolved `model_t.count` with a concrete definition (usage is unambiguous: vertex count for `glDrawArrays`, incremented by 3 per triangle at PLY load) rather than a formal follow-up reference.
- Left `gfx_backend.h`, `gfx_backend_wgl.c`, and `def_ZARF_9.h`'s `#include <windows.h>` untouched — all explicitly out of scope for this gap plan.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Both BLOCKER gaps from 01-VERIFICATION.md are closed on this macOS box via static/source verification; Phase 1 is auditable-complete on the seam-completeness and no-debt-marker truths.
- **Deferred (unchanged):** Windows MSVC rebuild + D-06 render parity (CMP-01) remains pending in `.planning/todos/pending/phase-01-windows-validation.md`. The committed `tkogl2.dll` predates this refactor and must be rebuilt from post-seam source off-box before shipping (threat T-01-05-01).
- Phase 2 (RND-02) will replace the `(void *)(intptr_t)` int cast with pathname-based drawable resolution.

## Self-Check: PASSED

- FOUND: integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c
- FOUND: integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.h
- FOUND: integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h
- FOUND commit: 309a7e4 (Task 1)
- FOUND commit: ff51566 (Task 2)
- Seam-boundary scan over src/ (excluding gfx_backend_wgl.c): empty
- TBD scan over def_ZARF_9.h: empty
- Lifecycle order gfx_create -> gfx_make_current -> ogl_init: preserved

---
*Phase: 01-aqua-tk-deployment-gate-windows-rendering-seam*
*Completed: 2026-07-13*
