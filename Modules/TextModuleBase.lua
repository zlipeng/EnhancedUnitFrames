-- TextModuleBase.lua
-- EnhancedUnitFrames 文字模块基类
-- 所有文字模块的抽象基类

local addonName, EUF = ...

local TextModuleBase = {}
EUF.TextModuleBase = TextModuleBase

-- 继承模块基类
setmetatable(TextModuleBase, {__index = EUF.ModuleBase})

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function TextModuleBase:New(moduleKey, frameKey, unit)
    local obj = EUF.ModuleBase.New(self, moduleKey, frameKey, unit)
    obj.fontString = nil
    obj.originalFont = nil
    obj.originalFontSize = nil
    obj.originalFontFlags = nil
    obj.originalColor = {r = 1, g = 1, b = 1}
    obj.originalPoint = nil
    obj.originalJustifyH = nil
    return obj
end

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function TextModuleBase:Initialize(parent, config)
    if self.initialized then return end

    self.parent = parent
    self.config = config or EUF.Database:GetModuleConfig(self.frameKey, self.moduleKey)

    -- 查找文字对象
    self:FindFontString()

    if not self.fontString then
        EUF:Debug(string.format("TextModuleBase: %s.%s 文字对象未找到", self.frameKey, self.moduleKey))
        return
    end

    -- 保存原始状态
    self:SaveOriginalState()

    -- 检查是否启用
    if not self.config or not self.config.enabled then
        self.enabled = false
        return
    end

    -- 应用配置
    self:ApplyConfig(self.config)

    self.initialized = true
    self.enabled = true

    -- 初始更新
    self:Update()

    EUF:Debug(string.format("TextModuleBase: %s.%s 初始化完成", self.frameKey, self.moduleKey))
end

-------------------------------------------------------------------------------
-- 查找文字对象（子类实现）
-------------------------------------------------------------------------------

function TextModuleBase:FindFontString()
    -- 子类实现
end

-------------------------------------------------------------------------------
-- 保存原始状态
-------------------------------------------------------------------------------

function TextModuleBase:SaveOriginalState()
    if not self.fontString then return end

    self.originalFont, self.originalFontSize, self.originalFontFlags = self.fontString:GetFont()
    self.originalColor = {self.fontString:GetTextColor()}

    local point, relativeTo, relativePoint, x, y = self.fontString:GetPoint()
    self.originalPoint = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }

    self.originalJustifyH = self.fontString:GetJustifyH()
end

-------------------------------------------------------------------------------
-- 应用配置
-------------------------------------------------------------------------------

function TextModuleBase:ApplyConfig(config)
    if not self.fontString then return end

    self.config = config

    -- 检查是否启用
    if not config or not config.enabled then
        self:Hide()
        return
    end

    -- 应用字体
    if config.font and config.fontSize then
        self:SetFont(config.font, config.fontSize, config.fontFlags)
    end

    -- 应用位置
    if config.position then
        self:SetPosition(config.position, config.xOffset or 0, config.yOffset or 0)
    end

    -- 应用对齐
    if config.justifyH then
        self:SetJustifyH(config.justifyH)
    end

    -- 应用颜色
    self:ApplyColor()

    self.enabled = true
    self:Show()
end

-------------------------------------------------------------------------------
-- 字体设置
-------------------------------------------------------------------------------

function TextModuleBase:SetFont(fontName, fontSize, fontFlags)
    if not self.fontString then return end

    local fontPath = self:GetFontPath(fontName)
    self.fontString:SetFont(fontPath, fontSize, fontFlags or "")
end

function TextModuleBase:GetFontPath(name)
    local fonts = {
        ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
        ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
        ["Skurri"] = "Fonts\\SKURRI.TTF",
        ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
    }

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local path = LSM:Fetch("font", name, true)
        if path then return path end
    end

    return fonts[name] or fonts["Friz Quadrata TT"]
end

-------------------------------------------------------------------------------
-- 位置设置
-------------------------------------------------------------------------------

function TextModuleBase:SetPosition(point, xOffset, yOffset)
    if not self.fontString then return end

    xOffset = xOffset or 0
    yOffset = yOffset or 0

    self.fontString:ClearAllPoints()
    self.fontString:SetPoint(point, self.parent, point, xOffset, yOffset)
end

-------------------------------------------------------------------------------
-- 对齐设置
-------------------------------------------------------------------------------

function TextModuleBase:SetJustifyH(justify)
    if not self.fontString then return end
    self.fontString:SetJustifyH(justify)
end

-------------------------------------------------------------------------------
-- 颜色设置
-------------------------------------------------------------------------------

function TextModuleBase:SetColor(r, g, b, a)
    if not self.fontString then return end
    self.fontString:SetTextColor(r, g, b, a or 1)
end

function TextModuleBase:SetClassColor()
    if not self.fontString then return end
    local color = EUF.SecretSafe.SafeGetClassColor(self.unit)
    if color and color.r and color.g and color.b then
        self:SetColor(color.r, color.g, color.b)
    end
end

function TextModuleBase:SetCustomColor(color)
    if not self.fontString or not color then return end
    self:SetColor(color.r, color.g, color.b, color.a)
end

function TextModuleBase:ApplyColor()
    if not self.config then return end

    if self.config.useClassColor then
        self:SetClassColor()
    elseif self.config.color then
        self:SetCustomColor(self.config.color)
    else
        -- 恢复原始颜色
        self:SetColor(self.originalColor.r, self.originalColor.g, self.originalColor.b)
    end
end

-------------------------------------------------------------------------------
-- 更新（子类实现）
-------------------------------------------------------------------------------

function TextModuleBase:Update()
    -- 子类实现
end

-------------------------------------------------------------------------------
-- 刷新
-------------------------------------------------------------------------------

function TextModuleBase:Refresh()
    self:ApplyColor()
    self:Update()
end

-------------------------------------------------------------------------------
-- 显示/隐藏
-------------------------------------------------------------------------------

function TextModuleBase:Show()
    if self.fontString then
        self.fontString:Show()
    end
    self.enabled = true
end

function TextModuleBase:Hide()
    if self.fontString then
        self.fontString:Hide()
    end
    self.enabled = false
end

-------------------------------------------------------------------------------
-- 恢复原始状态
-------------------------------------------------------------------------------

function TextModuleBase:RestoreOriginal()
    if not self.fontString then return end

    if self.originalFont then
        self.fontString:SetFont(self.originalFont, self.originalFontSize, self.originalFontFlags)
    end

    if self.originalPoint then
        self.fontString:ClearAllPoints()
        self.fontString:SetPoint(
            self.originalPoint.point,
            self.originalPoint.relativeTo,
            self.originalPoint.relativePoint,
            self.originalPoint.x,
            self.originalPoint.y
        )
    end

    if self.originalJustifyH then
        self.fontString:SetJustifyH(self.originalJustifyH)
    end

    self:SetColor(self.originalColor.r, self.originalColor.g, self.originalColor.b)
end

return TextModuleBase