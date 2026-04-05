# EnhancedUnitFrames 单位框体个性化功能设计文档

## 概述

本文档描述 EnhancedUnitFrames 插件的单位框体个性化功能设计。该功能允许玩家对暴雪原生单位框体（玩家、目标、焦点、宠物、目标的目标）进行深度定制，包括头像、生命条、能量条、次级能量条等模块的独立配置。

## 设计目标

1. **模块化设计**：每个框体元素（头像、生命条、能量条等）作为独立模块，可单独配置
2. **可视化配置**：通过暴雪设置面板提供直观的配置界面
3. **12.0 合规**：遵守 WoW 12.0 机密值系统限制
4. **性能优先**：避免频繁的帧更新，使用事件驱动模式

---

## 一、框体模块划分

### 1.1 目标框体列表

| 框体类型 | 单位标识 | 说明 |
|---------|---------|------|
| 玩家框体 | player | 当前玩家 |
| 目标框体 | target | 当前目标 |
| 焦点框体 | focus | 当前焦点 |
| 宠物框体 | pet | 当前宠物 |
| 目标的目标 | targettarget | 目标的目标 |

### 1.2 模块定义

每个单位框体由以下模块组成：

#### 模块列表

| 模块ID | 模块名称 | 说明 | 适用框体 |
|--------|---------|------|---------|
| portrait | 头像 | 显示单位3D头像或图标 | player, target, focus, pet |
| healthBar | 生命条 | 显示当前/最大生命值 | 所有 |
| powerBar | 能量条 | 显示主要能量（法力/怒气等） | player, target, focus, pet |
| secondaryPowerBar | 次级能量条 | 显示职业特殊能量（神圣能量/连击点等） | player |
| castBar | 施法条 | 显示施法进度 | player, target, focus, pet |
| buffs | 增益效果 | 显示增益Buff图标 | target, focus |
| debuffs | 减益效果 | 显示减益Debuff图标 | target, focus |
| nameText | 名称文字 | 显示单位名称 | 所有 |
| healthText | 生命值文字 | 显示生命值数值/百分比 | 所有 |
| powerText | 能量值文字 | 显示能量值数值/百分比 | 所有 |
| levelText | 等级文字 | 显示单位等级 | target, focus, pet |
| border | 边框 | 框体外边框 | 所有 |

---

## 二、模块配置结构

### 2.1 通用模块配置

每个模块支持以下通用配置项：

```lua
ModuleConfig = {
    enabled = true,           -- 是否启用该模块
    width = 100,              -- 宽度（像素）
    height = 20,              -- 高度（像素）
    xOffset = 0,              -- X轴偏移
    yOffset = 0,              -- Y轴偏移
    anchor = "CENTER",        -- 锚点
    anchorTo = "CENTER",      -- 相对于父框架的锚点
    strata = "LOW",           -- 图层层级
    level = 1,                -- 图层等级
}
```

### 2.2 头像模块 (portrait)

```lua
PortraitConfig = {
    -- 通用配置
    enabled = true,
    width = 64,
    height = 64,
    xOffset = 0,
    yOffset = 0,
    
    -- 特有配置
    style = "3D",             -- 显示样式: "3D"(3D模型), "2D"(静态图标), "class"(职业图标)
    showOverlay = true,       -- 是否显示覆盖层（等级图标等）
    borderEnabled = true,     -- 是否显示边框
    borderSize = 2,           -- 边框宽度
    borderColor = {r=1, g=1, b=1, a=1},  -- 边框颜色
}
```

### 2.3 生命条模块 (healthBar)

