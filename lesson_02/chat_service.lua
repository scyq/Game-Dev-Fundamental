require("GameRoleMgr")

local skynet = require "skynet"
local socket = require "skynet.socket"

require("utils")

-- 创建GameRoleMgr服务
local manager = GameRoleMgr:new()
manager:generate_role_list(10000)

-- 处理用户输入的命令包
local function parse_package(package)
    local parsed_packed = Split(package, "##")
    local option = parsed_packed[1]
    local param = parsed_packed[2]
    local str = ""

    -- 获取角色列表数量
    if (option == "1") then
        str = "当前角色数量为：" .. TableLength(manager.role_table)
        -- 请求角色列表
    elseif (option == "2") then
        str = "角色列表为：\n"
        for i = 1, tonumber(param) do
            local role = manager:get_role_by_id(i)
            str = str ..
                "ID: " ..
                role.ID ..
                " Name: " ..
                role.name ..
                " Model ID" .. role.modelID .. " Attack: " .. role.attack .. " Defense: " .. role.defense .. "\n"
        end
        -- 根据ID登录角色
    elseif (option == "3") then
        local role = manager:get_role_by_id(tonumber(param))
        if (role) then
            str = "登陆成功! 登陆信息ID: " ..
                role.ID .. " Name: " .. role.name .. " Model ID: " .. role.modelID .. " Attack: " .. role.attack ..
                " Defense: " .. role.defense
        else
            str = "未找到ID为" .. param .. "的角色"
        end
        -- 根据ID删除角色
    elseif (option == "4") then
        local role = manager:get_role_by_id(tonumber(param))
        if (role) then
            manager:del_role_by_id(tonumber(param))
            str = "删除ID为" .. param .. "的角色成功"
        else
            str = "未找到ID为" .. param .. "的角色"
        end
        -- 获取攻击力排序列表
    elseif (option == "5") then
        local arr = manager:get_att_sort_list()
        local cnt = 0
        str = "攻击力排行榜前十玩家为：\n"
        for k, v in pairs(arr) do
            cnt = cnt + 1
            if (cnt > 10) then
                break
            end
            str = str .. "Rank" .. cnt .. " Name: " .. v.name .. " Attack: " .. v.attack .. "\n"
        end
        -- 获取防御力排序列表
    elseif (option == "6") then
        local arr = manager:get_def_sort_list()
        local cnt = 0
        str = "防御力排行榜前十玩家为：\n"
        for k, v in pairs(arr) do
            cnt = cnt + 1
            if (cnt > 10) then
                break
            end
            str = str .. "Rank" .. cnt .. " Name: " .. v.name .. " Defense: " .. v.defense .. "\n"
        end
    elseif (option == "7") then
        str = "攻击力排行榜前" .. param .. "玩家为：\n"
        local arr = manager:get_att_sort_list()
        for i = 1, tonumber(param) do
            local role = arr[i]
            str = str ..
                "ID: " ..
                role.ID ..
                " Name: " ..
                role.name ..
                " Model ID" .. role.modelID .. " Attack: " .. role.attack .. " Defense: " .. role.defense .. "\n"
        end
    elseif (option == "8") then
        str = "防御力排行榜前" .. param .. "玩家为：\n"
        local arr = manager:get_def_sort_list()
        for i = 1, tonumber(param) do
            local role = arr[i]
            str = str ..
                "ID: " ..
                role.ID ..
                " Name: " ..
                role.name ..
                " Model ID" .. role.modelID .. " Attack: " .. role.attack .. " Defense: " .. role.defense .. "\n"
        end
    else
        str = "未知命令"
    end


    return str, option

end

-- 接收到客户端连接或收到客户端消息
local function handle_client(id, addr)
    print("connect from " .. addr .. " " .. id)
    skynet.error("handle_client service", coroutine.running())
    -- 任何一个服务只有在调用 socket.start(id) 之后，才可以收到这个 socket 上的数据。
    socket.start(id)
    while true do
        local str = socket.read(id)
        if str then
            local res, option = parse_package(str)
            print(res)
            socket.write(id, res)
            if option == "q" then
                socket.close(id)
                return
            end
        else
            print("handle_client-- over")
            socket.close(id)
            return
        end
    end
end

-- 启动服务器
function start_server()
    print("==========Socket Start=========")
    -- 监听一个端口，返回一个 id ，供 start 使用。
    local srv_id = socket.listen("0.0.0.0", 8888)
    print("Listen socket :", "0.0.0.0", 8888)

    socket.start(srv_id, handle_client)
end

-- 启动服务器
skynet.start(start_server)
