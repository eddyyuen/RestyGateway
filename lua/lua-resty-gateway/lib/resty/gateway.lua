-- Copyright (C) Eddy Yuen

local _M = { _VERSION = "0.0.1" }

--local match = require "urlroutes"
local util = require "resty.gateway.util"
local cjson = require "cjson"
local cache =  require "resty.gateway.cache"
local gateway_jwt = require "resty.gateway.jwt"
local gateway_ngx= require "resty.gateway.ngx"
local gateway_req = require "resty.gateway.ratelimit_dict"

local ngx_var = ngx.var
local ngx_req = ngx.req
local ngx_re_find = ngx.re.find
local ngx_re_sub = ngx.re.sub

local get_cache = cache.get
local set_cache = cache.set
local set_cache_expire = cache.set_expire

local ngx_exit_json = gateway_ngx.json_result
local ngx_exit_text = gateway_ngx.text
local ngx_exit_json_tab = gateway_ngx.json


local function request(uri,req_method,headers,body)

	
	local tab_url_prefix = get_cache("url_prefix")
 
	local prefix_url
	--检查URL是否在规则内
	for _,v in ipairs(tab_url_prefix) do
		local from , to = ngx_re_find(uri,v,"jo")
		if from then
			prefix_url = v
		end
	end
	 
	-- URL没有匹配成功返回 404 错误
	if not prefix_url  then
		ngx_exit_json(ngx.HTTP_NOT_FOUND,uri.."url route not found")
		-- ngx.status = ngx.HTTP_NOT_FOUND
		-- ngx.say(cjson.encode({returnCode=404,message=uri.."url route not found"}))
		-- ngx.exit(ngx.HTTP_NOT_FOUND)
		return
	end


	local urlroute = get_cache(prefix_url)

	local remote_addr = ngx_var.remote_addr or "0.0.0.0"
	local ip_block_time,err = gateway_req.get(util.get_ratelimit_ip_block_key(prefix_url,remote_addr))
	if ip_block_time then
		-- 被屏蔽
		ngx_exit_json(ngx.HTTP_TOO_MANY_REQUESTS,string.format("客户端访问频率过高，已到达调用上限，已被禁止访问%s秒。请稍后再试", ip_block_time))
		return
	end

	local url_block_time,_ = gateway_req.get(util.get_ratelimit_url_block_key(prefix_url,"_url_"))
	if url_block_time then
		-- 被屏蔽
		ngx_exit_json(ngx.HTTP_TOO_MANY_REQUESTS,string.format("2.接口访问频率过高，已到达调用上限，暂停服务%s秒。请稍后再试", url_block_time))
		return
	end

	-- IP限流
	if urlroute["ratelimit_ip_enable"]  then
		local ratelimit_ip_key = get_cache(util.get_ratelimit_ip_key(prefix_url))
		if ratelimit_ip_key then
			for k,v in ipairs(ratelimit_ip_key) do				
				local from , to = ngx_re_find(remote_addr,v,"jo") 
				if from then
					
					-- 是否被屏蔽
					-- local block_time = get_cache(util.get_ratelimit_ip_block_key(prefix_url,remote_addr))
					-- TODO 共享内存字典
					-- local block_time,err = gateway_req.get(util.get_ratelimit_ip_block_key(prefix_url,remote_addr))
					-- if block_time then
					-- 	-- 被屏蔽
					-- 	ngx_exit_json(ngx.HTTP_TOO_MANY_REQUESTS,string.format("客户端访问频率过高，已到达调用上限，已被禁止访问%s秒。请稍后再试", block_time))
					-- end

					
					-- 获取流量计数
					local ratelimit_roles =  get_cache(util.get_ratelimit_ip_item_key(prefix_url,v))
					if ratelimit_roles then
						for key,value in ipairs(ratelimit_roles) do
							-- 循环判断限流规则
							local limit = value["limit"]
							local over = value["over"]
							local block = value["block"]
							-- ngx_exit_text(200,limit..over..block)
							-- 获取限制流量数字
							-- local ratelimit_ip_count =  get_cache(util.get_ratelimit_ip_limit_key(prefix_url,remote_addr,over))
							-- TODO 共享内存字典
							local ratelimit_ip_count,_=  gateway_req.get(util.get_ratelimit_ip_limit_key(prefix_url,remote_addr,over))
							if not ratelimit_ip_count then
								ratelimit_ip_count = 0
							end
							ratelimit_ip_count = ratelimit_ip_count +1
							-- ngx_exit_text(200,ratelimit_ip_count)
							if ratelimit_ip_count > limit then
								-- 超流量
								if block > 0 then
									-- set_cache_expire(util.get_ratelimit_ip_block_key(prefix_url,remote_addr),1,block)

									gateway_req.incr(util.get_ratelimit_ip_block_key(prefix_url,remote_addr),block,block)

									ngx_exit_json(ngx.HTTP_TOO_MANY_REQUESTS,string.format("客户端访问频率过高，已到达调用上限，已被禁止访问。%s/%s/%s",limit,over,block))
									return
									
								else
									ngx_exit_json(ngx.HTTP_TOO_MANY_REQUESTS,string.format("客户端访问频率过高，已到达调用上限。%s/%s/%s",limit,over,block))
									return
									
								end
								
							end
							-- set_cache_expire(util.get_ratelimit_ip_limit_key(prefix_url,remote_addr,over),ratelimit_ip_count,over)
							gateway_req.incr(util.get_ratelimit_ip_limit_key(prefix_url,remote_addr,over),1,over)
						end
					end
					-- 跳出循环，只使用一个规则
					break

				end
			end
		end
	end

	-- 获取URL限流列表
	if urlroute["ratelimit_url_enable"]  then
		local ratelimit_url_key = get_cache(util.get_ratelimit_url_key(prefix_url))
		if ratelimit_url_key then
			for k,v in ipairs(ratelimit_url_key) do
				local from , to = ngx_re_find(uri,v,"jo") 
				if from then
					-- 是否被屏蔽
					-- local block_time = get_cache(util.get_ratelimit_url_block_key(prefix_url,v))
					-- TODO 共享内存字典
					-- local block_time,_ = gateway_req.get(util.get_ratelimit_url_block_key(prefix_url,v))

					-- if block_time then
					-- 	-- 被屏蔽
					-- 	ngx_exit_json(ngx.HTTP_TOO_MANY_REQUESTS,string.format("2.接口访问频率过高，已到达调用上限，暂停服务%s秒。请稍后再试", block_time))
						
					-- end

					-- TODO 获取流量计数
					local ratelimit_roles =  get_cache(util.get_ratelimit_url_item_key(prefix_url,v))
					if ratelimit_roles then
						for key,value in ipairs(ratelimit_roles) do
							-- 循环判断限流规则
							local limit = value["limit"]
							local over = value["over"]
							local block = value["block"]
							-- ngx.log(ngx.ERR,limit..over..block)
							-- 获取限制流量数字
							-- local ratelimit_url_count =  get_cache(util.get_ratelimit_url_limit_key(prefix_url,v,over))
							-- TODO 共享内存字典 流量数量
							local ratelimit_url_count,err = gateway_req.get(util.get_ratelimit_url_limit_key(prefix_url,v,over))

							if not ratelimit_url_count then
								ratelimit_url_count = 0
							-- 	ngx.log(ngx.ERR,err)
							-- else
							-- 	ngx.log(ngx.ERR,"ratelimit_url_count："..ratelimit_url_count)
							end
							-- ngx.log(ngx.ERR,"ratelimit_url_count "..ratelimit_url_count)
							ratelimit_url_count = ratelimit_url_count +1
							if ratelimit_url_count > limit then
								-- 超流量
								if block > 0 then
									-- set_cache_expire(util.get_ratelimit_url_block_key(prefix_url,v),1,block)
									-- TODO 
									local ret,err = gateway_req.incr(util.get_ratelimit_url_block_key(prefix_url,"_url_"),block,block)
									-- if not ret then ngx.log(ngx.ERR,err) end

									ngx_exit_json(ngx.HTTP_TOO_MANY_REQUESTS,string.format("1.接口访问频率过高，已到达调用上限，暂停服务%s秒。请稍后再试。%s/%s/%s",limit,over,block))
								else
									ngx_exit_json(ngx.HTTP_TOO_MANY_REQUESTS,string.format("接口访问频率过高，已到达调用上限。请稍后再试。%s/%s/%s",limit,over,block))
								end
								
							end
							-- set_cache_expire(util.get_ratelimit_url_limit_key(prefix_url,v,over),ratelimit_url_count,over)
							-- TODO 
							local ret,err = gateway_req.incr(util.get_ratelimit_url_limit_key(prefix_url,v,over),1,over)
							-- if not ret then ngx.log(ngx.ERR,err) end
						end
					end
				
					-- 跳过其他的规则。即只使用第一条匹配的规则
					break
				end
			end
		end
	end



	-- 处理 host url
	
	local new_path,_,_ = ngx_re_sub(uri,prefix_url,urlroute["url_route"])
	if not new_path then
		ngx_exit_json(ngx.HTTP_BAD_GATEWAY,"Gateway Config Error")
		-- ngx.status = ngx.HTTP_BAD_GATEWAY
		-- ngx.say(cjson.encode({returnCode=571,message="Gateway Config Error"}))
		-- ngx.exit(ngx.status)
		return
	end

	-- 处理 request headers
	local _headers = {}
	-- for k,v in pairs(headers) do
	-- 	if k ~= "transfer-encoding" and k ~= "connection" and k ~= "host" then
	-- 		_headers[k] =v
	-- 	end
	-- end

	_headers["accept"] =headers["accept"] or "*/*"
	_headers["cache-control"] =headers["cache-control"] or "no-cache"
	_headers["accept-encoding"] =headers["accept-encoding"] or "*"
	_headers["user-agent"] =headers["user-agent"]
	_headers["content-type"] =headers["content-type"] or "application/json"

	if urlroute["header_host"] ~="" then
		_headers["host"] =urlroute["header_host"]
	end


	-- 处理是否需要jwt检查
	if urlroute["jwt_enable"] then
		local skip_jwt = false
		local jwt_ignore_tab = get_cache(util.get_jwt_ignore_key(prefix_url))
		for k,v in ipairs(jwt_ignore_tab) do
			local from , to = ngx_re_find(uri,v,"jo")
			if from then 
				skip_jwt = true 
				break
			end
		end
		if not skip_jwt then
			local header_authorization = headers["Authorization"]
			if not header_authorization then
				ngx_exit_json(ngx.HTTP_FORBIDDEN,"Request Forbidden")
				-- ngx.status= ngx.HTTP_FORBIDDEN 
				-- ngx.say(cjson.encode({returnCode=2,message="Request Forbidden"}))
				-- ngx.exit(ngx.status)
				-- return
			end
			local header_token = string.gsub(header_authorization,'bearer ','')
		 
			if gateway_jwt.verify(header_token) == false then
				ngx_exit_json(ngx.HTTP_UNAUTHORIZED,"Token Error")
				-- ngx.status= ngx.HTTP_UNAUTHORIZED 
				-- ngx.say(cjson.encode({returnCode=2,message="Token Error"}))
				-- ngx.exit(ngx.status)
				-- return
			end
		 
		end

	end
	

	
	-- 获取访问的Server
	local servers = get_cache(util.get_server_host_key(prefix_url))
	local server_host_sum =get_cache(util.get_server_host_sum_key(prefix_url))	
	local random_num = util.random(1,server_host_sum)
	local host_uri
	for k,server in ipairs(servers) do		
		if random_num <= server["sum"] then
			host_uri = server["uri"]
			break
		end
	end

	-- TODO SERVER限流

	
	if ngx_var.query_string then
		host_uri = string.format("%s%s%s%s",host_uri ,new_path,"?",ngx_var.query_string)
	else
		host_uri = string.format("%s%s",host_uri ,new_path)
	end
	
 
	-- 访问接口
	local http = require "resty.http"
	local httpc = http.new()
	httpc:set_timeout(30000)
	local res, err = httpc:request_uri(host_uri,{
	    method = req_method,
	    body=body,
		headers = _headers,
		ssl_verify = false
	    -- keepalive_timeout = 60,
	    -- keepalive_pool = 10
	  })
	if not res then
		ngx_exit_json(ngx.HTTP_GATEWAY_TIMEOUT ,err)
		-- ngx.say("failed to request: ", err)
		return
	end
	-- 返回数据
	-- ngx.status = res.status_code
	ngx.status = res.status

	--获取响应信息
	--响应头中的Transfer-Encoding和Connection可以忽略，因为这个数据是当前server输出的。
	for k,v in pairs(res.headers) do
		if k ~= "Transfer-Encoding" and k ~= "Connection" then
				ngx.header[k] =v
		end
	end

	ngx.say(res.body)
	-- httpc.close()
