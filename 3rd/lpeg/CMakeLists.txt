set(CMAKE_C_FLAGS "-Wall -Wextra -pedantic -Waggregate-return -Wcast-align -Wcast-qual -Wdisabled-optimization -Wpointer-arith -Wshadow -Wsign-compare -Wundef -Wwrite-strings -Wbad-function-cast -Wdeclaration-after-statement -Wmissing-prototypes -Wnested-externs -Wstrict-prototypes")
if (LINUX)
    set(SHARED_FLAGS "-shared -fPIC")
elseif (UNIX)
    set(SHARED_FLAGS "-bundle -undefined dynamic_lookup")
endif ()

set(LPEG_SOURCES
        lpcap.c lpcap.h lpcode.c lpcode.h lpprint.c lpprint.h lptree.c lptree.h lptypes.h lpvm.c lpvm.h)

include_directories(../../skynet-src)

add_library(lpeg OBJECT ${LPEG_SOURCES})
set_target_properties(lpeg PROPERTIES COMPILE_FLAGS "-O2 -std=c99 -fPIC" LINK_FLAGS "${SHARED_FLAGS}")
