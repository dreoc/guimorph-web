#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include "RunTime_Defines_ZARF_9.h"
#include "def_ZARF_9.h"

const char DOT_VERSION_INFORMATION[] = "File dot Edit revision date is 15 August 2020 4:22 PM";
const char* dotVersionPtr = DOT_VERSION_INFORMATION;


static dot_t** dots = NULL; /*array storing dots, dot_slice_index indicates which dots belong to which specimen*/
static int dot_slice_id = 0;
static int dot_slice_amount = 0;
static dot_t* selected = NULL;
static int selected_id = 0;

static dot_t** anchors = NULL;
static int anchor_slice_id = 0;
static int anchor_slice_amount = 0;
static dot_t* anchor_selected = NULL;
static int anchor_selected_id = 0;


static char buffer[128];

#define DOT_EQUAL(p1, p2) p1.x == p2->x && p1.y == p2->y && p1.z == p2->z

#define IS_IN_RANGE(target, test, dotRadius) (target - dotRadius) <= test && (target + dotRadius) >= test


int isDotArrayNull()
{
	if (NULL == dots) return 1;
	return 0;
}

int isDotArrayNotNull()
{
	if (NULL == dots) return 0;
	return 1;
}

int isAnchorArrayNull()
{
	if (NULL == anchors) return 1;
	return 0;
}

int isAnchorArrayNotNull()
{
	if (NULL == anchors) return 0;
	return 1;
}

// returns the current slice index, that is the index forresponding to the current specimen
int get_dot_slice_id() { return dot_slice_id; }
int get_anchor_slice_id() { return anchor_slice_id; }

int get_dot_slice_index() { return dot_slice_id; }
int get_anchor_slice_index() { return anchor_slice_id; }



// returns the array dimension 
int get_dot_slice_amount() { return dot_slice_amount; }
int get_anchor_slice_amount() { return anchor_slice_amount; }


int get_dot_selected_id() { return selected_id; }
int get_anchor_selected_id() { return anchor_selected_id; }





int dot_size()
{

	/*no dots, size is 0*/
	if (dots == NULL)
	{
		simpleLog("ERROR : dot_size ... dots array is NULL ... no length");
		return -1;
	}


	dot_t* n = dots[dot_slice_id];

	if (NULL == n)
	{
		simpleLog("ERROR : dot_size() null first pointer ... How did this happen");
		return -1;
	}

	/*increment size and iterate through all dots starting at dot_slice_id*/
	int size = 0;
	while (n != NULL)
	{
		size++;
		n = n->next;
	}
	sprintf(buffer, "INFO : dot_size is [%d]", size);
	simpleLog(buffer);
	return size;
}


