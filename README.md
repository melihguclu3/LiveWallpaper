# LiveWallpaper

A lightweight macOS menu bar app that lets you set **videos**, **GIFs**, or **YouTube videos** as your desktop wallpaper.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Video wallpaper** — Play any video file (MP4, MOV, AVI) as your desktop background
- **GIF wallpaper** — Use animated GIFs as wallpaper with smooth Core Animation playback
- **YouTube support** — Paste a YouTube URL, download, and set as wallpaper (requires `yt-dlp`)
- **Multi-monitor** — Show wallpaper on all screens or just the main display
- **Sleep/wake safe** — No duplicate windows or glitches after waking from sleep
- **Menu bar app** — Lives in the menu bar, no dock icon clutter
- **Launch at login** — Optionally start with macOS
- **Mute control** — Toggle video audio on/off
- **Localized** — English and Turkish

## Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder" width="320" alt="LiveWallpaper menu">
</p>

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16+ (to build)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (to generate Xcode project)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) (optional, for YouTube support)

## Installation

### Build from source

```bash
# 1. Clone the repo
git clone https://github.com/melihguclu3/LiveWallpaper.git
cd LiveWallpaper

# 2. Install XcodeGen (if you don't have it)
brew install xcodegen

# 3. Generate the Xcode project
xcodegen generate

# 4. Build
xcodebuild -project LiveWallpaper.xcodeproj \
  -scheme LiveWallpaper \
  -configuration Release \
  build

# 5. Copy to Applications
cp -R ~/Library/Developer/Xcode/DerivedData/LiveWallpaper-*/Build/Products/Release/LiveWallpaper.app /Applications/

# 6. Launch
open /Applications/LiveWallpaper.app
```

### One-liner

```bash
git clone https://github.com/melihguclu3/LiveWallpaper.git && cd LiveWallpaper && brew install xcodegen && xcodegen generate && xcodebuild -project LiveWallpaper.xcodeproj -scheme LiveWallpaper -configuration Release build && cp -R ~/Library/Developer/Xcode/DerivedData/LiveWallpaper-*/Build/Products/Release/LiveWallpaper.app /Applications/ && open /Applications/LiveWallpaper.app
```

### YouTube support (optional)

```bash
brew install yt-dlp
```

## Usage

1. Click the **play icon** in the menu bar
2. Choose a source:
   - **Video Sec / Choose Video** — pick a local video file
   - **GIF Sec / Choose GIF** — pick a local GIF file
   - **YouTube URL** — paste a link and click Download
3. Use **Pause / Play / Stop** to control playback
4. Toggle options:
   - **Show on All Screens** — multi-monitor support
   - **Muted** — mute/unmute video audio
   - **Launch at Login** — auto-start with macOS

## Project Structure

```
Sources/
  LiveWallpaperApp.swift   — App entry point (@main)
  AppDelegate.swift        — Menu bar + popover setup
  PopoverView.swift        — SwiftUI popover UI
  WallpaperManager.swift   — Central playback & window manager
  WallpaperWindow.swift    — Desktop-level borderless window
  VideoPlayerView.swift    — AVPlayerLooper video playback
  GIFPlayerView.swift      — Core Animation GIF playback
  YouTubeService.swift     — yt-dlp download wrapper
  SleepWakeHandler.swift   — Sleep/wake bug prevention
  ScreenObserver.swift     — Monitor connect/disconnect handling
  LaunchAtLogin.swift      — SMAppService login item
  Defaults.swift           — UserDefaults persistence
  Localization.swift       — L10n helper
Resources/
  en.lproj/                — English strings
  tr.lproj/                — Turkish strings
  Assets.xcassets/         — App icon
```

## How it works

- **WallpaperWindow** creates a borderless `NSWindow` at desktop level (below icons, above wallpaper)
- **VideoPlayerView** uses `AVQueuePlayer` + `AVPlayerLooper` for gapless hardware-accelerated looping
- **GIFPlayerView** extracts frames via `CGImageSource` and animates with `CAKeyframeAnimation`
- **SleepWakeHandler** listens for sleep/wake and screen lock notifications — pauses on sleep, resumes on wake without creating new windows (fixes the classic duplicate-window bug)
- **ScreenObserver** reacts to monitor changes and reconfigures windows automatically

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Made by [Melih Guclu](https://github.com/melihguclu3)
