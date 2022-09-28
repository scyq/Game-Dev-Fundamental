require("GameRole")
require("utils")

GameRoleMgr = {
    role_table = {},
}
GameRoleMgr.__index = GameRoleMgr


function GameRoleMgr:new()
    local o = {}
    setmetatable(o, self)
    o.__index = self
    return o
end

function GameRoleMgr:add_role(role)
    self.role_table[role.ID] = role
end

function GameRoleMgr:del_role_by_id(role_id)
    table.remove(self.role_table, role_id)
end

function GameRoleMgr:get_role_by_id(role_id)
    -- 这里必须要遍历，否则可能存在被补齐的情况
    for k, v in pairs(self.role_table) do
        if (v.ID == role_id) then
            return v
        end
    end
    return nil
end

function GameRoleMgr:get_att_sort_list()
    -- 进行一次深拷贝，防止对原表进行修改，且转换为数组
    local temp = Table2List(self.role_table)
    -- 按照自定义方法从大到小排序
    table.sort(temp, function(a, b)
        return a.attack > b.attack
    end)
    return temp
end

function GameRoleMgr:get_def_sort_list()
    -- 进行一次深拷贝，防止对原表进行修改，且转换为数组
    local temp = Table2List(self.role_table)
    -- 按照自定义方法从大到小排序
    table.sort(temp, function(a, b)
        return a.defense > b.defense
    end)
    return temp
end

function GameRoleMgr:generate_role_list(n)
    -- 获得当前角色列表的长度, 防止ID重复
    local current_length = TableLength(self.role_table)

    for i = 1, n do
        local role = GameRole:new(current_length + i, "Game Role_" .. current_length + i,
            GetRandomNumber(0, 10000),
            GetRandomNumber(0, 10000), GetRandomNumber(0, 10000))
        self:add_role(role)
    end
end
