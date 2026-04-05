# Testing Checklist

This document provides a comprehensive testing checklist for EnhancedUnitFrames v1.0.0.

## Prerequisites

- WoW 12.0 (Midnight) retail client
- Fresh install or clean SavedVariables recommended
- Optional: LibSharedMedia-3.0 installed

---

## 1. Installation & Loading

### 1.1 Basic Loading
- [ ] Addon appears in AddOns list at character select
- [ ] Addon loads without Lua errors on login
- [ ] Chat message shows "Enhanced Unit Frames loaded"
- [ ] `/euf status` displays correct version and state

### 1.2 SavedVariables
- [ ] Settings persist after `/reload`
- [ ] Settings persist after game restart
- [ ] Settings persist after logout/login

---

## 2. Class Color Tinting

### 2.1 Player Frame
- [ ] Player frame shows correct class color on health bar
- [ ] Background coloring works when enabled
- [ ] Border coloring works when enabled
- [ ] Colors match expected class color (check against known values)

### 2.2 Target Frame
- [ ] Targeting a player shows their class color
- [ ] Targeting a hostile NPC shows red (or custom hostile color)
- [ ] Targeting a neutral NPC shows yellow (or custom neutral color)
- [ ] Targeting a friendly NPC shows green (or custom friendly color)
- [ ] Switching targets updates color immediately

### 2.3 Focus Frame (if available)
- [ ] Focus frame shows correct class color
- [ ] Focus target changes update color correctly

### 2.4 Settings
- [ ] Enabling/disabling class colors works immediately
- [ ] Background toggle works correctly
- [ ] Border toggle works correctly
- [ ] NPC reaction toggle works correctly
- [ ] Custom reaction colors apply correctly

---

## 3. Frame Scaling

### 3.1 Out of Combat
- [ ] Player frame scale slider works (50%-200%)
- [ ] Target frame scale slider works
- [ ] Focus frame scale slider works
- [ ] Pet frame scale slider works
- [ ] Scale changes apply immediately

### 3.2 In Combat
- [ ] Attempting to change scale shows "will apply after combat" message
- [ ] Scale changes are queued correctly
- [ ] Queued changes apply immediately after combat ends
- [ ] No Lua errors during combat

### 3.3 Slash Commands
- [ ] `/euf scale player 1.5` works correctly
- [ ] `/euf scale target 0.8` works correctly
- [ ] Invalid values show appropriate error message
- [ ] Invalid frame names show appropriate error message

### 3.4 Persistence
- [ ] Scales persist after `/reload`
- [ ] Scales persist after game restart

---

## 4. Texture Customization

### 4.1 Status Bar Textures
- [ ] Blizzard texture renders correctly
- [ ] Flat texture renders correctly (if custom texture exists)
- [ ] Gradient texture renders correctly (if custom texture exists)
- [ ] Texture preview updates in settings

### 4.2 Border Styles
- [ ] None border style removes visible border
- [ ] Rounded border style displays correctly
- [ ] Square border style displays correctly
- [ ] Blizzard border style displays correctly

### 4.3 Border Colors
- [ ] Custom border color applies correctly
- [ ] Alpha/transparency works correctly

### 4.4 LibSharedMedia (if installed)
- [ ] External textures appear in dropdown
- [ ] External textures apply correctly

---

## 5. Text Configuration

### 5.1 Health Text Formats
- [ ] Blizzard Default format works
- [ ] Percentage format works (may show fallback in combat)
- [ ] Current value format works (may show fallback in combat)
- [ ] Current/Max format works (may show fallback in combat)
- [ ] Deficit format works (may show fallback in combat)
- [ ] Hidden format hides health text

### 5.2 Combat Behavior
- [ ] No Lua errors in combat with custom formats
- [ ] Fallback to default occurs when secret values detected
- [ ] Text updates correctly after combat ends

---

## 6. Edit Mode Integration

### 6.1 Entering Edit Mode
- [ ] Blue highlight appears on frames
- [ ] Corner drag handles appear
- [ ] Resize handle appears (bottom-right)
- [ ] Scale percentage displays above each frame

### 6.2 Dragging Frames
- [ ] Frames move when dragged
- [ ] Position persists after exiting Edit Mode
- [ ] Combat lockdown prevents dragging (shows message)

### 6.3 Resizing Frames
- [ ] Dragging resize handle changes scale
- [ ] Scale percentage updates in real-time
- [ ] Scale persists after exiting Edit Mode
- [ ] Combat lockdown prevents resizing (queues change)

### 6.4 Exiting Edit Mode
- [ ] Controls are hidden
- [ ] Settings are saved
- [ ] No Lua errors

---

## 7. Settings Panel Integration

