local _M ={}

local lrucache = require "resty.lrucache"
local c, err = lrucache.new(100)  -- allow up to 200 items in the cache
if not c then
  --  ngx.say("failed to create the cache: " .. (err or "unknown"))
    ngx.exit(200)
end

local url_routes = {
	{
		name="api",
		prefix="/api/",
		route="",
		server_host={
			server01 = {uri ="http://api.scigeeker.com/",weight=100},
		},
		skipjwt={
			"^/api/get",
			"^/api/sy",
		},
		host="",
		usejwt=true
	},
	{
		name="wxapi",
		prefix="/wxapi/",
		route="",
		server_host={
			server03 = {uri ="http://wxapi.scigeeker.com/",weight=100},
		},
		skipjwt={},
		host="wxapi.scigeeker.com",
		usejwt=false
	},
	{
		name="api_gdqy",
		prefix="/api-gdqy/",
		route="",
		server_host={
			server04 = {uri ="http://api.gdgy.scigeeker.com/",weight=100},
		},
		skipjwt={},
		host="api.gdgy.scigeeker.com",
		usejwt=false,
		orderno=30
	},
	{
		name="api_sysu",
		prefix="/api-sysu/",
		route="",
		server_host={
			server04 = {uri ="http://api.sysu.scigeeker.com/",weight=100},
		},
		skipjwt={},
		host="api.sysu.scigeeker.com",
		usejwt=false,
		orderno=40
	},
	{
		name="api_gzhmu",
		prefix="/api-gzhmu/",
		route="",
		server_host={
			server04 = {uri ="http://api.gzhmu.scigeeker.com/",weight=100},
		},
		skipjwt={},
		host="api.gzhmu.scigeeker.com",
		usejwt=false,
		orderno=50
	},
	{
		name="api_gzhu",
		prefix="/api-gzhu/",
		route="",
		server_host={
			server04 = {uri ="http://api.gzhu.scigeeker.com/",weight=100},
		},
		skipjwt={},
		host="api.gzhu.scigeeker.com",
		usejwt=false,
		orderno=60
	},
	{
		name="api_scut",
		prefix="/api-scut/",
		route="",
		server_host={
			server04 = {uri ="http://api.scut.scigeeker.com/",weight=100},
		},
		skipjwt={},
		host="api.scut.scigeeker.com",
		usejwt=false,
		orderno=70
	},
	{
		name="api_dev",
		prefix="/api-dev/",
		route="",
		server_host={
			server04 = {uri ="http://api.dev.scigeeker.com/",weight=100},
		},
		skipjwt={},
		host="api.dev.scigeeker.com",
		usejwt=false,
		orderno=80
	},
	{
		name="api_vending",
		prefix="/api-vending/",
		route="",
		server_host={
			server04 = {uri ="http://api-vending.gzhmu.scigeeker.com/",weight=100},
		},
		skipjwt={},
		host="api-vending.gzhmu.scigeeker.com",
		usejwt=false,
		orderno=90
	},
	{
		name="api_an1",
		prefix="/api-an1/",
		route="",
		server_host={
			server04 = {uri ="http://172.18.177.197:9039/",weight=100},
		},
		skipjwt={},
		host="172.18.177.197",
		usejwt=false,
		orderno=100
	},
	{
		name="client_sync",
		prefix="/api-gdqy/",
		route="",
		server_host={
			server04 = {uri ="http://172.18.212.43:9005/",weight=100},
		},
		skipjwt={},
		host="172.18.212.43",
		usejwt=false,
		orderno=110
	},
	{
		name="default",
		prefix="/",
		route="",
		server_host={
			server04 = {uri ="http://127.0.0.1/404/",weight=100},
		},
		skipjwt={},
		host="",
		usejwt=true,
		orderno=120
	},
}


function _M.init()
	c:set("routes",url_routes)
	for k,v in ipairs(url_routes) do 
		local host_weight = {}
		local count =0
		for k1,v1 in pairs(v["server_host"]) do 
			for i=1,v1["weight"] do
				host_weight[count+i] ={v1["uri"],k1}
			end
			count = v1["weight"]

		end
		c:set(v["name"].."hosts",host_weight)
		c:set(v["name"].."skipjwt",v["skipjwt"])
	end
end

function _M.get(key)
	return c:get(key)
end
return _M