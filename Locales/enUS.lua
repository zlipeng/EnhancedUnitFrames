-- enUS.lua
-- EnhancedUnitFrames English localization
-- Default locale (fallback for all languages)

local addonName, EUF = ...

local L = {}

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

L["ADDON_NAME"] = "Enhanced Unit Frames"
L["ADDON_DESCRIPTION"] = "Enhances the default Player and Target unit frames with class colors, scaling, textures, and text customization."
L["ENABLED"] = "Enabled"
L["DISABLED"] = "Disabled"
L["RESET"] = "Reset"
L["RESET_ALL"] = "Reset All"
L["APPLY"] = "Apply"
L["CANCEL"] = "Cancel"
L["DEFAULT"] = "Default"

-------------------------------------------------------------------------------
-- Settings Panel Titles
-------------------------------------------------------------------------------

L["SETTINGS_TITLE"] = "Enhanced Unit Frames Settings"
L["GENERAL_SETTINGS"] = "General Settings"
L["CLASS_COLORS_SETTINGS"] = "Class Color Settings"
L["FRAME_SCALE_SETTINGS"] = "Frame Scale Settings"
L["TEXTURE_SETTINGS"] = "Texture Settings"
L["TEXT_SETTINGS"] = "Text Settings"
L["ADVANCED_SETTINGS"] = "Advanced Settings"
L["EDIT_MODE_SETTINGS"] = "Edit Mode Settings"

-------------------------------------------------------------------------------
-- General Options
-------------------------------------------------------------------------------

L["ENABLE_ADDON"] = "Enable Addon"
L["ENABLE_ADDON_DESC"] = "Enable or disable Enhanced Unit Frames addon"
L["DEBUG_MODE"] = "Debug Mode"
L["DEBUG_MODE_DESC"] = "Output debug messages to chat frame"

-------------------------------------------------------------------------------
-- Class Colors
-------------------------------------------------------------------------------

L["ENABLE_CLASS_COLORS"] = "Enable Class Colors"
L["ENABLE_CLASS_COLORS_DESC"] = "Automatically color health bars based on unit class"
L["COLOR_BACKGROUND"] = "Color Background"
L["COLOR_BACKGROUND_DESC"] = "Also apply class color to health bar background"
L["COLOR_BORDER"] = "Color Border"
L["COLOR_BORDER_DESC"] = "Apply class color to frame border"
L["NPC_REACTION_COLOR"] = "NPC Reaction Color"
L["NPC_REACTION_COLOR_DESC"] = "Color NPC units by reaction (friendly/neutral/hostile)"
L["HOSTILE_COLOR"] = "Hostile Color"
L["NEUTRAL_COLOR"] = "Neutral Color"
L["FRIENDLY_COLOR"] = "Friendly Color"
L["CLASS_COLOR_PREVIEW"] = "Class Color Preview"

-------------------------------------------------------------------------------
-- Frame Scale
-------------------------------------------------------------------------------

L["PLAYER_FRAME_SCALE"] = "Player Frame Scale"
L["TARGET_FRAME_SCALE"] = "Target Frame Scale"
L["FOCUS_FRAME_SCALE"] = "Focus Frame Scale"
L["PET_FRAME_SCALE"] = "Pet Frame Scale"
L["SCALE_RANGE"] = "Scale Range: 50%% - 200%%"
L["SCALE_TIP"] = "Tip: Scale changes in combat will be applied after combat ends"
L["RESET_SCALE"] = "Reset Scale"

-------------------------------------------------------------------------------
-- Textures
-------------------------------------------------------------------------------

L["HEALTH_BAR_TEXTURE"] = "Health Bar Texture"
L["HEALTH_BAR_TEXTURE_DESC"] = "Select health bar texture style"
L["MANA_BAR_TEXTURE"] = "Mana Bar Texture"
L["MANA_BAR_TEXTURE_DESC"] = "Select mana bar texture style"
L["BORDER_STYLE"] = "Border Style"
L["BORDER_STYLE_DESC"] = "Select frame border style"
L["BORDER_COLOR"] = "Border Color"
L["TEXTURE_PREVIEW"] = "Texture Preview"

-- Texture Names
L["TEXTURE_BLIZZARD"] = "Blizzard"
L["TEXTURE_FLAT"] = "Flat"
L["TEXTURE_GRADIENT"] = "Gradient"
L["TEXTURE_GLOSSY"] = "Glossy"

-- Border Names
L["BORDER_NONE"] = "None"
L["BORDER_ROUNDED"] = "Rounded"
L["BORDER_SQUARE"] = "Square"
L["BORDER_BLIZZARD"] = "Blizzard Default"

-------------------------------------------------------------------------------
-- Text Settings
-------------------------------------------------------------------------------

