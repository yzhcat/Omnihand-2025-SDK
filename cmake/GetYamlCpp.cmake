# Copyright (c) 2023, AgiBot Inc.
# All rights reserved.

message(STATUS "get yaml-cpp ...")

find_package(yaml-cpp QUIET)

if(NOT yaml-cpp_FOUND)
  include(FetchContent)

  set(FETCHCONTENT_BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/_deps)

  set(yaml-cpp_DOWNLOAD_URL
      "https://github.com/jbeder/yaml-cpp/archive/refs/tags/yaml-cpp-0.7.0.tar.gz"
      CACHE STRING "")

  set(_YAML_CPP_LOCAL_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/_deps/yaml-cpp-src)
  if(EXISTS ${_YAML_CPP_LOCAL_SOURCE}/CMakeLists.txt)
    message(STATUS "  using local yaml-cpp source: ${_YAML_CPP_LOCAL_SOURCE}")
    set(yaml-cpp_SOURCE_DIR ${_YAML_CPP_LOCAL_SOURCE})
    set(yaml-cpp_POPULATED TRUE)
  else()
    FetchContent_Declare(
      yaml-cpp
      URL ${yaml-cpp_DOWNLOAD_URL}
      DOWNLOAD_EXTRACT_TIMESTAMP TRUE)

    function(get_yaml_cpp)
      FetchContent_GetProperties(yaml-cpp)
      if(NOT yaml-cpp_POPULATED)
        set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
        set(YAML_CPP_BUILD_TESTS OFF CACHE BOOL "" FORCE)
        set(YAML_CPP_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
        set(YAML_CPP_FORMAT_SOURCE OFF CACHE BOOL "" FORCE)
        set(YAML_CPP_BUILD_CONTRIB OFF CACHE BOOL "" FORCE)

        FetchContent_Populate(yaml-cpp)
        add_subdirectory(${yaml-cpp_SOURCE_DIR} ${yaml-cpp_BINARY_DIR})

        if(TARGET yaml-cpp AND NOT TARGET yaml-cpp::yaml-cpp)
          get_target_property(_yaml_cpp_imported yaml-cpp TARGET_IS_IMPORTED)
          if(NOT _yaml_cpp_imported)
            add_library(yaml-cpp::yaml-cpp ALIAS yaml-cpp)
          endif()
        endif()
      endif()
    endfunction()

    get_yaml_cpp()
  endif()

  if(TARGET yaml-cpp AND NOT TARGET yaml-cpp::yaml-cpp)
    get_target_property(_yaml_cpp_imported yaml-cpp TARGET_IS_IMPORTED)
    if(NOT _yaml_cpp_imported)
      add_library(yaml-cpp::yaml-cpp ALIAS yaml-cpp)
    endif()
  endif()
endif()

if(TARGET yaml-cpp AND NOT TARGET yaml-cpp::yaml-cpp)
  get_target_property(_yaml_cpp_imported yaml-cpp TARGET_IS_IMPORTED)
  if(NOT _yaml_cpp_imported)
    add_library(yaml-cpp::yaml-cpp ALIAS yaml-cpp)
  endif()
endif()