-- PortraitModule.lua
-- EnhancedUnitFrames 头像模块
-- 显示单位3D头像或职业图标
-- 注意：边框使用纹理方式，避免 Taint

local addonName, EUF = ...

local PortraitModule = {}
EUF.PortraitModule = PortraitModule

-- 继承模块基类
setmetatable(PortraitModule, {__index = EUF.ModuleBase})

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function PortraitModule:New(moduleKey, frameKey, unit)
    local obj = EUF.ModuleBase.New(self, moduleKey, frameKey, unit)
    obj.portraitFrame = nil
    obj.portraitTexture = nil
    obj.portrait3D = nil
    obj.borderTextures = {}
    obj.hidden = false
    return obj
end

-------------------------------------------------------------------------------
-- 创建UI元素
-------------------------------------------------------------------------------

function PortraitModule:CreateElements()
    -- 找到暴雪原生头像框架
    self:FindPortraitFrame()

    if not self.portraitFrame then
        EUF:Debug(string.format("PortraitModule: %s 无法找到头像框架", self.frameKey))
        return
    end

    self.elements.portraitFrame = self.portraitFrame
end

-------------------------------------------------------------------------------
-- 查找头像框架
-------------------------------------------------------------------------------

function PortraitModule:FindPortraitFrame()
    if self.frameKey == "player" then
        -- 玩家头像 - WoW 12.0 多种路径尝试
        -- 方法 1: 新结构路径
        if PlayerFrame and PlayerFrame.PlayerFrameContent then
            local content = PlayerFrame.PlayerFrameContent
            if content.PlayerFrameContentMain then
                local main = content.PlayerFrameContentMain
                -- 尝试多种可能的属性名
                self.portraitFrame = main.PortraitContainer or main.Portrait or main.PlayerPortrait
            end
        end

        -- 方法 2: 旧版全局变量
        if not self.portraitFrame then
            self.portraitFrame = _G.PlayerFramePortrait
        end

        -- 方法 3: 直接从 PlayerFrame 查找
        if not self.portraitFrame and PlayerFrame then
            self.portraitFrame = PlayerFrame.Portrait or PlayerFrame.portrait
        end

    elseif self.frameKey == "target" then
        -- 目标头像
        if TargetFrame and TargetFrame.TargetFrameContent then
            local content = TargetFrame.TargetFrameContent
            self.portraitFrame = content.PortraitContainer or content.UnitPortrait or content.Portrait
        end
        if not self.portraitFrame then
            self.portraitFrame = _G.TargetFramePortrait
        end

    elseif self.frameKey == "focus" then
        -- 焦点头像
        if FocusFrame and FocusFrame.FocusFrameContent then
            local content = FocusFrame.FocusFrameContent
            self.portraitFrame = content.PortraitContainer or content.UnitPortrait or content.Portrait
        end
        if not self.portraitFrame then
            self.portraitFrame = _G.FocusFramePortrait
        end

    elseif self.frameKey == "pet" then
        -- 宠物头像
        self.portraitFrame = _G.PetFramePortrait
        if not self.portraitFrame and PetFrame then
            self.portraitFrame = PetFrame.Portrait or PetFrame.portrait
        end
    end
end

-------------------------------------------------------------------------------
-- 应用配置
-------------------------------------------------------------------------------

function PortraitModule:ApplyConfig(config)
    -- 先设置配置
    self.config = config or EUF.Database:GetModuleConfig(self.frameKey, self.moduleKey)

    if not self.initialized then
        -- 如果未初始化，不做任何操作
        return
    end

    -- 检查是否隐藏（优先级最高）
    local hidden = self:GetConfigValue("hidden", false)
    if hidden then
        self:HideFrame()
        return
    end

    -- 应用显示样式
    local style = self:GetConfigValue("style", "3D")
    self:ApplyStyle(style)

    -- 根据启用状态显示或隐藏
    local enabled = self:GetConfigValue("enabled", true)
    if enabled then
        self:Show()
    else
        self:Hide()
    end

    -- 应用边框
    if self:GetConfigValue("borderEnabled", false) then
        -- 延迟创建边框
        C_Timer.After(0, function()
            self:CreateTextureBorder()
        end)
    else
        self:ClearBorder()
    end

    EUF:Debug(string.format("PortraitModule: %s 配置已应用 (enabled=%s, hidden=%s)", self.frameKey, tostring(enabled), tostring(hidden)))
