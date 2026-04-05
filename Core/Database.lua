-- Database.lua
-- EnhancedUnitFrames SavedVariables 管理模块
-- 负责配置数据的初始化、默认值合并和持久化

local addonName, EUF = ...

local Database = {}
EUF.Database = Database

-------------------------------------------------------------------------------
-- 默认配置
-------------------------------------------------------------------------------

-- 全局默认配置
Database.DEFAULTS_GLOBAL = {
    enableAddon = true,
    debugMode = false,
}

-- 角色配置默认值
Database.DEFAULTS_PROFILE = {
    -- 职业染色配置
    classColors = {
        enabled = true,              -- 启用职业染色
        colorBackground = false,     -- 染色背景
        colorBorder = true,          -- 染色边框
        colorNPCByReaction = true,   -- NPC使用反应色
        customColors = {
            hostile = {r = 1.0, g = 0.0, b = 0.0},    -- 敌对颜色
            neutral = {r = 1.0, g = 1.0, b = 0.0},    -- 中立颜色
            friendly = {r = 0.0, g = 1.0, b = 0.0},   -- 友好颜色
        },
    },

    -- 缩放配置
    scales = {
        player = 1.0,
        target = 1.0,
        focus = 1.0,
        pet = 1.0,
    },

    -- 材质配置
    textures = {
        healthBar = "Blizzard",
        manaBar = "Blizzard",
        background = "None",
        border = "None",
        borderSize = 2,
        borderColor = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},
    },

    -- 文字配置
    text = {
        -- 文字格式配置
        formats = {
            player = {
                health = "DEFAULT",
                mana = "DEFAULT",
            },
            target = {
                health = "DEFAULT",
                mana = "DEFAULT",
            },
        },
        -- 字体配置
        fonts = {
            player = {
                name = {font = "Friz Quadrata TT", size = 12, flags = ""},
                health = {font = "Friz Quadrata TT", size = 10, flags = ""},
                mana = {font = "Friz Quadrata TT", size = 10, flags = ""},
            },
            target = {
                name = {font = "Friz Quadrata TT", size = 12, flags = ""},
                health = {font = "Friz Quadrata TT", size = 10, flags = ""},
                mana = {font = "Friz Quadrata TT", size = 10, flags = ""},
            },
        },
        -- 颜色配置
        colors = {
            player = {
                name = {r = 1.0, g = 1.0, b = 1.0},
                health = {r = 1.0, g = 1.0, b = 1.0},
            },
            target = {
                name = {r = 1.0, g = 1.0, b = 1.0},
                health = {r = 1.0, g = 1.0, b = 1.0},
            },
        },
    },

    -- 编辑模式配置
    editMode = {
        showInEditMode = true,
        syncWithBlizzard = true,
    },
}

-- 缩放范围限制
Database.SCALE_MIN = 0.5
Database.SCALE_MAX = 2.0
Database.SCALE_DEFAULT = 1.0

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

-- 初始化数据库
function Database:Initialize()
    -- 确保全局变量存在
    EnhancedUnitFramesDB = EnhancedUnitFramesDB or {}
    EnhancedUnitFramesDBGlobal = EnhancedUnitFramesDBGlobal or {}

    -- 保存引用
    self.db = EnhancedUnitFramesDB      -- 角色配置
    self.global = EnhancedUnitFramesDBGlobal  -- 全局配置

    -- 应用默认值
    self:ApplyDefaults()

    return true
end

-------------------------------------------------------------------------------
-- 默认值应用
-------------------------------------------------------------------------------

-- 应用所有默认值
function Database:ApplyDefaults()
    -- 合并全局默认值
    self:MergeDefaults(self.global, self.DEFAULTS_GLOBAL)

    -- 合并角色配置默认值
    self:MergeDefaults(self.db, self.DEFAULTS_PROFILE)
end

-- 递归合并默认值（不覆盖已存在的值）
function Database:MergeDefaults(tbl, defaults)
    if type(tbl) ~= "table" then return end
    if type(defaults) ~= "table" then return end

    for key, defaultValue in pairs(defaults) do
        if tbl[key] == nil then
            -- 键不存在，设置默认值
            if type(defaultValue) == "table" then
                tbl[key] = self:CopyTable(defaultValue)
            else
                tbl[key] = defaultValue
            end
        elseif type(tbl[key]) == "table" and type(defaultValue) == "table" then
            -- 递归合并嵌套表
            self:MergeDefaults(tbl[key], defaultValue)
        end
    end
end

-------------------------------------------------------------------------------
-- 深拷贝
-------------------------------------------------------------------------------

