# Phase 9: C Engine Cleanup & Validation - Research

**Researched:** 2026-06-22
**Domain:** C/OpenGL engine refactor (numbered-global → array conversion, debug-cruft removal) behind a frozen Tcl extension DLL interface; manual Windows MSVC GUI regression UAT
**Confidence:** HIGH (source-grounded — every count and site verified against the live tree)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Globals → Arrays (CENG-03)**
- **D-01:** Replace numbered globals with **fixed-capacity static arrays**. Capacity is exposed as a **named `#define` documented in the owning header**.
- **D-02:** **Behavior-preserving** — same effective count and indexing as today. Structural rename + array-ification only; no functional change.
- **D-03:** **Respect the frozen `def_ZARF_9.h` layout** (Phase 8 D-08). `dot_t`/enum stay untouched. Array conversions localized to owning modules; `extern` declarations updated in the appropriate header (single-definition + extern convention from Phase 7).
- **D-13:** Rejected dynamic/growable allocation for Phase 9.

**Debug Cruft Removal (CENG-04)**
- **D-04:** **Remove pure tracing `printf`** outright. **Port any load-bearing diagnostics through `tcl_log.c`** rather than deleting.
- **D-05:** **Caution on the `openDgt` reload path** — a prior fix interacted with `printf` removal. Any `printf` near that path is potentially load-bearing and verified before removal.
- **D-06:** **Delete `MAKE_INERT`-wrapped code outright** (remove the dead/broken code, not just the guards). `CODE_FOR_LIBRARY` is the active build mode.
- **D-07:** **Delete `if(0)` debug toggles** outright (e.g. `ogl_model_ZARF_9.c:488`).
- **D-08:** **No retained compile-time debug-flag facility** — clean removal over toggles. `tcl_log.c` is the single surviving diagnostic channel.

**Regression Validation (CENG-05)**
- **D-09:** **Full Phase 4–5 round-trip is the bar:** load PLY → digitize landmarks + curves + anchors → save `.dgt` → reload → GPA. The analysis step is explicitly required.
- **D-10:** **Two fixtures:** Phase 4 `test_fresh.dgt` and the Phase 8 anchors+curves `test_dgt_anchors_curves.dgt`.
- **D-11:** **Manual Windows MSVC GUI UAT** — no automated harness. Append pass/fail to `.planning/smoke-test-findings.md`.
- **D-12:** **"Identical to baseline" judged by manual visual + functional confirmation**, not an automated diff.

**Build & Docs (09-03)**
- **D-14:** Update `BUILD.md` with the **final module-layout table**; prune obsolete references to the deleted god file (`tcl_if_ZARF_9.c`) and the reference-only `.vcxproj`. Keep **MSVC-only** instructions.

**Process / Safety**
- **D-15:** **Back up the pre-Phase-9 DLL** before refactoring (parallel to `.pre-phase7.bak` / `.pre-phase8.bak`).
- **D-16:** **MSVC is the supported build toolchain** — MinGW renders incorrectly. All builds and UAT use the MSVC DLL.

### Claude's Discretion
- **Work ordering** within the phase. Recommended: globals refactor → debug removal → validation last.
- **Exact capacity values** for each array — derived from current numbered-global counts (see CENG-03 inventory below).
- **Per-`printf` disposition** — case-by-case: pure tracing → delete; error/user-facing/load-bearing → route through `tcl_log.c`.

### Deferred Ideas (OUT OF SCOPE)
- Dynamic/growable global storage (malloc/realloc to remove hard capacity limits).
- Automated smoke-test harness (QA-01, v2).
- Capturing the 26 `load_all` warnings (tracked separately).
- Per-specimen curve bind / C curve state on specimen switch.
- PLY vertex coloration for geometry-only (all-zero RGB) scans (lighting fallback already in place).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CENG-03 | Numbered globals (`GBL_PTR_*_1..N`) replaced with arrays; capacity limits documented in headers | Complete inventory below: 3 numbered families (`GBL_PTR_MODEL_1..5`, `GBL_PTR_CONTEXT_1..5`, `GBL_PTR_CURVE_1..6`) all owned by `tcl_state.c`/`.h`; live read/write sites enumerated; capacity values derived. |
| CENG-04 | Debug cruft removed (`MAKE_INERT`, `if(0)` toggles, pervasive `printf` tracing) | Authoritative counts: ~118 live bare `printf(`; 9 `if(0)` blocks; **zero `#ifdef MAKE_INERT` blocks** (the "inert" code survives as `if(0) // made inert` blocks). Per-file dispositions below. |
| CENG-05 | Post-rehabilitation DLL passes full digitize smoke test (no regression vs Phase 4–5 baseline) | Validation Architecture section defines the manual UAT sampling plan (2 fixtures × digitize/save/reload/GPA workflow) and where to record it. |
</phase_requirements>

## Summary

Phase 9 is the final in-place cleanup of the `tkogl2` C engine. The investigation found the
cleanup surface is **smaller and lower-risk than the roadmap shorthand implied**, but with two
sharp edges the planner must respect.

**CENG-03 (numbered globals):** There are exactly **three** numbered-pointer families, all
defined in `tcl_state.c` and declared `extern` in `tcl_state.h`: `GBL_PTR_MODEL_1..5` (5 slots),
`GBL_PTR_CONTEXT_1..5` (5 slots), `GBL_PTR_CURVE_1..6` (6 slots). The model/context families are
**effectively write-only mirrors** of the existing dynamic `models[]` / `context[]` arrays — every
assignment ladder is **already commented out** in `tcl_dispatch.c`; the only live read is
`GBL_PTR_MODEL_1` in `snapshot()`. The curve family has **one live cluster** (a development
logging block in the `add("curve",…)` handler, `tcl_dispatch.c:2172-2202`) which contains a
pre-existing index bug. Converting these to arrays is therefore mostly mechanical with near-zero
runtime impact; the deliverable is the documented capacity `#define`s in the header.

