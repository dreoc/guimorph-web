#if defined(__APPLE__)

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

#include <stdlib.h>
#include "gfx_backend.h"

/*
 * macOS (Cocoa / NSOpenGL) backend for the gfx seam.
 *
 * Phase 3 (BLD-01) status: STUB. This exists so the tri-platform CMake build
 * produces a real Mach-O tkogl2.dylib linked against -framework
 * OpenGL/AppKit/Foundation and satisfying the 5-function seam. It intentionally
 * does NOT render yet.
 *
 * Phase 4 ("first light", RND-03/RND-04) fills in the live path: build an
 * NSOpenGLContext with a legacy 2.1 profile on Tk's embedded NSView, make it
 * current, draw, and present via [ctx flushBuffer].
 *
 * native_drawable is the NSWindow* produced by the RND-02 accessor
 * (Tk_MacOSXGetNSWindowForDrawable on Tk_WindowId). We take its contentView as
 * the surface to attach to in Phase 4.
 *
 * Object pointers are held as void* (with __bridge casts) so this compiles under
 * both MRC and ARC; ARC forbids strong Objective-C pointers inside C structs.
 */

struct gfx_surface {
    void *view;   /* NSView*          -- Tk's embedded content view */
    void *ctx;    /* NSOpenGLContext* -- created in Phase 4 */
};

gfx_surface *gfx_create(void *native_drawable)
{
    if (native_drawable == NULL) {
        return NULL;
    }

    gfx_surface *s = (gfx_surface *)calloc(1, sizeof(gfx_surface));
    if (s == NULL) {
        return NULL;
    }

    NSWindow *win = (__bridge NSWindow *)native_drawable;
    s->view = (__bridge void *)[win contentView];
    s->ctx  = NULL;   /* Phase 4: NSOpenGLContext (legacy 2.1) attached to view */

    return s;
}

int gfx_make_current(gfx_surface *s)
{
    if (s == NULL || s->ctx == NULL) {
        return -1;    /* Phase 4: makeCurrentContext once ctx exists */
    }
    [(__bridge NSOpenGLContext *)s->ctx makeCurrentContext];
    return 0;
}

void gfx_swap(gfx_surface *s)
{
    if (s == NULL || s->ctx == NULL) {
        return;       /* Phase 4: present the back buffer */
    }
    [(__bridge NSOpenGLContext *)s->ctx flushBuffer];
}

void gfx_resize(gfx_surface *s, int w, int h)
{
    /* Phase 4: [ctx update] and set the GL viewport at backingScaleFactor
     * (Retina, PICK-01). No-op in the stub. */
    (void)s;
    (void)w;
    (void)h;
}

void gfx_destroy(gfx_surface *s)
{
    if (s == NULL) {
        return;
    }
    /* Phase 4: [NSOpenGLContext clearCurrentContext] and release ctx. */
    free(s);
}

#endif /* __APPLE__ */