```lua
HealthBarConfig = {
    -- 通用配置
    enabled = true,
    width = 200,
    height = 24,
    xOffset = 0,
    yOffset = 0,
    
    -- 材质与颜色
    texture = "Blizzard",     -- 材质名称或路径
    colorMode = "class",      -- 颜色模式: "class"(职业色), "reaction"(反应色), "custom"(自定义)
    customColor = {r=0, g=1, b=0, a=1},  -- 自定义颜色
    backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8},  -- 背景颜色
    useClassColor = true,     -- 快捷设置：使用职业染色
    smoothFill = true,        -- 平滑填充动画
    
    -- 边框
    borderEnabled = true,
    borderSize = 2,
    borderColor = {r=1, g=1, b=1, a=1},
    borderTexture = "Blizzard", -- 边框材质
    
    -- 预测
    showHealPrediction = true,   -- 显示治疗预测
    showDamagePrediction = true, -- 显示伤害预测
    showAbsorb = true,           -- 显示吸收盾
}
```

### 2.4 能量条模块 (powerBar)

```lua
PowerBarConfig = {
    -- 通用配置
    enabled = true,
    width = 200,
    height = 12,
    xOffset = 0,
    yOffset = 0,
    
    -- 材质与颜色
    texture = "Blizzard",
    colorMode = "powerType",   -- 颜色模式: "powerType"(按能量类型), "custom"(自定义)
    customColor = {r=0, g=0.5, b=1, a=1},
    backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8},
    
    -- 能量类型颜色映射
    powerColors = {
        MANA = {r=0, g=0.5, b=1, a=1},
        RAGE = {r=1, g=0, b=0, a=1},
        ENERGY = {r=1, g=1, b=0, a=1},
        RUNIC_POWER = {r=0, g=0.82, b=1, a=1},
        FURY = {r=0.6, g=0.3, b=0.6, a=1},
        PAIN = {r=1, g=0.5, b=0.5, a=1},
        -- 更多能量类型...
    },
    
    -- 边框
    borderEnabled = true,
    borderSize = 1,
    borderColor = {r=1, g=1, b=1, a=1},
}
```

### 2.5 次级能量条模块 (secondaryPowerBar)

```lua
SecondaryPowerBarConfig = {
    enabled = true,
    width = 200,
    height = 6,
    
    -- 显示模式
    displayMode = "bar",      -- "bar"(条状), "icons"(图标), "runes"(符文)
    orientation = "HORIZONTAL", -- "HORIZONTAL", "VERTICAL"
    
    -- 职业特定配置
    -- 圣骑士: 神圣能量
    -- 潜行者/德鲁伊: 连击点
    -- 战士: 怒气额外条
    -- 死亡骑士: 符文
    -- 武僧: 真气
    -- 术士: 灵魂碎片
    -- 猎人: 荷枪实弹
    -- 唤魔师: 精华
}
```

### 2.6 文字模块配置

所有文字模块共享以下基础配置：

```lua
TextConfig = {
    enabled = true,
    
    -- 位置
    position = "CENTER",      -- 相对于父框架的位置
    xOffset = 0,
    yOffset = 0,
    
    -- 对齐
    justifyH = "CENTER",      -- 水平对齐: "LEFT", "CENTER", "RIGHT"
    justifyV = "MIDDLE",      -- 垂直对齐: "TOP", "MIDDLE", "BOTTOM"
    
    -- 字体
    font = "Friz Quadrata TT", -- 字体名称
    fontSize = 12,
    fontFlags = "OUTLINE",    -- 字体标志: "", "OUTLINE", "THICKOUTLINE", "MONOCHROME"
    
    -- 颜色
    colorMode = "default",    -- "default"(默认), "class"(职业色), "custom"(自定义)
    color = {r=1, g=1, b=1, a=1},
    
    -- 阴影
    shadowEnabled = true,
    shadowColor = {r=0, g=0, b=0, a=1},
    shadowOffsetX = 1,
    shadowOffsetY = -1,
}
```

#### 名称文字 (nameText)

```lua
NameTextConfig = TextConfig + {
    maxLength = 20,           -- 最大显示字符数
    abbreviate = true,        -- 超长时是否缩写
    showTitle = false,        -- 是否显示头衔
    showRealm = false,        -- 是否显示服务器名
}
```

