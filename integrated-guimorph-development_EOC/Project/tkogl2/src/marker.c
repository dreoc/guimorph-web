#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include <string.h>

#include "RunTime_Defines_ZARF_9.h"
#include "def_ZARF_9.h"
#include "marker.h"

const char DOT_VERSION_INFORMATION[] = "File marker Edit revision date is 22 June 2026 (unified dot/anchor)";
const char* dotVersionPtr = DOT_VERSION_INFORMATION;

static marker_set_t g_landmarks = { NULL, 0, 0, NULL, 0, LANDMARK };
static marker_set_t g_anchors  = { NULL, 0, 0, NULL, 0, ANCHOR };

static char buffer[128];

#define DOT_EQUAL(p1, p2) p1.x == p2->x && p1.y == p2->y && p1.z == p2->z
#define IS_IN_RANGE(target, test, dotRadius) (target - dotRadius) <= test && (target + dotRadius) >= test

/* ============================================================================
 * marker_* core (unified dot/anchor logic operating on marker_set_t*)
 * ============================================================================ */

int marker_is_array_null(marker_set_t* s)
{
	if (NULL == s->slices) return 1;
	return 0;
}

int marker_size(marker_set_t* s)
{
	if (s->slices == NULL)
	{
		simpleLog("ERROR : dot_size ... dots array is NULL ... no length");
		return -1;
	}

	dot_t* n = s->slices[s->slice_id];

	if (NULL == n)
	{
		simpleLog("ERROR : dot_size() null first pointer ... How did this happen");
		return -1;
	}

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

int marker_select(marker_set_t* s, point_t* p, float dotRadius)
{
	if (s->slices == NULL)
	{
		simpleLog("ERROR : dot select when the dots array is null");
		return -1;
	}

	if (NULL == p)
	{
		simpleLog("ERROR : dot select NULL argument for point_t* p");
		return -1;
	}

	if (s->slice_id < 0)
	{
		simpleLog("ERROR : dot select  dot_slice_id is negative");
		return -1;
	}
	if (s->slice_id >= s->slice_count)
	{
		simpleLog("ERROR : dot select  dot_slice_id out of bounds");
		return -1;
	}

	if (dotRadius < 0)
	{
		simpleLog("ERROR : dot select  - dotRadius is negative");
		return -1;
	}

	dot_t* n = s->slices[s->slice_id];
	if (NULL == n)
	{
		simpleLog("ERROR : dot select  - the specified array index has no list of dots");
		return -1;
	}

	sprintf(buffer, "DEBUG: Starting to search for a close dot ... slice id is [%d]", s->slice_id);
	simpleLog(buffer);
	sprintf(buffer, "DEBUG: DOT components   x %10.6f   y %10.6f   z %10.6f", p->x, p->y, p->z);
	simpleLog(buffer);

	int id = 0;
	while (n != NULL)
	{
		if (IS_IN_RANGE(n->p.x, p->x, dotRadius)
			&& IS_IN_RANGE(n->p.y, p->y, dotRadius)
			&& IS_IN_RANGE(n->p.z, p->z, dotRadius))
		{
			s->selected = n;
			s->selected_id = id;

			sprintf(buffer, "INFO : found dot (index [%d] )in range with dotRadius of <%f>", id, dotRadius);
			simpleLog(buffer);
			sprintf(buffer, "INFO : points  selected  <%10.6f  %10.f %10.6f", n->p.x, n->p.y, n->p.z);
			simpleLog(buffer);
			sprintf(buffer, "INFO : points  found     <%10.6f  %10.f %10.6f", p->x, p->y, p->z);
			simpleLog(buffer);

			return 0;
		}
		id++;
		n = n->next;
	}
	simpleLog("ERROR : dot_select - dot close enough to location not found ... list searched to end");
	return -1;
}

int marker_add(marker_set_t* s, point_t* p, color_t* c)
{
	if (s->slices == NULL)
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

	node->p.x = p->x;
	node->p.y = p->y;
	node->p.z = p->z;
	node->c.r = c->r;
	node->c.g = c->g;
	node->c.b = c->b;
	node->next = NULL;
	node->type = s->node_type;

	sprintf(buffer, "INFO : addDot ... dot_slice_id is [%d]", s->slice_id);
	simpleLog(buffer);

	if (NULL == s->slices[s->slice_id])
	{
		sprintf(buffer, "INFO : addDot ... adding node  to a null list");
		simpleLog(buffer);
		s->slices[s->slice_id] = node;
	}
	else
	{
		sprintf(buffer, "INFO : addDot ... adding node  to the end of an existing list index [%d]", s->slice_id);
		simpleLog(buffer);
		dot_t* n = s->slices[s->slice_id];
		while (n->next != NULL)
		{
			n = n->next;
		}
		n->next = node;
	}
	sprintf(buffer, "INFO : added dot to the list at index [%d]", s->slice_id);
	simpleLog(buffer);
	int temp = marker_size(s);
	sprintf(buffer, "dot size is [%d]", temp);
	simpleLog(buffer);
	return 0;
}

int marker_move(marker_set_t* s, point_t* p)
{
	if (NULL == s->selected)
	{
		simpleLog("ERROR : dot move with a NULL 'selected' point");
		return -1;
	}
	if (s->selected != NULL)
	{
		s->selected->p.x = p->x;
		s->selected->p.y = p->y;
		s->selected->p.z = p->z;
	}
	return 0;
}

int marker_color(marker_set_t* s, color_t* c)
{
	if (NULL == c)
	{
		simpleLog("ERROR : dot_color NULL pointer for color_t");
		return -1;
	}
	if (s->selected != NULL)
	{
		s->selected->c.r = c->r;
		s->selected->c.g = c->g;
		s->selected->c.b = c->b;
	}
	return 0;
}

int marker_del(marker_set_t* s, point_t* p)
{
	if (s->slices == NULL)
	{
		simpleLog("ERROR : dot_del ... dots array is NULL");
		return -1;
	}

	if (NULL == p)
	{
		simpleLog("ERROR : dot_del ... null pointer to point");
		return -1;
	}

	if (s->slices[s->slice_id] == NULL)
	{
		simpleLog("ERROR : marker_del ... empty list at current slice");
		return -1;
	}

	if (DOT_EQUAL(s->slices[s->slice_id]->p, p))
	{
		dot_t* tempPtr;
		tempPtr = s->slices[s->slice_id];
		s->slices[s->slice_id] = s->slices[s->slice_id]->next;
		FREE_WRAPPER((void*)tempPtr);
		return 0;
	}

	dot_t* n = s->slices[s->slice_id];
	while (n->next != NULL)
	{
		if (DOT_EQUAL(n->next->p, p))
		{
			dot_t* tmp = n->next;
			n->next = tmp->next;
			FREE_WRAPPER((void*)tmp);
			return 0;
		}
		n = n->next;
	}
	sprintf(buffer, "ERROR : dot_del did not find a point to delete");
	simpleLog(buffer);
	return -1;
}

int marker_del_selected(marker_set_t* s)
{
	if (NULL == s->selected) return -1;
	marker_del(s, &s->selected->p);
	s->selected = NULL;
	return marker_size(s);
}

dot_t* marker_get(marker_set_t* s, int id)
{
	sprintf(buffer, "INFO : dot_get for id [%d]", id);
	simpleLog(buffer);

	if (s->slices == NULL)
	{
		simpleLog("ERROR : dot_get ... dots is NULL");
		return NULL;
	}

	if (id == -1)
	{
		sprintf(buffer, "INFO : dot_get ... id is -1, setting id to dot_slice_id [%d]", s->slice_id);
		id = s->slice_id;
		simpleLog(buffer);
		dot_t* temp = NULL;
		temp = s->slices[s->slice_id];
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

	if (id >= s->slice_count)
	{
		sprintf(buffer, "ERROR : dot_get for id (exceeds array bounds) [%d]", id);
		simpleLog(buffer);
		return NULL;
	}

	dot_t* temp;
	temp = (dot_t*)s->slices[id];
	if (NULL == temp)
	{
		sprintf(buffer, "WARNING : dot_get  for id [%d] ... returning NULL ... !", id);
		return NULL;
	}
	return (dot_t*)s->slices[id];
}

dot_t* marker_get_with_pid(marker_set_t* s, int id, int pid)
{
	dot_t* n = marker_get(s, id);
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

dot_t* marker_get_selected(marker_set_t* s)
{
	return s->selected;
}

int marker_selected_id(marker_set_t* s)
{
	return s->selected_id;
}

int marker_get_slice_id(marker_set_t* s)
{
	return s->slice_id;
}

int marker_get_slice_amount(marker_set_t* s)
{
	return s->slice_count;
}

int marker_set_slice_amount(marker_set_t* s, int amount)
{
	if (amount < 0)
	{
		sprintf(buffer, "ERROR : set_dot_slice_amount : allocation amount is negative [%d]", amount);
		simpleLog(buffer);
		return -1;
	}

	if (s->slice_count < 0)
	{
		sprintf(buffer, "ERROR : (dot) slice amount is negative ... how did this happen [%d]", s->slice_count);
		simpleLog(buffer);
		return -1;
	}

	if (s->slices != NULL)
	{
		for (int i = 0; i < s->slice_count; i++)
		{
			dot_t* n = s->slices[i];
			while (n != NULL)
			{
				dot_t* t = n;
				n = n->next;
				FREE_WRAPPER((void*)t);
			}
		}
		FREE_WRAPPER((void*)s->slices);
		s->slices = NULL;
	}

	if (0 == amount)
	{
		s->slice_id = 0;
		s->slice_count = 0;
		return 0;
	}

	const unsigned int howMuch = (unsigned int)(amount * sizeof(dot_t*));
	s->slices = (dot_t**)ALLOCATE_WRAPPER(howMuch);
	if (NULL == s->slices)
	{
		s->slice_id = 0;
		s->slice_count = 0;
		simpleLog("ERROR : failed to allocate memory for dots linked list");
		return -1;
	}

	s->slice_id = 0;
	s->slice_count = amount;
	memset(s->slices, 0, amount * sizeof(dot_t*));

	return 0;
}

int marker_allocate_list(marker_set_t* s, int listLength)
{
	if (listLength < 0)
	{
		simpleLog("ERROR : dotAllocateList ... negative length");
		return -1;
	}
	return marker_set_slice_amount(s, listLength);
}

int marker_release_list(marker_set_t* s)
{
	return marker_set_slice_amount(s, 0);
}

int marker_free(marker_set_t* s)
{
	if (s->slices != NULL)
	{
		for (int i = 0; i < s->slice_count; i++)
		{
			dot_t* n = s->slices[i];
			while (n != NULL)
			{
				dot_t* t = n;
				n = n->next;
				FREE_WRAPPER((void*)t);
			}
		}
		FREE_WRAPPER((void*)s->slices);
		s->slices = NULL;
		s->slice_id = 0;
		s->slice_count = 0;
	}
	return 0;
}

int marker_slice_index(marker_set_t* s, int id)
{
	if (id < 0)
	{
		sprintf(buffer, "ERROR : dot_slice_index ... index negative [%d]", id);
		simpleLog(buffer);
		return -1;
	}
	if (id >= s->slice_count)
	{
		sprintf(buffer, "ERROR : dot_slice_index ... index beyond linked list length [%d]", id);
		simpleLog(buffer);
		return -1;
	}

	s->slice_id = id;

	return 0;
}

int marker_list_length_at_current_slice(marker_set_t* s)
{
	if (s->slices == NULL)
	{
		simpleLog("ERROR : dot_getListLengthAtCurrentSlice ... dots array is NULL ... no length");
		return -1;
	}

	dot_t* n = s->slices[s->slice_id];
	if (NULL == n)
	{
		simpleLog("INFO : dot_getListLengthAtCurrentSlice  null first pointer ... so length is 0");
		return 0;
	}

	int size = 0;
	while (n != NULL)
	{
		size++;
		n = n->next;
	}
	sprintf(buffer, "INFO : walked the list and found the length to be [%d]", size);
	return size;
}

dot_t* marker_get_at_index_current_slice(marker_set_t* s, int index)
{
	if (s->slices == NULL)
	{
		simpleLog("ERROR : get_dot_at_index_current_slice ... dots array is NULL ... no length");
		return NULL;
	}

	dot_t* n = s->slices[s->slice_id];

	if (NULL == n)
	{
		simpleLog("ERROR : dot_size() null first pointer ... How did this happen ??");
		return NULL;
	}

	int countOfDots = 0;
	while (n != NULL)
	{
		countOfDots++;
		if (countOfDots == index)
		{
			simpleLog("INFO : found the requested dot ...");
			return n;
		}
		else
		{
			n = n->next;
		}
	}
	sprintf(buffer, "ERROR : did not find the requested dot ... indexing error [%d]", index);
	simpleLog(buffer);
	return NULL;
}

int marker_size_for_slice_index(marker_set_t* s, int index)
{
	if (s->slices == NULL)
	{
		simpleLog("ERROR : get_dot_size_for_slice_index ... dots array is NULL ... no length");
		return -1;
	}
	if (index >= s->slice_count)
	{
		simpleLog("ERROR : get_dot_size_for_slice_index ... bad index");
		return -1;
	}
	if (index < 0)
	{
		simpleLog("ERROR : get_dot_size_for_slice_index ... bad index");
		return -1;
	}

	dot_t* n = s->slices[index];
	if (NULL == n)
	{
		return 0;
	}

	int size = 0;
	while (n != NULL)
	{
		size++;
		n = n->next;
	}
	sprintf(buffer, "INFO : walked the (dot) list [%d] and found the length to be [%d]", index, size);
	simpleLog(buffer);
	return size;
}

/* ============================================================================
 * dot_* wrappers (forward to g_landmarks)
 * ============================================================================ */

int isDotArrayNull(void) { return marker_is_array_null(&g_landmarks); }
int isDotArrayNotNull(void) { return !marker_is_array_null(&g_landmarks); }
int isAnchorArrayNull(void) { return marker_is_array_null(&g_anchors); }
int isAnchorArrayNotNull(void) { return !marker_is_array_null(&g_anchors); }

int get_dot_slice_id(void) { return marker_get_slice_id(&g_landmarks); }
int get_anchor_slice_id(void) { return marker_get_slice_id(&g_anchors); }
int get_dot_slice_index(void) { return marker_get_slice_id(&g_landmarks); }
int get_anchor_slice_index(void) { return marker_get_slice_id(&g_anchors); }
int get_dot_slice_amount(void) { return marker_get_slice_amount(&g_landmarks); }
int get_anchor_slice_amount(void) { return marker_get_slice_amount(&g_anchors); }
int get_dot_selected_id(void) { return marker_selected_id(&g_landmarks); }
int get_anchor_selected_id(void) { return marker_selected_id(&g_anchors); }

int dot_size(void) { return marker_size(&g_landmarks); }
int dot_select(point_t* p, float dotRadius) { return marker_select(&g_landmarks, p, dotRadius); }
int dotGetSelectedIndex(void) { return dot_selected_id(); }
int dot_selected_id(void) { return marker_selected_id(&g_landmarks); }
int dot_add(point_t* p, color_t* c) { return marker_add(&g_landmarks, p, c); }
int dot_move(point_t* p) { return marker_move(&g_landmarks, p); }
int dot_color(color_t* c) { return marker_color(&g_landmarks, c); }
int dot_del(point_t* p) { return marker_del(&g_landmarks, p); }
int dot_del_selected(void) { return marker_del_selected(&g_landmarks); }
dot_t* dot_get(int id) { return marker_get(&g_landmarks, id); }
dot_t* dot_get_dot(int id, int pid) { return marker_get_with_pid(&g_landmarks, id, pid); }
dot_t* dotGetPointerToTheSelectedDot(void) { return marker_get_selected(&g_landmarks); }
dot_t* dot_get_selected(void) { return marker_get_selected(&g_landmarks); }
int dotGetArraySize(void) { return marker_get_slice_amount(&g_landmarks); }
int dotAllocateList(int listLength) { return marker_allocate_list(&g_landmarks, listLength); }
int dotReleaseList(void) { return marker_release_list(&g_landmarks); }
int set_dot_slice_amount(int amount) { return marker_set_slice_amount(&g_landmarks, amount); }
int dots_free(void) { return marker_free(&g_landmarks); }
int dotSetArrayIndex(int whichIndex) { return marker_slice_index(&g_landmarks, whichIndex); }
int dot_slice_index(int id) { return marker_slice_index(&g_landmarks, id); }
int dot_getListLengthAtCurrentSlice(void) { return marker_list_length_at_current_slice(&g_landmarks); }
dot_t* get_dot_at_index_current_slice(int index) { return marker_get_at_index_current_slice(&g_landmarks, index); }
int get_dot_size_for_slice_index(int index) { return marker_size_for_slice_index(&g_landmarks, index); }

/* ============================================================================
 * anchor_* wrappers (forward to g_anchors — D-03 fix)
 * ============================================================================ */

int anchorAllocateList(int listLength) { return marker_allocate_list(&g_anchors, listLength); }
int anchorReleaseList(void) { return marker_release_list(&g_anchors); }
int anchor_size(void) { return marker_size(&g_anchors); }
int anchors_selected_id(void) { return marker_selected_id(&g_anchors); }
int anchorGetSelectedIndex(void) { return anchors_selected_id(); }
int anchor_del(point_t* p) { return marker_del(&g_anchors, p); }
int anchor_del_selected(void) { return marker_del_selected(&g_anchors); }
dot_t* anchor_get_anchor(int id, int pid) { return marker_get_with_pid(&g_anchors, id, pid); }
int set_anchors_slice_amount(int amount) { return marker_set_slice_amount(&g_anchors, amount); }
int anchors_free(void) { return marker_free(&g_anchors); }
int anchor_slice_index(int id) { return marker_slice_index(&g_anchors, id); }
int anchor_select(point_t* p, float dotRadius) { return marker_select(&g_anchors, p, dotRadius); }
int anchor_move(point_t* p) { return marker_move(&g_anchors, p); }
int anchor_color(color_t* c) { return marker_color(&g_anchors, c); }
dot_t* anchor_get(int id) { return marker_get(&g_anchors, id); }
int anchorGetArraySize(void) { return marker_get_slice_amount(&g_anchors); }
int anchor_add(point_t* p, color_t* c) { return marker_add(&g_anchors, p, c); }
dot_t* anchorGetPointerToTheSelectedDot(void) { return marker_get_selected(&g_anchors); }
dot_t* anchor_get_selected(void) { return marker_get_selected(&g_anchors); }
int anchorSetArrayIndex(int whichIndex) { return marker_slice_index(&g_anchors, whichIndex); }
int anchor_getListLengthAtCurrentSlice(void) { return marker_list_length_at_current_slice(&g_anchors); }
int get_anchor_size_for_slice_index(int index) { return marker_size_for_slice_index(&g_anchors, index); }
