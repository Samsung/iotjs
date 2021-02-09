# Copyright 2015-present Samsung Electronics Co., Ltd. and other contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 2.8)

# Host jerry for snapshot generation
set(DEPS_HOST_JERRY deps/jerry-host)
if ("${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Linux")
  set(JERRY_HOST_C_FLAGS_INIT "-Wno-error=maybe-uninitialized")
endif()

if (USING_MSVC)
  set(JERRY_HOST_C_FLAGS_INIT "-DWIN32")
endif()

ExternalProject_Add(hostjerry
  PREFIX ${DEPS_HOST_JERRY}
  SOURCE_DIR ${ROOT_DIR}/deps/jerry/
  BUILD_IN_SOURCE 0
  BINARY_DIR ${DEPS_HOST_JERRY}
  CMAKE_ARGS
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_C_FLAGS=${JERRY_HOST_C_FLAGS_INIT}
    -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/${DEPS_HOST_JERRY}
    -DENABLE_AMALGAM=ON
    -DENABLE_LTO=${ENABLE_LTO}
    -DJERRY_CMDLINE=OFF
    -DJERRY_CMDLINE_SNAPSHOT=ON
    -DJERRY_EXT=ON
    -DJERRY_LOGGING=ON
    -DJERRY_ERROR_MESSAGES=ON
    -DJERRY_SNAPSHOT_SAVE=${ENABLE_SNAPSHOT}
    -DJERRY_PROFILE=${JERRY_PROFILE}
    -DJERRY_LINE_INFO=${JERRY_LINE_INFO}
    ${EXTRA_JERRY_CMAKE_PARAMS}

    # The snapshot tool does not require the system allocator
    # turn it off by default.
    #
    # Additionally this is required if one compiles on a
    # 64bit system to a 32bit system with system allocator
    # enabled. This is beacuse on 64bit the system allocator
    # should not be used as it returns 64bit pointers which
    # can not be represented correctly in the JerryScript engine
    # currently.
    -DJERRY_SYSTEM_ALLOCATOR=OFF
)
set(JERRY_HOST_SNAPSHOT
    ${CMAKE_BINARY_DIR}/${DEPS_HOST_JERRY}/bin/jerry-snapshot)
add_executable(jerry-snapshot IMPORTED)
add_dependencies(jerry-snapshot hostjerry)
set_property(TARGET jerry-snapshot PROPERTY
  IMPORTED_LOCATION ${JERRY_HOST_SNAPSHOT})

# Utility method to add -D<KEY>=<KEY_Value>
macro(add_cmake_arg TARGET_ARG KEY)
  if(${KEY})
    list(APPEND ${TARGET_ARG} -D${KEY}=${${KEY}})
  endif()
endmacro(add_cmake_arg)

# Target libjerry
set(JERRY_LIBS jerry-core jerry-port-default jerry-ext)
set(DEPS_LIB_JERRY_ARGS)

# Configure the MinSizeRel as the default build type
# for target jerry in release mode.
if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  set(JERRY_CMAKE_BUILD_TYPE MinSizeRel)
else()
  set(JERRY_CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE})
endif()


# use system libm on Unix like targets
if("${TARGET_OS}" MATCHES "TIZENRT|NUTTX")
  list(APPEND JERRY_LIBS jerry-math)
  list(APPEND DEPS_LIB_JERRY_ARGS
    -DJERRY_MATH=ON
    -DEXTERNAL_CMAKE_SYSTEM_PROCESSOR=${EXTERNAL_CMAKE_SYSTEM_PROCESSOR}
  )
elseif("${TARGET_OS}" MATCHES "LINUX|TIZEN|DARWIN|OPENWRT")
  list(APPEND JERRY_LIBS m)
  list(APPEND DEPS_LIB_JERRY_ARGS
    -DJERRY_MATH=OFF)
elseif("${TARGET_OS}" MATCHES "WINDOWS")
  list(APPEND DEPS_LIB_JERRY_ARGS
    -DJERRY_MATH=OFF)
else()
  list(APPEND JERRY_LIBS jerry-math)
  list(APPEND DEPS_LIB_JERRY_ARGS
    -DJERRY_MATH=ON
    -DEXTERNAL_CMAKE_SYSTEM_PROCESSOR=${EXTERNAL_CMAKE_SYSTEM_PROCESSOR}
  )
endif()

# Add a few cmake options based on buildtype/external cmake defines
if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  list(APPEND DEPS_LIB_JERRY_ARGS -DJERRY_ERROR_MESSAGES=ON)
endif()

# NuttX is not using the default port implementation of JerryScript
if("${TARGET_OS}" MATCHES "NUTTX|TIZENRT")
  list(APPEND DEPS_LIB_JERRY_ARGS -DJERRY_PORT_DEFAULT=OFF)