**CENG-04 (debug cruft):** `MAKE_INERT` has **no `#ifdef` blocks anywhere** — it only survives as
documentation in `RunTime_Defines_ZARF_9.h` and as the *intent* behind three `if(0) // made inert`
blocks in `tcl_dispatch.c`. There are **9 `if(0)` debug toggles** total. Live bare `printf(`
tracing totals **~118**, concentrated in `ogl_model_ply_ZARF_9.c` (74, mostly in the `.dgt`/PLY
loaders) and `tcl_state.c` (30, all inside dead debug-dump functions). Note: raw `printf` greps
(~759) are dominated by `sprintf`/`fprintf` (log-buffer formatting and the `tcl_log.c` file
facility) — **those are load-bearing and must NOT be removed.**

**CENG-05 (regression):** No automated harness exists. Validation is manual Windows MSVC GUI UAT
across the full round-trip using both `.dgt` fixtures, recorded in `smoke-test-findings.md`.

**Primary recommendation:** Order the work globals → debug-removal → validation. Treat
`ogl_loadDgtModel` (`ogl_model_ply_ZARF_9.c:1054+`) as the D-05 caution zone: its `printf` are
decorative *around* the load-bearing `sscanf`/`FLAG_READ_SURFACES` logic — delete the trace, port
the `ERROR : why did we not find TAG_*` diagnostics to `simpleLog`, and re-run the full `.dgt`
round-trip after. The frozen interface (`Tkogl2_Init` + 8 Tcl commands + `def_ZARF_9.h` layout)
must be byte-for-byte unchanged.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Numbered global storage (CENG-03) | C engine — `tcl_state.c`/`.h` | `tcl_dispatch.c` (usage sites) | Globals are single-defined in `tcl_state.c`; `extern` in `tcl_state.h`; only consumer is dispatch + `snapshot()`. |
| Debug-trace removal (CENG-04) | C engine — all `*.c` modules | `tcl_log.c` (diagnostic destination) | `printf`/`if(0)` are scattered across modules; load-bearing diagnostics route to the `tcl_log.c` facility. |
| `.dgt`/PLY parsing (D-05 zone) | C engine — `ogl_model_ply_ZARF_9.c` | `tcl_dispatch.c` (`loadDgt` handler) | `ogl_loadDgtModel` parses the reload file; dispatch's `loadDgt` only logs via `simpleLog`. |
| DLL interface (frozen) | C engine — `tcl_init.c` | `tcl_dispatch.c`/`tcl_window.c` (handlers) | `Tkogl2_Init` registers 8 commands; export and command names are the R↔Tcl contract. |
| Regression validation (CENG-05) | Manual UAT (Windows R GUI) | R layer (`GUImorphDevelopment/R/*`) | No automated GL/Tk harness; validation is human visual + functional confirmation. |
| Build / deploy / docs | Build tooling (MSVC + CMake) + `BUILD.md` | `scripts/deploy-dll.ps1` | MSVC-only; DLL deployed to `inst/libs/x64/`. |

## Standard Stack

**No new external packages are introduced by this phase.** It is an internal C refactor of an
existing codebase. The relevant toolchain is already locked:

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| MSVC (VS 2022 Build Tools, VCTools) | 19.3x | Compile `tkogl2.dll` | Only toolchain that renders correctly (MinGW mis-renders — D-16) |
| CMake | 3.16+ | Configure/build (`-G "Visual Studio 17 2022" -A x64`) | Existing `CMakeLists.txt` |
| Tcl 8.6 stubs (`tclstub86_64.lib`) | 8.6 | DLL ↔ R/Tk linkage | Vendored in-tree (`lib/`); `USE_TCL_STUBS` |
| GLUT/OpenGL (`glut64.lib`, `opengl32`, `glu32`) | legacy fixed-function | Renderer | Vendored; Option A retains legacy GL |
| Windows R | 4.6+ | Runtime host for UAT | `renv`-pinned (Phase 6) |

**Build command (verified, MSVC):**
```powershell
cd integrated-guimorph-development_EOC\Project\tkogl2
cmake -B build-msvc -G "Visual Studio 17 2022" -A x64   # already configured; build-msvc/ exists
cmake --build build-msvc --config Release
# output: build-msvc\Release\tkogl2.dll
```

**Deploy target:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64/tkogl2.dll`

## Package Legitimacy Audit

**Not applicable** — this phase installs no external packages (npm/PyPI/crates or otherwise). It
edits existing in-tree C sources only. No package legitimacy gate required.

## Project Constraints (from .cursorrules and PROJECT.md)

These have the authority of locked decisions; research recommends nothing that contradicts them:

- **`.cursorrules` — `rtk` prefix:** The repo asks that shell commands be prefixed with `rtk`
  (Rust Token Killer) for token savings. ⚠️ **`rtk` is a WSL/Linux tool and is NOT on the Windows
  PowerShell PATH** in this environment (verified — `rtk` returns "not recognized"). The executor
  runs on Windows PowerShell against a `\\wsl$\` UNC mount; `rtk` is unavailable there. Use plain
  PowerShell (`Select-String`, `Get-ChildItem`) or invoke `rtk` via `wsl rtk …` if token savings
  are desired. This does not block any work.
- **Frozen `def_ZARF_9.h` layout (D-08/D-03):** `dot_t`, `point_t`, `model_t`, `context_t`,
  `curve_t`, `color_t`, and the `show_mode_t`/`X,Y,Z` enums must not change. (The `D`/`D1`/`D2`/`D3`
  debug-print macros also live in this header — see Open Questions for whether call-site removal is
  in scope without touching the type layout.)
- **Preserve the DLL interface:** `Tkogl2_Init` export + the 8 Tcl commands
  (`add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`) +
  the R↔Tcl shape-string protocol must be byte-for-byte compatible (PROJECT constraint).
- **MSVC-only build** (D-16). **Manual UAT only** — no automated Tk/OpenGL harness.

## Architecture Patterns

### Single-definition global + extern-in-header (Phase 7 convention)
Every global is **defined once** in a `.c` file and declared `extern` in the matching `.h`. All
numbered globals already follow this: defined in `tcl_state.c` (lines 45-89), `extern` in
`tcl_state.h` (lines 21-62). Array conversions keep the same split — change both the definition and
the `extern` declaration, plus a capacity `#define` in `tcl_state.h`.

