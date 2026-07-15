# Codebase Concerns

**Analysis Date:** 2026-07-12

Scope: full repo. GUImorph is an R package (`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`) with a native C/OpenGL engine `tkogl2.dll` (`integrated-guimorph-development_EOC/Project/tkogl2/`) loaded at runtime via Tcl/Tk. Concerns below are ordered by likely impact for future work.

## Platform & Build Toolchain Constraints

**Windows-only by design (hard limitation):**
- Issue: The GUI cannot run on Linux/macOS. The engine creates an OpenGL context directly on a Tk widget's `HWND` via WGL, and the header set is Windows-specific (`#include <windows.h>` unconditionally in `tkogl2/src/def_ZARF_9.h:8`). `README.md:5` and `BUILD.md:3` state Linux/macOS are unsupported in beta v0.9.0.
- Files: `tkogl2/src/def_ZARF_9.h`, `tkogl2/src/tcl_window.c` (HWND/WGL setup), `GUImorphDevelopment/R/rtkogl.R:466` (`.onLoad`).
- Impact: No cross-platform path exists; this is the project's defining constraint, not a quick fix.
- Fix approach: A portable renderer (e.g. GLFW/EGL offscreen or an rgl bridge) would be a major rewrite of `tcl_window.c` + the `ogl_*` layer.

**MinGW builds render black/blank mesh — only MSVC is supported:**
- Issue: MinGW-w64 builds (MSYS2 native or WSL cross-compile via `tkogl2/cmake/mingw-w64-x86_64.cmake`) link successfully but render an all-black/blank mesh. Only the MSVC-built DLL is fit for distribution. Documented in `BUILD.md:8-11` and `tkogl2/BUILD.md:68-70`.
- Files: `BUILD.md`, `tkogl2/BUILD.md`, `tkogl2/cmake/mingw-w64-x86_64.cmake`.
- Impact: Root cause of the black-mesh divergence between toolchains is **not diagnosed** — a latent rendering/ABI bug that MSVC happens to mask. `tkogl2/BUILD.md` documents two MinGW paths as if usable, contradicting the "MSVC only" policy in the root `BUILD.md` (documentation drift, contributor confusion).
- Fix approach: Diagnose the MinGW render failure (likely GL state, calling-convention, or the hand-rolled Tcl stub ABI below) so the build isn't locked to one proprietary toolchain.

**Hand-rolled Tcl stub bootstrap relies on undocumented internal ABI:**
- Issue: `tkogl2/src/tcl_stub_bootstrap.c` provides `Tcl_InitStubs` by reading the internal Tcl 8.6 `Interp::stubTable` field layout directly, because the vendored `lib/tclstub86_64.lib` is an MSVC COFF archive GNU `ld` cannot read. `tkogl2/BUILD.md:83-86` explicitly flags this as needing re-validation.
- Files: `tkogl2/src/tcl_stub_bootstrap.c`, `tkogl2/BUILD.md`.
- Impact: Any Tcl 8.6 point release that reorders `Interp` fields silently breaks DLL load. Plausible contributor to the MinGW black-mesh symptom.
- Fix approach: Link a MinGW-compatible Tcl stub import lib (regenerate from `tcl86.dll` via `gendef`/`dlltool`), or gate the ABI assumption behind a runtime self-check.

**Prebuilt binary DLL committed to the repo:**
- Issue: `GUImorphDevelopment/inst/libs/x64/tkogl2.dll` (and `glut64.dll`, plus an i386 `glut32.dll`) are committed binaries so clones run without building (`BUILD.md:13-16`). `.gitignore` ignores newly built `tkogl2.dll` but the shipped one stays tracked.
- Files: `GUImorphDevelopment/inst/libs/x64/tkogl2.dll`, `GUImorphDevelopment/inst/libs/x64/glut64.dll`, `GUImorphDevelopment/inst/libs/i386/glut32.dll`, `tkogl2/lib/glut64.dll`.
- Impact: Binary/source can drift (no CI verifies the committed DLL matches current C sources); supply-chain trust rests on a checked-in binary; bloats history.
- Fix approach: Build + verify DLL in CI, or attach as a release asset instead of tracking in-tree.

## Tech Debt

**God file removed but naming/organization debt remains:**
- Issue: The historical god file `tkogl2/src/tcl_if_ZARF_9.c` is removed from the CMake build (confirmed: not present on disk), and `dot_ZARF_9.c` was replaced by `marker.c` (`BUILD.md:207`). But its responsibilities largely moved into `tcl_dispatch.c`, now the new god file at **3916 lines** — by far the largest source file.
- Files: `tkogl2/src/tcl_dispatch.c` (3916 lines), `tkogl2/src/ogl_model_ply_ZARF_9.c` (1798 lines).
- Impact: `tcl_dispatch.c` mixes Tcl command handlers, the draw pass, and wrapper helpers; hard to test or modify safely.
- Fix approach: Continue the Phase 7-style split — separate command dispatch from the GL draw pass and `Wrapper_Get*` accessors.

