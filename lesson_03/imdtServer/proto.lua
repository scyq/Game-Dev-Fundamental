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
		modelid 	2 : integer
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
		scene	2 : integer
		pos 	3 : *double
		facing	4 : *double
		modelid	5 : integer
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


]]

return proto
