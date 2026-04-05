-- BlizzardHooks.lua
-- EnhancedUnitFrames 暴雪框体安全后钩模块
-- 使用 hooksecurefunc 安全地扩展暴雪原生函数
-- 12.0 合规：只使用后钩（Post-Hook），不使用前钩

local addonName, EUF = ...

local BlizzardHooks = {}
EUF.BlizzardHooks = BlizzardHooks

-- 模块状态
BlizzardHooks.initialized = false
BlizzardHooks.hooksRegistered = {}

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function BlizzardHooks:Initialize()
    if self.initialized then return end

    -- 注册所有安全后钩
    self:RegisterAllHooks()

    self.initialized = true
    EUF:Debug("BlizzardHooks: 模块初始化完成")
end

-------------------------------------------------------------------------------
-- 注册所有 Hook
-------------------------------------------------------------------------------

function BlizzardHooks:RegisterAllHooks()
    -- WoW 12.0: 使用 Mixin 的方式 hook

    -- Hook PlayerFrame 相关 (如果存在)
    if PlayerFrame_UpdateStatus then
        self:SafeHook("PlayerFrame_UpdateStatus", function()
            self:OnPlayerFrameUpdate()
        end)
    end

    -- Hook TargetFrameHealthBarMixin.OnValueChanged (WoW 12.0)
    if TargetFrameHealthBarMixin then
        self:SafeHookMethod(TargetFrameHealthBarMixin, "OnValueChanged", function(bar)
            self:OnTargetHealthBarUpdate(bar)
        end)
    end

    -- Hook FocusFrame (如果存在)
    if FocusFrameHealthBarMixin then
        self:SafeHookMethod(FocusFrameHealthBarMixin, "OnValueChanged", function(bar)
            self:OnFocusHealthBarUpdate(bar)
        end)
    end

    -- 状态条文字更新
    if TextStatusBar_UpdateTextString then
        self:SafeHook("TextStatusBar_UpdateTextString", function(statusBar)
            self:OnTextStatusBarUpdate(statusBar)
        end)
    end

    -- 单位框体生命条更新
    if UnitFrameHealthBar_Update then
        self:SafeHook("UnitFrameHealthBar_Update", function(unitFrame, unit)
            self:OnHealthBarUpdate(unitFrame, unit)
        end)
    end

    -- 单位框体法力条更新
    if UnitFrameManaBar_Update then
        self:SafeHook("UnitFrameManaBar_Update", function(manaBar, unit)
            self:OnManaBarUpdate(manaBar, unit)
        end)
    end

    EUF:Debug("BlizzardHooks: 所有安全后钩已注册")
end

-------------------------------------------------------------------------------
-- Hook 回调函数
-------------------------------------------------------------------------------

-- PlayerFrame 更新回调
function BlizzardHooks:OnPlayerFrameUpdate()
    if not EUF.enabled then return end

    -- 职业染色
    if EUF.ClassColors and EUF.ClassColors.initialized then
        EUF.ClassColors:ApplyToPlayerFrame()
    end
end

-- 目标生命条更新回调
function BlizzardHooks:OnTargetHealthBarUpdate(bar)
    if not EUF.enabled then return end

    -- 职业染色
    if EUF.ClassColors and EUF.ClassColors.initialized then
        EUF.ClassColors:ApplyToTargetFrame()
    end
end

-- 焦点生命条更新回调
function BlizzardHooks:OnFocusHealthBarUpdate(bar)
    if not EUF.enabled then return end

    -- 职业染色
    if EUF.ClassColors and EUF.ClassColors.initialized then
        EUF.ClassColors:ApplyToFocusFrame()
    end
end

-- 文字状态条更新回调
function BlizzardHooks:OnTextStatusBarUpdate(statusBar)
    if not EUF.enabled then return end
    if not statusBar then return end

    -- 文字设置模块可能需要在此处理
    -- 目前由 TextSettings 自己 Hook 处理
end

