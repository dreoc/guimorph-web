#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include "RunTime_Defines_ZARF_9.h"
#include "def_ZARF_9.h"

const char CURVE_VERSION_INFORMATION[] = "File curve Edit revision date is 15 August 2020 4:22 PM";



const char* curveVersionPtr = CURVE_VERSION_INFORMATION;




const extern float GBL_INWORK_CURVE_SCALEFACTOR_MPY;
const extern float GBL_INWORK_CURVE_SCALEFACTOR_ADD;

// NOTE TO DEVELOPERS - MAKE SURE ALL printf statements are commented out
// for use in building the library !

static curve_t** curves = NULL; /*stores each individual curve with an associated id*/
static int curve_slice_id = 0;
static int curve_slice_amount = 0;

static char curveBuffer[256];

curve_t** getPointerToCurveVector()
{
	return curves;
}

// id is the array index : also known as the slice number (which specimen)
curve_t* get_curveAtIndex(int id)
{
	if (id < 0)
	{
		return NULL;
	}

	if (id >= curve_slice_amount)
	{
		return NULL;
	}
	///printf("get_curveAtIndex [%d]\n", id);

	curve_t* temp = NULL;
	temp = curves[id];
	return temp;
}

int get_curve_slice_index()  { return curve_slice_id; }
int get_curve_slice_id()     { return curve_slice_id; }
int get_curve_slice_amount() { return curve_slice_amount; }

 float absf(float a, float b)
{
	return a > b ? a - b : b - a;
}


 // creates and intitializes a single curve instance effectively 
 // the constructor

curve_t* curve_create() 
{
	curve_t* curve = (curve_t*)ALLOCATE_WRAPPER((unsigned int)(sizeof(curve_t)));
	if (NULL == curve)
	{
		return NULL;
	}
	if (0 != initialize_Curve(curve))
	{
		simpleLog("ERROR : curve_create ... fail to intitialize ... how can this happen ?");
	}
	return curve;
}

int curve_release(curve_t* curve)   // effectively the destructor for the array of pointers
{
	if (NULL == curve) { return -1; }
	FREE_WRAPPER((void*)curve);
	curve = NULL;
	return 0;
}


// grabs ith curve specified by the curve_slice_id
curve_t* curve_get()
{
	return curves[curve_slice_id];
}

/*gets ith dot identified by pointNum  ... from the selected slice (specimen index) */
int curve_getDotId()
{
	return curves[curve_slice_id]->pointNum;
}

// Allocate the curve array (array of pointers) : one index allocated 
// for each specimen
//
int curveAllocateArray(int numberOfSlices)
{
	if (numberOfSlices < 0)
	{
		sprintf(curveBuffer, "ERROR curveAllocateArray ... number of curves negative [%d]", numberOfSlices);
		simpleLog(curveBuffer);
		return -1;
	}

	int rv = -1;
	rv = set_curve_slice_amount(numberOfSlices);
	if (0 == rv)
	{
		sprintf(curveBuffer, "DEBUG : Have allocated [%d] curve slices -OK-", numberOfSlices);
		simpleLog(curveBuffer);
	}
	else
	{
		sprintf(curveBuffer, "ERROR : Failed to allocate [%d] curve slices -OK-", numberOfSlices);
		simpleLog(curveBuffer);
	}

	return rv;
}

int curveReleaseArray()
{
	int rv = -1;
	rv = set_curve_slice_amount(0);
	return rv;
}

int curveSetArrayIndex(int whichIndex)
{
	int rv = -1;
	rv = set_curve_slice_index(whichIndex);
	return rv;
}

// This function allocates an array of curve_t items.
// any previously allocated array is deallocated.
// The newly allocated array is initialized 
// Argument amount corresponds to the number of specimens
int set_curve_slice_amount(int amount)
{
	if (amount < 0)
	{
		sprintf(curveBuffer, "ERROR : curve_slice_amount non positive [%d]", amount);
		simpleLog(curveBuffer);
		return -1;
	}

	if (curve_slice_amount < 0)   // previously allocated memory in error ?
	{
		sprintf(curveBuffer, "ERROR : curve_slice_amount negative [%d]", curve_slice_amount);
		simpleLog(curveBuffer);
		return -1;
	}

	if (curves != NULL)
	{
		for (int i = 0; i < curve_slice_amount; i++)
		{
			curve_t* n = curves[i];
			while (n != NULL)
			{
				curve_t* t = n;
				n = n->next;
				FREE_WRAPPER((void*)t);
			}
		}
		FREE_WRAPPER((void*)curves);
		curves = NULL;
	}

	if (NULL != curves)
	{
		sprintf(curveBuffer, "ERROR : CODE ERROR : curves should have been deallocated but were not");
		simpleLog(curveBuffer);
		return -1;
	}

	curve_slice_id = 0;

	const unsigned int howMuch = (unsigned int)(amount * sizeof(curve_t*));

	curves = (curve_t**)ALLOCATE_WRAPPER(howMuch);
	if (NULL == curves)
	{
		curve_slice_amount = 0; // failed to allocate 
		sprintf(curveBuffer, "FAIL : curve_slice_amount did not allocate memory [%u]", howMuch);
		simpleLog(curveBuffer);
		return -1;
	}
	else
	{
		memset(curves, 0, howMuch);
		curve_slice_amount = amount; // successfull allocation
	}

	for (int ii = 0; ii < amount;  ii++)
	{
		clearCurve(curves[ii]);
	}
	
	for (int ii = 0; ii < amount; ii++)
	{
		//simpleLogWriteCurveToFile(curves[ii]);
	}

	sprintf(curveBuffer, "INFO : Allocated [%d] curve items", curve_slice_amount);
	simpleLog(curveBuffer);
	return 0;
}

