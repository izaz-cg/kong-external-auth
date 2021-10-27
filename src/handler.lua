local BasePlugin = require "kong.plugins.base_plugin"
local http = require "resty.http"
local json = require "cjson"

local kong = kong

local ExternalAuthHandler = BasePlugin:extend()

function ExternalAuthHandler:new()
  ExternalAuthHandler.super.new(self, "external-auth")
end

function ExternalAuthHandler:access(conf)
  ExternalAuthHandler.super.access(self)

  local client = http.new()
  client:set_timeouts(conf.connect_timeout, send_timeout, read_timeout)

  local res, err = client:request_uri(conf.url, {
    path = conf.path,
    query = {
      "auth_token": conf.token_header
    },
    headers = {
      ["Accepts"] : "application/json"
    },
    method = "GET"
  })

  if not res then
    return kong.response.exit(500, {message=err})
  end

  if res.status == 403 then
    return kong.response.exit(403, {message=conf.message_403})
  elseif res.status == 404 then
    return kong.response.exit(404, {message=conf.message_404})
  elseif res.status ~= 200 then
    return kong.response.exit(401, {message=conf.message_401})
  else
    kong.service.request.set_header(conf.injection_header, res.body)
  end
end

ExternalAuthHandler.PRIORITY = 900
ExternalAuthHandler.VERSION = "0.2.1"

return ExternalAuthHandler
