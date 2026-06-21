#pragma warning( disable : 4305)
#pragma warning( disable : 4244)
#include <math.h>
#include "def_ZARF_9.h"
#include <time.h>

#include <string.h>   // c language functions : NOT c++

#include "RunTime_Defines_ZARF_9.h"
#include "StatisticsFunction_ZARF_9.h"


const char OGL_MODEL_PLY_VERSION_INFORMATION[] = "File olg_model_ply Edit revision date is 15 August 2020 4:22 PM";
const char* oglModelPlyVersionPtr = OGL_MODEL_PLY_VERSION_INFORMATION;

extern int GBL_LANDMARK_SET_NUMBER_OF_ROWS;
extern int GBL_LANDMARK_SET_MAX_ROWS;
extern const float* pointerTO_GBL_LANDMARK_SET;


extern const float* pointerTO_GBL_CURVE_SET;
extern int GBL_CURVE_SET_MAX_ROWS;
extern int GBL_CURVE_SET_NUMBER_OF_ROWS;
extern color_t defaultDotColor;
extern color_t defaultAnchor;
extern int model_index;
extern int model_amount;

int addDot_NO_TCL(double* xp, double* yp, double* zp);
int addAnchor_NO_TCL(double* xp, double* yp, double* zp);

char ogl_buffer[128];


/****This file handles the LOADING of .ply files. ogl_model.c handles drawing****/

#define PLY_ATTR_GET_INT(name, buf, value) \
	if (strncmp(name, buffer, strlen(name)) == 0) { \
		strcpy(buf, buf + strlen(name)); \
		sscanf(buffer, "%i", value); \
	}

static void calculateNormal(float* coord1, float* coord2, float* coord3, float* norm)
{
	/* calculate Vector1 and Vector2 */
	float va[3], vb[3], vr[3], val;
	va[0] = coord1[0] - coord2[0];
	va[1] = coord1[1] - coord2[1];
	va[2] = coord1[2] - coord2[2];

	vb[0] = coord1[0] - coord3[0];
	vb[1] = coord1[1] - coord3[1];
	vb[2] = coord1[2] - coord3[2];

	/* cross product */
	vr[0] = va[1] * vb[2] - vb[1] * va[2];
	vr[1] = vb[0] * va[2] - va[0] * vb[2];
	vr[2] = va[0] * vb[1] - vb[0] * va[1];

	/* normalization factor */
	val = (float)sqrt((double)vr[0] * (double)vr[0] + (double)vr[1] * (double)vr[1] + (double)vr[2] * (double)vr[2]);

	norm[0] = vr[0] / val;
	norm[1] = vr[1] / val;
	norm[2] = vr[2] / val;
}


int model_Initialize(model_t* model)
{
	if (NULL == model)
	{
		simpleLog("model initialize ...  model_t .... NULL pointer for model");
		return -1;
	}
	model->vertex = NULL;
	model->color = NULL;
	model->normal = NULL;
	model->dsVertex = NULL;
	model->vertexSize = 0;
	model->colorSize = 0;
	model->normalSize = 0;
	model->dsVertexSize = 0;
	model->fileName[0] = '\0';
	model->originalMeanValues[0] = 0;
	model->originalMeanValues[1] = 0;
	model->originalMeanValues[2] = 0;
	model->largestScaleFactor = 0;
	resetModel(model);
	return 0;
}

// sets all values to 0 and frees drawing memory
int resetModel(model_t* model)
{

	if (NULL == model)
	{
		simpleLog("reset model_t .... NULL pointer for model");
		return -1;
	}

	model->max[0] = 0.0;
	model->max[1] = 0.0;
	model->max[2] = 0.0;

	model->min[0] = 0.0;
	model->min[1] = 0.0;
	model->min[2] = 0.0;

	model->dsMax[0] = 0.0;
	model->dsMax[1] = 0.0;
	model->dsMax[2] = 0.0;

	model->dsMin[0] = 0.0;
	model->dsMin[1] = 0.0;
	model->dsMin[2] = 0.0;

	model->delta[0] = 0.0;
	model->delta[1] = 0.0;
	model->delta[2] = 0.0;
	model->delta[3] = 0.0;

	model->count = 0;
	model->dsCount = 0;

	model->vertexSize = 0;
	model->colorSize = 0;
	model->normalSize = 0;
	model->dsVertexSize = 0;
	model->fileName[0] = '\0';


	model->originalMeanValues[0] = 0;
	model->originalMeanValues[1] = 0;
	model->originalMeanValues[2] = 0;
	model->largestScaleFactor = 0;


	if (model->vertex != NULL)
	{
		free(model->vertex);
		model->vertex = NULL;
	}
	if (model->normal != NULL)
	{
		free(model->normal);
		model->normal = NULL;
	}
	if (model->color != NULL)
	{
		free(model->color);
		model->color = NULL;
	}
	if (model->dsVertex != NULL)
	{
		free(model->dsVertex);
		model->dsVertex = NULL;
	}
	return 0;
}




/*transform model coordinates and clamp if outside range*/
float ogl_calCoordinate(float value, int id, float* delta)
{
	//printf("delta[0]  <%f>\n", (double)delta[0]);
	//printf("delta[1]  <%f>\n", (double)delta[1]);
	//printf("delta[2]  <%f>\n", (double)delta[2]);
	//printf("delta[3]  <%f>\n", (double)delta[3]);



	if (delta[3] > 1.0)
	{
		return (value - delta[id]) / delta[3];
	}
	else
	{
		return (value - delta[id]);
	}

	return value;
}

/*normalize model coordinates*/
float calCoordinate1(float value, int id, float* delta)
{
	if (delta[3] > 1.0) {
		return value / delta[3];
	}
	return value;
}


#define POSITIVE(i) (i > 0.0) ? i : (i * -1.0)
/*loads SPECIFICALLY .ply files*/

#define BEG_LING(tag) \
	char* p = NULL; \
	do { \
		p = fgets(buffer, 300, file); \
	} while (p != NULL && !feof(file) && strncmp(tag, buffer, strlen(tag)) != 0)



