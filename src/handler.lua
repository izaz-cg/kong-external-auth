local BasePlugin = require "kong.plugins.base_plugin"
local http = require "resty.http"
local json = require "cjson"

local kong = kong

local ExternalAuthHandler = BasePlugin:extend()

function ExternalAuthHandler:new()
  ExternalAuthHandler.super.new(self, "external-auth-payment")
end
function print_table(node)
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)

    print(output_str)
end
function ExternalAuthHandler:access(conf)
  ExternalAuthHandler.super.access(self)

  local client = http.new()
  client:set_timeouts(conf.connect_timeout, send_timeout, read_timeout)
  print("~~~~~")
  print("conf.token_header")
  print(conf.token_header)
  print("~~~~~")
  for k, v in pairs(kong.request.get_headers() ) do
    print(k, v)
  end
  print(kong.request.get_header(conf.token_header))
  print_table(kong.request.get_headers())
  local res, err = client:request_uri(conf.url, {
    path = conf.path,
    query = {
      auth_token = kong.request.get_header(conf.token_header)
    },
    headers = {
      Accepts = "application/json",
      Authorization = kong.request.get_header(conf.token_header)
    },
    method = "POST"
  })

  if not res then
    return kong.response.exit(500, {message=err})
  end
  print("res")
  print(res.status)
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
    print(res.body)
    local decoded_body = json.decode(res.body)
    if not decoded_body then
      return kong.response.exit(502, {message="empty authentication response object"})
    end
    
    local user = decoded_body["user"]
    if not user then
      return kong.response.exit(502, {message="no user details in authentication response"})
    end

    kong.service.request.set_header(conf.injection_header, json.encode(user))
  end
end

ExternalAuthHandler.PRIORITY = 900
ExternalAuthHandler.VERSION = "0.2.1"

return ExternalAuthHandler
