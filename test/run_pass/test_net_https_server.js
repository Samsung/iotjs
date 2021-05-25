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
var https = require('https');
var fs = require('fs');

var server_options = {
  key: fs.readFileSync(process.cwd() + '/resources/my_key.key').toString(),
  cert: fs.readFileSync(process.cwd() + '/resources/my_crt.crt').toString()
};

var server = https.createServer(server_options, function(req, res) {
  res.writeHead(200);
  res.end('hello world\n');
}).listen(8000, startTesting);


var client_options = {
  host: 'localhost',
  port: 8000,
  rejectUnauthorized: false
}

var responseHandler = function (res) {
  var res_body = '';

  assert.equal(200, res.statusCode);

  var endHandler = function(){
    assert.equal(res_body, 'hello world\n');
    server.close();
  };
  res.on('end', endHandler);

  res.on('data', function(chunk){
    res_body += chunk.toString();
  });
}

function startTesting() {
  https.get(client_options, responseHandler);
}
