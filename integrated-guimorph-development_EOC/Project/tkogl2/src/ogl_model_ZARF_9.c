#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include <math.h>
#include "def_ZARF_9.h"
#include "RunTime_Defines_ZARF_9.h"
#if defined(_WIN32)
#include <GL/glut.h>   /* BLD-04: GLUT retained on Windows only, for glutBitmapCharacter numeric labels */
#endif
static char  oglBuffer[128];
const char OGL_MODEL_VERSION_INFORMATION[] = "File ogl_model Edit revision date is 15 August 2020 4:22 PM";

const char* oglModelVersionPtr = OGL_MODEL_VERSION_INFORMATION;

extern float GBL_INWORK_CURVE_SCALEFACTOR_MPY;   
extern float GBL_INWORK_CURVE_SCALEFACTOR_ADD;  

extern float GBL_INWORK_LABEL_SCALEFACTOR_MPY;
extern float GBL_INWORK_LABEL_SCALEFACTOR_ADD;


static void dump(float* data)
{
	static int dumped = 0;
	if (data == NULL) return;
	if (dumped) return;
	dumped = 1;
	for (int i = 0; i < 20; i += 4)
	{
		//printf("%f %f %f %f\n", data[i], data[i + 1], data[i + 2], data[i + 3]);
		sprintf(oglBuffer, "function dump : %f %f %f %f\n", data[i], data[i + 1], data[i + 2], data[i + 3]);
		simpleLog(oglBuffer);
	}
}

int ogl_DrawTriangle()
{
	glBegin(GL_TRIANGLES);
	glColor3f(0.1, 0.2, 0.3);
	glVertex3f(0, 0, 0);
	glVertex3f(1, 0, 0);
	glVertex3f(0, 1, 0);
	glEnd();
	return 0;
}

int ogl_drawModel(model_t* model)
{
	/* DAT-03 parity relies on the same vertex ordering after load/save cycles.
	 * Draw order is intentionally tied to model->count with no platform-specific
	 * reindexing so byte-validated fixtures remain semantically equivalent. */
	glEnableClientState(GL_VERTEX_ARRAY); /*enables vertex array for writing and used during rendering*/
	glEnableClientState(GL_NORMAL_ARRAY); /*enables normal array for writing and used during rendering*/
	glVertexPointer(3, GL_FLOAT, 0, model->vertex); /*defines an array of vertex, we are storing it in the model's vertex*/

	/*if color exists, write it to color matrix using model's color*/
	if (model->color != NULL)
	{
		ogl_disableLight();
		glEnableClientState(GL_COLOR_ARRAY);
		/*glColorPointer(GLint size, GLenum type, GLsizei stride, const GLvoid *pointer)*/
		glColorPointer(4, GL_FLOAT, 0, model->color);
	}
	/*if not, use regular lighting*/
	else
	{
		ogl_enableLight();
	}

	glNormalPointer(GL_FLOAT, 0, model->normal); /*defines array of normals, using model's normal*/
	/*void glDrawArrays(GLenum mode, GLint first, GLsizei count); mode - specifies what kind of primitive to render. first - specifies the starting index in the enabled arrays. count - specifies the number of
	indices to be rendered*/
	glDrawArrays(GL_TRIANGLES, 0, model->count); /*renders the primitives from array data*/
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	return 0;
}

