------------------------------------------------------
--------------- 用于存放工具函数的文件 -----------------
------------------------------------------------------

-- 初始化随机种子
math.randomseed(os.time())

-- 获取一个随机整数
function GetRandomNumber(min, max)
    return math.random(min, max)
end

-- 获取表的长度
function TableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- 根据指定字符串分割字符串
function Split(str, reps)
    local result = {}
    local exe_res = string.gsub(str, '[^' .. reps .. ']+', function(w)
        table.insert(result, w)
    end)
    return result
end

-- 将哈希表转为线性表
function Table2List(table)
    local temp = {}
    local cnt = 1
    for k, v in pairs(table) do
        temp[cnt] = v
        cnt = cnt + 1
    end
    return temp
end