else()
  list(APPEND DEPS_LIB_JERRY_ARGS -DJERRY_PORT_DEFAULT=ON)
endif()

add_cmake_arg(DEPS_LIB_JERRY_ARGS ENABLE_LTO)
add_cmake_arg(DEPS_LIB_JERRY_ARGS JERRY_MEM_STATS)
add_cmake_arg(DEPS_LIB_JERRY_ARGS JERRY_ERROR_MESSAGES)
add_cmake_arg(DEPS_LIB_JERRY_ARGS JERRY_DEBUGGER)
add_cmake_arg(DEPS_LIB_JERRY_ARGS JERRY_GLOBAL_HEAP_SIZE)
add_cmake_arg(DEPS_LIB_JERRY_ARGS JERRY_ATTR_GLOBAL_HEAP)

separate_arguments(EXTRA_JERRY_CMAKE_PARAMS)

build_lib_name(JERRY_CORE_NAME jerry-core)
build_lib_name(JERRY_LIBM_NAME jerry-math)
build_lib_name(JERRY_EXT_NAME jerry-ext)

set(DEPS_LIB_JERRY deps/jerry)
set(DEPS_LIB_JERRY_SRC ${ROOT_DIR}/${DEPS_LIB_JERRY})
ExternalProject_Add(libjerry
  PREFIX ${DEPS_LIB_JERRY}
  SOURCE_DIR ${ROOT_DIR}/deps/jerry/
  BUILD_IN_SOURCE 0
  BINARY_DIR ${DEPS_LIB_JERRY}
  INSTALL_COMMAND
    ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_BINARY_DIR}/${DEPS_LIB_JERRY}/lib/${CONFIG_TYPE}
    ${CMAKE_BINARY_DIR}/lib/
  CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DCMAKE_BUILD_TYPE=${JERRY_CMAKE_BUILD_TYPE}
    -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
    -DENABLE_AMALGAM=ON
    -DJERRY_CMDLINE=OFF
    -DJERRY_SNAPSHOT_EXEC=${ENABLE_SNAPSHOT}
    -DJERRY_SNAPSHOT_SAVE=OFF
    -DJERRY_PROFILE=${JERRY_PROFILE}
    -DJERRY_LOGGING=ON
    -DJERRY_LINE_INFO=${JERRY_LINE_INFO}
    -DJERRY_VM_EXEC_STOP=ON
    -DJERRY_ERROR_MESSAGES=ON
    -DENABLE_LTO=${ENABLE_LTO}
    ${DEPS_LIB_JERRY_ARGS}
    ${EXTRA_JERRY_CMAKE_PARAMS}
)

set_property(DIRECTORY APPEND PROPERTY
  ADDITIONAL_MAKE_CLEAN_FILES
    ${CMAKE_BINARY_DIR}/lib/${JERRY_CORE_NAME}
    ${CMAKE_BINARY_DIR}/lib/${JERRY_LIBM_NAME}
    ${CMAKE_BINARY_DIR}/lib/${JERRY_EXT_NAME}
)

# define external jerry-core target
add_library(jerry-core STATIC IMPORTED)
add_dependencies(jerry-core libjerry)
set_property(TARGET jerry-core PROPERTY
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/lib/${JERRY_CORE_NAME})

# define external jerry-libm target
add_library(jerry-math STATIC IMPORTED)
add_dependencies(jerry-math libjerry)
set_property(TARGET jerry-math PROPERTY
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/lib/${JERRY_LIBM_NAME})

# define external jerry-ext target
add_library(jerry-ext STATIC IMPORTED)
add_dependencies(jerry-ext libjerry)
set_property(TARGET jerry-ext PROPERTY
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/lib/${JERRY_EXT_NAME})

if(NOT "${TARGET_OS}" MATCHES "NUTTX|TIZENRT")
  build_lib_name(JERRY_PORT_NAME jerry-port)
  build_lib_name(JERRY_PORT_DEFAULT_NAME jerry-port-default)
  set_property(DIRECTORY APPEND PROPERTY
    ADDITIONAL_MAKE_CLEAN_FILES
      ${CMAKE_BINARY_DIR}/lib/${JERRY_PORT_NAME}
  )

  # define external jerry-port-default target
  add_library(jerry-port-default STATIC IMPORTED)
  add_dependencies(jerry-port-default libjerry)
  set_property(TARGET jerry-port-default PROPERTY
    IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/lib/${JERRY_PORT_DEFAULT_NAME})

  set(JERRY_PORT_DIR ${DEPS_LIB_JERRY_SRC}/jerry-port/default)
endif()

set(JERRY_INCLUDE_DIR ${DEPS_LIB_JERRY_SRC}/jerry-core/include)
set(JERRY_EXT_DIR ${DEPS_LIB_JERRY_SRC}/jerry-ext)