-- 深拷贝表
function Database:CopyTable(src)
    if type(src) ~= "table" then
        return src
    end

    local dest = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = self:CopyTable(v)
        else
            dest[k] = v
        end
    end

    return dest
end

-------------------------------------------------------------------------------
-- 配置访问
-------------------------------------------------------------------------------

-- 获取配置值（支持嵌套路径）
-- 用法: Database:Get("classColors", "enabled")
function Database:Get(...)
    local current = self.db
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

-- 设置配置值（支持嵌套路径）
-- 用法: Database:Set(true, "classColors", "enabled")
function Database:Set(value, ...)
    local keys = {...}
    if #keys == 0 then return false end

    local current = self.db
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

-- 获取全局配置值
function Database:GetGlobal(key)
    return self.global[key]
end

-- 设置全局配置值
function Database:SetGlobal(key, value)
    self.global[key] = value
end

-------------------------------------------------------------------------------
-- 缩放配置辅助
-------------------------------------------------------------------------------

-- 验证并规范化缩放值
function Database:ValidateScale(scale)
    local num = tonumber(scale)
    if not num then
        return self.SCALE_DEFAULT
    end
    return math.max(self.SCALE_MIN, math.min(self.SCALE_MAX, num))
end

-- 获取框体缩放
function Database:GetScale(frameKey)
    local scale = self:Get("scales", frameKey)
    return self:ValidateScale(scale)
end

-- 设置框体缩放
function Database:SetScale(frameKey, scale)
    scale = self:ValidateScale(scale)
    return self:Set(scale, "scales", frameKey)
end

-------------------------------------------------------------------------------
-- 重置功能
-------------------------------------------------------------------------------

-- 重置角色配置
function Database:ResetProfile()
    -- 清空现有配置
    for key, _ in pairs(self.db) do
        self.db[key] = nil
    end

    -- 重新应用默认值
    self:ApplyDefaults()

    EUF:Print("配置已重置为默认值")
end

-- 重置全局配置
function Database:ResetGlobal()
    for key, _ in pairs(self.global) do
        self.global[key] = nil
    end

    self:MergeDefaults(self.global, self.DEFAULTS_GLOBAL)

    EUF:Print("全局配置已重置")
end

-- 重置所有配置
function Database:ResetAll()
    self:ResetProfile()
    self:ResetGlobal()
end

-------------------------------------------------------------------------------
-- 导入/导出
-------------------------------------------------------------------------------

-- 导出配置为字符串
function Database:ExportProfile()
    local serialized = ""

    -- 简单的序列化（WoW 没有 JSON 库，使用 table.tostring）
    local function serialize(tbl, indent)
        indent = indent or ""
        local result = {}

        for k, v in pairs(tbl) do
            local keyStr
            if type(k) == "string" then
                keyStr = string.format("[%q]", k)
            else
                keyStr = string.format("[%s]", k)
            end

            local valueStr
            if type(v) == "table" then
                valueStr = serialize(v, indent .. "  ")
            elseif type(v) == "string" then
                valueStr = string.format("%q", v)
            elseif type(v) == "boolean" then
                valueStr = v and "true" or "false"
            else
                valueStr = tostring(v)
            end

            table.insert(result, string.format("%s%s = %s", indent .. "  ", keyStr, valueStr))
        end

        return "{\n" .. table.concat(result, ",\n") .. "\n" .. indent .. "}"
    end

    return serialize(self.db)
end

-- 验证导入的配置
function Database:ValidateImport(data)
    if type(data) ~= "table" then
        return false, "无效的配置格式"
    end

    -- 基本验证：检查是否有已知的配置键
    local validKeys = {
        "classColors", "scales", "textures", "text", "editMode"
    }

    local hasValidKey = false
    for _, key in ipairs(validKeys) do
        if data[key] ~= nil then
            hasValidKey = true
            break
        end
    end

    if not hasValidKey then
        return false, "配置中没有有效的设置项"
    end

    return true, nil
end

-- 导入配置
function Database:ImportProfile(data)
    local success, err = self:ValidateImport(data)
    if not success then
        return false, err
    end

    -- 清空并导入
    for key, _ in pairs(self.db) do
        self.db[key] = nil
    end

    -- 复制导入的数据
    for key, value in pairs(data) do
        if type(value) == "table" then
            self.db[key] = self:CopyTable(value)
        else
            self.db[key] = value
        end
    end

    -- 重新应用默认值（确保新增字段存在）
    self:ApplyDefaults()

    return true, nil
end

return Database