#if defined(__APPLE__)

/*
 * Silence the fixed-function GL deprecation firehose BEFORE any GL header is
 * pulled in (Pitfall 8). This engine is legacy 2.1 by design (D-01), so the
 * deprecation warnings are expected noise; silencing them targeted-ly keeps a
 * genuine error from being buried, without a blanket -Wno-deprecated flag.
 */
#define GL_SILENCE_DEPRECATION

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>   /* GLU (gluSphere/gluUnProject) parity with the draw path */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "gfx_backend.h"

/*
 * NSOpenGLContext / NSOpenGLPixelFormat / -setView: /
 * wantsBestResolutionOpenGLSurface are all deprecated since macOS 10.14 but
 * remain the functional legacy-2.1 GL path on Apple Silicon (GL runs over a
 * Metal wrapper). GL_SILENCE_DEPRECATION above quiets the GL calls; this pragma
 * quiets the AppKit NSOpenGL surface we deliberately use (State of the Art),
 * keeping a genuine future error visible instead of buried in expected noise.
 */
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/*
 * macOS (Cocoa / NSOpenGL) backend for the gfx seam.
 *
 * Phase 4 ("first light", RND-03/RND-04): this fills the Phase 3 stub with a
 * live legacy-2.1 NSOpenGLContext attached to Tk's embedded NSView. It creates
 * the context (gfx_create), makes it current with a GL_VERSION legacy guard
 * (gfx_make_current), presents via [ctx flushBuffer] (gfx_swap), and drives the
 * Retina viewport in backing pixels (gfx_resize). All Cocoa/GL work runs on the
 * main thread inside Tk's Tcl_DoOneEvent cycle wrapped in @autoreleasepool
 * (D-03 / Pitfall 5) -- no [NSApp run], no render thread.
 *
 * native_drawable is the NSWindow* produced by the RND-02 accessor
 * (Tk_MacOSXGetNSWindowForDrawable on Tk_WindowId). Its contentView is the
 * surface the context attaches to (D-04).
 *
 * Lifetime discipline: this .m compiles under MRC (the CMake APPLE branch does
 * NOT enable -fobjc-arc). Object pointers are held as void* (with __bridge
 * casts, which are plain casts under MRC). Ownership is explicit and balanced:
 * the context is owned via +alloc and stored as-is; the contentView is not
 * owned so it is -retain'd on store; gfx_destroy -release's both.
 */

struct gfx_surface {
    void *view;   /* NSView*          -- GL child view embedded in Tk's contentView (owned) */
    void *ctx;    /* NSOpenGLContext* -- legacy-2.1 context (owned via +alloc) */
};

/*
 * A1 / Pitfall 2 embed rectangle. Tk shares ONE NSView per toplevel, so the GL
 * context cannot attach to the whole contentView without painting over every
 * sibling widget. tcl_window.c computes the digitizing widget's sub-rectangle
 * (Tk point-space, top-left origin, toplevel-relative) and stashes it here via
 * gfx_set_embed_rect BEFORE gfx_create runs. If it was never set, gfx_create
 * falls back to the full contentView bounds.
 */
static int    g_embed_set = 0;
static NSRect g_embed_rect;  /* Tk point-space, origin top-left */

void gfx_set_embed_rect(int x, int y, int w, int h)
{
    g_embed_rect = NSMakeRect((CGFloat)x, (CGFloat)y, (CGFloat)w, (CGFloat)h);
    g_embed_set = 1;
}

