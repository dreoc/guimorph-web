#pragma once
#ifndef TCL_WINDOW_H
#define TCL_WINDOW_H

#include "def_ZARF_9.h"

extern int width;
extern int height;

int setWindowId(HWND hwnd);
int setWindow(ClientData, Tcl_Interp*, int, Tcl_Obj* const[]);

#endif
