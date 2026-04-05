-- ClassColorsPanel.lua
-- EnhancedUnitFrames 职业染色子面板
-- 提供职业染色详细配置

local addonName, EUF = ...

local ClassColorsPanel = {}
EUF.ClassColorsPanel = ClassColorsPanel

-- 模块状态
ClassColorsPanel.initialized = false

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function ClassColorsPanel:Initialize()
    if self.initialized then return end

    -- 子面板由 OptionsPanel 集成，这里只是提供额外功能

    self.initialized = true
end

-------------------------------------------------------------------------------
-- 创建详细面板（用于自定义GUI）
-------------------------------------------------------------------------------

function ClassColorsPanel:CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetSize(300, 400)

    -- 标题
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    title:SetText("职业染色设置")

    -- 启用开关
    local enabledCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enabledCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -40)
    enabledCheck.text = enabledCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    enabledCheck.text:SetPoint("LEFT", enabledCheck, "RIGHT", 5, 0)
    enabledCheck.text:SetText("启用职业染色")
    enabledCheck:SetChecked(EUF.Database:Get("classColors", "enabled"))

    enabledCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        EUF.Database:Set(checked and true or false, "classColors", "enabled")
        EUF.ClassColors:Refresh()
    end)

    -- 染色背景
    local bgCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    bgCheck:SetPoint("TOPLEFT", enabledCheck, "BOTTOMLEFT", 0, -5)
    bgCheck.text = bgCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    bgCheck.text:SetPoint("LEFT", bgCheck, "RIGHT", 5, 0)
    bgCheck.text:SetText("染色背景")
    bgCheck:SetChecked(EUF.Database:Get("classColors", "colorBackground"))

    bgCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        EUF.Database:Set(checked and true or false, "classColors", "colorBackground")
        EUF.ClassColors:Refresh()
    end)

    -- 染色边框
    local borderCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    borderCheck:SetPoint("TOPLEFT", bgCheck, "BOTTOMLEFT", 0, -5)
    borderCheck.text = borderCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    borderCheck.text:SetPoint("LEFT", borderCheck, "RIGHT", 5, 0)
    borderCheck.text:SetText("染色边框")
    borderCheck:SetChecked(EUF.Database:Get("classColors", "colorBorder"))

    borderCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        EUF.Database:Set(checked and true or false, "classColors", "colorBorder")
        EUF.ClassColors:Refresh()
    end)

    -- NPC反应色
    local npcCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    npcCheck:SetPoint("TOPLEFT", borderCheck, "BOTTOMLEFT", 0, -5)
    npcCheck.text = npcCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    npcCheck.text:SetPoint("LEFT", npcCheck, "RIGHT", 5, 0)
    npcCheck.text:SetText("NPC使用反应色")
    npcCheck:SetChecked(EUF.Database:Get("classColors", "colorNPCByReaction"))

    npcCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        EUF.Database:Set(checked and true or false, "classColors", "colorNPCByReaction")
        EUF.ClassColors:Refresh()
    end)

    -- 分隔线
    local separator = panel:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("TOPLEFT", npcCheck, "BOTTOMLEFT", 0, -15)
    separator:SetSize(280, 1)
    separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)

    -- 自定义颜色标题
    local colorTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    colorTitle:SetPoint("TOPLEFT", separator, "BOTTOMLEFT", 0, -10)
    colorTitle:SetText("自定义反应色:")

    -- 敌对颜色
    local hostileLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hostileLabel:SetPoint("TOPLEFT", colorTitle, "BOTTOMLEFT", 0, -10)
    hostileLabel:SetText("敌对:")

    local hostileColor = EUF.Database:Get("classColors", "customColors", "hostile")
    local hostileBtn = EUF.ColorPicker:CreateButton(panel, hostileColor, function(r, g, b)
        EUF.Database:Set({r = r, g = g, b = b}, "classColors", "customColors", "hostile")
    end, "选择敌对单位颜色")
    hostileBtn:SetPoint("LEFT", hostileLabel, "RIGHT", 10, 0)

    -- 中立颜色
    local neutralLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    neutralLabel:SetPoint("TOPLEFT", hostileLabel, "BOTTOMLEFT", 0, -10)
    neutralLabel:SetText("中立:")

    local neutralColor = EUF.Database:Get("classColors", "customColors", "neutral")
    local neutralBtn = EUF.ColorPicker:CreateButton(panel, neutralColor, function(r, g, b)
        EUF.Database:Set({r = r, g = g, b = b}, "classColors", "customColors", "neutral")
    end, "选择中立单位颜色")
    neutralBtn:SetPoint("LEFT", neutralLabel, "RIGHT", 10, 0)

    -- 友好颜色
    local friendlyLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    friendlyLabel:SetPoint("TOPLEFT", neutralLabel, "BOTTOMLEFT", 0, -10)
    friendlyLabel:SetText("友好:")

    local friendlyColor = EUF.Database:Get("classColors", "customColors", "friendly")
    local friendlyBtn = EUF.ColorPicker:CreateButton(panel, friendlyColor, function(r, g, b)
        EUF.Database:Set({r = r, g = g, b = b}, "classColors", "customColors", "friendly")
    end, "选择友好单位颜色")
    friendlyBtn:SetPoint("LEFT", friendlyLabel, "RIGHT", 10, 0)

    -- 职业色预览
    local previewTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    previewTitle:SetPoint("TOPLEFT", friendlyLabel, "BOTTOMLEFT", 0, -20)
    previewTitle:SetText("职业色预览:")

    local preview = EUF.TexturePreview:CreateClassColorPreview(panel)
    preview:SetPoint("TOPLEFT", previewTitle, "BOTTOMLEFT", 0, -5)
    preview:SetSize(280, 100)

    return panel
end

return ClassColorsPanel