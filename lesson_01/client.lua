package.cpath = "luaclib/?.so"

if _VERSION ~= "Lua 5.4" then
    error "Use lua 5.4"
end

local socket = require "client.socket"
local fd = assert(socket.connect("101.33.247.191", 8888))
print("卿宝提示您~ 加入聊天室请输入自己的昵称哦！")
print("请在下方输入您的昵称：")

local user_name = nil

while true do
    user_name = socket.readstdin()
    if user_name then
        socket.send(fd, user_name)
        break
    end
end


while true do

    -- 接收服务器返回消息
    local str = socket.recv(fd)
    if str ~= nil and str ~= "" then
        print(str)
    end

    -- 读取用户输入消息
    local readstr = socket.readstdin()
    if readstr then
        socket.send(fd, readstr)
        if readstr == "quit" then
            socket.close(fd)
            break;
        end
    else
        socket.usleep(100)
    end
end
