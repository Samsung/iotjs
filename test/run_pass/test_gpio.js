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

/*
  @TIMEOUT=10
*/

var assert = require('assert');
var gpio = require('gpio');

var gpioSequence = '';
var result;

result = gpio.initialize();
if (result >= 0)
  gpioSequence += "I";

result = gpio.setPin(1, "in");
if (result >= 0)
  gpioSequence += "A";

gpio.setPin(2, "out", function(err) {
  if (err>=0)
    gpioSequence += 'B';
});

gpio.setPin(3, "in", "float", function(err) {
  if (err>=0)
    gpioSequence += 'C';
});

gpio.release();

process.on('exit', function(code) {
  assert.equal(gpioSequence, 'IABC');
});