int ogl_loadDownSampleModel(double* flattenedVertices, unsigned int totalSize, model_t* model)
{
	if (NULL == flattenedVertices)
	{
		sprintf(ogl_buffer, "ERROR : ogl_loadDownSampleModel ... NULL pointer for flattenedVertices");
		simpleLog(ogl_buffer);
		return -1;
	}

	if (NULL == model)
	{
		sprintf(ogl_buffer, "ERROR : ogl_loadDownSampleModel ... NULL pointer for model");
		simpleLog(ogl_buffer);
		return -1;
	}

	if (0 == totalSize)
	{
		sprintf(ogl_buffer, "ERROR : ogl_loadDownSampleModel ... total size is zero");
		simpleLog(ogl_buffer);
		return -1;
	}


	//Vertex size   future work : probably want to check the size for being an integer multiple of 3 
	model->dsCount = (int)(totalSize / 3);
	if (model->dsCount <= 0)
	{
		sprintf(ogl_buffer, "ERROR : ogl_loadDownSampleModel ... model->dsCount non positive [%d] <%f>", totalSize, (float)model->dsCount);
		simpleLog(ogl_buffer);
		return -1;
	}

	// CODE PROBLEM HERE ... MALLOC USED ... no obvious plan to free memory (aside from processing the model)
	// AT ANY RATE ... this should be managed by the WRAPPER functions

	// 10 JULY 2020 ... need to test for non null pointer ... AND
	// Ask Erik about the operation
	if (NULL != model->dsVertex)
	{
		FREE(model->dsVertex);    // yes this macro tests the pointer as well ...
		model->dsVertex = NULL;
		model->dsMax[0] = 0.0;
		model->dsMax[1] = 0.0;
		model->dsMax[2] = 0.0;
		model->dsMin[0] = 0.0;
		model->dsMin[1] = 0.0;
		model->dsMin[2] = 0.0;
		model->dsVertexSize = 0;
		simpleLog("INFO : existing downsample data has been freed");
	}

	unsigned int requestedSize = (unsigned int)model->dsCount * (unsigned int)3;
	model->dsVertex = (float*)malloc((unsigned int)(requestedSize * sizeof(float)));

	if (NULL == model->dsVertex)
	{
		sprintf(ogl_buffer, "ERROR : failed to allocate memory for dsVertex : requested size [%u] (floats)", requestedSize);
		simpleLog(ogl_buffer);
		model->dsCount = 0;  // reassign to avoid attempting to assign to null memory
		model->dsVertexSize = 0;
		model->dsMax[0] = 0.0;
		model->dsMax[1] = 0.0;
		model->dsMax[2] = 0.0;
		model->dsMin[0] = 0.0;
		model->dsMin[1] = 0.0;
		model->dsMin[2] = 0.0;
		return -1;
	}
	else
	{
		model->dsCount = requestedSize;
		model->dsVertexSize = (int)(requestedSize * sizeof(float));

		model->dsMax[0] = 0.0;
		model->dsMax[1] = 0.0;
		model->dsMax[2] = 0.0;
		model->dsMin[0] = 0.0;
		model->dsMin[1] = 0.0;
		model->dsMin[2] = 0.0;

		sprintf(ogl_buffer, "INFO : allocated memory for downsamples : float count [%u] ", requestedSize);
		simpleLog(ogl_buffer);
		sprintf(ogl_buffer, "INFO : model data : dsCount [%d] ... dsVertexSize [%d]", model->dsCount, model->dsVertexSize);
		simpleLog(ogl_buffer);
		sprintf(ogl_buffer, "INFO : models->dsVertex is %s", (NULL == model->dsVertex) ? "NULL  -ERROR-" : "not  NULL -OK-");
		simpleLog(ogl_buffer);
	}


	if (1)
	{
		simpleLog("DEBUG : First iteration");
		simpleLog("DEBUG : Iterating over flattented vertices");
		for (int ii = 0; ii < model->dsCount; ii += 3)
		{
			sprintf(ogl_buffer, "DEBUG :  [%5d]  %10.6f  %10.6f  %10.6f", ii,
				flattenedVertices[ii + 0], flattenedVertices[ii + 1], flattenedVertices[ii + 2]);
			simpleLog(ogl_buffer);
		}
		simpleLog("DEBUG : First iteration complete");
		simpleLogBlankLine();
	}

	simpleLog("DEBUG : Second iteration");
	simpleLog("DEBUG : Iterating over flattented vertices ... assigning to model dsVertices");
	for (int i = 0; i < model->dsCount; i += 3)
	{
		model->dsVertex[i + 0] = (float)flattenedVertices[i + 0];
		model->dsVertex[i + 1] = (float)flattenedVertices[i + 1];
		model->dsVertex[i + 2] = (float)flattenedVertices[i + 2];
	}
	simpleLog("DEBUG : Second iteration complete ds vertex data is transferred to the model");
	simpleLogBlankLine();

	if (0)
	{
		simpleLog("DEBUG : Third iteration (write to flat file) ... started");
		FILE* dsFile;
		time_t NOW;
		time(&NOW);
		//sprintf(buffer, "a1_1_dsv_MODEL_%u.txt", (unsigned int)NOW);
		sprintf(ogl_buffer, "C:/home/0_GuiMorph_IO_FILES/OUTPUT_FILES/a1_1_dsv_MODEL_%u.txt", (unsigned int)NOW);
		dsFile = fopen(ogl_buffer, "w");
		if (NULL == dsFile)
		{
			simpleLog("FAIL : did not open temp file for downsamples in ogl model ply");
		}
		else
		{
			simpleLogBlankLine();
			simpleLog("DEBUG : OGL MODEL PLY vertices from model");
			simpleLog("DEBUG : Iteration over the model dsVertices");
			for (int i = 0; i < model->dsCount; i += 3)
			{
				sprintf(ogl_buffer, "DEBUG :  [%4d]  %10.6f  %10.6f  %10.6f", i, model->dsVertex[i + 0], model->dsVertex[i + 1], model->dsVertex[i + 2]);
				fprintf(dsFile, "%s\n", ogl_buffer);
			}
			fprintf(dsFile, "DATA_COMPLETE\n");
			fclose(dsFile);
		}

		simpleLog("DEBUG : Third iteration (write to flat file) ... complete");
	}


	struct statistics  xStats;
	struct statistics  yStats;
	struct statistics  zStats;
	struct statistics* xStatPointer = &xStats;
	struct statistics* yStatPointer = &yStats;
	struct statistics* zStatPointer = &zStats;
	resetStatistic(xStatPointer);   // explicitly reset since there is no C language constructor
	resetStatistic(yStatPointer);
	resetStatistic(zStatPointer);

	simpleLog("INFO : simpleLog statistics for X just reset");
	simpleLogStatistics(xStatPointer);
	simpleLog("INFO : simpleLog statistics for Y just reset ");
	simpleLogStatistics(yStatPointer);
	simpleLog("INFO : simpleLog statistics for Z just reset ");
	simpleLogStatistics(zStatPointer);
	simpleLogBlankLine();

	for (int i = 0; i < model->dsCount; i += 3)
	{
		accumulateStatistic(xStatPointer, model->dsVertex[i + 0]);
		accumulateStatistic(yStatPointer, model->dsVertex[i + 1]);
		accumulateStatistic(zStatPointer, model->dsVertex[i + 2]);

		if (0)   // turned off 10 July 2020 
		{
			sprintf(ogl_buffer, "DEBUG :  [%4d]  %10.6f  %10.6f  %10.6f", i, model->dsVertex[i + 0], model->dsVertex[i + 1], model->dsVertex[i + 2]);
			simpleLog(ogl_buffer);
		}

	}
	simpleLog("DEBUG : Fourth iteration (statistics assign) complete");

	// manually force recalculation before accessing results
	recalculate(xStatPointer);
	recalculate(yStatPointer);
	recalculate(zStatPointer);

	if (1 != isValidStatistic(xStatPointer))
	{
		simpleLog("ERROR : invalid x statistics in ogl_loadDownSampleModel");
	}
	if (1 != isValidStatistic(yStatPointer))
	{
		simpleLog("ERROR : invalid y statistics in ogl_loadDownSampleModel");
	}
	if (1 != isValidStatistic(zStatPointer))
	{
		simpleLog("ERROR : invalid z statistics in ogl_loadDownSampleModel");
	}

	simpleLog("INFO : simpleLog statistics for X ");
	simpleLogStatistics(xStatPointer);
	simpleLog("INFO : simpleLog statistics for Y ");
	simpleLogStatistics(yStatPointer);
	simpleLog("INFO : simpleLog statistics for Z ");
	simpleLogStatistics(zStatPointer);

	model->dsMin[X] = getMinimumStatistic(xStatPointer);
	model->dsMax[X] = getMaximumStatistic(xStatPointer);

	model->dsMin[Y] = getMinimumStatistic(yStatPointer);
	model->dsMax[Y] = getMaximumStatistic(yStatPointer);

	model->dsMin[Z] = getMinimumStatistic(zStatPointer);
	model->dsMax[Z] = getMaximumStatistic(zStatPointer);

	sprintf(ogl_buffer, "DEBUG : ds min max values  X : %10.6f ... %10.6f", model->dsMin[X], model->dsMax[X]); simpleLog(ogl_buffer);
	sprintf(ogl_buffer, "DEBUG : ds min max values  Y : %10.6f ... %10.6f", model->dsMin[Y], model->dsMax[Y]); simpleLog(ogl_buffer);
	sprintf(ogl_buffer, "DEBUG : ds min max values  Z : %10.6f ... %10.6f", model->dsMin[Z], model->dsMax[Z]); simpleLog(ogl_buffer);

	simpleLog("DEBUG : line 382");



	/*Read Vertices*/
	// This needs some better documentation of what is going on

	if (1)
	{
		simpleLog("DEBUG : Iterating over flattented vertices assigning to model dsVertices");

		for (int i = 0; i < model->dsCount; i += 3)
		{
			model->dsVertex[i + 0] = flattenedVertices[i];
			model->dsVertex[i + 1] = flattenedVertices[i + 1];
			model->dsVertex[i + 2] = flattenedVertices[i + 2];

			// why are ENUMS used here mixed with raw integer values that have the same numerical value
			if (i >= 3 * 5)
			{
				/*handle outliers and grab coords*/
				if (model->dsVertex[i + 0] < model->dsMin[X]) { model->dsMin[X] = model->dsVertex[i]; }
				if (model->dsVertex[i + Y] < model->dsMin[Y]) { model->dsMin[Y] = model->dsVertex[i + Y]; }
				if (model->dsVertex[i + Z] < model->dsMin[Z]) { model->dsMin[Z] = model->dsVertex[i + Z]; }

				if (model->dsVertex[i + 0] > model->dsMax[X]) { model->dsMax[X] = model->dsVertex[i]; }
				if (model->dsVertex[i + Y] > model->dsMax[Y]) { model->dsMax[Y] = model->dsVertex[i + Y]; }
				if (model->dsVertex[i + Z] > model->dsMax[Z]) { model->dsMax[Z] = model->dsVertex[i + Z]; }

				model->dsVertex[i + 0] = ogl_calCoordinate(model->dsVertex[i + 0], 0, model->delta);          // +0.11;  //what is this ?
				model->dsVertex[i + 1] = ogl_calCoordinate(model->dsVertex[i + 1], 1, model->delta);
				model->dsVertex[i + 2] = ogl_calCoordinate(model->dsVertex[i + 2], 2, model->delta);
			}
			else
			{
				/*if no outliers, grab coords*/
				model->dsVertex[i + 0] = ogl_calCoordinate(model->dsVertex[i + 0], 0, model->delta);      // +0.11; //what is this ?
				model->dsVertex[i + 1] = ogl_calCoordinate(model->dsVertex[i + 1], 1, model->delta);      // +1.27; //what is this ?
				model->dsVertex[i + 2] = ogl_calCoordinate(model->dsVertex[i + 2], 2, model->delta);      // -0.02; //what is this ?
			}
		}
		simpleLog("INFO : finished fifth iteration");
		simpleLog("INFO : finished assigning data to model->dsVertex -OK-");
	}




	simpleLog("DEBUG : dosnsample : performing delta calculations");

	double delta[4] = { 0.0 };
	for (int j = 0; j < 3; j++)
	{
		if (model->dsMax[j] - model->dsMin[j] != 0)
		{
			// distinct max/min
			delta[j] = (model->dsMax[j] + model->dsMin[j]) / 2;          /*midpoint*/
			float tmp = POSITIVE(delta[j]) + model->dsMax[j];           //go beyond delta[j] of max

			if (tmp > delta[3]) //if our jump exceeds maximum threshold
			{
				delta[3] = tmp; //set our new threshold to that jump
			}
		}
		//printf("min=%f, max=%f, delta[j]=%f\n", model->dsMin[j], model->dsMax[j], delta[j]);
	}


	// this dead code should be removed   Why was it commented out ??
	/**
	for (int i = 15; i < model->dsCount * 3; i += 3)
	{
		//model->dsVertex[i] = calCoordinate(model->dsVertex[i], 0, delta);
		//model->dsVertex[i + 1] = calCoordinate(model->dsVertex[i + 1], 1, delta);
		//model->dsVertex[i + 2] = calCoordinate(model->dsVertex[i + 2], 2, delta);
	}
	*/


	sprintf(ogl_buffer, "DEBUG : ds min max values  X : %10.6f ... %10.6f", model->dsMin[X], model->dsMax[X]); simpleLog(ogl_buffer);
	sprintf(ogl_buffer, "DEBUG : ds min max values  Y : %10.6f ... %10.6f", model->dsMin[Y], model->dsMax[Y]); simpleLog(ogl_buffer);
	sprintf(ogl_buffer, "DEBUG : ds min max values  Z : %10.6f ... %10.6f", model->dsMin[Z], model->dsMax[Z]); simpleLog(ogl_buffer);

	sprintf(ogl_buffer, "INFO : ogl_loadDownSampleModel .. end ...  model->dsCount is [%u] vertices", (unsigned int)model->dsCount);
	simpleLog(ogl_buffer);
	return 0; // success //// model->dsCount;
}

