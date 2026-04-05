-- OptionsPanel.lua
-- EnhancedUnitFrames 设置面板模块
-- 使用暴雪 12.0 Settings API 创建设置界面

local addonName, EUF = ...

local OptionsPanel = {}
EUF.OptionsPanel = OptionsPanel

-- 模块状态
OptionsPanel.initialized = false
OptionsPanel.category = nil

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function OptionsPanel:Initialize()
    if self.initialized then return end

    -- 创建主设置分类
    self:CreateMainCategory()

    self.initialized = true
    EUF:Debug("OptionsPanel: 模块初始化完成")
end

-------------------------------------------------------------------------------
-- 主分类创建
-------------------------------------------------------------------------------

function OptionsPanel:CreateMainCategory()
    -- 使用 12.0 推荐的垂直布局分类
    local category = Settings.RegisterVerticalLayoutCategory("Enhanced Unit Frames")

    if not category then
        EUF:Debug("OptionsPanel: 无法创建设置分类")
        return
    end

    self.category = category

    -- 通用设置
    self:CreateGeneralSettings(category)

    -- 职业染色设置
    self:CreateClassColorSettings(category)

    -- 缩放设置
    self:CreateScaleSettings(category)

    -- 材质设置
    self:CreateTextureSettings(category)

    -- 文字设置
    self:CreateTextSettings(category)

    -- 高级设置
    self:CreateAdvancedSettings(category)

    -- 注册到暴雪设置系统
    Settings.RegisterAddOnCategory(category)

    EUF:Debug("OptionsPanel: 主设置分类已创建")
end

-------------------------------------------------------------------------------
-- 通用设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateGeneralSettings(category)
    -- 启用插件
    local enableSetting = Settings.RegisterAddOnSetting(
        category,
        "启用插件",
        "enableAddon",
        EUF.Database.global,
        Settings.GetValueTypeBoolean(),
        true
    )
    Settings.CreateCheckBox(category, enableSetting, "启用或禁用 Enhanced Unit Frames 插件")

    Settings.SetOnValueChangedCallback("enableAddon", function()
        if EUF.Database:GetGlobal("enableAddon") then
            EUF:OnEnable()
        else
            EUF:OnDisable()
        end
    end)

    -- 调试模式
    local debugSetting = Settings.RegisterAddOnSetting(
        category,
        "调试模式",
        "debugMode",
        EUF.Database.global,
        Settings.GetValueTypeBoolean(),
        false
    )
    Settings.CreateCheckBox(category, debugSetting, "在聊天框输出调试信息")

    Settings.SetOnValueChangedCallback("debugMode", function()
        EUF.debugMode = EUF.Database:GetGlobal("debugMode")
    end)

    Settings.AddSpacer(category)
end

-------------------------------------------------------------------------------
-- 职业染色设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateClassColorSettings(category)
    -- 分隔标题
    Settings.RegisterSetting(category, "职业染色", function()
        return "|cFFFFFFFF职业染色设置|r"
    end)

    -- 创建本地存储表（用于 Settings API）
    self.classColorSettings = self.classColorSettings or {}

    -- 启用职业染色
    local enabledSetting = Settings.RegisterAddOnSetting(
        category,
        "启用职业染色",
        "classColorsEnabled",
        self.classColorSettings,
        Settings.GetValueTypeBoolean(),
        EUF.Database:Get("classColors", "enabled") and true or false
    )
    Settings.CreateCheckBox(category, enabledSetting, "根据单位职业自动着色生命条")

    Settings.SetOnValueChangedCallback("classColorsEnabled", function()
        local value = self.classColorSettings.classColorsEnabled
        EUF.Database:Set(value, "classColors", "enabled")
        self:RefreshClassColors()
    end)

    -- 染色背景
    local bgSetting = Settings.RegisterAddOnSetting(
        category,
        "染色背景",
        "classColorsBackground",
        self.classColorSettings,
        Settings.GetValueTypeBoolean(),
        EUF.Database:Get("classColors", "colorBackground") and true or false
    )
    Settings.CreateCheckBox(category, bgSetting, "同时为生命条背景添加职业色")

    Settings.SetOnValueChangedCallback("classColorsBackground", function()
        local value = self.classColorSettings.classColorsBackground
        EUF.Database:Set(value, "classColors", "colorBackground")
        self:RefreshClassColors()
    end)

    -- 染色边框
    local borderSetting = Settings.RegisterAddOnSetting(
        category,
        "染色边框",
        "classColorsBorder",
        self.classColorSettings,
        Settings.GetValueTypeBoolean(),
        EUF.Database:Get("classColors", "colorBorder") and true or false
    )
    Settings.CreateCheckBox(category, borderSetting, "为框体边框添加职业色")

    Settings.SetOnValueChangedCallback("classColorsBorder", function()
        local value = self.classColorSettings.classColorsBorder
        EUF.Database:Set(value, "classColors", "colorBorder")
        self:RefreshClassColors()
    end)

    -- NPC使用反应色
    local npcSetting = Settings.RegisterAddOnSetting(
        category,
        "NPC反应色",
        "classColorsNPC",
        self.classColorSettings,
        Settings.GetValueTypeBoolean(),
        EUF.Database:Get("classColors", "colorNPCByReaction") and true or false
    )
    Settings.CreateCheckBox(category, npcSetting, "非玩家单位使用反应色（友好/中立/敌对）")

    Settings.SetOnValueChangedCallback("classColorsNPC", function()
        local value = self.classColorSettings.classColorsNPC
        EUF.Database:Set(value, "classColors", "colorNPCByReaction")
        self:RefreshClassColors()
    end)

    Settings.AddSpacer(category)
