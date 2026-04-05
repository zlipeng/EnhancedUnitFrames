-- FrameScale.lua
-- EnhancedUnitFrames 框体缩放模块
-- 支持自定义 PlayerFrame、TargetFrame 等的缩放大小
-- 12.0 合规：战斗中使用队列机制，脱战后应用

local addonName, EUF = ...

local FrameScale = {}
EUF.FrameScale = FrameScale

-- 缩放范围
FrameScale.MIN_SCALE = 0.5
FrameScale.MAX_SCALE = 2.0
FrameScale.DEFAULT_SCALE = 1.0

-- 模块状态
FrameScale.initialized = false
FrameScale.db = nil
FrameScale.pendingScales = {}
FrameScale.originalSizes = {}
FrameScale.frames = {}

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function FrameScale:Initialize(db)
    if self.initialized then return end

    self.db = db and db.scales
    if not self.db then
        EUF:Debug("FrameScale: 数据库配置不存在")
        return
    end

    -- 注册框体
    self.frames = {
        player = { frame = PlayerFrame, name = "玩家框体" },
        target = { frame = TargetFrame, name = "目标框体" },
        focus = { frame = FocusFrame, name = "焦点框体" },
        pet = { frame = PetFrame, name = "宠物框体" },
    }

    -- 保存原始尺寸
    for key, data in pairs(self.frames) do
        local frame = data.frame
        if frame then
            self.originalSizes[key] = {
                width = frame:GetWidth(),
                height = frame:GetHeight(),
                scale = frame:GetScale(),
            }
        end
    end

    -- 应用已保存的缩放
    self:ApplySavedScales()

    self.initialized = true
    EUF:Debug("FrameScale: 模块初始化完成")
end

-------------------------------------------------------------------------------
-- 核心功能
-------------------------------------------------------------------------------

-- 设置框体缩放
-- 返回: success, message
function FrameScale:SetFrameScale(frameKey, scale)
    -- 参数验证
    if not frameKey then
        return false, "无效的框体标识"
    end

    local frameData = self.frames[frameKey]
    if not frameData or not frameData.frame then
        return false, "框体不存在: " .. tostring(frameKey)
    end

    -- 验证并规范化缩放值
    scale = self:ValidateScale(scale)
    local frame = frameData.frame

    -- 12.0 关键：检查战斗状态
    if InCombatLockdown() then
        -- 战斗中：加入待处理队列
        self.pendingScales[frameKey] = scale
        EUF:Print(string.format("|cFFFFFF00战斗中:|r %s 缩放将在脱战后应用 (%.2f)",
            frameData.name, scale))
        return true, "queued"
    end

    -- 非战斗：直接应用
    self:ApplyScale(frame, scale)

    -- 保存设置
    if self.db then
        self.db[frameKey] = scale
    end

    EUF:Debug("FrameScale:", frameKey, "缩放已设置为", scale)
    return true, "applied"
end

-- 应用缩放到框体
function FrameScale:ApplyScale(frame, scale)
    if not frame then return end

    -- 非战斗状态检查
    if InCombatLockdown() then
        EUF:Debug("FrameScale: 战斗中无法应用缩放")
        return false
    end

    -- 保存当前锚点信息
    local point, relativeTo, relativePoint, x, y
    if frame.GetPoint and frame:GetNumPoints() > 0 then
        point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    end

    -- 设置缩放
    frame:SetScale(scale)

    -- 恢复锚点（缩放可能导致位置偏移）
    if point then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x or 0, y or 0)
    end

    return true
end

-- 应用已保存的缩放（登录时）
function FrameScale:ApplySavedScales()
    -- 战斗状态检查
    if InCombatLockdown() then
        EUF:Debug("FrameScale: 战斗中，延迟应用保存的缩放")
        -- 注册到 EUF 的待处理队列
        EUF:AddPendingOperation("ApplySavedScales", function()
            self:ApplySavedScales()
        end)
        return
    end

    if not self.db then return end

    for frameKey, scale in pairs(self.db) do
        local frameData = self.frames[frameKey]
        if frameData and frameData.frame and scale then
            scale = self:ValidateScale(scale)
            self:ApplyScale(frameData.frame, scale)
            EUF:Debug("FrameScale: 已应用", frameKey, "缩放", scale)
        end
    end
end

-- 处理待执行的缩放队列
function FrameScale:ProcessPendingScales()
    -- 再次检查战斗状态
    if InCombatLockdown() then
        EUF:Debug("FrameScale: 仍在战斗中，无法处理队列")
        return
    end

    local processed = 0
    for frameKey, scale in pairs(self.pendingScales) do
        local frameData = self.frames[frameKey]
        if frameData and frameData.frame then
            self:ApplyScale(frameData.frame, scale)
            if self.db then
                self.db[frameKey] = scale
            end
            processed = processed + 1
            EUF:Print(string.format("%s 缩放已应用 (%.2f)", frameData.name, scale))
        end
    end

    -- 清空队列
    wipe(self.pendingScales)

    if processed > 0 then
        EUF:Debug("FrameScale: 已处理", processed, "个待执行缩放")
    end
end

-- 重置为默认缩放
function FrameScale:ResetToDefault(frameKey)
    return self:SetFrameScale(frameKey, self.DEFAULT_SCALE)
end

-- 获取当前缩放
function FrameScale:GetFrameScale(frameKey)
    local frameData = self.frames[frameKey]
    if frameData and frameData.frame then
        return frameData.frame:GetScale()
    end
    return self.DEFAULT_SCALE
end

-- 获取原始尺寸
function FrameScale:GetOriginalSize(frameKey)
    return self.originalSizes[frameKey]
end

-------------------------------------------------------------------------------
-- 辅助函数
-------------------------------------------------------------------------------

-- 验证并规范化缩放值
function FrameScale:ValidateScale(scale)
    local num = tonumber(scale)
    if not num then
        return self.DEFAULT_SCALE
    end
    return math.max(self.MIN_SCALE, math.min(self.MAX_SCALE, num))
end

-- 获取所有支持的框体列表
function FrameScale:GetFrameList()
    local list = {}
    for key, data in pairs(self.frames) do
        if data.frame then
            table.insert(list, {
                key = key,
                name = data.name,
                scale = self:GetFrameScale(key),
            })
        end
    end
    return list
end

-- 检查是否有待处理的缩放
function FrameScale:HasPendingScales()
    return next(self.pendingScales) ~= nil
end

-------------------------------------------------------------------------------
-- 战斗事件处理
-------------------------------------------------------------------------------

-- 战斗结束时调用（由 Core.lua 触发）
function FrameScale:OnCombatEnd()
    if self:HasPendingScales() then
        self:ProcessPendingScales()
    end
end

return FrameScale