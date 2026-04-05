# EnhancedUnitFrames 插件开发规划书

> **目标**：开发一款增强型单位框体插件，在暴雪官方 PlayerFrame 和 TargetFrame 基础上提供职业染色、框体大小调整、材质自定义、文字配置等功能，并支持通过编辑模式（Edit Mode）进行控制。

> **目标版本**：WoW 12.0 (Midnight)

---

## 零、12.0 版本重大变更：必须理解的核心限制

### 0.1 Secret Value 系统（机密值系统）

12.0 版本引入了革命性的 **Secret Value** 机制，这是暴雪"插件裁军"（Addon Disarmament）政策的核心技术实现。

**核心理念**：
> 战斗状态信息被标记为"机密值"，插件可以**显示**这些信息，但无法"知道"（处理/计算）它们。战斗事件被放入黑盒，插件可以改变盒子的大小、形状和颜色，但无法窥视盒子内部。

**技术实现**：
```lua
-- 12.0 之前：API 返回可直接处理的数据
local health = UnitHealth("target")  -- 返回具体数值，如 150000
local maxHealth = UnitHealthMax("target")  -- 返回具体数值，如 200000
local percent = (health / maxHealth) * 100  -- 可以计算百分比

-- 12.0 之后：在竞技性战斗中返回"机密值"
local health = UnitHealth("target")
-- 在团本/大秘境/PVP中，health 可能返回一个无法用于计算的"机密对象"
-- 任何算术运算、比较运算都会导致错误或返回 nil
```

### 0.2 12.0 对单位框体插件的影响

| 影响维度 | 具体变化 | 应对策略 |
|----------|----------|----------|
| **生命值/能量显示** | `UnitHealth`/`UnitPower` 在战斗中返回机密值 | 使用暴雪原生 StatusBar 组件自动处理，不自行计算 |
| **职业颜色** | `UnitClass` 在某些场景返回机密值 | 使用 `C_ClassColor.GetClassColor()` + 暴雪提供的非机密API |
| **文本格式化** | 无法对机密值进行算术运算 | 使用暴雪原生格式化函数，避免自定义计算 |
| **框体缩放** | Secure Frame 限制更严格 | 必须使用属性驱动(Attribute-Driven)，禁止直接方法调用 |
| **Hook 机制** | 直接 Hook Secure 模板会触发 Taint | 必须使用 `hooksecurefunc` 后钩或 `WrapScript` 安全包装 |

### 0.3 12.0 允许的插件行为（白名单）

根据暴雪官方声明，以下功能**仍然可行**：

- ✅ **视觉自定义**：改变框体大小、形状、位置、材质、字体、颜色
- ✅ **信息呈现**：以不同方式展示 UI 已显示的战斗信息
- ✅ **Edit Mode 集成**：通过官方 Edit Mode API 控制框体布局
- ✅ **非战斗数据处理**：脱战后仍可完全访问所有数据
- ✅ **外观主题**：皮肤、边框、动画效果等纯视觉元素

### 0.4 12.0 禁止的插件行为（黑名单）

- ❌ **战斗决策自动化**：基于战斗数据自动判断并执行动作
- ❌ **计算最优循环**：实时计算并提示最优技能序列
- ❌ **敌人信息简化**：重命名怪物为"治疗者"、技能为"正面攻击"等
- ❌ **直接修改 Secure 属性**：在战斗中调用 `Show()`/`Hide()`/`SetScale()` 等方法

---

## 一、项目概述

### 1.1 插件定位

| 维度 | 说明 |
|------|------|
| **核心定位** | 视觉增强型插件（Visual Enhancement），符合12.0"插件裁军"政策 |
| **技术路线** | 安全后钩（Safe Post-Hook）+ 属性驱动（Attribute-Driven）+ 暴雪原生渲染 |
| **兼容性** | WoW 12.0 (Midnight)，TOC 版本 120000 |
| **依赖** | 无硬性依赖，可选 LibSharedMedia-3.0 提供材质扩展 |

### 1.2 核心原则：12.0 合规性设计

```lua
-- ⚠️ 12.0 核心开发原则

-- 原则 1: 永远不要对 UnitHealth/UnitPower 的返回值进行算术运算
-- ❌ 错误
local percent = (UnitHealth("target") / UnitHealthMax("target")) * 100

-- ✅ 正确：让暴雪原生组件处理计算
TargetFrameHealthBar:SetValue(UnitHealth("target"))  -- StatusBar 内部安全处理

-- 原则 2: 使用 Secure Template 继承而非自定义实现
-- ❌ 错误：自己创建按钮逻辑
local button = CreateFrame("Button")
button:SetScript("OnClick", function() ... end)

-- ✅ 正确：继承暴雪安全模板
local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")

-- 原则 3: 属性驱动而非方法调用
-- ❌ 错误：战斗中调用方法
if shouldShow then frame:Show() else frame:Hide() end

-- ✅ 正确：通过属性控制
frame:SetAttribute("statehidden", not shouldShow)

-- 原则 4: 安全后钩而非前钩
-- ❌ 错误：前钩可能污染参数
local original = frame.SetScript
frame.SetScript = function(self, ...) ... end

-- ✅ 正确：使用 hooksecurefunc 后钩
hooksecurefunc(frame, "SetScript", function(self, ...) ... end)
```

### 1.3 核心功能矩阵

| 功能模块 | 描述 | 优先级 | 12.0 兼容性 |
|----------|------|--------|-------------|
| 职业色染色 | 根据单位职业自动着色生命条/边框 | P0 | ✅ 完全兼容（使用非机密API） |
| 框体缩放 | 自定义 PlayerFrame / TargetFrame 尺寸 | P0 | ✅ 兼容（需属性驱动） |
| 材质替换 | 自定义生命条、法力条、背景材质 | P1 | ✅ 完全兼容（纯视觉） |
| 文字配置 | 自定义名称、生命值、法力值的字体/大小/位置 | P1 | ⚠️ 部分限制（避免自定义计算） |
| Edit Mode 集成 | 在暴雪编辑模式中提供配置入口 | P0 | ✅ 完全兼容 |
| 配置持久化 | SavedVariables 保存用户设置 | P0 | ✅ 完全兼容 |

---

## 二、技术架构设计

### 2.1 目录结构

```
EnhancedUnitFrames/
├── EnhancedUnitFrames.toc          # 插件描述文件 (TOC 120000)
├── Core/
│   ├── Core.lua                    # 核心初始化与事件管理
│   ├── Database.lua                # SavedVariables 管理与默认值
│   ├── Utils.lua                   # 工具函数（SafeNumber/SafeText等）
│   └── SecretSafe.lua              # 12.0 机密值安全处理层
├── Modules/
│   ├── ClassColors.lua             # 职业色系统（12.0合规）
│   ├── FrameScale.lua              # 框体缩放模块（属性驱动）
│   ├── Textures.lua                # 材质管理模块
│   └── TextSettings.lua            # 文字配置模块（限制性实现）
├── Integration/
│   ├── EditMode.lua                # Edit Mode 集成
│   └── BlizzardHooks.lua           # 暴雪框体安全后钩
├── GUI/
│   └── OptionsPanel.lua            # 设置界面（Settings API）
├── Media/
│   └── Textures/                   # 内置材质文件
│       ├── statusbar_flat.tga
│       ├── statusbar_gradient.tga
│       └── border_rounded.tga
└── Libs/
    └── LibSharedMedia-3.0/        # 可选：材质库
```