end


-- Request Method & body & args
local function get_reponese()
	local request_method = ngx_var.request_method
	local request_args , request_body 
	if  "POST" == request_method then
		ngx_req.read_body()
		request_args = ngx_req.get_post_args()
	    request_body = ngx_req.get_body_data()
	elseif "GET" == request_method then
		request_args = ngx_req.get_uri_args()
	end
	local headers = ngx_req.get_headers()
	local uri = string.lower(ngx_var.uri)
	request(uri,request_method,headers,request_body)
end

local function url_routes_sort(a,b)
	return a["order_no"] < b["order_no"]

end

-- 初始化路由信息
local function init(urlroutes)
	-- set_cache("routes",url_routes)
	table.sort( urlroutes, url_routes_sort )
	local url_prefix = {}
	for k,v in ipairs(urlroutes) do 
		url_prefix[k] = v["url_prefix"]
		local url_route = {
			url_route = v["url_route"],
			jwt_enable = v["jwt_enable"],
			header_host = v["header_host"],
			order_no = v["order_no"],
		}
		set_cache(v["url_prefix"],url_route)

		local server_host = {}
		local weight_sum = 0
		for key,value in ipairs(v["server_host"]) do
			weight_sum = weight_sum + value["weight"]
			server_host[key] = { sum = weight_sum,uri = value["uri"]}
		end
		set_cache(v["url_prefix"].."_server_host",server_host)
		set_cache(v["url_prefix"].."_server_host_sum",weight_sum)
		set_cache(v["url_prefix"].."_jwt_ignore",v["jwt_ignore"])
	end
	set_cache("url_prefix",url_prefix)
	
end



_M.get_reponese = get_reponese
_M.init =init
return _M