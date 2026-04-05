-- PowerTextModule.lua
-- EnhancedUnitFrames 能量值文字模块
-- 显示能量值数值

local addonName, EUF = ...

local PowerTextModule = {}
EUF.PowerTextModule = PowerTextModule

-- 继承文字模块基类
setmetatable(PowerTextModule, {__index = EUF.TextModuleBase})

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function PowerTextModule:New(moduleKey, frameKey, unit)
    local obj = EUF.TextModuleBase.New(self, moduleKey, frameKey, unit)
    return obj
end

-------------------------------------------------------------------------------
-- 查找文字对象
-------------------------------------------------------------------------------

function PowerTextModule:FindFontString()
    if self.frameKey == "player" then
        self.fontString = _G.PlayerFrameManaBarText
        if not self.fontString and PlayerFrame then
            if PlayerFrame.PlayerFrameContent then
                local content = PlayerFrame.PlayerFrameContent
                if content.PlayerFrameContentMain then
                    local manaBar = content.PlayerFrameContentMain.ManaBar
                    if manaBar then
                        self.fontString = manaBar.Text
                    end
                end
            end
        end

    elseif self.frameKey == "target" then
        self.fontString = _G.TargetFrameManaBarText
        if not self.fontString and TargetFrame then
            if TargetFrame.TargetFrameContent then
                local manaBar = TargetFrame.TargetFrameContent.ManaBar
                if manaBar then
                    self.fontString = manaBar.Text
                end
            end
        end

    elseif self.frameKey == "focus" then
        self.fontString = _G.FocusFrameManaBarText
        if not self.fontString and FocusFrame then
            if FocusFrame.FocusFrameContent then
                local manaBar = FocusFrame.FocusFrameContent.ManaBar
                if manaBar then
                    self.fontString = manaBar.Text
                end
            end
        end

    elseif self.frameKey == "pet" then
        self.fontString = _G.PetFrameManaBarText

    elseif self.frameKey == "targettarget" then
        self.fontString = nil  -- 目标的目标通常没有能量值文字
    end
end

-------------------------------------------------------------------------------
-- 更新
-------------------------------------------------------------------------------

function PowerTextModule:Update()
    if not self.initialized or not self.enabled then return end
    if not self.fontString then return end

    -- 能量值文字由暴雪自动更新
end

-------------------------------------------------------------------------------
-- 格式化能量值（12.0 注意事项）
-------------------------------------------------------------------------------

function PowerTextModule:FormatPower(format)
    -- ⚠️ 12.0 警告：在竞技性战斗中，UnitPower 返回机密值

    if not self.fontString then return end

    local power = UnitPower(self.unit)
    local maxPower = UnitPowerMax(self.unit)

    -- 检测机密值
    if EUF.SecretSafe.IsSecretValue(power) or EUF.SecretSafe.IsSecretValue(maxPower) then
        return
    end

    local text = self:FormatValue(format, power, maxPower)
    if text then
        self.fontString:SetText(text)
    end
end

function PowerTextModule:FormatValue(format, current, maximum)
    if not format or format == "NONE" then
        return ""
    end

    if format == "PERCENT" then
        if maximum > 0 then
            return string.format("%.0f%%", (current / maximum) * 100)
        end

    elseif format == "CURRENT" then
        return tostring(current)

    elseif format == "MAX" then
        return tostring(maximum)

    elseif format == "CURMAX" then
        return string.format("%d/%d", current, maximum)

    elseif format == "CURPERCENT" then
        if maximum > 0 then
            return string.format("%d %.0f%%", current, (current / maximum) * 100)
        end
    end

    return nil
end

return PowerTextModule