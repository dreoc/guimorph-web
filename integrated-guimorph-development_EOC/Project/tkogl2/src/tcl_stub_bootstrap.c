/*
 * tcl_stub_bootstrap.c --
 *
 *   Self-contained Tcl 8.6 stub bootstrap for the tkogl2 extension.
 *
 *   A stubs-enabled extension must provide Tcl_InitStubs() plus the global
 *   stub-table pointers that the USE_TCL_STUBS macros in <tclDecls.h>
 *   dereference for every Tcl_* call. Normally these come from Tcl's
 *   prebuilt stub library (tclstub86.lib). That vendored library is an MSVC
 *   COFF archive that GNU ld cannot read, and the vendored Tcl source can't
 *   be compiled here because its Windows platform headers (tclWinPort.h, ...)
 *   were not included in the snapshot.
 *
 *   Tcl_InitStubs needs exactly one thing from Tcl's internals: the address of
 *   the stub table, stored in Interp::stubTable. In Tcl 8.6 the internal
 *   Interp struct begins with the same three fields as the public Tcl_Interp
 *   (result, freeProc, errorLine) immediately followed by stubTable (verified
 *   against tclInt.h in this tree). We therefore mirror just that prefix and
 *   read the stub table without needing tclInt.h at all.
 *
 *   This is a faithful reimplementation of generic/tclStubLib.c limited to the
 *   public stub table (the extension uses no Tcl *internal* API, so the
 *   internal/platform-internal stub pointers are intentionally omitted).
 */

#include "tcl.h"

/*
 * ABI-stable prefix of the internal Interp struct (Tcl 8.6). The comment in
 * tclInt.h states the first three fields must match Tcl_Interp exactly;
 * stubTable is the next field.
 */
typedef struct InterpStubPrefix {
    char *result;
    Tcl_FreeProc *freeProc;
    int errorLine;
    const struct TclStubs *stubTable;
} InterpStubPrefix;

/* Globals referenced by the USE_TCL_STUBS macros in the public headers. */
const TclStubs *tclStubsPtr = NULL;
const TclPlatStubs *tclPlatStubsPtr = NULL;

static int stubIsDigit(const int c)
{
    return (c >= '0' && c <= '9');
}

/*
 * Tcl_InitStubs is the one entry point not routed through the stub table; it
 * bootstraps the table. (#undef in case a non-stubs build turned it into a
 * macro mapping to Tcl_PkgInitStubsCheck.)
 */
#undef Tcl_InitStubs
const char *
Tcl_InitStubs(
    Tcl_Interp *interp,
    const char *version,
    int exact)
{
    const char *actualVersion = NULL;
    ClientData pkgData = NULL;
    const TclStubs *stubsPtr = ((InterpStubPrefix *) interp)->stubTable;

    if (!stubsPtr || (stubsPtr->magic != TCL_STUB_MAGIC)) {
        return NULL;
    }

    actualVersion = stubsPtr->tcl_PkgRequireEx(interp, "Tcl", version, 0, &pkgData);
    if (actualVersion == NULL) {
        return NULL;
    }

    if (exact) {
        const char *p = version;
        int count = 0;

        while (*p) {
            count += !stubIsDigit(*p++);
        }
        if (count == 1) {
            const char *q = actualVersion;

            p = version;
            while (*p && (*p == *q)) {
                p++; q++;
            }
            if (*p || stubIsDigit(*q)) {
                stubsPtr->tcl_PkgRequireEx(interp, "Tcl", version, 1, NULL);
                return NULL;
            }
        } else {
            actualVersion = stubsPtr->tcl_PkgRequireEx(interp, "Tcl", version, 1, NULL);
            if (actualVersion == NULL) {
                return NULL;
            }
        }
    }

    tclStubsPtr = (const TclStubs *) pkgData;

    if (tclStubsPtr->hooks) {
        tclPlatStubsPtr = tclStubsPtr->hooks->tclPlatStubs;
    } else {
        tclPlatStubsPtr = NULL;
    }

    return actualVersion;
}
