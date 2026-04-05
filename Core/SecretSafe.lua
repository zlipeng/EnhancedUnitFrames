-- SecretSafe.lua
-- EnhancedUnitFrames 机密值安全处理层
-- WoW 12.0 "Addon Disarmament" 核心合规模块
--
-- 12.0 机密值系统说明：
-- 在竞技性战斗（团本/大秘境/PVP）中，UnitHealth/UnitPower 等API返回"机密值"
-- 机密值无法进行算术运算或比较操作，只能传递给暴雪原生组件（如StatusBar）
-- 本模块提供安全包装函数，确保插件不会因机密值而报错

local addonName, EUF = ...

local SecretSafe = {}
EUF.SecretSafe = SecretSafe

-- 是否启用了机密值检测（可通过配置关闭以提升性能）
SecretSafe.enableDetection = true

-------------------------------------------------------------------------------
-- 机密值检测
-------------------------------------------------------------------------------

-- 判断值是否为机密值
-- 12.0 机密值通常是 userdata 类型或带有特殊标记的表
function SecretSafe.IsSecretValue(value)
    if not SecretSafe.enableDetection then
        return false
    end

    if value == nil then
        return false
    end

    -- 机密值通常是 userdata 类型
    if type(value) == "userdata" then
        return true
    end

    -- 检查是否是暴雪定义的机密值类型（12.0新API，如果存在）
    -- 暴雪可能在12.0提供 IsSecretValue() 全局函数
    if _G.IsSecretValue then
        return _G.IsSecretValue(value)
    end

    -- 检查表是否有机密值标记
    if type(value) == "table" then
        if value.IsSecret and type(value.IsSecret) == "function" then
            return value:IsSecret()
        end
        -- 检查常见的机密值标记
        if value._isSecret or value.isSecretValue then
            return true
        end
    end

    return false
end

-------------------------------------------------------------------------------
-- 安全数值获取
-------------------------------------------------------------------------------

-- 安全数值获取
-- 如果是机密值，返回 fallback；否则返回数值
function SecretSafe.SafeNumber(value, fallback)
    fallback = fallback or 0

    if SecretSafe.IsSecretValue(value) then
        return fallback, true  -- 返回fallback，并标记遇到了机密值
    end

    local num = tonumber(value)
    if num == nil then
        return fallback, false
    end

    return num, false
end

-- 尝试获取数值，如果失败返回 nil
function SecretSafe.TryNumber(value)
    if SecretSafe.IsSecretValue(value) then
        return nil
    end
    return tonumber(value)
end

-------------------------------------------------------------------------------
-- 安全文本获取
-------------------------------------------------------------------------------

-- 安全文本获取
-- 如果是机密值，返回 fallback；否则返回字符串
function SecretSafe.SafeText(value, fallback)
    fallback = fallback or ""

    if SecretSafe.IsSecretValue(value) then
        return fallback, true
    end

    if value == nil then
        return fallback, false
    end

    return tostring(value), false
end

-------------------------------------------------------------------------------
-- 安全 API 调用包装
-------------------------------------------------------------------------------

-- 安全 API 调用包装
-- 使用 pcall 包装可能失败的 API 调用
-- 返回: success, result, isSecret
function SecretSafe.SafeAPICall(func, ...)
    -- 检查函数有效性
    if type(func) ~= "function" then
        return false, nil, false
    end

    -- 尝试调用
    local success, result = pcall(func, ...)

    if not success then
        -- 调用失败（可能是机密值错误或其他错误）
        return false, nil, false
    end

    -- 检查返回值是否为机密值
    local isSecret = SecretSafe.IsSecretValue(result)

    return true, result, isSecret
end

-- 安全 API 调用（多返回值版本）
-- 返回: success, isSecret, ...results
function SecretSafe.SafeAPICallMulti(func, ...)
    if type(func) ~= "function" then
        return false, false
    end

    local success, result = pcall(func, ...)

    if not success then
        return false, false
    end

    -- 检查是否有任何返回值是机密值
    local isSecret = false
    if type(result) == "table" then
        for i = 1, #result do
            if SecretSafe.IsSecretValue(result[i]) then
                isSecret = true
                break
            end
        end
    else
        isSecret = SecretSafe.IsSecretValue(result)
    end

    return true, isSecret, result
end

-------------------------------------------------------------------------------
-- 职业色安全获取（GUID路径 - 12.0推荐）
-------------------------------------------------------------------------------

