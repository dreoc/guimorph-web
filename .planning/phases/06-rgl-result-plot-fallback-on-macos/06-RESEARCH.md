# Phase 6: rgl Result-Plot Fallback on macOS - Research

**Researched:** 2026-07-18
**Domain:** R / rgl WebGL (`rglwidget`) result-plot rendering on macOS from a plain R + Tk (`tcltk`) session
**Confidence:** HIGH (rgl NULL/`rglwidget` path verified live on this macOS box with rgl 1.3.36; the three plot functions audited from source)

## Summary

Three result-plot functions live in `R/3dDigitize.geomorph.r`. Two of them are 3-D and use interactive `rgl` (`plotspecs`, `plotMeanShape`); the third (`plotPCA`) is a **2-D base-graphics** scatterplot and does **not** touch `rgl` at all. On current macOS, interactive `rgl` is dead: the installed rgl build (1.3.36) reports *"This build of rgl does not include OpenGL functions"* — there is no XQuartz/GLX path to fall back onto, so the only way to draw a 3-D scene is `rgl`'s NULL device + `rglwidget()` (WebGL in a browser). `plotPCA` already works on macOS because base graphics render to the Cocoa `quartz()` device, independent of X11.

The fix is small and additive: (1) set `options(rgl.useNULL = TRUE)` on macOS before the first `open3d()`; (2) after building each 3-D scene, capture it with `rgl::rglwidget()`, write it to a temp HTML file with `htmlwidgets::saveWidget(..., selfcontained = FALSE)`, and open it with `utils::browseURL()`; (3) skip the deprecated `rgl.bringtotop(stay = TRUE)` call (it is a no-op that only warns in NULL mode). Windows keeps the exact current interactive path behind a `.isMacOS()` guard (`rtkogl.R` already has `.isMacOS()`). **No plot function uses `select3d()` or `rgl.snapshot()`**, so the NULL-mode audit criterion (ANL-02 / success criterion 2) is already satisfied — the only unsupported call in play is `rgl.bringtotop`, which is cosmetic.

**Primary recommendation:** Add one platform-guarded helper (`.rgl_show()` or similar) that on macOS emits `rglwidget()` → `saveWidget(selfcontained = FALSE)` → `browseURL()` → `close3d()`, and on Windows calls the existing `rgl.bringtotop(stay = TRUE)`. Replace the two `rgl::rgl.bringtotop(stay = TRUE)` lines with a call to it, and set `options(rgl.useNULL = TRUE)` under `.isMacOS()` at `GUImorph()` startup. Do not touch `plotPCA` beyond confirming it stays base-graphics. **Critical constraint: this box has no `pandoc`, so `selfcontained = TRUE` (the htmlwidgets/`print()` default) will error — you MUST use `selfcontained = FALSE`.**

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ANL-02 | Result visualization (aligned specimens, PCA morphospace, mean shape) works on macOS via an rgl fallback (`rgl.useNULL`/`rglwidget`) since interactive XQuartz rgl is broken on current macOS | §Standard Stack (NULL+`rglwidget`+`saveWidget`+`browseURL` sequence, verified), §Plot-Function Audit (per-function `select3d`/`rgl.snapshot`/`bringtotop` inventory), §Architecture Patterns (platform-guarded `.rgl_show()` helper), §Common Pitfalls (pandoc/selfcontained, device leak, option ordering, PCA-is-base-graphics) |
| CMP-01 | Windows build still works: result plots render unchanged on the Windows build | §Architecture Pattern 1 keeps the Windows branch byte-identical (interactive `open3d`+`rgl.bringtotop`); the macOS branch is reached only under `.isMacOS()`. Verification is off-box (D-16 recurring checkpoint). |
</phase_requirements>

