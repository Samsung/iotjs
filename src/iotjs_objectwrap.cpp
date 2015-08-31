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

#include "iotjs_def.h"
#include "iotjs_objectwrap.h"


namespace iotjs {


JFREE_HANDLER_FUNCTION(FreeObjectWrap, wrapper) {
  // native pointer must not be NULL.
  IOTJS_ASSERT(wrapper != 0);
  JObjectWrap* object_wrap = reinterpret_cast<JObjectWrap*>(wrapper);
  object_wrap->Destroy();
}


JObjectWrap::JObjectWrap(JObject& jobject)
    : _jobject(NULL)
    , _jholder(NULL) {
  IOTJS_ASSERT(jobject.IsObject());

  // This wrapper hold pointer to the javascript object but never increase
  // reference count.
  JRawValueType raw_value = jobject.raw_value();
  _jobject = new JObject(&raw_value, false);
  // Set native pointer of the object to be this wrapper.
  // If the object is freed by GC, the wrapper instance should also be freed.
  _jobject->SetNative((uintptr_t)this, FreeObjectWrap);
}


JObjectWrap::JObjectWrap(JObject& jobject, JObject& jholder)
    : JObjectWrap(jobject) {
  IOTJS_ASSERT(jholder.IsObject() || jholder.IsNull() || jholder.IsUndefined());

  if (jholder.IsObject()) {
    set_jholder(jholder);
  }
}


JObjectWrap::~JObjectWrap() {
  IOTJS_ASSERT(_jobject != NULL);
  IOTJS_ASSERT(_jobject->IsObject());

  delete _jobject;

  if (_jholder != NULL) {
    delete _jholder;
  }
}


JObject& JObjectWrap::jobject() {
  IOTJS_ASSERT(_jobject != NULL);
  return *_jobject;
}


JObject& JObjectWrap::jholder() {
  IOTJS_ASSERT(_jholder != NULL);
  return *_jholder;
}


void JObjectWrap::set_jholder(JObject& jholder) {
  IOTJS_ASSERT(_jholder == NULL);
  IOTJS_ASSERT(jholder.IsObject());

  JRawValueType raw_value = jholder.raw_value();
  _jholder = new JObject(&raw_value, false);
}


void JObjectWrap::Destroy(void) {
  delete this;
}


} // namespace itojs
