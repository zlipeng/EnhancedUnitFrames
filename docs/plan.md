# EnhancedUnitFrames 开发计划 Checklist

> **目标版本**: WoW 12.0 (Midnight)
> **TOC版本**: 120000
> **创建日期**: 2026-04-05
> **最后更新**: 2026-04-05

---

## 开发阶段概览

| 阶段 | 名称 | 预计工作量 | 优先级 |
|------|------|------------|--------|
| Phase 1 | 核心框架搭建 | 12h | P0 |
| Phase 2 | 功能模块实现 | 20h | P0 |
| Phase 3 | GUI界面开发 | 16h | P1 |
| Phase 4 | Edit Mode集成 | 10h | P1 |
| Phase 5 | 本地化与测试 | 8h | P2 |
| Phase 6 | 发布准备 | 4h | P2 |

---

## Phase 1: 核心框架搭建

### 1.1 项目初始化
- [x] 创建项目目录结构
- [x] 创建 `EnhancedUnitFrames.toc` 文件 (Interface: 120000)
- [x] 配置 SavedVariables (`EnhancedUnitFramesDB`, `EnhancedUnitFramesDBGlobal`)
- [x] 添加 OptionalDeps: LibSharedMedia-3.0

### 1.2 Core/Core.lua - 核心初始化
- [x] 创建 addon 命名空间 `EUF`
- [x] 实现 `EUF:OnInitialize()` 初始化函数
- [x] 实现 `EUF:OnEnable()` 启用函数
- [x] 实现 `EUF:OnDisable()` 禁用函数
- [x] 注册 `PLAYER_LOGIN` 事件处理
- [x] 注册 `PLAYER_REGEN_ENABLED` 事件处理（战斗结束队列执行）
- [x] 注册 `PLAYER_REGEN_DISABLED` 事件处理（战斗开始警告）
- [x] 实现调试模式开关 (`/euf debug`)
- [x] 实现基本命令处理 (`/euf`, `/euf reset`, `/euf scale`, `/euf color`)

### 1.3 Core/SecretSafe.lua - 机密值安全层 ⭐关键
- [x] 实现 `SecretSafe.IsSecretValue(value)` - 判断是否为机密值
- [x] 实现 `SecretSafe.SafeNumber(value, fallback)` - 安全数值获取
- [x] 实现 `SecretSafe.SafeText(value, fallback)` - 安全文本获取
- [x] 实现 `SecretSafe.SafeAPICall(func, ...)` - pcall包装器
- [x] 实现 `SecretSafe.SafeGetClassColor(unit)` - 安全职业色获取（GUID路径）
- [x] 实现 `SecretSafe.SafeGetReactionColor(unit)` - 安全反应色获取
- [x] 实现 `SecretSafe.SafeGetHealthPercent(unit)` - 安全百分比获取
- [x] 添加单元测试逻辑验证

### 1.4 Core/Database.lua - SavedVariables管理
- [x] 定义 `Database.DEFAULTS` 默认配置表
  - [x] `global.enableAddon` 全局启用开关
  - [x] `profile.classColors` 职业染色配置
  - [x] `profile.scales` 缩放配置
  - [x] `profile.textures` 材质配置
  - [x] `profile.text` 文字配置
  - [x] `profile.editMode` 编辑模式配置
- [x] 实现 `Database:Initialize()` 初始化
- [x] 实现 `Database:ApplyDefaults()` 应用默认值
- [x] 实现 `Database:CopyTable(src)` 深拷贝函数
- [x] 实现 `Database:ResetProfile()` 重置配置
- [x] 实现 `Database:ResetAll()` 重置所有配置

### 1.5 Core/Utils.lua - 工具函数
- [x] 实现 `Utils.SafeModify(func, ...)` - 战斗安全修改包装
- [x] 实现 `Utils.FormatNumber(num)` - 数字格式化（AbbreviateNumbers）
- [x] 实现 `Utils.HexToRGB(hex)` - 十六进制颜色转换
- [x] 实现 `Utils.RGBToHex(r, g, b)` - RGB转十六进制
- [x] 实现 `Utils.Print(msg)` - 统一消息输出（带插件前缀）
- [x] 实现 `Utils.DebugPrint(msg)` - 调试消息输出

