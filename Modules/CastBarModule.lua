-- CastBarModule.lua
-- EnhancedUnitFrames 施法条模块
-- 显示施法进度条

local addonName, EUF = ...

local CastBarModule = {}
EUF.CastBarModule = CastBarModule

-- 继承模块基类
setmetatable(CastBarModule, {__index = EUF.ModuleBase})

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function CastBarModule:New(moduleKey, frameKey, unit)
    local obj = EUF.ModuleBase.New(self, moduleKey, frameKey, unit)
    obj.castBar = nil
    obj.castBarText = nil
    obj.castBarTimer = nil
    obj.castBarSpark = nil
    obj.castBarIcon = nil
    obj.eventFrame = nil
    obj.hidden = false
    return obj
end

-------------------------------------------------------------------------------
-- 创建UI元素
-------------------------------------------------------------------------------

function CastBarModule:CreateElements()
    -- 查找暴雪原生施法条
    self:FindBlizzardCastBar()

    -- 如果有原生施法条，对其进行增强
    if self.castBar then
        self:EnhanceCastBar()
    else
        -- 创建自定义施法条
        self:CreateCustomCastBar()
    end

    -- 注册事件
    self:RegisterEvents()
end

-------------------------------------------------------------------------------
-- 查找暴雪施法条
-------------------------------------------------------------------------------

function CastBarModule:FindBlizzardCastBar()
    if self.frameKey == "player" then
        -- 玩家施法条
        self.castBar = _G.PlayerCastingBarFrame
        if not self.castBar then
            -- 12.0 新结构
            if CastingBarFrame then
                self.castBar = CastingBarFrame
            end
        end

    elseif self.frameKey == "target" then
        -- 目标施法条
        self.castBar = _G.TargetFrameSpellBar
        if not self.castBar and TargetFrame then
            if TargetFrame.TargetFrameContent then
                self.castBar = TargetFrame.TargetFrameContent.CastBar
            end
        end

    elseif self.frameKey == "focus" then
        -- 焦点施法条
        self.castBar = _G.FocusFrameSpellBar
        if not self.castBar and FocusFrame then
            if FocusFrame.FocusFrameContent then
                self.castBar = FocusFrame.FocusFrameContent.CastBar
            end
        end

    elseif self.frameKey == "pet" then
        -- 宠物施法条
        self.castBar = _G.PetCastingBarFrame
    end

    if self.castBar then
        self.elements.castBar = self.castBar
        EUF:Debug(string.format("CastBarModule: %s 找到暴雪施法条", self.frameKey))
    end
end

-------------------------------------------------------------------------------
-- 增强暴雪施法条
-------------------------------------------------------------------------------

function CastBarModule:EnhanceCastBar()
    if not self.castBar then return end

    -- 应用尺寸配置
    local width = self:GetConfigValue("width", 200)
    local height = self:GetConfigValue("height", 16)

    if not InCombatLockdown() then
        self.castBar:SetSize(width, height)
    end

    -- 创建/查找文字显示
    self:FindOrCreateCastText()

    -- 创建计时器文字
    if self:GetConfigValue("showTimer", true) then
        self:CreateTimerText()
    end

    -- 创建施法图标
    if self:GetConfigValue("showIcon", true) then
        self:CreateCastIcon()
    end

    -- 应用材质
    self:ApplyTexture()
end

-------------------------------------------------------------------------------
-- 创建自定义施法条
-------------------------------------------------------------------------------