// This function walks a linked list of dots searching for a dot whose location 
// is 'close' to the specified location.
// 'Close' is defined by the dotRadius the specific linked list of dots
// (from the array of dot pointers, is specified by the variable dot_slice_id 
//
int dot_select(point_t* p, float dotRadius)
{
	if (dots == NULL)
	{
		simpleLog("ERROR : dot select when the dots array is null");
		return -1;
	}

	if (NULL == p)
	{
		simpleLog("ERROR : dot select NULL argument for point_t* p");
		return -1;
	}


	if (dot_slice_id < 0)
	{
		simpleLog("ERROR : dot select  dot_slice_id is negative");
		return -1;
	}
	if (dot_slice_id >= dot_slice_amount)
	{
		simpleLog("ERROR : dot select  dot_slice_id out of bounds");
		return -1;
	}

	if (dotRadius < 0)
	{
		simpleLog("ERROR : dot select  - dotRadius is negative");
		return -1;
	}

	dot_t* n = dots[dot_slice_id];
	if (NULL == n)
	{
		simpleLog("ERROR : dot select  - the specified array index has no list of dots");
		return -1;
	}



	sprintf(buffer, "DEBUG: Starting to search for a close dot ... slice id is [%d]", dot_slice_id);
	simpleLog(buffer);
	sprintf(buffer, "DEBUG: DOT components   x %10.6f   y %10.6f   z %10.6f", p->x, p->y, p->z);
	simpleLog(buffer);



	// iterate through all dots in the list at array location  dot_slice_id
	int id = 0;
	while (n != NULL)
	{

		if (IS_IN_RANGE(n->p.x, p->x, dotRadius))
		{
			sprintf(buffer, "DEBUG : InRange (id : [%d] )  x  <%10.6f  %10.6f> {%10.6f}", id, n->p.x, p->x, dotRadius);
			simpleLog(buffer);
		}
		else
		{
			sprintf(buffer, "FAIL : InRange (id : [%d] )  x  <%10.6f  %10.6f> {%10.6f}", id, n->p.x, p->x, dotRadius);
			simpleLog(buffer);
		}
		if (IS_IN_RANGE(n->p.y, p->y, dotRadius))
		{
			sprintf(buffer, "DEBUG : InRange (id : [%d] )  y  <%10.6f  %10.6f> {%10.6f}", id, n->p.y, p->y, dotRadius);
			simpleLog(buffer);
		}
		else
		{
			sprintf(buffer, "FAIL : InRange (id : [%d] )  y  <%10.6f  %10.6f> {%10.6f}", id, n->p.y, p->y, dotRadius);
			simpleLog(buffer);
		}


		if (IS_IN_RANGE(n->p.z, p->z, dotRadius))
		{
			sprintf(buffer, "DEBUG : InRange (id : [%d] )  z  <%10.6f  %10.6f> {%10.6f}", id, n->p.z, p->z, dotRadius);
			simpleLog(buffer);
		}
		else
		{
			sprintf(buffer, "FAIL : InRange (id : [%d] )  z  <%10.6f  %10.6f> {%10.6f}", id, n->p.z, p->z, dotRadius);
			simpleLog(buffer);
		}


	
		/*if ith dot is in range of chosen point, select that dot and store its id*/
		if (IS_IN_RANGE(n->p.x, p->x, dotRadius)
			&& IS_IN_RANGE(n->p.y, p->y, dotRadius)
			&& IS_IN_RANGE(n->p.z, p->z, dotRadius))
		{
			selected = n;
			selected_id = id;

			sprintf(buffer, "INFO : found dot (index [%d] )in range with dotRadius of <%f>", id, dotRadius);
			simpleLog(buffer);
			sprintf(buffer, "INFO : points  selected  <%10.6f  %10.f %10.6f", n->p.x, n->p.y, n->p.z);
			simpleLog(buffer);
			sprintf(buffer, "INFO : points  found     <%10.6f  %10.f %10.6f", p->x, p->y, p->z);
			simpleLog(buffer);

			return 0;  // dot is selected  .. so we quit here 
		}
		id++;
		// else try next dot in the lst
		n = n->next;
	}
	simpleLog("ERROR : dot_select - dot close enough to location not found ... list searched to end");
	return -1;
}

int dotGetSelectedIndex()
{
	return dot_selected_id();
}

int dot_selected_id()
{
	return selected_id;
}

int dot_add(point_t* p, color_t* c)
{

	if (dots == NULL)
	{
		simpleLog("ERROR : dot_add ... dots array is NULL");
		return -1;
	}

	if (NULL == p)
	{
		simpleLog("ERROR : dot_add ... NULL pointer for point");
		return -1;
	}

	if (NULL == c)
	{
		simpleLog("ERROR : dot_add NULL pointer for color");
		return -1;
	}

	dot_t* node = (dot_t*)ALLOCATE_WRAPPER((unsigned int)sizeof(dot_t));

	if (NULL == node)
	{
		simpleLog("ERROR : dot_add failed to allocate memory for a dot");
		return -1;
	}


	/*construct coords and color of node dot*/
	node->p.x = p->x;
	node->p.y = p->y;
	node->p.z = p->z;
	node->c.r = c->r;
	node->c.g = c->g;
	node->c.b = c->b;
	node->next = NULL;
	node->type = LANDMARK;

	sprintf(buffer, "INFO : addDot ... dot_slice_id is [%d]", dot_slice_id);
	simpleLog(buffer);

	/*if ith dot doesn't exist, assign to it to node*/
	if (NULL == dots[dot_slice_id])
	{
		sprintf(buffer, "INFO : addDot ... adding node  to a null list");
		simpleLog(buffer);
		dots[dot_slice_id] = node;
	}
	/*iterate to end of dots, assign new entry to node*/
	else
	{
		sprintf(buffer, "INFO : addDot ... adding node  to the end of an existing list index [%d]", dot_slice_id);
		simpleLog(buffer);
		dot_t* n = dots[dot_slice_id];
		while (n->next != NULL)
		{
			n = n->next;
		}
		n->next = node;
	}
	sprintf(buffer, "INFO : added dot to the list at index [%d]", dot_slice_id);
	simpleLog(buffer);
	int temp = -1;
	temp = dot_size();
	sprintf(buffer, "dot size is [%d]", temp);
	simpleLog(buffer);
	return 0;
}

//assigns dot coords to arg p
int dot_move(point_t* p)
{
	if (NULL == selected)
	{
		simpleLog("ERROR : dot move with a NULL 'selected' point");
		return -1;
	}
	if (selected != NULL)
	{
		selected->p.x = p->x;
		selected->p.y = p->y;
		selected->p.z = p->z;
	}
	return 0;  ////// dot_size();
}

