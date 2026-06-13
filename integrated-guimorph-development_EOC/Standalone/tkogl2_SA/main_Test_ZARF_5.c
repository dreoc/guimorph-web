

#include<stdio.h>
#include <string.h>

#include "def.h"
#include "RunTime_Defines.h"

//#include "statisticsTestFunctions.h"

#ifdef STAND_ALONE_TOOL
extern int add(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
extern int set(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
extern int setSpecimen(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
extern int show(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
extern int setWindow(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
extern int setDownSample(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
extern int setDot(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
extern int del(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
extern int loadDgt(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
extern int directive(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
extern int setWindow(ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[]);
#endif



// these 'stuffer' functions are provided to mimic the function calls from the R GuiMorph package
// they provide for the population of TCL structures as is performed in R and then
// invoke the appropriate functions within the 'tcl_if.c' file
// Also, the commands as identified in the test code (below) are intended to be identical  to 
// commands which may be written in the GuiMorph tool - thus allwoing for one to one command 
//execution in this test environment and in the R code. 
// Well, that is the intent anyway 
//

void stuffer_add_integer(char* command, char* shape, int arg1, int arg2, int arg3);
void stuffer_add_double(char* command, char* shape, double arg1, double arg2, double arg3);
void stuffer_add_string(char* command, char* shape, char* arg1, int arg2, int arg3);
void stuffer_set_specimen_integer(char* command, char* shape, int arg1, int arg2, int arg3);
void stuffer_set_specimen_string_double(char* command, char* shape, char* arg1, double arg2, double  arg3);
void stuffer_set_window_integer(char* command, char* shape, int arg1, int arg2, int arg3);
void stuffer_set_window_string(char* command, char* shape, char* arg1, int arg2, int arg3);
void stuffer_del_integer(char* command, char* shape, int arg1, int arg2, int arg3);
void stuffer_set_dot_integer(char* command, char* shape, int arg1, int arg2, int arg3);
void stuffer_set_dot_double(char* command, char* shape, double arg1, double arg2, double arg3);
void stuffer_show_string(char* command, char* shape, char* arg1, int arg2, int arg3);
void stuffer_downsample_integer(char* command, char* shape, int arg1, int arg2, int arg3);



// These are structures needed to simulate the TCL/TK  environment in the R
// GuiMorph tool.
Tcl_ObjType commandType;
Tcl_ObjType doubleType;
Tcl_ObjType integerType;
Tcl_ObjType* DoubleTypePointer = &doubleType;
Tcl_ObjType* IntegerTypePointer = &integerType;
Tcl_ObjType* CommandTypePointer = &commandType;
ClientData clientData;
Tcl_Interp* testInterp = NULL;


int test_statisticsFunctions();




int main(int argc, char* argv[])
{
	printf("\nThis is the gui morph stand alone tool 07 June 2020  ZARF_5 ... \n");

	// setup tcl interface for stand alone tool which does not use the TCL library
	// 
	DoubleTypePointer->name = "double";
	IntegerTypePointer->name = "int";
	CommandTypePointer->name = "cmmd";

	DoubleTypePointer->freeIntRepProc = NULL;
	DoubleTypePointer->dupIntRepProc = NULL;
	DoubleTypePointer->updateStringProc = NULL;
	DoubleTypePointer->setFromAnyProc = NULL;

	IntegerTypePointer->freeIntRepProc = NULL;
	IntegerTypePointer->dupIntRepProc = NULL;
	IntegerTypePointer->updateStringProc = NULL;
	IntegerTypePointer->setFromAnyProc = NULL;

	CommandTypePointer->freeIntRepProc = NULL;
	CommandTypePointer->dupIntRepProc = NULL;
	CommandTypePointer->updateStringProc = NULL;
	CommandTypePointer->setFromAnyProc = NULL;
	const int NA = -1;


	// a test of the dot allocation : turned on/off at developer discretion
	int rv = -1;
	rv = dotAllocateList(100);
	if (0 == rv)
	{
		printf("SUCCESS ! \n");
	}
	else
	{
		printf("ERROR ! \n");
	}


	// These are the files and the directories used on my development machine for testing
	// 
	char dgtFileName_1[] = "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/DavesTest_03_June_2020_9_Landmarks_5_Curves.dgt";
	char* dgtFptr = dgtFileName_1;

	char fileName_1[] = "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/A6.1.PLY";
	char* f1 = fileName_1;

	char fileName_2[] = "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/B7.1.PLY";
	char* f2 = fileName_2;

	printf("file name 1 is <%s>\n", f1);
	printf("file name 2 is <%s>\n", f2);


	// Manually edit the test flags as desired 
	// as of June 2020 this is the intended mathod of use 

	const int LOOP_COUNTS = 1;   // and edit this as desred. Warning I have observed memory issues when this is > 1 !

	int test_00 = 0;
	int test_01 = 0;
	int test_02 = 0;
	int test_03 = 0;
	int test_04 = 0;
	int test_05 = 0;
	int test_06 = 0;
	int test_07 = 0;
	int test_08 = 0;
	int test_09 = 0;
	int test_10 = 0;
	int test_11 = 1;  // ALLOCATE WRAPPER TEST ... use intended is in the IDE with a break point ! 
	int test_12 = 0;
	int test_13 = 0;
	int test_14 = 0;   // special test for log messages and setting function return values

	int test_15 = 0;   /// low level tests of ogl_loadDownSamplModel ... VERY low level 

	int test_16 = 0;   // statiscics 


	if (0)  // maunally edit as desired ... that is the intended method of use 
	{
		test_00 = 1;
		test_01 = 1;
		test_02 = 1;
		test_03 = 1;
		test_04 = 1;
		test_05 = 1;
		test_06 = 1;
		test_07 = 1;
		test_08 = 1;
		test_09 = 1;
		test_10 = 1;
		test_11 = 0;     // <----- read the directions of for intended use  ! ..... 
		test_12 = 1;
		test_13 = 0;
		test_14 = 0;
		test_15 = 0;
		test_16 = 0;
	}




	for (int ii = 0; ii < LOOP_COUNTS; ii++)
	{
		printf("\n\nEXECUTION LOOP [%3d] \n", ii);


		if (1 == test_01)
		{
			// my standard start up sequence
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);
			stuffer_add_integer("add", "initialize", NA, NA, -NA);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);




			// the next test is to assign landmark data.
			// these values were generated by using the R gui and placing landmarks
			// the dgt file was 'daves_dgt_WITH_CURVES.dgt' 

			// convey landmark dimensionality
			// this test uses the extended interface I added 
			stuffer_add_integer("add", "InfoLandmarks", 5, 3, 2);

			stuffer_add_integer("add", "InfoLandmarks_setN", 1, 2, NA);

			stuffer_add_double("add", "rawdot", -20.054497, -37.918907, -3.670341);
			stuffer_add_double("add", "rawdot", -7.808026, -36.100124, -3.915579);
			stuffer_add_double("add", "rawdot", -5.382958, -26.884939, -4.359759);
			stuffer_add_double("add", "rawdot", -2.109146, -39.252674, -4.167464);
			stuffer_add_double("add", "rawdot", -3.32168, -55.985489, -3.792133);


			stuffer_add_string("add", "specimen", f2, 1, NA);
			stuffer_add_integer("add", "InfoLandmarks_setN", 2, 2, NA);
			stuffer_add_double("add", "rawdot", -12.235758, -32.720879, 0.714147);
			stuffer_add_double("add", "rawdot", -1.019839, -33.35817, 0.060274);
			stuffer_add_double("add", "rawdot", -1.911993, -44.701553, -0.004728);
			stuffer_add_double("add", "rawdot", -8.029779, -48.142807, 0.080747);
			stuffer_add_double("add", "rawdot", -10.706311, -40.495575, 0.689502);

			stuffer_add_integer("add", "InfoLandmarks_complete", NA, NA, NA);
			// with the above line executed - check the log file - there should be
			// no ERROR entries in the log file.
			// if there are ERROR entries then something is still incorrect in the 
			// code ... investigate this.
			// 04 June 2020 - manually verified that there are no ERROR entries in the log file




			stuffer_set_window_integer("setWindow", "curve", NA, NA, NA);

			// there are two curves : three rows and two specimens

			stuffer_add_integer("add", "InfoCurves", 2, 3, 2);
			// set up for curve on the first specimen
			stuffer_add_integer("add", "SetCurveIndex", 0, NA, NA);
			stuffer_add_integer("add", "curve", 1, 5, 4);
			stuffer_add_integer("add", "curve", 2, 3, 4);
			stuffer_add_integer("add", "InfoCurves_complete", NA, NA, NA);

			curve_t* testCurve = NULL;
			testCurve = get_curveAtIndex(0);
			// manually inspect the curve data here ...
			// that is ... in the IDE place a breakboint and stop execution
			ut_showCurve(testCurve);
			printf("\n");

			stuffer_add_integer("add", "SetCurveIndex", 1, NA, NA);
			stuffer_add_integer("add", "curve", 2, 3, 4);
			stuffer_add_integer("add", "curve", 1, 5, 4);
			stuffer_add_integer("add", "InfoCurves_complete", NA, NA, NA);

			// manually inspect the curve data here ...
			// that is ... in the IDE place a breakboint and stop execution

			ut_showCurve(testCurve);
			printf("\n");


			// the gui and the c code should now be in a state that would
			// exist after reading a .dgt file and the R function 'draw.curves'
			// has just completed
			// 



			stuffer_add_integer("add", "snapshot", 0, NA, NA);
			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);
		}
		if (1 == test_02)
		{
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);

			stuffer_add_integer("add", "initialize", NA, NA, -NA);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);

			char lmFileName[] = "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/Landmarks_9_A_6_1.lm_pts";
			char* fp = lmFileName;


			//  this uses a unit test feature
			// after execution it is the responsibility of a main program (like this test main)
			// to extract the data suitable for use in making calls to 'rawdots' option
			// in tcl_if.
			// This main test program does NOT perform this action
			stuffer_add_string("add", "loadLandmarkFormFile", fp, NA, NA);  // watch this option

			// snapshot capability might record ERROR .. when there are none
			// since it attempts to record many pieces of data that might not 
			// have been setup in the test program ... so it might be turned off ...
			// stuffer_add_integer("add", "snapshot", 0, NA, NA);

			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);

		}
		if (1 == test_03)
		{
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);

			stuffer_add_integer("add", "initialize", NA, NA, -NA);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);

			char lmFileName[] = "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/CurvesForLandmarks_9_A_6_1.CURVE_PTS";
			char* fp = lmFileName;


			//  this uses a unit test feature
			// after execution it is the responsibility of a main program (like this test main)
			// to extract the data suitable for use in making calls to 'rawdots' option
			// in tcl_if.
			// This main test program does NOT perform this action
			stuffer_add_string("add", "LoadCurvesFromFile", fp, NA, NA);  // watch this option

			// snapshot capability might record ERROR .. when there are none
			// since it attempts to record many pieces of data that might not 
			// have been setup in the test program ... so it might be turned off ...
			// stuffer_add_integer("add", "snapshot", 0, NA, NA);

			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);

		}
		if (1 == test_04)
		{
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);
			stuffer_add_integer("add", "initialize", NA, NA, -NA);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);


			stuffer_show_string("show", "landmark", "xyz", 0, NA);



			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);
		}
		if (1 == test_05)
		{
			// my standard start up sequence
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);

			stuffer_add_integer("add", "initialize", NA, NA, -NA);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);



			/////stuffer_del_integer("del", "specimen", 0, 0, NA);


			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);
		}
		if (1 == test_06)
		{
			// these tests verify that the setWindow function does no crash 
			// in exection
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);


			stuffer_add_integer("add", "initialize", NA, NA, -NA);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);


			stuffer_set_window_integer("setWindow", "id", 1, NA, NA);
			stuffer_set_window_integer("setWindow", "size", 400, 400, NA);
			stuffer_set_window_string("setWindow", "mode", "digitize", NA, NA);
			stuffer_set_window_string("setWindow", "mode", "anchor", NA, NA);
			stuffer_set_window_string("setWindow", "mode", "surface", NA, NA);
			stuffer_set_window_string("setWindow", "mode", "geomorpj", NA, NA);
			stuffer_set_window_string("setWindow", "mode", "surfaceonly", NA, NA);
			stuffer_set_window_string("setWindow", "mode", "curve", NA, NA);
			stuffer_set_window_string("setWindow", "mode", "none", NA, NA);
			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);
		}
		if (1 == test_07)
		{
			// these tests verify that the setDot function does no crash 
			// in exection

			// my standard start up sequence
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);

			stuffer_add_integer("add", "initialize", NA, NA, -NA);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);

			stuffer_set_dot_integer("setDot", "selected", 3, 5, NA);
			stuffer_set_dot_double("setDot", "coordinate", 1.1, 3.3, 5.5);
			stuffer_set_dot_double("setDot", "dcolor", 0.5, 0.6, 0.7);
			stuffer_set_dot_double("setDot", "acolor", 0.1, 0.3, 0.5);
			stuffer_set_dot_double("setDot", "color", 0.2, 0.4, 0.6);
			stuffer_set_dot_double("setDot", "anchorColor", 0.1, 0.3, 0.5);

			stuffer_set_dot_integer("setDot", "labeled", 9, NA, NA);
			stuffer_set_dot_integer("setDot", "alabeled", 8, NA, NA);

			stuffer_set_dot_double("setDot", "radius", 0.1, NA, NA);
			stuffer_set_dot_double("setDot", "aradius", 0.2, NA, NA);

			// load a PLY file do models is NOT null
			stuffer_add_string("add", "specimen", f1, 0, NA);

			stuffer_set_dot_integer("setDot", "selected", 3, 5, NA);
			stuffer_set_dot_double("setDot", "coordinate", 1.1, 3.3, 5.5);
			stuffer_set_dot_double("setDot", "dcolor", 0.5, 0.6, 0.7);
			stuffer_set_dot_double("setDot", "acolor", 0.1, 0.3, 0.5);
			stuffer_set_dot_double("setDot", "color", 0.2, 0.4, 0.6);
			stuffer_set_dot_double("setDot", "anchorColor", 0.1, 0.3, 0.5);

			stuffer_set_dot_integer("setDot", "labeled", 9, NA, NA);
			stuffer_set_dot_integer("setDot", "alabeled", 8, NA, NA);

			stuffer_set_dot_double("setDot", "radius", 0.1, NA, NA);
			stuffer_set_dot_double("setDot", "aradius", 0.2, NA, NA);

			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);

		}
		if (1 == test_08)
		{
			// these tests verify that the setSpecimen function does no crash 
			// in exection

			// my standard start up sequence
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);

			stuffer_add_integer("add", "initialize", NA, NA, -NA);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);

			stuffer_set_specimen_string_double("setSpecimen", "angle", "x", 30.0, NA);
			stuffer_set_specimen_string_double("setSpecimen", "angle", "y", 30.0, NA);
			stuffer_set_specimen_string_double("setSpecimen", "angle", "z", 30.0, NA);
			stuffer_set_specimen_string_double("setSpecimen", "scale", "in", NA, NA);
			stuffer_set_specimen_string_double("setSpecimen", "scale", "out", NA, NA);
			stuffer_set_specimen_integer("setSpecimen", "allocate", 4, NA, NA);
			stuffer_set_specimen_integer("setSpecimen", "allocate", 0, NA, NA);
			stuffer_set_specimen_integer("setSpecimen", "allocate", 4, NA, NA);
			stuffer_set_specimen_integer("setSpecimen", "id", 0, NA, NA);
			stuffer_set_specimen_integer("setSpecimen", "id", 1, NA, NA);
			stuffer_set_specimen_integer("setSpecimen", "id", 2, NA, NA);
			stuffer_set_specimen_integer("setSpecimen", "id", 3, NA, NA);
			stuffer_set_specimen_integer("setSpecimen", "id", 4, NA, NA);  // this will generate non success log messages

			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);
		}
		if (1 == test_09)
		{

			// my standard start up sequence
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);

			stuffer_add_integer("add", "initialize", NA, NA, -NA);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);



			stuffer_show_string("show", "specimen", "xyz", 3, 5);
			stuffer_show_string("show", "landmark", "xyz", 1, 2);
			stuffer_show_string("show", "landmark", "id", NA, NA);

			stuffer_show_string("show", "anchor", "xyz", 1, 2);

			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);
		}
		if (1 == test_10)
		{
			// my standard start up sequence
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);
			stuffer_add_integer("add", "initialize", NA, NA, -NA);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);

			stuffer_downsample_integer("setDownSample", "offsetBegin", 3, 5, NA);
			stuffer_downsample_integer("setDownSample", "offsetEnd", 3, 5, NA);


			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);


			stuffer_downsample_integer("setDownSample", "offsetBegin", 3, 5, NA);
			stuffer_downsample_integer("setDownSample", "offsetEnd", 3, 5, NA);



			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);
		}
		if (1 == test_11)
		{
			// my standard start up sequence
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);
			simpleLog("Executing test 11 : ALLOCATE_WRAPPER / FREE WRAPPER tests");



			//stuffer_add_integer("add", "initialize", NA, NA, -NA);
			//stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			//stuffer_add_string("add", "specimen", f1, 0, NA);



			void* tempPointer = NULL;
			void* otherTempPointer = NULL;
			const int COUNTER = 100;  // manually edit and rebuild as desired 
			char buffer[128];
			buffer[127] = '\0';

			sprintf(buffer, "Executing  tests [%d] times", COUNTER);
			simpleLog(buffer);




			for (int jj = 0; jj < COUNTER; jj++)
			{
				tempPointer = (void*)ALLOCATE_WRAPPER(1024);  // size in bytes
				otherTempPointer = (void*)ALLOCATE_WRAPPER(2048);  // size in bytes

				if (NULL == tempPointer)
				{

					// intended use ... in IDE and set a break point !
					printf("Memory allocation faiure .... loop [%d] \n", jj);
					printf("Memory allocation faiure .... loop [%d] \n", jj);
				}
				else
				{
					FREE_WRAPPER(tempPointer);
				}



				if (NULL == otherTempPointer)
				{

					// intended use ... in IDE and set a break point !
					printf("Memory allocation faiure .... loop [%d] \n", jj);
					printf("Memory allocation faiure .... loop [%d] \n", jj);
				}
				else
				{
					FREE_WRAPPER(otherTempPointer);
				}



			}


			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);

		}
		if (1 == test_12)
		{
			// to determine if there are errors here - the preprocessor item NO_GRAPHICS
			// must be undefined
			// Doing so is NOT the way the test tool is intended to be run.
			// BE advised of this and make sure it is undefined for desk top 
			// execution of these programs

			// as of 06 June 2020 I have observed that invoking these open GL focused functions 
			// do not cause execution errors 
			// the status of the NO_GRAPHICS directive remains un changed 
			//

			// how ever the function onDisplay() does crash ! 



			stuffer_add_integer("add", "invoke_draw_curves", -1, -2, -3);
			stuffer_add_integer("add", "invoke_draw_dots", -1, -2, -3);
			stuffer_add_integer("add", "invoke_draw_grid", -1, -2, -3);
			stuffer_add_integer("add", "invoke_draw_anchors", -1, -2, -3);
			stuffer_add_integer("add", "invoke_on_display", -1, -2, -3);
			stuffer_add_integer("add", "invoke_draw_test", -1, -2, -3);
		}



		if (1 == test_13)
		{
			// my standard start up sequence
			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);
			stuffer_add_integer("add", "initialize", NA, NA, -NA);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);
			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);

		}

		if (1 == test_14)
		{

			// test of return values for the tcl_if_functions

			stuffer_add_integer("add", "startRecording", -1, NA, -NA);
			stuffer_add_integer("add", "openLogFile", -1, NA, NA);
			
			
			
			stuffer_add_integer("add", "logMessage", -13, NA, -NA);    // a generic log message 
			stuffer_add_integer("add", "logMessage",  -7,  0, -NA);    // success
			stuffer_add_integer("add", "logMessage",  -7, -1, -NA);    // error
			stuffer_add_integer("add", "logMessage",  -7, -2, -NA);    // ignore
			stuffer_add_integer("add", "logMessage",  -7, -3, -NA);    //under construction
			stuffer_add_integer("add", "logMessage",  -13, -14, -NA);  // a generic log message with secondary integer
			
			// NOTE : The TCL/TK library code rezerves a couple of positive integers for TCL return values (from C to R)
			// whichc the TCL/TK code acts upon - BEFORE returning to R ... 
			// Thus positive values less than 5 are HIGHLY recommended to NOT be used !

			stuffer_add_integer("add", "logMessage", -11, 4, -NA);  // NOTE ! 12 June 2020 changes in R code
			stuffer_add_integer("add", "logMessage", -11, 5, -NA);
			stuffer_add_integer("add", "logMessage", -11, 6, -NA);


			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);

		}


		if (1 == test_00)
		{
			// test of add function 
			// make sure that no function call crashes when given reasonable data

			stuffer_add_integer("add", "initialize", -1, -2, -3);

			stuffer_add_string("add", "UNIT_TEST_specimen", f1, 0, NA);

			stuffer_add_integer("add", "initialize", -1, -2, -3);
			stuffer_set_specimen_integer("specimen", "allocate", 2, NA, -NA);
			stuffer_add_string("add", "specimen", f1, 0, NA);

			stuffer_add_integer("add", "InfoLandmarks", 5, 3, 2);

			stuffer_add_integer("add", "SetLandmarkIndex", 1, 2, NA);
			stuffer_add_double("add", "rawdot", -20.054497, -37.918907, -3.670341);
			stuffer_add_double("add", "rawdot", -7.808026, -36.100124, -3.915579);
			stuffer_add_double("add", "rawdot", -5.382958, -26.884939, -4.359759);
			stuffer_add_double("add", "rawdot", -2.109146, -39.252674, -4.167464);
			stuffer_add_double("add", "rawdot", -3.32168, -55.985489, -3.792133);
			stuffer_add_string("add", "specimen", f2, 1, NA);
			stuffer_add_integer("add", "SetLandmarkIndex", 2, 2, NA);
			stuffer_add_double("add", "rawdot", -12.235758, -32.720879, 0.714147);
			stuffer_add_double("add", "rawdot", -1.019839, -33.35817, 0.060274);
			stuffer_add_double("add", "rawdot", -1.911993, -44.701553, -0.004728);
			stuffer_add_double("add", "rawdot", -8.029779, -48.142807, 0.080747);
			stuffer_add_double("add", "rawdot", -10.706311, -40.495575, 0.689502);
			stuffer_add_integer("add", "InfoLandmarks_complete", NA, NA, NA);
			stuffer_add_integer("add", "SetCurveIndex", 1, NA, NA);
			stuffer_add_integer("add", "curve", 2, 3, 4);
			stuffer_add_integer("add", "curve", 1, 5, 4);
			stuffer_add_integer("add", "InfoCurves_complete", NA, NA, NA);


			stuffer_add_integer("add", "snapshot", 0, NA, NA);
			stuffer_add_integer("add", "endRecording", 0, 0, 0);
			stuffer_add_integer("add", "closeLogFile", 0, 0, 0);



			stuffer_add_double("add", "rawanchor", -20.054497, -37.918907, -3.670341);
			stuffer_add_double("add", "rawanchor", -7.808026, -36.100124, -3.915579);
			stuffer_add_double("add", "rawanchor", -5.382958, -26.884939, -4.359759);
			stuffer_add_double("add", "rawanchor", -2.109146, -39.252674, -4.167464);
			stuffer_add_double("add", "rawanchor", -3.32168, -55.985489, -3.792133);

			stuffer_add_double("add", "dot", -20.054497, -37.918907, -3.670341);
			stuffer_add_double("add", "dot", -7.808026, -36.100124, -3.915579);
			stuffer_add_double("add", "dot", -5.382958, -26.884939, -4.359759);
			stuffer_add_double("add", "dot", -2.109146, -39.252674, -4.167464);
			stuffer_add_double("add", "dot", -3.32168, -55.985489, -3.792133);


			stuffer_add_double("add", "anchor", -20.054497, -37.918907, -3.670341);
			stuffer_add_double("add", "anchor", -7.808026, -36.100124, -3.915579);
			stuffer_add_double("add", "anchor", -7.808026, -36.100124, -3.915579);
			stuffer_add_double("add", "anchor", -5.382958, -26.884939, -4.359759);
			stuffer_add_double("add", "anchor", -2.109146, -39.252674, -4.167464);
			stuffer_add_double("add", "anchor", -3.32168, -55.985489, -3.792133);

			stuffer_add_integer("add", "downsample", 1, 2, 3);

			// THESE FUNCTIONS ARE FOR UNIT TESTING OF FUTURE ENHANCEMENTS
			// 
			stuffer_add_integer("add", "rawdot_NO_ADJUSTMENT", 1, 2, 3);
			char landmarkfileName_1[] = "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/Landmarks_9_A_6_1.lm_pts";
			const char* lm_f1 = landmarkfileName_1;

			char curvefileName_1[] = "C:/home/0_GuiMorph_IO_FILES/INPUT_PLY_FILES/Folsom3D/CurvesForLandmarks_9_A_6_1.curve_pts";
			const char* curve_f1 = curvefileName_1;

			stuffer_add_string("add", "LoadLandmarksFromFile", (char*)lm_f1, 0, NA);
			stuffer_add_string("add", "LoadCurvesFromFile", (char*)curve_f1, 0, NA);
		}



		if (1 == test_15)
		{

			double* ptrToFlattenedVertices = NULL;
			unsigned int totalSizeOfVertices = 0;     /// needs to be multiples of 3
			model_t* prtToModel = NULL;

		}


		if(1 == test_16)
		{
			test_statisticsFunctions();
		}
	}




	char trash;
	printf("\n");
	printf("This is main test ZARF_5  ... Complete .... \n");
	printf(" ... MAIN PROGRAM ... press ENTER to end\n");
	trash = getc(stdin);
	return 0;
}