// sets curve_slice_id to specified id 
int set_curve_slice_index(int id)
{
	if (id >= curve_slice_amount)
	{
		sprintf(curveBuffer, "ERROR : attempt to set index beyond the allocated array [%d]", id);
		simpleLog(curveBuffer);
		return -1;
	}

	if (id < 0)
	{
		sprintf(curveBuffer, "ERROR : attempt to set index negative [%d]", id);
		simpleLog(curveBuffer);
		return -1;
	}

	if (id < curve_slice_amount)
	{
		curve_slice_id = id;
		return 0;   // this is the success return
	}
	// else .... 
	sprintf(curveBuffer, "ERROR  curve_slice_index requested id [%d] not less than curve_slice_amount [%d]", id, curve_slice_amount);
	simpleLog(curveBuffer);
	return -1;
}

int initialize_Curve(curve_t* c)
{
	if (NULL == c)
	{
		sprintf(curveBuffer, "ERROR initialize_Curve : NULL pointer for argument");
		simpleLog(curveBuffer);
		return -1;
	}
	c->lines1 = NULL;
	c->lines2 = NULL;
	c->points[0] = NULL;
	c->points[1] = NULL;
	c->points[2] = NULL;
	c->line1Size = 0;
	c->line2Size = 0;
	c->pointNum = 0;
	c->next = NULL;
	return 0;
}



// id is the slice id for the curves (this is the speciment index)
int curve_addDot(int id, dot_t* d)
{
	if (NULL == curves)
	{
		sprintf(curveBuffer, "ERROR : curve_addDot : curves is NULL");
		simpleLog(curveBuffer);
		return -1;
	}

	if (NULL == d)
	{
		sprintf(curveBuffer, "ERROR : curve_addDot : null pointer for dot");
		simpleLog(curveBuffer);
		return -1;
	}

	if (id < 0)
	{
		sprintf(curveBuffer, "ERROR : curve_addDot : argument id negative [%d]", id);
		simpleLog(curveBuffer);
		return -1;
	}

	if (id >= curve_slice_amount)
	{
		sprintf(curveBuffer, "ERROR : curve_addDot : id [%d] >= curve_slice_amount [%d]", id, curve_slice_amount);
		simpleLog(curveBuffer);
		return -1;
	}

	point_t* p = &d->p;    /*get the dot point*/
	if (NULL == p)
	{
		sprintf(curveBuffer, "ERROR : curve_addDot : NULL dot point for dot_t pointer");
		simpleLog(curveBuffer);
		return -1;
	}


	if (NULL == curves[id])
	{
		curve_t* temp = NULL;
		temp = curve_create();
		if (NULL == temp)
		{
			sprintf(curveBuffer, "ERROR : curve_addDot : NULL pointer from curve_create");
			simpleLog(curveBuffer);
			return -1;
		}
		else
		{
			curve_t* c;
			c = temp;
			clearCurve(c);
			sprintf(curveBuffer, "INFO : success from curve_create for id (slice index) [%d]", id);
			simpleLog(curveBuffer);
			curves[id] = temp;
		}
	}

	simpleLog("CURVE/ADDDOT");
	sprintf(curveBuffer, "INFO : this is curve_addDot and the slice index (id) is [%d]", id);
	simpleLog(curveBuffer);

	// else curves[id] was not null ... it had at least one curve_t in a list
	// else curves[id] is not now null so here pointer 'c' is also not null
	curve_t* c = curves[id];
	// if c->pointNum is 0, then we can place the point and we are done
	// if c->pointNum is 1, then we can place the point and we are done
	// if c->pointNum is 2, then we can place the point and we are done
	// if c->pointNum is 3, then the node is full. c points to a valid- full node
	// 
	int pointsIndex = -1;
	switch (c->pointNum)
	{
	case 0:
	case 1:
		pointsIndex = curves[id]->pointNum;
		curves[id]->points[pointsIndex] = p;
		curves[id]->pointNum++;
		sprintf(curveBuffer,"added another point to the existing curve node. Point count is now [%d]\n", curves[id]->pointNum);
		simpleLog(curveBuffer);

		return 0; // success
		break;
	case 2:  // the point to be added is the 3rd : generate the line
	{
		pointsIndex = curves[id]->pointNum;
		curves[id]->points[pointsIndex] = p;
		curves[id]->pointNum++;
		sprintf(curveBuffer,"added another point to the existing curve node. Point count is now [%d]\n", curves[id]->pointNum);
		simpleLog(curveBuffer);
		c->line1Size = curve_buildLine(c->points[0], c->points[1], &c->lines1);
		c->line2Size = curve_buildLine(c->points[2], c->points[1], &c->lines2);
		//simpleLogWriteCurveToFile(curves[id]);
		return 0; // success 
		break;
	}
	case 3:
	{
		// make a new node and place it INFRONT of the current full node
		// place the point and we are done
		curve_t* temp = NULL;
		temp = curve_create();
		if (NULL == temp)
		{
			sprintf(curveBuffer, "ERROR : curve_addDot : NULL pointer from curve_create");
			simpleLog(curveBuffer);
			return -1;
		}
		else
		{
			clearCurve(temp);
			temp->next = c;
			curves[id] = temp;
			pointsIndex = curves[id]->pointNum;
			curves[id]->points[pointsIndex] = p;  /*first point is p*/
			curves[id]->pointNum++;
			sprintf(curveBuffer, "INFO : success from curve_create");
			simpleLog(curveBuffer);
			return 0; // success !
			break;
		}
	}
	default:
	{
		sprintf(curveBuffer, "ERROR : default case for point count on a curve : count is [%d]\n", curves[id]->pointNum);
		simpleLog(curveBuffer);
	}
	};
	return -1;
}



