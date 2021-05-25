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


var port = 22703;
var limit = 233;
var server = net.createServer();

server.listen({ port: port }, startTesting);

server.on('connection', function(socket) {
  var i = 0;
  var writing = function() {
    var ok;
    do {
      ok = socket.write('' + (i % 10));
      if (++i == limit) {
        socket.end();
        ok = false;
      }
    } while (ok);
  };
  socket.on('drain', writing);
  writing();
});

var msg1 = '';
var msg2 = '';
var msg3 = '';
var msg4 = '';
var endCount = 0;
var connectListenerCheck = false;

function endCallback() {
  endCount += 1;
  if (endCount === 4) {
    server.close();
  }
}

function startTesting() {
  var socket1 = net.createConnection(port);

  socket1.on('data', function(data) {
    msg1 += data;
  });
  socket1.on('end', endCallback);


  var socket2 = net.createConnection({port: port});

  socket2.on('data', function(data) {
    msg2 += data;
  });
  socket2.on('end', endCallback);


  var socket3 = net.createConnection({port: port, host: '127.0.0.1'});

  socket3.on('data', function(data) {
    msg3 += data;
  });
  socket3.on('end', endCallback);


  var socket4 = net.createConnection({port: port}, function() {
    connectListenerCheck = true;
  });

  socket4.on('data', function(data) {
    msg4 += data;
  });

  socket4.on('end', endCallback);
}

process.on('exit', function(code) {
  assert.equal(code, 0);
  assert.equal(endCount, 4);
  assert.equal(msg1.length, limit);
  assert.equal(msg2.length, limit);
  assert.equal(msg3.length, limit);
  assert.equal(msg4.length, limit);
  assert(connectListenerCheck);
});
