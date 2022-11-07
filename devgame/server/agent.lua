-- Coding Format : UTF-8

-- 「agent.lua 脚本介绍」
-- 玩家需要服务，agent就是服务员，一个玩家对应一个agent
-- agent负责处理自己的玩家发来的消息，可以转发或广播消息，也可以修改数据库中的信息

-- 请注意，在一些特定场合，skynet会fork（复制）一个新的进程，来完成一些特殊操作（如定时）
-- 而不同进程拥有独立的的命名空间，一个进程中的local变量只能被这个进程所用，无法被其他进程所用
-- 由于agent脚本中包含多处fork，请尽量不要在agent中维护全局信息————如在线玩家列表等
-- 因为如果你在fork之后，修改了某个变量，这个修改将只对后一个进程生效，对原有的进程不生效，这可能造成难以排查的逻辑错误
-- 如果希望维护全局信息，建议在simpledb.lua中编写，然后再在此脚本中调用

local skynet = require "skynet"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local WATCHDOG
local host
local proto_pack
local client_fd
local player_id

local CMD = {}
local REQUEST = {}
local clientReady = false
local heartbeat_session = nil
local frame_actions = {}

math.randomseed(os.time())

local function split(str, reps, foreach)
	local result = {}
	local exe_res = string.gsub(str, '[^' .. reps .. ']+', function(w)
		if (foreach) then
			foreach(w)
		end
		table.insert(result, w)
	end
	)
	return result
end

local function broadcast_request(pack, fd)
	local package = string.pack(">s2", pack)
	skynet.send(WATCHDOG, "lua", "broadcast", package, fd)
end

local function broadcastall_request(pack)
	local package = string.pack(">s2", pack)
	skynet.send(WATCHDOG, "lua", "broadcastall", package)
end

local function send_request(pack, fd)
	local package = string.pack(">s2", pack)
	socket.write(fd, package)
end

function REQUEST:init() end

function REQUEST:dead()
	print("player dead", self.id)
	skynet.call("SIMPLEDB", "lua", "dead", self.id)
end

-- 处理玩家的登录请求
function REQUEST:login()
	-- 与后台数据库交互，获取玩家ID。如果是从未登录过的玩家，将会自动分配一个新的ID
	player_id = skynet.call("SIMPLEDB", "lua", "login", self.name, self.password, self.model)

	-- 向新玩家告知他被分配到的ID
	send_request(proto_pack("login", { id = player_id, name = self.name, model = self.model }), client_fd)
	skynet.error(">>>>> db return:" .. player_id)

	-- 如果 id == -1，说明密码错误或者已经在线，无法登陆
	if player_id < 0 then
		skynet.send(WATCHDOG, "lua", "close", client_fd)
		return
	end

	-- 让 新玩家 加载场景，并把自己加入场景
	local player = skynet.call("SIMPLEDB", "lua", "get_player", player_id)
	send_request(proto_pack("enter_scene", player), client_fd)
	skynet.send(WATCHDOG, "lua", "login", player_id)

	-- 由于加载场景可能耗费较长时间，为了防止玩家加载不完场景，这里需要先等待一段时间再发送后续消息
	-- skynet提供了休眠函数：skynet.sleep(time)。调用后，当前进程将休眠
	-- 但是，所有玩家是共用同一个agent的，如果这个agent休眠了，那其他玩家怎么办呢？
	-- 我们可以复制一个新的agent，只让新的agent休眠，让原来的agent继续服务其他玩家
	-- skynet提供了linux格式的fork函数，可以用来“复制”进程
	skynet.fork(function()
		-- fork：复制当前进程，然后让新进程执行括号里的代码，而旧进程将跳过这段代码
		-- 这里fork的括号里写的是一个function，所以就会执行这个function

		-- 等待一段时间（1s）
		skynet.sleep(100)

		-- 让 其他玩家 把 新玩家 加入场景
		local player = skynet.call("SIMPLEDB", "lua", "get_player", player_id)
		broadcast_request(proto_pack("enter_scene", player), client_fd)


		-- 获得现在人数
		local player_count = skynet.call("SIMPLEDB", "lua", "GET_PLAYER_COUNTS")

		-- 广播现在人数
		broadcastall_request(proto_pack("playerCountBC", { count = player_count }))

		-- TODO 最后一个进入游戏的玩家判定是否可以开始游戏
		if player_count == 2 then
			broadcastall_request(proto_pack("ready_start", nil))
		end

		-- 让 新玩家 把 其他玩家 加入场景
		local players = skynet.call("SIMPLEDB", "lua", "get_players")
		for id, player in pairs(players) do
			if id ~= player_id then
				send_request(proto_pack("enter_scene", player), client_fd)
			end
		end

	end)
end

function REQUEST:snapshoot()
	broadcastall_request(proto_pack("snapshootBC",
		{ id = self.id, info = self.info, anim = self.anim, animtime = self.animtime }))
end

function REQUEST:action()
	broadcastall_request(proto_pack("actionBC",
		{ id = self.id, frame = self.frame, input = self.input, facing = self.facing }))
end

function REQUEST:start_game_req()
	local game_start = skynet.call("SIMPLEDB", "lua", "GET_GAME_START")
	if game_start == false then
		skynet.call("SIMPLEDB", "lua", "SET_GAME_START", true)
		local player_count = skynet.call("SIMPLEDB", "lua", "GET_PLAYER_COUNTS")
		local ghost = math.random(1, player_count)
		broadcastall_request(proto_pack("start_game", ghost))
	end
end

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	-- if response then
	-- skynet.error(">>>>>>>>>>> response:"..name)
	-- return response(r)
	-- end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function(msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function(fd, _, type, ...)
		--assert(fd == client_fd)	-- You can use fd to reply message
		skynet.ignoreret() -- session is fd, don't call skynet.ret
		--skynet.trace()
		if type == "REQUEST" then
			args = ...

			local ok, result = pcall(request, ...)
			if ok then
				if result then
					send_request(result, fd)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	client_fd = fd

	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	proto_pack = host:attach(sprotoloader.load(2))
	clientReady = false
	skynet.fork(function()
		while true do
			if clientReady then
				cr = skynet.call("SIMPLEDB", "lua", "getclientready")
				for k, v in pairs(cr) do
					print("send moving:" .. k)
					if k ~= fd and v == true then
						local name, status, pos, rot, delta = skynet.call("SIMPLEDB", "lua", "getplayermovement", k)
						--print("sending playerinfo", k, name, status)
						send_request(proto_pack("sendmovedelta",
							{ id = k, name = name, status = status, pos = pos, rot = rot, delta = delta }), fd)
					end
				end
			end
			skynet.sleep(1)
		end
	end)
	skynet.call(gate, "lua", "forward", fd)
	print("fd is ------: ", fd)
	--	send_request(proto_pack("sendid", { id = fd }), fd)
end

function CMD.disconnect(fd)
	skynet.send(WATCHDOG, "lua", "logout", player_id)
	skynet.send("SIMPLEDB", "lua", "logout", player_id)
	local pack = proto_pack("logout", { id = player_id })
	broadcast_request(pack, fd)
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_, _, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
