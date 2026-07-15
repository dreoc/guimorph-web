# Coding Conventions

**Analysis Date:** 2026-07-12

GUImorph is a two-language codebase: **R** (the package + Tk GUI) and **C**
(the `tkogl2` OpenGL engine compiled to `tkogl2.dll`). The two halves have
distinct, historically-accreted conventions. Follow the conventions of the
file/module you are editing; do not import R idioms into C or vice versa.

- R package root: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`
  (sources in `R/`)
- C engine root: `integrated-guimorph-development_EOC/Project/tkogl2/` (sources in `src/`)

There is **no linter or formatter config** in the repo (no `.lintr`,
`.editorconfig`, `.clang-format`, `.prettierrc`). Conventions are enforced by
convention only. When adding code, match the surrounding file.

---

## Naming Patterns

### R

**Files:**
- GUI modules use a legacy dot-separated, lowercase-`.r` scheme:
  `3dDigitize.main.r`, `3dDigitize.curve.r`, `3dDigitize.digitize.r`,
  `3dDigitize.surface.r`, `3dDigitize.geomorph.r`.
- Newer/utility modules use `.R` (capital): `gm_utils.R`, `rtkogl.R`.
- Extension is inconsistent (`.r` vs `.R`) — keep the existing extension of the
  file you edit; do not rename.

**Functions:** Three coexisting styles — pick based on the file's existing style:
- `camelCase` for GUI/action handlers and helpers: `setStatus`, `busyStart`,
  `busyStop`, `refreshTabGating`, `updateWidgets`, `onSelectCurve`, `onFit`.
- `dot.separated` for file I/O and S3-style module constructors:
  `read.curve`, `write.curve`, `read.vertex.3D`, `init.curve`, `ui.curve`,
  `bind.curve`.
- `snake_case` for a few legacy tag/date helpers: `get_main_date`,
  `get_curve_date`, `get_rtkogl_date`, `get_geomorph_support_date`.

**Internal / private helpers:** leading dot — `.clampCurveMax`,
`.clampCurveCurrent`, `.redrawAllCurves`, `.center_toplevel`,
`.guimorph_dev_mode`, `.STATUS_FG`. These are not exported.

**Constants:** `UPPER_SNAKE` or dotted-with-caps — `GUIMORPH_THEME`
(`R/3dDigitize.main.r:39`), `.STATUS_FG` (`R/3dDigitize.main.r:206`).

**S3 classes / methods:** The main environment is given `class(e) <- "main"`
(`R/rtkogl.R:402`) and generics dispatch via `UseMethod`: `ui`, `init`, `bind`,
`updateWidgets` (`R/3dDigitize.main.r:78-92`). Method files implement e.g.
`ui.curve`, `init.curve`, `bind.curve`.

### C

**Files — the `ZARF_9` suffix convention:** Legacy source files carry a
`_ZARF_9` (or `ZARF9`) suffix marking them as descendants of the original
`tcl_if_ZARF_9.c` "god file": `def_ZARF_9.h`, `RunTime_Defines_ZARF_9.h`,
`curve_ZARF_9.c`, `ogl_ZARF9.c`, `ogl_model_ZARF_9.c`, `ogl_model_ply_ZARF_9.c`,
`StatisticsFunction_ZARF_9.c`. Files extracted during the Phase 7-9 modular
split **drop the suffix**: `tcl_init.c`, `tcl_dispatch.c`, `tcl_window.c`,
`tcl_state.c`, `tcl_log.c`, `marker.c`. New engine code should use the
suffix-free style; treat `ZARF_9` as a "this is old / god-file lineage" marker.

**Types:** `_t` suffix, `snake_case` — `point_t`, `dot_t`, `color_t`, `model_t`,
`curve_t`, `context_t`, `marker_set_t`, `show_mode_t` (defined in
`src/def_ZARF_9.h` and `src/marker.h`).

**Functions:** Two styles coexist (a known wart — see `src/def_ZARF_9.h:168`,
`"THERE ARE TOO MANY FUNCTIONS ! LOTS OF REPLICATION !"`):
- `snake_case` (preferred/modern): `marker_add`, `dot_select`,
  `get_dot_slice_index`, `set_dot_slice_amount`.
- `camelCase` (legacy): `dotAllocateList`, `dotGetArraySize`,
  `anchorSetArrayIndex`, `dotGetPointerToTheSelectedDot`.

**Globals — `GBL_` prefix:** All module-level state uses `GBL_` (e.g.
`GBL_LANDMARK_SET`, `GBL_PTR_MODEL`, `GBL_ROTATION_ANGLE_X`,
`GBL_ENABLE_TCL_OBJECT_LOGGING`) in `src/tcl_state.c`. Pointers to globals use
`GBL_PTR_*` / `pointerTO_GBL_*`. Capacities are `#define`d as
`GBL_*_CAPACITY` / `GBL_*_SLOTS`.