### 2.2 12.0 架构核心：安全层设计

```
┌─────────────────────────────────────────────────────────────┐
│                     用户配置层                               │
│  (OptionsPanel / Edit Mode / SavedVariables)                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  SecretSafe.lua 安全层                       │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │  SafeNumber()   │  │  SafeText()     │                   │
│  │  IsSecretValue()│  │  SafeAPICall()  │                   │
│  └─────────────────┘  └─────────────────┘                   │
│  职责：拦截所有可能触发机密值错误的操作                        │
└────────────────────────┬────────────────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌───────────┐
    │ClassColors│   │FrameScale│   │ Textures  │
    │(非机密API)│   │(属性驱动) │   │ (纯视觉)  │
    └──────────┘   └──────────┘   └───────────┘
          │              │              │
          └──────────────┼──────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                BlizzardHooks.lua 安全后钩层                   │
│  hooksecurefunc() / HookScript() / WrapScript()             │
│  职责：在不污染暴雪代码的前提下注入自定义逻辑                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   暴雪原生框体系统                            │
│  PlayerFrame / TargetFrame / FocusFrame / etc.              │
│  (所有核心渲染由暴雪代码处理，插件仅修改视觉属性)               │
└─────────────────────────────────────────────────────────────┘
```

---

## 三、暴雪官方 API 技术规范（12.0）

### 3.1 关键 API 变更（11.0 → 12.0）

#### 3.1.1 机密值处理 API

```lua
-- 判断值是否为机密值（12.0 新增）
local isSecret = IsSecretValue(value)

-- 安全数值处理（避免对机密值进行算术运算）
local safeNumber = SafeNumber(value, fallback)
-- 返回：如果是机密值则返回 fallback，否则返回原值

-- 安全文本处理
local safeText = SafeText(value, fallback)
-- 返回：如果是机密值则返回 fallback，否则返回 tostring(value)

-- 安全 API 调用包装
local success, result = SafeAPICall(func, ...)
-- 返回：pcall 包装，捕获机密值错误
```

#### 3.1.2 单位信息 API（12.0 状态）

```lua
-- ⚠️ 在战斗/团本/大秘境/PVP 中返回机密值
UnitHealth("unit")        -- 可能返回机密值
UnitHealthMax("unit")     -- 可能返回机密值
UnitPower("unit")         -- 可能返回机密值
UnitPowerMax("unit")      -- 可能返回机密值

-- ✅ 非机密 API（可在任何场景安全使用）
UnitExists("unit")        -- 返回布尔值
UnitIsPlayer("unit")      -- 返回布尔值
UnitIsUnit("unit1", "unit2")  -- 返回布尔值
UnitName("unit")          -- 在非竞技场景返回名称
UnitClassification("unit") -- 返回 elite/rare 等（非机密）
UnitReaction("unit", "otherUnit")  -- 返回反应类型（非机密）

-- ✅ 职业颜色 API（非机密）
local color = C_ClassColor.GetClassColor(classToken)
-- 返回 ColorMixin 对象，可直接用于 SetVertexColor

-- ✅ GUID 相关（非机密）
local guid = UnitGUID("unit")
local classToken = select(2, GetPlayerInfoByGUID(guid))
```

#### 3.1.3 StatusBar 安全操作（12.0 推荐）

```lua
-- ✅ 正确：让暴雪原生 StatusBar 处理机密值
-- StatusBar 内部使用安全代码，可以正确处理机密值
healthBar:SetMinMaxValues(0, UnitHealthMax("target"))
healthBar:SetValue(UnitHealth("target"))

-- ⚠️ 如果需要获取百分比的显示（而非计算）
-- 使用暴雪内置的文本格式化，不要自己计算
hooksecurefunc("TextStatusBar_UpdateTextString", function(statusBar)
    -- 暴雪已经处理好了文本显示
    -- 我们只需要修改样式，不要重新计算
end)
```

#### 3.1.4 Edit Mode API（12.0 更新）

```lua
-- C_EditMode 命名空间核心函数（12.0 仍有效）

-- 获取当前布局
C_EditMode.GetLayouts() -- 返回布局信息表

-- 保存布局
C_EditMode.SaveLayouts()

-- 设置活动布局
C_EditMode.SetActiveLayout(layoutIndex)

-- 获取/设置账户设置
C_EditMode.GetAccountSettings()
C_EditMode.SetAccountSetting(setting, value)

-- ⚠️ 12.0 新增：单位框体系统设置常量
Enum.EditModeSystem.UnitFrame = 3

-- 布局设置项（需通过 GetLayouts 获取实际索引）
-- PlayerFrame Size: setting ID 可能在运行时动态分配
-- 建议通过遍历 systems 查找
```

#### 3.1.5 Settings API（12.0 推荐）

```lua
-- 注册设置面板（垂直布局模式）- 12.0 推荐方式
local category = Settings.RegisterVerticalLayoutCategory("Enhanced Unit Frames")

-- 注册设置项
local setting = Settings.RegisterAddOnSetting(
    category,
    "displayName",      -- 设置显示名称
    "variableName",     -- 变量名
    MyAddonDB,          -- 存储表
    type(defaultValue), -- 值类型 ("boolean", "number", "string")
    defaultValue        -- 默认值
)

-- 创建控件
Settings.CreateCheckBox(category, setting, "tooltipText")

local sliderOptions = Settings.CreateSliderOptions(minValue, maxValue, step)
sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
Settings.CreateSlider(category, setting, sliderOptions, "tooltipText")

Settings.CreateDropDown(category, setting, getOptionsFunc, "tooltipText")

-- 注册到插件设置
Settings.RegisterAddOnCategory(category)

-- 设置变更回调
Settings.SetOnValueChangedCallback("variableName", function(_, setting, value)
    -- 处理设置变更
end)
```

### 3.2 暴雪框体结构（需 Hook 的目标）

#### 3.2.1 PlayerFrame 结构（12.0）

```lua
PlayerFrame
├── PlayerFrameHealthBar          -- 生命条（StatusBar）
│   ├── PlayerFrameHealthBarText  -- 生命值文字
│   └── PlayerFrameHealthBarTextLeft
├── PlayerFrameManaBar            -- 法力条（StatusBar）
│   ├── PlayerFrameManaBarText    -- 法力值文字
│   └── PlayerFrameManaBarTextLeft
├── PlayerFrameTexture            -- 框体背景材质
├── PlayerNameText                -- 名称文字
├── PlayerPortrait                -- 头像
└── PlayerFrameGroupIndicator     -- 队伍指示器
```

#### 3.2.2 TargetFrame 结构（12.0）