-- 安全职业色获取
-- 使用 GUID + GetPlayerInfoByGUID 路径（非机密）
-- 返回: ColorMixin 对象 或 nil
function SecretSafe.SafeGetClassColor(unit)
    -- 防御性检查
    if not unit or not UnitExists(unit) then
        return nil
    end

    -- 方法 1: 通过 GUID 获取职业（推荐，非机密路径）
    local guid = UnitGUID(unit)
    if guid then
        local _, englishClass = GetPlayerInfoByGUID(guid)
        if englishClass then
            local color = C_ClassColor.GetClassColor(englishClass)
            if color then
                -- 确保 color 是 ColorMixin 对象
                -- C_ClassColor.GetClassColor 可能返回带 r/g/b 的表而非完整 ColorMixin
                return CreateColor(color.r, color.g, color.b, 1)
            end
        end
    end

    -- 方法 2: 通过 UnitClass 获取（某些场景可能返回机密值）
    local _, englishClass = UnitClass(unit)
    if englishClass then
        local color = C_ClassColor.GetClassColor(englishClass)
        if color then
            return CreateColor(color.r, color.g, color.b, 1)
        end
    end

    -- 默认白色
    return nil
end

-- 安全获取职业 Token
-- 返回: classToken (如 "WARRIOR", "PALADIN" 等)
function SecretSafe.SafeGetClassToken(unit)
    if not unit or not UnitExists(unit) then
        return nil
    end

    -- 优先使用 GUID 路径（非机密）
    local guid = UnitGUID(unit)
    if guid then
        local _, englishClass = GetPlayerInfoByGUID(guid)
        if englishClass then
            return englishClass
        end
    end

    -- 备用方案：UnitClass
    local _, englishClass = UnitClass(unit)
    if englishClass then
        return englishClass
    end

    return nil
end

-------------------------------------------------------------------------------
-- 反应色安全获取（NPC用）
-------------------------------------------------------------------------------

-- 反应色映射表（基于暴雪默认颜色）
SecretSafe.REACTION_COLORS = {
    [1] = {r = 1.0, g = 0.0, b = 0.0},  -- 敌对（红）
    [2] = {r = 1.0, g = 0.0, b = 0.0},  -- 仇恨（红）
    [3] = {r = 1.0, g = 0.5, b = 0.0},  -- 不友好（橙）
    [4] = {r = 1.0, g = 1.0, b = 0.0},  -- 中立（黄）
    [5] = {r = 0.5, g = 1.0, b = 0.0},  -- 友好（绿黄）
    [6] = {r = 0.0, g = 1.0, b = 0.0},  -- 友善（绿）
    [7] = {r = 0.0, g = 1.0, b = 0.0},  -- 尊敬（绿）
    [8] = {r = 0.0, g = 1.0, b = 0.0},  -- 崇拜（绿）
}

-- 安全反应色获取
-- 返回: ColorMixin 对象
function SecretSafe.SafeGetReactionColor(unit)
    if not unit or not UnitExists(unit) then
        return CreateColor(1, 1, 1, 1)
    end

    -- UnitReaction 是非机密 API
    local reaction = UnitReaction(unit, "player")
    if reaction then
        local c = SecretSafe.REACTION_COLORS[reaction]
        if c then
            return CreateColor(c.r, c.g, c.b, 1)
        end
    end

    return CreateColor(1, 1, 1, 1)
end

-------------------------------------------------------------------------------
-- 生命值/能量值安全处理
-------------------------------------------------------------------------------

-- 安全百分比计算
-- ⚠️ 12.0 注意：在竞技性战斗中可能无法获取具体数值
-- 推荐做法：让暴雪 StatusBar 处理，不要自行计算
-- 返回: percent 或 nil（无法计算时）
function SecretSafe.SafeGetHealthPercent(unit)
    -- 方法 1: 从 StatusBar 获取（如果已设置）
    local healthBar
    if unit == "player" then
        -- WoW 12.0: 优先使用新路径
        if PlayerFrame and PlayerFrame.PlayerFrameContent then
            local content = PlayerFrame.PlayerFrameContent
            if content.PlayerFrameContentMain and content.PlayerFrameContentMain.HealthBarsContainer then
                healthBar = content.PlayerFrameContentMain.HealthBarsContainer.HealthBar
            end
        end
        -- 备用旧版全局变量
        if not healthBar then
            healthBar = _G.PlayerFrameHealthBar
        end
    elseif unit == "target" then
        if TargetFrame and TargetFrame.TargetFrameContent then
            local content = TargetFrame.TargetFrameContent
            if content.TargetFrameContentMain and content.TargetFrameContentMain.HealthBarsContainer then
                healthBar = content.TargetFrameContentMain.HealthBarsContainer.HealthBar
            end
        end
        if not healthBar then
            healthBar = _G.TargetFrameHealthBar
        end
    elseif unit == "focus" then
        if FocusFrame and FocusFrame.FocusFrameContent then
            local content = FocusFrame.FocusFrameContent
            if content.FocusFrameContentMain and content.FocusFrameContentMain.HealthBarsContainer then
                healthBar = content.FocusFrameContentMain.HealthBarsContainer.HealthBar
            end
        end
        if not healthBar then
            healthBar = _G.FocusFrameHealthBar
        end
    end

    if healthBar then
        local min, max = healthBar:GetMinMaxValues()
        local value = healthBar:GetValue()

        -- 检查获取的值是否有效
        if min and max and value and not SecretSafe.IsSecretValue(min)
           and not SecretSafe.IsSecretValue(max) and not SecretSafe.IsSecretValue(value) then
            if max > 0 then
                return (value / max) * 100
            end
        end
    end

    -- 方法 2: 尝试直接获取（可能失败）
    local success1, health = SecretSafe.SafeAPICall(UnitHealth, unit)
    local success2, maxHealth = SecretSafe.SafeAPICall(UnitHealthMax, unit)

    if success1 and success2 then
        health, _ = SecretSafe.SafeNumber(health, 0)
        maxHealth, _ = SecretSafe.SafeNumber(maxHealth, 1)

        if maxHealth > 0 then
            return (health / maxHealth) * 100
        end
    end

    -- 无法获取
    return nil
