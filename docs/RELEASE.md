# Release Packaging Guide

This document provides instructions for packaging EnhancedUnitFrames for distribution.

## Pre-Release Checklist

Before creating a release package, verify:

- [ ] All code changes committed
- [ ] Version number updated in:
  - [ ] `EnhancedUnitFrames.toc` (## Version:)
  - [ ] `Core/Core.lua` (EUF.VERSION)
  - [ ] `CHANGELOG.md` (new version entry)
- [ ] CHANGELOG.md updated with release notes
- [ ] README.md updated if needed
- [ ] No debug prints left in production code
- [ ] All files saved and tested

## Package Contents

The release package should include:

```
EnhancedUnitFrames/
├── EnhancedUnitFrames.toc
├── README.md
├── CHANGELOG.md
├── LICENSE (if applicable)
├── Core/
│   ├── Utils.lua
│   ├── SecretSafe.lua
│   ├── Database.lua
│   └── Core.lua
├── Modules/
│   ├── ClassColors.lua
│   ├── FrameScale.lua
│   ├── Textures.lua
│   └── TextSettings.lua
├── Integration/
│   ├── EditMode.lua
│   └── BlizzardHooks.lua
├── GUI/
│   ├── OptionsPanel.lua
│   ├── Widgets/
│   │   ├── ColorPicker.lua
│   │   └── TexturePreview.lua
│   └── Panes/
│       ├── ClassColorsPanel.lua
│       ├── FrameScalePanel.lua
│       ├── TexturesPanel.lua
│       ├── TextSettingsPanel.lua
│       └── AdvancedPanel.lua
├── Locales/
│   ├── Locales.lua
│   ├── enUS.lua
│   ├── zhCN.lua
│   └── zhTW.lua
└── Media/
    └── Textures/
        └── README.md
```

## Creating the Release Package

### Option 1: Manual ZIP Creation

1. Navigate to parent directory of `EnhancedUnitFrames`
2. Select the `EnhancedUnitFrames` folder
3. Create a ZIP archive named `EnhancedUnitFrames-1.0.0.zip`
4. Verify ZIP structure: extracting should create `EnhancedUnitFrames/` folder

### Option 2: Command Line (macOS/Linux)

```bash
cd /path/to/parent/directory
zip -r EnhancedUnitFrames-1.0.0.zip EnhancedUnitFrames \
  -x "*.git*" \
  -x "*docs/plan.md" \
  -x "*docs/EnhancedUnitFrames_Development_Plan.md" \
  -x "*docs/EnhancedUnitFrames_UI_Design.md" \
  -x "*.DS_Store"
```

### Option 3: Command Line (Windows PowerShell)

```powershell
cd C:\path\to\parent\directory
Compress-Archive -Path EnhancedUnitFrames -DestinationPath EnhancedUnitFrames-1.0.0.zip
```

## Files to Exclude

The following files should NOT be included in the release package:

- `.git/` folder (if using git)
- `.DS_Store` (macOS)
- `Thumbs.db` (Windows)
- `*.bak` files
- Development documentation:
  - `docs/plan.md`
  - `docs/EnhancedUnitFrames_Development_Plan.md`
  - `docs/EnhancedUnitFrames_UI_Design.md`
  - `docs/TESTING.md` (optional, can include)

## Uploading to Distribution Platforms

### CurseForge

1. Go to https://curseforge.com/wow/addons
2. Click "Upload a Project" or navigate to your project
3. Upload the ZIP file
4. Set version: `1.0.0`
5. Set game version: `12.0 Midnight`
6. Copy CHANGELOG entry as release notes
7. Publish

### WoWInterface

1. Go to https://wowinterface.com/addons/
2. Login and go to "My Addons"
3. Click "Update Addon"
4. Upload the ZIP file
5. Fill in version info and notes
6. Submit

## Version Naming Convention

Use semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes, major feature additions
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, minor improvements

Examples:
- `1.0.0` - Initial release
- `1.0.1` - Bug fix release
- `1.1.0` - New feature release
- `2.0.0` - Major overhaul

## Post-Release

After successful release:

1. Tag the release in git: `git tag v1.0.0`
2. Push tag: `git push origin v1.0.0`
3. Update GitHub releases page (if applicable)
4. Announce release on:
   - Discord/forums
   - In-game chat channels
5. Monitor for bug reports
6. Plan next version improvements

## Rollback Plan

If critical bugs are found post-release:

1. Document the bug clearly
2. Create hotfix branch from release tag
3. Fix the issue
4. Bump version to `1.0.1`
5. Test thoroughly
6. Release as patch version
7. Update CurseForge/WoWInterface

---

## Release Checklist Summary

### Before Release
- [ ] Version numbers updated
- [ ] CHANGELOG updated
- [ ] Code reviewed and tested
- [ ] Debug mode off by default

### Create Package
- [ ] ZIP file created
- [ ] Structure verified
- [ ] Excluded unnecessary files

### Upload
- [ ] CurseForge upload complete
- [ ] WoWInterface upload complete
- [ ] Release notes published

### Post-Release
- [ ] Git tag created
- [ ] GitHub release created
- [ ] Announcement posted
- [ ] Monitoring for issues