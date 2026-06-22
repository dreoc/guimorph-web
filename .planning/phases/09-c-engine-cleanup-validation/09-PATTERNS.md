# Phase 9: C Engine Cleanup & Validation - Pattern Map

**Mapped:** 2026-06-22
**Files analyzed:** 11 (9 C sources/headers + `CMakeLists.txt` + `BUILD.md`)
**Analogs found:** 11 / 11 (this is an in-place refactor — every change has an in-repo precedent)

> **Nature of this phase:** All "files to modify" are **EXISTING** files. There are **no new files**.
> The "analog" for each change is therefore an *in-repo precedent* (Phase 7/8 convention or a
> sibling pattern in the same file), not a template for a new file. Concrete copy-from excerpts and
> line numbers below.

> **Tooling caveat (carried from RESEARCH):** Cursor `Grep`/`Glob` under-traverse the `\\wsl$\` UNC
> mount. All line numbers below were taken from direct `Read` of the live files this session.

---

## File Classification

| Modified File | Role | Data Flow | Closest In-Repo Precedent | Match Quality |
|---------------|------|-----------|---------------------------|---------------|
| `tcl_state.h` | header (global decls) | state-declaration | own `GBL_LANDMARK_SET`/`CONST_25` pairing (lines 11-13) + Phase 7 extern convention | exact (same file) |
| `tcl_state.c` | state/storage module | state-definition + debug-dump | own `GBL_LANDMARK_SET[25][3]`+`CONST_25` (32-35); `marker.c` array-state | exact |
| `tcl_dispatch.c` | controller (Tcl handlers) | request-response + dev-logging | own live curve cluster (2172-2202); commented ladders (2795-2865) | exact (same file) |
| `tcl_log.c` | utility (diagnostic facility) | file-I/O / append-log | `simpleLog()` itself (130-155) — the destination pattern | exact (canonical) |
| `tcl_log.h` | header (log API) | api-declaration | existing `simpleLog`/`simpleLog_Obj` decls (10-21) | exact |
| `ogl_model_ply_ZARF_9.c` | loader/parser | file-I/O (parse `.dgt`/PLY) | `simpleLog` port pattern; D-05 caution zone | role-match + caution |
| `ogl_model_ZARF_9.c` | OpenGL draw/model | transform/render | `if(0)` delete pattern (RESEARCH 09 example) | role-match |
| `curve_ZARF_9.c` | geometry/state module | transform | `if(0)` delete pattern; `marker.c` `if(0)` at 469 | role-match |
| `StatisticsFunction_ZARF_9.c` | compute module | batch/transform | bare-`printf` delete / `simpleLog` port | role-match |
| `RunTime_Defines_ZARF_9.h` | config header | build-directive | `MAKE_INERT` doc block (24-30); `#undef` (10) | exact (same file) |
| `CMakeLists.txt` / `BUILD.md` | build config / docs | build/doc | RESEARCH "BUILD.md update (D-14)" module table | doc-template |

---

## Pattern Assignments

### CENG-03 — Numbered globals → fixed-capacity arrays

#### `tcl_state.c` + `tcl_state.h` (state-definition + state-declaration)

**Precedent A — the literal "fixed-capacity array + named `#define` + extern in header" pattern already lives in the file being edited.**

Definition side, `tcl_state.c:32-35` (this is the *exact target form* CENG-03 wants, applied to the numbered families):

```32:36:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c
float GBL_LANDMARK_SET[25][3];
#define CONST_25  25
const float* pointerTO_GBL_LANDMARK_SET = &GBL_LANDMARK_SET[0][0];
int GBL_LANDMARK_SET_MAX_ROWS = CONST_25;
int GBL_LANDMARK_SET_NUMBER_OF_ROWS = 0;
```

Declaration side, `tcl_state.h:11-13` (single-definition-in-`.c` + `extern`-in-`.h`, Phase 7 convention):

