local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 		0 : integer
	session 	1 : integer
}

init 		1 {
	request {
		info   	  0 : integer
	}
}

login 		2 {
	request {
		name 		0 : string
		password 	1 : string
		room 		2 : string
	}
}

logout 		3 {
	request {
		id 	0  : integer
	}	
}

snapshoot	4 {
	request {
		id 		0 : integer
		info	1 : *double 
		anim	2 : string
		animtime 3 : double
	}
}

dead		5 {
	request {
		id 		0 : integer
	}
}

start_game_req 6 {
	request {
		id 		0 : integer
	}
}

catch_player_req 7 {
	request {
		id 		0 : integer
	}
}

save_player_req 8 {
	request {
		id 		0 : integer
	}
}

freeze_player_req 9 {
	request {
		id 		0 : integer
	}
}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 		0 : integer
	session 	1 : integer
}

heartbeat 		1 {
	request {
		frame 		0 : integer
	}
}


login 		2 {
	request {
		id 		0 : integer
		name	1 : string
		room    2 : string
	}
}


logout 		3 {
	request {
		id 	0  : integer
	}	
}

enter_scene 	4 {
	request {	
		id 		0 : integer
		name	1 : string
		model   2 : string
		scene	3 : integer
		pos 	4 : *double
		ghost   5 : integer
		freeze  6 : integer
	}
}

exit_scene 		5 {
	request {
		id 		0 : integer
	}
}

actions 		6 {
	request {
		actions 0 : *action
	}
}

sync_info 	7 {
	request {	
		
	}
}

snapshootBC 8 {
	request {
		id 		0 : integer
		info	1 : *double 
		anim	2 : string
		animtime 3 : double
	}
}

playerCountBC 9 {
	request {
		count 0 : integer
	}
}

ready_start 10 {
	request {
	}
}

start_game 11 {
	request {
		ghost 0 : integer
	}
}

catch_player 12 {
	request {
		id 0 : integer
	}
}

save_player 13 {
	request {
		id 0 : integer
	}
}

freeze_player 14 {
	request {
		id 0 : integer
	}
}

]]

return proto
