# Pitfalls Research

**Domain:** Porting a Win32/WGL OpenGL engine (embedded in Tcl/Tk, driven from R) to macOS
**Researched:** 2026-07-12
**Confidence:** HIGH (macOS OpenGL profile/header/Retina/dylib facts confirmed against Apple archive docs, Tcl/Tk `macosx/README`, and Apple Developer forums; R-event-loop + Tk NSView embedding specifics are MEDIUM)

> Scope note: this document is deliberately specific to *this* engine — fixed-function/immediate-mode OpenGL, embedded into a Tk frame's native window, loaded by Tcl's `load` inside an R process, distributed as a prebuilt binary. The team was already burned once by a "links fine, renders black" failure (MinGW-w64 on Windows). Every pitfall below is chosen because it reproduces or resembles that signature on macOS, or blocks the port outright.

## Critical Pitfalls

### Pitfall 1: Requesting a Core (3.2+) profile — fixed-function engine renders nothing

**What goes wrong:**
The context is created successfully, the DLL/dylib loads, `glGetError` is clean, but the mesh is **black/blank** and no markers appear. This is the exact same signature as the MinGW black-mesh bug — "links but renders nothing" — reappearing for a new reason.

**Why it happens:**
macOS offers only two profiles: **legacy 2.1** (full fixed-function pipeline) or **core 3.2+** (fixed-function *removed and prohibited from being re-added via extensions* — Apple's words). This engine is immediate-mode/fixed-function: `glBegin/glEnd`, `glVertex*`, `glColor*`, `glMatrixMode`, `glTranslatef`, `gluUnProject`, client vertex arrays, the accumulation/aux buffers. Under a core context every one of those calls silently no-ops or errors and **nothing draws**. Teams pick core "because it's modern," or inherit it accidentally (see Pitfall 2).

**How to avoid:**
Explicitly request the **legacy profile** for the port. With NSOpenGL that means `NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersionLegacy`; with CGL `kCGLOGLPVersion_Legacy`. Legacy caps you at OpenGL 2.1 on macOS — that is fine, the engine predates 3.x. Do **not** attempt a core-profile rewrite of the draw code as part of the *port* milestone; that is a separate, much larger project (rewrite to VBO/VAO + GLSL 1.5 shaders) and is explicitly out of scope per PROJECT.md.

**Warning signs:**
`glGetString(GL_VERSION)` returns a `3.2`/`4.1` string with `Core Profile` in it; a lone `glBegin` immediately sets `GL_INVALID_OPERATION`; the very first triangle of a smoke test never appears.

**Phase to address:**
Rendering-approach decision phase (lock "legacy 2.1 profile" as a hard requirement) and the render-path phase.

---

### Pitfall 2: Adopting GLFW/SDL and inheriting a core/forward-compatible context by default

**What goes wrong:**
The team picks a portable windowing layer (GLFW or SDL) to avoid writing Cocoa glue, gets a window and a context, and the mesh renders black — again the "links but nothing draws" signature, now caused by the toolkit's defaults rather than the engine.

**Why it happens:**
On macOS a **default** `NSOpenGLView`/`[NSOpenGLView defaultPixelFormat]` actually gives you a *legacy 2.1* context, which is what this engine needs. But GLFW and SDL, to expose modern GL on macOS at all, require you to explicitly request `3.2 core + forward-compatible`; if you request anything ≥ 3.0 on macOS they force `GLFW_OPENGL_FORWARD_COMPAT` / core, which strips fixed-function. Worse, GLFW/SDL create their *own* top-level window with their *own* run loop — which fights Tk's event loop and does not embed in the Tk frame (see Pitfall 5).

**How to avoid:**
If GLFW/SDL is chosen, request **exactly** `GLFW_CONTEXT_VERSION_MAJOR=2, MINOR=1` (no forward-compat, no core profile hint) so you land on legacy fixed-function. But strongly prefer **native NSOpenGL/CGL glue** here: it defaults to legacy 2.1, it embeds into Tk's NSView hierarchy, and it does not introduce a competing run loop. The portable-layer convenience is a trap for a fixed-function engine that must live inside Tk.

**Warning signs:**
`glfwWindowHint(GLFW_OPENGL_PROFILE, ...)` set to core anywhere; a separate OS window appears *next to* the Tk window instead of inside the digitizing frame; GLFW/SDL "failed to create context" only when you downgrade the version hint.

**Phase to address:**
Rendering-approach decision phase — this is the "portable layer vs native glue" fork flagged in PROJECT.md. Recommend native NSOpenGL/CGL.

---

### Pitfall 3: The window/context handoff — replacing Win32 `HWND`+`WGL` with the wrong macOS primitive

**What goes wrong:**
The engine embeds GL into a Tk frame's native window via `HWND` + WGL device context (`tcl_window.c`). On macOS there is no `HWND` and no `wglMakeCurrent`. Teams either (a) create a standalone Cocoa/GLFW window (loses embedding — the viewport floats free of the digitizing UI), or (b) grab the wrong handle from Tk and crash or draw into nothing.

**Why it happens:**
`tcl_window.c` assumes a single Win32 window handle and a WGL `HDC`. The macOS equivalent is: get the Tk widget's `NSView` (via `Tk_MacOSXGetNSViewForDrawable` / the drawable of the Tk window), attach an `NSOpenGLContext` to it (or add an `NSOpenGLView` subview), and use `[ctx makeCurrentContext]` + `[ctx flushBuffer]` instead of `wglMakeCurrent` + `SwapBuffers`. This is genuinely new code, not a `#ifdef` sprinkle.

**How to avoid:**
Isolate all windowing behind a thin platform seam (create-context, make-current, resize, swap, destroy) and implement a macOS backend using the Tk-provided `NSView`. Draw to the **same NSView Tk owns** so the viewport stays embedded and respects Tk geometry. Use `[NSOpenGLContext flushBuffer]` for double-buffered present — `glFlush`/`glFinish` alone will not present, giving (yet again) a blank viewport.

**Warning signs:**
You find yourself calling `NSApp run` or `[[NSWindow alloc] init]` (you should be reusing Tk's window); a separate window appears; resizing the Tk frame does not resize the GL surface; the first frame never presents.

**Phase to address:**
macOS window/context glue phase (the core cross-platform work).

---

### Pitfall 4: Retina backing-scale mismatch → mesh in a corner, offset/blank picking

**What goes wrong:**
On a Retina display the mesh renders into only the bottom-left **quarter** of the viewport (or is squished), and — more damaging for a digitizer — **double-click landmark placement lands in the wrong spot or picks nothing**. Because picking is the core value ("place landmarks correctly"), this is a parity-breaking bug even when the mesh *looks* fine.

**Why it happens:**
Retina backing scale is typically 2.0: one point = two pixels. `glViewport` and `glReadPixels`/`gluUnProject` need **pixels**, but Tk/Cocoa report widget geometry and mouse coordinates in **points**. Passing `[view bounds]` (points) to `glViewport` covers only 1/4 of the surface. Passing point-space mouse coords into `gluUnProject`/`glReadPixels` (which read the pixel-space framebuffer) yields an offset that grows toward the top-right, or reads an empty region → "blank picking."

**How to avoid:**
Set `wantsBestResolutionOpenGLSurface = YES` on the GL view, then convert with `[view convertRectToBacking:[view bounds]]` for the viewport and `convertPointToBacking:` for mouse coordinates before any `glViewport`, `glReadPixels`, or `gluUnProject`. Do **not** hardcode `* 2` or read `backingScaleFactor` directly (breaks on mixed 1×/2× multi-monitor setups and when a window is dragged between displays) — use the `convert*ToBacking:` conversions, which Apple documents as the correct, display-aware path. The R↔C picking bridge (`addDot(e,x,y)` → `add("landmark", x,y,z)`) must pass coordinates already in the same space the C picking code samples.

**Warning signs:**
Mesh occupies a rectangular sub-region of the canvas; landmark markers drift further from the cursor toward one corner; picking works at window origin but fails near edges; behavior changes when the window moves to an external non-Retina monitor.

**Phase to address:**
Input & picking phase (co-locate with the coordinate-conversion bridge work).

---

### Pitfall 5: Cocoa main-thread / run-loop violations against Tk's event loop

**What goes wrong:**
Intermittent crashes, hangs, "not on main thread" AppKit assertions, or a viewport that never redraws — especially when GL setup or drawing is triggered from an R callback or a background thread.

**Why it happens:**
No Cocoa/AppKit call is thread-safe; NSOpenGL context creation and drawing **must** happen on the main thread. Critically, **Tk on macOS does not run `[NSApp run]`** — it drives Cocoa manually via repeated `Tcl_DoOneEvent`/`TkDoOneEvent` calls and manages the autorelease pool itself (per Tk's `macosx/README`). R adds another layer: the R REPL/event loop pumps Tcl events via the `tcltk` integration. So GL work must ride on the *same* main thread that R+Tk are pumping, inside that event cycle, with an autorelease pool in scope. Spinning your own thread or your own `NSApp run` loop for rendering deadlocks or double-drives the queue.

**How to avoid:**
Do all context creation, `makeCurrent`, draw, and `flushBuffer` on the main thread, invoked from Tk event/callback handlers (the same path the Windows build already uses). Never start a render thread. Do not call `[NSApp run]`. Wrap GL/Cocoa work so an `NSAutoreleasePool` is active (Tk provides one during its event cycle; if you enter Cocoa outside that cycle, create a local `@autoreleasepool`). Trigger redraws by requesting them through Tk (e.g. mark the widget dirty / schedule via the Tcl event loop) rather than driving frames yourself.

**Warning signs:**
`-[NSView ...] called from a background thread` console warnings; the app freezes when the mesh should redraw; leaks/growing memory during interaction (missing autorelease pool); works in a standalone C test harness but hangs under R.

**Phase to address:**
macOS window/context glue phase; verify explicitly during the render-path phase under a real R+Tk session (not a standalone harness).

---

### Pitfall 6: Building a `.so`/bundle instead of a Mach-O `.dylib` — Tcl `load` rejects it

**What goes wrong:**
The build succeeds, but `tcl("load", file, "Tkogl2")` fails at package load with `not a Mach-O library file, bad filetype value` (or the package "loads" but 3D is dead because `.onLoad` swallows the failure with a `warning()` and continues — see the documented silent-degrade behavior in CONCERNS.md).

**Why it happens:**
This engine is **loaded by Tcl's `load`**, not by R's `dyn.load` (see `.onLoad` → `tcl("load", file, "Tkogl2")`). Tcl's loader on macOS wants a proper Mach-O **shared library** built with `-dynamiclib` and the extension returned by `[info sharedlibextension]` = **`.dylib`**. Two classic mistakes: (1) building a **bundle** (`-bundle`) — loadable via `dlopen` but historically finicky for Tcl and not what `[info sharedlibextension]` yields; (2) copying Linux habits and producing a `.so`. Note the confusing macOS trivia: R's *own* package objects use `.so`, and `.so`/`.dylib` can be technically interchangeable via `dlopen` — but Tcl's `load` specifically expects a `.dylib` here, so don't rely on that equivalence.

**How to avoid:**
Build with `-dynamiclib`, name the artifact `tkogl2.dylib`, and place it where `.onLoad` looks (mirror the Windows `inst/libs/x64/` layout with a macOS arch dir). Have the R loader compute the extension via Tcl's `[info sharedlibextension]` rather than hardcoding `.dll`, so the same `.onLoad` works cross-platform. Make `.onLoad` **fail loudly** (or at least detect and surface) when the load fails on macOS instead of silently degrading — the current warn-and-continue path will mask this exact mistake.

**Warning signs:**
`bad filetype value` / `not a Mach-O library file` in the Tcl load error; `file tkogl2.dylib` reports `bundle` not `dynamically linked shared library`; `otool -hv` shows `MH_BUNDLE` instead of `MH_DYLIB`; package loads but the viewport is dead and only a `warning()` was printed.

**Phase to address:**
Build, load & distribution phase.

---

### Pitfall 7: Gatekeeper quarantine + hardened-runtime library validation blocks the downloaded `.dylib`

**What goes wrong:**
It works on the build machine but fails for end users who downloaded the package: the dylib is blocked, or refuses to load into the R process with `code signature ... not valid for use in process` / "cannot be opened because the developer cannot be verified."

**Why it happens:**
Two distinct macOS mechanisms bite:
1. **Quarantine** — any file downloaded via a browser gets the `com.apple.quarantine` extended attribute; macOS refuses to run/load unsigned quarantined binaries. (Files fetched via `curl`/`scp`/`git`/`install.packages` from CRAN-style sources typically are *not* quarantined, which is why it "works for me" but not for a user who downloaded a zip.)
2. **Library validation** — if the host process (R, or a notarized launcher) runs with the Hardened Runtime, the dynamic linker only loads code signed by Apple or with the **same Team ID**. A third-party-signed or unsigned `tkogl2.dylib` loaded into that process is rejected unless the host opts out via `com.apple.security.cs.disable-library-validation`.

**How to avoid:**
At minimum **ad-hoc sign** the dylib (`codesign -s -`) so it isn't "completely unsigned." For real distribution, sign with a **Developer ID Application** cert and **notarize**, so quarantined downloads pass. Because the loader is R (which the team doesn't control/sign), prefer distribution channels that don't set quarantine (build-from-source via `R CMD INSTALL`, or CRAN-style install) and **document the `xattr -dr com.apple.quarantine` / right-click-Open workaround** as an explicit fallback in BUILD.md. Do not apply entitlements to the dylib itself — entitlements only work on main executables; signing library code with them causes a code-signing crash.

**Warning signs:**
Works from a local build but a beta tester reports "damaged / can't be opened"; `spctl`/`syspolicy_check` flags the file; `codesign -dv tkogl2.dylib` shows "code object is not signed at all"; failure only after downloading via Safari/Chrome, not after `curl`.

**Phase to address:**
Build, load & distribution phase (signing/notarization + documented user workaround).

---

### Pitfall 8: Wrong GL header path / deprecation-warning handling on macOS

**What goes wrong:**
Compilation fails with missing `GL/gl.h`, or the build is buried under hundreds of `'glTranslatef' is deprecated` warnings that hide real errors — and someone "fixes" it by suppressing warnings so aggressively that a *genuine* future removal goes unnoticed.

**Why it happens:**
macOS puts GL headers under the framework path: `<OpenGL/gl.h>`, `<OpenGL/glu.h>`, `<GLUT/glut.h>` — not `<GL/gl.h>`. The engine unconditionally `#include <windows.h>` and Windows GL headers (`def_ZARF_9.h`). Every fixed-function call is flagged deprecated since 10.14, producing overwhelming warning noise.

**How to avoid:**
Add a platform `#ifdef __APPLE__` header block: define `GL_SILENCE_DEPRECATION` **before** any GL/GLUT include, then include `<OpenGL/gl.h>`/`<OpenGL/glu.h>`. Link with `-framework OpenGL` (and only `-framework GLUT` if genuinely needed — see Pitfall 9). Use `GL_SILENCE_DEPRECATION` (targeted) rather than blanket `-Wno-deprecated-declarations`, and keep a periodic un-silenced build to notice if Apple ever escalates deprecation to removal.

**Warning signs:**
`fatal error: 'GL/gl.h' file not found`; thousands of deprecation warnings on first macOS build; `windows.h` include errors.

**Phase to address:**
macOS window/context glue phase (build-system + header seam), early.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems for this port.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Adopt GLFW/SDL to skip Cocoa glue | Fast context on screen | Separate window (no Tk embedding), competing run loop, core-profile default → black mesh; long-term maintenance of a heavyweight dep | Only if it can embed in Tk's NSView **and** be forced to legacy 2.1 — otherwise never |
| Rewrite draw code to core 3.2 "while we're here" | "Modern," survives eventual GL removal | Explodes the port into a full renderer rewrite (VBO/VAO/GLSL); out of scope per PROJECT.md; high risk of parity regressions | Never during the port milestone; a separate future milestone |
| Keep `.onLoad` warn-and-continue on macOS load failure | Package still "loads" | Masks the dylib/quarantine/arch failure as a dead-but-silent viewport (the very bug you're hunting) | Never on the primary platform being ported |
| Hardcode Retina scale `*2` | One-line viewport fix | Breaks on 1× external monitors, mixed-DPI, window drag between displays | Never — use `convertRectToBacking:` |
| Ship an unsigned/ad-hoc dylib | No cert/notarization setup | Blocked for any user who downloads via browser; support burden | Acceptable for internal beta with documented `xattr` step; never for public release |
| Leave unsafe PLY parser (`strcpy`/`sscanf`/overlapping copy) as-is on the port | No parser work | The port is the ideal moment to catch it under ASAN/UBSan on clang; carrying UB across platforms risks new-platform-only crashes | Only if parser hardening is explicitly deferred to its own tracked phase |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Tcl `load` of the native lib | Building `.so`/bundle; hardcoding `.dll` in `.onLoad` | Build `-dynamiclib` → `.dylib`; compute extension via `[info sharedlibextension]` |
| Tk frame ↔ GL context | Creating a standalone NSWindow/GLFW window | Attach `NSOpenGLContext` to Tk's existing `NSView` (`Tk_MacOSXGetNSViewForDrawable`) |
| R + Tk event loop | Rendering on a background thread or calling `[NSApp run]` | Drive GL on the main thread inside the Tcl/Tk event cycle; no custom loop |
| Double-buffer present | Porting `SwapBuffers`/`glFlush` verbatim | Use `[NSOpenGLContext flushBuffer]` |
| GLUT shim | Pulling in real GLUT for windowing/`glutMainLoop` | Drop GLUT windowing; GLUT is deprecated on macOS and owns its own run loop — keep only any pure-math helpers, provide GL context via NSOpenGL/CGL |
| Apple Silicon build | Building x86_64-only, mismatching R's arch | Build **universal2** (arm64 + x86_64); GL runs via a Metal wrapper on arm64 — test rendering there, not just Intel |
| Codesigning | Applying entitlements to the dylib | Entitlements go on main executables only; sign the dylib with Developer ID + notarize (no entitlements on library code) |

## Performance Traps

Small-scale tool (single researcher, one specimen at a time), so scale is modest — but a few macOS-specific traps exist.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Immediate-mode redraw of large meshes | Sluggish rotate/zoom on dense PLY under the Metal-wrapped legacy path on Apple Silicon | Acceptable for the port; if painful, batch into client vertex arrays (still legacy-compatible) before any core rewrite | High-vertex meshes (100k+), pronounced on arm64 wrapper |
| Redraw-per-event without coalescing | UI lag while dragging landmarks | Coalesce redraws through the Tk event loop; one `flushBuffer` per cycle | Rapid interaction |
| `glReadPixels` picking every mouse move | Pipeline stall (readback forces GPU sync) | Only read on click, not on move; read the minimal region in backing pixels | Continuous hover-picking |

## Security Mistakes

Threat model is low (researcher opens their own/collaborators' local files), but the port is the moment these become clang-detectable.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Carry the unsafe PLY parser across platforms | Overlapping `strcpy` (UB), unchecked `sscanf`/`fgets`, `ftell*sizeof(float)` int-overflow, file-declared counts driving loops → crash/overflow on malformed/downloaded `.ply` | Port under clang **ASan + UBSan**; replace `strcpy`→`memmove`, `sscanf`→bounded parse, `sprintf`→`snprintf`; validate `vertexNum`/`faceNum` against file size |
| `sprintf` into fixed global buffers with filename data | Overflow via long file paths (macOS paths differ from Windows) | `snprintf` with `sizeof` bounds throughout |
| Disable library validation broadly to "make loading work" | Weakens the R host process's code-loading guarantees | Prefer proper signing/notarization; only touch validation as a last resort and document it |
| Ship a binary dylib with no checksum/signature (mirrors current Windows DLL practice) | Supply-chain trust rests on an unverified binary | Publish a checksum; sign + notarize the release dylib |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| GL viewport in a separate floating window (GLFW/SDL) | Digitizing feels broken — canvas detached from controls | Embed in the Tk frame; keep the single-window workflow parity |
| Silent dead viewport when dylib fails to load | User sees UI but mesh never appears; blames the whole app | Surface a clear error (arch/quarantine/signature) instead of warn-and-continue |
| Retina picking offset | Landmarks land off-target; researcher mistrusts the data | Backing-store coordinate conversion so picks are pixel-accurate |
| rgl result-plot windows opening behind the Tk window | User thinks plotting failed | Known Windows quirk (README); verify/raise plot windows on macOS too |

## "Looks Done But Isn't" Checklist

- [ ] **Mesh renders:** A triangle/mesh actually appears — verify against the *known* black-screen failure; confirm `GL_VERSION` is legacy 2.1, not core.
- [ ] **Picking accuracy on Retina:** Landmarks land under the cursor on a 2× display **and** on a 1× external monitor — verify with `convertPointToBacking:` in the path.
- [ ] **Runs inside R+Tk, not just a harness:** Verify in a real `GUImorph()` session on the main thread — a standalone C test can hide run-loop/thread bugs.
- [ ] **Loads as `.dylib`:** `otool -hv` shows `MH_DYLIB`; `.onLoad` computes the extension, doesn't hardcode `.dll`.
- [ ] **Loads for a *downloaded* copy:** Test with `com.apple.quarantine` set (download via browser), not just a local build.
- [ ] **Universal binary:** `lipo -info` shows both `arm64` and `x86_64`; rendering verified on Apple Silicon (Metal-wrapped), not only Intel.
- [ ] **Present path:** Double-buffer uses `flushBuffer`; single frame actually presents.
- [ ] **Windows build still works:** macOS changes are `#ifdef`-gated; the MSVC DLL path is unbroken (additive-not-replacement constraint).
- [ ] **`.dgt`/`.csv`/`.rds` cross-platform:** Files written on macOS open on Windows and vice versa.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Black mesh from core profile | LOW | Switch pixel format to legacy profile; re-verify `GL_VERSION` — no draw-code changes needed |
| Retina offset/blank picking | LOW–MEDIUM | Insert `wantsBestResolutionOpenGLSurface` + `convertRectToBacking:`/`convertPointToBacking:` at viewport and pick sites |
| Standalone window instead of embedded | MEDIUM | Rework windowing seam to attach context to Tk's NSView; drop the extra window/run loop |
| `.so`/bundle won't load | LOW | Rebuild with `-dynamiclib`, rename `.dylib`, fix loader extension logic |
| Gatekeeper/quarantine block | LOW (workaround) / MEDIUM (proper) | Immediate: document `xattr -dr com.apple.quarantine`; proper: Developer ID sign + notarize |
| Thread/run-loop crashes | MEDIUM | Move all GL/Cocoa to main thread inside Tk's event cycle; remove custom threads/`NSApp run`; ensure autorelease pool |
| Wrong-arch silent dead viewport | LOW | Build universal2; make `.onLoad` report load failure loudly |

## Pitfall-to-Phase Mapping

Phase names are topic-based (roadmap not yet authored); these should shape phase ordering and success criteria.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. Core profile → black mesh | Rendering-approach decision + render-path | `GL_VERSION` reports legacy 2.1; smoke triangle draws |
| 2. GLFW/SDL core default | Rendering-approach decision | Chosen approach embeds in Tk **and** yields fixed-function context |
| 3. HWND/WGL → macOS context handoff | macOS window/context glue | Viewport embedded in Tk frame, resizes with it, presents frames |
| 4. Retina backing-scale mismatch | Input & picking | Pixel-accurate picking on 2× and 1× displays |
| 5. Main-thread/run-loop | macOS window/context glue (verified in render-path) | No AppKit thread warnings; stable under real R+Tk session |
| 6. `.so`/bundle vs `.dylib` | Build, load & distribution | `otool` shows `MH_DYLIB`; Tcl `load` succeeds |
| 7. Gatekeeper/quarantine/signing | Build, load & distribution | Downloaded (quarantined) copy loads; signed + notarized artifact |
| 8. GL header path / deprecation | macOS window/context glue (build seam, early) | Clean compile with `OpenGL/gl.h`; noise silenced, not real errors hidden |
| PLY parser UB (carried) | Parser-hardening phase (can parallelize) | ASan/UBSan clean on malformed `.ply` fixtures |
| Universal2 / Apple Silicon | Build, load & distribution | `lipo -info` dual-arch; render verified on arm64 |

## Sources

- Apple, *About OpenGL for OS X* / *Choosing Renderer and Buffer Attributes* / *OpenGL Programming Guide for Mac* (archive) — legacy vs core 3.2 profile, fixed-function removed in core, `NSOpenGLProfileVersion3_2Core`/legacy constants. **HIGH**
- Apple, *Optimizing OpenGL for High Resolution* + *APIs for Supporting High Resolution* + `wantsBestResolutionOpenGLSurface` docs, WWDC 2012 session 245 — `convertRectToBacking:`, don't use `backingScaleFactor` directly. **HIGH**
- Apple Developer Forums (threads 650427, 694866) — OpenGL deprecated in 10.14 but still available on Apple Silicon (Metal-wrapped). **HIGH**
- StackOverflow 53562228 + dev.to macOS OpenGL setup — `GL_SILENCE_DEPRECATION` before includes, `<OpenGL/gl.h>` header path. **HIGH**
- tcltk/tk `macosx/README` — Tk does not call `[NSApp run]`; uses `TclDoOneEvent`; autorelease-pool handling; main-thread requirement. **HIGH**
- tcltk/tcl `macosx/README` + Tcl `load` man page + postgresql mailing-list thread — `.dylib` via `-dynamiclib`, bundles vs dylibs, `[info sharedlibextension]`, "not a Mach-O library" error. **HIGH**
- StackOverflow 2339679 — `.so` vs `.dylib` vs bundle on macOS (`MH_DYLIB`/`MH_BUNDLE`). **HIGH**
- Apple Developer Forums (706437 Resolving Library Loading, 706442 Trusted Execution) + ninja-build issue 1695 + SO 31709087 — quarantine attribute, library validation, `disable-library-validation` entitlement, entitlements on main executables only, `xattr` workaround. **HIGH**
- Project context: `.planning/PROJECT.md`, `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/CONCERNS.md` — engine is fixed-function, Win32/WGL embedding in `tcl_window.c`, Tcl `load` path, MinGW black-mesh precedent, unsafe PLY parser, silent `.onLoad` degrade. **HIGH**

---
*Pitfalls research for: Win32/WGL OpenGL + Tk + R engine → macOS port*
*Researched: 2026-07-12*