end

-------------------------------------------------------------------------------
-- 缩放设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateScaleSettings(category)
    -- 分隔标题
    Settings.RegisterSetting(category, "框体缩放", function()
        return "|cFFFFFFFF框体缩放设置|r"
    end)

    -- 创建本地存储表
    self.scaleSettings = self.scaleSettings or {}

    -- 玩家框体缩放
    self:CreateScaleSlider(category, "玩家框体缩放", "player")

    -- 目标框体缩放
    self:CreateScaleSlider(category, "目标框体缩放", "target")

    -- 焦点框体缩放
    self:CreateScaleSlider(category, "焦点框体缩放", "focus")

    -- 宠物框体缩放
    self:CreateScaleSlider(category, "宠物框体缩放", "pet")

    Settings.AddSpacer(category)
end

-- 创建缩放滑块
function OptionsPanel:CreateScaleSlider(category, displayName, frameKey)
    self.scaleSettings = self.scaleSettings or {}

    local varKey = "scale_" .. frameKey
    local currentValue = EUF.Database:GetScale(frameKey)
    self.scaleSettings[varKey] = currentValue

    local setting = Settings.RegisterAddOnSetting(
        category,
        displayName,
        varKey,
        self.scaleSettings,
        Settings.GetValueTypeNumber(),
        currentValue
    )

    local options = Settings.CreateSliderOptions(0.5, 2.0, 0.05)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

    Settings.CreateSlider(category, setting, options, "调整框体大小 (50% - 200%)")

    Settings.SetOnValueChangedCallback(varKey, function()
        local scale = self.scaleSettings[varKey]
        EUF.Database:SetScale(frameKey, scale)
        if EUF.FrameScale and EUF.FrameScale.initialized then
            EUF.FrameScale:SetFrameScale(frameKey, scale)
        end
    end)
end

-------------------------------------------------------------------------------
-- 材质设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateTextureSettings(category)
    -- 分隔标题
    Settings.RegisterSetting(category, "材质设置", function()
        return "|cFFFFFFFF材质设置|r"
    end)

    -- 创建本地存储表
    self.textureSettings = self.textureSettings or {}

    -- 生命条材质
    local healthTexture = EUF.Database:Get("textures", "healthBar") or "Blizzard"
    self.textureSettings.healthBarTexture = healthTexture

    local healthTextureSetting = Settings.RegisterAddOnSetting(
        category,
        "生命条材质",
        "healthBarTexture",
        self.textureSettings,
        Settings.GetValueTypeString(),
        healthTexture
    )

    local textureOptions = self:CreateTextureOptions()
    Settings.CreateDropDown(category, healthTextureSetting, textureOptions, "选择生命条材质样式")

    Settings.SetOnValueChangedCallback("healthBarTexture", function()
        local value = self.textureSettings.healthBarTexture
        EUF.Database:Set(value, "textures", "healthBar")
        self:RefreshTextures()
    end)

    -- 法力条材质
    local manaTexture = EUF.Database:Get("textures", "manaBar") or "Blizzard"
    self.textureSettings.manaBarTexture = manaTexture

    local manaTextureSetting = Settings.RegisterAddOnSetting(
        category,
        "法力条材质",
        "manaBarTexture",
        self.textureSettings,
        Settings.GetValueTypeString(),
        manaTexture
    )

    Settings.CreateDropDown(category, manaTextureSetting, textureOptions, "选择法力条材质样式")

    Settings.SetOnValueChangedCallback("manaBarTexture", function()
        local value = self.textureSettings.manaBarTexture
        EUF.Database:Set(value, "textures", "manaBar")
        self:RefreshTextures()
    end)

    -- 边框样式
    local borderStyle = EUF.Database:Get("textures", "border") or "None"
    self.textureSettings.borderStyle = borderStyle

    local borderSetting = Settings.RegisterAddOnSetting(
        category,
        "边框样式",
        "borderStyle",
        self.textureSettings,
        Settings.GetValueTypeString(),
        borderStyle
    )

    local borderOptions = self:CreateBorderOptions()
    Settings.CreateDropDown(category, borderSetting, borderOptions, "选择框体边框样式")

    Settings.SetOnValueChangedCallback("borderStyle", function()
        local value = self.textureSettings.borderStyle
        EUF.Database:Set(value, "textures", "border")
        self:RefreshTextures()
    end)

    Settings.AddSpacer(category)
