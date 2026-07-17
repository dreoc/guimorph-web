#ifndef GFX_BACKEND_H
#define GFX_BACKEND_H

typedef struct gfx_surface gfx_surface;

gfx_surface *gfx_create(void *native_drawable);
int gfx_make_current(gfx_surface *s);
void gfx_swap(gfx_surface *s);
void gfx_resize(gfx_surface *s, int w, int h);
void gfx_destroy(gfx_surface *s);
int gfx_point_to_backing(gfx_surface *s, int x_pt, int y_pt, int *x_px, int *y_px);
int gfx_get_viewport_size(gfx_surface *s, int *w_px, int *h_px);

#if defined(__APPLE__)
/*
 * macOS-only (A1 / Pitfall 2): Tk has exactly ONE NSView per toplevel (the shared
 * contentView), so attaching the GL context to it paints over every other Tk
 * widget. The NSGL backend instead embeds a child NSView at the digitizing
 * widget's sub-rectangle. This hands the backend that rectangle, expressed in Tk
 * point-space with a top-left origin, relative to the toplevel's content area.
 * Must be called before gfx_create (setWindowId). If never called, gfx_create
 * falls back to the full contentView bounds.
 */
void gfx_set_embed_rect(int x, int y, int w, int h);
#endif

extern gfx_surface *g_surface;

#endif
