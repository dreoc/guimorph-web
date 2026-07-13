cmake_minimum_required(VERSION 3.16)
project(gateext C)

if(NOT APPLE)
  message(FATAL_ERROR "gateext smoke target is macOS-only")
endif()

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

add_library(gateext SHARED gate_ext.c)
set_target_properties(gateext PROPERTIES PREFIX "" SUFFIX ".dylib")

if(DEFINED ENV{HOMEBREW_PREFIX})
  set(HOMEBREW_PREFIX $ENV{HOMEBREW_PREFIX})
else()
  execute_process(
    COMMAND brew --prefix
    OUTPUT_VARIABLE HOMEBREW_PREFIX
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
endif()

if(NOT HOMEBREW_PREFIX)
  message(FATAL_ERROR "Unable to determine Homebrew prefix")
endif()

set(TCLTK_PREFIX "${HOMEBREW_PREFIX}/opt/tcl-tk")
target_include_directories(gateext PRIVATE
  "${TCLTK_PREFIX}/include"
  "${TCLTK_PREFIX}/include/tcl-tk"
)
target_link_directories(gateext PRIVATE "${TCLTK_PREFIX}/lib")
target_link_libraries(gateext PRIVATE tcl9.0 tcl9tk9.0)
