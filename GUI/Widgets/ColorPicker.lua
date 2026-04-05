-- ColorPicker.lua
-- EnhancedUnitFrames 颜色选择器控件
-- 提供颜色选择功能

local addonName, EUF = ...

local ColorPicker = {}
EUF.ColorPicker = ColorPicker

-- 颜色选择器缓存
ColorPicker.activePickers = {}

-------------------------------------------------------------------------------
-- 创建颜色选择按钮
-------------------------------------------------------------------------------

-- 创建颜色选择按钮
-- parent: 父框架
-- initialColor: 初始颜色 {r, g, b, a}
-- onColorChanged: 颜色变更回调 function(r, g, b, a)
-- 返回: 按钮框架
function ColorPicker:CreateButton(parent, initialColor, onColorChanged, tooltip)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 24)

    -- 颜色预览纹理
    local swatch = button:CreateTexture(nil, "ARTWORK")
    swatch:SetAllPoints(button)
    swatch:SetColorTexture(
        initialColor and initialColor.r or 1,
        initialColor and initialColor.g or 1,
        initialColor and initialColor.b or 1,
        initialColor and initialColor.a or 1
    )
    button.swatch = swatch

    -- 边框
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints(button)
    border:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
    button.border = border

    -- 高亮
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
    highlight:SetVertexColor(1, 0.82, 0, 0.5)

    -- 存储当前颜色
    button.currentColor = {
        r = initialColor and initialColor.r or 1,
        g = initialColor and initialColor.g or 1,
        b = initialColor and initialColor.b or 1,
        a = initialColor and initialColor.a or 1,
    }

    -- 存储回调
    button.onColorChanged = onColorChanged

    -- 点击处理
    button:SetScript("OnClick", function(self)
        ColorPicker:OpenColorPicker(self)
    end)

    -- 设置颜色方法
    function button:SetColor(r, g, b, a)
        self.currentColor.r = r
        self.currentColor.g = g
        self.currentColor.b = b
        self.currentColor.a = a or 1
        self.swatch:SetColorTexture(r, g, b, a or 1)
    end

    -- 获取颜色方法
    function button:GetColor()
        return self.currentColor.r, self.currentColor.g, self.currentColor.b, self.currentColor.a
    end

    -- 设置提示
    if tooltip then
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end

    return button
end

-------------------------------------------------------------------------------
-- 打开暴雪颜色选择器
-------------------------------------------------------------------------------

function ColorPicker:OpenColorPicker(button)
    local color = button.currentColor

    -- 保存引用
    self.activePickers[button] = true

    -- 设置颜色选择器
    ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacity = 1 - (color.a or 1)

    -- 设置回调
    ColorPickerFrame.func = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = 1 - OpacitySliderFrame:GetValue()

        button:SetColor(r, g, b, a)

        if button.onColorChanged then
            button.onColorChanged(r, g, b, a)
        end
    end

    ColorPickerFrame.opacityFunc = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = 1 - OpacitySliderFrame:GetValue()

        button:SetColor(r, g, b, a)

        if button.onColorChanged then
            button.onColorChanged(r, g, b, a)
        end
    end

    ColorPickerFrame.cancelFunc = function()
        -- 取消时恢复原色
        button:SetColor(color.r, color.g, color.b, color.a)
    end

    -- 显示颜色选择器
    ShowUIPanel(ColorPickerFrame)
end

-------------------------------------------------------------------------------
-- 预定义颜色
-------------------------------------------------------------------------------

-- 职业颜色
ColorPicker.CLASS_COLORS = {
    ["WARRIOR"] =     { r = 0.78, g = 0.61, b = 0.43 },
    ["PALADIN"] =     { r = 0.96, g = 0.55, b = 0.73 },
    ["HUNTER"] =      { r = 0.67, g = 0.83, b = 0.45 },
    ["ROGUE"] =       { r = 1.00, g = 0.96, b = 0.41 },
    ["PRIEST"] =      { r = 1.00, g = 1.00, b = 1.00 },
    ["SHAMAN"] =      { r = 0.00, g = 0.44, b = 0.87 },
    ["MAGE"] =        { r = 0.41, g = 0.80, b = 0.94 },
    ["WARLOCK"] =     { r = 0.58, g = 0.51, b = 0.79 },
    ["DRUID"] =       { r = 1.00, g = 0.49, b = 0.04 },
    ["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23 },
    ["MONK"] =        { r = 0.00, g = 1.00, b = 0.59 },
    ["DEMONHUNTER"] = { r = 0.64, g = 0.19, b = 0.79 },
    ["EVOKER"] =      { r = 0.20, g = 0.58, b = 0.50 },
}

-- 反应颜色
ColorPicker.REACTION_COLORS = {
    ["hostile"] =  { r = 1.0, g = 0.0, b = 0.0 },  -- 敌对（红）
    ["neutral"] =  { r = 1.0, g = 1.0, b = 0.0 },  -- 中立（黄）
    ["friendly"] = { r = 0.0, g = 1.0, b = 0.0 },  -- 友好（绿）
}

-- 获取职业颜色
function ColorPicker:GetClassColor(classToken)
    local color = self.CLASS_COLORS[classToken]
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

-- 获取反应颜色
function ColorPicker:GetReactionColor(reactionType)
    local color = self.REACTION_COLORS[reactionType]
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

return ColorPicker