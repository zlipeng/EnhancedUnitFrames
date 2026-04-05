-- Textures.lua
-- EnhancedUnitFrames 材质管理模块
-- 支持自定义生命条、法力条、边框等材质
-- 12.0 合规：纯视觉修改，不涉及数据处理

local addonName, EUF = ...

local Textures = {}
EUF.Textures = Textures

-- 内置材质路径
Textures.BUILTIN_TEXTURES = {
    ["Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
    ["Flat"] = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\statusbar_flat.tga",
    ["Gradient"] = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\statusbar_gradient.tga",
}

-- 边框样式定义
Textures.BORDER_STYLES = {
    ["None"] = { name = "无", edgeFile = nil, edgeSize = 0 },
    ["Rounded"] = { name = "圆角", edgeFile = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\border_rounded.tga", edgeSize = 12 },
    ["Square"] = { name = "方形", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 },
    ["Blizzard"] = { name = "暴雪默认", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 },
}

-- 模块状态
Textures.initialized = false
Textures.db = nil
Textures.sharedMediaLoaded = false

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function Textures:Initialize(db)
    if self.initialized then return end

    self.db = db and db.textures
    if not self.db then
        EUF:Debug("Textures: 数据库配置不存在")
        return
    end

    -- 尝试加载 LibSharedMedia
    self:LoadSharedMedia()

    -- 应用当前设置
    self:ApplyAllSettings()

    self.initialized = true
    EUF:Debug("Textures: 模块初始化完成")
end

-------------------------------------------------------------------------------
-- LibSharedMedia 集成
-------------------------------------------------------------------------------

function Textures:LoadSharedMedia()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not LSM then
        EUF:Debug("Textures: LibSharedMedia-3.0 未安装")
        return
    end

    -- 加载外部材质列表
    local statusBars = LSM:List("statusbar")
    if statusBars then
        for _, name in ipairs(statusBars) do
            local path = LSM:Fetch("statusbar", name, true)
            if path and path ~= "" then
                self.BUILTIN_TEXTURES[name] = path
            end
        end
    end

    self.sharedMediaLoaded = true
    EUF:Debug("Textures: LibSharedMedia 材质已加载")
end

-------------------------------------------------------------------------------
-- 核心功能
-------------------------------------------------------------------------------

-- 获取材质路径
function Textures:GetTexturePath(textureName)
    if not textureName or textureName == "" then
        return self.BUILTIN_TEXTURES["Blizzard"]
    end

    return self.BUILTIN_TEXTURES[textureName] or self.BUILTIN_TEXTURES["Blizzard"]
end

-- 应用材质到状态条
function Textures:ApplyToStatusBar(statusBar, textureName)
    if not statusBar then return end

    local texturePath = self:GetTexturePath(textureName)

    -- SetStatusBarTexture 是纯视觉操作，12.0 允许
    statusBar:SetStatusBarTexture(texturePath)
end

-- 应用材质到框体背景
function Textures:ApplyToFrameBackground(frame, textureName, alpha)
    if not frame then return end
    alpha = alpha or 1.0

    -- 创建或获取背景纹理
    local bg = frame.enhancedBG
    if not bg then
        bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(frame)
        frame.enhancedBG = bg
    end

    if textureName and textureName ~= "None" then
        local texturePath = self:GetTexturePath(textureName)
        bg:SetTexture(texturePath)
        bg:SetAlpha(alpha)
        bg:Show()
    else
        bg:Hide()
    end
end

-- 应用边框到框体
-- 12.0 要求使用 BackdropTemplate
function Textures:ApplyBorder(frame, borderStyle, r, g, b, a)
    if not frame then return end

    -- 移除旧边框
    if frame.enhancedBorder then
        frame.enhancedBorder:Hide()
        frame.enhancedBorder = nil
    end

    -- 如果是无边框或样式不存在
    if not borderStyle or borderStyle == "None" then
        return
    end

    local styleData = self.BORDER_STYLES[borderStyle]
    if not styleData or not styleData.edgeFile then
        return
    end

    -- 创建新边框（使用 BackdropTemplate，12.0 推荐）
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetAllPoints(frame)

    border:SetBackdrop({
        edgeFile = styleData.edgeFile,
        edgeSize = styleData.edgeSize,
    })

    -- 设置边框颜色
    border:SetBackdropBorderColor(r or 1, g or 1, b or 1, a or 1)

    frame.enhancedBorder = border
end

-- 应用所有材质设置
function Textures:ApplyAllSettings()
    if not self.db then return end

    local healthTexture = self.db.healthBar or "Blizzard"
    local manaTexture = self.db.manaBar or healthTexture
    local borderStyle = self.db.border or "None"
    local borderColor = self.db.borderColor or { r = 1, g = 1, b = 1, a = 1 }

    -- 应用到玩家框体
    self:ApplyToStatusBar(PlayerFrameHealthBar, healthTexture)
    self:ApplyToStatusBar(PlayerFrameManaBar, manaTexture)
    self:ApplyBorder(PlayerFrame, borderStyle, borderColor.r, borderColor.g, borderColor.b, borderColor.a)

    -- 应用到目标框体
    self:ApplyToStatusBar(TargetFrameHealthBar, healthTexture)
    self:ApplyToStatusBar(TargetFrameManaBar, manaTexture)
    self:ApplyBorder(TargetFrame, borderStyle, borderColor.r, borderColor.g, borderColor.b, borderColor.a)

    -- 应用到焦点框体（如果存在）
    if FocusFrame then
        self:ApplyToStatusBar(FocusFrameHealthBar, healthTexture)
        self:ApplyToStatusBar(FocusFrameManaBar, manaTexture)
        self:ApplyBorder(FocusFrame, borderStyle, borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    end

    EUF:Debug("Textures: 所有材质设置已应用")
end

-- 获取材质列表（用于下拉菜单）
function Textures:GetTextureList()
    local list = {}
    for name, _ in pairs(self.BUILTIN_TEXTURES) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

-- 获取边框样式列表
function Textures:GetBorderStyleList()
    local list = {}
    for style, data in pairs(self.BORDER_STYLES) do
        table.insert(list, {
            value = style,
            text = data.name,
        })
    end
    table.sort(list, function(a, b) return a.text < b.text end)
    return list
end

-------------------------------------------------------------------------------
-- 配置更新
-------------------------------------------------------------------------------

-- 设置生命条材质
function Textures:SetHealthBarTexture(textureName)
    if self.db then
        self.db.healthBar = textureName
    end

    self:ApplyToStatusBar(PlayerFrameHealthBar, textureName)
    self:ApplyToStatusBar(TargetFrameHealthBar, textureName)

    if FocusFrame then
        self:ApplyToStatusBar(FocusFrameHealthBar, textureName)
    end
end

-- 设置法力条材质
function Textures:SetManaBarTexture(textureName)
    if self.db then
        self.db.manaBar = textureName
    end

    self:ApplyToStatusBar(PlayerFrameManaBar, textureName)
    self:ApplyToStatusBar(TargetFrameManaBar, textureName)

    if FocusFrame then
        self:ApplyToStatusBar(FocusFrameManaBar, textureName)
    end
end

-- 设置边框样式
function Textures:SetBorderStyle(style, r, g, b, a)
    if self.db then
        self.db.border = style
        if r and g and b then
            self.db.borderColor = { r = r, g = g, b = b, a = a or 1 }
        end
    end

    r = r or 1
    g = g or 1
    b = b or 1
    a = a or 1

    self:ApplyBorder(PlayerFrame, style, r, g, b, a)
    self:ApplyBorder(TargetFrame, style, r, g, b, a)

    if FocusFrame then
        self:ApplyBorder(FocusFrame, style, r, g, b, a)
    end
end

-- 刷新材质设置
function Textures:Refresh()
    self:ApplyAllSettings()
end

return Textures