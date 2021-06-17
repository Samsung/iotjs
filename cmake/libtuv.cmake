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

# Configure external libtuv
set(DEPS_TUV deps/libtuv)
set(DEPS_TUV_SRC ${ROOT_DIR}/${DEPS_TUV})

build_lib_name(LIBTUV_NAME tuv)
if("${TARGET_OS}" STREQUAL "MOCK")
  string(TOLOWER ${TARGET_ARCH}-linux PLATFORM_DESCRIPTOR)
else()
  string(TOLOWER ${TARGET_ARCH}-${TARGET_OS} PLATFORM_DESCRIPTOR)
endif()
set(DEPS_TUV_TOOLCHAIN
  ${DEPS_TUV_SRC}/cmake/config/config_${PLATFORM_DESCRIPTOR}.cmake)
message(STATUS "libtuv toolchain file: ${DEPS_TUV_TOOLCHAIN}")
ExternalProject_Add(libtuv
  PREFIX ${DEPS_TUV}
  SOURCE_DIR ${DEPS_TUV_SRC}
  BUILD_IN_SOURCE 0
  BINARY_DIR ${DEPS_TUV}
  INSTALL_COMMAND
    ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_BINARY_DIR}/${DEPS_TUV}/lib/${CONFIG_TYPE}/
    ${CMAKE_BINARY_DIR}/lib/
  CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${DEPS_TUV_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
    -DTARGET_PLATFORM=${PLATFORM_DESCRIPTOR}
    -DLIBTUV_CUSTOM_LIB_OUT=lib
    -DBUILDTESTER=NO
    -DBUILDAPIEMULTESTER=NO
    -DTARGET_SYSTEMROOT=${TARGET_SYSTEMROOT}
    -DTARGET_BOARD=${TARGET_BOARD}
)
add_library(tuv STATIC IMPORTED)
add_dependencies(tuv libtuv)
set_property(TARGET tuv PROPERTY
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/lib/${LIBTUV_NAME})
set_property(DIRECTORY APPEND PROPERTY
  ADDITIONAL_MAKE_CLEAN_FILES ${CMAKE_BINARY_DIR}/lib/${LIBTUV_NAME})
set(TUV_INCLUDE_DIR ${DEPS_TUV_SRC}/include)
set(TUV_LIBS tuv)

if("${TARGET_OS}" STREQUAL "MOCK" OR
   "${TARGET_OS}" STREQUAL "LINUX")
  list(APPEND TUV_LIBS pthread)
elseif("${TARGET_OS}" STREQUAL "WINDOWS")
  list(APPEND TUV_LIBS
        ws2_32.lib
        UserEnv.lib
        advapi32.lib
        iphlpapi.lib
        psapi.lib
        shell32.lib)
endif()
