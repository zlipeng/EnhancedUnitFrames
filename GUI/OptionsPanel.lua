-- OptionsPanel.lua
-- EnhancedUnitFrames 设置面板模块
-- 使用暴雪 12.0 Settings API 创建设置界面

local addonName, EUF = ...

local OptionsPanel = {}
EUF.OptionsPanel = OptionsPanel

-- 模块状态
OptionsPanel.initialized = false
OptionsPanel.category = nil

-- 设置变量前缀
local PREFIX = "EUF_"

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function OptionsPanel:Initialize()
    if self.initialized then return end

    self:CreateMainCategory()

    self.initialized = true
    EUF:Debug("OptionsPanel: 模块初始化完成")
end

-------------------------------------------------------------------------------
-- 主分类创建
-------------------------------------------------------------------------------

function OptionsPanel:CreateMainCategory()
    local category, layout = Settings.RegisterVerticalLayoutCategory("Enhanced Unit Frames")

    if not category then
        EUF:Debug("OptionsPanel: 无法创建设置分类")
        return
    end

    self.category = category

    -- 通用设置
    self:CreateGeneralSettings(category)

    -- 各框体设置
    self:CreateFrameSettings(category, "player", "玩家框体")
    self:CreateFrameSettings(category, "target", "目标框体")
    self:CreateFrameSettings(category, "focus", "焦点框体")
    self:CreateFrameSettings(category, "pet", "宠物框体")

    -- 小地图按钮设置
    self:CreateMinimapSettings(category)

    -- 高级设置
    self:CreateAdvancedSettings(category)

    Settings.RegisterAddOnCategory(category)

    EUF:Debug("OptionsPanel: 主设置分类已创建, ID = " .. tostring(category:GetID()))
end

-------------------------------------------------------------------------------
-- 辅助函数
-------------------------------------------------------------------------------

local function CreateCheckbox(category, variable, name, default, tooltip, getter, setter)
    local varKey = PREFIX .. variable

    local setting = Settings.RegisterProxySetting(
        category,
        varKey,
        Settings.VarType.Boolean,
        name,
        default,
        getter or function() return EUF.Database:GetGlobal(variable) or default end,
        setter or function(value) EUF.Database:SetGlobal(variable, value) end
    )

    local element = Settings.CreateCheckbox(category, setting, tooltip)

    return setting, element
end

local function CreateSlider(category, variable, name, default, minVal, maxVal, step, tooltip, getter, setter)
    local varKey = PREFIX .. variable

    local setting = Settings.RegisterProxySetting(
        category,
        varKey,
        Settings.VarType.Number,
        name,
        default,
        getter or function() return EUF.Database:GetGlobal(variable) or default end,
        setter or function(value) EUF.Database:SetGlobal(variable, value) end
    )

    local options = Settings.CreateSliderOptions(minVal, maxVal, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

    local element = Settings.CreateSlider(category, setting, options, tooltip)

    return setting, element
end

local function CreateHeader(category, text)
    local init = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", { name = text })
    Settings.RegisterInitializer(category, init)
    return init
end

-------------------------------------------------------------------------------
-- 通用设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateGeneralSettings(category)
    CreateHeader(category, "通用设置")

    -- 启用插件
    CreateCheckbox(category, "enableAddon", "启用插件", true, "启用或禁用 Enhanced Unit Frames 插件",
        function() return EUF.Database:GetGlobal("enableAddon") ~= false end,
        function(value)
            EUF.Database:SetGlobal("enableAddon", value)
            if value then
                EUF:OnEnable()
            else
                EUF:OnDisable()
            end
        end
    )

    -- 调试模式
    CreateCheckbox(category, "debugMode", "调试模式", false, "在聊天框输出调试信息",
        function() return EUF.Database:GetGlobal("debugMode") == true end,
        function(value)
            EUF.Database:SetGlobal("debugMode", value)
            EUF.debugMode = value
        end
    )
end

-------------------------------------------------------------------------------
-- 框体设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateFrameSettings(category, frameKey, displayName)
    CreateHeader(category, displayName)

    -- 启用自定义
    CreateCheckbox(category, frameKey .. "_enabled", "启用自定义", true, "为该框体启用自定义设置",
        function() return EUF.Database:Get("frames", frameKey, "enabled") ~= false end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "enabled")
            if EUF.frames[frameKey] then
                EUF.frames[frameKey]:SetEnabled(value)
            end
        end
    )

    -- 缩放
    CreateSlider(category, frameKey .. "_scale", "框体缩放", 1.0, 0.5, 2.0, 0.05, "调整框体大小 (50% - 200%)",
        function() return EUF.Database:Get("frames", frameKey, "scale") or 1.0 end,
        function(value)
            EUF.Database:Set(EUF.Database:ValidateScale(value), "frames", frameKey, "scale")
            if EUF.frames[frameKey] and not InCombatLockdown() then
                local blizzFrame = _G[EUF.FrameBase.BLIZZARD_FRAMES[frameKey]]
                if blizzFrame then
                    blizzFrame:SetScale(value)
                end
            end
        end
    )

    -- 头像设置
    self:CreatePortraitSettings(category, frameKey)

    -- 生命条设置
    self:CreateHealthBarSettings(category, frameKey)

    -- 能量条设置
    self:CreatePowerBarSettings(category, frameKey)

    -- 次级能量条设置（仅玩家）
    if frameKey == "player" then
        self:CreateSecondaryPowerBarSettings(category, frameKey)
    end

    -- 施法条设置
    self:CreateCastBarSettings(category, frameKey)

    -- 边框设置
    self:CreateBorderSettings(category, frameKey)
