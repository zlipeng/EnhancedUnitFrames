-- HealthBarModule.lua
-- EnhancedUnitFrames 生命条模块
-- 处理生命条的显示、染色和材质
-- 注意：边框由 BorderModule 单独处理，不在本模块设置边框

local addonName, EUF = ...

local HealthBarModule = {}
EUF.HealthBarModule = HealthBarModule

-- 继承模块基类
setmetatable(HealthBarModule, {__index = EUF.ModuleBase})

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function HealthBarModule:New(moduleKey, frameKey, unit)
    local obj = EUF.ModuleBase.New(self, moduleKey, frameKey, unit)
    obj.healthBar = nil
    obj.originalTexture = nil
    obj.originalColor = {r = 1, g = 1, b = 1, a = 1}
    return obj
end

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function HealthBarModule:Initialize(parent, config)
    if self.initialized then return end

    self.parent = parent
    self.config = config or EUF.Database:GetModuleConfig(self.frameKey, "healthBar")

    -- 查找生命条
    self:FindHealthBar()

    if not self.healthBar then
        EUF:Debug(string.format("HealthBarModule: %s 生命条未找到", self.frameKey))
        return
    end

    -- 保存原始状态
    self.originalTexture = self.healthBar:GetStatusBarTexture()
    -- WoW 12.0: GetStatusBarColor() 返回 4 个数值 (r, g, b, a)
    local r, g, b, a = self.healthBar:GetStatusBarColor()
    self.originalColor = {
        r = r or 1,
        g = g or 1,
        b = b or 1,
        a = a or 1
    }

    -- 检查是否启用
    if not self.config or not self.config.enabled then
        self.enabled = false
        return
    end

    -- 应用配置（不包括边框，边框由 BorderModule 处理）
    self:ApplyConfigInternal(self.config)

    self.initialized = true
    self.enabled = true

    -- 初始更新
    self:Update()

    EUF:Debug(string.format("HealthBarModule: %s 初始化完成", self.frameKey))
end

-------------------------------------------------------------------------------
-- 查找生命条
-------------------------------------------------------------------------------

function HealthBarModule:FindHealthBar()
    -- WoW 12.0 框体结构：需要通过 HealthBarsContainer 查找
    if self.frameKey == "player" then
        -- 优先使用新结构路径
        if PlayerFrame and PlayerFrame.PlayerFrameContent then
            local content = PlayerFrame.PlayerFrameContent
            if content.PlayerFrameContentMain then
                local main = content.PlayerFrameContentMain
                -- WoW 12.0: 正确路径包含 HealthBarsContainer
                if main.HealthBarsContainer then
                    self.healthBar = main.HealthBarsContainer.HealthBar
                end
            end
        end
        -- 备用：旧版全局变量
        if not self.healthBar then
            self.healthBar = _G.PlayerFrameHealthBar
        end

    elseif self.frameKey == "target" then
        if TargetFrame and TargetFrame.TargetFrameContent then
            local content = TargetFrame.TargetFrameContent
            if content.TargetFrameContentMain then
                local main = content.TargetFrameContentMain
                if main.HealthBarsContainer then
                    self.healthBar = main.HealthBarsContainer.HealthBar
                end
            end
        end
        if not self.healthBar then
            self.healthBar = _G.TargetFrameHealthBar
        end

    elseif self.frameKey == "focus" then
        if FocusFrame and FocusFrame.FocusFrameContent then
            local content = FocusFrame.FocusFrameContent
            if content.FocusFrameContentMain then
                local main = content.FocusFrameContentMain
                if main.HealthBarsContainer then
                    self.healthBar = main.HealthBarsContainer.HealthBar
                end
            end
        end
        if not self.healthBar then
            self.healthBar = _G.FocusFrameHealthBar
        end

    elseif self.frameKey == "pet" then
        -- PetFrame 结构可能不同
        if PetFrame and PetFrame.PetFrameContent then
            local content = PetFrame.PetFrameContent
            if content.HealthBarsContainer then
                self.healthBar = content.HealthBarsContainer.HealthBar
            end
        end
        if not self.healthBar then
            self.healthBar = _G.PetFrameHealthBar
        end

    elseif self.frameKey == "targettarget" then
        self.healthBar = _G.TargetFrameToTHealthBar
        if not self.healthBar and TargetFrameToT then
            if TargetFrameToT.TargetFrameToTContent then
                local content = TargetFrameToT.TargetFrameToTContent
                if content.HealthBarsContainer then
                    self.healthBar = content.HealthBarsContainer.HealthBar
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- 应用配置
-------------------------------------------------------------------------------

function HealthBarModule:ApplyConfig(config)
    if not self.healthBar then return end

    self.config = config

    -- 检查是否启用
    if not config or not config.enabled then
        self:Hide()
        return
    end

    self:ApplyConfigInternal(config)
    self.enabled = true
end

