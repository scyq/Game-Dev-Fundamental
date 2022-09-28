-- 元表和基类定义
GameRole = {
    ID = 0,
    name = "",
    modelID = 0,
    attack = 0,
    defense = 0,
}
-- 为了元表继承链和Metatable寻找
GameRole.__index = GameRole

-- 实现构造函数
function GameRole:new(ID, name, modelID, attack, defense)
    local o = {}
    setmetatable(o, self)
    o.__index = self
    o.ID = ID or 0
    o.name = name or ""
    o.modelID = modelID or 0
    o.attack = attack or 0
    o.defense = defense or 0
    return o
end