// assigns the selected dot the color values from the argument
// the selected dot is specified by the variable 'selected'
// the selected dot is any individual dot instance 
int dot_color(color_t* c)
{
	if (NULL == c)
	{
		simpleLog("ERROR : dot_color NULL pointer for color_t");
		return -1;
	}
	if (selected != NULL)
	{
		selected->c.r = c->r;
		selected->c.g = c->g;
		selected->c.b = c->b;
	}
	return 0; //  dot_size();
}


// deletes a dot whose location matches the point p
// the specific linked list is specified by the index dot_slice_id
// THIS IN GENERAL IS A BAD IMPLEMENTATION ... we are checking equality of floating point variables
//
int dot_del(point_t* p)
{

	//if no dots, return eror 
	if (dots == NULL)
	{
		simpleLog("ERROR : dot_del ... dots array is NULL");
		return -1;
	}

	if (NULL == p)
	{
		simpleLog("ERROR : dot_del ... null pointer to point");
		return -1;
	}


	// if ith dot matches arg p coords, move to next dot and return
	if (DOT_EQUAL(dots[dot_slice_id]->p, p))
	{
		dot_t* tempPtr;
		tempPtr = dots[dot_slice_id];  // this is the first dot in the linked list at the dot_slice_id index

		dots[dot_slice_id] = dots[dot_slice_id]->next;   // point to second dot in the list which could be NULL
		FREE_WRAPPER((void*)tempPtr);  // delete the dot which was the first dot
		return 0;  // success

	}

	dot_t* n = dots[dot_slice_id];
	while (n->next != NULL)
	{
		if (DOT_EQUAL(n->next->p, p))
		{
			dot_t* tmp = n->next;
			n->next = tmp->next;
			FREE_WRAPPER((void*)tmp);
			return 0;  // success
			break;
		}
		n = n->next;
	}
	sprintf(buffer, "ERROR : dot_del did not find a point to delete");
	simpleLog(buffer);
	return -1; // dot_size();
}

int dot_del_selected()
{
	dot_del(&selected->p);
	selected = NULL;
	return dot_size();
}

// This function returns the i'th dot pointer from the dots array,
// the dots array is an array of pointers to dots
// NULL is returned if there is an indexing error
dot_t* dot_get(int id)
{

	sprintf(buffer, "INFO : dot_get for id [%d]", id);
	simpleLog(buffer);


	if (dots == NULL)
	{
		simpleLog("ERROR : dot_get ... dots is NULL");
		return NULL;
	}

	if (id == -1)
	{
		sprintf(buffer, "INFO : dot_get ... id is -1, setting id to dot_slice_id [%d]", dot_slice_id);
		id = dot_slice_id;
		simpleLog(buffer);
		dot_t* temp = NULL;
		temp = dots[dot_slice_id];
		if (NULL == temp)
		{
			simpleLog("INFO : dot_get() returning NULL as result from dots[dot_slice_id]");
		}
		if (NULL == temp)
		{
			simpleLog("INFO : dot_get() returning NON NULL as result from dots[dot_slice_id] - OK-");
		}
		return (dot_t*)temp;
	}


	if (id < 0)
	{
		sprintf(buffer, "ERROR : dot_get for id (negative) [%d]", id);
		simpleLog(buffer);
		return NULL;
	}

	if (id >= dot_slice_amount)
	{
		sprintf(buffer, "ERROR : dot_get for id (exceeds array bounds) [%d]", id);
		simpleLog(buffer);
		return NULL;
	}

	dot_t* temp;
	temp = (dot_t*)dots[id];
	if (NULL == temp)
	{

		// how does this happen ? Anyway I think it is an abnormal condition
		sprintf(buffer, "WARNING : dot_get  for id [%d] ... returning NULL ... !", id);
		return NULL;
	}
	return (dot_t*)dots[id];
}



////////////////////////  DON"T USE ????????????
/*grabs dot a different way, not sure why. maybe to protect from going out of array bounds?*/
dot_t* dot_get_dot(int id, int pid)
{
	dot_t* n = dot_get(id);
	if (NULL == n)
	{
		simpleLog("WARNING : dot_get_dot ... dot pointer from dot_get is NULL");
	}

	while (pid > 1 && n != NULL)
	{
		pid--;
		n = n->next;
	}
	return n;
}

dot_t* dotGetPointerToTheSelectedDot()
{
	return dot_get_selected();
}

dot_t* anchorGetPointerToTheSelectedDot()
{
	return anchor_get_selected();
}

