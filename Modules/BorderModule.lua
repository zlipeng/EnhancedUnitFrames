-- BorderModule.lua
-- EnhancedUnitFrames 边框模块
-- 使用纹理覆盖方式添加边框，避免直接修改暴雪安全框架

local addonName, EUF = ...

local BorderModule = {}
EUF.BorderModule = BorderModule

-- 继承模块基类
setmetatable(BorderModule, {__index = EUF.ModuleBase})

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function BorderModule:New(moduleKey, frameKey, unit)
    local obj = EUF.ModuleBase.New(self, moduleKey, frameKey, unit)
    obj.borderTextures = {}
    return obj
end

-------------------------------------------------------------------------------
-- 创建UI元素
-------------------------------------------------------------------------------

function BorderModule:CreateElements()
    -- 不在初始化时创建边框，等待 ApplyConfig
    -- 这样可以避免在错误的时机修改框架
end

-------------------------------------------------------------------------------
-- 应用配置
-------------------------------------------------------------------------------

function BorderModule:ApplyConfig(config)
    self.config = config or EUF.Database:GetModuleConfig(self.frameKey, self.moduleKey)

    -- 应用边框样式
    if self.config and self.config.enabled then
        -- 延迟到下一帧创建边框，避免在事件处理中修改框架
        C_Timer.After(0, function()
            self:ApplyBorderStyle()
        end)
    else
        self:ClearBorder()
    end
end

-------------------------------------------------------------------------------
-- 应用边框样式
-------------------------------------------------------------------------------

function BorderModule:ApplyBorderStyle()
    -- 如果没有父框架，跳过
    if not self.parent then return end

    -- 清除旧边框
    self:ClearBorder()

    local borderEnabled = self:GetConfigValue("enabled", false)

    if not borderEnabled then
        return
    end

    local borderSize = self:GetConfigValue("size", 2)
    local borderColor = self:GetConfigValue("color", {r = 1, g = 1, b = 1, a = 1})

    -- 使用纹理覆盖方式创建边框，而不是 Backdrop
    -- 这样可以避免 Taint 问题
    self:CreateTextureBorder(borderSize, borderColor)
end

-------------------------------------------------------------------------------
-- 使用纹理创建边框（避免 Taint）
-------------------------------------------------------------------------------

function BorderModule:CreateTextureBorder(size, color)
    if not self.parent then return end

    -- 获取用于创建纹理的框架（必须是 Frame，不能是 Texture）
    local parentFrame = self.parent
    if parentFrame.GetObjectType and parentFrame:GetObjectType() == "Texture" then
        parentFrame = parentFrame:GetParent()
    end

    if not parentFrame or not parentFrame.CreateTexture then
        EUF:Debug("BorderModule: 无法创建边框，父框架无效")
        return
    end

    -- 获取父框架尺寸
    local width = parentFrame:GetWidth()
    local height = parentFrame:GetHeight()

    if not width or not height then return end

    -- 清除旧纹理
    self:ClearBorder()

    -- 创建四个边的纹理
    local textures = {}

    -- 顶边
    local top = parentFrame:CreateTexture(nil, "OVERLAY")
    top:SetColorTexture(color.r, color.g, color.b, color.a or 1)
    top:SetPoint("TOPLEFT", self.parent, "TOPLEFT", -size, size)
    top:SetPoint("TOPRIGHT", self.parent, "TOPRIGHT", size, size)
    top:SetHeight(size)
    textures.top = top

    -- 底边
    local bottom = parentFrame:CreateTexture(nil, "OVERLAY")
    bottom:SetColorTexture(color.r, color.g, color.b, color.a or 1)
    bottom:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", -size, -size)
    bottom:SetPoint("BOTTOMRIGHT", self.parent, "BOTTOMRIGHT", size, -size)
    bottom:SetHeight(size)
    textures.bottom = bottom

    -- 左边
    local left = parentFrame:CreateTexture(nil, "OVERLAY")
    left:SetColorTexture(color.r, color.g, color.b, color.a or 1)
    left:SetPoint("TOPLEFT", self.parent, "TOPLEFT", -size, size)
    left:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", -size, -size)
    left:SetWidth(size)
    textures.left = left

    -- 右边
    local right = parentFrame:CreateTexture(nil, "OVERLAY")
    right:SetColorTexture(color.r, color.g, color.b, color.a or 1)
    right:SetPoint("TOPRIGHT", self.parent, "TOPRIGHT", size, size)
    right:SetPoint("BOTTOMRIGHT", self.parent, "BOTTOMRIGHT", size, -size)
    right:SetWidth(size)
    textures.right = right

    self.borderTextures = textures

    EUF:Debug(string.format("BorderModule: %s 边框已创建", self.frameKey))
end

-------------------------------------------------------------------------------
-- 清除边框
-------------------------------------------------------------------------------

function BorderModule:ClearBorder()
    if self.borderTextures then
        for _, texture in pairs(self.borderTextures) do
            if texture then
                texture:Hide()
                texture:SetParent(nil)
            end
        end
        self.borderTextures = {}
    end
end

-------------------------------------------------------------------------------
-- 更新
-------------------------------------------------------------------------------

function BorderModule:Update()
    -- 边框不需要频繁更新
end

-------------------------------------------------------------------------------
-- 刷新
-------------------------------------------------------------------------------

function BorderModule:Refresh()
    self:ApplyBorderStyle()
end

-------------------------------------------------------------------------------
-- 设置边框颜色
-------------------------------------------------------------------------------

function BorderModule:SetColor(r, g, b, a)
    if not self.config then return end

    self.config.color = {r = r, g = g, b = b, a = a or 1}

    -- 更新现有边框纹理颜色
    if self.borderTextures then
        for _, texture in pairs(self.borderTextures) do
            if texture then
                texture:SetColorTexture(r, g, b, a or 1)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- 使用职业色设置边框颜色
-------------------------------------------------------------------------------

function BorderModule:SetClassColor()
    local unit = self.unit
    if not unit then return end

    local color = EUF.SecretSafe.SafeGetClassColor(unit)
    if color and color.r and color.g and color.b then
        self:SetColor(color.r, color.g, color.b, 1)
    end
end

-------------------------------------------------------------------------------
-- 使用反应色设置边框颜色
-------------------------------------------------------------------------------

function BorderModule:SetReactionColor()
    local unit = self.unit
    if not unit then return end

    local color = EUF.SecretSafe.SafeGetReactionColor(unit)
    if color and color.r and color.g and color.b then
        self:SetColor(color.r, color.g, color.b, 1)
    end
end

-------------------------------------------------------------------------------
-- 设置边框启用状态
-------------------------------------------------------------------------------

function BorderModule:SetEnabled(enabled)
    if not self.config then return end

    self.config.enabled = enabled

    if enabled then
        self:ApplyBorderStyle()
    else
        self:ClearBorder()
    end
end

-------------------------------------------------------------------------------
-- 战斗结束处理
-------------------------------------------------------------------------------

function BorderModule:OnCombatEnd()
    EUF.ModuleBase.OnCombatEnd(self)
    -- 战斗结束后不需要特殊处理
end

-------------------------------------------------------------------------------
-- 显示/隐藏
-------------------------------------------------------------------------------

function BorderModule:Show()
    if self.borderTextures then
        for _, texture in pairs(self.borderTextures) do
            if texture then
                texture:Show()
            end
        end
    end
    self.enabled = true
end

function BorderModule:Hide()
    if self.borderTextures then
        for _, texture in pairs(self.borderTextures) do
            if texture then
                texture:Hide()
            end
        end
    end
    self.enabled = false
end

return BorderModule