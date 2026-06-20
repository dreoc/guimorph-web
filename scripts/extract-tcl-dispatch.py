#!/usr/bin/env python3
"""Extract tcl_dispatch.c from tcl_if_ZARF_9.c per 07-01 plan (line ranges 1-indexed)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOD = ROOT / "integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_if_ZARF_9.c"
DISPATCH_C = ROOT / "integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c"
DISPATCH_H = ROOT / "integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.h"

# Inclusive 1-indexed line ranges to move to tcl_dispatch.c
MOVE_RANGES = [
    (114, 154),    # Wrapper_Get* helpers
    (206, 209),    # Wrapper_ListObjGetElements
    (215, 337),    # TCL_CMD, TCL_RESULT macros
    (339, 352),    # tclCmdStep
    (612, 898),    # absd, getRealZ, draw*
    (902, 1062),   # getSpecimenCoordinate, specimen_del, validateDot, helpers
    (1064, 1064),  # ANGLE_REDUCE (duplicate macro — dispatch TU)
    (1067, 2990),  # add, show handlers
    (3153, 4138),  # setSpecimen..loadDgt (excludes setWindow)
    (5063, 5133),  # onDisplay
    (5275, 5580),  # addDot_NO_TCL, addAnchor_NO_TCL, change*Color*
]


def merge_ranges(ranges):
    sorted_r = sorted(ranges)
    merged = [list(sorted_r[0])]
    for start, end in sorted_r[1:]:
        if start <= merged[-1][1] + 1:
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    return merged


def extract_lines(lines, ranges):
    chunks = []
    for start, end in ranges:
        chunks.append("".join(lines[start - 1 : end]))
    return chunks


def build_god_file(lines, merged):
    out = []
    i = 0
    n = len(lines)
    range_idx = 0
    while i < n:
        line_no = i + 1
        if range_idx < len(merged) and line_no == merged[range_idx][0]:
            # Skip moved region; inject include once before first removal after headers
            if range_idx == 0:
                pass  # include added separately
            i = merged[range_idx][1]
            range_idx += 1
            continue
        out.append(lines[i])
        i += 1
    return out


DISPATCH_HEADER = '''#pragma once
#ifndef TCL_DISPATCH_H
#define TCL_DISPATCH_H

#include "def_ZARF_9.h"

/* Tcl command handlers — registered from Tkogl2_Init (god file until 07-03) */
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

/* Non-Tcl entry points used by .dgt load path */
int addDot_NO_TCL(double* xp, double* yp, double* zp);
int addAnchor_NO_TCL(double* xp, double* yp, double* zp);
void changeLandmarkDotColor(void);
void changeDotColorToSlider(int dotIndex);

#endif
'''

DISPATCH_PREAMBLE = '''#pragma warning( disable : 4305)
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

const char DISPATCH_VERSION_INFORMATION[] = "File tcl_dispatch : Phase 7 dispatch extraction 2026-06-19";
const char* dispatchVersionPtr = DISPATCH_VERSION_INFORMATION;

extern const char COMPILE_INFORMATION[];

/* Globals defined in tcl_if_ZARF_9.c until 07-03 state extraction */
extern HDC dc;
extern model_t* models;
extern context_t* context;
extern float deltas[1000][4];
extern int model_index;
extern int model_amount;
extern show_mode_t showModel;
extern int width;
extern int height;
extern int labeled;
extern int alabeled;
extern int anchorPlaced;
extern int downsampled;
extern color_t defaultDotColor;
extern color_t defaultAnchorColor;
extern GLdouble dotRadius;
extern GLdouble anchorRadius;
extern point_t downSampleOffsetBeg;
extern point_t downSampleOffset;
extern char messageBuffer[128];
extern char buffer[1024];
extern int UT_MY_INTEGER_VALUE;

extern const int GBL_RTN_SUCCESS;
extern const int GBL_RTN_ERROR;
extern const int GBL_RTN_IGNORE;
extern const int GBL_RTN_UNDER_CONSTRUCTION;

extern void* ALLOCATE_WRAPPER(unsigned int howMuch);
extern void FREE_WRAPPER(void* pointer);

'''


def patch_god(content_lines):
    """Insert include and remove moved forward decls."""
    out = []
    inserted_include = False
    skip_forward = {
        "int addDot_NO_TCL(double* xp, double* yp, double* zp);",
        "int addAnchor_NO_TCL(double* xp, double* yp, double* zp);",
        "void changeLandmarkDotColor();",
        "void changeDotColorToSlider(int dotIndex);",
    }
    for i, line in enumerate(content_lines):
        stripped = line.strip()
        if stripped in skip_forward:
            continue
        if (
            not inserted_include
            and line.strip() == '#include "RunTime_Defines_ZARF_9.h"'
        ):
            out.append(line)
            out.append('#include "tcl_dispatch.h"\n')
            inserted_include = True
            continue
        out.append(line)

    # Remove static from UT_MY_INTEGER_VALUE for cross-TU access
    text = "".join(out)
    text = text.replace(
        "static int UT_MY_INTEGER_VALUE = 0;",
        "int UT_MY_INTEGER_VALUE = 0;",
    )
    return text


def main():
    lines = GOD.read_text(encoding="utf-8", errors="replace").splitlines(keepends=True)
    merged = merge_ranges(MOVE_RANGES)

    dispatch_body = extract_lines(lines, MOVE_RANGES)
    dispatch_c = DISPATCH_PREAMBLE + "".join(dispatch_body)

    god_lines = build_god_file(lines, merged)
    god_text = patch_god(god_lines)

    DISPATCH_H.write_text(DISPATCH_HEADER, encoding="utf-8")
    DISPATCH_C.write_text(dispatch_c, encoding="utf-8")
    GOD.write_text(god_text, encoding="utf-8")

    print(f"Wrote {DISPATCH_H} ({DISPATCH_H.stat().st_size} bytes)")
    print(f"Wrote {DISPATCH_C} ({DISPATCH_C.stat().st_size} bytes, {dispatch_c.count(chr(10))} lines)")
    print(f"Trimmed {GOD} ({GOD.stat().st_size} bytes, {god_text.count(chr(10))} lines)")


if __name__ == "__main__":
    main()