### `marker.c` array-state precedent (Phase 8)
`marker.c` already models array-backed state cleanly (`g_landmarks`/`g_anchors` as
`marker_set_t`). It is the pattern reference for "fixed structure, indexed access, documented
bounds." (Note: `marker.c` itself has **0 live bare `printf`** and **1 `if(0)`** dead block at
line 469 — minimal cleanup there.)

### Pattern: numbered-pointer family → fixed array (CENG-03)
**What:** Replace `T* GBL_X_1 … GBL_X_N;` with `T* GBL_X[GBL_X_SLOTS];` and a documented
`#define GBL_X_SLOTS N` in the header.
**When to use:** All three numbered families.
**Example (behavior-preserving):**
```c
// tcl_state.h — add capacity #define + array extern (replaces 5 numbered externs)
#define GBL_MODEL_SLOTS   5   /* max specimens mirrored by the numbered-pointer table */
extern model_t* GBL_PTR_MODEL[GBL_MODEL_SLOTS];

// tcl_state.c — single definition (replaces GBL_PTR_MODEL_1..5)
model_t* GBL_PTR_MODEL[GBL_MODEL_SLOTS] = { NULL };

// Live read site: snapshot()  GBL_PTR_MODEL_1  ->  GBL_PTR_MODEL[0]
```

### Anti-Patterns to Avoid
- **Replacing the commented-out assignment ladders with a live loop.** The model/context ladders
  in `tcl_dispatch.c:2795-2865` are `/* */`-commented and inert. Do **not** "restore" them as
  `for(i=0;i<amount;i++) GBL_PTR_MODEL[i]=&models[i];` — that would *add* behavior (D-02 forbids).
  Either array-ify the dead comment text verbatim or delete the dead comment block (it is also
  CENG-04 cruft).
- **Deleting `sprintf`/`fprintf`.** They build log strings and write the `tcl_log.c` file facility.
  Removing them breaks logging and (for `sprintf(buffer,…); simpleLog(buffer);` pairs) deletes the
  message content. Only **bare `printf(`** to stdout is the CENG-04 target.
- **Removing a `printf` that is the sole body of a brace-less `if`/`for`.** `if (x) printf(...);`
  becomes `if (x);` (empty statement, latent bug). Remove the whole statement or the whole `if`.
  (Most sites here are inside braces, but `ogl_model_ply` has dense conditionals — verify per site.)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Diagnostic logging | New logging mechanism / retained debug-flag | `simpleLog()` / `simpleLog_Obj()` in `tcl_log.c` | D-04/D-08: `tcl_log.c` is the single surviving channel; load-bearing diagnostics route here |
| Capacity tracking | Magic numbers inline | Named `#define` in owning header | D-01: limits must be documented in headers |
| Specimen/context storage | Re-mirror `models[]`/`context[]` | The existing dynamic `models[]`/`context[]` arrays + `GBL_PTR_TO_A_MODEL` | They already are the live storage; numbered pointers are vestigial mirrors |

**Key insight:** The numbered model/context globals duplicate state that `models[]`/`context[]`
already hold. The lowest-risk, behavior-preserving change is array-ification of the *declarations*
(for the CENG-03 deliverable) while leaving the live engine path — which uses `models[i]` /
`context[i]` directly — untouched.

## Runtime State Inventory

> This IS a refactor/cleanup phase. All five categories answered explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | The `.dgt` file format is the only persisted data. **No format change** — Phase 9 must NOT alter `.dgt` reading (`ogl_loadDgtModel`) or writing semantics. Existing fixtures (`test_fresh.dgt`, `test_dgt_anchors_curves.dgt`) must reload byte-compatibly. | None (data migration). Verify round-trip in UAT. |
| **Live service config** | None. No external services, daemons, or UI-resident config. | None — verified (engine is an in-process DLL). |
| **OS-registered state** | None. No scheduled tasks, services, or registry entries reference the cleanup targets. The DLL is loaded by R at runtime via `tcl("load",…)`. | None — verified. |
| **Secrets / env vars** | None. No secrets, env-var names, or keys reference numbered globals or debug macros. | None — verified. |
| **Build artifacts / installed packages** | (1) **Deployed DLL** `inst/libs/x64/tkogl2.dll` (313,344 B, 2026-06-22 Phase-8 build) — will be replaced by the Phase-9 build. (2) Stale backups present: `.pre-phase7.bak`, `.pre-phase8.bak`, `.phase7-test`, `.bak`. (3) `build-msvc/` exists and is configured. (4) `tcl_if_ZARF_9.c.bak` (40,983 B) — orphan god-file backup in `src/`, NOT in the CMake build. | **D-15:** back up current `tkogl2.dll` → `tkogl2.dll.pre-phase9.bak` before deploy. Rebuild MSVC → deploy. Optionally note/remove the orphan `tcl_if_ZARF_9.c.bak` (D-14 doc cleanup). |

**Canonical question — after every file is updated, what runtime state still has the old string?**
*Nothing.* The numbered globals are pure in-memory C symbols with no external footprint; removing
`printf` changes only stdout volume. The single persisted contract is the `.dgt` format, which this
phase must preserve unchanged.

## CENG-03 — Numbered Global Inventory (authoritative)

**Owner module:** `tcl_state.c` (definitions) + `tcl_state.h` (externs). **No other module defines
these.** Usage appears in `tcl_dispatch.c` (mostly commented) and `snapshot()`.

