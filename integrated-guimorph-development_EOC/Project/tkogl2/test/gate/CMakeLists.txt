cmake_minimum_required(VERSION 3.16)
project(gateext C)

if(NOT APPLE)
  message(FATAL_ERROR "gateext smoke target is macOS-only")
endif()

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

add_library(gateext SHARED gate_ext.c)
set_target_properties(gateext PROPERTIES PREFIX "" SUFFIX ".dylib")

# macOS Tcl/Tk prefix. Default empty so resolution only runs when the user did
# NOT pass -DTKOGL2_MACOS_TCLTK_PREFIX=<path>. An explicit flag is the
# first-choice prefix and short-circuits every Homebrew probe below. Mirrors the
# main build's APPLE branch so the gate is Homebrew-optional (GATE-04).
set(TKOGL2_MACOS_TCLTK_PREFIX ""
  CACHE PATH "macOS Tcl/Tk install prefix; auto-detected when empty")
if(NOT TKOGL2_MACOS_TCLTK_PREFIX)
  # Homebrew-optional resolution. Runs ONLY when the flag was not passed.
  # Priority (stop at first hit):
  #   (1) $HOMEBREW_PREFIX/opt/tcl-tk when the env var is set and the path exists,
  #   (2) a `brew --prefix tcl-tk` probe, but ONLY if brew is on PATH,
  #   (3) the static Apple-Silicon default /opt/homebrew/opt/tcl-tk.
  # A missing brew must NOT abort configuration -- it falls through to (3).
  if(DEFINED ENV{HOMEBREW_PREFIX} AND EXISTS "$ENV{HOMEBREW_PREFIX}/opt/tcl-tk")
    set(TKOGL2_MACOS_TCLTK_PREFIX "$ENV{HOMEBREW_PREFIX}/opt/tcl-tk")
  else()
    find_program(TKOGL2_BREW brew)
    if(TKOGL2_BREW)
      execute_process(
        COMMAND ${TKOGL2_BREW} --prefix tcl-tk
        OUTPUT_VARIABLE _tkogl2_brew_prefix
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE _tkogl2_brew_result)
      if(_tkogl2_brew_result EQUAL 0 AND _tkogl2_brew_prefix)
        set(TKOGL2_MACOS_TCLTK_PREFIX "${_tkogl2_brew_prefix}")
      endif()
    endif()
  endif()
  if(NOT TKOGL2_MACOS_TCLTK_PREFIX)
    # Static fallback (Apple Silicon Homebrew default). Intel Macs / non-brew
    # installs should pass -DTKOGL2_MACOS_TCLTK_PREFIX=<path> explicitly.
    set(TKOGL2_MACOS_TCLTK_PREFIX "/opt/homebrew/opt/tcl-tk")
  endif()
endif()

set(TCLTK_PREFIX "${TKOGL2_MACOS_TCLTK_PREFIX}")

# Homebrew tcl-tk 9.x nests tcl.h/tk.h under include/tcl-tk/ (8.6 kept them at
# include/). List both so bare <tcl.h>/<tk.h> resolve on either layout (GATE-03).
target_include_directories(gateext PRIVATE
  "${TCLTK_PREFIX}/include"
  "${TCLTK_PREFIX}/include/tcl-tk"
)

# The gate links the real Tcl/Tk RUNTIME libraries (not the stubs the main build
# links). Resolve them version-agnostically via find_library over versioned
# NAMES so no single version is hardcoded (GATE-04).
find_library(TKOGL2_MAC_GATE_TCL
  NAMES tcl tcl9.0 tcl8.6 tcl86
  PATHS "${TCLTK_PREFIX}/lib" NO_DEFAULT_PATH)
find_library(TKOGL2_MAC_GATE_TK
  NAMES tk tk9.0 tk8.6 tcl9tk9.0 tk86
  PATHS "${TCLTK_PREFIX}/lib" NO_DEFAULT_PATH)

if(NOT TKOGL2_MAC_GATE_TCL OR NOT TKOGL2_MAC_GATE_TK)
  message(FATAL_ERROR
    "gateext: no Tcl/Tk runtime libraries were found under "
    "${TCLTK_PREFIX}/lib. Install Tcl/Tk (e.g. brew install tcl-tk) "
    "and/or pass -DTKOGL2_MACOS_TCLTK_PREFIX=<path-to-tcl-tk> "
    "(for Homebrew: -DTKOGL2_MACOS_TCLTK_PREFIX=$(brew --prefix tcl-tk)).")
endif()

target_link_libraries(gateext PRIVATE ${TKOGL2_MAC_GATE_TCL} ${TKOGL2_MAC_GATE_TK})