int curve_buildLine(point_t* p1, point_t* p2, point_t** line)
{
	if (NULL == p1)
	{
		simpleLog("ERROR : curve_buildLine ... NULL pointer for p1");
		return -1;
	}
	if (NULL == p2)
	{
		simpleLog("ERROR : curve_buildLine ... NULL pointer for p2");
		return -1;
	}

	if (NULL == line)
	{
		simpleLog("ERROR : curve_buildLine ... NULL pointer for line (point_t **line) ");
		return -1;
	}

	sprintf(curveBuffer, "curve_buildLine : multiplier <%10.6f>", GBL_INWORK_CURVE_SCALEFACTOR_MPY);
	simpleLog(curveBuffer);
	sprintf(curveBuffer, "curve_buildLine : additive   <%10.6f>", GBL_INWORK_CURVE_SCALEFACTOR_ADD);
	simpleLog(curveBuffer);



	const float precision = 0.002;      // loop execution time below is sensitive to this parameter
	if (absf(p2->x, p1->x) < precision) /*points are already close together, skip incrementation process*/
	{
		// build the line
		if (*line != NULL)
		{
			FREE_WRAPPER((void*)*line);  //if memory already allocated, free it up
			*line = NULL;
		}
		unsigned int howMuch = -1;
		const int numberOfLines = 2;
		howMuch = (unsigned int)(sizeof(point_t) * 2);

		*line = (point_t*)ALLOCATE_WRAPPER(howMuch); // allocate memory for 2 lines 
		if (NULL == *line)
		{
			sprintf(curveBuffer, "failed to allocate line pointer of size [%d] (bytes)", (int)howMuch);
			simpleLog(curveBuffer);
			sprintf(curveBuffer, "failed to allocate line pointer of size [%d] (2 lines)", (int)numberOfLines);
			simpleLog(curveBuffer);
			return -1;
		}

		sprintf(curveBuffer, "INFO : allocated line of size [%d] ", (int)howMuch);
		simpleLog(curveBuffer);

		(*line)[0].x = p1->x;
		(*line)[0].y = p1->x;
		(*line)[0].z = getRealZ(p1->x, p1->y, p1->z);
		(*line)[1].x = p2->x;
		(*line)[1].y = p2->x;
		(*line)[1].z = getRealZ(p2->x, p2->y, p2->z);
		return 0;
	}
	else  // not already close together
	{

		if (*line != NULL) FREE_WRAPPER((void*)*line);

		int size = (int)(absf(p2->x, p1->x) / precision);
		const int size_no_spare_space = size;
		const int size_with_space_space = size + 3;

		sprintf(curveBuffer, "size of line is (calculated) %d", size_no_spare_space);
		simpleLog(curveBuffer);
		sprintf(curveBuffer, "size of line is (with spare) %d", size_with_space_space);
		simpleLog(curveBuffer);

		unsigned int howMuch;
		howMuch = (unsigned int)((int)sizeof(point_t) * size_with_space_space);

		*line = (point_t*)ALLOCATE_WRAPPER(howMuch);
		if (NULL == *line)
		{
			sprintf(curveBuffer, "ERROR : failed to allocate *line of size[ %d]", (int)howMuch);
			simpleLog(curveBuffer);
			return -1;
		}

		sprintf(curveBuffer, "INFO : allocated line of size [%d] bytes ", (int)howMuch);
		simpleLog(curveBuffer);


		float divisor;
		if (0 == (p2->x - p1->x))
		{
			divisor = 1;
			simpleLog("ERROR : detected zero divisor ... set it to 1");
		}
		else
		{
			divisor = (p2->x - p1->x);
		}


		float a = (p2->y - p1->y) / divisor;  // slope
		float b = p1->y - a * p1->x;          // intercept


		float beg, end;
		// starting points to build line from pt 1 to pt 2 or vice versa
		if (p2->x > p1->x)
		{
			beg = p1->x;
			end = p2->x;
		}
		else
		{
			beg = p2->x;
			end = p1->x;
		}


		// based on an apparent defect the following condition tests are added 
		// to avoid an unending loop.
		// Trouble item seems to be the resolution value
		int indexEstimate = 0;
		{
			///printf("curve build line parameters...\n");
			///printf("beg %10.6f ... end %10.6f ... precision %10.6f\n", beg, end, precision);
			float b = beg;
			float e = end;
			//if (b < 0) { b = -1.0 * b; }
			//if (e < 0) { e = -1.0 * e; }


			indexEstimate = (int)((e-b) / precision);
			///printf("index estimate [%d]\n", indexEstimate);
		}

		//build line
		int i = 0;
		int indexCheck = 0;
		for (float x = beg; x <= end; x += precision)
		{
			float y = a * x + b;
			(*line)[i].x = x;
			(*line)[i].y = y;
			(*line)[i].z = getRealZ(x, y, p1->z);

			//if both points live in 3D (with same sign), increment z coord 
			if (p1->z > 0.0 && p2->z > 0.0)
			{
				(*line)[i].z += precision;
			}
			else if (p1->z < 0.0 && p2->z < 0.0)
			{
				(*line)[i].z -= precision;
			}


			// added this code to test moving the curve off the specimen
			// for visibility
			// if the values are 1.0 for multuply and 0.0 for add
			// then we do nothing
			// this is development ONLY 
			// so expect issues if the developer is not careful in setting these values
			// which is done in the R code !


			// looking at the operation - yes it is possible to have a multiplication factor 
			// other than 1.00 AND an offset value other than 0.00 at the same time
			// This is ONLY a developer test  ... the intent is to investigate to only two decimal places
		
			// context 
			{
				(*line)[i].z *= GBL_INWORK_CURVE_SCALEFACTOR_MPY;
			}

			// another context 
			{
				(*line)[i].z += GBL_INWORK_CURVE_SCALEFACTOR_ADD;
			}


			//
			//
			// if the following output lines are uncommented, the build
			// line process slows SIGNIFICANTLY.  These are intended for development
			// use... 
			// sprintf(curveBuffer, "build line loop [%d] x=%f,  y=%f,  z=%f", i, (*line)[i].x, (*line)[i].y, (*line)[i].z);
			// simpleLog(curveBuffer);
			//
			//

			i++;
			indexCheck++;
			if (indexCheck >= indexEstimate)
			{
				sprintf(curveBuffer, "WARNING : curve_buildLine ... ");
				simpleLog(curveBuffer);
				sprintf(curveBuffer, "caught possible overflow [%d] ... [% d]{ % d }",
					indexCheck, size_no_spare_space, size_with_space_space);
				simpleLog(curveBuffer);
				break;
			}


			if (i > size_no_spare_space)
			{
				sprintf(curveBuffer, "WARNING : curve_buildLine ... ");
				simpleLog(curveBuffer);

				sprintf(curveBuffer, "caught possible overflow [%d] ... [%d] {%d}",
					i, size_no_spare_space, size_with_space_space);
				simpleLog(curveBuffer);
				break;
			}
		}
		sprintf(curveBuffer, "DEBUG : build line loop  has completed ... max i [%d]", i);
		simpleLog(curveBuffer);

		sprintf(curveBuffer, "DEBUG : the number of points generated is  [%d]", size_no_spare_space);
		simpleLog(curveBuffer);
		return size_no_spare_space;  
	}

	simpleLog("ERROR : unsuccessful processing curve_buildLine ... INVESTIGATE ");
	return -1;
}

