cmake_minimum_required(VERSION 2.6)
project(skynet)

set(SHARED_FLAGS "-fPIC --shared")
set(EXPORT "-Wl,-E")

if (LINUX)
    message(STATUS "Now is LINUX")
elseif (WIN32)
    message(STATUS "Windows cannot support")
elseif (UNIX)
    message(STATUS "Now is UNIX-like OS's. Including Apple osx and CygWin")
    set(SHARED_FLAGS "${SHARED_FLAGS} -dynamiclib -Wl,-undefined,dynamic_lookup")
    set(EXPORT "")
endif ()

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Wall")
set(CMAKE_C_FLAGS_RELEASE "-g -O2 -Wall")

message(STATUS "CMAKE_C_FLAGS_DEBUG -> ${CMAKE_C_FLAGS_DEBUG}")
message(STATUS "CMAKE_C_FLAGS_RELEASE -> ${CMAKE_C_FLAGS_RELEASE}")

#set(CMAKE_C_FLAGS "-g -O2 -Wall")
#set(CMAKE_VERBOSE_MAKEFILE on)

find_package(Threads)

add_definitions(-DNOUSE_JEMALLOC)

if ("${CMAKE_C_COMPILER_ID}" STREQUAL "TinyCC")
    message(STATUS "using pthread lock")
    add_definitions(-DUSE_PTHREAD_LOCK)
endif ()

include_directories(./3rd/lua)
include_directories(skynet-src)

add_subdirectory(./3rd/lua)
add_subdirectory(./3rd/lua-md5)
add_subdirectory(./3rd/lpeg)

set(SKYNET_SOURCES service-src/service_logger.c
        service-src/service_snlua.c
        service-src/service_harbor.c
        service-src/service_gate.c

        skynet-src/atomic.h skynet-src/skynet_env.c skynet-src/skynet_harbor.h skynet-src/skynet_module.h skynet-src/skynet_socket.c skynet-src/socket_poll.h
        skynet-src/luashrtbl.h skynet-src/skynet_env.h skynet-src/skynet_imp.h skynet-src/skynet_monitor.c skynet-src/skynet_socket.h skynet-src/socket_server.c
        skynet-src/malloc_hook.c skynet-src/skynet_error.c skynet-src/skynet_log.c skynet-src/skynet_monitor.h skynet-src/skynet_start.c skynet-src/socket_server.h
        skynet-src/malloc_hook.h skynet-src/skynet.h skynet-src/skynet_log.h skynet-src/skynet_mq.c skynet-src/skynet_timer.c skynet-src/spinlock.h
        skynet-src/rwlock.h skynet-src/skynet_handle.c skynet-src/skynet_main.c skynet-src/skynet_mq.h skynet-src/skynet_timer.h
        skynet-src/skynet_daemon.c skynet-src/skynet_handle.h skynet-src/skynet_malloc.h skynet-src/skynet_server.c skynet-src/socket_epoll.h
        skynet-src/skynet_daemon.h skynet-src/skynet_harbor.c skynet-src/skynet_module.c skynet-src/skynet_server.h skynet-src/socket_kqueue.h

        )

add_library(lualib OBJECT

        lualib-src/lsha1.c lualib-src/lua-cluster.c lualib-src/lua-memory.c lualib-src/lua-mysqlaux.c lualib-src/lua-seri.c lualib-src/lua-skynet.c
        lualib-src/lua-bson.c lualib-src/lua-crypt.c lualib-src/lua-mongo.c lualib-src/lua-netpack.c lualib-src/lua-seri.h lualib-src/lua-socket.c
        lualib-src/lua-clientsocket.c lualib-src/lua-debugchannel.c lualib-src/lua-multicast.c lualib-src/lua-profile.c lualib-src/lua-sharedata.c lualib-src/lua-stm.c


        lualib-src/sproto/lsproto.c lualib-src/sproto/msvcint.h lualib-src/sproto/sproto.c lualib-src/sproto/sproto.h

        )

add_library(skynet_shared SHARED lualib-src/lua-skynet.c lualib-src/lua-seri.c)
add_library(socketdriver SHARED lualib-src/lua-socket.c)
add_library(bson SHARED lualib-src/lua-bson.c)
add_library(mongo SHARED lualib-src/lua-mongo.c)
add_library(md5 SHARED 3rd/lua-md5/md5.c 3rd/lua-md5/md5lib.c 3rd/lua-md5/compat-5.2.c)
add_library(netpack SHARED lualib-src/lua-netpack.c)
add_library(clientsocket SHARED lualib-src/lua-clientsocket.c)
add_library(memory SHARED lualib-src/lua-memory.c)
add_library(profile SHARED lualib-src/lua-profile.c)
add_library(multicast SHARED lualib-src/lua-multicast.c)
add_library(cluster SHARED lualib-src/lua-cluster.c)
add_library(crypt SHARED lualib-src/lua-crypt.c lualib-src/lsha1.c)
add_library(sharedata SHARED lualib-src/lua-sharedata.c)
add_library(stm SHARED lualib-src/lua-stm.c)
add_library(sproto SHARED lualib-src/sproto/sproto.c lualib-src/sproto/lsproto.c)
add_library(lpeg_shared SHARED 3rd/lpeg/lpcap.c 3rd/lpeg/lpcode.c 3rd/lpeg/lpprint.c 3rd/lpeg/lptree.c 3rd/lpeg/lpvm.c)
add_library(mysqlaux SHARED lualib-src/lua-mysqlaux.c)
add_library(debugchannel SHARED lualib-src/lua-debugchannel.c)
set_target_properties(skynet_shared PROPERTIES OUTPUT_NAME "skynet")
set_target_properties(lpeg_shared PROPERTIES OUTPUT_NAME "lpeg")
set_target_properties(skynet_shared socketdriver bson mongo md5 netpack clientsocket memory profile multicast
        cluster crypt sharedata stm sproto lpeg_shared mysqlaux debugchannel
        PROPERTIES PREFIX "" SUFFIX ".so" LINK_FLAGS "${SHARED_FLAGS}" LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/luaclib")
set_target_properties(clientsocket PROPERTIES LINK_FLAGS "${SHARED_FLAGS} -lpthread")

add_library(logger SHARED service-src/service_logger.c)
add_library(snlua SHARED service-src/service_snlua.c)
add_library(harbor SHARED service-src/service_harbor.c)
add_library(gate SHARED service-src/service_gate.c)
set_target_properties(logger snlua harbor gate
        PROPERTIES PREFIX "" SUFFIX ".so" LINK_FLAGS "${SHARED_FLAGS}" LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/cservice")

aux_source_directory(skynet-src SKYNET_SRCS)
#add_executable(skynet ${SKYNET_SRCS})
# 这些静态库的符号因为没有在主程序里引用, 故而直接作为静态库链接会导致 obj 被从可执行文件移除
# 所以需要使用 cmake OBJECT 库来组织引用. 将他们还是作为最终可执行文件的 obj 来链接, 而不是静态库
add_executable(skynet ${SKYNET_SRCS} $<TARGET_OBJECTS:lualib> $<TARGET_OBJECTS:lua-md5> $<TARGET_OBJECTS:lpeg>)
#add_executable(skynet ${SKYNET_SRCS})
set_target_properties(skynet PROPERTIES COMPILE_FLAGS "${EXPORT}")
# link to static libraries of skynet project
# target_link_libraries(skynet )

# link to bundled static libraries
target_link_libraries(skynet liblua_static)

# link to standart library on UNIX systems
target_link_libraries(skynet ${CMAKE_THREAD_LIBS_INIT} m dl)