void stuffer_add_integer(char* command, char* shape, int arg1, int arg2, int arg3)
{
	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;

	arg1Obj.refCount = 1;
	arg1Obj.bytes = NULL;
	arg1Obj.length = 0;
	arg1Obj.typePtr = IntegerTypePointer;
	arg1Obj.internalRep.longValue = arg1;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.longValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.longValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = add(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_add_integer\n");
	}
	else if (1 == rv)
	{
		printf("ERROR : stuffer_add_integer\n");
	}
	else if(2 == rv)
	{
		printf("IGNORE : stuffer_add_integer\n");
	}
	else if(3 == rv)
	{
		printf("UNDER_CONSTRUCTION : stuffer_add_integer\n");
	}
	else
	{
		printf("UNKNOWN RETURN  : stuffer_add_integer ... [%d]\n" , rv);
	}
}

void stuffer_add_double(char* command, char* shape, double arg1, double arg2, double arg3)
{
	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;

	arg1Obj.refCount = 1;
	arg1Obj.bytes = NULL;
	arg1Obj.length = 0;
	arg1Obj.typePtr = IntegerTypePointer;
	arg1Obj.internalRep.doubleValue = arg1;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.doubleValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.doubleValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = add(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_add_double\n");
	}
	else
	{
		printf("ERROR : stuffer_add_double\n");
	}
}