```lua
TargetFrame
├── TargetFrameHealthBar
│   ├── TargetFrameHealthBarText
│   └── TargetFrameTextureDeadDead
├── TargetFrameManaBar
│   └── TargetFrameManaBarText
├── TargetFrameTextureFrame
│   └── TargetFrameTexture
├── TargetFrameNameBackground
├── TargetNameText (或 TargetFrame.Name)
├── TargetPortrait
└── TargetFrameToT                -- Target of Target
```

### 3.3 战斗锁定机制（12.0 增强）

```lua
-- 12.0 战斗锁定限制更加严格
-- 以下操作在战斗中完全禁止：

-- ❌ 创建/删除框体
-- ❌ 修改框体大小、位置
-- ❌ 设置缩放比例（即使是 Secure Frame）
-- ❌ 修改 secure frame 属性
-- ❌ 调用 Show()/Hide() 方法
-- ❌ 重新锚定框体

-- 安全检查函数
local function CanModifyFrame()
    return not InCombatLockdown()
end

-- 12.0 推荐：使用属性驱动系统
local function SafeSetHidden(frame, hidden)
    if InCombatLockdown() then
        -- 战斗中：设置属性，让 Secure 系统处理
        if frame.SetAttribute then
            frame:SetAttribute("statehidden", hidden)
        end
    else
        -- 非战斗：直接方法调用
        frame:SetShown(not hidden)
    end
end
```

---

## 四、核心模块详细设计（12.0 合规版）

### 4.1 机密值安全处理层（SecretSafe.lua）⭐新增

```lua
-- SecretSafe.lua
-- 12.0 版本核心安全层：处理所有可能与机密值交互的操作

local SecretSafe = {}

-- 判断值是否为机密值
function SecretSafe.IsSecretValue(value)
    if value == nil then return false end
    
    -- 机密值通常是 userdata 类型
    if type(value) == "userdata" then
        return true
    end
    
    -- 检查是否实现了机密值的特殊方法
    if type(value) == "table" and value.IsSecret then
        return value:IsSecret()
    end
    
    return false
end

-- 安全数值获取
function SecretSafe.SafeNumber(value, fallback)
    fallback = fallback or 0
    if SecretSafe.IsSecretValue(value) then
        return fallback
    end
    local num = tonumber(value)
    return num or fallback
end

-- 安全文本获取
function SecretSafe.SafeText(value, fallback)
    fallback = fallback or ""
    if SecretSafe.IsSecretValue(value) then
        return fallback
    end
    return tostring(value)
end

-- 安全 API 调用包装
function SecretSafe.SafeAPICall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        -- 记录错误但不中断执行
        return false, nil
    end
    return true, result
end

-- 安全颜色获取（专门用于职业色）
function SecretSafe.SafeGetClassColor(unit)
    -- 方法 1: 通过 GUID 获取职业（非机密）
    local guid = UnitGUID(unit)
    if guid then
        local _, classToken = GetPlayerInfoByGUID(guid)
        if classToken then
            local color = C_ClassColor.GetClassColor(classToken)
            if color then
                return color.r, color.g, color.b, color.colorStr
            end
        end
    end
    
    -- 方法 2: 通过 UnitClass 获取（某些场景可能返回机密）
    local success, _, classToken = SecretSafe.SafeAPICall(UnitClass, unit)
    if success and classToken then
        local color = C_ClassColor.GetClassColor(classToken)
        if color then
            return color.r, color.g, color.b, color.colorStr
        end
    end
    
    -- 默认白色
    return 1, 1, 1, "ffffffff"
end

-- 安全反应色获取（NPC 用）
function SecretSafe.SafeGetReactionColor(unit)
    local reaction = UnitReaction(unit, "player")
    if reaction then
        -- 使用暴雪预定义的反应色
        local colors = {
            [1] = {1, 0, 0},       -- 敌对（红）
            [2] = {1, 0, 0},       -- 仇恨（红）
            [3] = {1, 0.5, 0},     -- 不友好（橙）
            [4] = {1, 1, 0},       -- 中立（黄）
            [5] = {0.5, 1, 0},     -- 友好（绿黄）
            [6] = {0, 1, 0},       -- 友善（绿）
            [7] = {0, 1, 0},       -- 尊敬（绿）
            [8] = {0, 1, 0},       -- 崇拜（绿）
        }
        local c = colors[reaction] or {1, 1, 1}
        return c[1], c[2], c[3], "ffffffff"
    end
    return 1, 1, 1, "ffffffff"
end

-- 安全百分比计算（避免直接算术）
-- ⚠️ 12.0 推荐做法：使用暴雪原生格式化
function SecretSafe.SafeGetHealthPercent(unit)
    -- 方法 1: 从 StatusBar 获取（如果已设置）
    local frame = unit == "player" and PlayerFrameHealthBar or TargetFrameHealthBar
    if frame then
        local min, max = frame:GetMinMaxValues()
        local value = frame:GetValue()
        if min and max and value and max > 0 then
            return (value / max) * 100
        end
    end
    
    -- 方法 2: 尝试直接获取（可能失败）
    local success, health = SecretSafe.SafeAPICall(UnitHealth, unit)
    local success2, maxHealth = SecretSafe.SafeAPICall(UnitHealthMax, unit)
    
    if success and success2 then
        health = SecretSafe.SafeNumber(health, 0)
        maxHealth = SecretSafe.SafeNumber(maxHealth, 1)
        if maxHealth > 0 then
            return (health / maxHealth) * 100
        end
    end
    
    return nil  -- 无法获取，让调用者决定 fallback
end

return SecretSafe
```

### 4.2 职业色系统（ClassColors.lua）- 12.0 合规版