#### 生命值文字 (healthText)

```lua
HealthTextConfig = TextConfig + {
    format = "PERCENT",       -- 显示格式（见下文格式列表）
    delimiter = "/",          -- 分隔符
    showDeadText = true,      -- 死亡时显示"死亡"
    deadText = "死亡",
}

-- 文字格式选项
TextFormats = {
    "NONE" = "无",
    "PERCENT" = "百分比 (100%)",
    "CURRENT" = "当前值 (85000)",
    "MAX" = "最大值 (100000)",
    "CURMAX" = "当前/最大 (85000/100000)",
    "CURPERCENT" = "当前 百分比% (85000 85%)",
    "CURMAXPERCENT" = "当前/最大 百分比% (85000/100000 85%)",
    "DEFICIT" = "亏损值 (-15000)",
}
```

#### 能量值文字 (powerText)

```lua
PowerTextConfig = TextConfig + {
    format = "CURRENT",       -- 显示格式
    showOnlyInCombat = false, -- 仅战斗中显示
    hideWhenFull = false,     -- 满能量时隐藏
}
```

---

## 三、数据结构设计

### 3.1 数据库结构

```lua
EnhancedUnitFramesDB = {
    -- 框体配置
    frames = {
        player = FrameConfig,
        target = FrameConfig,
        focus = FrameConfig,
        pet = FrameConfig,
        targettarget = FrameConfig,
    },
    
    -- 全局设置
    global = {
        enableAddon = true,
        debugMode = false,
        profileVersion = 1,
    },
}

FrameConfig = {
    enabled = true,           -- 是否启用该框体的自定义
    
    -- 缩放
    scale = 1.0,
    
    -- 各模块配置
    portrait = PortraitConfig,
    healthBar = HealthBarConfig,
    powerBar = PowerBarConfig,
    secondaryPowerBar = SecondaryPowerBarConfig,
    castBar = CastBarConfig,
    nameText = NameTextConfig,
    healthText = HealthTextConfig,
    powerText = PowerTextConfig,
    levelText = LevelTextConfig,
    border = BorderConfig,
    
    -- Buff/Debuff配置
    buffs = BuffsConfig,
    debuffs = DebuffsConfig,
}
```

### 3.2 默认配置

```lua
local DEFAULTS = {
    frames = {
        player = {
            enabled = true,
            scale = 1.0,
            
            portrait = {
                enabled = true,
                width = 64, height = 64,
                style = "3D",
                borderEnabled = true,
                borderSize = 2,
            },
            
            healthBar = {
                enabled = true,
                width = 200, height = 24,
                useClassColor = true,
                texture = "Blizzard",
                borderEnabled = true,
                borderSize = 2,
            },
            
            powerBar = {
                enabled = true,
                width = 200, height = 12,
                colorMode = "powerType",
                texture = "Blizzard",
                borderEnabled = true,
                borderSize = 1,
            },
            
            healthText = {
                enabled = true,
                position = "CENTER",
                xOffset = 0, yOffset = 0,
                format = "CURMAXPERCENT",
                fontSize = 10,
                fontFlags = "OUTLINE",
            },
            
            powerText = {
                enabled = true,
                position = "CENTER",
                format = "CURRENT",
                fontSize = 10,
            },
            
            nameText = {
                enabled = true,
                position = "TOP",
                yOffset = 5,
                fontSize = 12,
            },
        },
        
        target = {
            -- 类似player配置...
        },
        
        -- 其他框体...
    },
}
```

---

## 四、设置面板设计

### 4.1 面板结构

```
Enhanced Unit Frames (主分类)
├── 玩家框体
│   ├── 通用设置 (启用/禁用、缩放)
│   ├── 头像设置
│   ├── 生命条设置
│   ├── 能量条设置
│   ├── 次级能量条设置
│   ├── 文字设置
│   │   ├── 名称文字
│   │   ├── 生命值文字
│   │   └── 能量值文字
│   └── 边框设置
├── 目标框体
│   └── (同玩家框体结构)
├── 焦点框体
├── 宠物框体
├── 目标的目标
├── 高级选项
│   ├── 重置配置
│   ├── 导入配置
│   └── 导出配置
└── 小地图按钮
```

