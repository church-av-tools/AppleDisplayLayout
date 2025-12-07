# Installation Guide

## Prerequisites

These scripts require `displayplacer` to be installed on your Mac. The scripts can automatically install it for you, or you can install it manually.

## Installing displayplacer

### Option 1: Automatic Installation (Recommended)

When you run either script and `displayplacer` is not found, you'll be prompted to install it automatically. Simply click "Install" and enter your administrator password when prompted.

### Option 2: Manual Installation

If you prefer to install manually, or if automatic installation fails, you can install `displayplacer` using Homebrew:

```bash
brew install displayplacer
```

### Installing Homebrew (if needed)

If you don't have Homebrew installed, you can install it by running:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

For Apple Silicon Macs, Homebrew installs to `/opt/homebrew/bin/brew`.  
For Intel Macs, Homebrew installs to `/usr/local/bin/brew`.

After installing Homebrew, make sure it's in your PATH. You may need to add it to your shell profile:

**For zsh (default on macOS):**
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**For bash:**
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## Usage

### Capturing Display Layout

Run `CaptureDisplayLayout.applescript` to save your current display configuration. The script will:
- Detect all connected displays
- Capture resolution, position, scaling, color depth, refresh rate, and primary display settings
- Save the configuration to `~/.config/display-layout/display-layout.plist`

### Restoring Display Layout

Run `RestoreDisplayLayout.applescript` to restore your saved display configuration. The script will:
- Read the saved configuration from the plist file
- Match saved displays with currently available displays
- Restore settings only for available displays
- Gracefully handle missing displays (skips unavailable displays and reports which ones were missing)

## Verifying Installation

You can verify that `displayplacer` is installed by running:

```bash
displayplacer list
```

This should display information about your current display configuration.

## Troubleshooting

If the scripts cannot find `displayplacer` after installation:

1. Make sure Homebrew is in your PATH
2. Try restarting Terminal or your shell
3. Verify the installation: `brew list displayplacer`
4. Check if it's accessible: `which displayplacer`

If you continue to have issues, you can manually specify the path to `displayplacer` in the scripts, or ensure Homebrew's bin directory is in your PATH.

## Notes

- The configuration file is stored in Property List (plist) format at `~/.config/display-layout/display-layout.plist`
- Display rotation is captured but not currently restored (to be added in a future update)
- The main display is determined by its origin position `(0,0)`, not by a separate flag

