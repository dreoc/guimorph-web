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

extern void* ALLOCATE_WRAPPER(unsigned int howMuch);
extern void FREE_WRAPPER(void* pointer);

int Wrapper_GetIntFromObj(Tcl_Interp* interp, Tcl_Obj* objPtr, int* ptrToYourInteger)
{
#ifdef STAND_ALONE_TOOL
	long int temp;
	int tempAsInt;
	temp = (long int)objPtr->internalRep.longValue;
	tempAsInt = (int)temp;
	*ptrToYourInteger = tempAsInt;
#endif
#ifdef CODE_FOR_LIBRARY
	Tcl_GetIntFromObj(interp, objPtr, ptrToYourInteger);
#endif
	return 0;
}

int Wrapper_GetDoubleFromObj(Tcl_Interp* interp, Tcl_Obj* objPtr, double* ptrToYourDouble)
{
#ifdef STAND_ALONE_TOOL
	double temp;
	temp = objPtr->internalRep.doubleValue;
	*ptrToYourDouble = temp;
#endif

#ifdef CODE_FOR_LIBRARY
	Tcl_GetDoubleFromObj(interp, objPtr, ptrToYourDouble);
#endif
	return 0;
}

const char* Wrapper_GetStringFromObj(Tcl_Obj* objPtr, int* NOTUSED)
{
#ifdef STAND_ALONE_TOOL
	char* shape;
	shape = objPtr->bytes;
	return (const char*)shape;
#endif
#ifdef CODE_FOR_LIBRARY
	const char* shape = Tcl_GetStringFromObj(objPtr, NULL); // returns shape argument passed from R
	return (const char*)shape;
#endif
}
int Wrapper_ListObjGetElements(Tcl_Interp* interp, Tcl_Obj* objv, unsigned int* listc, Tcl_Obj*** listv)
{
	return 0;  // have not yet the need to develop 
}
#ifdef CODE_FOR_LIBRARY 
#define TCL_CMD(name) int name(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
#endif

/*
#ifdef STAND_ALONE_TOOL
int add(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
int set(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
int setSpecimen(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
int show(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
int setWindow(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
int setDownSample(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
int setDot(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
int del(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
int loadDgt(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
int directive(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);

#endif
*/

const int GBL_RTN_SUCCESS = 0;
const int GBL_RTN_ERROR = -1;
const int GBL_RTN_IGNORE = -2;
const int GBL_RTN_UNDER_CONSTRUCTION = -3;

// defines as in the original code ... 
#define D1(info, arg1) printf(info"\n", arg1)
#define D(info) printf(info"\n")
#define D1(info, arg1) printf(info"\n", arg1)
#define D2(info, arg1, arg2) printf("%s: "info"\n", __FUNCTION__, arg1, arg2)
#define D3(info, arg1, arg2, arg3) printf("%s: "info"\n", __FUNCTION__, arg1, arg2, arg3)


#ifdef STAND_ALONE_TOOL
char msg[512];

#define TCL_RESULT_SUCCESS()  \
	sprintf(msg, "SUCCESS"); \
	simpleLog(msg);

#define TCL_RESULT_UNDER_CONSTRUCTION()  \
	sprintf(msg, "UNDER_CONSTRUCTION"); \
	simpleLog(msg);

#define TCL_RESULT_ERROR()  \
	sprintf(msg, "ERROR"); \
	simpleLog(msg);

#define TCL_RESULT_IGNORE()  \
	sprintf(msg, "IGNORE"); \
	simpleLog(msg);

#define TCL_RESULT(info, arg1) \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, info, arg1); \
	simpleLog(msg);

#define TCL_RESULT1(info, arg1) \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, info, arg1); \
	simpleLog(msg);

#define TCL_RESULT2(info, arg1, arg2) \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, info, arg1, arg2); \
	simpleLog(msg);

#define TCL_RESULT3(info, arg1, arg2, arg3) \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, info, arg1, arg2, arg3); \
	simpleLog(msg);
#endif

#ifdef CODE_FOR_LIBRARY

#define TCL_RESULT_SUCCESS()  \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, "SUCCESS"); \
	Tcl_SetResult(interp, msg, TCL_DYNAMIC);

#define TCL_RESULT_UNDER_CONSTRUCTION()  \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, "UNDER_CONSTRUCTION"); \
	Tcl_SetResult(interp, msg, TCL_DYNAMIC);

#define TCL_RESULT_ERROR()  \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, "ERROR"); \
	Tcl_SetResult(interp, msg, TCL_DYNAMIC);

#define TCL_RESULT_IGNORE()  \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, "IGNORE"); \
	Tcl_SetResult(interp, msg, TCL_DYNAMIC);


#define TCL_RESULT1(info, arg1) \
    char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, info, arg1); \
	Tcl_SetResult(interp, msg, TCL_DYNAMIC);

#define TCL_RESULT2(info, arg1, arg2) \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, info, arg1, arg2); \
	Tcl_SetResult(interp, msg, TCL_DYNAMIC);

#define TCL_RESULT3(info, arg1, arg2, arg3) \
	char *msg = ALLOCATE_WRAPPER(512); \
	sprintf(msg, info, arg1, arg2, arg3); \
	Tcl_SetResult(interp, msg, TCL_DYNAMIC);


#endif 
int tclCmdStep(int curId, Tcl_Obj* const objv[], const char** steps, int stepNum, int stepId)
{
	if (curId > 0) return curId;

	for (int i = 1; i <= stepNum; i++) {

		const char* step = Wrapper_GetStringFromObj(objv[i], NULL);
		if (strcmp(step, steps[i - 1]) != 0)
		{
			return 0;
		}
	}
	return stepId;
}
float absd(float a, float b)
{
	float tmp = a > b ? a - b : b - a;

	return tmp > 0.0 ? tmp : -1.0 * tmp;
}

float getRealZ(float x, float y, float z)
{
	if (0 == model_amount)
	{
		return 0.0;
	}

	for (int i = 0; i < models->count * 3; i += 3)
	{
		if (absd(models->vertex[i], x) < 0.01
			&& absd(models->vertex[i + 1], y) < 0.01
			&& absd(models->vertex[i + 2], z) < 0.01)
		{
			return models->vertex[i + 2];
		}
	}
	return 0.0;
}

//displays dots to GUI screen
void drawDots()
{
	simpleLog("INFO : drawDots ... start");
	if (model_amount == 0)
	{
		simpleLog("INFO :drawDots ... model_amount is 0, nothing to do  .. .returning");
		return;
	}

	dotSetArrayIndex(model_index);
	anchorSetArrayIndex(model_index);

	sprintf(buffer, "draw dots (land marks) using  current slice of [%d] {zero based}", get_dot_slice_index());
	simpleLog(buffer);

	dot_t* n = dot_get(get_dot_slice_index());


	if (NULL == n)
	{
		simpleLog("WARNING : null pointer for dot returned from dot_get() ");
		return;
	}


	color_t* c = &defaultDotColor;
	color_t thisDotColor;
	color_t* otherColorPointer = &defaultDotColor;

	int dotId = 1;
	while (n != NULL) //while we haven't reached the end
	{
		//  if dot type is CURVE (as is generated by the curves code,
		//  and the GUI tab is not on the Curves tab, then ignore this dot
		//  But curves are contained in their own data structure.

		if (n->type == CURVE && showModel != CURVE)
		{
			n = n->next;
			continue;
		}

		if (showModel == CURVE && n->c.r >= 0.0 && n->c.r <= 1.0)
		{
			c = &n->c;
			otherColorPointer = &n->c;
		}

		int rv = -1;

		// if the gui is on the digitize tab or is on the anchors tab 
		if (LANDMARK == showModel || ANCHOR == showModel)
		{
			thisDotColor.r = n->c.r;
			thisDotColor.g = n->c.g;
			thisDotColor.b = n->c.b;
			otherColorPointer = &defaultDotColor;
			// if the dot color is other than the default color
			// then substitute the pointer 
			if (thisDotColor.r != c->r) { otherColorPointer = &thisDotColor; }
			if (thisDotColor.g != c->g) { otherColorPointer = &thisDotColor; }
			if (thisDotColor.b != c->b) { otherColorPointer = &thisDotColor; }
		}

		rv = ogl_drawDot(&n->p, otherColorPointer, dotRadius);    //uses ogl to draw dot at point p with color c and radius dotRadius
		if (0 != rv)
		{
			simpleLog("ERROR : negative return from ogl_drawDot");
		}

		if (labeled && n->type != CURVE) //displays ordered label for dot
		{
			sprintf(buffer, "INFO : dot labels : dot [%d]  %10.6f %10.6f %10.6f ", dotId, n->p.x, n->p.y, n->p.z);
			simpleLog(buffer);

			// this code moves the label off the surface of the specimen
			// if default values then do nothing. This is the original implementation 
			if ((1.0 == GBL_INWORK_LABEL_SCALEFACTOR_MPY) && (0 == GBL_INWORK_LABEL_SCALEFACTOR_ADD))
			{
				ogl_drawLabel(&n->p, otherColorPointer, dotId, dotRadius, n->p.z >= 0 ? models->max[Z] : models->min[Z]);
			}
			else
			{
				float tempZ;
				if (n->p.z >= 0)
				{
					tempZ = GBL_INWORK_LABEL_SCALEFACTOR_MPY * models->max[Z] + GBL_INWORK_LABEL_SCALEFACTOR_ADD;
				}
				else
				{
					tempZ = -1.0 * GBL_INWORK_LABEL_SCALEFACTOR_MPY * models->min[Z] - GBL_INWORK_LABEL_SCALEFACTOR_ADD;
				}
				ogl_drawLabel(&n->p, otherColorPointer, dotId, dotRadius, tempZ);

			}
			dotId++;

		}
		n = n->next;
	}
	simpleLog("INFO : drawDots ... end");
	simpleLogBlankLine();
	return;
}

//displays dots (anchors) to GUI screen
void drawAnchors()
{
	if (0 == model_amount)
	{
		return;
	}

	dotSetArrayIndex(model_index);
	anchorSetArrayIndex(model_index);

	simpleLog("INFO : drawAnchors start");
	sprintf(buffer, "INFO : using  current slice of [%d] {zero based}", get_anchor_slice_index());
	simpleLog(buffer);
	dot_t* n = anchor_get(get_anchor_slice_index());
	color_t* c = &defaultAnchorColor;
	color_t thisDotColor;
	color_t* otherColorPointer = &defaultAnchorColor;
	int dotId = 1;
	while (n != NULL)
	{
		// if dot type is a curve dot and we are not on the curve tab in the gui
		// then we ignore this dot. Question is how did we get access to such a dot ?
		// curves are contained in their own data structure . Legacy code ?
		//   ---- is this completely incorrect ?? 
		if (n->type == CURVE && showModel != CURVE)
		{
			n = n->next;
			continue;
		}

		// so is the GUI is on the curve tab and this dot has a red component outside
		// the range [0 ... 1] we change the dot color
		if (showModel == CURVE && n->c.r >= 0.0 && n->c.r <= 1.0)
		{
			c = &n->c;
			otherColorPointer = &n->c;
		}


		if (ANCHOR == showModel)   // applies to  dots on the anchor tab 
		{
			otherColorPointer = &defaultAnchorColor;
			thisDotColor.r = n->c.r;
			thisDotColor.g = n->c.g;
			thisDotColor.b = n->c.b;
			// if the dot color is other than the default color (because it is 'selected'
			// then substitute the pointer for color
			if (thisDotColor.r != c->r) { otherColorPointer = &thisDotColor; }
			if (thisDotColor.g != c->g) { otherColorPointer = &thisDotColor; }
			if (thisDotColor.b != c->b) { otherColorPointer = &thisDotColor; }
		}

		ogl_drawDot(&n->p, otherColorPointer, anchorRadius);

		if (alabeled && n->type != CURVE)
		{
			sprintf(buffer, "INFO : anchor labels : dot [%d]  %10.6f %10.6f %10.6f ", dotId, n->p.x, n->p.y, n->p.z);
			simpleLog(buffer);
			ogl_drawLabel(&n->p, otherColorPointer, dotId, anchorRadius, n->p.z >= 0 ? models->max[Z] : models->min[Z]);
			dotId++;
		}
		n = n->next;
	}
	simpleLog("INFO : drawAnchors end");
	simpleLogBlankLine();
}

//displays curves to GUI screen
void drawCurves()
{
#ifdef NO_GRAPHICS
	return;
#endif

	simpleLog("INFO : drawCurves start");
	int curveCurrentIndexIs = get_curve_slice_id();
	sprintf(buffer, "DEBUG : This is drawCurves. Current slice index is [%d]", curveCurrentIndexIs);
	simpleLog(buffer);

	curve_t* p = get_curveAtIndex(curveCurrentIndexIs);
	if (NULL == p)
	{
		// this may not be a real error ... thee could be no curves greated yet ... 
		simpleLog("WARNING : Failed to get the curve for the current slice index - are there any curves yet ?");
		return;
	}

	if (NULL == p) { return; }
	if (p->pointNum < 3) { return; }

	// should this be modified to allow display of one of the lines if the other is null ??
	if (NULL == p->lines1) { return; }
	if (NULL == p->lines2) { return; }


	// we need at least 3 dots to build a curve, so keep drawing curve until we reach 
	// no more points or we dont have enough dots to build curve

	while (p != NULL && p->pointNum >= 3)
	{
		ogl_drawLine(p->lines1, p->line1Size);
		ogl_drawLine(p->lines2, p->line2Size);
		p = p->next;
	}
	simpleLog("INFO : drawCurves end");
}

//3d plot functionality
void drawGrid()
{
#ifdef NO_GRAPHICS
	return;
#endif

	glLineWidth(1.5);
	glEnable(GL_LINE_SMOOTH);
	glColor3f(0.0, 0.0, 1.0);
	glBegin(GL_LINES);

	if (NULL == models)
	{
		simpleLog("DEBUG : NULL models in drawgrid ... ");
		return;
	}

	if (0)
	{
		sprintf(buffer, "DEBUG : models->min[Z]  : %10.6f", models->min[Z]); simpleLog(buffer);
		sprintf(buffer, "DEBUG : models->max[Z]  : %10.6f", models->max[Z]); simpleLog(buffer);
		sprintf(buffer, "DEBUG : increment value : %10.6f", (models->max[Z] - models->min[Z]) / 10); simpleLog(buffer);

		sprintf(buffer, "models->max[0] %10.6f models->max[1] %10.6f", models->max[0], models->max[1]); simpleLog(buffer);
		sprintf(buffer, "models->max[0] %10.6f models->min[1] %10.6f", models->max[0], models->min[1]); simpleLog(buffer);
		sprintf(buffer, "models->min[0] %10.6f models->max[1] %10.6f", models->min[0], models->max[1]); simpleLog(buffer);
		sprintf(buffer, "models->min[0] %10.6f models->min[1] %10.6f", models->min[0], models->min[1]); simpleLog(buffer);
		sprintf(buffer, "models->max[0] %10.6f models->max[1] %10.6f", models->max[0], models->max[1]); simpleLog(buffer);
		sprintf(buffer, "models->min[0] %10.6f models->max[1] %10.6f", models->min[0], models->max[1]); simpleLog(buffer);
		sprintf(buffer, "models->max[0] %10.6f models->min[1] %10.6f", models->max[0], models->min[1]); simpleLog(buffer);
		sprintf(buffer, "models->min[0] %10.6f models->min[1] %10.6f", models->min[0], models->min[1]); simpleLog(buffer);
	}

	for (float i = models->min[Z]; i <= models->max[Z]; i += (models->max[Z] - models->min[Z]) / 10)
	{
		glVertex3f(models->max[0], models->max[1], i);
		glVertex3f(models->max[0], models->min[1], i);
		glVertex3f(models->min[0], models->max[1], i);
		glVertex3f(models->min[0], models->min[1], i);
		glVertex3f(models->max[0], models->max[1], i);
		glVertex3f(models->min[0], models->max[1], i);
		glVertex3f(models->max[0], models->min[1], i);
		glVertex3f(models->min[0], models->min[1], i);
	}
	glEnd();
}
int getSpecimenCoordinate(int x, int y, point_t* p, char* buf)
{
	// IT SEEMS THAT THIS FUNCTION CAN BE CALLED WITH A NULL buf pointer
	simpleLogBlankLine();
	simpleLog("getSpecimenCoordinate ... start");

	sprintf(buffer, "INFO : getSpecimenCoordinate input arguments[%d] [%d]", x, y);
	simpleLog(buffer);


	if (model_amount == 0)
	{
		simpleLog("IGNORE : getSpecimenCoordinate ... model _amount is 0 ... nothing to do");
		return -1;
	}
	if (NULL == p)
	{
		simpleLog("IGNORE : getSpecimenCoordinate ... NULL pointer for point_t");
		return -1;
	}



	show_mode_t oldModel = showModel;
	showModel = SPECIMEN;
	onDisplay();

	glPushMatrix();
	glRotatef(context[model_index].rotation[0], 1, 0, 0);
	glRotatef(context[model_index].rotation[1], 0, 1, 0);
	glRotatef(context[model_index].rotation[2], 0, 0, 1);
	glScalef(context[model_index].scale, context[model_index].scale, context[model_index].scale);
	glTranslatef(context[model_index].x, context[model_index].y, context[model_index].z);

	// 01 July 2020 investigating why anchors can not be dragged  ... discovered an item in the following function
	ogl_getObjCoordinate(x, y, &p->x, &p->y, &p->z, buf);

	sprintf(buffer, "INFO : result from ogl_getObjCoordinate  [%d] [%d] <%10.6f  %10.6f  %10.6f>", x, y, p->x, p->y, p->z);
	simpleLog(buffer);


	glPopMatrix();

	showModel = oldModel;
	onDisplay();
	simpleLog("getSpecimenCoordinate ... end");
	simpleLogBlankLine();
	return 0;
}