### 4.2 设置项控件类型

| 设置类型 | 控件 |
|---------|------|
| 布尔值 | 复选框 (Checkbox) |
| 数值范围 | 滑块 (Slider) |
| 枚举选择 | 下拉框 (Dropdown) |
| 颜色 | 颜色选择器 (ColorPicker) |
| 字体 | 字体选择器 (带LibSharedMedia) |
| 材质 | 材质预览选择器 |
| 文字格式 | 下拉框 + 预览 |

### 4.3 折叠面板设计

使用可展开的子分类来组织设置：

```
[▼] 生命条设置
    ├─ [x] 启用生命条
    ├─ 宽度: [====|====] 200
    ├─ 高度: [==|====] 24
    ├─ [x] 使用职业染色
    ├─ 材质: [Blizzard ▼]
    └─ [x] 显示边框
         └─ 边框宽度: [|====] 2

[▶] 能量条设置  (折叠状态)
```

---

## 五、材质系统

### 5.1 内置材质

```lua
BUILTIN_TEXTURES = {
    ["Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
    ["Blizzard RAID"] = "Interface\\RaidFrame\\Raid-Bar-Hp-Bg",
    ["Blizzard RAID 2"] = "Interface\\RaidFrame\\Raid-Bar-Resource-Fill",
    ["Flat"] = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\flat.tga",
    ["Gradient"] = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\gradient.tga",
    ["Glossy"] = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\glossy.tga",
    ["Minimalist"] = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\minimalist.tga",
}
```

### 5.2 LibSharedMedia 集成

```lua
-- 如果安装了 LibSharedMedia-3.0，则加载用户自定义材质
local LSM = LibStub("LibSharedMedia-3.0", true)
if LSM then
    -- 注册内置材质
    LSM:Register("statusbar", "EUF Flat", BUILTIN_TEXTURES.Flat)
    LSM:Register("statusbar", "EUF Gradient", BUILTIN_TEXTURES.Gradient)
    
    -- 获取所有可用材质
    function Textures:GetTextureList()
        local list = {}
        for name, _ in pairs(BUILTIN_TEXTURES) do
            table.insert(list, name)
        end
        if LSM then
            for _, name in ipairs(LSM:List("statusbar")) do
                if not tContains(list, name) then
                    table.insert(list, name)
                end
            end
        end
        table.sort(list)
        return list
    end
end
```

### 5.3 边框样式

```lua
BORDER_STYLES = {
    ["None"] = {
        name = "无",
        edgeFile = nil,
        edgeSize = 0,
    },
    ["Solid"] = {
        name = "实线",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    },
    ["Blizzard Tooltip"] = {
        name = "暴雪工具提示",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
    },
    ["Blizzard Dialog"] = {
        name = "暴雪对话框",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 32,
    },
    ["Rounded"] = {
        name = "圆角",
        edgeFile = "Interface\\AddOns\\EnhancedUnitFrames\\Media\\Textures\\border_rounded.tga",
        edgeSize = 12,
    },
}
```

---

## 六、实现架构

### 6.1 文件结构