```lua
-- ClassColors.lua
-- 12.0 合规的职业色系统：使用非机密 API 获取颜色信息

local addonName, EUF = ...
local SecretSafe = EUF.SecretSafe

local ClassColors = {}
EUF.ClassColors = ClassColors

-- 初始化
function ClassColors:Initialize(db)
    self.db = db.classColors
    self:HookHealthBarUpdate()
end

-- 判断单位是否应该染色
function ClassColors:ShouldColorUnit(unit)
    if not UnitExists(unit) then return false end
    if not self.db.enabled then return false end
    
    -- 玩家单位：职业色
    -- NPC 单位：反应色（如果启用）
    return true
end

-- 获取单位应显示的颜色（12.0 安全版）
function ClassColors:GetUnitColor(unit)
    if UnitIsPlayer(unit) then
        -- 使用 GUID 方式获取职业色（非机密路径）
        return SecretSafe.SafeGetClassColor(unit)
    else
        -- NPC 使用反应色
        if self.db.colorNPCByReaction then
            return SecretSafe.SafeGetReactionColor(unit)
        end
    end
    
    return 1, 1, 1, "ffffffff"
end

-- 应用颜色到生命条（安全方式）
function ClassColors:ApplyToHealthBar(healthBar, unit)
    if not healthBar then return end
    
    local r, g, b, colorStr = self:GetUnitColor(unit)
    
    -- 12.0 安全操作：SetStatusBarColor 是允许的
    -- 因为这只是修改视觉属性，不涉及数据处理
    healthBar:SetStatusBarColor(r, g, b)
    
    -- 如果启用背景染色
    if self.db.colorBackground then
        local bg = healthBar.bg
        if bg then
            bg:SetVertexColor(r * 0.3, g * 0.3, b * 0.3, 0.5)
        end
    end
    
    -- 边框染色
    if self.db.colorBorder and healthBar.border then
        healthBar.border:SetVertexColor(r, g, b)
    end
end

-- Hook 暴雪原生更新函数（安全后钩）
function ClassColors:HookHealthBarUpdate()
    -- ✅ 使用 hooksecurefunc 后钩（不污染原始参数）
    
    -- Hook PlayerFrame 生命条颜色
    hooksecurefunc("PlayerFrame_Update", function()
        if self:ShouldColorUnit("player") then
            self:ApplyToHealthBar(PlayerFrameHealthBar, "player")
        end
    end)
    
    -- Hook TargetFrame 生命条颜色
    hooksecurefunc("TargetFrame_Update", function()
        if UnitExists("target") and self:ShouldColorUnit("target") then
            self:ApplyToHealthBar(TargetFrameHealthBar, "target")
        end
    end)
    
    -- Hook FocusFrame（如果存在）
    if FocusFrame then
        hooksecurefunc("FocusFrame_Update", function()
            if UnitExists("focus") and self:ShouldColorUnit("focus") then
                self:ApplyToHealthBar(FocusFrameHealthBar, "focus")
            end
        end)
    end
    
    -- 监听目标切换事件
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    eventFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
    eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_TARGET_CHANGED" then
            if UnitExists("target") and self:ShouldColorUnit("target") then
                self:ApplyToHealthBar(TargetFrameHealthBar, "target")
            end
        elseif event == "PLAYER_FOCUS_CHANGED" then
            if UnitExists("focus") and self:ShouldColorUnit("focus") then
                self:ApplyToHealthBar(FocusFrameHealthBar, "focus")
            end
        end
    end)
end

return ClassColors
```

### 4.3 框体缩放模块（FrameScale.lua）- 12.0 属性驱动版

```lua
-- FrameScale.lua
-- 12.0 合规的框体缩放：属性驱动 + 非战斗时设置

local addonName, EUF = ...

local FrameScale = {}
EUF.FrameScale = FrameScale

-- 缩放范围
FrameScale.MIN_SCALE = 0.5
FrameScale.MAX_SCALE = 2.0
FrameScale.DEFAULT_SCALE = 1.0

-- 初始化
function FrameScale:Initialize(db)
    self.db = db.scales
    self.pendingScales = {}
    self.frames = {
        player = PlayerFrame,
        target = TargetFrame,
        focus = FocusFrame,
        pet = PetFrame,
    }
    
    -- 保存原始尺寸用于计算
    self.originalSizes = {}
    for key, frame in pairs(self.frames) do
        if frame then
            self.originalSizes[key] = {
                width = frame:GetWidth(),
                height = frame:GetHeight(),
            }
        end
    end
    
    -- 注册战斗结束事件
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            self:ProcessPendingScales()
        elseif event == "PLAYER_LOGIN" then
            self:ApplySavedScales()
        end
    end)
end

-- 设置框体缩放（12.0 安全版）
function FrameScale:SetFrameScale(frameKey, scale)
    -- 参数验证
    scale = tonumber(scale) or self.DEFAULT_SCALE
    scale = math.max(self.MIN_SCALE, math.min(self.MAX_SCALE, scale))
    
    local frame = self.frames[frameKey]
    if not frame then return end
    
    -- 12.0 关键：检查战斗状态
    if InCombatLockdown() then
        -- 战斗中：加入待处理队列
        -- ⚠️ 12.0 中，即使是属性驱动的方式也不能在战斗中修改缩放
        -- 只能排队等待战斗结束
        self.pendingScales[frameKey] = scale
        return
    end
    
    -- 非战斗：直接应用
    self:ApplyScale(frame, scale)
    
    -- 保存设置
    self.db[frameKey] = scale
end

-- 实际应用缩放
function FrameScale:ApplyScale(frame, scale)
    if not frame or InCombatLockdown() then return end
    
    -- 保存当前锚点信息
    local point, relativeTo, relativePoint, x, y
    if frame.GetPoint then
        point, relativeTo, relativePoint, x, y = frame:GetPoint()
    end
    
    -- 设置缩放
    frame:SetScale(scale)
    
    -- 恢复锚点（缩放可能导致位置偏移）
    if point then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x or 0, y or 0)
    end
end

-- 应用已保存的缩放（登录时）
function FrameScale:ApplySavedScales()
    if InCombatLockdown() then return end
    
    for frameKey, scale in pairs(self.db) do
        local frame = self.frames[frameKey]
        if frame and scale then
            self:ApplyScale(frame, scale)
        end
    end
end

-- 处理待执行的缩放
function FrameScale:ProcessPendingScales()
    -- 再次检查战斗状态
    if InCombatLockdown() then return end
    
    for frameKey, scale in pairs(self.pendingScales) do
        local frame = self.frames[frameKey]
        if frame then
            self:ApplyScale(frame, scale)
            self.db[frameKey] = scale
        end
    end
    self.pendingScales = {}
end

-- 恢复默认缩放
function FrameScale:ResetToDefault(frameKey)
    self:SetFrameScale(frameKey, self.DEFAULT_SCALE)
end

-- 获取当前缩放
function FrameScale:GetFrameScale(frameKey)
    local frame = self.frames[frameKey]
    if frame then
        return frame:GetScale()
    end
    return self.DEFAULT_SCALE
end

return FrameScale
```

### 4.4 材质管理模块（Textures.lua）- 12.0 纯视觉版

