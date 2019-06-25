
--local server_host = "http://127.0.0.1/args/"


local Content_Type = "application/json;charset=utf-8" 
--ngx.say(ngx.var.uri)
--local url_target, err = ngx.re.match(ngx.var.uri, "^/api/([/a-zA-Z-_]*)")
--if not url_target then
--	ngx.say("invalid url ", err)
--	return
--end
--ngx.say("match_value  m[0]:",url_target[0])
--ngx.say("match_value  m[1]:",url_target[1])
local match = require "urlroutes"
local cjson = require "cjson"

local match_ret = match.match(ngx.var.uri)
if match_ret[1] == false then
	if match_ret[2] ==1 then
		ngx.say(cjson.encode({returnCode=3,message = match_ret[3]}))
		ngx.exit(200)
	elseif match_ret[2] ==2 then
		ngx.say(cjson.encode({returnCode=2,token=false}))
		ngx.exit(200)
	end
end

if ngx.var.request_method =="POST" then 
	ngx.req.read_body()
end
local args, err = ngx.req.get_uri_args()

if  err then
		ngx.say("failed to get args: ", err)
		return
end

	local http = require "resty.http"
	local httpc = http.new()
	local res, err = httpc:request_uri(match_ret[3],{
	        method = ngx.var.request_method,
	        body=args.data,
	         headers = {
          		["Content-Type"] = ngx.req.get_headers()["Content-Type"] or Content_Type,
          		["Host"] = match_ret[4] or ngx.var.host
        		},
	        keepalive_timeout = 60,
	        keepalive_pool = 10
	      })
	 if not res then
		ngx.say("failed to request: ", err)
		return
	 end
	ngx.status = res.status
	ngx.header.content_type = res.headers["Content-Type"] or Content_Type
	ngx.say(res.body)
	return


--ngx.status=200
--ngx.header.content_type = "application/json;charset=utf-8"
--ngx.say("ok")
--return
-- ngx.say(ngx.var.request_method)
--ngx.say(ngx.var.host)
--ngx.say(ngx.var.uri)
--ngx.say(ngx.var.query_string)
--ngx.say(ngx.var.remote_addr)
--ngx.say(ngx.var.scheme)





 

