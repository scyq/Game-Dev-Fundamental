-- Coding Format : UTF-8

-- 「WatchDog.lua 脚本介绍」
-- WatchDog，正如其字面意思，扮演了“看门狗”的角色，负责蹲在大门口，看有没有新玩家过来
-- 玩家通过服务器IP地址+端口号，来接入服务器，而WatchDog就在服务器里一直盯着这个端口看，如果从端口收到请求，就进行处理


local skynet = require "skynet"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local host
local proto_pack
local CMD = {}
local SOCKET = {}
local gate
local agent = {}
local frame_actions = {}
local action_cache = {}
local current_frame = 0

local lastTime = 0
local totalTime = 0
local totalFrame = 0

-- SOCKET.open是系统调用，在新客户端申请接入时自动调用
function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)

	-- 为新玩家分配一个agent
	agent[fd] = skynet.newservice("agent")

	-- 启动新玩家的agent
	skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
end

-- 关闭agent
local function close_agent(fd)
	local a = agent[fd]
	skynet.error(">>>>>close_agent>>>>" .. fd)
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		skynet.send(a, "lua", "disconnect", fd)
	end
end

-- 断开连接
function SOCKET.close(fd)
	print("socket close", fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error", fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open", conf)
end

function CMD.close(fd)
	close_agent(fd)
end

-- 消息广播函数
-- package : 要发送的数据包
-- fd      : 要屏蔽的客户端
-- 如果输入fd，则fd会被广播过滤。如果fd==nil, 就是全员广播
function CMD.broadcast(package, fd)
	for k, v in pairs(agent) do
		if k and k ~= fd then
			--skynet.error("broadcast:"..k)
			socket.write(k, package)
		end
	end
end

function CMD.broadcastall(package)
	for k, v in pairs(agent) do
		socket.write(k, package)
	end
end

function CMD.login(id)
	print("login:" .. id)
	action_cache[id] = {}
end

function CMD.logout(id)
	if action_cache[id] == nil then
		return
	end

	if frame_actions[id] == nil then
		return
	end

	action_cache[id]  = nil
	frame_actions[id] = nil
end

function CMD.heartbeat()
	-- 广播HeartBeat信息
	local pack = proto_pack("heartbeat", { frame = current_frame })
	local pack_str = string.pack(">s2", pack)
	CMD.broadcast(pack_str, nil)

	-- 每隔100帧，进行一次全局同步
	if current_frame % 100 == 0 then
		local pack = proto_pack("sync_info", { info = "All" })
		local pack_str = string.pack(">s2", pack)
		CMD.broadcast(pack_str, nil)
	end

	current_frame = current_frame + 1
end

skynet.start(function()
	host = sprotoloader.load(1):host "package"
	proto_pack = host:attach(sprotoloader.load(2))

	-- 每隔0.02s，向客户端发送一次HeartBeat信号
	skynet.fork(function()
		while (true) do
			skynet.sleep(2) --sleep()的时间单位是0.01s。Sleep的时间决定了服务器的HeartBeat帧率
			CMD.heartbeat()
		end
	end)

	-- 处理外部调用请求
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	-- 启动端口监视器
	gate = skynet.newservice("gate")
end)
