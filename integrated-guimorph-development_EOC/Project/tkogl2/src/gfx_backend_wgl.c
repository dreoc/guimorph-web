#ifdef _WIN32

#pragma warning( disable : 4305)
#pragma warning( disable : 4244)

#include <string.h>
#include <stdlib.h>

#include "def_ZARF_9.h"
#include "gfx_backend.h"

struct gfx_surface {
	HDC dc;
	HGLRC rc;
};

gfx_surface *gfx_create(void *native_drawable)
{
	HWND hwnd = (HWND)native_drawable;
	if (hwnd == NULL)
	{
		return NULL;
	}

	gfx_surface *s = (gfx_surface *)ALLOCATE_WRAPPER(sizeof(gfx_surface));
	if (s == NULL)
	{
		return NULL;
	}

	memset(s, 0, sizeof(gfx_surface));
	s->dc = GetDC(hwnd);
	if (s->dc == NULL)
	{
		FREE_WRAPPER(s);
		return NULL;
	}

	PIXELFORMATDESCRIPTOR pfd;
	memset(&pfd, 0, sizeof(pfd));
	pfd.nVersion = 1;
	pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
	pfd.iPixelType = PFD_TYPE_RGBA;
	pfd.cColorBits = 24;
	pfd.cDepthBits = 16;
	pfd.iLayerType = PFD_MAIN_PLANE;

	GLuint pixelFormat = ChoosePixelFormat(s->dc, &pfd);
	SetPixelFormat(s->dc, pixelFormat, &pfd);

	s->rc = wglCreateContext(s->dc);
	if (s->rc == NULL)
	{
		FREE_WRAPPER(s);
		return NULL;
	}

	return s;
}

int gfx_make_current(gfx_surface *s)
{
	if (s == NULL)
	{
		return -1;
	}

	return wglMakeCurrent(s->dc, s->rc) ? 0 : -1;
}

void gfx_swap(gfx_surface *s)
{
	if (s == NULL)
	{
		return;
	}

	SwapBuffers(s->dc);
}

void gfx_resize(gfx_surface *s, int w, int h)
{
	/* WGL requires no resize update; NSGL will use this seam in Phase 4. */
	(void)s;
	(void)w;
	(void)h;
}

void gfx_destroy(gfx_surface *s)
{
	/* Behavior-preserving stub: legacy code did not tear down context/DC. */
	(void)s;
}

#endif