void stuffer_set_specimen_integer(char* command, char* shape, int arg1, int arg2, int arg3)
{
	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;

	arg1Obj.refCount = 1;
	arg1Obj.bytes = NULL;
	arg1Obj.length = 0;
	arg1Obj.typePtr = IntegerTypePointer;
	arg1Obj.internalRep.longValue = arg1;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.longValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.longValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = setSpecimen(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_add_integer\n");
	}
	else
	{
		printf("ERROR : stuffer_add_integer\n");
	}
}

void stuffer_set_window_string(char* command, char* shape, char* arg1, int arg2, int arg3)
{
	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;

	arg1Obj.refCount = 1;
	arg1Obj.bytes = (char*)arg1;
	arg1Obj.length = (int)strlen(arg1);
	arg1Obj.typePtr = IntegerTypePointer;
	arg1Obj.internalRep.longValue = 0;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.longValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.longValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = setWindow(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_setWindow_string\n");
	}
	else
	{
		printf("ERROR : stuffer_setWindow_string\n");
	}
}

void stuffer_add_string(char* command, char* shape, char* arg1, int arg2, int arg3)
{
	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;


	int lengthOF = 0;
	if (NULL == arg1)
	{
	}
	else
	{
		lengthOF = (int)strlen(arg1);
	}
	arg1Obj.refCount = 1;
	arg1Obj.bytes = (char*)arg1;
	arg1Obj.length = lengthOF;
	arg1Obj.typePtr = IntegerTypePointer;
	arg1Obj.internalRep.longValue = 0;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.longValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.longValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = add(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_add_string\n");
	}
	else
	{
		printf("ERROR : stuffer_add_string\n");
	}
}

