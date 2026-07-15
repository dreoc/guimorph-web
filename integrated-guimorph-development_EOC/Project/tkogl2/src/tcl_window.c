#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include <string.h>
#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <memory.h>

#include "def_ZARF_9.h"
#include "RunTime_Defines_ZARF_9.h"
#include <tk.h>
#include "gfx_backend.h"
#include "tcl_window.h"
#include "tcl_dispatch.h"
#include "tcl_state.h"
#include "tcl_log.h"

const char WINDOW_VERSION_INFORMATION[] = "File tcl_window : Phase 7 window extraction 2026-06-21";
const char* windowVersionPtr = WINDOW_VERSION_INFORMATION;

gfx_surface *g_surface = NULL;

int width;
int height;

#ifdef CODE_FOR_LIBRARY
#define TCL_CMD(name) int name(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
#endif

#ifdef CODE_FOR_LIBRARY
#define TCL_RESULT2(info, arg1, arg2) \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, info, arg1, arg2); \
	Tcl_SetResult(interp, msg, TCL_DYNAMIC);
#endif

int setWindowId(void *native_drawable)
{
	g_surface = gfx_create(native_drawable);
	gfx_make_current(g_surface);
	ogl_init();  // this function returns an integer - but I have yet to investigate what to do on  failure
	return TCL_OK;
}

#ifdef STAND_ALONE_TOOL
int setWindow(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[])
# else
TCL_CMD(setWindow)
#endif
{

	// comment on code changes 03 July 2020
	// This function ic called from R at GUI start up and when ever the opertor
	// switches tabs. This provides us the information of the opertions that the 
	// R gui code can perform.
	// The only return value is TCL_OK since we have no control over the fact that the operator
	// has switched tabs in the GUI,
	// When this function is called with a window resize argument, we return a messge to R. 
	// We only do this since the R code could be execution of a predefined sequence (that is code
	// execution which coulderesult in bad parameters) and not a gui manual resize operation.



	int UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
	simpleLogBlankLine();
	simpleLog((const char*)"TCL_CMD_SET_WINDOW");
	TclIf_LogCommands(objc, objv);

	const char* attr = Wrapper_GetStringFromObj(objv[1], NULL);
	if (strcmp(attr, "id") == 0) // initializes context for drawing space
	{
		simpleLog((const char*)"function setWindow ... attr id");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);

		// RND-02 (Phase 2): the R bridge now passes the Tk widget PATHNAME
		// (e.g. ".1.canvasframe"), not `winfo id`. Resolve the pathname to a
		// Tk_Window, realize its native window, read the platform-neutral Tk
		// window id, then branch to the per-platform drawable accessor. The
		// resulting native drawable (HWND on Windows, NSWindow* on macOS)
		// crosses the gfx seam unchanged. This removes the 32-bit int->pointer
		// cast, which truncated the 64-bit macOS Drawable/NSView pointer and was
		// fragile on Win64 (previously blamed for blank viewports).
		const char *framePath = Wrapper_GetStringFromObj(objv[2], NULL);
		Tk_Window tkwin = Tk_NameToWindow(interp, framePath, Tk_MainWindow(interp));
		if (tkwin == NULL)
		{
			sprintf(buffer, "ERROR : setWindow id ... Tk_NameToWindow returned NULL for pathname <%s>", framePath ? framePath : "(null)");
			simpleLog(buffer);
			// Preserve the historical "always TCL_OK" contract for GUI/tab ops.
			return TCL_OK;
		}
		// Force native window creation so Tk_WindowId returns a valid drawable
		// (the id is None until the widget is realized; the old winfo-id path
		// realized it as a side effect on the R side).
		Tk_MakeWindowExist(tkwin);

		void *native_drawable = NULL;
#if defined(_WIN32)
		native_drawable = (void *)Tk_GetHWND(Tk_WindowId(tkwin));
#elif defined(MAC_OSX_TK) || defined(__APPLE__)
		// Requires Tk >= 8.7/9.0 headers (Homebrew tcl-tk on macOS provides the
		// public Tk_ prefix). The Phase 4 NSGL backend derives the NSView from
		// this NSWindow.
		native_drawable = (void *)Tk_MacOSXGetNSWindowForDrawable(Tk_WindowId(tkwin));
#else
		// X11 fallback for a future Linux backend: hand the raw Window id across.
		native_drawable = (void *)(intptr_t)Tk_WindowId(tkwin);
#endif
		if (native_drawable == NULL)
		{
			simpleLog("ERROR : setWindow id ... platform drawable accessor returned NULL");
		}
		if (models != NULL)
		{
			FREE_WRAPPER((void*)models);
			models = NULL;
			simpleLog("INFO : models was not NULL. Freeing memory");
		}
		if (NULL != context)
		{
			FREE_WRAPPER((void*)context);
			context = NULL;
			simpleLog("INFO : context was not NULL. Freeing memory");
		}

		// initialize model Id, amount and dot ID
		model_index = 0;
		model_amount = 0;
		int temp = -1;
		temp = set_dot_slice_amount(0);
		if (0 != temp)
		{
			simpleLog("ERROR : dot slice amount not successful - argument was zero");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}

		temp = set_anchors_slice_amount(0);
		if (0 != temp)
		{
			simpleLog("ERROR : set_anchor_slice_amount not successful - argument was zero");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}

		setWindowId(native_drawable);
		simpleLog((const char*)"function setWindow id ... end");
	}
	else if (strcmp(attr, "size") == 0) // constructs drawing space for specimen
	{
		simpleLog((const char*)"function setWindow ... attr size");
		simpleLog((const char*)"objects 2 and 3");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		Wrapper_GetIntFromObj(interp, objv[2], &width);
		Wrapper_GetIntFromObj(interp, objv[3], &height);
		if (width <= 0)
		{
			width = 600;
			simpleLog("WARNING : window width was zero or negative ... setting it to 600");
		}
		if (height <= 0)
		{
			height = 600;
			simpleLog("WARNING : window height was zero or negative ... setting it to 600");
		}
		float dx = (float)width / height;
		glViewport(0, 0, width, height);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-0.1 * dx, 0.1 * dx, -0.1, 0.1, -2, 2);
		simpleLog((const char*)"function setWindow size ... end");

		// why do we bother returning this string at all ? The window size is observable
