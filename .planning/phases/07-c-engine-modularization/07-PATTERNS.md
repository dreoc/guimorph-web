# Phase 7: C Engine Modularization - Pattern Map

**Mapped:** 2026-06-19
**Files analyzed:** 14
**Analogs found:** 12 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `tcl_if_ZARF_9.c` (split source) | controller/service (god file) | request-response, event-driven, file-I/O | `dot_ZARF_9.c` + `curve_ZARF_9.c` (existing split modules) | exact (self + precedent) |
| `tcl_dispatch.c` | controller/route | request-response, event-driven | `tcl_if_ZARF_9.c` handlers + draw pass | exact |
| `tcl_dispatch.h` | route | — | `def_ZARF_9.h` (handler declarations) | role-match |
| `tcl_window.c` | service/controller | request-response, WGL I/O | `tcl_if_ZARF_9.c` `setWindowId`/`setWindow` + `ogl_ZARF9.c` | exact |
| `tcl_window.h` | route | — | `def_ZARF_9.h` (`extern HDC dc`) | role-match |
| `tcl_state.c` | model/store | CRUD, transform | `tcl_if_ZARF_9.c` globals cluster + `dot_ZARF_9.c` module-local state | exact |
| `tcl_state.h` | model | — | `ogl_model_ply_ZARF_9.c` cross-TU `extern` pattern | exact |
| `tcl_log.c` | utility/service | file-I/O | `tcl_if_ZARF_9.c` `simpleLog_*` block | exact |
| `tcl_log.h` | utility | — | `def_ZARF_9.h` logging declarations | role-match |
| `tcl_init.c` | provider/config | request-response (DLL init) | `tcl_if_ZARF_9.c` `Tkogl2_Init` | exact |
| `CMakeLists.txt` | config | build | existing `CMakeLists.txt` | exact |
| `def_ZARF_9.h` | model | shared types | itself (extend minimally) | exact |
| `BUILD.md` | config/docs | — | `integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md` | role-match |
| `dot_ZARF_9.c` / `curve_ZARF_9.c` / `ogl_*.c` | service (unchanged) | — | themselves | reference-only |

## Pattern Assignments

### `tcl_dispatch.c` (controller, request-response + event-driven)

**Analog:** `tcl_if_ZARF_9.c` (handlers ~1068–4138, draw pass ~619–905, `onDisplay` ~5063–5133)

**Imports pattern** (lines 1–14, 13–14):
```c
#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include <string.h>
#include <stdio.h>
#include <stddef.h>
#include <time.h>
#include <math.h>
#include <stdint.h>
#include <memory.h>

#include "def_ZARF_9.h"
#include "RunTime_Defines_ZARF_9.h"
#include "tcl_dispatch.h"
#include "tcl_state.h"
#include "tcl_window.h"
#include "tcl_log.h"
```

**Tcl handler signature + dual-build guard** (lines 215–217, 1067–1071):
```c
#ifdef CODE_FOR_LIBRARY
#define TCL_CMD(name) int name(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
#endif

#ifdef STAND_ALONE_TOOL
int add(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[])
#else
TCL_CMD(add)
#endif
```

**Handler entry pattern** (lines 1072–1096):
```c
{
	int rv = -1;
	char messageBuffer[128];

	const char* shape = Wrapper_GetStringFromObj(objv[1], NULL);
	simpleLogBlankLine();
	simpleLog((const char*)"TCL_CMD_ADD");
	rv = TclIf_LogCommands(objc, objv);
	UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;

	if (strcmp(shape, "getCompileInformation") == 0)
	{
		sprintf(buffer, COMPILE_INFORMATION);
		simpleLog(buffer);
#ifdef CODE_FOR_LIBRARY
		char* msg = ALLOCATE_WRAPPER(512);
		sprintf(msg, buffer);
		Tcl_SetResult(interp, msg, TCL_DYNAMIC);
#endif
		return TCL_OK;
	}
	/* ... shape-string routing continues ... */
```

**TCL_RESULT macros** (lines 298–334) — move verbatim with handlers; require `interp`:
```c
#ifdef CODE_FOR_LIBRARY

#define TCL_RESULT_SUCCESS()  \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, "SUCCESS"); \
	Tcl_SetResult(interp, msg, TCL_DYNAMIC);

#define TCL_RESULT1(info, arg1) \
    char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, info, arg1); \
	Tcl_SetResult(interp, msg, TCL_DYNAMIC);
/* ... TCL_RESULT2, TCL_RESULT3, ERROR, IGNORE ... */

#endif
```

