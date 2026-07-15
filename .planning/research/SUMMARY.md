# Project Research Summary

**Project:** GUImorph — macOS cross-platform milestone (port the native Win32/WGL OpenGL + Tcl/Tk digitizing engine to macOS with full feature parity)
**Domain:** Brownfield port of a fixed-function OpenGL viewport embedded in a Tcl/Tk desktop app, loaded by R via `tcltk`
**Researched:** 2026-07-12
**Confidence:** HIGH (platform APIs, GL profile requirement, embedding model, dylib/load mechanics) / MEDIUM (the R+Aqua-Tk deployment path; rgl result-plot fallback; `.dgt` byte compatibility)

## Executive Summary

GUImorph works on Windows by embedding a fixed-function (immediate-mode) OpenGL viewport into a Tk frame via Win32 `HWND` + `WGL` (`src/tcl_window.c`), driven from R over an 8-command Tcl bridge. This milestone ports that engine to macOS at **full feature parity** without breaking Windows. All four research streams converge on one architecture: **keep everything except the window+context layer.** The `ogl_*` draw/pick code, markers, curves, the Tcl bridge, and the R/Tk GUI are portable as-is; only the WGL/HWND glue must be replaced. The recommended cut is a thin platform seam (`gfx_backend.h`: create / make_current / swap / resize / destroy) with the existing WGL code moved behind it and a new macOS backend added — a native `NSView` + `NSOpenGLContext` (CGL under the hood) obtained through Tk's private accessor `Tk_MacOSXGetNSWindowForDrawable`. GLFW and SDL are explicitly ruled out: they own their own top-level windows and cannot reliably render into someone else's Tk-owned `NSView`, and their macOS defaults push a core/forward-compatible context that would blank the fixed-function engine.

The single most important — and most surprising — finding reframes the milestone from a *GL-context* problem into a *Tcl/Tk-flavor* problem. **CRAN R on macOS uses X11 Tk via XQuartz, and XQuartz's GLX is broken on macOS Tahoe (26)** — the exact `GLXBadContext` failure that killed rgl/geomorph interactive digitizing and motivated GUImorph's existence in the first place. The native path only works if the R session runs against an **Aqua (Cocoa) Tk build**, which exposes the private `NSView` accessor that X11 Tk lacks. Determining and packaging a supported "R + Aqua Tk" configuration is therefore the **gating risk**: it must be an early spike/gate before any Cocoa/GL code is written, verified at runtime with `tk windowingsystem` returning `aqua` (not `x11`).

Beyond the gate, the risks are a well-characterized cluster that all share the team's prior "links fine, renders black" signature: (1) a core GL profile silently no-ops every fixed-function call — the macOS backend **must** request the legacy 2.1 profile; (2) Retina/HiDPI reports points not pixels, so `glViewport` and screen→world unproject must scale by the backing factor via `convertRectToBacking:`/`convertPointToBacking:` or every landmark pick is off ~2×; (3) presenting must use `[NSOpenGLContext flushBuffer]`, not `SwapBuffers`/`glFlush`; (4) all Cocoa/GL work stays on the main thread inside Tk's `TclDoOneEvent`-pumped event cycle (no `[NSApp run]`, no render thread); (5) the artifact must be a Mach-O `.dylib` (`-dynamiclib`), universal2, signed/notarized to survive quarantine and library validation. A separate batch of macOS Tk *input* quirks (button 2/3 swap breaking right-click delete, `MouseWheel %D`/120 truncating zoom to zero, native file panel hiding custom extensions) rounds out the parity work.

## Key Findings

### Recommended Stack

