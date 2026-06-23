/*
 * Minimal GLUT shim for the GUImorph tkogl2 extension.
 * ---------------------------------------------------------------------------
 * MinGW-w64 ships <GL/gl.h> and <GL/glu.h> but NOT <GL/glut.h>. The tkogl2
 * engine uses only three GLUT symbols, so rather than vendor the whole of
 * freeglut we declare just what is needed here and link against the
 * already-vendored Windows glut64.dll at link time.
 *
 * The constant values below are the standard Win32 GLUT values and are
 * IDENTICAL for classic GLUT 3.7 (glut32/glut64.dll) and freeglut on Windows,
 * because both encode bitmap-font handles as small integer "pointers" across
 * the DLL boundary. On x86_64 there is a single calling convention, so no
 * __stdcall name decoration is involved.
 *
 * If we ever drop the GLUT dependency entirely (replace glutSolidSphere with
 * gluSphere, glutBitmapCharacter with wglUseFontBitmaps, and delete the no-op
 * glutInitDisplayMode call), this shim and the glut64.dll link can be removed.
 */
#ifndef GUIMORPH_GLUT_SHIM_H
#define GUIMORPH_GLUT_SHIM_H

#include <GL/gl.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Display-mode flags (glutInitDisplayMode) */
#define GLUT_RGBA    0
#define GLUT_RGB     0
#define GLUT_INDEX   1
#define GLUT_SINGLE  0
#define GLUT_DOUBLE  2
#define GLUT_DEPTH   16

/* Bitmap font handle used by glutBitmapCharacter */
#define GLUT_BITMAP_9_BY_15 ((void *)2)

/* The only GLUT entry points referenced by the tkogl2 sources. */
extern void glutInitDisplayMode(unsigned int mode);
extern void glutBitmapCharacter(void *font, int character);
extern void glutSolidSphere(GLdouble radius, GLint slices, GLint stacks);

#ifdef __cplusplus
}
#endif

#endif /* GUIMORPH_GLUT_SHIM_H */