/*max and min array of x,y,z max and min values*/
int ogl_drawCube(float* max, float* min)
{
	/* Draw a simple cube. */
	glBegin(GL_QUADS); /*treats each group of four vertices as an independent quadrilateral*/

	glColor4f(0.8f, 0.8f, 0.8f, 0.1f);
	glVertex3f(max[X], max[Y], max[Z]);
	glVertex3f(max[X], max[Y], min[Z]);
	glVertex3f(min[X], max[Y], min[Z]);
	glVertex3f(min[X], max[Y], max[Z]);

	glVertex3f(max[X], min[Y], max[Z]);
	glVertex3f(min[X], min[Y], max[Z]);
	glVertex3f(min[X], min[Y], min[Z]);
	glVertex3f(max[X], min[Y], min[Z]);

	glVertex3f(max[X], max[Y], max[Z]);
	glVertex3f(min[X], max[Y], max[Z]);
	glVertex3f(min[X], min[Y], max[Z]);
	glVertex3f(max[X], min[Y], max[Z]);

	glVertex3f(max[X], max[Y], min[Z]);
	glVertex3f(max[X], min[Y], min[Z]);
	glVertex3f(min[X], min[Y], min[Z]);
	glVertex3f(min[X], max[Y], min[Z]);

	glVertex3f(min[X], max[Y], max[Z]);
	glVertex3f(min[X], max[Y], min[Z]);
	glVertex3f(min[X], min[Y], min[Z]);
	glVertex3f(min[X], min[Y], max[Z]);

	glVertex3f(max[X], max[Y], max[Z]);
	glVertex3f(max[X], min[Y], max[Z]);
	glVertex3f(max[X], min[Y], min[Z]);
	glVertex3f(max[X], max[Y], min[Z]);

	glEnd();
	return 0;
}

int ogl_grid(float* max, float* min)
{
	glBegin(GL_LINES); /*treats each pair of vertices as an independent line segment*/
	glColor4f(0.8f, 0.8f, 0.8f, 0.2f);
	for (float z = min[Z]; z <= max[Z]; z += (float)((double)max[Z] - (double)min[Z]) / 10.0)
	{
		/*builds grid along Z axis*/
		glVertex3f(min[X], max[Y], z);
		glVertex3f(max[X], max[Y], z);

		glVertex3f(max[X], max[Y], z);
		glVertex3f(max[X], min[Y], z);

		glVertex3f(min[X], min[Y], z);
		glVertex3f(max[X], min[Y], z);

		glVertex3f(min[X], max[Y], z);
		glVertex3f(min[X], min[Y], z);
	}

	for (float x = min[X]; x <= max[X]; x += (float)((double)max[X] - (double)min[X]) / 10.0)
	{
		/*Builds grid along x axis*/
		glVertex3f(x, min[Y], max[Z]);
		glVertex3f(x, max[Y], max[Z]);

		glVertex3f(x, max[Y], max[Z]);
		glVertex3f(x, max[Y], min[Z]);

		glVertex3f(x, min[Y], min[Z]);
		glVertex3f(x, max[Y], min[Z]);

		glVertex3f(x, min[Y], max[Z]);
		glVertex3f(x, min[Y], min[Z]);
	}

	for (float y = min[Y]; y <= max[Y]; y += (float)((double)max[Y] - (double)min[Y]) / 10.0)
	{
		/*builds grid along y axis*/
		glVertex3f(min[X], y, max[Z]);
		glVertex3f(max[X], y, max[Z]);

		glVertex3f(max[X], y, max[Z]);
		glVertex3f(max[X], y, min[Z]);

		glVertex3f(min[X], y, min[Z]);
		glVertex3f(max[X], y, min[Z]);

		glVertex3f(min[X], y, max[Z]);
		glVertex3f(min[X], y, min[Z]);
	}

	glEnd();
	return 0;
}

/*raster = matrix of cells organized into rows and columns where each cell contains a value representing information, such as temperature*/
int ogl_drawLabel(point_t* p, color_t* c, int id, GLdouble dotRadius, float z)
{
	sprintf(oglBuffer, "DEBUG : label index is [%d]", id);
	simpleLog(oglBuffer);

#ifdef NO_GRAPHICS
	return 0;
#endif

	glPushMatrix(); /*Creates matrix 1 on the top*/
	/*applies the following transformations*/
	glTranslatef(p->x, p->y, z);/*multiplies current matrix by a translation matrix (x,y,z) coords of translation vector*/
	glColor3f(c->r, c->g, c->b); /*sets the color*/
	glRasterPos3f(dotRadius * 2, 0.0, p->z); /*Specifies raster position for pixel operations*/
	/*draw text*/
#if defined(_WIN32)
	if (id >= 10) {
		glutBitmapCharacter(GLUT_BITMAP_9_BY_15, '0' + (id / 10));
	}
	glutBitmapCharacter(GLUT_BITMAP_9_BY_15, '0' + (id % 10));
#else
	/* BLD-04 (Phase 3): GLUT bitmap fonts are unavailable off Windows. Numeric
	 * landmark labels on macOS are deferred to Phase 4/5 (portable text via a
	 * GL bitmap font or a textured glyph atlas). The dot itself still draws. */
	(void)id;
#endif
	glPopMatrix(); /*removes matrix 1 from stack (i.e. stop doing transformations)*/
	return 0;
}

