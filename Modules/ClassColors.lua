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

    -- Hook PlayerFrame_Update
    hooksecurefunc("PlayerFrame_Update", function()
        if EUF.enabled and self.db and self.db.enabled then
            self:ApplyToPlayerFrame()
        end
    end)

    -- Hook TargetFrame_Update
    hooksecurefunc("TargetFrame_Update", function()
        if EUF.enabled and self.db and self.db.enabled then
            self:ApplyToTargetFrame()
        end
    end)

    -- Hook FocusFrame_Update (如果存在)
    if FocusFrame then
        hooksecurefunc("FocusFrame_Update", function()
            if EUF.enabled and self.db and self.db.enabled then
                self:ApplyToFocusFrame()
            end
        end)
    end

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
-- 返回: r, g, b, colorStr
function ClassColors:GetUnitColor(unit)
    if not unit or not UnitExists(unit) then
        return 1, 1, 1, "ffffffff"
    end

    -- 判断是否为玩家单位
    if UnitIsPlayer(unit) then
        -- 使用 GUID 路径获取职业色（12.0 安全）
        return EUF.SecretSafe.SafeGetClassColor(unit)
    else
        -- NPC 单位：使用反应色
        if self.db and self.db.colorNPCByReaction then
            local r, g, b = EUF.SecretSafe.SafeGetReactionColor(unit)
            return r, g, b, "ffffffff"
        end

        -- 使用自定义颜色
        if self.db and self.db.customColors then
            local reaction = UnitReaction(unit, "player")
            if reaction then
                if reaction <= 2 then
                    -- 敌对
                    local c = self.db.customColors.hostile
                    if c then return c.r, c.g, c.b, "ffffffff" end
                elseif reaction == 4 then
                    -- 中立
                    local c = self.db.customColors.neutral
                    if c then return c.r, c.g, c.b, "ffffffff" end
                elseif reaction >= 5 then
                    -- 友好
                    local c = self.db.customColors.friendly
                    if c then return c.r, c.g, c.b, "ffffffff" end
                end
            end
        end
    end

    return 1, 1, 1, "ffffffff"
end

-- 应用颜色到生命条
function ClassColors:ApplyToHealthBar(healthBar, unit)
    if not healthBar then return end

    local r, g, b = self:GetUnitColor(unit)

    -- 12.0 安全操作：SetStatusBarColor 是允许的
    -- 因为这只是修改视觉属性，不涉及数据处理
    healthBar:SetStatusBarColor(r, g, b)

    -- 如果启用背景染色
    if self.db and self.db.colorBackground then
        local bg = healthBar.bg or healthBar.Background
        if bg then
            bg:SetVertexColor(r * 0.3, g * 0.3, b * 0.3, 0.5)
        end
    end
end

-- 应用颜色到边框
function ClassColors:ApplyToBorder(frame, r, g, b)
    if not frame then return end

    if not self.db or not self.db.colorBorder then
        return
    end

    -- 查找边框纹理
    local border = frame.border or frame.Border or frame.FrameBorder
    if border then
        border:SetVertexColor(r, g, b)
    end

    -- 尝试查找其他可能的边框元素
    if frame.TargetFrameBorder then
        frame.TargetFrameBorder:SetVertexColor(r, g, b)
    end
end

-------------------------------------------------------------------------------
-- 框体应用
-------------------------------------------------------------------------------

-- 应用到玩家框体
function ClassColors:ApplyToPlayerFrame()
    if not self:ShouldColorUnit("player") then return end

    self:ApplyToHealthBar(PlayerFrameHealthBar, "player")

    if self.db.colorBorder then
        local r, g, b = self:GetUnitColor("player")
        self:ApplyToBorder(PlayerFrame, r, g, b)
    end
end

-- 应用到目标框体
function ClassColors:ApplyToTargetFrame()
    if not self:ShouldColorUnit("target") then return end

    self:ApplyToHealthBar(TargetFrameHealthBar, "target")

    if self.db.colorBorder then
        local r, g, b = self:GetUnitColor("target")
        self:ApplyToBorder(TargetFrame, r, g, b)
    end
end

-- 应用到焦点框体
function ClassColors:ApplyToFocusFrame()
    if not FocusFrame then return end
    if not self:ShouldColorUnit("focus") then return end

    self:ApplyToHealthBar(FocusFrameHealthBar, "focus")

    if self.db.colorBorder then
        local r, g, b = self:GetUnitColor("focus")
        self:ApplyToBorder(FocusFrame, r, g, b)
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