### 7.1 Interface Options Display
- [ ] Plugin appears in ESC → Options → AddOns left panel list
- [ ] Clicking "Enhanced Unit Frames" shows settings on right panel
- [ ] All settings sections display correctly
- [ ] No Lua errors when opening settings

### 7.2 Opening Methods
- [ ] `/euf config` opens settings panel
- [ ] `/euf` opens settings panel
- [ ] Settings panel opens from minimap button

---

## 8. Minimap Button

### 8.1 Display
- [ ] Button appears near minimap on first load
- [ ] Button icon displays correctly
- [ ] Button border displays correctly
- [ ] Hover highlight works

### 8.2 Tooltip
- [ ] Tooltip appears on hover
- [ ] Tooltip shows correct instructions
- [ ] Tooltip hides on mouse leave

### 8.3 Left Click
- [ ] Left-click opens settings panel
- [ ] Settings panel displays correctly

### 8.4 Right Click Menu
- [ ] Right-click shows context menu
- [ ] Menu options display correctly
- [ ] Toggle Class Colors works
- [ ] Lock Position works
- [ ] Hide Button works
- [ ] Reset Config works

### 8.5 Dragging
- [ ] Button can be dragged around minimap
- [ ] Position is saved after dragging
- [ ] Locked button cannot be dragged
- [ ] Position persists after `/reload`

### 8.6 Show/Hide
- [ ] `/euf minimap hide` hides button
- [ ] `/euf minimap show` shows button
- [ ] Settings panel toggle works
- [ ] Hidden state persists after `/reload`

### 8.7 Reset Position
- [ ] `/euf minimap reset` resets to default position
- [ ] Reset button in settings works

---

## 9. Settings Panel

### 7.1 Opening/Closing
- [ ] `/euf` or game menu opens settings
- [ ] Panel scrolls correctly
- [ ] No Lua errors when opening

### 7.2 Controls
- [ ] Checkboxes toggle correctly
- [ ] Sliders work correctly
- [ ] Dropdowns display options correctly
- [ ] Color picker works (if applicable)

### 7.3 Reset
- [ ] Reset button clears settings
- [ ] Reset shows confirmation message
- [ ] All settings return to defaults

---

## 8. Slash Commands

- [ ] `/euf` shows help
- [ ] `/euf help` shows help
- [ ] `/euf debug` toggles debug mode
- [ ] `/euf reset` resets settings
- [ ] `/euf scale` works correctly
- [ ] `/euf color on/off` works correctly
- [ ] `/euf enable` enables addon
- [ ] `/euf disable` disables addon
- [ ] `/euf status` shows current state

---

## 9. Combat Scenarios

### 9.1 Dungeons
- [ ] No Lua errors in dungeon combat
- [ ] Class colors display correctly
- [ ] Scale changes queue correctly

### 9.2 Raids
- [ ] No Lua errors in raid combat
- [ ] Performance is acceptable (no FPS drop)
- [ ] Multiple target switches work correctly

### 9.3 PvP
- [ ] No Lua errors in PvP combat
- [ ] Enemy player class colors work
- [ ] No protected action errors

---

## 10. Localization

### 10.1 English Client (enUS)
- [ ] All text displays in English
- [ ] Settings panel text is correct
- [ ] Slash command help is correct

### 10.2 Simplified Chinese Client (zhCN)
- [ ] All text displays in Chinese
- [ ] Settings panel text is correct
- [ ] No untranslated strings visible

### 10.3 Traditional Chinese Client (zhTW)
- [ ] All text displays in Traditional Chinese
- [ ] Settings panel text is correct
- [ ] No untranslated strings visible

---

## 11. Compatibility

### 11.1 Other Addons
- [ ] Works with other unit frame addons
- [ ] No conflicts with action bar addons
- [ ] No conflicts with UI replacement addons

### 11.2 Resolutions
- [ ] Works at 1920x1080
- [ ] Works at 2560x1440
- [ ] Works at 4K (3840x2160)
- [ ] Works with UI scale changes

---

## 12. Performance

- [ ] No significant FPS impact
- [ ] Memory usage is reasonable (<1MB)
- [ ] No memory leaks over extended play
- [ ] No CPU spike during target switching

---

## Regression Testing Checklist

After any code changes, verify:
- [ ] All Phase 1 tests pass
- [ ] All Phase 2 tests pass
- [ ] All Phase 3 tests pass
- [ ] All Phase 4 tests pass
- [ ] All Phase 5 tests pass

---

## Test Results Template

```
Test Date: _______________
Tester: _______________
WoW Version: 12.0 (Midnight)
AddOn Version: 1.0.0

Summary:
- Tests Passed: ___ / Total
- Critical Issues: ___
- Minor Issues: ___

Issues Found:
1. [Description]
2. [Description]

Notes:
[Additional observations]
```