#pragma once
#ifndef TCL_STATE_H
#define TCL_STATE_H

#include "def_ZARF_9.h"

extern const char COMPILE_INFORMATION[];
extern const char TCL_IF_VERSION_INFORMATION[];
extern const char* tcl_ifVersionPtr;

/* Fixed-capacity global storage limits (CENG-03, D-01) */
#define GBL_LANDMARK_SET_CAPACITY 25   /* rows in GBL_LANDMARK_SET[25][3] */
#define GBL_CURVE_SET_CAPACITY 10      /* logical max curves; array dim stays 25 */
#define GBL_MODEL_SLOTS 5              /* model pointer mirror slots */
#define GBL_CONTEXT_SLOTS 5            /* context pointer mirror slots */
#define GBL_CURVE_SLOTS 6              /* curve pointer table slots */
#define GBL_DELTAS_CAPACITY 1000       /* rows in deltas[1000][4] */

extern float GBL_LANDMARK_SET[GBL_LANDMARK_SET_CAPACITY][3];
extern const float* pointerTO_GBL_LANDMARK_SET;
extern int GBL_LANDMARK_SET_MAX_ROWS;
extern int GBL_LANDMARK_SET_NUMBER_OF_ROWS;

extern float GBL_CURVE_SET[GBL_LANDMARK_SET_CAPACITY][3]; /* physical dim 25, logical max GBL_CURVE_SET_CAPACITY */
extern const float* pointerTO_GBL_CURVE_SET;
extern int GBL_CURVE_SET_MAX_ROWS;
extern int GBL_CURVE_SET_NUMBER_OF_ROWS;

extern model_t* GBL_PTR_TO_A_MODEL;
extern model_t* GBL_PTR_MODEL[GBL_MODEL_SLOTS];
extern context_t* GBL_PTR_CONTEXT[GBL_CONTEXT_SLOTS];

extern int GBL_LANDMARKS_ROWS;
extern int GBL_LANDMARKS_COLS;
extern int GBL_ANCHOR_ROWS;
extern int GBL_ANCHOR_COLS;

extern int GBL_LANDMARKS_NUM_SPECIMENS;
extern int GBL_CURVES_NUMBER_OF_CURVES;
extern int GBL_CURVES_LENGTH;
extern int GBL_CURVES_NUM_SPECIMENS;

extern int GBL_SET_NUMBER_OF_LANDMARKS;
extern int GBL_SET_NUMBER_OF_ANCHORS;

extern float GBL_INWORK_LABEL_SCALEFACTOR_MPY;
extern float GBL_INWORK_LABEL_SCALEFACTOR_ADD;
extern float GBL_INWORK_CURVE_SCALEFACTOR_MPY;
extern float GBL_INWORK_CURVE_SCALEFACTOR_ADD;

extern float GBL_ROTATION_ANGLE_X;
extern float GBL_ROTATION_ANGLE_Y;

extern int GBL_ENABLE_TCL_OBJECT_LOGGING;

extern curve_t* GBL_PTR_CURVE[GBL_CURVE_SLOTS];

extern model_t* models;
extern context_t* context;

extern float deltas[GBL_DELTAS_CAPACITY][4];

extern int model_index;
extern int model_amount;
extern int temp_index;
extern show_mode_t showModel;

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

extern int UT_MY_INTEGER_VALUE;

extern char messageBuffer[128];
extern char buffer[1024];

void clear_GBL_LANDMARK_SET(void);
void clear_GBL_CURVE_SET(void);

int clear_model(model_t* m);
int clear_context(context_t* c);
int clearCurve(curve_t* c);
int development_function(int selector);
int snapshot(void);
int drawTest(void);
int ut_test_ogl_loadModel(const char* filename, model_t* model);

int resetContext(int id, float maxXY);

#endif
