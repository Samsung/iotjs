/* Copyright 2017-present Samsung Electronics Co., Ltd. and other contributors
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
var http = require('http');
var net = require('net');

// Messages for further requests.
var message = 'Hello IoT.js';

// Options for further requests.
function createOptions(port) {
  return {
    method: 'POST',
    port: port,
    path: '/',
    headers : {'Content-Length': message.length}
  };

}

var server1 = http.createServer(function(request, response) {
  var str = '';

  request.on('data', function (chunk) {
    str += chunk.toString();
  });

  request.on('end', function() {
    assert.equal(str, message);
    response.end();
  });
});
server1.listen(3005, 5, startRequest1);

// Simple request with valid utf-8 message.
var isRequest1Finished = false;
function startRequest1() {
  var request1 = http.request(createOptions(3005), function(response) {
    var str = '';

    response.on('data', function(chunk) {
      str += chunk.toString();
    });

    response.on('end', function() {
      isRequest1Finished = true;
      server1.close();
    });
  });
  request1.end(message, 'utf-8');
}


var server2 = http.createServer(function(request, response) {
  response.end();
});
server2.listen(3006, 5, startRequest2);

// Simple request with end callback.
var isRequest2Finished = false;
function startRequest2() {
  var request2 = http.request(createOptions(3006));
  request2.end(message, function() {
    server2.close();
    isRequest2Finished = true;
  });
}


var server3 = http.createServer(function(request, response) {
  var str = '';

  request.on('data', function(chunk) {
    str += chunk;
  });

  request.on('end', function() {
    // Check if we got the proper message.
    assert.equal(str, message);
    response.end();
  });
});
server3.listen(3007, 5, startRequest3);

// Simple request with buffer chunk as message parameter.
var isRequest3Finished = false;
function startRequest3() {
  var request3 = http.request(createOptions(3007), function(response) {
    var str = '';

    response.on('data', function(chunk) {
      str += chunk;
    });

    response.on('end', function() {
      isRequest3Finished = true;
      server3.close();
    });
  });
  request3.end(new Buffer(message));
}


// This test is to make sure that when the HTTP server
// responds to a HEAD request, it does not send any body.
var server4 = http.createServer(function(request, response) {
  response.writeHead(200);
  response.end();
});
server4.listen(3008, 5, startRequest4);

var isRequest4Finished = false;
function startRequest4() {
  var request4 = http.request({
    method: 'HEAD',
    port: 3008,
    path: '/'
  }, function(response) {
    response.on('end', function() {
      isRequest4Finished = true;
      assert.equal(response.statusCode, 200);
      server4.close();
    });
  });
  request4.end();
}


// Write a header twice in the server response.
var server5 = http.createServer(function(request, response) {
  var str = '';

  request.on('data', function(chunk) {
    str += chunk;
  });

  request.on('end', function() {
    response.writeHead(200, 'OK', {'Connection' : 'close1'});
    // Wrote the same head twice.
    response.writeHead(200, 'OK', {'Connection' : 'close2'});
    // Wrote a new head.
    response.writeHead(200, {'Head' : 'Value'});
    response.end();
  });
});
server5.listen(3009, 5, startRequest5);

var isRequest5Finished = false;
function startRequest5() {
  var options = createOptions(3009)
  options.headers = null;
    var request5 = http.request(options, function(response) {
    response.on('end', function() {
      isRequest5Finished = true;
      assert.equal(response.headers['Connection'], 'close2');
      assert.equal(response.headers['Head'], 'Value');
      server5.close();
    });
  });
  request5.end();
}


// Test the IncomingMessage read function.
var server6 = http.createServer(function(request, response) {
  request.on('end', function() {
    response.end('ok');
    server6.close();
  });
}).listen(8080, 5, startRequest6);

function startRequest6() {
  var readRequest = http.request({
    host: '127.0.0.1',
    port: 8080,
    path: '/',
    method: 'GET'
  });
  readRequest.end();

  readRequest.on('response', function(incomingMessage) {
    incomingMessage.on('readable', function() {
      var inc = incomingMessage.read();
      assert.equal(inc instanceof Buffer, true);
      assert.assert(inc.toString('utf8').length > 0);
    });
  });
}

process.on('exit', function() {
  assert.equal(isRequest1Finished, true);
  assert.equal(isRequest2Finished, true);
  assert.equal(isRequest3Finished, true);
  assert.equal(isRequest4Finished, true);
  assert.equal(isRequest5Finished, true);
});