function CastBarModule:CreateCustomCastBar()
    if not self.parent then return end

    local width = self:GetConfigValue("width", 200)
    local height = self:GetConfigValue("height", 16)

    -- 创建施法条框架
    self.castBar = CreateFrame("StatusBar", nil, self.parent)
    self.castBar:SetSize(width, height)
    self.castBar:SetPoint("TOPLEFT", self.parent, "BOTTOMLEFT", 0, -5)

    -- 设置状态条纹理
    local texture = self:GetConfigValue("texture", "Blizzard")
    local texturePath = self:GetTexturePath(texture)
    self.castBar:SetStatusBarTexture(texturePath)

    -- 默认颜色
    self.castBar:SetStatusBarColor(1.0, 0.7, 0.0, 1)

    -- 背景纹理
    local bg = self.castBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(texturePath)
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    -- 施法文字
    self.castBarText = self.castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.castBarText:SetPoint("LEFT", self.castBar, "LEFT", 5, 0)
    self.castBarText:SetWidth(width - 40)

    -- 计时器文字
    self.castBarTimer = self.castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.castBarTimer:SetPoint("RIGHT", self.castBar, "RIGHT", -5, 0)

    -- 光效
    self.castBarSpark = self.castBar:CreateTexture(nil, "OVERLAY")
    self.castBarSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    self.castBarSpark:SetSize(16, height)
    self.castBarSpark:SetBlendMode("ADD")

    -- 施法图标
    self:CreateCastIcon()

    self.elements.castBar = self.castBar
    self.elements.castBarText = self.castBarText
    self.elements.castBarTimer = self.castBarTimer
end

-------------------------------------------------------------------------------
-- 查找或创建施法文字
-------------------------------------------------------------------------------

function CastBarModule:FindOrCreateCastText()
    if not self.castBar then return end

    -- 尝试查找现有文字
    if self.castBar.Text then
        self.castBarText = self.castBar.Text
    elseif self.castBar.NameText then
        self.castBarText = self.castBar.NameText
    else
        -- 创建新文字
        self.castBarText = self.castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        self.castBarText:SetPoint("LEFT", self.castBar, "LEFT", 5, 0)
    end

    self.elements.castBarText = self.castBarText
end

-------------------------------------------------------------------------------
-- 创建计时器文字
-------------------------------------------------------------------------------

function CastBarModule:CreateTimerText()
    if not self.castBar then return end

    -- 尝试查找现有计时器
    if self.castBar.TimerText then
        self.castBarTimer = self.castBar.TimerText
    else
        self.castBarTimer = self.castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        self.castBarTimer:SetPoint("RIGHT", self.castBar, "RIGHT", -5, 0)
    end

    self.elements.castBarTimer = self.castBarTimer
end

-------------------------------------------------------------------------------
-- 创建施法图标
-------------------------------------------------------------------------------

function CastBarModule:CreateCastIcon()
    if not self.castBar then return end

    local iconSize = self:GetConfigValue("iconSize", 16)

    -- 尝试查找现有图标
    if self.castBar.Icon then
        self.castBarIcon = self.castBar.Icon
    else
        -- 创建图标框架
        local iconFrame = CreateFrame("Frame", nil, self.castBar)
        iconFrame:SetSize(iconSize, iconSize)
        iconFrame:SetPoint("LEFT", self.castBar, "LEFT", -iconSize - 5, 0)

        -- 创建图标纹理
        self.castBarIcon = iconFrame:CreateTexture(nil, "ARTWORK")
        self.castBarIcon:SetAllPoints()

        -- 边框
        local border = iconFrame:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
        border:SetAllPoints()
        border:SetTexCoord(0.296875, 0.5703125, 0.1015625, 0.375)

        self.elements.castBarIconFrame = iconFrame
    end

    self.elements.castBarIcon = self.castBarIcon
end

-------------------------------------------------------------------------------
-- 应用材质
-------------------------------------------------------------------------------

function CastBarModule:ApplyTexture()
    if not self.castBar then return end

    local texture = self:GetConfigValue("texture", "Blizzard")
    local texturePath = self:GetTexturePath(texture)

    -- 设置状态条纹理
    if self.castBar.SetStatusBarTexture then
        self.castBar:SetStatusBarTexture(texturePath)
    end

    -- 设置背景纹理（如果是我们创建的）
    if self.castBar.Background then
        self.castBar.Background:SetTexture(texturePath)
    end
end

-------------------------------------------------------------------------------
-- 注册事件
-------------------------------------------------------------------------------

