# Feature Research

**Domain:** Cross-platform port of a Windows OpenGL/Tcl-Tk desktop app (3D morphometric digitizer) to macOS — "full feature parity"
**Researched:** 2026-07-12
**Confidence:** HIGH (parity scope grounded in actual codebase bindings; platform differences confirmed against Tk core docs/wiki, Tk tickets, and rgl author statements)

## What "parity" means here

This is a **subsequent milestone on an existing system**. No new user-facing features are in scope. "Feature landscape" therefore maps to three buckets the downstream requirements step asked for:

- **Table Stakes (parity)** — every Windows behavior that must reproduce on macOS. Missing any = the digitizer is broken for researchers.
- **Platform Gotchas** — Windows code that *silently misbehaves* on macOS because Tk/aqua, Cocoa, or Apple's OpenGL stack behave differently. These are the real porting work; each is tied to a concrete binding/call already in the code.
- **Deliberately Defer** — macOS-native polish that is tempting but not required for parity.

All findings are grounded in the actual bindings/dialog calls in `R/3dDigitize.*.r` and `R/rtkogl.R` (line refs included) so requirements can be written against real code, not generic advice.

## Feature Landscape

### Table Stakes (Users Expect These)

Every one of these works on Windows today and MUST work on macOS. Users give zero credit for them but the product is "broken" without any single one.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| PLY mesh renders in the embedded viewport (not black/blank) | Core value; MinGW Windows builds already render black — the #1 failure mode | HIGH | Depends entirely on the native GL-context-into-Tk-frame path (Win32 HWND+WGL → NSOpenGL/CGL or portable layer). This is the rendering milestone, not a "behavior" item; enumerated here because parity fails at step 0 without it. See STACK/ARCHITECTURE research. |
| Double-click places a landmark at the picked mesh point | Primary digitizing gesture (`<Double-Button-1>` → `addDot`) | MEDIUM | Binding itself is cross-platform. The *accuracy* of the pick is a Retina gotcha (below). |
| Left-drag rotates the model; wheel zooms | Standard 3D navigation (`<ButtonPress-1>`/`<Motion>`/`<MouseWheel>`) | MEDIUM | Drag works cross-platform. Wheel-zoom delta scaling is a gotcha (below). |
| Move a landmark by dragging it | Editing expectation | MEDIUM | Same unproject/picking path as placement; inherits the Retina pixel gotcha. |
| Right-click deletes the nearest landmark/anchor | Advertised in the UI hint "Right-click to delete" (`main.r:370-371`); bound to `<ButtonPress-3>` | LOW (once diagnosed) | **BROKEN on macOS as written** — see the button-number gotcha. This is the single highest-risk parity break because it is silent. |
| Undo (`Ctrl-Z`) reverses last placement | Standard editing (`<Control-z>`, `main.r:776`, `digitize.r:159`) | LOW | Works, but non-idiomatic on macOS (should also be `Cmd-Z`). |
| Menu/keyboard shortcuts: open, save, prev/next, fit | Windows accelerators (`<Control-o/s/f/bracketleft/bracketright>`, `main.r:771-775`) | LOW | Control bindings still fire on macOS but are non-native and `Control-click` collides with the context-menu gesture. |
| Anchors, curves (3-lmk triplets), surface-slider / template build | Full workflow tabs | MEDIUM | Same viewport/picking + button bindings as digitizing (`curve.r`, `surface.r`, `geomorph.r` all bind `<ButtonPress-3>`, `<Double-Button-1>`). Every tab inherits the same button/Retina/wheel gotchas — fix once, centrally. |
| GPA / PCA / mean-shape compute | Analysis is pure R (`geomorph::gpagen`, `gm.prcomp`) | LOW | Platform-agnostic R; no porting risk. |
| **Result plots** (Plot Aligned Specimens, PCA morphospace, Mean Shape) render on macOS | Researchers must *see* results | HIGH | **AT RISK** — these open `rgl` interactive windows, and rgl's macOS display is broken on current macOS (see gotcha). PROJECT.md's assumption "macOS renders rgl plots today" is stale as of macOS Tahoe. |
| `.dgt` save/load/merge, add-PLY | Session persistence + must stay Windows-compatible | LOW–MEDIUM | Logic is R/C and portable; risk is only in the file-dialog layer (extensions) and byte/endianness compatibility of `.dgt` (verify). |
| `.csv` / `.rds` export | Feed into geomorph | LOW | Pure R. |
| Tab gating (unlock Curves/Surface/GPA after landmarks) | Workflow guardrail | LOW | Pure R/Tk; portable. |
| File open/save dialogs for `.ply` / `.dgt` / `.pts` | Every load/save path | MEDIUM | Native NSOpenPanel behaves differently for custom extensions (see gotcha). |
| Native library loads via `.onLoad` on macOS | App won't start otherwise | HIGH | `.dylib`/`.so` built + `tcl("load", …, "Tkogl2")`. Build/toolchain item; see STACK research. |

