-- Database.lua
-- EnhancedUnitFrames SavedVariables 管理模块
-- 负责配置数据的初始化、默认值合并和持久化

local addonName, EUF = ...

local Database = {}
EUF.Database = Database

-------------------------------------------------------------------------------
-- 常量定义
-------------------------------------------------------------------------------

Database.SCALE_MIN = 0.5
Database.SCALE_MAX = 2.0
Database.SCALE_DEFAULT = 1.0

-- 文字格式
Database.TEXT_FORMATS = {
    NONE = "无",
    PERCENT = "百分比",
    CURRENT = "当前值",
    MAX = "最大值",
    CURMAX = "当前/最大",
    CURPERCENT = "当前 百分比",
    CURMAXPERCENT = "当前/最大 百分比",
    DEFICIT = "亏损值",
}

-- 能量类型颜色
Database.POWER_COLORS = {
    MANA = {r = 0.00, g = 0.50, b = 1.00},
    RAGE = {r = 1.00, g = 0.00, b = 0.00},
    FOCUS = {r = 1.00, g = 0.50, b = 0.00},
    ENERGY = {r = 1.00, g = 1.00, b = 0.00},
    RUNIC_POWER = {r = 0.00, g = 0.82, b = 1.00},
    FURY = {r = 0.60, g = 0.30, b = 0.60},
    PAIN = {r = 1.00, g = 0.50, b = 0.50},
    LUNAR_POWER = {r = 0.30, g = 0.52, b = 0.90},
    INSANITY = {r = 0.40, g = 0.00, b = 0.80},
    MAELSTROM = {r = 0.00, g = 0.50, b = 1.00},
    COMBO_POINTS = {r = 1.00, g = 0.96, b = 0.41},
    HOLY_POWER = {r = 0.95, g = 0.55, b = 0.73},
    SOUL_SHARDS = {r = 0.53, g = 0.53, b = 0.93},
    CHI = {r = 0.71, g = 1.00, b = 0.92},
    ARCANE_CHARGES = {r = 0.25, g = 0.78, b = 0.92},
    ESSENCE = {r = 0.20, g = 0.58, b = 0.50},
}

-- 反应色
Database.REACTION_COLORS = {
    hostile = {r = 1.0, g = 0.0, b = 0.0},
    neutral = {r = 1.0, g = 1.0, b = 0.0},
    friendly = {r = 0.0, g = 1.0, b = 0.0},
}

-------------------------------------------------------------------------------
-- 模块默认配置
-------------------------------------------------------------------------------

-- 头像模块默认配置
local function getDefaultPortraitConfig()
    return {
        enabled = true,
        hidden = false,  -- 隐藏头像
        style = "3D",  -- "3D", "2D", "class"
        borderEnabled = false,  -- 默认禁用边框，避免 Taint
        borderSize = 2,
        borderColor = {r = 1, g = 1, b = 1, a = 1},
    }
end

-- 生命条模块默认配置
local function getDefaultHealthBarConfig()
    return {
        enabled = true,
        width = 200,
        height = 24,
        useClassColor = true,
        useReactionColor = true,
        customColor = {r = 0, g = 1, b = 0, a = 1},
        backgroundColor = {r = 0.1, g = 0.1, b = 0.1, a = 0.8},
        texture = "Blizzard",
        borderEnabled = false,  -- 默认禁用边框，由 BorderModule 单独处理
        borderSize = 2,
        borderColor = {r = 1, g = 1, b = 1, a = 1},
    }
end

-- 能量条模块默认配置
local function getDefaultPowerBarConfig()
    return {
        enabled = true,
        hidden = false,  -- 隐藏能量条
        width = 200,
        height = 12,
        usePowerTypeColor = true,
        customColor = {r = 0, g = 0.5, b = 1, a = 1},
        backgroundColor = {r = 0.1, g = 0.1, b = 0.1, a = 0.8},
        texture = "Blizzard",
        borderEnabled = false,  -- 默认禁用边框，由 BorderModule 单独处理
        borderSize = 1,
        borderColor = {r = 1, g = 1, b = 1, a = 1},
    }
end

-- 文字模块默认配置
local function getDefaultTextConfig()
    return {
        enabled = true,
        position = "CENTER",
        xOffset = 0,
        yOffset = 0,
        justifyH = "CENTER",
        font = "Friz Quadrata TT",
        fontSize = 10,
        fontFlags = "OUTLINE",
        color = {r = 1, g = 1, b = 1, a = 1},
        useClassColor = false,
    }
