local method = ngx.req.get_method():lower()
local headers = ngx.req.get_headers()
local redis = require "resty.redis"
local cjson = require "cjson"
--local jwt = require "resty.jwt"

local red = redis:new()
local k, v, auth, ts, user, secret, err, ok, src, digest, jwt

local function isempty(s)
  return s == nil or s == ''
end

-- read headers
for k, v in pairs(headers) do
  if(k == "oneflow-authorization") then
    auth = v
  elseif(k == "oneflow-timestamp") then
    ts = v
  elseif(k == "oneflow-user") then
    user = v
  elseif(k == "bearer-token") then
    jwt = v
  end
end

print(jwt)

if (isempty(auth) or isempty(ts) or isempty(user)) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("bad api request")
    return
end

-- connect to redis
ok, err = red:connect("redis", 6379)
if not ok then
    ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
    ngx.say("failed to connect: ", err)
    return
end

-- lookup user in redis
secret, err = red:get(user)
if not secret then
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say("failed to get user: ", err)
    return
end

-- pool the redis connection
ok, err = red:set_keepalive(10000, 100)
if not ok then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR 
    ngx.say("failed to set keepalive: ", err)
    return
end

-- check user was found
if secret == ngx.null then
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say("user not found.")
    return
end

-- sign the request
src = method .. " " .. ngx.var.uri .. " " .. ts
digest = ngx.encode_base64(ngx.hmac_sha1(secret, src))

-- check signature matches one on request
if(digest == auth) then
  ngx.say(digest)
else
  ngx.status = ngx.HTTP_UNAUTHORIZED
end