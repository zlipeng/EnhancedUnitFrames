-- Core.lua
-- EnhancedUnitFrames 核心模块
-- 负责插件初始化、事件管理和命令处理

local addonName, EUF = ...

-- 创建全局访问入口
EnhancedUnitFrames = EUF

-- 版本信息
EUF.VERSION = "1.1.0"
EUF.VERSION_DISPLAY = "v" .. EUF.VERSION

-- 插件状态
EUF.initialized = false
EUF.enabled = false
EUF.debugMode = false

-- 待处理的战斗锁定操作队列
EUF.pendingOperations = {}

-- 框体实例存储
EUF.frames = {}

-------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------

-- 主初始化函数
function EUF:OnInitialize()
    -- 初始化本地化系统（最先初始化）
    if self.Locales then
        self.Locales:Initialize()
    end

    -- 初始化数据库
    self.Database:Initialize()

    -- 加载调试模式设置
    self.debugMode = self.Database:GetGlobal("debugMode") or false

    -- 注册斜杠命令
    self:RegisterCommands()

    -- 创建事件框架
    self:EventFrame()

    -- 初始化设置面板（始终初始化，确保出现在选项列表中）
    if self.OptionsPanel then
        self.OptionsPanel:Initialize()
    end

    self.initialized = true
    self:Debug("EnhancedUnitFrames 初始化完成 - " .. self.VERSION_DISPLAY)
end

-- 启用函数
function EUF:OnEnable()
    if not self.initialized then
        self:OnInitialize()
    end

    -- 检查是否启用（但设置面板始终可用）
    if not self.Database:GetGlobal("enableAddon") then
        self:Debug("插件已禁用")
        return
    end

    self.enabled = true

    -- 初始化各功能模块
    self:InitializeModules()

    self:Print("已加载 - " .. self.VERSION_DISPLAY)
end

-- 禁用函数
function EUF:OnDisable()
    self.enabled = false
    self:Print("已禁用")
end

-------------------------------------------------------------------------------
-- 模块初始化
-------------------------------------------------------------------------------

-- 初始化各功能模块
function EUF:InitializeModules()
    -- 暴雪安全后钩模块（最先初始化）
    if self.BlizzardHooks then
        self.BlizzardHooks:Initialize()
    end

    -- 初始化新的模块化框体系统
    self:InitializeFrameModules()

    -- 小地图按钮
    if self.MinimapButton then
        self.MinimapButton:Initialize()
    end

    -- 注意：OptionsPanel 已在 OnInitialize() 中初始化

    self:Debug("所有模块初始化完成")
end

-- 初始化模块化框体系统
function EUF:InitializeFrameModules()
    local frameKeys = {"player", "target", "focus", "pet", "targettarget"}

    for _, frameKey in ipairs(frameKeys) do
        if self.FrameBase then
            local frame = self.FrameBase:New(frameKey)
            frame:Initialize()
            self.frames[frameKey] = frame
        end
    end

    self:Debug("框体模块初始化完成")
end

-------------------------------------------------------------------------------
-- 事件管理
-------------------------------------------------------------------------------

-- 创建并注册事件框架
function EUF:EventFrame()
    local eventFrame = CreateFrame("Frame")

    -- 注册需要监听的事件（注意：EDIT_MODE_MODE_CHANGED 在 12.0 中不存在）
    local events = {
        "PLAYER_LOGIN",
        "PLAYER_LOGOUT",
        "PLAYER_REGEN_ENABLED",
        "PLAYER_REGEN_DISABLED",
        "PLAYER_TARGET_CHANGED",
        "PLAYER_FOCUS_CHANGED",
        "UNIT_CLASSIFICATION_CHANGED",
    }

    for _, event in ipairs(events) do
        eventFrame:RegisterEvent(event)
    end

    -- 事件处理脚本
    eventFrame:SetScript("OnEvent", function(frame, event, ...)
        EUF:OnEvent(event, ...)
    end)

    self.eventFrame = eventFrame

    -- TODO: WoW 12.0 编辑模式 API 需要进一步研究
    -- EditModeManagerFrame 的方法名称可能已改变
    -- 暂时通过 EditMode 模块自身的初始化处理
end