| Family | Slots → capacity `#define` | Type | Definition | Extern | Live read/write sites | Disposition |
|--------|---------------------------|------|------------|--------|-----------------------|-------------|
| `GBL_PTR_MODEL_1..5` | **5** → `GBL_MODEL_SLOTS 5` | `model_t*` | `tcl_state.c:47-51` | `tcl_state.h:22-26` | **All assignment ladders commented out** (`tcl_dispatch.c:2795-2831`). One live read: `GBL_PTR_MODEL_1` in `snapshot()` `tcl_state.c:430`. Rest only in commented blocks (`tcl_state.c:245-262`, `434-450`). | Array-ify decls; update `snapshot()` read to `[0]`. Near-zero runtime impact. |
| `GBL_PTR_CONTEXT_1..5` | **5** → `GBL_CONTEXT_SLOTS 5` | `context_t*` | `tcl_state.c:53-57` | `tcl_state.h:28-32` | **Entirely dead** — only in commented ladder (`tcl_dispatch.c:2832-2865`) and commented blocks in `tcl_state.c`. No live read or write. | Array-ify decls (or delete as dead — see Open Q1). |
| `GBL_PTR_CURVE_1..6` | **6** → `GBL_CURVE_SLOTS 6` | `curve_t*` | `tcl_state.c:84-89` | `tcl_state.h:57-62` | **One live cluster:** `add("curve")` handler `tcl_dispatch.c:2172-2202` writes `CURVE_1/CURVE_2` and reads `CURVE_1/2/3` via `simpleLogWriteCurveToFile` (development logging). `CURVE_4..6` dead. | Array-ify; preserve exact indices (see pitfall — pre-existing bug). |
| `GBL_PTR_TO_A_MODEL` | n/a (single, **not numbered**) | `model_t*` | `tcl_state.c:45` | `tcl_state.h:21` | **Genuinely live** — assigned at `tcl_dispatch.c:2719,2736,2782,2962`. | **Leave unchanged** — not a numbered family. |

**Already-array globals with magic-number capacities** (CENG-03 "limits documented" also applies):

| Global | Current declaration | Capacity facts | Recommendation |
|--------|--------------------|----------------|----------------|
| `GBL_LANDMARK_SET[25][3]` | `tcl_state.c:32`; `#define CONST_25 25`; `GBL_LANDMARK_SET_MAX_ROWS = CONST_25` | Physical rows 25 = logical max 25 (consistent) | Rename `CONST_25` → descriptive `#define GBL_LANDMARK_SET_CAPACITY 25` in `tcl_state.h`; document. |
| `GBL_CURVE_SET[25][3]` | `tcl_state.c:39`; `#define CONST_10 10`; `GBL_CURVE_SET_MAX_ROWS = CONST_10` | ⚠️ **Inconsistent:** array dim is **25** rows but `MAX_ROWS` is **10**. | Document the true capacity. Behavior-preserving: keep dim `[25]` and `MAX_ROWS=10`, but add a clear `#define` and comment explaining the (intentional?) over-allocation. Do NOT shrink the array. |
| `deltas[1000][4]` | `tcl_state.c:131` (comment: "How do we know there are only need for 1000 deltas?") | Magic 1000 with no header `#define` | Optional (discretion): `#define GBL_DELTAS_CAPACITY 1000` in header, used by `clear_deltas()`. |

**Completeness:** A full read of `tcl_state.c`/`.h` confirms these are the **only** numbered/suffixed
global families. No `_1.._N` families exist outside `MODEL`/`CONTEXT`/`CURVE`.

## CENG-04 — Debug Cruft Inventory (authoritative)

### `MAKE_INERT` (D-06)
- **Zero `#ifdef MAKE_INERT` blocks in the entire active source tree.** `MAKE_INERT` appears only
  in `RunTime_Defines_ZARF_9.h` (3×: one `#undef`, two in comments) as documentation of a
  convention that was never (or no longer) used in the modular files.
- The *intent* of `MAKE_INERT` ("make broken/unused code inert") survives as **`if(0) // made
  inert` blocks** in `tcl_dispatch.c` (lines 1072 "made inert … chose to not delete … NOT used",
  3438 "made inert by dave").
- **Disposition:** Delete those `if(0)//made inert` blocks (counts under `if(0)` below). Optionally
  prune the now-obsolete `MAKE_INERT` documentation/`#undef` from `RunTime_Defines_ZARF_9.h`
  (it is a `#undef`/comment, not a type — safe; but see Open Q2 re: editing that header).

### `if(0)` debug toggles (D-07) — 9 total

| File | Line | Note in source | Disposition |
|------|------|----------------|-------------|
| `curve_ZARF_9.c` | 572 | "only needed for very detailed debugging" | Delete block |
| `curve_ZARF_9.c` | 585 | "only needed for very detailed debugging" | Delete block |
| `marker.c` | 469 | dead error path ("SHOULD NOT BE HERE") | Delete block |
| `ogl_model_ZARF_9.c` | 488 | "lot of output — really detailed debugging" (named in CONTEXT) | Delete block |
| `ogl_model_ply_ZARF_9.c` | 324 | DGT "write to flat file" debug (hardcoded `C:/home/...` path) | Delete block |
| `ogl_model_ply_ZARF_9.c` | 379 | "turned off 10 July 2020" per-vertex dump | Delete block |
| `tcl_dispatch.c` | 455 | debug | Delete block |
| `tcl_dispatch.c` | 1072 | "made inert … NOT used" (MAKE_INERT intent) | Delete block (D-06) |
| `tcl_dispatch.c` | 3438 | "made inert by dave" (MAKE_INERT intent) | Delete block (D-06) |

> Note: the disabled `if(0)` "forcibly switch specimens" patch in `openDgt` mentioned in STATE
> (backlog 999.2) — if present in this set, deletion is fine; 999.2 is tracked separately and the
> patch is already inert.

### Live bare `printf(` (D-04) — ~118 total

