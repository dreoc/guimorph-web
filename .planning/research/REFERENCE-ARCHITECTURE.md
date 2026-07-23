# Reference Architecture: landmarking-EOC

**Status:** adopted
**Date:** 2026-07-23
**Source:** `landmarking-EOC`, a Flask + browser 2D landmarking tool by the same
author, for the same users. 27 API routes, ~170 KB server, ~110 KB single-page UI.

GUImorphWeb is the 3D version of an architecture that already works. This
document records what carries over, so later phases inherit decisions rather than
re-deriving them.

## The load-bearing decision: the server owns state

`landmarking-EOC` has zero `localStorage` and zero `sessionStorage`. The browser
is a pure view and input layer; every piece of state is fetched from or posted to
the server (`/api/image-state`, `/api/view-state`, `/api/save`).

**Adopted.** R owns the landmark arrays, the `.dgt` reader and writer, GPA, and
export. The browser sends interaction events and renders what it is given.

This is why the migration's data contract is defensible. `saveToDgt` and the
export paths are the same R code as the native path, not a reimplementation, so
DAT-01 and DAT-02 compare one writer against itself rather than two writers
against each other. A browser that never owns data cannot drift from the format.

It also means the browser can be replaced or rewritten later without touching
anything the parity suite guards.

## Port selection

`find_available_local_port()` walks forward from a preferred port for up to
`max_attempts`, then falls back to `bind(host, 0)` for an OS-assigned ephemeral
port. Bound to `127.0.0.1` throughout.

**Adopted with the order inverted.** Primary is an OS-assigned or randomly probed
free port (`httpuv::randomPort()`), because it never collides and needs no
guessing. The walk-forward-from-preferred pattern is retained as the **backup**
path, for the case where a predictable URL matters (documentation, a bookmark, a
lab machine where a fixed port has been allowed through a firewall).

## Do not auto-open the browser

`landmarking-EOC` prints the `http://127.0.0.1:PORT` URL and lets the user open
it. It never calls `webbrowser.open()`.

**Adopted as the fallback, and as the guaranteed-correct path.** WEB-04 lists a
missing, blocked, or misconfigured default browser as a realistic failure on a
managed lab machine. Printing the URL cannot fail. Attempt `utils::browseURL()`
for convenience, but always print the URL first, so a failed launch is an
inconvenience rather than a dead end.

## Offline by construction

`templates/index.html` has no external `src` or `href` references. No CDN, no
runtime fetch.

**Adopted.** WEB-03 already required this. Worth noting it is the existing habit,
not a new constraint.

## Testing technique

`tests/test_local_server_startup.py` patches `socket.socket` with a fake that
raises on the preferred port, then asserts the fallback sequence. Port selection
is tested without binding anything.

**Adopted.** The same shape works in R: inject the port-probing function, assert
the fallback order. WEB-01 and WEB-04 get real tests instead of manual checks.

## UI scaffolding already worked out

Pan and zoom off `getBoundingClientRect()`, plus `wheel`, `contextmenu`,
`keydown`, `mousedown`/`mousemove`/`mouseup`, and drag-and-drop. Multi-item
navigation via `/api/images`.

Relevant to UI-01 (browser shell) and DGT-02 (multi-specimen switching). The
interaction vocabulary is settled; only the 3D camera differs.

Concepts that map directly: `/api/anchor-contour` to anchors,
`/api/distribute` to equidistant curve or surface points, `/api/tps` to
morphometrics export.

## What does not carry over

- Everything 2D and image-specific: OpenCV, EXIF orientation, contour detection,
  livewire tracing, scale bars.
- Flask to httpuv is a rewrite, not a port. Only the route shape transfers.

## One trap

There is no `devicePixelRatio` handling anywhere in the 2D UI. On a 2D canvas
that is a sharpness compromise; it does not break coordinates.

Do not carry that assumption into 3D canvas sizing. Note that **picking is
unaffected either way**: raycasting is resolution-independent, which is exactly
why the browser path avoids the Retina backing-pixel defect class that the macOS
milestone had to fix in C (PICK-01 there).

## Effect on risk

Phases 2 and 3 are lower risk than originally scoped. The transport, port,
offline, browser-launch, and state-ownership questions all have a working answer
from the same author, the same user base, and the same workflow. This is stronger
precedent than StereoMorph, which was third-party.

Phase 4 (picking parity) is unaffected. It remains the gate.