Reuse the existing renderer and bridge; replace only the window/context primitive with native Cocoa glue. Add `src/tcl_window_macos.m` (or `gfx_backend_nsgl.m`) exposing the same lifecycle functions the Windows path does, backed by `NSView` + `NSOpenGLContext`. Build with Xcode CLT + CMake (`APPLE` branch), linking `-framework OpenGL -framework AppKit -framework Foundation` plus Tcl/Tk stubs, and ship a universal2 (`arm64;x86_64`) `.dylib`. The whole approach hinges on the R session using an **Aqua Tcl/Tk build**, not CRAN's default X11 Tk. See `STACK.md`.

**Core technologies:**
- **Apple OpenGL 4.1 (`OpenGL.framework`)**: the GL implementation `ogl_*` renders against — deprecated since 10.14 but still present/functional on Apple Silicon + Intel in 2026, no removal date; use the **legacy 2.1 profile** for fixed-function.
- **NSOpenGL / CGL (`AppKit` + `OpenGL.framework`)**: the direct 1:1 replacement for WGL+HDC — wraps a CGL context and draws into the Tk widget's `NSView`.
- **Aqua (Cocoa) Tk 8.6.14+ (prefer 9.0.x)**: exposes `Tk_MacOSXGetNSWindowForDrawable` (public stub slot 13) + `TkMacOSXGetNSViewForDrawable`; **X11 Tk does not** and routes through broken XQuartz GLX. Tk 9.0 has better Retina support.
- **CMake ≥ 3.16 + Xcode CLT (Apple Clang, Obj-C for the `.m` glue)**: one build system across platforms; universal builds via `-DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"`.
- **GLU (bundled in `OpenGL.framework`)**: `gluUnProject`/`gluSphere` available without vendoring — lets us drop the deprecated GLUT dependency (`glutSolidSphere` → `gluSphere`).
- **Togl 2.x `TOGL_NSOPENGL`**: reference prior art for the `NSView` + `NSOpenGLContext` + `[ctx setView:]` pattern (study, or adopt wholesale).

### Expected Features

This is a parity milestone on an existing product — **no new user-facing features**. "Features" split into parity behaviors that must reproduce, and macOS gotchas where Windows code silently misbehaves. See `FEATURES.md`.

**Must have (table stakes — parity fails without any one):**
- PLY mesh renders in the embedded viewport (not black) — depends entirely on the native GL-context-into-Tk path.
- Double-click place / drag-move landmark, pixel-accurate — the core value; accuracy depends on the Retina pixel fix.
- Right-click delete landmark (all four tabs) — **silently broken on aqua** until the button 2/3 swap is fixed.
- Wheel zoom + GPA-panel scroll — **truncates to zero on aqua** until the `%D`/120 divisor is branched.
- Anchors, curves, surface-slider workflows — inherit the same picking/button/wheel fixes (fix once, centrally).
- `.dgt` save/load/merge + `.ply` add via working file dialogs; `.csv`/`.rds` export; GPA/PCA/mean-shape compute (pure R, portable).
- Reproducible macOS build + `.onLoad` load path (`.dylib`).

**Should have (parity polish, after validation):**
- `Cmd`-based accelerators + ⌘ menu labels alongside Control bindings.
- File-dialog "All files" fallback entry + verified default-extension append.
- Round-trip `.dgt` compatibility test (Windows-authored file opens on macOS and vice versa).

**Defer (out of this milestone):**
- macOS app-bundle / native menu bar / notarization polish beyond what load requires.
- Trackpad gestures (net-new interaction, not parity).
- Migrating result plots off rgl entirely; rewriting the viewport to rgl/WebGL; fixing the unsafe PLY parser as part of the port (track separately).

### Architecture Approach

