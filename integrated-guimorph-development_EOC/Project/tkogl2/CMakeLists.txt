cmake_minimum_required(VERSION 3.16)

# ============================================================================
# tkogl2 -- Tcl extension DLL for the GUImorph 3D digitizing engine.
#
# This is a WINDOWS DLL (the engine embeds OpenGL into a Tk widget's HWND via
# WGL, so it cannot build as a native Linux .so). The supported build path is
# a MinGW-w64 cross-compile from WSL/Linux:
#
#   sudo apt install mingw-w64 mingw-w64-tools cmake
#   cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake
#   cmake --build build -j
#
# Produces: build/tkogl2.dll  (loaded by Windows-R via `tcl("load", ..., "Tkogl2")`)
# ============================================================================

project(tkogl2 C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(SRC        ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(VENDOR_LIB ${CMAKE_CURRENT_SOURCE_DIR}/lib)

# --- Sources (note: includes StatisticsFunction_ZARF_9.c, which the old
#     .vcxproj omitted even though tcl_if references statisticsVersionPtr) ---
add_library(tkogl2 SHARED
    ${SRC}/tcl_dispatch.c
    ${SRC}/tcl_if_ZARF_9.c
    ${SRC}/ogl_ZARF9.c
    ${SRC}/ogl_model_ZARF_9.c
    ${SRC}/ogl_model_ply_ZARF_9.c
    ${SRC}/curve_ZARF_9.c
    ${SRC}/dot_ZARF_9.c
    ${SRC}/StatisticsFunction_ZARF_9.c
    # Self-contained Tcl stub bootstrap (replaces the unreadable MSVC
    # tclstub86_64.lib; see tcl_stub_bootstrap.c for the rationale).
    ${SRC}/tcl_stub_bootstrap.c
)

# Tcl/R expect the file to be exactly "tkogl2.dll" (no "lib" prefix).
set_target_properties(tkogl2 PROPERTIES
    PREFIX ""
    OUTPUT_NAME "tkogl2"
    SUFFIX ".dll"
)

target_compile_definitions(tkogl2 PRIVATE
    USE_TCL_STUBS
    _CRT_SECURE_NO_WARNINGS
    # CODE_FOR_LIBRARY is hard-#defined in RunTime_Defines_ZARF_9.h.
)

# Silence the MSVC-style `#pragma warning(...)` lines under gcc.
target_compile_options(tkogl2 PRIVATE -Wno-unknown-pragmas)

target_include_directories(tkogl2 PRIVATE
    ${SRC}
    ${CMAKE_CURRENT_SOURCE_DIR}/include/tcl_include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/tk_include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/tk_include/ttk
    # GL/glut.h shim (MinGW has GL/gl.h + GL/glu.h but not GL/glut.h):
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/glut_shim
)

# ----------------------------------------------------------------------------
# External libraries
#
# opengl32 / glu32 / gdi32 / user32 ship with MinGW-w64 (system import libs).
#
# GLUT: the vendored glut64.dll is linked directly (ld synthesizes the import
# table). MinGW has no GLUT of its own.
#
# Tcl stubs: NOT linked from the vendored MSVC tclstub86_64.lib (GNU ld cannot
# read its COFF archive). Instead src/tcl_stub_bootstrap.c provides the stub
# bootstrap directly inside the DLL.
# ----------------------------------------------------------------------------
set(TKOGL2_GLUT_LIB "${VENDOR_LIB}/glut64.dll"
    CACHE FILEPATH "GLUT library (or DLL) to link against")

target_link_libraries(tkogl2 PRIVATE
    ${TKOGL2_GLUT_LIB}
    opengl32
    glu32
    gdi32
    user32
)

# Avoid a runtime dependency on libgcc_s_seh-1.dll.
target_link_options(tkogl2 PRIVATE -static-libgcc)

# Drop the build output next to the project for convenience.
set_target_properties(tkogl2 PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
