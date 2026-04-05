-- MinimapButton.lua
-- EnhancedUnitFrames 小地图按钮模块
-- 提供快捷访问设置面板的功能

local addonName, EUF = ...

local MinimapButton = {}
EUF.MinimapButton = MinimapButton

-- 模块状态
MinimapButton.initialized = false
MinimapButton.button = nil
MinimapButton.isDragging = false

-- 待处理的战斗中操作
MinimapButton.pendingShow = nil

-- 常量
MinimapButton.ICON_PATH = "Interface\\Icons\\INV_Misc_Gear_01"
MinimapButton.BUTTON_SIZE = 32

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

function MinimapButton:Initialize()
    if self.initialized then return end

    -- 检查是否启用（带 nil 检查）
    local db = EUF.Database
    if not db or not db:Get("minimap", "show") then
        self.initialized = true
        return
    end

    -- 创建按钮
    self:CreateButton()

    -- 更新位置
    self:UpdatePosition()

    self.initialized = true
    EUF:Debug("MinimapButton: 模块初始化完成")
end

-------------------------------------------------------------------------------
-- 创建按钮
-------------------------------------------------------------------------------

function MinimapButton:CreateButton()
    if self.button then return end

    -- 创建按钮框架（父框架使用 Minimap 以确保位置计算一致）
    local button = CreateFrame("Button", "EUF_MinimapButton", Minimap)
    button:SetSize(self.BUTTON_SIZE, self.BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetClampedToScreen(true)

    -- 设置图标
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture(self.ICON_PATH)
    button.icon = icon

    -- 边框和高亮
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(54, 54)
    overlay:SetPoint("CENTER")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.overlay = overlay

    -- 高亮效果
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(24, 24)
    highlight:SetPoint("CENTER")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetHighlightTexture(highlight)

    -- 设置可拖拽
    button:SetMovable(true)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- 点击事件
    button:SetScript("OnClick", function(self, btn)
        MinimapButton:OnClick(btn)
    end)

    -- 拖拽事件（战斗中禁止）
    button:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then
            EUF:Print("|cFFFFFF00战斗中无法移动按钮|r")
            return
        end
        local db = EUF.Database
        if db and not db:Get("minimap", "locked") then
            self:StartMoving()
            MinimapButton.isDragging = true
        end
    end)

    button:SetScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        self:StopMovingOrSizing()
        MinimapButton.isDragging = false
        MinimapButton:SavePosition()
    end)

    -- 进入/离开提示
    button:SetScript("OnEnter", function(self)
        MinimapButton:OnEnter(self)
    end)

    button:SetScript("OnLeave", function(self)
        -- 检查 tooltip 所有权
        if GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)

    -- 鼠标滚轮（可选：调整缩放）
    button:EnableMouseWheel(true)
    button:SetScript("OnMouseWheel", function(self, delta)
        MinimapButton:OnMouseWheel(delta)
    end)

    self.button = button

    -- 检查隐藏状态
    local db = EUF.Database
    if db and db:Get("minimap", "hide") then
        button:Hide()
    end
end

-------------------------------------------------------------------------------
-- 事件处理
-------------------------------------------------------------------------------

-- 点击处理
function MinimapButton:OnClick(btn)
    if self.isDragging then return end

    if btn == "LeftButton" then
        -- 左键：打开设置面板
        self:OpenSettings()
    elseif btn == "RightButton" then
        -- 右键：显示菜单
        self:ShowContextMenu()
    end
end

-- 鼠标滚轮处理（可选功能）
function MinimapButton:OnMouseWheel(delta)
    -- 可以用于调整框体缩放等
    -- 暂时不实现，保留扩展接口
end

-- 提示框
function MinimapButton:OnEnter(frame)
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cFFFFFFFFEnhanced Unit Frames|r")
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFF00FF00左键|r 打开设置面板", 1, 1, 1)
    GameTooltip:AddLine("|cFF00FF00右键|r 快捷菜单", 1, 1, 1)
    GameTooltip:AddLine("|cFF00FF00拖拽|r 移动按钮位置", 1, 1, 1)
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- 功能方法
-------------------------------------------------------------------------------

-- 打开设置面板
function MinimapButton:OpenSettings()
    if EUF.OptionsPanel then
        EUF.OptionsPanel:Open()
    else
        -- 回退：打开插件设置页面
        InterfaceOptionsFrame_OpenToCategory("Enhanced Unit Frames")
    end
end