end

-- 名称文字默认配置
local function getDefaultNameTextConfig()
    local config = getDefaultTextConfig()
    config.fontSize = 12
    config.position = "TOP"
    config.yOffset = 5
    config.maxWidth = 180
    return config
end

-- 生命值文字默认配置
local function getDefaultHealthTextConfig()
    local config = getDefaultTextConfig()
    config.format = "CURMAXPERCENT"
    return config
end

-- 能量值文字默认配置
local function getDefaultPowerTextConfig()
    local config = getDefaultTextConfig()
    config.format = "CURRENT"
    return config
end

-- 次级能量条默认配置
local function getDefaultSecondaryPowerBarConfig()
    return {
        enabled = true,
        hidden = false,  -- 隐藏次级能量条
        displayMode = "bar",  -- "bar", "icons", "runes"
        width = 200,
        height = 6,
        iconSize = 16,
        spacing = 2,
        orientation = "HORIZONTAL",
        texture = "Blizzard",
    }
end

-- 施法条默认配置
local function getDefaultCastBarConfig()
    return {
        enabled = true,
        hidden = false,  -- 隐藏施法条
        width = 200,
        height = 16,
        texture = "Blizzard",
        showTimer = true,
        showIcon = true,
        iconSize = 16,
        borderEnabled = false,  -- 默认禁用边框，避免 Taint
        borderSize = 1,
        borderColor = {r = 1, g = 1, b = 1, a = 1},
        castColor = {r = 1.0, g = 0.7, b = 0.0},
        channelColor = {r = 0.0, g = 1.0, b = 0.0},
        failColor = {r = 1.0, g = 0.0, b = 0.0},
    }
end

-- 边框默认配置
local function getDefaultBorderConfig()
    return {
        enabled = false,  -- 默认禁用边框，避免潜在的 Taint 问题
        style = "Solid",  -- "None", "Solid", "BlizzardTooltip", "Rounded", "Gold"
        size = 2,
        color = {r = 1, g = 1, b = 1, a = 1},
        useClassColor = false,
        useReactionColor = false,
    }
end

-- 框体默认配置
local function getDefaultFrameConfig()
    return {
        enabled = true,
        portrait = getDefaultPortraitConfig(),
        healthBar = getDefaultHealthBarConfig(),
        powerBar = getDefaultPowerBarConfig(),
        secondaryPowerBar = getDefaultSecondaryPowerBarConfig(),
        castBar = getDefaultCastBarConfig(),
        border = getDefaultBorderConfig(),
        nameText = getDefaultNameTextConfig(),
        healthText = getDefaultHealthTextConfig(),
        powerText = getDefaultPowerTextConfig(),
    }
end

-- 目标框体默认配置（稍有不同）
local function getDefaultTargetFrameConfig()
    local config = getDefaultFrameConfig()
    config.portrait.style = "2D"
    return config
end

-- 焦点框体默认配置
local function getDefaultFocusFrameConfig()
    local config = getDefaultFrameConfig()
    config.healthBar.width = 150
    config.healthBar.height = 20
    config.powerBar.width = 150
    config.powerBar.height = 10
    config.portrait.enabled = false
    return config
end

-- 宠物框体默认配置
local function getDefaultPetFrameConfig()
    local config = getDefaultFrameConfig()
    config.healthBar.width = 100
    config.healthBar.height = 16
    config.powerBar.width = 100
    config.powerBar.height = 8
    config.portrait.enabled = false
    config.nameText.fontSize = 10
    return config
end

-- 目标的目标框体默认配置
local function getDefaultTargetTargetFrameConfig()
    local config = getDefaultFrameConfig()
    config.healthBar.width = 100
    config.healthBar.height = 16
    config.powerBar.enabled = false
    config.portrait.enabled = false
    config.nameText.fontSize = 10
    config.healthText.enabled = false
    return config
end

-------------------------------------------------------------------------------
-- 默认配置
-------------------------------------------------------------------------------

Database.DEFAULTS_GLOBAL = {
    enableAddon = true,
    debugMode = false,
}

