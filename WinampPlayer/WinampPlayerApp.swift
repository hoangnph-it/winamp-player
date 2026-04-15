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
                .frame(minWidth: 340, minHeight: 560)
            #endif
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .defaultSize(width: 370, height: 640)
        #endif
    }
}
