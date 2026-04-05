-- PowerBarModule.lua
-- EnhancedUnitFrames 能量条模块
-- 处理能量条的显示、染色和材质
-- 注意：边框由 BorderModule 单独处理，不在本模块设置边框

local addonName, EUF = ...

local PowerBarModule = {}
EUF.PowerBarModule = PowerBarModule

-- 继承模块基类
setmetatable(PowerBarModule, {__index = EUF.ModuleBase})

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function PowerBarModule:New(moduleKey, frameKey, unit)
    local obj = EUF.ModuleBase.New(self, moduleKey, frameKey, unit)
    obj.powerBar = nil
    obj.originalTexture = nil
    obj.originalColor = {r = 0, g = 0.5, b = 1, a = 1}
    obj.currentPowerType = nil
    obj.hidden = false
    return obj
end

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function PowerBarModule:Initialize(parent, config)
    if self.initialized then return end

    self.parent = parent
    self.config = config or EUF.Database:GetModuleConfig(self.frameKey, "powerBar")

    -- 查找能量条
    self:FindPowerBar()

    if not self.powerBar then
        EUF:Debug(string.format("PowerBarModule: %s 能量条未找到", self.frameKey))
        return
    end

    -- 保存原始状态
    self.originalTexture = self.powerBar:GetStatusBarTexture()
    -- WoW 12.0: GetStatusBarColor() 返回 4 个数值 (r, g, b, a)
    local r, g, b, a = self.powerBar:GetStatusBarColor()
    self.originalColor = {
        r = r or 0,
        g = g or 0.5,
        b = b or 1,
        a = a or 1
    }

    -- 检查是否启用
    if not self.config or not self.config.enabled then
        self.enabled = false
        return
    end

    -- 应用配置（不包括边框）
    self:ApplyConfigInternal(self.config)

    self.initialized = true
    self.enabled = true

    -- 初始更新
    self:Update()

    EUF:Debug(string.format("PowerBarModule: %s 初始化完成", self.frameKey))
end

-------------------------------------------------------------------------------
-- 查找能量条
-------------------------------------------------------------------------------

function PowerBarModule:FindPowerBar()
    -- WoW 12.0: 优先使用暴雪提供的获取函数
    if self.frameKey == "player" then
        -- 方法 1: 使用暴雪提供的函数（推荐）
        if _G.PlayerFrame_GetManaBar then
            self.powerBar = _G.PlayerFrame_GetManaBar()
        end

        -- 方法 2: 新结构路径
        if not self.powerBar and PlayerFrame and PlayerFrame.PlayerFrameContent then
            local content = PlayerFrame.PlayerFrameContent
            if content.PlayerFrameContentMain then
                local main = content.PlayerFrameContentMain
                -- 尝试 ManaBarsContainer 或 ManaBar
                if main.ManaBarsContainer then
                    self.powerBar = main.ManaBarsContainer.ManaBar
                elseif main.ManaBar then
                    self.powerBar = main.ManaBar
                end
            end
        end

        -- 方法 3: 旧版全局变量
        if not self.powerBar then
            self.powerBar = _G.PlayerFrameManaBar
        end

    elseif self.frameKey == "target" then
        -- 目标框体能量条
        if TargetFrame and TargetFrame.TargetFrameContent then
            local content = TargetFrame.TargetFrameContent
            if content.TargetFrameContentMain then
                local main = content.TargetFrameContentMain
                if main.ManaBarsContainer then
                    self.powerBar = main.ManaBarsContainer.ManaBar
                elseif main.ManaBar then
                    self.powerBar = main.ManaBar
                end
            end
        end

        if not self.powerBar then
            self.powerBar = _G.TargetFrameManaBar
        end

    elseif self.frameKey == "focus" then
        -- 焦点框体能量条
        if FocusFrame and FocusFrame.FocusFrameContent then
            local content = FocusFrame.FocusFrameContent
            if content.FocusFrameContentMain then
                local main = content.FocusFrameContentMain
                if main.ManaBarsContainer then
                    self.powerBar = main.ManaBarsContainer.ManaBar
                elseif main.ManaBar then
                    self.powerBar = main.ManaBar
                end
            end
        end

        if not self.powerBar then
            self.powerBar = _G.FocusFrameManaBar
        end

    elseif self.frameKey == "pet" then
        self.powerBar = _G.PetFrameManaBar

    elseif self.frameKey == "targettarget" then
        self.powerBar = nil  -- 目标的目标通常没有能量条显示
    end
end

-------------------------------------------------------------------------------
-- 应用配置
-------------------------------------------------------------------------------