//deletes specimen with chosen id, currently not in use
int  specimen_del(int id)     // ANGLEA ... argument id is not used 
{
	if (NULL == models)
	{
		simpleLog("ERROR : attempt to delete a specimen and models is NULL");
		return  -1;
	}

	model_t* model = models;
	if (model == NULL)
	{
		// and how did this happen ??
		simpleLog("ERROR : attempt to delete a specimen and models is NULL");
		return -1;
	}

	FREE_WRAPPER((char*)model);
	model = NULL;

	// 14 July 2020 as a precaution and until this concept (delete a specimen - the only specimen)
	// we release the dots, anchors, and curves 
	curveReleaseArray();
	anchorReleaseList();
	dotReleaseList();


	//_CrtDumpMemoryLeaks();    // what is this ??
	return 0;
}

//checks to see if dot is within model parameters
int validateDot(point_t* p)
{
	int fail = 0;

	if (NULL == models)
	{
		simpleLog("ERROR : validatDot ... models is NULL");
		return -1;
	}

	if (NULL == p)
	{
		simpleLog("ERROR : validatDot ... point_t  argument is NULL");
		return -1;
	}

	if (1)
	{
		printf(" X :   min %10.6f  X %10.6f  max %10.6f\n", models->min[X], p->x, models->max[X]);
		printf(" Y :   min %10.6f  Y %10.6f  max %10.6f\n", models->min[Y], p->y, models->max[Y]);
		printf(" Z :   min %10.6f  Z %10.6f  max %10.6f\n", models->min[Z], p->z, models->max[Z]);
	}

	if (p->x < models->min[X]) { fail = 1; }
	if (p->x > models->max[X]) { fail = 1; }

	if (p->y < models->min[Y]) { fail = 1; }
	if (p->y > models->max[Y]) { fail = 1; }

	if (p->z < models->min[Z]) { fail = 1; }
	if (p->z > models->max[Z]) { fail = 1; }

	simpleLog("   dot validation data ...");
	if (1 == fail)
	{
		sprintf(buffer, "FAIL dot validation ...");
		simpleLog(buffer);
	}
	else
	{
		sprintf(buffer, "PASS  dot validation ...");
		simpleLog(buffer);
	}

	sprintf(buffer, " X : <  %10.6f  |  %10.6f  | %10.6f >", models->min[X], p->x, models->max[X]);
	simpleLog(buffer);
	sprintf(buffer, " Y : <  %10.6f  |  %10.6f  | %10.6f >", models->min[Y], p->y, models->max[Y]);
	simpleLog(buffer);
	sprintf(buffer, " Z : <  %10.6f  |  %10.6f  | %10.6f >", models->min[Z], p->z, models->max[Z]);
	simpleLog(buffer);

	if (1 == fail)
	{
		return -1;
	}
	if (0 == fail) { return  0; }
	return -1;
}

int tclSubCmdID(Tcl_Obj* const objv[], int num, const char* subCmd[], int id)
{
	for (int i = 1; i <= num; i++)
	{
		const char* cmd = Wrapper_GetStringFromObj(objv[i], NULL);
		if (strcmp(cmd, subCmd[i - 1]) != 0)
		{
			return 0;
		}
	}
	return id;
}

float calUnCoordinate(float value, int id, float* delta)
{
	if (delta[3] > 1.0) {
		return value * delta[3] + delta[id];
	}
	return value;
}
#define ANGLE_REDUCE(angle) while (angle > 360.0) angle -= 360.0; while (angle < -360.0) angle += 360.0
#ifdef STAND_ALONE_TOOL
int add(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[])
#else
TCL_CMD(add)
#endif
{
	int rv = -1;
	char messageBuffer[128];

	const char* shape = Wrapper_GetStringFromObj(objv[1], NULL); // returns shape argument parsed from R
	simpleLogBlankLine();
	simpleLog((const char*)"TCL_CMD_ADD");
	rv = TclIf_LogCommands(objc, objv);
	UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;



	// implement special handling for data logging commands 
	// simply do the indicated actions with out attempting to record them 
	// (at least the open file actions)  then simply return 
	if (strcmp(shape, "getCompileInformation") == 0)
	{
		sprintf(buffer, COMPILE_INFORMATION);
		simpleLog(buffer);
#ifdef CODE_FOR_LIBRARY 
		char* msg = ALLOCATE_WRAPPER(512);
		sprintf(msg, buffer);
		Tcl_SetResult(interp, msg, TCL_DYNAMIC);
#endif
		return TCL_OK;
	}
	else if (strcmp(shape, "queryFromR") == 0)
	{
		// 
		int whichQuery = -1;
		int whichQueryOption = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &whichQuery);
		Wrapper_GetIntFromObj(interp, objv[3], &whichQueryOption);
		sprintf(messageBuffer, "QUERY : Which query from R is [%d] and option is [%d]", whichQuery, whichQueryOption);
		simpleLog((const char*)messageBuffer);
		//
		//  This is something in work : R will have the ability to invoke this 
		//  code and receive back a text message. What these queries are  is still being designed.
		//
		sprintf(buffer, "CONCEPT UNDER CONSTRUCTION  query was [%d]", whichQuery);
		if (1 == whichQuery)
		{
			if (whichQueryOption <= 0)
			{
				sprintf(buffer, "QUERY : (1) invalid option value [%d]", whichQueryOption);
			}
			if (whichQueryOption > model_amount)
			{
				sprintf(buffer, "QUERY : (1) invalid option value [%d]", whichQueryOption);
			}
			int returnSize = -1;
			// returns the length of the dot linked list at the current slice
			// because R uses 1 based counting for specimens and 
			// the use of this option is for array indexing, we decrement by 1
			whichQueryOption--;
			returnSize = get_dot_size_for_slice_index(whichQueryOption);
			whichQueryOption++;
			sprintf(buffer, "QUERY : (1) dot slice length for slice [%d] is [%d]", whichQueryOption, returnSize);
		}
		if (2 == whichQuery)  // return just the integer to R
		{
			if (whichQueryOption <= 0)
			{
				sprintf(buffer, "QUERY : (2) invalid option value [%d]", whichQueryOption);
			}
			if (whichQueryOption > model_amount)
			{
				sprintf(buffer, "QUERY : (2) invalid option value [%d]", whichQueryOption);
			}
			int returnSize = -1;
			// returns the length of the dot linked list at the current slice
			// because R uses 1 based counting for specimens and 
			// the use of this option is for array indexing, we decrement by 1
			whichQueryOption--;
			returnSize = get_dot_size_for_slice_index(whichQueryOption);
			sprintf(buffer, "%d", returnSize);
		}


		if (3 == whichQuery)
		{
			if (whichQueryOption <= 0)
			{
				sprintf(buffer, "QUERY : (3) invalid option value [%d]", whichQueryOption);
			}
			if (whichQueryOption > model_amount)
			{
				sprintf(buffer, "QUERY : (3) invalid option value [%d]", whichQueryOption);
			}
			int returnSize = -1;
			// returns the length of the dot linked list at the current slice
			// because R uses 1 based counting for specimens and 
			// the use of this option is for array indexing, we decrement by 1
			whichQueryOption--;
			returnSize = get_anchor_size_for_slice_index(whichQueryOption);
			whichQueryOption++;
			sprintf(buffer, "QUERY : (3) anchor slice length for slice [%d] is [%d]", whichQueryOption, returnSize);
		}
		if (4 == whichQuery)  // return just the integer to R
		{
			if (whichQueryOption <= 0)
			{
				sprintf(buffer, "QUERY : (4) invalid option value [%d]", whichQueryOption);
			}
			if (whichQueryOption > model_amount)
			{
				sprintf(buffer, "QUERY : (4) invalid option value [%d]", whichQueryOption);
			}
			int returnSize = -1;
			// returns the length of the dot linked list at the current slice
			// because R uses 1 based counting for specimens and 
			// the use of this option is for array indexing, we decrement by 1
			whichQueryOption--;
			returnSize = get_anchor_size_for_slice_index(whichQueryOption);
			sprintf(buffer, "%d", returnSize);
		}






#ifdef CODE_FOR_LIBRARY 
		char* msg = ALLOCATE_WRAPPER(512);
		sprintf(msg, buffer);
		Tcl_SetResult(interp, msg, TCL_DYNAMIC);
#endif
		return TCL_OK;
	}
	else if (strcmp(shape, "messageFromR") == 0)
	{
		// This provides the capability to log a message string as sent from the R environment
		// If the log file has been opened, the message will be logged.
		// No other processing of the message is intended 
		const char* fn = Wrapper_GetStringFromObj(objv[2], NULL);
		sprintf(buffer, "R MESSAGE : <%s>", fn);
		simpleLog(buffer);
		return TCL_OK;
	}
	else if (strcmp(shape, "startRecording") == 0)
	{
		commandStream_OpenFile();
		return TCL_OK;
	}
	else if (strcmp(shape, "endRecording") == 0)
	{
		commandStream_CloseFile();
		return TCL_OK;
	}
	else if (strcmp(shape, "openLogFile") == 0)
	{
		int messageInteger;
		Wrapper_GetIntFromObj(interp, objv[2], &messageInteger);
		sprintf(messageBuffer, "ATTENTION : opening the log file with message [%d]", messageInteger);
		simpleLog_Open();
		simpleLog((const char*)messageBuffer);
		return TCL_OK;
	}
	else if (strcmp(shape, "closeLogFile") == 0)
	{
		int messageInteger;
		Wrapper_GetIntFromObj(interp, objv[2], &messageInteger);
		sprintf(messageBuffer, "ATTENTION : closing the log file with message [%d]", messageInteger);
		simpleLog((const char*)messageBuffer);
		simpleLog_Close();
		return TCL_OK;
	}
	else if (strcmp(shape, "Control_Tcl_Object_Logging") == 0)
	{
		GBL_ENABLE_TCL_OBJECT_LOGGING = 0;
		int flag = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &flag);
		if (1 == flag)
		{
			GBL_ENABLE_TCL_OBJECT_LOGGING = 1;
		}
	}
	else if (strcmp(shape, "logMessage") == 0)
	{
		int messageInteger = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &messageInteger);

		simpleLogBlankLine();
		sprintf(messageBuffer, "ATTENTION : LOG MESSAGE [%d]", messageInteger);
		simpleLog((const char*)messageBuffer);
		UT_MY_INTEGER_VALUE = -99;
		Wrapper_GetIntFromObj(interp, objv[3], &UT_MY_INTEGER_VALUE);   // this is for testing ONLY

		int stringSelector = -2;
		Wrapper_GetIntFromObj(interp, objv[4], &stringSelector);    // this is for testing ONLY

		// objv [2] : numeric value to be placed into the log file - not otherwise used
		// objv [3] : numeric value to be placed into the log file - and is used as the function return value
		// objv [4] : numeric value to be placed into the log file - and is used to select the return string , -1 means no string


		sprintf(messageBuffer, "ATTENTION : LOG MESSAGE ... secondary integer [%d]", UT_MY_INTEGER_VALUE);
		simpleLog((const char*)messageBuffer);
		sprintf(messageBuffer, "ATTENTION : LOG MESSAGE ... string selector [%d]", stringSelector);
		simpleLog((const char*)messageBuffer);
		simpleLogBlankLine();

		// 14 JULY 2020 : We are still having issues regarding what to return to R if something other than TCL_OK,
		// which is zero.
		// So as of this date here is how this function operates for testing
		// Argument 1 (nominally a negative integer for visual purposes within the log file):
		// This function returns the value of the second argument to R.
		// if the 3rd argument is other than 0 then the following string values are returned
		// through the TCL_RESULT mechanism.

		// So the minimal impact function call will provide the arguments for example :
		// logMessage, -17, 0, 0

		// 0:  there will be no return string
		// 1 : 'SUCCESS'
		// 2 : 'ERROR'
		// 3 : 'OK'
		// 4 : 'NO'
		// 5 : 'BAD'
		// 6 : 'INERT'
		// 7 : 'UNDER_CONSTRUCTION'
		// 8 : 'GOOD'

		// These return strings are selected for our testing only along with the return value - 
		// REMINDER : integer values 1, 2, 3, and 4 have special meaning to TCL/TK and the R / C interface 
		// traps these ... and this is why this function is revised for testing

		if (0 == stringSelector)
		{
			return UT_MY_INTEGER_VALUE;
		}
#ifdef CODE_FOR_LIBRARY
		if (1 == stringSelector)
		{
			char* msg = ALLOCATE_WRAPPER(512);
			sprintf(msg, "SUCCESS");
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);
			return UT_MY_INTEGER_VALUE;
		}
		if (2 == stringSelector)
		{
			char* msg = ALLOCATE_WRAPPER(512);
			sprintf(msg, "ERROR");
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);
			return UT_MY_INTEGER_VALUE;
		}
		if (3 == stringSelector)
		{
			char* msg = ALLOCATE_WRAPPER(512);
			sprintf(msg, "OK");
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);
			return UT_MY_INTEGER_VALUE;
		}
		if (4 == stringSelector)
		{
			char* msg = ALLOCATE_WRAPPER(512);
			sprintf(msg, "NO");
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);

			return UT_MY_INTEGER_VALUE;
		}
		if (5 == stringSelector)
		{
			char* msg = ALLOCATE_WRAPPER(512);
			sprintf(msg, "BAD");
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);
			return UT_MY_INTEGER_VALUE;
		}
		if (6 == stringSelector)
		{
			char* msg = ALLOCATE_WRAPPER(512);
			sprintf(msg, "INERT");
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);

			return UT_MY_INTEGER_VALUE;
		}
		if (7 == stringSelector)
		{
			char* msg = ALLOCATE_WRAPPER(512);
			sprintf(msg, "UNDER_CONSTRUCTION");
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);
			return UT_MY_INTEGER_VALUE;
		}
		if (8 == stringSelector)
		{
			char* msg = ALLOCATE_WRAPPER(512);
			sprintf(msg, "GOOD");
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);
			return UT_MY_INTEGER_VALUE;
		}
