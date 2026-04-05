# EnhancedUnitFrames UI 集成计划

> **需求来源**: 用户反馈
> **创建日期**: 2026-04-05
> **优先级**: P1

---

## 需求概述

### 需求 1: 设置面板正确显示在游戏设置-插件列表

**当前问题**: 设置面板使用 Settings API 但未正确显示在游戏设置界面的插件列表左侧。

**期望效果**:
- 在 `ESC → 选项 → 插件` 左侧列表中显示 "Enhanced Unit Frames"
- 点击后在右侧面板显示插件设置选项
- 与其他插件（如 DBM, WeakAuras）显示方式一致

### 需求 2: 小地图快捷按钮

**期望效果**:
- 创建一个可拖拽的小地图按钮，吸附在小地图边缘
- 点击按钮打开设置面板
- 右键菜单提供快捷操作（开关职业染色、重置等）
- 支持隐藏/显示按钮的设置选项
- 按钮图标与插件主题一致

---

## 技术分析

### WoW 12.0 设置面板系统

WoW 12.0 引入了新的 Settings API，有两种注册方式：

#### 方式 A: Settings.RegisterAddOnCategory (推荐)
```lua
-- 创建设置分类
local category = Settings.RegisterVerticalLayoutCategory("Enhanced Unit Frames")
Settings.RegisterAddOnCategory(category)
```
此方式会将插件注册到 `选项 → 插件` 左侧列表。

#### 方式 B: InterfaceOptionsFrame_AddCategory (旧式)
```lua
-- 旧版 API（可能仍有支持）
local panel = CreateFrame("Frame", "EUF_OptionsPanel", UIParent)
panel.name = "Enhanced Unit Frames"
InterfaceOptionsFrame_AddCategory(panel)
```

**当前代码分析**:
- `OptionsPanel.lua` 已使用 `Settings.RegisterAddOnCategory(category)`
- 问题可能是分类未正确设置 ID 或缺少必要的属性

### 小地图按钮实现

#### 方案 A: LibDataBroker + LibDBIcon (推荐)
- 使用社区标准库
- 与其他插件共享小地图按钮位置
- 支持按钮收藏夹功能

**依赖**:
- `LibDataBroker-1.1`
- `LibDBIcon-1.0`

#### 方案 B: 自定义实现
- 创建独立的小地图按钮
- 不依赖外部库
- 简单但可能与其他插件按钮冲突

---

## 实现计划

### Phase 1: 设置面板修复

#### 1.1 调查当前问题
- [ ] 测试当前代码在游戏中的实际显示效果
- [ ] 检查 `Settings.RegisterAddOnCategory` 的正确用法
- [ ] 对比其他插件（DBM, Details）的实现方式

#### 1.2 修复方案
- [ ] 确保 category 有正确的 ID
- [ ] 可能需要使用 `Settings.RegisterCategory()` 替代
- [ ] 添加 category 图标

#### 1.3 测试验证
- [ ] 在游戏中打开设置界面
- [ ] 确认左侧列表显示插件名称
- [ ] 确认点击后右侧显示设置面板

### Phase 2: 小地图按钮实现

#### 2.1 选择实现方案
**推荐**: 方案 A (LibDataBroker + LibDBIcon)
- 优点: 标准、与社区一致、不占用独立位置
- 缺点: 需要嵌入两个库文件

**备选**: 方案 B (自定义实现)
- 优点: 无外部依赖、代码简洁
- 缺点: 可能与其他按钮重叠

#### 2.2 LibDataBroker + LibDBIcon 实现

**文件结构**:
```
Libs/
├── LibDataBroker-1.1/
│   └── LibDataBroker-1.1.lua
└── LibDBIcon-1.0/
    ├── LibDBIcon-1.0.lua
    └── LibDBIcon-1.0.toc
```

**代码实现** (GUI/MinimapButton.lua):
```lua
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local minimapButton = LDB:NewDataObject("EnhancedUnitFrames", {
    type = "launcher",
    icon = "Interface\\Icons\\INV_Misc_Gear_01",
    OnClick = function(self, button)
        if button == "LeftButton" then
            EUF.OptionsPanel:Open()
        elseif button == "RightButton" then
            -- 显示右键菜单
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Enhanced Unit Frames")
        tooltip:AddLine("点击打开设置")
        tooltip:AddLine("右键显示快捷菜单")
    end,
})

LDBIcon:Register("EnhancedUnitFrames", minimapButton, EUF.Database.db.minimap)
```