**Draw pass pattern** (lines 638–740):
```c
void drawDots()
{
	simpleLog("INFO : drawDots ... start");
	if (model_amount == 0)
	{
		simpleLog("INFO :drawDots ... model_amount is 0, nothing to do  .. .returning");
		return;
	}

	dotSetArrayIndex(model_index);
	anchorSetArrayIndex(model_index);
	/* ... iterate dot linked list, call ogl_drawDot/ogl_drawLabel ... */
	simpleLog("INFO : drawDots ... end");
	simpleLogBlankLine();
	return;
}
```

**onDisplay orchestration** (lines 5063–5130):
```c
void onDisplay()
{
#ifdef NO_GRAPHICS
	return;
#endif

	float dx = (float)width / height;
	glViewport(0, 0, width, height);
	/* ... projection, clear, push matrix, apply context transforms ... */
	switch (showModel)
	{
	case LANDMARK:
		drawDots();
		break;
	case ANCHOR:
		drawDots();
		drawAnchors();
		break;
	/* ... DOWN_SAMPLE, CURVE, DOWN_SAMPLE_ONLY ... */
	}
	glPopMatrix();
	glFlush();
#ifdef _WIN32
	SwapBuffers(dc);
#endif
}
```

**Handler exit pattern** — all handlers end with `onDisplay(); return TCL_OK;` (e.g. lines 2988–2989, 4136–4137).

**Symbols to move here (07-01):** `add`, `show`, `setSpecimen`, `setDownSample`, `setDot`, `del`, `loadDgt`, `directive` (unregistered), `drawDots`/`drawAnchors`/`drawCurves`/`drawGrid`, `onDisplay`, `getRealZ`, `getSpecimenCoordinate`, `validateDot`, `specimen_del`, `addDot_NO_TCL`, `addAnchor_NO_TCL`, `changeLandmarkDotColor`, `changeDotColorToSlider`, `Wrapper_Get*FromObj`, `tclCmdStep`, `TCL_RESULT_*` macros, `TCL_CMD` macro.

---

### `tcl_dispatch.h` (route)

**Analog:** `def_ZARF_9.h` (lines 261–311 — existing cross-module function declarations)

**Header guard pattern** (from `StatisticsFunction_ZARF_9.h` lines 1–4):
```c
#pragma once
#ifndef TCL_DISPATCH_H
#define TCL_DISPATCH_H

#include "def_ZARF_9.h"

/* Tcl command handlers — registered from tcl_init.c */
int add(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);
int show(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);
int setSpecimen(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);
int setDownSample(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);
int setDot(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);
int del(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);
int loadDgt(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);

/* Draw pass — called from onDisplay and handlers */
void drawDots(void);
void drawAnchors(void);
void drawCurves(void);
void drawGrid(void);
void onDisplay(void);

/* Tcl_Obj wrappers used by handlers */
int Wrapper_GetIntFromObj(Tcl_Interp*, Tcl_Obj*, int*);
int Wrapper_GetDoubleFromObj(Tcl_Interp*, Tcl_Obj*, double*);
const char* Wrapper_GetStringFromObj(Tcl_Obj*, int*);

#endif
```

---

### `tcl_window.c` (service/controller, request-response + WGL I/O)

**Analog:** `tcl_if_ZARF_9.c` `setWindowId`/`setWindow` (lines 582–610, 2997–3148) + `ogl_ZARF9.c` init call pattern

**Imports pattern** (from `ogl_ZARF9.c` lines 1–7):
```c
#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include "def_ZARF_9.h"
#include "RunTime_Defines_ZARF_9.h"
#include "tcl_window.h"
#include "tcl_state.h"
#include "tcl_log.h"
#include "tcl_dispatch.h"   /* onDisplay() at handler exit */
```

**WGL context setup** (lines 582–610) — move verbatim:
```c
int setWindowId(HWND hwnd)
{
	dc = GetDC(hwnd);

	PIXELFORMATDESCRIPTOR pfd;
	memset(&pfd, 0, sizeof(pfd));
	pfd.nVersion = 1;
	pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
	pfd.iPixelType = PFD_TYPE_RGBA;
	pfd.cColorBits = 24;
	pfd.cDepthBits = 16;
	pfd.iLayerType = PFD_MAIN_PLANE;

	GLuint pixelFormat = ChoosePixelFormat(dc, &pfd);
	SetPixelFormat(dc, pixelFormat, &pfd);

	HGLRC rc = wglCreateContext(dc);
	wglMakeCurrent(dc, rc);

	ogl_init();
	return TCL_OK;
}
```