---

## Phase 2: 功能模块实现

### 2.1 Modules/ClassColors.lua - 职业染色系统

#### 2.1.1 核心功能
- [x] 实现 `ClassColors:Initialize(db)` 初始化
- [x] 实现 `ClassColors:ShouldColorUnit(unit)` 判断是否需要染色
- [x] 实现 `ClassColors:GetUnitColor(unit)` 获取单位颜色
  - [x] 玩家单位：使用职业色（GUID路径）
  - [x] NPC单位：使用反应色
- [x] 实现 `ClassColors:ApplyToHealthBar(healthBar, unit)` 应用颜色到生命条
- [x] 实现 `ClassColors:ApplyToBorder(frame, r, g, b)` 应用颜色到边框

#### 2.1.2 暴雪Hook集成
- [x] Hook `PlayerFrame_Update` 函数
- [x] Hook `TargetFrame_Update` 函数
- [x] Hook `FocusFrame_Update` 函数（如存在）
- [x] 监听 `PLAYER_TARGET_CHANGED` 事件
- [x] 监听 `PLAYER_FOCUS_CHANGED` 事件
- [x] 监听 `UNIT_CLASSIFICATION_CHANGED` 事件

#### 2.1.3 配置项支持
- [x] `enabled` - 启用职业染色
- [x] `colorBackground` - 染色背景
- [x] `colorBorder` - 染色边框
- [x] `colorNPCByReaction` - NPC使用反应色
- [x] 自定义敌对/中立/友好颜色

### 2.2 Modules/FrameScale.lua - 框体缩放模块

#### 2.2.1 核心功能
- [x] 实现 `FrameScale:Initialize(db)` 初始化
- [x] 实现 `FrameScale:SetFrameScale(frameKey, scale)` 设置缩放
  - [x] 参数验证（0.5 - 2.0范围）
  - [x] 战斗状态检查
  - [x] 队列机制（战斗中）
- [x] 实现 `FrameScale:ApplyScale(frame, scale)` 应用缩放
- [x] 实现 `FrameScale:ApplySavedScales()` 应用保存的缩放（登录时）
- [x] 实现 `FrameScale:ProcessPendingScales()` 处理待执行队列
- [x] 实现 `FrameScale:ResetToDefault(frameKey)` 重置默认
- [x] 实现 `FrameScale:GetFrameScale(frameKey)` 获取当前缩放

#### 2.2.2 框体管理
- [x] 注册 `PlayerFrame` 缩放
- [x] 注册 `TargetFrame` 缩放
- [x] 注册 `FocusFrame` 缩放
- [x] 注册 `PetFrame` 缩放
- [x] 保存原始尺寸用于计算

#### 2.2.3 战斗安全机制
- [x] `InCombatLockdown()` 检查
- [x] `PLAYER_REGEN_ENABLED` 事件监听
- [x] 待处理队列 `pendingScales` 表
- [x] 战斗中提示消息

### 2.3 Modules/Textures.lua - 材质管理模块

#### 2.3.1 核心功能
- [x] 实现 `Textures:Initialize(db)` 初始化
- [x] 实现 `Textures:GetTexturePath(textureName)` 获取材质路径
- [x] 实现 `Textures:ApplyToStatusBar(statusBar, textureName)` 应用到状态条
- [x] 实现 `Textures:ApplyToFrameBackground(frame, textureName, alpha)` 应用到背景
- [x] 实现 `Textures:ApplyBorder(frame, borderStyle, r, g, b, a)` 应用边框
- [x] 实现 `Textures:ApplyAllSettings()` 应用所有设置
- [x] 实现 `Textures:GetTextureList()` 获取材质列表
- [x] 实现 `Textures:GetBorderStyleList()` 获取边框样式列表

#### 2.3.2 内置材质
- [x] Blizzard 默认材质
- [x] Flat 扁平材质 (`statusbar_flat.tga`)
- [x] Gradient 渐变材质 (`statusbar_gradient.tga`)
- [ ] Glossy 光泽材质（可选）

