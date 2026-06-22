# Phase 8: C Engine Deduplication - Pattern Map

**Mapped:** 2026-06-22
**Files analyzed:** 6 (2 new, 2 modified, 1 deleted, 2 unchanged-but-relevant)
**Analogs found:** 5 / 5 (all changed/created files have a strong in-repo analog)

The dominant analog for the *whole phase* is the **Phase 7 modularization precedent**:
new `tcl_*` modules were added, the `tcl_if_ZARF_9.c` god file was deleted, and
`CMakeLists.txt` was edited incrementally — exactly the add-new / delete-old / CMake
shape this phase repeats for `marker.c` vs `dot_ZARF_9.c`. The new module's *skeleton*
(pragmas → includes → version pointer → file-statics → functions; matching `.h` with
`#pragma once` guard + `#include "def_ZARF_9.h"` + declarations) copies the
`tcl_log.c`/`tcl_log.h` and `tcl_state.h` shape. The *function bodies* inside `marker.c`
are absorbed verbatim (landmark) or fixed-by-construction (anchor) from the existing
`dot_*`/`anchor_*` bodies in `dot_ZARF_9.c`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `…/tkogl2/src/marker.c` (NEW) | module / C-engine data structure | CRUD + transform (linked-list ops over `marker_set_t`) | `…/tkogl2/src/tcl_log.c` (skeleton) + `…/tkogl2/src/dot_ZARF_9.c` (bodies) | exact (skeleton) + source-of-truth (bodies) |
| `…/tkogl2/src/marker.h` (NEW) | header / cross-module API | declarations | `…/tkogl2/src/tcl_log.h` / `tcl_state.h` | exact |
| `…/tkogl2/src/def_ZARF_9.h` (MODIFIED) | shared types + declarations header | declarations | itself (Phase 7 declaration-split into `tcl_state.h`) | exact |
| `…/tkogl2/CMakeLists.txt` (MODIFIED) | build config | source-list edit | Phase 7 CMake edit (same `add_library` list) | exact |
| `…/tkogl2/src/dot_ZARF_9.c` (DELETED) | module being absorbed | — | Phase 7 deletion of `tcl_if_ZARF_9.c` | exact (precedent) |
| `…/tkogl2/src/tcl_dispatch.c` (UNCHANGED) | name-dispatch consumer | request-response | n/a — must keep compiling against wrapper names | reference only |
| `…/tkogl2/src/curve_ZARF_9.c` (UNCHANGED) | `dot_t` consumer | reference | n/a — `dot_t` layout must not change | reference only |

> Paths abbreviated `…/tkogl2` = `integrated-guimorph-development_EOC/Project/tkogl2`.

## Pattern Assignments

### `marker.c` (NEW — module / C-engine data structure, CRUD + transform)

**Analog A — module skeleton: `tcl_log.c`**

Copy the translation-unit header shape exactly (warning pragmas → system includes →
project includes → version const + `*Ptr` → file-statics → functions). The existing
`dot_ZARF_9.c` opening is the most literal template since `marker.c` replaces it:

```1:28:integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c
#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include "RunTime_Defines_ZARF_9.h"
#include "def_ZARF_9.h"

const char DOT_VERSION_INFORMATION[] = "File dot Edit revision date is 15 August 2020 4:22 PM";
const char* dotVersionPtr = DOT_VERSION_INFORMATION;


static dot_t** dots = NULL; /*array storing dots, dot_slice_index indicates which dots belong to which specimen*/
static int dot_slice_id = 0;
static int dot_slice_amount = 0;
static dot_t* selected = NULL;
static int selected_id = 0;

static dot_t** anchors = NULL;
static int anchor_slice_id = 0;
static int anchor_slice_amount = 0;
static dot_t* anchor_selected = NULL;
static int anchor_selected_id = 0;


static char buffer[128];

#define DOT_EQUAL(p1, p2) p1.x == p2->x && p1.y == p2->y && p1.z == p2->z

#define IS_IN_RANGE(target, test, dotRadius) (target - dotRadius) <= test && (target + dotRadius) >= test
```

