/* Copyright 2015-2016 Samsung Electronics Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef IOTJS_UTIL_H
#define IOTJS_UTIL_H


#include "iotjs_string.h"


#ifdef __cplusplus
extern "C" {
#endif

// Return value should be released with iotjs_string_destroy()
iotjs_string_t iotjs_file_read(const char* path);

char* iotjs_buffer_allocate(unsigned size);
char* iotjs_buffer_reallocate(char* buffer, unsigned size);
void iotjs_buffer_release(char* buff);

#define IOTJS_ALLOC(iotjs_classname_t) \
  (iotjs_classname_t*) iotjs_buffer_allocate(sizeof(iotjs_classname_t))

#define IOTJS_RELEASE(ptr) \
  iotjs_buffer_release((char*)ptr)


#ifdef __cplusplus
} // extern "C"
#endif


#endif /* IOTJS_UTIL_H */
