# KeyboardCleaner

<p align="center">
  <img src="https://github.com/sabr2007/KeyboardCleaner/raw/main/logo_preview.png" alt="KeyboardCleaner" width="200">
</p>

A lightweight macOS utility that locks your keyboard and trackpad so you can safely wipe them down without triggering random inputs.

## Features

- Blocks **all** keyboard input (regular keys, function keys, media keys, modifiers)
- Blocks **all** trackpad/mouse input (clicks, gestures, scrolling, cursor movement)
- Fullscreen overlay with clear instructions
- **Exit**: hold both **Left ⌘ + Right ⌘** for 3 seconds
- **Auto-exit**: automatically unlocks after 3 minutes
- Works across all connected displays
- Activation countdown (3 seconds) before locking

## Installation

### Option 1: Build & Install (recommended)

Requires **Xcode Command Line Tools** and **Homebrew**.

```bash
# Clone the repo
git clone https://github.com/sabr2007/KeyboardCleaner.git
cd KeyboardCleaner

# Install librsvg for app icon generation
brew install librsvg

# Build and create .app bundle
./scripts/build_app.sh

# Install to Applications (appears in Launchpad)
cp -r build/KeyboardCleaner.app /Applications/
```

### Option 2: Build with Swift directly

```bash
swift build -c release
.build/release/KeyboardCleaner
```

### Option 3: Open in Xcode

```bash
open Package.swift
```

Then press **Cmd+R** to build and run.

## Usage

1. Launch **KeyboardCleaner** from Launchpad, Spotlight, or terminal
2. A fullscreen overlay appears with a **3-second countdown**
3. Once locked — clean your keyboard and trackpad freely
4. To exit, hold **both Command keys** (left + right) for **3 seconds**
5. The app also auto-exits after **3 minutes**

## Permissions

On first launch, macOS will ask for **Accessibility** permission:

**System Settings → Privacy & Security → Accessibility → KeyboardCleaner ✓**

This is required to intercept keyboard and trackpad events. The app cannot function without it.

## How It Works

- Uses `CGEvent.tapCreate` to intercept and suppress all input events at the system level
- Uses `CGAssociateMouseAndMouseCursorPosition(0)` to freeze the cursor
- Overlay window sits at `screenSaver` level covering all displays and Spaces
- Exit mechanism tracks raw modifier flag bits to distinguish left/right Command keys
- All input is fully restored when the app exits (including crash/force-quit scenarios)

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Emergency Exit

If something goes wrong:
- **SSH from another device**: `killall KeyboardCleaner`
- **Force restart**: hold power button for 10 seconds (last resort)

The app automatically releases all input when its process terminates, so force-quitting always works.

## License

MIT