// as of 06 June 2020 , I am not sure this capability is used 
// dave to investigate how and when this should be sequenced in tcl_if
// since deltas and models are required.
//
void ogl_loadLandmark(FILE* file, float** deltas, int model_size)
{
	simpleLog("WARNING ... ogl_loadLandmark who called this function !");
	simpleLog("WARNING ... ogl_loadLandmark who called this function !");
	simpleLog("WARNING ... ogl_loadLandmark who called this function !");

	char buffer[1000] = { 0 };
	int lmkNum = 0;
	BEG_LING("LM3="); /*start at LM3*/
	PLY_ATTR_GET_INT("LM3=", buffer, &lmkNum);
	//printf("Load landmark: number=%d\n", lmkNum);

	if (lmkNum <= 0)
	{
		return;
	}

	/*read vertices*/
	for (int i = 0; i < lmkNum; i++)
	{
		point_t p;
		fgets(buffer, 300, file);
		sscanf(buffer, "%lf %lf %lf", &p.x, &p.y, &p.z);/*read x,y,z coords of point*/
		//D3("raw dot is %f, %f, %f", p.x, p.y, p.z); /*prints info*/

		for (int j = 0; j < model_size; j++)
		{
			/*calculate point coords*/
			p.x = ogl_calCoordinate(p.x, 0, deltas[j]);
			p.y = ogl_calCoordinate(p.y, 1, deltas[j]);
			p.z = ogl_calCoordinate(p.z, 2, deltas[j]);

			if (!validateDot(&p))
			{
				continue;
			}

			/*assign color and draw*/
			//D3("add dot %f, %f, %f", p.x, p.y, p.z);
			color_t c = defaultDotColor;
			dot_slice_index(j);
			dot_add(&p, &c);
		}
	}
	return;
}

/*assigns null terminator after whitespace*/
void rtrim(char* buf)
{
	char* back = buf + strlen(buf);
	while (isspace(*--back));
	*(back + 1) = '\0';
}



// Implementing this capability in C for investigation of displaying the
// formerly downsampled data when the gui is switched to the surfaces tab
// 22 July 2020

int ogl_loadLandMark(const char* filename, model_t* models, int model_id, int amount, float** deltas)
{
	simpleLog("WARNING ... ogl_loadLandMark who called this function !");
	simpleLog("WARNING ... ogl_loadLandMark who called this function !");
	simpleLog("WARNING ... ogl_loadLandMark who called this function !");
	return -1;
}


////////////////////////////////////////



// loads SPECIFICALLY .ply files 