**Macros / #defines:** `UPPER_SNAKE` — `DOT_EQUAL`, `IS_IN_RANGE`, `FREE`,
`ALLOCATE_WRAPPER`, `FREE_WRAPPER`, `DLLEXPORT`, `CODE_FOR_LIBRARY`.

### The `marker_* / dot_* / anchor_*` wrapper convention (C)

This is the central C pattern for landmark/anchor storage (Phase 8
unification, `src/marker.c`, `src/marker.h`):

1. **Core** operates on an explicit `marker_set_t*`:
   `marker_add(marker_set_t* s, ...)`, `marker_select`, `marker_del`, etc. All
   linked-list logic lives here once.
2. **Two module statics** hold the two data sets:
   `static marker_set_t g_landmarks` (node_type `LANDMARK`) and
   `static marker_set_t g_anchors` (node_type `ANCHOR`) (`src/marker.c:11-12`).
3. **Thin wrappers** forward to the right set:
   `dot_add(p,c) -> marker_add(&g_landmarks, p, c)` and
   `anchor_add(p,c) -> marker_add(&g_anchors, p, c)` (`src/marker.c:591-641`).

When adding marker behavior: implement it once in `marker_*`, then add both a
`dot_*` and an `anchor_*` one-line wrapper. Never duplicate list logic into the
wrappers. Each set carries its **own** `selected`/`selected_id` (this fixed the
D-03 anchor-selection bugs documented in `src/marker.h:12-30`).

---

## Code Style

### R

**Braces:** Two styles by era. Legacy files (`R/rtkogl.R`, older parts of
`R/3dDigitize.*.r`) use **Allman** (opening brace on its own line):

```r
add <- function(shape, arg1, arg2, arg3)
{
  if (shape == "curve")
  {
    ...
  }
}
```

Refactored helpers use **K&R** (brace on the same line):

```r
setStatus <- function(e, text, state = "neutral") {
  tkconfigure(e$statusLabel, text = text, foreground = .STATUS_FG[[state]])
}
```

Match the file you are in. Indentation is 2 spaces (some legacy blocks use
tabs/irregular spacing).

**State passing:** Nearly every GUI function takes the shared environment `e`
as its first argument and mutates it in place (`e$activeDataList`, `e$currImgId`,
`e$tabState`, ...). `e` is created in `GUImorph()` via `new.env()`
(`R/rtkogl.R:399-405`). This environment-as-mutable-object pattern is the
backbone of the GUI; prefer it over returning modified copies.

**Tcl bridge dispatch:** `add`, `del`, `shows`, `set`, `show` (`R/rtkogl.R`)
are large `if/else if` chains dispatching on a `shape` string argument. Design
rule (documented at `R/rtkogl.R:341-351`, `:577-579`): calls into the C
`tcl_if` layer **always pass three positional args**; pass negative-integer
placeholders (`-1`, `-2`, `-3`) for unused slots. Exception: the
"delete-selected" path deliberately omits args because the C `del` command
keys on `objc` (argument count).

### C

**Indentation:** hard tabs. **Braces:** Allman throughout.

**File header boilerplate:** each `.c` starts with MSVC pragma suppressions and
the two config headers first:

```c
#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include "RunTime_Defines_ZARF_9.h"
#include "def_ZARF_9.h"
```

