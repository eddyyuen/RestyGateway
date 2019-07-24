local _M = {}

local jwt = require "resty.jwt"
local jwt_key = "12qyg4coej88uqromo0xdmx4y0il5dn5y7b72tlb3imba677ht1p1xlfcnh36mk5u3xzjktfara29axvzk85apfplun7oslbe1m20c148p5d519kja5wvg7lmn5v4a5ou"
function _M.verify(token)
    -- local jwt = require "resty.jwt"
    -- local jwt_key = "12qyg4coej88uqromo0xdmx4y0il5dn5y7b72tlb3imba677ht1p1xlfcnh36mk5u3xzjktfara29axvzk85apfplun7oslbe1m20c148p5d519kja5wvg7lmn5v4a5ou"
    local jwt_obj = jwt:verify(jwt_key, token)
    if not jwt_obj["verified"] then
       return false
    end
    return true
end

return _M