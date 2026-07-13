#ifndef GFX_BACKEND_H
#define GFX_BACKEND_H

typedef struct gfx_surface gfx_surface;

gfx_surface *gfx_create(void *native_drawable);
int gfx_make_current(gfx_surface *s);
void gfx_swap(gfx_surface *s);
void gfx_resize(gfx_surface *s, int w, int h);
void gfx_destroy(gfx_surface *s);

extern gfx_surface *g_surface;

#endif
