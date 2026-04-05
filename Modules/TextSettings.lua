-- TextSettings.lua
-- EnhancedUnitFrames 文字配置模块
-- 支持自定义名称、生命值、法力值的字体和格式
-- ⚠️ 12.0 限制：文字格式在竞技性战斗中可能受机密值限制

local addonName, EUF = ...

local TextSettings = {}
EUF.TextSettings = TextSettings

-- 字体定义
TextSettings.FONTS = {
    ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
    ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
    ["Skurri"] = "Fonts\\SKURRI.TTF",
    ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
}

-- 文字格式（12.0 部分受限）
TextSettings.HEALTH_FORMATS = {
    ["DEFAULT"] = "暴雪默认",
    ["PERCENT"] = "百分比",
    ["CURRENT"] = "当前值",
    ["CURRENT/MAX"] = "当前/最大",
    ["DEFICIT"] = "亏损值",
    ["HIDDEN"] = "隐藏",
}

-- 模块状态
TextSettings.initialized = false
TextSettings.db = nil
TextSettings.hooksRegistered = {}

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function TextSettings:Initialize(db)
    if self.initialized then return end

    self.db = db and db.text
    if not self.db then
        EUF:Debug("TextSettings: 数据库配置不存在")
        return
    end

    -- 应用当前设置
    self:ApplyAllSettings()

    self.initialized = true
    EUF:Debug("TextSettings: 模块初始化完成")
end

-------------------------------------------------------------------------------
-- 核心功能
-------------------------------------------------------------------------------

-- 设置字体
function TextSettings:SetFont(fontString, fontName, fontSize, fontFlags)
    if not fontString then return end

    local fontPath = self.FONTS[fontName] or self.FONTS["Friz Quadrata TT"]
    fontSize = tonumber(fontSize) or 12
    fontFlags = fontFlags or ""

    -- SetFont 是纯视觉操作，12.0 允许
    fontString:SetFont(fontPath, fontSize, fontFlags)
end

-- 设置文字颜色
function TextSettings:SetTextColor(fontString, r, g, b, a)
    if not fontString then return end
    fontString:SetTextColor(r or 1, g or 1, b or 1, a or 1)
end

-- 设置文字位置
function TextSettings:SetTextPosition(fontString, point, relativeTo, relativePoint, x, y)
    if not fontString then return end

    fontString:ClearAllPoints()
    if relativeTo then
        fontString:SetPoint(point, relativeTo, relativePoint or point, x or 0, y or 0)
    else
        fontString:SetPoint(point, x or 0, y or 0)
    end
end

-------------------------------------------------------------------------------
-- 健康值文字格式（12.0 限制版）
-------------------------------------------------------------------------------

-- 设置健康值文字格式
function TextSettings:SetHealthTextFormat(unit, formatType)
    if not self.db then return end

    -- 保存格式设置
    if not self.db.formats then
        self.db.formats = {}
    end
    if not self.db.formats[unit] then
        self.db.formats[unit] = {}
    end
    self.db.formats[unit].health = formatType

    -- 获取对应的文字对象
    local fontString = self:GetHealthFontString(unit)
    if not fontString then return end

    -- 隐藏格式
    if formatType == "HIDDEN" then
        fontString:Hide()
        return
    end

    fontString:Show()

    -- 如果是默认格式，不需要自定义 Hook
    if formatType == "DEFAULT" then
        return
    end

    -- 注册自定义格式化器
    self:RegisterTextFormatter(unit, formatType, fontString)
end

-- 获取健康值文字对象
function TextSettings:GetHealthFontString(unit)
    if unit == "player" then
        return PlayerFrameHealthBarText
    elseif unit == "target" then
        return TargetFrameHealthBarText
    elseif unit == "focus" and FocusFrame then
        return FocusFrameHealthBarText
    end
    return nil
end

-- 注册文字格式化器
-- ⚠️ 12.0 注意：自定义格式可能因机密值而失败
function TextSettings:RegisterTextFormatter(unit, formatType, fontString)
    local hookKey = unit .. "_health"

    -- 避免重复注册
    if self.hooksRegistered[hookKey] then
        return
    end

    -- Hook 暴雪的文字更新函数
    local updateFunc
    if unit == "player" then
        updateFunc = "TextStatusBar_UpdateTextString"
    elseif unit == "target" then
        updateFunc = "TextStatusBar_UpdateTextString"
    end

    if not updateFunc then return end

    -- 使用安全后钩
    hooksecurefunc(updateFunc, function(statusBar)
        -- 检查是否是目标状态条
        local targetBar
        if unit == "player" then
            targetBar = PlayerFrameHealthBar
        elseif unit == "target" then
            targetBar = TargetFrameHealthBar
        elseif unit == "focus" then
            targetBar = FocusFrameHealthBar
        end

        if statusBar ~= targetBar then
            return
        end

        -- 检查当前格式设置
        local currentFormat = self.db and self.db.formats
            and self.db.formats[unit] and self.db.formats[unit].health

        if currentFormat ~= formatType then
            return
        end

        -- 尝试格式化文字
        self:FormatHealthText(unit, formatType, fontString, statusBar)
    end)

    self.hooksRegistered[hookKey] = true
