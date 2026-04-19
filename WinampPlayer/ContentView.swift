import SwiftUI

struct ContentView: View {
    @EnvironmentObject var player: AudioPlayerManager
    @EnvironmentObject var library: MusicLibraryManager

    var body: some View {
        WinampLayout()
            .onAppear {
                if !library.needsFolderSelection {
                    library.startScanning()
                }
            }
    }
}

// MARK: - Platform-aware layout
///
///  • macOS — Mimics the reference video: 3 "windows" arranged with the
///    Main player + Equalizer stacked on the LEFT and the Playlist on the
///    RIGHT (playlist "stays on the right").
///
///  • iOS — Vertical stack in a single scroll view, Main → Equalizer →
///    Playlist.
struct WinampLayout: View {
    // Dimensions tuned to match the reference video proportions
    private let mainWidth: CGFloat = 330
    private let playlistWidth: CGFloat = 320

    var body: some View {
        ZStack {
            WinampBackground()

            #if os(macOS)
            macOSLayout
            #else
            iOSLayout
            #endif
        }
    }

    // MARK: - macOS: 3-window video layout
    #if os(macOS)
    private var macOSLayout: some View {
        HStack(alignment: .top, spacing: 8) {
            // Left column: Main window + Equalizer stacked
            VStack(spacing: 8) {
                WinampMainWindow()
                    .frame(width: mainWidth)
                WinampEqualizer()
                    .frame(width: mainWidth)
                Spacer(minLength: 0)
            }

            // Right column: Playlist window (taller, spans full height)
            WinampPlaylistWindow()
                .frame(width: playlistWidth)
                .frame(maxHeight: .infinity)
        }
        .padding(8)
        .frame(minWidth: mainWidth + playlistWidth + 24,
               minHeight: 360)
    }
    #endif

    // MARK: - iOS: vertical stack
    #if os(iOS)
    private var iOSLayout: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                WinampMainWindow()
                WinampEqualizer()
                WinampPlaylistWindow()
                    .frame(minHeight: 320)
            }
            .frame(maxWidth: mainWidth)
            .padding(8)
        }
        .frame(maxWidth: .infinity)
    }
    #endif
}

// MARK: - The Main player "window" (Phase 3: real Winamp skin sprites)
///
/// The composition is implemented in `WinampMainWindowSkinned.swift` — this
/// thin wrapper keeps the legacy type name so the window controller built by
/// `WinampAppDelegate` (and the iOS / preview callers in `WinampLayout`)
/// still resolves without any changes.
struct WinampMainWindow: View {
    var body: some View {
        WinampMainWindowSkinned()
    }
}

// MARK: - The Playlist "window" (Title bar + list + ADD/REM/SEL/MISC bar)
struct WinampPlaylistWindow: View {
    var body: some View {
        VStack(spacing: 0) {
            WinampTitleBar(title: "WINAMP PLAYLIST")
            PlaylistView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(WinampTheme.frameBg)
        .overlay(
            Rectangle().strokeBorder(
                LinearGradient(
                    colors: [WinampTheme.frameHighlight, WinampTheme.frameShadow],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        )
    }
}