end

-- 安全能量百分比计算
function SecretSafe.SafeGetPowerPercent(unit, powerType)
    powerType = powerType or nil  -- nil = 默认能量类型

    local powerBar
    if unit == "player" then
        -- 使用暴雪提供的函数（推荐）
        if _G.PlayerFrame_GetManaBar then
            powerBar = _G.PlayerFrame_GetManaBar()
        end
        -- 备用：新结构路径
        if not powerBar and PlayerFrame and PlayerFrame.PlayerFrameContent then
            local content = PlayerFrame.PlayerFrameContent
            if content.PlayerFrameContentMain then
                local main = content.PlayerFrameContentMain
                if main.ManaBarsContainer then
                    powerBar = main.ManaBarsContainer.ManaBar
                elseif main.ManaBar then
                    powerBar = main.ManaBar
                end
            end
        end
        -- 备用旧版全局变量
        if not powerBar then
            powerBar = _G.PlayerFrameManaBar
        end
    elseif unit == "target" then
        if TargetFrame and TargetFrame.TargetFrameContent then
            local content = TargetFrame.TargetFrameContent
            if content.TargetFrameContentMain then
                local main = content.TargetFrameContentMain
                if main.ManaBarsContainer then
                    powerBar = main.ManaBarsContainer.ManaBar
                elseif main.ManaBar then
                    powerBar = main.ManaBar
                end
            end
        end
        if not powerBar then
            powerBar = _G.TargetFrameManaBar
        end
    end

    if powerBar then
        local min, max = powerBar:GetMinMaxValues()
        local value = powerBar:GetValue()

        if min and max and value and not SecretSafe.IsSecretValue(min)
           and not SecretSafe.IsSecretValue(max) and not SecretSafe.IsSecretValue(value) then
            if max > 0 then
                return (value / max) * 100
            end
        end
    end

    -- 直接 API 尝试
    local success1, power = SecretSafe.SafeAPICall(UnitPower, unit, powerType)
    local success2, maxPower = SecretSafe.SafeAPICall(UnitPowerMax, unit, powerType)

    if success1 and success2 then
        power, _ = SecretSafe.SafeNumber(power, 0)
        maxPower, _ = SecretSafe.SafeNumber(maxPower, 1)

        if maxPower > 0 then
            return (power / maxPower) * 100
        end
    end

    return nil
end

-------------------------------------------------------------------------------
-- 调试辅助
-------------------------------------------------------------------------------

-- 检测并报告机密值
function SecretSafe.DetectAndReport(value, context)
    if SecretSafe.IsSecretValue(value) then
        if EUF and EUF.debugMode then
            local ctx = context or "unknown"
            EUF:Debug("Secret value detected in context:", ctx)
        end
        return true
    end
    return false
end

-- 安全调用包装器（带日志）
function SecretSafe.SafeCallWithLog(func, funcName, ...)
    local success, result = pcall(func, ...)

    if not success then
        if EUF and EUF.debugMode then
            EUF:Debug("SafeCall failed for:", funcName or "unknown function")
        end
        return false, nil
    end

    if SecretSafe.IsSecretValue(result) then
        if EUF and EUF.debugMode then
            EUF:Debug("Secret value returned from:", funcName or "unknown function")
        end
        return true, result, true  -- success, result, isSecret
    end

    return true, result, false
end

return SecretSafe