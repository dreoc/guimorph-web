# GUImorphWeb

## What This Is

GUImorphWeb is an R package for **3D geometric morphometrics** that renders and
digitizes in a browser surface driven from R. Load PLY mesh specimens, digitize
landmarks, curves, anchors, and surface semilandmarks, run `geomorph` analyses
(GPA, PCA, mean shape), and export coordinates in geomorph-native form.

It is a sibling project to GUImorph, not a branch of it. GUImorph digitizes
through a native OpenGL engine (`tkogl2`) embedded in a Tcl/Tk window. That
engine is maintained separately and continues on its own track. GUImorphWeb takes
the same R analytical layer and the same `.dgt` data format, and replaces the
native rendering and interaction layer with three.js in a browser, served over
loopback by `httpuv`.

The two projects share a data contract and diverge below it.

## Why This Exists

Apple retired OpenGL in 10.14 and has removed more of it in every release since.
On current macOS, `rgl` cannot load at all (missing `libGLU`), which takes any
package that lists it in `Imports` down with it. The wider R 3D ecosystem is
migrating toward WebGL widgets: the `rgl` maintainer points users to
`rglwidget()`, and the `geomorph` discussions land in the same place. Browser
rendering is the one path that is not being deprecated out from under the field
on either platform.

`StereoMorph` already does browser-based 2D digitizing inside R for this same user
base, so the pattern is established rather than novel.

## Core Value

A researcher can digitize a 3D specimen and feed the result straight into
`geomorph`, on a stock machine, with no XQuartz, no Homebrew, no compiler, no
external application, and no runtime network access.

## Architecture

R keeps what it is good at: file I/O, PLY parsing, k-means downsampling, template
warping, GPA, and export. The browser takes mesh display, orbit, picking, and
overlays.

- **Server**: `httpuv`, loopback only, serves PLY bytes over HTTP. Never
  JSON-encoded.
- **Renderer**: three.js. WebGL is the baseline target; WebGPU is opportunistic
  through three.js's automatic fallback, not a dependency.
- **Picking**: `three-mesh-bvh` raycast. Resolution-independent, so the entire
  HiDPI backing-pixel class of defect cannot occur.
- **Bundling**: JS vendored in `inst/htmlwidgets/`. No CDN. Works offline.

## Inherited From GUImorph

Carried over and reused as-is:

- The full R analytical layer (`geomorph`, `Morpho`, `Rvcg` integration)
- The `.dgt` session format, reader, and writer
- `exportGeomorph()` and the `.csv`/`.rds` export paths
- The parity test suite (`test-dgt-cross-platform.R`, `test-export-parity.R`,
  `test-gpa-parity.R`) and `tests/fixtures/parity/`
- The native `tkogl2` engine, retained temporarily as the picking-parity oracle
  and removed at Phase 6

Carried over as lessons, though the code carrying them is retired:

- Multi-model indexing defects came from operations defaulting to `models[0]`
  instead of `&models[id]`
- Flattening surface semilandmarks requires `as.vector(t(surfaces[,,id]))`; the
  transpose is not optional
- NextEngine PLY exports carry unreferenced stray vertices, including origin-null
  points at (0,0,0), which become GPA outliers if captured as template points
- Anchors are hand-placed points forced into the k-means template to guarantee
  topographically significant features are represented, not curve boundary
  markers

## Requirements

### Validated

<!-- Inherited from GUImorph, already working in the R layer. -->

- ✓ PLY specimen sets load and parse in R
- ✓ `geomorph::gpagen` GPA with sliding, principal-axis alignment, and
  tangent-space options
- ✓ `.dgt` session save, load, merge, and add-PLY
- ✓ `.csv` aligned-coordinate and `.rds` geomorph-ready export
- ✓ Cross-platform `.dgt` byte parity, Windows to macOS direction

### Active

<!-- Milestone v1.0: browser rendering migration. See ROADMAP.md. -->

- [ ] Result plots render through a three.js widget with `rgl` optional
- [ ] PLY meshes served over loopback and rendered in the browser
- [ ] Offline packaging, port selection, browser launch, and clean teardown
- [ ] Browser picking agrees with the native engine's unproject within tolerance
- [ ] Full digitizing workflow in the browser with byte-identical `.dgt` output
- [ ] Browser shell replaces the Tk chrome; native engine removed

### Out of Scope

- Maintaining the native macOS OpenGL path. That work continues in GUImorph on
  its own track and is not duplicated here.
- Metal-backed native rendering. This architecture makes it unnecessary.
- Rewriting the `geomorph` / `Morpho` / `Rvcg` analysis pipeline. Validated,
  reused as-is.
- Linux as an explicit milestone target. The architecture makes it nearly free,
  but it is not scoped or tested here.

## Relationship to GUImorph

`upstream` remote points at `dreoc/GUImorph`. R-layer fixes made there can be
cherry-picked in. Native-engine work there is deliberately not merged.

Nothing in this project should be expected to merge back into GUImorph. They
diverge at the rendering layer by design.
