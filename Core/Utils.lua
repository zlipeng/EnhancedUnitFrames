-- Utils.lua
-- EnhancedUnitFrames 工具函数模块
-- 提供通用工具函数

local addonName, EUF = ...

local Utils = {}
EUF.Utils = Utils

-- 插件名称前缀
Utils.PREFIX = "|cFF00FF00EnhancedUnitFrames|r:"

-- 战斗安全修改包装
-- 检查战斗状态，返回是否可以执行
function Utils.SafeModify(func, ...)
    if InCombatLockdown() then
        return false, "combat_lockdown"
    end

    local success, err = pcall(func, ...)
    if not success then
        EUF:Debug("SafeModify error:", err)
        return false, err
    end

    return true, nil
end

-- 数字格式化（使用暴雪内置函数）
function Utils.FormatNumber(num)
    if not num or type(num) ~= "number" then
        return "0"
    end

    -- 使用暴雪内置的 AbbreviateNumbers 函数（如果存在）
    if AbbreviateNumbers then
        return AbbreviateNumbers(num)
    end

    -- 后备方案：手动格式化
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

-- 十六进制颜色转 RGB
-- 输入: "RRGGBB" 或 "#RRGGBB"
-- 输出: r, g, b (0-1 范围)
function Utils.HexToRGB(hex)
    if not hex then
        return 1, 1, 1
    end

    -- 移除 # 前缀
    hex = hex:gsub("^#", "")

    if #hex ~= 6 then
        return 1, 1, 1
    end

    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255

    return r / 255, g / 255, b / 255
end

-- RGB 转十六进制颜色
-- 输入: r, g, b (0-1 范围)
-- 输出: "RRGGBB"
function Utils.RGBToHex(r, g, b)
    r = r or 1
    g = g or 1
    b = b or 1

    -- 确保 0-1 范围
    r = math.max(0, math.min(1, r))
    g = math.max(0, math.min(1, g))
    b = math.max(0, math.min(1, b))

    return string.format("%02X%02X%02X",
        math.floor(r * 255),
        math.floor(g * 255),
        math.floor(b * 255))
end

-- 统一消息输出（带插件前缀）
function Utils.Print(msg)
    if not msg then return end
    print(Utils.PREFIX, msg)
end

-- 调试消息输出
-- 仅在调试模式开启时输出
function Utils.DebugPrint(msg, ...)
    if not EUF.debugMode then return end

    if select("#", ...) > 0 then
        local args = {}
        for i = 1, select("#", ...) do
            local arg = select(i, ...)
            if type(arg) == "table" then
                table.insert(args, "(table)")
            elseif arg == nil then
                table.insert(args, "nil")
            else
                table.insert(args, tostring(arg))
            end
        end
        msg = msg .. " " .. table.concat(args, " ")
    end

    print("|cFFFFFF00[EUF Debug]|r", msg)
end

-- 深拷贝表
function Utils.DeepCopy(src)
    if type(src) ~= "table" then
        return src
    end

    local dest = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = Utils.DeepCopy(v)
        else
            dest[k] = v
        end
    end

    return dest
end

-- 合并表（不覆盖已存在的键）
function Utils.MergeTable(dest, src)
    if type(dest) ~= "table" then dest = {} end
    if type(src) ~= "table" then return dest end

    for k, v in pairs(src) do
        if dest[k] == nil then
            if type(v) == "table" then
                dest[k] = Utils.DeepCopy(v)
            else
                dest[k] = v
            end
        elseif type(dest[k]) == "table" and type(v) == "table" then
            Utils.MergeTable(dest[k], v)
        end
    end

    return dest
end

-- 检查值是否在表中
function Utils.TableContains(tbl, value)
    if type(tbl) ~= "table" then return false end

    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end

    return false
end

-- 获取表的键数量
function Utils.TableCount(tbl)
    if type(tbl) ~= "table" then return 0 end

    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

-- 安全获取嵌套表值
-- 例如: Utils.GetNestedValue(db, "classColors", "enabled")
function Utils.GetNestedValue(tbl, ...)
    if type(tbl) ~= "table" then return nil end

    local current = tbl
    for i = 1, select("#", ...) do
        local key = select(i, ...)
        if type(current) ~= "table" then
            return nil
        end
        current = current[key]
        if current == nil then
            return nil
        end
    end

    return current
end

-- 安全设置嵌套表值
-- 例如: Utils.SetNestedValue(db, true, "classColors", "enabled")
function Utils.SetNestedValue(tbl, value, ...)
    if type(tbl) ~= "table" then return false end

    local keys = {...}
    if #keys == 0 then return false end

    local current = tbl
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end

    current[keys[#keys]] = value
    return true
end

-- 限制数值范围
function Utils.Clamp(value, minVal, maxVal)
    return math.max(minVal, math.min(maxVal, value))
end

-- 安全的 tonumber，带默认值
function Utils.ToNumber(value, default)
    default = default or 0
    local num = tonumber(value)
    return num or default
end

-- 安全 tostring，处理 nil
function Utils.ToStr(value)
    if value == nil then
        return "nil"
    elseif type(value) == "boolean" then
        return value and "true" or "false"
    elseif type(value) == "table" then
        return "(table)"
    else
        return tostring(value)
    end
end

return Utils