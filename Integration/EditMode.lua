-- EditMode.lua
-- EnhancedUnitFrames 编辑模式集成模块
-- 与暴雪 Edit Mode 系统集成，提供框体缩放拖拽功能
-- 12.0 合规：战斗中禁止操作，使用安全方法

local addonName, EUF = ...

local EditMode = {}
EUF.EditMode = EditMode

-- 模块状态
EditMode.initialized = false
EditMode.db = nil
EditMode.isInEditMode = false
EditMode.systemFrames = {}
EditMode.editControls = {}
EditMode.draggingFrame = nil
EditMode.resizingFrame = nil

-- 颜色配置
EditMode.HIGHLIGHT_COLOR = {r = 0.2, g = 0.4, b = 0.8, a = 0.5}
EditMode.HANDLE_SIZE = 12

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function EditMode:Initialize(db)
    if self.initialized then return end

    self.db = db and db.editMode
    if not self.db then
        self:InitDefaultDB()
    end

    -- 注册框体
    self:RegisterFrames()

    -- 监听编辑模式事件（Core.lua 已注册 EDIT_MODE_MODE_CHANGED）
    -- 此处只需要实现回调方法

    self.initialized = true
    EUF:Debug("EditMode: 模块初始化完成")
end

-- 初始化默认数据库
function EditMode:InitDefaultDB()
    self.db = {
        showInEditMode = true,
        syncWithBlizzard = true,
    }
end

-- 注册要编辑的框体
function EditMode:RegisterFrames()
    self.systemFrames = {
        player = {
            frame = PlayerFrame,
            name = "玩家框体",
            scaleKey = "player",
        },
        target = {
            frame = TargetFrame,
            name = "目标框体",
            scaleKey = "target",
        },
        focus = {
            frame = FocusFrame,  -- 可能为 nil
            name = "焦点框体",
            scaleKey = "focus",
        },
        pet = {
            frame = PetFrame,
            name = "宠物框体",
            scaleKey = "pet",
        },
    }
end

-------------------------------------------------------------------------------
-- 编辑模式事件处理
-------------------------------------------------------------------------------

-- 编辑模式状态变化（由 Core.lua 事件触发）
function EditMode:OnEditModeChanged(isInEditMode)
    self.isInEditMode = isInEditMode

    if isInEditMode then
        self:OnEditModeEnter()
    else
        self:OnEditModeExit()
    end
end

-- 进入编辑模式
function EditMode:OnEditModeEnter()
    if not self.db or not self.db.showInEditMode then
        return
    end

    -- 战斗中禁止
    if InCombatLockdown() then
        EUF:Print("|cFFFFFF00无法在战斗中进入编辑模式|r")
        return
    end

    EUF:Debug("EditMode: 进入编辑模式")

    -- 为所有框体创建编辑控件（仅对存在的框体）
    for key, data in pairs(self.systemFrames) do
        if data.frame then
            self:CreateEditControls(data.frame, key)
        end
    end
end

-- 退出编辑模式
function EditMode:OnEditModeExit()
    EUF:Debug("EditMode: 退出编辑模式")

    -- 保存设置
    self:SaveFrameSettings()

    -- 隐藏所有编辑控件
    self:HideEditControls()

    -- 与暴雪编辑模式同步
    if self.db and self.db.syncWithBlizzard then
        self:SyncWithBlizzardEditMode()
    end
end

-------------------------------------------------------------------------------
-- 编辑控件创建
-------------------------------------------------------------------------------

-- 为框体创建编辑控件
function EditMode:CreateEditControls(frame, unitKey)
    if not frame then return end

    -- 战斗中禁止
    if InCombatLockdown() then return end

    -- 清除旧控件（完整清理）
    if self.editControls[unitKey] then
        local oldControls = self.editControls[unitKey]
        -- 清理子对象
        if oldControls.dragHandles then
            for i, handle in ipairs(oldControls.dragHandles) do
                handle:Hide()
                handle:SetParent(nil)
            end
        end
        if oldControls.resizeHandle then
            oldControls.resizeHandle:Hide()
            oldControls.resizeHandle:SetParent(nil)
        end
        if oldControls.highlight then
            oldControls.highlight:SetParent(nil)
        end
        if oldControls.border then
            oldControls.border:SetParent(nil)
        end
        if oldControls.scaleDisplay then
            oldControls.scaleDisplay:SetParent(nil)
        end
        oldControls:Hide()
        oldControls:SetParent(nil)
        self.editControls[unitKey] = nil
    end

    -- 创建控件容器
    local controls = CreateFrame("Frame", nil, frame)
    controls:SetAllPoints(frame)
    controls:SetFrameLevel(frame:GetFrameLevel() + 100)
    controls.unitKey = unitKey

    -- 高亮边框
    local highlight = controls:CreateTexture(nil, "OVERLAY")
    highlight:SetAllPoints(controls)
    highlight:SetColorTexture(
        self.HIGHLIGHT_COLOR.r,
        self.HIGHLIGHT_COLOR.g,
        self.HIGHLIGHT_COLOR.b,
        self.HIGHLIGHT_COLOR.a
    )
    controls.highlight = highlight

    -- 边框线条
    local border = controls:CreateTexture(nil, "OVERLAY")
    border:SetPoint("CENTER")
    border:SetSize(controls:GetWidth() + 4, controls:GetHeight() + 4)
    border:SetColorTexture(0.2, 0.4, 0.8, 0.8)
    -- 使用 SetDrawLayer 实现边框效果
    border:SetDrawLayer("OVERLAY", 1)
    controls.border = border

    -- 创建四角拖拽手柄
    self:CreateDragHandles(controls, frame)

    -- 创建缩放手柄（右下角）
    self:CreateResizeHandle(controls, frame, unitKey)

    -- 创建缩放百分比显示
    self:CreateScaleDisplay(controls, unitKey)

    -- 存储控件
    self.editControls[unitKey] = controls

    -- 设置拖拽行为
    self:SetupDragging(controls, frame, unitKey)

    controls:Show()
