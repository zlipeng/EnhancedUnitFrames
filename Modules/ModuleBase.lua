-- ModuleBase.lua
-- EnhancedUnitFrames 模块基类
-- 所有框体模块的抽象基类

local addonName, EUF = ...

local ModuleBase = {}
EUF.ModuleBase = ModuleBase

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function ModuleBase:New(moduleKey, frameKey, unit)
    local obj = {
        moduleKey = moduleKey,   -- 模块标识 (如 "healthBar", "powerBar")
        frameKey = frameKey,     -- 框体标识 (如 "player", "target")
        unit = unit,             -- 单位标识 (如 "player", "target")
        config = nil,            -- 当前配置
        parent = nil,            -- 父框架引用
        elements = {},           -- 创建的UI元素
        initialized = false,     -- 是否已初始化
        enabled = true,          -- 是否启用
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function ModuleBase:Initialize(parent, config)
    if self.initialized then return end

    self.parent = parent
    self.config = config or EUF.Database:GetModuleConfig(self.frameKey, self.moduleKey)

    -- 创建UI元素（子类实现）
    -- 始终创建元素，即使模块未启用
    self:CreateElements()

    -- 标记为已初始化
    self.initialized = true

    -- 检查是否启用
    if not self.config or not self.config.enabled then
        self.enabled = false
        EUF:Debug(string.format("ModuleBase: %s.%s 初始化完成（未启用）", self.frameKey, self.moduleKey))
        return
    end

    -- 应用初始配置
    self:ApplyConfig(self.config)

    self.enabled = true
    EUF:Debug(string.format("ModuleBase: %s.%s 初始化完成", self.frameKey, self.moduleKey))
end

-------------------------------------------------------------------------------
-- 子类必须实现的方法
-------------------------------------------------------------------------------

-- 创建UI元素
function ModuleBase:CreateElements()
    -- 子类实现
end

-- 应用配置
function ModuleBase:ApplyConfig(config)
    -- 子类实现
    self.config = config
end

-- 刷新显示
function ModuleBase:Refresh()
    if not self.initialized or not self.enabled then return end
    -- 子类实现
end

-- 更新数据（单位数据变化时调用）
function ModuleBase:Update()
    if not self.initialized or not self.enabled then return end
    -- 子类实现
end

-------------------------------------------------------------------------------
-- 显示/隐藏
-------------------------------------------------------------------------------

function ModuleBase:Show()
    if not self.initialized then return end

    if InCombatLockdown() then
        self.pendingShow = true
        return
    end

    for _, element in pairs(self.elements) do
        if element and element.Show then
            element:Show()
        end
    end
    self.enabled = true
end

function ModuleBase:Hide()
    if not self.initialized then return end

    if InCombatLockdown() then
        self.pendingShow = false
        return
    end

    for _, element in pairs(self.elements) do
        if element and element.Hide then
            element:Hide()
        end
    end
    self.enabled = false
end

function ModuleBase:SetEnabled(enabled)
    if not self.initialized then return end

    -- 更新配置
    if self.config then
        self.config.enabled = enabled
    end

    if enabled then
        self:Show()
        self:Refresh()
    else
        self:Hide()
    end
end

-------------------------------------------------------------------------------
-- 禁用模块（完全禁用，包括暴雪元素）
-------------------------------------------------------------------------------

function ModuleBase:Disable()
    self.enabled = false
    self:Hide()
end

-------------------------------------------------------------------------------
-- 启用模块
-------------------------------------------------------------------------------

function ModuleBase:Enable()
    if not self.initialized then return end
    self.enabled = true
    self:Show()
    self:Refresh()
end

-------------------------------------------------------------------------------
-- 尺寸设置
-------------------------------------------------------------------------------

function ModuleBase:SetSize(width, height)
    if not self.initialized then return end

    if InCombatLockdown() then
        self.pendingSize = {width = width, height = height}
        return
    end

    for _, element in pairs(self.elements) do
        if element and element.SetSize then
            element:SetSize(width, height)
        end
    end
end

function ModuleBase:SetWidth(width)
    if not self.initialized then return end
    self:SetSize(width, self.config and self.config.height or 20)
end

function ModuleBase:SetHeight(height)
    if not self.initialized then return end
    self:SetSize(self.config and self.config.width or 100, height)
end

-------------------------------------------------------------------------------
-- 战斗结束后处理待执行操作
-------------------------------------------------------------------------------

function ModuleBase:OnCombatEnd()
    if self.pendingShow ~= nil then
        if self.pendingShow then
            self:Show()
        else
            self:Hide()
        end
        self.pendingShow = nil
    end

    if self.pendingSize then
        self:SetSize(self.pendingSize.width, self.pendingSize.height)
        self.pendingSize = nil
    end
end

-------------------------------------------------------------------------------
-- 工具方法
-------------------------------------------------------------------------------

-- 获取配置值（带默认值）
function ModuleBase:GetConfigValue(key, default)
    if self.config and self.config[key] ~= nil then
        return self.config[key]
    end
    return default
end

-- 创建纹理
function ModuleBase:CreateTexture(name, layer, parent)
    parent = parent or self.parent
    local texture = parent:CreateTexture(name, layer or "ARTWORK")
    return texture
end

-- 创建字体字符串
function ModuleBase:CreateFontString(name, layer, parent)
    parent = parent or self.parent
    local fontString = parent:CreateFontString(name, layer or "ARTWORK")
    return fontString
end

return ModuleBase