-- zhTW.lua
-- EnhancedUnitFrames 繁體中文本地化
-- Traditional Chinese locale (Optional)

local addonName, EUF = ...

local L = {}

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

L["ADDON_NAME"] = "增強單位框架"
L["ADDON_DESCRIPTION"] = "增強預設的玩家和目標單位框架，支援職業染色、缩放、材質和文字自訂。"
L["ENABLED"] = "已啟用"
L["DISABLED"] = "已停用"
L["RESET"] = "重置"
L["RESET_ALL"] = "重置全部"
L["APPLY"] = "套用"
L["CANCEL"] = "取消"
L["DEFAULT"] = "預設"

-------------------------------------------------------------------------------
-- Settings Panel Titles
-------------------------------------------------------------------------------

L["SETTINGS_TITLE"] = "增強單位框架設定"
L["GENERAL_SETTINGS"] = "一般設定"
L["CLASS_COLORS_SETTINGS"] = "職業染色設定"
L["FRAME_SCALE_SETTINGS"] = "框架缩放設定"
L["TEXTURE_SETTINGS"] = "材質設定"
L["TEXT_SETTINGS"] = "文字設定"
L["ADVANCED_SETTINGS"] = "進階選項"
L["EDIT_MODE_SETTINGS"] = "編輯模式設定"

-------------------------------------------------------------------------------
-- General Options
-------------------------------------------------------------------------------

L["ENABLE_ADDON"] = "啟用插件"
L["ENABLE_ADDON_DESC"] = "啟用或停用增強單位框架插件"
L["DEBUG_MODE"] = "除錯模式"
L["DEBUG_MODE_DESC"] = "在聊天框輸出除錯資訊"

-------------------------------------------------------------------------------
-- Class Colors
-------------------------------------------------------------------------------

L["ENABLE_CLASS_COLORS"] = "啟用職業染色"
L["ENABLE_CLASS_COLORS_DESC"] = "根據單位職業自動著色生命條"
L["COLOR_BACKGROUND"] = "染色背景"
L["COLOR_BACKGROUND_DESC"] = "同時為生命條背景添加職業色"
L["COLOR_BORDER"] = "染色邊框"
L["COLOR_BORDER_DESC"] = "為框架邊框添加職業色"
L["NPC_REACTION_COLOR"] = "NPC反應色"
L["NPC_REACTION_COLOR_DESC"] = "非玩家單位使用反應色（友好/中立/敵對）"
L["HOSTILE_COLOR"] = "敵對顏色"
L["NEUTRAL_COLOR"] = "中立顏色"
L["FRIENDLY_COLOR"] = "友好顏色"
L["CLASS_COLOR_PREVIEW"] = "職業色預覽"

-------------------------------------------------------------------------------
-- Frame Scale
-------------------------------------------------------------------------------

L["PLAYER_FRAME_SCALE"] = "玩家框架缩放"
L["TARGET_FRAME_SCALE"] = "目標框架缩放"
L["FOCUS_FRAME_SCALE"] = "焦點框架缩放"
L["PET_FRAME_SCALE"] = "寵物框架缩放"
L["SCALE_RANGE"] = "缩放範圍：50%% - 200%%"
L["SCALE_TIP"] = "提示：戰鬥中的缩放更改将在脱戰後自動套用"
L["RESET_SCALE"] = "重置缩放"

-------------------------------------------------------------------------------
-- Textures
-------------------------------------------------------------------------------

L["HEALTH_BAR_TEXTURE"] = "生命條材質"
L["HEALTH_BAR_TEXTURE_DESC"] = "選擇生命條材質樣式"
L["MANA_BAR_TEXTURE"] = "法力條材質"
L["MANA_BAR_TEXTURE_DESC"] = "選擇法力條材質樣式"
L["BORDER_STYLE"] = "邊框樣式"
L["BORDER_STYLE_DESC"] = "選擇框架邊框樣式"
L["BORDER_COLOR"] = "邊框顏色"
L["TEXTURE_PREVIEW"] = "材質預覽"

-- Texture Names
L["TEXTURE_BLIZZARD"] = "暴雪預設"
L["TEXTURE_FLAT"] = "扁平"
L["TEXTURE_GRADIENT"] = "漸變"
L["TEXTURE_GLOSSY"] = "光澤"

-- Border Names
L["BORDER_NONE"] = "無"
L["BORDER_ROUNDED"] = "圓角"
L["BORDER_SQUARE"] = "方形"
L["BORDER_BLIZZARD"] = "暴雪預設"

-------------------------------------------------------------------------------
-- Text Settings
-------------------------------------------------------------------------------