#endif

		simpleLog("WARNING : THIS SHOULD NOT APPEAR IN THE LOG FILE !");
		return TCL_OK;    // just for robustness ... we should not get here !
	}
	else if (strcmp(shape, "snapshot") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_UNDER_CONSTRUCTION;   //23 may 2020
		snapshot();  // This function is modified as desired bu the development team
		return TCL_OK;
	}
	else if (strcmp(shape, "initialize") == 0)    // allows capability from R to reset internal state
	{
		int initializeSelector = -1;
		int option = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &initializeSelector);
		Wrapper_GetIntFromObj(interp, objv[3], &option);
		sprintf(buffer, "INFO : Initialize state with selector [%d] and option [%d]", initializeSelector, option);
		simpleLog(buffer);
		initialize_state(initializeSelector, option);
	}
	else if (strcmp(shape, "invoke_draw_curves") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_UNDER_CONSTRUCTION; //23 may 2020
		drawCurves();
		return TCL_OK;
	}
	else if (strcmp(shape, "invoke_draw_dots") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_UNDER_CONSTRUCTION; //23 may 2020
		drawDots();
		return TCL_OK;
	}
	else if (strcmp(shape, "invoke_draw_grid") == 0)
	{
	    simpleLog("DEBUG : Invoke draw grid");

		UT_MY_INTEGER_VALUE = GBL_RTN_UNDER_CONSTRUCTION; //23 may 2020
		drawGrid();
		simpleLog("DEBUG : Invoke draw grid ... end");
		return TCL_OK;
	}
	else if (strcmp(shape, "invoke_draw_anchors") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_UNDER_CONSTRUCTION; //23 may 2020
		drawAnchors();
		return TCL_OK;
	}
	else if (strcmp(shape, "invoke_on_display") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_UNDER_CONSTRUCTION; //23 may 2020
		onDisplay();
		return TCL_OK;
	}
	else if (strcmp(shape, "invoke_draw_test") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_UNDER_CONSTRUCTION; //23 may 2020
		int rv = -1;
		rv = drawTest();
		if (0 != rv)
		{
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}
		return TCL_OK;
	}
	else if (strcmp(shape, "setLabelScaleFactor") == 0)
	{
		// 06 August 2020 - use of this feature has been made inert 
		// 
		simpleLog_Obj(objv[2]);   // multiplier
		simpleLog_Obj(objv[3]);   // additive

		double localsf_mpy = 1.0;
		double localsf_add = 0.0;
		Wrapper_GetDoubleFromObj(interp, objv[2], &localsf_mpy);
		Wrapper_GetDoubleFromObj(interp, objv[3], &localsf_add);

		GBL_INWORK_LABEL_SCALEFACTOR_MPY = (float)localsf_mpy;   // this is used as a multiplier !
		GBL_INWORK_LABEL_SCALEFACTOR_ADD = (float)localsf_add;   // this is used as a multiplier !
		sprintf(buffer, "development test LABEL (MPY) scale factor is <%10.6f>", (double)GBL_INWORK_LABEL_SCALEFACTOR_MPY);
		simpleLog(buffer);
		sprintf(buffer, "development test LABEL (ADD) scale factor is <%10.6f>", (double)GBL_INWORK_LABEL_SCALEFACTOR_ADD);
		simpleLog(buffer);
	}
	else if (strcmp(shape, "setCurveScaleFactor") == 0)
	{
		// 06 August 2020 - use of this feature has been made inert 
		//
		simpleLog_Obj(objv[2]); // multiplier
		simpleLog_Obj(objv[3]); // additive
		double localsf_mpy = 1.0;
		double localsf_add = 0.0;
		Wrapper_GetDoubleFromObj(interp, objv[2], &localsf_mpy);
		Wrapper_GetDoubleFromObj(interp, objv[3], &localsf_add);

		GBL_INWORK_CURVE_SCALEFACTOR_MPY = localsf_mpy;
		GBL_INWORK_CURVE_SCALEFACTOR_ADD = localsf_add;
		sprintf(buffer, "development test curve mpy scale factor is <%10.6f>", GBL_INWORK_CURVE_SCALEFACTOR_MPY);
		simpleLog(buffer);
		sprintf(buffer, "development test curve add scale factor is <%10.6f>", GBL_INWORK_CURVE_SCALEFACTOR_ADD);
		simpleLog(buffer);
	}
	else if (strcmp(shape, "UNIT_TEST_specimen") == 0)
	{
		// This option is NOT for operational use
		// It exists mainly in the stand alone open GL test package
		// 04 June 2020		
		simpleLog((const char*)"function add ... UNIT_TEST_specimen");
		simpleLog((const char*)"objects 2 and 3");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);

		int id = 0;
		Wrapper_GetIntFromObj(interp, objv[3], &id);
		if (NULL == models)
		{
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			simpleLog("NULL value for global item  'models' ");
		}
		else
		{
			float maxXY = 0;
			memset(models, 0, sizeof(model_t));
			const char* fn = Wrapper_GetStringFromObj(objv[2], NULL);
			if (0 != ut_test_ogl_loadModel(fn, models))
			{
				simpleLog("ERROR : failure from ogl_LoadModel");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			else
			{
				if (0)   // /made inert ... chose to not delete the code. it is NOT used
				{
					temp_index = id;
					memcpy(&deltas[temp_index], &(models->delta), sizeof(models->delta)); // lose deltas when switching specimens, so they are copied and saved

					maxXY = models->max[0] > models->max[1] ? models->max[0] : models->max[1];
					if (maxXY > 0.8)
					{
						dotRadius = 0.01f;
						anchorRadius = 0.01f;
					}
					else if (maxXY > 0.6)
					{
						dotRadius = 0.008f;
						anchorRadius = 0.008f;
					}
					else if (maxXY > 0.4)
					{
						dotRadius = 0.006f;
						anchorRadius = 0.006f;
					}
					else if (maxXY > 0.2)   // duplicate clause 23 May 2020  fixed
					{
						dotRadius = 0.004f;
						anchorRadius = 0.004f;
					}
					else if (maxXY > 0.1)
					{
						dotRadius = 0.002f;
						anchorRadius = 0.002f;
					}
					else if (maxXY > 0.08)
					{
						dotRadius = 0.001f;
						anchorRadius = 0.001f;
					}
					else if (maxXY <= 0.08)
					{
						dotRadius = 0.001f;
						anchorRadius = 0.001f;
					}

				}
				if (0 != resetContext(id, maxXY))
				{
					UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
					simpleLog("ERROR : negative return from resetContext");
				}

				if (0 != dot_slice_index(id))
				{
					UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
					simpleLog("ERROR : negative return from dot_slice_index");
				}

				if (0 != anchor_slice_index(id))
				{
					UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
					simpleLog("ERROR : negative return from anchor_slice_index");
				}
			}
		}
		simpleLog((const char*)"function add shape UNIT_TEST_specimen.. end");
	}
	else if (strcmp(shape, "specimen") == 0) // adds one specimen into memory
	{
		simpleLog("ADD/SPECIMEN");
		simpleLog((const char*)"function add ... shape specimen");
		simpleLog((const char*)"objects 2 and 3");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);

		int id = -1;
		Wrapper_GetIntFromObj(interp, objv[3], &id);
		id = id - 1; // convert 1 based in R to 0 based in C
		if (NULL == models)
		{
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			simpleLog("NULL value for global item  'models' ");
		}
		else
		{
			float maxXY = 0;
			memset(&models[id], 0, sizeof(model_t));
			const char* fn = Wrapper_GetStringFromObj(objv[2], NULL);
			sprintf(buffer, "INFO : add specimen for id [%d] and file name \n    <%s>", id, fn);
			simpleLog(buffer);

			models[id].thisModelIntegerCount = id;


			if (0 != ogl_loadModel(fn, &models[id]))
			{
				simpleLog("ERROR : failure from ogl_LoadModel");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			else
			{
				strncpy(models[id].fileName, fn, 254);
				simpleLogWriteModelToFile(&models[id]);

				temp_index = id;

				// 02 August 2020 NO LONGER true
				//memcpy(&deltas[temp_index], &(models->delta), sizeof(models->delta)); 
				// lose deltas when switching specimens, so they are copied and saved

				model_t* ptr = &models[id];
				deltas[temp_index][0] = ptr->delta[0];
				deltas[temp_index][1] = ptr->delta[1];
				deltas[temp_index][2] = ptr->delta[2];
				deltas[temp_index][3] = ptr->delta[3];



				maxXY = models[id].max[0] > models[id].max[1] ? models[id].max[0] : models[id].max[1];
				if (maxXY > 0.8)
				{
					dotRadius = 0.01f;
					anchorRadius = 0.01f;
				}
				else if (maxXY > 0.6)
				{
					dotRadius = 0.008f;
					anchorRadius = 0.008f;
				}
				else if (maxXY > 0.4)
				{
					dotRadius = 0.006f;
					anchorRadius = 0.006f;
				}
				else if (maxXY > 0.2)   // duplicate clause 23 May 2020  fixed
				{
					dotRadius = 0.004f;
					anchorRadius = 0.004f;
				}
				else if (maxXY > 0.1)
				{
					dotRadius = 0.002f;
					anchorRadius = 0.002f;
				}
				else if (maxXY > 0.08)
				{
					dotRadius = 0.001f;
					anchorRadius = 0.001f;
				}
				else if (maxXY <= 0.08)
				{
					dotRadius = 0.001f;
					anchorRadius = 0.001f;
				}
			}

			if (0 != resetContext(id, maxXY))
			{
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				simpleLog("ERROR : negative return from resetContext");
			}
			else
			{
				simpleLog("INFO : resetContext -OK-");
			}

			if (0 != dotSetArrayIndex(id))
			{
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				simpleLog("ERROR : negative return from dot_slice_index");
			}

			if (0 != anchorSetArrayIndex(id))
			{
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				simpleLog("ERROR : negative return from anchor_slice_index");
			}

			if (0 != curveSetArrayIndex(id))
			{
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				simpleLog("ERROR : negative return from curve_slice_index");
			}

		}
		simpleLog((const char*)"function add shape specimen ... end");
	}
	else if (strcmp(shape, "rawdot") == 0) // adds dot with raw coordinates based on the model's deltas (used for loading DGT)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"ADD / RAWDOT");
		simpleLog((const char*)"function add ... rawdot");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);

		if (model_amount <= 0)
		{
			sprintf(buffer, "INFO : model amount is [%d]", model_amount);
			simpleLog(buffer);
			simpleLog("ERROR : add rawdot ... model amount is non positive");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}
		else // model amount > 0 ... allocated 
		{
			// I will show this code ... i will forcibly set the slice index every time ! 

			dotSetArrayIndex(model_index);
			anchorSetArrayIndex(model_index);
			curveSetArrayIndex(model_index);


			int temp;
			temp = get_dot_slice_index();
			sprintf(buffer, "current dot slice id [%d]", temp);
			simpleLog(buffer);
			temp = dot_getListLengthAtCurrentSlice();
			sprintf(buffer, "INFO : building raw dot list : length is [%d]", temp);
			simpleLog(buffer);

			point_t p;
			Wrapper_GetDoubleFromObj(interp, objv[2], &p.x);
			Wrapper_GetDoubleFromObj(interp, objv[3], &p.y);
			Wrapper_GetDoubleFromObj(interp, objv[4], &p.z);

			sprintf(buffer, "input argument dot : <%f %f %f>", (float)p.x, (float)p.y, (float)p.z);

			simpleLog(buffer);

			p.x = ogl_calCoordinate(p.x, 0, deltas[temp_index]);
			p.y = ogl_calCoordinate(p.y, 1, deltas[temp_index]);
			p.z = ogl_calCoordinate(p.z, 2, deltas[temp_index]);

			if (0 != validateDot(&p))  // quit on error ... even if processing for GUI is not complete
			{
				simpleLog("ERROR : function add rawdot ... invalid dot");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				sprintf(buffer, "ERROR: cannot add dot at %f %f %f", p.x, p.y, p.z);
				simpleLog(buffer);
			}
			sprintf(buffer, "  modified dot : <%f %f %f>", (float)p.x, (float)p.y, (float)p.z);
			simpleLog(buffer);
			color_t c = defaultDotColor; ///  { -1.0, -1.0, -1.0 };
			if (0 != dot_add(&p, &c)) // with newly calculated coordinates, adds dot into memory
			{
				simpleLog("ERROR : function add rawdot ... negative size from dot_add");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}

		}
		simpleLog((const char*)"function add rawdot ... end");
	}
	else if (strcmp(shape, "rawdot_NO_ADJUSTMENT") == 0) // adds dot with raw coordinates form a UNIT TEST PROGRAM)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_UNDER_CONSTRUCTION;   // this is NOT for operational use
		simpleLog((const char*)"function add ... rawdot NO ADJUSTMENT ");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);

		if (model_amount <= 0)
		{
			sprintf(buffer, "INFO : model amount is [%d]", model_amount);
			simpleLog(buffer);
			simpleLog("ERROR : add rawdot ... model amount is non positive");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}
		else // model amount > 0 ... allocated 
		{
			int temp;
			temp = get_dot_slice_index();
			sprintf(buffer, "current dot slice id [%d]", temp);
			simpleLog(buffer);
			temp = dot_getListLengthAtCurrentSlice();
			sprintf(buffer, "INFO : building raw dot list : length is [%d]", temp);
			simpleLog(buffer);

			point_t p;
			Wrapper_GetDoubleFromObj(interp, objv[2], &p.x);
			Wrapper_GetDoubleFromObj(interp, objv[3], &p.y);
			Wrapper_GetDoubleFromObj(interp, objv[4], &p.z);

			sprintf(buffer, "  input argument dot (landmark) : <%f %f %f>", (float)p.x, (float)p.y, (float)p.z);
			simpleLog(buffer);

			///   NO COORDINATE ADJUSTMENT



			// NO DOT VALIDATION 

			sprintf(buffer, "  modified dot : <%f %f %f>", (float)p.x, (float)p.y, (float)p.z);
			simpleLog(buffer);
			color_t c = defaultDotColor; ///  { -1.0, -1.0, -1.0 };
			if (0 != dot_add(&p, &c)) // with newly calculated coordinates, adds dot into memory
			{
				simpleLog("ERROR : function add rawdot ... negative size from dot_add");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}

		}
		simpleLog((const char*)"function add rawdot NO_ADJUSTMEND ... end");
	}
	else if (strcmp(shape, "rawanchor") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"ADD / RAW ANCHOR");
		simpleLog((const char*)"function add ... shape rawanchor");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		if (model_amount == 0)
		{
			simpleLog("ERROR : add rawanchor ... model amount is non positive");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}
		else // model amount > 0 ... allocated 
		{
			// I will show this code ... i will forcibly set the slice index every time ! 
			dotSetArrayIndex(model_index);
			anchorSetArrayIndex(model_index);
			curveSetArrayIndex(model_index);




			int temp;
			temp = get_anchor_slice_index();
			sprintf(buffer, "INFO : current anchor slice id [%d]", temp);
			simpleLog(buffer);

			temp = anchor_getListLengthAtCurrentSlice();
			sprintf(buffer, "INFO : building raw anchor list : length is [%d]", temp);
			simpleLog(buffer);

			point_t p;
			Wrapper_GetDoubleFromObj(interp, objv[2], &p.x);
			Wrapper_GetDoubleFromObj(interp, objv[3], &p.y);
			Wrapper_GetDoubleFromObj(interp, objv[4], &p.z);

			sprintf(buffer, "input argument dot (anchor) : <%f %f %f>", (float)p.x, (float)p.y, (float)p.z);
			simpleLog(buffer);

			p.x = ogl_calCoordinate(p.x, 0, deltas[temp_index]);
			p.y = ogl_calCoordinate(p.y, 1, deltas[temp_index]);
			p.z = ogl_calCoordinate(p.z, 2, deltas[temp_index]);

			if (0 != validateDot(&p)) // quit on error .. .even if processing for GUI is not complete
			{
				simpleLog("ERROR : function add rawanchor ... invalid dot");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				sprintf(buffer, "ERROR: cannot add dot at %f %f %f", p.x, p.y, p.z);
				simpleLog(buffer);
				anchorPlaced = 0;
			}
			else
			{
				color_t c = defaultAnchorColor; // { -1.0, -1.0, -1.0 };

				if (0 != anchor_add(&p, &c))
				{
					simpleLog("ERROR : function add rawanchor ... negative size from dot_add");
					anchorPlaced = 0;
				}
				else
				{
					anchorPlaced = 1;
				}
			}
		}
		simpleLog((const char*)"function add rawanchor ... end");
	}
	else if (strcmp(shape, "dot") == 0) // adds dot using ogl coords, called whenever user places landmarks using mouse
	{
		simpleLogBlankLine();
		simpleLog((const char*)"ADD/SHAPE/DOT");
		simpleLog((const char*)"function add ... shape dot ... ADD/SHAPE/DOT");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);

		point_t p;
		Wrapper_GetDoubleFromObj(interp, objv[2], &p.x);
		Wrapper_GetDoubleFromObj(interp, objv[3], &p.y);
		Wrapper_GetDoubleFromObj(interp, objv[4], &p.z);

		sprintf(buffer, "INFO : Dot (landmark) point coordinates <%f ... %f ... %f", p.x, p.y, p.z);
		simpleLog(buffer);

		if (0 != validateDot(&p))  // quit on error ... even if processing for GUI is not complete
		{
			simpleLog("WARNING : function add dot ... invalid dot");
			sprintf(buffer, "WARNING : cannot add dot at %f %f %f", p.x, p.y, p.z);
			simpleLog(buffer);
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;


#ifdef CODE_FOR_LIBRARY 
			char* msg = ALLOCATE_WRAPPER(512);
			sprintf(msg, buffer);
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);
			return TCL_OK; /// TCL_ERROR;
