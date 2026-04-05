-- FrameScalePanel.lua
-- EnhancedUnitFrames 框体缩放子面板
-- 提供框体缩放详细配置

local addonName, EUF = ...

local FrameScalePanel = {}
EUF.FrameScalePanel = FrameScalePanel

-- 模块状态
FrameScalePanel.initialized = false

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function FrameScalePanel:Initialize()
    if self.initialized then return end
    self.initialized = true
end

-------------------------------------------------------------------------------
-- 创建缩放面板
-------------------------------------------------------------------------------

function FrameScalePanel:CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetSize(300, 350)

    -- 标题
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    title:SetText("框体缩放设置")

    -- 提示
    local tip = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    tip:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -35)
    tip:SetText("|cFFFFFF00提示: 战斗中的缩放更改将在脱战后自动应用|r")

    -- 创建缩放滑块
    local yOffset = -60
    local frames = {
        { key = "player", name = "玩家框体" },
        { key = "target", name = "目标框体" },
        { key = "focus", name = "焦点框体" },
        { key = "pet", name = "宠物框体" },
    }

    panel.sliders = {}

    for i, frameInfo in ipairs(frames) do
        local slider = self:CreateScaleSlider(panel, frameInfo.key, frameInfo.name)
        slider:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset - (i - 1) * 50)
        panel.sliders[frameInfo.key] = slider
    end

    -- 重置按钮
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetPoint("BOTTOM", panel, "BOTTOM", 0, 20)
    resetBtn:SetSize(100, 25)
    resetBtn:SetText("重置全部")
    resetBtn:SetScript("OnClick", function()
        for _, frameInfo in ipairs(frames) do
            EUF.FrameScale:ResetToDefault(frameInfo.key)
            if panel.sliders[frameInfo.key] then
                panel.sliders[frameInfo.key]:SetValue(1.0)
            end
        end
        EUF:Print("所有缩放已重置")
    end)

    return panel
end

-------------------------------------------------------------------------------
-- 创建缩放滑块
-------------------------------------------------------------------------------

function FrameScalePanel:CreateScaleSlider(parent, frameKey, displayName)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(280, 40)

    -- 标签
    local label = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", container, "LEFT", 0, 0)
    label:SetText(displayName .. ":")

    -- 滑块（使用全局命名以兼容 OptionsSliderTemplate）
    -- 注意: OptionsSliderTemplate 要求全局命名来访问子控件
    local slider = CreateFrame("Slider", "EUF_" .. frameKey .. "_ScaleSlider", container, "OptionsSliderTemplate")
    slider:SetPoint("LEFT", label, "RIGHT", 10, 0)
    slider:SetWidth(150)
    slider:SetHeight(20)
    slider:SetMinMaxValues(0.5, 2.0)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)

    -- 设置初始值
    local currentValue = EUF.Database:GetScale(frameKey)
    slider:SetValue(currentValue)

    -- 滑块标签
    _G[slider:GetName() .. "Low"]:SetText("50%")
    _G[slider:GetName() .. "High"]:SetText("200%")
    _G[slider:GetName() .. "Text"]:SetText(string.format("%.0f%%", currentValue * 100))

    -- 数值显示
    local valueText = container:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)

    -- 更新函数
    slider.UpdateDisplay = function(self, value)
        value = value or self:GetValue()
        _G[self:GetName() .. "Text"]:SetText(string.format("%.0f%%", value * 100))
        valueText:SetText(string.format("%.2f", value))
    end

    slider:UpdateDisplay()

    -- 滑块拖动事件
    slider:SetScript("OnValueChanged", function(self, value)
        self:UpdateDisplay(value)
    end)

    -- 鼠标释放时应用
    slider:SetScript("OnMouseUp", function(self)
        -- 检查战斗状态并给出提示
        if InCombatLockdown() then
            EUF:Print("|cFFFFFF00战斗中:|r 缩放设置将在脱战后应用")
        end
        local value = self:GetValue()
        EUF.FrameScale:SetFrameScale(frameKey, value)
    end)

    -- 存储滑块引用
    container.slider = slider

    return container
end

-------------------------------------------------------------------------------
-- 更新所有滑块显示
-------------------------------------------------------------------------------

function FrameScalePanel:UpdateAllSliders()
    -- 由外部调用更新所有滑块显示
end

return FrameScalePanel