void stuffer_set_window_integer(char* command, char* shape, int arg1, int arg2, int arg3)
{
	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;

	arg1Obj.refCount = 1;
	arg1Obj.bytes = NULL;
	arg1Obj.length = 0;
	arg1Obj.typePtr = IntegerTypePointer;
	arg1Obj.internalRep.longValue = arg1;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.longValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.longValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = setWindow(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_set_window_integer\n");
	}
	else
	{
		printf("ERROR : stuffer_set_window_integer\n");
	}
}

void stuffer_show_string(char* command, char* shape, char* arg1, int arg2, int arg3)
{
	printf("Command <%s>\n", command);
	printf("shape   <%s>\n", shape);
	printf("arg1    <%s>\n", arg1);


	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;

	arg1Obj.refCount = 1;
	arg1Obj.bytes = (char*)arg1;
	arg1Obj.length = (int)strlen(arg1);
	arg1Obj.typePtr = CommandTypePointer;
	arg1Obj.internalRep.longValue = 0;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.longValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.longValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = show(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_show_string\n");
	}
	else
	{
		printf("ERROR : stuffer_show_string\n");
	}
}

int ut_show_dot(dot_t* d)
{
	point_t* _p = &(d->p);
	color_t* _c = &(d->c);
	show_mode_t* _t = &(d->type);
	ut_show_point(_p);
	ut_show_color(_c);
	ut_show_show_mode_t(_t);
	printf(" Next link  {%s}\n", NULL == d->next ? "NULL" : "non null");
	return 0;
}

