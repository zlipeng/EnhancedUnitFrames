# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EnhancedUnitFrames is a World of Warcraft 12.0 (Midnight) addon that visually enhances the official PlayerFrame and TargetFrame with features including class color tinting, frame scaling, texture customization, and text configuration. Design documents are located in `docs/`.

## Critical: WoW 12.0 Secret Value System

This addon must comply with WoW 12.0's "Addon Disarmament" policy. The Secret Value system means combat data (health, power, etc.) in raids/mythics/PVP returns "secret values" that **cannot be processed or calculated** - they can only be displayed.

### Core Compliance Rules

```lua
-- NEVER perform arithmetic on UnitHealth/UnitPower returns in combat scenarios
-- ❌ WRONG: local percent = (UnitHealth("target") / UnitHealthMax("target")) * 100
-- ✅ CORRECT: Let Blizzard StatusBar handle it: healthBar:SetValue(UnitHealth("target"))

-- NEVER use pre-hooks on secure templates - causes Taint
-- ❌ WRONG: local original = frame.SetScript; frame.SetScript = function(...) ...
-- ✅ CORRECT: hooksecurefunc(frame, "SetScript", function(...) ...)

-- NEVER call Show()/Hide()/SetScale() directly in combat
-- ❌ WRONG: if shouldShow then frame:Show() end (in combat)
-- ✅ CORRECT: Queue changes, apply on PLAYER_REGEN_ENABLED

-- Use non-secret APIs for class colors
-- ✅ Safe: C_ClassColor.GetClassColor(classToken)
-- ✅ Safe: UnitGUID() + GetPlayerInfoByGUID() to get class
```

### Allowed Operations (Whitelist)
- Visual customization: size, shape, position, textures, fonts, colors
- Information display: presenting what UI already shows
- Edit Mode integration via official APIs
- Non-combat data processing (full access out of combat)

### Blocked Operations (Blacklist)
- Combat automation or decision-making
- Direct Secure frame modification in combat
- Custom text formatting that requires arithmetic on secret values

## Architecture

```
EnhancedUnitFrames/
├── EnhancedUnitFrames.toc    # TOC version 120000
├── Core/
│   ├── Core.lua              # Event management, initialization
│   ├── Database.lua          # SavedVariables (EnhancedUnitFramesDB)
│   ├── Utils.lua             # Helper functions
│   └── SecretSafe.lua        # Secret value handling layer
├── Modules/
│   ├── ClassColors.lua       # Class/reaction color system
│   ├── FrameScale.lua        # Scaling (out-of-combat only)
│   ├── Textures.lua          # Texture/material management
│   └── TextSettings.lua      # Font/text configuration
├── Integration/
│   ├── EditMode.lua          # /editmode integration
│   └── BlizzardHooks.lua     # Safe post-hooks on Blizzard frames
├── GUI/
│   └── OptionsPanel.lua      # Settings panel (Settings API)
├── Media/Textures/           # Custom textures (.tga/.blp)
└── Libs/LibSharedMedia-3.0/  # Optional dependency
```

### Key Frame Targets
- `PlayerFrame`, `PlayerFrameHealthBar`, `PlayerFrameManaBar`, `PlayerNameText`
- `TargetFrame`, `TargetFrameHealthBar`, `TargetFrameManaBar`
- `FocusFrame`, `PetFrame` (optional)

## API Patterns

### Class Colors (Non-Secret Path)
```lua
-- Use GUID approach - works in all scenarios
local guid = UnitGUID(unit)
local _, classToken = GetPlayerInfoByGUID(guid)
local color = C_ClassColor.GetClassColor(classToken)
healthBar:SetStatusBarColor(color.r, color.g, color.b)
```

### Combat-Safe Scaling
```lua
-- Always check InCombatLockdown()
if InCombatLockdown() then
    self.pendingScales[frameKey] = scale  -- Queue for later
else
    frame:SetScale(scale)
end

-- Apply queued changes on PLAYER_REGEN_ENABLED event
```

### Settings Panel (12.0 Vertical Layout)
```lua
local category = Settings.RegisterVerticalLayoutCategory("Enhanced Unit Frames")
local setting = Settings.RegisterAddOnSetting(category, "displayName", "varName", DB, "boolean", default)
Settings.CreateCheckBox(category, setting, "tooltip")
Settings.RegisterAddOnCategory(category)
```

### Borders (BackdropTemplate Required)
```lua
-- 12.0 requires BackdropTemplate for borders
local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
border:SetBackdrop({edgeFile = path, edgeSize = size})
border:SetBackdropBorderColor(r, g, b, a)
```

## API Reference

**Official WoW API Documentation:** https://warcraft.wiki.gg/wiki/World_of_Warcraft_API

All API implementations must align with the official documentation. Key API categories used in this addon:

### Unit Functions
- `UnitGUID(unit)` - Returns GUID for unit
- `UnitHealth(unit)`, `UnitHealthMax(unit)` - Health values (may return secret values in combat)
- `UnitPower(unit)`, `UnitPowerMax(unit)` - Power values (may return secret values in combat)
- `GetPlayerInfoByGUID(guid)` - Returns class, race, gender, etc.
- `UnitExists(unit)`, `UnitIsPlayer(unit)`, `UnitIsFriend(unit)` - Unit validation

