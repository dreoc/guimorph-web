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

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
// Developers : it is your responsibility to update this string each time you compile the library
// for purposes of building an R package for the GUI Morph Tool
const char COMPILE_INFORMATION[] = "Library compile information : date is 15 AUGUST 2020 04:22 PM";
//
// The  following line should be updated based on edits to this file - not for simple recompilation 
// of the library
const char TCL_IF_VERSION_INFORMATION[] = "File tcl_if : edit date is 15 AUGUST 2020 04:22 PM";
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////


#define ANGLE_REDUCE(angle) while (angle > 360.0) angle -= 360.0; while (angle < -360.0) angle += 360.0

float GBL_LANDMARK_SET[25][3];
#define CONST_25  25
const float* pointerTO_GBL_LANDMARK_SET = &GBL_LANDMARK_SET[0][0];
int GBL_LANDMARK_SET_MAX_ROWS = CONST_25;
int GBL_LANDMARK_SET_NUMBER_OF_ROWS = 0;
void clear_GBL_LANDMARK_SET();
void show_GBL_LANDMARK_SET();

int unit_test_ogl_loadLandmark(const char* filename);
int unit_test_ogl_loadCurve(const char* filename);

extern const char* statisticsVersionPtr;
extern const char* oglModelVersionPtr;
extern const char* oglModelPlyVersionPtr;
extern const char* dotVersionPtr;
extern const char* curveVersionPtr;
extern const char* oglVersionPtr;

extern const char* UTILVersionPtr;

const char* tcl_ifVersionPtr = TCL_IF_VERSION_INFORMATION;
float GBL_CURVE_SET[25][3];
#define CONST_10  10
const float* pointerTO_GBL_CURVE_SET = &GBL_CURVE_SET[0][0];
int GBL_CURVE_SET_MAX_ROWS = CONST_10;
int GBL_CURVE_SET_NUMBER_OF_ROWS = 0;
void clear_GBL_CURVE_SET();
void show_GBL_CURVE_SET();

model_t* GBL_PTR_TO_A_MODEL;

model_t* GBL_PTR_MODEL_1 = NULL;
model_t* GBL_PTR_MODEL_2 = NULL;
model_t* GBL_PTR_MODEL_3 = NULL;
model_t* GBL_PTR_MODEL_4 = NULL;
model_t* GBL_PTR_MODEL_5 = NULL;

context_t* GBL_PTR_CONTEXT_1 = NULL;
context_t* GBL_PTR_CONTEXT_2 = NULL;
context_t* GBL_PTR_CONTEXT_3 = NULL;
context_t* GBL_PTR_CONTEXT_4 = NULL;
context_t* GBL_PTR_CONTEXT_5 = NULL;

int GBL_LANDMARKS_ROWS = -1;
int GBL_LANDMARKS_COLS = -1;
int GBL_ANCHOR_ROWS = -1;
int GBL_ANCHOR_COLS = -1;

int GBL_LANDMARKS_NUM_SPECIMENS = -1;
int GBL_CURVES_NUMBER_OF_CURVES = -1;
int GBL_CURVES_LENGTH = -1;
int GBL_CURVES_NUM_SPECIMENS = -1;

int GBL_SET_NUMBER_OF_LANDMARKS = -1;    // set from R gui hen operator changes the number of landmarks 
int GBL_SET_NUMBER_OF_ANCHORS = -1;      // set from R gui hen operator changes the number of anchors 

float GBL_INWORK_LABEL_SCALEFACTOR_MPY = 1.0;   // investigate issue with label placement
float GBL_INWORK_LABEL_SCALEFACTOR_ADD = 0.0;

float GBL_INWORK_CURVE_SCALEFACTOR_MPY = 1.0;   // added to investigate curve visibility
float GBL_INWORK_CURVE_SCALEFACTOR_ADD = 0.0;   // these are the NO EFFECT values

float GBL_ROTATION_ANGLE_X = 0;    // units degrees from R
float GBL_ROTATION_ANGLE_Y = 0;    // units degrees from R

int GBL_ENABLE_TCL_OBJECT_LOGGING = 0;   // turn off when 0 ; turn on when 1


curve_t* GBL_PTR_CURVE_1 = NULL;
curve_t* GBL_PTR_CURVE_2 = NULL;
curve_t* GBL_PTR_CURVE_3 = NULL;
curve_t* GBL_PTR_CURVE_4 = NULL;
curve_t* GBL_PTR_CURVE_5 = NULL;
curve_t* GBL_PTR_CURVE_6 = NULL;

extern int WindowHandle;


void simpleLogWriteAnchorsToFile();
void simpleLogWriteLandmarksToFile();


void* ALLOCATE_WRAPPER(unsigned int howMuch);

void FREE_WRAPPER(void* pointer);


// memory allocation wrapper functions 
// address recording is provided (comment / uncomment print statements) as desired
// the long term goal is to implement a memory allocation manager to track memory allocations
// and detect leaks. This is prototyped in an external tool.  June 2020


void* ALLOCATE_WRAPPER(unsigned int howMuch)
{
#ifdef STAND_ALONE_TOOL

	uintptr_t theAddress = 0;
	void* vPointer = NULL;
	unsigned int theSize = howMuch;
	vPointer = (int*)malloc(howMuch);
	theAddress = (uintptr_t)vPointer;
	printf("ALLOCATE WRAPPER : address [%u]  the size [%u]\n", (unsigned int)theAddress, (unsigned int)theSize);
	return vPointer;
#endif
#ifdef CODE_FOR_LIBRARY
	return (void*)Tcl_Alloc(howMuch);
#endif 
}

void FREE_WRAPPER(void* pointer)
{
#ifdef STAND_ALONE_TOOL
	if (NULL == pointer)
	{
	}
	else
	{
		uintptr_t theAddress;
		theAddress = (uintptr_t)pointer;
		printf("FREEE WRAPPER : address    [%u]\n", (unsigned int)theAddress);
		free(pointer);
	}
#endif
#ifdef CODE_FOR_LIBRARY 
	Tcl_Free(pointer);
#endif 
	return;
}

// still inwork - the stand alone tool has yet to use this 28 May 2020
// The library code as of 05 July 2020 does not use the wrapper 