**What to replicate / change:**
- Keep the `#pragma warning` lines, `#include "RunTime_Defines_ZARF_9.h"` +
  `#include "def_ZARF_9.h"`. Add `#include "marker.h"` (and `tcl_log.h`/`tcl_state.h`
  if `simpleLog`/globals aren't already reachable via `def_ZARF_9.h`). Note
  `tcl_log.c` includes `tcl_log.h` + `tcl_state.h` explicitly (`tcl_log.c:12-15`) —
  follow that include discipline.
- Keep a **file-static `dotVersionPtr`** const string (it is `extern`-referenced by
  `tcl_log.c:20` → `simpleLogDotInformation()`; renaming/dropping it breaks the log
  module link). Update the literal text if desired but keep the symbol name
  `dotVersionPtr` and `DOT_VERSION_INFORMATION`.
- **Replace the 10 parallel statics (lines 11-21) with the two `marker_set_t`
  instances** per RESEARCH §"Parallel Global State" (`g_landmarks`, `g_anchors`).
- **Keep the file-static `char buffer[128]` (line 24)** — do NOT extern it from another
  TU; each TU owns its own `buffer` (RESEARCH Anti-Pattern; `tcl_log.c` & dispatch each
  declare their own).
- **Move the two macros (lines 26-28) into `marker.c`** unchanged (`DOT_EQUAL`,
  `IS_IN_RANGE`) — behavior-preserving per D-04 / "Don't Hand-Roll".

**Analog B — landmark body to absorb verbatim (`dot_select`, the canonical core):**

```113:224:integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c
int dot_select(point_t* p, float dotRadius)
{
	if (dots == NULL)
	{ simpleLog("ERROR : dot select when the dots array is null"); return -1; }
	if (NULL == p)                       // BUG-FIX SOURCE: anchor_select lacks this
	{ simpleLog("ERROR : dot select NULL argument for point_t* p"); return -1; }
	if (dot_slice_id < 0)  { ... return -1; }
	if (dot_slice_id >= dot_slice_amount) { ... return -1; }
	if (dotRadius < 0)                   // BUG-FIX SOURCE: anchor_select lacks this
	{ simpleLog("ERROR : dot select  - dotRadius is negative"); return -1; }
	dot_t* n = dots[dot_slice_id];
	if (NULL == n) { ... return -1; }
	// ...pre-loop INFO logging (KEEP, lines 154-157)...
	int id = 0;
	while (n != NULL)
	{
		// lines 166-197: SIX in-loop IS_IN_RANGE DEBUG/FAIL simpleLog calls -> TRIM (D-05)
		if (IS_IN_RANGE(n->p.x, p->x, dotRadius)
			&& IS_IN_RANGE(n->p.y, p->y, dotRadius)
			&& IS_IN_RANGE(n->p.z, p->z, dotRadius))
		{
			selected = n;            // -> s->selected = n;
			selected_id = id;        // -> s->selected_id = id;  (0-based: id++ AFTER match)
			// post-match INFO logging (KEEP, lines 209-214)
			return 0;
		}
		id++;
		n = n->next;
	}
	simpleLog("ERROR : dot_select - dot close enough to location not found ... list searched to end");
	return -1;
}
```

This is the **template for `marker_select(marker_set_t* s, point_t* p, float r)`**:
- Replace every `dots`→`s->slices`, `dot_slice_id`→`s->slice_id`,
  `dot_slice_amount`→`s->slice_count`, `selected`→`s->selected`,
  `selected_id`→`s->selected_id`.
- **Keep** the `NULL == p` (line 121-125) and `dotRadius < 0` (line 139-143) guards —
  these are exactly the checks `anchor_select` is missing (D-03 §5).
- **Keep** the 0-based `id++` *after* the match test (line 218) — this is the convention
  both sets adopt (D-03 §6). `anchor_select`'s `id++` *before* the test (line 1016) is
  dropped.
- **Trim** only the six in-loop `IS_IN_RANGE` DEBUG/FAIL `simpleLog` calls (lines
  166-197) — they have no anchor counterpart and collapse on merge (D-05). Keep the
  pre-loop "Starting to search" (154-157) and post-match "found dot" (209-214) logs.

**Analog C — `dot_add` (template for `marker_add` with a `type` arg):**

```236:305:integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c
int dot_add(point_t* p, color_t* c)
{
	if (dots == NULL) { ... return -1; }
	if (NULL == p)    { ... return -1; }
	if (NULL == c)    { ... return -1; }
	dot_t* node = (dot_t*)ALLOCATE_WRAPPER((unsigned int)sizeof(dot_t));
	if (NULL == node) { ... return -1; }
	node->p.x = p->x; node->p.y = p->y; node->p.z = p->z;
	node->c.r = c->r; node->c.g = c->g; node->c.b = c->b;
	node->next = NULL;
	node->type = LANDMARK;          // <-- the ONLY divergence: anchor_add sets ANCHOR
	if (NULL == dots[dot_slice_id]) { dots[dot_slice_id] = node; }
	else { dot_t* n = dots[dot_slice_id]; while (n->next != NULL) n = n->next; n->next = node; }
	return 0;
}
```

`marker_add(marker_set_t* s, point_t* p, color_t* c, show_mode_t type)` is this body
with `node->type = type;` and set-pointer substitution. Use the existing
`ALLOCATE_WRAPPER` (RESEARCH "Don't Hand-Roll"). Wrappers:
`dot_add` → `marker_add(&g_landmarks, p, c, LANDMARK)`;
`anchor_add` → `marker_add(&g_anchors, p, c, ANCHOR)`.

**Analog D — `dot_del` + `dot_del_selected` (template for `marker_del`*; fixes BUG-4):**

```348:400:integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c
int dot_del(point_t* p)
{
	if (dots == NULL) { ... return -1; }
	if (NULL == p)    { ... return -1; }
	if (DOT_EQUAL(dots[dot_slice_id]->p, p))     // head-match: free head, advance
	{ dot_t* tempPtr = dots[dot_slice_id];
	  dots[dot_slice_id] = dots[dot_slice_id]->next;
	  FREE_WRAPPER((void*)tempPtr); return 0; }
	dot_t* n = dots[dot_slice_id];               // walk + unlink
	while (n->next != NULL)
	{ if (DOT_EQUAL(n->next->p, p)) { dot_t* tmp = n->next; n->next = tmp->next; FREE_WRAPPER((void*)tmp); return 0; }
	  n = n->next; }
	return -1;
}
int dot_del_selected()
{
	dot_del(&selected->p);   // <-- works for dots because dot_select sets `selected`
	selected = NULL;
	return dot_size();
}
```

`marker_del_selected(marker_set_t* s)` must **add a NULL guard** before deref
(`if (NULL == s->selected) return -1;`) — the unified core thereby fixes BUG-4
(`anchor_del_selected` deref of never-set `anchor_selected`, lines 826-831) by
construction. The bounds/NULL-list checks `dot_del` has are applied to both sets,
giving anchors the checks `anchor_del` lacked (D-03).

**Anchor bugs the unified core fixes BY CONSTRUCTION** (these bodies are the
*divergent* anchor code that must NOT be copied — they are replaced by routing
`&g_anchors` through `marker_*`):

```1003:1029:integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c
	// anchor_select BUGS:
	int id = 0;
	while (n != NULL)
	{
		id++;                                  // BUG-6: id++ BEFORE match (1-based) -> drop
		if (IS_IN_RANGE(...) && ...) {
			selected = n;                      // BUG-1: writes DOT global -> use s->selected
			selected_id = id;                  // BUG-1: writes DOT global -> use s->selected_id
			return 0;
		}
		n = n->next;
	}
	// also missing: NULL==p check and dotRadius<0 check (BUG-5)
```

```1032:1065:integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c
int anchor_move(point_t* p)
{
	if (NULL == selected) { ... return -1; }   // BUG-2: reads DOT global
	if (selected != NULL) { selected->p.x = p->x; ... }   // BUG-2: moves DOT node
	return 0;
}
int anchor_color(color_t* c)
{
	if (NULL == c) { ... return -1; }
	if (selected != NULL) { selected->c.r = c->r; ... }   // BUG-3: recolors DOT node
	return 0;
}
```

```826:831:integrated-guimorph-development_EOC/Project/tkogl2/src/dot_ZARF_9.c
int anchor_del_selected()
{
	anchor_del(&anchor_selected->p);   // BUG-4: anchor_selected never set by anchor_select -> stale/NULL deref
	anchor_selected = NULL;
	return anchor_size();
}
```

After unification, `anchor_move`/`anchor_color`/`anchor_select`/`anchor_del_selected`
become one-line wrappers forwarding `&g_anchors` to `marker_*`, so each uses
`g_anchors.selected` / `g_anchors.selected_id` — the bugs disappear (D-03).

**Wrapper pattern (apply to ALL ~50 public names — RESEARCH Pattern 1):**

```c
// marker.c — every dot_ZARF_9.h name survives as a one-liner
int dot_select(point_t* p, float r)    { return marker_select(&g_landmarks, p, r); }
int anchor_select(point_t* p, float r) { return marker_select(&g_anchors,   p, r); }
int dot_add(point_t* p, color_t* c)    { return marker_add(&g_landmarks, p, c, LANDMARK); }
int anchor_add(point_t* p, color_t* c) { return marker_add(&g_anchors,   p, c, ANCHOR); }
// ...and so on for *_move/*_color/*_del/*_del_selected/*_size/*_get/
//    *SetArrayIndex/*_slice_index/get_*_slice_*/*selected_id/*GetArraySize/etc.
```

> **Accessor-variant caution (RESEARCH Pattern 2 / Pitfall 1):** `dot_size()` returns
> **-1** on NULL head (lines 76-105) while `dot_getListLengthAtCurrentSlice()` returns
> **0**. Consolidate the inner list-walk into one helper but each public wrapper MUST
> keep its exact empty/error return contract. Same for the `+1` discrepancy: `show
> landmark id` returns `dot_selected_id()+1` but `show anchor id` returns
> `anchors_selected_id()` raw — confirm in anchor UAT (D-10 / Pitfall 2).

---

### `marker.h` (NEW — header / cross-module API)

**Analog:** `tcl_log.h` (and `tcl_state.h`). Copy the guard + include + declaration shape:

```1:11:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_log.h
#pragma once
#ifndef TCL_LOG_H
#define TCL_LOG_H

#include "def_ZARF_9.h"

int simpleLog_Open(void);
int simpleLog_Close(void);
int simpleLogBlankLine(void);
int simpleLog(const char* yC);
int simpleLog_Obj(Tcl_Obj* p);
```

**Replicate:** `#pragma once` + `#ifndef MARKER_H` guard, `#include "def_ZARF_9.h"`
(needs `dot_t`, `point_t`, `color_t`, `show_mode_t`), then declare the new cross-module
API: `marker_set_t` typedef, `marker_*` core prototypes, and (planner's discretion per
D-08) the `dot_*`/`anchor_*` wrapper prototypes — OR leave the wrapper prototypes in
`def_ZARF_9.h` and put only the `marker_*` core + `marker_set_t` here. End with
`#endif`. The cross-module API (anything dispatch/PLY-loader calls) must be reachable;
`tcl_state.h` shows the convention of declaring the struct-bearing extern surface in the
module header (`tcl_state.h:5` includes `def_ZARF_9.h` then declares everything).

---

### `def_ZARF_9.h` (MODIFIED — shared types + declarations)

**Analog:** itself + the Phase 7 split (declarations that moved into `tcl_state.h`).

**KEEP unchanged (D-08 — `curve_addDot` & `show xyz` depend on `dot_t` layout):**

```75:92:integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h
typedef enum {
	NONE,
	SPECIMEN,
	LANDMARK,
	DOWN_SAMPLE,
	DOWN_SAMPLE_ONLY,
	CURVE,
	ANCHOR,
	ALL
} show_mode_t;

typedef struct dot_t
{
	point_t p;
	color_t c;
	show_mode_t type;
	struct dot_t* next;
} dot_t;
```

**RECONCILE the `dot_*`/`anchor_*` declarations (lines 174-256).** These are the ~50
prototypes the wrappers satisfy. Planner's discretion (D-08): either (a) leave them here
and add `marker_*`/`marker_set_t` to `marker.h`, or (b) move the cross-module ones to
`marker.h` and `#include "marker.h"` where needed. RESEARCH notes harmless **duplicate
declarations** already exist (`get_dot_slice_index` at 213 & 245; `get_anchor_slice_index`
at 246 & 252) — don't be surprised; don't introduce new conflicting prototypes.

```174:256:integrated-guimorph-development_EOC/Project/tkogl2/src/def_ZARF_9.h
dot_t* dot_get(int id);
dot_t* anchor_get(int id);
dot_t* dot_get_selected();
dot_t* anchor_get_selected();
// ... ~50 dot_*/anchor_*/get_*/*Get*/*Set* prototypes through line 256 ...
int isDotArrayNotNull();
int isDotArrayNull();
```

---

### `CMakeLists.txt` (MODIFIED — build config, source-list edit)

**Analog:** the Phase 7 edit to this same `add_library(tkogl2 SHARED ...)` list (it
already shows the five `tcl_*` modules that replaced the god file).

```44:56:integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt
add_library(tkogl2 SHARED
    ${SRC}/tcl_init.c
    ${SRC}/tcl_dispatch.c
    ${SRC}/tcl_window.c
    ${SRC}/tcl_state.c
    ${SRC}/tcl_log.c
    ${SRC}/ogl_ZARF9.c
    ${SRC}/ogl_model_ZARF_9.c
    ${SRC}/ogl_model_ply_ZARF_9.c
    ${SRC}/curve_ZARF_9.c
    ${SRC}/dot_ZARF_9.c          # <-- DROP this line
    ${SRC}/StatisticsFunction_ZARF_9.c
)
```

**Edit:** replace `${SRC}/dot_ZARF_9.c` with `${SRC}/marker.c` (add `marker.c`, drop
`dot_ZARF_9.c`) — D-09, mirroring how Phase 7 removed `tcl_if_ZARF_9.c`. No other CMake
changes needed (no new include dirs, no new libs — `marker.c` uses the same
`def_ZARF_9.h`/`ALLOCATE_WRAPPER`/`simpleLog` already linked). The CMake file also runs
on **MSVC only** for the verified build (lines 9-20 / RESEARCH Pitfall 4).

---

### `dot_ZARF_9.c` (DELETED — module absorbed into `marker.c`)

**Analog:** Phase 7's deletion of `tcl_if_ZARF_9.c` (07-03-SUMMARY.md `deleted:` list,
"Delete god file entirely rather than keep empty stub"). Same procedure:
1. Move all retained bodies/wrappers into `marker.c`.
2. Remove `${SRC}/dot_ZARF_9.c` from `CMakeLists.txt`.
3. Delete the file. Confirm nothing `#include`s the `.c` (RESEARCH "canonical
   question": only `CMakeLists.txt` references the TU; all callers use `def_ZARF_9.h`
   declarations).