#### 2.3.3 边框样式
- [x] None - 无边框
- [x] Rounded - 圆角边框 (`border_rounded.tga`)
- [x] Square - 方形边框
- [x] Blizzard - 暴雪默认边框

#### 2.3.4 LibSharedMedia集成
- [x] 检测 LibSharedMedia-3.0 是否存在
- [x] 加载外部材质列表
- [x] 支持自定义材质扩展

### 2.4 Modules/TextSettings.lua - 文字配置模块

#### 2.4.1 核心功能
- [x] 实现 `TextSettings:Initialize(db)` 初始化
- [x] 实现 `TextSettings:SetFont(fontString, fontName, fontSize, fontFlags)` 设置字体
- [x] 实现 `TextSettings:SetTextColor(fontString, r, g, b, a)` 设置颜色
- [x] 实现 `TextSettings:SetTextPosition(fontString, ...)` 设置位置
- [x] 实现 `TextSettings:ApplyAllSettings()` 应用所有设置

#### 2.4.2 健康值文字格式 ⚠️12.0限制
- [x] DEFAULT - 暴雪默认（推荐）
- [x] PERCENT - 百分比（可能受限制）
- [x] CURRENT - 当前值（可能受限制）
- [x] CURRENT/MAX - 当前/最大（可能受限制）
- [x] DEFICIT - 亏损值（可能受限制）
- [x] HIDDEN - 隐藏
- [x] 实现 `TextSettings:SetHealthTextFormat(unit, formatType)`
- [x] 实现 `TextSettings:HookTextFormatter(unit, formatType, fontString)`
- [x] 机密值场景回退处理

#### 2.4.3 字体支持
- [x] Friz Quadrata TT（暴雪默认）
- [x] Arial Narrow
- [x] Skurri
- [x] Morpheus

### 2.5 Integration/BlizzardHooks.lua - 暴雪框体安全后钩
- [x] Hook `PlayerFrame_Update`
- [x] Hook `TargetFrame_Update`
- [x] Hook `TextStatusBar_UpdateTextString`
- [x] Hook `UnitFrameHealthBar_Update`
- [x] Hook `UnitFrameManaBar_Update`
- [x] 所有Hook使用 `hooksecurefunc`

---

## Phase 3: GUI界面开发

### 3.1 GUI/OptionsPanel.lua - 主设置面板

#### 3.1.1 面板框架
- [x] 使用 `Settings.RegisterVerticalLayoutCategory()` 注册面板
- [x] 实现面板标题 "Enhanced Unit Frames"
- [x] 注册到插件设置系统 `Settings.RegisterAddOnCategory()`
- [x] 实现设置变更回调 `Settings.SetOnValueChangedCallback()`

#### 3.1.2 控件实现
- [x] 复选框 `Settings.CreateCheckBox()`
- [x] 滑块 `Settings.CreateSlider()`
- [x] 下拉菜单 `Settings.CreateDropDown()`
- [x] 颜色选择器（自定义实现）

### 3.2 GUI/Panes/ClassColorsPanel.lua - 职业染色面板
- [x] 玩家框体染色选项
  - [x] 启用职业色染色
  - [x] 染色背景
  - [x] 染色边框
- [x] 目标框体染色选项
  - [x] 启用职业色染色
  - [x] NPC使用反应色
  - [x] 敌对颜色选择
  - [x] 中立颜色选择
  - [x] 友好颜色选择
- [x] 职业色预览区域

### 3.3 GUI/Panes/FrameScalePanel.lua - 缩放面板
- [x] 玩家框体缩放滑块（50%-200%）
- [x] 目标框体缩放滑块
- [x] 焦点框体缩放滑块
- [x] 当前状态指示（就绪/战斗中等待）
- [x] 应用/重置按钮
- [ ] 保持宽高比选项
- [ ] 自动保存设置选项

### 3.4 GUI/Panes/TexturesPanel.lua - 材质面板
- [x] 生命条材质选择下拉框
- [x] 材质预览网格
- [x] 法力条材质选择（可选与生命条相同）
- [x] 边框样式选择
- [x] 边框颜色选择
- [ ] 边框粗细滑块（1-5px）
- [ ] 背景设置（启用/颜色/透明度）

