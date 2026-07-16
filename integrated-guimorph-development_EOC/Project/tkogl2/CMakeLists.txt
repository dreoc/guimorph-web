cmake_minimum_required(VERSION 3.16)

# ============================================================================
# tkogl2 -- Tcl extension for the GUImorph 3D digitizing engine.
#
# The engine embeds OpenGL into a Tk widget's native drawable via the gfx seam
# (gfx_backend.h). It is tri-platform:
#
#   WINDOWS (primary, verified) -- WGL backend, builds tkogl2.dll.
#       cmake -B build-msvc -G "Visual Studio 17 2022" -A x64
#       cmake --build build-msvc --config Release
#     MinGW-w64 cross-compile also targets Windows (WIN32); it links but renders
#     a black mesh and is NOT for distribution.
#
#   macOS (Phase 3+, BLD-01) -- Cocoa/NSOpenGL backend, builds tkogl2.dylib
#       (Mach-O -dynamiclib) linking -framework OpenGL/AppKit/Foundation.
#     The Phase 3 NSGL backend is a compiling STUB (no render yet); Phase 4 adds
#     first light. Point the build at a macOS Tcl/Tk (Homebrew tcl-tk) via
#     -DTKOGL2_MACOS_TCLTK_PREFIX=<prefix> if it is not the default.
#       cmake -B build-mac -DTKOGL2_MACOS_TCLTK_PREFIX=$(brew --prefix tcl-tk)
#       cmake --build build-mac
#
# Either loads in R via tcl("load", <full path>, "Tkogl2"); .onLoad computes the
# platform library extension from [info sharedlibextension] (BLD-02).
# ============================================================================

