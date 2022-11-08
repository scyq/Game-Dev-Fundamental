local skynet = require "skynet"
require "skynet.manager" -- import skynet.register

local online_server = true
local current_folder = "devgame/server" -- 当前文件夹名称，不需要加斜线
if online_server then
	package.path = package.path .. ";/home/ubuntu/Game-dev-fundamental/" .. current_folder .. "/?.lua"
else
	package.path = package.path .. ";/mnt/c/scyq/Game/dev-basic/Game-dev-fundamental/" .. current_folder .. "/?.lua"
end


local rooms = {}

local clientReady = {}
local playerName = {}
local command = {}

local game_start = false

function command.REMOVE(id)
	local name = playerName[id]
	clientReady[id] = nil
	playerName[id] = nil
	return name
end

function command.GETCLIENTREADY()
	return clientReady
end

function command.UPDATE_PLAYER(id, key, value)
	if players[id] then
		players[id][key] = value
	end
end

function command.GET_PLAYERS(room)
	local online_players = {}
	for i, player in pairs(rooms[room].players) do
		if rooms[room].players[i].online then
			online_players[i] = player
		end
	end
	return online_players
end

function command.GET_PLAYER(id)
	if players[id] then
		return players[id]
	end
	return nil
end

function command.GET_PLAYER_COUNTS()
	local cnt = 0
	for i, player in pairs(players) do
		cnt = cnt + 1
	end
	return cnt
end

function command:GET_GAME_START()
	return game_start
end

function command.SET_GAME_START(value)
	game_start = value
	return true
end

function command.HUMAN2GHOST(id)
	if players[id] then
		if players[id].freeze == 0 then
			players[id].ghost = 1
			return true
		end
	end
	return false
end

function command.FREEZE(id)
	if players[id] then
		if players[id].ghost == 0 then
			players[id].freeze = 1
			return true
		end
	end
	return false
end

function command.UNFREEZE(id)
	if players[id] then
		if players[id].ghost == 0 then
			players[id].freeze = 0
			return true
		end
	end
	return false
end

local function create_new_room(room)
	if rooms[room] then
		return false
	end
	rooms[room] = {
		state = "waiting",
		players = {},
		name2id = {}
	}
end

local function get_or_create_room(room)
	if rooms[room] then
		return rooms[room]
	end
	create_new_room(room)
	return rooms[room]
end

local function get_room_player_cnts(room)
	local index = 0
	if rooms[room] then
		for id, player in pairs(rooms[room].players) do
			index = index + 1
		end
		return index
	end
	return 0
end

function command.GET_ROOM(room)
	if rooms[room] then
		return rooms[room]
	end
	return nil
end

function command.UPDATE_MODEL(room, player_id, model)
	if rooms[room] then
		if rooms[room].players[player_id] then
			rooms[room].players[player_id].model = model
			return true
		end
	end
	return false
end

-- 处理玩家的登录信息
function command.LOGIN(player_name, player_password, current_room)
	local the_room = get_or_create_room(current_room)
	local player_id = the_room.name2id[player_name]

	if player_id then
		if the_room.players[player_id].online then
			return -1 --用户已经登陆
		elseif the_room.players[player_id].password ~= player_password then
			return -2 --密码错误
		end
	end

	-- 如果是从未登录过的新用户
	if player_id == nil then
		--产生一个新ID
		player_id = get_room_player_cnts(current_room) + 1
		the_room.name2id[player_name] = player_id

		-- 构造一个player，存进后台数据库
		local player = {
			id       = player_id,
			name     = player_name,
			password = player_password,
			model    = "F1",
			scene    = 0,
			online   = true,
			pos      = { math.random(-10, 10), 0, math.random(-5, 15) },
			ghost    = 0,
			freeze   = 0,
			room     = current_room,
		}

		the_room.players[player_id] = player
	else
		the_room.players[player_id].online = true
	end

	return player_id
end

-- 处理玩家的登出信息
function command.LOGOUT(player_id)
	if player_id == nil then
		return
	end
	skynet.error("logout:" .. player_id)

	-- 修改数据库中的玩家状态
	if players[player_id] then
		skynet.error("online:" .. tostring(players[player_id].online))
		players[player_id].online = false
		skynet.error("online:" .. tostring(players[player_id].online))
	end

	for id, player in pairs(players) do
		skynet.error("player[" .. id .. "] online:" .. tostring(player.online))
	end

end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		cmd = cmd:upper()
		if cmd == "PING" then
			assert(session == 0)
			local str = (...)
			if #str > 20 then
				str = str:sub(1, 20) .. "...(" .. #str .. ")"
			end
			skynet.error(string.format("%s ping %s", skynet.address(address), str))
			return
		end
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register "SIMPLEDB"
end)