function CastBarModule:RegisterEvents()
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:SetScript("OnEvent", function(frame, event, unit, ...)
            self:OnCastEvent(event, unit, ...)
        end)
    end

    -- 施法相关事件
    local events = {
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_DELAYED",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_CHANNEL_UPDATE",
        "UNIT_SPELLCAST_EMPOWER_START",
        "UNIT_SPELLCAST_EMPOWER_STOP",
        "UNIT_SPELLCAST_EMPOWER_UPDATE",
    }

    for _, event in ipairs(events) do
        self.eventFrame:RegisterUnitEvent(event, self.unit)
    end

    -- 单位切换事件
    if self.frameKey == "target" then
        self.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    elseif self.frameKey == "focus" then
        self.eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    end
end

-------------------------------------------------------------------------------
-- 施法事件处理
-------------------------------------------------------------------------------

function CastBarModule:OnCastEvent(event, unit, ...)
    if not self.initialized or not self.enabled then return end
    if unit ~= self.unit then return end

    if event == "UNIT_SPELLCAST_START" then
        self:OnSpellCastStart(...)

    elseif event == "UNIT_SPELLCAST_STOP" then
        self:OnSpellCastStop()

    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        self:OnSpellCastFailed()

    elseif event == "UNIT_SPELLCAST_DELAYED" then
        self:OnSpellCastDelayed(...)

    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        self:OnSpellCastChannelStart(...)

    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        self:OnSpellCastChannelStop()

    elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        self:OnSpellCastChannelUpdate(...)

    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
        self:OnTargetChanged()
    end
end

-------------------------------------------------------------------------------
-- 施法开始
-------------------------------------------------------------------------------

function CastBarModule:OnSpellCastStart(name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible)
    if not self.castBar then return end

    -- 设置施法条数值
    local duration = endTime - startTime
    self.castBar:SetMinMaxValues(0, duration)

    -- 更新文字
    if self.castBarText then
        self.castBarText:SetText(text)
    end

    -- 更新图标
    if self.castBarIcon and texture then
        self.castBarIcon:SetTexture(texture)
    end

    -- 显示施法条
    if not InCombatLockdown() then
        self.castBar:Show()
    end

    -- 设置颜色
    if notInterruptible then
        self.castBar:SetStatusBarColor(0.8, 0.8, 0.8, 1)
    else
        self.castBar:SetStatusBarColor(1.0, 0.7, 0.0, 1)
    end

    -- 开始计时器更新
    self.castStartTime = startTime / 1000
    self.castEndTime = endTime / 1000
    self.castDuration = duration / 1000
    self.isChanneling = false

    if self.castBarTimer and not self.castBar.onUpdateScript then
        self.castBar:SetScript("OnUpdate", function()
            self:UpdateTimer()
        end)
        self.castBar.onUpdateScript = true
    end
end

-------------------------------------------------------------------------------
-- 施法停止
-------------------------------------------------------------------------------

function CastBarModule:OnSpellCastStop()
    if not self.castBar then return end

    -- 清除计时器更新脚本（如果是我们添加的）
    if self.castBarTimer and self.castBar.onUpdateScript then
        self.castBar:SetScript("OnUpdate", nil)
        self.castBar.onUpdateScript = nil
    end

    self.castStartTime = nil
    self.castEndTime = nil
end

-------------------------------------------------------------------------------
-- 施法失败
-------------------------------------------------------------------------------

function CastBarModule:OnSpellCastFailed()
    if not self.castBar then return end

    -- 显示失败效果
    self.castBar:SetStatusBarColor(1.0, 0.0, 0.0, 1)

    if self.castBarTimer and self.castBar.onUpdateScript then
        self.castBar:SetScript("OnUpdate", nil)
        self.castBar.onUpdateScript = nil
    end
end

-------------------------------------------------------------------------------
-- 施法延迟
-------------------------------------------------------------------------------