int  ogl_loadModel(const char* filename, model_t* model)
{
	const  int HEADER_SIZE = 300;

	if (NULL == model)
	{
		simpleLog("ogl_loadModel ... null pointer for model");
		return -1;
	}

	if (NULL == filename)
	{
		simpleLog("ogl_loadModel ... null pointer for file name");
		return -1;
	}

	char* pch = strstr(filename, ".ply");  // we check lower case and upper case but NOT mixed case
	if (NULL == pch)
	{
		pch = strstr(filename, ".PLY");
		if (NULL == pch)
		{
			simpleLog("ogl_loadModel ... filename does not have a '.PLY' extension ... file NOT loaded");
			return -1;
		}
		else
		{
			// do nothing ... we found one of the cases of 'ply' or 'PLY'
		}
	}

	FILE* file = fopen(filename, "r"); /*read contents*/
	if (!file)
	{
		simpleLog("ogl_loadModel ... file could NOT be opened  ... file NOT loaded");
		return -1;
	}


	int tempRV;
	tempRV = resetModel(model); // reset and deallocate any existing memory attached to this model
	if (tempRV != 0)
	{
		// this function does not return anything except 0;
	}

	fseek(file, 0, SEEK_END); /*move to end of file*/

	const unsigned int FILE_SIZE = (unsigned int)(ftell(file) * sizeof(float));    /*size of file*/
	const unsigned int MEMORY_REQUEST_SIZE = (unsigned int)ftell(file);

	// begin with memory allocation and graceful unwinding if we do notget memory allocation
	// not much a person can do if malloc fails - maybe too many external programs running ?
	//
	float* Vertex_Buffer = (float*)malloc(MEMORY_REQUEST_SIZE); /*alloc memory for vertex drawing buffer*/
	if (Vertex_Buffer == NULL)
	{
		fclose(file);
		simpleLog("ERROR ...malloc failed  for vertex buffer in ogl_model_ply");
		return -1;
	}

	float* VertexColor_Buffer = (float*)malloc(MEMORY_REQUEST_SIZE); /*alloc memory for vertex color buffer*/
	if (VertexColor_Buffer == NULL)
	{

		fclose(file);
		free(Vertex_Buffer);
		simpleLog("ERROR ...malloc failed  for vertex buffer in ogl_model_ply");
		return -1;
	}

	// alloc memory for vertices and normals
	model->vertex = (float*)malloc(FILE_SIZE);
	if (NULL == model->vertex)
	{
		fclose(file);
		free(Vertex_Buffer);
		free(VertexColor_Buffer);
		simpleLog("ERROR ...malloc failed  for  model vertex buffer in ogl_model_ply");
		return -1;
	}

	model->normal = (float*)malloc(FILE_SIZE);
	if (NULL == model->normal)
	{
		fclose(file);
		free(Vertex_Buffer);
		free(VertexColor_Buffer);
		resetModel(model);
		simpleLog("ERROR ...malloc failed  for  model normal buffer in ogl_model_ply");
		return -1;
	}

	model->normalSize = FILE_SIZE;
	model->vertexSize = FILE_SIZE;

	/*variable definitions*/
	int i = 0;
	int temp = 0;
	int quads_index = 0;
	int triangle_index = 0;
	int normal_index = 0;
	char buffer[1000];

	int vertexNum = 0;
	int faceNum = 0;
	fseek(file, 0, SEEK_SET); //start at beginning of file

	// reads information up to end_header in .ply file*
	while (strncmp("end_header", buffer, strlen("end_header")) != 0)
	{
		fgets(buffer, HEADER_SIZE, file);
		PLY_ATTR_GET_INT("element vertex", buffer, &vertexNum);
		PLY_ATTR_GET_INT("element face", buffer, &faceNum);
		if (strncmp("property uchar red", buffer, strlen("property uchar red")) == 0)
		{
			model->color = (float*)malloc(FILE_SIZE);
		}
	}

	// so if we detect the end of the header, we need to check that we allocated the last piece of memory
	// allocated. Unwind everything if this didn't work
	if (NULL == model->color)
	{
		fclose(file);
		resetModel(model);
		free(Vertex_Buffer);
		free(VertexColor_Buffer);
		simpleLog("ERROR ...malloc failed  for  model color buffer in ogl_model_ply");
		return -1;
	}
	model->colorSize = FILE_SIZE;


	char msgbuffer[128];
	sprintf(msgbuffer, "Load PLY model : vertex num = %d, face num = %d, colored = %s", vertexNum, faceNum, model->color != NULL ? "yes" : "no");
	simpleLog(msgbuffer);

	// Read vertices
	i = 0;
	int anotherCounter = 0;
	int anyColorSeen = 0;   // tracks whether the PLY carries non-zero vertex colors
	for (int iterator = 0; iterator < vertexNum; iterator++)
	{
		fgets(buffer, HEADER_SIZE, file);
		/*if color specified, read that in along side  vertex location, if not, just get vertex*/
		if (model->color != NULL)
		{
			sscanf(buffer, "%f %f %f %f %f %f", &Vertex_Buffer[i], &Vertex_Buffer[i + 1], &Vertex_Buffer[i + 2],
				&VertexColor_Buffer[i], &VertexColor_Buffer[i + 1], &VertexColor_Buffer[i + 2]);
			if (VertexColor_Buffer[i] != 0.0f || VertexColor_Buffer[i + 1] != 0.0f || VertexColor_Buffer[i + 2] != 0.0f)
			{
				anyColorSeen = 1;
			}
		}
		else
		{
			sscanf(buffer, "%f %f %f", &Vertex_Buffer[i], &Vertex_Buffer[i + 1], &Vertex_Buffer[i + 2]);
		}
		anotherCounter++;

		// checks for outlier vertices and sets to max/min values 
		// this should have been implemented post file reading when the data was in memory
		// in my opinion. However ... it works 
		for (int j = 0; j < 3; j++)
		{
			if (Vertex_Buffer[i + j] < model->min[j])
			{
				model->min[j] = Vertex_Buffer[i + j];
			}

			if (Vertex_Buffer[i + j] > model->max[j])
			{
				model->max[j] = Vertex_Buffer[i + j];
			}
		}
		i += 3;
	}

	// Geometry-only scans (e.g. NextEngine PLYs) declare red/green/blue properties but
	// store all-zero colors. A zero color array renders the mesh flat black. Drop it so
	// ogl_drawModel uses the lighting path instead, producing a visible shaded surface.
	if (model->color != NULL && !anyColorSeen)
	{
		free(model->color);
		model->color = NULL;
		model->colorSize = 0;
		simpleLog("INFO : PLY vertex colors are all zero -> using lighting (no color array)");
	}

	model->vertexCountActual = anotherCounter;
	sprintf(msgbuffer,"DEBUG : Count of vertices is [%d]", anotherCounter); simpleLog(msgbuffer);
	

	sprintf(msgbuffer, "Load PLY model :  X min = %10.6f, max = %10.6f", model->min[0], model->max[0]); 	simpleLog(msgbuffer);
	sprintf(msgbuffer, "Load PLY model :  Y min = %10.6f, max = %10.6f", model->min[1], model->max[1]); 	simpleLog(msgbuffer);
	sprintf(msgbuffer, "Load PLY model :  Z min = %10.6f, max = %10.6f", model->min[2], model->max[2]); 	simpleLog(msgbuffer);

	for (int j = 0; j < 3; j++)
	{
		/*algorithm to search for maximum delta, store in delta[3]*/
		if (model->max[j] - model->min[j] != 0)
		{
			/*if min and max are distinct*/
			model->delta[j] = (model->max[j] + model->min[j]) / 2;     /*midpoint*/

			//printf("%f %f\n", POSITIVE(model->delta[j]), model->delta[3]);
			sprintf(msgbuffer, "%f %f", POSITIVE(model->delta[j]), model->delta[3]);
			float tmp = POSITIVE(model->delta[j]) + model->max[j];
			if (tmp > model->delta[3])
			{
				model->delta[3] = tmp;
			}
		}


		sprintf(msgbuffer, "Load PLY model : min = %10.6f, max = %10.6f, delta[j] = %10.6f", model->min[j], model->max[j], model->delta[j]);
		simpleLog(msgbuffer);
	}

	sprintf(msgbuffer, "----delta 0,1, and 2 are the mid points between min and max-----"); simpleLog(msgbuffer);
	sprintf(msgbuffer, "Load PLY model : delta[0] = <%f>", model->delta[0]);	simpleLog(msgbuffer);
	sprintf(msgbuffer, "Load PLY model : delta[1] = <%f>", model->delta[1]);	simpleLog(msgbuffer);
	sprintf(msgbuffer, "Load PLY model : delta[2] = <%f>", model->delta[2]);	simpleLog(msgbuffer);
	sprintf(msgbuffer, "----largest of the deltas ----"); simpleLog(msgbuffer);
	sprintf(msgbuffer, "Load PLY model : delta[3] = <%f>", model->delta[3]);	simpleLog(msgbuffer);




	sprintf(msgbuffer, "Load PLY model : max delta is %f", model->delta[3]);
	simpleLog(msgbuffer);


	// read faces, deals in clusters of 9
	i = 0;
	for (int iterator = 0; iterator < faceNum; iterator++)
	{
		fgets(buffer, HEADER_SIZE, file);

		/*if we start on face values*/
		if (buffer[0] == '3')
		{
			int vertex[3] = { 0 }; /*initialize vertices for triangle*/
			buffer[0] = ' ';
			sscanf(buffer, "%i%i%i", &vertex[0], &vertex[1], &vertex[2]); /*read in the data*/

			float coord[3][3] = { 0 };
			for (int i = 0; i < 9; i++)
			{
				// This old stuff should be removed .........
				//model->vertex[triangle_index + i] = Vertex_Buffer[3 * vertex[i / 3] + (i % 3)];
				//if (model->max[0] > 1.0 || model->max[1] > 1.0
				//	|| model->max[2] > 1.0 || model->min[0] < -1.0
				//	|| model->min[1] < -1.0 || model->min[2] < -1.0) {
				//	model->vertex[triangle_index + i] = (Vertex_Buffer[3 * vertex[i / 3] + (i % 3)] - delta[i % 3]) / 33.0;
				//}

				model->vertex[triangle_index + i] = ogl_calCoordinate(Vertex_Buffer[3 * vertex[i / 3] + (i % 3)], i % 3, model->delta); /*sets ith triangle vertex*/

				/*set ith triangle color*/
				if (model->color != NULL)
				{
					model->color[triangle_index / 9 * 12 + i / 3 * 4 + (i % 3)] = VertexColor_Buffer[3 * vertex[i / 3] + (i % 3)] / 255.0f;
					if (i % 3 == 2) { model->color[triangle_index / 9 * 12 + i / 3 * 4 + 3] = 0.9f; }
				}
				coord[i / 3][i % 3] = model->vertex[triangle_index + i];
			}



			// norm for faces (gives direction)
			float norm[3];
			calculateNormal(coord[0], coord[1], coord[2], norm);
			for (int i = 0; i < 9; i++)
			{
				model->normal[normal_index + i] = norm[i % 3];
			}

			/*9 faces, 9 triangles*/
			normal_index += 9;
			triangle_index += 9;
			model->count += 3;
		}
		i += 3;
	}

	fclose(file);



	// finalize max and min vertex
	for (int i = 0; i < 3; i++)
	{
		sprintf(msgbuffer, "Load PLY model :  [%d] min = %10.6f, max = %10.6f uncal", i, model->min[i], model->max[i]); simpleLog(msgbuffer);
		model->max[i] = ogl_calCoordinate(model->max[i], i, model->delta);
		model->min[i] = ogl_calCoordinate(model->min[i], i, model->delta);
		sprintf(msgbuffer, "Load PLY model :  [%d] min = %10.6f, max = %10.6f ", i, model->min[i], model->max[i]); simpleLog(msgbuffer);
	}

	// We are finished. 
	// Deallocate the memory used by this function which has not
	// been allocated and given to the model. The model now owns the other allocated memory
	free(Vertex_Buffer);
	free(VertexColor_Buffer);
	return 0;
}