dot_t* dot_get_selected()
{
	return selected;
}

dot_t* anchor_get_selected()
{
	return anchor_selected;
}

int dotGetArraySize()
{
	return dot_slice_amount;
}

int dotAllocateList(int listLength)
{
	if (listLength < 0)
	{
		simpleLog("ERROR : dotAllocateList ... negative length");
		return -1;
	}

	int rv = -1;
	rv = set_dot_slice_amount(listLength);
	return rv;
}

int dotReleaseList()
{
	int rv = -1;
	rv = set_dot_slice_amount(0);
	return rv;
}

//if present, deletes dots and sets to 0, allocates memory for dots
int set_dot_slice_amount(int amount)
{

	if (amount < 0)
	{
		sprintf(buffer, "ERROR : set_dot_slice_amount : allocation amount is negative [%d]", amount);
		simpleLog(buffer);
		return -1;

	}

	if (dot_slice_amount < 0)
	{
		sprintf(buffer, "ERROR : (dot) slice amount is negative ... how did this happen [%d]", dot_slice_amount);
		simpleLog(buffer);
		return -1;
	}


	if (dots != NULL)
	{
		for (int i = 0; i < dot_slice_amount; i++)
		{
			dot_t* n = dots[i];
			while (n != NULL)
			{
				dot_t* t = n;
				n = n->next;
				FREE_WRAPPER((void*)t);
			}
		}
		FREE_WRAPPER((void*)dots);
		dots = NULL;
	}


	if (0 == amount)  // with previous memory released ... if zero dots to be allocated .. work is done 
	{
		dot_slice_id = 0;
		dot_slice_amount = 0;
		return 0;
	}

	const unsigned int howMuch = (unsigned int)(amount * sizeof(dot_t*));
	dots = (dot_t**)ALLOCATE_WRAPPER(howMuch);
	if (NULL == dots)
	{
		dot_slice_id = 0;
		dot_slice_amount = 0;
		simpleLog("ERROR : failed to allocate memory for dots linked list");
		return -1;
	}

	dot_slice_id = 0;
	dot_slice_amount = amount;
	memset(dots, 0, amount * sizeof(dot_t*));

	// dave you can assign static pointers here 
	return 0;
}

int dots_free()
{
	if (dots != NULL)
	{
		for (int i = 0; i < dot_slice_amount; i++)
		{
			dot_t* n = dots[i];
			while (n != NULL)
			{
				dot_t* t = n;
				n = n->next;
				FREE_WRAPPER((void*)t);
			}
		}
		FREE_WRAPPER((void*)dots);
		dots = NULL;
		dot_slice_id = 0;
		dot_slice_amount = 0;
	}
	return 0;
}

int dotSetArrayIndex(int whichIndex)
{
	int rv = -1;
	rv = dot_slice_index(whichIndex);
	return rv;
}

int anchorSetArrayIndex(int whichIndex)
{
	int rv = -1;
	rv = anchor_slice_index(whichIndex);
	return rv;
}

// sets dot_slice_id and curve_slice_id to the chosen id .... NOT THE CURVE_SLIDE_id
int dot_slice_index(int id)
{

	if (id < 0)
	{
		sprintf(buffer, "ERROR : dot_slice_index ... index negative [%d]", id);
		simpleLog(buffer);
		return -1;
	}
	if (id >= dot_slice_amount)
	{
		sprintf(buffer, "ERROR : dot_slice_index ... index beyond linked list length [%d]", id);
		simpleLog(buffer);
		return -1;
	}


	dot_slice_id = id;

	if (0)   /// in work 
	{

		simpleLog("ERROR >>> ERROR >>> ERROR In DOTS (anchors_slice_index)  SHOULD NOT BE HERE");
		int rv = -1;
		rv = set_curve_slice_index(id);
		if (rv != 0)
		{
			simpleLog("ERROR : fail return from curve_slice_index()");
			return -1;
		}
	}

	return 0;
}



/********************************************************************************************************************************************************************************************/
/*all anchor functions are directly analagous to above dot functions*/

int anchorAllocateList(int listLength)
{
	if (listLength < 0)
	{
		simpleLog("ERROR : anchor AllocateList ... negative length");
		return -1;
	}
	int rv = -1;
	rv = set_anchors_slice_amount(listLength);
	return rv;
}

int anchorReleaseList()
{
	int rv = -1;
	rv = set_anchors_slice_amount(0);
	return rv;
}