end

-------------------------------------------------------------------------------
-- 创建纹理边框（避免 Taint）
-------------------------------------------------------------------------------

function PortraitModule:CreateTextureBorder()
    if not self.portraitFrame then return end

    -- 清除旧边框
    self:ClearBorder()

    -- 获取用于创建纹理的框架（必须是 Frame，不能是 Texture）
    local parentFrame = self.portraitFrame
    -- 如果 portraitFrame 是 Texture，则使用其父框架
    if parentFrame.GetObjectType and parentFrame:GetObjectType() == "Texture" then
        parentFrame = parentFrame:GetParent()
    end

    if not parentFrame or not parentFrame.CreateTexture then
        EUF:Debug("PortraitModule: 无法创建边框，父框架无效")
        return
    end

    local borderSize = self:GetConfigValue("borderSize", 2)
    local borderColor = self:GetConfigValue("borderColor", {r = 1, g = 1, b = 1, a = 1})

    local textures = {}

    -- 顶边
    local top = parentFrame:CreateTexture(nil, "OVERLAY")
    top:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    top:SetPoint("TOPLEFT", self.portraitFrame, "TOPLEFT", -borderSize, borderSize)
    top:SetPoint("TOPRIGHT", self.portraitFrame, "TOPRIGHT", borderSize, borderSize)
    top:SetHeight(borderSize)
    textures.top = top

    -- 底边
    local bottom = parentFrame:CreateTexture(nil, "OVERLAY")
    bottom:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    bottom:SetPoint("BOTTOMLEFT", self.portraitFrame, "BOTTOMLEFT", -borderSize, -borderSize)
    bottom:SetPoint("BOTTOMRIGHT", self.portraitFrame, "BOTTOMRIGHT", borderSize, -borderSize)
    bottom:SetHeight(borderSize)
    textures.bottom = bottom

    -- 左边
    local left = parentFrame:CreateTexture(nil, "OVERLAY")
    left:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    left:SetPoint("TOPLEFT", self.portraitFrame, "TOPLEFT", -borderSize, borderSize)
    left:SetPoint("BOTTOMLEFT", self.portraitFrame, "BOTTOMLEFT", -borderSize, -borderSize)
    left:SetWidth(borderSize)
    textures.left = left

    -- 右边
    local right = parentFrame:CreateTexture(nil, "OVERLAY")
    right:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    right:SetPoint("TOPRIGHT", self.portraitFrame, "TOPRIGHT", borderSize, borderSize)
    right:SetPoint("BOTTOMRIGHT", self.portraitFrame, "BOTTOMRIGHT", borderSize, -borderSize)
    right:SetWidth(borderSize)
    textures.right = right

    self.borderTextures = textures
end

-------------------------------------------------------------------------------
-- 清除边框
-------------------------------------------------------------------------------

function PortraitModule:ClearBorder()
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
-- 应用显示样式
-------------------------------------------------------------------------------

function PortraitModule:ApplyStyle(style)
    if not self.portraitFrame then return end

    if style == "3D" then
        -- 3D模型头像（暴雪默认）
        self:Setup3DPortrait()

    elseif style == "2D" then
        -- 2D静态图标
        self:Setup2DPortrait()

    elseif style == "class" then
        -- 职业图标
        self:SetupClassPortrait()
    end
end

-------------------------------------------------------------------------------
-- 3D头像设置
-------------------------------------------------------------------------------

