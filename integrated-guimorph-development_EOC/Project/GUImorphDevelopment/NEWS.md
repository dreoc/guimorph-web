# GUImorphWeb 1.0.0

The browser migration is complete. GUImorphWeb now digitizes, analyzes, and
renders entirely in the browser: a local `httpuv` loopback server owns all state
and serves a `three.js` viewport, and every dialog, menu, tab, and status
readout is browser-rendered. This is the first release with the architecture
stabilized (D-05).

## Breaking changes

The native rendering and desktop-toolkit stack has been **removed**:

- The bundled native OpenGL engine (`tkogl2`, `inst/libs/*`, and the entire
  `tkogl2/` build tree) is deleted.
- `rgl` is removed from the dependencies (3-D result plots render through the
  browser `three.js` widget).
- The Tk chrome and toolkit are gone: `tcltk` and `tcltk2` are dropped from
  `Imports`. There is no native window, notebook, menu, status bar, message box,
  color picker, or file chooser — all are browser-rendered, and file open/save
  is served from R over the loopback shell (server owns the path).

## Migration for native-path users

If you depend on the native OpenGL / Tk desktop engine:

- **Primary — switch to GUImorph.** The native OpenGL/Tk project continues as a
  separately maintained package at [`dreoc/GUImorph`](https://github.com/dreoc/GUImorph)
  (the `upstream` remote). It carries the native rendering engine forward
  (D-07).
- **Fallback — pin the last engine-bundling release.** GUImorphWeb `0.10.0` is
  the final version that still shipped the native engine (D-06). Pin it with,
  e.g.:

  ```r
  remotes::install_version("GUImorphWeb", version = "0.10.0")
  # or the equivalent git-tag pin:
  # remotes::install_github("dreoc/GUImorphWeb@v0.10.0")
  ```

## Verification gates closed as won't-verify (D-04)

Deleting the native `tkogl2` engine removes the only oracle for two gates that
had been awaiting a Windows `tkogl2` capture:

- **PICK-03** — the browser-vs-native picking-parity milestone gate.
- **DAT-02** — the `.dgt` `-rewrite` byte-parity gate (a Windows re-save of an
  authored `.dgt` compared byte-for-byte against itself).

Both are now formally closed as **won't-verify**. The harnesses are complete and
were drop-in-ready — the gap is Windows-host availability, not code. The exact
deferred Windows reviewer steps are recorded in
`.planning/phases/05-full-digitizing-and-data-parity/05-WINDOWS-REVIEW.md`. The
parity reader (which accepts both platform dialects) and the automated primary
gates remain in place.