Additive, minimum-blast-radius port: introduce one seam (`gfx_backend.h`) that is the *only* windowing interface the core includes, move the Windows WGL code behind it unchanged, add a macOS `.m` backend, and confine every platform `#ifdef` to backend files plus the Tk-drawable resolver in `tcl_window.c`. The crux is drawable acquisition: R must pass the frame **pathname** (not `winfo id`, which is a meaningless/negative MacDrawable pointer on aqua); C resolves `Tk_NameToWindow` → `Tk_WindowId`, then branches to `Tk_GetHWND` (Win) or `Tk_MacOSXGetNSWindowForDrawable` → `contentView` (mac). This requires adding **Tk stubs** (`Tk_InitStubs`, link `tkstub`) and vendoring Tk **private** headers. An offscreen FBO + `Tk_PhotoPutBlock` blit backend exists as a documented fallback behind the same seam if NSView embedding proves unstable. See `ARCHITECTURE.md`.

**Major components:**
1. **Platform-neutral core** (`tcl_*`, `marker.c`, `curve_*`, `ogl_*`) — mesh/marker/curve state, fixed-function draw, picking, Tcl commands; stays `#ifdef`-free, talks only to the seam.
2. **`gfx_backend.h` seam** — opaque `gfx_surface*` + create/make_current/swap/resize/destroy; one TU per platform (`gfx_backend_wgl.c`, `gfx_backend_nsgl.m`, deferred `gfx_backend_glx.c`).
3. **Tk-drawable resolver in `tcl_window.c`** — pathname → per-platform drawable; localizes the one genuinely divergent decision.
4. **R bridge (`rtkogl.R`)** — generalize `.onLoad` to compute the shared-lib extension (not hardcode `.dll`) and pass the frame pathname; select the per-OS artifact.

### Critical Pitfalls

1. **Aqua-Tk prerequisite is the real pivot (HIGH)** — the native path only works against Aqua Tk; CRAN R ships X11 Tk and XQuartz GLX is dead on Tahoe. Make it an early spike/gate; verify `tk windowingsystem eq "aqua"` at runtime.
2. **Core profile → black mesh (HIGH)** — a core 3.2/4.1 context silently no-ops every fixed-function call. Request `NSOpenGLProfileVersionLegacy` (2.1); do not attempt a core rewrite during the port.
3. **Retina backing-scale mismatch (HIGH)** — points ≠ pixels; wrong scaling puts the mesh in a quadrant and every pick off ~2×. Use `wantsBestResolutionOpenGLSurface` + `convertRectToBacking:`/`convertPointToBacking:` (never hardcode `*2`) for viewport and unproject.
4. **Present/thread violations (MEDIUM)** — use `[NSOpenGLContext flushBuffer]` (not `SwapBuffers`/`glFlush`); do all GL/Cocoa on the main thread inside Tk's `TclDoOneEvent` cycle with an autorelease pool; never `[NSApp run]` or spawn a render thread.
5. **Wrong artifact / distribution (MEDIUM)** — build a Mach-O `.dylib` (`-dynamiclib`), universal2, and stop `.onLoad` from silently degrading on load failure; ad-hoc sign at minimum, Developer ID sign + notarize for downloaded copies (quarantine + library validation), no entitlements on the dylib.

## Implications for Roadmap

Based on combined research, a dependency-ordered phase spine. Each build phase should end with a **"Windows still works"** checkpoint (additive-not-replacement constraint). The recurring theme: the seam must exist before any backend, the NSView is unreachable without pathname-based drawable resolution, and Cocoa code cannot compile without the CMake/framework scaffolding — so gate → seam → drawable → build → first light → parity.

### Phase 1: Aqua-Tk Deployment Gate + Extract the WGL Seam
**Rationale:** The whole port is dead if R can't run against Aqua Tk (X11 Tk + broken XQuartz GLX). Resolve the deployment question *before* writing GL code, and de-risk the abstraction on Windows first.
**Delivers:** A confirmed, documented supported "R + Aqua Tk" config (verified `tk windowingsystem == aqua`); `gfx_backend.h` added with all WGL/HDC/HGLRC/`SwapBuffers` code moved out of `tcl_window.c`/`onDisplay` into `gfx_backend_wgl.c`; core routed through the seam.
**Addresses:** Foundation for "PLY renders" — nothing else is reachable.
**Avoids:** Pitfall 1 (Aqua-Tk pivot), Pitfall 2 (GLFW/SDL trap — the seam makes native glue the obvious backend), Anti-Pattern 4 (scattered `#ifdef`s).

