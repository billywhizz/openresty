"use strict";
/*jshint asi: true, browser: false, devel: false, debug: true, evil: true, forin: true, es5: false, undef: true, node: true, bitwise: true, eqnull: true, noarg: true, noempty: true, eqeqeq: true, boss: true, loopfunc: true, laxbreak: true, strict: true, curly: false, nonew: true, jquery: false */
var crypto = require("crypto")
var redis = require("redis")
var client = redis.createClient()
var server = require("http").createServer(function(req, res) {
  var user = req.headers["oneflow-user"]
  var auth = req.headers["oneflow-authorization"]
  var ts = req.headers["oneflow-timestamp"]
  if(!(user && auth && ts)) {
    res.statusCode = 400
    return res.end()
  }
  var StringToSign = req.method.toLowerCase() + " " + req.url + " " + ts
  client.get(user, function(err, secret) {
    if(err) {
      res.statusCode = 401
      return res.end()
    }
    var hmac = crypto.createHmac("SHA1", secret)
    hmac.update(StringToSign)
    var digest = hmac.digest("base64")
    if(auth == digest) {
      res.end(digest)
    }
    else {
      res.statusCode = 401
      return res.end()
    }
  })
})

server.listen(8081);