end

-- 格式化健康值文字
-- ⚠️ 12.0：如果遇到机密值，保持暴雪默认显示
function TextSettings:FormatHealthText(unit, formatType, fontString, statusBar)
    if not fontString or not statusBar then return end

    -- 尝试从 StatusBar 获取值
    local min, max = statusBar:GetMinMaxValues()
    local value = statusBar:GetValue()

    -- 检查是否为机密值
    if EUF.SecretSafe.IsSecretValue(min) or
       EUF.SecretSafe.IsSecretValue(max) or
       EUF.SecretSafe.IsSecretValue(value) then
        -- 遇到机密值，保持暴雪默认显示
        EUF:Debug("TextSettings: 检测到机密值，使用默认格式")
        return
    end

    -- 安全转换
    min = tonumber(min) or 0
    max = tonumber(max) or 1
    value = tonumber(value) or 0

    local text = ""

    if formatType == "PERCENT" then
        if max > 0 then
            local percent = (value / max) * 100
            text = string.format("%.0f%%", percent)
        end
    elseif formatType == "CURRENT" then
        text = EUF.Utils.FormatNumber(value)
    elseif formatType == "CURRENT/MAX" then
        text = string.format("%s / %s",
            EUF.Utils.FormatNumber(value),
            EUF.Utils.FormatNumber(max))
    elseif formatType == "DEFICIT" then
        local deficit = max - value
        if deficit > 0 then
            text = "-" .. EUF.Utils.FormatNumber(deficit)
        else
            text = ""
        end
    end

    if text ~= "" then
        fontString:SetText(text)
    end
end

-------------------------------------------------------------------------------
-- 应用所有设置
-------------------------------------------------------------------------------

function TextSettings:ApplyAllSettings()
    if not self.db then return end

    -- 应用字体设置
    if self.db.fonts then
        for unit, settings in pairs(self.db.fonts) do
            self:ApplyFontSettings(unit, settings)
        end
    end

    -- 应用格式设置
    if self.db.formats then
        for unit, formats in pairs(self.db.formats) do
            if formats.health then
                self:SetHealthTextFormat(unit, formats.health)
            end
        end
    end

    -- 应用颜色设置
    if self.db.colors then
        for unit, colors in pairs(self.db.colors) do
            self:ApplyColorSettings(unit, colors)
        end
    end

    EUF:Debug("TextSettings: 所有设置已应用")
end

-- 应用字体设置到单位
function TextSettings:ApplyFontSettings(unit, settings)
    local nameFont, healthFont, manaFont

    if unit == "player" then
        nameFont = PlayerNameText
        healthFont = PlayerFrameHealthBarText
        manaFont = PlayerFrameManaBarText
    elseif unit == "target" then
        nameFont = TargetFrame.Name or TargetNameText
        healthFont = TargetFrameHealthBarText
        manaFont = TargetFrameManaBarText
    elseif unit == "focus" and FocusFrame then
        nameFont = FocusFrame.name
        healthFont = FocusFrameHealthBarText
        manaFont = FocusFrameManaBarText
    end

    if settings.name then
        self:SetFont(nameFont, settings.name.font, settings.name.size, settings.name.flags)
    end
    if settings.health then
        self:SetFont(healthFont, settings.health.font, settings.health.size, settings.health.flags)
    end
    if settings.mana then
        self:SetFont(manaFont, settings.mana.font, settings.mana.size, settings.mana.flags)
    end
end

-- 应用颜色设置到单位
function TextSettings:ApplyColorSettings(unit, colors)
    local nameFont, healthFont

    if unit == "player" then
        nameFont = PlayerNameText
        healthFont = PlayerFrameHealthBarText
    elseif unit == "target" then
        nameFont = TargetFrame.Name or TargetNameText
        healthFont = TargetFrameHealthBarText
    elseif unit == "focus" and FocusFrame then
        nameFont = FocusFrame.name
        healthFont = FocusFrameHealthBarText
    end

    if colors.name and nameFont then
        self:SetTextColor(nameFont, colors.name.r, colors.name.g, colors.name.b)
    end
    if colors.health and healthFont then
        self:SetTextColor(healthFont, colors.health.r, colors.health.g, colors.health.b)
    end
end

-------------------------------------------------------------------------------
-- 辅助函数
-------------------------------------------------------------------------------

-- 获取字体列表
function TextSettings:GetFontList()
    local list = {}
    for name, _ in pairs(self.FONTS) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

-- 获取健康值格式列表
function TextSettings:GetHealthFormatList()
    local list = {}
    for format, name in pairs(self.HEALTH_FORMATS) do
        table.insert(list, { value = format, text = name })
    end
    table.sort(list, function(a, b) return a.text < b.text end)
    return list
end

-- 刷新设置
function TextSettings:Refresh()
    self:ApplyAllSettings()
end

return TextSettings