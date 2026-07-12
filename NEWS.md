# GUImorph 0.9.0

First public beta (Windows only).

## Digitizing & data integrity
- Save-safe **Add PLY to Current DGT**: adding specimens to an open dataset no
  longer drops the ones already digitized (snapshot -> grow -> replay, with a
  post-add self-check).
- **Merge DGT Files** (`mergeDgt`, `mergeDgtFiles`, File menu): combine two or
  more `.dgt` files into one dataset, refusing unless their template, curves,
  and per-specimen landmark / anchor / surface counts all match.
- Safe navigation of mixed digitized / undigitized sessions.

## 3D engine (tkogl2)
- Multi-specimen rendering, picking, `validateDot`, and surface/downsample
  handling now act on the active specimen (previously hardcoded to slot 0).
- Landmark dots render on the mesh surface in all views (marker Z-lift fix).
- Corrected the installed-package DLL load path (`.Platform$r_arch`), so the
  engine loads from a normal `install.packages`, not only `load_all`.

## Analysis
- **PCA (morphospace)** (`plotPCA`), **mean-shape** reconstruction
  (`plotMeanShape`), and aligned-specimens plotting on the GPA tab.
- Surface-semilandmark pipeline fixes; `getTemplate()` accessor. GPA runs on
  fixed landmarks + surface semilandmarks.

## Interface
- Quiet console by default; full diagnostics via `GUImorph(debug = TRUE)`.
- Proper startup banner (version, beta, Windows-only).
- "Fixed landmarks" label on the count spinbox; `GUImorph()` no longer echoes
  a stray `TRUE`.

## Context
Restores the interactive 3D template-based digitizing workflow deprecated in
geomorph 4.1 (`digit.fixed`, `digitsurface`, `buildtemplate`) - rgl-independent.

## Credits
Built on the UI modernization by Austin Lutterbach.