### Phase 2: Unify Tk-Drawable Resolution via Pathname + Tk Stubs
**Rationale:** The NSView is only reachable by resolving a widget pathname through Tk stubs; `winfo id` is meaningless on aqua. This is the prerequisite for reaching any macOS drawable and removes the fragile int→HWND cast already blamed for blank Windows viewports.
**Delivers:** `setWindow "id"` accepts a pathname; `Tk_NameToWindow`/`Tk_WindowId` resolution; `Tk_InitStubs` + `tkstub` linkage; R `set("window","id",frame)` passes the pathname.
**Uses:** Tk public stub `Tk_MacOSXGetNSWindowForDrawable`, `Tk_GetHWND`.
**Implements:** The Tk-drawable resolver component.
**Avoids:** Anti-Pattern 1 (casting `winfo id`).

### Phase 3: Tri-Platform CMake + Generalized `.onLoad` + Drop GLUT
**Rationale:** Cocoa code can't compile/link without framework scaffolding and vendored Tk private headers; establish the toolchain before writing Objective-C.
**Delivers:** `WIN32/APPLE/UNIX` CMake branches, `-framework OpenGL/AppKit/Foundation`, universal `CMAKE_OSX_ARCHITECTURES`, Mach-O `.dylib` naming; vendored Tk private headers; `.onLoad` computes the extension via `[info sharedlibextension]` and fails loudly; `glutSolidSphere` → `gluSphere` (removes deprecated GLUT dep).
**Uses:** CMake, Xcode CLT, GLU.
**Avoids:** Pitfall 6 (`.so`/bundle vs `.dylib`), Pitfall 8 (GL header path/deprecation), Anti-Pattern 5 (GLUT dep); sets up Pitfall 5/7 mitigation.
**Checkpoint:** macOS build compiles with a stub backend; Windows unaffected.

### Phase 4: macOS NSGL Backend — "First Light"
**Rationale:** With seam + drawable + toolchain in place, implement the actual Cocoa backend. Getting *any* correct pixels is the first real macOS risk.
**Delivers:** `gfx_backend_nsgl.m` — legacy-2.1 `NSOpenGLPixelFormat`, `NSOpenGLContext`, child `NSView` via `[contentView addSubview:]`, `makeCurrent`, `flushBuffer`, `backingScaleFactor` handling in create/resize.
**Addresses:** "PLY mesh renders (not black) on macOS."
**Avoids:** Pitfall 2 (legacy profile), Pitfall 3 (context handoff), Pitfall 5 (main-thread/run-loop), Anti-Pattern 2.
**Checkpoint:** a PLY mesh renders in the digitizing viewport on macOS.

### Phase 5: DPI-Correct Picking + Input-Behavior Fixes + Full Parity
**Rationale:** Rendering is meaningless for a digitizer until picking is pixel-accurate and macOS input quirks are fixed. Batch the aqua input gotchas here since they share the same central fix points.
**Delivers:** `viewport[3]-y` and unproject in backing pixels; landmark place/move/delete/undo, anchors, curves, surface sliders, resize; **button 2/3 swap** fix (bind delete to `<ButtonPress-2>` + `<Control-Button-1>` on aqua); **MouseWheel `%D`** branch (no /120 on aqua); file-dialog custom-extension handling (+ "All files" entry, default-extension append); ⌘ accelerators; verify `.dgt`/`.csv`/`.rds` are byte-compatible with Windows.
**Addresses:** All remaining table-stakes parity behaviors.
**Avoids:** Pitfall 4 (Retina picking), the aqua input gotchas from FEATURES.md.
**Checkpoint:** full digitizing workflow parity on macOS.

