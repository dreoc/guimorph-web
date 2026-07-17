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
    void *view;   /* NSView*          -- Tk's embedded content view (retained) */
    void *ctx;    /* NSOpenGLContext* -- legacy-2.1 context (owned via +alloc) */
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

    @autoreleasepool {
        NSWindow *win  = (__bridge NSWindow *)native_drawable;
        NSView   *view = [win contentView];
        if (view == nil) {
            free(s);
            return NULL;
        }

        /*
         * D-05 (viewport half): request a backing-resolution surface so
         * glViewport can be driven in backing pixels (see gfx_resize). Apple
         * documents that layer-backed views (Tk's aqua contentView on modern
         * macOS) manage their own backing and may ignore this, but it is the
         * documented, display-aware request and is harmless where ignored.
         */
        view.wantsBestResolutionOpenGLSurface = YES;

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
         * D-04: attach the context to Tk's embedded contentView (no standalone
         * window).
         *
         * READY FALLBACK (A1 / Pitfall 2) -- DO NOT activate unless Plan 03's
         * live session shows a blank / invalid-drawable viewport on this
         * layer-backed Tk view. In that case: create a dedicated child NSView
         * matching the contentView's bounds/autoresize mask, add it as a subview
         * of the contentView, and setView: on that child instead. That isolates
         * GL drawing from Tk's own layer-backed content drawing while staying
         * within D-04 (still Tk's view hierarchy, no new top-level window).
         */
        [ctx setView:view];

        [view retain];                        /* contentView not owned -> retain */
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
         * D-05: glViewport wants BACKING pixels. convertRectToBacking: is the
         * display-aware path (survives 1x/2x displays and monitor moves) -- do
         * NOT hardcode *2 or read backingScaleFactor (Pitfall 4). Viewport only;
         * pick-coordinate backing conversion is deferred to Phase 5 / PICK-01.
         */
        NSRect px = [view convertRectToBacking:[view bounds]];
        glViewport(0, 0, (GLsizei)px.size.width, (GLsizei)px.size.height);
    }
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
            [(__bridge NSView *)s->view release];            /* balances -retain */
            s->view = NULL;
        }
    }
    free(s);
}

#endif /* __APPLE__ */
