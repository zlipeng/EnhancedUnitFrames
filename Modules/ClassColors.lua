-- ClassColors.lua
-- EnhancedUnitFrames 职业染色模块
-- 根据单位职业自动着色生命条和边框
-- 12.0 合规：使用 GUID 路径获取职业色

local addonName, EUF = ...

local ClassColors = {}
EUF.ClassColors = ClassColors

-- 模块状态
ClassColors.initialized = false
ClassColors.db = nil
ClassColors.hooksRegistered = false

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function ClassColors:Initialize(db)
    if self.initialized then return end

    self.db = db and db.classColors
    if not self.db then
        EUF:Debug("ClassColors: 数据库配置不存在")
        return
    end

    -- 注册 Hook
    self:RegisterHooks()

    -- 初始应用颜色
    self:Refresh()

    self.initialized = true
    EUF:Debug("ClassColors: 模块初始化完成")
end

-------------------------------------------------------------------------------
-- Hook 注册
-------------------------------------------------------------------------------

function ClassColors:RegisterHooks()
    if self.hooksRegistered then return end

    -- WoW 12.0: Hook PlayerFrame_UpdateStatus (如果存在)
    if PlayerFrame_UpdateStatus then
        hooksecurefunc("PlayerFrame_UpdateStatus", function()
            if EUF.enabled and self.db and self.db.enabled then
                self:ApplyToPlayerFrame()
            end
        end)
    end

    -- WoW 12.0: Hook TargetFrameHealthBarMixin.OnValueChanged
    if TargetFrameHealthBarMixin then
        hooksecurefunc(TargetFrameHealthBarMixin, "OnValueChanged", function(bar)
            if not EUF.enabled or not self.db or not self.db.enabled then return end

            -- 检测是哪个框体
            local parent = bar
            for _ = 1, 8 do
                if not parent then break end
                local name = parent.GetName and parent:GetName()
                if name == "PlayerFrame" then
                    self:ApplyToPlayerFrame()
                    return
                elseif name == "TargetFrame" then
                    if UnitExists("target") then
                        self:ApplyToTargetFrame()
                    end
                    return
                elseif name == "FocusFrame" then
                    if UnitExists("focus") then
                        self:ApplyToFocusFrame()
                    end
                    return
                end
                parent = parent.GetParent and parent:GetParent() or nil
            end
        end)
    end

    -- 备用：监听事件来更新颜色
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    eventFrame:RegisterEvent("UNIT_FACTION")
    eventFrame:RegisterEvent("UNIT_CONNECTION")

    eventFrame:SetScript("OnEvent", function(frame, event, unit)
        if not EUF.enabled or not self.db or not self.db.enabled then return end

        if event == "PLAYER_TARGET_CHANGED" then
            self:ApplyToTargetFrame()
        elseif event == "PLAYER_FOCUS_CHANGED" then
            self:ApplyToFocusFrame()
        elseif event == "UNIT_FACTION" or event == "UNIT_CONNECTION" then
            if unit == "player" then
                self:ApplyToPlayerFrame()
            elseif unit == "target" then
                self:ApplyToTargetFrame()
            elseif unit == "focus" then
                self:ApplyToFocusFrame()
            end
        end
    end)

    self.hooksRegistered = true
    EUF:Debug("ClassColors: Hooks 已注册")
end

-------------------------------------------------------------------------------
-- 核心功能
-------------------------------------------------------------------------------

-- 判断单位是否应该染色
function ClassColors:ShouldColorUnit(unit)
    if not unit or not UnitExists(unit) then
        return false
    end

    if not self.db or not self.db.enabled then
        return false
    end

    return true
end

-- 获取单位应显示的颜色
-- 返回: ColorMixin 对象
function ClassColors:GetUnitColor(unit)
    if not unit or not UnitExists(unit) then
        return CreateColor(1, 1, 1, 1)
    end

    -- 判断是否为玩家单位
    if UnitIsPlayer(unit) then
        -- 使用 GUID 路径获取职业色（12.0 安全）
        local color = EUF.SecretSafe.SafeGetClassColor(unit)
        if color then
            return color
        end
    else
        -- NPC 单位：使用反应色
        if self.db and self.db.colorNPCByReaction then
            local color = EUF.SecretSafe.SafeGetReactionColor(unit)
            if color then
                return color
            end
        end

        -- 使用自定义颜色
        if self.db and self.db.customColors then
            local reaction = UnitReaction(unit, "player")
            if reaction then
                if reaction <= 2 then
                    -- 敌对
                    local c = self.db.customColors.hostile
                    if c then return CreateColor(c.r, c.g, c.b, 1) end
                elseif reaction == 4 then
                    -- 中立
                    local c = self.db.customColors.neutral
                    if c then return CreateColor(c.r, c.g, c.b, 1) end
                elseif reaction >= 5 then
                    -- 友好
                    local c = self.db.customColors.friendly
                    if c then return CreateColor(c.r, c.g, c.b, 1) end
                end
            end
        end
    end

    return CreateColor(1, 1, 1, 1)
end

