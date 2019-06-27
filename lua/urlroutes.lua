local _M = {}

local jwt_key = "12qyg4coej88uqromo0xdmx4y0il5dn5y7b72tlb3imba677ht1p1xlfcnh36mk5u3xzjktfara29axvzk85apfplun7oslbe1m20c148p5d519kja5wvg7lmn5v4a5ou"

local cache = require "routes_config"
--cache.init()
local url_routes = cache.get("routes")

function _M.match(uri)
	local match_url =nil
	local usejwt = true
	local server_name= ""
	--local server_uri = nil
	local route = ""
	local  server_host = nil
	
	-- 查找URL是否符合正则
	for _, value in ipairs(url_routes) do 
		if not value['route'] or value['route']=='' then
			route = "^"..value["prefix"].."(.*)"
		else
			route = value['route']
		end
		local url_target, err = ngx.re.match(uri, route)
		if  url_target then
			match_url = url_target[1]
			usejwt = value["usejwt"]
			--server_uri=url_routes[key]["server_host"]..match_url.."?"..ngx.var.query_string
			--server_uris =url_routes[key]["server_host"]
			server_name = value["name"]
			if value["host"] ~= nil and value["host"]~="" then
				server_host = value["host"]
			end
			break
		end
		
	end

	--URL不正确
	if not match_url then
		return {false,1,"invaild url"..uri}
	end

	--URL正确，查找JWT是否正确
	if usejwt then
		--判断跳过jwt检测的URL
		local skipjwt = cache.get(server_name.."skipjwt")
		local can_skip_jwt = false
		for _,v in ipairs(skipjwt) do
			if ngx.re.match(uri,v) ~= nil then
				can_skip_jwt = true
				break
			end
		end

		if false == can_skip_jwt then
			-- 获取header
			local headers = ngx.req.get_headers()
			if not headers["Authorization"] then
				return  {false,2,"No Authorization header"}
			end
			local header_token = string.gsub(headers["Authorization"],'bearer ','')

			local cjson = require "cjson"
			local jwt = require "resty.jwt"
			local jwt_obj = jwt:verify(jwt_key, header_token)
			--ngx.say(cjson.encode(jwt_obj))
			if not jwt_obj["verified"] then
				if not jwt_obj["payload"] or not jwt_obj["payload"]["UserId"] then
					return  {false,2,"invalid jwt"}
				end
			end
		end

		 
		
	end

	--取随机数
	--根据随机数获取serveruri
	local server_uris =cache.get(server_name.."hosts")
	local next = tostring(os.time()):reverse():sub(1, 6)
	math.randomseed(next)
	local random_weight = math.random(1,100)
	local server_uri = nil
	if not ngx.var.query_string then
		server_uri = server_uris[random_weight][1]..match_url
	else
		server_uri = server_uris[random_weight][1]..match_url.."?"..ngx.var.query_string
	end

	--全部正确
	return {true,0,server_uri,server_host}


end

 
return _M