Database.DEFAULTS_PROFILE = {
    frames = {
        player = getDefaultFrameConfig(),
        target = getDefaultTargetFrameConfig(),
        focus = getDefaultFocusFrameConfig(),
        pet = getDefaultPetFrameConfig(),
        targettarget = getDefaultTargetTargetFrameConfig(),
    },

    -- 职业染色全局设置
    classColors = {
        enabled = true,
        colorBackground = false,
        colorBorder = true,
        colorNPCByReaction = true,
        customColors = {
            hostile = {r = 1.0, g = 0.0, b = 0.0},
            neutral = {r = 1.0, g = 1.0, b = 0.0},
            friendly = {r = 0.0, g = 1.0, b = 0.0},
        },
    },

    -- 小地图按钮配置
    minimap = {
        show = false,
        hide = true,
        locked = false,
        radius = 80,
        angle = -45,
    },
}

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function Database:Initialize()
    EnhancedUnitFramesDB = EnhancedUnitFramesDB or {}
    EnhancedUnitFramesDBGlobal = EnhancedUnitFramesDBGlobal or {}

    self.db = EnhancedUnitFramesDB
    self.global = EnhancedUnitFramesDBGlobal

    self:ApplyDefaults()

    return true
end

-------------------------------------------------------------------------------
-- 默认值应用
-------------------------------------------------------------------------------

function Database:ApplyDefaults()
    self:MergeDefaults(self.global, self.DEFAULTS_GLOBAL)
    self:MergeDefaults(self.db, self.DEFAULTS_PROFILE)
end

function Database:MergeDefaults(tbl, defaults)
    if type(tbl) ~= "table" then return end
    if type(defaults) ~= "table" then return end

    for key, defaultValue in pairs(defaults) do
        if tbl[key] == nil then
            if type(defaultValue) == "table" then
                tbl[key] = self:CopyTable(defaultValue)
            else
                tbl[key] = defaultValue
            end
        elseif type(tbl[key]) == "table" and type(defaultValue) == "table" then
            self:MergeDefaults(tbl[key], defaultValue)
        end
    end
end

-------------------------------------------------------------------------------
-- 深拷贝
-------------------------------------------------------------------------------

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

-- 获取框体配置
function Database:GetFrameConfig(frameKey)
    return self:Get("frames", frameKey) or getDefaultFrameConfig()
end

-- 获取模块配置
function Database:GetModuleConfig(frameKey, moduleKey)
    return self:Get("frames", frameKey, moduleKey)
end

-- 设置模块配置
function Database:SetModuleConfig(frameKey, moduleKey, config)
    return self:Set(config, "frames", frameKey, moduleKey)
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

function Database:ValidateScale(scale)
    local num = tonumber(scale)
    if not num then
        return self.SCALE_DEFAULT
    end
    return math.max(self.SCALE_MIN, math.min(self.SCALE_MAX, num))
end

function Database:GetScale(frameKey)
    local scale = self:Get("frames", frameKey, "scale")
    return self:ValidateScale(scale)
end

function Database:SetScale(frameKey, scale)
    scale = self:ValidateScale(scale)
    return self:Set(scale, "frames", frameKey, "scale")
end

-------------------------------------------------------------------------------
-- 重置功能
-------------------------------------------------------------------------------

function Database:ResetProfile()
    for key, _ in pairs(self.db) do
        self.db[key] = nil
    end
    self:ApplyDefaults()
    EUF:Print("配置已重置为默认值")
end

function Database:ResetGlobal()
    for key, _ in pairs(self.global) do
        self.global[key] = nil
    end
    self:MergeDefaults(self.global, self.DEFAULTS_GLOBAL)
    EUF:Print("全局配置已重置")
end

function Database:ResetAll()
    self:ResetProfile()
    self:ResetGlobal()
end

-------------------------------------------------------------------------------
-- 重置单个框体配置
-------------------------------------------------------------------------------

function Database:ResetFrameConfig(frameKey)
    local defaults
    if frameKey == "player" then
        defaults = getDefaultFrameConfig()
    elseif frameKey == "target" then
        defaults = getDefaultTargetFrameConfig()
    elseif frameKey == "focus" then
        defaults = getDefaultFocusFrameConfig()
    elseif frameKey == "pet" then
        defaults = getDefaultPetFrameConfig()
    elseif frameKey == "targettarget" then
        defaults = getDefaultTargetTargetFrameConfig()
    else
        return
    end

    self:Set(self:CopyTable(defaults), "frames", frameKey)
end

return Database