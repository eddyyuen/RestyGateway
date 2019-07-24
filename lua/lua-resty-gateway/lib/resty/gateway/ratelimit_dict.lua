local limit_req = require "resty.gateway.req"

local lim, err = limit_req.new("ratelimit_req_store")

if not lim then
    ngx.log(ngx.ERR, "failed to instantiate a resty.limit.req object: ", err)
    return ngx.exit(500)
end

local _M = {}

function _M.get( key )
    return lim:get(key)
end
function _M.incr( key,value,expire )
    return lim:set(key,value,expire)
end

return _M