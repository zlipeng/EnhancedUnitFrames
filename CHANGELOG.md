# Changelog

All notable changes to Enhanced Unit Frames will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-05

### Added

#### Core Framework
- Initial release for WoW 12.0 (Midnight)
- Core initialization system with event-driven architecture
- Database management for SavedVariables (global and per-character)
- Utility functions for safe operations and debugging
- Combat-safe operation queue system

#### Secret Value Safety Layer
- `SecretSafe.IsSecretValue()` - Detect protected combat values
- `SecretSafe.SafeGetClassColor()` - GUID-based class color retrieval
- `SecretSafe.SafeGetReactionColor()` - NPC reaction color handling
- `SecretSafe.SafeGetHealthPercent()` - Safe percentage calculation

#### Class Color Tinting
- Automatic health bar coloring based on unit class
- Background and border coloring options
- NPC reaction colors (friendly/neutral/hostile)
- Customizable reaction color presets
- Hook integration with PlayerFrame, TargetFrame, FocusFrame

#### Frame Scaling
- Individual scale control for Player, Target, Focus, Pet frames
- Scale range: 50% - 200%
- Combat-safe with pending operation queue
- Persistent settings across sessions and reloads

#### Texture Customization
- Multiple status bar textures (Blizzard, Flat, Gradient)
- Border styles (None, Rounded, Square, Blizzard Default)
- Custom border colors with alpha support
- LibSharedMedia-3.0 integration for external textures

#### Text Configuration
- Health text format options:
  - Blizzard Default (recommended)
  - Percentage
  - Current value
  - Current/Max
  - Deficit
  - Hidden
- Combat-safe fallback for secret value scenarios

#### Edit Mode Integration
- Visual editing controls in Blizzard Edit Mode
- Blue highlight border on editable frames
- Corner drag handles for positioning
- Resize handle with real-time scale display
- Combat lockdown protection
- Sync with Blizzard Edit Mode layouts

#### Settings Panel
- Modern Settings API integration (WoW 12.0)
- Organized by category: General, Class Colors, Scale, Textures, Text, Advanced
- Real-time preview for class colors
- Reset and import/export functionality

#### Localization
- English (enUS) - Default
- Simplified Chinese (zhCN)
- Traditional Chinese (zhTW)
- Automatic client language detection
- Fallback mechanism for missing translations

### Security

#### WoW 12.0 Compliance
- Full compliance with "Addon Disarmament" policy
- No combat data calculation for secret values
- Secure GUID path for class color retrieval
- `InCombatLockdown()` checks before all frame modifications
- `hooksecurefunc` only (no pre-hooks or global overrides)
- No taint of Blizzard global variables

### Performance

- Event-based updates with throttling support
- Minimal OnUpdate usage
- Efficient memory management for edit controls
- Table reuse patterns to reduce garbage collection

### Technical Details

- **Interface Version**: 120000
- **SavedVariables**: `EnhancedUnitFramesDBGlobal`, `EnhancedUnitFramesDB`
- **Optional Dependencies**: LibSharedMedia-3.0

---

## Version History

| Version | Date | WoW Interface | Notes |
|---------|------|---------------|-------|
| 1.0.0 | 2026-04-05 | 120000 | Initial release for WoW 12.0 (Midnight) |

---

## Upgrade Notes

This is the initial release. No upgrade path is required.

## Known Issues

- Some health text formats may display fallback values during intense combat encounters due to WoW 12.0's secret value protection
- Focus frame controls only appear when FocusFrame exists in the current game state

## Roadmap

Potential future enhancements:
- Additional texture packs
- More font customization options
- Profile system for saving/loading configurations
- Integration with additional LibSharedMedia textures