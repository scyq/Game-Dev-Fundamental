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
		model       2 : string
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
		model   2 : string
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
		facing	5 : *double
		ghost   6 : integer
		freeze  7 : integer
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

]]

return proto