int setWindowId(HWND hwnd);

#define MAX_STEP_NAME 128

#ifdef CODE_FOR_LIBRARY
#define TCL_CMD(name) int name(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
#endif

extern const int GBL_RTN_SUCCESS;
extern const int GBL_RTN_ERROR;
extern const int GBL_RTN_IGNORE;
extern const int GBL_RTN_UNDER_CONSTRUCTION;

#ifdef CODE_FOR_LIBRARY
#define TCL_RESULT2(info, arg1, arg2) \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, info, arg1, arg2); \
	Tcl_SetResult(interp, msg, TCL_DYNAMIC);
#endif

/* Logging file handles — stay in god file until 07-03 tcl_log.c extraction */
static FILE* fp = NULL;
static FILE* cmmdFileP = NULL;
static int xCounts = 0;
static int yCounts = 0;

HDC dc; /*device context for windows, allows us to communicate to display for drawing*/

model_t* models = NULL;
context_t* context = NULL;

float deltas[1000][4];

int model_index = 0;
int model_amount = 0;
int temp_index = 0;
show_mode_t showModel = LANDMARK;

int width;  // graphics window in R width
int height; // graphics window in R height ... see function setWindow below

int labeled = 1;
int alabeled = 1;
int anchorPlaced = 0;
int downsampled = 0;

color_t defaultDotColor = { 1.0, 0.0, 0.0 };   // red
color_t defaultAnchorColor = { 0.0, 1.0, 0.0 };  // green 
GLdouble dotRadius = 0.01f;
GLdouble anchorRadius = 0.01f;
point_t downSampleOffsetBeg = { 0.0 };
point_t downSampleOffset = { 0.0 };
int UT_MY_INTEGER_VALUE = 0;  //unit testing in THIS version ONLY 

char messageBuffer[128];
char buffer[1024];


//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////

int clear_deltas()
{
	// 17 July 2020 How do we know that there are only need for 1000 deltas ?
	for (int ii = 0; ii < 1000; ii++)
	{
		for (int jj = 0; jj < 4; jj++)
		{
			deltas[ii][jj] = 0.0;
		}
	}
	return 0;
}


int initialize_state(int selector, int option)
{


	if (1 == selector)
	{
		clear_deltas();   // probably NOT ok to use this operationally !!!
		return 0;
	}
	if (2 == selector)
	{
		simpleLog("DEBUG : initialize function argument 2 : initialize curves");
		curveReleaseArray();
		return 0;
	}
	if (3 == selector)
	{
		anchorReleaseList();
		anchorPlaced = 0;
		return 0;
	}
	if (4 == selector)
	{
		dotReleaseList();
		return 0;
	}
	if (5 == selector)
	{
		resetModel(models);
		downsampled = 0;
		return 0;
	}

	if (6 == selector)
	{
		// 12 July 2020 inwork : release down sample data only
		simpleLog("DEBUG : initialize with argument 6 under construction");
		return -1;
	}


	if (0 != selector)
	{
		sprintf(buffer, "DEBUG : initialize state ... unknown selection [%d]", selector);
		return -1;
	}

	// else everything re-intiailized
	clear_deltas();
	curveReleaseArray();
	anchorReleaseList();
	dotReleaseList();
	resetModel(models);

	// some of the following code may be redundant ... 
	if (NULL != models)
	{
		FREE_WRAPPER((void*)models);
		models = NULL;

	}
	else
	{
		models = NULL;
	}

	if (NULL != context)
	{
		FREE_WRAPPER((void*)context);
		context = NULL;
	}

	/*
		GBL_PTR_MODEL_1 = NULL;
		GBL_PTR_MODEL_2 = NULL;
		GBL_PTR_MODEL_3 = NULL;
		GBL_PTR_MODEL_4 = NULL;
		GBL_PTR_MODEL_5 = NULL;

		GBL_PTR_CONTEXT_1 = NULL;
		GBL_PTR_CONTEXT_2 = NULL;
		GBL_PTR_CONTEXT_3 = NULL;
		GBL_PTR_CONTEXT_4 = NULL;
		GBL_PTR_CONTEXT_5 = NULL;

		GBL_PTR_CURVE_1 = NULL;
		GBL_PTR_CURVE_2 = NULL;
		GBL_PTR_CURVE_3 = NULL;
		GBL_PTR_CURVE_4 = NULL;
		GBL_PTR_CURVE_5 = NULL;
		GBL_PTR_CURVE_6 = NULL;
	*/

	model_index = 0;
	model_amount = 0;
	temp_index = 0;
	showModel = LANDMARK;
	width = 600;  // graphics window in R width
	height = 600; // graphics window in R height 
	labeled = 1;
	alabeled = 1;
	anchorPlaced = 0;
	downsampled = 0;
	UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
	messageBuffer[0] = '\0';
	buffer[0] = '\0';

	GBL_LANDMARKS_ROWS = -1;
	GBL_LANDMARKS_COLS = -1;
	GBL_ANCHOR_ROWS = -1;
	GBL_ANCHOR_COLS = -1;
	GBL_LANDMARKS_NUM_SPECIMENS = -1;

	GBL_CURVES_NUMBER_OF_CURVES = -1;
	GBL_CURVES_LENGTH = -1;
	GBL_CURVES_NUM_SPECIMENS = -1;

	GBL_INWORK_LABEL_SCALEFACTOR_MPY = 1.0;
	GBL_INWORK_LABEL_SCALEFACTOR_ADD = 0.0;
	GBL_INWORK_CURVE_SCALEFACTOR_MPY = 1.0;
	GBL_INWORK_CURVE_SCALEFACTOR_ADD = 0.0;

	GBL_ROTATION_ANGLE_X = 0;
	GBL_ROTATION_ANGLE_Y = 0;

	return 0;
}

