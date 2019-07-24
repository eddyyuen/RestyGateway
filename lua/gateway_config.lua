-- Copyright (C) Eddy Yuen

-- 路由信息，可编辑
local url_routes = {
    {
        -- http://api.scigeeker.com/
        -- URL的正则表达式，匹配成功即采用本条规则
        url_prefix="^/api/(.*)$",
        -- 实际访问接口服务器的URL地址
        url_route="/$1",
        -- 后端服务器地址。weight是权重，权重越高，访问频率越高。0为不访问。
        server_host={
            {uri ="http://api.scigeeker.com",weight=100}
        },
        -- 是否启用jwt
        jwt_enable=true,
        -- JWT URL例外列表，不进行jwt验证
        jwt_ignore={
            "^/api/",
            "^/api/sy",
        },
        -- 是否移动流量限制
        ratelimit_url_enable = true, 
        ratelimit_url={
            -- 根据URL限制流量
            -- * 表示默认，如果其他规则没有匹配成功，就采用默认规则
            -- sec_block 每秒访问限制与屏蔽时间。 10，0 表示每秒最大访问量10次，屏蔽时间0秒
            {key="^/api/user/getlogin.*",sec_block="0,0",min_block="1,0",hour_block="0,0",day_block="0,0"},
            {key=".*",sec_block="3,10",min_block="5,0",hour_block="1000,0",day_block="9000,0"},
        }, 
        ratelimit_ip_enable = true, 
        ratelimit_ip={
            -- 根据访问者的IP限制流量            
            {key="^127\\.0\\.0\\.1$",sec_block="0,10",min_block="3,0",hour_block="0,0",day_block="0,0"},
            {key=".*",sec_block="1,11",min_block="600,0",hour_block="1000,10",day_block="9000,900"},
        },
        header_host="api.scigeeker.com",
        order_no = 1
    },
    {
        -- http://api.scut.scigeeker.com/
        url_prefix="^/api-scut/(.*)$",
        url_route="/$1",
        server_host={
            {uri ="http://api.scut.scigeeker.com",weight=100}
        },
        jwt_enable=true,
        jwt_ignore={
            "^/api-scut/.*",
        },
        -- 是否移动流量限制
        ratelimit_url_enable = true, 
        ratelimit_url={
            {key=".*",sec_block="300,0",min_block="0,0",hour_block="0,0",day_block="0,0"},
        }, 
        ratelimit_ip_enable = true, 
        ratelimit_ip={         
            {key="^127\\.0\\.0\\.1$",sec_block="10000,0",min_block="0,0",hour_block="3000,0",day_block="0,0"},
            {key=".*",sec_block="50,0",min_block="0,0",hour_block="0,0",day_block="0,0"},
        },
        header_host="api.scut.scigeeker.com",
        order_no = 2
    },
}

-- 以下不能修改
local config = require("resty.gateway.config")
config.init(url_routes)