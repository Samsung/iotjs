/* Copyright 2018-present Samsung Electronics Co., Ltd. and other contributors
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

var assert = require('assert');
var fs = require('fs');
var tls = require('tls');

var expected_client_msg = 'Client hello';
var expected_server_msg = 'Server hello';
var client_message = '';
var server_message = '';
var server_closed = false;
var server_handshake_done = false;
var handshake_done = false;
var endCount = 0;

var port = 8080;

var server_options = {
  key: fs.readFileSync(process.cwd() + '/resources/my_key.key').toString(),
  cert: fs.readFileSync(process.cwd() + '/resources/my_crt.crt'),
  rejectUnauthorized: false,
  isServer: true,
};

var server = tls.createServer(server_options, function(socket) {
  socket.write('Server hello');

  socket.on('data', function(data) {
    client_message = data.toString();
  });

}).listen(port, startTesting);

server.on('secureConnection', function() {
  server_handshake_done = true;
});

server.on('close', function() {
  server_closed = true;
});

function endCallback() {
  endCount += 1;
  if (endCount === 3) {
    server.close();
  }
}

function startTesting() {
  var socket_options = {
    rejectUnauthorized: false,
  };

  var socket1 = tls.connect(port, 'localhost', socket_options);

  socket1.on('secureConnect', function() {
    handshake_done = true;
  });

  socket1.on('data', function(data) {
    server_message = data.toString();
    socket1.write('Client hello');
    socket1.end();
  });
  socket1.on('end', endCallback);

  var socket2 = tls.connect(port, 'localhost', socket_options, function() {});

  socket1.on('secureConnect', function() {
    handshake_done = true;
  });

  socket2.on('data', function(data) {
    server_message = data.toString();
    socket2.write('Client hello');
    socket2.end();
  });
  socket2.on('end', endCallback);

  var socket3 = tls.connect(port, 'localhost', function() {});

  socket3.on('secureConnect', function() {
    handshake_done = true;
  });

  socket3.on('data', function(data) {
    server_message = data.toString();
    socket3.write('Client hello');
    socket3.end();
  });

  socket3.on('end', endCallback);
}

process.on('exit', function() {
  assert.equal(endCount, 3);
  assert.equal(handshake_done, true);
  assert.equal(server_handshake_done, true);
  assert.equal(client_message === expected_client_msg, true);
  assert.equal(server_message === expected_server_msg, true);
  assert.equal(server_closed, true);
});
