# Copyright 2017-present Samsung Electronics Co., Ltd. and other contributors
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

set(MODULE_NAME "tls")

if ("${TARGET_OS}" STREQUAL "TIZENRT")
  set(MBEDTLS_LIBS "")
  set(MBEDTLS_INCLUDE_DIR ${TARGET_SYSTEMROOT}/../external/include)
else()
  set(DEPS_MBEDTLS deps/mbedtls)
  set(DEPS_MBEDTLS_SRC ${ROOT_DIR}/${DEPS_MBEDTLS})
  set(DEPS_MBEDTLS_BUILD_DIR
      ${CMAKE_BINARY_DIR}/${DEPS_MBEDTLS}/library/${CONFIG_TYPE})
  set(MODULE_BINARY_DIR ${DEPS_MBEDTLS_BUILD_DIR})

  if("${TARGET_OS}" STREQUAL "TIZEN")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-cpp")
  endif()

  if(USING_MSVC)
    set(CONFIG_DELIMITER "")
  else()
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-sign-conversion")
    set(CONFIG_DELIMITER "'")
  endif()

  set(MBED_CONFIG "${CONFIG_DELIMITER}<config-for-iotjs.h>${CONFIG_DELIMITER}")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -I${ROOT_DIR}/config/mbedtls")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DMBEDTLS_CONFIG_FILE=${MBED_CONFIG}")

  # FIXME:
  #       Remove this workaround when the related bug is fixed in
  #       mbedtls. https://github.com/ARMmbed/mbedtls/issues/1550
  set(CMAKE_C_FLAGS_BCK "${CMAKE_C_FLAGS}")
  string(REPLACE "-fsanitize=address" "" CMAKE_C_FLAGS ${CMAKE_C_FLAGS})

  build_lib_name(MBED_X509_NAME mbedx509)
  build_lib_name(MBED_TLS_NAME mbedtls)
  build_lib_name(MBED_CRYPTO_NAME mbedcrypto)
  ExternalProject_Add(mbedtls
    PREFIX ${DEPS_MBEDTLS}
    SOURCE_DIR ${DEPS_MBEDTLS_SRC}
    BUILD_IN_SOURCE 0
    BINARY_DIR ${DEPS_MBEDTLS}
    INSTALL_COMMAND
      COMMAND ${CMAKE_COMMAND} -E copy
        ${DEPS_MBEDTLS_BUILD_DIR}/${MBED_X509_NAME} ${ARCHIVE_DIR}
      COMMAND ${CMAKE_COMMAND} -E copy
        ${DEPS_MBEDTLS_BUILD_DIR}/${MBED_TLS_NAME} ${ARCHIVE_DIR}
      COMMAND ${CMAKE_COMMAND} -E copy
        ${DEPS_MBEDTLS_BUILD_DIR}/${MBED_CRYPTO_NAME} ${ARCHIVE_DIR}
    CMAKE_ARGS
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
      -DENABLE_PROGRAMS=OFF
      -DENABLE_TESTING=OFF
  )

  # define external mbedtls target
  add_library(libmbedtls STATIC IMPORTED)
  add_dependencies(libmbedtls mbedtls)
  set_property(TARGET libmbedtls PROPERTY
    IMPORTED_LOCATION ${ARCHIVE_DIR}/${MBED_TLS_NAME})

  # define external mbedx509 target
  add_library(libmbedx509 STATIC IMPORTED)
  add_dependencies(libmbedx509 mbedx509)
  set_property(TARGET libmbedx509 PROPERTY
    IMPORTED_LOCATION ${ARCHIVE_DIR}/${MBED_X509_NAME})

  # define external libmbedcrypto target
  add_library(libmbedcrypto STATIC IMPORTED)
  add_dependencies(libmbedcrypto mbedcrypto)
  set_property(TARGET libmbedcrypto PROPERTY
    IMPORTED_LOCATION ${ARCHIVE_DIR}/${MBED_CRYPTO_NAME})

  set_property(DIRECTORY APPEND PROPERTY
    ADDITIONAL_MAKE_CLEAN_FILES
    ${ARCHIVE_DIR}/${MBED_X509_NAME}
    ${ARCHIVE_DIR}/${MBED_TLS_NAME}
    ${ARCHIVE_DIR}/${MBED_CRYPTO_NAME}
  )

  set(MBEDTLS_LIBS libmbedtls libmbedx509 libmbedcrypto)
  set(MBEDTLS_INCLUDE_DIR ${DEPS_MBEDTLS}/include)

  # FIXME:
  #       Remove this workaround when the related bug is fixed in
  #       mbedtls. https://github.com/ARMmbed/mbedtls/issues/1550
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS_BCK}")
endif()
