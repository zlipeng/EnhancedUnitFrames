-- Locales.lua
-- EnhancedUnitFrames 本地化管理模块
-- 使用自定义实现，无需外部依赖

local addonName, EUF = ...

local Locales = {}
EUF.Locales = Locales

-- 当前语言
Locales.currentLocale = "enUS"

-- 本地化字符串存储
Locales.strings = {}

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function Locales:Initialize()
    -- 获取客户端语言
    self.currentLocale = GetLocale() or "enUS"

    -- 加载对应语言
    self:LoadLocale(self.currentLocale)

    -- 回退到英语（确保所有字符串都有值）
    self:LoadLocale("enUS")

    EUF:Debug("Locales: 初始化完成，语言 =", self.currentLocale)
end

-- 加载本地化文件
function Locales:LoadLocale(locale)
    if locale == "zhCN" and EUF.Locale_zhCN then
        self:MergeLocale(EUF.Locale_zhCN)
    elseif locale == "zhTW" and EUF.Locale_zhTW then
        self:MergeLocale(EUF.Locale_zhTW)
    elseif EUF.Locale_enUS then
        self:MergeLocale(EUF.Locale_enUS)
    end
end

-- 合并本地化字符串
function Locales:MergeLocale(localeTable)
    for key, value in pairs(localeTable) do
        -- 只设置未存在的键（优先使用客户端语言）
        if not self.strings[key] then
            self.strings[key] = value
        end
    end
end

-------------------------------------------------------------------------------
-- 获取本地化字符串
-------------------------------------------------------------------------------

-- 获取本地化字符串
-- key: 字符串键
-- ...: 可选参数（用于格式化）
function Locales:Get(key, ...)
    local str = self.strings[key] or key

    if select("#", ...) > 0 then
        return format(str, ...)
    end

    return str
end

-- 简短别名
function EUF.L(key, ...)
    return Locales:Get(key, ...)
end

return Locales