#ifdef CODE_FOR_LIBRARY
		TCL_RESULT2("Window size changed to %d %d", width, height);
#endif

	}
	else if (strcmp(attr, "mode") == 0) // changes what should be displayed on screen
	{
		simpleLog((const char*)"function setWindow ... attr mode");
		const char* mode = Wrapper_GetStringFromObj(objv[2], NULL);
		sprintf(buffer, "set Window mode ... secondary argument is <%s>", mode);
		simpleLog(buffer);
		if (strcmp(mode, "digitize") == 0)
		{
			simpleLog("TAB CHANGE / DIGITIZE");
			showModel = LANDMARK;
		}
		else if (strcmp(mode, "anchor") == 0)
		{
			simpleLog("TAB CHANGE / ANCHOR");
			showModel = ANCHOR;
		}
		else if (strcmp(mode, "surface") == 0)
		{
			simpleLog("TAB CHANGE / SURFACE");
			showModel = DOWN_SAMPLE;
		}
		else if (strcmp(mode, "geomorph") == 0)
		{
			showModel = DOWN_SAMPLE;
		}
		else if (strcmp(mode, "surfaceonly") == 0)
		{
			simpleLog("TAB CHANGE / DOWNSAMPLE ONLY");
			showModel = DOWN_SAMPLE_ONLY;
		}
		else if (strcmp(mode, "curve") == 0)
		{
			simpleLog("TAB CHANGE / CURVE");
			showModel = CURVE;
		}
		else if (strcmp(mode, "none") == 0)
		{
			showModel = NONE;
		}
		else
		{
			sprintf(buffer, "ERROR : set window mode ... unknown parameter for 'mode' <%s>", mode);
			simpleLog(buffer);
			UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;
		}
		simpleLog((const char*)"function setWindow mode  ... end");
	}

	simpleLog((const char*)"END TCL_CMD_SET_WINDOW");
	simpleLogBlankLine();

	onDisplay();
	return TCL_OK;
}
