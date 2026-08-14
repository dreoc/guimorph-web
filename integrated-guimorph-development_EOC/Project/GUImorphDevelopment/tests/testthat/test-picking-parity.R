# PICK-03 browser-vs-native picking-parity gate -- RETIRED at Phase 6 (D-04).
#
# The gate compared browser-replay pick coordinates against a native tkogl2
# oracle capture. Phase 6 physically deleted that engine (Plan 06-07: R/rtkogl.R,
# the inst/libs binaries, and the whole tkogl2/ build tree), so the oracle no
# longer exists and can never be captured from this package. Per D-04 the gate is
# formally closed as WON'T-VERIFY: the harness was complete and drop-in-ready --
# the gap was Windows-host availability, not code. The migration note (NEWS.md
# 1.0.0) records the closure; the deferred reviewer steps live in
# .planning/phases/05-full-digitizing-and-data-parity/05-WINDOWS-REVIEW.md.

test_that("PICK-03 picking-parity gate is closed as won't-verify (D-04)", {
  skip("PICK-03 oracle (native tkogl2) retired at Phase 6 -- won't-verify (D-04)")
})
