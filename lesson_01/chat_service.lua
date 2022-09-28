local skynet = require "skynet"
local socket = require "skynet.socket"

local id_table = {}

local function broadcast(id, msg)
    for id, _table in pairs(id_table) do
        socket.write(id, msg)
    end
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
            if str == "quit" then
                broadcast(id, "============" .. id_table[id].name .. "退出了聊天室============")
                socket.close(id)
                id_table[id] = nil
                return
            end
            if id_table[id] then
                broadcast(id, id_table[id].name .. "说：" .. str)
            else
                print("client info: " .. str)
                id_table[id] = {
                    name = str,
                    addr = addr
                }
                broadcast(id, "============欢迎" .. str .. "来到卿宝的聊天室============")
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
