-- SecondaryPowerBarModule.lua
-- EnhancedUnitFrames 次级能量条模块
-- 处理职业特殊能量如神圣能量、连击点、符文等

local addonName, EUF = ...

local SecondaryPowerBarModule = {}
EUF.SecondaryPowerBarModule = SecondaryPowerBarModule

-- 继承模块基类
setmetatable(SecondaryPowerBarModule, {__index = EUF.ModuleBase})

-- 职业次级能量映射
SecondaryPowerBarModule.CLASS_POWER_TYPES = {
    PALADIN = {
        powerType = Enum.PowerType.HolyPower,
        maxPower = 5,
        color = {r = 0.95, g = 0.55, b = 0.73},
        name = "神圣能量",
    },
    ROGUE = {
        powerType = Enum.PowerType.ComboPoints,
        maxPower = 5,
        color = {r = 1.00, g = 0.96, b = 0.41},
        name = "连击点",
    },
    DRUID = {
        powerType = Enum.PowerType.ComboPoints,
        maxPower = 5,
        color = {r = 1.00, g = 0.96, b = 0.41},
        name = "连击点",
    },
    DEATHKNIGHT = {
        powerType = Enum.PowerType.Runes,
        maxPower = 6,
        color = {r = 0.00, g = 0.82, b = 1.00},
        name = "符文",
        special = "runes",
    },
    MONK = {
        powerType = Enum.PowerType.Chi,
        maxPower = 5,
        color = {r = 0.71, g = 1.00, b = 0.92},
        name = "真气",
    },
    WARLOCK = {
        powerType = Enum.PowerType.SoulShards,
        maxPower = 5,
        color = {r = 0.53, g = 0.53, b = 0.93},
        name = "灵魂碎片",
    },
    MAGE = {
        powerType = Enum.PowerType.ArcaneCharges,
        maxPower = 4,
        color = {r = 0.25, g = 0.78, b = 0.92},
        name = "奥术充能",
    },
    EVOKER = {
        powerType = Enum.PowerType.Essence,
        maxPower = 5,
        color = {r = 0.20, g = 0.58, b = 0.50},
        name = "精华",
    },
}

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:New(moduleKey, frameKey, unit)
    local obj = EUF.ModuleBase.New(self, moduleKey, frameKey, unit)
    obj.powerBar = nil
    obj.powerIcons = {}
    obj.powerTypeConfig = nil
    obj.playerClass = nil
    obj.hidden = false
    return obj
end

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:Initialize(parent, config)
    if self.frameKey ~= "player" then
        -- 次级能量条仅用于玩家框体
        self.enabled = false
        return
    end

    -- 获取玩家职业
    self.playerClass = select(2, UnitClass("player"))

    -- 检查职业是否支持次级能量
    if not self.CLASS_POWER_TYPES[self.playerClass] then
        self.enabled = false
        EUF:Debug(string.format("SecondaryPowerBar: 职业 %s 不支持次级能量", self.playerClass))
        return
    end

    self.powerTypeConfig = self.CLASS_POWER_TYPES[self.playerClass]

    EUF.ModuleBase.Initialize(self, parent, config)
end

-------------------------------------------------------------------------------
-- 创建UI元素
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:CreateElements()
    local displayMode = self:GetConfigValue("displayMode", "bar")

    if displayMode == "bar" then
        self:CreateBarDisplay()
    elseif displayMode == "icons" then
        self:CreateIconDisplay()
    elseif displayMode == "runes" and self.powerTypeConfig.special == "runes" then
        self:CreateRuneDisplay()
    end

    -- 注册事件
    self:RegisterEvents()
end

