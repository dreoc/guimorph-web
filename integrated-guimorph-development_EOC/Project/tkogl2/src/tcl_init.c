#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include "def_ZARF_9.h"
#include "RunTime_Defines_ZARF_9.h"
#include "tcl_dispatch.h"
#include "tcl_window.h"
#include <tk.h>

#ifdef CODE_FOR_LIBRARY 

/*
* Tkogl2_Init -- Called when Tcl loads your extension.
*/
int DLLEXPORT Tkogl2_Init(Tcl_Interp* interp)
{
	if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
		return TCL_ERROR;
	}

	/* RND-02 (Phase 2): bind Tk's stub tables so Tk_NameToWindow / Tk_WindowId
	 * and the platform drawable accessors (Tk_GetHWND on Windows,
	 * Tk_MacOSXGetNSWindowForDrawable on macOS) are callable. These are stub
	 * macros that dereference tkStubsPtr / tkPlatStubsPtr; without Tk_InitStubs
	 * those pointers are NULL and the calls crash. */
	if (Tk_InitStubs(interp, TK_VERSION, 0) == NULL) {
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