int ut_show_point(point_t* p)
{
	printf(" Show point ...");
	printf(" x <%f>  y <%f>  z <%f>\n", p->x, p->y, p->z);
	return 0;
}

int ut_show_color(color_t* c)
{
	printf(" Show color ...");
	printf(" r <%f>  g <%f>  b <%f>\n", c->r, c->g, c->b);
	return 0;
}

int ut_show_show_mode_t(show_mode_t* t)
{
	printf(" Show mode : ");
	if (NONE == *t) {
		printf("NONE \n"); return 0;
	}
	if (SPECIMEN == *t) {
		printf("SPECIMEN \n"); return 0;
	}
	if (LANDMARK == *t) {
		printf("LANDMARK \n"); return 0;
	}
	if (DOWN_SAMPLE == *t) {
		printf("DOWN_SAMPLE \n"); return 0;
	}
	if (DOWN_SAMPLE_ONLY == *t) {
		printf("DOWN_SAMPLE_ONLY \n"); return 0;
	}
	if (CURVE == *t) {
		printf("CURVE \n"); return 0;
	}
	if (ANCHOR == *t) {
		printf("ANCHOR \n"); return 0;
	}
	if (ALL == *t) {
		printf("ALL \n"); return 0;
	}
	printf("-- unknown type -- \n");
	return 0;

};

