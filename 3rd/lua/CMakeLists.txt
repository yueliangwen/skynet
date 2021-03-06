#add_library(lua_static STATIC ${LUA_SOURCES})
#set_target_properties(lua_static PROPERTIES COMPILE_FLAGS "${SYSCFLAGS}" LINK_FLAGS "${SYSLIBS}" OUTPUT_NAME "lua")

project ( lua C )
cmake_minimum_required ( VERSION 2.6 )

set(CMAKE_C_FLAGS "-std=gnu99 -O2 -Wall -Wextra")
if(APPLE)
	set(SYSCFLAGS "-DLUA_USE_MACOSX")
	set(SYSLIBS "-lreadline")
elseif(UNIX)
	set(SYSCFLAGS "-DLUA_USE_LINUX")
	set(SYSLIBS "-Wl,-E -ldl -lreadline")
endif()


## CONFIGURATION
# Default configuration (we assume POSIX by default)
set ( LUA_PATH "LUA_PATH" CACHE STRING "Environment variable to use as package.path." )
set ( LUA_CPATH "LUA_CPATH" CACHE STRING "Environment variable to use as package.cpath." )
set ( LUA_INIT "LUA_INIT" CACHE STRING "Environment variable for initial script." )

option ( LUA_ANSI "Use only ansi features." OFF )
option ( LUA_USE_RELATIVE_LOADLIB "Use modified loadlib.c with support for relative paths on posix systems."
        ON )
set ( LUA_IDSIZE 60 CACHE NUMBER "gives the maximum size for the description of the source." )
set ( LUA_PROMPT "> " CACHE STRING "Is the default prompt used by stand-alone Lua." )
set ( LUA_PROMPT2 ">> " CACHE STRING "Is the default continuation prompt used by stand-alone Lua." )
set ( LUA_MAXINPUT 512 CACHE NUMBER "Is the maximum length for an input line in the stand-alone interpreter." )

#2DO: LUAI_* and LUAL_* settings, for now defaults are used.
set ( LUA_DIRSEP "/" )
set ( LUA_MODULE_SUFFIX ${CMAKE_SHARED_MODULE_SUFFIX} )
set ( LUA_LDIR ${INSTALL_LMOD} )
set ( LUA_CDIR ${INSTALL_CMOD} )

if ( LUA_USE_RELATIVE_LOADLIB )
	# This will set up relative paths to lib
	string ( REGEX REPLACE "[^!/]+" ".." LUA_DIR "!/${INSTALL_BIN}/" )
else ( )
	# Direct path to installation
	set ( LUA_DIR ${CMAKE_INSTALL_PREFIX} CACHE STRING "Destination from which modules will be resolved. See INSTALL_LMOD and INSTALL_CMOD." )
endif ( )

set ( LUA_PATH_DEFAULT "./?.lua;${LUA_DIR}${LUA_LDIR}/?.lua;${LUA_DIR}${LUA_LDIR}/?/init.lua;./?/init.lua" )
set ( LUA_CPATH_DEFAULT "./?${LUA_MODULE_SUFFIX};${LUA_DIR}${LUA_CDIR}/?${LUA_MODULE_SUFFIX};${LUA_DIR}${LUA_CDIR}/loadall${LUA_MODULE_SUFFIX}" )

if ( WIN32 AND NOT CYGWIN )
	# Windows systems
	option ( LUA_WIN "Windows specific build." ON )
	option ( LUA_BUILD_WLUA "Build wLua interpretter without console output." ON )
	option ( LUA_BUILD_AS_DLL "Build Lua library as Dll." ${BUILD_SHARED_LIBS} )

	# Paths (Double escapes needed)
	set ( LUA_DIRSEP "\\\\" )
	string ( REPLACE " /" ${LUA_DIRSEP} LUA_DIR "${LUA_DIR}" )
	string ( REPLACE "/" ${LUA_DIRSEP} LUA_LDIR "${LUA_LDIR}" )
	string ( REPLACE "/" ${LUA_DIRSEP} LUA_CDIR "${LUA_CDIR}" )
	string ( REPLACE "/" ${LUA_DIRSEP} LUA_PATH_DEFAULT "${LUA_PATH_DEFAULT}" )
	string ( REPLACE "/" ${LUA_DIRSEP} LUA_CPATH_DEFAULT "${LUA_CPATH_DEFAULT}" )