function CastBarModule:OnSpellCastDelayed(name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible)
    if not self.castBar then return end

    local duration = endTime - startTime
    self.castBar:SetMinMaxValues(0, duration)

    self.castStartTime = startTime / 1000
    self.castEndTime = endTime / 1000
    self.castDuration = duration / 1000
end

-------------------------------------------------------------------------------
-- 引导开始
-------------------------------------------------------------------------------

function CastBarModule:OnSpellCastChannelStart(name, text, texture, startTime, endTime, isTradeSkill, notInterruptible)
    if not self.castBar then return end

    local duration = endTime - startTime
    self.castBar:SetMinMaxValues(0, duration)
    self.castBar:SetValue(duration)  -- 引导从最大值开始递减

    -- 更新文字
    if self.castBarText then
        self.castBarText:SetText(text)
    end

    -- 更新图标
    if self.castBarIcon and texture then
        self.castBarIcon:SetTexture(texture)
    end

    -- 设置颜色
    if notInterruptible then
        self.castBar:SetStatusBarColor(0.8, 0.8, 0.8, 1)
    else
        self.castBar:SetStatusBarColor(0.0, 1.0, 0.0, 1)  -- 引导使用绿色
    end

    -- 记录时间
    self.castStartTime = startTime / 1000
    self.castEndTime = endTime / 1000
    self.castDuration = duration / 1000
    self.isChanneling = true

    if self.castBarTimer and not self.castBar.onUpdateScript then
        self.castBar:SetScript("OnUpdate", function()
            self:UpdateTimerChannel()
        end)
        self.castBar.onUpdateScript = true
    end
end

-------------------------------------------------------------------------------
-- 引导停止
-------------------------------------------------------------------------------

function CastBarModule:OnSpellCastChannelStop()
    if not self.castBar then return end

    if self.castBarTimer and self.castBar.onUpdateScript then
        self.castBar:SetScript("OnUpdate", nil)
        self.castBar.onUpdateScript = nil
    end

    self.castStartTime = nil
    self.castEndTime = nil
end

-------------------------------------------------------------------------------
-- 引导更新
-------------------------------------------------------------------------------

function CastBarModule:OnSpellCastChannelUpdate(name, text, texture, startTime, endTime, isTradeSkill, notInterruptible)
    if not self.castBar then return end

    local duration = endTime - startTime
    self.castBar:SetMinMaxValues(0, duration)

    self.castStartTime = startTime / 1000
    self.castEndTime = endTime / 1000
    self.castDuration = duration / 1000
end

-------------------------------------------------------------------------------
-- 目标切换
-------------------------------------------------------------------------------

function CastBarModule:OnTargetChanged()
    -- 检查新目标是否正在施法
    if UnitCastingInfo(self.unit) then
        local name, text, texture, startTime, endTime = UnitCastingInfo(self.unit)
        self:OnSpellCastStart(name, text, texture, startTime, endTime)
    elseif UnitChannelInfo(self.unit) then
        local name, text, texture, startTime, endTime = UnitChannelInfo(self.unit)
        self:OnSpellCastChannelStart(name, text, texture, startTime, endTime)
    else
        if self.castBar then
            self.castBar:Hide()
        end
    end
end

-------------------------------------------------------------------------------
-- 更新计时器（施法）
-------------------------------------------------------------------------------

function CastBarModule:UpdateTimer()
    if not self.castBarTimer then return end
    if not self.castStartTime then return end

    local currentTime = GetTime()
    local remaining = self.castEndTime - currentTime

    if remaining < 0 then
        remaining = 0
    end

    -- 更新计时器文字
    self.castBarTimer:SetText(string.format("%.1f", remaining))

    -- 更新状态条值（如果是我们创建的施法条）
    if self.elements.castBar and not self.castBar:IsProtected() then
        local elapsed = currentTime - self.castStartTime
        self.castBar:SetValue(elapsed)
    end

    -- 更新光效位置
    if self.castBarSpark and self.castBar.SetValue then
        local percent = elapsed / self.castDuration
        local sparkX = self.castBar:GetWidth() * percent
        self.castBarSpark:SetPoint("CENTER", self.castBar, "LEFT", sparkX, 0)
        self.castBarSpark:Show()
    end
