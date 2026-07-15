cmake_minimum_required(VERSION 3.16)

# ============================================================================
# tkogl2 -- Tcl extension DLL for the GUImorph 3D digitizing engine.
#
# This is a WINDOWS DLL (the engine embeds OpenGL into a Tk widget's HWND via
# WGL, so it cannot build as a native Linux .so).
#
# PRIMARY (recommended) build path -- native Windows / MSVC. This matches the
# toolchain that produced the original working DLL. Install "Build Tools for
# Visual Studio" (the free C++ workload) and CMake, then from this directory:
#
#   cmake -B build-msvc -G "Visual Studio 17 2022" -A x64
#   cmake --build build-msvc --config Release
#
# Produces: build-msvc/tkogl2.dll
#
# ALTERNATIVE (advanced) build path -- MinGW-w64 cross-compile from WSL/Linux.
# Note: as of 2026-06 the MinGW build links but renders incorrectly (black mesh)
# and is NOT recommended for distribution; use the MSVC path above.
#
#   sudo apt install mingw-w64 mingw-w64-tools cmake
#   cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake
#   cmake --build build -j
#
# Either path loads in Windows-R via `tcl("load", ..., "Tkogl2")`.
# ============================================================================

project(tkogl2 C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Statically link the MSVC C runtime so the DLL is self-contained (no VC++
# redistributable required on end-user machines). No-op for the MinGW path.
cmake_policy(SET CMP0091 NEW)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set(SRC        ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(VENDOR_LIB ${CMAKE_CURRENT_SOURCE_DIR}/lib)

# --- Sources (note: includes StatisticsFunction_ZARF_9.c, which the old
#     .vcxproj omitted even though tcl_if references statisticsVersionPtr) ---
add_library(tkogl2 SHARED
    ${SRC}/tcl_init.c
    ${SRC}/tcl_dispatch.c
    ${SRC}/tcl_window.c
    ${SRC}/gfx_backend_wgl.c
    ${SRC}/tcl_state.c
    ${SRC}/tcl_log.c
    ${SRC}/ogl_ZARF9.c
    ${SRC}/ogl_model_ZARF_9.c
    ${SRC}/ogl_model_ply_ZARF_9.c
    ${SRC}/curve_ZARF_9.c
    ${SRC}/marker.c
    ${SRC}/StatisticsFunction_ZARF_9.c
)

# Tcl stub linkage differs by toolchain:
#   MSVC  -> link the vendored COFF stub lib (lib/tclstub86_64.lib) directly.
#   MinGW -> GNU ld cannot read that COFF archive, so compile the self-contained
#            bootstrap TU instead (see tcl_stub_bootstrap.c for the rationale).
if(NOT MSVC)
    target_sources(tkogl2 PRIVATE ${SRC}/tcl_stub_bootstrap.c)
endif()

# Tcl/R expect the file to be exactly "tkogl2.dll" (no "lib" prefix).
set_target_properties(tkogl2 PROPERTIES
    PREFIX ""
    OUTPUT_NAME "tkogl2"
    SUFFIX ".dll"
)

target_compile_definitions(tkogl2 PRIVATE
    USE_TCL_STUBS
    USE_TK_STUBS   # RND-02 (Phase 2): route Tk_* and Tk platform accessors through the stub tables
    _CRT_SECURE_NO_WARNINGS
    # CODE_FOR_LIBRARY is hard-#defined in RunTime_Defines_ZARF_9.h.
)

# MSVC understands the in-source `#pragma warning(...)` lines natively; gcc does
# not, so silence the resulting noise only under non-MSVC toolchains.
if(NOT MSVC)
    target_compile_options(tkogl2 PRIVATE -Wno-unknown-pragmas)
endif()

# RND-02 (Phase 2): introducing <tk.h> pulls Tk's <X11/Xlib.h> shim. The
# vendored include/tk_include/ ships tk.h/tkDecls.h/tkPlatDecls.h but NOT the
# X11/ shim subdir, so the Tk X11 headers must be reachable on the include path.
# Point this at a Tcl/Tk install's include dir that contains X11/ (e.g. the
# Tcl/Tk that ships with R, or a standalone Tcl/Tk 8.6), OR drop the Tk 8.6
# xlib/X11/*.h headers into include/tk_include/X11/ to keep the build
# self-contained. Default assumes the self-contained vendored location.
set(TKOGL2_TK_XLIB_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include/tk_include"
    CACHE PATH "Include dir containing Tk's X11/ shim headers (X11/Xlib.h, X11/X.h, ...)")

target_include_directories(tkogl2 PRIVATE
    ${SRC}
    ${CMAKE_CURRENT_SOURCE_DIR}/include/tcl_include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/tk_include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/tk_include/ttk
    ${TKOGL2_TK_XLIB_INCLUDE}
    # GL/glut.h shim (MinGW has GL/gl.h + GL/glu.h but not GL/glut.h):
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/glut_shim
)

# ----------------------------------------------------------------------------
# External libraries
#
# opengl32 / glu32 / gdi32 / user32 ship with both MSVC (Windows SDK) and
# MinGW-w64 as system import libs.
#
# GLUT and Tcl stubs are toolchain-specific:
#   MSVC  -> link the vendored COFF import libs (glut64.lib, tclstub86_64.lib).
#   MinGW -> link glut64.dll directly (ld synthesizes the import table); GNU ld
#            cannot read the COFF tclstub86_64.lib, so the stub bootstrap TU
#            (added above) provides Tcl_InitStubs instead.
# ----------------------------------------------------------------------------
if(MSVC)
    target_link_libraries(tkogl2 PRIVATE
        ${VENDOR_LIB}/glut64.lib
        ${VENDOR_LIB}/tclstub86_64.lib
        ${VENDOR_LIB}/tkstub86.lib   # RND-02 (Phase 2): Tk stub table for Tk_NameToWindow / Tk_GetHWND / Tk_InitStubs
        opengl32
        glu32
        gdi32
        user32
    )
else()
    set(TKOGL2_GLUT_LIB "${VENDOR_LIB}/glut64.dll"
        CACHE FILEPATH "GLUT library (or DLL) to link against")

    # NOTE (RND-02): GNU ld cannot read the COFF tkstub86.lib (same limitation
    # as tclstub86_64.lib, handled via tcl_stub_bootstrap.c). Tk-stub linkage
    # for the non-MSVC path is deferred to Phase 3's tri-platform build; the
    # MinGW path is already flagged non-distributable (black-mesh render), so
    # the new Tk_* symbols are expected to be unresolved here until then.
    target_link_libraries(tkogl2 PRIVATE
        ${TKOGL2_GLUT_LIB}
        opengl32
        glu32
        gdi32
        user32
    )

    # Avoid a runtime dependency on libgcc_s_seh-1.dll (MinGW only).
    target_link_options(tkogl2 PRIVATE -static-libgcc)
endif()

# Drop the build output next to the project for convenience.
set_target_properties(tkogl2 PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