int ogl_drawDot(point_t* p, color_t* c, GLdouble radius)
{
	if (NULL == p)
	{
		simpleLog("ERROR : NULL pointer for point in ogl_draw_dot");
		return -1;
	}
	if (NULL == c)
	{
		simpleLog("ERROR : NULL pointer for color  in ogl_draw_dot");
		return -1;
	}
	if (radius <= 0.0)
	{
		simpleLog("WARNING : non positive value for radius ogl_draw_dot");
	}


#ifdef NO_GRAPHICS
	return 0;
#endif

	/*creates simple shapes from respective math equation*/
	GLUquadric* qobj = gluNewQuadric();
	gluQuadricNormals(qobj, GLU_SMOOTH); /*specifies what kind of normals are desired for quadrics, here we are generating one normal for every vertex
	of the quadric*/
	glPushMatrix();/*begin transformations*/

	// if the scale factors are the intert vales : do nothing. THis is the original implementation
	if ((1.0 == GBL_INWORK_LABEL_SCALEFACTOR_MPY) && (0 == GBL_INWORK_LABEL_SCALEFACTOR_ADD))
	{
		glTranslatef(p->x, p->y, p->z); /*position of dot*/
	}
	else
	{   // else move the dot off the surface
		float tempZ;
		tempZ = GBL_INWORK_LABEL_SCALEFACTOR_MPY * p->z + GBL_INWORK_LABEL_SCALEFACTOR_ADD;
		glTranslatef(p->x, p->y, tempZ); 
	}
	
	
	glColor3f(c->r, c->g, c->b);    /*color of dot*/


	gluSphere(qobj, radius, 10, 10); /*construct dot (BLD-04: gluSphere replaces glutSolidSphere and reuses the qobj created above, which the original code allocated then leaked)*/
	glPopMatrix();/*remove transformation matrix*/
	gluDeleteQuadric(qobj);
	return 0;
}