int ut_showCurve(curve_t* c)
{
	if (NULL == c)
	{
		return -1;
	}

	char buffer[128];
	buffer[0] = '\0';

	if (NULL == c)
	{
		simpleLog("ERROR : NULL pointer for curve type ");
		return -1;
	}

	printf("Curve data ...");
	int counter = 0;


	while (c != NULL)
	{
		counter++;
		printf("Curve # [%d]\n", counter);

		sprintf(buffer, "  points [0] <%s>\n", (NULL == c->points[0]) ? "NULL" : "not null");
		printf("%s", buffer);
		if (NULL != c->points[0])
		{
			sprintf(buffer, "  point  [0] :   <%f ... %f ... %f>\n",
				(float)c->points[0]->x, (float)c->points[0]->y, (float)c->points[0]->z);
			printf("%s", buffer);;
		}


		sprintf(buffer, "  points [1] <%s>\n", (NULL == c->points[1]) ? "NULL" : "not null");
		printf("%s", buffer);
		if (NULL != c->points[1])
		{
			sprintf(buffer, "  point  [1] :   <%f ... %f ... %f>\n",
				c->points[1]->x, c->points[1]->y, c->points[1]->z);
			printf("%s", buffer);;
		}


		sprintf(buffer, "  points [2] <%s>\n", (NULL == c->points[2]) ? "NULL" : "not null");
		printf("%s", buffer);;
		if (NULL != c->points[2])
		{
			sprintf(buffer, "  point  [2] :   <%f ... %f ... %f>\n",
				c->points[2]->x, c->points[2]->y, c->points[2]->z);
			printf("%s", buffer);;
		}

		sprintf(buffer, "  lines1     <%s>\n", (NULL == c->lines1) ? "NULL" : "not null");
		printf("%s", buffer);

		sprintf(buffer, "  lines2     <%s>\n", (NULL == c->lines2) ? "NULL" : "not null");
		printf("%s", buffer);

		sprintf(buffer, "  line1Size  [%d]\n", c->line1Size);
		printf("%s", buffer);

		sprintf(buffer, "  line2Size  [%d]\n", c->line2Size);
		printf("%s", buffer);

		sprintf(buffer, "  pointNum   [%d]\n", c->pointNum);
		printf("%s", buffer);;

		sprintf(buffer, "  next link  <%s>\n", (NULL == c->next) ? "NULL" : "not null");
		printf("%s", buffer);

		c = c->next;

	}


	simpleLog("Curve data ... complete");
	return 0;
}

