-- Copyright (C) Eddy Yuen

local  _M = {}

local function random( min,max)
	local next = tostring(os.time()):reverse():sub(1, 6)
	math.randomseed(next)
	return math.random(min,max)
end

local function get_jwt_ignore_key(prefix_url)
	return prefix_url.."_jwt_ignore"
end

local function get_server_host_key(prefix_url)
	return prefix_url.."_server_host"
end
local function get_server_host_sum_key(prefix_url)
	return prefix_url.."_server_host_sum"
end

local function get_ratelimit_url_key(prefix_url)
	return prefix_url.."_ratelimit_url_key"
end
local function get_ratelimit_ip_key(prefix_url)
	return prefix_url.."_ratelimit_ip_key"
end
 
local function get_ratelimit_url_item_key(prefix_url,key)
	return prefix_url.."_ratelimit_url_"..key
end

local function get_ratelimit_url_block_key(prefix_url,key)
	return prefix_url.."_block_"..key
end

local function get_ratelimit_url_limit_key(prefix_url,key,over)
	return prefix_url.."_ratelimit_url_"..key..over
end


local function get_ratelimit_ip_block_key(prefix_url,ip)
	return prefix_url.."_block_"..ip
end
local function get_ratelimit_ip_item_key(prefix_url,key)
	return prefix_url.."_ratelimit_ip_"..key
end
local function get_ratelimit_ip_limit_key(prefix_url,ip,over)
	return prefix_url.."_ratelimit_ip_"..ip..over
end

_M.random = random
_M.get_jwt_ignore_key = get_jwt_ignore_key
_M.get_server_host_key = get_server_host_key
_M.get_server_host_sum_key = get_server_host_sum_key

_M.get_ratelimit_url_key = get_ratelimit_url_key
_M.get_ratelimit_url_item_key = get_ratelimit_url_item_key
_M.get_ratelimit_url_block_key = get_ratelimit_url_block_key
_M.get_ratelimit_url_limit_key = get_ratelimit_url_limit_key

_M.get_ratelimit_ip_key = get_ratelimit_ip_key
_M.get_ratelimit_ip_block_key = get_ratelimit_ip_block_key
_M.get_ratelimit_ip_item_key=get_ratelimit_ip_item_key
_M.get_ratelimit_ip_limit_key=get_ratelimit_ip_limit_key

return _M