### Platform Gotchas (Windows code that misbehaves on macOS)

These are the substantive porting tasks. Each is "table stakes" in outcome but listed separately because the *fix* is macOS-specific and the failure is **silent** (no error — just wrong behavior), which is what makes them dangerous.

| Gotcha | What breaks on macOS | Complexity | Fix / Notes |
|---------|----------------------|------------|-------------|
| **Mouse buttons 2↔3 swapped** | On Tk/aqua the **right** button sends `Button-2`, the **middle** sends `Button-3` (reverse of Windows/X11, a documented backwards-compat holdover). Every `<ButtonPress-3>` handler (right-click delete in `digitize.r:430/461`, and the no-op stubs in `curve.r:67`, `surface.r:103`, `geomorph.r:131`) fires on the **middle** button on macOS — so **right-click delete is dead** on a Mac. | LOW | Detect `[tk windowingsystem] eq "aqua"` and bind the delete handler to `<ButtonPress-2>` **and** `<Control-Button-1>` (the Mac context gesture) instead of `<ButtonPress-3>`. Best done via an abstract `event add` alias applied once. Confidence HIGH (Tcl/Tk wiki MacMice, New TkAqua FAQ, oooutlk Tk book). |
| **Retina / HiDPI pixel mismatch** | Tk/aqua reports event coords and `winfo width/height` in **points** (logical), and `tk scaling` on aqua always maps to ~100% ("the desktop engine scales everything as needed"). But the GL backing store is **2× points** on Retina (`backingScaleFactor` 2.0). If `glViewport` uses point dims, the mesh renders into the **bottom-left quadrant**; if screen→world unproject uses point coords against a pixel-sized framebuffer, **every landmark pick lands at the wrong 3D point**. | HIGH | In the native layer, size the viewport and read the pick buffer in physical pixels (`points × backingScaleFactor`, via `[view convertRectToBacking:]` / `[window backingScaleFactor]`); convert incoming Tk event x/y (points) to pixels before `gluUnProject`. Confidence MEDIUM–HIGH (Tk `tkvars.n`; Apple/GLFW HiDPI guidance). This is the item most likely to produce "it renders but picks are off by 2×." |
| **rgl interactive windows broken on current macOS** | Result plots call rgl, which draws its interactive OpenGL window through **XQuartz/X11**. On macOS Tahoe (26.x, current in 2026) XQuartz OpenGL throws `GLXBadContext`; the rgl author states X11 windows won't work and no fix is expected (Apple OpenGL deprecation + unmaintained XQuartz). So "view results" silently fails on the newest Macs. | MEDIUM | Set `options(rgl.useNULL = TRUE, rgl.printRglwidget = TRUE)` so plots render via `rglwidget()` (WebGL) in a browser/viewer pane. Caveat: `select3d()` and `rgl.snapshot()` are unsupported in NULL mode — check the plot functions don't rely on them. Confidence HIGH (rgl GH #488, r-help 2025-11, CRAN rgl README). **Flag for deeper phase research.** |
| **rgl window focus / z-order not controllable** | `rgl.bringtotop()` is documented "not currently implemented under OS/X." Secondary plot windows can open behind the main Tk window with no programmatic way to raise them. | LOW | Accept it, or (if using rglwidget/browser path) the issue is moot. Don't build custom window-raising logic. |
| **MouseWheel delta scale differs** | On Windows `%D` wheel delta arrives in multiples of 120; code divides by 120 (`geomorph.r:40` canvas scroll `as.integer(-D/120)`, zoom in `digitize.r:418`). On macOS aqua `%D` deltas are small raw integers, so `-D/120` truncates to **0** → wheel zoom/scroll does nothing. | LOW | Branch on `[tk windowingsystem]`: don't divide by 120 on aqua (use the raw delta, possibly with a small multiplier). Confidence MEDIUM (well-documented Tk MouseWheel behavior; inferred against the /120 code). |
| **File dialog: custom extensions / no type dropdown** | Native NSOpenPanel (used by `tkgetOpenFile`/`tkgetSaveFile`) **greys out or hides** files not matching `-filetypes`, and unlike Windows shows **no file-type dropdown** to switch. Custom extensions `.dgt`/`.pts` map through `UTType typeWithFilenameExtension:`; a recent Tk had a **crash** on unusual/unknown extensions (fixed in 9.x trunk, Jan 2025). Calls at `main.r:1424/1875/2713/3062/3340/3358`, `digitize.r:902`, `geomorph.r:292`. | MEDIUM | Verify the pinned Tk version includes the UTType-nil crash fix; consider adding an "All files `*`" filetype entry so `.dgt`/`.pts` are never fully hidden; confirm save dialogs append the default extension. `multiple = TRUE` (merge, `main.r:3340`) works but returns a Tcl list — verify parsing. Confidence MEDIUM. |
| **Ctrl vs Cmd accelerators** | macOS users expect ⌘-based shortcuts; the app binds `Control-o/s/z/f/[/]`. They still function (the Control key exists) but are non-native, and `Control-Button-1` is the macOS context-click — so a Control accelerator can collide with the delete gesture. | LOW | On aqua, additionally bind `<Command-…>` equivalents and set menu `-accelerator` labels to ⌘. Keep Control bindings for muscle-memory parity. Low effort, high polish. |
| **`.dgt` cross-platform byte compatibility** | Constraint: `.dgt` files must round-trip between Windows and macOS. Native (de)serialization may assume LP64/endianness/`long` sizes. | MEDIUM | Verify the `.dgt` reader/writer in the C engine uses fixed-width types and consistent endianness; add a round-trip test with a Windows-authored `.dgt`. Flag for the persistence phase. Confidence MEDIUM (inferred from C global-state design; not yet inspected). |

### Anti-Features (Commonly Requested, Often Problematic)

Things that will be tempting during the port but are **out of scope** for a parity milestone.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Rewrite the digitizer viewport to use rgl/WebGL instead of the C engine | rgl "already sort of works"; would sidestep native GL glue | Loses the pixel-accurate picking + the rgl-independent design that is the app's entire reason to exist; huge rewrite; not parity | Keep the C engine; only replace the Win32/WGL window/context glue. |
| Full macOS-native menu bar / app bundle / notarization polish | "Make it feel like a Mac app" | Scope creep beyond behavioral parity; doesn't affect whether digitizing works | Defer to a later polish milestone; ⌘ accelerators are the only cheap native touch worth doing now. |
| Multi-touch trackpad gestures (pinch-zoom, two-finger rotate) | Macs have great trackpads | New interaction model, not present on Windows → not parity; extra event plumbing | Keep wheel-zoom + drag-rotate parity; revisit later. |
| Retina "2× everything" UI asset overhaul | Sharp widgets | Tk/aqua already auto-scales widgets; only the *GL viewport* needs pixel handling | Fix the GL viewport pixel mapping only; let Tk handle widget scaling. |
| Fixing the known C-safety issues (`strcpy`/`sscanf` PLY parse, global caps) during the port | "While we're in there" | Conflates a security/refactor effort with the port; expands blast radius | Track separately (CONCERNS.md); the port should be behavior-preserving. |

## Feature Dependencies

```
Native GL context embedded in Tk frame (NSOpenGL/CGL or portable layer)   [FOUNDATION]
    └──requires──> PLY renders (not black)
                       └──requires──> Retina pixel-correct glViewport
                                          └──requires──> pixel-accurate screen->world unproject (picking)
                                                             ├──requires──> double-click place landmark
                                                             ├──requires──> drag-move landmark
                                                             └──requires──> anchors / curves / surface picking

Button 2/3 swap fix ──enables──> right-click delete (all tabs)
Control-Button-1 alias ──conflicts──> Control-key accelerators (context-click collision)
MouseWheel delta branch ──enables──> wheel zoom + GPA-panel scroll

rgl.useNULL/rglwidget path ──enables──> result plots on macOS Tahoe
    └──conflicts──> select3d() / rgl.snapshot() (unsupported in NULL mode)

Native file-dialog extension handling ──enables──> .ply/.dgt/.pts open+save
.dgt fixed-width serialization ──enables──> Windows<->macOS .dgt round-trip
```

### Dependency Notes

- **Everything picking-related depends on the Retina pixel fix.** Placement, move, curves, anchors, and surface all funnel through the same screen→world unproject. Fix it once in the native layer; do not patch per tab.
- **The button-swap fix is a single central change** (`event add` alias or a `windowingsystem` branch) that all four tabs' `<ButtonPress-3>` handlers should route through — otherwise you fix delete on one tab and forget the others.
- **`Control-Button-1` (Mac context gesture) collides with Control accelerators.** If you adopt Control-click for delete, migrate accelerators to Command to avoid a double-fire.
- **The rgl NULL/widget path conflicts with any code using `select3d()`/`rgl.snapshot()`.** Audit the three plot functions before flipping the option globally.

## MVP Definition

For a parity milestone the "MVP" is the ordered set that makes the digitizer *usable end-to-end* on macOS. Sequenced by dependency.

### Launch With (parity-critical, in order)

- [ ] Native GL context in Tk frame → **PLY renders, not black** — nothing works until pixels appear.
- [ ] Retina pixel-correct viewport + unproject — without it, rendering and picking are visibly wrong (2× offset).
- [ ] Double-click place + drag-move landmark, pixel-accurate — the core value.
- [ ] Button 2/3 swap fix → right-click delete works on all tabs.
- [ ] MouseWheel delta branch → zoom/scroll work.
- [ ] Anchors, curves, surface-slider workflows (inherit the above fixes).
- [ ] `.dgt` save/load/merge + `.ply` add via working file dialogs, Windows-compatible.
- [ ] GPA/PCA/mean-shape compute (already portable) + **result plots visible** via rgl widget fallback.
- [ ] `.csv`/`.rds` export.
- [ ] Reproducible macOS build + `.onLoad` load path.

### Add After Validation (parity polish)

- [ ] `Cmd`-based accelerators + native ⌘ menu labels alongside Control bindings.
- [ ] File-dialog "All files" fallback entry + verified default-extension append.
- [ ] Round-trip `.dgt` compatibility test (Windows-authored file opens on macOS and vice versa).

### Future Consideration (out of this milestone)

- [ ] macOS app-bundle / notarization / native menu bar — deliver behavior parity first.
- [ ] Trackpad gestures — net-new interaction, not parity.
- [ ] Migrating result plots off rgl entirely — only if the widget fallback proves inadequate.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| PLY renders (GL context glue) | HIGH | HIGH | P1 |
| Retina pixel viewport + unproject | HIGH | HIGH | P1 |
| Double-click place / drag-move picking | HIGH | MEDIUM | P1 |
| Button 2/3 swap → right-click delete | HIGH | LOW | P1 |
| MouseWheel delta branch (zoom/scroll) | HIGH | LOW | P1 |
| Result plots via rgl widget fallback | HIGH | MEDIUM | P1 |
| File dialogs for `.ply`/`.dgt`/`.pts` | HIGH | MEDIUM | P1 |
| `.dgt` / csv / rds I/O portability | HIGH | LOW–MEDIUM | P1 |
| Cmd accelerators + ⌘ menu labels | MEDIUM | LOW | P2 |
| `.dgt` round-trip compatibility test | MEDIUM | LOW | P2 |
| rgl window focus/z-order handling | LOW | LOW | P3 |
| macOS app bundle / notarization | LOW (for parity) | MEDIUM | P3 |

**Priority key:** P1 = required for parity launch · P2 = should-have polish · P3 = future / non-parity.

## Competitor Feature Analysis

Not a competitive-market question — this is a port of a single existing product to itself on a second OS. The only relevant "comparison" is Windows behavior vs required macOS behavior, captured throughout as the Table-Stakes vs Platform-Gotcha split. (Domain peers like `geomorph`'s deprecated `digit.fixed`/`digitsurface` and `Stereomorph`/`StereoMorph`, `Checkpoint`, `Landmark Editor`, `Viewbox` exist, but this milestone explicitly adds no features and does not chase them.)

## Sources

- Tcl/Tk wiki — *MacMice* and *New Tcl/TkAqua FAQ* (right button = Button-2, middle = Button-3 on aqua; context = Button-2 / Control-Button-1) — HIGH
- *Tk Tutorial — Contextual Menus* (oooutlk.github.io) and perl-tk issue #31 (button-number swap intentional passthrough) — HIGH
- Tk core docs `tkvars.n` / `tk scaling` (aqua scaling percentage always 100; desktop engine auto-scales) — MEDIUM–HIGH
- Apple `backingScaleFactor` docs + GLFW `glfwGetFramebufferSize` guidance (render to backing-store pixels, not points) — MEDIUM
- rgl GitHub issue #488, r-help mailing list 2025-11 (D. Murdoch), CRAN `rgl` README, `rgl.bringtotop` man page (X11/XQuartz broken on Tahoe; NULL/widget workaround; bringtotop not implemented on OS X) — HIGH
- Tk core ticket 080a2810 (tk_getOpenFile UTType crash on unusual extensions, fixed 2025), StackOverflow (no filetype dropdown on macOS native panel), Tk wiki *Tk differences on Mac OS X* — MEDIUM
- Codebase bindings/dialogs: `R/3dDigitize.digitize.r`, `.curve.r`, `.surface.r`, `.geomorph.r`, `.main.r` (line refs inline) — HIGH

---
*Feature research for: Windows→macOS parity port of a Tcl-Tk/OpenGL 3D morphometric digitizer*
*Researched: 2026-07-12*