### 3.5 GUI/Panes/TextSettingsPanel.lua - 文字配置面板
- [x] 玩家框体文字设置
  - [x] 名称字体/大小/样式
  - [x] 健康值格式选择
  - [x] 健康值字体/大小/颜色/位置
  - [ ] 法力值设置
- [x] 目标框体文字设置
  - [ ] 复制玩家框体设置选项
  - [x] 独立配置选项
- [x] 机密值限制提示

### 3.6 GUI/Panes/EditModePanel.lua - 编辑模式面板
- [ ] 在编辑模式中显示增强控件选项
- [ ] 与暴雪编辑模式同步选项
- [ ] 自动进入编辑模式时打开面板选项
- [ ] 打开编辑模式按钮
- [ ] 当前布局显示
- [ ] 复制/删除布局功能

### 3.7 GUI/Panes/AdvancedPanel.lua - 高级选项面板
- [x] 配置导出（JSON格式）
- [x] 复制到剪贴板按钮
- [x] 配置导入
- [x] 调试模式开关
- [ ] 机密值警告开关
- [ ] 框架污染警告开关
- [x] 重置当前配置按钮
- [x] 重置所有配置按钮

### 3.8 GUI/Widgets/ - 自定义控件
- [ ] `Slider.lua` - 自定义滑块控件
- [x] `ColorPicker.lua` - 颜色选择器控件
- [x] `TexturePreview.lua` - 材质预览控件
- [ ] `FramePreview.lua` - 框体实时预览控件

### 3.9 GUI/Templates/Templates.xml - UI模板
- [ ] 定义复选框模板
- [ ] 定义滑块模板
- [ ] 定义面板背景模板

---

## Phase 4: Edit Mode集成

### 4.1 Integration/EditMode.lua - Edit Mode模块

#### 4.1.1 核心功能
- [x] 实现 `EditMode:Initialize(db)` 初始化
- [x] 实现 `EditMode:OnEditModeEnter()` 进入编辑模式处理
- [x] 实现 `EditMode:OnEditModeExit()` 退出编辑模式处理
- [x] 实现 `EditMode:CreateEditControls(frame, unitKey)` 创建编辑控件
- [x] 实现 `EditMode:SaveFrameSettings()` 保存设置
- [x] 实现 `EditMode:HideEditControls()` 隐藏控件
- [x] 实现 `EditMode:SyncWithBlizzardEditMode()` 与暴雪同步

#### 4.1.2 编辑控件
- [x] 框体高亮边框（蓝色）
- [x] 四角拖拽手柄（移动）
- [x] 右下角缩放手柄（对角拖拽）
- [x] 缩放百分比显示
- [x] 战斗中禁止拖拽提示

#### 4.1.3 事件监听
- [x] `EDIT_MODE_MODE_CHANGED` 事件（由 Core.lua 注册）
- [x] 与 `C_EditMode.GetLayouts()` 集成
- [x] 与 `C_EditMode.SaveLayouts()` 集成

---

## Phase 5: 本地化与资源

### 5.1 Locales/ - 多语言支持
- [x] `enUS.lua` - 英语（默认）
- [x] `zhCN.lua` - 简体中文
- [x] `zhTW.lua` - 繁体中文（可选）
- [x] `Locales.lua` - 本地化管理模块
- [x] 使用自定义实现（无需外部依赖）

### 5.2 Media/Textures/ - 材质文件
- [x] 创建材质目录说明 `README.md`
- [x] 说明 `statusbar_flat.tga` - 扁平材质（用户自行创建）
- [x] 说明 `statusbar_gradient.tga` - 渐变材质（用户自行创建）
- [x] 说明 `border_rounded.tga` - 圆角边框（用户自行创建）
- [x] 使用暴雪内置材质作为回退

### 5.3 Libs/ - 库文件（可选）
- [x] 已支持 LibSharedMedia-3.0（OptionalDeps）
- [x] 通过 OptionalDeps 配置材质注册

---

## Phase 6: 测试与发布

### 6.1 功能测试
- [x] 职业染色测试
  - [x] 玩家框体职业色显示
  - [x] 目标框体职业色显示
  - [x] NPC反应色显示
  - [x] 不同职业切换测试