```lua
-- Textures.lua
-- 12.0 材质管理：纯视觉修改，不涉及数据处理

local addonName, EUF = ...

local Textures = {}
EUF.Textures = Textures

-- 内置材质路径
Textures.BUILTIN_TEXTURES = {
    ["Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
    ["Flat"] = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\statusbar_flat.tga",
    ["Gradient"] = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\statusbar_gradient.tga",
}

-- 边框样式
Textures.BORDER_STYLES = {
    ["None"] = "无",
    ["Rounded"] = "圆角",
    ["Square"] = "方形",
    ["Blizzard"] = "暴雪默认",
}

-- 初始化
function Textures:Initialize(db)
    self.db = db.textures
    self.textureCache = {}
    
    -- 尝试加载 LibSharedMedia（如果存在）
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        self:LoadSharedMedia(LSM)
    end
end

-- 加载 LibSharedMedia 材质
function Textures:LoadSharedMedia(LSM)
    local statusBars = LSM:List("statusbar")
    for _, name in ipairs(statusBars) do
        local path = LSM:Fetch("statusbar", name, true)
        if path and path ~= "" then
            self.BUILTIN_TEXTURES[name] = path
        end
    end
end

-- 获取材质路径
function Textures:GetTexturePath(textureName)
    return self.BUILTIN_TEXTURES[textureName] or self.BUILTIN_TEXTURES["Blizzard"]
end

-- 应用材质到状态条（12.0 安全操作）
function Textures:ApplyToStatusBar(statusBar, textureName)
    if not statusBar then return end
    
    local texturePath = self:GetTexturePath(textureName)
    
    -- SetStatusBarTexture 是纯视觉操作，12.0 允许
    statusBar:SetStatusBarTexture(texturePath)
    
    -- 保存当前设置
    if self.db then
        self.db.healthBar = textureName
    end
end

-- 应用材质到框体背景
function Textures:ApplyToFrameBackground(frame, textureName, alpha)
    if not frame then return end
    alpha = alpha or 1.0
    
    -- 创建或获取背景纹理
    local bg = frame.enhancedBG
    if not bg then
        bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(frame)
        frame.enhancedBG = bg
    end
    
    local texturePath = self:GetTexturePath(textureName)
    bg:SetTexture(texturePath)
    bg:SetAlpha(alpha)
end

-- 应用边框（12.0 安全版）
function Textures:ApplyBorder(frame, borderStyle, r, g, b, a)
    if not frame then return end
    
    -- 移除旧边框
    if frame.enhancedBorder then
        frame.enhancedBorder:Hide()
        frame.enhancedBorder = nil
    end
    
    if borderStyle == "None" then return end
    
    -- 创建新边框（使用 BackdropTemplate，12.0 推荐）
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetAllPoints(frame)
    
    local edgeFile, edgeSize
    if borderStyle == "Rounded" then
        edgeFile = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\border_rounded.tga"
        edgeSize = 12
    elseif borderStyle == "Square" then
        edgeFile = "Interface\\Buttons\\WHITE8x8"
        edgeSize = 1
    elseif borderStyle == "Blizzard" then
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"
        edgeSize = 16
    end
    
    if edgeFile then
        border:SetBackdrop({
            edgeFile = edgeFile,
            edgeSize = edgeSize,
        })
        
        -- 设置边框颜色
        border:SetBackdropBorderColor(r or 1, g or 1, b or 1, a or 1)
    end
    
    frame.enhancedBorder = border
end

-- 应用所有材质设置
function Textures:ApplyAllSettings()
    -- 应用到玩家框体
    if self.db then
        self:ApplyToStatusBar(PlayerFrameHealthBar, self.db.healthBar)
        self:ApplyToStatusBar(PlayerFrameManaBar, self.db.manaBar or self.db.healthBar)
        
        -- 应用边框
        self:ApplyBorder(PlayerFrame, self.db.border)
        
        -- 应用到目标框体
        self:ApplyToStatusBar(TargetFrameHealthBar, self.db.healthBar)
        self:ApplyToStatusBar(TargetFrameManaBar, self.db.manaBar or self.db.healthBar)
        self:ApplyBorder(TargetFrame, self.db.border)
    end
end

-- 获取可用材质列表（用于下拉菜单）
function Textures:GetTextureList()
    local list = {}
    for name, _ in pairs(self.BUILTIN_TEXTURES) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

-- 获取边框样式列表
function Textures:GetBorderStyleList()
    local list = {}
    for style, name in pairs(self.BORDER_STYLES) do
        table.insert(list, {value = style, text = name})
    end
    return list
end

return Textures
```

### 4.5 文字配置模块（TextSettings.lua）- 12.0 限制版

```lua
-- TextSettings.lua
-- 12.0 文字配置：限制性实现，避免自定义计算

local addonName, EUF = ...
local SecretSafe = EUF.SecretSafe

local TextSettings = {}
EUF.TextSettings = TextSettings

-- 字体定义
TextSettings.FONTS = {
    ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
    ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
    ["Skurri"] = "Fonts\\SKURRI.TTF",
    ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
}

-- 12.0 支持的文字格式（使用暴雪内置格式）
TextSettings.HEALTH_FORMATS = {
    ["DEFAULT"] = "暴雪默认",           -- 让暴雪处理
    ["PERCENT"] = "百分比",              -- 需要暴雪 API 支持
    ["CURRENT"] = "当前值",              -- 可能受机密值限制
    ["CURRENT/MAX"] = "当前/最大",       -- 可能受机密值限制
    ["DEFICIT"] = "亏损值",              -- 可能受机密值限制
    ["HIDDEN"] = "隐藏",                 -- 直接隐藏文字
}

-- 初始化
function TextSettings:Initialize(db)
    self.db = db.text
    self.originalSettings = {}
end

-- 设置字体（12.0 安全操作）
function TextSettings:SetFont(fontString, fontName, fontSize, fontFlags)
    if not fontString then return end
    
    local fontPath = self.FONTS[fontName] or self.FONTS["Friz Quadrata TT"]
    fontSize = tonumber(fontSize) or 12
    fontFlags = fontFlags or ""
    
    -- SetFont 是纯视觉操作，12.0 允许
    fontString:SetFont(fontPath, fontSize, fontFlags)
end

-- 设置文字颜色（12.0 安全操作）
function TextSettings:SetTextColor(fontString, r, g, b, a)
    if not fontString then return end
    fontString:SetTextColor(r or 1, g or 1, b or 1, a or 1)
end

-- 设置文字位置（12.0 安全操作）
function TextSettings:SetTextPosition(fontString, point, relativeTo, relativePoint, x, y)
    if not fontString then return end
    fontString:ClearAllPoints()
    fontString:SetPoint(point, relativeTo, relativePoint, x or 0, y or 0)
end

-- ⚠️ 12.0 限制：文字格式化
-- 在 12.0 中，我们无法安全地对生命值进行自定义格式化
-- 推荐做法：
-- 1. 使用暴雪默认格式（最安全）
-- 2. 如果用户坚持自定义格式，尝试使用暴雪提供的格式化工具
-- 3. 如果格式化失败（机密值），回退到暴雪默认

function TextSettings:SetHealthTextFormat(unit, formatType)
    -- 保存设置
    if not self.db.formats[unit] then
        self.db.formats[unit] = {}
    end
    self.db.formats[unit].health = formatType
    
    -- 获取对应的文字对象
    local fontString
    if unit == "player" then
        fontString = PlayerFrameHealthBarText
    elseif unit == "target" then
        fontString = TargetFrameHealthBarText
    end
    
    if not fontString then return end
    
    if formatType == "HIDDEN" then
        fontString:Hide()
        return
    end
    
    fontString:Show()
    
    -- 对于其他格式，我们 Hook 暴雪的更新函数
    -- 尝试使用我们注册的自定义格式化器
    self:HookTextFormatter(unit, formatType, fontString)
end

-- Hook 文字格式化器（12.0 限制版）
function TextSettings:HookTextFormatter(unit, formatType, fontString)
    -- 如果是默认格式，不需要 Hook
    if formatType == "DEFAULT" then
        return
    end
    
    -- 对于自定义格式，我们需要 Hook 暴雪的更新函数
    -- ⚠️ 这里我们只能尽力而为，如果遇到机密值就放弃自定义格式
    
    local updateFunc
    if unit == "player" then
        updateFunc = "PlayerFrame_UpdateHealthText"
    elseif unit == "target" then
        updateFunc = "TargetFrame_UpdateHealthText"
    end
    
    if not updateFunc then return end
    
    -- 使用安全后钩
    hooksecurefunc(updateFunc, function()
        if self.db.formats[unit].health ~= formatType then return end
        
        -- 尝试获取生命值
        local success, health = SecretSafe.SafeAPICall(UnitHealth, unit)
        local success2, maxHealth = SecretSafe.SafeAPICall(UnitHealthMax, unit)
        
        if not success or not success2 then
            -- 遇到机密值，保持暴雪默认显示
            return
        end
        
        health = SecretSafe.SafeNumber(health, 0)
        maxHealth = SecretSafe.SafeNumber(maxHealth, 1)
        
        local text = ""
        if formatType == "PERCENT" then
            if maxHealth > 0 then
                text = string.format("%.0f%%", (health / maxHealth) * 100)
            end
        elseif formatType == "CURRENT" then
            text = AbbreviateNumbers(health)
        elseif formatType == "CURRENT/MAX" then
            text = string.format("%s / %s", AbbreviateNumbers(health), AbbreviateNumbers(maxHealth))
        elseif formatType == "DEFICIT" then
            local deficit = maxHealth - health
            if deficit > 0 then
                text = "-" .. AbbreviateNumbers(deficit)
            end
        end
        
        if text ~= "" then
            fontString:SetText(text)
        end
    end)
end

-- 应用所有文字设置
function TextSettings:ApplyAllSettings()
    if not self.db then return end
    
    -- 应用字体设置
    for unit, settings in pairs(self.db.fonts or {}) do
        local nameFont, healthFont, manaFont
        if unit == "player" then
            nameFont = PlayerNameText
            healthFont = PlayerFrameHealthBarText
            manaFont = PlayerFrameManaBarText
        elseif unit == "target" then
            nameFont = TargetFrame.Name or TargetNameText
            healthFont = TargetFrameHealthBarText
            manaFont = TargetFrameManaBarText
        end
        
        if settings.name then
            self:SetFont(nameFont, settings.name.font or "Friz Quadrata TT", settings.name.size or 12, settings.name.flags or "")
        end
        if settings.health then
            self:SetFont(healthFont, settings.health.font or "Friz Quadrata TT", settings.health.size or 10, settings.health.flags or "")
        end
        if settings.mana then
            self:SetFont(manaFont, settings.mana.font or "Friz Quadrata TT", settings.mana.size or 10, settings.mana.flags or "")
        end
    end
    
    -- 应用格式设置
    for unit, formats in pairs(self.db.formats or {}) do
        if formats.health then
            self:SetHealthTextFormat(unit, formats.health)
        end
    end
    
    -- 应用颜色设置
    for unit, colors in pairs(self.db.colors or {}) do
        local nameFont, healthFont
        if unit == "player" then
            nameFont = PlayerNameText
            healthFont = PlayerFrameHealthBarText
        elseif unit == "target" then
            nameFont = TargetFrame.Name or TargetNameText
            healthFont = TargetFrameHealthBarText
        end
        
        if colors.name then
            self:SetTextColor(nameFont, colors.name.r, colors.name.g, colors.name.b)
        end
        if colors.health then
            self:SetTextColor(healthFont, colors.health.r, colors.health.g, colors.health.b)
        end
    end
end

return TextSettings
```