```11:13:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.h
extern float GBL_LANDMARK_SET[25][3];
extern const float* pointerTO_GBL_LANDMARK_SET;
extern int GBL_LANDMARK_SET_MAX_ROWS;
```

> **CENG-03 capacity-doc note (RESEARCH):** `CONST_25` / `CONST_10` are *non-descriptive* magic
> names. D-01 wants a documented capacity. Rename to descriptive `#define`s
> (`GBL_LANDMARK_SET_CAPACITY 25`, etc.) in the header and comment them. **Do NOT shrink
> `GBL_CURVE_SET[25][3]`** — its array dim (25) intentionally exceeds `MAX_ROWS` (`CONST_10`=10);
> document the discrepancy, keep behavior.

**The numbered families to array-ify** — current definitions, `tcl_state.c:45-89`:

```45:89:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c
model_t* GBL_PTR_TO_A_MODEL;

model_t* GBL_PTR_MODEL_1 = NULL;
model_t* GBL_PTR_MODEL_2 = NULL;
model_t* GBL_PTR_MODEL_3 = NULL;
model_t* GBL_PTR_MODEL_4 = NULL;
model_t* GBL_PTR_MODEL_5 = NULL;

context_t* GBL_PTR_CONTEXT_1 = NULL;
context_t* GBL_PTR_CONTEXT_2 = NULL;
context_t* GBL_PTR_CONTEXT_3 = NULL;
context_t* GBL_PTR_CONTEXT_4 = NULL;
context_t* GBL_PTR_CONTEXT_5 = NULL;
/* ... GBL_LANDMARKS_*, GBL_CURVES_*, scalars between ... */
curve_t* GBL_PTR_CURVE_1 = NULL;
curve_t* GBL_PTR_CURVE_2 = NULL;
curve_t* GBL_PTR_CURVE_3 = NULL;
curve_t* GBL_PTR_CURVE_4 = NULL;
curve_t* GBL_PTR_CURVE_5 = NULL;
curve_t* GBL_PTR_CURVE_6 = NULL;
```

Current externs, `tcl_state.h:21-62` (note `GBL_PTR_TO_A_MODEL` at line 21 is **single, not numbered — LEAVE UNCHANGED**):

```21:62:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.h
extern model_t* GBL_PTR_TO_A_MODEL;
extern model_t* GBL_PTR_MODEL_1;
extern model_t* GBL_PTR_MODEL_2;
/* ... _3 _4 _5 ... */
extern context_t* GBL_PTR_CONTEXT_1;
/* ... _2.._5 ... */
extern curve_t* GBL_PTR_CURVE_1;
/* ... _2.._6 ... */
```

**Target form** (RESEARCH Code Examples — behavior-preserving array-ification):

```c
// tcl_state.h
#define GBL_MODEL_SLOTS    5   /* numbered-pointer mirror of models[0..4]; vestigial */
#define GBL_CONTEXT_SLOTS  5
#define GBL_CURVE_SLOTS    6
extern model_t*   GBL_PTR_MODEL[GBL_MODEL_SLOTS];
extern context_t* GBL_PTR_CONTEXT[GBL_CONTEXT_SLOTS];
extern curve_t*   GBL_PTR_CURVE[GBL_CURVE_SLOTS];

// tcl_state.c
model_t*   GBL_PTR_MODEL[GBL_MODEL_SLOTS]     = { NULL };
context_t* GBL_PTR_CONTEXT[GBL_CONTEXT_SLOTS] = { NULL };
curve_t*   GBL_PTR_CURVE[GBL_CURVE_SLOTS]     = { NULL };
```

**The one live read to update** — `snapshot()`, `tcl_state.c:430` (`GBL_PTR_MODEL_1` → `GBL_PTR_MODEL[0]`):

```430:431:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c
	simpleLogWriteModelToFile(GBL_PTR_MODEL_1);
```

