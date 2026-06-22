#pragma once
#ifndef MARKER_H
#define MARKER_H

#include "def_ZARF_9.h"

/*
 * Unified marker contract (Phase 8 — header only; bodies in marker.c, plan 08-02).
 *
 * Behavioral contract encoded here (source of truth: dot_ZARF_9.c until 08-02 absorbs it):
 *
 * D-03 — Each marker_set_t uses its OWN selection state (fixes anchor bugs):
 *   BUG-1/2/3: anchor_select/move/color wrote dot globals selected/selected_id
 *              (dot_ZARF_9.c:1021-1022, 1034-1043, 1058-1062) — core uses s->selected/s->selected_id.
 *   BUG-4: anchor_del_selected deref'd never-set anchor_selected (:826-831);
 *          marker_del_selected NULL-guards s->selected before deref (dot_del_selected :395-400
 *          lacks the guard but works today because dot_select sets selected).
 *   BUG-5/6: marker_select keeps NULL==p and dotRadius<0 guards (dot_select :121, :139)
 *            and 0-based id++-after-match convention (dot_select :162-218; anchor_select :1013-1025
 *            used id++ before match — unified to dot convention).
 *
 * D-04 — Landmark observable behavior unchanged when wrappers forward to g_landmarks.
 *
 * D-05 — In-loop per-coordinate IS_IN_RANGE debug logging in dot_select (:166-197) is
 *        trimmed on merge; match/selection logging retained.
 *
 * Parallel statics map (dot_ZARF_9.c:11-21) → marker_set_t:
 *   dots/anchors → slices, *_slice_id → slice_id, *_slice_amount → slice_count,
 *   selected/anchor_selected → selected, *_selected_id → selected_id.
 * marker_add stamps node->type from s->node_type (LANDMARK vs ANCHOR; dot_add :274, anchor_add :1166).
 */

typedef struct marker_set_t {
	dot_t** slices;
	int slice_id;
	int slice_count;
	dot_t* selected;
	int selected_id;
	show_mode_t node_type;
} marker_set_t;

int marker_add(marker_set_t* s, point_t* p, color_t* c);
int marker_select(marker_set_t* s, point_t* p, float dotRadius);
int marker_move(marker_set_t* s, point_t* p);
int marker_color(marker_set_t* s, color_t* c);
int marker_del(marker_set_t* s, point_t* p);
int marker_del_selected(marker_set_t* s);
int marker_size(marker_set_t* s);
dot_t* marker_get(marker_set_t* s, int id);
dot_t* marker_get_with_pid(marker_set_t* s, int id, int pid);
dot_t* marker_get_selected(marker_set_t* s);
int marker_selected_id(marker_set_t* s);
int marker_slice_index(marker_set_t* s, int id);
int marker_get_slice_id(marker_set_t* s);
int marker_get_slice_amount(marker_set_t* s);
int marker_set_slice_amount(marker_set_t* s, int amount);
int marker_allocate_list(marker_set_t* s, int listLength);
int marker_release_list(marker_set_t* s);
int marker_free(marker_set_t* s);
int marker_list_length_at_current_slice(marker_set_t* s);
dot_t* marker_get_at_index_current_slice(marker_set_t* s, int index);
int marker_size_for_slice_index(marker_set_t* s, int index);
int marker_is_array_null(marker_set_t* s);

#endif
