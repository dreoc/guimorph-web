# Source-scan gate for the D-02 page-side tab-close beacon (WEB-04, plan 03-03).
#
# Pure source inspection -- no server, no browser, no sourcing of view3d.R. It
# mirrors the readLines + grepl style of the transport guard block, and lives in
# its own file so it never overlaps the transport plans' edits to
# test-transport.R (lets this plan run in parallel with plan 01). See RESEARCH
# Pattern 3 / Pitfall 4 and helper-pkg-source.R.

test_that("the viewport page fires a same-origin tab-close beacon", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  # The reliable-event beacon hook is present.
  expect_true(any(grepl("sendBeacon", src, fixed = TRUE)))
  expect_true(any(grepl("pagehide", src, fixed = TRUE)))
  expect_true(any(grepl("visibilitychange", src, fixed = TRUE)))

  # Pitfall 4: the deprecated/unreliable unload event is NOT registered.
  expect_false(any(grepl('addEventListener("unload"', src, fixed = TRUE)))
  expect_false(any(grepl("addEventListener('unload'", src, fixed = TRUE)))

  # WEB-03 offline-by-construction: the beacon target is the RELATIVE token
  # "close" (resolves same-origin against the page URL), never an absolute
  # http(s):// URL. The hook adds no external src=/href= reference either. The
  # plan-04 offline smoke test is the end-to-end backstop for external refs.
  expect_false(any(grepl("sendBeacon(\"http", src, fixed = TRUE)))
  expect_false(any(grepl("sendBeacon('http", src, fixed = TRUE)))
  expect_false(any(grepl('src="http', src, fixed = TRUE)))
  expect_false(any(grepl('href="http', src, fixed = TRUE)))
})