#endif
		}
		else
		{

			sprintf(buffer, "INFO : selected dot index [%d]", dotGetSelectedIndex());
			simpleLog(buffer);
			color_t c = defaultDotColor; ////  { -1.0, -1.0, -1.0 };
			if (0 != dot_add(&p, &c))
			{
				simpleLog("ERROR : function add dot ... negative return from dot_add");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			sprintf(buffer, "INFO : dot size at selected dot index [%d]", dot_size());
			simpleLog(buffer);
		}



		simpleLog((const char*)"function add dot ... end");
	}
	else if (strcmp(shape, "anchor") == 0)
	{
		simpleLogBlankLine();
		simpleLog((const char*)"ADD/SHAPE/ANCHOR");
		simpleLog((const char*)"function add ... shape anchor");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		point_t p;
		Wrapper_GetDoubleFromObj(interp, objv[2], &p.x);
		Wrapper_GetDoubleFromObj(interp, objv[3], &p.y);
		Wrapper_GetDoubleFromObj(interp, objv[4], &p.z);
		sprintf(buffer, "INFO : Anchor point coordinates <%f ... %f ... %f", p.x, p.y, p.z);
		simpleLog(buffer);


		if (0 != validateDot(&p))  // quit on error ... even if processing for GUI is not complete
		{
			simpleLog("WARNING : function add anchor ... invalid dot");
			sprintf(buffer, "WARNING : cannot add (anchor) dot at %f %f %f", p.x, p.y, p.z);
			simpleLog(buffer);
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			anchorPlaced = 0;
			return TCL_OK; // TCL_ERROR;
		}
		else
		{
			sprintf(buffer, "INFO : selected anchor  index [%d]", get_anchor_slice_index());
			simpleLog(buffer);

			color_t c = defaultAnchorColor;  ///{ -1.0, -1.0, -1.0 };
			if (0 != anchor_add(&p, &c))
			{
				simpleLog("ERROR : function add anchor ... negative size from anchor_add");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				anchorPlaced = 0;
			}
			else
			{
				anchorPlaced = 1;
			}
			sprintf(buffer, "INFO : anchor (dot) size at selected dot index [%d]", anchor_size());
			simpleLog(buffer);
		}
		simpleLog((const char*)"function add ... shape anchor end");
	}
	else if (strcmp(shape, "downsample") == 0) // adds surface sliders into memory
	{
		// NOTE TO DAVE : there is a defect in logging the tcl objects for this situation : 
		// specifically what the object union fields are for a list !


		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLogBlankLine();
		simpleLog("ADD/DOWNSAMPLE");
		simpleLog((const char*)"function add ... shape downsample");
		simpleLog((const char*)"objects 2, 3 and 4");
		simpleLog_Obj(objv[2]);    // from R this will be 'vertToDownsample'  ... and extended list ??
		simpleLog_Obj(objv[3]);    // from R this is the current image id which is 1 based in R 
		simpleLog_Obj(objv[4]);
		int id = -1;;
		Wrapper_GetIntFromObj(interp, objv[3], &id);
		id = id - 1;
		sprintf(buffer, "add downsample function for image (0 based) id [%d]", id);
		simpleLog(buffer);
		int vLength = -1;
		Wrapper_GetIntFromObj(interp, objv[4], &vLength);
		sprintf(buffer, "add downsample function  vector length from R [%d]", vLength);
		simpleLog(buffer);


		unsigned int listc = 0;
		Tcl_Obj** listv;


		// here I am interested in the list length variable whihc populates listc
		if (TCL_OK != Tcl_ListObjGetElements(interp, objv[2], &listc, &listv))
		{
			sprintf(buffer, "ERROR : listc is [%u]", (unsigned int)listc);
			simpleLog(buffer);
			simpleLog("ERROR : function add downsample ... not valid list ... could not extract the data");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			onDisplay();
			return TCL_OK;
		}
		sprintf(buffer, "INFO : listc is [%d]", (int)listc);
		simpleLog(buffer);

		if (0 == listc)
		{
			simpleLog("ERROR : downsample ... empty list");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			onDisplay();
			return TCL_OK;
		}



		// discovered ...this is the condition when the R gui operator switches tabs to the surface tab
		// and R calls this TCL_IF function with no real data. There is nothing to do. 
		// Especially do not allocate memory !
		if (1 == (unsigned int)listc)
		{
			simpleLog("INFO : inert call to tcl_if / add / downsample : just an R gui tab change ? Nothing to do.");
			onDisplay();
			return TCL_OK;
		}

		double* flattenedVertices = NULL;

		if (GBL_RTN_SUCCESS == UT_MY_INTEGER_VALUE)
		{
			flattenedVertices = (double*)malloc(listc * sizeof(double));
			if (NULL == flattenedVertices)
			{
				simpleLog("ERROR : NULL pointer from malloc for flattened vertices");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			else
			{
				sprintf(buffer, "INFO : allocated flattenedVertices of size [%d] doubles", listc);
				simpleLog(buffer);
			}
		}


		if (TCL_OK != Tcl_ListObjGetElements(interp, objv[2], &listc, &listv))
		{
			sprintf(buffer, "ERROR : listc is [%u]", (unsigned int)listc);
			simpleLog(buffer);
			simpleLog("ERROR : function add downsample ... not valid list ... could not extract the data");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			free(flattenedVertices);
			flattenedVertices = NULL;
		}
		else
		{
			// step two of two step process of getting the list elements 
			for (int ii = 0; ii < (int)listc; ii++)
			{
				if (TCL_OK != Tcl_GetDoubleFromObj(interp, listv[ii], &flattenedVertices[ii]))
				{
					UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				}
			}
		}

		if (GBL_RTN_SUCCESS == UT_MY_INTEGER_VALUE)
		{


			sprintf(buffer, "Sample of flattedVertices : tcl_if add downsample ");
			simpleLog(buffer);
			int j = 0;
			sprintf(buffer, "%10.6f  %10.6f  %10.6f", flattenedVertices[j], flattenedVertices[j + 1], flattenedVertices[j + 2]);
			simpleLog(buffer);
			j = 3;
			sprintf(buffer, "%10.6f  %10.6f  %10.6f", flattenedVertices[j], flattenedVertices[j + 1], flattenedVertices[j + 2]);
			simpleLog(buffer);
			simpleLogBlankLine();
		}

		// development and debug code ONLY : Write the downsampled vertices and other data to a local flat 
		// file for use in the stand alone tool.
		// The downsampled vertex data is coupled tightly with the specimen ply file and the 
		// landmarks / anchors ! 
		if (GBL_RTN_SUCCESS == UT_MY_INTEGER_VALUE)
		{
			//10 August 2020 turned off code to write the downsamples to a simple flat file
			FILE* dsFile = NULL;
			time_t NOW;
			time(&NOW);
			sprintf(buffer, "./DATA_LOG_FILES/a1_1_ds_%u.txt", (unsigned int)NOW);
			//sprintf(buffer, "C:/home/0_GuiMorph_IO_FILES/OUTPUT_FILES/a1_1_ds_%u.txt", (unsigned int)NOW);
			///dsFile = fopen(buffer, "w");
			if (NULL == dsFile)
			{
				simpleLog("FAIL : did not open temp file for downsamples");
			}
			else
			{
				simpleLogBlankLine();
				simpleLog("DEBUG : TCL_IF_FLATTENED VERTICES");
				sprintf(buffer, "variable listc");
				///fprintf(dsFile, "%s\n", buffer);
				simpleLog(buffer);
				sprintf(buffer, "%d", listc);
				///fprintf(dsFile, "%s\n", buffer); 
				simpleLog(buffer);
				sprintf(buffer, "variable vLength");
				///fprintf(dsFile, "%s\n", buffer); 
				simpleLog(buffer);
				sprintf(buffer, "%d", vLength);
				///fprintf(dsFile, "%s\n", buffer); 
				simpleLog(buffer);

				for (int jj = 0; jj < (int)listc; jj += 3)
				{
					sprintf(buffer, "%4d  %10.6f %10.6f  %10.6f", jj, flattenedVertices[jj + 0], flattenedVertices[jj + 1], flattenedVertices[jj + 2]);
					///fprintf(dsFile, "%s\n", buffer);
					simpleLog(buffer);
				}
				///fprintf(dsFile, "DATA_COMPLETE\n");
				simpleLog("DATA_COMPLETE");
				simpleLogBlankLine();
				///fclose(dsFile);
			}

		}







		if (GBL_RTN_SUCCESS == UT_MY_INTEGER_VALUE)
		{
			simpleLog("INFO : attempting to load downsample model");

			int rv = -1;
			rv = ogl_loadDownSampleModel(flattenedVertices, listc, models);
			if (0 != rv)
			{
				simpleLog("ERROR : fail return from ogl_loadDownSampleModel");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				sprintf(buffer, "ERROR : model data :  dsVertex size is [%u] ", (unsigned int)models->dsVertexSize);
				simpleLog(buffer);
				sprintf(buffer, "ERROR : models->dsVertex is %s", (NULL == models->dsVertex) ? "NULL  -ERROR-" : "not  NULL -OK-");
				simpleLog(buffer);
				downsampled = 0;
			}
			else
			{
				simpleLog("SUCCESS : ?? did I actually load the downsampled model ??");
				sprintf(buffer, "INFO : model data :  dsVertex size is [%u] ", (unsigned int)models->dsVertexSize);
				simpleLog(buffer);
				sprintf(buffer, "INFO : models->dsVertex is %s", (NULL == models->dsVertex) ? "NULL  -ERROR-" : "not  NULL -OK-");
				downsampled = 1;
			}
		}

		// I think this is where I can release the malloced flattened vertice data ....
		if (NULL != flattenedVertices)
		{
			free(flattenedVertices);
			flattenedVertices = NULL;
		}
		simpleLog((const char*)"function add downsample ... end");
	}
	else if (strcmp(shape, "EraseDownSampleData") == 0) //  erase downsample data from specified model
	{
		// 11 AUGUST 2020 UNDER CONSTRUCTION - EXECUTION AS IS CRASHES THE GUI 
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLogBlankLine();
		simpleLog("ADD/ERASE DOWNSAMPLE");
		simpleLog((const char*)"function add ... shape Erase down sample");
		simpleLog((const char*)"objects 2, 3 and 4");
		simpleLog_Obj(objv[2]);    // from R this is the specified image id which is 1 based in R
		// does NOT need to be the 'current displayed image' although the useage in R might make this so.

		simpleLog_Obj(objv[3]);    // not used
		simpleLog_Obj(objv[4]);    // not used
		int id = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &id);
		id = id - 1;
		sprintf(buffer, "INFO : erase downsample data function for image (0 based) id [%d]", id);
		simpleLog(buffer);

		ogl_eraseDownSampleDataForModel(&models[id]);   // could return a -1 indicating null pointer but I ignore it now

		simpleLog((const char*)"function shape Erase down sample ... end");
	}
	else if (strcmp(shape, "EraseVertexData") == 0) //  erase vertex data for the specified model
	{
		// 11 AUGUST 2020 UNDER CONSTRUCTION - EXECUTION AS IS CRASHES THE GUI 
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLogBlankLine();
		simpleLog("ADD/ERASE VERTEX");
		simpleLog((const char*)"function add ... shape Erase Vertex Data");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);    // from R this is the specified image id which is 1 based in R
		// does NOT need to be the 'current displayed image' although the useage in R might make this so.

		//simpleLog_Obj(objv[3]);    // not used
		//simpleLog_Obj(objv[4]);    // not used
		int id = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &id);
		id = id - 1;
		sprintf(buffer, "INFO : erase vertex data for image (0 based) id [%d]", id);
		simpleLog(buffer);
		// As of 11 August 2020 we ONLY erase the vertex, normal and color data. 
		// there are additional functions for releasing other malloced memory items (down sample data)

		ogl_eraseVertexDataForModel(&models[id]);   // could return a -1 indicating null pointer but I ignore it now

		simpleLog((const char*)"function add shape Erase Vertex Data ... end");
	}
	else if (strcmp(shape, "LoadLandmarksFromFile") == 0) // used for load landmark feature
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"LANDMARK");
		simpleLog((const char*)"function add ... shape LoadLandmarksFromFile");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);

		int id = -1;
		int amount = -1;
		char* ptrToFileName = NULL;
		/*   THIS IS A CHANGE TO THE INTERFACE !   MAKE SURE R IS CHANGED !
				Wrapper_GetIntFromObj(interp, objv[2], &id);
				Wrapper_GetIntFromObj(interp, objv[3], &amount);
				ptrToFileName = (char*)Wrapper_GetStringFromObj(objv[4], NULL);
		*/
		Wrapper_GetIntFromObj(interp, objv[3], &id);
		Wrapper_GetIntFromObj(interp, objv[4], &amount);
		ptrToFileName = (char*)Wrapper_GetStringFromObj(objv[2], NULL);
		int rv = -1;
		// 04 June 2020 This function is under construction
		// need to save a landmark file from the R environment ... 
		//
		//rv = ogl_loadLandMark(ptrToFileName, models, id, amount, (float**)deltas);



		rv = unit_test_ogl_loadLandmark(ptrToFileName);
		if (0 != rv)
		{
			simpleLog("ERROR : ogl load landmark failed");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}
		simpleLog((const char*)"function add ... shape LoadLandmarksFromFile ... end");
	}
	else if (strcmp(shape, "LoadCurvesFromFile") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"loadCurvesFrmFile");
		simpleLog((const char*)"function add ... shape LoadCurvesFromFile");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		int what_1 = -1;
		int what_2 = -1;
		char* ptrToFileName = NULL;
		Wrapper_GetIntFromObj(interp, objv[3], &what_1);
		Wrapper_GetIntFromObj(interp, objv[4], &what_2);
		ptrToFileName = (char*)Wrapper_GetStringFromObj(objv[2], NULL);
		int rv = -1;
		rv = unit_test_ogl_loadCurve(ptrToFileName);
		if (0 != rv)
		{
			simpleLog("ERROR : ogl load cruve from file failes");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}
		simpleLog((const char*)"function add ... shape LoadCurvesFromFile ... end ");
	}
	else if (strcmp(shape, "InfoLandmarks") == 0)  // tells me the size of the landmarks information from R
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"function add ... shape InfoLandmarks");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		int lmRows = -1;
		int lmCols = -1;
		int numberOfSpecimens = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &lmRows);
		Wrapper_GetIntFromObj(interp, objv[3], &lmCols);
		Wrapper_GetIntFromObj(interp, objv[4], &numberOfSpecimens);
		sprintf(buffer, "INFO : landmark information :  rows [%d]   colums  [%d] nSpecimens [%d]",
			lmRows, lmCols, numberOfSpecimens);
		simpleLog(buffer);
		simpleLog((const char*)"function add ... shape InfoLandmarks end");
	}
	else if (strcmp(shape, "InfoAnchors") == 0)  // tells me the size of the anchor information from R
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"function add ... shape InfoAnchors");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		int anchorRows = -1;
		int anchorCols = -1;
		int numberOfSpecimens = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &anchorRows);
		Wrapper_GetIntFromObj(interp, objv[3], &anchorCols);
		Wrapper_GetIntFromObj(interp, objv[4], &numberOfSpecimens);
		sprintf(buffer, "INFO : anchor information :  rows [%d]   colums  [%d] nSpecimens [%d]",
			anchorRows, anchorCols, numberOfSpecimens);
		simpleLog(buffer);
		simpleLog((const char*)"function add ... shape InfoAnchors end");
	}
	else if (strcmp(shape, "SetLandmarkIndex") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"function add ... shape SetLandmarkIndex");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);
		int specifiedIndex = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &specifiedIndex);
		// The code in the R environment is 1 based whilst this C code is 0 based
		// as is traditional in C 
		specifiedIndex = specifiedIndex - 1;
		const int allocatedSlices = get_dot_slice_amount();
		// test requested index. example : vaild indexes are 0 or 1 for slice allocation of 2

		if (specifiedIndex < 0)
		{
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			sprintf(buffer, "ERROR : selected index of [%d] must be non negative", specifiedIndex);
			simpleLog(buffer);
		}
		if (specifiedIndex >= allocatedSlices)
		{
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			sprintf(buffer, "ERROR : selected index of [%d] exceeds allocation of [%d]", specifiedIndex, allocatedSlices);
			simpleLog(buffer);
		}
		if (GBL_RTN_SUCCESS == UT_MY_INTEGER_VALUE)
		{
			sprintf(buffer, "DEBUG : specifiedIndex for landmarks is [%d]", specifiedIndex);
			simpleLog(buffer);
			sprintf(buffer, "DEBUG : allocatedSlices for landmarks is [%d]", allocatedSlices);
			simpleLog(buffer);
			dotSetArrayIndex(specifiedIndex);
		}
		simpleLog((const char*)"function add ... shape SetLandmarkIndex ... end");
	}
	else if (strcmp(shape, "SetAnchorIndex") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"function add ... shape SetAnchorIndex");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);
		int specifiedIndex = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &specifiedIndex);
		// The code in the R environment is 1 based whilst this C code is 0 based
		// as is traditional in C 
		specifiedIndex = specifiedIndex - 1;
		const int allocatedSlices = get_anchor_slice_amount();

		// test requested index. example : vaild indexes are 0 or 1 for slice allocation of 2
		if (specifiedIndex < 0)
		{
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			sprintf(buffer, "ERROR : selected index of [%d] must be non negative", specifiedIndex);
			simpleLog(buffer);
		}
		if (specifiedIndex >= allocatedSlices)
		{
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			sprintf(buffer, "ERROR : selected index of [%d] exceeds allocation of [%d]", specifiedIndex, allocatedSlices);
			simpleLog(buffer);
		}

		if (GBL_RTN_SUCCESS == UT_MY_INTEGER_VALUE)
		{
			sprintf(buffer, "DEBUG : specifiedIndex for anchors is    [%d]", specifiedIndex);
			simpleLog(buffer);
			sprintf(buffer, "DEBUG : allocatedSlices for anchors is   [%d]", allocatedSlices);
			simpleLog(buffer);
			anchorSetArrayIndex(specifiedIndex);
			sprintf(buffer, "DEBUG : Verify anchor slice index is set [%d]", get_anchor_slice_index());
			simpleLog(buffer);
		}
		simpleLog((const char*)"function add ... shape SetAnchorIndex ... end");
	}
	else if (strcmp(shape, "SetCurveIndex") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"function add ... shape SetCurveIndex");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);
		int whichCurve = -1;

		Wrapper_GetIntFromObj(interp, objv[2], &whichCurve);
		whichCurve = whichCurve - 1;   //adjust 1 based to zero based
		int rv = -1;
		rv = set_curve_slice_index(whichCurve);
		if (0 != rv)
		{
			sprintf(buffer, "ERROR : fail to set curve index to [%d]", whichCurve);
			simpleLog(buffer);
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}
		simpleLog((const char*)"function add ... shape SetCurveIndex ... end");
	}
	else if (strcmp(shape, "InfoLandmarks_complete") == 0)
	{
		simpleLog((const char*)"function add ... InfoLandmarks_complete");
		simpleLog((const char*)"function add ... InfoLandmarks_complete ... end");
	}
	else if (strcmp(shape, "InfoAnchors_complete") == 0)
	{
		simpleLog((const char*)"function add ... InfoAnchors_complete");
		simpleLog((const char*)"function add ... InfoAnchors_complete ... end");
	}
	else if (strcmp(shape, "InfoCurves_complete") == 0)
	{
		simpleLog((const char*)"function add ... InfoCurves_complete");
		simpleLog((const char*)"function add ... InfoCurves_complete ... end");
	}
	else if (strcmp(shape, "InfoCurves") == 0)  // tells me the size of the curve information from R
	{
		//simpleLog("UNDER CONSTRUCTION");

		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"function add ... shape InfoCurves");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		int numberOfCurves = -1;
		int curveLength = -1;
		int numberOfSpecimens = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &numberOfCurves);
		Wrapper_GetIntFromObj(interp, objv[3], &curveLength);
		Wrapper_GetIntFromObj(interp, objv[4], &numberOfSpecimens);

		sprintf(buffer,
			"INFO : curve data : number of curves [%d] curve length [%d] number of specimens [%d]",
			numberOfCurves, curveLength, numberOfSpecimens);
		simpleLog(buffer);
		int rv = -1;

		rv = curveAllocateArray(numberOfSpecimens);
		if (0 != rv)
		{
			sprintf(buffer, "ERROR : failed to allocate curves ... num curves requested [%d]", numberOfSpecimens);
			simpleLog(buffer);
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}


		// NOTE : at this time we have created a vector of pointers to curves
		// which is the variable 'curves'
		// each element of the vector is NULL ...
		// thus, all the code which follows operates on the vector which is 
		// still empty !

		curve_t** temp = getPointerToCurveVector();
		if (NULL == temp)
		{
			sprintf(buffer, "ERROR : failed to get handle to curves vector");
			simpleLog(buffer);
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}

		for (int ii = 0; ii < numberOfSpecimens; ii++)
		{
			int rv = -1;
			curve_t* tc = NULL;
			rv = set_curve_slice_index(ii);
			if (0 != rv)
			{
				sprintf(buffer, "ERROR : did not set curve slice index to [%d]", ii);
				simpleLog(buffer);
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			// the curve vector has been created but each element in the vector points to NULL
		}
		simpleLog((const char*)"function add ... shape InfoCurves end");
	}
	else if (strcmp(shape, "curve") == 0) // adds dots to curve structure
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"ADD / CURVE / POINTS");
		simpleLog((const char*)"function add ... shape curve");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		int beg = -1;
		int mid = -1;
		int end = -1;;
		Wrapper_GetIntFromObj(interp, objv[2], &beg);
		Wrapper_GetIntFromObj(interp, objv[3], &mid);
		Wrapper_GetIntFromObj(interp, objv[4], &end);
		int whichCurve = -1;
		sprintf(buffer, " { zero based values beg[%d]  mid [%d] end [%d]", beg, mid, end);
		simpleLog(buffer);
		//beg++; mid++; end++;   // adjust    maybe NO 
		//sprintf(buffer, " { one  based values beg[%d]  mid [%d] end [%d]", beg, mid, end);
		//simpleLog(buffer);
		sprintf(buffer, "model_amount  [%d]", model_amount);
		simpleLog(buffer);

		if (model_amount <= 0)
		{
			sprintf(buffer, "add curve ... model_amount not positive ... [%d]", model_amount);
			simpleLog(buffer);
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}
		else
		{
			if (GBL_RTN_SUCCESS == UT_MY_INTEGER_VALUE)
			{
				// changes 29 July 2020 : Recompute curves each time GUI changes 
				// to the curves tab  per Eriks request. 
				// do we need to assign to each slice since only 1 specimen is shown at any one 
				// time ? 
				int whichCurve = -1;
				int s1 = -1;
				for (int cc = 0; cc < model_amount; cc++)
				{
					sprintf(buffer, "DEBUG : Processing curve points for slice [%d]", cc);
					simpleLog(buffer);

					curveSetArrayIndex(cc);
					whichCurve = -1;
					whichCurve = get_curve_slice_id();
					if (whichCurve != cc)
					{
						sprintf(buffer, "ERROR : curve array index not set correctly");
						simpleLog(buffer);
					}


					dotSetArrayIndex(whichCurve);  // set to specified  slice
					s1 = -1;
					s1 = get_dot_slice_index();
					if (s1 != cc)
					{
						sprintf(buffer, "ERROR : dot (landmark)  array index not set correctly");
						simpleLog(buffer);
					}




					dot_t* beginningDot = NULL;
					dot_t* middleDot = NULL;
					dot_t* endingDot = NULL;
					// yes I remember ... I need to check for NULL !
					beginningDot = get_dot_at_index_current_slice(beg);
					middleDot = get_dot_at_index_current_slice(mid);
					endingDot = get_dot_at_index_current_slice(end);

					int rv;
					sprintf(buffer, "calling curve_addDot ...  [%d]", whichCurve);
					simpleLog(buffer);

					rv = curve_addDot(whichCurve, beginningDot);
					sprintf(buffer, "rv from call to curve_addDot (beginning dot) [%d]", rv);
					simpleLog(buffer);
					if (0 != rv)
					{
						UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
					}

					rv = curve_addDot(whichCurve, middleDot);
					sprintf(buffer, "rv from call to curve_addDot (middle dot)[%d]", rv);
					simpleLog(buffer);
					if (0 != rv)
					{
						UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
					}

					rv = curve_addDot(whichCurve, endingDot);
					sprintf(buffer, "rv from call to curve_addDot (ending dot)[%d]", rv);
					simpleLog(buffer);
					if (0 != rv)
					{
						UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
					}


					// this is retained for development. There could certainly be more 
					// than 3 curves. If this is so and the need to expand this arises
					// this code is easily extended
					if (0 == whichCurve)
					{
						GBL_PTR_CURVE_1 = get_curveAtIndex(0);
						simpleLogWriteCurveToFile(GBL_PTR_CURVE_1);
					}
					if (1 == whichCurve)
					{
						GBL_PTR_CURVE_2 = get_curveAtIndex(1);
						simpleLogWriteCurveToFile(GBL_PTR_CURVE_2);
					}
					if (3 == whichCurve)
					{
						GBL_PTR_CURVE_2 = get_curveAtIndex(2);
						simpleLogWriteCurveToFile(GBL_PTR_CURVE_3);
					}
				}
			}
		}

		if (NULL != GBL_PTR_CURVE_1)
		{
			simpleLogWriteCurveToFile(GBL_PTR_CURVE_1);
		}
		if (NULL != GBL_PTR_CURVE_2)
		{
			simpleLogWriteCurveToFile(GBL_PTR_CURVE_2);
		}
		if (NULL != GBL_PTR_CURVE_3)
		{
			simpleLogWriteCurveToFile(GBL_PTR_CURVE_3);
		}
		simpleLog((const char*)"function add curve");
	}
	else if (strcmp(shape, "setNewLandmarkCount") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"function add ... shape setNewLandmarkCount");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);
		int howMany = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &howMany);
		if (howMany > 0)
		{
			GBL_SET_NUMBER_OF_LANDMARKS = howMany;
			sprintf(buffer, "set new landmark count to [%d]", GBL_SET_NUMBER_OF_LANDMARKS);
			simpleLog(buffer);
		}
		else
		{
			sprintf(buffer, "ERROR : attempt to set new landmark count to negative  [%d]", howMany);
			simpleLog(buffer);
			sprintf(buffer, "INFO : global number of landmarks unchanged at [%d]", GBL_SET_NUMBER_OF_LANDMARKS);
			simpleLog(buffer);
		}
		simpleLog((const char*)"function add ... shape setNewLandmarkCount ... end ");
	}
	else if (strcmp(shape, "setNewAnchorCount") == 0)
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"function add ... shape setNewAnchorCount");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);
		int howMany = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &howMany);
		if (howMany > 0)
		{
			GBL_SET_NUMBER_OF_ANCHORS = howMany;
			sprintf(buffer, "set new anchor count to [%d]", GBL_SET_NUMBER_OF_ANCHORS);
			simpleLog(buffer);
		}
		else
		{
			sprintf(buffer, "ERROR : attempt to set new anchor count to negative  [%d]", howMany);
			simpleLog(buffer);
			sprintf(buffer, "INFO : global number of anchors unchanged at [%d]", GBL_SET_NUMBER_OF_ANCHORS);
			simpleLog(buffer);
		}
		simpleLog((const char*)"function add ... shape setNewAnchorCount ... end ");
	}
	else if (strcmp(shape, "rotationAngles") == 0)
	{
		// possible future enhancement to processing. For now, all this does is 
		// assign values to global variables. One application is with regard to
		// getting text and curves off the speciment surface
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"function add ... rotationAngles");
		simpleLog((const char*)"objects 2 and 3");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		double aX = 0.0;
		double aY = 0.0;
		Wrapper_GetDoubleFromObj(interp, objv[2], &aX);
		Wrapper_GetDoubleFromObj(interp, objv[3], &aY);
		GBL_ROTATION_ANGLE_X = (float)aX;
		GBL_ROTATION_ANGLE_Y = (float)aY;
		simpleLog((const char*)"function add ... rotationAngles ... end");
	}
	else if (strcmp(shape, "reset_state") == 0)
	{
		simpleLog((const char*)"function add ... reset_state (initialize_state argument 0)");
		initialize_state(0, 0);
		simpleLog((const char*)"function add ... reset_state .. .end");
	}
	else if (strcmp(shape, "curveSetDotSliderColor") == 0)
	{ // based on GUI operation swich back to curves tab = change the specified dot 
	  // to the slider color... in use this would be the middle dot index for each curve

		simpleLog((const char*)"function add ... curveSetDotSliderColor");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);
		int whichDotIndex = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &whichDotIndex);  /// is 1 based and we keep it as 1 based

		sprintf(buffer, "DEBUG : setting color of slider dot index [%d]  curve slice index is[%d]",
			whichDotIndex, get_curve_slice_index());
		simpleLog(buffer);
		changeDotColorToSlider(whichDotIndex); // 1 based

		simpleLog((const char*)"function add ... curveSetDotSliderColor .. .end");
	}

	else
	{
		sprintf(buffer, "function add ... unknown command (shape argument) {%s}", shape);
		simpleLog(buffer);
		/// 20 May 2020 do nothing else
	}


	simpleLog((const char*)"END TCL_CMD_ADD");
	simpleLogBlankLine();
	onDisplay();
	return TCL_OK;
}