end

function OptionsPanel:CreateHealthBarSettings(category, frameKey)
    -- 启用生命条自定义
    CreateCheckbox(category, frameKey .. "_healthBarEnabled", "启用生命条自定义", true, "启用生命条自定义设置",
        function() return EUF.Database:Get("frames", frameKey, "healthBar", "enabled") ~= false end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "healthBar", "enabled")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.healthBar then
                local config = EUF.Database:Get("frames", frameKey, "healthBar")
                EUF.frames[frameKey].modules.healthBar:ApplyConfig(config)
            end
        end
    )

    -- 使用职业染色
    CreateCheckbox(category, frameKey .. "_healthClassColor", "生命条使用职业染色", true, "根据单位职业自动着色生命条",
        function() return EUF.Database:Get("frames", frameKey, "healthBar", "useClassColor") ~= false end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "healthBar", "useClassColor")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.healthBar then
                EUF.frames[frameKey].modules.healthBar:Update()
            end
        end
    )

    -- 生命条宽度
    CreateSlider(category, frameKey .. "_healthWidth", "生命条宽度", 200, 50, 400, 10, "调整生命条宽度",
        function() return EUF.Database:Get("frames", frameKey, "healthBar", "width") or 200 end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "healthBar", "width")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.healthBar then
                EUF.frames[frameKey].modules.healthBar:SetWidth(value)
            end
        end
    )

    -- 生命条高度
    CreateSlider(category, frameKey .. "_healthHeight", "生命条高度", 24, 5, 50, 1, "调整生命条高度",
        function() return EUF.Database:Get("frames", frameKey, "healthBar", "height") or 24 end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "healthBar", "height")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.healthBar then
                EUF.frames[frameKey].modules.healthBar:SetHeight(value)
            end
        end
    )
end

function OptionsPanel:CreatePowerBarSettings(category, frameKey)
    -- 启用能量条自定义
    CreateCheckbox(category, frameKey .. "_powerBarEnabled", "启用能量条自定义", true, "启用能量条自定义设置",
        function() return EUF.Database:Get("frames", frameKey, "powerBar", "enabled") ~= false end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "powerBar", "enabled")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.powerBar then
                local config = EUF.Database:Get("frames", frameKey, "powerBar")
                EUF.frames[frameKey].modules.powerBar:ApplyConfig(config)
            end
        end
    )

    -- 能量条使用能量类型颜色
    CreateCheckbox(category, frameKey .. "_powerTypeColor", "能量条按类型染色", true, "根据能量类型自动着色能量条",
        function() return EUF.Database:Get("frames", frameKey, "powerBar", "usePowerTypeColor") ~= false end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "powerBar", "usePowerTypeColor")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.powerBar then
                EUF.frames[frameKey].modules.powerBar:Update()
            end
        end
    )

    -- 能量条宽度
    CreateSlider(category, frameKey .. "_powerWidth", "能量条宽度", 200, 50, 400, 10, "调整能量条宽度",
        function() return EUF.Database:Get("frames", frameKey, "powerBar", "width") or 200 end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "powerBar", "width")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.powerBar then
                EUF.frames[frameKey].modules.powerBar:SetWidth(value)
            end
        end
    )

    -- 能量条高度
    CreateSlider(category, frameKey .. "_powerHeight", "能量条高度", 12, 3, 30, 1, "调整能量条高度",
        function() return EUF.Database:Get("frames", frameKey, "powerBar", "height") or 12 end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "powerBar", "height")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.powerBar then
                EUF.frames[frameKey].modules.powerBar:SetHeight(value)
            end
        end
    )
