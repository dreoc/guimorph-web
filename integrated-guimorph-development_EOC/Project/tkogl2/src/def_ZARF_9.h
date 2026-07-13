#pragma once
#ifndef DEF_H
#define DEF_H

// NOTE: header names use canonical casing. Windows is case-insensitive, but a
// MinGW-w64 cross-compile on a case-sensitive (Linux/WSL) filesystem requires
// the exact case: <windows.h> and the <GL/...> directory.
#include <windows.h>
#include <tcl.h>
#include <tclDecls.h>
#include <GL/glut.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include "RunTime_Defines_ZARF_9.h"
#include "main.h"


typedef struct point_t
{
	GLdouble x;
	GLdouble y;
	GLdouble z;
} point_t;

typedef struct curve_t
{
	point_t* points[3];
	point_t* lines1;
	point_t* lines2;
	int line1Size;
	int line2Size;
	int pointNum;
	struct curve_t* next;
} curve_t;

typedef struct color_t
{
	GLdouble r;
	GLdouble g;
	GLdouble b;
} color_t;

typedef struct model_t
{
	int thisModelIntegerCount;
	float* vertex;
	float* color;
	float* normal;
	float* dsVertex; //down sample vertex
	int count;       // vertex count passed to glDrawArrays(GL_TRIANGLES, 0, count): three vertices per triangle (incremented by 3 per emitted triangle at PLY load), distinct from vertexCountActual and dsCount
	int vertexCountActual;
	int dsCount;      //the number of down sample vertices
	float max[3];
	float min[3];
	float originalMeanValues[3];
	float dsMax[3];
	float dsMin[3];
	float delta[4];
	int vertexSize;
	int colorSize;
	int normalSize;
	int dsVertexSize;            // how is this different from dsCount?
	float largestScaleFactor;    // derived from min / max data 
	char fileName[256];          // this will contain the specimen file name

} model_t;

enum
{
	X,
	Y,
	Z
};

typedef enum {
	NONE,
	SPECIMEN,
	LANDMARK,
	DOWN_SAMPLE,
	DOWN_SAMPLE_ONLY,
	CURVE,
	ANCHOR,
	ALL
} show_mode_t;

typedef struct dot_t
{
	point_t p;
	color_t c;
	show_mode_t type;
	struct dot_t* next;
} dot_t;

typedef struct {
	float x;
	float y;
	float z;
	float scale;
	float rotation[3];
} context_t;



void* ALLOCATE_WRAPPER(unsigned int howMuch);
void FREE_WRAPPER(void* pointer);




#define FREE(p) if (p != NULL) {free(p); p = NULL;}

float getRealZ(float x, float y, float z);


int ogl_drawLabel(point_t* p, color_t* c, int id, GLdouble dotRadius, float z);
int ogl_drawDot(point_t* p, color_t* c, GLdouble radius);
int ogl_drawLine(point_t* line, int size);
float ogl_calCoordinate(float value, int id, float* delta);


int ogl_init();
int ogl_enableLight();
int ogl_disableLight();
int ogl_getObjCoordinate(int x, int y, GLdouble* posX, GLdouble* posY, GLdouble* posZ, char* buf);
int ogl_loadDgtModel(const char* filename, model_t* model);
int ogl_loadModel(const char* filename, model_t* model);
int ogl_loadDownSampleModel(double* flattenedVertices, unsigned int totalSize, model_t* model);
int ogl_drawModel(model_t* model);
int ogl_drawDownSampleModel(model_t* model, GLdouble radius, point_t* downSampleOffset);
int ogl_loadLandMark(const char* filename, model_t* models, int model_id, int amount, float** deltas);
int ogl_eraseDownSampleDataForModel(model_t* model);
int ogl_eraseVertexDataForModel(model_t* model);

int clear_context(context_t* c);

int clear_deltas();

curve_t* curve_create();
curve_t* curve_get();
curve_t* get_curveAtIndex(int id);
curve_t** getPointerToCurveVector();

float absf(float a, float b);
int curve_addDot(int id, dot_t* d);
int curve_buildLine(point_t* p1, point_t* p2, point_t** line);
int curve_getDotId();
int curve_release(curve_t* c);

int set_curve_slice_amount(int amount);
int get_curve_slice_amount();
int set_curve_slice_index(int id);
int get_curve_slice_id();

int curveAllocateArray(int numberOfCurves);   //allocates memory, releases any prior memory
int curveReleaseArray();
int curveSetArrayIndex(int whichIndex);
int initialize_Curve(curve_t* c);



