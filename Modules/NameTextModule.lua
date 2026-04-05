-- NameTextModule.lua
-- EnhancedUnitFrames 名称文字模块
-- 显示单位名称

local addonName, EUF = ...

local NameTextModule = {}
EUF.NameTextModule = NameTextModule

-- 继承文字模块基类
setmetatable(NameTextModule, {__index = EUF.TextModuleBase})

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function NameTextModule:New(moduleKey, frameKey, unit)
    local obj = EUF.TextModuleBase.New(self, moduleKey, frameKey, unit)
    return obj
end

-------------------------------------------------------------------------------
-- 查找文字对象
-------------------------------------------------------------------------------

function NameTextModule:FindFontString()
    if self.frameKey == "player" then
        self.fontString = _G.PlayerName
        if not self.fontString and PlayerFrame then
            -- 尝试新结构
            if PlayerFrame.PlayerFrameContent then
                local content = PlayerFrame.PlayerFrameContent
                if content.PlayerFrameContentMain then
                    self.fontString = content.PlayerFrameContentMain.Name
                end
            end
        end

    elseif self.frameKey == "target" then
        self.fontString = _G.TargetFrameTextureFrameName
        if not self.fontString and TargetFrame then
            if TargetFrame.TargetFrameContent then
                self.fontString = TargetFrame.TargetFrameContent.Name
            end
        end

    elseif self.frameKey == "focus" then
        self.fontString = _G.FocusFrameTextureFrameName
        if not self.fontString and FocusFrame then
            if FocusFrame.FocusFrameContent then
                self.fontString = FocusFrame.FocusFrameContent.Name
            end
        end

    elseif self.frameKey == "pet" then
        self.fontString = _G.PetName

    elseif self.frameKey == "targettarget" then
        self.fontString = _G.TargetFrameToTTextureFrameName
    end
end

-------------------------------------------------------------------------------
-- 更新
-------------------------------------------------------------------------------

function NameTextModule:Update()
    if not self.initialized or not self.enabled then return end
    if not self.fontString then return end

    -- 名称由暴雪自动更新，这里只处理样式
    -- 如果需要截断或格式化名称，可以在这里处理
end

-------------------------------------------------------------------------------
-- 设置名称（可选）
-------------------------------------------------------------------------------

function NameTextModule:SetText(text)
    if not self.fontString then return end
    self.fontString:SetText(text)
end

-------------------------------------------------------------------------------
-- 截断名称
-------------------------------------------------------------------------------

function NameTextModule:TruncateName(maxWidth)
    if not self.fontString then return end

    local name = UnitName(self.unit)
    if not name then return end

    if maxWidth and self.fontString:GetStringWidth() > maxWidth then
        -- 截断并添加省略号
        local truncated = name:sub(1, -4) .. "..."
        self.fontString:SetText(truncated)
    end
end

return NameTextModule