int unit_test_ogl_loadLandmark(const char* filename)
{

	if (NULL == filename)
	{
		simpleLog("ERROR : unit_test_ogl_loadLandmark ... null pointer for file name");
		return -1;
	}

	char* pch = (char*)strstr(filename, ".lm_pts");  // we check lower case and upper case but NOT mixed case
	if (NULL == pch)
	{
		pch = (char*)strstr(filename, ".LM_PTS");
		if (NULL == pch)
		{
			simpleLog("ERROR : unit_test_ogl_loadLandmark ... filename does not have a '.LM_PTS' extension ... file NOT loaded");
			return -1;
		}
		else
		{
			// do nothing ... we found one of the cases of 'lm_pts' or 'LM_PTS'
		}
	}

	FILE* file = fopen(filename, "r"); /*read contents*/
	if (!file)
	{
		simpleLog("ERROR : unit_test_ogl_loadModel ... file could NOT be opened  ... file NOT loaded");
		//printf("%s can't be opened\n", filename);
		return -1;
	}



	clear_GBL_LANDMARK_SET();

	char buffer[1000] = { 0 };
	int lmkNum = 0;
	BEG_LING("LM3="); /*start at LM3*/
	PLY_ATTR_GET_INT("LM3=", buffer, &lmkNum);
	printf("Load landmark: number=%d\n", lmkNum);

	if (lmkNum <= 0)
	{
		simpleLog("ERROR : unit_test_ogl_loadLandmark ... no landmark data detected  ... file NOT loaded");
		return -1;
	}

	if (lmkNum >= GBL_LANDMARK_SET_MAX_ROWS)
	{
		simpleLog("ERROR : unit_test_ogl_loadLandmark ... too many landpark points  ... file NOT loaded");
		return -1;
	}


	float* pointerIntoLandmarkArray = (float*)pointerTO_GBL_LANDMARK_SET;

	for (int ii = 0; ii < lmkNum; ii++)
	{
		point_t p;
		fgets(buffer, 300, file);
		sscanf(buffer, "%lf %lf %lf", &p.x, &p.y, &p.z); // read x,y,z coords of point*/
		printf("landmark [%2d] : <%10.6f ... %10.6f ... %10.6f>\n", ii, p.x, p.y, p.z);

		*pointerIntoLandmarkArray = p.x; pointerIntoLandmarkArray++;
		*pointerIntoLandmarkArray = p.y; pointerIntoLandmarkArray++;
		*pointerIntoLandmarkArray = p.z; pointerIntoLandmarkArray++;


	}
	GBL_LANDMARK_SET_NUMBER_OF_ROWS = lmkNum;
	return 0;
}

int unit_test_ogl_loadCurve(const char* filename)
{

	if (NULL == filename)
	{
		simpleLog("ERROR : unit_test_ogl_loadCurve ... null pointer for file name");
		return -1;
	}

	char* pch = (char*)strstr(filename, ".curve_pts");  // we check lower case and upper case but NOT mixed case
	if (NULL == pch)
	{
		pch = (char*)strstr(filename, ".CURVE_PTS");
		if (NULL == pch)
		{
			simpleLog("ERROR : unit_test_ogl_loadCurve ... filename does not have a '.CURVE_PTS' extension ... file NOT loaded");
			return -1;
		}
		else
		{
			// do nothing ... we found one of the cases of 'curve_pts' or 'CURVE_PTS'
		}
	}

	FILE* file = fopen(filename, "r"); /*read contents*/
	if (!file)
	{
		simpleLog("ERROR : unit_test_ogl_loadCurve ... file could NOT be opened  ... file NOT loaded");
		//printf("%s can't be opened\n", filename);
		return -1;
	}


	clear_GBL_CURVE_SET();


	char buffer[1000] = { 0 };
	int curveNum = 0;
	BEG_LING("CURVES="); /*start at LM3*/
	PLY_ATTR_GET_INT("CURVES=", buffer, &curveNum);
	printf("Load curve k: number=%d\n", curveNum);

	if (curveNum <= 0)
	{
		simpleLog("ERROR : unit_test_ogl_loadCurve ... no landmark data detected  ... file NOT loaded");
		return -1;
	}

	if (curveNum >= GBL_LANDMARK_SET_MAX_ROWS)
	{
		simpleLog("ERROR : unit_test_ogl_loadCurve ... too many landpark points  ... file NOT loaded");
		return -1;
	}


	float* pointerIntoCurveArray = (float*)pointerTO_GBL_CURVE_SET;

	for (int ii = 0; ii < curveNum; ii++)
	{
		int start = -1;
		int middle = -1;
		int end = -1;

		fgets(buffer, 300, file);
		sscanf(buffer, "%d %d %d", &start, &middle, &end);
		printf("landmarks [%2d] : [%2d ... %2d ... %2d]\n", ii, start, middle, end);

		*pointerIntoCurveArray = start; pointerIntoCurveArray++;
		*pointerIntoCurveArray = middle; pointerIntoCurveArray++;
		*pointerIntoCurveArray = end; pointerIntoCurveArray++;


	}
	GBL_CURVE_SET_NUMBER_OF_ROWS = curveNum;
	return 0;
}