-- 事件分发处理
function EUF:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:OnEnable()

    elseif event == "PLAYER_LOGOUT" then
        -- 登出时无需特殊处理，SavedVariables 自动保存

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- 战斗结束，执行排队的操作
        self:ProcessPendingOperations()

        -- 通知各框体战斗结束
        for frameKey, frame in pairs(self.frames) do
            if frame and frame.OnCombatEnd then
                frame:OnCombatEnd()
            end
        end

        -- 处理小地图按钮待执行操作
        if self.MinimapButton then
            self.MinimapButton:OnCombatEnd()
        end

        self:Debug("战斗结束，已处理待执行操作")

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- 进入战斗
        self:Debug("进入战斗")

    elseif event == "PLAYER_TARGET_CHANGED" then
        -- 目标切换事件（由各框体自己处理）

    elseif event == "PLAYER_FOCUS_CHANGED" then
        -- 焦点切换事件（由各框体自己处理）

    elseif event == "UNIT_CLASSIFICATION_CHANGED" then
        -- 单位分类变化（由各框体自己处理）
    end
    -- 注意：编辑模式变化现在通过 hooksecurefunc(EditModeManagerFrame) 处理
end

-------------------------------------------------------------------------------
-- 战斗锁定操作队列
-------------------------------------------------------------------------------

-- 添加待处理操作
-- operationType: 操作类型
-- func: 要执行的函数
-- ...: 函数参数
function EUF:AddPendingOperation(operationType, func, ...)
    if type(func) ~= "function" then
        return false
    end

    table.insert(self.pendingOperations, {
        type = operationType,
        func = func,
        args = {...},
    })

    self:Debug("操作已加入队列:", operationType)
    return true
end

-- 处理所有待执行操作
function EUF:ProcessPendingOperations()
    -- 再次检查战斗状态
    if InCombatLockdown() then
        self:Debug("仍在战斗中，跳过操作处理")
        return
    end

    local operations = self.pendingOperations
    self.pendingOperations = {}

    for _, op in ipairs(operations) do
        local success, err = pcall(op.func, unpack(op.args))
        if not success then
            self:Debug("执行待处理操作失败:", op.type, err)
        end
    end

    -- 清空操作队列
    wipe(operations)
end

-- 清空待处理队列
function EUF:ClearPendingOperations()
    wipe(self.pendingOperations)
end

-------------------------------------------------------------------------------
-- 斜杠命令
-------------------------------------------------------------------------------

-- 注册斜杠命令
function EUF:RegisterCommands()
    SLASH_ENHANCEDUNITFRAMES1 = "/euf"
    SLASH_ENHANCEDUNITFRAMES2 = "/enhancedunitframes"

    SlashCmdList["ENHANCEDUNITFRAMES"] = function(msg)
        self:HandleCommand(msg)
    end
end

-- 命令处理
function EUF:HandleCommand(msg)
    msg = msg:lower():trim()

    -- 解析命令和参数
    local command, args = msg:match("^(%S+)%s*(.*)$")
    command = command or msg
    args = args or ""

    if command == "" or command == "help" then
        self:ShowHelp()

    elseif command == "debug" then
        self:ToggleDebug()

    elseif command == "reset" then
        self:ResetConfig(args)

    elseif command == "scale" then
        self:CommandScale(args)

    elseif command == "color" then
        self:CommandColor(args)

    elseif command == "enable" then
        self:SetEnabled(true)

    elseif command == "disable" then
        self:SetEnabled(false)

    elseif command == "status" then
        self:ShowStatus()

    elseif command == "minimap" then
        self:CommandMinimap(args)

    elseif command == "config" then
        self:OpenConfig()

    else
        self:Print("未知命令:", command)
        self:ShowHelp()
    end
end

-- 显示帮助信息
function EUF:ShowHelp()
    local help = {
        "EnhancedUnitFrames 命令帮助:",
        "  /euf         - 显示此帮助",
        "  /euf help    - 显示此帮助",
        "  /euf config  - 打开设置面板",
        "  /euf debug   - 切换调试模式",
        "  /euf reset   - 重置所有配置",
        "  /euf scale [player|target|focus] [值] - 设置缩放",
        "  /euf color [on|off] - 开关职业染色",
        "  /euf minimap [show|hide|reset] - 小地图按钮控制",
        "  /euf enable  - 启用插件",
        "  /euf disable - 禁用插件",
        "  /euf status  - 显示当前状态",
    }

    for _, line in ipairs(help) do
        self:Print(line)
    end
end

-- 切换调试模式
function EUF:ToggleDebug()
    self.debugMode = not self.debugMode
    self.Database:SetGlobal("debugMode", self.debugMode)

    if self.debugMode then
        self:Print("调试模式已 |cFF00FF00开启|r")
    else
        self:Print("调试模式已 |cFFFF0000关闭|r")
    end
end

-- 重置配置
function EUF:ResetConfig(args)
    if args == "global" then
        self.Database:ResetGlobal()
    else
        self.Database:ResetProfile()
    end

    -- 重新初始化模块
    self:InitializeModules()