end

-- 创建拖拽手柄
function EditMode:CreateDragHandles(controls, frame)
    local handleSize = self.HANDLE_SIZE

    -- 四个角的位置
    local corners = {
        { point = "TOPLEFT",    x = -handleSize/2, y = handleSize/2 },
        { point = "TOPRIGHT",   x = handleSize/2,  y = handleSize/2 },
        { point = "BOTTOMLEFT", x = -handleSize/2, y = -handleSize/2 },
        { point = "BOTTOMRIGHT",x = handleSize/2,  y = -handleSize/2 },
    }

    controls.dragHandles = {}

    for i, corner in ipairs(corners) do
        local handle = CreateFrame("Frame", nil, controls)
        handle:SetSize(handleSize, handleSize)
        handle:SetPoint(corner.point, controls, corner.point, corner.x, corner.y)

        -- 手柄外观
        local texture = handle:CreateTexture(nil, "OVERLAY")
        texture:SetAllPoints(handle)
        texture:SetColorTexture(0.4, 0.6, 1, 1)

        -- 高亮效果
        handle:SetScript("OnEnter", function(self)
            texture:SetColorTexture(0.6, 0.8, 1, 1)
        end)
        handle:SetScript("OnLeave", function(self)
            texture:SetColorTexture(0.4, 0.6, 1, 1)
        end)

        controls.dragHandles[i] = handle
    end
end

-- 创建缩放手柄
function EditMode:CreateResizeHandle(controls, frame, unitKey)
    local handleSize = self.HANDLE_SIZE + 4

    local handle = CreateFrame("Frame", nil, controls)
    handle:SetSize(handleSize, handleSize)
    handle:SetPoint("BOTTOMRIGHT", controls, "BOTTOMRIGHT", handleSize/2, -handleSize/2)
    handle.unitKey = unitKey

    -- 缩放手柄图标
    local texture = handle:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(handle)
    texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    -- 高亮效果
    handle:SetScript("OnEnter", function(self)
        texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end)
    handle:SetScript("OnLeave", function(self)
        texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)

    -- 缩放拖拽
    handle:SetScript("OnMouseDown", function(self, button)
        if InCombatLockdown() then
            EUF:Print("|cFFFFFF00战斗中无法调整缩放|r")
            return
        end

        if button == "LeftButton" then
            EditMode.resizingFrame = {
                frame = frame,
                unitKey = unitKey,
                startX = GetCursorPosition(),
                startScale = frame:GetScale(),
                startWidth = frame:GetWidth(),
            }
            self:StartSizing()
        end
    end)

    handle:SetScript("OnMouseUp", function(self)
        if EditMode.resizingFrame then
            -- resize handle 不需要 StopMovingOrSizing，它本身不执行移动/缩放
            EditMode:OnResizeEnd()
        end
    end)

    controls.resizeHandle = handle
end

-- 创建缩放显示
function EditMode:CreateScaleDisplay(controls, unitKey)
    local display = controls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    display:SetPoint("BOTTOM", controls, "TOP", 0, 5)

    -- 更新显示
    local function updateDisplay()
        if EUF.FrameScale then
            local scale = EUF.FrameScale:GetFrameScale(unitKey)
            display:SetText(string.format("缩放: %.0f%%", scale * 100))
        end
    end

    updateDisplay()
    controls.scaleDisplay = display
    controls.UpdateScaleDisplay = updateDisplay
end

-------------------------------------------------------------------------------
-- 拖拽行为设置
-------------------------------------------------------------------------------

-- 设置框体拖拽
function EditMode:SetupDragging(controls, frame, unitKey)
    -- 使框体可拖拽
    controls:SetMovable(true)
    controls:EnableMouse(true)
    controls:RegisterForDrag("LeftButton")

    -- 开始拖拽
    controls:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then
            EUF:Print("|cFFFFFF00战斗中无法移动框体|r")
            return
        end

        -- 检查是否在缩放手柄上
        if EditMode.resizingFrame then
            return
        end

        frame:StartMoving()
        EditMode.draggingFrame = {
            frame = frame,
            unitKey = unitKey,
        }
    end)

    -- 停止拖拽
    controls:SetScript("OnDragStop", function(self)
        if EditMode.draggingFrame then
            frame:StopMovingOrSizing()
            EditMode:OnDragEnd(frame, unitKey)
            EditMode.draggingFrame = nil
        end
    end)
