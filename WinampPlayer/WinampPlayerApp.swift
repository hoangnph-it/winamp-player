import SwiftUI

@main
struct WinampPlayerApp: App {
    @StateObject private var playerManager = AudioPlayerManager()
    @StateObject private var libraryManager = MusicLibraryManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerManager)
                .environmentObject(libraryManager)
            #if os(macOS)
                // Matches the reference video: 3 floating windows laid out
                // with Main + EQ on the left column and Playlist on the right.
                .frame(minWidth: 680, minHeight: 380)
            #endif
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .defaultSize(width: 700, height: 440)
        #endif
    }
}
