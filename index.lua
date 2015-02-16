local JSON     = require('json')
local timer    = require('timer')
local http     = require('http')
local boundary = require('boundary')

local __pgk = "BOUNDARY NGINX"
local _previous = {}
local poll = 1000
local host = "localhost"
local port = 80
local path = "/nginx_status"

if (boundary.param ~= nil) then
  poll = boundary.param['poll'] or poll
  host = boundary.param['host'] or host
  port = boundary.param['port'] or port
  path = boundary.param['path'] or path
end

function berror(err)
  if err then print(string.format("%s ERROR: %s", __pgk, tostring(err))) return err end
end

--- do a http request
local doreq = function(host, port, path, cb)
    local output = ""
    local req = http.request({host = host, port = port, path = path}, function (res)
      res:on("error", function(err)
        cb("Error while receiving a response: " .. tostring(err), nil)
      end)
      res:on("data", function (chunk)
        output = output .. chunk
      end)
      res:on("end", function ()
        res:destroy()
        cb(nil, output)
      end)
    end)
    req:on("error", function(err)
      cb("Error while sending a request: " .. tostring(err), nil)
    end)
    req:done()
end


function split(str, delim)
   local res = {}
   local pattern = string.format("([^%s]+)%s()", delim, delim)
   while (true) do
      line, pos = str:match(pattern, pos)
      if line == nil then break end
      table.insert(res, line)
   end
   return res
end


function parse(str)
  return tonumber(str)
end

function diff(a, b)
    if a == nil or b == nil then return 0 end
    return math.max(a - b, 0)
end

function parseStatsText(body)
    --[[
    See http://nginx.org/en/docs/http/ngx_http_stub_status_module.html for body format.
    Sample response:
    Active connections: 1
    server accepts handled requests
     112 112 121
    Reading: 0 Writing: 1 Waiting: 0
    --]]
    local stats = {}
    for i, v in ipairs(split(body, "\n")) do
      if v:find("Active connections:", 1, true) then
        local active, connections = v:gmatch('(%w+):%s*(%d+)')()
        stats[active:lower()] = parse(connections)

      elseif v:match("%s*(%d+)%s+(%d+)%s+(%d+)%s*$") then
        accepts, handled, requests = v:gmatch("%s*(%d+)%s+(%d+)%s+(%d+)%s*$")()
        stats.accepts    = parse(accepts)
        stats.handled    = parse(handled)
        stats.requests   = parse(requests)
        stats.nothandled = stats.accepts - stats.handled

      elseif v:match("(%w+):%s*(%d+)") then
        while true do
          k, va = v:gmatch("(%w+):%s*(%d+)")()
          if not k then break end
          stats[k:lower()] = parse(va)
          v = v:gsub(k, "")
        end
      end
    end
    return stats
end


function printStats(stats)
    local handled               = _previous['handled'] and diff(stats.handled, _previous.handled) or 0
    local requests              = _previous['requests'] and diff(stats.requests, _previous.requests) or 0
    local requestsPerConnection = (requests > 0 and handled) and requests / handled or 0

    _previous = stats

    print(string.format('NGINX_ACTIVE_CONNECTIONS %d', stats.connections))
    print(string.format('NGINX_READING %d', stats.reading))
    print(string.format('NGINX_WRITING %d', stats.writing))
    print(string.format('NGINX_WAITING %d', stats.waiting))
    print(string.format('NGINX_HANDLED %d', handled))
    print(string.format('NGINX_NOT_HANDLED %d', stats.nothandled))
    print(string.format('NGINX_REQUESTS %d', requests))
    print(string.format('NGINX_REQUESTS_PER_CONNECTION %d', requestsPerConnection))

end



print("_bevent:NGINX plugin up : version 1.0|t:info|tags:nginx,lua,plugin")

timer.setInterval(poll, function ()

  doreq(host, port, path, function(err, body)
      if berror(err) then return end
      stats = parseStatsText(body)
      printStats(stats)
  end)

end)