> **Note — no CONTEXT.md exists for this phase.** No `/gsd-discuss-phase` decisions constrain the research. The recommendations below are the researcher's prescriptions; the planner/discuss step should confirm the display mechanism (browser vs. any RStudio-viewer nicety) and the option-setting site before locking.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Build 3-D scene (points/mesh) | R analysis layer (`3dDigitize.geomorph.r`) | rgl (NULL device) | Scene assembly is pure R geometry from `gm.results`; rgl only holds the scene graph |
| Render 3-D scene on macOS | rgl `rglwidget()` → WebGL | Browser (via `browseURL`) | No OpenGL in the rgl build on macOS; WebGL in a browser is the only working 3-D surface |
| Render 3-D scene on Windows | rgl interactive OpenGL device | — | XQuartz-free; native rgl window works, unchanged |
| Render PCA morphospace (2-D) | R base graphics → `quartz()`/`windows()` device | — | `plotPCA` is a base `plot()`; Cocoa `quartz` works on macOS without X11 |
| Choose platform path | R (`.isMacOS()` in `rtkogl.R`) | — | Single existing seam already used for wheel/dialog/shortcut parity |
| Persist + open widget HTML | `htmlwidgets::saveWidget` + `utils::browseURL` | filesystem (`tempdir()`) | Plain R+Tk session has no viewer pane; browser is the reliable sink |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `rgl` | 1.3.36 (installed, verified) | 3-D scene graph + `rglwidget()` WebGL export | Already an Import; the only supported 3-D path when OpenGL is absent `[VERIFIED: Rscript installed.packages on this box]` |
| `htmlwidgets` | 1.6.4 (installed, verified) | `saveWidget()` writes the rgl widget to standalone HTML | Direct dependency of `rgl` (already present); provides the browser-viewable artifact `[VERIFIED: tools::package_dependencies(rgl)]` |
| `utils::browseURL` | base R | Opens the widget HTML in the default browser | Works from a plain R + Tk session with no RStudio viewer `[VERIFIED: base R]` |
| `grDevices` / base `graphics` | base R | `plotPCA` 2-D scatter via `dev.new()` → `quartz()` | Base graphics render on macOS Cocoa without X11; no change needed `[ASSUMED — quartz is the macOS default device; see Open Questions]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Rvcg` | 0.25 (installed) | Ball-pivot mesh for `plotMeanShape` | Unchanged; already used to build the mesh before rgl draws it `[VERIFIED]` |
| `geomorph` | 4.1.1 (installed, meets `>= 4.1.1`) | `gm.prcomp` for PCA, `$coords`/`$consensus` for the 3-D plots | Unchanged `[VERIFIED]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `rglwidget()` + browser | Offscreen `rgl.snapshot()`/`snapshot3d()` PNG shown in a Tk photo | Requires OpenGL (absent) or `webshot2` + headless Chrome; heavier, still static; WebGL keeps interactivity (rotate/zoom) `[VERIFIED: snapshot3d in NULL mode warns and needs webshot2]` |
| `browseURL` of a temp file | `print(rglwidget())` relying on `rgl.printRglwidget = TRUE` autoprint | Autoprint fires only at REPL top-level, **not** inside a Tk button callback; and `print.htmlwidget` defaults to `selfcontained = TRUE` → needs pandoc (absent here) → errors. Explicit `saveWidget(selfcontained = FALSE)` + `browseURL` is deterministic `[VERIFIED: pandoc_available() == FALSE, selfcontained=TRUE errored]` |
| Widget in browser | Keep interactive OpenGL rgl | Not available — this rgl build has no OpenGL functions on macOS `[VERIFIED: "This build of rgl does not include OpenGL functions" printed on open3d]` |

**Installation:** No new packages. `rgl` and `htmlwidgets` are already installed (htmlwidgets is a direct rgl Import). If `htmlwidgets::` is called directly, promote it from transitive to a direct entry in `DESCRIPTION` `Imports:` for correctness (it is already on disk, so this is a manifest change, not an install).

**Version verification (run on this macOS box, 2026-07-18):**
```
rgl 1.3.36    htmlwidgets 1.6.4    geomorph 4.1.1    Rvcg 0.25    webshot2 NOT INSTALLED
```

## Package Legitimacy Audit

No **new** external packages are introduced by this phase. All libraries are pre-existing project dependencies already installed and vetted through Phase 5 (GPA/plot workflow ran with 212 live picks across rgl plots on Windows).

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `rgl` | CRAN | mature (>15 yrs) | very high | github.com/dmurdoch/rgl | OK | Already a dependency — no change |
| `htmlwidgets` | CRAN | mature | very high | github.com/ramnathv/htmlwidgets | OK | Promote transitive→direct Import (already installed via rgl) |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none
**webshot2:** intentionally **not** added — only needed for PNG snapshotting, which none of the three functions require.

## Plot-Function Audit (the ANL-02 success-criterion-2 deliverable)

All three functions live in `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r`. Read directly this session `[VERIFIED: source read + grep]`.

| Function | Lines | Uses rgl? | `open3d` | `select3d` | `rgl.snapshot`/`snapshot3d` | `rgl.bringtotop` | Verdict |
|----------|-------|-----------|----------|------------|------------------------------|------------------|---------|
| `plotspecs` (Plot Aligned Specimens) | ~374–393 | **yes** | ✅ | ❌ none | ❌ none | ✅ `stay = TRUE` (line 392) | NULL-safe once `bringtotop` is guarded; add widget emit |
| `plotPCA` (PCA morphospace) | ~395–452 | **no** | ❌ | ❌ | ❌ | ❌ | **base graphics only** (`grDevices::dev.new()`, `plot()`, `text()`) — unaffected by the rgl fallback |
| `plotMeanShape` | ~454–481 | **yes** | ✅ | ❌ none | ❌ none | ✅ `stay = TRUE` (line 480) | NULL-safe once `bringtotop` is guarded; add widget emit |

**Exact rgl usage:**
- `plotspecs`: `rgl::open3d()`; loop `rgl::points3d(aligned[,,i], ...)`; `rgl::points3d(consensus, ...)`; `rgl::aspect3d("iso")`; `rgl::rgl.bringtotop(stay = TRUE)`. All of `points3d`/`aspect3d` are fully supported in NULL mode `[VERIFIED live]`.
- `plotMeanShape`: `rgl::open3d()`; `rgl::wire3d(mesh, ...)` **or** `rgl::shade3d(mesh, ...)`; `rgl::points3d(M, ...)`; `rgl::aspect3d("iso")`; `rgl::rgl.bringtotop(stay = TRUE)`. `wire3d`/`shade3d` are supported in NULL mode `[VERIFIED: exists in rgl ns + scene builds under useNULL]`.

**Key audit result:** Neither 3-D function calls `select3d()` (interactive rubber-band selection) or `rgl.snapshot()`/`snapshot3d()`. Success criterion 2 is met with **zero rewrites of picking/snapshot logic** — the audit turns up nothing to replace. The only unsupported-in-NULL call is `rgl.bringtotop(stay = TRUE)`, which in NULL mode does not error — it emits a warning `'stay' not implemented` `[VERIFIED live]` — but it is pointless there (there is no rgl window to raise) and should be routed through the platform helper so Windows keeps it and macOS skips it.

## Architecture Patterns

### System Architecture Diagram

```
User clicks a Results button (Tk)
        │
        ▼