**`ZARF_9` legacy naming and stale version strings:**
- Issue: Files carry opaque `_ZARF_9` suffixes (`curve_ZARF_9.c`, `ogl_model_ply_ZARF_9.c`, `def_ZARF_9.h`, etc.). Hardcoded version/date strings are years stale and manually maintained: `tcl_state.c:28` `"edit date is 15 AUGUST 2020"`, `ogl_model_ply_ZARF_9.c:14` `"15 August 2020"`, and `DESCRIPTION` `Date: 2020-08-18`, `RoxygenNote: 7.1.1`.
- Files: all `*_ZARF_9.*`, `tcl_state.c:22-28`, `ogl_model_ply_ZARF_9.c:14`, `GUImorphDevelopment/DESCRIPTION`.
- Impact: New contributors cannot infer intent from filenames; manual version strings are always wrong.
- Fix approach: Rename to intent-revealing names; derive build/version info from the build system instead of hand-edited string literals.

**Dead code, stubs, and abandoned functions left in-tree:**
- Issue: Multiple functions are stubs or explicitly unused: `development_function()` returns `-1` (`tcl_state.c:374-378`); `ut_test_ogl_loadModel()` returns `-1` "actual function is not part of this package" (`tcl_state.c:449-452`); `ogl_loadLandmark`/`ogl_loadLandMark` log "who called this function !" and one is fully stubbed to `return -1` (`ogl_model_ply_ZARF_9.c:483-548`). Commented-out debug `printf` blocks and dead loops throughout (e.g. `ogl_model_ply_ZARF_9.c:459-467`). `tkogl2/R/geomorph.support.code.r:1720,1798` mark functions "NO LONGER USED ... retained for future debugging". Duplicate `#include "tcl_state.h"` at `ogl_model_ply_ZARF_9.c:10-11`.
- Files: `tkogl2/src/tcl_state.c`, `tkogl2/src/ogl_model_ply_ZARF_9.c`, `tkogl2/R/geomorph.support.code.r`.
- Impact: Noise inflates the surface area and obscures live paths.
- Fix approach: Delete dead code; move any needed helpers behind a debug flag.

**Vendored copy of geomorph inside the C project:**
- Issue: `tkogl2/R/geomorph.support.code.r` is a vendored/duplicated copy of geomorph support code living inside the C engine directory, while the package also `Imports: geomorph (>= 4.1.1)` in `DESCRIPTION`.
- Files: `tkogl2/R/geomorph.support.code.r`, `GUImorphDevelopment/DESCRIPTION`.
- Impact: Two sources of truth for the same logic; can silently diverge from the pinned geomorph dependency.
- Fix approach: Remove the vendored copy if the dependency covers it, or document why it must be forked.

**Comment-documented past bugs indicate a fragile history:**
- Issue: `marker.h:12-30` documents six historical anchor bugs (BUG-1..BUG-6) around shared selection state that the Phase 8 `marker_set_t` unification fixed. `tcl_state.c:295` notes a previously "duplicate clause ... fixed"; `tcl_state.c:144` "How do we know that there are only need for 1000 deltas ?".
- Files: `tkogl2/src/marker.h`, `tkogl2/src/marker.c`, `tkogl2/src/tcl_state.c`.
- Impact: The marker/selection subsystem has a proven history of state-aliasing bugs; changes there are high-risk.
- Fix approach: Add regression tests for marker select/move/delete/color across landmark vs anchor sets before further edits.

## Security Considerations

> Note: threat model is low — a desktop research tool where the user opens their own local `.ply`/`.dgt` files. Still, files from collaborators/downloads are untrusted input parsed in C.

**Unsafe PLY/DGT parsing in C (untrusted-file attack surface):**
- Risk: `ogl_loadModel` (`ogl_model_ply_ZARF_9.c:557+`) parses file headers and vertices with `sscanf`/`fgets` into fixed stack buffers and drives allocation and loop bounds from **file-declared** counts.
  - `PLY_ATTR_GET_INT` macro (`ogl_model_ply_ZARF_9.c:38-42`) does `strcpy(buf, buf + strlen(name))` — an **overlapping `strcpy` (undefined behavior)** with no bounds check.
  - Buffer sizing uses `FILE_SIZE = ftell(file) * sizeof(float)` (`:605`) — an unchecked `int`→`unsigned` multiply that **overflows** for large files; `Vertex_Buffer` is `malloc(ftell(file))` bytes yet indexed as floats.
  - The vertex loop runs `for (iterator < vertexNum)` (`:700-735`) with `vertexNum` from the header; a malformed/oversized count overruns `Vertex_Buffer`/`VertexColor_Buffer`.
  - `fgets`/`sscanf` return values are unchecked (`:669,:702,:706,:715`); a truncated file leaves buffers uninitialized.
