/* Copyright 2015-present Samsung Electronics Co., Ltd. and other contributors
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

var net = require('net');
var assert = require('assert');
var timers = require('timers');

var port = 22708;

var server = net.createServer();

server.listen(port, 5);

server.on('close', function() {
  assert.equal(msg, '12');
});

server.on('connection', function(socket) {
  socket.on('data', function(data) {
    socket.end(data);
  });
  socket.on('close', function() {
  });
});

var sock1 = new net.Socket();
var sock2 = new net.Socket();

var msg = '';

sock1.connect(port, 'localhost');
sock2.connect(port, 'localhost');

sock1.on('data', function(data) {
  msg += data;
  sendSock2Data();
});

sock1.on('end', function() {
  sock1.end();
});

sock2.on('data', function(data) {
  msg += data;
});

sock2.on('end', function() {
  sock2.end();
  server.close();
});

timers.setTimeout(function() {
  sock1.write('1');
}, 1000);

function sendSock2Data() {
  sock2.write('2');
}

process.on('exit', function(code) {
  assert.equal(code, 0);
});