> Raw `printf` grep ≈ 759 is **misleading** — it counts `sprintf` (string building, KEEP) and
> `fprintf` (the `tcl_log.c` file facility, KEEP). The table below is **live, non-commented,
> non-macro-definition bare `printf(`** = the actual removal surface.

| File | Live bare `printf(` | Character / location | Disposition |
|------|--------------------:|----------------------|-------------|
| `ogl_model_ply_ZARF_9.c` | **74** | `.dgt`/PLY/landmark/curve/anchor/surface parse tracing in `ogl_loadModel` (594+), `ogl_loadLandMark` (579+), and **`ogl_loadDgtModel` (1054+)** | **D-05 ZONE.** Delete pure trace ("found SURF", "processing surfaces Na", per-landmark dumps). **Port `ERROR : why did we not find TAG_*` (lines ~1181-1182, 1207-1208, 1240-1241) to `simpleLog`.** Verify `.dgt` round-trip after. |
| `tcl_state.c` | **30** | Entirely inside debug-dump functions: `showPoint()` (495-497), `ut_show_Model()` (501-573), `show_GBL_LANDMARK_SET()` (599-608), `show_GBL_CURVE_SET()` (620-629) | These functions are debug-only dumps. Prefer removing the whole functions (and their prototypes) if unreferenced in the library path — confirm call sites first. |
| `StatisticsFunction_ZARF_9.c` | **9** | statistics trace | Inspect; delete pure trace, port any error/diagnostic to `simpleLog`. |
| `tcl_dispatch.c` | **4** | Coordinate-bounds dump (584-586 X/Y/Z min/max), specimen filename dump (2937) | Pure trace → delete. (The 5 `D/D1/D2/D3` macro *definitions* at 96-100 are separate — see below.) |
| `tcl_log.c` | **1** | line 149 `printf(" ! <%s>\n", yC)` — stdout echo inside `simpleLog` | Borderline. This is the facility echoing each log line to stdout. Remove for clean stdout, OR keep as intentional console mirror — planner decides. Low risk either way. |
| `ogl_ZARF9.c`, `tcl_window.c`, `marker.c`, `curve_ZARF_9.c`, `ogl_model_ZARF_9.c` | **0 live** | (their `printf` matches are all commented or inside `sprintf`/macros) | No bare-`printf` removal needed; only `if(0)` blocks above. |

**`D`/`D1`/`D2`/`D3` debug macros:** Defined in `def_ZARF_9.h:111-114` (and **duplicated** in
`tcl_dispatch.c:96-100`, where `D1` is even defined twice). They expand to `printf`. Call sites:
`tcl_dispatch.c` (7), `ogl_model_ply` (2), `ogl_model_ZARF_9.c` (2). **Disposition:** remove the
call sites (debug tracing); the duplicate definitions in `tcl_dispatch.c` can be deleted. Whether
to delete the macro *definitions* in the frozen `def_ZARF_9.h` is an Open Question (they are macros,
not the protected type layout — see Open Q2).

### `STAND_ALONE_TOOL` dead blocks (NOT explicitly in CONTEXT — scope question)
`#ifdef STAND_ALONE_TOOL` blocks are **dead under the active `CODE_FOR_LIBRARY` build** (the two
modes are mutually exclusive; `CODE_FOR_LIBRARY` is hard-`#define`d at
`RunTime_Defines_ZARF_9.h:49`). Counts: `tcl_dispatch.c` (12), `tcl_log.c` (3), `tcl_state.c` (2),
`tcl_window.c` (1), `def_ZARF_9.h` (1). Example: `ALLOCATE_WRAPPER`/`FREE_WRAPPER`
(`tcl_state.c:91-126`) have `#ifdef STAND_ALONE_TOOL … #endif #ifdef CODE_FOR_LIBRARY … #endif`
pairs where the STAND_ALONE half is dead. **CONTEXT named only `MAKE_INERT` + `if(0)` + `printf`**,
so removing all `STAND_ALONE_TOOL` blocks is a larger, separate cleanup. See Open Q3 — recommend
the planner scope this explicitly (default: leave them, since they are guarded and harmless, unless
the user wants the deeper clean per the D-08 "no retained compile-time toggle" spirit).

## Common Pitfalls

### Pitfall 1: Deleting `sprintf`/`fprintf` along with `printf`
**What goes wrong:** A naive "remove all printf" deletes log-buffer formatting (`sprintf(buffer,
…); simpleLog(buffer);`) and the `tcl_log.c` file writers (`fprintf(logfile, …)`), silently
breaking logging and erasing log message content.
**How to avoid:** Target **bare `printf(`** only (word-boundary match, not `s`/`f`/`sn`/`v` prefix).
**Warning sign:** `simpleLog(buffer)` with an empty/stale `buffer` after edit.

### Pitfall 2: `printf` as the sole body of a brace-less conditional
**What goes wrong:** `if (cond) printf(...);` → `if (cond);` — a no-op that may also strip an
intended side-effect grouping. `ogl_model_ply_ZARF_9.c` has dense `if`/`for` blocks around the
parse trace.
**How to avoid:** Remove the entire statement (and the `if` if it becomes empty). Build with MSVC
warnings on; watch for "empty controlled statement".

### Pitfall 3: The curve-logging index bug (behavior-preservation tension)
**What goes wrong:** `tcl_dispatch.c:2172-2202` assigns `GBL_PTR_CURVE_2` **twice** (lines 2179 and
2184) and reads `GBL_PTR_CURVE_3` (2185, 2199-2201) which is **never assigned** in this block (it
stays whatever it was — likely NULL). A "clean" array loop would change this behavior.
**How to avoid:** D-02 is behavior-preserving — port the indices **verbatim** (`CURVE_1→[0]`,
the buggy `CURVE_2` double-assign stays `[1]` twice, `CURVE_3` read stays `[2]`). Do not silently
fix unless the planner makes it an explicit, separate decision. (Impact is log-file-only; not
user-visible.) Flag for the user.