//called when adding or switching between specimens, resets specimen to be in neutral position
int resetContext(int id, float maxXY)
{

	sprintf(buffer, "resetContext for integer id [%d]  {zero based}", id);
	simpleLog(buffer);
	if (id < 0)
	{
		simpleLog("ERROR : resetContext passed negative id argument");
		return -1;
	}
	context[id].x = 0.0;
	context[id].y = 0.0;
	context[id].z = 0.0;
	context[id].scale = 1.0;
	context[id].rotation[0] = 0.0;
	context[id].rotation[1] = 0.0;
	context[id].rotation[2] = 0.0;

	if (maxXY > 0.8)
	{
		context[id].scale = 1.0;
	}
	else if (maxXY > 0.6)
	{
		context[id].scale = 2.0;
	}
	else if (maxXY > 0.4)
	{
		context[id].scale = 3.0;
	}
	else if (maxXY > 0.2) // duplicate clause 23 May 2020  fixed
	{
		context[id].scale = 4.0;
	}
	else if (maxXY > 0.1)
	{
		context[id].scale = 5.0;
	}
	else if (maxXY > 0.08)
	{
		context[id].scale = 6.0;
	}
	else if (maxXY > 0.04)
	{
		context[id].scale = 12.0;
	}
	return 0;
}

int setWindowId(HWND hwnd)
{
	//////#ifdef _WIN32
		/* Grab the HWND from Tcl. */

		/* Setup OpenGL. */
	dc = GetDC(hwnd);


	/* Windows code, setup OpenGL. */
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

	ogl_init();  // this function returns an integer - but I have yet to investigate what to do on  failure
	return TCL_OK;
}



//used to switch between ogl coordinates and normal coords when loading models using "raw" coords









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

		HWND hwnd;
		Wrapper_GetIntFromObj(interp, objv[2], (int*)&hwnd);
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

		setWindowId(hwnd);
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






#ifdef CODE_FOR_LIBRARY 

/*
* Tkogl2_Init -- Called when Tcl loads your extension.
*/
int DLLEXPORT Tkogl2_Init(Tcl_Interp* interp)
{
	if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
		return TCL_ERROR;
	}

	if (Tcl_PkgProvide(interp, "Tkogl2", "1.0") == TCL_ERROR) {
		return TCL_ERROR;
	}

	/*implement these new commands so that C understands*/
	/*Tcl_CreateObjCommand defines a new command in interp and associates it with procedure proc such that whenever name is invoked as a Tcl command
	(via Tcl_Eval), the Tcl interpreter will call proc to process the command.*/
	Tcl_CreateObjCommand(interp, "add", add, 0, 0);
	Tcl_CreateObjCommand(interp, "show", show, 0, 0);
	Tcl_CreateObjCommand(interp, "setWindow", setWindow, 0, 0);
	Tcl_CreateObjCommand(interp, "setSpecimen", setSpecimen, 0, 0);
	Tcl_CreateObjCommand(interp, "setDownSample", setDownSample, 0, 0);
	Tcl_CreateObjCommand(interp, "setDot", setDot, 0, 0);
	Tcl_CreateObjCommand(interp, "del", del, 0, 0);

	// high level interface to simple the R code
	Tcl_CreateObjCommand(interp, "loadDgt", loadDgt, 0, 0);

	return TCL_OK;

}
#endif


int simpleLog_Open()
{
	char buffer[128];
	if (NULL != fp)
	{
		fprintf(fp, "WARNING : this file being closed by opening a new log file");
		fprintf(fp, "LOG FILE CLOSE\n");
		fflush(fp);
		fflush(fp);
		fclose(fp);
		fp = NULL;
		xCounts = 0;
	}

	fp = NULL;
	xCounts = 0;
	if (NULL == fp)   // decided to have not implicit file open
	{

		time_t rawtime;
		struct tm* timeinfo;
		char finalFileName[128];
		time(&rawtime);
		timeinfo = localtime(&rawtime);
		int ll;

		strftime(buffer, 80, "%c", timeinfo);
		//printf("%s\n", buffer);
		ll = (int)strlen(buffer);
		for (int ii = 0; ii < ll; ii++)
		{
			if (buffer[ii] == ':') {
				buffer[ii] = '_';
			}
			if (buffer[ii] == ' ') {
				buffer[ii] = '_';
			}
		}

		//printf("new buffer is <%s>\n", buffer);


#ifdef STAND_ALONE_TOOL

		sprintf(finalFileName, "C:/home/0_GuiMorph_IO_FILES/DATA_LOG_FILES/DL_%s.txt", buffer);
#else 
		sprintf(finalFileName, "./DATA_LOG_FILES/DL_%s.txt", buffer);
#endif

		//printf("This is the new file name\n");
		//printf(buffer);
		fp = fopen(finalFileName, "a+");
		if (NULL == fp)
		{
			return -1;  // not much I can do about this when the code is in a library 
		}
	}

	xCounts = 0;
	//printf("xCounts [%d]\n", xCounts);
	fprintf(fp, "LOG FILE OPEN\n");


	simpleLogCurveInformation();
	simpleLogDotInformation();
	simpleLogOglModelInformation();
	simpleLogOglModelPlyInformation();
	simpleLogStatisticsInformation();
	simpleLogBlankLine();


	return 0;

}

int simpleLog_Close()
{
	if (NULL == fp)
	{
		return 0;   // design decision ... not an error to close a closed file
	}
	fprintf(fp, "LOG FILE CLOSE\n");
	fflush(fp);
	fflush(fp);
	fclose(fp);
	fp = NULL;
	xCounts = 0;
	return 0;
}

int simpleLogBlankLine()
{
	if (NULL == fp)
	{
		// do nothing
		return -1;
	}
	fprintf(fp, "\n");
	return 0;
}

int simpleLog(const char* yC)
{
	char buffer[128];

	if (NULL == fp)
	{
		// do nothing
		return -1;
	}
	else
	{
		time_t rawtime;
		struct tm* timeinfo;
		time(&rawtime);
		timeinfo = localtime(&rawtime);
		strftime(buffer, 80, "%X", timeinfo);
		fprintf(fp, "[%4d] {%s}  <%s>\n", xCounts, buffer, yC);
		fflush(fp);
#ifdef STAND_ALONE_TOOL
		printf(" ! <%s>\n", yC);
#endif

		xCounts++;
	}
	return 0;
}