// gets the length of the linked list as indexed by the anchor_slice_id 
int anchor_size()
{

	// no anchors then size if zero ... but it really does not even exist
	if (NULL == anchors)
	{
		simpleLog("ERROR : anchor_size() ... anchors array is NULL");
		return -1;
	}


	dot_t* n = anchors[anchor_slice_id];

	if (NULL == n)
	{
		simpleLog("ERROR : anchor_size() null first pointer ... How did this happen ?");
		return -1;
	}

	// increment size and iterate through all anchors in the linked list as indexed by anchor_slice_id
	int size = 0;
	while (n != NULL)
	{
		size++;
		n = n->next;
	}
	sprintf(buffer, "INFO : anchor_size is [%d] for list (slice) indexed by [%d]", size, anchor_slice_id);
	simpleLog(buffer);
	return size;
}


/* int anchor_select(point_t* p, float dotRadius)
{
	if (anchors == NULL)
		return -1;

	int id = 0;
	dot_t* n = anchors[anchor_slice_id];

	while (n != NULL)
	{
		id++;
		if (IS_IN_RANGE(n->p.x, p->x, dotRadius)
			&& IS_IN_RANGE(n->p.y, p->y, dotRadius)
			&& IS_IN_RANGE(n->p.z, p->z, dotRadius)) {
			anchor_selected = n;
			anchor_selected_id = id;
			return 0;
		}
		n = n->next;
	}
	return -1;
}
*/

int anchors_selected_id()  // I do not like the name here
{
	return anchor_selected_id;
}

int anchorGetSelectedIndex()
{
	return anchors_selected_id();
}


// deletes a dot whose location matches the point p
// the specific linked list is specified by the index anchor_slice_id
// THIS IN GENERAL IS A BAD IMPLEMENTATION ... we are checking equality of floating point variables
//
int anchor_del(point_t* p)
{

	//if no dots, return eror 
	if (anchors == NULL)
	{
		simpleLog("ERROR : anchor_del ... anchors array is NULL");
		return -1;
	}

	if (NULL == p)
	{
		simpleLog("ERROR : anchor_del ... null pointer to point");
		return -1;
	}

	dot_t* n = anchors[anchor_slice_id];
	if (NULL == n)
	{
		sprintf(buffer, "ERROR : anchors at index [%d] is NULL. Not list to walk", anchor_slice_id);
		simpleLog(buffer);
		return -1;
	}



	// else the list is not null, we have an actuat dot ...
	//
	// if first dot matches arg p coords, move to next dot and return first dot to memory pool
	if (DOT_EQUAL(anchors[anchor_slice_id]->p, p))
	{
		dot_t* tempPtr;
		tempPtr = anchors[anchor_slice_id];  // this is the first dot in the linked list at the anchor_slice_id index
		anchors[anchor_slice_id] = anchors[anchor_slice_id]->next;   // point to second dot in the list which could be NULL
		FREE_WRAPPER((void*)tempPtr);    // delete the dot which was the first dot
		return 0;  // success

	}

	n = anchors[anchor_slice_id];

	if (NULL == n)   // this should be redundant
	{
		sprintf(buffer, "ERROR : anchors at index [%d] is NULL  ist this redundant?", anchor_slice_id);
		simpleLog(buffer);
		return -1;
	}




	while (n->next != NULL)
	{
		if (DOT_EQUAL(n->next->p, p))
		{
			dot_t* tmp = n->next;
			n->next = tmp->next;
			FREE_WRAPPER((void*)tmp);
			return 0;  // success
			break;
		}
		n = n->next;
	}
	sprintf(buffer, "ERROR : anchor_del did not find a point to delete");
	simpleLog(buffer);
	return -1;   // anchor_size();
}

int anchor_del_selected()
{
	anchor_del(&anchor_selected->p);
	anchor_selected = NULL;
	return anchor_size();
}

dot_t* anchor_get_anchor(int id, int pid)
{
	dot_t* n = anchor_get(id);
	while (pid > 1 && n != NULL)
	{
		pid--;
		n = n->next;
	}
	return n;
}