### Pitfall 4: The D-05 `.dgt` reload path
**What goes wrong:** Removing `printf` near the Surface/`nSurfaces` parse could be conflated with
removing the load-bearing `sscanf(++surfDigits, "%d", &nSurfaces)` and
`FLAG_READ_SURFACES = 0/1` logic that drives `Surface=0` handling (the documented Phase-4 reload
fix area).
**How to avoid:** In `ogl_loadDgtModel` (`ogl_model_ply_ZARF_9.c:1054+`), delete only the trace
`printf`; keep all `sscanf`/`strstr`/`strncmp`/`FLAG_*` lines. Re-run the **full** `.dgt` round-trip
with **both** fixtures after editing this file. (Note a pre-existing logging bug at line 1227-1228:
`sprintf(ogl_buffer, …)` then `simpleLog(buffer)` logs the wrong buffer — leave unless flagged.)

### Pitfall 5: Touching the frozen interface
**What goes wrong:** Renaming a global that `tcl_dispatch.c` references, or altering `def_ZARF_9.h`
type layout, breaks the DLL ABI / R↔Tcl contract.
**How to avoid:** Keep `def_ZARF_9.h` type/enum layout and the 8 Tcl command registrations
(`tcl_init.c`) unchanged. Numbered-global renames are internal C symbols (not exported) — safe, but
update **all** `extern` decls and usage sites in lockstep (single-definition convention).

### Pitfall 6: MinGW build masks render regressions
**What goes wrong:** Building with MinGW links but renders black/blank — a false "regression."
**How to avoid:** Build and UAT **only** with MSVC (D-16). Verify the freshness banner
(`FRESH BUILD <date> <time>` via `__DATE__`/`__TIME__` in `tcl_state.c:24`) to confirm the deployed
DLL is your fresh build, not a stale `.bak`.

## Code Examples

### Array-ify a numbered family (CENG-03), preserving the one live read
```c
// --- tcl_state.h ---
#define GBL_MODEL_SLOTS    5   /* numbered-pointer mirror of models[0..4]; vestigial */
#define GBL_CONTEXT_SLOTS  5
#define GBL_CURVE_SLOTS    6
extern model_t*   GBL_PTR_MODEL[GBL_MODEL_SLOTS];
extern context_t* GBL_PTR_CONTEXT[GBL_CONTEXT_SLOTS];
extern curve_t*   GBL_PTR_CURVE[GBL_CURVE_SLOTS];

// --- tcl_state.c ---
model_t*   GBL_PTR_MODEL[GBL_MODEL_SLOTS]     = { NULL };
context_t* GBL_PTR_CONTEXT[GBL_CONTEXT_SLOTS] = { NULL };
curve_t*   GBL_PTR_CURVE[GBL_CURVE_SLOTS]     = { NULL };

// snapshot()  (was: simpleLogWriteModelToFile(GBL_PTR_MODEL_1);)
simpleLogWriteModelToFile(GBL_PTR_MODEL[0]);
```

### Port a load-bearing diagnostic instead of deleting it (D-04)
```c
// ogl_loadDgtModel — BEFORE
printf("ERROR : why did we not find TAG_SURF again ??");
printf("ERROR : why did we not find TAG_SURF again ??");
// AFTER
simpleLog("ERROR : ogl_loadDgtModel : TAG_SURF present but no value parsed");
```

### Delete a pure-trace block (D-04 / D-07)
```c
// ogl_model_ZARF_9.c:488 — BEFORE
if (0)   // when enabled this provides a lot of output ...
{
    /* verbose dump */
}
// AFTER: remove entirely
```

## State of the Art

| Old Approach | Current Approach | When | Impact |
|--------------|------------------|------|--------|
| `printf` to stdout for tracing | `simpleLog()` file facility (`tcl_log.c`) | Phase 7 | D-04: stdout trace deleted; load-bearing diagnostics already route through the facility |
| `MAKE_INERT` `#ifdef` guards | (gone) → `if(0)` blocks | pre-Phase-7 | No `#ifdef MAKE_INERT` remains; clean removal of `if(0)` finishes the job |
| Numbered global pointers (`_1.._N`) | Direct `models[]`/`context[]` + `GBL_PTR_TO_A_MODEL`; numbered ladders commented out | pre-Phase-9 | CENG-03 array-ifies the vestigial decls; live engine path already uses arrays |

**Deprecated/outdated in-tree:**
- `tcl_if_ZARF_9.c.bak` (orphan god-file backup in `src/`) — not built; remove or note in D-14.
- `COMPILE_INFORMATION`/`TCL_IF_VERSION_INFORMATION` "15 AUGUST 2020" string is now overridden by
  `__DATE__`/`__TIME__` freshness banner — informational only.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `tcl_state.c` debug-dump functions (`showPoint`, `ut_show_Model`, `show_GBL_*`) are unreferenced in the library path and can be removed wholesale | CENG-04 / `tcl_state.c` 30 printf | LOW — if referenced, keep the function and just strip its `printf`; planner must grep call sites before deleting |
| A2 | Removing bare `printf` in `ogl_loadDgtModel` does not alter `.dgt` parsing (printf are decorative around `sscanf`/`FLAG_*`) | D-05 zone | MEDIUM — mitigated by mandatory full round-trip UAT with both fixtures |
| A3 | The pre-existing curve-index bug (Pitfall 3) should be **preserved**, not fixed, under D-02 | CENG-03 curve family | LOW — log-file-only effect; flagged for user decision |
| A4 | `STAND_ALONE_TOOL` dead-block removal is **out of scope** (CONTEXT named only MAKE_INERT/if(0)/printf) | CENG-04 scope | LOW — default leave-as-is; planner should confirm with user (Open Q3) |
| A5 | Editing `RunTime_Defines_ZARF_9.h` (prune MAKE_INERT docs) and removing `D/D1/D2/D3` macro **call sites** does not violate the `def_ZARF_9.h` *type-layout* freeze | CENG-04 / Open Q2 | LOW — macros/comments are not the protected `dot_t`/enum layout; confirm intent |
| A6 | Capacity values 5/5/6 for MODEL/CONTEXT/CURVE are the intended limits (derived from the numbered-slot counts) | CENG-03 | LOW — they match the declared families exactly |