```
EnhancedUnitFrames/
├── Core/
│   ├── Core.lua              # 核心：初始化、事件管理
│   ├── Database.lua          # 数据库：配置存取
│   ├── Utils.lua             # 工具函数
│   └── SecretSafe.lua        # 机密值处理
│
├── Modules/
│   ├── FrameBase.lua         # 框体基类
│   ├── Portrait.lua          # 头像模块
│   ├── HealthBar.lua         # 生命条模块
│   ├── PowerBar.lua          # 能量条模块
│   ├── SecondaryPowerBar.lua # 次级能量条模块
│   ├── CastBar.lua           # 施法条模块
│   ├── TextModule.lua        # 文字模块基类
│   ├── NameText.lua          # 名称文字
│   ├── HealthText.lua        # 生命值文字
│   ├── PowerText.lua         # 能量值文字
│   └── Border.lua            # 边框模块
│
├── Frames/
│   ├── PlayerFrame.lua       # 玩家框体配置
│   ├── TargetFrame.lua       # 目标框体配置
│   ├── FocusFrame.lua        # 焦点框体配置
│   ├── PetFrame.lua          # 宠物框体配置
│   └── TargetTargetFrame.lua # 目标的目标框体配置
│
├── GUI/
│   ├── OptionsPanel.lua      # 主设置面板
│   ├── Widgets/
│   │   ├── ColorPicker.lua   # 颜色选择器
│   │   ├── TexturePreview.lua# 材质预览
│   │   └── FontSelector.lua  # 字体选择器
│   └── Panes/
│       ├── FrameConfigPanel.lua    # 框体配置面板
│       ├── ModuleConfigPanel.lua   # 模块配置面板
│       └── TextConfigPanel.lua     # 文字配置面板
│
├── Media/
│   └── Textures/             # 自定义材质
│
└── Integration/
    ├── BlizzardHooks.lua     # 暴雪函数钩子
    └── EditMode.lua          # 编辑模式集成
```

### 6.2 模块基类设计

```lua
-- Modules/FrameBase.lua
local FrameBase = {}
EUF.FrameBase = FrameBase

function FrameBase:New(frameKey, unit)
    local obj = {
        frameKey = frameKey,
        unit = unit,
        modules = {},
        config = nil,
        initialized = false,
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function FrameBase:Initialize(config)
    self.config = config
    self:LoadModules()
    self:ApplyConfig()
    self.initialized = true
end

function FrameBase:LoadModules()
    -- 加载各模块
    self.modules.portrait = EUF.Portrait:New(self)
    self.modules.healthBar = EUF.HealthBar:New(self)
    self.modules.powerBar = EUF.PowerBar:New(self)
    -- ...
end

function FrameBase:ApplyConfig()
    for moduleName, module in pairs(self.modules) do
        if self.config[moduleName] then
            module:ApplyConfig(self.config[moduleName])
        end
    end
end

function FrameBase:Refresh()
    for _, module in pairs(self.modules) do
        module:Refresh()
    end
end

function FrameBase:OnEvent(event, ...)
    -- 事件分发到各模块
end

return FrameBase
```

### 6.3 模块接口设计

```lua
-- 所有模块需要实现的接口
IModule = {
    -- 初始化
    Initialize = function(self, frame, config) end,
    
    -- 应用配置
    ApplyConfig = function(self, config) end,
    
    -- 刷新显示
    Refresh = function(self) end,
    
    -- 显示/隐藏
    Show = function(self) end,
    Hide = function(self) end,
    
    -- 战斗安全操作
    OnCombatEnd = function(self) end,
    
    -- 事件响应
    OnEvent = function(self, event, ...) end,
}
```

---

## 七、职业染色详细设计

### 7.1 染色规则

```lua
ColorRules = {
    -- 玩家单位：使用职业色
    player = {
        rule = "class",
        source = "C_ClassColor.GetClassColor",
    },
    
    -- 敌对玩家：使用职业色
    hostilePlayer = {
        rule = "class",
    },
    
    -- 友好玩家：使用职业色
    friendlyPlayer = {
        rule = "class",
    },
    
    -- NPC单位：使用反应色
    npc = {
        rule = "reaction",
        colors = {
            hostile    = {r=1, g=0, b=0},    -- 敌对（红）
            neutral    = {r=1, g=1, b=0},    -- 中立（黄）
            friendly   = {r=0, g=1, b=0},    -- 友好（绿）
        },
    },
    
    -- 特殊单位类型
    pet = {
        rule = "owner_class",  -- 使用主人职业色
    },
    
    totem = {
        rule = "custom",
        color = {r=0.5, g=0.5, b=0.5},
    },
}
```

