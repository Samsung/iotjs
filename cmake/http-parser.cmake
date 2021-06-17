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

if("${TARGET_OS}" MATCHES "NUTTX|TIZENRT")
  set(HTTPPARSER_NUTTX_ARG -DNUTTX_HOME=${TARGET_SYSTEMROOT})
endif()

build_lib_name(HTTPPARSER_NAME httpparser)

set(DEPS_HTTPPARSER deps/http-parser)
set(DEPS_HTTPPARSER_SRC ${ROOT_DIR}/${DEPS_HTTPPARSER}/)
ExternalProject_Add(http-parser
  PREFIX ${DEPS_HTTPPARSER}
  SOURCE_DIR ${DEPS_HTTPPARSER_SRC}
  BUILD_IN_SOURCE 0
  BINARY_DIR ${DEPS_HTTPPARSER}
  INSTALL_COMMAND
    ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_BINARY_DIR}/${DEPS_HTTPPARSER}/${CONFIG_TYPE}/
    ${CMAKE_BINARY_DIR}/lib/
  CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
    -DOS=${TARGET_OS}
    ${HTTPPARSER_NUTTX_ARG}
    -DENABLE_MEMORY_CONSTRAINTS=ON
)
add_library(libhttp-parser STATIC IMPORTED)
add_dependencies(libhttp-parser http-parser)
set_property(TARGET libhttp-parser PROPERTY
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/lib/${HTTPPARSER_NAME})
set_property(DIRECTORY APPEND PROPERTY
  ADDITIONAL_MAKE_CLEAN_FILES ${CMAKE_BINARY_DIR}/lib/${HTTPPARSER_NAME})

set(HTTPPARSER_INCLUDE_DIR ${DEPS_HTTPPARSER_SRC})