void stuffer_del_integer(char* command, char* shape, int arg1, int arg2, int arg3)
{

	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;

	arg1Obj.refCount = 1;
	arg1Obj.bytes = NULL;
	arg1Obj.length = 0;
	arg1Obj.typePtr = IntegerTypePointer;
	arg1Obj.internalRep.longValue = arg1;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.longValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.longValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = del(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_del_integer\n");
	}
	else
	{
		printf("ERROR : stuffer_del_integer\n");
	}
}

void stuffer_set_dot_integer(char* command, char* shape, int arg1, int arg2, int arg3)
{
	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;

	arg1Obj.refCount = 1;
	arg1Obj.bytes = NULL;
	arg1Obj.length = 0;
	arg1Obj.typePtr = IntegerTypePointer;
	arg1Obj.internalRep.longValue = arg1;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.longValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.longValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = setDot(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_set_dot_integer\n");
	}
	else
	{
		printf("ERROR : stuffer_set_dot_integer\n");
	}
}

void stuffer_set_dot_double(char* command, char* shape, double arg1, double arg2, double arg3)
{
	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;

	arg1Obj.refCount = 1;
	arg1Obj.bytes = NULL;
	arg1Obj.length = 0;
	arg1Obj.typePtr = IntegerTypePointer;
	arg1Obj.internalRep.doubleValue = arg1;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.doubleValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.doubleValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = setDot(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_add_double\n");
	}
	else
	{
		printf("ERROR : stuffer_add_double\n");
	}
}

