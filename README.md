# Enhanced Unit Frames

[![WoW Version](https://img.shields.io/badge/WoW-12.0%20Midnight-blue.svg)](https://worldofwarcraft.com)
[![Version](https://img.shields.io/badge/Version-1.0.0-green.svg)](https://github.com)

A lightweight World of Warcraft addon that enhances the default Player and Target unit frames with class color tinting, frame scaling, texture customization, and text configuration. Fully compatible with WoW 12.0 (Midnight) and the new "Secret Value" combat system.

## Features

### Class Color Tinting
- Automatically color health bars based on unit class
- Optional background and border coloring
- NPC units use reaction colors (friendly/neutral/hostile)
- Customizable reaction color presets

### Frame Scaling
- Scale individual frames: Player, Target, Focus, Pet
- Range: 50% - 200%
- Combat-safe: Changes queued and applied after combat ends
- Persistent settings across sessions

### Texture Customization
- Multiple status bar textures: Blizzard, Flat, Gradient
- Border styles: None, Rounded, Square, Blizzard Default
- Custom border colors with transparency support
- LibSharedMedia-3.0 integration for additional textures

### Text Configuration
- Health text format options: Default, Percentage, Current, Current/Max, Deficit, Hidden
- Combat-safe fallback for secret value scenarios (WoW 12.0)
- Font customization support

### Edit Mode Integration
- Drag and resize frames directly in Blizzard Edit Mode
- Real-time scale percentage display
- Combat lockdown protection with pending queue
- Syncs with Blizzard Edit Mode layouts

## WoW 12.0 Compliance

This addon is fully compliant with WoW 12.0's "Addon Disarmament" policy:

- **Secret Values**: Combat data returns protected values that cannot be calculated/processed
- **Safe Class Colors**: Uses GUID path (`UnitGUID` → `GetPlayerInfoByGUID` → `C_ClassColor.GetClassColor`)
- **Combat Lockdown**: All frame modifications check `InCombatLockdown()` and queue pending operations
- **Secure Hooks**: Only uses `hooksecurefunc` for post-hooks (no pre-hooks or global overrides)
- **No Taint**: Does not modify Blizzard global variables or functions

## Installation

### Manual Installation

1. Download the latest release
2. Extract the `EnhancedUnitFrames` folder
3. Place it in your WoW `Interface/AddOns` directory:
   - **Windows**: `C:\Program Files\World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac**: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`
4. Restart WoW or reload UI (`/reload`)

### Requirements

- World of Warcraft 12.0 (Midnight) retail
- No mandatory dependencies
- Optional: LibSharedMedia-3.0 for additional textures

## Usage

### Slash Commands

```
/euf              - Show help
/euf debug        - Toggle debug mode
/euf reset        - Reset all settings
/euf scale <frame> <value>  - Set frame scale (0.5-2.0)
/euf color [on|off] - Toggle class colors
/euf enable       - Enable addon
/euf disable      - Disable addon
/euf status       - Show current status
```

### Settings Panel

Open the settings panel via:
- Game Menu → Options → AddOns → Enhanced Unit Frames
- Slash command: `/euf config`

### Edit Mode

When entering Blizzard Edit Mode (Game Menu → Edit Mode), Enhanced Unit Frames will display:
- Blue highlight border on supported frames
- Corner drag handles for positioning
- Resize handle (bottom-right) for scaling
- Scale percentage display above each frame

## Configuration

All settings are saved automatically and persist across sessions:

- **Global Settings**: `EnhancedUnitFramesDBGlobal` (account-wide)
- **Character Settings**: `EnhancedUnitFramesDB` (per-character)

### Reset Settings

- `/euf reset` - Reset current character profile
- `/euf reset global` - Reset all global settings

## Localization

The addon supports multiple languages:
- English (enUS) - Default
- Simplified Chinese (zhCN)
- Traditional Chinese (zhTW)

Language is automatically detected based on your WoW client language.

## Custom Textures

To use custom textures:

1. Create 256x64 TGA files for status bars
2. Create 128x128 TGA files for borders (RGBA for transparency)
3. Place them in `Media/Textures/` folder
4. See `Media/Textures/README.md` for detailed specifications

Alternatively, install LibSharedMedia-3.0 for community texture packs.

## Compatibility

- **WoW Version**: 12.0 (Midnight) retail only
- **Frame Compatibility**: Works with default Blizzard frames
- **Addon Conflicts**: Generally compatible with other unit frame addons
- **Combat Safety**: All features work correctly during combat with proper queueing

## Known Limitations

- Some health text formats may display fallback values during combat (WoW 12.0 secret value restriction)
- Focus frame may not be available on all clients/configurations
- Frame positioning is managed by Blizzard Edit Mode system

## Support

For bug reports or feature requests:
- Check in-game debug mode (`/euf debug`) for diagnostic messages
- Review the settings panel for configuration issues

## Credits

- Developed for WoW 12.0 (Midnight)
- Uses Blizzard's Settings API for modern configuration panel
- Optional LibSharedMedia-3.0 integration

## License

This addon is provided as-is for the World of Warcraft community. Feel free to modify and share.

---

**Version**: 1.0.0
**Interface**: 120000
**Author**: EnhancedUnitFrames Team