else ( )
	# Posix systems (incl. Cygwin)
	option ( LUA_USE_POSIX "Use POSIX functionality." ON )
	option ( LUA_USE_DLOPEN "Use dynamic linker to load modules." ON )
	option ( LUA_USE_MKSTEMP "Use mkstep." ON )
	option ( LUA_USE_ISATTY "Use tty." ON )
	option ( LUA_USE_POPEN "Use popen." ON )
	option ( LUA_USE_ULONGJMP "Use ulongjmp" ON )
endif ( )

# Setup needed variables and libraries
if ( LUA_USE_POSIX )
	# On POSIX Lua links to standard math library "m"
	find_library ( MATH_LIBRARY NAMES m )
	if ( MATH_LIBRARY )
		list ( APPEND LIBS ${MATH_LIBRARY} )
	endif ( )
endif ( )

if ( LUA_USE_DLOPEN )
	# Link to dynamic linker library "dl"
	find_library ( DL_LIBRARY NAMES dl )
	if ( DL_LIBRARY )
		list ( APPEND LIBS ${DL_LIBRARY} )
	endif ( )
endif ( )

if ( LUA_USE_READLINE )
	# Add readline
	include_directories ( ${READLINE_INCLUDE_DIR} )
	list ( APPEND LIBS ${READLINE_LIBRARY} )
endif ( )

if ( LUA_USE_CURSES )
	# Add curses
	include_directories ( ${CURSES_INCLUDE_DIR} )
	list ( APPEND LIBS ${CURSES_LIBRARY} )
endif ( )

# Sources and headers
include_directories(../../skynet-src)
include_directories ( . ${CMAKE_CURRENT_BINARY_DIR} )
set ( SRC_LIB lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c
		lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c
		ltm.c lundump.c lvm.c lzio.c
		lauxlib.c lbaselib.c lbitlib.c lcorolib.c ldblib.c liolib.c
		lmathlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c loadlib.c linit.c)
set ( SRC_LUA lua.c )
set ( SRC_LUAC luac.c )

## BUILD
# Create dynamic library
add_library ( liblua SHARED ${SRC_LIB} ${LUA_DLL_RC} ${LUA_DEF} )
target_link_libraries ( liblua ${LIBS} )
set_target_properties ( liblua PROPERTIES OUTPUT_NAME lua CLEAN_DIRECT_OUTPUT 1 )
if ( LUA_BUILD_AS_DLL )
	set_target_properties ( liblua PROPERTIES COMPILE_DEFINITIONS LUA_BUILD_AS_DLL )
endif ( )

# Create static library, this is needed to compile luac in the 5.1.x Lua series
add_library ( liblua_static STATIC ${SRC_LIB} )
set_target_properties(liblua_static PROPERTIES COMPILE_FLAGS "${SYSCFLAGS}" LINK_FLAGS "${SYSLIBS}")
target_link_libraries ( liblua_static ${LIBS} )

add_executable ( lua ${SRC_LUA} )
set_target_properties(lua PROPERTIES COMPILE_FLAGS "${SYSCFLAGS}" LINK_FLAGS "${SYSLIBS}")
target_link_libraries ( lua liblua_static )

# On windows a variant of the lua interpreter without console output needs to be built
if ( LUA_BUILD_WLUA )
	add_executable ( wlua WIN32 src/wmain.c ${SRC_LUA} )
	target_link_libraries ( wlua liblua )
	install_executable ( wlua )
endif ( )

add_executable ( luac ${SRC_LUAC} ${LUAC_RC} )
target_link_libraries ( luac liblua_static )

