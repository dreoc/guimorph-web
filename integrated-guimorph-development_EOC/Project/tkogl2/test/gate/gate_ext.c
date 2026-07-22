#include <tcl.h>
#include <tk.h>

static int GateWinsysCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *const objv[]
) {
    (void)clientData;
    (void)objc;
    (void)objv;
    return Tcl_Eval(interp, "tk windowingsystem");
}

int DLLEXPORT Gateext_Init(Tcl_Interp *interp) {
    if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
        return TCL_ERROR;
    }

    if (Tk_InitStubs(interp, TK_VERSION, 0) == NULL) {
        return TCL_ERROR;
    }

    if (Tcl_PkgProvide(interp, "Gateext", "1.0") == TCL_ERROR) {
        return TCL_ERROR;
    }

    Tcl_CreateObjCommand(interp, "gate_winsys", GateWinsysCmd, 0, 0);
    return TCL_OK;
}