-------------------------------------------------------------------------------
-- 创建条状显示
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:CreateBarDisplay()
    if not self.parent then return end

    local width = self:GetConfigValue("width", 200)
    local height = self:GetConfigValue("height", 6)

    -- 创建能量条
    self.powerBar = CreateFrame("StatusBar", nil, self.parent)
    self.powerBar:SetSize(width, height)
    self.powerBar:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", 0, -height - 2)

    -- 设置状态条纹理
    local texture = self:GetConfigValue("texture", "Blizzard")
    local texturePath = self:GetTexturePath(texture)
    self.powerBar:SetStatusBarTexture(texturePath)

    -- 设置颜色
    local color = self.powerTypeConfig.color
    self.powerBar:SetStatusBarColor(color.r, color.g, color.b, 1)

    -- 背景纹理
    local bg = self.powerBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(texturePath)
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    -- 设置范围
    self.powerBar:SetMinMaxValues(0, self.powerTypeConfig.maxPower)

    self.elements.powerBar = self.powerBar
end

-------------------------------------------------------------------------------
-- 创建图标显示
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:CreateIconDisplay()
    if not self.parent then return end

    local iconSize = self:GetConfigValue("iconSize", 16)
    local spacing = self:GetConfigValue("spacing", 2)
    local orientation = self:GetConfigValue("orientation", "HORIZONTAL")

    self.powerIcons = {}

    for i = 1, self.powerTypeConfig.maxPower do
        local icon = CreateFrame("Frame", nil, self.parent)
        icon:SetSize(iconSize, iconSize)

        if orientation == "HORIZONTAL" then
            icon:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT",
                (i - 1) * (iconSize + spacing), -iconSize - 2)
        else
            icon:SetPoint("BOTTOMRIGHT", self.parent, "BOTTOMRIGHT",
                -2, (i - 1) * (iconSize + spacing))
        end

        -- 图标纹理
        local tex = icon:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")

        -- 默认颜色（空状态）
        tex:SetVertexColor(0.2, 0.2, 0.2, 0.8)

        -- 边框
        local border = icon:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
        border:SetAllPoints()
        border:SetTexCoord(0.296875, 0.5703125, 0.1015625, 0.375)

        self.powerIcons[i] = {
            frame = icon,
            texture = tex,
            border = border,
        }

        self.elements["powerIcon" .. i] = icon
    end
end

-------------------------------------------------------------------------------
-- 创建符文显示（死亡骑士专用）
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:CreateRuneDisplay()
    if not self.parent then return end
    if self.playerClass ~= "DEATHKNIGHT" then return end

    local iconSize = self:GetConfigValue("iconSize", 20)
    local spacing = self:GetConfigValue("spacing", 4)

    self.powerIcons = {}

    for i = 1, 6 do
        local rune = CreateFrame("Frame", nil, self.parent)
        rune:SetSize(iconSize, iconSize)
        rune:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT",
            (i - 1) * (iconSize + spacing), -iconSize - 2)

        -- 符文图标
        local tex = rune:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture("Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Glow")

        -- 冷却动画
        local cooldown = CreateFrame("Cooldown", nil, rune, "CooldownFrameTemplate")
        cooldown:SetAllPoints()
        cooldown:SetHideCountdownNumbers(true)

        self.powerIcons[i] = {
            frame = rune,
            texture = tex,
            cooldown = cooldown,
            active = false,
        }

        self.elements["rune" .. i] = rune
    end
end

-------------------------------------------------------------------------------
-- 注册事件
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:RegisterEvents()
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:SetScript("OnEvent", function(frame, event, unit, powerType)
            self:OnPowerEvent(event, unit, powerType)
        end)
    end

    -- 注册能量更新事件
    self.eventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    self.eventFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    self.eventFrame:RegisterEvent("RUNE_POWER_UPDATE")

    -- 玩家登录时更新
    self.eventFrame:RegisterEvent("PLAYER_LOGIN")
end

-------------------------------------------------------------------------------
-- 能量事件处理
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:OnPowerEvent(event, unit, powerType)
    if not self.initialized or not self.enabled then return end

    if event == "RUNE_POWER_UPDATE" then
        self:UpdateRunes()
        return
    end

    if unit ~= "player" then return end

    -- 检查是否是我们要监控的能量类型
    if powerType and powerType ~= self.powerTypeConfig.powerType then
        return
    end

    self:Update()
end

