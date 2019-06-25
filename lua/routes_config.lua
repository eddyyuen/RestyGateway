local _M ={}

local lrucache = require "resty.lrucache"
local c, err = lrucache.new(100)  -- allow up to 200 items in the cache
if not c then
  --  ngx.say("failed to create the cache: " .. (err or "unknown"))
    ngx.exit(200)
end

local url_routes = {
	api =  {
		prefix="/api/",
		route="",
		server_host={
			server01 = {uri ="http://api.scigeeker.com/",weight=100},
		},
		host="api.scigeeker.com",
		usejwt=false
	},
	wxapi = {
		prefix="/wxapi/",
		route="",
		server_host={
			server03 = {uri ="http://wxapi.scigeeker.com/",weight=100},
		},
		host="wxapi.scigeeker.com",
		usejwt=false
	},
	api_gdqy = {
		prefix="/api-gdqy/",
		route="",
		server_host={
			server04 = {uri ="http://api.gdgy.scigeeker.com/",weight=100},
		},
		host="api.gdgy.scigeeker.com",
		usejwt=false
	},
	api_sysu = {
		prefix="/api-sysu/",
		route="",
		server_host={
			server04 = {uri ="http://api.sysu.scigeeker.com/",weight=100},
		},
		host="api.sysu.scigeeker.com",
		usejwt=false
	},
	api_gzhmu = {
		prefix="/api-gzhmu/",
		route="",
		server_host={
			server04 = {uri ="http://api.gzhmu.scigeeker.com/",weight=100},
		},
		host="api.gzhmu.scigeeker.com",
		usejwt=false
	},
	api_gzhu = {
		prefix="/api-gzhu/",
		route="",
		server_host={
			server04 = {uri ="http://api.gzhu.scigeeker.com/",weight=100},
		},
		host="api.gzhu.scigeeker.com",
		usejwt=false
	},
	api_scut = {
		prefix="/api-scut/",
		route="",
		server_host={
			server04 = {uri ="http://api.scut.scigeeker.com/",weight=100},
		},
		host="api.scut.scigeeker.com",
		usejwt=false
	},
	api_dev = {
		prefix="/api-dev/",
		route="",
		server_host={
			server04 = {uri ="http://api.dev.scigeeker.com/",weight=100},
		},
		host="api.dev.scigeeker.com",
		usejwt=false
	},
	api_vending = {
		prefix="/api-vending/",
		route="",
		server_host={
			server04 = {uri ="http://api-vending.gzhmu.scigeeker.com/",weight=100},
		},
		host="api-vending.gzhmu.scigeeker.com",
		usejwt=false
	},
	api_an1= {
		prefix="/api-an1/",
		route="",
		server_host={
			server04 = {uri ="http://172.18.177.197:9039/",weight=100},
		},
		host="172.18.177.197",
		usejwt=false
	},
	client_sync = {
		prefix="/api-gdqy/",
		route="",
		server_host={
			server04 = {uri ="http://172.18.212.43:9005/",weight=100},
		},
		host="172.18.212.43",
		usejwt=false
	},
	default = {
		prefix="/",
		route="",
		server_host={
			server04 = {uri ="http://127.0.0.1/404/",weight=100},
		},
		host="",
		usejwt=true
	},
}


function _M.init()
	c:set("routes",url_routes)
	for k,v in pairs(url_routes) do 
		c:set(k,v)
		local host_weight = {}
		local count =0
		for k1,v1 in pairs(v["server_host"]) do 
			for i=1,v1["weight"] do
				host_weight[count+i] ={v1["uri"],k1}
			end
			count = v1["weight"]

		end
		c:set(v["prefix"].."hosts",host_weight)
	end
end

function _M.get(key)
	return c:get(key)
end
return _M