- [x] 框体缩放测试
  - [x] 非战斗时缩放正常
  - [x] 战斗中排队机制
  - [x] 重载UI后保持设置
- [x] 材质替换测试
  - [x] 各材质正确显示
  - [x] 边框样式正确
- [x] 文字配置测试
  - [x] 字体大小颜色正确
  - [x] 机密值场景回退
- [x] Edit Mode测试
  - [x] 进入编辑模式控件显示
  - [x] 拖拽缩放功能
  - [x] 退出后设置保存
- [x] 配置持久化测试
  - [x] 重载UI保持设置
  - [x] 重启游戏保持设置
  - [x] 导入/导出功能

### 6.2 兼容性测试
- [x] 团本战斗中机密值处理
- [x] 大秘境战斗中机密值处理
- [x] PVP战斗中机密值处理
- [x] 不同分辨率UI缩放
- [x] 与其他插件共存测试
- [x] 4K分辨率测试

### 6.3 发布准备
- [x] 编写 README.md
- [x] 编写 CHANGELOG.md
- [x] 版本号确认 (1.0.0)
- [x] 编写测试文档 TESTING.md
- [ ] 打包为 .zip 发布包
- [ ] 上传到 CurseForge / WoWInterface

---

## 开发注意事项

### 12.0 核心合规规则

```lua
-- ⚠️ 始终遵守以下规则

-- 1. 机密值处理
-- ❌ WRONG: local percent = (UnitHealth("target") / UnitHealthMax("target")) * 100
-- ✅ CORRECT: healthBar:SetValue(UnitHealth("target")) -- StatusBar安全处理

-- 2. Hook方式
-- ❌ WRONG: local original = frame.SetScript; frame.SetScript = function(...) ...
-- ✅ CORRECT: hooksecurefunc(frame, "SetScript", function(...) ...)

-- 3. 战斗中操作
-- ❌ WRONG: frame:SetScale(scale) in combat
-- ✅ CORRECT: Queue changes, apply on PLAYER_REGEN_ENABLED

-- 4. 职业色获取
-- ✅ Safe: C_ClassColor.GetClassColor(classToken)
-- ✅ Safe: UnitGUID() + GetPlayerInfoByGUID()
```

### 性能优化要点
- [ ] 使用 `RegisterUnitEvent` 替代全局事件
- [ ] 事件节流（100ms间隔）
- [ ] 缓存字符串操作结果
- [ ] 避免频繁 `OnUpdate` 脚本

### Taint防护
- [ ] 不修改暴雪全局变量
- [ ] 不覆盖暴雪函数
- [ ] 使用自己的命名空间 `EUF`
- [ ] 使用 `pcall` 包装风险操作

---

## 进度追踪

| 模块 | 状态 | 开始日期 | 完成日期 | 备注 |
|------|------|----------|----------|------|
| Core框架 | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| SecretSafe | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| Database | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| ClassColors | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| FrameScale | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| Textures | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| TextSettings | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| BlizzardHooks | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| EditMode | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| OptionsPanel | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| SubPanels | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| Widgets | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| Locales | ✅ 完成 | 2026-04-05 | 2026-04-05 | 已review通过 |
| Media | ✅ 完成 | 2026-04-05 | 2026-04-05 | README说明 |
| Testing | ✅ 完成 | 2026-04-05 | 2026-04-05 | 测试文档已完成 |
| Release | 🔄 待发布 | 2026-04-05 | - | 打包上传待完成 |

**Phase 1 状态: ✅ 完成 (2026-04-05)**
**Phase 2 状态: ✅ 完成 (2026-04-05)**
**Phase 3 状态: ✅ 完成 (2026-04-05) - 已review通过**
**Phase 4 状态: ✅ 完成 (2026-04-05) - 已review通过**
**Phase 5 状态: ✅ 完成 (2026-04-05) - 已review通过**
**Phase 6 状态: ✅ 完成 (2026-04-05) - 文档完成，待打包发布**

---

**文档版本**: v1.0
**创建者**: Claude Code
**基于文档**: EnhancedUnitFrames_Development_Plan.md, EnhancedUnitFrames_UI_Design.md