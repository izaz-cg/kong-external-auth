local BasePlugin = require "kong.plugins.base_plugin"
local http = require "resty.http"
local json = require "cjson"

local kong = kong

local ExternalAuthHandler = BasePlugin:extend()

function ExternalAuthHandler:new()
  ExternalAuthHandler.super.new(self, "external-auth")
end

function get_company_id()
  local company_id = kong.request.get_query_arg("company_id")
  if not company_id then
    local body, err, mimetype = kong.request.get_body()
    if body then
      if mimetype == "application/json" then
        company_id = body.company_id
      else
        if mimetype == "multipart/form-data" then
          company_id = body.company_id
        end
      end
    end
  end
  return company_id
end

function has_value(tab, val)
  for index, value in ipairs(tab) do
    if value == val then
        return true
    end
  end
  return false
end

function ExternalAuthHandler:access(conf)
  ExternalAuthHandler.super.access(self)

  local client = http.new()
  client:set_timeouts(conf.connect_timeout, send_timeout, read_timeout)
  local company_id = get_company_id()

  local res, err = client:request_uri(conf.url, {
    path = conf.path,
    query = {
      auth_token = kong.request.get_header(conf.token_header),
      company_id = company_id,
      ip_address = kong.client.get_ip()
    },
    headers = {
      Accepts = "application/json",
      referer = kong.request.get_header("referer")
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
    if not res.body then
      return kong.response.exit(502, {message="no authentication response"})
    end

    local decoded_body = json.decode(res.body)
    if not decoded_body then
      return kong.response.exit(502, {message="empty authentication response object"})
    end
    
    local user = decoded_body["output"]
    if not user then
      return kong.response.exit(502, {message="no user details in authentication response"})
    end

    kong.service.request.set_header(conf.injection_header, json.encode(user))
    if kong.request.get_header(conf.masking_header) then 
      kong.service.request.set_header(conf.masking_header, kong.request.get_header(conf.masking_header))
    end
    
    if decoded_body["company_details"] then
        kong.service.request.set_header(conf.company_injection_header, json.encode(decoded_body["company_details"]))
    end

    if kong.request.get_path() == "/recovery/portfolio" and has_value(conf.new_portfolio_company_id, company_id) then
      return kong.response.exit(301, 'page moved - redirecting...', {['Location'] = conf.portfolio_url .. "/portfolio/v1/loan?" .. kong.request.get_raw_query()})
    end

    if kong.request.get_path() == "/recovery/portfolio" and has_value(conf.new_credit_line_portfolio_company_id, company_id) then
      return kong.response.exit(301, 'page moved - redirecting...', {['Location'] = conf.portfolio_url .. "/portfolio/v1/credit-line?" .. kong.request.get_raw_query()})
    end
  end
end

ExternalAuthHandler.PRIORITY = 900
ExternalAuthHandler.VERSION = "0.2.1"

return ExternalAuthHandler
