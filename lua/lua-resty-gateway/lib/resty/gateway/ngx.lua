local _M = {}
local cjson = require "cjson"

local function text(status_code,message)
	ngx.status = status_code
	ngx.header["content-type"] = "text/plain;charset=utf-8"
	ngx.say(message)
	ngx.exit(ngx.status)
end

local function json_resp(status_code,message)
	ngx.status = status_code
	ngx.header["content-type"] = "application/json;charset=utf-8"
	ngx.say(cjson.encode({returnCode=status_code,message=message}))
	ngx.exit(ngx.status)
end

local function json_tab(status_code,data)
	ngx.status = status_code
	ngx.header["content-type"] = "application/json;charset=utf-8"
	ngx.say(cjson.encode(data))
	ngx.exit(ngx.status)
end


_M.text = text
_M.json_result = json_resp
_M.json = json_tab
return _M