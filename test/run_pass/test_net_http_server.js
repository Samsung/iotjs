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

var assert = require('assert');
var http = require('http');
var Server = http.Server;

var responseCheck = '';
var connectionEvent = 0;
var serverCloseEvent = 0;
var requestEvent = 0;
var responseEvent = 0;
var socketEvent = 0;
// server side code
// server will return the received msg from client
// and shutdown
var server = http.createServer(function (req, res) {

  var body = '';
  var url = req.url;

  req.on('data', function (chunk) {
    body += chunk;
  });

  var endHandler = function () {

    res.writeHead(200, { 'Connection' : 'close',
                         'Content-Length' : body.length
                       });
    res.write(body);
    res.end(function(){
      if(body == 'close server') {
        server.close();
      }
    });
  };

  req.on('end', endHandler);

});

server.on('request', function() {
  requestEvent++;
});

server.on('connection', function() {
  connectionEvent++;
});

server.on('close', function() {
  serverCloseEvent++;
});

server.listen(3001, 3, startTestingPost);


// client side code
// 1. send POST req to server and check response msg
// 2. send GET req to server and check response msg
// 3. send 'close server' msg

// 1. POST req
var msg = 'http request test msg';
var options = {
  method : 'POST',
  port : 3001,
  rejectUnauthorized: false,
  headers : {'Content-Length': msg.length}
};


function startTestingPost() {
  var postResponseHandler = function (res) {
    var res_body = '';

    assert.equal(200, res.statusCode);
    var endHandler = function(){
      assert.equal(msg, res_body);
      responseCheck += '1';
      startTestingGet();
    };
    res.on('end', endHandler);

    res.on('data', function(chunk){
      res_body += chunk.toString();
    });
  };

  var req = http.request(options, postResponseHandler);
  req.on('response', function() {
    responseEvent++;
  });
  req.on('socket', function() {
    socketEvent++;
  });
  req.write(msg);
  req.end();
}

function startTestingGet() {
  // 2. GET req
  options = {
    method : 'GET',
    port : 3001
  };

  var getResponseHandler = function (res) {
    var res_body = '';

    assert.equal(200, res.statusCode);

    var endHandler = function(){
      // GET msg, no received body
      assert.equal('', res_body);
      responseCheck += '2';
      startTestingFinal();
    };
    res.on('end', endHandler);

    res.on('data', function(chunk){
      res_body += chunk.toString();
    });
  };


  var getReq = http.request(options, getResponseHandler);
  getReq.on('response', function() {
    responseEvent++;
  });
  getReq.on('socket', function() {
    socketEvent++;
  });
  getReq.end();
}

function startTestingFinal() {
  // 3. close server req
  var finalMsg = 'close server';
  var finalOptions = {
    method : 'POST',
    port : 3001,
    rejectUnauthorized: false,
    headers : {'Content-Length': finalMsg.length}
  };

  var finalResponseHandler = function (res) {
    var res_body = '';

    assert.equal(200, res.statusCode);

    var endHandler = function(){
      assert.equal(finalMsg, res_body);
      responseCheck += '3';
    };
    res.on('end', endHandler);

    res.on('data', function(chunk){
      res_body += chunk.toString();
    });
  };

  var finalReq = http.request(finalOptions, finalResponseHandler);
  finalReq.on('response', function() {
    responseEvent++;
  });
  finalReq.on('socket', function() {
    socketEvent++;
  });
  finalReq.write(finalMsg);
  finalReq.end();
}

// Create server without requestListener.
var server2 = http.createServer();

// Create server instance without new keyword.
var server3 = Server(function(request, response) {});

process.on('exit', function() {
  assert.equal(responseCheck.length, 3);
  assert.equal(connectionEvent, 3);
  assert.equal(serverCloseEvent, 1);
  assert.equal(requestEvent, 3);
  assert.equal(responseEvent, 3);
  assert.equal(socketEvent, 3);
  assert.equal(server2 instanceof Server, true);
  assert.equal(server3 instanceof Server, true);
});