//if present, deletes dots and sets to 0, allocates memory for anchors
int set_anchors_slice_amount(int amount)
{

	if (amount < 0)
	{
		sprintf(buffer, "ERROR : anchors : allocation amount is negative [%d]", amount);
		simpleLog(buffer);
		return -1;

	}

	if (anchor_slice_amount < 0)
	{
		sprintf(buffer, "ERROR : slice amount is negative ... how did this happen [%d]", anchor_slice_amount);
		simpleLog(buffer);
		return -1;
	}


	if (anchors != NULL)
	{
		for (int i = 0; i < anchor_slice_amount; i++)
		{
			dot_t* n = anchors[i];
			while (n != NULL)
			{
				dot_t* t = n;
				n = n->next;
				FREE_WRAPPER((void*)t);
			}
		}
		FREE_WRAPPER((void*)anchors);
		anchors = NULL;
	}


	if (0 == amount)  // with previous memory released ... if zero anchors to be allocated .. work is done 
	{
		anchor_slice_id = 0;
		anchor_slice_amount = 0;
		///curve_slice_amount(0);   //WHY !! ?? 
		return 0;
	}

	const unsigned int howMuch = (unsigned int)(amount * sizeof(dot_t*));
	anchors = (dot_t**)ALLOCATE_WRAPPER(howMuch);
	if (NULL == anchors)
	{
		anchor_slice_id = 0;
		anchor_slice_amount = 0;
		////////curve_slice_amount(0);   //WHY !! ?? 
		simpleLog("ERROR : failed to allocate memory for anchors linked list");
		return -1;
	}

	anchor_slice_id = 0;
	anchor_slice_amount = amount;
	///////curve_slice_amount(amount);   //WHY !! ?? 
	memset(anchors, 0, amount * sizeof(dot_t*));

	// DAVE ASSIGN GBL STATIC POINTERS HERE ...  future work
	return 0;
}

int  anchors_free()
{
	if (anchors != NULL)
	{
		for (int i = 0; i < anchor_slice_amount; i++)
		{
			dot_t* n = anchors[i];
			while (n != NULL)
			{
				dot_t* t = n;
				n = n->next;
				FREE_WRAPPER((void*)t);
			}
		}
		FREE_WRAPPER((void*)anchors);
		anchors = NULL;
		anchor_slice_id = 0;
		anchor_slice_amount = 0;
	}
	return 0;

}

// sets anchor_slice_id and curve_slice_id to the chosen id .... NOT THE CURVE_SLIDE_id
int anchor_slice_index(int id)
{

	if (id < 0)
	{
		sprintf(buffer, "ERROR : anchor_slice_index ... index negative [%d]", id);
		simpleLog(buffer);
		return -1;
	}
	if (id >= anchor_slice_amount)
	{
		sprintf(buffer, "ERROR : anchor_slice_index ... index beyond linked list length [%d]", id);
		simpleLog(buffer);
		return -1;
	}


	anchor_slice_id = id;

	sprintf(buffer, "INFO : anchor_slice_index has been set to  [%d]", anchor_slice_id);
	simpleLog(buffer);



	if (0)   /// in work     see original code ... this was present 
	{
		simpleLog("ERROR >>> ERROR >>> ERROR In ANCHORS (anchors_slice_index)  SHOULD NOT BE HERE");
		return -1;
		int rv = -1;
		rv = set_curve_slice_index(id);
		if (rv != 0)
		{
			simpleLog("ERROR : fail return from curve_slice_index() ");
			return -1;
		}
	}


	return 0;
}


// This function walks a linked list of dots searching for a dot whose location 
// is 'close' to the  specified location.
// 'Close' is defined by the dotRadius.
// The specific linked list of dots (from the array of dot pointers),
// is specified by the variable anchor_slice_id 
//
int anchor_select(point_t* p, float dotRadius)
{
	if (NULL == anchors)
	{
		simpleLog("ERROR : anchor select when the anchors array is null");
		return -1;
	}



	if (anchor_slice_id < 0)
	{
		simpleLog("ERROR : anchor select  anchor_slice_id is negative");
		return -1;
	}

	if (anchor_slice_id >= anchor_slice_amount)
	{
		simpleLog("ERROR : anchor select  anchor_slice_id out of bounds");
		return -1;
	}

	dot_t* n = anchors[anchor_slice_id];
	if (NULL == n)
	{
		sprintf(buffer, "ERROR : anchor select  - the specified array index [%d] has no list of dots", anchor_slice_id);
		simpleLog(buffer);
		return -1;
	}

	// iterate through all dots in the list at array location  dot_slice_id

	int id = 0;
	while (n != NULL)
	{
		id++;
		/*if ith dot is in range of chosen point, select that dot and store its id*/
		if (IS_IN_RANGE(n->p.x, p->x, dotRadius)
			&& IS_IN_RANGE(n->p.y, p->y, dotRadius)
			&& IS_IN_RANGE(n->p.z, p->z, dotRadius)) {
			selected = n;
			selected_id = id;
			return 0;  // dot is selected  .. so we quit here 
		}
		n = n->next;
	}
	simpleLog("ERROR : anchor_select - dot close enouth to location not found .. list searched to end");
	return -1;
}

//assigns dot coords to arg p
int anchor_move(point_t* p)
{
	if (NULL == selected)
	{
		simpleLog("ERROR : anchor move with NULL 'selected' dot");
		return -1;
	}
	if (selected != NULL)
	{
		selected->p.x = p->x;
		selected->p.y = p->y;
		selected->p.z = p->z;
	}
	return 0;  ////// anchor_size();
}

