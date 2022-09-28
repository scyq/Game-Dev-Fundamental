require("GameRoleMgr")

local manager = GameRoleMgr:new()
manager:generate_role_list(10)
manager:get_att_sort_list()
for k, v in pairs(manager.role_list) do
    print(k, v.ID, v.modelID, v.name, v.attack, v.defense)
end
