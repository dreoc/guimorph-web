# Phase 06 — Deferred / Out-of-Scope Items

Items discovered during execution that are **not** caused by the current plan's
changes and are therefore logged rather than fixed (executor SCOPE BOUNDARY).

## From Plan 06-07 execution (rtkogl.R deletion)

### `test-macos-dialog-shortcuts-parity.R:58` — surface.r wheel/zoom assertion is stale (pre-existing)
- **Failure:** `expect_true(any(grepl("zoom\\(e, normalizeWheelDelta\\(D\\)\\)", surface_src)))`
  is FALSE — `3dDigitize.surface.r` no longer contains a `zoom(e, normalizeWheelDelta(D))`
  wheel-binding call.
- **Root cause:** Plan **06-06** stripped the Tk builders (incl. the wheel/zoom
  binding) from `3dDigitize.surface.r`. This parity assertion (in a file last
  touched by Plan 06-04) was not repointed at that time, so it has been red since
  the 06-06 surface strip.
- **Why not fixed here:** Plan 06-07 does not modify `3dDigitize.surface.r` nor
  `test-macos-dialog-shortcuts-parity.R`; the failure is unrelated to the engine
  deletion. Fixing it would be scope creep into 06-06's territory.
- **Suggested resolution:** In Plan 08 (or a 06-06 follow-up), retire/repoint the
  `:58` surface wheel/zoom assertion to reflect that the browser now owns
  wheel-to-zoom (view3d.R), mirroring the 06-06 inversion pattern.
