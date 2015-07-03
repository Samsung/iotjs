/* Copyright 2015 Samsung Electronics Co., Ltd.
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

#ifndef IOTJS_OBJECTWRAP_H
#define IOTJS_OBJECTWRAP_H


#include "iotjs_binding.h"


namespace iotjs {


// This wrapper refer javascript object but never increase reference count
// If the object is freed by GC, then this wrapper instance will be also freed.
class JObjectWrap {
 public:
  explicit JObjectWrap(JObject& jobject);
  explicit JObjectWrap(JObject& jobject, JObject& jholder);

  virtual ~JObjectWrap();

  JObject& jobject();
  JObject& jholder();
  void set_jholder(JObject& jholder);

 protected:
  JObject* _jobject;
  JObject* _jholder;
};


} // namespace iotjs


#endif /* IOTJS_OBJECTWRAP_H */