**setWindow handler — id branch** (lines 3021–3062):
```c
const char* attr = Wrapper_GetStringFromObj(objv[1], NULL);
if (strcmp(attr, "id") == 0)
{
	simpleLog((const char*)"function setWindow ... attr id");
	HWND hwnd;
	Wrapper_GetIntFromObj(interp, objv[2], (int*)&hwnd);
	if (models != NULL) { FREE_WRAPPER((void*)models); models = NULL; }
	if (NULL != context) { FREE_WRAPPER((void*)context); context = NULL; }
	model_index = 0;
	model_amount = 0;
	set_dot_slice_amount(0);
	set_anchors_slice_amount(0);
	setWindowId(hwnd);
}
```

**setWindow handler — size branch** (lines 3064–3092):
```c
else if (strcmp(attr, "size") == 0)
{
	Wrapper_GetIntFromObj(interp, objv[2], &width);
	Wrapper_GetIntFromObj(interp, objv[3], &height);
	if (width <= 0)  { width = 600; }
	if (height <= 0) { height = 600; }
	float dx = (float)width / height;
	glViewport(0, 0, width, height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(-0.1 * dx, 0.1 * dx, -0.1, 0.1, -2, 2);
#ifdef CODE_FOR_LIBRARY
	TCL_RESULT2("Window size changed to %d %d", width, height);
#endif
}
```

**Symbols to move here (07-02):** `setWindowId`, `setWindow` handler, `dc`, `width`, `height`, window-dimension defaults in `initialize_state`.

---

### `tcl_window.h` (route)

**Analog:** `def_ZARF_9.h` line 116 (`extern HDC dc`)

```c
#pragma once
#ifndef TCL_WINDOW_H
#define TCL_WINDOW_H

#include "def_ZARF_9.h"

extern HDC dc;
extern int width;
extern int height;

int setWindowId(HWND hwnd);
int setWindow(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);

#endif
```

**Note:** `dc` is already declared in `def_ZARF_9.h:116`. Planner may keep it there and omit duplicate from `tcl_window.h` — follow D-14 minimal extension rule.

---

### `tcl_state.c` (model/store, CRUD + transform)

**Analog:** `tcl_if_ZARF_9.c` globals cluster (lines 31–106, 355–385, 390–580) + `dot_ZARF_9.c` module-local state pattern (lines 7–24)

**Imports pattern** (from `dot_ZARF_9.c` lines 1–6):
```c
#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include "RunTime_Defines_ZARF_9.h"
#include "def_ZARF_9.h"
#include "tcl_state.h"
#include "tcl_log.h"
```

**Global definitions pattern** (lines 31–106, 355–385):
```c
float GBL_LANDMARK_SET[25][3];
const float* pointerTO_GBL_LANDMARK_SET = &GBL_LANDMARK_SET[0][0];
int GBL_LANDMARK_SET_MAX_ROWS = CONST_25;
int GBL_LANDMARK_SET_NUMBER_OF_ROWS = 0;

model_t* GBL_PTR_MODEL_1 = NULL;
/* ... GBL_PTR_MODEL_2..5, GBL_PTR_CONTEXT_1..5, GBL_PTR_CURVE_1..6 ... */

HDC dc;  /* MOVE TO tcl_window.c in 07-02 — do not duplicate */
model_t* models = NULL;
context_t* context = NULL;
float deltas[1000][4];
int model_index = 0;
int model_amount = 0;
show_mode_t showModel = LANDMARK;
char messageBuffer[128];
char buffer[1024];
```

**State init pattern** (lines 390–530):
```c
int clear_deltas()
{
	for (int ii = 0; ii < 1000; ii++)
		for (int jj = 0; jj < 4; jj++)
			deltas[ii][jj] = 0.0;
	return 0;
}

int initialize_state(int selector, int option)
{
	if (1 == selector) { clear_deltas(); return 0; }
	if (2 == selector) { curveReleaseArray(); return 0; }
	/* ... selectors 3–6 ... */
	clear_deltas();
	curveReleaseArray();
	anchorReleaseList();
	dotReleaseList();
	resetModel(models);
	/* ... free models/context, reset counters and GBL_* fields ... */
	return 0;
}
```