int ogl_loadDgtModel(const char* filename, model_t* model)
{
	simpleLog("DEBUG : ogl_loadDgtModel ... ");

	if (NULL == model)
	{
		simpleLog("ERROR : ogl_loadDgtModel ... null pointer for model");
		return -1;
	}

	if (NULL == filename)
	{
		simpleLog("ERROR : ogl_loadDgtModel ... null pointer for file name");
		return -1;
	}


	printf("Current model index is ...  [%d]\n", model_index);
	printf("Current model allocation is [%d]\n", model_amount);



	FILE* file = fopen(filename, "r");
	if (NULL == file)
	{
		simpleLog("ERROR :ogl_loadDgtModel ... file can not be opened");
		return -1;
	}

	char buffer[1000] = { 0 };
	int amount = 0;
	fseek(file, 0, SEEK_SET);

	/*count IDs*/
	char* p = NULL;
	const char* TAG_ID = "ID=";
	const char* TAG_LM = "LM3=";
	const char* TAG_ANCH = "AC3=";
	const char* TAG_SURF = "Surface=";
	const char* TAG_TEMPLATE = "Template=";
	const char* TAG_TEMPLATE_NUMBER = "TemplateNumber=";
	const char* TAG_CURVE = "Curve=";
	const char* TAG_PLY_LC = ".ply";
	const char* TAG_PLY_UC = ".PLY";
	const char* TAG_EQUALS = "=";

	int FLAG_READ_SURFACES = 0;
	int FLAG_READ_LANDMARKS = 0;
	int FLAG_READ_ANCHORS = 0;

	int nSurfaces = 0;
	int nlandmarks = 0;
	int nAnchors = 0;

	// creating integer arrays that count the number of occurrences of fields within the .dgt file
	// for the present date( 23 July 2020) we limit the size of the large arrays to 3 items (3 specimens)

	int count_LANDMARKS = 0;
	int count_ANCHORS = 0;
	int count_SURFACES = 0;
	int count_CURVES = 0;
	int count_ID = 0;
	int count_TEMPLATE = 0;
	int count_TEMPLATE_NUMBER = 0;
	int count_PLY = 0;

	double* surfaces_1 = NULL;
	double* surfaces_2 = NULL;
	double* surfaces_3 = NULL;
	double* landmarks_1 = NULL;
	double* landmarks_2 = NULL;
	double* landmarks_3 = NULL;
	double* anchors_1 = NULL;
	double* anchors_2 = NULL;
	double* anchors_3 = NULL;

	while (!feof(file))
	{
		buffer[0] = '\0';
		for (int jj = 0; jj < 300; jj++)  // trash embedded new line character
		{
			if ('\n' == buffer[jj]) { buffer[jj] = '\0'; }
		}




		p = fgets(buffer, 300, file);   // get text line 
		//printf("p = %s", p);

		// search for specific string data in the file
		if (NULL != strstr(buffer, TAG_PLY_LC))
		{
			printf("found PLY_LC\n");
			printf("PLY FILE NAME <%s>", buffer);
			count_PLY++;
		}
		if (NULL != strstr(buffer, TAG_PLY_UC))
		{
			printf("found PLY_UC\n");
			printf("PLY FILE NAME <%s>", buffer);
			count_PLY++;
		}
		if (0 == strncmp(TAG_ID, buffer, strlen(TAG_ID)))
		{
			printf("found ID\n");
			count_ID++;
		}
		if (0 == strncmp(TAG_LM, buffer, strlen(TAG_LM)))
		{
			///printf("found LM\n");
			count_LANDMARKS++;
			if (NULL != strstr(buffer, TAG_LM))
			{
				char* lmDigits;
				lmDigits = strstr(buffer, TAG_EQUALS);
				///printf("landmark digits <%s>\n", &lmDigits[1]);
				nlandmarks = 0;
				sscanf(++lmDigits, "%d", &nlandmarks);
				///printf("nLandmarks [%d]\n", nlandmarks);
				sprintf(ogl_buffer, "DEBUG : nLandmarks [%d]", nlandmarks); simpleLog(ogl_buffer);

				FLAG_READ_LANDMARKS = 1;
			}
			else
			{
				FLAG_READ_LANDMARKS = 0;
				printf("ERROR : why did we not find TAG_LM again ??");
				printf("ERROR : why did we not find TAG_LM again ??");
			}



			//////////////////////////////////////////////////////////////////////////////////////////////////////
		}
		if (0 == strncmp(TAG_ANCH, buffer, strlen(TAG_ANCH)))
		{
			printf("found AC\n");
			count_ANCHORS++;
			if (NULL != strstr(buffer, TAG_ANCH))
			{
				char* acDigits;
				acDigits = strstr(buffer, TAG_EQUALS);
				printf("anchor digits <%s>", &acDigits[1]);
				nAnchors = 0;
				sscanf(++acDigits, "%d", &nAnchors);
				printf("nAnchors [%d]\n", nAnchors);
				printf("\n");
				FLAG_READ_ANCHORS = 1;
			}
			else
			{
				FLAG_READ_ANCHORS = 0;
				printf("ERROR : why did we not find TAG_ANCH again ??");
				printf("ERROR : why did we not find TAG_ANCH again ??");
			}



		}
		if (0 == strncmp(TAG_SURF, buffer, strlen(TAG_SURF)))
		{
			count_SURFACES++;
			printf("found SURF\n");
			if (NULL != strstr(buffer, TAG_SURF))
			{
				char* surfDigits;
				surfDigits = strstr(buffer, TAG_EQUALS);
				printf("surf digits <%s>", &surfDigits[1]);
				nSurfaces = 0;
				sscanf(++surfDigits, "%d", &nSurfaces);
				printf("nSurfaces [%d]\n", nSurfaces);
				printf("\n");
				sprintf(ogl_buffer, "LOAD DGT : nSurfaces[% d]", nSurfaces);
				simpleLog(buffer);
				if (nSurfaces <= 0) {
					FLAG_READ_SURFACES = 0;
				}
				else
				{
					FLAG_READ_SURFACES = 1;
				}
			}
			else
			{
				FLAG_READ_SURFACES = 0;
				printf("ERROR : why did we not find TAG_SURF again ??");
				printf("ERROR : why did we not find TAG_SURF again ??");
			}


		}
		if (0 == strncmp(TAG_TEMPLATE, buffer, strlen(TAG_TEMPLATE)))
		{
			printf("found Template\n");
			printf("Template line <%s>", buffer);
			count_TEMPLATE++;

		}
		if (0 == strncmp(TAG_TEMPLATE_NUMBER, buffer, strlen(TAG_TEMPLATE_NUMBER)))
		{
			printf("found Template Number\n");
			count_TEMPLATE_NUMBER++;
		}
		if (0 == strncmp(TAG_CURVE, buffer, strlen(TAG_CURVE)))
		{ // under construction 
		}


		FLAG_READ_LANDMARKS = 0; // TURNED OF 30 JULY 2020 : R language implementation is still being used
		FLAG_READ_ANCHORS = 0;   // TURNED OF 30 JULY 2020 : R language implementation is still being used

		//////////////////////////////////////////////////////////////////////
		if (1 == FLAG_READ_SURFACES)
		{
			unsigned int sizeInBytes = nSurfaces * 3 * sizeof(double);
			double* ptrToV = NULL;
			if (sizeInBytes < 3)
			{
				FLAG_READ_SURFACES = 0;
				sprintf(buffer, "ERROR : size in bytes for surface vertices is incorrect [%u]\n", sizeInBytes);
				simpleLog(buffer);
				return -1;
			}
			else
			{
				ptrToV = (double*)malloc(sizeInBytes);
				if (NULL == ptrToV)
				{
					FLAG_READ_SURFACES = 0;
					sprintf(buffer, "ERROR : Failed to allocate surface vertex array [%u]\n", sizeInBytes);
					simpleLog(buffer);
					return -1;

				}
				else
				{
					if (1 == count_SURFACES)
					{
						surfaces_1 = (double*)ptrToV;
					}
					if (2 == count_SURFACES)
					{
						surfaces_2 = (double*)ptrToV;
					}
					if (3 == count_SURFACES)
					{
						surfaces_3 = (double*)ptrToV;
					}
					// memory allocated ... process below ;
				}
			}


			if (1 == FLAG_READ_SURFACES)
			{
				FLAG_READ_SURFACES = 0; // this is a good thing
				float v1 = 0;
				float v2 = 0;
				float v3 = 0;
				double* ptrToArray = NULL;
				if (1 == count_SURFACES)
				{
					ptrToArray = surfaces_1;
					printf("processing surfaces 1a\n");
				}
				if (2 == count_SURFACES)
				{
					ptrToArray = surfaces_2;
					printf("processing surfaces 2a\n");
				}
				if (3 == count_SURFACES)
				{
					ptrToArray = surfaces_3;
					printf("processing surfaces 3a\n");
				}

				for (int ii = 0; ii < nSurfaces; ii++)
				{
					p = fgets(buffer, 300, file);
					sscanf(p, "%f %f %f", &v1, &v2, &v3);
					///printf("Surf [%4d]  <%10.6f %10.6f %10.6f>\n", ii, v1, v2, v3);
					ptrToArray[0] = (double)v1;
					ptrToArray[1] = (double)v2;
					ptrToArray[2] = (double)v3;
					///printf("Surf [%4d]  <%10.6f %10.6f %10.6f>\n", ii, ptrToArray[0], ptrToArray[1], ptrToArray[2]);
					ptrToArray++;
					ptrToArray++;
					ptrToArray++;
				}
				///printf("end surfaces\n");

				// reset for next iteration loop



				if (1 == count_SURFACES)
				{
					ptrToArray = surfaces_1;
					printf("processing surfaces 1b\n");
				}
				if (2 == count_SURFACES)
				{
					ptrToArray = surfaces_2;
					printf("processing surfaces 2b\n");
				}
				if (3 == count_SURFACES)
				{
					ptrToArray = surfaces_3;
					printf("processing surfaces 3b\n");
				}
				// code to show the vertex data copied into the malloced arrat
				for (int ii = 0; ii < nSurfaces; ii++)
				{
					///printf(" [%4d] <%10.6f %10.6f %10.6f>\n", ii, ptrToArray[0], ptrToArray[1], ptrToArray[2]);
					ptrToArray++;
					ptrToArray++;
					ptrToArray++;
				}
				///printf("Show complete\n");


				if (1 == count_SURFACES)
				{
					if (0 == model_index)
					{
						ptrToArray = surfaces_1;
						printf("processing surfaces 1c\n");
					}
					else
					{
						ptrToArray = NULL;
					}
				}
				if (2 == count_SURFACES)
				{
					if (1 == model_index)
					{
						ptrToArray = surfaces_2;
						printf("processing surfaces 2c\n");
					}
					else
					{
						ptrToArray = NULL;
					}

				}
				if (3 == count_SURFACES)
				{
					if (2 == model_index)
					{
						ptrToArray = surfaces_3;
						printf("processing surfaces 3c\n");
					}
					else
					{
						ptrToArray = NULL;
					}
				}



				printf("test count_Surfaces is [%d]\n", count_SURFACES);
				printf("test model_index is .. [%d]\n", model_index);
				if (NULL != ptrToArray)
				{

					sprintf(buffer, "DEBUG : Processing surface data for current specimen [%d] [%d] of [%d] [%d]", count_SURFACES, model_index, model_amount - 1, model_amount);
					simpleLog(buffer);

					if (1)
					{
						if (0 != ogl_loadDownSampleModel(ptrToArray, 3 * nSurfaces, model))
						{
							sprintf(buffer, "ERROR : Non zero return from ogl_loadDownSampleModel\n");
							simpleLog(buffer);
							free(ptrToV); ptrToV = NULL;
							return -1;
						}
						else
						{
							printf("-OK- : Zero return from ogl_loadDownSampleModel\n");
						}
					}
				}
				else
				{
					sprintf(buffer, "DEBUG : Skip processing of surface data for non current specimen [%d] [%d] of [%d] [%d]", count_SURFACES, model_index, model_amount - 1, model_amount);
					simpleLog(buffer);
				}

				// we are done with the allocated memory because it has been transferred to the model 
				free(ptrToV);
				ptrToV = NULL;

			}




		}
		//////////////////////////////////////////////////////////////////////
		if (1 == FLAG_READ_LANDMARKS)
		{
			unsigned int sizeInBytes = nlandmarks * 3 * sizeof(double);
			double* ptrToLM = NULL;
			if (sizeInBytes < 3)
			{
				FLAG_READ_LANDMARKS = 0;
				sprintf(ogl_buffer, "ERROR : size in bytes for landmarks is incorrect [%u]\n", sizeInBytes);
				simpleLog(ogl_buffer);
				return -1;
			}
			else
			{
				ptrToLM = (double*)malloc(sizeInBytes);
				if (NULL == ptrToLM)
				{
					FLAG_READ_LANDMARKS = 0;
					sprintf(ogl_buffer, "ERROR : Failed to allocate landmark array [%u]\n", sizeInBytes);
					simpleLog(ogl_buffer);
					return -1;

				}
				else
				{
					sprintf(ogl_buffer, "DEBUG : memory allocated for landmark array [%u]", sizeInBytes);
					simpleLog(ogl_buffer);

					if (1 == count_LANDMARKS)
					{
						landmarks_1 = (double*)ptrToLM;
						landmarks_2 = NULL;
						landmarks_3 = NULL;    // for all ??? 
					}
					if (2 == count_LANDMARKS)
					{
						landmarks_2 = (double*)ptrToLM;
						landmarks_1 = NULL;
						landmarks_3 = NULL;
					}
					if (3 == count_LANDMARKS)
					{
						landmarks_3 = (double*)ptrToLM;
						landmarks_1 = NULL;
						landmarks_2 = NULL;
					}
					// memory allocated ... process below ;
				}
			}





			if (1 == FLAG_READ_LANDMARKS)
			{
				FLAG_READ_LANDMARKS = 0;
				float v1 = 0;
				float v2 = 0;
				float v3 = 0;
				double* ptrToArray = NULL;
				if (1 == count_LANDMARKS)
				{
					ptrToArray = landmarks_1;
					printf("processing landmarks 1a\n");
				}
				if (2 == count_LANDMARKS)
				{
					ptrToArray = landmarks_2;
					printf("processing landmarks 2a\n");
				}
				if (3 == count_LANDMARKS)
				{
					ptrToArray = landmarks_3;
					printf("processing landmarks 3a\n");
				}

				for (int ii = 0; ii < nlandmarks; ii++)
				{
					p = fgets(buffer, 300, file);
					sscanf(p, "%f %f %f", &v1, &v2, &v3);
					printf("Landmark [%4d]  <%10.6f %10.6f %10.6f>\n", ii, v1, v2, v3);
					ptrToArray[0] = (double)v1;
					ptrToArray[1] = (double)v2;
					ptrToArray[2] = (double)v3;
					printf("Landmark [%4d]  <%10.6f %10.6f %10.6f>\n", ii, ptrToArray[0], ptrToArray[1], ptrToArray[2]);
					ptrToArray++;
					ptrToArray++;
					ptrToArray++;
				}
				printf("end landmarks\n");


				if (1 == count_LANDMARKS)
				{
					ptrToArray = landmarks_1;
					printf("processing landmarks 1b\n");
				}
				if (2 == count_LANDMARKS)
				{
					ptrToArray = landmarks_2;
					printf("processing landmarks 2b\n");
				}
				if (3 == count_LANDMARKS)
				{
					ptrToArray = landmarks_3;
					printf("processing landmarks 3b\n");
				}
				// code to show the vertex data copied into the malloced array
				for (int ii = 0; ii < nlandmarks; ii++)
				{
					printf(" [%4d] <%10.6f %10.6f %10.6f>\n", ii, ptrToArray[0], ptrToArray[1], ptrToArray[2]);
					ptrToArray++;
					ptrToArray++;
					ptrToArray++;
				}
				printf("Show landmark complete\n");


				if (1 == count_LANDMARKS)
				{
					if (0 == model_index)
					{
						ptrToArray = landmarks_1;
						printf("processing landmarks 1c\n");
					}
					else
					{
						ptrToArray = NULL;
					}
				}
				if (2 == count_LANDMARKS)
				{
					if (1 == model_index)
					{
						ptrToArray = landmarks_2;
						printf("processing landmarks 2c\n");
					}
					else
					{
						ptrToArray = NULL;
					}

				}
				if (3 == count_LANDMARKS)
				{
					if (2 == model_index)
					{
						ptrToArray = landmarks_3;
						printf("processing landmarks 3c\n");
					}
					else
					{
						ptrToArray = NULL;
					}
				}
				printf("test count_LANDMARKS is [%d]\n", count_LANDMARKS);
				printf("test model_index is ... [%d]\n", model_index);
				if (NULL != ptrToArray)
				{
					sprintf(buffer, "DEBUG : Processing of landmark data for current specimen [%d] [%d] of [%d] [%d]",
						count_LANDMARKS, model_index, model_amount - 1, model_amount);
					simpleLog(buffer);
					if (1)
					{

						//printf("THIS IS WHERE I PROCESS THE LANDMARKS\n");
						//printf("THIS IS WHERE I PROCESS THE LANDMARKS\n");

						sprintf(buffer, "Current model index is ...  [%d]", model_index); simpleLog(buffer);
						sprintf(buffer, "Current model allocation is [%d]", model_amount); simpleLog(buffer);
						sprintf(buffer, "FORCING THE SLICE INDEX TO [%d]", model_index); simpleLog(buffer);



						dotSetArrayIndex(model_index);
						anchorSetArrayIndex(model_index);
						for (int ii = 0; ii < nlandmarks; ii++)
						{
							printf(" [%4d] <%10.6f %10.6f %10.6f>\n", ii, ptrToArray[0], ptrToArray[1], ptrToArray[2]);
							addDot_NO_TCL(&ptrToArray[0], &ptrToArray[1], &ptrToArray[2]);
							ptrToArray++;
							ptrToArray++;
							ptrToArray++;
						}
					}
				}
				else
				{
					sprintf(ogl_buffer, "DEBUG : Skip processing of landmark data for non current specimen [%d] [%d] of [%d] [%d]",
						count_LANDMARKS, model_index, model_amount - 1, model_amount);
					simpleLog(ogl_buffer);
				}


				// we are done with the allocated memory because it has been transferred to the model 
				ptrToArray = NULL;
				free(ptrToLM);
				ptrToLM = NULL;


			}
		}
		//////////////////////////////////////////////////////////////////////
		if (1 == FLAG_READ_ANCHORS)
		{
			unsigned int sizeInBytes = nAnchors * 3 * sizeof(double);
			double* ptrToAnchor = NULL;
			if (sizeInBytes < 3)
			{
				FLAG_READ_ANCHORS = 0;
				sprintf(buffer, "ERROR : size in bytes for anchors is incorrect [%u]\n", sizeInBytes);
				simpleLog(buffer);
				return -1;
			}
			else
			{
				ptrToAnchor = (double*)malloc(sizeInBytes);
				if (NULL == ptrToAnchor)
				{
					FLAG_READ_ANCHORS = 0;
					sprintf(buffer, "ERROR : Failed to allocate anchor array [%u]\n", sizeInBytes);
					simpleLog(buffer);
					return -1;

				}
				else
				{
					if (1 == count_ANCHORS)
					{
						anchors_1 = (double*)ptrToAnchor;
					}
					if (2 == count_ANCHORS)
					{
						anchors_2 = (double*)ptrToAnchor;
					}
					if (3 == count_ANCHORS)
					{
						anchors_3 = (double*)ptrToAnchor;
					}
					// memory allocated ... process below ;
				}
			}

			if (1 == FLAG_READ_ANCHORS)
			{
				FLAG_READ_ANCHORS = 0;
				float v1 = 0;
				float v2 = 0;
				float v3 = 0;
				double* ptrToArray = NULL;
				if (1 == count_ANCHORS)
				{
					ptrToArray = anchors_1;
					printf("processing ANCHORS 1a\n");
				}
				if (2 == count_ANCHORS)
				{
					ptrToArray = anchors_2;
					printf("processing ANCHORS 2a\n");
				}
				if (3 == count_ANCHORS)
				{
					ptrToArray = anchors_3;
					printf("processing ANCHORS 3a\n");
				}

				for (int ii = 0; ii < nAnchors; ii++)
				{
					p = fgets(buffer, 300, file);
					sscanf(p, "%f %f %f", &v1, &v2, &v3);
					printf("Anchor [%4d]  <%10.6f %10.6f %10.6f>\n", ii, v1, v2, v3);
					ptrToArray[0] = (double)v1;
					ptrToArray[1] = (double)v2;
					ptrToArray[2] = (double)v3;
					printf("Anchor [%4d]  <%10.6f %10.6f %10.6f>\n", ii, ptrToArray[0], ptrToArray[1], ptrToArray[2]);
					ptrToArray++;
					ptrToArray++;
					ptrToArray++;
				}
				printf("end ANCHORS\n");

				if (1 == count_ANCHORS)
				{
					ptrToArray = anchors_1;
					printf("processing ANCHORS 1b\n");
				}
				if (2 == count_ANCHORS)
				{
					ptrToArray = anchors_2;
					printf("processing ANCHORS 2b\n");
				}
				if (3 == count_ANCHORS)
				{
					ptrToArray = anchors_3;
					printf("processing ANCHORS 3b\n");
				}
				// code to show the vertex data copied into the malloced array
				for (int ii = 0; ii < nAnchors; ii++)
				{
					printf(" [%4d] <%10.6f %10.6f %10.6f>\n", ii, ptrToArray[0], ptrToArray[1], ptrToArray[2]);
					ptrToArray++;
					ptrToArray++;
					ptrToArray++;
				}
				printf("Show anchor complete\n");


				if (1 == count_ANCHORS)
				{
					if (0 == model_index)
					{
						ptrToArray = anchors_1;
						printf("processing ANCHORS 1c\n");
					}
					else
					{
						ptrToArray = NULL;
					}
				}
				if (2 == count_ANCHORS)
				{
					if (1 == model_index)
					{
						ptrToArray = anchors_2;
						printf("processing ANCHORS 2c\n");
					}
					else
					{
						ptrToArray = NULL;
					}
				}
				if (3 == count_ANCHORS)
				{
					if (2 == model_index)
					{
						ptrToArray = anchors_3;
						printf("processing ANCHORS 3c\n");
					}
					else
					{
						ptrToArray = NULL;
					}
				}

				printf("test count_ANCHORS is [%d]\n", count_ANCHORS);
				printf("test model_index is .. [%d]\n", model_index);
				if (NULL != ptrToArray)
				{

					sprintf(buffer, "DEBUG : Processing of anchor data for current specimen [%d] [%d] of [%d] [%d]",
						count_ANCHORS, model_index, model_amount - 1, model_amount);
					simpleLog(buffer);
					if (1)
					{
						//printf("THIS IS WHERE I PROCESS THE ANCHORS\n");
						//printf("THIS IS WHERE I PROCESS THE ANCHORS\n");

						sprintf(buffer, "Current model index is ...  [%d]", model_index); simpleLog(buffer);
						sprintf(buffer, "Current model allocation is [%d]", model_amount); simpleLog(buffer);
						sprintf(buffer, "FORCING THE SLICE INDEX TO [%d]", model_index); simpleLog(buffer);

						dotSetArrayIndex(model_index);
						anchorSetArrayIndex(model_index);



						for (int ii = 0; ii < nAnchors; ii++)
						{
							printf(" [%4d] <%10.6f %10.6f %10.6f>\n", ii, ptrToArray[0], ptrToArray[1], ptrToArray[2]);
							addAnchor_NO_TCL(&ptrToArray[0], &ptrToArray[1], &ptrToArray[2]);
							ptrToArray++;
							ptrToArray++;
							ptrToArray++;
						}

					}
				}
				else
				{
					sprintf(buffer, "DEBUG : Skip processing of anchor data for non current specimen [%d] [%d] of [%d] [%d]",
						count_ANCHORS, model_index, model_amount - 1, model_amount);
					simpleLog(buffer);
				}

				// we are done with the allocated memory because it has been transferred to the model 
				free(ptrToAnchor);
				ptrToAnchor = NULL;

			}



		}
		//////////////////////////////////////////////////////////////////////

	} // end while




	fclose(file);
	simpleLog("DEBUG : successful return from ogl_loadDgtModel");
	simpleLogBlankLine();
	return 0;
}