The commented-out re-init ladder right below it (`tcl_state.c:244-263`) and the commented snapshot block (`432-461`) are **dead CENG-04 cruft** — array-ify-verbatim or delete. **Anti-pattern (RESEARCH):** do NOT revive these as live `for` loops — that adds behavior (violates D-02).

#### `marker.c` (array-state precedent — Phase 8)

`marker.c` is the precedent for **array-backed, indexed marker state with a documented contract in the header**. Note its capacity is *runtime* (`slice_count`), not a compile-time `#define` — so for the literal `#define`-capacity requirement, prefer Precedent A above. Use `marker.c` for the *struct-owns-its-state + header-documents-the-contract* shape.

State declared once as module-static, `marker.c:11-12`:

```11:12:integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c
static marker_set_t g_landmarks = { NULL, 0, 0, NULL, 0, LANDMARK };
static marker_set_t g_anchors  = { NULL, 0, 0, NULL, 0, ANCHOR };
```

Indexed array type + bounds field, `marker.h:33-40`:

```33:40:integrated-guimorph-development_EOC/Project/tkogl2/src/marker.h
typedef struct marker_set_t {
	dot_t** slices;
	int slice_id;
	int slice_count;
	dot_t* selected;
	int selected_id;
	show_mode_t node_type;
} marker_set_t;
```

Bounds-checked indexed access (the discipline new array code should mirror), `marker.c:452-466`:

```452:466:integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c
int marker_slice_index(marker_set_t* s, int id)
{
	if (id < 0)
	{
		sprintf(buffer, "ERROR : dot_slice_index ... index negative [%d]", id);
		simpleLog(buffer);
		return -1;
	}
	if (id >= s->slice_count)
	{
		sprintf(buffer, "ERROR : dot_slice_index ... index beyond linked list length [%d]", id);
		simpleLog(buffer);
		return -1;
	}
```

#### `tcl_dispatch.c` — the one live `GBL_PTR_CURVE` cluster (CENG-03 + Pitfall 3)

`add("curve",…)` handler, `tcl_dispatch.c:2172-2202`. This is the only live write/read of the curve family. **Contains a pre-existing index bug — preserve verbatim under D-02** (`CURVE_2` double-assigned at 2179 & 2184; `CURVE_3` read at 2185/2199 is never assigned here):

```2172:2202:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c
					if (0 == whichCurve)
					{
						GBL_PTR_CURVE_1 = get_curveAtIndex(0);
						simpleLogWriteCurveToFile(GBL_PTR_CURVE_1);
					}
					if (1 == whichCurve)
					{
						GBL_PTR_CURVE_2 = get_curveAtIndex(1);
						simpleLogWriteCurveToFile(GBL_PTR_CURVE_2);
					}
					if (3 == whichCurve)
					{
						GBL_PTR_CURVE_2 = get_curveAtIndex(2);
						simpleLogWriteCurveToFile(GBL_PTR_CURVE_3);
					}
				}
			}
		}

		if (NULL != GBL_PTR_CURVE_1)
		{
			simpleLogWriteCurveToFile(GBL_PTR_CURVE_1);
		}
		if (NULL != GBL_PTR_CURVE_2)
		{
			simpleLogWriteCurveToFile(GBL_PTR_CURVE_2);
		}
		if (NULL != GBL_PTR_CURVE_3)
		{
			simpleLogWriteCurveToFile(GBL_PTR_CURVE_3);
		}
```

**Index map (behavior-preserving):** `CURVE_1`→`[0]`, `CURVE_2`→`[1]` (twice, keep the bug), `CURVE_3`→`[2]`. Flag the bug to the user; fix only as an explicit separate decision (RESEARCH Open Q4).

---

### CENG-04 — Debug cruft removal

#### Diagnostic destination: `tcl_log.c` / `tcl_log.h` (the surviving channel)

**Analog/destination API** — port load-bearing diagnostics here instead of deleting. `tcl_log.h:7-23`:

```7:23:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_log.h
int simpleLog_Open(void);
int simpleLog_Close(void);
int simpleLogBlankLine(void);
int simpleLog(const char* yC);
int simpleLog_Obj(Tcl_Obj* p);
/* ... */
int simpleLogWriteModelToFile(model_t* m);
int simpleLogWriteContextToFile(context_t* c);
int simpleLogWriteCurveToFile(curve_t* c);
```

**Usage idiom** (literal-string vs `sprintf`-into-`buffer`-then-`simpleLog`) — copy from `marker.c`:

```33:33:integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c
		simpleLog("ERROR : dot_size ... dots array is NULL ... no length");
```

```51:52:integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c
	sprintf(buffer, "INFO : dot_size is [%d]", size);
	simpleLog(buffer);
```

**`simpleLog` itself** — confirms `fprintf(fp,…)` is the load-bearing file write (KEEP) and the only stdout echo is `#ifdef STAND_ALONE_TOOL`-gated (already inert in the library build). `tcl_log.c:130-155`:

```130:155:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_log.c
int simpleLog(const char* yC)
{
	char buffer[128];

	if (NULL == fp)
	{
		// do nothing
		return -1;
	}
	else
	{
		time_t rawtime;
		struct tm* timeinfo;
		time(&rawtime);
		timeinfo = localtime(&rawtime);
		strftime(buffer, 80, "%X", timeinfo);
		fprintf(fp, "[%4d] {%s}  <%s>\n", xCounts, buffer, yC);
		fflush(fp);
#ifdef STAND_ALONE_TOOL
		printf(" ! <%s>\n", yC);
#endif

		xCounts++;
	}
	return 0;
}
```

> **The "line 149 printf" the RESEARCH flags is already `#ifdef STAND_ALONE_TOOL`-gated** (148-150
> above) — i.e. dead in the `CODE_FOR_LIBRARY` build. It is NOT a live bare `printf`. Removing it is
> optional/cosmetic; low risk. Do **not** touch `fprintf(fp,…)` at 146 (that is the log facility).

**Port target form** (RESEARCH — for `ogl_loadDgtModel` `ERROR : why did we not find TAG_*`):

```c
// BEFORE: printf("ERROR : why did we not find TAG_SURF again ??");  (x2)
// AFTER:
simpleLog("ERROR : ogl_loadDgtModel : TAG_SURF present but no value parsed");
```

#### Bare-`printf` removal — `tcl_state.c` debug-dump functions

`tcl_state.c:489-629` are the 30 bare `printf` (`showPoint`, `ut_show_Model`, `show_GBL_LANDMARK_SET`, `show_GBL_CURVE_SET`). They are debug-only dumps. Example, `tcl_state.c:489-499`:

```489:499:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c
int showPoint(point_t* p)
{
	if (NULL == p)
	{
		return -1;
	}
	printf(" x : <%f>\n", p->x);
	printf(" y : <%f>\n", p->y);
	printf(" z : <%f>\n", p->z);
	return 0;
}
```

**Disposition (A1):** prefer removing whole functions + their prototypes in `tcl_state.h:92-103`
(`show_GBL_LANDMARK_SET`, `show_GBL_CURVE_SET`, `showPoint`, `ut_show_Model`) **only after grepping
call sites**. If referenced, keep the function and strip the `printf`. **Pitfall:** `ut_show_Model`
uses `sprintf(buffer,…); printf("%s\n", buffer);` pairs — delete *both* lines together, not just the
`printf`, or you leave dead `sprintf`s.

#### `if(0)` toggles + `MAKE_INERT`-intent blocks — delete outright (9 sites)

Use RESEARCH's authoritative site table (file:line). In-repo precedent for what a dead `if(0)` looks
like — `marker.c:469-479` (D-07 "delete block"):

```469:479:integrated-guimorph-development_EOC/Project/tkogl2/src/marker.c
	if (0)
	{
		simpleLog("ERROR >>> ERROR >>> ERROR In DOTS (anchors_slice_index)  SHOULD NOT BE HERE");
		int rv = -1;
		rv = set_curve_slice_index(id);
		if (rv != 0)
		{
			simpleLog("ERROR : fail return from curve_slice_index()");
			return -1;
		}
	}
```