function PowerBarModule:ApplyConfig(config)
    if not self.powerBar then return end

    self.config = config

    -- 检查是否隐藏（优先级最高）
    local hidden = config and config.hidden
    if hidden then
        self:HideFrame()
        return
    end

    -- 检查是否启用
    if not config or not config.enabled then
        self:Hide()
        return
    end

    self:ApplyConfigInternal(config)
    self.enabled = true
    self.hidden = false
end

-- 内部配置应用（不包含边框）
function PowerBarModule:ApplyConfigInternal(config)
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

function PowerBarModule:SetTexture(textureName)
    if not self.powerBar then return end

    local texture = self:GetTexturePath(textureName)
    if texture then
        self.powerBar:SetStatusBarTexture(texture)
    end
end

function PowerBarModule:GetTexturePath(name)
    local textures = {
        ["Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
        ["Blizzard RAID"] = "Interface\\RaidFrame\\Raid-Bar-Hp-Bg",
        ["Flat"] = "Interface\\Buttons\\WHITE8X8",
        ["Gradient"] = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\gradient.tga",
    }

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

function PowerBarModule:SetColor(r, g, b, a)
    if not self.powerBar then return end
    a = a or 1
    -- WoW 12.0: SetStatusBarColor(r, g, b, a) - 使用4参数形式
    self.powerBar:SetStatusBarColor(r, g, b, a)
end

function PowerBarModule:SetPowerTypeColor()
    if not self.powerBar then return end

    -- 获取当前能量类型
    local powerType, powerToken = UnitPowerType(self.unit)

    -- 更新当前能量类型
    self.currentPowerType = powerToken

    -- 获取能量类型对应的颜色
    local color = EUF.Database.POWER_COLORS[powerToken]
    if color then
        self:SetColor(color.r, color.g, color.b, 1)
    else
        -- 使用暴雪默认颜色
        local powerColor = PowerBarColor and PowerBarColor[powerToken]
        if powerColor then
            local r = powerColor.r or powerColor[1]
            local g = powerColor.g or powerColor[2]
            local b = powerColor.b or powerColor[3]
            self:SetColor(r, g, b, 1)
        end
    end
end

function PowerBarModule:SetCustomColor(color)
    if not self.powerBar or not color then return end
    self:SetColor(color.r, color.g, color.b, color.a or 1)
end

-------------------------------------------------------------------------------
-- 更新
-------------------------------------------------------------------------------

function PowerBarModule:Update()
    if not self.initialized or not self.enabled then return end
    if not self.powerBar then return end

    -- 应用颜色
    self:ApplyColor()
end

function PowerBarModule:ApplyColor()
    if not self.config then return end

    -- 检查单位是否存在
    if not UnitExists(self.unit) then
        return
    end

    -- 按能量类型染色
    if self.config.usePowerTypeColor then
        self:SetPowerTypeColor()
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

function PowerBarModule:Refresh()
    self:Update()
end

-------------------------------------------------------------------------------
-- 显示/隐藏
-------------------------------------------------------------------------------

function PowerBarModule:Show()
    -- 能量条由暴雪控制
    if self.powerBar then
        self.powerBar:SetAlpha(1)
        self.powerBar:Show()
    end
    self.enabled = true
    self.hidden = false
    self:ApplyColor()
end

function PowerBarModule:Hide()
    -- 禁用自定义设置，恢复暴雪默认
    self.enabled = false
    -- 恢复原始颜色
    if self.powerBar and self.originalColor then
        local r = self.originalColor.r or 0
        local g = self.originalColor.g or 0.5
        local b = self.originalColor.b or 1
        self:SetColor(r, g, b, 1)
    end
end

-- 完全隐藏能量条框体（隐藏功能）
function PowerBarModule:HideFrame()
    if self.powerBar then
        self.powerBar:SetAlpha(0)
        self.powerBar:Hide()
    end
    self.enabled = false
    self.hidden = true
end

function PowerBarModule:Disable()
    self:Hide()
end

-------------------------------------------------------------------------------
-- 尺寸设置（覆盖基类方法）
-------------------------------------------------------------------------------

function PowerBarModule:SetWidth(width)
    if not self.powerBar then return end
    if not InCombatLockdown() then
        local height = self.powerBar:GetHeight()
        self.powerBar:SetSize(width, height)
    end
end

function PowerBarModule:SetHeight(height)
    if not self.powerBar then return end
    if not InCombatLockdown() then
        local width = self.powerBar:GetWidth()
        self.powerBar:SetSize(width, height)
    end
end

function PowerBarModule:SetSize(width, height)
    if not self.powerBar then return end
    if not InCombatLockdown() then
        self.powerBar:SetSize(width, height)
    end
end

return PowerBarModule