-- 显示右键菜单
function MinimapButton:ShowContextMenu()
    local db = EUF.Database
    if not db then return end

    local menu = {
        { text = "Enhanced Unit Frames", isTitle = true, notCheckable = true },
        { text = "打开设置", func = function() self:OpenSettings() end },
        { text = " ", isTitle = true, notCheckable = true },
    }

    -- 职业染色开关
    local classColorEnabled = db:Get("classColors", "enabled")
    table.insert(menu, {
        text = "职业染色",
        checked = classColorEnabled,
        func = function()
            local newStatus = not db:Get("classColors", "enabled")
            db:Set(newStatus, "classColors", "enabled")
            if EUF.ClassColors then
                EUF.ClassColors:Refresh()
            end
        end,
    })

    -- 分隔线
    table.insert(menu, { text = " ", isTitle = true, notCheckable = true })

    -- 锁定位置
    local locked = db:Get("minimap", "locked")
    table.insert(menu, {
        text = "锁定按钮位置",
        checked = locked,
        func = function()
            db:Set(not locked, "minimap", "locked")
        end,
    })

    -- 隐藏按钮
    table.insert(menu, {
        text = "隐藏按钮",
        func = function()
            self:Hide()
        end,
    })

    -- 分隔线
    table.insert(menu, { text = " ", isTitle = true, notCheckable = true })

    -- 重置配置
    table.insert(menu, {
        text = "|cFFFF0000重置配置|r",
        func = function()
            db:ResetProfile()
            EUF:InitializeModules()
            EUF:Print("配置已重置")
        end,
    })

    -- 显示菜单
    EasyMenu(menu, CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate"), "cursor", 0, 0, "MENU")
end

-------------------------------------------------------------------------------
-- 位置管理
-------------------------------------------------------------------------------

-- 更新按钮位置
function MinimapButton:UpdatePosition()
    if not self.button then return end

    local db = EUF.Database
    if not db then return end

    local angle = db:Get("minimap", "angle") or -45
    local radius = db:Get("minimap", "radius") or 80

    -- 转换角度为弧度
    local radian = math.rad(angle)

    -- 计算位置
    local x = radius * math.cos(radian)
    local y = radius * math.sin(radian)

    -- 设置位置
    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- 保存位置
function MinimapButton:SavePosition()
    if not self.button then return end

    -- 获取按钮相对于小地图中心的位置
    local mx, my = Minimap:GetCenter()
    local px, py = self.button:GetCenter()

    if not mx or not px then return end

    -- 计算角度
    local angle = math.deg(math.atan2(py - my, px - mx))

    -- 保存角度
    if EUF.Database then
        EUF.Database:Set(angle, "minimap", "angle")
    end

    -- 更新位置（确保吸附）
    self:UpdatePosition()
end

-- 重置位置
function MinimapButton:ResetPosition()
    if EUF.Database then
        EUF.Database:Set(-45, "minimap", "angle")
        EUF.Database:Set(80, "minimap", "radius")
    end
    self:UpdatePosition()
end

-------------------------------------------------------------------------------
-- 显示/隐藏（战斗安全）
-------------------------------------------------------------------------------

-- 显示按钮
function MinimapButton:Show()
    if not self.button then return end

    if InCombatLockdown() then
        -- 战斗中排队等待
        self.pendingShow = true
        EUF:Print("|cFFFFFF00小地图按钮将在脱战后显示|r")
        return
    end

    self.button:Show()
    if EUF.Database then
        EUF.Database:Set(false, "minimap", "hide")
    end
end

-- 隐藏按钮
function MinimapButton:Hide()
    if not self.button then return end

    if InCombatLockdown() then
        -- 战斗中排队等待
        self.pendingShow = false
        EUF:Print("|cFFFFFF00小地图按钮将在脱战后隐藏|r")
        return
    end

    self.button:Hide()
    if EUF.Database then
        EUF.Database:Set(true, "minimap", "hide")
    end
    EUF:Print("小地图按钮已隐藏，使用 /euf minimap show 重新显示")
end

-- 切换显示
function MinimapButton:Toggle()
    if self.button and self.button:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- 战斗结束后处理待执行操作
function MinimapButton:OnCombatEnd()
    if not self.button then return end

    if self.pendingShow == true then
        self.button:Show()
        if EUF.Database then
            EUF.Database:Set(false, "minimap", "hide")
        end
        self.pendingShow = nil
    elseif self.pendingShow == false then
        self.button:Hide()
        if EUF.Database then
            EUF.Database:Set(true, "minimap", "hide")
        end
        self.pendingShow = nil
    end
end

-------------------------------------------------------------------------------
-- 刷新
-------------------------------------------------------------------------------

function MinimapButton:Refresh()
    if not self.initialized then return end

    local db = EUF.Database
    if not db then return end

    local show = db:Get("minimap", "show")
    local hide = db:Get("minimap", "hide")

    -- 战斗中不执行 Show/Hide
    if InCombatLockdown() then
        return
    end

    if show and not hide then
        if not self.button then
            self:CreateButton()
        end
        self.button:Show()
        self:UpdatePosition()
    elseif self.button then
        if hide then
            self.button:Hide()
        else
            self.button:Show()
        end
    end
end

return MinimapButton