### Phase 6: rgl Result-Plot Fallback on macOS
**Rationale:** GPA/PCA/mean-shape compute is portable R, but the *result plots* open rgl interactive windows through XQuartz — broken on Tahoe. This corrects PROJECT.md's stale assumption that "macOS renders rgl plots today." Own phase because it needs its own research.
**Delivers:** `options(rgl.useNULL = TRUE, rgl.printRglwidget = TRUE)` → `rglwidget()` (WebGL) rendering; audit that plot functions don't rely on `select3d()`/`rgl.snapshot()` (unsupported in NULL mode).
**Addresses:** "GPA/PCA/mean-shape and result plots work on macOS."
**Research flag:** yes — verify the widget path is adequate and doesn't break `select3d`/snapshot usage.

### Phase 7 (Optional): Offscreen FBO + Tk-Photo-Blit Fallback
**Rationale:** Documented escape hatch if NSView embedding proves unstable across Tk 8.6/9.0. Decoupled and last.
**Delivers:** CGL + FBO + `Tk_PhotoPutBlock` backend behind the same seam.
**Checkpoint:** switchable, documented fallback.

**Parallelizable side-track — PLY parser hardening:** the unsafe PLY loader (`strcpy`/`sscanf`/`sprintf`, count-driven loops) can be hardened under clang ASan/UBSan in its own tracked phase, independent of the port spine. Keep it separate so it doesn't expand the port's blast radius.

### Phase Ordering Rationale

- **Gate first:** the Aqua-Tk deployment question invalidates the entire native approach if unresolved, so it precedes all code (Phase 1).
- **Seam before backend, drawable before NSView, toolchain before Cocoa:** hard technical dependencies (1 → 2 → 3 → 4) confirmed across ARCHITECTURE and PITFALLS.
- **Correctness after first light:** picking/input parity (5) is only meaningful once pixels appear (4).
- **rgl plots and the FBO fallback are decoupled** (6, 7) and don't block the digitizing spine.
- **Every build phase carries a Windows-regression checkpoint** to honor the additive constraint.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1:** which supported R + Aqua-Tk config actually ships to researchers (mac.r-project.org toolchain vs bundled Tcl/Tk vs MacPorts) — the milestone's central open question.
- **Phase 6:** rgl NULL/`rglwidget` fallback details and `select3d`/`rgl.snapshot` dependencies in the three plot functions.
- **Phase 5 (partial):** `.dgt` endianness / fixed-width serialization for Windows↔macOS round-trip; native file-panel UTType behavior on the pinned Tk version.

Phases with standard patterns (lighter research):
- **Phase 3:** tri-platform CMake + framework linkage + `.dylib` packaging are well-documented.
- **Phase 4:** NSOpenGL/NSView embedding has strong prior art (Togl 2.x `TOGL_NSOPENGL`).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH / MEDIUM | Rendering API, embedding limits, Tk stubs, Tcl load = HIGH (Apple docs, Tk source, Togl). MEDIUM on the exact R+Aqua-Tk deployment path and precise GL profile depending on an `ogl_*` audit. |
| Features | HIGH | Parity scope grounded in actual code bindings (line refs); platform diffs confirmed against Tk docs/tickets and rgl author statements. |
| Architecture | HIGH / MEDIUM | Platform APIs verified against Tk source + Apple docs (HIGH); phase sequencing/tradeoffs are grounded engineering judgment (MEDIUM). |
| Pitfalls | HIGH / MEDIUM | GL profile/header/Retina/dylib facts confirmed against Apple + Tcl/Tk `macosx/README` (HIGH); R-event-loop + NSView embedding specifics MEDIUM. |

**Overall confidence:** HIGH on the technical approach (native NSOpenGL behind a seam, legacy 2.1, Retina conversion, `.dylib`), MEDIUM on the deployment gate that governs whether that approach is even reachable.

### Gaps to Address

