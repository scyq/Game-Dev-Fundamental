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
local room

local CMD = {}
local REQUEST = {}
local clientReady = false

math.randomseed(os.time())

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
	player_id = skynet.call("SIMPLEDB", "lua", "login", self.name, self.password, self.room)

	-- 如果 id == -1，说明密码错误或者已经在线，无法登陆
	if player_id < 0 then
		skynet.send(WATCHDOG, "lua", "close", client_fd)
		return
	end

	room = self.room

	-- 向新玩家告知他被分配到的ID
	send_request(proto_pack("login", { id = player_id, name = self.name, room = self.room }), client_fd)
	print("player login... ", self.name, player_id, self.room)

	-- TODO 只广播给本房间
	-- 向所有玩家广播新玩家的登陆信息
	broadcastall_request(proto_pack("enter_room", { id = player_id, name = self.name, room = self.room, model = "F1" }))

	-- 让该玩家加载所有已经在房间中的玩家
	local players = skynet.call("SIMPLEDB", "lua", "get_players", self.room)
	for _, player in ipairs(players) do
		if player.id ~= player_id then
			send_request(proto_pack("enter_room", { id = player.id, name = player.name, room = player.room, model = player.model })
				, client_fd)
		end
	end

	-- 检测玩家人数是否达到上限
	local count = skynet.call("SIMPLEDB", "lua", "GET_PLAYER_COUNTS", self.room)
	if count >= 4 then
		-- TODO 只广播给本房间
		-- 广播游戏开始
		broadcastall_request(proto_pack("ready_start", { room = self.room }))

		-- 由最后进入的人开启游戏
		skynet.fork(
			function()
				skynet.sleep(500)
				print("Game Start....")
				skynet.call("SIMPLEDB", "lua", "SET_GAME_START", self.room, true)
				local final_players = skynet.call("SIMPLEDB", "lua", "GET_PLAYERS", self.room)
				-- 把所有玩家加入场景
				for id, _player in pairs(final_players) do
					broadcastall_request(proto_pack("enter_scene", {
						room = self.room,
						id = _player.id,
						name = _player.name,
						model = _player.model,
						scene = _player.scene,
						pos = _player.pos,
						ghost = _player.ghost,
						freeze = _player.freeze,
					}))
				end

				skynet.fork(function()
					-- 等待大家加入场景
					skynet.sleep(150)
					-- 四个人随机一个人做鬼
					local ghost = math.random(1, 4)
					local check_ghost = skynet.call("SIMPLEDB", "lua", "HUMAN2GHOST", self.room, ghost)
					print("calling ghost ", check_ghost)
					broadcastall_request(proto_pack("catch_player", { id = ghost, room = self.room }))

					-- TODO 改为全局计时器
					-- 这里只能做妥协，把最后一个人当作房主
					-- 用它来做计时器，所以如果这个人断线，游戏就会爆炸哈哈哈哈哈
					skynet.fork(function()
						local total_time = 3 * 60 * 100
						while true do
							skynet.sleep(100)
							total_time = total_time - 100
							broadcast_request(proto_pack("sync_timer", { room = self.room, time = total_time }))

							if total_time <= 0 then
								-- 游戏结束
							end
						end
					end)
				end)
			end
		)
	end
end

function REQUEST:update_player_model_req()
	local check = skynet.call("SIMPLEDB", "lua", "UPDATE_MODEL", self.room, self.id, self.model)
	if check then
		broadcastall_request(proto_pack("update_player_model_bc", { id = self.id, room = self.room, model = self.model }))
	end
end

function REQUEST:snapshoot()
	broadcastall_request(proto_pack("snapshootBC",
		{ id = self.id, info = self.info, anim = self.anim, animtime = self.animtime }))
end

-- function REQUEST:start_game_req()
-- 	local game_start = skynet.call("SIMPLEDB", "lua", "GET_GAME_START", self.room)
-- 	if game_start == false then
-- 		print("Game Start....")
-- 		skynet.call("SIMPLEDB", "lua", "SET_GAME_START", self.room, true)
-- 		local player_count = skynet.call("SIMPLEDB", "lua", "GET_PLAYER_COUNTS", self.room)
-- 		local players = skynet.call("SIMPLEDB", "lua", "GET_PLAYERS", self.room)

-- 		-- 把所有玩家加入场景
-- 		for id, player in pairs(players) do
-- 			send_request(proto_pack("enter_scene", player), client_fd)
-- 			local ghost = math.random(1, player_count)
-- 			local index = 1
-- 			for _id, _player in pairs(players) do
-- 				if index == ghost then
-- 					print("Ghost is " .. id)
-- 					_player.ghost = true
-- 					broadcastall_request(proto_pack("start_game", { ghost = id }))
-- 					break
-- 				end
-- 				index = index + 1
-- 			end
-- 			skynet.fork(function()
-- 				skynet.sleep(200)
-- 				-- 开始计时

-- 			end)
-- 		end
-- 	end
-- end

function REQUEST:catch_player_req()
	local check = skynet.call("SIMPLEDB", "lua", "HUMAN2GHOST", self.room, self.id)
	if check == true then
		broadcastall_request(proto_pack("catch_player", { id = self.id, room = self.room }))
	end
end

-- Save就是Unfreeze
function REQUEST:save_player_req()
	skynet.call("SIMPLEDB", "lua", "UNFREEZE", self.room, self.id)
	broadcastall_request(proto_pack("save_player", { id = self.id, room = self.room }))
end

function REQUEST:freeze_player_req()
	skynet.call("SIMPLEDB", "lua", "FREEZE", self.room, self.id)
	broadcastall_request(proto_pack("freeze_player", { id = self.id, room = self.room }))
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
	skynet.send("SIMPLEDB", "lua", "logout", room, player_id)
	local pack = proto_pack("logout", { id = player_id, room = room })
	broadcast_request(pack, fd)
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_, _, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