int ogl_drawDownSampleModel(model_t* model, GLdouble radius, point_t* downSampleOffset)
{
	simpleLogBlankLine();
	simpleLog("OGL_DRAW_DOWNSAMPLE_MODEL start");

	if (NULL == model)
	{

		simpleLog("ERROR : Null pointer to model");
		return -1;
	}

	if (NULL == downSampleOffset)
	{
		simpleLog("ERROR : Null pointer to point_t : downSampleOffset");
		simpleLog("OGL_DRAW_DOWNSAMPLE_MODEL end");
		simpleLogBlankLine();
		return -1;
	}

	if (NULL == model->dsVertex)
	{
		simpleLog("ERROR :  oglModel : NULL dsVertex pointer patch 13 JULY 2020");
		simpleLog("OGL_DRAW_DOWNSAMPLE_MODEL end");
		simpleLogBlankLine();
		return -1;
	}
	if ((int)model->dsCount <= 0)
	{
		simpleLog("ERROR :  oglModel : dsCount <= 0  patch  13 JULY 2020 ");
		simpleLog("OGL_DRAW_DOWNSAMPLE_MODEL end");
		simpleLogBlankLine();
		return -1;
	}


	/*downsample calculations*/
	double dx = 0.0, dy = 0.0, dz = 0.0;
	sprintf(oglBuffer, "INFO : dx items  <%10.6f> ... <%10.6f>", (float)model->dsMax[X], (float)model->max[X]);
	simpleLog(oglBuffer);
	sprintf(oglBuffer, "INFO : dy items  <%10.6f> ... <%10.6f>", (float)model->dsMax[Y], (float)model->max[Y]);
	simpleLog(oglBuffer);
	sprintf(oglBuffer, "INFO : dz items  <%10.6f> ... <%10.6f>", (float)model->dsMax[Z], (float)model->max[Z]);
	simpleLog(oglBuffer);

	dx = (double)model->dsMax[X] - (double)model->max[X];
	dy = (double)model->dsMax[Y] - (double)model->max[Y];
	dz = (double)model->dsMax[Z] - (double)model->max[Z];

	sprintf(oglBuffer, "INFO : delta items : %10.6f, %10.6f, %10.6f", model->delta[0], model->delta[1], model->delta[2]);
	simpleLog(oglBuffer);

	/*begin transformation*/
	simpleLog("DEBUG : calling glPushMatrix");
	glPushMatrix();

	simpleLog("DEBUG : calling glColor3f (to blue)");
	glColor3f(0.0, 0.0, 1.0); /*set the dot color to blue*/

	sprintf(oglBuffer, "INFO : ogl_drawDownSampleModel  model ds Count [%d]", (int)model->dsCount);
	simpleLog(oglBuffer);
	sprintf(oglBuffer, "DEBUG : dsVertex test for NULL pointer %s", (NULL == model->dsVertex) ? "NULL -ERROR-" : "-ok- not null -ok-");
	simpleLog(oglBuffer);
	if (NULL == model->dsVertex)
	{
		simpleLogBlankLine();
		simpleLog("ERROR !   oglModel line 256 ! ");
		simpleLogBlankLine();
	}


	///////////////////////////
	// attempting to determine crash cause

	float* pToFloat = NULL;
	pToFloat = &model->dsVertex[0];
	if (NULL == pToFloat)
	{
		simpleLog("ERROR : pointer to dsVertex[0] is null ... memory corrupt ?");
		return -1;
	}
	int howMany = 0;
#ifdef STAND_ALONE_TOOL
	for (int ii = 0; ii < (int)model->dsCount; ii++)
	{
		if (NULL == pToFloat)
		{
			sprintf(oglBuffer, "ERROR : in loop ... pointer to dsVertex[%d] is null ... memory corrupt ?", ii);
			simpleLog(oglBuffer);
			return -1;
		}
		sprintf(oglBuffer, "DEBUG : current index [%5d] ... <%10.6f>", ii, *pToFloat);
		simpleLog(oglBuffer);
		pToFloat++;
		howMany++;

	}
	sprintf(oglBuffer, "DEBUG : Have iterated over [%d] dsVertices ... -OK-", howMany);
	simpleLog(oglBuffer);
#endif



	// iterates through each downsample dot and places it on the i,i+1,i+2 vertex with a radius of 10*/

	// the below tests are redundant now due to above iteration test loop
	int breakFlag = 0;
	GLUquadric* dsQobj = gluNewQuadric();          /* BLD-04: gluSphere replaces glutSolidSphere; one quadric reused for all downsample dots */
	gluQuadricNormals(dsQobj, GLU_SMOOTH);

	if (0 == breakFlag)
	{
		for (int i = 0; i < model->dsCount; i += 3)
		{

			//sprintf(oglBuffer, "DEBUG : loop index is [%d]", (int)i);
			//simpleLog(oglBuffer);

			if (NULL == model->dsVertex) { breakFlag = 1; }
			if (1 == breakFlag)
			{
				break;
			}



			double tx = (double)model->dsVertex[i + 0];
			double ty = (double)model->dsVertex[i + 1];
			double tz = (double)model->dsVertex[i + 2];     // ?? Are doubles acceptable for GLfloats 

			//simpleLog("DEBUG : calling glTranslate");
			glTranslatef(tx, ty, tz); /*will multiply current matrix by translation matrix generated by tx, ty, tz*/

			// why is this dead code still here ??
			/*void glutSolidSphere(GLdouble radius, GLint slices, GLint stacks)*/
			/*slices - number of subidvisions around the Z axis (similar to lines of longitude)*/
			/*stacks - number of subdivisions along the Z axis (similar to lines of latitude)*/

			//simpleLog("DEBUG : calling  gluSphere");
			gluSphere(dsQobj, radius, 10, 10);

			//simpleLog("DEBUG : calling glTranslate");
			glTranslatef(0 - tx, 0 - ty, 0 - tz);
		}

	}

	gluDeleteQuadric(dsQobj);


	if (1 == breakFlag)
	{
		simpleLog("ERROR : breakflag is 1 ... ");
	}

	simpleLog("DEBUG : iteration loop complete ... calling glPopMatrix");
	glPopMatrix(); /*end transformation*/
	simpleLog("OGL_DRAW_DOWNSAMPLE_MODEL end");
	return 0;
}



