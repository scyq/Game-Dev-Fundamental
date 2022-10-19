local parser = {}

parser.taskFileName = "task.txt"

function parser:readFile()
    local file = assert(io.open(self.taskFileName, "r"))
    local content = file:read("*all")
    file:close()
    return content
end

function parser:parseTasks()
    print(self:readFile())
end