## Open Questions

1. **Dead context/model families — array-ify or delete?**
   - What we know: `GBL_PTR_CONTEXT_1..5` is entirely dead; `GBL_PTR_MODEL_2..5` and
     `GBL_PTR_CURVE_4..6` are dead. CENG-03 says "replace with arrays"; CENG-04 says "remove cruft."
   - What's unclear: Whether to array-ify the dead decls (literal CENG-03 reading) or delete them
     (they are also cruft). D-13 rejected removing storage; D-02 says behavior-preserving.
   - Recommendation: **Array-ify all three families** (cleanest CENG-03 deliverable: documented
     capacity in the header) and **delete the commented-out assignment ladders** (CENG-04). This
     satisfies both requirements without behavior change. Surface to user if they prefer outright
     deletion of the dead families.

2. **`def_ZARF_9.h` `D/D1/D2/D3` macros and `RunTime_Defines_ZARF_9.h` MAKE_INERT docs.**
   - What we know: D-03/D-08 freeze the `def_ZARF_9.h` *type layout*. The debug macros and the
     MAKE_INERT documentation are not types.
   - Recommendation: Remove macro **call sites** (CENG-04) for sure. Treat editing the macro
     *definitions* / `RunTime_Defines_ZARF_9.h` MAKE_INERT text as a small, explicit sub-decision —
     default: prune them too (they are dead debug scaffolding), but confirm the freeze is layout-only.

3. **`STAND_ALONE_TOOL` dead blocks — in or out of scope?**
   - Recommendation: Default **out of scope** (CONTEXT named only MAKE_INERT/if(0)/printf). If the
     user wants the deeper clean (D-08 "no retained compile-time toggle" spirit), add it as an
     explicit task with its own UAT, since it touches ~19 sites across 5 files.

4. **Curve-index bug (Pitfall 3) — preserve or fix?**
   - Recommendation: Preserve verbatim under D-02; flag to user. (One-line fix available if they opt
     in.)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| MSVC (VS 2022 Build Tools) | DLL build (D-16) | ✓ (per BUILD.md/Phase 7-8) | 19.3x | None — MinGW mis-renders (not a fallback) |
| CMake | configure/build | ✓ | 3.16+ | None |
| `build-msvc/` configured | incremental build | ✓ (verified present) | — | re-run `cmake -B build-msvc …` |
| Windows R | UAT host | ✓ | 4.6+ | None |
| `renv` lockfile | reproducible R env | ✓ (Phase 6) | — | — |
| `.dgt` fixtures + `.ply` meshes | regression UAT | ✓ (`zips/Folsom 3D models/`) | — | None — required for CENG-05 |
| `rtk` CLI (.cursorrules) | token-saving shell wrapper | ✗ on Windows PATH | — | Use plain PowerShell, or `wsl rtk …` |

**Missing dependencies with no fallback:** none blocking. **With fallback:** `rtk` (use plain
PowerShell / `wsl`).

## Validation Architecture

> `workflow.nyquist_validation` is not disabled in config; included. **No automated test framework
> exists** for the Tk/OpenGL GUI — validation is manual GUI UAT (D-11/D-12). This section defines
> the manual **sampling plan** (workflows × fixtures × assertions) from which a VALIDATION.md can be
> derived.

### "Test Framework"
| Property | Value |
|----------|-------|
| Framework | **None** — manual Windows R GUI UAT (no Tk/OpenGL harness; QA-01 deferred to v2) |
| Config file | none |
| Quick run | Build MSVC → deploy → `devtools::load_all(".")` + `GUImorph()` smoke |
| Full suite | Full round-trip below × 2 fixtures |
| Record results | `.planning/smoke-test-findings.md` (append a "Phase 9 — Cleanup & Validation" section, mirroring the Phase 7/8 tables) |

### Sampling plan — workflows × fixtures × assertions

**Build/deploy gate (run first):**
- [ ] D-15 backup: `Copy-Item inst/libs/x64/tkogl2.dll inst/libs/x64/tkogl2.dll.pre-phase9.bak`
- [ ] MSVC build green; `Tkogl2_Init` exported; no new warnings vs Phase 8 baseline
- [ ] Deploy to `inst/libs/x64/tkogl2.dll`; freshness banner prints `FRESH BUILD <today>`

**Fixture A — `test_fresh.dgt`** (Phase 4; 2 specimens × 3 landmarks; curve on specimen 1; landmarks-only):
| Workflow step | Assertion (vs Phase 4–5 baseline) |
|---------------|-----------------------------------|
| `load_all` + `GUImorph()` | Window opens; no doubled nav buttons |
| Load PLY (`C13.1.ply`) | Shaded mesh visible (not blank/black) |
| Double-click landmarks | Placement works; dots visible |
| Curve bind (3 landmarks) on specimen 1 | `add("curve",1,2,3)`; chord segments draw; no R error |
| Save `.dgt` | File written; `Curve=1`, `LM3=3`, `Surface=0` sections present |
| Same-session `openDgt` reload | Both specimens + landmarks + curve restore; **`Surface=0` does not abort reload** (D-05 critical) |
| GPA tab → Compute (sliding OFF) | `gpagen` converges (3 LM × 2 specimens) |
| Save Result CSV | Non-empty (Csize + aligned coords) |

