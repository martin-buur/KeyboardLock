# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build
xcodebuild -project KeyboardLock.xcodeproj -scheme KeyboardLock -configuration Debug build

# Run tests
xcodebuild -project KeyboardLock.xcodeproj -scheme KeyboardLock test

# Clean build
xcodebuild -project KeyboardLock.xcodeproj -scheme KeyboardLock clean
```

For development, open `KeyboardLock.xcodeproj` in Xcode and use ⌘B to build, ⌘R to run.

## Releasing

When asked to release a new version, read `RELEASE.md` for the complete release process.

## Architecture

KeyboardLock is a macOS menu bar app that locks keyboard and mouse input. It runs as an LSUIElement (no dock icon).

### Core Components

- **KeyboardLockApp.swift** - App entry point with `MenuBarExtra` for the menu bar UI and `AppDelegate` for lifecycle/deep link handling
- **KeyboardManager.swift** - Central controller managing lock state via `CGEvent.tapCreate()`. Handles event interception, permission checks, and distributed notification API
- **UnlockTracker.swift** - Tracks ⌘ key presses (6x within 2 seconds) for unlock gesture
- **LockOverlayWindow.swift** - Full-screen overlay shown when locked (uses NSPanel at `.screenSaver` level)
- **Settings.swift / SettingsView.swift** - UserDefaults-backed preferences with SwiftUI settings window

### Lock Modes

`LockMode` enum defines four modes:
- `keyboard` - Blocks keyboard, shows overlay with unlock button
- `keyboardMouse` - Blocks keyboard + mouse, shows overlay (no unlock button)
- `keyboardSilent` - Blocks keyboard only, no overlay ("cat mode")
- `keyboardMouseSilent` - Blocks keyboard + mouse, no overlay

### External Control

**Deep Links** (`keyboardlock://`):
- `keyboardlock://lock` or `keyboardlock://lock/keyboard-mouse`
- `keyboardlock://unlock`

**Distributed Notifications** (for CLI/automation):
- `com.keyboardlock.lock` / `unlock` / `toggle` / `status`
- Response: `com.keyboardlock.status.response` with `["locked": Bool]`

### Key Implementation Details

- Uses `CGEvent.tapCreate()` with `.cgSessionEventTap` - requires Accessibility permission (`AXIsProcessTrusted()`)
- Event tap listens for key events, flags changes, media keys (type 14), and optionally mouse events
- Auto-unlock timer uses `DispatchWorkItem` with countdown via `Timer`
- Launch at login uses `SMAppService.mainApp`