int simpleLog_Obj(Tcl_Obj* p)
{
	if (NULL == p)
	{
		return -1;
	}
	if (NULL == fp)
	{
		return -1;
	}


	// added this 24 July 2020 ... the log file is messy when this is active
	// use log message to turn on and off

	if (0 == GBL_ENABLE_TCL_OBJECT_LOGGING) {
		return 0;
	}

	simpleLog("Tcl_Object ... ");  // this  sets the time stamp
	fprintf(fp, "  ref count [%d]\n", p->refCount);
	// access and print string representation
	if (NULL == p->bytes)
	{
		fprintf(fp, "  bytes <NULL>\n");
	}
	else
	{
		fprintf(fp, "  bytes <%s>\n", p->bytes);
	}

	// access and print length (string length) 
	fprintf(fp, "  length [%d] \n", p->length);


	if (NULL == p->typePtr)
	{
		fprintf(fp, "  Tcl_ObjType <NULL>\n");
	}
	else
	{
		char* tptr = (char*)p->typePtr->name;
		fprintf(fp, "  Tcl_ObjType <%s>\n", tptr);

		const char dblC[] = "double";
		const char intC[] = "int";
		const char intList[] = "list";
		if (0 == strcmp(intC, p->typePtr->name))
		{

			const double numerator = 1.0;
			const double denominator = (double)p->internalRep.longValue;
			const double q = numerator / denominator;

			const int isZero = (int)p->internalRep.longValue;
			if (0 == isZero)
			{
				fprintf(fp, "  longValue   [%d]\n", (long int)p->internalRep.longValue);
			}
			else  // else integer is non zero so  is there an issue from R ?   how can this be ??
			{
				if (isinf(q))
				{
					fprintf(cmmdFileP, "presumed invalid long int [%d]\n", (int)p->internalRep.longValue);

					fprintf(cmmdFileP, "FAIL : non valid long integer value from tcl object ! \n");
					simpleLog("Tcl_Object ... negative return");
					return -1;
				}
				else
				{
					fprintf(fp, "  longValue   [%d]\n", (long int)p->internalRep.longValue);
				}
			}
		}
		else if (0 == strcmp(dblC, p->typePtr->name))
		{
			const double numerator = 1.0;
			const double denominator = (double)p->internalRep.doubleValue;
			double q = numerator / denominator;
			if (isnan(denominator))
			{
				fprintf(cmmdFileP, "Invalid double (isnan)   from TCL object \n");
				fprintf(cmmdFileP, " ... value <%f>\n", (double)p->internalRep.doubleValue);   // what happens if this executes ??
				// as of 21 may 2020 .. this is still in work 
			}
			else if (0 == (int)denominator)  // else denominator is some number ....
			{
				// then do not bother with the quotient this will be a invalid defect  
			}
			else if (isinf(q))    // well how did this happen ?? 
			{
				fprintf(cmmdFileP, "FAIL : non valid double (infinite)  value from tcl object ! \n");
				fprintf(cmmdFileP, "presumed invalid double <%f>\n", (double)p->internalRep.doubleValue);
				simpleLog("Tcl_Object ... negative return");
				return -1;
			}
			else
			{
				fprintf(fp, "  doubleValue [%f]\n", (double)p->internalRep.doubleValue);
			}
		}
		else if (0 == strcmp(intList, p->typePtr->name))
		{
			fprintf(fp, "type is list ... still in work\n");
		}

	}
	simpleLog("Tcl_Object ... complete");  // this  sets the time stamp
	fprintf(fp, "\n"); // white space for visual separation
	return 0;
}

int commandStream_OpenFile()
{
	if (NULL != cmmdFileP)
	{
		simpleLog((const char*)"WARNING : this file being closed by opening a new command recoding file");
		///simpleLog((char*)"WARNING : this file being closed by opening a new command recoding file");
		commandStream_CloseFile();
		cmmdFileP = NULL;
		yCounts = 0;
	}

	cmmdFileP = NULL;
	yCounts = 0;
	if (NULL == cmmdFileP)   // decided to have not implicit file open
	{
		time_t rawtime;
		struct tm* timeinfo;
		char finalFileName[128];
		time(&rawtime);
		timeinfo = localtime(&rawtime);
		int ll;

		strftime(buffer, 80, "%c", timeinfo);
		//printf("%s\n", buffer);
		ll = (int)strlen(buffer);
		for (int ii = 0; ii < ll; ii++)
		{
			if (buffer[ii] == ':') {
				buffer[ii] = '_';
			}
			if (buffer[ii] == ' ') {
				buffer[ii] = '_';
			}
		}

		//printf("new buffer is <%s>\n", buffer);
#ifdef STAND_ALONE_TOOL
		sprintf(finalFileName, "c:/home/0_GuiMorph_IO_FILES/DATA_LOG_FILES/CMMDS_DL_%s.txt", buffer);
#else 
		// for library code and execution with R this will be the R current working directory
		sprintf(finalFileName, "./DATA_LOG_FILES/CMMDS_DL_%s.txt", buffer);
#endif

		//printf("This is the new file name\n");
		//printf(buffer);
		cmmdFileP = fopen(finalFileName, "a+");
		if (NULL == cmmdFileP)
		{
			return -1;  // not much I can do about this when the code is in a library 
		}
	}

	yCounts = 0;
	fprintf(cmmdFileP, "Command Recording OPEN FILE\n");
	return 0;
}

int commandStream_CloseFile()
{

	if (NULL == cmmdFileP)
	{
		return 0;   // design decision ... not an error to close a closed file
	}
	fprintf(cmmdFileP, "Command Recording FILE CLOSE\n");
	fflush(cmmdFileP);
	fflush(cmmdFileP);
	fclose(cmmdFileP);
	cmmdFileP = NULL;
	yCounts = 0;
	return 0;
}

int commandStream_WriteStringToFile(const char* s)
{
	if (NULL == cmmdFileP)
	{
		return -1;
	}
	fprintf(cmmdFileP, "<%s>\n", s);  // intent is to write spaces an ..... strings
	yCounts++;
	return 0;
}