end

-- 拖拽结束处理
function EditMode:OnDragEnd(frame, unitKey)
    -- 位置由暴雪编辑模式系统管理
    -- 无需额外保存
    EUF:Debug("EditMode: 框体拖拽结束", unitKey)
end

-- 缩放结束处理
function EditMode:OnResizeEnd()
    if not self.resizingFrame then return end

    local data = self.resizingFrame
    local frame = data.frame
    local unitKey = data.unitKey

    -- 战斗中禁止缩放修改
    if InCombatLockdown() then
        EUF:Print("|cFFFFFF00战斗中无法应用缩放更改，将在脱战后自动应用|r")
        -- 将缩放请求排队等待战斗结束
        local scaleFactor = 1 + ((GetCursorPosition() - data.startX) / 200)
        local newScale = math.max(0.5, math.min(2.0, data.startScale * scaleFactor))
        if EUF.FrameScale then
            EUF.FrameScale.pendingScales = EUF.FrameScale.pendingScales or {}
            EUF.FrameScale.pendingScales[unitKey] = newScale
        end
        self.resizingFrame = nil
        return
    end

    -- 计算新缩放
    local currentX, currentY = GetCursorPosition()
    local deltaX = currentX - data.startX

    -- 简单的缩放计算
    local scaleFactor = 1 + (deltaX / 200)
    local newScale = data.startScale * scaleFactor

    -- 限制范围
    newScale = math.max(0.5, math.min(2.0, newScale))

    -- 应用缩放
    if EUF.FrameScale then
        EUF.FrameScale:SetFrameScale(unitKey, newScale)
    else
        frame:SetScale(newScale)
    end

    -- 更新显示
    local controls = self.editControls[unitKey]
    if controls and controls.UpdateScaleDisplay then
        controls:UpdateScaleDisplay()
    end

    self.resizingFrame = nil
    EUF:Debug("EditMode: 缩放结束", unitKey, newScale)
end

-------------------------------------------------------------------------------
-- 设置保存与同步
-------------------------------------------------------------------------------

-- 保存框体设置
function EditMode:SaveFrameSettings()
    -- 缩放设置由 FrameScale 模块管理
    -- 位置设置由暴雪 Edit Mode 系统管理
    EUF:Debug("EditMode: 设置已保存")
end

-- 与暴雪编辑模式同步
function EditMode:SyncWithBlizzardEditMode()
    -- 尝试同步到 C_EditMode
    if C_EditMode and C_EditMode.SaveLayouts then
        local success, err = pcall(function()
            C_EditMode.SaveLayouts()
        end)

        if success then
            EUF:Debug("EditMode: 已同步到暴雪编辑模式")
        else
            EUF:Debug("EditMode: 同步失败", err)
        end
    end
end

-------------------------------------------------------------------------------
-- 控件管理
-------------------------------------------------------------------------------

-- 隐藏所有编辑控件
function EditMode:HideEditControls()
    for key, controls in pairs(self.editControls) do
        if controls then
            controls:Hide()
        end
    end
end

-- 显示编辑控件
function EditMode:ShowEditControls()
    for key, controls in pairs(self.editControls) do
        if controls then
            controls:Show()
        end
    end
end

-- 销毁所有编辑控件
function EditMode:DestroyEditControls()
    for key, controls in pairs(self.editControls) do
        if controls then
            -- 清理子对象
            if controls.dragHandles then
                for i, handle in ipairs(controls.dragHandles) do
                    handle:SetParent(nil)
                    handle:ClearAllPoints()
                end
                wipe(controls.dragHandles)
            end
            if controls.resizeHandle then
                controls.resizeHandle:SetParent(nil)
                controls.resizeHandle:ClearAllPoints()
            end
            if controls.highlight then
                controls.highlight:SetParent(nil)
            end
            if controls.border then
                controls.border:SetParent(nil)
            end
            if controls.scaleDisplay then
                controls.scaleDisplay:SetParent(nil)
            end
            -- 隐藏并分离控件容器
            controls:Hide()
            controls:SetParent(nil)
        end
    end
    wipe(self.editControls)
end

-------------------------------------------------------------------------------
-- 辅助函数
-------------------------------------------------------------------------------

-- 检查是否在编辑模式
function EditMode:IsInEditMode()
    return self.isInEditMode
end

-- 检查是否启用了编辑模式集成
function EditMode:IsEnabled()
    return self.db and self.db.showInEditMode
end

-- 刷新编辑控件
function EditMode:Refresh()
    if self.isInEditMode then
        self:HideEditControls()
        self:OnEditModeEnter()
    end
end

return EditMode