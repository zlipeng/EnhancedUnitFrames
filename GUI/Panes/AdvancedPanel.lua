-- AdvancedPanel.lua
-- EnhancedUnitFrames 高级选项子面板
-- 提供配置导入导出和重置功能

local addonName, EUF = ...

local AdvancedPanel = {}
EUF.AdvancedPanel = AdvancedPanel

-- 模块状态
AdvancedPanel.initialized = false

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function AdvancedPanel:Initialize()
    if self.initialized then return end
    self.initialized = true
end

-------------------------------------------------------------------------------
-- 创建高级选项面板
-------------------------------------------------------------------------------

function AdvancedPanel:CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetSize(320, 400)

    -- 标题
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    title:SetText("高级选项")

    local yOffset = -40

    -- 配置管理标题
    local configTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    configTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    configTitle:SetText("|cFFFFFFFF配置管理:|r")
    yOffset = yOffset - 30

    -- 导出配置按钮
    local exportBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    exportBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    exportBtn:SetSize(100, 25)
    exportBtn:SetText("导出配置")
    exportBtn:SetScript("OnClick", function()
        self:ExportConfig()
    end)

    -- 导入配置按钮
    local importBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
    importBtn:SetSize(100, 25)
    importBtn:SetText("导入配置")
    importBtn:SetScript("OnClick", function()
        self:ShowImportDialog()
    end)
    yOffset = yOffset - 40

    -- 分隔线
    local sep1 = panel:CreateTexture(nil, "ARTWORK")
    sep1:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    sep1:SetSize(300, 1)
    sep1:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    yOffset = yOffset - 20

    -- 调试选项标题
    local debugTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    debugTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    debugTitle:SetText("|cFFFFFFFF调试选项:|r")
    yOffset = yOffset - 30

    -- 调试模式
    local debugCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    debugCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    debugCheck.text = debugCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    debugCheck.text:SetPoint("LEFT", debugCheck, "RIGHT", 5, 0)
    debugCheck.text:SetText("调试模式")
    debugCheck:SetChecked(EUF.Database:GetGlobal("debugMode"))

    debugCheck:SetScript("OnClick", function(self)
        EUF.Database:SetGlobal("debugMode", self:GetChecked() and true or false)
        EUF.debugMode = self:GetChecked()
    end)
    yOffset = yOffset - 30

    -- 分隔线
    local sep2 = panel:CreateTexture(nil, "ARTWORK")
    sep2:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    sep2:SetSize(300, 1)
    sep2:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    yOffset = yOffset - 20

    -- 重置选项标题
    local resetTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    resetTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    resetTitle:SetText("|cFFFFFFFF重置选项:|r")
    yOffset = yOffset - 30

    -- 重置当前配置按钮
    local resetProfileBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetProfileBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    resetProfileBtn:SetSize(140, 25)
    resetProfileBtn:SetText("重置当前配置")
    resetProfileBtn:SetScript("OnClick", function()
        self:ConfirmReset("profile")
    end)

    -- 重置所有配置按钮
    local resetAllBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetAllBtn:SetPoint("LEFT", resetProfileBtn, "RIGHT", 10, 0)
    resetAllBtn:SetSize(140, 25)
    resetAllBtn:SetText("重置所有配置")
    resetAllBtn:SetScript("OnClick", function()
        self:ConfirmReset("all")
    end)
    yOffset = yOffset - 40

    -- 警告文字
    local warning = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    warning:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    warning:SetText("|cFFFF0000⚠ 警告: 重置操作不可撤销!|r")

    return panel
end

-------------------------------------------------------------------------------
-- 导出配置
-------------------------------------------------------------------------------

function AdvancedPanel:ExportConfig()
    local config = EUF.Database:ExportProfile()

    -- 创建对话框
    local frame = CreateFrame("Frame", "EUF_ExportDialog", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 300)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- 标题
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("导出配置")

    -- 文本框
    local editBox = CreateFrame("EditBox", nil, frame)
    editBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    editBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 40)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontNormalSmall)
    editBox:SetText(config)
    editBox:HighlightText()

    -- 滚动支持
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 40)
    scrollFrame:SetScrollChild(editBox)

    -- 关闭按钮
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    closeBtn:SetSize(80, 25)
    closeBtn:SetText("关闭")
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame:Show()
end

-------------------------------------------------------------------------------
-- 显示导入对话框
-------------------------------------------------------------------------------

function AdvancedPanel:ShowImportDialog()
    -- 创建对话框
    local frame = CreateFrame("Frame", "EUF_ImportDialog", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 300)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- 标题
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("导入配置")

    -- 文本框
    local editBox = CreateFrame("EditBox", nil, frame)
    editBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    editBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 45)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontNormalSmall)

    -- 滚动支持
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 45)
    scrollFrame:SetScrollChild(editBox)

    -- 导入按钮
    local importBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    importBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOM", -50, 10)
    importBtn:SetSize(80, 25)
    importBtn:SetText("导入")
    importBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        if text and text ~= "" then
            -- 简单解析（实际应该用更复杂的解析）
            EUF:Print("导入功能待完善")
        end
    end)

    -- 关闭按钮
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", 50, 10)
    closeBtn:SetSize(80, 25)
    closeBtn:SetText("关闭")
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame:Show()
end

-------------------------------------------------------------------------------
-- 确认重置
-------------------------------------------------------------------------------

function AdvancedPanel:ConfirmReset(resetType)
    StaticPopupDialogs["EUF_CONFIRM_RESET"] = {
        text = "确定要重置" .. (resetType == "all" and "所有" or "当前") .. "配置吗？此操作不可撤销。",
        button1 = "确定",
        button2 = "取消",
        OnAccept = function()
            if resetType == "all" then
                EUF.Database:ResetAll()
            else
                EUF.Database:ResetProfile()
            end
            EUF:InitializeModules()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopup_Show("EUF_CONFIRM_RESET")
end

return AdvancedPanel