// FUNCTION STILL UNDER DEVELOPMENT - CRASHES IN THE R ENVIRONMENT
int ogl_eraseDownSampleDataForModel( model_t* model)
{
	if (NULL == model)
	{
		sprintf(ogl_buffer, "ERROR : ogl_eraseDownSampleDataForModel ... NULL pointer for model");
		simpleLog(ogl_buffer);
		return -1;
	}

	if (NULL != model->dsVertex)
	{
		FREE(model->dsVertex);    // yes this macro tests the pointer as well ...
		model->dsVertex = NULL;
		model->dsMax[0] = 0.0;
		model->dsMax[1] = 0.0;
		model->dsMax[2] = 0.0;
		model->dsMin[0] = 0.0;
		model->dsMin[1] = 0.0;
		model->dsMin[2] = 0.0;
		model->dsVertexSize = 0;
		simpleLog("INFO : existing downsample data has been freed");
	}

	sprintf(ogl_buffer, "INFO : ogl_eraseDownSampleDataForModel .. end");
	simpleLog(ogl_buffer);
	return 0; 
}

// FUNCTION STILL UNDER DEVELOPMENT - CRASHES IN THE R ENVIRONMENT
int ogl_eraseVertexDataForModel(model_t* model)
{
	if (NULL == model)
	{
		simpleLog("ogl_eraseVertexDataForModel.... NULL pointer for model");
		return -1;
	}

	if (model->vertex != NULL)
	{
		free(model->vertex);
		model->vertex = NULL;
	}
	if (model->normal != NULL)
	{
		free(model->normal);
		model->normal = NULL;
	}
	if (model->color != NULL)
	{
		free(model->color);
		model->color = NULL;
	}
	model->vertexSize = 0;
	model->colorSize = 0;
	model->normalSize = 0;
	return 0;
}