local method = ngx.req.get_method():lower()
local headers = ngx.req.get_headers()
local redis = require "resty.redis"
local cjson = require "cjson"
local jwt = require "luajwt"
local hex = require "hex"

local red = redis:new()
local k, v, auth, ts, user, secret, err, ok, src, digest, bearerToken

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
    bearerToken = v
  end
end

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



-- jwt testing
local args = ngx.req.get_uri_args(1)
if not bearerToken then
    return ngx.say("Where is token?")
end
local key = "SECRET"
local ok, err = jwt.decode(bearerToken, key)
if not ok then
    return ngx.say("Error: ", err)
end

-- check signature matches one on request
if(digest == auth) then
  ngx.say(hex.encode(ngx.hmac_sha1(secret, src)))
else
  ngx.status = ngx.HTTP_UNAUTHORIZED
end