**resetContext pattern** (lines 533–580):
```c
int resetContext(int id, float maxXY)
{
	sprintf(buffer, "resetContext for integer id [%d]  {zero based}", id);
	simpleLog(buffer);
	if (id < 0) { return -1; }
	context[id].x = 0.0;
	/* ... scale based on maxXY thresholds ... */
	return 0;
}
```

**Module-local static pattern** (from `dot_ZARF_9.c` lines 11–24) — use for file-private helpers only; do NOT `static`-ify cross-TU globals per D-15:
```c
static dot_t** dots = NULL;
static int dot_slice_id = 0;
static char buffer[128];
```

**Symbols to move here (07-03):** All `GBL_*` globals, `models`, `context`, `deltas`, `model_index`/`model_amount`, `showModel`, `defaultDotColor`/`defaultAnchorColor`, radii, `downSampleOffset*`, `buffer`/`messageBuffer`, `ALLOCATE_WRAPPER`/`FREE_WRAPPER`, `initialize_state`, `resetContext`, `clear_deltas`, `clear_GBL_*`, `resetModel` (if not kept in `ogl_model_ply_ZARF_9.c`).

---

### `tcl_state.h` (model)

**Analog:** `ogl_model_ply_ZARF_9.c` cross-TU `extern` declarations (lines 16–27)

```c
#pragma once
#ifndef TCL_STATE_H
#define TCL_STATE_H

#include "def_ZARF_9.h"

/* Runtime state — single definition in tcl_state.c */
extern model_t* models;
extern context_t* context;
extern int model_index;
extern int model_amount;
extern show_mode_t showModel;
extern float deltas[1000][4];
extern char buffer[1024];
extern char messageBuffer[128];

/* GBL_* arrays consumed by ogl_model_ply_ZARF_9.c — preserve names */
extern int GBL_LANDMARK_SET_NUMBER_OF_ROWS;
extern int GBL_LANDMARK_SET_MAX_ROWS;
extern const float* pointerTO_GBL_LANDMARK_SET;
extern const float* pointerTO_GBL_CURVE_SET;
extern int GBL_CURVE_SET_MAX_ROWS;
extern int GBL_CURVE_SET_NUMBER_OF_ROWS;
extern float GBL_INWORK_CURVE_SCALEFACTOR_MPY;
extern float GBL_INWORK_CURVE_SCALEFACTOR_ADD;
extern float GBL_INWORK_LABEL_SCALEFACTOR_MPY;
extern float GBL_INWORK_LABEL_SCALEFACTOR_ADD;
extern color_t defaultDotColor;
extern color_t defaultAnchorColor;

int initialize_state(int selector, int option);
int resetContext(int id, float maxXY);
int clear_deltas(void);
void* ALLOCATE_WRAPPER(unsigned int howMuch);
void FREE_WRAPPER(void* pointer);

#endif
```

**Existing consumer pattern to preserve** (`ogl_model_ply_ZARF_9.c` lines 16–27):
```c
extern int GBL_LANDMARK_SET_NUMBER_OF_ROWS;
extern int GBL_LANDMARK_SET_MAX_ROWS;
extern const float* pointerTO_GBL_LANDMARK_SET;
extern const float* pointerTO_GBL_CURVE_SET;
extern int GBL_CURVE_SET_MAX_ROWS;
extern int GBL_CURVE_SET_NUMBER_OF_ROWS;
extern color_t defaultDotColor;
extern color_t defaultAnchor;
extern int model_index;
extern int model_amount;
```

**Existing consumer pattern** (`curve_ZARF_9.c` lines 16–17, `ogl_model_ZARF_9.c` lines 11–15):
```c
const extern float GBL_INWORK_CURVE_SCALEFACTOR_MPY;
const extern float GBL_INWORK_CURVE_SCALEFACTOR_ADD;
```

---

### `tcl_log.c` (utility, file-I/O)

**Analog:** `tcl_if_ZARF_9.c` logging block (lines 239–243, 4176–4302, 4596–4624, 5138–5223)

**Module-private FILE handles** (lines 239–243):
```c
static FILE* fp = NULL;
static FILE* cmmdFileP = NULL;
static int xCounts = 0;
static int yCounts = 0;
```

