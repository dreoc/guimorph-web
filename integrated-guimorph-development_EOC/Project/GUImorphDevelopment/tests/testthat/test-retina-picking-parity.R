# Retina picking-parity gate -- RETIRED at Phase 6 (D-04).
#
# These checks read the native tkogl2 C/Objective-C backend sources
# (gfx_backend_nsgl.m, tcl_dispatch.c) to prove Retina backing-pixel parity in
# the native pick path. Phase 6 deleted the entire tkogl2/ build tree (Plan
# 06-07), so the sources are gone and the PICK-03 oracle they supported is
# closed as WON'T-VERIFY (D-04). Retained as a single documented skip so the
# closure is visible in the suite rather than silently dropped.

test_that("retina picking-parity gate is closed as won't-verify (D-04)", {
  skip("native tkogl2 Retina backend retired at Phase 6 -- won't-verify (D-04)")
})
