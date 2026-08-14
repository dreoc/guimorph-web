# Source-scan gate for the digitizing wiring baked into GMW_VIEW3D_TEMPLATE
# (DGT-01 anchors + curve-by-index, DGT-02 surface cloud + delete/undo/specimen;
# plan 05-03).
#
# Pure source inspection -- no server, no browser, no sourcing of view3d.R. It
# mirrors the readLines + grepl style of test-picking-view3d.R and lives in its
# own file so it never overlaps the transport plans' test edits. See
# helper-pkg-source.R for the skip-if-source-absent idiom.

test_that("anchor placement wires a green non-raycast overlay group (DGT-01)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  # Green anchor dot (native anchor colour 0x00ff00) drawn by a dedicated helper
  # mirroring addOverlayDot.
  expect_true(any(grepl("addAnchorDot", src, fixed = TRUE)))
  expect_true(any(grepl("0x00ff00", src, fixed = TRUE)))
  # A SECOND overlay group, sibling to `overlay`, added to the scene and NEVER
  # passed to intersectObject so anchor dots are never a raycast target (T-4-07).
  expect_true(any(grepl("scene.add(anchors)", src, fixed = TRUE)))
  expect_false(any(grepl("intersectObject(anchors", src, fixed = TRUE)))
  # Anchor hit reported over the same-origin relative /anchor route.
  expect_true(any(grepl('sendBeacon("anchor"', src, fixed = TRUE)))
})

test_that("curve mode resolves clicks to landmark indices with cyan/blue recolor (DGT-01)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  # A curve segment is three landmark INDICES; the click resolves the NEAREST
  # existing overlay dot rather than raycasting the mesh.
  expect_true(any(grepl("nearestOverlayIndex", src, fixed = TRUE)))
  # First selected dot cyan rgb(1/255,164/255,191/255); second dot blue (0,0,1)
  # (the slider), matching the native onSelectCurve recolor sequence.
  expect_true(any(grepl("164/255", src, fixed = TRUE)))
  expect_true(any(grepl("191/255", src, fixed = TRUE)))
  expect_true(any(grepl("THREE.Color(0,0,1)", src, fixed = TRUE)))
  # Three distinct indices reported over the relative /curve route.
  expect_true(any(grepl('sendBeacon("curve"', src, fixed = TRUE)))
})

test_that("surface semilandmarks render as a THREE.Points cloud layer (DGT-02)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  # R-flattened surface points DISPLAYED (never recomputed in the browser) as a
  # Points layer in their own group.
  expect_true(any(grepl("addSurfaceCloud", src, fixed = TRUE)))
  expect_true(any(grepl("scene.add(surfaces)", src, fixed = TRUE)))
  expect_true(any(grepl("THREE.Points", src, fixed = TRUE)))
})

test_that("delete/undo/specimen controls post to their routes and rebuild the BVH (DGT-02)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  expect_true(any(grepl('sendBeacon("delete"', src, fixed = TRUE)))
  expect_true(any(grepl('sendBeacon("undo"', src, fixed = TRUE)))
  expect_true(any(grepl('sendBeacon("specimen"', src, fixed = TRUE)))
  # Specimen switch loads the re-served mesh and rebuilds the BVH on the NEW
  # mesh (never a stale tree, Pitfall 4). computeBoundsTree is reachable from
  # loadSpecimen.
  expect_true(any(grepl("loadSpecimen", src, fixed = TRUE)))
  expect_true(any(grepl("computeBoundsTree", src, fixed = TRUE)))
  # No beacon is ever an absolute URL (offline invariant, WEB-03).
  expect_false(any(grepl('sendBeacon("http', src, fixed = TRUE)))
})

test_that("delete/undo re-read /overlays and rebuild EVERY layer (DGT-02)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  # redraw() pulls the active specimen's re-served overlays from /overlays ...
  expect_true(any(grepl('fetch("overlays"', src, fixed = TRUE)))
  # ... and rebuilds BOTH dot layers (not just the surface cloud), so a
  # server-side delete/undo is reflected in the viewport.
  expect_true(any(grepl("rebuildDotLayer(overlay", src, fixed = TRUE)))
  expect_true(any(grepl("rebuildDotLayer(anchors", src, fixed = TRUE)))
  # The old stub target (an unregistered /redraw route that always 404'd) is gone.
  expect_false(any(grepl('fetch("redraw"', src, fixed = TRUE)))
})