function PortraitModule:Setup3DPortrait()
    -- 暴雪原生已经处理了3D头像
    if self.portraitFrame and self.portraitFrame:IsObjectType("Texture") then
        SetPortraitTexture(self.portraitFrame, self.unit)
    end
end

-------------------------------------------------------------------------------
-- 2D头像设置
-------------------------------------------------------------------------------

function PortraitModule:Setup2DPortrait()
    if not self.portraitFrame then return end

    if self.portraitFrame:IsObjectType("Texture") then
        SetPortraitTexture(self.portraitFrame, self.unit)
    end
end

-------------------------------------------------------------------------------
-- 职业图标设置
-------------------------------------------------------------------------------

function PortraitModule:SetupClassPortrait()
    if not self.portraitFrame then return end

    local guid = UnitGUID(self.unit)
    if not guid then return end

    local _, classToken = GetPlayerInfoByGUID(guid)
    if not classToken then
        -- NPC 使用默认头像
        self:Setup2DPortrait()
        return
    end

    local classIcon = GetClassIcon(classToken)
    if classIcon and self.portraitFrame:IsObjectType("Texture") then
        self.portraitFrame:SetTexture(classIcon)
    end
end

-------------------------------------------------------------------------------
-- 更新
-------------------------------------------------------------------------------

function PortraitModule:Update()
    if not self.initialized or not self.enabled then return end
    if not self.portraitFrame then return end

    local style = self:GetConfigValue("style", "3D")
    self:ApplyStyle(style)
end

-------------------------------------------------------------------------------
-- 刷新
-------------------------------------------------------------------------------

function PortraitModule:Refresh()
    self:Update()
end

-------------------------------------------------------------------------------
-- 获取职业图标路径
-------------------------------------------------------------------------------

function GetClassIcon(classToken)
    local classIcons = {
        WARRIOR = "Interface\\Icons\\classicon_warrior",
        PALADIN = "Interface\\Icons\\classicon_paladin",
        HUNTER = "Interface\\Icons\\classicon_hunter",
        ROGUE = "Interface\\Icons\\classicon_rogue",
        PRIEST = "Interface\\Icons\\classicon_priest",
        DEATHKNIGHT = "Interface\\Icons\\classicon_deathknight",
        SHAMAN = "Interface\\Icons\\classicon_shaman",
        MAGE = "Interface\\Icons\\classicon_mage",
        WARLOCK = "Interface\\Icons\\classicon_warlock",
        MONK = "Interface\\Icons\\classicon_monk",
        DRUID = "Interface\\Icons\\classicon_druid",
        DEMONHUNTER = "Interface\\Icons\\classicon_demonhunter",
        EVOKER = "Interface\\Icons\\classicon_evoker",
    }
    return classIcons[classToken]
end

-------------------------------------------------------------------------------
-- 显示/隐藏
-------------------------------------------------------------------------------

function PortraitModule:Show()
    -- 恢复头像显示
    if self.portraitFrame then
        self.portraitFrame:SetAlpha(1)
        self.portraitFrame:Show()
    end
    self.enabled = true
    self.hidden = false
    self:Update()
end

function PortraitModule:Hide()
    -- 隐藏头像（通过设置透明度，避免安全问题）
    if self.portraitFrame then
        self.portraitFrame:SetAlpha(0)
    end
    self.enabled = false
end

-- 完全隐藏头像框体（隐藏功能）
function PortraitModule:HideFrame()
    if self.portraitFrame then
        self.portraitFrame:SetAlpha(0)
        -- 如果是Frame类型，尝试Hide
        if self.portraitFrame.Hide then
            self.portraitFrame:Hide()
        end
    end
    -- 清除边框
    self:ClearBorder()
    self.enabled = false
    self.hidden = true
end

function PortraitModule:Disable()
    self:Hide()
end

-------------------------------------------------------------------------------
-- 战斗结束处理
-------------------------------------------------------------------------------

function PortraitModule:OnCombatEnd()
    EUF.ModuleBase.OnCombatEnd(self)
end

return PortraitModule