gfx_surface *gfx_create(void *native_drawable)
{
    if (native_drawable == NULL) {
        return NULL;
    }

    gfx_surface *s = (gfx_surface *)calloc(1, sizeof(gfx_surface));
    if (s == NULL) {
        return NULL;
    }

    @autoreleasepool {
        NSWindow *win     = (__bridge NSWindow *)native_drawable;
        NSView   *content = [win contentView];
        if (content == nil) {
            free(s);
            return NULL;
        }

        /*
         * A1 / Pitfall 2: build a dedicated GL child NSView at the Tk widget's
         * rect and add it as a subview of the shared contentView, instead of
         * attaching GL to the contentView itself (which would cover the notebook,
         * nav buttons, and status bar -- the "blank window, no widgets" symptom).
         * Still within D-04: it lives inside Tk's own view hierarchy, no new
         * top-level window.
         *
         * Tk hands us a top-left-origin rect. AppKit views are bottom-left-origin
         * unless the superview is flipped, so consult -isFlipped and convert only
         * when needed -- this keeps the canvas vertically correct on either kind
         * of Tk contentView.
         */
        NSRect childFrame = [content bounds];   /* fallback: full contentView */
        if (g_embed_set &&
            g_embed_rect.size.width >= 1.0 && g_embed_rect.size.height >= 1.0) {
            CGFloat cx = g_embed_rect.origin.x;
            CGFloat cw = g_embed_rect.size.width;
            CGFloat ch = g_embed_rect.size.height;
            CGFloat cy;
            if ([content isFlipped]) {
                cy = g_embed_rect.origin.y;                         /* top-left origin */
            } else {
                cy = [content bounds].size.height
                     - (g_embed_rect.origin.y + ch);                /* flip to bottom-left */
            }
            childFrame = NSMakeRect(cx, cy, cw, ch);
        }

        NSView *view = [[NSView alloc] initWithFrame:childFrame];
        if (view == nil) {
            free(s);
            return NULL;
        }
        /* Track the parent as the window resizes (approximate; exact per-widget
         * relayout is Tk's job and is refreshed via gfx_resize on <Configure>). */
        [view setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [content addSubview:view];

        /*
         * D-05 (viewport half), first-light reality: Tk's contentView is
         * layer-backed on modern macOS, and layer-backing is inherited by every
         * subview -- so this GL child is layer-backed too and IGNORES
         * wantsBestResolutionOpenGLSurface. The GL surface therefore stays at
         * POINT size. Requesting a best-resolution (backing) surface here while
         * the layer refuses it desynchronizes the surface from a backing-pixel
         * glViewport and renders the scene into the bottom-left, clipped. Keep
         * the surface at point resolution and drive glViewport in points too
         * (see gfx_resize) so the mesh fills the canvas. Crisp full-Retina (a
         * non-layer-backed child NSView or a CAOpenGLLayer) is a deferred
         * follow-up -- "first light = fills the viewport", not pixel-perfect.
         */
        view.wantsBestResolutionOpenGLSurface = NO;

        /*
         * D-01: legacy 2.1 profile -- the engine is fixed-function immediate
         * mode (glBegin, glVertex, glOrtho, gluSphere); a core profile renders
         * black (Pitfall 1). Boolean attrs (DoubleBuffer/Accelerated) take no
         * value; sized attrs (the ...Size ones) take one; array is 0-terminated.
         */
        NSOpenGLPixelFormatAttribute attrs[] = {
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersionLegacy,
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFAColorSize, 24,
            NSOpenGLPFAAlphaSize,  8,
            NSOpenGLPFADepthSize, 24,
            0
        };

        NSOpenGLPixelFormat *pf =
            [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
        if (pf == nil) {
            /*
             * Pitfall 3 / A2: nil means this arm64 GL-on-Metal renderer rejected
             * the combo. The seam contract returns NULL on failure; the low-cost
             * empirical fallback (if ever needed) is to drop NSOpenGLPFAAlphaSize
             * or reduce depth to 16 -- kept minimal here so first light gets a
             * valid format.
             */
            free(s);
            return NULL;
        }

        NSOpenGLContext *ctx =
            [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
        [pf release];   /* initWithFormat: retains the format; drop our +alloc ref */
        if (ctx == nil) {
            free(s);
            return NULL;
        }

        /*
         * D-04: attach the context to the GL child view embedded above (A1 /
         * Pitfall 2 fallback, now the active path). This isolates GL drawing from
         * Tk's own content drawing while staying within Tk's view hierarchy.
         */
        [ctx setView:view];

        /* `view` is owned via +alloc (addSubview also retains it, dropped on
         * removeFromSuperview in gfx_destroy). Store our +alloc ref as-is. */
        s->view = (__bridge void *)view;
        s->ctx  = (__bridge void *)ctx;       /* owned via +alloc; store as-is */
    }

    return s;
}

int gfx_make_current(gfx_surface *s)
{
    if (s == NULL || s->ctx == NULL) {
        return -1;
    }
    [(__bridge NSOpenGLContext *)s->ctx makeCurrentContext];

    /*
     * RND-03/RND-04 black-mesh guard (Validation Architecture Wave-0 gap):
     * log GL_VERSION on EVERY make-current so the live Plan 03 session shows the
     * profile actually granted. A legacy context reports a "2.1 ..." string and
     * MUST NOT contain "Core Profile"; a core string here is Pitfall 1 (the mesh
     * will be black). fprintf(stderr) keeps this free of any core-logger dep.
     */
    const char *ver = (const char *)glGetString(GL_VERSION);
    fprintf(stderr, "[tkogl2/nsgl] GL_VERSION: %s\n",
            ver ? ver : "(null) -- no current context!");
    return 0;
}

void gfx_swap(gfx_surface *s)
{
    if (s == NULL || s->ctx == NULL) {
        return;
    }
    /* D-03 / Pitfall 6: present the double-buffered back buffer. The core's
     * trailing glFlush() is harmless; only flushBuffer actually presents. */
    [(__bridge NSOpenGLContext *)s->ctx flushBuffer];
}

void gfx_resize(gfx_surface *s, int w, int h)
{
    if (s == NULL || s->ctx == NULL) {
        return;
    }
    /* Viewport is derived from the view's backing rect, not the point-space
     * (w,h) the core passes -- those stay unused here (D-05). */
    (void)w;
    (void)h;
    @autoreleasepool {
        NSOpenGLContext *ctx = (__bridge NSOpenGLContext *)s->ctx;
        NSView *view = (__bridge NSView *)s->view;
        [ctx update];   /* NSOpenGL must be told the view geometry changed */

        /*
         * Phase 5 / PICK-01: use backing-pixel viewport dimensions so render-space
         * and pick-space share one coordinate authority on Retina displays.
         */
        NSRect backing = [view convertRectToBacking:[view bounds]];
        glViewport(0, 0, (GLsizei)backing.size.width, (GLsizei)backing.size.height);
    }
}

int gfx_point_to_backing(gfx_surface *s, int x_pt, int y_pt, int *x_px, int *y_px)
{
    if (s == NULL || s->view == NULL || x_px == NULL || y_px == NULL) {
        return -1;
    }

    @autoreleasepool {
        NSView *view = (__bridge NSView *)s->view;
        NSRect pt = NSMakeRect((CGFloat)x_pt, (CGFloat)y_pt, 0.0, 0.0);
        NSRect px = [view convertRectToBacking:pt];
        *x_px = (int)lround((double)px.origin.x);
        *y_px = (int)lround((double)px.origin.y);
    }

    return 0;
}

int gfx_get_viewport_size(gfx_surface *s, int *w_px, int *h_px)
{
    if (s == NULL || s->view == NULL || w_px == NULL || h_px == NULL) {
        return -1;
    }

    @autoreleasepool {
        NSView *view = (__bridge NSView *)s->view;
        NSRect backing = [view convertRectToBacking:[view bounds]];
        *w_px = (int)lround((double)backing.size.width);
        *h_px = (int)lround((double)backing.size.height);
    }

    return 0;
}

void gfx_destroy(gfx_surface *s)
{
    if (s == NULL) {
        return;
    }
    @autoreleasepool {
        /* Drop the current context before releasing it (Pitfall 5 hygiene). */
        [NSOpenGLContext clearCurrentContext];
        if (s->ctx) {
            [(__bridge NSOpenGLContext *)s->ctx release];   /* balances +alloc */
            s->ctx = NULL;
        }
        if (s->view) {
            NSView *v = (__bridge NSView *)s->view;
            [v removeFromSuperview];    /* drop the superview's addSubview retain */
            [v release];                /* balances +alloc */
            s->view = NULL;
        }
    }
    free(s);
}

#endif /* __APPLE__ */