-- 生命条更新回调
function BlizzardHooks:OnHealthBarUpdate(unitFrame, unit)
    if not EUF.enabled then return end

    -- 材质更新
    if EUF.Textures and EUF.Textures.initialized then
        local db = EUF.Database and EUF.Database.db
        if db and db.textures then
            local healthTexture = db.textures.healthBar or "Blizzard"
            EUF.Textures:ApplyToStatusBar(unitFrame.healthbar or unitFrame.HealthBar, healthTexture)
        end
    end
end

-- 法力条更新回调
function BlizzardHooks:OnManaBarUpdate(manaBar, unit)
    if not EUF.enabled then return end

    -- 材质更新
    if EUF.Textures and EUF.Textures.initialized then
        local db = EUF.Database and EUF.Database.db
        if db and db.textures then
            local healthTexture = db.textures.healthBar or "Blizzard"
            local manaTexture = db.textures.manaBar or healthTexture
            EUF.Textures:ApplyToStatusBar(manaBar, manaTexture)
        end
    end
end

-------------------------------------------------------------------------------
-- 安全后钩包装函数
-------------------------------------------------------------------------------

-- 安全后 Hook 全局函数
-- 返回: success (boolean)
function BlizzardHooks:SafeHook(funcName, hookFunc)
    -- 检查是否已注册
    if self.hooksRegistered[funcName] then
        EUF:Debug("BlizzardHooks: 函数已被 Hook:", funcName)
        return false
    end

    -- 检查目标函数是否存在
    if type(_G[funcName]) ~= "function" then
        EUF:Debug("BlizzardHooks: 目标函数不存在:", funcName)
        return false
    end

    -- 尝试注册 Hook
    local success, err = pcall(hooksecurefunc, funcName, hookFunc)

    if success then
        self.hooksRegistered[funcName] = true
        EUF:Debug("BlizzardHooks: Hook 成功:", funcName)
        return true
    else
        EUF:Debug("BlizzardHooks: Hook 失败:", funcName, err)
        return false
    end
end

-- 安全后 Hook 对象方法
-- 返回: success (boolean)
function BlizzardHooks:SafeHookMethod(object, methodName, hookFunc)
    if not object then
        EUF:Debug("BlizzardHooks: 目标对象为 nil")
        return false
    end

    if type(object[methodName]) ~= "function" then
        EUF:Debug("BlizzardHooks: 目标方法不存在:", methodName)
        return false
    end

    -- 生成唯一键
    local key = tostring(object) .. ":" .. methodName

    if self.hooksRegistered[key] then
        EUF:Debug("BlizzardHooks: 方法已被 Hook:", methodName)
        return false
    end

    -- 尝试注册 Hook
    local success, err = pcall(hooksecurefunc, object, methodName, hookFunc)

    if success then
        self.hooksRegistered[key] = true
        EUF:Debug("BlizzardHooks: 方法 Hook 成功:", methodName)
        return true
    else
        EUF:Debug("BlizzardHooks: 方法 Hook 失败:", methodName, err)
        return false
    end
end

-- 安全后 Hook 脚本
-- 注意：HookScript 可能导致 Taint，谨慎使用
function BlizzardHooks:SafeHookScript(frame, scriptName, hookFunc)
    if not frame then
        EUF:Debug("BlizzardHooks: 目标框架为 nil")
        return false
    end

    local key = tostring(frame) .. ":" .. scriptName

    if self.hooksRegistered[key] then
        return false
    end

    -- 使用 HookScript（安全后钩）
    local success, err = pcall(frame.HookScript, frame, scriptName, hookFunc)

    if success then
        self.hooksRegistered[key] = true
        EUF:Debug("BlizzardHooks: Script Hook 成功:", scriptName)
        return true
    else
        EUF:Debug("BlizzardHooks: Script Hook 失败:", scriptName, err)
        return false
    end
end

-------------------------------------------------------------------------------
-- 工具函数
-------------------------------------------------------------------------------

-- 检查 Hook 是否已注册
function BlizzardHooks:IsHookRegistered(funcName)
    return self.hooksRegistered[funcName] == true
end

-- 获取已注册 Hook 数量
function BlizzardHooks:GetHookCount()
    local count = 0
    for _ in pairs(self.hooksRegistered) do
        count = count + 1
    end
    return count
end

return BlizzardHooks