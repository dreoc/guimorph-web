#pragma once
#ifndef TCL_DISPATCH_H
#define TCL_DISPATCH_H

#include "def_ZARF_9.h"

extern const int GBL_RTN_SUCCESS;
extern const int GBL_RTN_ERROR;
extern const int GBL_RTN_IGNORE;
extern const int GBL_RTN_UNDER_CONSTRUCTION;

/* Tcl command handlers — registered from Tkogl2_Init */
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