-- 内部配置应用（不包含边框）
function HealthBarModule:ApplyConfigInternal(config)
    -- 应用尺寸（在战斗中跳过）
    if config.width and config.height and not InCombatLockdown() then
        self:SetSize(config.width, config.height)
    end

    -- 应用材质
    if config.texture then
        self:SetTexture(config.texture)
    end

    -- 注意：边框由 BorderModule 单独处理
    -- 不在这里调用 SetBackdrop 以避免 Taint
end

-------------------------------------------------------------------------------
-- 材质设置
-------------------------------------------------------------------------------

function HealthBarModule:SetTexture(textureName)
    if not self.healthBar then return end

    local texture = self:GetTexturePath(textureName)
    if texture then
        self.healthBar:SetStatusBarTexture(texture)
    end
end

function HealthBarModule:GetTexturePath(name)
    local textures = {
        ["Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
        ["Blizzard RAID"] = "Interface\\RaidFrame\\Raid-Bar-Hp-Bg",
        ["Flat"] = "Interface\\Buttons\\WHITE8X8",
        ["Gradient"] = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\gradient.tga",
    }

    -- 尝试从 LibSharedMedia 获取
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local path = LSM:Fetch("statusbar", name, true)
        if path then return path end
    end

    return textures[name] or textures["Blizzard"]
end

-------------------------------------------------------------------------------
-- 颜色设置
-------------------------------------------------------------------------------

function HealthBarModule:SetColor(r, g, b, a)
    if not self.healthBar then return end
    a = a or 1
    -- WoW 12.0: SetStatusBarColor(r, g, b, a) - 使用4参数形式
    self.healthBar:SetStatusBarColor(r, g, b, a)
end

function HealthBarModule:SetClassColor()
    if not self.healthBar then return end

    local color = EUF.SecretSafe.SafeGetClassColor(self.unit)
    if color then
        -- WoW 12.0: SetStatusBarColor(r, g, b, a) - 使用4参数形式
        self.healthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
    end
end

function HealthBarModule:SetReactionColor()
    if not self.healthBar then return end

    local color = EUF.SecretSafe.SafeGetReactionColor(self.unit)
    if color then
        -- WoW 12.0: SetStatusBarColor(r, g, b, a) - 使用4参数形式
        self.healthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
    end
end

function HealthBarModule:SetCustomColor(color)
    if not self.healthBar or not color then return end
    self:SetColor(color.r, color.g, color.b, color.a or 1)
end

-------------------------------------------------------------------------------
-- 更新
-------------------------------------------------------------------------------

function HealthBarModule:Update()
    if not self.initialized or not self.enabled then return end
    if not self.healthBar then return end

    -- 应用颜色
    self:ApplyColor()
end

function HealthBarModule:ApplyColor()
    if not self.config then return end

    -- 检查单位是否存在
    if not UnitExists(self.unit) then
        return
    end

    -- 职业染色
    if self.config.useClassColor and UnitIsPlayer(self.unit) then
        self:SetClassColor()
        return
    end

    -- 反应色（NPC）
    if self.config.useReactionColor and not UnitIsPlayer(self.unit) then
        self:SetReactionColor()
        return
    end

    -- 自定义颜色
    if self.config.customColor then
        self:SetCustomColor(self.config.customColor)
        return
    end

    -- 恢复原始颜色
    self:SetColor(self.originalColor.r, self.originalColor.g, self.originalColor.b)
end

-------------------------------------------------------------------------------
-- 刷新
-------------------------------------------------------------------------------

function HealthBarModule:Refresh()
    self:Update()
end

-------------------------------------------------------------------------------
-- 显示/隐藏
-------------------------------------------------------------------------------

function HealthBarModule:Show()
    -- 生命条由暴雪控制，我们只设置启用状态和应用颜色
    self.enabled = true
    self:ApplyColor()
end

function HealthBarModule:Hide()
    -- 生命条不能真正隐藏（游戏需要显示生命值）
    -- 这里只禁用自定义设置，恢复暴雪默认
    self.enabled = false
    -- 恢复原始颜色
    if self.healthBar and self.originalColor then
        local r = self.originalColor.r or 1
        local g = self.originalColor.g or 1
        local b = self.originalColor.b or 1
        self:SetColor(r, g, b, 1)
    end
end

function HealthBarModule:Disable()
    self:Hide()
end

-------------------------------------------------------------------------------
-- 尺寸设置（覆盖基类方法）
-------------------------------------------------------------------------------

function HealthBarModule:SetWidth(width)
    if not self.healthBar then return end
    -- 暴雪框体通常有自己的尺寸管理
    -- 尝试设置但可能被暴雪覆盖
    if not InCombatLockdown() then
        local height = self.healthBar:GetHeight()
        self.healthBar:SetSize(width, height)
    end
end

function HealthBarModule:SetHeight(height)
    if not self.healthBar then return end
    if not InCombatLockdown() then
        local width = self.healthBar:GetWidth()
        self.healthBar:SetSize(width, height)
    end
end

function HealthBarModule:SetSize(width, height)
    if not self.healthBar then return end
    if not InCombatLockdown() then
        self.healthBar:SetSize(width, height)
    end
end

return HealthBarModule