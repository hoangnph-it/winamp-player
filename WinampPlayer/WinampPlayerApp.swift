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
                .frame(minWidth: 600, minHeight: 500)
            #endif
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .defaultSize(width: 800, height: 600)
        #endif
    }
}
