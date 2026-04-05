-- FrameBase.lua
-- EnhancedUnitFrames 框体基类
-- 管理单个单位框体的所有模块

local addonName, EUF = ...

local FrameBase = {}
EUF.FrameBase = FrameBase

-- 框体到暴雪框体的映射
FrameBase.BLIZZARD_FRAMES = {
    player = "PlayerFrame",
    target = "TargetFrame",
    focus = "FocusFrame",
    pet = "PetFrame",
    targettarget = "TargetFrameToT",
}

-- 框体到单位的映射
FrameBase.UNIT_MAP = {
    player = "player",
    target = "target",
    focus = "focus",
    pet = "pet",
    targettarget = "targettarget",
}

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function FrameBase:New(frameKey)
    local obj = {
        frameKey = frameKey,
        unit = FrameBase.UNIT_MAP[frameKey],
        blizzardFrame = nil,
        config = nil,
        modules = {},
        initialized = false,
        enabled = false,
        eventFrame = nil,
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function FrameBase:Initialize()
    if self.initialized then return end

    -- 获取暴雪框体
    self.blizzardFrame = _G[FrameBase.BLIZZARD_FRAMES[self.frameKey]]
    if not self.blizzardFrame then
        EUF:Debug(string.format("FrameBase: %s 暴雪框体不存在", self.frameKey))
        return
    end

    -- 获取配置
    self.config = EUF.Database:GetFrameConfig(self.frameKey)
    if not self.config then
        EUF:Debug(string.format("FrameBase: %s 配置不存在", self.frameKey))
        return
    end

    -- 始终加载模块，即使框体未启用
    -- 这样用户可以在运行时启用框体而无需重载
    self:LoadModules()

    -- 创建事件框架
    self:CreateEventFrame()

    -- 应用初始配置
    self:ApplyConfig()

    self.initialized = true

    -- 根据配置决定是否启用
    if self.config.enabled then
        self.enabled = true
        EUF:Debug(string.format("FrameBase: %s 初始化完成并启用", self.frameKey))
    else
        self.enabled = false
        -- 如果未启用，隐藏所有模块
        for _, module in pairs(self.modules) do
            if module and module.Disable then
                module:Disable()
            end
        end
        EUF:Debug(string.format("FrameBase: %s 初始化完成但未启用", self.frameKey))
    end
end

-------------------------------------------------------------------------------
-- 加载模块
-------------------------------------------------------------------------------

function FrameBase:LoadModules()
    -- 头像模块
    if EUF.PortraitModule then
        self.modules.portrait = EUF.PortraitModule:New("portrait", self.frameKey, self.unit)
        self.modules.portrait:Initialize(self.blizzardFrame, self.config.portrait)
    end

    -- 生命条模块
    if EUF.HealthBarModule then
        self.modules.healthBar = EUF.HealthBarModule:New("healthBar", self.frameKey, self.unit)
        self.modules.healthBar:Initialize(self.blizzardFrame, self.config.healthBar)
    end

    -- 能量条模块
    if EUF.PowerBarModule then
        self.modules.powerBar = EUF.PowerBarModule:New("powerBar", self.frameKey, self.unit)
        self.modules.powerBar:Initialize(self.blizzardFrame, self.config.powerBar)
    end

    -- 名称文字模块
    if EUF.NameTextModule then
        self.modules.nameText = EUF.NameTextModule:New("nameText", self.frameKey, self.unit)
        self.modules.nameText:Initialize(self.blizzardFrame, self.config.nameText)
    end

    -- 生命值文字模块
    if EUF.HealthTextModule then
        self.modules.healthText = EUF.HealthTextModule:New("healthText", self.frameKey, self.unit)
        self.modules.healthText:Initialize(self.blizzardFrame, self.config.healthText)
    end

    -- 能量值文字模块
    if EUF.PowerTextModule then
        self.modules.powerText = EUF.PowerTextModule:New("powerText", self.frameKey, self.unit)
        self.modules.powerText:Initialize(self.blizzardFrame, self.config.powerText)
    end

    -- 次级能量条模块（仅玩家）
    if self.frameKey == "player" and EUF.SecondaryPowerBarModule then
        self.modules.secondaryPowerBar = EUF.SecondaryPowerBarModule:New("secondaryPowerBar", self.frameKey, self.unit)
        self.modules.secondaryPowerBar:Initialize(self.blizzardFrame, self.config.secondaryPowerBar)
    end

    -- 施法条模块
    if EUF.CastBarModule then
        self.modules.castBar = EUF.CastBarModule:New("castBar", self.frameKey, self.unit)
        self.modules.castBar:Initialize(self.blizzardFrame, self.config.castBar)
    end

    -- 边框模块
    if EUF.BorderModule then
        self.modules.border = EUF.BorderModule:New("border", self.frameKey, self.unit)
        self.modules.border:Initialize(self.blizzardFrame, self.config.border)
    end
end

-------------------------------------------------------------------------------
-- 应用配置
-------------------------------------------------------------------------------

function FrameBase:ApplyConfig()
    -- 应用各模块配置
    for moduleName, module in pairs(self.modules) do
        if module and self.config[moduleName] then
            module:ApplyConfig(self.config[moduleName])
        end
    end
end

-------------------------------------------------------------------------------
-- 事件框架
-------------------------------------------------------------------------------

function FrameBase:CreateEventFrame()
    local eventFrame = CreateFrame("Frame")
    self.eventFrame = eventFrame

    -- 单位特定事件（使用 RegisterUnitEvent）
    local unitEvents = {
        "UNIT_HEALTH",
        "UNIT_MAXHEALTH",
        "UNIT_POWER_UPDATE",
        "UNIT_MAXPOWER",
        "UNIT_DISPLAYPOWER",
        "UNIT_NAME_UPDATE",
        "UNIT_FACTION",
        "UNIT_CLASSIFICATION_CHANGED",
        "UNIT_PET",
    }

    for _, event in ipairs(unitEvents) do
        eventFrame:RegisterUnitEvent(event, self.unit)
    end

    -- 全局事件（使用 RegisterEvent）
    -- PLAYER_TARGET_CHANGED 和 PLAYER_FOCUS_CHANGED 是全局事件
    if self.frameKey == "target" or self.frameKey == "targettarget" then
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    end

    if self.frameKey == "focus" then
        eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    end

    eventFrame:SetScript("OnEvent", function(frame, event, unit, ...)
        self:OnEvent(event, unit, ...)
    end)
end

-------------------------------------------------------------------------------
-- 事件处理
-------------------------------------------------------------------------------

function FrameBase:OnEvent(event, unit, ...)
    if not self.initialized or not self.enabled then return end

    -- 验证单位
    if unit and unit ~= self.unit then return end

    -- 生命值相关事件
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if self.modules.healthBar then
            self.modules.healthBar:Update()
        end
        if self.modules.healthText then
            self.modules.healthText:Update()
        end

    -- 能量相关事件
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        if self.modules.powerBar then
            self.modules.powerBar:Update()
        end
        if self.modules.powerText then
            self.modules.powerText:Update()
        end

    -- 名称更新
    elseif event == "UNIT_NAME_UPDATE" then
        if self.modules.nameText then
            self.modules.nameText:Update()
        end

    -- 阵营变化
    elseif event == "UNIT_FACTION" or event == "UNIT_CLASSIFICATION_CHANGED" then
        self:Refresh()

    -- 目标切换
    elseif event == "PLAYER_TARGET_CHANGED" then
        if self.frameKey == "target" or self.frameKey == "targettarget" then
            self:Refresh()
        end

    -- 焦点切换
    elseif event == "PLAYER_FOCUS_CHANGED" then
        if self.frameKey == "focus" then
            self:Refresh()
        end
    end
end

-------------------------------------------------------------------------------
-- 刷新
-------------------------------------------------------------------------------

function FrameBase:Refresh()
    if not self.initialized or not self.enabled then return end

    for _, module in pairs(self.modules) do
        if module and module.Refresh then
            module:Refresh()
        end
    end
end

-------------------------------------------------------------------------------
-- 启用/禁用
-------------------------------------------------------------------------------

function FrameBase:SetEnabled(enabled)
    if enabled then
        self:Enable()
    else
        self:Disable()
    end
end

function FrameBase:Enable()
    if not self.initialized then
        self:Initialize()
    end

    self.enabled = true
    self:Refresh()

    EUF:Debug(string.format("FrameBase: %s 已启用", self.frameKey))
end

function FrameBase:Disable()
    self.enabled = false

    -- 隐藏所有模块
    for _, module in pairs(self.modules) do
        if module and module.Hide then
            module:Hide()
        end
    end

    EUF:Debug(string.format("FrameBase: %s 已禁用", self.frameKey))
end

-------------------------------------------------------------------------------
-- 战斗结束处理
-------------------------------------------------------------------------------

function FrameBase:OnCombatEnd()
    -- 通知各模块
    for _, module in pairs(self.modules) do
        if module and module.OnCombatEnd then
            module:OnCombatEnd()
        end
    end
end

-------------------------------------------------------------------------------
-- 配置更新
-------------------------------------------------------------------------------

function FrameBase:UpdateConfig()
    self.config = EUF.Database:GetFrameConfig(self.frameKey)
    self:ApplyConfig()
end

function FrameBase:UpdateModuleConfig(moduleKey)
    local module = self.modules[moduleKey]
    if module then
        local config = EUF.Database:GetModuleConfig(self.frameKey, moduleKey)
        module:ApplyConfig(config)
    end
end

return FrameBase