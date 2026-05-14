# Copyright (c) 2023, AgiBot Inc.
# All rights reserved.

message(STATUS "get serial ...")

find_package(serial QUIET)

if(NOT serial_FOUND)
  include(FetchContent)

  set(FETCHCONTENT_BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/_deps)

  set(serial_DOWNLOAD_URL
      "https://github.com/wjwwood/serial/archive/refs/tags/1.2.1.tar.gz"
      CACHE STRING "")

  set(_SERIAL_LOCAL_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/_deps/serial-src)
  if(EXISTS ${_SERIAL_LOCAL_SOURCE}/src/serial.cc)
    message(STATUS "  using local serial source: ${_SERIAL_LOCAL_SOURCE}")
    set(serial_SOURCE_DIR ${_SERIAL_LOCAL_SOURCE})
    set(serial_POPULATED TRUE)
  else()
    FetchContent_Declare(
      serial
      URL ${serial_DOWNLOAD_URL}
      DOWNLOAD_EXTRACT_TIMESTAMP TRUE)

    function(get_serial)
      FetchContent_GetProperties(serial)
      if(NOT serial_POPULATED)
        FetchContent_Populate(serial)
        set(serial_SOURCE_DIR ${serial_SOURCE_DIR} PARENT_SCOPE)
      endif()
    endfunction()

    get_serial()
  endif()

  if(NOT TARGET serial::serial AND EXISTS ${serial_SOURCE_DIR}/CMakeLists.txt)
    set(SERIAL_CMAKE_CONTENT "cmake_minimum_required(VERSION 2.8.3)
project(serial)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)

if(APPLE)
        find_library(IOKIT_LIBRARY IOKit)
        find_library(FOUNDATION_LIBRARY Foundation)
endif()

set(serial_SRCS
    src/serial.cc
    include/serial/serial.h
    include/serial/v8stdint.h
)
if(APPLE)
        list(APPEND serial_SRCS src/impl/unix.cc)
        list(APPEND serial_SRCS src/impl/list_ports/list_ports_osx.cc)
elseif(UNIX)
    list(APPEND serial_SRCS src/impl/unix.cc)
    list(APPEND serial_SRCS src/impl/list_ports/list_ports_linux.cc)
else()
    list(APPEND serial_SRCS src/impl/win.cc)
    list(APPEND serial_SRCS src/impl/list_ports/list_ports_win.cc)
endif()

add_library(serial \${serial_SRCS})
if(APPLE)
        target_link_libraries(serial \${FOUNDATION_LIBRARY} \${IOKIT_LIBRARY})
elseif(UNIX)
        target_link_libraries(serial rt pthread)
else()
        target_link_libraries(serial setupapi)
endif()

include_directories(include)

install(TARGETS serial
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)

install(FILES include/serial/serial.h include/serial/v8stdint.h
  DESTINATION include/serial)
")
    file(WRITE ${serial_SOURCE_DIR}/CMakeLists.txt "${SERIAL_CMAKE_CONTENT}")
    add_subdirectory(${serial_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}/serial-build)
  endif()
endif()