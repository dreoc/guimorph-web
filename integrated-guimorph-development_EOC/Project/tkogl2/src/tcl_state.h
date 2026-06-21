#pragma once
#ifndef TCL_STATE_H
#define TCL_STATE_H

#include "def_ZARF_9.h"

extern const char COMPILE_INFORMATION[];
extern const char TCL_IF_VERSION_INFORMATION[];
extern const char* tcl_ifVersionPtr;

extern float GBL_LANDMARK_SET[25][3];
extern const float* pointerTO_GBL_LANDMARK_SET;
extern int GBL_LANDMARK_SET_MAX_ROWS;
extern int GBL_LANDMARK_SET_NUMBER_OF_ROWS;

extern float GBL_CURVE_SET[25][3];
extern const float* pointerTO_GBL_CURVE_SET;
extern int GBL_CURVE_SET_MAX_ROWS;
extern int GBL_CURVE_SET_NUMBER_OF_ROWS;

extern model_t* GBL_PTR_TO_A_MODEL;
extern model_t* GBL_PTR_MODEL_1;
extern model_t* GBL_PTR_MODEL_2;
extern model_t* GBL_PTR_MODEL_3;
extern model_t* GBL_PTR_MODEL_4;
extern model_t* GBL_PTR_MODEL_5;

extern context_t* GBL_PTR_CONTEXT_1;
extern context_t* GBL_PTR_CONTEXT_2;
extern context_t* GBL_PTR_CONTEXT_3;
extern context_t* GBL_PTR_CONTEXT_4;
extern context_t* GBL_PTR_CONTEXT_5;

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

extern curve_t* GBL_PTR_CURVE_1;
extern curve_t* GBL_PTR_CURVE_2;
extern curve_t* GBL_PTR_CURVE_3;
extern curve_t* GBL_PTR_CURVE_4;
extern curve_t* GBL_PTR_CURVE_5;
extern curve_t* GBL_PTR_CURVE_6;

extern model_t* models;
extern context_t* context;

extern float deltas[1000][4];

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
void show_GBL_LANDMARK_SET(void);
void clear_GBL_CURVE_SET(void);
void show_GBL_CURVE_SET(void);

int clear_model(model_t* m);
int clear_context(context_t* c);
int clearCurve(curve_t* c);
int development_function(int selector);
int snapshot(void);
int drawTest(void);
int showPoint(point_t* p);
int ut_show_Model(model_t* m);
int ut_test_ogl_loadModel(const char* filename, model_t* model);

int resetContext(int id, float maxXY);

#endif