end

-------------------------------------------------------------------------------
-- 头像设置
-------------------------------------------------------------------------------

function OptionsPanel:CreatePortraitSettings(category, frameKey)
    -- 启用头像
    CreateCheckbox(category, frameKey .. "_portraitEnabled", "显示头像", true, "显示单位头像",
        function() return EUF.Database:Get("frames", frameKey, "portrait", "enabled") ~= false end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "portrait", "enabled")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.portrait then
                -- 更新模块配置并应用
                local config = EUF.Database:Get("frames", frameKey, "portrait")
                EUF.frames[frameKey].modules.portrait:ApplyConfig(config)
            end
        end
    )

    -- 头像宽度
    CreateSlider(category, frameKey .. "_portraitWidth", "头像宽度", 64, 32, 128, 4, "调整头像宽度",
        function() return EUF.Database:Get("frames", frameKey, "portrait", "width") or 64 end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "portrait", "width")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.portrait then
                EUF.frames[frameKey].modules.portrait:SetSize(value, EUF.Database:Get("frames", frameKey, "portrait", "height") or 64)
            end
        end
    )

    -- 头像高度
    CreateSlider(category, frameKey .. "_portraitHeight", "头像高度", 64, 32, 128, 4, "调整头像高度",
        function() return EUF.Database:Get("frames", frameKey, "portrait", "height") or 64 end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "portrait", "height")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.portrait then
                EUF.frames[frameKey].modules.portrait:SetSize(EUF.Database:Get("frames", frameKey, "portrait", "width") or 64, value)
            end
        end
    )

    -- 头像边框
    CreateCheckbox(category, frameKey .. "_portraitBorder", "显示头像边框", true, "为头像添加边框",
        function() return EUF.Database:Get("frames", frameKey, "portrait", "borderEnabled") ~= false end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "portrait", "borderEnabled")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.portrait then
                EUF.frames[frameKey].modules.portrait:ApplyConfig()
            end
        end
    )
end

-------------------------------------------------------------------------------
-- 次级能量条设置（仅玩家）
-------------------------------------------------------------------------------

function OptionsPanel:CreateSecondaryPowerBarSettings(category, frameKey)
    CreateHeader(category, "次级能量条设置")

    -- 启用次级能量条
    CreateCheckbox(category, frameKey .. "_secondaryPowerEnabled", "显示次级能量条", true, "显示职业特殊能量（神圣能量、连击点等）",
        function() return EUF.Database:Get("frames", frameKey, "secondaryPowerBar", "enabled") ~= false end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "secondaryPowerBar", "enabled")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.secondaryPowerBar then
                local config = EUF.Database:Get("frames", frameKey, "secondaryPowerBar")
                EUF.frames[frameKey].modules.secondaryPowerBar:ApplyConfig(config)
            end
        end
    )

    -- 次级能量条宽度
    CreateSlider(category, frameKey .. "_secondaryPowerWidth", "次级能量条宽度", 200, 50, 400, 10, "调整次级能量条宽度",
        function() return EUF.Database:Get("frames", frameKey, "secondaryPowerBar", "width") or 200 end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "secondaryPowerBar", "width")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.secondaryPowerBar then
                EUF.frames[frameKey].modules.secondaryPowerBar:ApplyConfig()
            end
        end
    )

    -- 次级能量条高度
    CreateSlider(category, frameKey .. "_secondaryPowerHeight", "次级能量条高度", 6, 3, 20, 1, "调整次级能量条高度",
        function() return EUF.Database:Get("frames", frameKey, "secondaryPowerBar", "height") or 6 end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "secondaryPowerBar", "height")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.secondaryPowerBar then
                EUF.frames[frameKey].modules.secondaryPowerBar:ApplyConfig()
            end
        end
    )
end