- Files: `tkogl2/src/ogl_model_ply_ZARF_9.c` (PLY loader), plus the `.dgt` loader path (`ogl_loadDgtModel`).
- Current mitigation: `.ply`/`.PLY` extension check only (`:573-586`); no content validation. Mixed-case extensions are not handled.
- Recommendations: Validate `vertexNum`/`faceNum` against actual file size, replace `sscanf`/`strcpy` with bounded parsing (`snprintf`/`strtof`/`memmove`), check every `fgets`, and guard the size multiply against overflow.

**Unbounded `sprintf` into fixed global buffers:**
- Risk: Log/message formatting uses `sprintf` (not `snprintf`) into fixed buffers: global `buffer[1024]` and `messageBuffer[128]` (`tcl_state.c:135-136`), `ogl_buffer[128]` (`ogl_model_ply_ZARF_9.c:33`), local `msgbuffer[128]` (`:692`). Format args include user-controlled data such as `model->fileName[256]` (`def_ZARF_9.h:64`). `sprintf`/`strcpy` usage is dense: ~100 occurrences in `tcl_dispatch.c`, ~64 in `tcl_log.c`, ~57 in `ogl_model_ply_ZARF_9.c`.
- Files: `tkogl2/src/tcl_state.c`, `tkogl2/src/tcl_log.c`, `tkogl2/src/tcl_dispatch.c`, `tkogl2/src/ogl_model_ply_ZARF_9.c`.
- Current mitigation: Most format strings are static; overflow requires a long filename/path reaching a 128-byte buffer.
- Recommendations: Replace `sprintf`→`snprintf` with `sizeof` bounds across the engine; treat filenames as untrusted length.

**Static-CRT, self-contained DLL is the trust anchor:**
- Risk: End users run a committed binary DLL with statically linked CRT (`BUILD.md:66`). No signature or checksum verification at load time (`rtkogl.R:466-495` just `dyn.load`s whatever is at `libs/<arch>/tkogl2.dll`).
- Files: `GUImorphDevelopment/R/rtkogl.R`, `GUImorphDevelopment/inst/libs/x64/tkogl2.dll`.
- Current mitigation: DLL shipped in-repo over HTTPS/git.
- Recommendations: Publish a checksum; consider signing the release DLL.

## Fragile Areas

**Pervasive global mutable state (non-reentrant, single-session assumption):**
- Files: `tkogl2/src/tcl_state.c:32-136`, `tkogl2/src/tcl_state.h:19-83`.
- Why fragile: The entire engine state lives in ~40 `GBL_*` globals plus `models`, `context`, `deltas`, selection flags (`labeled`, `anchorPlaced`, `downsampled`), colors, radii, and shared scratch buffers. All Tcl commands mutate this shared state; there is no per-session/per-interp encapsulation and no thread safety. `initialize_state()` (`tcl_state.c:156-262`) is a hand-maintained reset that must mirror every global — easy to miss one and leak stale state across specimens/sessions.
- Safe modification: Never assume a global is fresh; when adding state, update `initialize_state()` and all `selector`-specific resets. Long term, bundle state into a passed-in context struct.
- Test coverage: None for state reset correctness.

**Marker / selection subsystem:**
- Files: `tkogl2/src/marker.c`, `tkogl2/src/marker.h`.
- Why fragile: Documented history of selection-state aliasing bugs (BUG-1..BUG-6, `marker.h:12-30`); NULL-guard asymmetry noted between `marker_del_selected` and `dot_del_selected` (`marker.h:15-17`).
- Safe modification: Preserve the per-`marker_set_t` `selected`/`selected_id` isolation; do not reintroduce shared dot/anchor globals.

**PLY loader control flow:**
- Files: `tkogl2/src/ogl_model_ply_ZARF_9.c`.
- Why fragile: 1798 lines, multiple malloc/unwind paths, outlier handling interleaved with file reading (author comment `:719-721` admits it "should have been implemented post file reading"), and the all-zero-color heuristic (`:737-739`) that drops the color array to avoid a black mesh — a workaround, not a root-cause fix, and thematically related to the MinGW black-mesh issue.

## Scaling Limits

