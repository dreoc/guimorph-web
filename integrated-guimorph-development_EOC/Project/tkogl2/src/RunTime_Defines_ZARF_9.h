#ifndef __RUN_TIME_DEFINES__
#define __RUN_TIME_DEFINES__

// First undefine all known pre processor defines 
// This list is current as of 18 May 2020
// DO NOT CORRUPT THE UNDEFINES HERE
//
#undef STAND_ALONE_TOOL
#undef CODE_FOR_LIBRARY 
#undef MAKE_INERT
#undef __linux__
#undef NO_GRAPHICS
#undef STAND_ALONE_OPEN_GL

// Define the CODE_FOR_LIBRARY when the source code (for the GuiMorph tool) will be
// built into a library for use by the R Gui.
// Note : NOT all of the source code is intended for the library
// (example the testing code). Maibly, prinf () statements are to be made inert 
// as well as deletion of any debugger breakpoints

// Deine the STAND_ALONE_TOOL when the source code will be compiled and executed by
// the main program main_10 in a desk top testing environment.  This is for developers only.

// The directive  MAKE_INERT is for temporary use.
// it is intended to make broken code inert.
// For a formal code release the offending code should be removed from the source file
// To exclude offending code - wrap the code in the preprocessor directive 
// #ifdef MAKE_INERT
//     offending code here
// #endif







// Next, as desired define the directives suitable for your current test desires 
// THE GROUPING OF DEFINES IS MUTUALLY EXCLUSIVE !

//#define STAND_ALONE_TOOL
//#define NO_GRAPHICS

//  This is inwork by Dave for stand alone too visualization
//  This capability has not been delivered !
//  #define STAND_ALONE_OPEN_GL

///////////////////////////////////////
 #define CODE_FOR_LIBRARY 

#endif