**Verify-truly-dead before dropping** (Anti-Pattern): `dot_get_dot` IS declared
(`def_ZARF_9.h:181`) → keep as wrapper; `anchor_get_anchor` / `isAnchorArray*` have no
header decl (A2) → keep as internal helpers unless grep confirms zero refs.

---

### `tcl_dispatch.c` & `curve_ZARF_9.c` (UNCHANGED — reference only)

- **`tcl_dispatch.c`** — sole name-dispatch consumer; **must keep compiling against
  every wrapper name** (D-01). `drawDots()`/`drawAnchors()` are **defined here, not in
  marker.c** — do not move them (RESEARCH Pitfall 5). No edits.
- **`curve_ZARF_9.c`** — consumes `dot_t` via `curve_addDot(int, dot_t*)`; `dot_t`
  layout must not change. No edits.

## Shared Patterns

### Module translation-unit skeleton
**Source:** `tcl_log.c:1-15` (pragmas → includes → version const+Ptr) and
`dot_ZARF_9.c:1-28` (the literal predecessor of `marker.c`).
**Apply to:** `marker.c`.
Keep `#pragma warning(disable:4305/4244)`, `#include "RunTime_Defines_ZARF_9.h"` +
`"def_ZARF_9.h"`, a `const char* dotVersionPtr` symbol (extern'd by `tcl_log.c`), and a
file-static `char buffer[128]`.

### Header guard + include
**Source:** `tcl_log.h:1-5`, `tcl_state.h:1-5`.
**Apply to:** `marker.h`.
`#pragma once` + `#ifndef …_H` + `#include "def_ZARF_9.h"` + decls + `#endif`.

### Allocation / logging / equality primitives (do NOT hand-roll)
**Source:** `ALLOCATE_WRAPPER`/`FREE_WRAPPER` (`def_ZARF_9.h:104-110`), `simpleLog`
(`tcl_log.c:130`), `DOT_EQUAL`/`IS_IN_RANGE` (`dot_ZARF_9.c:26-28`).
**Apply to:** every `marker_*` function. Behavior-preserving (D-04).

### CMake source-list edit (add-new / drop-old)
**Source:** `CMakeLists.txt:44-56` (the post-Phase-7 list).
**Apply to:** the single `add_library` list — add `marker.c`, drop `dot_ZARF_9.c`.

### God-file deletion procedure
**Source:** Phase 7 (`07-03-SUMMARY.md`: deleted `tcl_if_ZARF_9.c`, CMake updated,
smoke passed).
**Apply to:** deleting `dot_ZARF_9.c` after absorption; D-13 backup of the prior DLL
before redeploy mirrors Phase 7's `.pre-phase7.bak`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | — | — | Every created/modified/deleted file maps to a strong in-repo analog (Phase 7 module precedent + the `dot_*`/`anchor_*` bodies). The only genuinely new construct is the `marker_set_t` struct + `marker_*` core, whose shape is dictated by the existing parallel statics (`dot_ZARF_9.c:11-21`) and function bodies — not a missing analog. |

## Metadata

**Analog search scope:** `integrated-guimorph-development_EOC/Project/tkogl2/src/`
(`dot_ZARF_9.c`, `def_ZARF_9.h`, `tcl_log.c/.h`, `tcl_state.h`) and
`…/tkogl2/CMakeLists.txt`; Phase 7 handoff (`07-03-SUMMARY.md`).
**Files scanned:** 6 source/header/build files + 1 Phase 7 summary (read-only).
**Pattern extraction date:** 2026-06-22

## PATTERN MAPPING COMPLETE

**Phase:** 8 - C Engine Deduplication
**Files classified:** 6 (2 new, 2 modified, 1 deleted, 2 reference-only)
**Analogs found:** 5 / 5

### Coverage
- Files with exact analog: 4 (`marker.h`←`tcl_log.h`; `def_ZARF_9.h`←self/Phase-7 split;
  `CMakeLists.txt`←Phase-7 edit; `dot_ZARF_9.c` deletion←`tcl_if_ZARF_9.c` deletion)
- Files with source-of-truth + skeleton analog: 1 (`marker.c` ← `tcl_log.c` skeleton +
  `dot_ZARF_9.c` bodies)
- Files with no analog: 0

### Key Patterns Identified
- **Module skeleton:** new `marker.c`/`marker.h` copy the `tcl_log.c`/`tcl_log.h`
  pragmas→includes→version-ptr→statics→functions / guard→include→decls shape; `marker.c`
  literally replaces `dot_ZARF_9.c:1-28`.
- **Thin-wrapper dedup:** the canonical `dot_*` body (`dot_select`/`dot_add`/`dot_del`)
  becomes `marker_*(marker_set_t* s, …)`; ~50 public names survive as one-line wrappers
  forwarding `&g_landmarks`/`&g_anchors`. Anchor bugs (lines 1003-1029, 1032-1065,
  826-831) vanish by construction because each set uses its own selection state.
- **Add-new / delete-old / CMake:** mirror Phase 7 exactly — add `marker.c`, drop and
  delete `dot_ZARF_9.c` from `CMakeLists.txt:44-56`, keep a pre-Phase-8 DLL backup.

### File Created
`.planning/phases/08-c-engine-deduplication/08-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. The planner can reference these analog files, line ranges, and
the keep/trim/fix annotations directly in the 08-01/08-02/08-03 plan actions.
