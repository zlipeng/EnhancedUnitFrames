-- TexturePreview.lua
-- EnhancedUnitFrames 材质预览控件
-- 显示材质预览效果

local addonName, EUF = ...

local TexturePreview = {}
EUF.TexturePreview = TexturePreview

-------------------------------------------------------------------------------
-- 创建材质预览框
-------------------------------------------------------------------------------

-- 创建材质预览框
-- parent: 父框架
-- textureName: 材质名称
-- width, height: 尺寸
-- 返回: 预览框架
function TexturePreview:CreatePreview(parent, textureName, width, height)
    local preview = CreateFrame("Frame", nil, parent)
    preview:SetSize(width or 100, height or 20)

    -- 背景
    local bg = preview:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(preview)
    bg:SetColorTexture(0.1, 0.1, 0.1, 1)

    -- 材质条
    local bar = preview:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("LEFT", preview, "LEFT", 2, 0)
    bar:SetPoint("RIGHT", preview, "RIGHT", -2, 0)
    bar:SetPoint("TOP", preview, "TOP", 0, -2)
    bar:SetPoint("BOTTOM", preview, "BOTTOM", 0, 2)
    preview.bar = bar

    -- 边框
    local border = preview:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints(preview)
    border:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    border:SetVertexColor(0.5, 0.5, 0.5, 1)

    -- 设置材质方法
    function preview:SetTexture(name)
        local path
        if EUF.Textures then
            path = EUF.Textures:GetTexturePath(name)
        else
            path = "Interface\\TargetingFrame\\UI-StatusBar"
        end
        self.bar:SetTexture(path)
    end

    -- 设置颜色方法
    function preview:SetColor(r, g, b, a)
        self.bar:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
    end

    -- 设置进度方法
    function preview:SetProgress(percent)
        -- 简单地用颜色深浅表示进度
        -- 实际材质预览不需要真正的进度条功能
    end

    -- 初始化材质
    if textureName then
        preview:SetTexture(textureName)
    end

    return preview
end

-------------------------------------------------------------------------------
-- 创建材质预览网格
-------------------------------------------------------------------------------

-- 创建材质预览网格
-- parent: 父框架
-- textures: 材质名称列表
-- onSelect: 选择回调 function(textureName)
-- 返回: 网格框架
function TexturePreview:CreateGrid(parent, textures, onSelect)
    local grid = CreateFrame("Frame", nil, parent)
    grid.textures = textures or {}
    grid.buttons = {}
    grid.selectedTexture = nil

    -- 创建预览按钮
    local function createButton(textureName, index)
        local row = math.floor((index - 1) / 4)
        local col = (index - 1) % 4

        local button = CreateFrame("Button", nil, grid)
        button:SetSize(80, 30)
        button:SetPoint("TOPLEFT", grid, "TOPLEFT", col * 85, -row * 35)

        -- 预览纹理
        local preview = self:CreatePreview(button, textureName, 70, 20)
        preview:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.preview = preview

        -- 选中状态边框
        local selectedBorder = button:CreateTexture(nil, "OVERLAY")
        selectedBorder:SetAllPoints(button)
        selectedBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        selectedBorder:SetVertexColor(1, 0.82, 0, 1)  -- 金色
        selectedBorder:Hide()
        button.selectedBorder = selectedBorder

        -- 高亮
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(button)
        highlight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        highlight:SetVertexColor(1, 1, 1, 0.3)

        -- 存储材质名称
        button.textureName = textureName

        -- 点击处理
        button:SetScript("OnClick", function(self)
            grid:SelectTexture(self.textureName)
            if onSelect then
                onSelect(self.textureName)
            end
        end)

        return button
    end

    -- 创建所有按钮
    function grid:Refresh()
        -- 复用或创建按钮
        local buttonCount = #self.textures

        -- 隐藏多余的按钮
        for i = buttonCount + 1, #self.buttons do
            self.buttons[i]:Hide()
        end

        -- 创建或更新按钮
        for i, name in ipairs(self.textures) do
            local button = self.buttons[i]

            if not button then
                -- 创建新按钮
                button = createButton(name, i)
                table.insert(self.buttons, button)
            else
                -- 复用现有按钮
                button:Show()
                button.textureName = name
                button.preview:SetTexture(name)
                button.selectedBorder:Hide()
            end
        end
    end

    -- 选择材质
    function grid:SelectTexture(textureName)
        self.selectedTexture = textureName

        for _, button in ipairs(self.buttons) do
            if button.textureName == textureName then
                button.selectedBorder:Show()
            else
                button.selectedBorder:Hide()
            end
        end
    end

    -- 设置材质列表
    function grid:SetTextures(textures)
        self.textures = textures
        self:Refresh()
    end

    -- 初始刷新
    grid:Refresh()

    return grid
end

-------------------------------------------------------------------------------
-- 创建职业色预览
-------------------------------------------------------------------------------

-- 创建职业色预览条
-- parent: 父框架
-- 返回: 预览框架
function TexturePreview:CreateClassColorPreview(parent)
    local preview = CreateFrame("Frame", nil, parent)
    preview:SetSize(300, 150)

    -- 标题
    local title = preview:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", preview, "TOP", 0, -5)
    title:SetText("职业色预览")

    -- 职业列表
    local classes = {
        "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE",
        "WARLOCK", "DRUID", "DEATHKNIGHT", "MONK", "DEMONHUNTER", "EVOKER"
    }

    local classNames = {
        WARRIOR = "战士", PALADIN = "圣骑", HUNTER = "猎人", ROGUE = "盗贼",
        PRIEST = "牧师", SHAMAN = "萨满", MAGE = "法师", WARLOCK = "术士",
        DRUID = "德鲁伊", DEATHKNIGHT = "死骑", MONK = "武僧",
        DEMONHUNTER = "恶魔猎手", EVOKER = "唤魔师"
    }

    -- 创建预览条
    for i, classToken in ipairs(classes) do
        local row = math.floor((i - 1) / 7)
        local col = (i - 1) % 7

        local bar = CreateFrame("Frame", nil, preview)
        bar:SetSize(38, 16)
        bar:SetPoint("TOPLEFT", preview, "TOPLEFT", 10 + col * 42, -25 - row * 40)

        -- 颜色条
        local colorBar = bar:CreateTexture(nil, "ARTWORK")
        colorBar:SetAllPoints(bar)
        colorBar:SetColorTexture(EUF.ColorPicker:GetClassColor(classToken))

        -- 边框
        local border = bar:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints(bar)
        border:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        border:SetVertexColor(0.3, 0.3, 0.3, 1)

        -- 职业名称
        local name = bar:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        name:SetPoint("TOP", bar, "BOTTOM", 0, -2)
        name:SetText(classNames[classToken] or classToken)
    end

    return preview
end

return TexturePreview