| File | Line(s) | Disposition |
|------|---------|-------------|
| `curve_ZARF_9.c` | 572, 585 | delete `if(0)` block |
| `marker.c` | 469 | delete `if(0)` block (shown above) |
| `ogl_model_ZARF_9.c` | 488 | delete `if(0)` block (named in CONTEXT D-07) |
| `ogl_model_ply_ZARF_9.c` | 324, 379 | delete `if(0)` block (hardcoded path / per-vertex dump) |
| `tcl_dispatch.c` | 455, 1072, 3438 | delete; 1072 & 3438 are `// made inert` = D-06 |

#### `RunTime_Defines_ZARF_9.h` — prune obsolete `MAKE_INERT` docs (D-06, Open Q2)

The `MAKE_INERT` doc block + `#undef` (the only remaining trace of the directive). Safe to prune —
these are comments/`#undef`, **not** the frozen `def_ZARF_9.h` type layout. `RunTime_Defines_ZARF_9.h:10` and `:24-30`:

```24:30:integrated-guimorph-development_EOC/Project/tkogl2/src/RunTime_Defines_ZARF_9.h
// The directive  MAKE_INERT is for temporary use.
// it is intended to make broken code inert.
// For a formal code release the offending code should be removed from the source file
// To exclude offending code - wrap the code in the preprocessor directive 
// #ifdef MAKE_INERT
//     offending code here
// #endif
```

> Keep `#define CODE_FOR_LIBRARY` (line 49) and the `#undef` discipline intact. `STAND_ALONE_TOOL`
> blocks are **out of scope** by default (RESEARCH Open Q3 / A4) — CONTEXT named only
> `MAKE_INERT`/`if(0)`/`printf`.

#### Per-file bare-`printf` removal surface (RESEARCH authoritative counts)

| File | Live bare `printf(` | Disposition |
|------|--------------------:|-------------|
| `ogl_model_ply_ZARF_9.c` | 74 | **D-05 ZONE.** Delete pure trace; port `TAG_*` errors to `simpleLog`; keep all `sscanf`/`strstr`/`strncmp`/`FLAG_*`. Re-run both `.dgt` fixtures after. |
| `tcl_state.c` | 30 | Debug-dump functions (489-629) — remove whole functions if unreferenced. |
| `StatisticsFunction_ZARF_9.c` | 9 | Delete pure trace; port diagnostics to `simpleLog`. |
| `tcl_dispatch.c` | 4 | Pure trace (coord-bounds 584-586; filename 2937) → delete. Remove duplicate `D/D1/D2/D3` macro defs (96-100). |
| `tcl_log.c` | 1 (gated) | `STAND_ALONE_TOOL`-gated (149) — optional cosmetic removal. |
| `ogl_ZARF9.c`, `tcl_window.c`, `marker.c`, `curve_ZARF_9.c`, `ogl_model_ZARF_9.c` | 0 live | No bare-`printf` work; only `if(0)` blocks listed above. |

---

### CENG-05 — Validation (no source files; manual UAT)

No analog code. Validation is manual Windows MSVC GUI UAT recorded in
`.planning/smoke-test-findings.md` (append a "Phase 9 — Cleanup & Validation" section mirroring the
Phase 7/8 tables). Precedent: the existing Phase 7/8 UAT tables in that file. Two fixtures
(`test_fresh.dgt`, `test_dgt_anchors_curves.dgt`), full `load PLY → digitize → save → reload → GPA`
round-trip. Freshness banner precedent — `tcl_state.c:24`:

```24:24:integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_state.c
const char COMPILE_INFORMATION[] = "Library compile information : FRESH BUILD " __DATE__ " " __TIME__;
```

---

### Build & docs (09-03)

