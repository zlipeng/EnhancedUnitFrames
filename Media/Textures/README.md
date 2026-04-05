# EnhancedUnitFrames Media/Textures

This directory contains custom texture files for EnhancedUnitFrames addon.

## Required Textures

The addon uses the following custom textures. You can create your own or use the fallback Blizzard textures.

### Status Bar Textures

| File | Description | Size | Format |
|------|-------------|------|--------|
| `statusbar_flat.tga` | Flat solid color texture | 256x64 | TGA (24-bit RGB) |
| `statusbar_gradient.tga` | Gradient texture (top lighter) | 256x64 | TGA (24-bit RGB) |
| `statusbar_glossy.tga` | Glossy texture with shine effect | 256x64 | TGA (24-bit RGB) |

### Border Textures

| File | Description | Size | Format |
|------|-------------|------|--------|
| `border_rounded.tga` | Rounded corner border | 128x128 | TGA (32-bit RGBA) |
| `border_square.tga` | Square border | 128x128 | TGA (32-bit RGBA) |

## Texture Creation Guide

### Status Bar Texture Guidelines

- **Dimensions**: 256x64 pixels (width x height)
- **Format**: TGA (24-bit RGB) or BLP
- **Design**: The texture fills from left to right
- **Tips**:
  - Keep left edge clean for seamless fill animation
  - Avoid patterns that might look distorted when stretched

### Border Texture Guidelines

- **Dimensions**: 128x128 pixels (square)
- **Format**: TGA (32-bit RGBA) for transparency support
- **Design**: Border should be centered with transparent inner area
- **Edge Size**: Recommended 2-4 pixels border thickness

## Fallback Behavior

If custom textures are not found, the addon falls back to Blizzard built-in textures:

- **Default Status Bar**: `Interface\TargetingFrame\UI-StatusBar`
- **Default Border**: Uses BackdropTemplate system

## LibSharedMedia Integration

EnhancedUnitFrames supports LibSharedMedia-3.0 for additional textures:

1. Install LibSharedMedia-3.0 addon
2. Select textures from any registered media in the addon settings
3. Custom textures registered with LibSharedMedia will appear automatically

## Creating TGA Files

You can create TGA textures using:

- **Adobe Photoshop**: Export as TGA (24-bit or 32-bit)
- **GIMP**: Export as TGA with appropriate bit depth
- **Online Tools**: Various texture generation tools

## Example Texture Locations

The addon also references these Blizzard textures as alternatives:

```
Interface\TargetingFrame\UI-StatusBar           -- Default status bar
Interface\PaperDollInfoFrame\UI-PaperDollInfoFrame-StatusBar  -- Paper doll bar
Interface\Buttons\WHITE8x8                      -- Solid white (for flat)
Interface\ChatFrame\ChatFrameBackground         -- Chat background
```

## Notes

- Textures should be placed in `Media\Textures\` relative to addon directory
- The addon's TOC does not need to explicitly load texture files
- Texture paths are referenced using `Interface\AddOns\EnhancedUnitFrames\Media\Textures\<filename>`