-------------------------------------------------------------------------------
-- 更新
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:Update()
    if not self.initialized or not self.enabled then return end

    local power = UnitPower("player", self.powerTypeConfig.powerType)
    local maxPower = UnitPowerMax("player", self.powerTypeConfig.powerType)

    -- 检测机密值（12.0合规）
    if EUF.SecretSafe.IsSecretValue(power) or EUF.SecretSafe.IsSecretValue(maxPower) then
        return
    end

    if self.powerBar then
        self.powerBar:SetMinMaxValues(0, maxPower)
        self.powerBar:SetValue(power)
    end

    if self.powerIcons and #self.powerIcons > 0 then
        self:UpdateIcons(power, maxPower)
    end
end

-------------------------------------------------------------------------------
-- 更新图标显示
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:UpdateIcons(power, maxPower)
    local color = self.powerTypeConfig.color

    for i, iconData in ipairs(self.powerIcons) do
        if i <= power then
            -- 已激活
            iconData.texture:SetVertexColor(color.r, color.g, color.b, 1)
        else
            -- 未激活
            iconData.texture:SetVertexColor(0.2, 0.2, 0.2, 0.8)
        end
    end
end

-------------------------------------------------------------------------------
-- 更新符文显示
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:UpdateRunes()
    if not self.powerIcons then return end

    for i = 1, 6 do
        local runeData = self.powerIcons[i]
        if not runeData then break end

        local start, duration, runeReady = GetRuneCooldown(i)

        if runeReady then
            -- 符文可用
            runeData.texture:SetVertexColor(0.00, 0.82, 1.00, 1)
            runeData.cooldown:Hide()
        else
            -- 符文冷却中
            runeData.texture:SetVertexColor(0.3, 0.3, 0.3, 0.8)
            if start and duration then
                runeData.cooldown:SetCooldown(start, duration)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- 应用配置
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:ApplyConfig(config)
    self.config = config or EUF.Database:GetModuleConfig(self.frameKey, self.moduleKey)

    -- 检查是否隐藏（优先级最高）
    local hidden = self:GetConfigValue("hidden", false)
    if hidden then
        self:HideFrame()
        return
    end

    -- 检查是否启用
    local enabled = self:GetConfigValue("enabled", true)
    if not enabled then
        self:Hide()
        return
    end

    -- 应用尺寸
    if self.powerBar then
        local width = self:GetConfigValue("width", 200)
        local height = self:GetConfigValue("height", 6)
        self.powerBar:SetSize(width, height)
    end

    -- 更新显示
    self:Show()
end

-------------------------------------------------------------------------------
-- 刷新
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:Refresh()
    self:Update()
end

-------------------------------------------------------------------------------
-- 获取材质路径
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:GetTexturePath(textureName)
    local textures = {
        Blizzard = "Interface\\TargetingFrame\\UI-StatusBar",
        Flat = "Interface\\Buttons\\WHITE8X8",
    }
    return textures[textureName] or textures.Blizzard
end

-------------------------------------------------------------------------------
-- 战斗结束处理
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:OnCombatEnd()
    EUF.ModuleBase.OnCombatEnd(self)
    self:Update()
end

-------------------------------------------------------------------------------
-- 清理
-------------------------------------------------------------------------------

function SecondaryPowerBarModule:Hide()
    if self.powerBar then
        self.powerBar:Hide()
    end

    for _, iconData in pairs(self.powerIcons) do
        if iconData.frame then
            iconData.frame:Hide()
        end
    end

    self.enabled = false
end

function SecondaryPowerBarModule:Show()
    if self.powerBar then
        self.powerBar:Show()
    end

    for _, iconData in pairs(self.powerIcons) do
        if iconData.frame then
            iconData.frame:Show()
        end
    end

    self.enabled = true
    self.hidden = false
    self:Update()
end

-- 完全隐藏次级能量条框体（隐藏功能）
function SecondaryPowerBarModule:HideFrame()
    if self.powerBar then
        self.powerBar:Hide()
        self.powerBar:SetAlpha(0)
    end

    for _, iconData in pairs(self.powerIcons) do
        if iconData.frame then
            iconData.frame:Hide()
            iconData.frame:SetAlpha(0)
        end
    end

    self.enabled = false
    self.hidden = true
end

return SecondaryPowerBarModule