// assigns the selected dot the color values from the argument
// the selected dot is specified by the variable 'selected'
// the selected dot is any individual dot instance 
int anchor_color(color_t* c)
{
	if (NULL == c)
	{
		simpleLog("ERROR : anchor_color NULL pointer for color_t");
		return -1;
	}
	if (selected != NULL)
	{
		selected->c.r = c->r;
		selected->c.g = c->g;
		selected->c.b = c->b;
	}
	return 0; //  anchor_size();
}

// This function returns the i'th anchor pointer from the anchors array,
// the anchors array is an array of pointers to dots
// NULL is returned if there is an indexing error

dot_t* anchor_get(int id)
{

	sprintf(buffer, "INFO : anchor_get for id [%d]", id);
	simpleLog(buffer);


	if (anchors == NULL)
	{
		simpleLog("anchor_get ... anchors is NULL");
		return NULL;
	}

	if (-1 == id)
	{
		sprintf(buffer, "anchor_get ... id is -1, setting id to anchor_slice_id [%d]", anchor_slice_id);
		id = anchor_slice_id;
		simpleLog(buffer);
		return (dot_t*)anchors[anchor_slice_id];
	}


	if (id < 0)
	{
		sprintf(buffer, "ERROR : anchor_get for id (negative) [%d]", id);
		simpleLog(buffer);
		return NULL;
	}

	if (id >= anchor_slice_amount)  // ok because we are using zero based indexing in C 
	{
		sprintf(buffer, "ERROR : anchor_get for id (exceeds array bounds) [%d]", id);
		simpleLog(buffer);
		return NULL;
	}

	dot_t* temp;
	temp = (dot_t*)anchors[id];
	if (NULL == temp)
	{
		// how does this happen ? Anyway I think it is an abnormal condition
		sprintf(buffer, "WARNING : anchor_get for id [%d] ... returning NULL ... !", id);
		simpleLog(buffer);
		return NULL;
	}
	else
	{
		sprintf(buffer, "INFO : anchor_get for id [%d] ... returning a dot* (not NULL) -OK-", id);
		simpleLog(buffer);
	}
	return (dot_t*)anchors[id];
}

int anchorGetArraySize()
{
	return anchor_slice_amount;
}

int anchor_add(point_t* p, color_t* c)
{

	if (anchors == NULL)
	{
		simpleLog("ERROR : anchor_add   anchors array is NULL");
		return -1;
	}

	if (NULL == p)
	{
		simpleLog("ERROR : anchor_add NULL pointer for point");
		return -1;
	}

	if (NULL == c)
	{
		simpleLog("ERROR : anchor_add NULL pointer for color");
		return -1;
	}

	dot_t* node = (dot_t*)ALLOCATE_WRAPPER((unsigned int)sizeof(dot_t));
	if (NULL == node)
	{
		simpleLog("ERROR : anchor_add failed to allocate memory for a dot");
		return -1;
	}


	/*construct coords and color of node dot*/
	node->p.x = p->x;
	node->p.y = p->y;
	node->p.z = p->z;
	node->c.r = c->r;
	node->c.g = c->g;
	node->c.b = c->b;
	node->next = NULL;
	node->type = ANCHOR;

	//  if first dot doesn't exist, assign to it to node
	if (anchors[anchor_slice_id] == NULL)
	{
		anchors[anchor_slice_id] = node;
	}
	else  //iterate to end of dots, assign new entry to node
	{
		dot_t* n = anchors[anchor_slice_id];
		while (n->next != NULL)
		{
			n = n->next;
		}
		n->next = node;
	}
	sprintf(buffer, "INFO : added anchor (dot) to the list at slice index [%d]", anchor_slice_id);
	simpleLog(buffer);

	int temp = -1;
	temp = anchor_size();
	sprintf(buffer, "INFO : new anchor size is [%d]", temp);
	simpleLog(buffer);
	return 0;
}

int dot_getListLengthAtCurrentSlice()
{
	if (dots == NULL)
	{
		simpleLog("ERROR : dot_getListLengthAtCurrentSlice ... dots array is NULL ... no length");
		return -1;
	}

	// get pointer to the first dot in the linked list as indexed in the 
	// array by the dot_slice_id
	dot_t* n = dots[dot_slice_id];
	if (NULL == n)
	{
		simpleLog("INFO : dot_getListLengthAtCurrentSlice  null first pointer ... so length is 0");
		return 0;
	}

	// else we have a non zero length list. Walk it and count

	int size = 0;
	while (n != NULL)
	{
		size++;
		n = n->next;   // keep going
	}
	sprintf(buffer, "INFO : walked the list and found the length to be [%d]", size);
	//simpleLog(buffer);
	return size;
}

