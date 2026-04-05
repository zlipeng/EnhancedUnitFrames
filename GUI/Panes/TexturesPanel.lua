-- TexturesPanel.lua
-- EnhancedUnitFrames 材质子面板
-- 提供材质详细配置

local addonName, EUF = ...

local TexturesPanel = {}
EUF.TexturesPanel = TexturesPanel

-- 模块状态
TexturesPanel.initialized = false

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function TexturesPanel:Initialize()
    if self.initialized then return end
    self.initialized = true
end

-------------------------------------------------------------------------------
-- 创建材质面板
-------------------------------------------------------------------------------

function TexturesPanel:CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetSize(320, 400)

    -- 标题
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    title:SetText("材质设置")

    local yOffset = -40

    -- 生命条材质
    local healthLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    healthLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    healthLabel:SetText("生命条材质:")

    local healthTextures = EUF.Textures and EUF.Textures:GetTextureList() or {"Blizzard"}
    local healthDropdown = self:CreateTextureDropdown(panel, healthTextures, function(textureName)
        EUF.Textures:SetHealthBarTexture(textureName)
    end)
    healthDropdown:SetPoint("LEFT", healthLabel, "RIGHT", 10, 0)
    yOffset = yOffset - 40

    -- 法力条材质
    local manaLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    manaLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    manaLabel:SetText("法力条材质:")

    local manaDropdown = self:CreateTextureDropdown(panel, healthTextures, function(textureName)
        EUF.Textures:SetManaBarTexture(textureName)
    end)
    manaDropdown:SetPoint("LEFT", manaLabel, "RIGHT", 10, 0)
    yOffset = yOffset - 40

    -- 分隔线
    local sep1 = panel:CreateTexture(nil, "ARTWORK")
    sep1:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    sep1:SetSize(300, 1)
    sep1:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    yOffset = yOffset - 15

    -- 边框样式
    local borderLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    borderLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    borderLabel:SetText("边框样式:")

    local borderStyles = {"None", "Rounded", "Square", "Blizzard"}
    local borderDropdown = self:CreateDropdown(panel, borderStyles, function(style)
        local borderColor = EUF.Database:Get("textures", "borderColor") or {r=1, g=1, b=1, a=1}
        EUF.Textures:SetBorderStyle(style, borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    end)
    borderDropdown:SetPoint("LEFT", borderLabel, "RIGHT", 10, 0)
    yOffset = yOffset - 40

    -- 边框颜色
    local colorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    colorLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    colorLabel:SetText("边框颜色:")

    local borderColor = EUF.Database:Get("textures", "borderColor") or {r=1, g=1, b=1, a=1}
    local colorBtn = EUF.ColorPicker:CreateButton(panel, borderColor, function(r, g, b, a)
        local borderStyle = EUF.Database:Get("textures", "border") or "None"
        EUF.Textures:SetBorderStyle(borderStyle, r, g, b, a)
    end, "选择边框颜色")
    colorBtn:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)
    yOffset = yOffset - 50

    -- 预览区域标题
    local previewTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    previewTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    previewTitle:SetText("材质预览:")
    yOffset = yOffset - 20

    -- 预览区域
    local previewFrame = CreateFrame("Frame", nil, panel)
    previewFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, yOffset)
    previewFrame:SetSize(280, 60)

    -- 预览背景
    local previewBg = previewFrame:CreateTexture(nil, "BACKGROUND")
    previewBg:SetAllPoints(previewFrame)
    previewBg:SetColorTexture(0.1, 0.1, 0.1, 1)

    -- 预览生命条
    local healthPreview = EUF.TexturePreview:CreatePreview(previewFrame, "Blizzard", 260, 20)
    healthPreview:SetPoint("TOP", previewFrame, "TOP", 0, -5)
    healthPreview:SetColor(0, 0.8, 0, 1)

    -- 预览法力条
    local manaPreview = EUF.TexturePreview:CreatePreview(previewFrame, "Blizzard", 260, 15)
    manaPreview:SetPoint("TOP", healthPreview, "BOTTOM", 0, -5)
    manaPreview:SetColor(0, 0.5, 1, 1)

    -- 更新预览
    function panel:UpdatePreview()
        local healthTex = EUF.Database:Get("textures", "healthBar") or "Blizzard"
        local manaTex = EUF.Database:Get("textures", "manaBar") or healthTex

        healthPreview:SetTexture(healthTex)
        manaPreview:SetTexture(manaTex)
    end

    return panel
end

-------------------------------------------------------------------------------
-- 创建下拉菜单
-------------------------------------------------------------------------------

function TexturesPanel:CreateTextureDropdown(parent, textures, onSelect)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetSize(150, 30)

    -- 初始化下拉菜单
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, name in ipairs(textures) do
            info.text = name
            info.value = name
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                if onSelect then
                    onSelect(self.value)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- 设置默认值
    UIDropDownMenu_SetSelectedValue(dropdown, textures[1] or "Blizzard")
    UIDropDownMenu_SetWidth(dropdown, 120)

    return dropdown
end

function TexturesPanel:CreateDropdown(parent, values, onSelect)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetSize(150, 30)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, value in ipairs(values) do
            info.text = value
            info.value = value
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                if onSelect then
                    onSelect(self.value)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedValue(dropdown, values[1])
    UIDropDownMenu_SetWidth(dropdown, 100)

    return dropdown
end

return TexturesPanel