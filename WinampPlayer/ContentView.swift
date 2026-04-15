import SwiftUI

struct ContentView: View {
    @EnvironmentObject var player: AudioPlayerManager
    @EnvironmentObject var library: MusicLibraryManager

    var body: some View {
        WinampStackedView()
            .onAppear {
                if !library.needsFolderSelection {
                    library.startScanning()
                }
            }
    }
}

// MARK: - Classic stacked Winamp layout
/// Pixel-faithful recreation of the Winamp 2.x window stack:
///   ┌─────────────────────────┐
///   │ WINAMP  (title bar)     │  ← 16pt
///   │ LCD Display             │  ← ~56pt
///   │ Seek bar                │  ← 10pt
///   │ Transport|Vol|Bal|Togl  │  ← ~36pt
///   ├─────────────────────────┤
///   │ WINAMP EQUALIZER        │  ← collapsible
///   ├─────────────────────────┤
///   │ WINAMP PLAYLIST (tabs)  │
///   │ track list …            │  ← fills remaining
///   │ status bar              │
///   └─────────────────────────┘
struct WinampStackedView: View {
    @EnvironmentObject var player: AudioPlayerManager
    @EnvironmentObject var library: MusicLibraryManager
    @State private var selectedTab: Int = 1
    @State private var showEQ: Bool = true

    // Classic Winamp main window is 275px; we scale to ~340–380pt
    private let winampWidth: CGFloat = 360

    var body: some View {
        ZStack {
            WinampBackground()

            #if os(iOS)
            ScrollView(.vertical, showsIndicators: false) {
                mainStack
                    .frame(width: winampWidth)
                    .frame(minHeight: 580)
            }
            .frame(maxWidth: .infinity)
            #else
            mainStack
                .frame(minWidth: 340, idealWidth: winampWidth, minHeight: 480)
            #endif
        }
        .onAppear {
            if !library.needsFolderSelection { selectedTab = 0 }
        }
    }

    private var mainStack: some View {
        VStack(spacing: 0) {
            // ═══════════════════════════════════════
            //  1. MAIN PLAYER WINDOW
            // ═══════════════════════════════════════
            VStack(spacing: 0) {
                // Title bar
                WinampTitleBar(title: player.currentTrack?.formattedTitle ?? "WINAMP")

                // LCD display (black panel with time, viz, scrolling text)
                WinampDisplay()
                    .padding(.horizontal, 3)
                    .padding(.top, 2)

                // Seek bar (thin position bar)
                WinampSeekBar()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)

                // Transport controls + volume + balance + toggles
                WinampControlStrip()
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

            // ═══════════════════════════════════════
            //  2. EQUALIZER (collapsible)
            // ═══════════════════════════════════════
            if showEQ {
                WinampEqualizer()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // ═══════════════════════════════════════
            //  3. PLAYLIST / LIBRARY / SEARCH
            // ═══════════════════════════════════════
            VStack(spacing: 0) {
                // Section title bar
                WinampTitleBar(title: "WINAMP PLAYLIST")

                // Tab switcher
                WinampTabBar(selectedTab: $selectedTab)

                // Content
                Group {
                    switch selectedTab {
                    case 0: PlaylistView()
                    case 1: LibraryBrowserView()
                    case 2: SearchView()
                    default: PlaylistView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                #if os(iOS)
                .frame(minHeight: 200)
                #endif
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
            .frame(maxHeight: .infinity)
        }
    }
}