---

## 五、Edit Mode 集成（12.0 版）

### 5.1 Edit Mode 框架集成

```lua
-- EditMode.lua
-- 12.0 Edit Mode 集成

local addonName, EUF = ...

local EditMode = {}
EUF.EditMode = EditMode

-- 初始化
function EditMode:Initialize(db)
    self.db = db.editMode
    self.systemFrames = {}
    self.isInEditMode = false
    
    -- 监听 Edit Mode 进入/退出事件
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("EDIT_MODE_MODE_CHANGED")
    eventFrame:SetScript("OnEvent", function(_, event, isInEditMode)
        if isInEditMode then
            self:OnEditModeEnter()
        else
            self:OnEditModeExit()
        end
    end)
end

-- Edit Mode 进入时创建控制点
function EditMode:OnEditModeEnter()
    self.isInEditMode = true
    
    -- 为 PlayerFrame 创建编辑控制点
    self:CreateEditControls(PlayerFrame, "player")
    
    -- 为 TargetFrame 创建编辑控制点
    self:CreateEditControls(TargetFrame, "target")
end

-- Edit Mode 退出时保存设置
function EditMode:OnEditModeExit()
    self.isInEditMode = false
    self:SaveFrameSettings()
    self:HideEditControls()
end

-- 创建编辑控制点
function EditMode:CreateEditControls(frame, unitKey)
    if not frame then return end
    
    local controls = CreateFrame("Frame", nil, frame)
    controls:SetAllPoints(frame)
    controls:SetFrameLevel(frame:GetFrameLevel() + 10)
    controls.unitKey = unitKey
    
    -- 添加缩放手柄
    local resizeHandle = CreateFrame("Button", nil, controls)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", controls, "BOTTOMRIGHT", 4, -4)
    resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    
    -- 缩放拖拽逻辑（12.0：仅在非战斗时允许）
    resizeHandle:SetScript("OnMouseDown", function()
        if InCombatLockdown() then
            print("|cffff0000EnhancedUnitFrames:|r 无法在战斗中调整框体大小")
            return
        end
        frame:StartSizing()
    end)
    
    resizeHandle:SetScript("OnMouseUp", function()
        if InCombatLockdown() then return end
        frame:StopMovingOrSizing()
        
        -- 计算新缩放
        local originalSize = EUF.FrameScale.originalSizes[unitKey]
        if originalSize then
            local newWidth = frame:GetWidth()
            local newScale = newWidth / originalSize.width
            EUF.FrameScale:SetFrameScale(unitKey, newScale)
        end
    end)
    
    controls.resizeHandle = resizeHandle
    self.systemFrames[unitKey] = controls
end

-- 保存框体设置到 Edit Mode 布局
function EditMode:SaveFrameSettings()
    -- 同步到 C_EditMode（如果需要与暴雪系统集成）
    if self.db.syncWithBlizzard then
        local layouts = C_EditMode.GetLayouts()
        if layouts then
            C_EditMode.SaveLayouts()
        end
    end
end

-- 隐藏编辑控制点
function EditMode:HideEditControls()
    for _, controls in pairs(self.systemFrames) do
        if controls then
            controls:Hide()
        end
    end
end

-- 与暴雪 Edit Mode 同步
function EditMode:SyncWithBlizzardEditMode()
    local layouts = C_EditMode.GetLayouts()
    if not layouts then return end
    
    for _, system in ipairs(layouts.systems or {}) do
        if system.system == Enum.EditModeSystem.UnitFrame then
            self:ParseUnitFrameSettings(system)
        end
    end
end

-- 解析单位框体设置
function EditMode:ParseUnitFrameSettings(systemData)
    -- 根据 systemIndex 判断是 Player 还是 Target
    local unitKey = self:GetUnitKeyFromSystemIndex(systemData.systemIndex)
    
    for _, setting in ipairs(systemData.settings or {}) do
        -- 解析具体设置项
        -- setting.setting = 设置ID
        -- setting.value = 设置值
    end
end

return EditMode
```

---

## 六、配置系统与持久化