L["PLAYER_HEALTH_FORMAT"] = "玩家生命值格式"
L["PLAYER_HEALTH_FORMAT_DESC"] = "選擇玩家框架生命值顯示格式"
L["TARGET_HEALTH_FORMAT"] = "目標生命值格式"
L["TARGET_HEALTH_FORMAT_DESC"] = "選擇目標框架生命值顯示格式"
L["SECRET_VALUE_WARNING"] = "(12.0部分格式在戰鬥中可能受限)"

-- Health Formats
L["FORMAT_DEFAULT"] = "暴雪預設（推薦）"
L["FORMAT_PERCENT"] = "百分比"
L["FORMAT_CURRENT"] = "當前值"
L["FORMAT_CURRENT_MAX"] = "當前/最大"
L["FORMAT_DEFICIT"] = "虧損值"
L["FORMAT_HIDDEN"] = "隱藏"

-------------------------------------------------------------------------------
-- Edit Mode
-------------------------------------------------------------------------------

L["SHOW_IN_EDIT_MODE"] = "在編輯模式中顯示"
L["SHOW_IN_EDIT_MODE_DESC"] = "在暴雪編輯模式中顯示增強控件"
L["SYNC_WITH_BLIZZARD"] = "與暴雪編輯模式同步"
L["SYNC_WITH_BLIZZARD_DESC"] = "將設定同步到暴雪編輯模式佈局"
L["SCALE_DISPLAY"] = "缩放：%.0f%%"

-------------------------------------------------------------------------------
-- Advanced Options
-------------------------------------------------------------------------------

L["EXPORT_CONFIG"] = "匯出設定"
L["IMPORT_CONFIG"] = "匯入設定"
L["COPY_TO_CLIPBOARD"] = "複製到剪貼簿"
L["RESET_CURRENT_PROFILE"] = "重置當前設定"
L["RESET_ALL_CONFIG"] = "重置所有設定"
L["RESET_WARNING"] = "點擊重置所有設定為預設值"

-------------------------------------------------------------------------------
-- Combat Messages
-------------------------------------------------------------------------------

L["COMBAT_SCALE_PENDING"] = "戰鬥中：缩放設定将在脱戰後套用"
L["COMBAT_MOVE_BLOCKED"] = "戰鬥中無法移動框架"
L["COMBAT_EDIT_BLOCKED"] = "戰鬥中無法進入編輯模式"
L["COMBAT_SCALE_BLOCKED"] = "戰鬥中無法調整缩放"
L["COMBAT_PENDING_APPLIED"] = "待處理更改已套用"

-------------------------------------------------------------------------------
-- Chat Messages
-------------------------------------------------------------------------------

L["CONFIG_RESET"] = "設定已重置"
L["CONFIG_IMPORTED"] = "設定匯入成功"
L["CONFIG_EXPORTED"] = "設定已匯出"
L["SCALE_APPLIED"] = "缩放已套用：%s -> %.0f%%"
L["ADDON_LOADED"] = "增強單位框架已載入。輸入 /euf 打開設定。"

-------------------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------------------

L["SLASH_HELP"] = "可用命令："
L["SLASH_DEBUG"] = "/euf debug - 切換除錯模式"
L["SLASH_RESET"] = "/euf reset - 重置所有設定"
L["SLASH_SCALE"] = "/euf scale <框架> <值> - 設定框架缩放 (0.5-2.0)"
L["SLASH_COLOR"] = "/euf color - 切換職業染色"
L["SLASH_CONFIG"] = "/euf config - 打開設定面板"

-------------------------------------------------------------------------------
-- Frame Names
-------------------------------------------------------------------------------

L["FRAME_PLAYER"] = "玩家框架"
L["FRAME_TARGET"] = "目標框架"
L["FRAME_FOCUS"] = "焦點框架"
L["FRAME_PET"] = "寵物框架"

-------------------------------------------------------------------------------
-- Class Names (Traditional Chinese)
-------------------------------------------------------------------------------

L["CLASS_WARRIOR"] = "戰士"
L["CLASS_PALADIN"] = "聖騎士"
L["CLASS_HUNTER"] = "獵人"
L["CLASS_ROGUE"] = "盜贼"
L["CLASS_PRIEST"] = "牧師"
L["CLASS_SHAMAN"] = "薩滿"
L["CLASS_MAGE"] = "法師"
L["CLASS_WARLOCK"] = "術士"
L["CLASS_DRUID"] = "德魯伊"
L["CLASS_DEATHKNIGHT"] = "死亡騎士"
L["CLASS_MONK"] = "武僧"
L["CLASS_DEMONHUNTER"] = "惡魔獵手"
L["CLASS_EVOKER"] = "唤魔師"

-------------------------------------------------------------------------------
-- Register Locale
-------------------------------------------------------------------------------

EUF.Locale_zhTW = L

return L