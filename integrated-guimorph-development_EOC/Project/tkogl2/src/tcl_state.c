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
#include "tcl_state.h"
#include "tcl_log.h"
#include "tcl_window.h"

extern const int GBL_RTN_SUCCESS;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
// Developers : it is your responsibility to update this string each time you compile the library
// for purposes of building an R package for the GUI Morph Tool
const char COMPILE_INFORMATION[] = "Library compile information : FRESH BUILD " __DATE__ " " __TIME__;
//
// The  following line should be updated based on edits to this file - not for simple recompilation 
// of the library
const char TCL_IF_VERSION_INFORMATION[] = "File tcl_if : edit date is 15 AUGUST 2020 04:22 PM";
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

float GBL_LANDMARK_SET[GBL_LANDMARK_SET_CAPACITY][3];
const float* pointerTO_GBL_LANDMARK_SET = &GBL_LANDMARK_SET[0][0];
int GBL_LANDMARK_SET_MAX_ROWS = GBL_LANDMARK_SET_CAPACITY;
int GBL_LANDMARK_SET_NUMBER_OF_ROWS = 0;

const char* tcl_ifVersionPtr = TCL_IF_VERSION_INFORMATION;
float GBL_CURVE_SET[GBL_LANDMARK_SET_CAPACITY][3];
const float* pointerTO_GBL_CURVE_SET = &GBL_CURVE_SET[0][0];
int GBL_CURVE_SET_MAX_ROWS = GBL_CURVE_SET_CAPACITY;
int GBL_CURVE_SET_NUMBER_OF_ROWS = 0;

model_t* GBL_PTR_TO_A_MODEL;

model_t* GBL_PTR_MODEL[GBL_MODEL_SLOTS] = { NULL };
context_t* GBL_PTR_CONTEXT[GBL_CONTEXT_SLOTS] = { NULL };

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


curve_t* GBL_PTR_CURVE[GBL_CURVE_SLOTS] = { NULL };

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

model_t* models = NULL;
context_t* context = NULL;

float deltas[GBL_DELTAS_CAPACITY][4];

int model_index = 0;
int model_amount = 0;
int temp_index = 0;
show_mode_t showModel = LANDMARK;

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

	simpleLogWriteModelToFile(GBL_PTR_MODEL[0]);

	simpleLog("----- snapshot ------ end");
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
