import SwiftUI

struct ContentView: View {
    @EnvironmentObject var playerManager: AudioPlayerManager
    @EnvironmentObject var libraryManager: MusicLibraryManager

    var body: some View {
        #if os(iOS)
        iOSMainView()
        #else
        macOSMainView()
        #endif
    }
}

// MARK: - iOS Layout
struct iOSMainView: View {
    @EnvironmentObject var playerManager: AudioPlayerManager
    @EnvironmentObject var libraryManager: MusicLibraryManager
    @State private var selectedTab: Int = 1  // Start on Library tab for first-time setup

    var body: some View {
        ZStack {
            WinampBackground()

            VStack(spacing: 0) {
                // Title Bar
                WinampTitleBar(title: playerManager.currentTrack?.title ?? "WINAMP PLAYER")

                // Now Playing Display
                WinampDisplay()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)

                // Visualization
                AudioVisualizerView()
                    .frame(height: 60)
                    .padding(.horizontal, 8)

                // Progress Bar
                WinampSeekBar()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)

                // Transport Controls
                WinampTransportControls()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)

                // Volume
                WinampVolumeControl()
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)

                // Tab Selector
                WinampTabBar(selectedTab: $selectedTab)

                // Content Area
                Group {
                    switch selectedTab {
                    case 0:
                        PlaylistView()
                    case 1:
                        LibraryBrowserView()
                    case 2:
                        SearchView()
                    default:
                        PlaylistView()
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .onAppear {
            // If a folder is already saved, scan it; otherwise stay on Library tab
            if !libraryManager.needsFolderSelection {
                libraryManager.startScanning()
                selectedTab = 0  // Switch to playlist if we already have a folder
            }
        }
    }
}

// MARK: - macOS Layout
struct macOSMainView: View {
    @EnvironmentObject var playerManager: AudioPlayerManager
    @EnvironmentObject var libraryManager: MusicLibraryManager

    var body: some View {
        ZStack {
            WinampBackground()

            VStack(spacing: 0) {
                // Title Bar
                WinampTitleBar(title: playerManager.currentTrack?.title ?? "WINAMP PLAYER")

                HStack(spacing: 0) {
                    // Left: Player Controls
                    VStack(spacing: 0) {
                        // Display
                        WinampDisplay()
                            .padding(8)

                        // Visualization
                        AudioVisualizerView()
                            .frame(height: 80)
                            .padding(.horizontal, 8)

                        // Seek Bar
                        WinampSeekBar()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)

                        // Transport Controls
                        WinampTransportControls()
                            .padding(8)

                        // Volume + Extras
                        HStack {
                            WinampVolumeControl()
                            Spacer()
                            WinampShuffleRepeatControls()
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)

                        Spacer()
                    }
                    .frame(width: 320)

                    // Divider
                    WinampDivider()

                    // Right: Playlist / Library
                    VStack(spacing: 0) {
                        MacOSTabView()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear {
            // If a folder is already saved, scan it automatically
            if !libraryManager.needsFolderSelection {
                libraryManager.startScanning()
            }
        }
    }
}

struct MacOSTabView: View {
    @EnvironmentObject var libraryManager: MusicLibraryManager
    // Start on Library tab if no folder is selected yet
    @State private var selectedTab: Int = 1

    private func initialTab() -> Int {
        libraryManager.needsFolderSelection ? 1 : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            WinampTabBar(selectedTab: $selectedTab)

            Group {
                switch selectedTab {
                case 0:
                    PlaylistView()
                case 1:
                    LibraryBrowserView()
                case 2:
                    SearchView()
                default:
                    PlaylistView()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .onAppear {
            selectedTab = initialTab()
        }
    }
}
