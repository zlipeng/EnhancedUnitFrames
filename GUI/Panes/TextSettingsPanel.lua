-- TextSettingsPanel.lua
-- EnhancedUnitFrames 文字配置子面板
-- 提供文字详细配置

local addonName, EUF = ...

local TextSettingsPanel = {}
EUF.TextSettingsPanel = TextSettingsPanel

-- 模块状态
TextSettingsPanel.initialized = false

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function TextSettingsPanel:Initialize()
    if self.initialized then return end
    self.initialized = true
end

-------------------------------------------------------------------------------
-- 创建文字设置面板
-------------------------------------------------------------------------------

function TextSettingsPanel:CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetSize(320, 450)

    -- 标题
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    title:SetText("文字设置")

    -- 警告提示
    local warning = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    warning:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -35)
    warning:SetText("|cFFFF0000⚠ 12.0 注意: 某些文字格式在团本/大秘境中可能受限|r")

    local yOffset = -60

    -- 玩家框体设置标题
    local playerTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    playerTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    playerTitle:SetText("|cFFFFFFFF玩家框体:|r")
    yOffset = yOffset - 25

    -- 玩家生命值格式
    local playerHealthLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    playerHealthLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, yOffset)
    playerHealthLabel:SetText("生命值格式:")

    local formats = {"DEFAULT", "PERCENT", "CURRENT", "CURRENT/MAX", "DEFICIT", "HIDDEN"}
    local playerHealthDropdown = self:CreateFormatDropdown(panel, formats, function(format)
        EUF.TextSettings:SetHealthTextFormat("player", format)
    end)
    playerHealthDropdown:SetPoint("LEFT", playerHealthLabel, "RIGHT", 10, 0)
    yOffset = yOffset - 35

    -- 目标框体设置标题
    local targetTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    targetTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    targetTitle:SetText("|cFFFFFFFF目标框体:|r")
    yOffset = yOffset - 25

    -- 目标生命值格式
    local targetHealthLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    targetHealthLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, yOffset)
    targetHealthLabel:SetText("生命值格式:")

    local targetHealthDropdown = self:CreateFormatDropdown(panel, formats, function(format)
        EUF.TextSettings:SetHealthTextFormat("target", format)
    end)
    targetHealthDropdown:SetPoint("LEFT", targetHealthLabel, "RIGHT", 10, 0)
    yOffset = yOffset - 40

    -- 分隔线
    local sep = panel:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    sep:SetSize(300, 1)
    sep:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    yOffset = yOffset - 15

    -- 字体设置标题
    local fontTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    fontTitle:SetText("|cFFFFFFFF字体设置:|r")
    yOffset = yOffset - 25

    -- 字体选择
    local fontLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, yOffset)
    fontLabel:SetText("字体:")

    local fonts = {"Friz Quadrata TT", "Arial Narrow", "Skurri", "Morpheus"}
    local fontDropdown = self:CreateFontDropdown(panel, fonts, function(fontName)
        -- 应用字体设置
        if EUF.TextSettings then
            -- 更新数据库
            EUF.Database:Set(fontName, "text", "fonts", "player", "name", "font")
            EUF.Database:Set(fontName, "text", "fonts", "target", "name", "font")
            EUF.TextSettings:Refresh()
        end
    end)
    fontDropdown:SetPoint("LEFT", fontLabel, "RIGHT", 10, 0)
    yOffset = yOffset - 35

    -- 字体大小滑块
    local sizeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, yOffset)
    sizeLabel:SetText("字体大小:")

    local sizeSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    sizeSlider:SetPoint("LEFT", sizeLabel, "RIGHT", 10, 0)
    sizeSlider:SetWidth(120)
    sizeSlider:SetMinMaxValues(8, 24)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetObeyStepOnDrag(true)
    sizeSlider:SetValue(12)

    _G[sizeSlider:GetName() .. "Low"]:SetText("8")
    _G[sizeSlider:GetName() .. "High"]:SetText("24")
    _G[sizeSlider:GetName() .. "Text"]:SetText("12")

    sizeSlider:SetScript("OnValueChanged", function(self, value)
        _G[self:GetName() .. "Text"]:SetText(math.floor(value))
    end)

    sizeSlider:SetScript("OnMouseUp", function(self)
        local value = math.floor(self:GetValue())
        EUF.Database:Set(value, "text", "fonts", "player", "name", "size")
        EUF.Database:Set(value, "text", "fonts", "target", "name", "size")
        EUF.TextSettings:Refresh()
    end)

    return panel
end

-------------------------------------------------------------------------------
-- 创建格式下拉菜单
-------------------------------------------------------------------------------

function TextSettingsPanel:CreateFormatDropdown(parent, formats, onSelect)
    local formatNames = {
        ["DEFAULT"] = "暴雪默认",
        ["PERCENT"] = "百分比",
        ["CURRENT"] = "当前值",
        ["CURRENT/MAX"] = "当前/最大",
        ["DEFICIT"] = "亏损值",
        ["HIDDEN"] = "隐藏",
    }

    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetSize(150, 30)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, format in ipairs(formats) do
            info.text = formatNames[format] or format
            info.value = format
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                if onSelect then
                    onSelect(self.value)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedValue(dropdown, "DEFAULT")
    UIDropDownMenu_SetWidth(dropdown, 100)

    return dropdown
end

-------------------------------------------------------------------------------
-- 创建字体下拉菜单
-------------------------------------------------------------------------------

function TextSettingsPanel:CreateFontDropdown(parent, fonts, onSelect)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetSize(180, 30)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, font in ipairs(fonts) do
            info.text = font
            info.value = font
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                if onSelect then
                    onSelect(self.value)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedValue(dropdown, fonts[1] or "Friz Quadrata TT")
    UIDropDownMenu_SetWidth(dropdown, 140)

    return dropdown
end

return TextSettingsPanel