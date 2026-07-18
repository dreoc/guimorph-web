---
title: "Windows rebuild + regression for Austin's Phase 4/5 merge (a98769a)"
status: pending
priority: high
resolves_phase: 5
created: 2026-07-17
updated: 2026-07-17
owner: eoc
source_plan: "04/05 (Austin) merged at a98769a"
---

## Why this exists

Austin's Phase 4 + Phase 5 work (merged into `macos-test` at `a98769a`) changed
shared C and R that compile/run on Windows, but the committed Windows binary
`inst/libs/x64/tkogl2.dll` was NOT rebuilt (only the arm64 `.dylib` was added).
So the Windows R code and the committed Windows DLL are out of sync: the new R
picking/parity path calls Tcl commands and seam functions that the stale DLL
does not contain. Nobody has verified Windows since the merge. Phase 5 criterion
5 ("Windows workflow runs unchanged") and DAT-03 (bidirectional `.dgt`
byte-compatibility) are the recurring CMP-01 checkpoint and are still open.

Off-box code review (2026-07-17) confirmed the macOS-only pieces are properly
guarded (NSGL backend; `setWindow` embed-rect + `gfx_resize`;
`getSpecimenCoordinate` backing conversion all `#if defined(__APPLE__)`;
`bindPlatformAccelerator`/`bindDeleteGesture` keep Windows Control/right-click and
only add aqua bindings on macOS). Four UNGUARDED changes alter Windows behavior
and are the focus of this validation.

## Mandatory rebuild first

The shared C changed (`gfx_backend.h` seam grew; `gfx_backend_wgl.c`,
`tcl_dispatch.c`, `tcl_window.c`, plus small edits to several `ogl_*`/`tcl_*`
TUs). Rebuild and redeploy before testing (cached direct-Tk-link config from
Phase 3 is fine; if `build-msvc` was wiped, re-pass
`-DTKOGL2_TK_USE_STUBS=OFF -DTKOGL2_TK_STUB_LIB=<abs>\tk86.lib`):

```
cd ...\Project\tkogl2
cmake --build build-msvc --config Release
copy /Y build-msvc\Release\tkogl2.dll ..\GUImorphDevelopment\inst\libs\x64\tkogl2.dll
```

Then `devtools::load_all(".")` + `GUImorph(debug=TRUE)` from the package dir.

## The four unguarded changes to judge on Windows

1. **Wheel-zoom sensitivity (likely 4x too fast).** `normalizeWheelDelta` (rtkogl.R)
   divides `%D` by 120 on all platforms; on Windows one notch (`%D=120`) becomes
   `1.0`, and `zoom()` steps every `0.25` of residual = 4 steps/notch vs the old
   1 step/notch. Scroll-zoom a specimen: does it feel ~4x too fast? If so, retune
   (raise the 0.25 threshold, or make normalize/threshold platform-aware) — likely
   an Austin follow-up.
2. **Retina near-miss pick retry (perf).** `tcl_dispatch.c` `setDot` retries up to
   24 neighboring points on a missed `dot_select`/`anchor_select`/`curve` pick,
   each a full `onDisplay()` re-render. Click empty space near/around dots on a
   large mesh: any stutter? Consider `#if defined(__APPLE__)` guarding it (its
   stated purpose is Retina tolerance).
3. **Ortho projection for portrait canvases.** `tcl_window.c` landscape branch is
   byte-identical (verified); portrait (`width < height`) now widens the vertical
   range instead of squeezing horizontal. If the window can be sized portrait,
   confirm the mesh isn't distorted/clipped.
4. **`.dgt` write-format rewrite (DAT-01/02/03).** `saveToDgt` now uses
   `.dgt_write_matrix_block` + `formatC` 6-digit + restructured
   `ID=`/`Template=`/`Surface=` blocks. Verify on Windows:
   - save a session -> reopen it in GUImorph (round-trip loads correctly);
   - an OLD (pre-merge) `.dgt` still opens;
   - run the committed parity testthat suite
     (`tests/testthat/test-dgt-cross-platform.R`, `test-export-parity.R`,
     `test-gpa-parity.R`) against the fixtures on Windows.

## Full-workflow regression (Phase 5 criterion 5)

Load a PLY (and the 6-specimen `.dgt`), then exercise: landmark + curve + surface
digitize, anchors, GPA, and export `.dgt`/`.csv`/`.rds`. Confirm unchanged vs the
Phase 3 build. Confirm Ctrl+O/S/[/]/F/Z accelerators and right-click delete still
work (they should — bindings are preserved on Windows).

## DAT-03 bidirectional gate (joint with Austin)

`.dgt` files and `.csv`/`.rds` exports must be byte-compatible both directions:
- author a `.dgt` + export on Windows -> confirm it opens/round-trips on Austin's Mac;
- take a macOS-authored `.dgt` -> confirm it opens on Windows.
The committed `tests/fixtures/parity/reference-session.dgt` /
`reference-export.csv` encode the expected bytes for the automated check.

## Acceptance

- DLL rebuilds/links clean; full workflow renders + digitizes + exports unchanged.
- The four unguarded changes are each judged acceptable-as-is or flagged for an
  Austin follow-up (record the decision here).
- Parity tests pass on Windows; DAT-03 round-trips both directions.
- Commit the rebuilt Windows `tkogl2.dll`. Then Phase 5 can close.

## Notes

- BLD-03 stays partial (arm64-only macOS engine; universal2 x86_64 + sign/notarize
  deferred). Intel-Mac + Gatekeeper distribution is not covered by this todo.
- If any unguarded change needs guarding, that's a small Austin PR, not a blocker
  on the Windows rebuild itself.
