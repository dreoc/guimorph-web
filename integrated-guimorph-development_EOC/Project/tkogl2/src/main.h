#pragma once

// This file (main.h) and this function declaration seem to be needed by R / TCL / TK in order to 
// correctly initiiate the GUI
// it is included in the   def.h file 



int setWindow(ClientData clientData, Tcl_Interp * interp, int objc, Tcl_Obj * const objv[]);
