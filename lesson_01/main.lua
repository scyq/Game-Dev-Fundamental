local skynet = require "skynet"

-- skynet启动回调
function start_cb()
	print("======Server start=======!")
	-- 启动聊天服务
	skynet.newservice("chat_service")
	
	-- 退出当前的服务
	-- skynet.exit 之后的代码都不会被运行。而且，当前服务被阻塞住的 coroutine 也会立刻中断退出。
	skynet.exit()
end

-- 启动skynet
skynet.start(start_cb)
