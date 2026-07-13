#pragma once
#ifndef TCL_WINDOW_H
#define TCL_WINDOW_H

#include "def_ZARF_9.h"

extern int width;
extern int height;

int setWindowId(void *native_drawable);
int setWindow(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);

#endif