#### 2.3 自定义实现方案

**代码实现** (GUI/MinimapButton.lua):
```lua
-- 创建小地图按钮框架
local button = CreateFrame("Button", "EUF_MinimapButton", MinimapCluster)
button:SetSize(32, 32)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)

-- 设置图标
button:SetNormalTexture("Interface\\Icons\\INV_Misc_Gear_01")
button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

-- 位置计算（基于小地图角度）
local function UpdatePosition()
    local angle = EUF.Database:Get("minimap", "angle") or 0
    local radius = 80
    local x = radius * cos(angle)
    local y = radius * sin(angle)
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- 拖拽功能
button:SetMovable(true)
button:RegisterForDrag("LeftButton")
button:SetScript("OnDragStart", function(self)
    self:StartMoving()
    IsDragging = true
end)
button:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- 计算新角度并保存
    local mx, my = Minimap:GetCenter()
    local px, py = self:GetCenter()
    local angle = atan2(py - my, px - mx)
    EUF.Database:Set(angle, "minimap", "angle")
end)
```

#### 2.4 右键菜单
- [ ] 开启/关闭职业染色
- [ ] 打开设置面板
- [ ] 重置配置
- [ ] 隐藏小地图按钮

#### 2.5 设置选项
- [ ] 在设置面板添加"显示小地图按钮"选项
- [ ] 添加"重置按钮位置"选项

---

## 文件修改计划

### 新增文件
| 文件 | 说明 |
|------|------|
| `GUI/MinimapButton.lua` | 小地图按钮模块 |
| `Libs/LibDataBroker-1.1.lua` | (可选) 数据代理库 |
| `Libs/LibDBIcon-1.0.lua` | (可选) 小地图图标库 |

### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `GUI/OptionsPanel.lua` | 修复设置面板注册方式 |
| `EnhancedUnitFrames.toc` | 加载新文件和库 |
| `Core/Database.lua` | 添加 minimap 配置默认值 |
| `Core/Core.lua` | 初始化小地图按钮模块 |

---

## Database 扩展

### 新增默认配置
```lua
DEFAULTS_PROFILE = {
    -- ...existing settings...
    minimap = {
        show = true,           -- 显示小地图按钮
        angle = -45,           -- 按钮角度（右上方）
        radius = 80,           -- 距离小地图中心的半径
    },
}
```

---

## Checklist

### 设置面板修复
- [x] 调查 Settings API 正确用法
- [x] 修复 OptionsPanel.lua 注册代码
- [ ] 测试在游戏设置中的显示
- [ ] 确保 `/euf config` 正确打开面板

### 小地图按钮
- [x] 决定实现方案（LibDataBroker vs 自定义）- 选择自定义实现
- [x] 创建 MinimapButton.lua 模块
- [x] 实现左键点击打开设置
- [x] 实现右键快捷菜单
- [x] 实现拖拽定位
- [x] 实现隐藏/显示控制
- [x] 更新 TOC 加载新模块
- [x] 更新 Database 默认值
- [x] 初始化集成到 Core.lua

### 测试
- [ ] 游戏内测试设置面板显示
- [ ] 游戏内测试小地图按钮功能
- [ ] 测试拖拽定位
- [ ] 测试隐藏按钮后恢复方法

---

## 预估工作量

| 任务 | 预估时间 |
|------|----------|
| 设置面板修复 | 1-2h |
| 小地图按钮实现 | 2-3h |
| 测试验证 | 1h |
| **总计** | **4-6h** |

---

## 参考资源

- [WoW API Documentation - Settings](https://wowpedia.fandom.com/wiki/Settings_API)
- [LibDataBroker-1.1](https://github.com/tekkub/libdatabroker-1-1)
- [LibDBIcon-1.0](https://github.com/tekkub/libdbicon-1-0)
- [ClassicCastBars](https://github.com/xorann/ClassicCastBars) - 参考实现