L["PLAYER_HEALTH_FORMAT"] = "Player Health Format"
L["PLAYER_HEALTH_FORMAT_DESC"] = "Select player frame health text display format"
L["TARGET_HEALTH_FORMAT"] = "Target Health Format"
L["TARGET_HEALTH_FORMAT_DESC"] = "Select target frame health text display format"
L["SECRET_VALUE_WARNING"] = "(12.0 Some formats may be restricted in combat)"

-- Health Formats
L["FORMAT_DEFAULT"] = "Blizzard Default (Recommended)"
L["FORMAT_PERCENT"] = "Percentage"
L["FORMAT_CURRENT"] = "Current Value"
L["FORMAT_CURRENT_MAX"] = "Current/Max"
L["FORMAT_DEFICIT"] = "Deficit"
L["FORMAT_HIDDEN"] = "Hidden"

-------------------------------------------------------------------------------
-- Edit Mode
-------------------------------------------------------------------------------

L["SHOW_IN_EDIT_MODE"] = "Show in Edit Mode"
L["SHOW_IN_EDIT_MODE_DESC"] = "Display enhanced controls in Blizzard Edit Mode"
L["SYNC_WITH_BLIZZARD"] = "Sync with Blizzard Edit Mode"
L["SYNC_WITH_BLIZZARD_DESC"] = "Synchronize settings with Blizzard Edit Mode layouts"
L["SCALE_DISPLAY"] = "Scale: %.0f%%"

-------------------------------------------------------------------------------
-- Advanced Options
-------------------------------------------------------------------------------

L["EXPORT_CONFIG"] = "Export Configuration"
L["IMPORT_CONFIG"] = "Import Configuration"
L["COPY_TO_CLIPBOARD"] = "Copy to Clipboard"
L["RESET_CURRENT_PROFILE"] = "Reset Current Profile"
L["RESET_ALL_CONFIG"] = "Reset All Configuration"
L["RESET_WARNING"] = "Click to reset all settings to default values"

-------------------------------------------------------------------------------
-- Combat Messages
-------------------------------------------------------------------------------

L["COMBAT_SCALE_PENDING"] = "Scale changes in combat will be applied after combat ends"
L["COMBAT_MOVE_BLOCKED"] = "Cannot move frames in combat"
L["COMBAT_EDIT_BLOCKED"] = "Cannot enter edit mode in combat"
L["COMBAT_SCALE_BLOCKED"] = "Cannot adjust scale in combat"
L["COMBAT_PENDING_APPLIED"] = "Pending changes have been applied"

-------------------------------------------------------------------------------
-- Chat Messages
-------------------------------------------------------------------------------

L["CONFIG_RESET"] = "Configuration has been reset"
L["CONFIG_IMPORTED"] = "Configuration imported successfully"
L["CONFIG_EXPORTED"] = "Configuration exported"
L["SCALE_APPLIED"] = "Scale applied: %s -> %.0f%%"
L["ADDON_LOADED"] = "Enhanced Unit Frames loaded. Type /euf for options."

-------------------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------------------

L["SLASH_HELP"] = "Available commands:"
L["SLASH_DEBUG"] = "/euf debug - Toggle debug mode"
L["SLASH_RESET"] = "/euf reset - Reset all settings"
L["SLASH_SCALE"] = "/euf scale <frame> <value> - Set frame scale (0.5-2.0)"
L["SLASH_COLOR"] = "/euf color - Toggle class colors"
L["SLASH_CONFIG"] = "/euf config - Open settings panel"

-------------------------------------------------------------------------------
-- Frame Names
-------------------------------------------------------------------------------

L["FRAME_PLAYER"] = "Player Frame"
L["FRAME_TARGET"] = "Target Frame"
L["FRAME_FOCUS"] = "Focus Frame"
L["FRAME_PET"] = "Pet Frame"

-------------------------------------------------------------------------------
-- Class Names (English)
-------------------------------------------------------------------------------

L["CLASS_WARRIOR"] = "Warrior"
L["CLASS_PALADIN"] = "Paladin"
L["CLASS_HUNTER"] = "Hunter"
L["CLASS_ROGUE"] = "Rogue"
L["CLASS_PRIEST"] = "Priest"
L["CLASS_SHAMAN"] = "Shaman"
L["CLASS_MAGE"] = "Mage"
L["CLASS_WARLOCK"] = "Warlock"
L["CLASS_DRUID"] = "Druid"
L["CLASS_DEATHKNIGHT"] = "Death Knight"
L["CLASS_MONK"] = "Monk"
L["CLASS_DEMONHUNTER"] = "Demon Hunter"
L["CLASS_EVOKER"] = "Evoker"

-------------------------------------------------------------------------------
-- Register Locale
-------------------------------------------------------------------------------

EUF.Locale_enUS = L

return L