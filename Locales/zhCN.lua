-- zhCN.lua
-- EnhancedUnitFrames 简体中文本地化
-- Simplified Chinese locale

local addonName, EUF = ...

local L = {}

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

L["ADDON_NAME"] = "增强单位框体"
L["ADDON_DESCRIPTION"] = "增强默认的玩家和目标单位框体，支持职业染色、缩放、材质和文字自定义。"
L["ENABLED"] = "已启用"
L["DISABLED"] = "已禁用"
L["RESET"] = "重置"
L["RESET_ALL"] = "重置全部"
L["APPLY"] = "应用"
L["CANCEL"] = "取消"
L["DEFAULT"] = "默认"

-------------------------------------------------------------------------------
-- Settings Panel Titles
-------------------------------------------------------------------------------

L["SETTINGS_TITLE"] = "增强单位框体设置"
L["GENERAL_SETTINGS"] = "通用设置"
L["CLASS_COLORS_SETTINGS"] = "职业染色设置"
L["FRAME_SCALE_SETTINGS"] = "框体缩放设置"
L["TEXTURE_SETTINGS"] = "材质设置"
L["TEXT_SETTINGS"] = "文字设置"
L["ADVANCED_SETTINGS"] = "高级选项"
L["EDIT_MODE_SETTINGS"] = "编辑模式设置"

-------------------------------------------------------------------------------
-- General Options
-------------------------------------------------------------------------------

L["ENABLE_ADDON"] = "启用插件"
L["ENABLE_ADDON_DESC"] = "启用或禁用增强单位框体插件"
L["DEBUG_MODE"] = "调试模式"
L["DEBUG_MODE_DESC"] = "在聊天框输出调试信息"

-------------------------------------------------------------------------------
-- Class Colors
-------------------------------------------------------------------------------

L["ENABLE_CLASS_COLORS"] = "启用职业染色"
L["ENABLE_CLASS_COLORS_DESC"] = "根据单位职业自动着色生命条"
L["COLOR_BACKGROUND"] = "染色背景"
L["COLOR_BACKGROUND_DESC"] = "同时为生命条背景添加职业色"
L["COLOR_BORDER"] = "染色边框"
L["COLOR_BORDER_DESC"] = "为框体边框添加职业色"
L["NPC_REACTION_COLOR"] = "NPC反应色"
L["NPC_REACTION_COLOR_DESC"] = "非玩家单位使用反应色（友好/中立/敌对）"
L["HOSTILE_COLOR"] = "敌对颜色"
L["NEUTRAL_COLOR"] = "中立颜色"
L["FRIENDLY_COLOR"] = "友好颜色"
L["CLASS_COLOR_PREVIEW"] = "职业色预览"

-------------------------------------------------------------------------------
-- Frame Scale
-------------------------------------------------------------------------------

L["PLAYER_FRAME_SCALE"] = "玩家框体缩放"
L["TARGET_FRAME_SCALE"] = "目标框体缩放"
L["FOCUS_FRAME_SCALE"] = "焦点框体缩放"
L["PET_FRAME_SCALE"] = "宠物框体缩放"
L["SCALE_RANGE"] = "缩放范围：50%% - 200%%"
L["SCALE_TIP"] = "提示：战斗中的缩放更改将在脱战后自动应用"
L["RESET_SCALE"] = "重置缩放"

-------------------------------------------------------------------------------
-- Textures
-------------------------------------------------------------------------------

L["HEALTH_BAR_TEXTURE"] = "生命条材质"
L["HEALTH_BAR_TEXTURE_DESC"] = "选择生命条材质样式"
L["MANA_BAR_TEXTURE"] = "法力条材质"
L["MANA_BAR_TEXTURE_DESC"] = "选择法力条材质样式"
L["BORDER_STYLE"] = "边框样式"
L["BORDER_STYLE_DESC"] = "选择框体边框样式"
L["BORDER_COLOR"] = "边框颜色"
L["TEXTURE_PREVIEW"] = "材质预览"

-- Texture Names
L["TEXTURE_BLIZZARD"] = "暴雪默认"
L["TEXTURE_FLAT"] = "扁平"
L["TEXTURE_GRADIENT"] = "渐变"
L["TEXTURE_GLOSSY"] = "光泽"

-- Border Names
L["BORDER_NONE"] = "无"
L["BORDER_ROUNDED"] = "圆角"
L["BORDER_SQUARE"] = "方形"
L["BORDER_BLIZZARD"] = "暴雪默认"

-------------------------------------------------------------------------------
-- Text Settings
-------------------------------------------------------------------------------

L["PLAYER_HEALTH_FORMAT"] = "玩家生命值格式"
L["PLAYER_HEALTH_FORMAT_DESC"] = "选择玩家框体生命值显示格式"
L["TARGET_HEALTH_FORMAT"] = "目标生命值格式"
L["TARGET_HEALTH_FORMAT_DESC"] = "选择目标框体生命值显示格式"
L["SECRET_VALUE_WARNING"] = "(12.0部分格式在战斗中可能受限)"

-- Health Formats
L["FORMAT_DEFAULT"] = "暴雪默认（推荐）"
L["FORMAT_PERCENT"] = "百分比"
L["FORMAT_CURRENT"] = "当前值"
L["FORMAT_CURRENT_MAX"] = "当前/最大"
L["FORMAT_DEFICIT"] = "亏损值"
L["FORMAT_HIDDEN"] = "隐藏"

-------------------------------------------------------------------------------
-- Edit Mode
-------------------------------------------------------------------------------