int commandStream_WriteObjectToFile(const Tcl_Obj* const p)
{
	if (NULL == p)
	{
		return -1;
	}
	if (NULL == cmmdFileP)
	{
		return -1;
	}

	fprintf(cmmdFileP, "Tcl_Object ... \n");  // this  sets the time stamp
	fprintf(cmmdFileP, "  ref count [%d]\n", p->refCount);
	// access and print string representation
	if (NULL == p->bytes)
	{
		fprintf(cmmdFileP, "  bytes <NULL>\n");
	}
	else
	{
		fprintf(cmmdFileP, "  bytes <%s>\n", p->bytes);
	}

	// access and print length (string length) 
	fprintf(cmmdFileP, "  length [%d] \n", p->length);


	if (NULL == p->typePtr)
	{
		fprintf(cmmdFileP, "  Tcl_ObjType <NULL>\n");
	}
	else
	{
		char* tptr = (char*)p->typePtr->name;
		fprintf(cmmdFileP, "  Tcl_ObjType <%s>\n", tptr);

		const char dblC[] = "double";
		const char intC[] = "int";
		if (0 == strcmp(intC, p->typePtr->name))
		{
			// 21 May 2020  ... made inert I suspect it is not possible for an integer to be invalid 
			// If I discover other wise, this issue will be worked

			//const double numerator = 1.0;
			//const double denominator = (double)p->internalRep.longValue;
			//double q = numerator / denominator;


			//if (isinf(q))         
			//{
			//	fprintf(cmmdFileP, "presumed invalid long int [%d]\n", (int)p->internalRep.longValue);
			//	fprintf(cmmdFileP, "FAIL : non valid long value from tcl object ! \n");
			//	simpleLog("Tcl_Object ... negative return");
			//	return -1;
			//}
			//else
			//{
			fprintf(cmmdFileP, "  longValue   [%d]\n", (long int)p->internalRep.longValue);
			//}
		}
		else if (0 == strcmp(dblC, p->typePtr->name))
		{
			// 21 May 2020 attempting to detect invalid double values from R 
			const double numerator = 1.0;
			const double denominator = (double)p->internalRep.doubleValue;
			double q = numerator / denominator;
			if (isnan(denominator))
			{
				fprintf(cmmdFileP, "FAIL : non valid double value from tcl object ! \n");
				fprintf(cmmdFileP, "presumed invalid double <%f>\n", p->internalRep.doubleValue);   // what happens here ????? 
				simpleLog("Tcl_Object ... negative return");
				return -1;
			}
			else if (0 == (int)denominator)
			{
				//  do not use quotient .... this is an induced defect 
			}
			else if (isinf(q))
			{
				fprintf(cmmdFileP, "FAIL : non valid  infinite double value from tcl object ! \n");
				fprintf(cmmdFileP, "presumed invalid double [%f]\n", p->internalRep.doubleValue);
				simpleLog("Tcl_Object ... negative return");
				return -1;
			}
			else
			{
				fprintf(cmmdFileP, "  doubleValue [%f]\n", (double)p->internalRep.doubleValue);
			}
		}
	}
	fprintf(cmmdFileP, "Tcl_Object ... complete\n");  // this  sets the time stamp
	yCounts++;
	return 0;
}

int TclIf_LogCommands(int objc, Tcl_Obj* const objv[])
{
	if (objc <= 0)
	{
		simpleLog("TclIf_LogCommands no objects to log");
		return -1;  // zero or less arguments ?? way bad !
	}
	// turned off simpleLog statements 07 August 2020 
	////simpleLog((const char*)"TclIF_LogCommands ... have objects");
	int rv = -1;
	int bad = 0;
	commandStream_WriteStringToFile("...................");
	for (int ii = 0; ii < objc; ii++)
	{
		rv = commandStream_WriteObjectToFile(objv[ii]);
		if (0 != rv)
		{
			simpleLog((const char*)"FAIL ... TclIF_LogCommands ... did not write object to file. File closed ?");
			bad = 1;
		}
	}

	if (0 != bad)
	{
		simpleLog((const char*)"FAIL ... TclIF_LogCommands ... returning -1");
		return -1;
	}
	////simpleLog((const char*)"TclIF_LogCommands ... returning 0 -OK-");
	return 0;

}

int clear_model(model_t* m)
{
	if (NULL == m)
	{
		return -1;
	}
	m->vertex = NULL;
	m->color = NULL;
	m->normal = NULL;
	m->dsVertex = NULL;   //down sample vertex
	m->count = 0;
	m->vertexCountActual = 0;
	m->dsCount = 0;
	m->max[0] = 0;
	m->min[0] = 0;
	m->min[1] = 0;
	m->min[2] = 0;

	m->dsMax[0] = 0;
	m->dsMax[1] = 0;
	m->dsMax[2] = 0;

	m->dsMin[0] = 0;
	m->dsMin[1] = 0;
	m->dsMin[2] = 0;

	m->delta[0] = 0;
	m->delta[1] = 0;
	m->delta[2] = 0;
	m->delta[3] = 0;

	m->vertexSize = 0;
	m->colorSize = 0;
	m->normalSize = 0;
	m->dsVertexSize = 0;
	m->fileName[0] = '\0';

	m->originalMeanValues[0] = 0;
	m->originalMeanValues[1] = 0;
	m->originalMeanValues[2] = 0;

	return 0;
}

int clear_context(context_t* c)
{
	if (NULL == c)
	{
		return -1;
	}
	c->x = 0;;
	c->y = 0;
	c->z = 0;
	c->scale = 0;
	c->rotation[0] = 0;
	c->rotation[1] = 0;
	c->rotation[2] = 0;
	return 0;
}

int development_function(int selector)
{

	return -1;
}