//returns preexisting object information
#ifdef STAND_ALONE_TOOL
int show(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[])
#else
TCL_CMD(show)
#endif
{
	simpleLogBlankLine();
	simpleLog((const char*)"TCL_CMD_SHOW");
	TclIf_LogCommands(objc, objv);
	const char* shape = Wrapper_GetStringFromObj(objv[1], NULL);
	if (strcmp(shape, "specimen") == 0) // returns specimens coordinates
	{
		simpleLog((const char*)"function show ... shape specimen");
		simpleLog((const char*)"objects 2, 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		const char* attr = Wrapper_GetStringFromObj(objv[2], NULL);
		if (strcmp(attr, "xyz") == 0)
		{
			simpleLog((const char*)"function show specimen xyz ...");

			int x = -1;
			int y = -1;

			Wrapper_GetIntFromObj(interp, objv[3], &x);
			Wrapper_GetIntFromObj(interp, objv[4], &y);
			sprintf(buffer, "INFO : Show shape specimen x, y coordinates are [%d ... %d]", x, y);
			simpleLog(buffer);
			char buf[1000] = { 0 };

			point_t p;
			if (0 != getSpecimenCoordinate(x, y, &p, buf))
			{
				simpleLog("ERROR :  ... negative return from getSpecimenCoordinate in specimen xyz");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			simpleLog("The following long line is the buf from getSpecimenCoordinate() ");
			simpleLog(buf);
			sprintf(buffer, "The point coordinates are   % f % f % f", p.x, p.y, p.z);
			simpleLog(buffer);

#ifdef CODE_FOR_LIBRARY 
			simpleLog((const char*)"function show specimen xyz ... end");
			simpleLog((const char*)"TCL_CMD_SHOW ... end");
			simpleLogBlankLine();
			char* msg = ALLOCATE_WRAPPER(512);
			sprintf(msg, "%f %f %f", p.x, p.y, p.z);
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);
			onDisplay();
			return TCL_OK;
#endif
		}
	}
	else if (strcmp(shape, "landmark") == 0)
	{
		simpleLogBlankLine();
		simpleLog((const char*)"SHOW/SHAPE/LANDMARK");
		simpleLog((const char*)"function show ... shape landmark");
		simpleLog((const char*)"objects 2, and 3");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);

		const char* attr = Wrapper_GetStringFromObj(objv[2], NULL);
		if (strcmp(attr, "xyz") == 0) // returns landmark coordinates
		{
			simpleLog((const char*)"function show landmark xyz ...");
			int id = -1;
			Wrapper_GetIntFromObj(interp, objv[3], &id);
			id = id - 1; // adjust 1 based indexing in R to 0 based indexing in C

			temp_index = id;
			char* msg = (char*)ALLOCATE_WRAPPER(2048);
			if (NULL == msg)
			{
				simpleLog("ERROR : failed to allocate memory for message xyz");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			else
			{
				strcpy(msg, "");
				dot_t* n = dot_get(id);
				if (NULL == n)
				{
					sprintf(buffer, "ERROR : negative return from dot_get [%d]", id);
					simpleLog(buffer);
					UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				}
				else
				{
					if (n->type == ANCHOR) { simpleLog("dot type is ANCHOR -FAIL-"); }
					if (n->type == LANDMARK) { simpleLog("dot type is LANDMARK -OK-"); }
				}

				int lmCount = 0;
				dot_t* tP = n;
				while (n != NULL)
				{
					lmCount++;
					n = n->next;
				}
				sprintf(buffer, "DEBUG : Linked list of dots has [%d] landmarks", lmCount);
				simpleLog(buffer);
				n = tP; // restore




				lmCount = 0;
				while (n != NULL)
				{
					if (n->type == LANDMARK)
					{
						char pStr[64] = { 0 };
						snprintf(pStr, 60, "%f %f %f ",
							calUnCoordinate(n->p.x, X, deltas[temp_index]), //for original, change back to models->delta
							calUnCoordinate(n->p.y, Y, deltas[temp_index]),
							calUnCoordinate(n->p.z, Z, deltas[temp_index]));
						sprintf(buffer, "DEBUG : LEN [%d] pStr building string <%s>", (int)strlen(pStr), pStr);
						simpleLog(buffer);
						strcat(msg, pStr);
						sprintf(buffer, "DEBUG : msg length is [%d]", (int)strlen(msg));
						simpleLog(buffer);
					}
					else
					{
						sprintf(buffer, "ERROR : point type is not landmark !  integer equiv {%d}", (int)n->type);
						simpleLog(buffer);
					}
					n = n->next;
					sprintf(buffer, "msg = <%s>", msg);
					simpleLog(buffer);

					sprintf(buffer, "INFO : (landmarks) [%d]  return string is <%s>", lmCount, msg);
					simpleLog(buffer);
					lmCount++;

					D1("msg=%s", msg);

				}
			}
			simpleLog((const char*)"function show landmark xyz ... end");

#ifdef CODE_FOR_LIBRARY
			simpleLog((const char*)"TCL_CMD_SHOW ... end");
			simpleLogBlankLine();
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);
			onDisplay();
			return TCL_OK;
#endif
		}
		else if (strcmp(attr, "id") == 0) // returns the selected landmark coordinate   
		{
			simpleLog("function show ... landmark id ...");
			sprintf(buffer, "INFO : show landmark id ... i'th dot is [%d]  {zero based}", dot_selected_id());
			simpleLog(buffer);
			simpleLog((const char*)"function show landmark id ... end");
#ifdef CODE_FOR_LIBRARY
			simpleLog((const char*)"TCL_CMD_SHOW ... end");
			simpleLogBlankLine();
			TCL_RESULT1("%d", dot_selected_id() + 1);  // we need to add 1 to return to the R environment 
			onDisplay();
			return TCL_OK;
#endif
		}
	}
	else if (strcmp(shape, "anchor") == 0)
	{
		simpleLogBlankLine();
		simpleLog((const char*)"SHOW/SHAPE/ANCHOR");
		simpleLog((const char*)"function show ... shape anchor");
		const char* attr = Wrapper_GetStringFromObj(objv[2], NULL);
		if (strcmp(attr, "xyz") == 0)
		{
			simpleLog((const char*)"function show ... shape anchor xyz ...");
			int id = -1;
			Wrapper_GetIntFromObj(interp, objv[3], &id);
			id = id - 1; // adjust 1 based indexing in R to 0 based indexing in C
			sprintf(buffer, "INFO : request anchors for id [%d]", id);
			simpleLog(buffer);
			if (id < 0)
			{
				sprintf(buffer, "ERROR : adjusted id is negative [%d] ... forcing it to zero", id);
				simpleLog(buffer);
				id = 0;
			}

			char* msg = (char*)ALLOCATE_WRAPPER(2048);
			strcpy(msg, "");
			dot_t* n = anchor_get(id);

			if (NULL == n)
			{
				sprintf(buffer, "INFO : There are NO anchors for id [%d] ... result from anchor_get is NULL", id);
				simpleLog(buffer);
			}


			while (n != NULL)
			{

				if (n->type == ANCHOR) { simpleLog("dot type is ANCHOR -OK-"); }
				if (n->type == LANDMARK) { simpleLog("dot type is LANDMARK -FAIL-"); }

				if (n->type == ANCHOR)
				{
					char pStr[64] = { 0 };
					snprintf(pStr, 60, "%f %f %f ",
						calUnCoordinate(n->p.x, X, deltas[temp_index]),
						calUnCoordinate(n->p.y, Y, deltas[temp_index]),
						calUnCoordinate(n->p.z, Z, deltas[temp_index]));
					strcat(msg, pStr);
				}
				n = n->next;
				D1("msg=%s", msg);
			}
			sprintf(buffer, "INFO : (anchors) return string is <%s>", msg);
			simpleLog(buffer);

			simpleLog((const char*)"function show anchor  xyz ... end ");

#ifdef CODE_FOR_LIBRARY
			simpleLog((const char*)"TCL_CMD_SHOW ... end");
			simpleLogBlankLine();
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);
			onDisplay();
			return TCL_OK;
#endif

		}
		else if (strcmp(attr, "id") == 0) // returns ith anchor coord   
		{
			simpleLog("function show ... anchor id ...");
			sprintf(buffer, "INFO : show anchor id ... ith dot is [%d] ", anchors_selected_id());
			simpleLog(buffer);
			simpleLog((const char*)"function show landmark id ... end");
#ifdef CODE_FOR_LIBRARY
			simpleLog((const char*)"TCL_CMD_SHOW ... end");
			simpleLogBlankLine();;
			TCL_RESULT1("%d", anchors_selected_id());
			onDisplay();
			return TCL_OK;
#endif
		}
	}
	//
	//  17 July 2020 : Should there be a selection for show curves as well ?
	//  else if (strcmp(shape, "curve") == 0) {} 
	//
	else
	{
		sprintf(buffer, "WARNING : Unknown string for argument 'shape' <%s> .. no action taken", shape);
		simpleLog(buffer);
	}

	simpleLog((const char*)"TCL_CMD_SHOW ... end");
	simpleLogBlankLine();

	onDisplay();
	return TCL_OK;
}
//allocates memory for specimen and updates specimen parameters
#ifdef STAND_ALONE_TOOL
int setSpecimen(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[])
#else
TCL_CMD(setSpecimen)
#endif
{
	int UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS; // success
	simpleLogBlankLine();
	simpleLog((const char*)"TCL_CMD_SET_SPECIMEN");
	TclIf_LogCommands(objc, objv);
	const char* attr = Wrapper_GetStringFromObj(objv[1], NULL);

	if (strcmp(attr, "angle") == 0) // handles rotation of specimen
	{
		simpleLog((const char*)"function setSpecimen attr ... angle");
		////simpleLog((const char*)"objects 2 and 3");
		simpleLog_Obj(objv[2]);   // character string : which axis
		simpleLog_Obj(objv[3]);   // floating point angle in degrees

		if (0 == model_amount)
		{
			simpleLog("WARN : function setSpecimen attr angle ... model amount is zero ... no action taken");
			UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;
		}
		else
		{
			const char* d = Wrapper_GetStringFromObj(objv[2], NULL);
			if (NULL == d)
			{
				simpleLog("ERROR : NULL value for assignd variable d");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}

			double r;
			double other;
			Wrapper_GetDoubleFromObj(interp, objv[3], &r);
			other = r;
			if (r != other)   // NAN values are suppose to be un equal 
			{
				// then assume ok since we believe valid doubles from the tcl object are 
				// not equal if they are NAN

				sprintf(buffer, "ERROR : possible NAN value for angle from R");
				simpleLog(buffer);
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				r = 0.0; // use a refault value so we don't crash
			}

			/*apply rotations*/
			switch (d[0])
			{
			case 'x':
				context[model_index].rotation[0] += (float)r;
				ANGLE_REDUCE(context[model_index].rotation[0]);
				break;
			case 'y':
				context[model_index].rotation[1] += (float)r;
				ANGLE_REDUCE(context[model_index].rotation[1]);
				break;
			case 'z':
				context[model_index].rotation[2] += (float)r;
				ANGLE_REDUCE(context[model_index].rotation[2]);
				break;
			default:
			{
				sprintf(buffer, "ERROR : unknown character case for  rotation selection {%1c}", d[0]);
				simpleLog(buffer);
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			}


			sprintf(buffer, "DEBUG : Rotation angles : %10.6f %10.6f %10.6f",
				context[model_index].rotation[0], context[model_index].rotation[1], context[model_index].rotation[2]);
			simpleLog(buffer);
			simpleLogWriteContextToFile(&context[model_index]);

#ifdef CODE_FOR_LIBRARY 
			char* msg = Tcl_Alloc(512);
			sprintf(msg, "Rotate: %f %f %f",
				context[model_index].rotation[0],
				context[model_index].rotation[1],
				context[model_index].rotation[2]);
			Tcl_SetResult(interp, msg, TCL_DYNAMIC);
#endif

		}
		simpleLog((const char*)"function setSpecimen attr angle ... end");
	}
	else if (strcmp(attr, "scale") == 0) // zooming in/out functionality
	{
		simpleLog((const char*)"setSpecimen ... scale");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);

		if (0 == model_amount)
		{
			simpleLog("WARNING : function setSpecimen attr scale ... model amount is zero ... no action taken");
			UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;
		}
		else
		{
			const char* value = Wrapper_GetStringFromObj(objv[2], NULL);
			if (NULL == value)
			{
				simpleLog("WARNING : function setSpecimen attr scale ... NULL string argument from R");
				UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;
			}
			else
			{
				// here we assume that 'model_index' is valid since this was assigned externally to
				// this function .. 
				// Apply scaling 
				if (strcmp(value, "in") == 0)
				{
					context[model_index].scale += 0.1;
				}
				else if (strcmp(value, "out") == 0 && context[model_index].scale > 0.1)
				{
					context[model_index].scale -= 0.1;
				}
				else
				{
					sprintf(buffer, "WARNING  : Invalid parameter for scaling <%s>", value);
					simpleLog(buffer);
					UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				}
			}
		}
		simpleLogWriteContextToFile(&context[model_index]);
		simpleLog((const char*)"setSpecimen scale ... end");
	}
	else if (strcmp(attr, "allocate") == 0) // allocates memory for N specimens and creates context and other data structures
	{
		simpleLog("SET SPECIMEN/ALLOCATE");
		simpleLog((const char*)"setSpecimen ... allocate");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);
		int amount = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &amount);
		sprintf(buffer, "allocating memory space for [%d] specimens and associated data structures", amount);
		GBL_LANDMARKS_NUM_SPECIMENS = amount;
		simpleLog(buffer);

		if (models != NULL)
		{
			FREE_WRAPPER((char*)models);
			models = NULL;
			GBL_PTR_TO_A_MODEL = NULL;
		}
		if (context != NULL)
		{
			FREE_WRAPPER((char*)context);
			context = NULL;

		}


		if (0 == amount)  // added 05 August as a method to clean up memory
		{
			sprintf(buffer, "INFO : allocate is zero : freeing all memory");
			simpleLog(buffer);
			curveReleaseArray();
			anchorReleaseList();
			dotReleaseList();
			GBL_PTR_TO_A_MODEL = NULL;

		}



		if (amount < 0)
		{
			sprintf(buffer, "set specimen allocate : parameter error: amount < 0 [%d]", amount);
			simpleLog(buffer);
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}

		if (amount > 0)
		{
			int howMuchModels = amount * sizeof(model_t);
			int howMuchContext = amount * sizeof(context_t);

			models = (model_t*)ALLOCATE_WRAPPER(howMuchModels);
			context = (context_t*)ALLOCATE_WRAPPER(howMuchContext);
			// handles graphical aspects of specimen


 // 28 May 2020 known issue in the implementation !
 // if malloc fails we are not cleaning up completely
 // this has not been observed in the new code so far

			if (NULL == (void*)models)
			{
				sprintf(buffer, "FAILED TO ALLOCATE MEMORY FOR MODELS");
				simpleLog(buffer);
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
				GBL_PTR_TO_A_MODEL = NULL;
			}
			else
			{
				memset(models, 0, howMuchModels);
				for (int ii = 0; ii < amount; ii++)
				{
					models[ii].thisModelIntegerCount = ii;
					models[ii].fileName[0] = '\0';
					models[ii].vertex = NULL;
					models[ii].color = NULL;
					models[ii].normal = NULL;
					models[ii].dsVertex = NULL;
				}
				GBL_PTR_TO_A_MODEL = &models[0];
			}

			if (NULL == (void*)context)
			{
				sprintf(buffer, "FAILED TO ALLOCATE MEMORY FOR CONTEXT");
				simpleLog(buffer);
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			else
			{
				memset(context, 0, howMuchContext);
			}
			/*
						switch (amount)
						{
						case 1:
							GBL_PTR_MODEL_1 = models;
							GBL_PTR_TO_A_MODEL = &models[0];
							break;
						case 2:
							GBL_PTR_MODEL_1 = &models[0];
							GBL_PTR_MODEL_2 = &models[1];
							GBL_PTR_TO_A_MODEL = &models[0];
							break;

						case 3:
							GBL_PTR_MODEL_1 = &models[0];
							GBL_PTR_MODEL_2 = &models[1];
							GBL_PTR_MODEL_3 = &models[2];
							break;
						case 4:
							GBL_PTR_MODEL_1 = &models[0];
							GBL_PTR_MODEL_2 = &models[1];
							GBL_PTR_MODEL_3 = &models[2];
							GBL_PTR_MODEL_4 = &models[3];
							break;
						case 5:
							GBL_PTR_MODEL_1 = &models[0];
							GBL_PTR_MODEL_2 = &models[1];
							GBL_PTR_MODEL_3 = &models[2];
							GBL_PTR_MODEL_4 = &models[3];
							GBL_PTR_MODEL_5 = &models[4];
							break;
						default:
							simpleLog("ERROR : too many models allocated");
							UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
							break;
						}
			*/
			/*
						switch (amount)
						{
						case 1:
							GBL_PTR_CONTEXT_1 = &context[0];
							break;
						case 2:
							GBL_PTR_CONTEXT_1 = &context[0];
							GBL_PTR_CONTEXT_2 = &context[1];
							break;
						case 3:
							GBL_PTR_CONTEXT_1 = &context[0];
							GBL_PTR_CONTEXT_2 = &context[1];
							GBL_PTR_CONTEXT_3 = &context[2];
							break;
						case 4:
							GBL_PTR_CONTEXT_1 = &context[0];
							GBL_PTR_CONTEXT_2 = &context[1];
							GBL_PTR_CONTEXT_3 = &context[2];
							GBL_PTR_CONTEXT_4 = &context[3];
							break;
						case 5:
							GBL_PTR_CONTEXT_1 = &context[0];
							GBL_PTR_CONTEXT_2 = &context[1];
							GBL_PTR_CONTEXT_3 = &context[2];
							GBL_PTR_CONTEXT_4 = &context[3];
							GBL_PTR_CONTEXT_5 = &context[4];
							break;
						default:
							simpleLog("ERROR : too many contexts allocated");
							UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
							break;
						}
			*/

			model_index = 0;
			model_amount = amount;
			sprintf(buffer, "INFO : set specimen allocate ");
			simpleLog(buffer);
			sprintf(buffer, "model_index [%d] ... model amount [%d]", model_index, model_amount);
			simpleLog(buffer);


			// There is an architecture issue here .. deltas is dimensioned[1000][4] 
			// The first dimension is the specimen index and as of 02 August 2020 this 
			// has not been properly addressed in useage
			clear_deltas();   // clean 2d array when memory is allocated

			// these now return ints : 0 is success
			int temp = -1;
			temp = set_dot_slice_amount(amount);
			if (0 != temp)
			{
				simpleLog("ERROR : negative return from dot_slice_amount. Memory not allocated");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			else
			{
				dotSetArrayIndex(0);
			}

			temp = set_anchors_slice_amount(amount);
			if (0 != temp)
			{
				simpleLog("ERROR : negative return from set_anchors_slice_amount. Memory not allocated");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			else
			{
				anchorSetArrayIndex(0);
			}

			temp = curveAllocateArray(amount);
			if (0 != temp)
			{
				simpleLog("ERROR : negative return from curveAllocateArray. Memory not allocated");
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			else
			{
				curveSetArrayIndex(0);
			}


		}


		simpleLog("SET SPECIMEN/ALLOCATE ... RESULTS");
		sprintf(buffer, "INFO : allocation amount ...  [%d]", amount); simpleLog(buffer);
		sprintf(buffer, "INFO : dots amount    [%d]", dotGetArraySize()); simpleLog(buffer);
		sprintf(buffer, "INFO : anchors amount [%d]", get_anchor_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : curve amount   [%d]", get_curve_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : dots current slice index    [%d]", get_dot_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : anchors current slice index [%d]", get_anchor_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : curve current slice index   [%d]", get_curve_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : Test of models pointer <%s>", (NULL == models) ? "NULL" : "not null"); simpleLog(buffer);

		// development test : can I access the models in the array ?
		for (int ii = 0; ii < amount; ii++)
		{
			models[ii].thisModelIntegerCount = ii;
			strncpy(models[ii].fileName, "DUMMY", 20);
		}
		for (int ii = 0; ii < amount; ii++)
		{
			printf("Models index [%d] : file name is <%s>\n", models[ii].thisModelIntegerCount, models[ii].fileName);
		}
		simpleLog((const char*)"setSpecimen allocate ... end");
	}
	else if (strcmp(attr, "id") == 0) // updates model id and it's associated landmarks/anchors
	{
		simpleLog("SET SPECIMEN/ID");
		simpleLog((const char*)"setSpecimen ... id");

		int index = -1;
		if (0 == model_amount)
		{
			simpleLog("DEBUG : function setSpecimen attr id ... model amount is zero ... no action taken");
			UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;
		}
		else
		{
			Wrapper_GetIntFromObj(interp, objv[2], &index);
			index = index - 1;   // adjust from 1 based in R to zero based in C

			sprintf(buffer, "INFO : current model index is [%d] ... setting to ... (0 based) {%d}", model_index, index);
			simpleLog(buffer);
			model_index = index;
			sprintf(buffer, "INFO : modified model index is [%d]", model_index);
			simpleLog(buffer);
			GBL_PTR_TO_A_MODEL = &models[model_index];

			curveSetArrayIndex(index);
			anchorSetArrayIndex(index);
			dotSetArrayIndex(index);


			sprintf(buffer, "INFO : Current model index is   ...   [%d]", model_index); simpleLog(buffer);
			sprintf(buffer, "INFO : Current dot slice index is ..  [%d]", get_dot_slice_index()); simpleLog(buffer);
			sprintf(buffer, "INFO : Current anchor slice index is  [%d]", get_anchor_slice_index()); simpleLog(buffer);
			sprintf(buffer, "INFO : Current curve slice index is   [%d]", get_curve_slice_index()); simpleLog(buffer);

			// possible fix 02 august 2020
			// when the model index is specified we copy the delta data from the model to the deltas[][] array
			// this the specimen index being the  deltas first index
			deltas[model_index][0] = models[model_index].delta[0];
			deltas[model_index][1] = models[model_index].delta[1];
			deltas[model_index][2] = models[model_index].delta[2];
			deltas[model_index][3] = models[model_index].delta[3];




			// This code is not as clean as I would like it to be ...
			if (anchorPlaced == 1)
			{
				if (0 == dot_slice_index(index) && 0 == anchor_slice_index(index))
				{
					sprintf(buffer, "INFO : anchors placed (previously ?) and dot/anchor slice indices set to [%d] -OK-", index);
					simpleLog(buffer);

					model_index = index;
					temp_index = index;
					float maxXY = models->max[0] > models->max[1] ? models->max[0] : models->max[1];
					resetContext(index, maxXY);
					TCL_RESULT1("Reset context for %d", model_index);
				}
				else
				{
					sprintf(buffer, "ERROR : anchor is placed : dot slice index / anchor_slice_index  [%d] zero (or less ? or exceeds allocation) ", index);
					simpleLog(buffer);
					UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;
				}
			}
			else  // else anchors not (yet) placed ... why does this matter ??
			{
				if (0 == dot_slice_index(index))
				{
					model_index = index;
					temp_index = index;
					float maxXY = models->max[0] > models->max[1] ? models->max[0] : models->max[1];
					resetContext(index, maxXY);
					TCL_RESULT2("Reset context for %d  ... {%d}", model_index, model_index + 1);
				}
				else
				{
					sprintf(buffer, "anchor not placed : dot slice index for index[%d] zero (or less ? or exceeds allocated size) ", index);
					simpleLog(buffer);
					UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;
				}

				if (0 == anchor_slice_index(index))
				{
					sprintf(buffer, "INFO : anchors not (yet) placed : set anchor slice index to [%d] -OK-", index);
					simpleLog(buffer);
				}
				else
				{
					sprintf(buffer, "ERROR : anchors not (yet) placed : failed to set anchor slice index to [%d]", index);
					simpleLog(buffer);
				}
			}
		}

		simpleLog("SET SPECIMEN/ID ... RESULTS");
		sprintf(buffer, "INFO : dots amount      [%d]", dotGetArraySize()); simpleLog(buffer);
		sprintf(buffer, "INFO : anchors amount   [%d]", get_anchor_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : curve amount     [%d]", get_curve_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : specified index is   ...       [%d]", index); simpleLog(buffer);
		sprintf(buffer, "INFO : Current model index is   ...   [%d]", model_index); simpleLog(buffer);
		sprintf(buffer, "INFO : Current dot slice index is ..  [%d]", get_dot_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : Current anchor slice index is  [%d]", get_anchor_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : Current curve slice index is   [%d]", get_curve_slice_index()); simpleLog(buffer);
		simpleLog((const char*)"setSpecimen id ... end");
	}

	simpleLog((const char*)"END TCL_CMD_SET_SPECIMEN");
	simpleLogBlankLine();
	onDisplay();
	return TCL_OK;
}

//updates downsample parameters
#ifdef STAND_ALONE_TOOL
int setDownSample(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[])
#else
TCL_CMD(setDownSample)
#endif
{
	simpleLog((const char*)"TCL_CMD_SET_DOWNSAMPLE");
	TclIf_LogCommands(objc, objv);
	simpleLog((const char*)"objects 2 and 3");
	simpleLog_Obj(objv[2]);
	simpleLog_Obj(objv[3]);
	int UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;


	const char* attr = Wrapper_GetStringFromObj(objv[1], NULL);
	if (strcmp(attr, "offsetBegin") == 0)
	{
		simpleLog("setDownSample ... offsetBegin");
		int x = 0;
		int y = 0;
		Wrapper_GetIntFromObj(interp, objv[2], &x);
		Wrapper_GetIntFromObj(interp, objv[3], &y);
		sprintf(buffer, " offsetBegin arguments  [%d] [%d]", x, y);
		simpleLog(buffer);

		if (0 != getSpecimenCoordinate(x, y, &downSampleOffsetBeg, NULL))
		{
			simpleLog("ERROR : negative return from getSpecimentCoordinate");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}
		simpleLog("setDownSample ... offsetBegin ... end");

	}
	else if (strcmp(attr, "offsetEnd") == 0)
	{
		simpleLog("setDownSample ... offsetEnd");
		int x = 0;
		int y = 0;
		Wrapper_GetIntFromObj(interp, objv[2], &x);
		Wrapper_GetIntFromObj(interp, objv[3], &y);

		sprintf(buffer, " offsetEnd arguments  [%d] [%d]", x, y);
		simpleLog(buffer);

		point_t p;
		if (0 != getSpecimenCoordinate(x, y, &p, NULL))
		{
			simpleLog("ERROR : negative return from getSpecimentCoordinate");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
		}

		downSampleOffset.x = p.x - downSampleOffsetBeg.x;
		downSampleOffset.y = p.y - downSampleOffsetBeg.y;
		downSampleOffset.z = 0.0;   //p.z - downSampleOffsetBeg.z;  why is this commented ??

		sprintf(buffer, " __downSampleOffsetBeg.x  <%f>", (double)downSampleOffsetBeg.x); simpleLog(buffer);
		sprintf(buffer, " __downSampleOffsetBeg.y  <%f>", (double)downSampleOffsetBeg.y); simpleLog(buffer);
		sprintf(buffer, " __point.x  <%f>", (double)p.x); simpleLog(buffer);
		sprintf(buffer, " __point.y  <%f>", (double)p.y); simpleLog(buffer);
		sprintf(buffer, " __downSampleOffset.x (end?) <%f>", (double)downSampleOffset.x); simpleLog(buffer);
		sprintf(buffer, " __downSampleOffset.y (end?) <%f>", (double)downSampleOffset.y); simpleLog(buffer);

		simpleLog("setDownSample ... offsetEnd ... end");
	}
	simpleLog((const char*)"END TCL_CMD_SET_DOWNSAMPLE");
	onDisplay();
	return TCL_OK;
}

//updates dot parameters
#ifdef STAND_ALONE_TOOL
int setDot(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[])
#else
TCL_CMD(setDot)
#endif
{
	simpleLog((const char*)"TCL_CMD_SET_DOT");
	TclIf_LogCommands(objc, objv);
	int UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;

	const char* attr = Wrapper_GetStringFromObj(objv[1], NULL);
	if (strcmp(attr, "selected") == 0) // grabs dot based on coordinates, used when user selects landmark with mouse
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog("SETDOT/SELECTED");
		simpleLog((const char*)"setDot ... selected ... ");
		simpleLog((const char*)"objects 2 and 3");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		int x = -1;
		int y = -1;
		Wrapper_GetIntFromObj(interp, objv[2], &x);
		Wrapper_GetIntFromObj(interp, objv[3], &y);

		sprintf(buffer, "INFO : setDot / selected ... mouse click was at [%d ... %d]", x, y);
		simpleLog(buffer);

		char buf[256];
		buf[0] = 0;

		point_t p;
		if (0 != getSpecimenCoordinate(x, y, &p, buf))
		{
			simpleLog("WARNING : setDot ... negative return from getSpecimenCoordinate");
			if (NULL != buf)
			{
				simpleLog(buf);
			}
			UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;
		}
		else
		{
			simpleLog("INFO : -ok- return from getSpecimenCoordinate {buf follows}");
			simpleLog(buf);

			sprintf(buffer, "DEBUG : Point_t data from getSpecimenCoordinate x %10.6f  y %10.6f  z %10.6f", p.x, p.y, p.z);
			simpleLog(buffer);
		}


		if (LANDMARK == showModel)
		{

			if (0 != dot_select(&p, dotRadius))
			{
				sprintf(buffer, "INFO : (landmark) No dot selected at %d %d", x, y);
				simpleLog(buffer); // NOT an error 
				UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;

#ifdef CODE_FOR_LIBRARY 
				simpleLog("WARNING : setDot selected LIBRARY early return");
				TCL_RESULT2("WARNING : No dot (landmark) selected at %d %d", x, y);
				//onDisplay();
				//return TCL_OK;  
#endif
			}
			// else we did find a dot close to the mouse click .... 
			// what do I do with it ?
			// when I selected the dot ... should the color change ?
		}




		if (ANCHOR == showModel)
		{
			if (0 != anchor_select(&p, anchorRadius))
			{
				sprintf(buffer, "INFO : No anchor selected at %d %d\n", x, y);
				simpleLog(buffer); // NOT an error 
				UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;

#ifdef CODE_FOR_LIBRARY 
				simpleLog("WARNING : setDot selected LIBRARY early return");
				TCL_RESULT2("WARNING : No dot (anchor) selected at %d %d\n", x, y);
				//onDisplay();
				//return TCL_OK;  
#endif
			}
			// else anchor point 'close' was found ....
			// what do I do with it. 
			// 12 JULY 2020 ...  Austin is working the return mechanism for TCL_ERROR returns in R 
		}



		// added 10 July 2020  // code copied from landmark for now
		if (CURVE == showModel)
		{

			if (0 != dot_select(&p, dotRadius))
			{
				sprintf(buffer, "INFO : (curve) No dot selected at %d %d", x, y);
				simpleLog(buffer); // NOT an error 
				UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;
#ifdef CODE_FOR_LIBRARY 
				simpleLog("WARNING : setDot (curve) selected LIBRARY early return");
				TCL_RESULT2("WARNING: No dot (curve) selected at %d %d", x, y);
				//onDisplay();
				//return TCL_ERROR;  
#endif
			}
			// else we did find a dot close to the mouse click .... 
			// what do I do with it ?
			// when I selected the dot ... should the color change ?
		}
		simpleLog("SETDOT/SELECTED ... END");
		simpleLog((const char*)"setDot selected ... end");
	}
	else if (strcmp(attr, "coordinate") == 0) // functionality for dragging dot
	{
		UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;
		simpleLog((const char*)"setDot ... coordinate ... ");
		simpleLog((const char*)"objects 2 , 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		point_t p;
		Wrapper_GetDoubleFromObj(interp, objv[2], &p.x);
		Wrapper_GetDoubleFromObj(interp, objv[3], &p.y);
		Wrapper_GetDoubleFromObj(interp, objv[4], &p.z);

		if (0 != validateDot(&p))
		{
			sprintf(buffer, "INFO : cannot move dot to %f %f %f", p.x, p.y, p.z);
			simpleLog(buffer); // NOT an error 
			UT_MY_INTEGER_VALUE = GBL_RTN_IGNORE;
#ifdef CODE_FOR_LIBRARY 
			simpleLog("setDot coordinate LIBRARY early return");
			TCL_RESULT3("WARNING : cannot move dot to %f %f %f ... (dot invalid ? )", p.x, p.y, p.z);
			onDisplay();
			return TCL_OK; ///  TCL_ERROR; ///  TCL_OK;
#endif
		}
		else  // valid dot ... 
		{
			if (0 != dot_move(&p))
			{
				simpleLog("ERROR : ... negative return from dot move ... dot not moved ?");
				simpleLog(buffer);
				UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			}
			// else dot move returned 0 ... good return - but what happened ?
		}
		simpleLog((const char*)"setDot ... coordinate ... end");
		onDisplay();
		return TCL_OK;

	}
	else if (strcmp(attr, "dcolor") == 0) // assigns default landmark color
	{
		simpleLog((const char*)"setDot ... dcolor");
		simpleLog((const char*)"objects 2 , 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		Wrapper_GetDoubleFromObj(interp, objv[2], &defaultDotColor.r);
		Wrapper_GetDoubleFromObj(interp, objv[3], &defaultDotColor.g);
		Wrapper_GetDoubleFromObj(interp, objv[4], &defaultDotColor.b);
		sprintf(buffer, "INFO : set dot default color to RGB : <%10.6f   %10.6f   %10.6f>",
			defaultDotColor.r, defaultDotColor.g, defaultDotColor.b);
		simpleLog(buffer);
		simpleLog((const char*)"setDot ... dcolor ... end");
	}
	else if (strcmp(attr, "dotColorRestore") == 0)
	{  // no function arguments are required. Default dot color is used
		simpleLog((const char*)"setDot ... dotColorRestore");
		changeLandmarkDotColor();
		simpleLog((const char*)"setDot ... dotColorRestore ... end");
	}
	/*assigns default anchor color, other anchor color is used for color selection by user*/
	else if (strcmp(attr, "acolor") == 0)
	{
		simpleLog((const char*)"setDot ... acolor");
		simpleLog((const char*)"objects 2 , 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		Wrapper_GetDoubleFromObj(interp, objv[2], &defaultAnchorColor.r);
		Wrapper_GetDoubleFromObj(interp, objv[3], &defaultAnchorColor.g);
		Wrapper_GetDoubleFromObj(interp, objv[4], &defaultAnchorColor.b);
		sprintf(buffer, "INFO : set anchor default color to <%10.6f   %10.6f   %10.6f>",
			defaultAnchorColor.r, defaultAnchorColor.g, defaultAnchorColor.b);
		simpleLog(buffer);
		simpleLog((const char*)"setDot ... acolor ... end ");
	}
	else if (strcmp(attr, "color") == 0) // assigns new color choice to landmark
	{
		simpleLog((const char*)"setDot ... color");
		simpleLog((const char*)"objects 2 , 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		color_t c;
		Wrapper_GetDoubleFromObj(interp, objv[2], &c.r);
		Wrapper_GetDoubleFromObj(interp, objv[3], &c.g);
		Wrapper_GetDoubleFromObj(interp, objv[4], &c.b);
		if (0 != dot_color(&c))
		{
			simpleLog("ERROR : negative return from dot color .... NULL pointer?");
		}
		simpleLog((const char*)"setDot ... color ... end");
	}
	else if (strcmp(attr, "anchorColor") == 0)
	{
		simpleLog((const char*)"setDot ... anchorColor");
		simpleLog((const char*)"objects 2 , 3, and 4");
		simpleLog_Obj(objv[2]);
		simpleLog_Obj(objv[3]);
		simpleLog_Obj(objv[4]);
		color_t c;
		Wrapper_GetDoubleFromObj(interp, objv[2], &c.r);
		Wrapper_GetDoubleFromObj(interp, objv[3], &c.g);
		Wrapper_GetDoubleFromObj(interp, objv[4], &c.b);
		if (0 != anchor_color(&c))
		{
			simpleLog("ERROR : negative return from dot color .... NULL pointer?");
		}
		simpleLog((const char*)"setDot ... anchorColor ... end ");
	}
	else if (strcmp(attr, "labeled") == 0) // toggle label on landmark
	{
		simpleLog((const char*)"setDot ... labeled");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);
		Wrapper_GetIntFromObj(interp, objv[2], &labeled);
		sprintf(buffer, "... variable 'labeled' assigned value [%d]", labeled);
		simpleLog((const char*)buffer);
		simpleLog((const char*)"setDot ... labeled ... end ");
	}
	else if (strcmp(attr, "alabeled") == 0) // toggle label on anchor
	{
		simpleLog((const char*)"setDot ... alabeled");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);
		Wrapper_GetIntFromObj(interp, objv[2], &alabeled);
		sprintf(buffer, "... variable 'alabeled' assigned value [%d]", alabeled);
		simpleLog((const char*)buffer);
		simpleLog((const char*)"setDot ... alabeled ... end");
	}
	else if (strcmp(attr, "radius") == 0) // functionality for increasing/decreasing dot size
	{
		simpleLog((const char*)"setDot ... radius");                    // not to dave ... check for negatives ?? 
		simpleLog_Obj(objv[2]);
		Wrapper_GetDoubleFromObj(interp, objv[2], &dotRadius);
		sprintf(buffer, "... variable 'dotRadius' value <%f>", (float)dotRadius);
		simpleLog((const char*)buffer);
		simpleLog((const char*)"setDot ... radius ... end");
	}
	else if (strcmp(attr, "anchorRadius") == 0)
	{
		simpleLog((const char*)"setDot ... anchorRadius");
		simpleLog((const char*)"object 2");
		simpleLog_Obj(objv[2]);
		Wrapper_GetDoubleFromObj(interp, objv[2], &anchorRadius);
		sprintf(buffer, "... variable 'anchorRadius' value <%f>", (float)anchorRadius);
		simpleLog((const char*)buffer);
		simpleLog((const char*)"setDot ... anchorRadius ... end");
	}

	simpleLog((const char*)"END TCL_CMD_SET_DOT");
	onDisplay();
	return TCL_OK;
}


//removes specified object from memory
#ifdef STAND_ALONE_TOOL
int del(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[])
#else
TCL_CMD(del)
#endif
{

	simpleLog((const char*)"TCL_CMD_DEL");
	TclIf_LogCommands(objc, objv);
	int UT_MY_INTEGER_VALUE = GBL_RTN_SUCCESS;

	if (0)  // 14 July 2020 made inert by dave 
	{
		// Design decision require five arguments 
		// Talk to Erik about this ..... 
		// If we delete the speciment, below, what should happen to the dots, the anchors and the 
		// curve data if anything ?

		simpleLog("ATTENTION : There is an architecture issue here (tcl_if / del function ... read code comments");
		if (5 != objc)  // require that 3 arguments in addition function name and shape
		{
			simpleLog((const char*)"ERROR : Incorrect argument count : need 5 arguments from R");
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			simpleLog((const char*)"END TCL_CMD_SET_DEL");
			onDisplay();
			return TCL_OK;
		}
	}



	const char* shape = Wrapper_GetStringFromObj(objv[1], NULL);

	if (strcmp(shape, "xdots") == 0)   // NOT OPERATIONAL ! something dave was working on ONLY for testing
	{
		simpleLog("del ... xdots is under construction");
		UT_MY_INTEGER_VALUE = GBL_RTN_UNDER_CONSTRUCTION;
		simpleLog("del ... xdots is under construction ... end");
	}
	else if (strcmp(shape, "dot") == 0) // delete ith dot
	{
		simpleLog("del ... dot");
		int size = 0;
		// 14 July 2020 This is still under construction
		// the R GUI does not invoke delete with an arbitrary point -
		// the R gui has the concept of the selected dot !

		if (objc > 2)     // THIS IS NOT ROBUST... IF THE NUMBER OF ARGUMENTS IS VARIABLE - EXPLICITLY HANDLE
		{
			point_t p;
			Wrapper_GetDoubleFromObj(interp, objv[2], &p.x);
			Wrapper_GetDoubleFromObj(interp, objv[3], &p.y);
			Wrapper_GetDoubleFromObj(interp, objv[4], &p.z);
			size = dot_del(&p);
		}
		else
		{
			size = dot_del_selected();
		}

		sprintf(buffer, "DEBUG : Delete dot : new size is [%d]", size);
		simpleLog(buffer);

	}
	else if (strcmp(shape, "anchor") == 0)
	{
		simpleLog("del ... anchor");
		int size = 0;
		// 14 July 2020 This is still under construction  regarding argument counts
		// the R GUI does not invoke delete with an arbitrary point -
		// the R gui has the concept of the selected dot !

		if (objc > 2)
		{
			point_t p;
			Wrapper_GetDoubleFromObj(interp, objv[2], &p.x);
			Wrapper_GetDoubleFromObj(interp, objv[3], &p.y);
			Wrapper_GetDoubleFromObj(interp, objv[4], &p.z);
			size = anchor_del(&p);
		}
		else
		{
			size = anchor_del_selected();
		}
		sprintf(buffer, "DEBUG : Delete anchor : new size is [%d]", size);
		simpleLog(buffer);
	}
	else if (strcmp(shape, "xanchors") == 0) // NOT OPERATIONAL ! something dave was working on ONLY for testing
	{
		simpleLog("del ... xanchors is under construction");
		UT_MY_INTEGER_VALUE = GBL_RTN_UNDER_CONSTRUCTION;
		simpleLog("del ... xanchors is under construction ... end");
	}
	else if (strcmp(shape, "specimen") == 0)
	{
		simpleLog((const char*)"del ... specimen");
		int id;
		Wrapper_GetIntFromObj(interp, objv[2], &id);

		if (id < 0)
		{
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			simpleLog("ERROR : specimen_del ... negative id argument");
		}
		if (0 != specimen_del(id))
		{
			// this looks like an architecture problem ...
			// ID is NOT used !  There is only one model !
			// how do I know the specimens ??
			UT_MY_INTEGER_VALUE = GBL_RTN_ERROR;
			simpleLog("ERROR : negative return from specimen_del");
		}
		simpleLog((const char*)"del ... specimen ... end");
	}

	simpleLog((const char*)"END TCL_CMD_SET_DEL");
	onDisplay();
	return TCL_OK;
}

//allocates memory for context and updates display, minimal functionality, most of it was moved to R
#ifdef STAND_ALONE_TOOL
int loadDgt(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[])
#else
TCL_CMD(loadDgt)
#endif
{
	simpleLog((const char*)"TCL_CMD_SET_loadDgt");
	TclIf_LogCommands(objc, objv);
	int UT_MY_INTEGER_VALUE = GBL_RTN_UNDER_CONSTRUCTION;

	const char* fileName = Wrapper_GetStringFromObj(objv[1], NULL);
	sprintf(buffer, "DEBUG : .dgt File name is \n <%s>", fileName);
	simpleLog(buffer);


	sprintf(buffer, "DEBUG : loadDgt Current model index is ...  [%d]", model_index); simpleLog(buffer);
	sprintf(buffer, "DEBUG : loadDgt Current model allocation is [%d]", model_amount); simpleLog(buffer);



	if (0 == ogl_loadDgtModel(fileName, models))
	{
		simpleLog("DEBUG : -OK- zero return from function ogl_loadDgtModel ... downSampledData is loaded");
	}
	else
	{
		simpleLog("ERROR : non zero return from function  ogl_loadDgtModel");
	}

	simpleLog((const char*)"END TCL_CMD_SET_loadDgt");
	onDisplay();
	return TCL_OK;
}
void onDisplay()
{
#ifdef NO_GRAPHICS
	return;
#endif

	//clean anything on screen
	float dx = (float)width / height;
	glViewport(0, 0, width, height);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(-1.1 * dx, 1.1 * dx, -1.1, 1.1, -2, 2);

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glPushMatrix();
	if (models != NULL || context != NULL)
	{
		glRotatef(context[model_index].rotation[0], 1, 0, 0);
		glRotatef(context[model_index].rotation[1], 0, 1, 0);
		glRotatef(context[model_index].rotation[2], 0, 0, 1);
		glScalef(context[model_index].scale, context[model_index].scale, context[model_index].scale);
		glTranslatef(context[model_index].x, context[model_index].y, context[model_index].z);

		glColor3f(1.0, 1.0, 1.0);
		if (showModel != NONE && showModel != DOWN_SAMPLE_ONLY) //display model without any additional objects 
		{
			ogl_drawModel(models);
		}

		//based on which tab the user is on, it will display specific information. 
		// GUI tab switching updates showModel and this checks what onDisplay should draw
		switch (showModel)
		{
		case LANDMARK:
			drawDots();
			break;
		case ANCHOR:
			drawDots();
			drawAnchors();
			break;
		case DOWN_SAMPLE:
			drawDots();
			drawAnchors();
			simpleLog("DAVE LOOK HERE");
			simpleLogWriteModelToFile(models);

			ogl_drawDownSampleModel(models, dotRadius, &downSampleOffset);
			break;
		case CURVE:
			drawDots();
			drawCurves();
			break;
		case DOWN_SAMPLE_ONLY:
			ogl_drawDownSampleModel(models, dotRadius, &downSampleOffset);
			break;
		}
	}

	glPopMatrix();
	glFlush();

#ifdef _WIN32
	SwapBuffers(dc); //throw that sucker on the main screen
#elif __linux__
	glXSwapBuffers(__glDisplay__, __glWindow__);
#endif


}
int addDot_NO_TCL(double* xp, double* yp, double* zp)
{

	if (NULL == xp) { return -1; }
	if (NULL == yp) { return -1; }
	if (NULL == zp) { return -1; }

	// this code is copied from the TCL_IF function add (raw dots)- and shall be maintained 
	// to be functionally identical  to the add implementation except for the TCL
	// specific portions.  This function, as of 25 July 2020 is called only by the load .dgtFile function

	simpleLogBlankLine();
	simpleLog((const char*)"DGT ADD/SHAPE/RAWDOT");

	////////////////////////////////////////////

	simpleLog((const char*)"{dgt} function add ... rawdot");

	if (model_amount <= 0)
	{
		sprintf(buffer, "INFO : model amount is [%d]", model_amount);
		simpleLog(buffer);
		simpleLog("ERROR : add rawdot ... model amount is non positive");
		return -1;
	}
	else // model amount > 0 ... allocated 
	{
		int temp;
		temp = get_dot_slice_index();
		sprintf(buffer, "current dot slice id [%d]", temp);
		simpleLog(buffer);
		temp = dot_getListLengthAtCurrentSlice();
		sprintf(buffer, "INFO : building raw dot list : length is [%d]", temp);
		simpleLog(buffer);

		point_t p;
		p.x = *xp;
		p.y = *yp;
		p.z = *zp;
		sprintf(buffer, "  input argument dot  : <%10.6f %10.6f %10.6f>", (float)p.x, (float)p.y, (float)p.z); simpleLog(buffer);

		//printf("deltas[0]  <%f>\n", (double)deltas[0][0]);
		//printf("deltas[1]  <%f>\n", (double)deltas[0][1]);
		//printf("deltas[2]  <%f>\n", (double)deltas[0][2]);
		//printf("deltas[3]  <%f>\n", (double)deltas[0][3]);
		p.x = ogl_calCoordinate(p.x, 0, deltas[0]);
		p.y = ogl_calCoordinate(p.y, 1, deltas[0]);
		p.z = ogl_calCoordinate(p.z, 2, deltas[0]);

		sprintf(buffer, "  modified dot values : <%10.6f %10.6f %10.6f>", (float)p.x, (float)p.y, (float)p.z); simpleLog(buffer);

		if (0 != validateDot(&p))  // quit on error 
		{
			simpleLog("ERROR : function {dgt} add rawdot ... invalid dot");
			sprintf(buffer, "ERROR: cannot add dot at %f %f %f", p.x, p.y, p.z);
			simpleLog(buffer);
			return -1;
		}
		sprintf(buffer, "  modified dot : <%f %f %f>", (float)p.x, (float)p.y, (float)p.z);
		simpleLog(buffer);
		color_t c = defaultDotColor; //  { -1.0, -1.0, -1.0 };

		int listlength = -1;

		sprintf(buffer, "INFO : dots amount      [%d]", dotGetArraySize()); simpleLog(buffer);
		sprintf(buffer, "INFO : anchors amount   [%d]", get_anchor_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : curve amount     [%d]", get_curve_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : dots current slice index    [%d]", get_dot_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : anchors current slice index [%d]", get_anchor_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : curve current slice index   [%d]", get_curve_slice_index()); simpleLog(buffer);


		listlength = get_dot_size_for_slice_index(0);
		sprintf(buffer, "INFO : dot slice 0 list length    [%d]", listlength); simpleLog(buffer);
		listlength = get_dot_size_for_slice_index(1);
		sprintf(buffer, "INFO : dot slice 1 list length    [%d]", listlength); simpleLog(buffer);
		listlength = get_anchor_size_for_slice_index(0);
		sprintf(buffer, "INFO : anchor slice 0 list length [%d]", listlength); simpleLog(buffer);
		listlength = get_anchor_size_for_slice_index(1);
		sprintf(buffer, "INFO : anchor slice 1 list length [%d]", listlength); simpleLog(buffer);





		if (0 != dot_add(&p, &c)) // with newly calculated coordinates, adds dot into memory
		{
			simpleLog("ERROR : function add rawdot ... negative size from dot_add");
			return -1;
		}

		sprintf(buffer, "INFO : dots amount      [%d]", dotGetArraySize()); simpleLog(buffer);
		sprintf(buffer, "INFO : anchors amount   [%d]", get_anchor_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : curve amount     [%d]", get_curve_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : dots current slice index    [%d]", get_dot_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : anchors current slice index [%d]", get_anchor_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : curve current slice index   [%d]", get_curve_slice_index()); simpleLog(buffer);
		listlength = get_dot_size_for_slice_index(0);
		sprintf(buffer, "INFO : dot slice 0 list length    [%d]", listlength); simpleLog(buffer);
		listlength = get_dot_size_for_slice_index(1);
		sprintf(buffer, "INFO : dot slice 1 list length    [%d]", listlength); simpleLog(buffer);
		listlength = get_anchor_size_for_slice_index(0);
		sprintf(buffer, "INFO : anchor slice 0 list length [%d]", listlength); simpleLog(buffer);
		listlength = get_anchor_size_for_slice_index(1);
		sprintf(buffer, "INFO : anchor slice 1 list length [%d]", listlength); simpleLog(buffer);



	}
	simpleLog((const char*)"function {dgt} add rawdot ... end");
	return 0;
}

int addAnchor_NO_TCL(double* xp, double* yp, double* zp)
{

	if (NULL == xp) { return -1; }
	if (NULL == yp) { return -1; }
	if (NULL == zp) { return -1; }

	// this code is copied from the TCL_IF function add (raw anchors)- and shall be maintained 
	// to be functionally identical  to the add implementation except for the TCL
	// specific portions.  This function, as of 25 July 2020 is called only by the load .dgtFile function

	simpleLogBlankLine();
	simpleLog((const char*)"DGT ADD/SHAPE/RAW ANCHOR");

	////////////////////////////////////////////

	simpleLog((const char*)"{dgt} function add ... rawanchor");

	if (model_amount <= 0)
	{
		sprintf(buffer, "INFO : model amount is [%d]", model_amount);
		simpleLog(buffer);
		simpleLog("ERROR : add rawanchor ... model amount is non positive");
		return -1;
	}
	else // model amount > 0 ... allocated 
	{
		int temp;
		temp = get_anchor_slice_index();
		sprintf(buffer, "current anchor slice id [%d]", temp);
		simpleLog(buffer);
		temp = anchor_getListLengthAtCurrentSlice();

		sprintf(buffer, "INFO : building raw anchor list : length is [%d]", temp);
		simpleLog(buffer);

		point_t p;
		p.x = *xp;
		p.y = *yp;
		p.z = *zp;
		sprintf(buffer, "  input argument anchor  : <%10.6f %10.6f %10.6f>", (float)p.x, (float)p.y, (float)p.z); simpleLog(buffer);

		//printf("deltas[0]  <%f>\n", (double)deltas[0][0]);
		//printf("deltas[1]  <%f>\n", (double)deltas[0][1]);
		//printf("deltas[2]  <%f>\n", (double)deltas[0][2]);
		//printf("deltas[3]  <%f>\n", (double)deltas[0][3]);
		p.x = ogl_calCoordinate(p.x, 0, deltas[0]);
		p.y = ogl_calCoordinate(p.y, 1, deltas[0]);
		p.z = ogl_calCoordinate(p.z, 2, deltas[0]);

		sprintf(buffer, "  modified anchor values : <%10.6f %10.6f %10.6f>", (float)p.x, (float)p.y, (float)p.z); simpleLog(buffer);

		if (0 != validateDot(&p))  // quit on error 
		{
			simpleLog("ERROR : function {dgt} add rawanchor ... invalid anchor");
			sprintf(buffer, "ERROR: cannot add dot at %f %f %f", p.x, p.y, p.z);
			simpleLog(buffer);
			return -1;
		}
		sprintf(buffer, "  modified anchor : <%f %f %f>", (float)p.x, (float)p.y, (float)p.z);
		simpleLog(buffer);
		color_t c = defaultAnchorColor; //  { -1.0, -1.0, -1.0 };


		int listlength = -1;

		sprintf(buffer, "INFO : dots amount      [%d]", dotGetArraySize()); simpleLog(buffer);
		sprintf(buffer, "INFO : anchors amount   [%d]", get_anchor_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : curve amount     [%d]", get_curve_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : dots current slice index    [%d]", get_dot_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : anchors current slice index [%d]", get_anchor_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : curve current slice index   [%d]", get_curve_slice_index()); simpleLog(buffer);


		listlength = get_dot_size_for_slice_index(0);
		sprintf(buffer, "INFO : dot slice 0 list length    [%d]", listlength); simpleLog(buffer);
		listlength = get_dot_size_for_slice_index(1);
		sprintf(buffer, "INFO : dot slice 1 list length    [%d]", listlength); simpleLog(buffer);
		listlength = get_anchor_size_for_slice_index(0);
		sprintf(buffer, "INFO : anchor slice 0 list length [%d]", listlength); simpleLog(buffer);
		listlength = get_anchor_size_for_slice_index(1);
		sprintf(buffer, "INFO : anchor slice 1 list length [%d]", listlength); simpleLog(buffer);


		if (0 != anchor_add(&p, &c)) // with newly calculated coordinates, adds anchor into memory
		{
			simpleLog("ERROR : function add rawanchor ... negative size from anchor_add");
			return -1;
		}

		sprintf(buffer, "INFO : dots amount      [%d]", dotGetArraySize()); simpleLog(buffer);
		sprintf(buffer, "INFO : anchors amount   [%d]", get_anchor_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : curve amount     [%d]", get_curve_slice_amount()); simpleLog(buffer);
		sprintf(buffer, "INFO : dots current slice index    [%d]", get_dot_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : anchors current slice index [%d]", get_anchor_slice_index()); simpleLog(buffer);
		sprintf(buffer, "INFO : curve current slice index   [%d]", get_curve_slice_index()); simpleLog(buffer);
		listlength = get_dot_size_for_slice_index(0);
		sprintf(buffer, "INFO : dot slice 0 list length    [%d]", listlength); simpleLog(buffer);
		listlength = get_dot_size_for_slice_index(1);
		sprintf(buffer, "INFO : dot slice 1 list length    [%d]", listlength); simpleLog(buffer);
		listlength = get_anchor_size_for_slice_index(0);
		sprintf(buffer, "INFO : anchor slice 0 list length [%d]", listlength); simpleLog(buffer);
		listlength = get_anchor_size_for_slice_index(1);
		sprintf(buffer, "INFO : anchor slice 1 list length [%d]", listlength); simpleLog(buffer);

	}
	simpleLog((const char*)"function {dgt} add rawanchor ... end");
	return 0;
}


// for the landmarks associated with the current dot array slice
// explicitly return all of the landmarks to the default color
// this is applicable when switching from the GUI curves tab to the 
// digitize tab
void changeLandmarkDotColor()

{
	simpleLog("INFO : changeLandmarkDotColor ... start");
	if (model_amount == 0)
	{
		simpleLog("INFO :changeLandmarkDotColor ... model_amount is 0, nothing to do  .. .returning");
		return;
	}

	dotSetArrayIndex(model_index);


	sprintf(buffer, "changeLandmarkDotColor (land marks) using  current slice of [%d] {zero based}", get_dot_slice_index());
	simpleLog(buffer);

	dot_t* n = dot_get(get_dot_slice_index());
	if (NULL == n)
	{
		simpleLog("WARNING : null pointer for dot returned from dot_get() ");
		return;
	}

	sprintf(buffer, "DEBUG : Default color parameters are RGB : <%10.f   %10.6f   %10.6f>",
		defaultDotColor.r, defaultDotColor.g, defaultDotColor.b);
	simpleLog(buffer);

	int dotId = 1;
	while (n != NULL) // while we haven't reached the end
	{
		//  if dot type is CURVE (as is generated by the curves code,
		//  and the GUI tab is not on the Curves tab, then ignore this dot
		//  But curves are contained in their own data structure. HOW DOES THIS HAPPEN ??

		if (n->type == CURVE && showModel != CURVE)
		{
			n = n->next;
			continue;
		}



		// if the gui is on the digitize tab 
		//if (LANDMARK == showModel )
		//{
		n->c.r = defaultDotColor.r;
		n->c.g = defaultDotColor.g;
		n->c.b = defaultDotColor.b;
		//}

		sprintf(buffer, "DEBUG : changed dot color for dot id [%d]", dotId);
		simpleLog(buffer);


		dotId++;
		n = n->next;
	}
	simpleLog("INFO : changeLandmarkDotColor ... end");
	simpleLogBlankLine();
	return;
}


void changeDotColorToSlider(int dotIndex)
{

	simpleLog("INFO : changeDotColorToSlider start");
	sprintf(buffer, "DEBUG : changing color of dot index [%d] for slice [%d] to blue", dotIndex, get_dot_slice_index());
	simpleLog(buffer);
	dot_t* sliderDot = get_dot_at_index_current_slice(dotIndex);


	sliderDot->c.r = 0;
	sliderDot->c.g = 0;
	sliderDot->c.b = 1;

	simpleLog("INFO : changeDotColorToSlider ... end");
}
