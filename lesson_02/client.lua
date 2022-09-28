package.cpath = "luaclib/?.so"

local online_server = false
local current_folder = "lesson_02" -- 当前文件夹名称，不需要加斜线
if online_server then
    package.path = package.path .. ";/home/ubuntu/Game-dev-fundamental/" .. current_folder .. "/?.lua"
else
    package.path = package.path .. ";/mnt/c/scyq/Game/dev-basic/Game-dev-fundamental/" .. current_folder .. "/?.lua"
end

if _VERSION ~= "Lua 5.4" then
    error "Use lua 5.4"
end

local socket = require "client.socket"
local fd = assert(socket.connect("101.33.247.191", 8888))

require("utils")

local function print_menu()
    print("========== 欢迎使用Game Role管理器 ==========")
    print("输入序号选择功能：")
    print("1. 获取角色列表数量")
    print("2. 请求角色列表")
    print("3. 根据ID登录角色")
    print("4. 根据ID删除角色")
    print("5. 查看攻击力排行榜")
    print("6. 查看防御力排行榜")
    print("7. 请求按攻击力排序的角色列表")
    print("8. 请求按防御力排序的角色列表")
    print("q. 退出")
end

-- 打包用户输入的命令
local function get_user_option()
    -- option是用户输入的命令
    -- param是用户输入的参数
    local option = socket.readstdin()
    local param = nil

    if option == nil then
        return nil
    end

    if option == "1" or option == "5" or option == "6" or option == "q" then
        -- 1 5 6 q不需要额外读取参数，不处理参数
        return option .. "##"
    elseif (option == "2" or option == "3" or option == "4" or option == "7" or option == "8") then
        if option == "2" or option == "7" or option == "8" then
            print("请输入要查询的数量：")
            while param == nil do
                param = socket.readstdin()
            end
        elseif option == "3" then
            print("请输入要登录的角色ID: ")
            while param == nil do
                param = socket.readstdin()
            end
        elseif option == "4" then
            print("请输入要删除的角色ID: ")
            while param == nil do
                param = socket.readstdin()
            end
        end
    else
        print("未知指令")
        return nil
    end

    -- 打包用户的输入，前一段为用户选项，后一段为用户可能提供的参数
    return option .. "##" .. param
end

-- 发回一个ACK
socket.send(fd, "Client Conection OK")
print_menu()

while true do
    -- 读取用户输入消息
    local option = get_user_option()
    if option then
        socket.send(fd, option)
        if Split(option, "##")[1] == "q" then
            print("========== 欢迎下次再来 ==========")
            socket.close(fd)
            break;
        end
    else
        socket.usleep(100)
    end

    -- 接收服务器返回消息
    local str = socket.recv(fd)
    if str ~= nil and str ~= "" then
        os.execute("clear")
        print(str)
        print_menu()
    end
end