int snapshot()
{
	// As a development tool - this fnction is continually under development
	// at the developers discretion
	char buffer[128];
	buffer[0] = '\0';
	simpleLogBlankLine();
	simpleLog("----- start snapshot ------");

	simpleLogWriteLandmarksToFile();
	simpleLogBlankLine();
	simpleLogWriteAnchorsToFile();
	simpleLogBlankLine();

	simpleLogWriteModelToFile(GBL_PTR_MODEL_1);

	/*

		simpleLogWriteModelToFile(GBL_PTR_MODEL_2);
		simpleLogWriteModelToFile(GBL_PTR_MODEL_3);
		//simpleLogWriteModelToFile(GBL_PTR_MODEL_4);
		//simpleLogWriteModelToFile(GBL_PTR_MODEL_5);

		simpleLogWriteContextToFile(GBL_PTR_CONTEXT_1);
		simpleLogWriteContextToFile(GBL_PTR_CONTEXT_2);
		simpleLogWriteContextToFile(GBL_PTR_CONTEXT_3);
		//simpleLogWriteContextToFile(GBL_PTR_CONTEXT_4);
		//simpleLogWriteContextToFile(GBL_PTR_CONTEXT_5);


		simpleLogWriteCurveToFile(GBL_PTR_CURVE_1);
		simpleLogWriteCurveToFile(GBL_PTR_CURVE_2);
		//simpleLogWriteCurveToFile(GBL_PTR_CURVE_3);
		//simpleLogWriteCurveToFile(GBL_PTR_CURVE_4);
		//simpleLogWriteCurveToFile(GBL_PTR_CURVE_5);



		sprintf(buffer, "Landmarks  rows [%d] numSpecimens [%d]",
			GBL_SET_NUMBER_OF_LANDMARKS,  GBL_LANDMARKS_NUM_SPECIMENS);
		simpleLog(buffer);

		sprintf(buffer, "Anchors  rows [%d]  numSpecimens [%d]",
			GBL_SET_NUMBER_OF_ANCHORS,  GBL_LANDMARKS_NUM_SPECIMENS);
		simpleLog(buffer);
	*/

	/*
		sprintf(buffer, "Curves  number [%d] length [%d] numSpecimens [%d]",
			GBL_CURVES_NUMBER_OF_CURVES, GBL_CURVES_LENGTH, GBL_CURVES_NUM_SPECIMENS);
		simpleLog(buffer);
	*/

	simpleLog("----- snapshot ------ end");
	simpleLogBlankLine();
	return 0;
}

int simpleLogWriteModelToFile(model_t* m)
{
	char buffer[128];
	buffer[0] = '\0';
	if (NULL == m)
	{
		return -1;
	}
	if (NULL == m->fileName)
	{
	}
	else
	{
		//m->fileName[255] = '\0';   // force a finite length if it is not done already
	}
	simpleLogBlankLine();
	sprintf(buffer, "FUNCTION simpleLogWriteModelToFile ...");
	simpleLog(buffer);
	sprintf(buffer, "Model Integer Count  [%d]", m->thisModelIntegerCount); simpleLog(buffer);

	sprintf(buffer, "vertex is   <%s> ", (NULL == m->vertex) ? "NULL" : "not null");
	simpleLog(buffer);
	sprintf(buffer, "color  is   <%s> ", (NULL == m->color) ? "NULL" : "not null");
	simpleLog(buffer);
	sprintf(buffer, "normal is   <%s> ", (NULL == m->normal) ? "NULL" : "not null");
	simpleLog(buffer);
	sprintf(buffer, "dsVertex is <%s> ", (NULL == m->dsVertex) ? "NULL" : "not null");
	simpleLog(buffer);
	sprintf(buffer, "count   [%d]", m->count);
	simpleLog(buffer);

	sprintf(buffer, "vertex count actual  [%d] <---------", m->vertexCountActual);
	simpleLog(buffer);

	sprintf(buffer, "dsCount [%d]", m->dsCount);
	simpleLog(buffer);
	sprintf(buffer, "max  <%10.6f ... %10.6f ... %10.6f", m->max[0], m->max[1], m->max[2]);
	simpleLog(buffer);
	sprintf(buffer, "min  <%10.6f ... %10.6f ... %10.6f", m->min[0], m->min[1], m->min[2]);
	simpleLog(buffer);

	sprintf(buffer, "originalMeanValues   <%10.6f ... %10.6f ... %10.6f",
		m->originalMeanValues[0], m->originalMeanValues[1], m->originalMeanValues[2]);
	simpleLog(buffer);


	sprintf(buffer, "dsMax  <%f ... %f ... %f", m->dsMax[0], m->dsMax[1], m->dsMax[2]);
	simpleLog(buffer);
	sprintf(buffer, "dsMin  <%f ... %f ... %f", m->dsMin[0], m->dsMin[1], m->dsMin[2]);
	simpleLog(buffer);
	sprintf(buffer, "vertex size   [%d] (allocated bytes)", m->vertexSize);
	simpleLog(buffer);
	sprintf(buffer, "color size    [%d] (allocated bytes)", m->colorSize);
	simpleLog(buffer);
	sprintf(buffer, "normal size   [%d] (allocated bytes)", m->normalSize);
	simpleLog(buffer);
	sprintf(buffer, "dsVertex size [%d] (allocated bytes)", m->dsVertexSize);
	simpleLog(buffer);

	if (NULL == m->fileName)
	{
	}
	else
	{
		sprintf(buffer, "file name :   <%s>", m->fileName);
		simpleLog(buffer);
	}

	sprintf(buffer, "FUNCTION simpleLogWriteModelToFile ... END");
	simpleLog(buffer);
	simpleLogBlankLine();
	return 0;
}

int clearCurve(curve_t* c)
{
	if (NULL == c) { return -1; }
	c->points[0] = 0;
	c->points[1] = 0;
	c->points[2] = 0;
	c->lines1 = NULL;
	c->lines2 = NULL;
	c->line1Size = -1;
	c->line2Size = -3;
	c->pointNum = 0;
	c->next = NULL;
	return 0;
}

int simpleLogWriteContextToFile(context_t* c)
{
	char buffer[128];
	buffer[0] = '\0';
	if (NULL == c)
	{
		simpleLog("ERROR  : NULL pointer for context type ");
		return -1;
	}

	sprintf(buffer, "x %f y %f z %f", c->x, c->y, c->z);
	simpleLog(buffer);
	sprintf(buffer, "s %f ", c->scale);
	simpleLog(buffer);
	sprintf(buffer, "rotations [0] %f  [1] %f  [2] %f", c->rotation[0], c->rotation[1], c->rotation[2]);
	simpleLog(buffer);
	return 0;
}