/*difference of squares*/
float dsquare(float a, float b)
{
	return (float)((double)a * (double)a - (double)b * (double)b);
}

/*divided difference of squares*/
float formula1(float x1, float x2)
{
	return dsquare(x1, x2) / (x2 - x1);
}

int ogl_drawCurve1(point_t* beg, point_t* mid, point_t* end)
{
	/*curve calculations*/
	float a, b, c;
	a = ((end->y - mid->y) * (mid->x - beg->x) - (mid->y - beg->y) * (end->x - mid->x))
		/ (dsquare(end->x, mid->x) * (mid->x - beg->x) - dsquare(mid->x, beg->x) * (end->x - mid->x));

	// b = (mid->y - beg->y - a * dsquare(mid->x, beg->x)) / (mid->x - beg->x);
	// received compiler warning for floats and doubles mixed
	b = (float)((mid->y - beg->y - (double)a * (double)dsquare(mid->x, beg->x)) / (mid->x - beg->x));


	c = beg->y - a * beg->x * beg->x - b * beg->x;
	//printf("a=%f, b=%f, c=%f\n", a, b, c);
	sprintf(oglBuffer, "ogl_draw_curve : a=%f, b=%f, c=%f\n", a, b, c);
	simpleLog(oglBuffer);

	/*draw connected line segment from vertices n and n+1, color it red*/
	glBegin(GL_LINE_STRIP);
	glColor3f(1.0f, 0.0f, 0.0f);

	/*draws the curve*/
	for (float x = beg->x; x <= end->x; x += 0.0001f)
	{
		float y = a * x * x + b * x + c;
		glVertex2f(x, y);
	}
	glEnd();
	return 0;
}

/*Used to model smooth curves that can be scaled indefinitely*/
void bezierPoint(point_t* p1, point_t* p2, point_t* p3, double t, point_t* p)
{
	/*Cubic Bezier curve*/
	double a1 = pow((1 - t), 3);
	double a2 = pow((1 - t), 2) * 3 * t;
	double a3 = 3 * t * t * (1 - t);
	double a4 = t * t * t;

	p->x = a1 * p1->x + a2 * p2->x + a3 * p2->x + a4 * p3->x;
	p->y = a1 * p1->y + a2 * p2->y + a3 * p2->y + a4 * p3->y;
}

int ogl_drawLine(point_t* line, int size)
{
	if (NULL == line)
	{
		simpleLog("ERROR ogl_drawLine ... NULL pointer for line");
		return -1;
	}


	// should we just return here ??
	if (size <= 0)
	{
		simpleLog("ERROR ogl_drawLine ... size argument non-positive");
	}

	glLineWidth(2.5f);/*thinner curve line (smoothing/blend set in drawCurves)*/
	glColor3f(1.0f, 0.0f, 0.0f); /*set to red*/
	/*begin line drawing*/
	glBegin(GL_LINE_STRIP);


	sprintf(oglBuffer, "ogl_drawLine : size is [%d]", (int)size);
	simpleLog(oglBuffer);

	float temp;
	temp = line[0].x;

	for (int i = 0; i < size; i++)
	{
		if ( (1.0 == GBL_INWORK_CURVE_SCALEFACTOR_MPY) && (0 == GBL_INWORK_CURVE_SCALEFACTOR_ADD))
		{
			// original code ... .do not mutate z compomponent
			glVertex3f(line[i].x, line[i].y, line[i].z);  /*draw ith coords of line*/
		}
		else
		{
			float tempz = GBL_INWORK_CURVE_SCALEFACTOR_MPY * line[i].z + GBL_INWORK_CURVE_SCALEFACTOR_ADD;
			glVertex3f(line[i].x, line[i].y, tempz);  /*draw ith coords of line*/
		}
	}
	glEnd();
	glFlush(); /*push all buffered operations to OpenGL so that they will all be executed, returns immediately and complete in finite time*/
	return 0;
}