**Fixture B — `test_dgt_anchors_curves.dgt`** (Phase 8; landmarks + curve + **anchor**):
| Workflow step | Assertion |
|---------------|-----------|
| Load `.dgt` | Specimen renders; landmarks + curve + anchor restore (exercises dedup'd marker path) |
| Anchor place / select / move / delete | Parity with Phase 8 baseline (selected anchor moves/deletes; landmark unaffected) |
| Landmark place / select / move / delete | Parity with Phase 8 baseline |
| Re-save → reload | Anchor + curve survive round-trip |

**Pass criterion (CENG-05):** Every assertion matches the Phase 4–5 (Fixture A) and Phase 8
(Fixture B) baselines by **manual visual + functional confirmation** (D-12). Any deviation is a
regression to fix before phase close. Record the two tables in `smoke-test-findings.md` with date,
DLL freshness banner, and rollback DLL name (`.pre-phase9.bak`).

**Rollback:** if UAT fails, `Copy-Item inst/libs/x64/tkogl2.dll.pre-phase9.bak inst/libs/x64/tkogl2.dll`.

### BUILD.md update (D-14)
Final module-layout table to replace the current "C source layout (Phase 7)" section:

| File | Responsibility |
|------|----------------|
| `tcl_init.c` | `Tkogl2_Init`; registers 8 Tcl commands (`add`, `show`, `setWindow`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`) |
| `tcl_dispatch.c` | Tcl handlers, draw pass (`drawDots`/`onDisplay`), `Wrapper_Get*` helpers |
| `tcl_window.c` | `setWindowId`, HWND/WGL setup, `dc`/`width`/`height`, `setWindow` |
| `tcl_state.c` | Globals (incl. the new capacity-`#define`d arrays), `initialize_state`, `resetContext`, alloc wrappers |
| `tcl_log.c` | `simpleLog*`, command stream, file writers (the surviving diagnostic channel) |
| `marker.c` | Unified `marker_*` core + `g_landmarks`/`g_anchors` + `dot_*`/`anchor_*` wrappers (Phase 8) |
| `curve_ZARF_9.c` | Curve geometry/state |
| `ogl_ZARF9.c`, `ogl_model_ZARF_9.c`, `ogl_model_ply_ZARF_9.c` | OpenGL init/draw + PLY/`.dgt` model loading |
| `StatisticsFunction_ZARF_9.c` | Vertex statistics |

Prune: the obsolete `dot_ZARF_9.c` / `tcl_if_ZARF_9.c` references (already gone from build) and the
`tcl_if_ZARF_9.c.bak` orphan; reaffirm MSVC-only.

## Security Domain

> `security_enforcement` not disabled; brief assessment. This is an internal cleanup with **no new
> attack surface** — no new inputs, network, auth, or data flows are introduced.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a (local desktop tool) |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a |
| V5 Input Validation | partial (existing) | The only external input is the `.dgt`/`.ply` file parsed by `ogl_loadDgtModel`/`ogl_loadModel`. Phase 9 must **not weaken** existing parse guards (`strncmp`/`sscanf`/`FLAG_*`). |
| V6 Cryptography | no | n/a |

### Known patterns for this stack
| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Buffer overrun in `.dgt`/`.ply` parse (fixed `buffer[1024]`, `sscanf` into fixed widths) | Tampering / DoS | Pre-existing; out of scope to harden in Phase 9 (cleanup-only). Do not remove existing bounds checks while deleting nearby `printf`. Flag any newly-noticed unbounded `sscanf("%s")` to the user but do not fix unless asked. |

**Net:** No security-relevant behavior changes. The single guardrail is "don't delete a guard while
deleting a trace `printf`" (Pitfall 4).

## Sources

### Primary (HIGH confidence — live source, verified this session)
- `tcl_state.c` / `tcl_state.h` — numbered-global definitions, externs, capacities, `snapshot()` read
- `tcl_dispatch.c` — commented assignment ladders (2795-2865), live curve-logging block (2172-2202), `loadDgt` handler (3549-3577), live `printf` sites
- `ogl_model_ply_ZARF_9.c` — `ogl_loadDgtModel` (1054+), 74 live `printf`, `if(0)` blocks, SURF/Surface parse
- `tcl_init.c` — `Tkogl2_Init` + 8 command registrations (frozen interface)
- `RunTime_Defines_ZARF_9.h` — `CODE_FOR_LIBRARY` active; `MAKE_INERT` documentation only
- `marker.c`, `tcl_log.h`, `def_ZARF_9.h`, `CMakeLists.txt` — patterns, API, build
- PowerShell `Select-String` authoritative counts (printf-family, GBL_PTR_*, MAKE_INERT, if(0), build directives)
- `.planning/smoke-test-findings.md`, `STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `PROJECT.md`, `BUILD.md`, `07-02-SUMMARY.md`, `09-CONTEXT.md`

### Secondary / Tertiary
- None required — this phase introduces no external dependencies or web-sourced claims.

## Metadata

**Confidence breakdown:**
- CENG-03 inventory: **HIGH** — every numbered global and usage site read directly; capacities are declared counts
- CENG-04 inventory: **HIGH** — counts from authoritative `Select-String` (the Grep tool under-reported on the `\\wsl$\` UNC path and was not used for final numbers)
- D-05 reload-path analysis: **HIGH** — `ogl_loadDgtModel` SURF block read line-by-line
- Validation plan: **HIGH** — derived from documented Phase 4/5/8 UAT patterns
- Scope open questions (dead-family disposition, STAND_ALONE_TOOL, macro defs): **MEDIUM** — require a one-line user/planner decision (captured in Open Questions)

**Tooling note for downstream agents:** The Cursor `Grep`/`Glob` tools silently under-traversed the
`\\wsl$\Ubuntu\…` UNC mount (e.g. missed `tcl_state.c` entirely for `printf`/`GBL_`). Use PowerShell
`Get-ChildItem` + `Select-String` (or `wsl rg`) for authoritative file/string inventory in this repo.

**Research date:** 2026-06-22
**Valid until:** stable (in-tree C refactor; no fast-moving external deps) — re-verify counts only if source changes before planning.