int simpleLogWriteCurveToFile(curve_t* c)
{
	char buffer[128];
	buffer[0] = '\0';

	if (NULL == c)
	{
		simpleLog("WARNING : NULL pointer for curve type  has it been allocated yet ?");
		return -1;
	}

	simpleLog("Curve data ...");
	sprintf(buffer, "points [0] <%s>", (NULL == c->points[0]) ? "NULL" : "not null");
	simpleLog(buffer);
	if (NULL != c->points[0])
	{
		sprintf(buffer, "point [0] :   <%f ... %f ... %f>",
			(float)c->points[0]->x, (float)c->points[0]->y, (float)c->points[0]->z);
		simpleLog(buffer);
	}


	sprintf(buffer, "points [1] <%s>", (NULL == c->points[1]) ? "NULL" : "not null");
	simpleLog(buffer);
	if (NULL != c->points[1])
	{
		sprintf(buffer, "point [1] :   <%f ... %f ... %f>",
			c->points[1]->x, c->points[1]->y, c->points[1]->z);
		simpleLog(buffer);
	}
	sprintf(buffer, "points [2] <%s>", (NULL == c->points[2]) ? "NULL" : "not null");
	simpleLog(buffer);
	if (NULL != c->points[2])
	{
		sprintf(buffer, "point [2] :   <%f ... %f ... %f>",
			c->points[2]->x, c->points[2]->y, c->points[2]->z);
		simpleLog(buffer);
	}

	sprintf(buffer, "lines1     <%s>", (NULL == c->lines1) ? "NULL" : "not null"); simpleLog(buffer);
	sprintf(buffer, "lines2     <%s>", (NULL == c->lines2) ? "NULL" : "not null"); simpleLog(buffer);
	sprintf(buffer, "line1Size  [%d]", c->line1Size);
	simpleLog(buffer);
	sprintf(buffer, "line2Size  [%d]", c->line2Size);
	simpleLog(buffer);

	sprintf(buffer, "pointNum   [%d]", c->pointNum); simpleLog(buffer);

	sprintf(buffer, "next link  <%s>", (NULL == c->next) ? "NULL" : "not null"); simpleLog(buffer);
	simpleLog("Curve data ... complete");


	return 0;    // inwork
}

int showPoint(point_t* p)
{
	if (NULL == p)
	{
		return -1;
	}
	printf(" x : <%f>\n", p->x);
	printf(" y : <%f>\n", p->y);
	printf(" z : <%f>\n", p->z);
	return 0;
}

int ut_show_Model(model_t* m)
{
	char buffer[128];
	buffer[0] = '\0';
	if (NULL == m)
	{
		return -1;
	}
	if (NULL == m->fileName)
	{
	}
	else
	{
		//m->fileName[255] = '\0';   // force a finite length if it is not done already
	}
	sprintf(buffer, "\nSHOW MODEL ...");
	printf("%s\n", buffer);
	sprintf(buffer, "vertex is   <%s> ", (NULL == m->vertex) ? "NULL" : "not null");
	printf("%s\n", buffer);
	sprintf(buffer, "color  is   <%s> ", (NULL == m->color) ? "NULL" : "not null");
	printf("%s\n", buffer);
	sprintf(buffer, "normal is   <%s> ", (NULL == m->normal) ? "NULL" : "not null");
	printf("%s\n", buffer);
	sprintf(buffer, "dsVertex is <%s> ", (NULL == m->dsVertex) ? "NULL" : "not null");
	printf("%s\n", buffer);
	sprintf(buffer, "count   [%d]", m->count);
	printf("%s\n", buffer);

	sprintf(buffer, "vertex count actual   [%d] <---------", m->vertexCountActual);
	printf("%s\n", buffer);

	sprintf(buffer, "dsCount [%d]", m->dsCount);
	printf("%s\n", buffer);

	sprintf(buffer, "max  < %10.6f ... %10.6f ... %10.6f>", m->max[0], m->max[1], m->max[2]);
	printf("%s\n", buffer);

	sprintf(buffer, "min  < %10.6f ... %10.6f ... %10.6f>", m->min[0], m->min[1], m->min[2]);
	printf("%s\n", buffer);

	sprintf(buffer, "O_MeanVals  < %10.6f ... %10.6f ... %10.6f>",
		m->originalMeanValues[0], m->originalMeanValues[1], m->originalMeanValues[2]);
	printf("%s\n", buffer);


	sprintf(buffer, "dsMax  <%f ... %f ... %f", m->dsMax[0], m->dsMax[1], m->dsMax[2]);
	printf("%s\n", buffer);
	sprintf(buffer, "dsMin  <%f ... %f ... %f", m->dsMin[0], m->dsMin[1], m->dsMin[2]);
	printf("%s\n", buffer);
	sprintf(buffer, "vertex size   [%d] (allocated bytes)", m->vertexSize);
	printf("%s\n", buffer);
	sprintf(buffer, "color size    [%d] (allocated bytes)", m->colorSize);
	printf("%s\n", buffer);
	sprintf(buffer, "normal size   [%d] (allocated bytes)", m->normalSize);
	printf("%s\n", buffer);
	sprintf(buffer, "dsVertex size [%d]", m->dsVertexSize);
	printf("%s\n", buffer);

	sprintf(buffer, "largest scale factor <%f>", m->largestScaleFactor);
	printf("%s\n", buffer);


	if (NULL == m->fileName)
	{
	}
	else
	{
		sprintf(buffer, "file name :   <%s>", m->fileName);
		printf("%s\n", buffer);
	}


	return 0;
}

int drawTest()
{
	model_t* mPointer;
	mPointer = models;
	if (NULL == mPointer)
	{
		return -1;
	}

	//simpleLogWriteModelToFile(mPointer);
	return 0;
}

void clear_GBL_LANDMARK_SET()
{
	for (int ii = 0; ii < GBL_LANDMARK_SET_MAX_ROWS; ii++)
	{
		GBL_LANDMARK_SET[ii][0] = 0;
		GBL_LANDMARK_SET[ii][1] = 0;
		GBL_LANDMARK_SET[ii][2] = 0;
	}
}

