local _M = {}

local cache =  require "resty.gateway.cache"
local get_cache = cache.get
local set_cache = cache.set
local ngx_re_find = ngx.re.find
local util = require("resty.gateway.util")

local function url_routes_sort(a,b)
	return a["order_no"] < b["order_no"]

end

-- 根据ratelimit_url的配置返回匹配前缀的table
local function get_ratelimit_key_tab(ratelimit_config)
    local ratelimit_tab ={}
    for k,v in ipairs(ratelimit_config) do 
        ratelimit_tab[k] =v["key"]
    end
    return ratelimit_tab
end


local function get_ratelimit_limit(value,over_time)
    local from , to = ngx_re_find(value,",","jo")
    local limit = tonumber(string.sub(value,1,from-1))
    if limit ~=0 then
        return {
            limit = limit,
            over = over_time,
            block = tonumber(string.sub(value,from+1))
        }
    end
    return nil
end

local function get_ratelimit_limit_tab(value)
    local ratelimit_tab ={}
    local sec_block = get_ratelimit_limit(value["sec_block"],1)
    if sec_block then
        table.insert(ratelimit_tab,sec_block)
    end
    local min_block = get_ratelimit_limit(value["min_block"],60)
    if min_block then
        table.insert(ratelimit_tab,min_block)
    end
    local hour_block = get_ratelimit_limit(value["hour_block"],3600)
    if hour_block then
        table.insert(ratelimit_tab,hour_block)
    end
    local day_block = get_ratelimit_limit(value["day_block"],3600*24)
    if day_block then
        table.insert(ratelimit_tab,day_block)
    end

    return ratelimit_tab
end

-- 初始化数据，不能编辑
local function init(urlroutes)
    table.sort( urlroutes, url_routes_sort )
    local url_prefix = {}
    for k,v in ipairs(urlroutes) do 
        -- 获取所有前缀
        url_prefix[k] = v["url_prefix"]
       
        -- 登记每个路由的信息
        local url_route = {
            url_route = v["url_route"] or "/$1",
            jwt_enable = v["jwt_enable"] or true,
            header_host = v["header_host"] or "",
            order_no = v["order_no"] or 999,
            ratelimit_url_enable = v["ratelimit_url_enable"] or false,
            ratelimit_ip_enable = v["ratelimit_ip_enable"] or false,
        }
        set_cache(v["url_prefix"],url_route)

        -- 接口服务器信息
        local server_host = {}
        local weight_sum = 0
        for key,value in ipairs(v["server_host"]) do
            -- 获取每个服务器的权重进行累计
            weight_sum = weight_sum + value["weight"]
            server_host[key] = { sum = weight_sum,uri = value["uri"]}
        end
        -- 接口服务器列表
        set_cache(util.get_server_host_key(v["url_prefix"]),server_host)
        -- 总权重字段
        set_cache(util.get_server_host_sum_key(v["url_prefix"]),weight_sum)
        -- jwt例外列表
        set_cache(util.get_jwt_ignore_key(v["url_prefix"]),v["jwt_ignore"])
        
        -- 限流的URL设置
        local ratelimit_url_key_tab = get_ratelimit_key_tab(v["ratelimit_url"])
        set_cache(util.get_ratelimit_url_key(v["url_prefix"]),ratelimit_url_key_tab)

        -- 限流的IP设置
        local ratelimit_ip_key_tab = get_ratelimit_key_tab(v["ratelimit_ip"])
        set_cache(util.get_ratelimit_ip_key(v["url_prefix"]),ratelimit_ip_key_tab)

        -- url 限流
        local ratelimit_urls = {}
        for key,value in ipairs(v["ratelimit_url"]) do
            local ratelimit_url =  get_ratelimit_limit_tab(value)
            if #ratelimit_url >0 then
                set_cache(util.get_ratelimit_url_item_key(v["url_prefix"],value["key"]), ratelimit_url) 
            end
            
        end
        

        -- ip 限流
        local ratelimit_ips = {}
        for key,value in ipairs(v["ratelimit_ip"]) do
            local ratelimit_ip =  get_ratelimit_limit_tab(value)
            if #ratelimit_ip >0 then
                set_cache(util.get_ratelimit_ip_item_key(v["url_prefix"],value["key"]), ratelimit_ip) 
            end
        end

    end
    set_cache("url_prefix",url_prefix)
end

_M.init = init
return _M