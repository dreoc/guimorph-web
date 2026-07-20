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
#include "tcl_log.h"
#include "tcl_state.h"

extern const char* statisticsVersionPtr;
extern const char* oglModelVersionPtr;
extern const char* oglModelPlyVersionPtr;
extern const char* dotVersionPtr;
extern const char* curveVersionPtr;
extern const char* oglVersionPtr;

static FILE* fp = NULL;
static FILE* cmmdFileP = NULL;
static int xCounts = 0;
static int yCounts = 0;

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

int simpleLogWriteModelToFile(model_t* m)
{
	/* Must hold "file name :   <%s>" where %s is a full filesystem path. A
	 * 128-byte buffer overflowed on macOS (fortified sprintf -> SIGTRAP) for
	 * deep specimen paths; size for a realistic path and bound the path write
	 * with snprintf so an even longer path truncates safely instead of crashing. */
	char buffer[1024];
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
		snprintf(buffer, sizeof(buffer), "file name :   <%s>", m->fileName);
		simpleLog(buffer);
	}

	sprintf(buffer, "FUNCTION simpleLogWriteModelToFile ... END");
	simpleLog(buffer);
	simpleLogBlankLine();
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


	return 0;
}

void simpleLogCurveInformation()
{
	snprintf(buffer, sizeof(buffer), "%s", curveVersionPtr);
	simpleLog(buffer);
}
void simpleLogDotInformation()
{
	snprintf(buffer, sizeof(buffer), "%s", dotVersionPtr);
	simpleLog(buffer);
}
void simpleLogOglModelInformation()
{
	snprintf(buffer, sizeof(buffer), "%s", oglModelVersionPtr);
	simpleLog(buffer);
}
void simpleLogOglModelPlyInformation()
{
	snprintf(buffer, sizeof(buffer), "%s", oglModelPlyVersionPtr);
	simpleLog(buffer);
}
void simpleLogStatisticsInformation()
{
	snprintf(buffer, sizeof(buffer), "%s", statisticsVersionPtr);
	simpleLog(buffer);
}
void simpleLogTclIfInformation()
{
	snprintf(buffer, sizeof(buffer), "%s", tcl_ifVersionPtr);
	simpleLog(buffer);
}
void simpleLogOglInformation()
{
	snprintf(buffer, sizeof(buffer), "%s", oglVersionPtr);
	simpleLog(buffer);
}


void simpleLogWriteAnchorsToFile()
{
	sprintf(buffer, "DEBUG : Write Anchors to log file"); simpleLog(buffer);
	sprintf(buffer, "DEBUG : Anchors allocated slices [%d]", anchorGetArraySize()); simpleLog(buffer);
	dot_t* oneDot = NULL;
	point_t* onePoint = NULL;

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
