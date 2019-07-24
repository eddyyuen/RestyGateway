local _M ={}

local lrucache = require "resty.lrucache"
local cache, err = lrucache.new(200)  -- allow up to 200 items in the cache
local function get(key)
	return cache:get(key)
end

local function set(key,value)
	return cache:set(key,value)
end

local function set_expire(key,value,seconds)
	return cache:set(key,value,seconds)
end

_M.get = get
_M.set = set
_M.set_expire = set_expire
return _M