**Yoda conditions:** constants on the left in equality tests, used pervasively:
`if (NULL == p)`, `if (NULL == s->slices)`, `if (0 == strcmp(...))`,
`if (0 == amount)`.

**Version stamping:** each module defines a `const char *_VERSION_INFORMATION[]`
with a hand-edited date and exposes a `*VersionPtr` (e.g.
`DOT_VERSION_INFORMATION` / `dotVersionPtr` in `src/marker.c:8-9`). These are
logged at log-file open (`src/tcl_log.c:628-662`). Update the date string when
you change a module.

**Build-mode preprocessor:** `RunTime_Defines_ZARF_9.h` `#undef`s all mode
flags then defines exactly one — `CODE_FOR_LIBRARY` for the R DLL build,
`STAND_ALONE_TOOL` for the desktop test harness. They are **mutually
exclusive**. `printf`/breakpoints are gated to `STAND_ALONE_TOOL`.

**Memory:** allocate via `ALLOCATE_WRAPPER(bytes)` and free via
`FREE_WRAPPER(ptr)` (not raw `malloc`/`free`); the `FREE(p)` macro
(`src/def_ZARF_9.h:110`) null-checks and nulls the pointer.

---

## Import Organization

### R

Dependencies are declared once via roxygen `#'@import` blocks in
`R/3dDigitize.main.r:17-36` (parallel, geomorph, Rvcg, Morpho, tcltk, tcltk2,
vegan) and regenerated into `NAMESPACE`. There are no per-call `pkg::fn`
qualifications for imported packages; functions are used unqualified because the
whole package is imported. `utils::` is qualified explicitly
(`utils::packageVersion`).

### C

Order: standard C headers (`<string.h>`, `<stdio.h>`, `<time.h>`, `<math.h>`,
...) first, then project headers with `def_ZARF_9.h` / `RunTime_Defines_ZARF_9.h`
early, then the module's own header. Platform headers require **canonical
casing** (`<windows.h>`, `<GL/glut.h>`) for the MinGW cross-compile path — see
the note at `src/def_ZARF_9.h:5-13`.

---

## Error Handling

### R

- **Boolean returns:** bridge functions return `TRUE`/`FALSE` to signal
  success/failure (`add`, `del`, `set`, `loadDgt` in `R/rtkogl.R`).
- **String-sentinel checks:** Tcl string results are inspected with
  `startsWith(result, "WARNING")` / `"ERROR"` / `"SUCCESS"` / `"IGNORE"` /
  `"UNDER_CONSTRUCTION"` (`R/rtkogl.R:244-251`, `:430-454`).
- **`tryCatch` for hard failures:** DLL load and window centering wrap risky
  Tcl calls and downgrade to `warning()` / `message()` rather than aborting
  (`.onLoad` `R/rtkogl.R:492-497`, `.center_toplevel` `R/3dDigitize.main.r:73-75`).
- **User-facing errors:** surfaced **inline** through the status bar via
  `setStatus(e, text, state)` with `state` in
  `neutral|info|success|warning|error` (`R/3dDigitize.main.r:206-217`).
  `tkmessageBox` dialogs are deliberately avoided — `test-undo-helpers.R:153-161`
  asserts the curve module uses inline warnings and contains no `tkmessageBox`.
- `suppressWarnings(as.integer(...))` + `is.na` fallback for parsing values
  coming back from C as strings (`R/rtkogl.R:115-116`).

### C

Documented contract at `src/def_ZARF_9.h:163-165`:
- Functions returning `int` return **negative (intent `-1`) on error**, `0` or
  positive on success.
- Functions returning pointers return **`NULL` on error**, a valid pointer
  otherwise.
- **All integer arguments must be `>= 0`** to be valid; negatives are rejected.
- Every pointer argument is NULL-guarded at function entry before use (see the
  cascade of guards in `marker_select`, `marker_add`, `marker_del` in
  `src/marker.c`). There are no exceptions/`setjmp`; errors propagate via the
  return code and a `simpleLog` message.

---

## Logging

### R — `dbg()` (gated debug printer)

`R/rtkogl.R:744`:

```r
dbg <- function(...) if (isTRUE(getOption("guimorph.debug", FALSE))) print(...)
```

- `dbg()` replaces raw `print()` and is silent unless
  `options(guimorph.debug = TRUE)`, which `GUImorph(debug = TRUE)` sets
  (`R/rtkogl.R:400`). The console is quiet by default.
- Legacy `print(...)`/`##print(...)` calls are commented out throughout rather
  than deleted. When adding diagnostics, use `dbg()`.
- Startup banner is emitted from `.onAttach` via `packageStartupMessage`
  (`R/rtkogl.R:746-754`), never `cat`/`print`.
- User status is separate from debug logging: use `setStatus`/`busyStart`/
  `busyStop` for anything the user should see.

### C — `simpleLog()` (file diagnostic channel)

`src/tcl_log.c` is the surviving diagnostic channel (Phase 9). Pattern:

- `simpleLog(const char* msg)` timestamps and appends one line to a log file
  under `./DATA_LOG_FILES/DL_<timestamp>.txt` (`src/tcl_log.c:130-155`). Sample
  output archived under
  `GUImorphDevelopment/DATA_LOG_FILES/`.
- **No-op when no file is open** — returns `-1` silently, so `simpleLog` calls
  are always safe.
- **Idiom:** `sprintf` into a shared file-static `char buffer[128]` then pass it
  to `simpleLog` (`src/marker.c:14`, used everywhere). Some functions inline
  `sprintf(buffer, ...); simpleLog(buffer);` on one line.
- **Message prefixes** encode severity by string convention:
  `"ERROR :"`, `"WARNING :"`, `"INFO :"`, `"DEBUG:"`. There is no numeric level;
  grep the prefix.
- A second channel, `commandStream_*` (`src/tcl_log.c:270-479`), records raw Tcl
  command objects to `CMMDS_DL_<timestamp>.txt`; gated by
  `GBL_ENABLE_TCL_OBJECT_LOGGING`.

---

## Comments

- **R:** module files open with a `#dgtDataList` layout comment documenting the
  per-specimen list structure (`[[1]]` dir, `[[2]]` font, `[[3]]` #landmarks,
  `[[4]]` curves, `[[5]]` template, `[[6]]` rotation, `[[7]]` zoom, `[[8]]`
  surface file) — see `R/3dDigitize.main.r:95-107`. Keep this in sync if you
  change the structure. Roxygen `#'` blocks document only the two exported
  functions (`GUImorph`, `loadDgt`) and the package.
- **C:** block comments (`/* ... */`) with `====` banners separate sections
  (`src/marker.c:19-21`); dated inline notes record design decisions and history
  (e.g. `src/def_ZARF_9.h:202-203`, `src/tcl_log.c:169`). The `marker.h` header
  carries a formal behavioral contract with bug IDs (D-03…D-05).
- Comments frequently explain *why* / historical intent, not just *what*.
  Preserve dated decision notes when refactoring.

---

## Function & Module Design

- **R exports:** only `GUImorph` and `loadDgt` are exported (`NAMESPACE:3-4`,
  `#'@export` tags). Everything else is package-internal. Do not add `@export`
  without reason — the public surface is intentionally tiny (one entry point).
- **R module shape:** each GUI tab/module provides `init.*`, `ui.*`, `bind.*`
  functions taking `e`; `ui.*` builds and returns a Tk frame, `bind.*` wires
  event handlers, `init.*` seeds `e$` fields.
- **C module shape:** one responsibility per file (see the table in
  `BUILD.md` §"C source layout"): `tcl_init.c` registers the 8 Tcl commands,
  `tcl_dispatch.c` handles them, `tcl_state.c` owns globals, `tcl_log.c` logs,
  `marker.c` owns landmark/anchor storage. Add new engine features in the file
  that owns that concern; do not resurrect the removed god file
  `tcl_if_ZARF_9.c`.
- **Tcl command surface:** exactly 8 commands are registered
  (`add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`,
  `loadDgt` — `src/tcl_init.c:24-31`). The R side calls these by name via
  `tcl("add", ...)` etc.

---

*Convention analysis: 2026-07-12*