void show_GBL_LANDMARK_SET()
{
	printf("show_GBL_LANDMARK_SET() ...\n");
	for (int ii = 0; ii < GBL_LANDMARK_SET_MAX_ROWS; ii++)
	{
		printf("  [%2d] ... <%10.6f ... %10.6f ... %10.6f>\n",
			ii, GBL_LANDMARK_SET[ii][0], GBL_LANDMARK_SET[ii][1], GBL_LANDMARK_SET[ii][2]);
	}
	printf("\n");
}

void clear_GBL_CURVE_SET()
{
	for (int ii = 0; ii < GBL_CURVE_SET_MAX_ROWS; ii++)
	{
		GBL_CURVE_SET[ii][0] = 0;
		GBL_CURVE_SET[ii][1] = 0;
		GBL_CURVE_SET[ii][2] = 0;
	}
}

void show_GBL_CURVE_SET()
{
	printf("show_GBL_CURVE_SET() ...\n");
	for (int ii = 0; ii < GBL_CURVE_SET_MAX_ROWS; ii++)
	{
		printf("  [%2d] ... <%10.6f ... %10.6f ... %10.6f>\n",
			ii, GBL_CURVE_SET[ii][0], GBL_CURVE_SET[ii][1], GBL_CURVE_SET[ii][2]);
	}
	printf("\n");
}

int ut_test_ogl_loadModel(const char* filename, model_t* model)
{
	return -1;  // actual function is not part of this package
}

//updates graphical changes to specimens, i.e. adding/removing dots, displaying downsample data, etc




void simpleLogCurveInformation()
{
	sprintf(buffer, curveVersionPtr);
	simpleLog(buffer);
}
void simpleLogDotInformation()
{
	sprintf(buffer, dotVersionPtr);
	simpleLog(buffer);
}
void simpleLogOglModelInformation()
{
	sprintf(buffer, oglModelVersionPtr);
	simpleLog(buffer);
}
void simpleLogOglModelPlyInformation()
{
	sprintf(buffer, oglModelPlyVersionPtr);
	simpleLog(buffer);
}
void simpleLogStatisticsInformation()
{
	sprintf(buffer, statisticsVersionPtr);
	simpleLog(buffer);
}
void simpleLogTclIfInformation()
{
	sprintf(buffer, tcl_ifVersionPtr);
	simpleLog(buffer);
}
void simpleLogOglInformation()
{
	sprintf(buffer, oglVersionPtr);
	simpleLog(buffer);
}


void simpleLogWriteAnchorsToFile()
{
	sprintf(buffer, "DEBUG : Write Anchors to log file"); simpleLog(buffer);
	sprintf(buffer, "DEBUG : Anchors allocated slices [%d]", anchorGetArraySize()); simpleLog(buffer);
	dot_t* oneDot = NULL;
	point_t* onePoint = NULL;
	//show_mode_t dotMode;

	for (int ii = 0; ii < anchorGetArraySize(); ii++)
	{
		anchorSetArrayIndex(ii);
		sprintf(buffer, "DEBUG : Anchor data for slice [%d]", get_anchor_slice_index()); simpleLog(buffer);
		oneDot = anchor_get(get_anchor_slice_index());
		int count = 0;

		if (NULL == oneDot)
		{
			sprintf(buffer, "NULL pointer to dot for first dot ... no List ??"); simpleLog(buffer);
			continue;
		}
		else
		{
			count++;
			sprintf(buffer, "DEBUG : count [%2d] Point  x <%10.6f> y <%10.6f> z <%10.6f>", count, oneDot->p.x, oneDot->p.y, oneDot->p.z);
			simpleLog(buffer);
		}

		while (oneDot->next != NULL)
		{
			oneDot = oneDot->next;
			if (NULL != oneDot)
			{
				count++;
				sprintf(buffer, "DEBUG : count [%2d] Point  x <%10.6f> y <%10.6f> z <%10.6f>", count, oneDot->p.x, oneDot->p.y, oneDot->p.z);
				simpleLog(buffer);
			}
			else
			{
				sprintf(buffer, "dot pointer is null for index [%d]", ii); simpleLog(buffer);
				break;
			}
		}
		sprintf(buffer, "DEBUG : list count for slice index [%d] is [%d]", ii, count); simpleLog(buffer);


	}

	sprintf(buffer, "DEBUG : Write Anchors to log file ... END "); simpleLog(buffer);
}

void simpleLogWriteLandmarksToFile()
{
	sprintf(buffer, "DEBUG : Write Landmarks to log file"); simpleLog(buffer);
	sprintf(buffer, "DEBUG : Landmarks allocated slices [%d]", dotGetArraySize()); simpleLog(buffer);
	dot_t* oneDot = NULL;
	point_t* onePoint = NULL;
	//show_mode_t dotMode;

	for (int ii = 0; ii < dotGetArraySize(); ii++)
	{
		dotSetArrayIndex(ii);
		sprintf(buffer, "DEBUG : Landmark data for slice [%d]", get_dot_slice_index()); simpleLog(buffer);
		oneDot = dot_get(get_dot_slice_index());
		int count = 0;

		if (NULL == oneDot)
		{
			sprintf(buffer, "NULL pointer to dot for first dot ... no List ??"); simpleLog(buffer);
			continue;
		}
		else
		{
			count++;
			sprintf(buffer, "DEBUG : count [%2d] Point  x <%10.6f> y <%10.6f> z <%10.6f>", count, oneDot->p.x, oneDot->p.y, oneDot->p.z);
			simpleLog(buffer);
		}

		while (oneDot->next != NULL)
		{
			oneDot = oneDot->next;
			if (NULL != oneDot)
			{
				count++;
				sprintf(buffer, "DEBUG : count [%2d] Point  x <%10.6f> y <%10.6f> z <%10.6f>", count, oneDot->p.x, oneDot->p.y, oneDot->p.z);
				simpleLog(buffer);
			}
			else
			{
				sprintf(buffer, "dot pointer is null for index [%d]", ii); simpleLog(buffer);
				break;
			}
		}
		sprintf(buffer, "DEBUG : list count for slice index [%d] is [%d]", ii, count); simpleLog(buffer);


	}

	sprintf(buffer, "DEBUG : Write Landmarks to log file ... END "); simpleLog(buffer);
}