**simpleLog_Open pattern** (lines 4176–4248):
```c
int simpleLog_Open()
{
	char buffer[128];
	if (NULL != fp)
	{
		fprintf(fp, "WARNING : this file being closed by opening a new log file");
		fprintf(fp, "LOG FILE CLOSE\n");
		fflush(fp);
		fclose(fp);
		fp = NULL;
		xCounts = 0;
	}
	/* ... timestamp filename, fopen to ./DATA_LOG_FILES/DL_*.txt ... */
	fprintf(fp, "LOG FILE OPEN\n");
	simpleLogCurveInformation();
	simpleLogDotInformation();
	/* ... version info dumps ... */
	return 0;
}
```

**simpleLog write pattern** (lines 4277–4301):
```c
int simpleLog(const char* yC)
{
	char buffer[128];
	if (NULL == fp) { return -1; }
	else
	{
		time_t rawtime;
		struct tm* timeinfo;
		time(&rawtime);
		timeinfo = localtime(&rawtime);
		strftime(buffer, 80, "%X", timeinfo);
		fprintf(fp, "[%4d] {%s}  <%s>\n", xCounts, buffer, yC);
		fflush(fp);
		xCounts++;
	}
	return 0;
}
```

**TclIf_LogCommands pattern** (lines 4596–4624):
```c
int TclIf_LogCommands(int objc, Tcl_Obj* const objv[])
{
	if (objc <= 0) { return -1; }
	int rv = -1;
	int bad = 0;
	commandStream_WriteStringToFile("...................");
	for (int ii = 0; ii < objc; ii++)
	{
		rv = commandStream_WriteObjectToFile(objv[ii]);
		if (0 != rv) { bad = 1; }
	}
	return bad ? -1 : 0;
}
```

**Symbols to move here (07-03):** `simpleLog_Open`/`Close`/`BlankLine`, `simpleLog`, `simpleLog_Obj`, `simpleLogWrite*`, `simpleLog*Information`, `TclIf_LogCommands`, `commandStream_*`, `GBL_ENABLE_TCL_OBJECT_LOGGING` (if logging-only).

---

### `tcl_log.h` (utility)

**Analog:** `def_ZARF_9.h` lines 261–274 (existing logging API)

```c
#pragma once
#ifndef TCL_LOG_H
#define TCL_LOG_H

#include "def_ZARF_9.h"

int simpleLog(const char* yC);
int simpleLog_Close(void);
int simpleLog_Open(void);
int simpleLogBlankLine(void);
int simpleLog_Obj(Tcl_Obj* const p);
int TclIf_LogCommands(int objc, Tcl_Obj* const objv[]);
int commandStream_OpenFile(void);
int commandStream_CloseFile(void);
int commandStream_WriteStringToFile(const char* s);
int commandStream_WriteObjectToFile(const Tcl_Obj* const p);

#endif
```

**Note:** Keep existing declarations in `def_ZARF_9.h` during Phase 7 to avoid breaking `dot_ZARF_9.c`/`curve_ZARF_9.c` includes — add `tcl_log.h` for new modules only.

---

### `tcl_init.c` (provider, request-response — DLL entry)

**Analog:** `tcl_if_ZARF_9.c` `Tkogl2_Init` (lines 4141–4172)

**Imports pattern:**
```c
#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include "def_ZARF_9.h"
#include "RunTime_Defines_ZARF_9.h"
#include "tcl_dispatch.h"
#include "tcl_window.h"
```

**Init + command registration** (lines 4141–4172) — sole `DLLEXPORT`:
```c
#ifdef CODE_FOR_LIBRARY

int DLLEXPORT Tkogl2_Init(Tcl_Interp* interp)
{
	if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
		return TCL_ERROR;
	}

	if (Tcl_PkgProvide(interp, "Tkogl2", "1.0") == TCL_ERROR) {
		return TCL_ERROR;
	}

	Tcl_CreateObjCommand(interp, "add", add, 0, 0);
	Tcl_CreateObjCommand(interp, "show", show, 0, 0);
	Tcl_CreateObjCommand(interp, "setWindow", setWindow, 0, 0);
	Tcl_CreateObjCommand(interp, "setSpecimen", setSpecimen, 0, 0);
	Tcl_CreateObjCommand(interp, "setDownSample", setDownSample, 0, 0);
	Tcl_CreateObjCommand(interp, "setDot", setDot, 0, 0);
	Tcl_CreateObjCommand(interp, "del", del, 0, 0);
	Tcl_CreateObjCommand(interp, "loadDgt", loadDgt, 0, 0);

	return TCL_OK;
}
#endif
```