plotspecs(e) / plotMeanShape(e) / plotPCA(e)   [R callback, main thread]
        │
        ├── gm.results present?  ──no──▶ tkmessageBox "Run Compute first"  (unchanged)
        │                       yes
        ▼
   build scene from gm.results ($coords / $consensus / Rvcg mesh)
        │
        ├─────────────── plotPCA: base graphics ──▶ dev.new()→quartz()/windows()  (2-D, unchanged)
        │
        ▼  (plotspecs / plotMeanShape only)
   open3d(); points3d/shade3d/wire3d/aspect3d   [rgl scene graph]
        │
        ▼
   .rgl_show()  ── .isMacOS()? ──┬── NO (Windows) ─▶ rgl.bringtotop(stay=TRUE)  [interactive OpenGL window]
                                 │
                                 └── YES (macOS) ──▶ rglwidget()
                                                       │
                                                       ▼
                                          htmlwidgets::saveWidget(w, tmp.html,
                                                     selfcontained = FALSE)   [tempdir() + _files/]
                                                       │
                                                       ▼
                                          utils::browseURL(tmp.html) ─▶ default browser (WebGL)
                                                       │
                                                       ▼
                                          rgl::close3d()   [free the null device]
```

### Component Responsibilities
| File | Change |
|------|--------|
| `R/rtkogl.R` | Add `.rgl_show()` helper next to the existing `.isMacOS()` platform seam; set `options(rgl.useNULL = TRUE)` under `.isMacOS()` at `GUImorph()` startup (line ~400, right after `options(guimorph.debug=...)`) |
| `R/3dDigitize.geomorph.r` | Replace `rgl::rgl.bringtotop(stay = TRUE)` in `plotspecs` (line 392) and `plotMeanShape` (line 480) with `.rgl_show()`; leave `plotPCA` untouched |
| `DESCRIPTION` | Promote `htmlwidgets` to a direct `Imports:` entry (already installed via rgl) |
| `tests/testthat/` | Add a source-scan audit test + a headless NULL-mode `rglwidget`/`saveWidget` smoke test |

### Pattern 1: Platform-guarded display helper (RECOMMENDED)
**What:** One helper owns the "how do I show this scene" decision; the plot functions stay declarative.
**When to use:** Both 3-D plot functions.
**Example:**
```r
# in R/rtkogl.R, near .isMacOS()
# Source: rgl 1.3.36 API verified live (rglwidget + htmlwidgets::saveWidget)
.rgl_show <- function() {
  if (.isMacOS()) {
    # NULL device on macOS -> render as a WebGL widget in the browser.
    w <- rgl::rglwidget()
    f <- tempfile(pattern = "guimorph-rgl-", fileext = ".html")   # random name: no clobber
    # selfcontained = FALSE avoids the pandoc dependency (absent on target box).
    htmlwidgets::saveWidget(w, f, selfcontained = FALSE)
    utils::browseURL(f)
    rgl::close3d()          # free the null device so scenes don't accumulate
  } else {
    rgl::rgl.bringtotop(stay = TRUE)   # Windows interactive path, unchanged
  }
}
```
And set the backend option once, guarded, at startup:
```r
# in GUImorph() <- function(debug = FALSE), after options(guimorph.debug=...)
if (.isMacOS()) options(rgl.useNULL = TRUE)
```

### Pattern 2: Set `rgl.useNULL` before the first `open3d()`
**What:** `open3d()` reads `getOption("rgl.useNULL")` at call time to decide device type.
**When to use:** Always — set it before any plot runs (startup is safest).
**Example:** setting it inside `GUImorph()` startup guarantees it is in effect before any Results button can fire.

### Anti-Patterns to Avoid
- **`print(rglwidget())` / relying on `rgl.printRglwidget = TRUE` autoprint inside a Tk callback:** autoprint only triggers at REPL top level, and `print.htmlwidget` defaults to `selfcontained = TRUE` → pandoc required → error on the target box. Use explicit `saveWidget(selfcontained = FALSE)` + `browseURL`.
- **`selfcontained = TRUE`:** errors without pandoc (`pandoc_available() == FALSE` here) `[VERIFIED live]`.
- **Leaving `open3d()` scenes open in NULL mode:** every plot opens a new null device; without `close3d()` they leak across a session. Close after capturing the widget.
- **Setting `options(rgl.useNULL = TRUE)` unconditionally:** would silently break the interactive Windows window (CMP-01 regression). Guard with `.isMacOS()`.
- **Rewriting `plotPCA` to use rgl "for consistency":** it is a 2-D ordination; base graphics via `quartz` already work on macOS. Adding rgl would introduce a browser round-trip for a plot that does not need one.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Serialize an rgl scene to interactive 3-D HTML | Custom WebGL/three.js exporter | `rgl::rglwidget()` | rgl emits a complete, correct WebGL scene from the current device |
| Write a self-standing HTML bundle | Hand-assembled `<script>`/asset copying | `htmlwidgets::saveWidget(selfcontained = FALSE)` | Handles the `_files/` asset dir and dependency wiring |
| Open a file in the user's browser | `system("open ...")` shell-out | `utils::browseURL()` | Cross-platform, no shell-injection surface, respects `getOption("browser")` |
| Detect macOS | New `Sys.info()` check | existing `.isMacOS()` in `rtkogl.R` | Single seam already used for wheel/dialog/shortcut parity |

**Key insight:** rgl already ships the entire NULL→WebGL pipeline. The phase is ~15 lines of glue plus a platform guard, not a rendering project.

## Common Pitfalls

### Pitfall 1: `selfcontained = TRUE` needs pandoc (which is absent)
**What goes wrong:** `saveWidget(w, f)` or `print(rglwidget())` aborts with *"Saving a widget with selfcontained = TRUE requires pandoc."*
**Why it happens:** htmlwidgets defaults `selfcontained = TRUE` and shells out to pandoc to inline assets; this box has `pandoc_available() == FALSE`.
**How to avoid:** always pass `selfcontained = FALSE`; it produces `foo.html` + a `foo_files/` sibling dir, which `browseURL` opens fine.
**Warning signs:** the error above, or a zero-byte HTML file.

### Pitfall 2: Autoprint / `rgl.printRglwidget` does not fire inside a Tk callback
**What goes wrong:** setting `options(rgl.printRglwidget = TRUE)` and expecting the widget to pop up when a button is clicked — nothing appears.
**Why it happens:** the autoprint hook runs on REPL top-level evaluation, not inside a function body invoked from a Tk event.
**How to avoid:** explicitly build and open the widget (`rglwidget()` → `saveWidget` → `browseURL`). Note: the ROADMAP mentions `rgl.printRglwidget = TRUE`; keep it harmless/optional but do NOT depend on it for the button path.
**Warning signs:** works when you paste `plotspecs(e)` at the console but not when you click the button.

### Pitfall 3: Null devices accumulate across a session
**What goes wrong:** after many plots, memory grows and `cur3d()` points at a stale scene.
**Why it happens:** each `open3d()` opens a fresh null device; nothing closes them.
**How to avoid:** `close3d()` after capturing each widget (the helper does this).

### Pitfall 4: `rgl.useNULL` set too late / unset
**What goes wrong:** `open3d()` tries to open a real device and, on this rgl build, prints *"This build of rgl does not include OpenGL functions"* — behavior becomes build-dependent.
**Why it happens:** the option is read at `open3d()` time.
**How to avoid:** set it at `GUImorph()` startup under `.isMacOS()`, before any Results button can fire. Setting it explicitly makes behavior deterministic regardless of whether the researcher's rgl was compiled with OpenGL.
**Warning signs:** the OpenGL-functions message, or a native window attempt.

### Pitfall 5: `rgl.bringtotop` on macOS
**What goes wrong:** warning `'stay' not implemented` on every 3-D plot.
**Why it happens:** there is no rgl OS window to raise in NULL mode; `rgl.bringtotop` is also deprecated in rgl 1.x.
**How to avoid:** route it through `.rgl_show()` so only Windows calls it.

### Pitfall 6: Assuming PCA needs the rgl fallback
**What goes wrong:** effort spent making `plotPCA` a widget; success criterion 1 lists "PCA morphospace ... via rglwidget", but the code is base graphics.
**Why it happens:** the ROADMAP criterion lumps all three plots under `rglwidget`.
**How to avoid:** treat `plotPCA` as a base-graphics plot that already renders on macOS `quartz`. Confirm it opens on the Mac (human-verify); do not convert it. Flag this framing mismatch to the planner.

## Code Examples

### Emit an rgl scene as a browser widget on macOS (verified)
```r
# Source: rgl 1.3.36 + htmlwidgets 1.6.4, run live on macOS 2026-07-18
options(rgl.useNULL = TRUE)
rgl::open3d()
rgl::points3d(matrix(rnorm(30), ncol = 3), color = "red")
rgl::aspect3d("iso")
w <- rgl::rglwidget()                 # class: "rglWebGL" "htmlwidget"
f <- tempfile(fileext = ".html")
htmlwidgets::saveWidget(w, f, selfcontained = FALSE)   # ~17 KB html + _files/
utils::browseURL(f)
rgl::close3d()
```

### Guarded startup option (verified pattern)
```r
GUImorph <- function(debug = FALSE) {
  options(guimorph.debug = isTRUE(debug))
  if (.isMacOS()) options(rgl.useNULL = TRUE)   # only macOS switches to NULL/WebGL
  e <- new.env(); class(e) <- "main"; ui(e); invisible(init(e))
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `rgl.open()` / `rgl.bringtotop()` / `rgl.snapshot()` (dot-named "legacy" rgl API) | `open3d()` / object-oriented API + `rglwidget()` | rgl 0.100+ (deprecations formalized through rgl 1.x) | dot-named functions warn or are stubbed; `rgl.bringtotop(stay=)` warns `'stay' not implemented` in NULL mode `[VERIFIED]` |
| Interactive OpenGL window on macOS via XQuartz | WebGL widget via NULL device | macOS OpenGL/XQuartz decline | The rgl build here has **no OpenGL at all** — NULL/`rglwidget` is the only 3-D path `[VERIFIED]` |

**Deprecated/outdated:**
- `rgl.bringtotop`, `rgl.snapshot`, and other `rgl.*` dot-named functions — superseded by `open3d`/`snapshot3d`/etc. Not needed on the macOS path.

## Runtime State Inventory

Not a rename/refactor/migration phase — this is additive rendering-path work. One process-global state item worth noting for the planner:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Session/process state | `options(rgl.useNULL)` is a **process-global** option; once set it changes rgl behavior for the whole R session (including any other rgl use). | Set it guarded by `.isMacOS()` at `GUImorph()` startup; acceptable because the whole GUImorph session wants NULL mode on macOS. No datastore/OS/secret state involved. |
| Stored data / OS-registered / secrets / build artifacts | None | None — verified: the change touches only in-session R options and two source lines. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `rgl` | 3-D scene + `rglwidget` | ✓ | 1.3.36 (no-OpenGL build → NULL only) | — |
| `htmlwidgets` | `saveWidget` | ✓ | 1.6.4 | — |
| Web browser (`browseURL` target) | display widget | ✓ (assumed — Safari ships with macOS) | — | any browser via `getOption("browser")` |
| `pandoc` | (only if `selfcontained=TRUE`) | ✗ | — | **use `selfcontained = FALSE`** (the recommended path — pandoc not needed) |
| `webshot2` + Chrome | (only for static PNG via `snapshot3d(webshot=TRUE)`) | ✗ | — | not needed — no function snapshots |
| `geomorph` | `gm.prcomp`, aligned coords | ✓ | 4.1.1 | — |
| `Rvcg` | mean-shape mesh | ✓ | 0.25 | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** `pandoc` (avoided by `selfcontained = FALSE`); `webshot2` (not required).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `testthat` (3e), via `tests/testthat.R` → `test_check("GUImorph")` |
| Config file | `tests/testthat.R`; suites in `tests/testthat/` (11 files) |
| Quick run command | `Rscript -e 'testthat::test_dir("integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat", filter="rgl")'` |
| Full suite command | `R CMD check` or `Rscript -e 'testthat::test_local("integrated-guimorph-development_EOC/Project/GUImorphDevelopment")'` |

**Existing pattern to mirror:** `tests/testthat/test-macos-input-core.R` `source()`s `R/rtkogl.R` directly and does both behavioral asserts (`normalizeWheelDelta`) and **source-scan** asserts (grep the file for required bindings). The Phase 6 audit test should follow the same source-scan style so it passes on any OS without a display.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| ANL-02 | No 3-D plot uses `select3d`/`rgl.snapshot`/`snapshot3d` | unit (source scan) | `Rscript -e 'testthat::test_file(".../test-rgl-fallback.R")'` | ❌ Wave 0 |
| ANL-02 | `rgl.bringtotop` appears only via the platform-guarded helper (not directly in `plotspecs`/`plotMeanShape`) | unit (source scan) | same | ❌ Wave 0 |
| ANL-02 | `.rgl_show()` on macOS builds an `rglwidget` and `saveWidget(selfcontained=FALSE)` writes a non-empty `.html` | unit (headless, `skip_if_not_installed("rgl")`) | same | ❌ Wave 0 |
| ANL-02 | `options(rgl.useNULL = TRUE)` set on macOS startup only | unit (source scan for the `.isMacOS()` guard) | same | ❌ Wave 0 |
| ANL-02 | `plotPCA` remains base-graphics (no `rgl::` calls) | unit (source scan) | same | ❌ Wave 0 |
| ANL-02 | Widget visually renders/rotates in browser; PCA quartz window opens; real specimen correctness | manual (human-verify) | live `GUImorph()` session on Mac | manual |
| CMP-01 | Windows result plots render unchanged (interactive path) | manual (off-box) | Windows live session | manual |

### Sampling Rate
- **Per task commit:** the `filter="rgl"` quick run above.
- **Per wave merge:** full `testthat` suite for the package.
- **Phase gate:** full suite green + human-verify of the three plots on macOS before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `tests/testthat/test-rgl-fallback.R` — source-scan audit (no `select3d`/`rgl.snapshot`; `bringtotop` only via helper; `plotPCA` has no `rgl::`; `.isMacOS()` guards `rgl.useNULL`) + one headless NULL-mode `rglwidget`→`saveWidget(selfcontained=FALSE)` smoke test.
- No new framework install needed — `testthat` already present.

## Security Domain

`security_enforcement` is enabled (ASVS L1). Attack surface for this phase is minimal and entirely local: it renders the user's own in-session shape coordinates.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | minimal | data is numeric matrices from the user's own GPA result, not external input |
| V6 Cryptography | no | — |
| V12 Files & Resources | yes (minor) | write the widget to a **randomly named** `tempfile()` (not a fixed path) to avoid symlink/clobber in a shared `tempdir()`; open via `browseURL` (no shell), never `system("open ...")` |

### Known Threat Patterns for R + rgl/htmlwidgets on macOS
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Predictable temp filename clobber/symlink | Tampering | `tempfile(pattern="guimorph-rgl-", fileext=".html")` (random) rather than a fixed name |
| Shell injection via `system("open <path>")` | Elevation/Tampering | use `utils::browseURL()` (no shell interpolation) |
| Data exfiltration by widget assets | Info disclosure | `selfcontained = FALSE` writes local assets only; no remote CDN calls in rgl's WebGL output |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `plotPCA`'s `dev.new()` opens a working Cocoa `quartz()` window in a plain terminal/R.app + Tk session on the target Mac | Standard Stack / Pitfall 6 | Low — if the session has no display device, PCA would fail; but base graphics on macOS use quartz independent of X11, and the digitizing GUI already runs interactively. Human-verify on the Mac. |
| A2 | A default web browser is present and `browseURL` opens it from the R+Tk session | Environment Availability | Low — Safari ships with macOS; `browseURL` honors `getOption("browser")` if customized. |
| A3 | The researcher's rgl may or may not have OpenGL, so setting `rgl.useNULL=TRUE` explicitly is the robust choice | Pitfall 4 | Low — explicit option removes build-dependence; verified this box's build has no OpenGL. |

## Open Questions

1. **Display sink beyond the browser**
   - What we know: `browseURL` + `saveWidget(selfcontained=FALSE)` works headlessly and is RStudio-independent.
   - What's unclear: whether the team wants a nicer in-app surface (e.g., a Tk toplevel with an embedded webview) — out of scope for parity, browser is sufficient.
   - Recommendation: ship the browser path; revisit only if researchers dislike the browser hand-off.
2. **`plotPCA` on macOS**
   - What we know: it is base graphics, not rgl; quartz should render it.
   - What's unclear: confirmed only by code reading, not a live Mac click this session.
   - Recommendation: include a human-verify step for the PCA window; do not convert it to rgl.
3. **`rgl.printRglwidget = TRUE`**
   - What we know: the ROADMAP names it; autoprint won't fire in a Tk callback.
   - Recommendation: setting it is harmless but must not be relied on; the explicit `.rgl_show()` path is the real mechanism.

## Sources

### Primary (HIGH confidence)
- Live execution on this macOS box (2026-07-18): `installed.packages()` versions; `open3d()`/`points3d()`/`aspect3d()`/`shade3d`/`wire3d` under `options(rgl.useNULL=TRUE)`; `rglwidget()` → `htmlwidgets::saveWidget(selfcontained=FALSE)` (17.5 KB HTML written); `rgl.bringtotop(stay=TRUE)` warning `'stay' not implemented`; `snapshot3d` NULL-mode warning; `pandoc_available() == FALSE`; `tools::package_dependencies("rgl")` confirming `htmlwidgets` Import.
- Source read: `R/3dDigitize.geomorph.r` (all three plot functions), `R/rtkogl.R` (`.isMacOS()`, `GUImorph()`, `.onLoad`), `DESCRIPTION`, `tests/testthat/test-macos-input-core.R`.

### Secondary (MEDIUM confidence)
- Project planning docs: `ROADMAP.md` (Phase 6 goal + criteria + research flag), `REQUIREMENTS.md` (ANL-02), `STATE.md` (129b42a GL-context prerequisite, defect-pca-single-component fix).

### Tertiary (LOW confidence)
- None — all critical claims verified live or by source read.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions and the full NULL→widget→browser chain run live on the target OS.
- Architecture (platform-guarded helper + startup option): HIGH — mirrors the existing `.isMacOS()` seam; option semantics verified.
- Plot-function audit: HIGH — read from source + grep; `select3d`/`rgl.snapshot` absent, `bringtotop` located exactly.
- Pitfalls: HIGH — pandoc/selfcontained, autoprint, device leak all reproduced live.

**Research date:** 2026-07-18
**Valid until:** ~2026-08-17 (30 days; rgl/htmlwidgets are stable, but re-check `selfcontained`/pandoc if the target box changes).
