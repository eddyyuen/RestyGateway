-- Copyright (C) Yichun Zhang (agentzh)
--
-- This library is an approximate Lua port of the standard ngx_limit_req
-- module.

local ngx_shared = ngx.shared
local setmetatable = setmetatable
local tonumber = tonumber
local type = type
local assert = assert


local _M = {
    _VERSION = '0.01'
}


local mt = {
    __index = _M
}


function _M.new(dict_name)
    local dict = ngx_shared[dict_name]
    if not dict then
        return nil, "shared dict not found"
    end
    local self = {
        dict = dict,
    }

    return setmetatable(self, mt)
end


function _M.set(self, key, value,expire)
    local dict = self.dict
    local count
    local v = dict:get(key)
    if v then
        count = v + value
        dict:incr(key,value,0,expire)
    else
        count = value
        dict:set(key, value,expire)
    end
    
    return count , nil
end

function _M.get(self,key)
    local dict = self.dict
    local count = 0
    local v = dict:get(key)
    if v then
        return v,nil
        
    end
    return nil, "key not found"
end

function _M.delete(self, key)
    assert(key)
    local dict = self.dict
    dict:delete(key)
    return true
end

return _M