test_that("toolbar drives mode + compute/export/save routes from the browser (DGT-02/DGT-03)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  # Mode buttons share the single setMode() setter with the keyboard shortcuts.
  expect_true(any(grepl("setMode(", src, fixed = TRUE)))
  expect_true(any(grepl('id="btn-c"', src, fixed = TRUE)))
  # Analytical buttons exist AND POST to the loopback routes R owns.
  expect_true(any(grepl('id="btn-ds"', src, fixed = TRUE)))
  expect_true(any(grepl('id="btn-gpa"', src, fixed = TRUE)))
  expect_true(any(grepl('id="btn-csv"', src, fixed = TRUE)))
  expect_true(any(grepl('id="btn-save"', src, fixed = TRUE)))
  expect_true(any(grepl('post("downsample")', src, fixed = TRUE)))
  expect_true(any(grepl('post("gpa")', src, fixed = TRUE)))
  expect_true(any(grepl('post("export", "csv")', src, fixed = TRUE)))
  expect_true(any(grepl('post("save")', src, fixed = TRUE)))
  # Offline invariant (WEB-03): no toolbar POST is ever an absolute URL.
  expect_false(any(grepl('post("http', src, fixed = TRUE)))
})

test_that("all digitizing JS stays in the parameter-free BODY (HEAD under the 8192-byte sprintf cap)", {
  skip_if_no_pkg_source()
  txt <- paste(
    readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE),
    collapse = "\n"
  )

  # Reconstruct the sprintf HEAD exactly as .gmw_view3d_html splits it: the
  # template literal up to and including the `MESH_URL = "%s";` marker. Every new
  # digitizing token must live AFTER the marker so the parameterised HEAD stays
  # under base-R sprintf's 8192-byte fmt cap. The HEAD region carries no
  # backslash escapes, so its source bytes equal the R string bytes.
  open_marker <- "GMW_VIEW3D_TEMPLATE <- '"
  at_open <- regexpr(open_marker, txt, fixed = TRUE)
  expect_gt(at_open, 0)
  tmpl_from <- at_open + attr(at_open, "match.length")
  tail_txt <- substring(txt, tmpl_from)

  head_marker <- 'MESH_URL = "%s";'
  at_marker <- regexpr(head_marker, tail_txt, fixed = TRUE)
  expect_gt(at_marker, 0)
  head_fmt <- substring(tail_txt, 1L, at_marker + attr(at_marker, "match.length") - 1L)
  expect_lt(nchar(head_fmt, type = "bytes"), 8192L)

  # The digitizing wiring lives in the BODY (after the marker): a couple of its
  # tokens must NOT appear in the parameterised HEAD.
  expect_false(grepl("addAnchorDot", head_fmt, fixed = TRUE))
  expect_false(grepl('sendBeacon("specimen"', head_fmt, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# Browser shell (06-02): tab strip, menu bar, status bar, reusable modal, and
# the menu/tab/nav/dialog wiring onto the Plan-01 routes. Same source-scan idiom
# as above -- the shell markup + wiring is baked into GMW_VIEW3D_TEMPLATE.
# ---------------------------------------------------------------------------

test_that("shell chrome renders a tab strip, menu bar, status bar, and modal layer (UI-01)", {
  skip_if_no_pkg_source()
  src <- readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE)

  # The four shell containers are built and appended from the BODY.
  expect_true(any(grepl('bar.id = "menubar"', src, fixed = TRUE)))
  expect_true(any(grepl('tabs.id = "tabs"', src, fixed = TRUE)))
  expect_true(any(grepl('status.id = "status"', src, fixed = TRUE)))
  expect_true(any(grepl('modal.id = "modal"', src, fixed = TRUE)))

  # Menu bar carries the File actions (Load/Add/Save/Export/Merge) and Help.
  expect_true(any(grepl("mi-load-ply", src, fixed = TRUE)))
  expect_true(any(grepl("mi-load-dgt", src, fixed = TRUE)))
  expect_true(any(grepl("mi-add-ply", src, fixed = TRUE)))
  expect_true(any(grepl("mi-save", src, fixed = TRUE)))
  expect_true(any(grepl("mi-export-csv", src, fixed = TRUE)))
  expect_true(any(grepl("mi-merge", src, fixed = TRUE)))
  expect_true(any(grepl("mi-help", src, fixed = TRUE)))

  # Tab strip carries data-tab attributes for the five Tk notebook tabs.
  expect_true(any(grepl("data-tab=", src, fixed = TRUE)))
  expect_true(any(grepl(">Digitize</button>", src, fixed = TRUE)))
  expect_true(any(grepl(">Surface</button>", src, fixed = TRUE)))

  # One reusable modal opener + closer hosts the picker, message box, color, save.
  expect_true(any(grepl("function openModal", src, fixed = TRUE)))
  expect_true(any(grepl("function closeModal", src, fixed = TRUE)))
})

test_that("all shell markup + wiring lives in the parameter-free BODY (HEAD under the 8192-byte cap)", {
  skip_if_no_pkg_source()
  txt <- paste(
    readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE),
    collapse = "\n"
  )

  open_marker <- "GMW_VIEW3D_TEMPLATE <- '"
  at_open <- regexpr(open_marker, txt, fixed = TRUE)
  expect_gt(at_open, 0)
  tail_txt <- substring(txt, at_open + attr(at_open, "match.length"))

  head_marker <- 'MESH_URL = "%s";'
  at_marker <- regexpr(head_marker, tail_txt, fixed = TRUE)
  expect_gt(at_marker, 0)
  head_fmt <- substring(tail_txt, 1L, at_marker + attr(at_marker, "match.length") - 1L)

  # The shell additions must not push the parameterised HEAD over the cap.
  expect_lt(nchar(head_fmt, type = "bytes"), 8192L)

  # No shell chrome or wiring token leaked into the HEAD fmt.
  expect_false(grepl("menubar", head_fmt, fixed = TRUE))
  expect_false(grepl("openModal", head_fmt, fixed = TRUE))
  expect_false(grepl("openPicker", head_fmt, fixed = TRUE))
  expect_false(grepl('fetch("status")', head_fmt, fixed = TRUE))

  # The HEAD carries exactly the six known sprintf slots (title, bg, bg,
  # clouds, mesh, mesh_url) -- no new %s slot was added for the shell chrome.
  slots <- gregexpr("%s", head_fmt, fixed = TRUE)[[1]]
  n_slots <- if (length(slots) == 1L && slots[1] == -1L) 0L else length(slots)
  expect_equal(n_slots, 6L)
})

test_that("specimen nav reuses the RE-SERVE switchSpecimen path (A4 not regressed)", {
  skip_if_no_pkg_source()
  src <- paste(
    readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE),
    collapse = "\n"
  )

  # The RE-SERVE primitives are still present: switchSpecimen posts /specimen and
  # loads the returned mesh URL via loadSpecimen(url).
  expect_true(grepl("function switchSpecimen", src, fixed = TRUE))
  expect_true(grepl("loadSpecimen(url)", src, fixed = TRUE))

  # Prev/next and the <select> drive switchSpecimen (never an inline index set).
  expect_true(grepl("switchSpecimen(curSpecimen - 1)", src, fixed = TRUE))
  expect_true(grepl("switchSpecimen(curSpecimen + 1)", src, fixed = TRUE))
  expect_true(grepl("switchSpecimen(Number(sel.value))", src, fixed = TRUE))
})

test_that("shell actions drive the Plan-01 routes over relative same-origin names (T-6-07)", {
  skip_if_no_pkg_source()
  src <- paste(
    readLines(file.path(pkg_source_root(), "R", "view3d.R"), warn = FALSE),
    collapse = "\n"
  )

  # Picker + dialogs + status all use the relative Plan-01 route names.
  expect_true(grepl('fetch("files")', src, fixed = TRUE))
  expect_true(grepl('post("open", name)', src, fixed = TRUE))
  expect_true(grepl('post("savepath"', src, fixed = TRUE))
  expect_true(grepl('post("msgack")', src, fixed = TRUE))
  expect_true(grepl('post("color", ci.value)', src, fixed = TRUE))
  expect_true(grepl('fetch("status")', src, fixed = TRUE))
  expect_true(grepl('fetch("tabstate")', src, fixed = TRUE))

  # Offline invariant (WEB-03/T-6-07): no shell fetch/post is an absolute URL.
  expect_false(grepl('fetch("http', src, fixed = TRUE))
  expect_false(grepl('post("http', src, fixed = TRUE))
})
