# WinampPlayer - Classic Winamp-Style Music Player

A SwiftUI multiplatform music player for **iOS** and **macOS** with a classic Winamp-inspired UI. Plays MP3 and WAV files from your iCloud Drive or any local folder.

## Features

- **Classic Winamp UI** — Dark theme with green LCD display, spectrum analyzer visualization, segmented transport controls
- **MP3 & WAV Support** — Plays both formats using AVFoundation
- **iCloud Drive Integration** — Automatically scans your iCloud Drive for music files
- **Folder Scanner** — Point to any folder on your device to discover audio files
- **Playlist Management** — Add, remove, reorder tracks; play all or enqueue
- **Shuffle & Repeat** — Shuffle mode plus repeat off/all/one
- **Search** — Search by title, artist, or album across your library
- **Audio Visualization** — Real-time spectrum analyzer bars
- **Metadata Extraction** — Reads ID3 tags (title, artist, album, duration) from audio files
- **Responsive Layout** — Side-by-side layout on macOS, stacked layout on iOS

## Requirements

- Xcode 15+
- iOS 16.0+ / macOS 13.0+
- An Apple Developer account (for iCloud entitlements)

## Setup Instructions

### 1. Open in Xcode

Double-click `WinampPlayer.xcodeproj` to open the project in Xcode.

> **Recommended:** Since the `.pbxproj` was generated externally, you may get better results creating a fresh Xcode project and dragging in the source files. See "Alternative Setup" below.

### 2. Configure Signing & Capabilities

1. Select the **WinampPlayer** target
2. Go to **Signing & Capabilities**
3. Select your **Team**
4. Change the **Bundle Identifier** to something unique (e.g., `com.yourname.winampplayer`)
5. Add the **iCloud** capability:
   - Check **CloudKit** or **iCloud Documents**
   - Add container: `iCloud.com.yourname.winampplayer`
6. Update the container identifier in `WinampPlayer.entitlements` and `Info.plist` to match

### 3. Select Target Platform

- For iPhone/iPad: Select an iOS simulator or device
- For Mac: Select "My Mac" as the run destination

### 4. Build & Run

Press `Cmd+R` to build and run!

## Alternative Setup (Recommended)

If the `.xcodeproj` doesn't open cleanly:

1. **Create a new Xcode project:**
   - File → New → Project
   - Choose **Multiplatform → App**
   - Product Name: `WinampPlayer`
   - Interface: SwiftUI
   - Language: Swift

2. **Add source files:**
   - Delete the default `ContentView.swift` (we have our own)
   - Drag all `.swift` files from `WinampPlayer/` folder structure into the Xcode project navigator
   - Make sure "Copy items if needed" is checked
   - Ensure all files are added to the WinampPlayer target

3. **Copy configuration files:**
   - Replace `Info.plist` with ours
   - Add `WinampPlayer.entitlements` to the project

4. **Add iCloud capability:**
   - Target → Signing & Capabilities → + Capability → iCloud
   - Enable iCloud Documents
   - Add your container identifier

5. **Set deployment targets:**
   - iOS: 16.0
   - macOS: 13.0

## Project Structure

```
WinampPlayer/
├── WinampPlayerApp.swift          # App entry point
├── ContentView.swift              # Main view (iOS/macOS layouts)
├── Info.plist                     # App configuration
├── WinampPlayer.entitlements      # iCloud & sandbox permissions
├── Models/
│   ├── Track.swift                # Audio track model with metadata
│   ├── Playlist.swift             # Playlist management
│   └── PlayerState.swift          # Playback state enums
├── Services/
│   ├── AudioPlayerManager.swift   # AVFoundation audio engine
│   └── MusicLibraryManager.swift  # iCloud & folder scanning
├── Views/
│   ├── Components/
│   │   ├── WinampBackground.swift
│   │   ├── WinampTitleBar.swift
│   │   ├── WinampDisplay.swift
│   │   ├── WinampTransportControls.swift
│   │   ├── WinampSeekBar.swift
│   │   ├── WinampVolumeControl.swift
│   │   ├── AudioVisualizerView.swift
│   │   └── WinampTabBar.swift
│   └── Screens/
│       ├── PlaylistView.swift
│       ├── LibraryBrowserView.swift
│       └── SearchView.swift
└── Utilities/
    └── WinampTheme.swift          # Colors, fonts, button styles
```

## Usage

1. **First launch:** The app scans your iCloud Drive for MP3/WAV files automatically
2. **Select a folder:** Go to the Library tab and tap the folder selector to pick any folder
3. **Play music:** Tap any track to start playing, or use "Play All" to queue everything
4. **Manage playlist:** Switch to the Playlist tab to see your queue, remove tracks, or clear all
5. **Search:** Use the Search tab to find tracks by title, artist, or album

## License

MIT License
