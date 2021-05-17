/* Copyright 2021 Samsung Electronics Co., Ltd. and other contributors
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

#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

int
LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
  if(size<20) {
    return 0;
  }

  // Skip test cases with double quotes
  for (int i=0; i<size; i++) {
    if(data[i]==34) {
      return 0;
    }
  }

  // Create javascript file
  char filename[256];
  sprintf(filename, "/tmp/libfuzzer.js");

  // Create javascript code
  char one[] = "(new Buffer(\"";
  char two[] = "\")).slice(0, 1).readUInt16LE({}, true);');\n";
  FILE *fp = fopen(filename, "wb");
  if (!fp)
    return 0;  
  fwrite(one, sizeof(char), strlen(one), fp);
  fwrite(data, size, 1, fp);
  fwrite(two, sizeof(char), strlen(two), fp);
  fclose(fp);

  int argc = 2;
  char* argv[argc];
  argv[0] = "iotjs";
  argv[1] = "/tmp/libfuzzer.js";

  iotjs_entry(argc, argv);
  
  unlink(filename);
  return 0;
}