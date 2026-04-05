-- HealthTextModule.lua
-- EnhancedUnitFrames 生命值文字模块
-- 显示生命值数值

local addonName, EUF = ...

local HealthTextModule = {}
EUF.HealthTextModule = HealthTextModule

-- 继承文字模块基类
setmetatable(HealthTextModule, {__index = EUF.TextModuleBase})

-------------------------------------------------------------------------------
-- 构造函数
-------------------------------------------------------------------------------

function HealthTextModule:New(moduleKey, frameKey, unit)
    local obj = EUF.TextModuleBase.New(self, moduleKey, frameKey, unit)
    return obj
end

-------------------------------------------------------------------------------
-- 查找文字对象
-------------------------------------------------------------------------------

function HealthTextModule:FindFontString()
    if self.frameKey == "player" then
        -- 玩家生命值文字
        self.fontString = _G.PlayerFrameHealthBarText
        if not self.fontString and PlayerFrame then
            if PlayerFrame.PlayerFrameContent then
                local content = PlayerFrame.PlayerFrameContent
                if content.PlayerFrameContentMain then
                    local healthBar = content.PlayerFrameContentMain.HealthBar
                    if healthBar then
                        self.fontString = healthBar.Text
                    end
                end
            end
        end

    elseif self.frameKey == "target" then
        self.fontString = _G.TargetFrameHealthBarText
        if not self.fontString and TargetFrame then
            if TargetFrame.TargetFrameContent then
                local healthBar = TargetFrame.TargetFrameContent.HealthBar
                if healthBar then
                    self.fontString = healthBar.Text
                end
            end
        end

    elseif self.frameKey == "focus" then
        self.fontString = _G.FocusFrameHealthBarText
        if not self.fontString and FocusFrame then
            if FocusFrame.FocusFrameContent then
                local healthBar = FocusFrame.FocusFrameContent.HealthBar
                if healthBar then
                    self.fontString = healthBar.Text
                end
            end
        end

    elseif self.frameKey == "pet" then
        self.fontString = _G.PetFrameHealthBarText

    elseif self.frameKey == "targettarget" then
        self.fontString = _G.TargetFrameToTHealthBarText
    end
end

-------------------------------------------------------------------------------
-- 更新
-------------------------------------------------------------------------------

function HealthTextModule:Update()
    if not self.initialized or not self.enabled then return end
    if not self.fontString then return end

    -- 生命值文字由暴雪自动更新
    -- 如果需要自定义格式，可以在这里处理
    -- 注意：12.0 机密值系统限制，不能进行数值计算
end

-------------------------------------------------------------------------------
-- 格式化生命值（12.0 注意事项）
-------------------------------------------------------------------------------

function HealthTextModule:FormatHealth(format)
    -- ⚠️ 12.0 警告：在竞技性战斗中，UnitHealth 返回机密值
    -- 无法进行算术运算，只能显示暴雪默认格式
    -- 此功能仅在非竞技性场景下可用

    if not self.fontString then return end

    -- 检查是否在竞技性场景
    -- 如果是，保持暴雪默认显示
    local health = UnitHealth(self.unit)
    local maxHealth = UnitHealthMax(self.unit)

    -- 检测机密值
    if EUF.SecretSafe.IsSecretValue(health) or EUF.SecretSafe.IsSecretValue(maxHealth) then
        -- 使用暴雪默认显示
        return
    end

    local text = self:FormatValue(format, health, maxHealth)
    if text then
        self.fontString:SetText(text)
    end
end

function HealthTextModule:FormatValue(format, current, maximum)
    if not format or format == "NONE" then
        return ""
    end

    if format == "PERCENT" then
        if maximum > 0 then
            return string.format("%.0f%%", (current / maximum) * 100)
        end

    elseif format == "CURRENT" then
        return self:FormatNumber(current)

    elseif format == "MAX" then
        return self:FormatNumber(maximum)

    elseif format == "CURMAX" then
        return string.format("%s/%s", self:FormatNumber(current), self:FormatNumber(maximum))

    elseif format == "CURPERCENT" then
        if maximum > 0 then
            return string.format("%s %.0f%%", self:FormatNumber(current), (current / maximum) * 100)
        end

    elseif format == "CURMAXPERCENT" then
        if maximum > 0 then
            return string.format("%s/%s %.0f%%",
                self:FormatNumber(current),
                self:FormatNumber(maximum),
                (current / maximum) * 100)
        end

    elseif format == "DEFICIT" then
        local deficit = maximum - current
        if deficit > 0 then
            return string.format("-%s", self:FormatNumber(deficit))
        else
            return ""
        end
    end

    return nil
end

function HealthTextModule:FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

return HealthTextModule