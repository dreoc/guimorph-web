# Phase 1: Aqua-Tk Deployment Gate + Windows Rendering Seam - Context

**Gathered:** 2026-07-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Confirm and document a supported "R + Aqua (Cocoa) Tk" configuration on macOS, and isolate all native window/context creation behind a platform seam — moving the existing Win32/WGL code behind it unchanged.

**In scope:**
- GATE-01: prove an R session on macOS reports `tk windowingsystem == aqua` and can `load` a trivial Aqua-Tk C extension (X11/XQuartz path ruled out).
- GATE-02: a documented, reproducible "R + Aqua Tk" setup a researcher can follow.
- RND-01: extract all WGL/HDC/HGLRC/`SwapBuffers` code out of `tcl_window.c`/`onDisplay` into `gfx_backend_wgl.c` behind `gfx_backend.h`; core includes only the seam.
- CMP-01: Windows build still works — MSVC `tkogl2.dll` builds and renders a PLY mesh identically after seam extraction.

**Out of scope (later phases):** pathname-based drawable resolution (Phase 2), tri-platform CMake / drop GLUT (Phase 3), the actual NSOpenGL backend (Phase 4). This phase writes NO Cocoa/GL macOS code — it only proves the gate and refactors the Windows path behind a seam.

</domain>

<decisions>
## Implementation Decisions

### Aqua-Tk Distribution (GATE-02)
- **D-01:** Target a **bundled prebuilt Aqua Tcl/Tk framework** shipped inside the package as the documented researcher setup — goal is zero manual Tcl/Tk setup for researchers. Rejected: Homebrew `tcl-tk` + R reconfigure (reproducible but pushes setup burden onto the researcher); ActiveTcl.
- **D-02:** The exact bundling mechanics (framework layout, how R's `tcltk`/Tk is pointed at the bundled Aqua Tk, feasibility vs CRAN R's default X11 Tk linkage) remain a **planning research spike** — the spike validates that bundling is viable before it's locked. Bundling has downstream weight: sign/notarize + `universal2` (ties into Phase 4 BLD-03). If the spike shows bundling is infeasible/too costly, fall back to the documented Homebrew-Aqua-Tk path.

### Gate Proof (GATE-01)
- **D-03:** **Commit a throwaway trivial Aqua-Tk C extension** to the repo as a repeatable smoke test that R can `load` an Aqua-backed Tk extension. It doubles as a regression guard for the load path (not a one-time manual check).

### Rendering Seam (RND-01)
- **D-04:** `gfx_backend.h` exposes exactly **5 functions**: `create` / `make_current` / `swap` / `resize` / `destroy`. No speculative extras (drawable-size query, explicit present/clear) — add those only when the macOS backend actually needs them.
- **D-05:** Seam extraction is a **pure mechanical refactor** on the Windows side: move WGL/HDC/HGLRC/`SwapBuffers` code, do not change rendering behavior. Windows selects the WGL backend at compile time (`#ifdef _WIN32` / CMake `WIN32` branch); no macOS code compiles into the Windows build.

### Windows Regression (CMP-01)
- **D-06:** "Renders identically" = **build MSVC `tkogl2.dll` + `load` it + eyeball-render a known PLY mesh**. Pragmatic manual check; no screenshot/pixel-compare baseline infra this phase.

### Claude's Discretion
- Seam file naming/layout beyond `gfx_backend.h` + `gfx_backend_wgl.c` (e.g., where the seam header lives in `src/`).
- Which specific PLY fixture serves as the regression mesh (pick an existing sample already used by the Windows build).
- Exact form/location of the GATE-02 setup doc (README section vs standalone doc) and the trivial-extension test's directory.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Roadmap
- `.planning/ROADMAP.md` §"Phase 1" — goal, success criteria, and the note that the R+Aqua-Tk config is the milestone's central open question (expect a spike).
- `.planning/REQUIREMENTS.md` — GATE-01, GATE-02, RND-01, CMP-01 definitions.
- `.planning/PROJECT.md` — milestone constraints (keep Windows working; `.onLoad` load model; OpenGL deprecation trajectory).

### Codebase (native engine + seam targets)
- `.planning/codebase/ARCHITECTURE.md` — native `tkogl2.dll` layering; HWND/WGL embedding lives in `tcl_window.c`; `Tkogl2_Init` registers 8 Tcl commands; dual build modes (`CODE_FOR_LIBRARY` / `STAND_ALONE_TOOL`).
- `.planning/codebase/CONCERNS.md` — MinGW builds render black/blank (only MSVC supported); relevant to the CMP-01 regression check.
- `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_window.c` — the WGL/HDC/HGLRC/`SwapBuffers` code to extract behind the seam.
- `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_init.c` — `Tkogl2_Init` DLL entry / command registry (pattern for the trivial gate extension).
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R` — `.onLoad` `tcl("load", file, "Tkogl2")` load path (the path the gate extension must prove on Aqua Tk).

**Note:** The bundled-Aqua-Tk mechanics have no existing spec yet — the planning research spike produces one.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Tkogl2_Init` (`src/tcl_init.c`): the DLL-init + `Tcl_InitStubs` + `Tcl_PkgProvide` + `Tcl_CreateObjCommand` pattern is the template for the throwaway trivial Aqua-Tk C extension (D-03).
- `.onLoad` in `R/rtkogl.R`: the `tcl("load", file, ...)` load path the gate must exercise on Aqua Tk.

### Established Patterns
- Dual build modes via `#ifdef` (`CODE_FOR_LIBRARY` / `STAND_ALONE_TOOL`) — the seam must preserve both.
- Platform selection is compile-time; Windows keeps the WGL backend behind `#ifdef _WIN32` / CMake `WIN32`.
- Authoritative R sources are under `.../GUImorphDevelopment/R/` — NOT the duplicated `tkogl2/R/` copies (anti-pattern flagged in ARCHITECTURE.md).

### Integration Points
- `gfx_backend.h` seam sits between the Tcl dispatch / `onDisplay` draw path and the platform window/context code currently in `tcl_window.c`.
- Windows build/toolchain: MSVC only (MinGW renders blank) — the CMP-01 regression check must use the MSVC `tkogl2.dll`.

</code_context>

<specifics>
## Specific Ideas

- Researcher experience should be "zero Tcl/Tk setup" — motivation behind choosing the bundled-framework distribution (D-01) over asking researchers to install/point at Homebrew Tk.
- Windows side of this phase is a refactor, not a feature — success is "nothing visibly changed on Windows."

</specifics>

<deferred>
## Deferred Ideas

- Homebrew `tcl-tk` + R-reconfigure setup path — kept as the documented fallback if the bundling spike (D-02) shows bundling is infeasible.
- Screenshot/pixel-compare regression baseline — heavier rigor than needed now; revisit if eyeball checks prove insufficient in later phases.
- Seam extras (drawable-size query, explicit present/clear) — add when the macOS NSOpenGL backend (Phase 4) actually needs them.

None of these expand Phase 1 scope.

</deferred>

---

*Phase: 1-Aqua-Tk Deployment Gate + Windows Rendering Seam*
*Context gathered: 2026-07-12*