void stuffer_set_specimen_string_double(char* command, char* shape, char* arg1, double arg2, double  arg3)
{
	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;

	arg1Obj.refCount = 1;
	arg1Obj.bytes = (char*)arg1;
	arg1Obj.length = (int)strlen(arg1);
	arg1Obj.typePtr = CommandTypePointer;
	arg1Obj.internalRep.longValue = 0;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.doubleValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.doubleValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = setSpecimen(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_add_double\n");
	}
	else
	{
		printf("ERROR : stuffer_add_double\n");
	}
}

void stuffer_downsample_integer(char* command, char* shape, int arg1, int arg2, int arg3)
{

	Tcl_Obj  commandObj;
	Tcl_Obj  shapeObj;
	Tcl_Obj  arg1Obj;
	Tcl_Obj  arg2Obj;
	Tcl_Obj  arg3Obj;

	commandObj.refCount = 1;
	commandObj.bytes = (char*)command;
	commandObj.length = (int)strlen(command);
	commandObj.typePtr = CommandTypePointer;
	commandObj.internalRep.longValue = 0;

	shapeObj.refCount = 1;
	shapeObj.bytes = (char*)shape;
	shapeObj.length = (int)strlen(shape);
	shapeObj.typePtr = CommandTypePointer;
	shapeObj.internalRep.longValue = 0;

	arg1Obj.refCount = 1;
	arg1Obj.bytes = NULL;
	arg1Obj.length = 0;
	arg1Obj.typePtr = IntegerTypePointer;
	arg1Obj.internalRep.longValue = arg1;

	arg2Obj.refCount = 1;
	arg2Obj.bytes = NULL;
	arg2Obj.length = 0;
	arg2Obj.typePtr = IntegerTypePointer;
	arg2Obj.internalRep.longValue = arg2;

	arg3Obj.refCount = 1;
	arg3Obj.bytes = NULL;
	arg3Obj.length = 0;
	arg3Obj.typePtr = IntegerTypePointer;
	arg3Obj.internalRep.longValue = arg3;


	Tcl_Obj* const objv[] = { &commandObj, &shapeObj, &arg1Obj, &arg2Obj, &arg3Obj };
	int rv = -1;
	rv = setDownSample(clientData, testInterp, 5, objv);
	if (0 == rv)
	{
		printf("SUCCESS : stuffer_del_integer\n");
	}
	else
	{
		printf("ERROR : stuffer_del_integer\n");
	}
}

int test_statisticsFunctions()
{
	/*struct statistics ts;
	struct statistics* p = &ts;

	resetStatistic(p);
	double tempD = 0;
	for (int ii = 0; ii < 100; ii++)
	{
		accumulateStatistic(p, (double)ii);
	}
	showStatistics(p);


	resetStatistic(p);
	accumulateStatistic(p, 17);
	accumulateStatistic(p, 15);
	accumulateStatistic(p, 23);
	accumulateStatistic(p, 7);
	accumulateStatistic(p, 9);
	accumulateStatistic(p, 13);

	showStatistics(p);


	return 0;*/
}