**Hardcoded capacity `#define`s cap dataset size:**
- Issue (`tcl_state.h:11-17`): fixed-capacity global arrays cap the workload:
  - `GBL_LANDMARK_SET_CAPACITY 25` → **max 25 landmarks** (`GBL_LANDMARK_SET[25][3]`, `tcl_state.c:32`).
  - `GBL_CURVE_SET_CAPACITY 10` (physical array still dim 25).
  - `GBL_MODEL_SLOTS 5` and `GBL_CONTEXT_SLOTS 5` → **model/context pointer mirror capped at 5** (`GBL_PTR_MODEL[5]`, `GBL_PTR_CONTEXT[5]`, `tcl_state.c:45-46`).
  - `GBL_CURVE_SLOTS 6` → max 6 curve pointer slots (`GBL_PTR_CURVE[6]`, `tcl_state.c:73`).
  - `GBL_DELTAS_CAPACITY 1000` → `deltas[1000][4]`, with author doubt at `tcl_state.c:144` ("How do we know that there are only need for 1000 deltas ?").
- Files: `tkogl2/src/tcl_state.h`, `tkogl2/src/tcl_state.c`.
- Limit: Studies needing >25 fixed landmarks, >10 curves, or exceeding the slot mirrors will silently hit these caps. Whether these arrays bound total specimens or just a mirror table needs verification against `tcl_dispatch.c` usage, but the `[25]`/`[5]` dimensions are compile-time hard caps.
- Scaling path: Convert fixed arrays to dynamically sized allocations driven by the loaded dataset, or raise the `#define`s with a rebuild (still a static cap).

## Test Coverage Gaps

**Effectively no automated tests:**
- What's not tested: No `tests/` or `testthat/` suite is present in the package (`DESCRIPTION` lists `Suggests: testthat`, `NAMESPACE` exports only `GUImorph`/`loadDgt`, but no test files exist). The C engine has only ad-hoc `STAND_ALONE_TOOL` `ut_*` helpers compiled out of the library build (`RunTime_Defines_ZARF_9.h:35` forces `CODE_FOR_LIBRARY`). `UT_MY_INTEGER_VALUE` is a leftover "unit testing in THIS version ONLY" global (`tcl_state.c:133`).
- Files: `GUImorphDevelopment/` (no `tests/`), `tkogl2/src/RunTime_Defines_ZARF_9.h`, `tkogl2/src/tcl_state.c`.
- Risk: Every change is validated by manual Windows GUI smoke test only (`BUILD.md:147-169`); regressions in state reset, PLY parsing, marker selection, and multi-specimen handling can ship unnoticed.
- Priority: High — the fragile globals and PLY parser most need regression coverage.

**Verification/UAT relies on a doc that isn't in the repo:**
- Issue: `BUILD.md:11,184` and the troubleshooting table repeatedly reference `.planning/smoke-test-findings.md` for the black-mesh finding and warning triage, but `.planning/` is gitignored and that file is not present (only `.planning/codebase/` exists).
- Files: `BUILD.md`, `.gitignore` (`.planning/` ignored).
- Impact: The authoritative rationale for "MSVC only" and the load-time warning baseline is not available to contributors from a clean clone.
- Fix approach: Move the durable findings into a tracked doc (e.g. under `docs/` or `BUILD.md`) rather than a gitignored path.

## Known Bugs / Behavioral Quirks

**Black/blank mesh under unsupported toolchains** — see Platform section (MinGW). Also documented user-facing quirks in `README.md:154-179` (double-click to place, tab gating, rgl plot window opening behind Tk) are intentional, not bugs, but overlap with common "is this broken?" reports.

**`.onLoad` degrades silently if DLL missing:**
- Symptoms: If `tkogl2.dll` is absent/wrong-arch, `.onLoad` emits a `warning()` and continues (`rtkogl.R:488-495`); the package loads but 3D rendering is dead.
- Files: `GUImorphDevelopment/R/rtkogl.R:466-495`.
- Trigger: Corrupted clone, wrong R arch, or failed deploy.
- Workaround: Re-clone or rebuild+deploy per `BUILD.md:172-184`.

## Dependencies at Risk

**geomorph deprecation is the project's raison d'être but also a moving target:**
- Risk: GUImorph exists because geomorph 4.1 deprecated interactive rgl/OpenGL digitizing (`README.md:9`). It pins `geomorph (>= 4.1.1)` and imports `rgl`, `Morpho`, `Rvcg`, `tcltk`, `tcltk2`, `vegan` (`DESCRIPTION`). GPA/PCA/mean-shape paths call into `geomorph::gpagen` etc.
- Impact: Future geomorph API changes can break analysis paths; `rgl` is still imported for GPA plots despite the project's rgl-independence goal.
- Migration plan: `renv.lock` pins versions for reproducibility (`BUILD.md:107-114`); keep it current and add smoke coverage for the `geomorph`-facing R functions.

---

*Concerns audit: 2026-07-12*