end

-------------------------------------------------------------------------------
-- 更新计时器（引导）
-------------------------------------------------------------------------------

function CastBarModule:UpdateTimerChannel()
    if not self.castBarTimer then return end
    if not self.castStartTime then return end

    local currentTime = GetTime()
    local remaining = self.castEndTime - currentTime

    if remaining < 0 then
        remaining = 0
    end

    -- 更新计时器文字
    self.castBarTimer:SetText(string.format("%.1f", remaining))

    -- 更新状态条值（引导是递减的）
    if self.elements.castBar and not self.castBar:IsProtected() then
        self.castBar:SetValue(remaining)
    end

    -- 隐藏光效（引导不需要光效）
    if self.castBarSpark then
        self.castBarSpark:Hide()
    end
end

-------------------------------------------------------------------------------
-- 应用配置
-------------------------------------------------------------------------------

function CastBarModule:ApplyConfig(config)
    self.config = config or EUF.Database:GetModuleConfig(self.frameKey, self.moduleKey)

    -- 检查是否隐藏（优先级最高）
    local hidden = self:GetConfigValue("hidden", false)
    if hidden then
        self:HideFrame()
        return
    end

    -- 检查是否启用
    local enabled = self:GetConfigValue("enabled", true)
    if not enabled then
        self:Hide()
        return
    end

    -- 应用尺寸
    local width = self:GetConfigValue("width", 200)
    local height = self:GetConfigValue("height", 16)

    if self.castBar and not InCombatLockdown() then
        self.castBar:SetSize(width, height)
    end

    -- 应用材质
    self:ApplyTexture()

    -- 显示施法条
    self:Show()

    -- 注意：边框由 BorderModule 单独处理
    -- 不在这里调用 SetBackdrop 以避免 Taint
end

-------------------------------------------------------------------------------
-- 更新
-------------------------------------------------------------------------------

function CastBarModule:Update()
    -- 施法条由暴雪自动更新
    -- 我们只需要处理额外元素
end

-------------------------------------------------------------------------------
-- 刷新
-------------------------------------------------------------------------------

function CastBarModule:Refresh()
    self:ApplyConfig(self.config)
end

-------------------------------------------------------------------------------
-- 获取材质路径
-------------------------------------------------------------------------------

function CastBarModule:GetTexturePath(textureName)
    local textures = {
        Blizzard = "Interface\\TargetingFrame\\UI-StatusBar",
        Flat = "Interface\\Buttons\\WHITE8X8",
        BlizzardCast = "Interface\\CastingBar\\UI-CastingBar",
    }
    return textures[textureName] or textures.Blizzard
end

-------------------------------------------------------------------------------
-- 战斗结束处理
-------------------------------------------------------------------------------

function CastBarModule:OnCombatEnd()
    EUF.ModuleBase.OnCombatEnd(self)

    -- 应用待执行的尺寸变更
    if self.pendingSize and self.castBar then
        self.castBar:SetSize(self.pendingSize.width, self.pendingSize.height)
        self.pendingSize = nil
    end
end

-------------------------------------------------------------------------------
-- 显示/隐藏
-------------------------------------------------------------------------------

function CastBarModule:Show()
    if self.castBar and not InCombatLockdown() then
        self.castBar:SetAlpha(1)
        self.castBar:Show()
    end
    self.enabled = true
    self.hidden = false
end

function CastBarModule:Hide()
    if self.castBar and not InCombatLockdown() then
        self.castBar:Hide()
    end
    self.enabled = false
end

-- 完全隐藏施法条框体（隐藏功能）
function CastBarModule:HideFrame()
    if self.castBar then
        self.castBar:SetAlpha(0)
        if not InCombatLockdown() then
            self.castBar:Hide()
        end
    end
    self.enabled = false
    self.hidden = true
end

return CastBarModule