end

-------------------------------------------------------------------------------
-- 文字设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateTextSettings(category)
    -- 分隔标题
    Settings.RegisterSetting(category, "文字设置", function()
        return "|cFFFFFFFF文字设置|r"
    end)

    -- 创建本地存储表
    self.textSettings = self.textSettings or {}

    -- 玩家健康值格式
    local playerFormat = EUF.Database:Get("text", "formats", "player", "health") or "DEFAULT"
    self.textSettings.playerHealthFormat = playerFormat

    local playerHealthFormatSetting = Settings.RegisterAddOnSetting(
        category,
        "玩家生命值格式",
        "playerHealthFormat",
        self.textSettings,
        Settings.GetValueTypeString(),
        playerFormat
    )

    local formatOptions = self:CreateHealthFormatOptions()
    Settings.CreateDropDown(category, playerHealthFormatSetting, formatOptions,
        "选择玩家框体生命值显示格式 |cFFFF0000(12.0部分格式在战斗中可能受限)|r")

    Settings.SetOnValueChangedCallback("playerHealthFormat", function()
        local format = self.textSettings.playerHealthFormat
        EUF.Database:Set(format, "text", "formats", "player", "health")
        if EUF.TextSettings and EUF.TextSettings.initialized then
            EUF.TextSettings:SetHealthTextFormat("player", format)
        end
    end)

    -- 目标健康值格式
    local targetFormat = EUF.Database:Get("text", "formats", "target", "health") or "DEFAULT"
    self.textSettings.targetHealthFormat = targetFormat

    local targetHealthFormatSetting = Settings.RegisterAddOnSetting(
        category,
        "目标生命值格式",
        "targetHealthFormat",
        self.textSettings,
        Settings.GetValueTypeString(),
        targetFormat
    )

    Settings.CreateDropDown(category, targetHealthFormatSetting, formatOptions,
        "选择目标框体生命值显示格式")

    Settings.SetOnValueChangedCallback("targetHealthFormat", function()
        local format = self.textSettings.targetHealthFormat
        EUF.Database:Set(format, "text", "formats", "target", "health")
        if EUF.TextSettings and EUF.TextSettings.initialized then
            EUF.TextSettings:SetHealthTextFormat("target", format)
        end
    end)

    Settings.AddSpacer(category)
end

-------------------------------------------------------------------------------
-- 高级设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateAdvancedSettings(category)
    -- 分隔标题
    Settings.RegisterSetting(category, "高级选项", function()
        return "|cFFFFFFFF高级选项|r"
    end)

    -- 重置配置按钮
    local resetSetting = Settings.RegisterSetting(category, "重置配置", function()
        return "|cFFFF0000点击重置所有设置为默认值|r"
    end)

    Settings.CreateButton(category, resetSetting, "重置配置", function()
        EUF.Database:ResetProfile()
        EUF:InitializeModules()
        EUF:Print("配置已重置")
    end)

    Settings.AddSpacer(category)
end

-------------------------------------------------------------------------------
-- 辅助函数
-------------------------------------------------------------------------------

-- 创建材质选项
function OptionsPanel:CreateTextureOptions()
    return function()
        local textures = EUF.Textures and EUF.Textures:GetTextureList() or {"Blizzard"}
        local options = {}

        for _, name in ipairs(textures) do
            table.insert(options, {
                text = name,
                value = name,
            })
        end

        return options
    end
end

-- 创建边框选项
function OptionsPanel:CreateBorderOptions()
    return function()
        return {
            { text = "无", value = "None" },
            { text = "圆角", value = "Rounded" },
            { text = "方形", value = "Square" },
            { text = "暴雪默认", value = "Blizzard" },
        }
    end
end

-- 创建健康值格式选项
function OptionsPanel:CreateHealthFormatOptions()
    return function()
        return {
            { text = "暴雪默认 (推荐)", value = "DEFAULT" },
            { text = "百分比", value = "PERCENT" },
            { text = "当前值", value = "CURRENT" },
            { text = "当前/最大", value = "CURRENT/MAX" },
            { text = "亏损值", value = "DEFICIT" },
            { text = "隐藏", value = "HIDDEN" },
        }
    end
end

-------------------------------------------------------------------------------
-- 刷新函数
-------------------------------------------------------------------------------

function OptionsPanel:RefreshClassColors()
    if EUF.ClassColors and EUF.ClassColors.initialized then
        EUF.ClassColors:Refresh()
    end
end

function OptionsPanel:RefreshTextures()
    if EUF.Textures and EUF.Textures.initialized then
        EUF.Textures:Refresh()
    end
end

function OptionsPanel:RefreshTextSettings()
    if EUF.TextSettings and EUF.TextSettings.initialized then
        EUF.TextSettings:Refresh()
    end
end

-------------------------------------------------------------------------------
-- 打开设置面板
-------------------------------------------------------------------------------

function OptionsPanel:Open()
    if self.category then
        Settings.OpenToCategory(self.category:GetID())
    end
end

return OptionsPanel