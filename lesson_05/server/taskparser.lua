parser = {}

parser.taskFileName = "tasks.txt"

function parser:split(str, reps, foreach)
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

function parser:readFile()
    local file = io.open(self.taskFileName, "r")
    local content = file:read("*all")
    file:close()
    return content
end

function parser:parseTasks()
    local tasks = parser:split(parser:readFile(), "####")
    local res = {}
    for i = 1, #tasks do
        local theTask = parser:split(tasks[i], "\n")
        local task = {}
        task.taskid = tonumber(theTask[1])
        task.taskname = theTask[2]
        task.taskdesc = theTask[3]
        task.tasktype = tonumber(theTask[4])
        -- 0表示任务类型为获得类，1表示任务类型为到达类
        -- 获得类任务需要两个数值，X物体和N个数量
        -- 到达类任务需要三个数值，X坐标和Y坐标和Z坐标
        task.tasktarget = parser:split(theTask[5], " ", tonumber)
        task.taskaward = theTask[6]
        table.insert(res, task)
    end
    return res
end