end

-- 缩放命令处理
function EUF:CommandScale(args)
    local frameKey, value = args:match("^(%S+)%s*(.*)$")

    if not frameKey or not value then
        self:Print("用法: /euf scale [player|target|focus] [0.5-2.0]")
        return
    end

    -- 验证框体类型
    local validFrames = {player = true, target = true, focus = true, pet = true}
    if not validFrames[frameKey] then
        self:Print("无效的框体类型:", frameKey)
        return
    end

    -- 解析缩放值
    local scale = tonumber(value)
    if not scale then
        self:Print("无效的缩放值:", value)
        return
    end

    -- 验证范围
    scale = self.Database:ValidateScale(scale)

    -- 设置缩放
    if self.FrameScale then
        self.FrameScale:SetFrameScale(frameKey, scale)
        self:Print(string.format("%s 缩放已设置为 %.2f", frameKey, scale))
    else
        self.Database:SetScale(frameKey, scale)
        self:Print(string.format("%s 缩放已保存 (%.2f)，将在下次加载时生效", frameKey, scale))
    end
end

-- 颜色命令处理
function EUF:CommandColor(args)
    if args == "on" or args == "true" or args == "1" then
        self.Database:Set(true, "classColors", "enabled")
        self:Print("职业染色已 |cFF00FF00开启|r")

    elseif args == "off" or args == "false" or args == "0" then
        self.Database:Set(false, "classColors", "enabled")
        self:Print("职业染色已 |cFFFF0000关闭|r")

    else
        local current = self.Database:Get("classColors", "enabled")
        self:Print("职业染色状态:", current and "|cFF00FF00开启|r" or "|cFFFF0000关闭|r")
    end

    -- 如果 ClassColors 模块存在，更新状态
    if self.ClassColors then
        self.ClassColors:Refresh()
    end
end

-- 小地图按钮命令处理
function EUF:CommandMinimap(args)
    if args == "show" then
        if self.MinimapButton then
            self.MinimapButton:Show()
            self:Print("小地图按钮已显示")
        end
    elseif args == "hide" then
        if self.MinimapButton then
            self.MinimapButton:Hide()
        end
    elseif args == "reset" then
        if self.MinimapButton then
            self.MinimapButton:ResetPosition()
            self:Print("小地图按钮位置已重置")
        end
    else
        self:Print("用法: /euf minimap [show|hide|reset]")
    end
end

-- 打开设置面板
function EUF:OpenConfig()
    if self.OptionsPanel then
        self.OptionsPanel:Open()
    else
        self:Print("设置面板模块未加载")
    end
end

-- 设置启用状态
function EUF:SetEnabled(enabled)
    self.Database:SetGlobal("enableAddon", enabled)

    if enabled then
        self:OnEnable()
    else
        self:OnDisable()
    end
end

-- 显示状态
function EUF:ShowStatus()
    local status = {
        "=== EnhancedUnitFrames 状态 ===",
        "版本: " .. self.VERSION_DISPLAY,
        "状态: " .. (self.enabled and "|cFF00FF00启用|r" or "|cFFFF0000禁用|r"),
        "调试模式: " .. (self.debugMode and "|cFF00FF00开启|r" or "|cFFFF0000关闭|r"),
        "职业染色: " .. (self.Database:Get("classColors", "enabled") and "|cFF00FF00开启|r" or "|cFFFF0000关闭|r"),
        string.format("玩家缩放: %.2f", self.Database:GetScale("player")),
        string.format("目标缩放: %.2f", self.Database:GetScale("target")),
        "待处理操作: " .. #self.pendingOperations,
    }

    for _, line in ipairs(status) do
        self:Print(line)
    end
end

-------------------------------------------------------------------------------
-- 工具函数代理
-------------------------------------------------------------------------------

-- 打印消息
function EUF:Print(msg)
    self.Utils.Print(msg)
end

-- 调试打印
function EUF:Debug(msg, ...)
    self.Utils.DebugPrint(msg, ...)
end

-------------------------------------------------------------------------------
-- 框架加载时自动初始化
-------------------------------------------------------------------------------

-- 使用 ADDON_LOADED 事件初始化基础设置
-- 使用 PLAYER_LOGIN 事件启用功能模块
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")

initFrame:SetScript("OnEvent", function(frame, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        -- 基础初始化（数据库、命令注册等）
        EUF:OnInitialize()
    elseif event == "PLAYER_LOGIN" then
        -- 玩家登录后启用功能模块
        -- 此时暴雪框体已经完全加载
        frame:UnregisterEvent("PLAYER_LOGIN")
        EUF:OnEnable()
    end
end)

return EUF