### 6.1 数据库设计（Database.lua）

```lua
-- Database.lua

local addonName, EUF = ...

local Database = {}
EUF.Database = Database

-- 默认配置（12.0 合规版）
Database.DEFAULTS = {
    global = {
        enableAddon = true,
    },
    profile = {
        classColors = {
            enabled = true,
            colorBackground = false,
            colorBorder = true,
            colorNPCByReaction = true,
        },
        scales = {
            player = 1.0,
            target = 1.0,
            focus = 1.0,
            pet = 1.0,
        },
        textures = {
            healthBar = "Blizzard",
            manaBar = "Blizzard",
            background = "None",
            border = "None",
        },
        text = {
            formats = {
                player = {health = "DEFAULT", mana = "DEFAULT"},
                target = {health = "DEFAULT", mana = "DEFAULT"},
            },
            fonts = {
                player = {
                    name = {font = "Friz Quadrata TT", size = 12, flags = ""},
                    health = {font = "Friz Quadrata TT", size = 10, flags = ""},
                    mana = {font = "Friz Quadrata TT", size = 10, flags = ""},
                },
                target = {
                    name = {font = "Friz Quadrata TT", size = 12, flags = ""},
                    health = {font = "Friz Quadrata TT", size = 10, flags = ""},
                    mana = {font = "Friz Quadrata TT", size = 10, flags = ""},
                },
            },
            colors = {
                player = {name = {r=1,g=1,b=1}, health = {r=1,g=1,b=1}},
                target = {name = {r=1,g=1,b=1}, health = {r=1,g=1,b=1}},
            },
        },
        editMode = {
            showInEditMode = true,
            syncWithBlizzard = true,
        },
    },
}

-- 初始化
function Database:Initialize()
    -- 注册 SavedVariables
    EnhancedUnitFramesDB = EnhancedUnitFramesDB or {}
    EnhancedUnitFramesDBGlobal = EnhancedUnitFramesDBGlobal or {}
    
    self.db = EnhancedUnitFramesDB
    self.global = EnhancedUnitFramesDBGlobal
    
    -- 应用默认值
    self:ApplyDefaults()
end

-- 应用默认值
function Database:ApplyDefaults()
    -- 合并 profile 默认值
    for key, value in pairs(self.DEFAULTS.profile) do
        if self.db[key] == nil then
            if type(value) == "table" then
                self.db[key] = self:CopyTable(value)
            else
                self.db[key] = value
            end
        end
    end
    
    -- 合并 global 默认值
    for key, value in pairs(self.DEFAULTS.global) do
        if self.global[key] == nil then
            self.global[key] = value
        end
    end
end

-- 深拷贝表
function Database:CopyTable(src)
    local dest = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = self:CopyTable(v)
        else
            dest[k] = v
        end
    end
    return dest
end

-- 重置为默认值
function Database:ResetProfile()
    for key, value in pairs(self.DEFAULTS.profile) do
        if type(value) == "table" then
            self.db[key] = self:CopyTable(value)
        else
            self.db[key] = value
        end
    end
end

return Database
```

---

## 七、TOC 文件配置（12.0）

### 7.1 EnhancedUnitFrames.toc

```toc
## Interface: 120000
## Title: Enhanced Unit Frames
## Title-zhCN: 增强单位框体
## Notes: Enhances the default Player and Target unit frames with class colors, scaling, textures, and text customization. Compatible with WoW 12.0 (Midnight).
## Notes-zhCN: 增强默认的玩家和目标单位框体，支持职业染色、缩放、材质和文字自定义。兼容魔兽世界 12.0（至暗之夜）。
## Author: YourName
## Version: 1.0.0
## SavedVariables: EnhancedUnitFramesDB
## SavedVariablesPerCharacter: EnhancedUnitFramesDBChar
## OptionalDeps: LibSharedMedia-3.0

# Core
Core\Core.lua
Core\Database.lua
Core\Utils.lua
Core\SecretSafe.lua

# Modules
Modules\ClassColors.lua
Modules\FrameScale.lua
Modules\Textures.lua
Modules\TextSettings.lua

# Integration
Integration\EditMode.lua
Integration\BlizzardHooks.lua

# GUI
GUI\OptionsPanel.lua
```

---

## 八、开发注意事项与最佳实践（12.0 专项）

### 8.1 Secret Value 处理规则

```lua
-- ⚠️ 12.0 核心规则

-- 规则 1: 永远假设 UnitHealth/UnitPower 可能返回机密值
-- 正确做法：检查返回值类型
local health = UnitHealth("target")
if type(health) == "userdata" then
    -- 这是机密值，无法进行算术运算
    -- 回退到暴雪默认显示
else
    -- 这是普通数值，可以安全处理
    local percent = health / UnitHealthMax("target") * 100
end

-- 规则 2: 使用暴雪提供的非机密 API 路径
-- 职业颜色：使用 C_ClassColor.GetClassColor() + GUID 方式
local guid = UnitGUID("target")
if guid then
    local _, classToken = GetPlayerInfoByGUID(guid)
    if classToken then
        local color = C_ClassColor.GetClassColor(classToken)
        -- color 可以安全使用
    end
end

-- 规则 3: 让暴雪原生组件处理复杂计算
-- StatusBar 内部使用安全代码，可以处理机密值
healthBar:SetMinMaxValues(0, UnitHealthMax("target"))
healthBar:SetValue(UnitHealth("target"))
-- 上述操作安全，因为 StatusBar 内部知道如何处理机密值
```

### 8.2 Secure Frame 操作规则（12.0）

```lua
-- ⚠️ 12.0 Secure Frame 操作规则

-- 规则 1: 使用模板继承而非自定义实现
-- ✅ 正确
local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")

-- ❌ 错误：自己实现安全逻辑
local button = CreateFrame("Button")
button:SetScript("OnClick", function() ... end)  -- 非安全

-- 规则 2: 属性驱动而非方法调用
-- ✅ 正确
frame:SetAttribute("statehidden", true)

-- ❌ 错误（战斗中）
frame:Hide()

-- 规则 3: 使用 WrapScript 安全包装
-- ✅ 正确
frame:WrapScript(frame, "OnShow", [[
    -- 这是安全代码，可以访问受保护的属性
    self:SetAttribute("customAttribute", "value")
]])

-- ❌ 错误：直接 Hook 安全处理程序
frame:SetScript("OnShow", function() ... end)  -- 会污染框架

-- 规则 4: 使用 hooksecurefunc 后钩
-- ✅ 正确
hooksecurefunc("PlayerFrame_Update", function()
    -- 在暴雪代码之后执行，不会污染原始调用
end)

-- ❌ 错误：前钩可能污染参数
local original = PlayerFrame_Update
PlayerFrame_Update = function(...)
    -- 如果这里修改了参数，会污染后续调用
    original(...)
end
```

### 8.3 Taint 防护（12.0 增强）

