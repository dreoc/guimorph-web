# Phase 8: C Engine Deduplication - Research

**Researched:** 2026-06-22
**Domain:** C refactoring — collapse duplicated `dot_*`/`anchor_*` linked-list code in a Tcl/OpenGL extension DLL into a shared `marker_*` core
**Confidence:** HIGH (entirely codebase-verified; no external dependencies)

## Summary

This phase unifies two near-identical families of functions in
`integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c` — the `dot_*`
(landmark) and `anchor_*` families — into a single shared `marker_*` core that operates
on a passed-in `marker_set_t*`, with the existing `dot_*`/`anchor_*` names retained as
thin wrappers so that **no caller changes**. The duplication is acknowledged in-source at
`dot_ZARF_9.c:665` (*"all anchor functions are directly analogous to above dot
functions"*) and the shared node type (`dot_t`) already carries a `show_mode_t type` field
(`LANDMARK`/`ANCHOR`) set at add-time. [VERIFIED: codebase]

The two families share the same algorithms but operate on parallel module-static state
(`dots`/`anchors`, `dot_slice_id`/`anchor_slice_id`, `dot_slice_amount`/
`anchor_slice_amount`, `selected`/`anchor_selected`, `selected_id`/`anchor_selected_id`).
`marker_set_t` (D-02) maps one-to-one onto this five-field shape, with two static
instances (e.g. `g_landmarks`, `g_anchors`). The anchor family contains **three concrete
bugs** that the dedup must deliberately fix (D-03): `anchor_select`/`anchor_move`/
`anchor_color` mutate the **dot** `selected`/`selected_id` globals, `anchor_del_selected`
dereferences a never-set `anchor_selected`, and `anchor_select` has weaker argument
validation plus an off-by-one `id` increment relative to `dot_select`.

`.dgt` **does serialize anchors** (verified: `write.anchors`/`read.anchors`/`getAnchor`/
`draw.anchors` in the R layer; `show anchor xyz` C handler iterates the anchor list), so
**D-11's anchor-persistence regression check is viable** and should be kept. Build/deploy
is **MSVC-only** (MinGW renders a black mesh); verification is **manual Windows R GUI UAT**
(no automated Tk/OpenGL harness).

**Primary recommendation:** Create `marker.c`/`marker.h` with a `marker_set_t` struct and a
`marker_*` core; reimplement every existing `dot_*`/`anchor_*`/`get_*`/`*Get*`/`*Set*` name
as a one-line wrapper that forwards to the core with `&g_landmarks` or `&g_anchors`; delete
`dot_ZARF_9.c`; update `CMakeLists.txt` (add `marker.c`, drop `dot_ZARF_9.c`). Preserve
landmark behavior bit-for-bit; fix the three anchor bugs by routing each set through its
**own** state.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CENG-02 | Dot and anchor implementations unified into shared marker code | Full API surface enumerated (§"API Surface Inventory"); parallel state mapped to `marker_set_t` (§"Parallel Global State"); anchor asymmetry bugs pinpointed (§"Anchor Asymmetry Bug Specifics"); caller list confirms `tcl_dispatch.c` + `ogl_model_ply_ZARF_9.c` are the only consumers (§"Architecture Patterns"). |
</phase_requirements>

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01: Shared core + thin wrappers.** Single `marker_*` family taking a marker-set
  pointer; keep `dot_*`/`anchor_*` as one-line wrappers. **`tcl_dispatch.c` is NOT
  modified** — all call sites keep working through wrappers. Lowest regression risk.
- **D-02: Group per-type state into a `marker_set_t` struct.** Bundle the array
  (`dots`/`anchors`), `slice_id`, `slice_amount`, `selected`, and `selected_id` into one
  struct, with two static instances (e.g. `g_landmarks`, `g_anchors`). **Grouping only** —
  replacing numbered `GBL_PTR_*` globals with arrays is Phase 9, NOT here.
- **D-03: Fix the anchor asymmetry (intended outcome, not a regression).** Today
  `anchor_select`/`anchor_move`/`anchor_color` mutate the **dot** `selected`/`selected_id`
  globals (~lines 1021-1022, 1039, 1058), and `anchor_del` lacks some bounds checks
  `dot_del` has. Unified core uses each set's **own** selection state and full bounds
  checks. Deliberate behavior change for anchors — they are effectively broken today.
- **D-04: Landmark behavior must remain identical.** Same observable landmark behavior
  (placement, select, move, delete, draw). Landmarks are the validated Phase 4 path — no
  regression allowed.
- **D-05: Trim only the in-loop `select` logging that collapses on merge.** Reduce the
  noisy per-coordinate `IS_IN_RANGE` debug logging in the dot `select` path. **Scope
  guard:** limited to per-coordinate select logging that disappears on merge — broader
  debug-cruft removal (`MAKE_INERT`, `if(0)`, pervasive `printf`) stays Phase 9.
- **D-06: New `marker.c`/`marker.h` module.** Holds shared `marker_*` core, `marker_set_t`
  struct, and absorbed `dot_*`/`anchor_*` wrappers.
- **D-07: Delete `dot_ZARF_9.c`** once content absorbed (same pattern Phase 7 used).
- **D-08: Shared types stay in `def_ZARF_9.h`.** `dot_t` and `LANDMARK`/`ANCHOR` enum stay.
  Reconcile `dot_*`/`anchor_*` declarations with new `marker.h` (planner discretion on
  split; cross-module API belongs in `marker.h`).
- **D-09: Update `CMakeLists.txt`** to add `marker.c` and drop `dot_ZARF_9.c`,
  incrementally as in Phase 7.
- **D-10: Anchor-specific UAT is mandatory.** Manual Windows R GUI UAT must exercise
  **anchor place + select + move + delete** — not just landmark placement.
- **D-11: `.dgt` regression baseline = full Phase 4 round-trip + anchor persistence.**
  Reuse `test_fresh.dgt`-style flow: load PLY → landmarks + curve → save → same-session
  `openDgt` reload. Additionally place an anchor before save and confirm it reloads —
  **conditional on anchors being serialized into `.dgt`** (RESOLVED: they are — keep the
  check; see §"Open Question Resolved").
- **D-12: Document UAT** in `.planning/smoke-test-findings.md` and each plan SUMMARY.
- **D-13: Keep a pre-Phase-8 DLL backup** for side-by-side comparison (Phase 7
  `.pre-phase7.bak` pattern).

### Claude's Discretion
- Exact `marker_set_t` field names and the two instance names.
- Exact split of declarations between `marker.h` and `def_ZARF_9.h`.
- Whether `marker_*` branches on `dot_t.type` internally anywhere, or relies purely on the
  passed-in set (set-pointer approach preferred per D-01/D-02).
- How to consolidate near-duplicate accessor variants (`get_dot_slice_id` /
  `get_dot_slice_index`; `dot_size` / `dot_getListLengthAtCurrentSlice` /
  `get_dot_size_for_slice_index`; `dot_get` / `dot_get_dot` /
  `get_dot_at_index_current_slice`) — consolidate where safe, but wrappers must preserve
  every name dispatch calls.
- Plan splitting across 08-01 (characterize) / 08-02 (implement marker.c) / 08-03 (remove
  duplicates + verify), or a tighter split if warranted.

### Deferred Ideas (OUT OF SCOPE)
- **Numbered globals → arrays** (`GBL_PTR_*_1..N`, per-type statics) — Phase 9 (CENG-03).
  `marker_set_t` only *groups* state this phase.
- **Broad debug-cruft removal** (`MAKE_INERT`, `if(0)` toggles, pervasive `printf`) — Phase
  9 (CENG-04). Only in-loop select logging trimmed here (D-05).
- **Aggressive `static` linkage tightening / dead-code removal** (e.g. `dot_get_dot` marked
  "DON'T USE", commented-out old `anchor_select`) — Phase 9 / post-rehab; remove only what
  is unambiguously dead during unification.
- **Curve deduplication / per-specimen curve bind** — out of scope; separate module.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Marker (landmark/anchor) storage + linked-list ops | C engine (`marker.c`) | — | Pure in-process data structure; no I/O, no Tcl, no GL state |
| Marker name dispatch / draw pass | C engine (`tcl_dispatch.c`) | — | Sole consumer of the dot/anchor API; **unchanged** this phase (D-01) |
| `.dgt` serialization of anchors/landmarks | R layer (`3dDigitize.*.r`) | C engine (`show`/`add` handlers) | R owns file format; C only emits/ingests coords via `shows`/`add` |
| Specimen index ↔ slice selection | C engine (`*SetArrayIndex`/`*_slice_index`) | — | Called by dispatch + PLY loader to align the active slice |
| Build / DLL deploy | Windows MSVC + PowerShell | — | MinGW renders black mesh; MSVC is the only supported path |

**Why this matters:** the entire change is confined to the C data-structure tier
(`marker.c` replacing `dot_ZARF_9.c`). The dispatch tier and R tier are explicitly held
constant (D-01), which is what makes this a low-regression refactor. The only behavior that
crosses a tier boundary is the **anchor fix** (D-03): correct anchor selection state is
observable through the dispatch `show`/`del`/`move` handlers into the R GUI.

## Standard Stack

This is an **in-tree C refactor with zero new dependencies.** No packages are installed,
so the Package Legitimacy Audit is **not applicable** (see note below). The relevant
"stack" is the existing toolchain.

### Core (existing — unchanged)
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| MSVC (VS 2022 Build Tools) | 17 / v143 | Compile `tkogl2.dll` | Only supported toolchain; MinGW renders black mesh [VERIFIED: BUILD.md, STATE.md 2026-06-21] |
| CMake | ≥ 3.16 | Build configuration | `CMakeLists.txt` `cmake_minimum_required(VERSION 3.16)` [VERIFIED: CMakeLists.txt:1] |
| C standard | C99 | Language level | `set(CMAKE_C_STANDARD 99)` [VERIFIED: CMakeLists.txt:31] |
| Windows R | 4.6+ | Runtime host for UAT | `load_all` + `GUImorph()` [VERIFIED: BUILD.md §5] |

### Supporting (existing — unchanged)
| Component | Purpose | Notes |
|-----------|---------|-------|
| Tcl stubs (`tclstub86_64.lib`) | Tcl extension linkage | Vendored; MSVC links COFF directly [VERIFIED: CMakeLists.txt:108] |
| `glut64.lib` / OpenGL / GLU / GDI / user32 | Rendering + Win32 | System + vendored import libs [VERIFIED: CMakeLists.txt:106-114] |
| `ALLOCATE_WRAPPER`/`FREE_WRAPPER` | Memory alloc/free | Defined in `tcl_state.c` (per Phase 7 layout); used by all marker node alloc [VERIFIED: def_ZARF_9.h:104-105, dot_ZARF_9.c] |
| `simpleLog` family | Debug logging | Defined in `tcl_log.c`; every marker function logs through it [VERIFIED: BUILD.md layout table] |

**Build (MSVC, primary):**
```powershell
cd C:\dev\GUImorph\integrated-guimorph-development_EOC\Project\tkogl2
cmake -B build-msvc -G "Visual Studio 17 2022" -A x64
cmake --build build-msvc --config Release
# output: build-msvc\Release\tkogl2.dll
```

**Deploy:** copy `build-msvc\Release\tkogl2.dll` →
`integrated-guimorph-development_EOC\Project\GUImorphDevelopment\inst\libs\x64\tkogl2.dll`
(back up the existing DLL first — D-13). `scripts/deploy-dll.ps1` currently validates the
**MinGW** path (`build/tkogl2.dll`), so for an MSVC build use the **manual copy** in BUILD.md
§3 fallback. [VERIFIED: BUILD.md:90-104]

> **Package Legitimacy Audit — N/A.** This phase installs no npm/PyPI/crates/external
> packages. It only moves and merges existing in-tree C source. No registry verification,
> postinstall-script check, or SLOP/SUS triage is required.

## API Surface Inventory

> **Every name below is referenced by `tcl_dispatch.c`, `ogl_model_ply_ZARF_9.c`, or
> `def_ZARF_9.h`, so every name MUST survive as a wrapper.** [VERIFIED: grep across
> `tkogl2/src`] Source line numbers are in `dot_ZARF_9.c` unless noted.

### Dot (landmark) family
| Function | Line | Behavior | Reads/Writes |
|----------|------|----------|--------------|
| `dot_add(point_t*, color_t*)` | 236 | Append node (`type=LANDMARK`) to `dots[dot_slice_id]` | dots |
| `dot_select(point_t*, float)` | 113 | Find in-range node; set `selected`/`selected_id` | dots → selected |
| `dot_move(point_t*)` | 308 | Move `selected` to new coords | selected |
| `dot_color(color_t*)` | 327 | Recolor `selected` | selected |
| `dot_del(point_t*)` | 348 | Delete node matching coords (head + walk) | dots |
| `dot_del_selected()` | 395 | `dot_del(&selected->p)`; `selected=NULL`; return `dot_size()` | selected, dots |
| `dot_size()` | 76 | Length of current slice list | dots |
| `dot_get(int id)` | 405 | Return `dots[id]` (id==-1 → current slice); bounds-checked | dots |
| `dot_get_dot(int id,int pid)` | 467 | Walk `pid` steps from `dot_get(id)` — **marked "DON'T USE"** | dots |
| `dot_get_selected()` | 493 | Return `selected` | selected |
| `dotGetPointerToTheSelectedDot()` | 483 | Alias → `dot_get_selected()` | selected |
| `dot_selected_id()` | 231 | Return `selected_id` | selected_id |
| `dotGetSelectedIndex()` | 226 | Alias → `dot_selected_id()` | selected_id |
| `dot_getListLengthAtCurrentSlice()` | 1192 | Length of current slice (no error on empty → 0) | dots |
| `get_dot_at_index_current_slice(int)` | 1222 | Return node at 1-based index in current slice | dots |
| `get_dot_size_for_slice_index(int)` | 1304 | Length of an arbitrary slice | dots |
| `get_dot_slice_id()` | 56 | Return `dot_slice_id` | dot_slice_id |
| `get_dot_slice_index()` | 59 | **Identical** to `get_dot_slice_id()` (alias) | dot_slice_id |
| `get_dot_slice_amount()` | 65 | Return `dot_slice_amount` | dot_slice_amount |
| `get_dot_selected_id()` | 69 | Return `selected_id` (dup of `dot_selected_id`) | selected_id |
| `dot_slice_index(int id)` | 627 | Set `dot_slice_id` (bounds-checked); dead `if(0)` curve branch | dot_slice_id |
| `dotSetArrayIndex(int)` | 612 | Alias → `dot_slice_index()` | dot_slice_id |
| `dotGetArraySize()` | 503 | Return `dot_slice_amount` | dot_slice_amount |
| `dotAllocateList(int)` | 508 | → `set_dot_slice_amount()` | dots |
| `dotReleaseList()` | 521 | → `set_dot_slice_amount(0)` | dots |
| `set_dot_slice_amount(int)` | 529 | Free existing, alloc `amount` slice pointers | dots, both ids |
| `dots_free()` | 590 | Free all + reset | dots, ids |
| `isDotArrayNull()` / `isDotArrayNotNull()` | 31 / 37 | NULL test on `dots` | dots |

### Anchor family (parallel)
| Function | Line | Behavior | Reads/Writes | **Asymmetry vs dot** |
|----------|------|----------|--------------|-----------------------|
| `anchor_add(point_t*,color_t*)` | 1129 | Append node (`type=ANCHOR`) | anchors | none (clean) |
| `anchor_select(point_t*,float)` | 981 | Find in-range; **writes `selected`/`selected_id` (DOT globals!)** | anchors → **selected (wrong)** | **BUG 1** + no `p` NULL check, no `dotRadius<0` check, `id++` before match (off-by-one) |
| `anchor_move(point_t*)` | 1032 | Move **`selected`** (DOT global) | **selected (wrong)** | **BUG 2** |
| `anchor_color(color_t*)` | 1051 | Recolor **`selected`** (DOT global) | **selected (wrong)** | **BUG 3** |
| `anchor_del(point_t*)` | 758 | Delete matching node | anchors | has its own NULL-list check (slightly different ordering) |
| `anchor_del_selected()` | 826 | `anchor_del(&anchor_selected->p)`; `anchor_selected=NULL` | **anchor_selected (never set by select!)** | **BUG 4** (stale/NULL deref — see below) |
| `anchor_size()` | 687 | Length of current slice | anchors | none |
| `anchor_get(int id)` | 1071 | Return `anchors[id]` (id==-1 → current); bounds-checked | anchors | none |
| `anchor_get_anchor(int,int)` | 833 | Walk `pid` from `anchor_get(id)` (no header decl — likely internal/dead) | anchors | none |
| `anchor_get_selected()` | 498 | Return `anchor_selected` | anchor_selected | none |
| `anchorGetPointerToTheSelectedDot()` | 488 | Alias → `anchor_get_selected()` | anchor_selected | none |
| `anchors_selected_id()` | 743 | Return `anchor_selected_id` | anchor_selected_id | none |
| `anchorGetSelectedIndex()` | 748 | Alias → `anchors_selected_id()` | anchor_selected_id | none |
| `anchor_getListLengthAtCurrentSlice()` | 1274 | Length of current slice | anchors | none |
| `get_anchor_size_for_slice_index(int)` | 1347 | Length of arbitrary slice | anchors | none |
| `get_anchor_slice_id()` | 57 | Return `anchor_slice_id` | anchor_slice_id | none |
| `get_anchor_slice_index()` | 60 | Identical alias | anchor_slice_id | none |
| `get_anchor_slice_amount()` | 66 | Return `anchor_slice_amount` | anchor_slice_amount | none |
| `get_anchor_selected_id()` | 70 | Return `anchor_selected_id` | anchor_selected_id | none |
| `anchor_slice_index(int)` | 933 | Set `anchor_slice_id` (bounds-checked); dead `if(0)` branch | anchor_slice_id | none |
| `anchorSetArrayIndex(int)` | 619 | Alias → `anchor_slice_index()` | anchor_slice_id | none |
| `anchorGetArraySize()` | 1124 | Return `anchor_slice_amount` | anchor_slice_amount | none |
| `anchorAllocateList(int)` | 667 | → `set_anchors_slice_amount()` | anchors | none |
| `anchorReleaseList()` | 679 | → `set_anchors_slice_amount(0)` | anchors | none |
| `set_anchors_slice_amount(int)` | 845 | Free existing, alloc `amount` | anchors, ids | none (note plural `anchors`) |
| `anchors_free()` | 909 | Free all + reset | anchors, ids | none |
| `isAnchorArrayNull()` / `isAnchorArrayNotNull()` | 43 / 49 | NULL test on `anchors` | anchors | **no header decl** (likely internal/dead) |

### Names with no `dot_` counterpart referenced
- `anchors_selected_id` is the anchor analog of `dot_selected_id`; note the spelling
  (`anchors_` plural) and that `def_ZARF_9.h` declares both `anchors_selected_id()` (243)
  and `get_anchor_selected_id()` (249). The header has **duplicate declarations** of
  several names (e.g. `get_dot_slice_index` at 213 and 245; `get_anchor_slice_index` at 246
  and 252) — harmless but the planner should not be surprised. [VERIFIED: def_ZARF_9.h]

### Callers (the only consumers — must keep compiling)
- **`tcl_dispatch.c`** — primary consumer. Uses (confirmed by grep, with line refs):
  `dotSetArrayIndex`/`anchorSetArrayIndex` (233-234, 337-338, 1235, 1241, 1277-1278, 1926,
  1963, 2890, 2901, 2965-2966, 3867), `dot_get`/`anchor_get` (239, 343, 2390, 2498, 3873),
  `dot_slice_index`/`anchor_slice_index` (1121, 1127, 2988, 3008, 3023), `dot_add`/
  `anchor_add` (1313, 1365, 1431, 1483, 1528, 3714, 3826), `dot_select`/`anchor_select`
  (3178, 3201, 3225), `dot_move` (3271), `dot_color`/`anchor_color` (3332, 3349),
  `dot_del`/`dot_del_selected`/`anchor_del`/`anchor_del_selected` (3455, 3459, 3480, 3484),
  `dot_size`/`anchor_size` (1488, 1538), `dot_selected_id`/`anchors_selected_id` (2463,
  2469, 2542, 2548), `dotGetSelectedIndex` (1480), `dotGetArraySize` (2921, 3037, 3693,
  3720, 3808, 3832), `dot_getListLengthAtCurrentSlice`/`anchor_getListLengthAtCurrentSlice`
  (1286, 1344, 1403, 3660, 3773), `anchorReleaseList`/`dotReleaseList` (557-558, 2734-2735).
  `drawDots()` (224) and `drawAnchors()` (330) are **defined in `tcl_dispatch.c`** (not in
  marker.c) and call `dot_get`/`anchor_get`/`*SetArrayIndex`/`get_*_slice_index` — they stay
  put and unchanged. [VERIFIED: grep + Read]
- **`ogl_model_ply_ZARF_9.c`** — calls `dot_slice_index(j)` (558), `dot_add(&p,&c)` (559),
  `dotSetArrayIndex`/`anchorSetArrayIndex` (1630-1631, 1817-1818). Not modified, so these
  wrapper names must exist. [VERIFIED: grep]
- **`curve_ZARF_9.c`** — defines `curve_addDot(int, dot_t*)` (269) which **consumes `dot_t`**
  but calls **no** `dot_*`/`anchor_*` function. `dot_t` layout in `def_ZARF_9.h` must not
  change. Reference only; do not modify. [VERIFIED: grep]

## Parallel Global State → `marker_set_t`

Current module statics in `dot_ZARF_9.c:11-21` [VERIFIED]:
```c
static dot_t** dots = NULL;        static dot_t** anchors = NULL;
static int dot_slice_id = 0;       static int anchor_slice_id = 0;
static int dot_slice_amount = 0;   static int anchor_slice_amount = 0;
static dot_t* selected = NULL;     static dot_t* anchor_selected = NULL;
static int selected_id = 0;        static int anchor_selected_id = 0;
```

Map directly onto one struct (field names are planner discretion — D-02):
```c
typedef struct {
    dot_t** slices;     // array of per-specimen list heads (was dots / anchors)
    int     slice_id;   // active slice index (was dot_slice_id / anchor_slice_id)
    int     slice_count;// allocated slice count (was *_slice_amount)
    dot_t*  selected;   // currently selected node (was selected / anchor_selected)
    int     selected_id;// index of selected node (was selected_id / anchor_selected_id)
} marker_set_t;

static marker_set_t g_landmarks;   // backs the dot_* wrappers
static marker_set_t g_anchors;     // backs the anchor_* wrappers
```

**Do NOT array-ify the numbered `GBL_PTR_*` globals** — those live in `tcl_state.c` and are
deferred to Phase 9 / CENG-03. This phase only *groups* the five per-type statics above.
[VERIFIED: CONTEXT.md D-02, Deferred Ideas]

**Shared static scratch:** `static char buffer[128]` (`dot_ZARF_9.c:24`) is used by every
function for `sprintf`+`simpleLog`. The merged file can keep a single `buffer`. **Caution:**
`tcl_dispatch.c` and other modules each have their own `buffer` — `marker.c` needs its own
file-static `buffer` (don't rely on an extern). [VERIFIED: codebase]

**Shared macros** (currently in `dot_ZARF_9.c:26-28`, move to `marker.c`):
```c
#define DOT_EQUAL(p1, p2) p1.x == p2->x && p1.y == p2->y && p1.z == p2->z
#define IS_IN_RANGE(target, test, dotRadius) (target - dotRadius) <= test && (target + dotRadius) >= test
```

## Anchor Asymmetry Bug Specifics (D-03)

The unified `marker_*` core fixes all of these **by construction** (each set uses its own
`selected`/`selected_id` and gets the full validation path). The planner should specify the
correct per-set behavior explicitly so the fix is intentional, not accidental:

1. **`anchor_select` writes the wrong selection globals** (`dot_ZARF_9.c:1021-1022`):
   sets `selected = n; selected_id = id;` — the **dot** globals — instead of
   `anchor_selected`/`anchor_selected_id`. [VERIFIED]
2. **`anchor_move` moves the wrong node** (`:1034, 1039-1043`): checks/moves `selected`
   (dot global), not `anchor_selected`. [VERIFIED]
3. **`anchor_color` recolors the wrong node** (`:1058-1062`): writes `selected->c`, not
   `anchor_selected->c`. [VERIFIED]
4. **`anchor_del_selected` derefs a never-set pointer** (`:826-831`): reads
   `anchor_selected` (which `anchor_select` never sets because of bug 1), so after selecting
   an anchor this is **stale or NULL** → wrong deletion or crash. Note `dot_del_selected`
   (`:395-400`) has the *same* missing-NULL-check shape but works because `dot_select`
   *does* set `selected`. The unified `marker_del_selected` should add a NULL guard for both
   sets. [VERIFIED]
5. **Weaker `anchor_select` validation** vs `dot_select`: `anchor_select` lacks the
   `NULL == p` check (`dot_select:121`) and the `dotRadius < 0` check (`dot_select:139`).
   The unified path should include both. [VERIFIED]
6. **Off-by-one `id` semantics:** `dot_select` increments `id` *after* the match test
   (`:218`, so first node = id 0); `anchor_select` increments `id` *before* the test
   (`:1016`, so first node = id 1). After the merge both sets get the dot's 0-based
   convention. **Watch the dispatch read path:** `show landmark id` returns
   `dot_selected_id() + 1` (`tcl_dispatch.c:2469`) while `show anchor id` returns
   `anchors_selected_id()` with **no +1** (`:2548`). Standardizing anchor indexing to
   0-based may shift the anchor `id` reported to R by one. **The R GUI anchor flows verified
   to matter are place/select/move/delete via coordinates (`shows("anchor","xyz",...)`),
   not the `id`-getter** — but the planner should call out this `+1` discrepancy as a thing
   to confirm during anchor UAT (D-10). [VERIFIED — see Open Questions]

## In-Loop `select` Logging Trim Scope (D-05)

The dot `select` path logs **per-coordinate per-node** `IS_IN_RANGE` pass/fail
(`dot_ZARF_9.c:166-198`): six `sprintf`+`simpleLog` calls *inside* the node loop, before
the actual match test. The anchor `select` path (`:1014-1026`) has **none** of this — the
loop body is just the match test. When the two bodies merge into one `marker_select`, the
natural single body is the **lean anchor-style loop** (match test only) plus the dot path's
pre-loop INFO logging (`:154-157`) and post-match INFO logging (`:209-214`).

**Scope guard (do not over-reach):** trim only the 6 in-loop `IS_IN_RANGE` debug/fail
`simpleLog` calls (`:166-197`) that have no anchor equivalent and disappear when the bodies
unify. Keep the pre-loop "Starting to search" log and the post-match "found dot" logs (they
exist in the dot path and are useful). Do **not** touch `MAKE_INERT`, `if(0)` toggles, or
the pervasive `printf`/`simpleLog` tracing elsewhere — Phase 9. [VERIFIED: codebase + D-05]

## Architecture Patterns

### Data flow (unchanged externally; internal collapse only)

```
R GUI (3dDigitize.*.r)
  │  tcl("add"/"set"/"show"/"del", "dot"|"anchor", ...)
  ▼
tcl_dispatch.c  (UNCHANGED — D-01)
  ├─ add dot      → dot_add()          ┐
  ├─ add anchor   → anchor_add()       │
  ├─ select       → dot_select()/anchor_select()
  ├─ move/color   → dot_move()/anchor_move()/...     thin wrappers
  ├─ del          → dot_del()/anchor_del()/...       (marker.c)
  ├─ drawDots()   → dot_get()/get_dot_slice_index()  │
  └─ drawAnchors()→ anchor_get()/...                 ┘
                         │  forward &g_landmarks / &g_anchors
                         ▼
              marker_* shared core (marker.c)  ◄── NEW
                  operates on marker_set_t*
                         │
                         ▼
        ALLOCATE_WRAPPER/FREE_WRAPPER (tcl_state.c), simpleLog (tcl_log.c)
```

`.dgt` round-trip path (relevant to D-11):
```
SAVE: write.digitize() → write.anchors()  ── R reads coords via shows("anchor","xyz",id)
        └─ C: show anchor xyz handler iterates anchor_get() list, emits "x y z ..." [tcl_dispatch.c:2480-2536]
LOAD: openDgt() → read.anchors() → drawElements() → draw.anchors() → set/add "anchor"
        └─ C: anchor_add() per coordinate
```
[VERIFIED: 3dDigitize.main.r:1665,1685,2545,2714; 3dDigitize.digitize.r:1156,1223,1305; tcl_dispatch.c:2480]

### Pattern 1: Thin wrapper preserving every name
**What:** Each public name becomes a one-liner forwarding to the core with the right set.
**When:** All ~50 public `dot_*`/`anchor_*`/`get_*`/`*Get*`/`*Set*` names.
**Example:**
```c
// marker.c
int marker_add(marker_set_t* s, point_t* p, color_t* c, show_mode_t type) { /* shared body */ }
int dot_add(point_t* p, color_t* c)    { return marker_add(&g_landmarks, p, c, LANDMARK); }
int anchor_add(point_t* p, color_t* c) { return marker_add(&g_anchors,   p, c, ANCHOR);   }

int marker_select(marker_set_t* s, point_t* p, float r) { /* uses s->selected, s->selected_id */ }
int dot_select(point_t* p, float r)    { return marker_select(&g_landmarks, p, r); }
int anchor_select(point_t* p, float r) { return marker_select(&g_anchors,   p, r); }
```
Note: `marker_add` needs the `type` (LANDMARK vs ANCHOR) because `dot_add` sets
`node->type = LANDMARK` and `anchor_add` sets `node->type = ANCHOR` — pass it as an arg or
store it on the `marker_set_t`. Storing a `show_mode_t node_type` on the set is the cleaner
option (Claude's discretion per CONTEXT). [VERIFIED: dot_ZARF_9.c:274, 1166]

### Pattern 2: Accessor-variant consolidation (discretion)
`dot_size()` (logs an error on empty list, returns -1) vs
`dot_getListLengthAtCurrentSlice()` (returns 0 on empty) vs
`get_dot_size_for_slice_index(int)` (arbitrary slice) have **subtly different empty/error
semantics**. Consolidate the list-walk into one helper but **preserve each public name's
exact return contract** — e.g. `dot_size()` must still return -1 (not 0) on a NULL head, or
landmark behavior changes. [VERIFIED: dot_ZARF_9.c:76-105 vs 1192-1220 vs 1304-1345]

### Anti-Patterns to Avoid
- **Don't change `dot_t` layout** — `curve_addDot` and the `show xyz` emitters depend on it.
- **Don't fold the numbered `GBL_PTR_*` globals into arrays** — Phase 9.
- **Don't "fix" landmark behavior** — only anchors get the deliberate fix (D-03/D-04).
- **Don't remove `dot_get_dot`/`anchor_get_anchor`/`isAnchorArray*` reflexively** — verify
  they are truly unreferenced before deleting (some have no header decl but could still be
  referenced; grep confirms `dot_get_dot` is declared at `def_ZARF_9.h:181`, so keep it).
- **Don't merge the two `buffer[128]` statics across modules** — each TU keeps its own.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Node allocation/free | raw `malloc`/`free` | existing `ALLOCATE_WRAPPER`/`FREE_WRAPPER` | Matches engine's instrumentation; `FREE` macro NULLs the pointer [def_ZARF_9.h:104-110] |
| Logging | new `printf`/log fn | existing `simpleLog`/`sprintf(buffer,...)` | Consistent with engine; UAT reads the simpleLog file |
| Float coord equality | new epsilon compare | existing `DOT_EQUAL` macro (kept as-is) | Behavior-preserving; changing it would alter `*_del` semantics (D-04) |
| Slice/list walking | per-call new loop | one shared `marker_*` walker | The whole point of the phase |

**Key insight:** the codebase already has all the primitives; this phase is *removal of
duplication*, not addition. The only "new" code is the `marker_set_t` struct and the shared
core — everything else is mechanical wrapper forwarding.

## Runtime State Inventory

> Refactor/module-replacement phase. Most categories are N/A because no string is being
> renamed and no external system stores engine state — but the build artifact lifecycle
> matters.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **None** — `.dgt` format unchanged; `dot_t` layout unchanged; no on-disk schema touched. Anchors are serialized as plain `x y z` triples via R, not as C struct dumps. [VERIFIED: write.anchors/read.anchors] | none |
| Live service config | **None** — no external service; pure in-process DLL. | none |
| OS-registered state | **None** — no Task Scheduler / services / registry entries. | none |
| Secrets/env vars | **None.** | none |
| Build artifacts | (1) The **deployed DLL** at `inst/libs/x64/tkogl2.dll` must be **rebuilt + redeployed** after the C change (R loads the deployed copy, not the source). (2) `build-msvc/` is the MSVC output dir. (3) **Pre-Phase-8 DLL backup** required (D-13) — e.g. `tkogl2.dll.pre-phase8.bak`. (4) CMake caches in `build-msvc/` regenerate from the edited `CMakeLists.txt`. | rebuild → backup → deploy; commit CMake change |

**The canonical question:** *After `dot_ZARF_9.c` is deleted and `marker.c` added, what still
references the old translation unit?* → Only `CMakeLists.txt` (the source list, line 54) and
the `dot_ZARF_9.c` filename itself. No headers `#include "dot_ZARF_9.c"`; all callers use the
`def_ZARF_9.h` declarations, which the planner reconciles with `marker.h`. [VERIFIED]

## Common Pitfalls

### Pitfall 1: Breaking landmark behavior while "cleaning up" accessor variants
**What goes wrong:** Consolidating `dot_size`/`dot_getListLengthAtCurrentSlice`/
`get_dot_size_for_slice_index` into one helper silently changes the empty-list return
(-1 vs 0).
**Why:** They have different error contracts today (see Pattern 2).
**Avoid:** Keep each wrapper's return value identical to current; only share the inner walk.
**Warning signs:** drawDots early-returns differently, or `dot_size` logs change in UAT.

### Pitfall 2: Anchor `id` reported to R shifts by one
**What goes wrong:** Standardizing `anchor_select` to 0-based `id` changes what
`show anchor id` returns (currently no `+1` adjustment in dispatch).
**Why:** `anchor_select` currently does `id++` before the match (1-based); dispatch returns
it raw.
**Avoid:** Confirm during anchor UAT whether any R flow consumes the anchor selected-id;
the xyz coordinate flows are unaffected. If an R flow does read it, preserve the observable
value (the wrapper can re-add the offset, or leave the dispatch read path — which is
unchanged — to compensate).
**Warning signs:** anchor delete/move targets the wrong anchor by one position.

### Pitfall 3: Two `marker_set_t` instances not initialized before use
**What goes wrong:** `g_landmarks`/`g_anchors` static zero-init gives `slices=NULL`,
`slice_count=0` — which is the same as today's `NULL`/`0`, so allocation paths
(`set_*_slice_amount`) still work. But if the planner adds a `node_type` field, it must be
set (LANDMARK/ANCHOR) at definition or first use.
**Avoid:** Either pass `type` per `marker_add` call, or initialize the field in a designated
initializer.

### Pitfall 4: MinGW build "passes" but renders black
**What goes wrong:** Building with the WSL MinGW toolchain links fine but the GUI mesh is
black — easy to mistake for a regression introduced by the refactor.
**Avoid:** Build/deploy/UAT **only** with MSVC (`build-msvc\Release\tkogl2.dll`).
[VERIFIED: BUILD.md, STATE.md]
**Warning signs:** black/blank mesh — that's the toolchain, not your code.

### Pitfall 5: Forgetting `drawDots`/`drawAnchors` live in `tcl_dispatch.c`, not the marker file
**What goes wrong:** Attempting to move the draw functions into `marker.c` would modify
`tcl_dispatch.c` (forbidden — D-01) and pull GL/model globals into the marker module.
**Avoid:** Leave `drawDots`/`drawAnchors` exactly where they are; `marker.c` only provides
the `dot_get`/`anchor_get`/`*_slice_index` accessors they call.

## Validation Architecture

> Nyquist validation is **enabled** (`config.json workflow.nyquist_validation: true`). There
> is **no automated Tk/OpenGL test harness** — verification is manual Windows R GUI UAT plus
> a build/compile gate. The "tests" here are a deterministic build + a scripted manual UAT
> checklist, not unit tests.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | **None automated** — MSVC compile gate + manual Windows R GUI UAT |
| Config file | `CMakeLists.txt` (build), `.planning/smoke-test-findings.md` (UAT log) |
| Quick run command | `cmake --build build-msvc --config Release` (compile + link must pass) |
| Full suite command | Deploy DLL → `devtools::load_all(".")` → `GUImorph()` → manual checklist |

### Phase Requirements → Validation Map
| Req | Behavior | Test Type | Command / Procedure | Automated? |
|-----|----------|-----------|---------------------|-----------|
| CENG-02 | DLL compiles + links with `marker.c`, no `dot_ZARF_9.c` | build gate | `cmake --build build-msvc --config Release`; verify `Tkogl2_Init` export (`dumpbin /exports` or `objdump -p`) | ✅ build |
| CENG-02 | Landmark place/select/move/delete unchanged | manual UAT | Double-click place; single-click select; move; delete; compare to pre-Phase-8 DLL if suspect (D-13) | ❌ manual |
| CENG-02 (D-03) | Anchor place/select/move/delete **now correct** | manual UAT | On Anchors tab: place N anchors, select one, move it, delete it — confirm the *intended* anchor changes (not a landmark, not the wrong index) | ❌ manual |
| CENG-02 (D-11) | `.dgt` round-trip incl. anchors | manual UAT | Load `C13.1.ply` → landmarks + 1 curve + ≥1 anchor → save `.dgt` → same-session `openDgt` reload → confirm landmarks, curve, **and anchor** restore | ❌ manual |

### Sampling Rate
- **Per task commit:** MSVC compile + link clean (no warnings-as-errors regressions).
- **Per plan (esp. 08-02/08-03):** build → deploy → minimal smoke (GUI opens, PLY loads,
  double-click landmark) — the Phase 7 per-plan smoke pattern.
- **Phase gate (08-03):** full digitize round-trip **plus** anchor place/select/move/delete
  UAT (D-10) and anchor `.dgt` persistence (D-11); append results to
  `.planning/smoke-test-findings.md` (D-12).

### Wave 0 Gaps
- [ ] No automated harness exists or is in scope — none to create (QA-01 is v2/deferred).
- [ ] Ensure a **pre-Phase-8 DLL backup** exists before first deploy (D-13).
- [ ] Confirm MSVC build environment is available on the UAT machine (see Environment
  Availability).

*The Nyquist "sampling" here is: compile gate (cheap, every commit) + per-plan GUI smoke +
phase-gate full UAT. This is the established Phase 4/5/7 cadence for a no-automated-test
codebase.*

## Security Domain

> `security_enforcement` key is **absent** in `config.json` → treated as enabled. This is an
> internal, single-process C data-structure refactor with **no network, no auth, no
> sessions, and no untrusted input** beyond coordinate doubles already parsed upstream.
> Most ASVS categories are N/A; the relevant concern is **memory safety**.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | partial | Bounds + NULL checks in `marker_*` (the anchor path currently lacks `p`/`radius` checks — D-03 fix restores them) |
| V6 Cryptography | no | — |
| V (Memory safety, C-specific) | **yes** | NULL-guard before deref (fixes the `anchor_del_selected` stale-pointer bug); slice-index bounds checks (already present in `*_slice_index`); no buffer overrun in shared `sprintf(buffer,...)` (128-byte buffer — keep format widths bounded, as today) |

### Known Threat Patterns for this stack (C / fixed-function GL DLL)
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| NULL-pointer deref (`anchor_del_selected` on unset `anchor_selected`) | Denial of Service (crash) | NULL guard in unified `marker_del_selected` (D-03) |
| Out-of-bounds slice index | DoS / memory corruption | Keep the existing `id < 0` / `id >= slice_count` checks in `marker_slice_index`/`marker_get` |
| Stack buffer overrun via `sprintf(buffer,128,...)` | Tampering | Preserve current bounded formats; do not widen logged strings unboundedly (existing risk, not introduced here) |

## State of the Art

Not applicable in the usual sense — this is rehabilitation of an ~8-year-old fixed-function
OpenGL/Tcl C codebase under **Option A** (rehabilitate in place, Windows-only, legacy GL).
No library/version currency question. The "modern approach" the project explicitly
**rejected** (rgl/Shiny rewrites, modern GL core profile) is out of scope per PROJECT.md.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Standardizing `anchor_select` to 0-based `id` does not break any R-consumed anchor selected-id flow (only xyz coord flows are used in practice) | Anchor Asymmetry §6, Pitfall 2 | LOW–MED — if some R path reads the anchor selected-id, the reported index shifts by one; caught by anchor UAT (D-10). Confirm during planning by checking R callers of the anchor `id` getter. |
| A2 | `anchor_get_anchor` and `isAnchorArray*` (no header decls) are not referenced outside `dot_ZARF_9.c` | API Surface Inventory | LOW — grep found no external refs; if dead, they can be dropped or kept as internal helpers without breaking callers. |
| A3 | `ALLOCATE_WRAPPER`/`simpleLog` remain linkable from a new `marker.c` TU exactly as from `dot_ZARF_9.c` (same `def_ZARF_9.h` includes) | Standard Stack | LOW — both are `extern` via `def_ZARF_9.h`; `marker.c` includes the same headers. |

**All other claims in this research are `[VERIFIED: codebase]` via direct Read/Grep.**

## Open Question Resolved

**Q: Does `.dgt` serialize anchors?** → **YES.** Confirmed end-to-end:
- **Save:** `3dDigitize.main.r:1685` calls `write.anchors(fileName, specimenId, anchors)`;
  anchors come from `getAnchor(i)` (`:1665, 1732`) which reads C via
  `shows("anchor","xyz", id)`; the C handler (`tcl_dispatch.c:2480-2536`) iterates the
  anchor list (`anchor_get`) and emits `x y z` triples. `write.anchors` is defined at
  `3dDigitize.digitize.r:1223`.
- **Load:** `openDgt` (`3dDigitize.main.r:2453`) calls `read.anchors(rawContent)` (`:2545`;
  defined `3dDigitize.digitize.r:1156`), then `drawElements(...)` (`:2714`) →
  `draw.anchors(id, anchor)` (`:1521`, defined `3dDigitize.digitize.r:1305`) which re-adds
  each anchor through the C `anchor_add` path.
- The `.dgt` per-specimen slot `[[9]]` = number of anchor points (`3dDigitize.digitize.r:22`).

**Therefore D-11's anchor-persistence check is VIABLE — keep it.** The anchor round-trip
exercises exactly the functions changed by D-03 (`anchor_add` on load, the anchor list-walk
on save), making it a strong regression signal. [VERIFIED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| MSVC (VS 2022 Build Tools, v143) | Build `tkogl2.dll` | Must verify on UAT machine | 17.x | **None** — MinGW renders black mesh; blocking if absent |
| CMake | Build config | Must verify | ≥ 3.16 | none |
| Windows R | UAT runtime | ✓ (Phase 1–7 used it) | 4.6+ | none |
| `C13.1.ply` / `test_fresh.dgt` | Smoke fixtures | Local only (gitignored) | — | use any PLY + fresh digitize session |
| `dumpbin`/`objdump` | Verify `Tkogl2_Init` export | with VS / MinGW | — | skip export check if GUI loads |

**Missing dependencies with no fallback:** MSVC toolchain — if not installed on the build
machine, the phase cannot be verified (do not substitute MinGW). Confirm before execution.

**Note:** the build runs on **Windows** (MSVC). The WSL/UNC workspace is for editing source;
the `cmake --build build-msvc` step must run in a Windows Developer PowerShell.

## Project Constraints (from .cursorrules)

`.cursorrules` defines the **RTK token-optimization** convention only: prefix shell commands
with `rtk` (e.g. `rtk git status`, `rtk grep`, `rtk read`) to reduce token usage;
pass-through is safe; use the raw command for debugging. No coding-style or
forbidden-pattern directives that affect the C refactor. [VERIFIED: .cursorrules]
No `.cursor/rules/*.md` project skills relevant to C-engine work were found beyond the GSD
skill set.

## Sources

### Primary (HIGH confidence — direct codebase reads this session)
- `integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c` (full, 1384 lines) — duplication, parallel state, anchor bugs, select logging
- `integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h` — `dot_t`, enum, all declarations
- `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c` — caller inventory, `drawDots`/`drawAnchors`, `show anchor xyz`, `del` handlers
- `integrated-guimorph-development_EOC/Project/tkogl2/src/curve_ZARF_9.c` — `curve_addDot` dependency on `dot_t` (no API calls)
- `integrated-guimorph-development_EOC/Project/tkogl2/src/ogl_model_ply_ZARF_9.c` — `dot_add`/`dot_slice_index`/`*SetArrayIndex` callers
- `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt` — source list, MSVC/MinGW linkage
- `3dDigitize.main.r` / `3dDigitize.digitize.r` — `.dgt` anchor save/load round-trip
- `BUILD.md` — MSVC build/deploy cycle, Phase 7 layout table
- `.planning/` CONTEXT/REQUIREMENTS/ROADMAP/STATE/PROJECT, `07-02-SUMMARY.md`, `config.json`, `.cursorrules`

### Secondary / Tertiary
- None. No external/web sources needed — phase is entirely internal.

## Metadata

**Confidence breakdown:**
- API surface & callers: HIGH — enumerated by grep + full file reads
- Parallel state → `marker_set_t`: HIGH — statics read verbatim
- Anchor bugs: HIGH — exact line numbers verified
- `.dgt` anchor persistence: HIGH — save + load paths both traced
- Build/verify harness: HIGH — BUILD.md + STATE.md + Phase 7 summary
- Anchor `id` R-consumption impact (A1): MEDIUM — inferred; confirm in planning

**Research date:** 2026-06-22
**Valid until:** Stable (legacy frozen codebase) — ~90 days; re-verify only if Phase 7
module layout or `.dgt` format changes.
