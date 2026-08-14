pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# UI-03 source-scan gate: the package metadata must be free of the retired
# toolkit/engine dependencies after Phase 6. These assertions read DESCRIPTION,
# NAMESPACE, and inst/libs directly (not this file's own text), so they cannot
# pass vacuously and cannot self-trip on the prose above. Forbidden tokens are
# built by concatenation for defence-in-depth. See helper-pkg-source.R.
skip_if_no_pkg_source()

# Pattern-built so the gate is a real check, never a comment-prose false hit.
tcltk_tok  <- paste0("tc", "ltk")     # matches both tcltk and tcltk2 (substring)
tcltk2_tok <- paste0("tc", "ltk2")
rgl_tok    <- paste0("rg", "l")
tkogl_tok  <- paste0("tk", "ogl2")
loaddgt_ex <- paste0("export(", "loadDgt", ")")

test_that("DESCRIPTION severs tcltk/tcltk2 from Imports, rgl from Suggests, and is 1.0.0", {
  desc <- read.dcf(file.path(pkg_root, "DESCRIPTION"))
  imports  <- if ("Imports"  %in% colnames(desc)) desc[1, "Imports"]  else ""
  suggests <- if ("Suggests" %in% colnames(desc)) desc[1, "Suggests"] else ""

  # Forbidden: no tcltk/tcltk2 anywhere in Imports (substring catches both), no
  # rgl in Suggests. Real gate -- reintroducing any of them fails this.
  expect_false(grepl(tcltk_tok, imports, fixed = TRUE))
  expect_false(grepl(rgl_tok, suggests, fixed = TRUE))

  # Positive: the retained deps stay declared, so the negative gate is not
  # trivially satisfied by an empty/renamed field.
  expect_true(grepl("geomorph", imports, fixed = TRUE))
  expect_true(grepl("Rvcg", imports, fixed = TRUE))
  expect_true(grepl("httpuv", imports, fixed = TRUE))

  expect_identical(unname(desc[1, "Version"]), "1.0.0")
})

test_that("NAMESPACE drops the tcltk imports and the loadDgt export, keeps the rest", {
  ns <- readLines(file.path(pkg_root, "NAMESPACE"), warn = FALSE)

  expect_false(any(grepl(paste0("import(", tcltk_tok, ")"), ns, fixed = TRUE)))
  expect_false(any(grepl(paste0("import(", tcltk2_tok, ")"), ns, fixed = TRUE)))
  expect_false(any(grepl(loaddgt_ex, ns, fixed = TRUE)))

  expect_true(any(grepl("import(Rvcg)", ns, fixed = TRUE)))
  expect_true(any(grepl("import(geomorph)", ns, fixed = TRUE)))
  for (ex in c("GUImorphWeb", "gmw_close", "gmw_picks", "gmw_session")) {
    expect_true(any(grepl(paste0("export(", ex, ")"), ns, fixed = TRUE)))
  }
})

test_that("no native tkogl2 binary lingers under inst/libs", {
  libs_dir <- file.path(pkg_root, "inst", "libs")
  libs <- if (dir.exists(libs_dir)) {
    list.files(libs_dir, recursive = TRUE, full.names = FALSE)
  } else {
    character(0)
  }
  expect_false(any(grepl(tkogl_tok, libs, fixed = TRUE)))
})
