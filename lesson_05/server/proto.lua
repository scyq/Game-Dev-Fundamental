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
		color       2 : integer
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
		frame 	1 : integer
		info	2 : *double 
	}
}

dead		6 {
	request {
		id 		0 : integer
	}
}

add_coin_req    7 {
	request {
		posx 	         0 : double
		posy 	         1 : double
		posz             2 : double
		ownerPlayerId    3 : integer
	}
}

remove_coin_req  8 {
	request {
		id               0 : integer
		pickerPlayerId   1 : integer
	}
}

get_task_list_req 9 {
	request {
	}
}

start_task_req 10 {
	request {
		taskid  0 : integer
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
		color   2 : integer
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
		color   2 : integer
		scene	3 : integer
		pos 	4 : *double
		facing	5 : *double
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
		frame 	1 : integer
		info	2 : *double 
	}
}

add_coin_bc    10 {
	request {
		id               0 : integer
		posx 	         1 : double
		posy 	         2 : double
		posz             3 : double
		ownerPlayerId    4 : integer
	}
}

remove_coin_bc    11 {
	request {
		id               0 : integer
		pickerPlayerId   1 : integer
	}
}

get_task_bc 12 {
	request {
		taskid 0 : integer
		taskname 1 : string
		taskdesc 2 : string
		tasktype 3 : integer
		tasktarget 4 : string
		taskaward 5 : string
		taskstate 6 : integer
	}
}

add_arrival_target 13 {
	request {
		x 0 : double
		z 1 : double
	}
}

task_complete_bc 14 {
	request {
		taskid 0 : integer
	}
}

start_obtain_task 15 {
	request {
		taskid 0 : integer
	}
}


]]

return proto