### 7.2 反应色映射

```lua
REACTION_COLORS = {
    [1] = {r = 1.0, g = 0.0, b = 0.0},  -- 仇恨
    [2] = {r = 1.0, g = 0.0, b = 0.0},  -- 敌对
    [3] = {r = 1.0, g = 0.5, b = 0.0},  -- 不友好
    [4] = {r = 1.0, g = 1.0, b = 0.0},  -- 中立
    [5] = {r = 0.5, g = 1.0, b = 0.0},  -- 友好
    [6] = {r = 0.0, g = 1.0, b = 0.0},  -- 友善
    [7] = {r = 0.0, g = 1.0, b = 0.0},  -- 尊敬
    [8] = {r = 0.0, g = 1.0, b = 0.0},  -- 崇拜
}
```

---

## 八、性能优化策略

### 8.1 事件驱动更新

```lua
-- 只在必要时更新，避免 OnUpdate
local UPDATE_EVENTS = {
    "UNIT_HEALTH",
    "UNIT_MAXHEALTH",
    "UNIT_POWER_UPDATE",
    "UNIT_MAXPOWER",
    "UNIT_DISPLAYPOWER",
    "UNIT_AURA",
    "PLAYER_TARGET_CHANGED",
    "PLAYER_FOCUS_CHANGED",
    "UNIT_FACTION",
}

function FrameBase:RegisterEvents()
    for _, event in ipairs(UPDATE_EVENTS) do
        self.eventFrame:RegisterEvent(event)
    end
end
```

### 8.2 战斗队列机制

```lua
-- 战斗中的操作排队等待脱战后执行
function Module:SetValue(value)
    if InCombatLockdown() then
        self.pendingValue = value
        EUF:AddPendingOperation(self.frameKey, function()
            self:SetValueInternal(value)
        end)
    else
        self:SetValueInternal(value)
    end
end
```

### 8.3 配置缓存

```lua
-- 缓存常用配置值，避免频繁数据库访问
local configCache = {}

function GetConfig(frameKey, moduleKey, key)
    local cacheKey = frameKey .. "." .. moduleKey .. "." .. key
    if configCache[cacheKey] ~= nil then
        return configCache[cacheKey]
    end
    local value = EUF.Database:Get("frames", frameKey, moduleKey, key)
    configCache[cacheKey] = value
    return value
end
```

---

## 九、实现优先级

### 阶段一：核心框架 (P0)
- [x] 设计并实现新的数据库结构
- [x] 创建框体基类 (FrameBase)
- [x] 创建模块基类 (ModuleBase)

### 阶段二：基础模块 (P0)
- [x] 实现生命条模块 (HealthBar)
- [x] 实现能量条模块 (PowerBar)
- [x] 实现职业染色功能

### 阶段三：文字模块 (P0)
- [x] 实现名称文字模块
- [x] 实现生命值文字模块
- [x] 实现能量值文字模块

### 阶段四：高级模块 (P1)
- [x] 实现头像模块
- [x] 实现次级能量条模块
- [x] 实现边框模块
- [x] 实现施法条模块

### 阶段五：设置面板重构 (P1)
- [x] 重构设置面板以支持新结构
- [x] 实现所有模块的设置项
- [x] 实现颜色选择器

### 阶段六：优化与测试 (P2)
- [ ] 性能优化
- [ ] 内存优化
- [ ] 游戏内测试

---

## 十、参考资源

- [EnhanceQoL 源码](https://github.com/R41z0r/EnhanceQoL)
- [Plater 源码](https://github.com/Terciob/Plater)
- [WoW 12.0 API 文档](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API)
- [LibSharedMedia-3.0](https://www.wowace.com/projects/libsharedmedia-3-0)

---

*文档版本: 1.0*
*最后更新: 2026-04-05*