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

## Installation

### Quick install (download pre-built app)

1. Go to [**Releases**](https://github.com/melihguclu3/LiveWallpaper/releases/latest)
2. Download `LiveWallpaper.zip`
3. Unzip and move `LiveWallpaper.app` to `/Applications`
4. Open the app — look for the **play icon** in your menu bar

> **Note:** On first launch, macOS may show "unidentified developer" warning. Go to **System Settings > Privacy & Security** and click **Open Anyway**.

### Build from source

```bash
git clone https://github.com/melihguclu3/LiveWallpaper.git
cd LiveWallpaper
./install.sh
```

The script handles everything: installs XcodeGen if needed, builds, copies to `/Applications`, and launches.

**Requirements for building:** macOS 14+, Xcode Command Line Tools (`xcode-select --install`)

### YouTube support (optional)

```bash
brew install yt-dlp
```

## Usage

1. Click the **play icon** in the menu bar
2. Choose a source:
   - **Choose Video** — pick a local video file
   - **Choose GIF** — pick a local GIF file
   - **YouTube URL** — paste a link and click Download
3. Use **Pause / Play / Stop** to control playback
4. Toggle options:
   - **Show on All Screens** — multi-monitor support
   - **Muted** — mute/unmute video audio
   - **Launch at Login** — auto-start with macOS

## Uninstall

```bash
rm -rf /Applications/LiveWallpaper.app
```

## How it works

- **WallpaperWindow** creates a borderless `NSWindow` at desktop level (below icons, above wallpaper)
- **VideoPlayerView** uses `AVQueuePlayer` + `AVPlayerLooper` for gapless hardware-accelerated looping
- **GIFPlayerView** extracts frames via `CGImageSource` and animates with `CAKeyframeAnimation`
- **SleepWakeHandler** listens for sleep/wake and screen lock notifications — pauses on sleep, resumes on wake without creating new windows (fixes the classic duplicate-window bug)
- **ScreenObserver** reacts to monitor changes and reconfigures windows automatically

## Project Structure

```
Sources/
  LiveWallpaperApp.swift   — App entry point
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

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Made by [Melih Guclu](https://github.com/melihguclu3)