-- 应用颜色到生命条
function ClassColors:ApplyToHealthBar(healthBar, unit)
    if not healthBar then return end

    local color = self:GetUnitColor(unit)
    if color then
        -- WoW 12.0: SetStatusBarColor(r, g, b, a) - 使用4参数形式
        healthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
    end

    -- 如果启用背景染色
    if self.db and self.db.colorBackground and color then
        local bg = healthBar.bg or healthBar.Background
        if bg then
            bg:SetVertexColor(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.5)
        end
    end
end

-- 应用颜色到边框
function ClassColors:ApplyToBorder(frame, color)
    if not frame then return end

    if not self.db or not self.db.colorBorder then
        return
    end

    if not color or not color.r then return end

    -- 查找边框纹理
    local border = frame.border or frame.Border or frame.FrameBorder
    if border then
        border:SetVertexColor(color.r, color.g, color.b, 1)
    end

    -- 尝试查找其他可能的边框元素
    if frame.TargetFrameBorder then
        frame.TargetFrameBorder:SetVertexColor(color.r, color.g, color.b, 1)
    end
end

-------------------------------------------------------------------------------
-- 框体应用
-------------------------------------------------------------------------------

-- 应用到玩家框体
function ClassColors:ApplyToPlayerFrame()
    if not self:ShouldColorUnit("player") then return end

    -- WoW 12.0: 查找正确的生命条路径（包含 HealthBarsContainer）
    local healthBar = nil

    -- 方法 1: 新结构路径
    if PlayerFrame and PlayerFrame.PlayerFrameContent then
        local content = PlayerFrame.PlayerFrameContent
        if content.PlayerFrameContentMain then
            local main = content.PlayerFrameContentMain
            if main.HealthBarsContainer then
                healthBar = main.HealthBarsContainer.HealthBar
            end
        end
    end

    -- 方法 2: 旧版全局变量备用
    if not healthBar then
        healthBar = _G.PlayerFrameHealthBar
    end

    if healthBar then
        self:ApplyToHealthBar(healthBar, "player")
    end

    if self.db.colorBorder then
        local color = self:GetUnitColor("player")
        self:ApplyToBorder(PlayerFrame, color)
    end
end

-- 应用到目标框体
function ClassColors:ApplyToTargetFrame()
    if not self:ShouldColorUnit("target") then return end

    local healthBar = nil

    -- 方法 1: 新结构路径（包含 HealthBarsContainer）
    if TargetFrame and TargetFrame.TargetFrameContent then
        local content = TargetFrame.TargetFrameContent
        if content.TargetFrameContentMain then
            local main = content.TargetFrameContentMain
            if main.HealthBarsContainer then
                healthBar = main.HealthBarsContainer.HealthBar
            end
        end
    end

    -- 方法 2: 旧版全局变量备用
    if not healthBar then
        healthBar = _G.TargetFrameHealthBar
    end

    if healthBar then
        self:ApplyToHealthBar(healthBar, "target")
    end

    if self.db.colorBorder then
        local color = self:GetUnitColor("target")
        self:ApplyToBorder(TargetFrame, color)
    end
end

-- 应用到焦点框体
function ClassColors:ApplyToFocusFrame()
    if not FocusFrame then return end
    if not self:ShouldColorUnit("focus") then return end

    local healthBar = nil

    -- 方法 1: 新结构路径（包含 HealthBarsContainer）
    if FocusFrame.FocusFrameContent then
        local content = FocusFrame.FocusFrameContent
        if content.FocusFrameContentMain then
            local main = content.FocusFrameContentMain
            if main.HealthBarsContainer then
                healthBar = main.HealthBarsContainer.HealthBar
            end
        end
    end

    -- 方法 2: 旧版全局变量备用
    if not healthBar then
        healthBar = _G.FocusFrameHealthBar
    end

    if healthBar then
        self:ApplyToHealthBar(healthBar, "focus")
    end

    if self.db.colorBorder then
        local color = self:GetUnitColor("focus")
        self:ApplyToBorder(FocusFrame, color)
    end
end

-------------------------------------------------------------------------------
-- 事件处理
-------------------------------------------------------------------------------

function ClassColors:OnTargetChanged()
    if not self.initialized then return end
    self:ApplyToTargetFrame()
end

function ClassColors:OnFocusChanged()
    if not self.initialized then return end
    self:ApplyToFocusFrame()
end

function ClassColors:OnUnitClassificationChanged(unit)
    if not self.initialized then return end

    if unit == "player" then
        self:ApplyToPlayerFrame()
    elseif unit == "target" then
        self:ApplyToTargetFrame()
    elseif unit == "focus" then
        self:ApplyToFocusFrame()
    end
end

-------------------------------------------------------------------------------
-- 刷新
-------------------------------------------------------------------------------

-- 刷新所有框体颜色
function ClassColors:Refresh()
    if not self.initialized then return end

    self:ApplyToPlayerFrame()

    if UnitExists("target") then
        self:ApplyToTargetFrame()
    end

    if FocusFrame and UnitExists("focus") then
        self:ApplyToFocusFrame()
    end
end

return ClassColors