// All functions return a negative on an error, intent is -1, or 0 (possibly greater than zero on success
// functions return ing pointers return NULL on any error ... else a valid pointer
// all integer arguments MUST be >= 0 to be valid
//

// THERE ARE TOO MANY FUNCTIONS ! LOTS OF REPLICATION ! 

dot_t* dot_get(int id);
dot_t* anchor_get(int id);

dot_t* dot_get_selected();
dot_t* anchor_get_selected();
dot_t* dotGetPointerToTheSelectedDot();
dot_t* anchorGetPointerToTheSelectedDot();
dot_t* dot_get_dot(int id, int pid);

int dotAllocateList(int listLength);
int dotReleaseList();

int anchorAllocateList(int amount);
int anchorReleaseList();

int set_dot_slice_amount(int amount);
int set_anchors_slice_amount(int amount);

int dotGetArraySize();
int dotGetSelectedIndex();

int anchorGetArraySize();
int anchorGetSelectedIndex();

int get_dot_size_for_slice_index(int index);
int get_anchor_size_for_slice_index(int index);

int dotSetArrayIndex(int whichIndex);
int anchorSetArrayIndex(int whichIndex);



// The below functions for dots and anchors are NOT my preferred functions to use
// The below functions for dots and anchors are NOT my preferred functions to use

int get_dot_slice_amount();
int get_anchor_slice_amount();

int get_dot_selected_id();
int get_dot_slice_index();

int dot_size();
int anchor_size();

int dot_add(point_t * p, color_t * c);
int anchor_add(point_t* p, color_t* c);

int dot_color(color_t* c);
int anchor_color(color_t* c);

int dot_del(point_t* p);
int anchor_del(point_t* p);

int dot_del_selected();
int anchor_del_selected();

int dot_move(point_t* p);
int anchor_move(point_t* p);

int dot_select(point_t* p, float dotRadius);
int anchor_select(point_t* p, float dotRadius);   

int dot_slice_index(int id);
int anchor_slice_index(int id);

int dots_free();
int anchors_free();

int dot_selected_id();
int anchors_selected_id();

int get_dot_slice_index();
int get_anchor_slice_index();

int get_dot_selected_id();
int get_anchor_selected_id();

int get_anchor_slice_id();
int get_anchor_slice_index();

int isDotArrayNotNull();
int isDotArrayNull();





struct Tcl_Obj;
int simpleLog(const char* yC);
int simpleLog_Close();
int simpleLog_Open(); 
int simpleLogBlankLine();
int simpleLog_Obj(Tcl_Obj* const p);
int simpleLogWriteContextToFile(context_t* c);
int simpleLogWriteModelToFile(model_t* m);

int commandStream_OpenFile();
int commandStream_CloseFile();
int commandStream_WriteStringToFile(const char* s);
int commandStream_WriteObjectToFile(const Tcl_Obj* const p);
int TclIf_LogCommands(int objc, Tcl_Obj* const objv[]);


int validateDot(point_t* p);
int development_function(int selector);

int resetModel(model_t* model);

int initialize_state( int selector, int option);
int snapshot();

int clearCurve(curve_t* c);
curve_t* get_curveAtIndex(int id);
int get_curve_slice_index();
int get_curve_slice_id();

#ifdef STAND_ALONE_TOOL
int ut_show_dot(dot_t* d);
int ut_show_point(point_t* p);
int ut_show_color(color_t* c);
int ut_show_show_mode_t(show_mode_t* t);
int ut_showCurve(curve_t* c);
int ut_show_Model(model_t* m); // on the screen 
#endif


int ut_test_ogl_loadModel(const char* filename, model_t* model);
dot_t* get_dot_at_index_current_slice(int index);
int dot_getListLengthAtCurrentSlice();
int anchor_getListLengthAtCurrentSlice();
int simpleLogWriteCurveToFile(curve_t* c);

void drawDots();
void drawAnchors();
void drawGrid();
void onDisplay();
void drawCurves();
int drawTest();

void clear_GBL_CURVE_SET();
void clear_GBL_LANDMARK_SET();
void simpleLogTclIfInformation();
void simpleLogCurveInformation();
void simpleLogDotInformation();
void simpleLogOglInformation();
void simpleLogOglModelInformation();
void simpleLogOglModelPlyInformation();
void simpleLogStatisticsInformation();
#endif