- **Which R + Aqua-Tk configuration ships to researchers.** Resolve in Phase 1 as a spike/gate before GL work; verify `tk windowingsystem == aqua` at runtime.
- **Confirm the engine is genuinely fixed-function.** Quick `ogl_*.c` audit during Phase 1/4 to lock the legacy-2.1 requirement (research assumes fixed-function; very likely given GLUT usage).
- **`.dgt` cross-platform byte compatibility.** Verify fixed-width types / endianness and add a Windows-authored round-trip test in Phase 5.
- **arm64 vs Intel user split + universal2 rendering.** Test rendering on Apple Silicon (Metal-wrapped legacy path), not just Intel; `lipo -info` dual-arch.
- **Distribution trust (quarantine/library validation).** Decide signing/notarization vs documented `xattr` workaround during the build/distribution work.

## Sources

### Primary (HIGH confidence)
- Apple Developer docs/forums — OpenGL deprecated since 10.14, still present on Apple Silicon + Intel, capped GL 4.1, no removal date; legacy vs core profile (fixed-function removed in core); `wantsBestResolutionOpenGLSurface`/`convertRectToBacking:` HiDPI guidance.
- Tk source (`tkMacOSXSubwindows.c`, `tkMacOSXPrivate.h`, `tkPlatDecls.h` 9.0.3) — `Tk_MacOSXGetNSWindowForDrawable` public stub + `TkMacOSXGetNSViewForDrawable`, Aqua-only; `winfo id` meaningless on aqua.
- Tk/Tcl `macosx/README` — Tk does not call `[NSApp run]`, drives Cocoa via `TclDoOneEvent`, main-thread + autorelease requirement; `.dylib` via `-dynamiclib`, `[info sharedlibextension]`, "not a Mach-O library" error.
- Togl 2.1 (`TOGL_NSOPENGL`) + MacPorts `Togl +quartz` — working NSOpenGL/NSView Tk-embedding prior art.
- rgl GitHub #488, r-help 2025-11 (D. Murdoch), CRAN rgl README — XQuartz/GLX broken on macOS Tahoe; NULL/`rglwidget` workaround; `rgl.bringtotop` not implemented on OS X.
- CRAN *R for macOS* + RMacOSX-FAQ §6 — R ships Tcl/Tk 8.6.12 **X11**, requires XQuartz; Aqua Tk "does not work in R.app".
- Tcl/Tk wiki (*MacMice*, *New TkAqua FAQ*) + oooutlk Tk tutorial — button 2↔3 swap on aqua; context = Button-2 / Control-Button-1.
- GUImorph codebase — `tcl_window.c` (WGL seam + int→HWND cast note), `tcl_dispatch.c` (`onDisplay` swap `#ifdef`), `ogl_*` (pick, `glutSolidSphere`), `rtkogl.R`/`3dDigitize.*.r` (bindings, drawable handoff, resize/offset; line refs inline in FEATURES/ARCHITECTURE).

### Secondary (MEDIUM confidence)
- GLFW issues #2031/#2774, SDL issues #12141/#3613 — GLFW/SDL cannot reliably embed into a foreign `NSView`; macOS defaults push core/forward-compat.
- Apple `backingScaleFactor` docs + GLFW framebuffer guidance — render to backing pixels, not points.
- Tk core ticket 080a2810 (tk_getOpenFile UTType crash, fixed 2025), SO (no filetype dropdown on macOS panel) — file-dialog custom-extension behavior.
- Apple Developer Forums (Library Loading / Trusted Execution) — quarantine, library validation, `disable-library-validation`, entitlements on executables only, `xattr` workaround.

### Tertiary (LOW confidence)
- `.dgt` endianness/fixed-width compatibility — inferred from C global-state design; not yet inspected, needs a round-trip test.
- MouseWheel `%D` raw-delta magnitude on aqua — inferred against the existing /120 code; validate empirically.

---
*Research completed: 2026-07-12*
*Ready for roadmap: yes*