```lua
-- Taint 防护最佳实践

-- 1. 永远不要修改暴雪的全局变量
-- ❌ 错误
PlayerFrame.customVar = true

-- ✅ 正确：使用自己的命名空间
EUF.frames.player = PlayerFrame

-- 2. 永远不要覆盖暴雪的函数
-- ❌ 错误
UnitHealth = function(unit) return 100 end

-- ✅ 正确：Hook 并扩展
hooksecurefunc("UnitHealth", function(unit)
    -- 只读取，不修改返回值
end)

-- 3. 使用 pcall 包装可能出错的操作
local function SafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        EUF:Debug("SafeCall error:", err)
        return false, nil
    end
    return true, err
end

-- 4. 检查 InCombatLockdown
local function SafeModify(func, ...)
    if InCombatLockdown() then
        return false, "combat_lockdown"
    end
    return SafeCall(func, ...)
end
```

### 8.4 性能优化（12.0）

```lua
-- 性能优化最佳实践

-- 1. 使用事件节流（Event Throttling）
local lastUpdate = 0
local UPDATE_INTERVAL = 0.1  -- 100ms

frame:SetScript("OnUpdate", function(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate >= UPDATE_INTERVAL then
        lastUpdate = 0
        -- 执行更新逻辑
    end
end)

-- 2. 避免频繁的字符串操作
-- ❌ 错误：每次都创建新字符串
local text = UnitName("target") .. " - " .. UnitClass("target")

-- ✅ 正确：缓存结果
local nameCache = {}
local function GetCachedName(unit)
    if not nameCache[unit] then
        nameCache[unit] = UnitName(unit) or ""
    end
    return nameCache[unit]
end

-- 3. 使用 RegisterUnitEvent 替代全局事件
-- ✅ 正确：只监听特定单位
frame:RegisterUnitEvent("UNIT_HEALTH", "player", "target")

-- ❌ 错误：监听所有单位的事件
frame:RegisterEvent("UNIT_HEALTH")
```

---

## 九、测试计划（12.0 专项）

### 9.1 功能测试清单

| 测试项 | 测试场景 | 预期结果 | 12.0 特殊处理 |
|--------|----------|----------|---------------|
| 职业染色 | 切换目标（不同职业玩家） | 生命条颜色正确显示职业色 | ✅ 使用 GUID 路径获取职业 |
| 框体缩放 | 在设置中调整缩放值 | 框体大小即时更新（非战斗） | ⚠️ 战斗中排队等待 |
| 战斗安全 | 在战斗中尝试修改设置 | 设置排队等待战斗结束后执行 | ✅ 队列机制 |
| 材质替换 | 选择不同材质 | 生命条/法力条材质正确替换 | ✅ 纯视觉操作 |
| 文字格式 | 切换百分比/数值显示 | 文字按格式显示（如果可能） | ⚠️ 机密值场景回退默认 |
| Edit Mode | 进入/退出编辑模式 | 控制点正确显示/隐藏 | ✅ 兼容 |
| 配置持久化 | 重载 UI / 重启游戏 | 设置正确保存和加载 | ✅ 兼容 |
| 机密值处理 | 在团本/大秘境中测试 | 无 Lua 错误，显示正常 | ✅ 安全回退 |

### 9.2 兼容性测试

- [ ] 与其他单位框体插件共存测试（如有）
- [ ] 不同分辨率下的 UI 缩放测试
- [ ] 多显示器 DPI 缩放测试
- [ ] 团本战斗中机密值处理测试
- [ ] 大秘境战斗中机密值处理测试
- [ ] PVP 战斗中机密值处理测试

---

## 十、发布与维护

### 10.1 版本号规范

```
Major.Minor.Patch
  │     │     │
  │     │     └── Bug 修复、小改动
  │     └──────── 新功能、API 变更
  └────────────── 重大架构变更、不兼容更新
```

### 10.2 更新日志模板

```markdown
## [1.0.0] - 2026-04-04

### Added
- Initial release for WoW 12.0 (Midnight)
- Class color support for Player/Target frames (Secret-Safe implementation)
- Frame scaling (50%-200%) with combat-safe queue
- Custom texture support
- Text format customization (limited in combat scenarios)
- Edit Mode integration

### Changed
- All modules rewritten for 12.0 Secret Value compliance
- Switched to Attribute-Driven approach for secure frames
- Text formatting now falls back to Blizzard default when secret values detected

### Known Issues
- Scale changes during combat are deferred until combat ends
- Custom health text formats may not work in raids/dungeons due to Secret Value restrictions
```

---

## 附录 A：12.0 API 变更速查表

| API | 10.x 状态 | 12.0 状态 | 替代方案 |
|-----|-----------|-----------|----------|
| `UnitHealth(unit)` | 返回数值 | 可能返回机密值 | 让 StatusBar 处理 |
| `UnitPower(unit)` | 返回数值 | 可能返回机密值 | 让 StatusBar 处理 |
| `UnitClass(unit)` | 返回职业 | 某些场景机密 | 使用 GUID + GetPlayerInfoByGUID |
| `C_ClassColor.GetClassColor()` | 正常 | ✅ 正常 | 推荐使用 |
| `UnitGUID(unit)` | 正常 | ✅ 正常 | 推荐使用 |
| `GetPlayerInfoByGUID(guid)` | 正常 | ✅ 正常 | 推荐使用 |
| `frame:Show()` | 正常 | 战斗中禁止 | 使用属性驱动 |
| `frame:Hide()` | 正常 | 战斗中禁止 | 使用属性驱动 |
| `frame:SetScale()` | 正常 | 战斗中禁止 | 非战斗时设置 |
| `hooksecurefunc()` | 正常 | ✅ 正常 | 推荐使用 |
| `frame:HookScript()` | 正常 | ⚠️ 小心使用 | 使用 WrapScript |

---

## 附录 B：常用事件参考（12.0）

```lua
-- 单位状态事件
UNIT_HEALTH           -- 生命值变化（参数可能是机密）
UNIT_MAXHEALTH        -- 最大生命值变化
UNIT_POWER_UPDATE     -- 能量值变化
UNIT_AURA             -- 光环变化
UNIT_DISPLAYPOWER     -- 能量类型变化

-- 目标事件
PLAYER_TARGET_CHANGED -- 目标切换
PLAYER_FOCUS_CHANGED  -- 焦点切换

-- 战斗事件
PLAYER_REGEN_DISABLED -- 进入战斗
PLAYER_REGEN_ENABLED  -- 离开战斗

-- Edit Mode 事件
EDIT_MODE_MODE_CHANGED -- 编辑模式状态变化
```

---

**文档版本**：v2.0 (12.0 适配版)  
**最后更新**：2026-04-04  
**目标游戏版本**：WoW 12.0 (Midnight)

---

## 附录 C：12.0 开发参考资料

- [暴雪官方：Combat Philosophy and Addon Disarmament in Midnight](https://news.blizzard.com/en-us/article/24246290)
- [暴雪官方：How Midnight's Upcoming Game Changes Will Impact Combat Addons](https://news.blizzard.com/en-us/article/24244638)
- [Wowhead：Last-Minute Addon API Changes](https://www.wowhead.com/news/some-last-minute-changes-coming-to-addon-api-before-mythic-raids-and-mythic-380900)
- [Warcraft Wiki：Secret Values](https://warcraft.wiki.gg/)