**Critical:** Do not register `set` or `directive` — they are forward-declared only (lines 221–230) and never wired.

---

### `CMakeLists.txt` (config, build)

**Analog:** existing `integrated-guimorph-development_EOC/Project/tkogl2/CMakeLists.txt`

**Current source list** (lines 27–38):
```cmake
add_library(tkogl2 SHARED
    ${SRC}/tcl_if_ZARF_9.c
    ${SRC}/ogl_ZARF9.c
    ${SRC}/ogl_model_ZARF_9.c
    ${SRC}/ogl_model_ply_ZARF_9.c
    ${SRC}/curve_ZARF_9.c
    ${SRC}/dot_ZARF_9.c
    ${SRC}/StatisticsFunction_ZARF_9.c
    ${SRC}/tcl_stub_bootstrap.c
)
```

**Incremental 07-01** — add dispatch alongside god file:
```cmake
add_library(tkogl2 SHARED
    ${SRC}/tcl_dispatch.c
    ${SRC}/tcl_if_ZARF_9.c   # remaining code — remove in 07-03
    ${SRC}/ogl_ZARF9.c
    # ... unchanged ...
)
```

**Final 07-03** — replace god file with all new modules:
```cmake
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
    ${SRC}/dot_ZARF_9.c
    ${SRC}/StatisticsFunction_ZARF_9.c
    ${SRC}/tcl_stub_bootstrap.c
)
```

**Preserve:** `USE_TCL_STUBS`, `PREFIX ""`, `OUTPUT_NAME "tkogl2"`, `SUFFIX ".dll"`, `-static-libgcc` (lines 40–89).

---

### `def_ZARF_9.h` (model, shared types)

**Analog:** itself — extend minimally per D-14

**Existing cross-module extern** (line 116):
```c
extern HDC dc;
```

**Existing draw/handler declarations** (lines 306–311) — may remain here during Phase 7 to avoid breaking unchanged modules:
```c
void drawDots();
void drawAnchors();
void drawGrid();
void onDisplay();
void drawCurves();
```

**Planner guidance:** Add new module headers (`tcl_*.h`) for cross-module refs introduced by the split. Only move declarations out of `def_ZARF_9.h` if all consumers are updated — D-12 limits changes to `dot_ZARF_9.c`/`curve_ZARF_9.c`/`ogl_*.c`.

---

### `BUILD.md` (config/docs)

**Analog:** `integrated-guimorph-development_EOC/Project/tkogl2/BUILD.md` (lines 48–60 — "What this build does differently")

**Documentation pattern to append per plan (D-16):**
```markdown
## C source layout (Phase 7)

| File | Responsibility |
|------|----------------|
| `tcl_init.c` | `Tkogl2_Init`, Tcl command registration |
| `tcl_dispatch.c` | Tcl handlers + draw pass + `onDisplay` |
| `tcl_window.c` | `setWindowId`, HWND/WGL, window dimensions |
| `tcl_state.c` | Globals, `initialize_state`, `resetContext` |
| `tcl_log.c` | `simpleLog_*`, command stream logging |
| `dot_ZARF_9.c`, `curve_ZARF_9.c`, `ogl_*.c` | Unchanged logic |
```

Update incrementally: 07-01 documents `tcl_dispatch.c`; 07-02 adds `tcl_window.c`; 07-03 completes table and notes god file removal.

---

### Reference: unchanged modules (`dot_ZARF_9.c`, `curve_ZARF_9.c`, `ogl_*.c`)

**Analog:** themselves — D-12 allows `#include`/header updates only.

**Include order pattern** (`dot_ZARF_9.c` lines 4–6):
```c
#include "RunTime_Defines_ZARF_9.h"
#include "def_ZARF_9.h"
```

**Cross-TU extern consumption** (`curve_ZARF_9.c` lines 16–17):
```c
const extern float GBL_INWORK_CURVE_SCALEFACTOR_MPY;
const extern float GBL_INWORK_CURVE_SCALEFACTOR_ADD;
```

