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

action		 4 {
	request {
		id 		0 : integer
		frame	1 : integer
		input	2 : *integer 
		facing	3 : *double
	}
}

snapshoot	5 {
	request {
		id 		0 : integer
		info	1 : *double 
		anim	2 : string
		animtime 3 : double
	}
}

dead		6 {
	request {
		id 		0 : integer
	}
}

start_game_req 7 {
	request {
		id 		0 : integer
	}
}

catch_player_req 8 {
	request {
		id 		0 : integer
	}
}

save_player_req 9 {
	request {
		id 		0 : integer
	}
}

freeze_player_req 10 {
	request {
		id 		0 : integer
	}
}

update_player_model_req 11 {
	request {
		id 		0 : integer
		room    1 : string
		model 	2 : string
	}
}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 		0 : integer
	session 	1 : integer
}

.action {
		id 		0 : integer
		frame	1 : integer
		input	2 : *integer 
		facing	3 : *double
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

actionBC 8 {
	request {
		id 		0 : integer
		frame	1 : integer
		input	2 : *integer 
		facing	3 : *double
	}
}

snapshootBC 9 {
	request {
		id 		0 : integer
		info	1 : *double 
		anim	2 : string
		animtime 3 : double
	}
}

playerCountBC 10 {
	request {
		count 0 : integer
	}
}

ready_start 11 {
	request {
		room 0 : string
	}
}

start_game 12 {
	request {
		ghost 0 : integer
	}
}

catch_player 13 {
	request {
		id 0 : integer
	}
}

save_player 14 {
	request {
		id 0 : integer
	}
}

freeze_player 15 {
	request {
		id 0 : integer
	}
}

enter_room 16 {
	request {
		id 0    : integer
		room 1  : string
		name 2  : string
		model 3 : string
	}
}

update_player_model_bc 17 {
	request {
		id 		0 : integer
		room    1 : string
		model 	2 : string
	}
}

]]

return proto