project(tkogl2 C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Statically link the MSVC C runtime so the DLL is self-contained (no VC++
# redistributable required on end-user machines). No-op off MSVC.
cmake_policy(SET CMP0091 NEW)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set(SRC        ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(VENDOR_LIB ${CMAKE_CURRENT_SOURCE_DIR}/lib)

# --- Common sources (platform GL backend added per-platform below). Includes
#     StatisticsFunction_ZARF_9.c, which the old .vcxproj omitted even though
#     tcl_if references statisticsVersionPtr. ---
add_library(tkogl2 SHARED
    ${SRC}/tcl_init.c
    ${SRC}/tcl_dispatch.c
    ${SRC}/tcl_window.c
    ${SRC}/tcl_state.c
    ${SRC}/tcl_log.c
    ${SRC}/ogl_ZARF9.c
    ${SRC}/ogl_model_ZARF_9.c
    ${SRC}/ogl_model_ply_ZARF_9.c
    ${SRC}/curve_ZARF_9.c
    ${SRC}/marker.c
    ${SRC}/StatisticsFunction_ZARF_9.c
)

# ----------------------------------------------------------------------------
# Per-platform GL backend + Tcl-stub bootstrap.
#   WIN32  -> WGL backend (gfx_backend_wgl.c). MinGW additionally needs the Tcl
#             stub bootstrap TU (GNU ld cannot read the COFF tclstub archive).
#   APPLE  -> Cocoa/NSOpenGL backend (gfx_backend_nsgl.m), Objective-C.
#   other  -> no GL backend yet (see Phase 6 rgl fallback).
# ----------------------------------------------------------------------------
if(WIN32)
    target_sources(tkogl2 PRIVATE ${SRC}/gfx_backend_wgl.c)
    if(NOT MSVC)
        target_sources(tkogl2 PRIVATE ${SRC}/tcl_stub_bootstrap.c)
    endif()
elseif(APPLE)
    enable_language(OBJC)
    set_source_files_properties(${SRC}/gfx_backend_nsgl.m PROPERTIES LANGUAGE OBJC)
    target_sources(tkogl2 PRIVATE ${SRC}/gfx_backend_nsgl.m)
else()
    message(FATAL_ERROR
        "tkogl2: no OpenGL backend for this platform yet. Windows (WGL) and "
        "macOS (NSGL) are supported; a native Linux/X11 backend is out of scope "
        "(see the Phase 6 rgl fallback in .planning/ROADMAP.md).")
endif()

# Tcl/R expect the loadable file to be exactly "tkogl2.<ext>" (no "lib" prefix).
if(WIN32)
    set(_tkogl2_suffix ".dll")
elseif(APPLE)
    set(_tkogl2_suffix ".dylib")   # BLD-01: Mach-O -dynamiclib
else()
    set(_tkogl2_suffix ".so")
endif()
set_target_properties(tkogl2 PROPERTIES
    PREFIX ""
    OUTPUT_NAME "tkogl2"
    SUFFIX "${_tkogl2_suffix}"
)

# ----------------------------------------------------------------------------
# Compile definitions.
# ----------------------------------------------------------------------------
target_compile_definitions(tkogl2 PRIVATE
    USE_TCL_STUBS
    # CODE_FOR_LIBRARY is hard-#defined in RunTime_Defines_ZARF_9.h.
)
if(MSVC)
    target_compile_definitions(tkogl2 PRIVATE _CRT_SECURE_NO_WARNINGS)
endif()

# RND-02: how Tk is linked.
#  ON  (default) = stubs mode: link an arch-matched tkstub lib and call
#                  Tk_InitStubs. Robust, version-portable, no load-time tk DLL
#                  dependency. Needs an x64 tkstub (the vendored lib/tkstub86.lib
#                  is x86 and is IGNORED by the x64 linker).
#  OFF           = direct mode: link a Tk import lib (e.g. one generated from the
#                  tk86.dll that ships with x64 R) and skip Tk_InitStubs.
# Windows-only knob; macOS always uses Tk stubs (the mac Tcl/Tk ships stub libs).
option(TKOGL2_TK_USE_STUBS "Link Tk via stubs (ON) or a direct import lib (OFF) [Windows]" ON)

if(APPLE)
    # macOS aqua Tk: select the aqua platform decls (Tk_MacOSXGetNSWindowForDrawable)
    # and route Tcl/Tk through their stub tables.
    target_compile_definitions(tkogl2 PRIVATE USE_TK_STUBS MAC_OSX_TK)
elseif(TKOGL2_TK_USE_STUBS)
    target_compile_definitions(tkogl2 PRIVATE USE_TK_STUBS)
endif()

# MSVC understands the in-source `#pragma warning(...)` lines natively; gcc/clang
# do not, so silence the resulting noise off MSVC.
if(NOT MSVC)
    target_compile_options(tkogl2 PRIVATE -Wno-unknown-pragmas)
endif()

# ----------------------------------------------------------------------------
# Include directories.
#   WIN32  -> vendored Tcl/Tk headers + the Tk X11/ shim + the GL/glut.h shim.
#   APPLE  -> the macOS Tcl/Tk install's headers (tk.h/tkPlatDecls.h/tcl.h and,
#             on aqua, its own X11/ shim). No GLUT (dropped, BLD-04).
# ----------------------------------------------------------------------------
target_include_directories(tkogl2 PRIVATE ${SRC})

if(WIN32)
    # RND-02 (Phase 2): introducing <tk.h> pulls Tk's <X11/Xlib.h> shim. The
    # vendored include/tk_include/ ships tk.h/tkDecls.h/tkPlatDecls.h but NOT the
    # X11/ shim subdir (it is vendored under include/tk_include/X11/). Point this
    # elsewhere only if you keep the shim in a different Tcl/Tk include dir.
    set(TKOGL2_TK_XLIB_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/include/tk_include"
        CACHE PATH "Include dir containing Tk's X11/ shim headers (X11/Xlib.h, X11/X.h, ...)")

    target_include_directories(tkogl2 PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include/tcl_include
        ${CMAKE_CURRENT_SOURCE_DIR}/include/tk_include
        ${CMAKE_CURRENT_SOURCE_DIR}/include/tk_include/ttk
        ${TKOGL2_TK_XLIB_INCLUDE}
        # GL/glut.h shim (MinGW has GL/gl.h + GL/glu.h but not GL/glut.h):
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/glut_shim
    )
elseif(APPLE)
    # macOS Tcl/Tk prefix (Homebrew tcl-tk by default on Apple Silicon; use
    # /usr/local/opt/tcl-tk on Intel, or pass -DTKOGL2_MACOS_TCLTK_PREFIX=...).
    set(TKOGL2_MACOS_TCLTK_PREFIX "/opt/homebrew/opt/tcl-tk"
        CACHE PATH "macOS Tcl/Tk install prefix (contains include/ and lib/)")
    target_include_directories(tkogl2 PRIVATE ${TKOGL2_MACOS_TCLTK_PREFIX}/include)
endif()

# ----------------------------------------------------------------------------
# Link libraries.
#   WIN32/MSVC  -> vendored COFF import libs (glut64, tclstub86_64, Tk lib) +
#                  Windows system libs.
#   WIN32/MinGW -> glut64.dll directly; Tcl via the bootstrap TU above.
#   APPLE       -> macOS Tcl/Tk stub libs + OpenGL/AppKit/Foundation frameworks.
#                  No GLUT (BLD-04). GLU (gluSphere, gluUnProject) lives in the
#                  OpenGL framework.
# ----------------------------------------------------------------------------
if(WIN32)
    if(MSVC)
        # The Tk lib to link: an arch-matched tkstub lib in stubs mode, or a Tk
        # import lib (tk86.lib, x64) in direct mode. Same arch as the target.
        set(TKOGL2_TK_STUB_LIB "${VENDOR_LIB}/tkstub86.lib"
            CACHE FILEPATH "Tk lib to link (x64): tkstub86.lib in stubs mode, or tk86.lib import lib in direct mode")

        target_link_libraries(tkogl2 PRIVATE
            ${VENDOR_LIB}/glut64.lib
            ${VENDOR_LIB}/tclstub86_64.lib
            ${TKOGL2_TK_STUB_LIB}   # RND-02: MUST be x64 (vendored tkstub86.lib is x86 -> override via -DTKOGL2_TK_STUB_LIB)
            opengl32
            glu32
            gdi32
            user32
        )
    else()
        set(TKOGL2_GLUT_LIB "${VENDOR_LIB}/glut64.dll"
            CACHE FILEPATH "GLUT library (or DLL) to link against")

        # NOTE (RND-02): GNU ld cannot read the COFF tkstub86.lib. Tk-stub linkage
        # for MinGW is out of scope (that path is non-distributable, black mesh);
        # the Tk_* symbols are expected unresolved here.
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
elseif(APPLE)
    # Tcl/Tk stub libs from the macOS Tcl/Tk prefix (name varies by version:
    # libtclstub.a on 9.x, libtclstub8.6.a on 8.6, etc.).
    find_library(TKOGL2_MAC_TCLSTUB
        NAMES tclstub tclstub9.0 tclstub8.6 tclstub86
        PATHS ${TKOGL2_MACOS_TCLTK_PREFIX}/lib NO_DEFAULT_PATH)
    find_library(TKOGL2_MAC_TKSTUB
        NAMES tkstub tkstub9.0 tkstub8.6 tkstub86
        PATHS ${TKOGL2_MACOS_TCLTK_PREFIX}/lib NO_DEFAULT_PATH)

    if(NOT TKOGL2_MAC_TCLSTUB OR NOT TKOGL2_MAC_TKSTUB)
        message(FATAL_ERROR
            "tkogl2: could not find Tcl/Tk stub libs under "
            "${TKOGL2_MACOS_TCLTK_PREFIX}/lib. Install Tcl/Tk (brew install tcl-tk) "
            "and pass -DTKOGL2_MACOS_TCLTK_PREFIX=$(brew --prefix tcl-tk).")
    endif()

    target_link_libraries(tkogl2 PRIVATE
        ${TKOGL2_MAC_TCLSTUB}
        ${TKOGL2_MAC_TKSTUB}
        "-framework OpenGL"
        "-framework AppKit"
        "-framework Foundation"
    )
endif()

# Drop the build output next to the project for convenience.
set_target_properties(tkogl2 PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