**OGL init module pattern** (`ogl_ZARF9.c` lines 1–7, 12–30):
```c
#include "def_ZARF_9.h"

const char OGL_VERSION_INFORMATION[] = "File ogl Edit revision date is 15 August 2020 4:22 PM";
const char* oglVersionPtr = OGL_VERSION_INFORMATION;

int ogl_init()
{
	glutInitDisplayMode(GLUT_RGBA | GLUT_DEPTH | GLUT_DOUBLE);
	/* ... GL state setup ... */
	return 0;
}
```

No logic changes — verify link still resolves `simpleLog`, `GBL_*`, `model_index` after state extraction.

---

## Shared Patterns

### Dual-build `#ifdef` guards
**Source:** `RunTime_Defines_ZARF_9.h` line 49 (`CODE_FOR_LIBRARY` active), `tcl_if_ZARF_9.c` throughout
**Apply to:** All moved code — preserve `#ifdef STAND_ALONE_TOOL` / `#ifdef CODE_FOR_LIBRARY` blocks verbatim; do not consolidate in Phase 7.

### Cross-module global linkage (one definition, many `extern`)
**Source:** `ogl_model_ply_ZARF_9.c` lines 16–27, `curve_ZARF_9.c` lines 16–17
**Apply to:** `tcl_state.c` (definitions) + `tcl_state.h` or `def_ZARF_9.h` (declarations)
```c
// tcl_state.c — definition
int model_index = 0;

// tcl_state.h — declaration
extern int model_index;

// ogl_model_ply_ZARF_9.c — consumer (unchanged)
extern int model_index;
```

### Tcl memory allocation
**Source:** `tcl_if_ZARF_9.c` lines 167–201
**Apply to:** `tcl_state.c` (move `ALLOCATE_WRAPPER`/`FREE_WRAPPER` definitions); all modules use via `def_ZARF_9.h` or `tcl_state.h`
```c
#ifdef CODE_FOR_LIBRARY
	return (void*)Tcl_Alloc(howMuch);
#endif
```

### Handler logging + redraw lifecycle
**Source:** `tcl_if_ZARF_9.c` handler pattern (e.g. `add` lines 1077–1079, exit lines 2988–2989)
**Apply to:** All Tcl handlers in `tcl_dispatch.c` and `setWindow` in `tcl_window.c`
```c
simpleLogBlankLine();
simpleLog((const char*)"TCL_CMD_ADD");
TclIf_LogCommands(objc, objv);
/* ... handler body ... */
onDisplay();
return TCL_OK;
```

### Version string per translation unit
**Source:** `dot_ZARF_9.c` lines 7–8, `curve_ZARF_9.c` lines 7–11, `ogl_ZARF9.c` lines 5–7
**Apply to:** Each new module — retain version constant + pointer pattern
```c
const char DISPATCH_VERSION_INFORMATION[] = "File tcl_dispatch : edit date is ...";
const char* dispatchVersionPtr = DISPATCH_VERSION_INFORMATION;
```

### Build verification gate
**Source:** `BUILD.md`, Phase 1 export check
**Apply to:** Every plan commit
```bash
cmake --build build -j
objdump -p build/tkogl2.dll | grep Tkogl2_Init
```

### `#pragma warning` suppression
**Source:** all `*_ZARF_9.c` files (line 1–2)
**Apply to:** All new `tcl_*.c` files
```c
#pragma warning( disable : 4305)
#pragma warning( disable : 4244)
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `tcl_dispatch.h` | route | — | No per-module headers exist yet; use `def_ZARF_9.h` + `StatisticsFunction_ZARF_9.h` as structural templates |
| `tcl_log.h` | utility | — | Logging API lives in `def_ZARF_9.h`; new header is greenfield |

## Extraction Order (locked D-09)

| Plan | Add to CMake | Remove from god file | Smoke gate |
|------|-------------|---------------------|------------|
| 07-01 | `tcl_dispatch.c` | Handlers, draw_*, onDisplay, wrappers, macros | build + export + PLY + landmark |
| 07-02 | `tcl_window.c` | setWindowId, setWindow, dc/width/height | same |
| 07-03 | `tcl_state.c`, `tcl_log.c`, `tcl_init.c` | globals, init, logging; remove `tcl_if_ZARF_9.c` from CMake | same + full digitize round-trip |

## Metadata

**Analog search scope:** `integrated-guimorph-development_EOC/Project/tkogl2/src/`, `CMakeLists.txt`, `BUILD.md`, `def_ZARF_9.h`
**Files scanned:** 11 source files + 2 build docs + 2 headers
**Pattern extraction date:** 2026-06-19