L["SHOW_IN_EDIT_MODE"] = "在编辑模式中显示"
L["SHOW_IN_EDIT_MODE_DESC"] = "在暴雪编辑模式中显示增强控件"
L["SYNC_WITH_BLIZZARD"] = "与暴雪编辑模式同步"
L["SYNC_WITH_BLIZZARD_DESC"] = "将设置同步到暴雪编辑模式布局"
L["SCALE_DISPLAY"] = "缩放：%.0f%%"

-------------------------------------------------------------------------------
-- Advanced Options
-------------------------------------------------------------------------------

L["EXPORT_CONFIG"] = "导出配置"
L["IMPORT_CONFIG"] = "导入配置"
L["COPY_TO_CLIPBOARD"] = "复制到剪贴板"
L["RESET_CURRENT_PROFILE"] = "重置当前配置"
L["RESET_ALL_CONFIG"] = "重置所有配置"
L["RESET_WARNING"] = "点击重置所有设置为默认值"

-------------------------------------------------------------------------------
-- Combat Messages
-------------------------------------------------------------------------------

L["COMBAT_SCALE_PENDING"] = "战斗中：缩放设置将在脱战后应用"
L["COMBAT_MOVE_BLOCKED"] = "战斗中无法移动框体"
L["COMBAT_EDIT_BLOCKED"] = "战斗中无法进入编辑模式"
L["COMBAT_SCALE_BLOCKED"] = "战斗中无法调整缩放"
L["COMBAT_PENDING_APPLIED"] = "待处理更改已应用"

-------------------------------------------------------------------------------
-- Chat Messages
-------------------------------------------------------------------------------

L["CONFIG_RESET"] = "配置已重置"
L["CONFIG_IMPORTED"] = "配置导入成功"
L["CONFIG_EXPORTED"] = "配置已导出"
L["SCALE_APPLIED"] = "缩放已应用：%s -> %.0f%%"
L["ADDON_LOADED"] = "增强单位框体已加载。输入 /euf 打开设置。"

-------------------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------------------

L["SLASH_HELP"] = "可用命令："
L["SLASH_DEBUG"] = "/euf debug - 切换调试模式"
L["SLASH_RESET"] = "/euf reset - 重置所有设置"
L["SLASH_SCALE"] = "/euf scale <框体> <值> - 设置框体缩放 (0.5-2.0)"
L["SLASH_COLOR"] = "/euf color - 切换职业染色"
L["SLASH_CONFIG"] = "/euf config - 打开设置面板"
L["SLASH_MINIMAP"] = "/euf minimap [show|hide|reset] - 小地图按钮控制"

-------------------------------------------------------------------------------
-- Minimap Button
-------------------------------------------------------------------------------

L["MINIMAP_BUTTON_TOOLTIP_TITLE"] = "增强单位框体"
L["MINIMAP_BUTTON_TOOLTIP_LEFT"] = "左键：打开设置"
L["MINIMAP_BUTTON_TOOLTIP_RIGHT"] = "右键：快捷菜单"
L["MINIMAP_BUTTON_TOOLTIP_DRAG"] = "拖拽：移动按钮位置"
L["MINIMAP_BUTTON_SHOW"] = "显示小地图按钮"
L["MINIMAP_BUTTON_SHOW_DESC"] = "在小地图旁显示快捷按钮"
L["MINIMAP_BUTTON_LOCK"] = "锁定按钮位置"
L["MINIMAP_BUTTON_LOCK_DESC"] = "锁定小地图按钮位置，禁止拖拽"
L["MINIMAP_BUTTON_RESET"] = "重置按钮位置"
L["MINIMAP_BUTTON_HIDDEN"] = "小地图按钮已隐藏，使用 /euf minimap show 重新显示"
L["MINIMAP_BUTTON_SHOWN"] = "小地图按钮已显示"
L["MINIMAP_BUTTON_RESET_POS"] = "小地图按钮位置已重置"

-------------------------------------------------------------------------------
-- Context Menu
-------------------------------------------------------------------------------

L["MENU_OPEN_SETTINGS"] = "打开设置"
L["MENU_CLASS_COLORS"] = "职业染色"
L["MENU_LOCK_BUTTON"] = "锁定按钮位置"
L["MENU_HIDE_BUTTON"] = "隐藏按钮"
L["MENU_RESET_CONFIG"] = "重置配置"

-------------------------------------------------------------------------------
-- Frame Names
-------------------------------------------------------------------------------

L["FRAME_PLAYER"] = "玩家框体"
L["FRAME_TARGET"] = "目标框体"
L["FRAME_FOCUS"] = "焦点框体"
L["FRAME_PET"] = "宠物框体"

-------------------------------------------------------------------------------
-- Class Names (Chinese)
-------------------------------------------------------------------------------

L["CLASS_WARRIOR"] = "战士"
L["CLASS_PALADIN"] = "圣骑士"
L["CLASS_HUNTER"] = "猎人"
L["CLASS_ROGUE"] = "盗贼"
L["CLASS_PRIEST"] = "牧师"
L["CLASS_SHAMAN"] = "萨满"
L["CLASS_MAGE"] = "法师"
L["CLASS_WARLOCK"] = "术士"
L["CLASS_DRUID"] = "德鲁伊"
L["CLASS_DEATHKNIGHT"] = "死亡骑士"
L["CLASS_MONK"] = "武僧"
L["CLASS_DEMONHUNTER"] = "恶魔猎手"
L["CLASS_EVOKER"] = "唤魔师"

-------------------------------------------------------------------------------
-- Register Locale
-------------------------------------------------------------------------------

EUF.Locale_zhCN = L

return L