dot_t* get_dot_at_index_current_slice(int index)
{

	if (dots == NULL)
	{
		simpleLog("ERROR : get_dot_at_index_current_slice ... dots array is NULL ... no length");
		return NULL;
	}

	// get pointer to the first dot in the linked list as indexed in the 
	// array by the dot_slice_id
	dot_t* n = dots[dot_slice_id];

	if (NULL == n)
	{
		simpleLog("ERROR : dot_size() null first pointer ... How did this happen ??");
		return NULL;
	}

	//if we asked for the 0th dot in the list (the head of the list) then 
	// since it is not null, then it is the one we want
	//if (0 == index)
	//{ 
	//	simpleLog("INFO : returning the 0th dot ... found it !");
	//	return n;
	//}
	// else the dot we asked for is somewhere in the list ... go a find it
	//increment size and iterate through all dots starting at dot_slice_id

	int size = 0;
	int countOfDots = 0;
	while (n != NULL)
	{
		size++;
		countOfDots++;
		if (countOfDots == index)
		{
			// then since we are some where in the list, not at the end of the list
			// and we have a non null dot ... well then this must be it
			simpleLog("INFO : found the requested dot ...");
			return n;
		}
		else
		{
			n = n->next;   // keep going
		}
	}
	sprintf(buffer, "ERROR : did not find the requested dot ... indexing error [%d]", index);
	simpleLog(buffer);
	return NULL;
}

int anchor_getListLengthAtCurrentSlice()
{
	if (anchors == NULL)
	{
		simpleLog("ERROR : anchor_getListLengthAtCurrentSlice ... dots array is NULL ... no length");
		return -1;
	}

	// get pointer to the first dot in the linked list as indexed in the 
	// array by the dot_slice_id
	dot_t* n = anchors[anchor_slice_id];
	if (NULL == n)
	{
		simpleLog("INFO : anchor_getListLengthAtCurrentSlice  null first pointer ... so length is 0");
		return 0;
	}

	// else we have a non zero length list. Walk it and count

	int size = 0;
	while (n != NULL)
	{
		size++;
		n = n->next;   // keep going
	}
	sprintf(buffer, "INFO : walked the list and found the length to be [%d]", size);
	//simpleLog(buffer);
	return size;
}

int get_dot_size_for_slice_index(int index)
{

	if (dots == NULL)
	{
		simpleLog("ERROR : get_dot_size_for_slice_index ... dots array is NULL ... no length");
		return -1;
	}
	if (index >= dot_slice_amount)
	{
		simpleLog("ERROR : get_dot_size_for_slice_index ... bad index");
		return -1;
	}
	if (index < 0)
	{
		simpleLog("ERROR : get_dot_size_for_slice_index ... bad index");
		return -1;
	}



	// get pointer to the first dot in the linked list as indexed in the 
	// array by the dot_slice_id
	dot_t* n = dots[index];
	if (NULL == n)
	{
		//simpleLog("INFO : get_dot_size_for_slice_index  null first pointer ... so length is 0");
		return 0;
	}

	// else we have a non zero length list. Walk it and count
	int size = 0;
	while (n != NULL)
	{
		size++;
		n = n->next;   // keep going
	}
	sprintf(buffer, "INFO : walked the (dot) list [%d] and found the length to be [%d]", index, size);
	simpleLog(buffer);
	return size;

}

int get_anchor_size_for_slice_index(int index)
{
	if (anchors == NULL)
	{
		simpleLog("ERROR : get_anchor_size_for_slice_index ... anchors array is NULL ... no length");
		return -1;
	}
	if (index >= anchor_slice_amount)
	{
		simpleLog("ERROR : get_anchor_size_for_slice_index ... bad index");
		return -1;
	}
	if (index < 0)
	{
		simpleLog("ERROR : get_anchor_size_for_slice_index ... bad index");
		return -1;
	}

	// get pointer to the first dot in the linked list as indexed in the 
	// array by the dot_slice_id
	dot_t* n = anchors[index];
	if (NULL == n)
	{
		//simpleLog("INFO : get_anchors_size_for_slice_index  null first pointer ... so length is 0");
		return 0;
	}

	// else we have a non zero length list. Walk it and count
	int size = 0;
	while (n != NULL)
	{
		size++;
		n = n->next;   // keep going
	}
	sprintf(buffer, "INFO : walked the (anchor) list [%d] and found the length to be [%d]", index, size);
	simpleLog(buffer);
	return size;
}