#### `CMakeLists.txt`
Touch only if file membership changes (none expected — no god file remains). No analog needed.

#### `BUILD.md` (D-14)
Replace the "C source layout (Phase 7)" section with RESEARCH's final module-layout table
(`tcl_init` / `tcl_dispatch` / `tcl_window` / `tcl_state` / `tcl_log` / `marker.c` /
`curve_ZARF_9.c` / `ogl_*` / `StatisticsFunction_ZARF_9.c`). Prune obsolete `tcl_if_ZARF_9.c` +
`.vcxproj` references and note the `tcl_if_ZARF_9.c.bak` orphan. Keep MSVC-only instructions.
Precedent: the existing BUILD.md layout table being replaced.

---

## Shared Patterns

### Single-definition global + `extern`-in-header (Phase 7 convention)
**Source of truth:** every global defined once in `tcl_state.c`, declared `extern` in `tcl_state.h`
(see `GBL_LANDMARK_SET` pairing, `tcl_state.c:32` ↔ `tcl_state.h:11`).
**Apply to:** all CENG-03 array conversions — change the definition, the `extern`, and add the
capacity `#define` **in lockstep** (a missed `extern` breaks the build; a renamed symbol referenced
in `tcl_dispatch.c` breaks the link).

### Route diagnostics through `simpleLog` (Phase 7 logging convention)
**Source:** `tcl_log.c` `simpleLog()` (130-155); usage idiom in `marker.c` (33, 51-52).
**Apply to:** every CENG-04 site classified load-bearing (errors / user-facing / parse diagnostics).
Pure stdout trace → delete; everything else → `simpleLog`.

### Keep `sprintf`/`fprintf`; target bare `printf(` only (Pitfall 1)
**Apply to:** all CENG-04 files. `sprintf` builds log strings; `fprintf(fp,…)` is the `tcl_log.c`
file writer. Word-boundary match `printf(` — never the `s`/`f`/`sn`/`v` prefixed forms.

### Frozen interface boundary (Pitfall 5)
**Apply to:** all edits. Do not alter `def_ZARF_9.h` type/enum layout or the 8 Tcl command
registrations in `tcl_init.c`. Numbered-global renames are internal (non-exported) symbols — safe,
but update all `extern`/usage sites together.

---

## No Analog Found

| File / Item | Role | Reason |
|-------------|------|--------|
| CENG-05 validation steps | manual UAT | No automated Tk/OpenGL harness exists (QA-01 deferred to v2). Use the manual sampling plan in RESEARCH "Validation Architecture" + `smoke-test-findings.md` precedent. |

> Everything else has an in-repo precedent — this is in-place cleanup, not greenfield.

## Open Decisions Surfaced to Planner (from RESEARCH)
1. **Dead `MODEL_2..5`/`CONTEXT_1..5`/`CURVE_4..6` families** — array-ify (clean CENG-03 deliverable) vs delete (also cruft). Recommend array-ify all three + delete commented ladders.
2. **`def_ZARF_9.h` `D/D1/D2/D3` macros** — remove call sites for sure; pruning the *definitions* is a small explicit sub-decision (macros ≠ frozen type layout).
3. **`STAND_ALONE_TOOL` blocks** — default OUT of scope (CONTEXT named only MAKE_INERT/if(0)/printf).
4. **Curve-index bug (Pitfall 3)** — preserve verbatim under D-02; flag to user.

## Metadata

**Analog search scope:** `integrated-guimorph-development_EOC/Project/tkogl2/src/` (read directly:
`marker.c`, `marker.h`, `tcl_state.c`, `tcl_state.h`, `tcl_log.c`, `tcl_log.h`,
`RunTime_Defines_ZARF_9.h`, `tcl_dispatch.c` curve cluster).
**Files read this session:** 8 (line numbers verified by direct Read; counts for unread sources
taken from RESEARCH authoritative `Select-String` inventory).
**Pattern extraction date:** 2026-06-22
