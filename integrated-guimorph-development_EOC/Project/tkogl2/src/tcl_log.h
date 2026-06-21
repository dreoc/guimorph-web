#pragma once
#ifndef TCL_LOG_H
#define TCL_LOG_H

#include "def_ZARF_9.h"

int simpleLog_Open(void);
int simpleLog_Close(void);
int simpleLogBlankLine(void);
int simpleLog(const char* yC);
int simpleLog_Obj(Tcl_Obj* p);

int commandStream_OpenFile(void);
int commandStream_CloseFile(void);
int commandStream_WriteStringToFile(const char* s);
int commandStream_WriteObjectToFile(const Tcl_Obj* const p);
int TclIf_LogCommands(int objc, Tcl_Obj* const objv[]);

int simpleLogWriteModelToFile(model_t* m);
int simpleLogWriteContextToFile(context_t* c);
int simpleLogWriteCurveToFile(curve_t* c);
void simpleLogWriteAnchorsToFile(void);
void simpleLogWriteLandmarksToFile(void);

void simpleLogCurveInformation(void);
void simpleLogDotInformation(void);
void simpleLogOglModelInformation(void);
void simpleLogOglModelPlyInformation(void);
void simpleLogStatisticsInformation(void);
void simpleLogTclIfInformation(void);
void simpleLogOglInformation(void);

#endif