### Frame Functions
- `CreateFrame(frameType, name, parent, template)` - Frame creation
- `frame:SetScale(scale)`, `frame:GetScale()` - Scale (blocked in combat)
- `frame:Show()`, `frame:Hide()` - Visibility (blocked in combat)
- `frame:SetSize(width, height)` - Dimensions

### Color APIs
- `C_ClassColor.GetClassColor(classToken)` - Get class color (non-secret path)

### Combat Status
- `InCombatLockdown()` - Returns true if in combat (restricted operations)
- `UnitAffectingCombat(unit)` - Check if specific unit is in combat

### Events
- `PLAYER_REGEN_ENABLED` - Fired when exiting combat
- `PLAYER_REGEN_DISABLED` - Fired when entering combat

**Important:** When implementing features, verify against the official API documentation to ensure correct usage and parameter handling.

## SavedVariables

Defined in TOC as `EnhancedUnitFramesDB` and `EnhancedUnitFramesDBGlobal`. Database.lua handles defaults merging.

Default profile structure includes: `classColors`, `scales`, `textures`, `text`, `editMode`.

## Hook Patterns

Always use `hooksecurefunc` for post-hooks:
```lua
hooksecurefunc("PlayerFrame_Update", function()
    -- Modify visual properties only
end)

hooksecurefunc("TargetFrame_Update", function()
    if UnitExists("target") then
        -- Apply class colors, textures, etc.
    end
end)
```

## Events to Monitor

- `PLAYER_LOGIN` - Initialize and apply saved settings
- `PLAYER_REGEN_ENABLED` - Apply queued combat-locked changes
- `PLAYER_TARGET_CHANGED` - Update target frame colors
- `PLAYER_FOCUS_CHANGED` - Update focus frame colors
- `EDIT_MODE_MODE_CHANGED` - Show/hide edit controls
- `UNIT_CLASSIFICATION_CHANGED` - Recalculate colors

## Testing Workflow

WoW addons are tested by:
1. Copying addon folder to WoW `_retail_/Interface/AddOns/`
2. Launching game and checking `/euf` command
3. Verifying settings panel opens via Interface Options > AddOns
4. Testing features in and out of combat
5. Checking chat for Lua errors (`/console scriptErrors 1`)

No automated test framework exists; validate by in-game testing.

## Development Workflow

### Mandatory Checklist Review Process

**Before completing any development task**, you must:

1. **Read `docs/plan.md`** to identify all checklist items for the current task
2. **Mark completed items** by changing `[ ]` to `[x]` in the plan file
3. **Verify all items are checked** before proceeding to the next phase

Example checklist verification:
```markdown
# In docs/plan.md, after completing a task:
- [x] 实现 `SecretSafe.IsSecretValue(value)` - 判断是否为机密值
- [x] 实现 `SecretSafe.SafeNumber(value, fallback)` - 安全数值获取
- [ ] 实现 `SecretSafe.SafeText(value, fallback)` - 安全文本获取  <-- NOT done yet
```

### Mandatory Code Review with Subagent

**Before moving to the next development phase**, you must:

1. **Spawn a review subagent** to analyze the completed code:
   ```
   Use Agent tool with prompt:
   "Review the completed [module name] code for:
   - 12.0 Secret Value compliance
   - Proper hooksecurefunc usage (no pre-hooks)
   - InCombatLockdown() checks where needed
   - Correct API patterns (GUID path for class colors)
   - Taint prevention (no global variable modification)
   - Code quality and error handling"
   ```

2. **Address all issues** identified by the review subagent
3. **Re-review if needed** until no issues remain
4. **Update plan.md status** only after clean review

### Phase Completion Criteria

A phase is considered **complete** only when:
- ✅ All checklist items in `docs/plan.md` are marked `[x]`
- ✅ Code review subagent returns no issues
- ✅ 12.0 compliance verified for all new code
- ✅ No TODO comments or placeholder code remains

### Development Order

Follow the phase order defined in `docs/plan.md`:
1. **Phase 1: Core Framework** (P0) - Foundation, cannot skip
2. **Phase 2: Functional Modules** (P0) - Core features
3. **Phase 3: GUI Development** (P1) - User interface
4. **Phase 4: Edit Mode Integration** (P1) - Blizzard integration
5. **Phase 5: Localization & Testing** (P2) - Polish
6. **Phase 6: Release Preparation** (P2) - Final steps

Do NOT proceed to later phases without completing earlier ones.

### Progress Tracking

After completing a module, update the Progress Tracking table in `docs/plan.md`:
```markdown
| 模块 | 状态 | 开始日期 | 完成日期 | 备注 |
|------|------|----------|----------|------|
| Core框架 | ✅ 完成 | 2026-04-05 | 2026-04-06 | 已review |
| SecretSafe | ✅ 完成 | 2026-04-05 | 2026-04-05 | 最高优先级 |
```

Status options: `⬜ 未开始`, `🔄 进行中`, `✅ 完成`, `❌ 有问题`