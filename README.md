# AppleDisplayLayout

Save and restore your monitor display layout for macOS presentations.

## Overview

This project provides two AppleScripts that allow you to capture and restore your display configuration, making it easy to maintain consistent display layouts for presentations or when switching between different monitor setups.

## Features

- **Capture Display Layout**: Save your current display configuration including:
  - Display arrangement and positioning
  - Primary display designation
  - Resolution for each display
  - Refresh rate (Hertz)
  - Color depth
  - Scaling settings
  - Rotation (captured, restoration coming soon)

- **Restore Display Layout**: Restore your saved configuration with intelligent handling:
  - Automatically matches saved displays with currently available displays
  - Gracefully handles missing displays (skips unavailable displays)
  - Reports which displays were restored and which were missing
  - Sets main display first to ensure proper positioning

## Requirements

- macOS
- `displayplacer` (can be installed automatically via the scripts or manually with Homebrew)

## Installation

See [INSTALLATION.md](INSTALLATION.md) for detailed installation instructions.

## Usage

### Capture Display Layout

1. Run `CaptureDisplayLayout.applescript`
2. The script will save your current display configuration to `~/.config/display-layout/display-layout.plist`

### Restore Display Layout

1. Run `RestoreDisplayLayout.applescript`
2. The script will restore your saved display configuration
3. If any displays from the saved configuration are unavailable, they will be skipped and reported

## Configuration

The display configuration is stored in Property List (plist) format at:
```
~/.config/display-layout/display-layout.plist
```

## License

MIT License