-------------------------------------------------------------------------------
-- 施法条设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateCastBarSettings(category, frameKey)
    CreateHeader(category, "施法条设置")

    -- 启用施法条
    CreateCheckbox(category, frameKey .. "_castBarEnabled", "显示施法条", true, "显示施法进度条",
        function() return EUF.Database:Get("frames", frameKey, "castBar", "enabled") ~= false end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "castBar", "enabled")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.castBar then
                local config = EUF.Database:Get("frames", frameKey, "castBar")
                EUF.frames[frameKey].modules.castBar:ApplyConfig(config)
            end
        end
    )

    -- 施法条宽度
    CreateSlider(category, frameKey .. "_castBarWidth", "施法条宽度", 200, 100, 400, 10, "调整施法条宽度",
        function() return EUF.Database:Get("frames", frameKey, "castBar", "width") or 200 end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "castBar", "width")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.castBar then
                EUF.frames[frameKey].modules.castBar:ApplyConfig()
            end
        end
    )

    -- 施法条高度
    CreateSlider(category, frameKey .. "_castBarHeight", "施法条高度", 16, 8, 40, 1, "调整施法条高度",
        function() return EUF.Database:Get("frames", frameKey, "castBar", "height") or 16 end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "castBar", "height")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.castBar then
                EUF.frames[frameKey].modules.castBar:ApplyConfig()
            end
        end
    )

    -- 显示施法计时器
    CreateCheckbox(category, frameKey .. "_castBarTimer", "显示施法计时器", true, "显示剩余施法时间",
        function() return EUF.Database:Get("frames", frameKey, "castBar", "showTimer") ~= false end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "castBar", "showTimer")
        end
    )

    -- 显示施法图标
    CreateCheckbox(category, frameKey .. "_castBarIcon", "显示施法图标", true, "显示施法技能图标",
        function() return EUF.Database:Get("frames", frameKey, "castBar", "showIcon") ~= false end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "castBar", "showIcon")
        end
    )
end

-------------------------------------------------------------------------------
-- 边框设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateBorderSettings(category, frameKey)
    CreateHeader(category, "边框设置")

    -- 启用边框
    CreateCheckbox(category, frameKey .. "_borderEnabled", "显示边框", false, "为框体添加边框",
        function() return EUF.Database:Get("frames", frameKey, "border", "enabled") == true end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "border", "enabled")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.border then
                local config = EUF.Database:Get("frames", frameKey, "border")
                EUF.frames[frameKey].modules.border:ApplyConfig(config)
            end
        end
    )

    -- 边框粗细
    CreateSlider(category, frameKey .. "_borderSize", "边框粗细", 2, 1, 5, 1, "调整边框粗细",
        function() return EUF.Database:Get("frames", frameKey, "border", "size") or 2 end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "border", "size")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.border then
                EUF.frames[frameKey].modules.border:ApplyConfig()
            end
        end
    )

    -- 使用职业色边框
    CreateCheckbox(category, frameKey .. "_borderClassColor", "使用职业色边框", false, "边框颜色随职业变化",
        function() return EUF.Database:Get("frames", frameKey, "border", "useClassColor") == true end,
        function(value)
            EUF.Database:Set(value, "frames", frameKey, "border", "useClassColor")
            if EUF.frames[frameKey] and EUF.frames[frameKey].modules and EUF.frames[frameKey].modules.border then
                if value then
                    EUF.frames[frameKey].modules.border:SetClassColor()
                else
                    EUF.frames[frameKey].modules.border:ApplyConfig()
                end
            end
        end
    )
end

-------------------------------------------------------------------------------
-- 小地图按钮设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateMinimapSettings(category)
    CreateHeader(category, "小地图按钮设置")

    -- 显示小地图按钮
    CreateCheckbox(category, "showMinimapButton", "显示小地图按钮", false, "在小地图旁显示快捷按钮",
        function() return EUF.Database:Get("minimap", "hide") ~= true end,
        function(value)
            EUF.Database:Set(not value, "minimap", "hide")
            if EUF.MinimapButton then
                EUF.MinimapButton:Refresh()
            end
        end
    )

    -- 锁定按钮位置
    CreateCheckbox(category, "lockMinimapButton", "锁定按钮位置", false, "锁定小地图按钮位置，禁止拖拽",
        function() return EUF.Database:Get("minimap", "locked") == true end,
        function(value)
            EUF.Database:Set(value, "minimap", "locked")
        end
    )
end

-------------------------------------------------------------------------------
-- 高级设置
-------------------------------------------------------------------------------

function OptionsPanel:CreateAdvancedSettings(category)
    CreateHeader(category, "高级选项")

    -- 重置配置
    CreateCheckbox(category, "resetConfigConfirm", "重置所有配置", false, "勾选此项将重置所有设置为默认值",
        function() return false end,
        function(value)
            if value then
                C_Timer.After(0.1, function()
                    EUF.Database:ResetProfile()
                    EUF:InitializeModules()
                    EUF:Print("配置已重置")
                end)
            end
        end
    )
end

-------------------------------------------------------------------------------
-- 打开设置面板
-------------------------------------------------------------------------------

function OptionsPanel:Open()
    if self.category then
        local categoryID = self.category:GetID()
        if categoryID then
            Settings.OpenToCategory(categoryID)
        else
            EUF:Print("无法获取设置分类 ID")
        end
    else
        EUF:Print("设置面板未正确初始化")
    end
end

return OptionsPanel