import SwiftUI

/// App entry point.
///
///  • macOS — Owns a `WinampAppDelegate` that creates the three (four with
///    Library) borderless `NSWindow`s, each hosting its SwiftUI content and
///    subject to snap/dock/shade via `WindowCoordinator`. The legacy
///    `WindowGroup` is replaced by a `Settings` scene so SwiftUI doesn't
///    auto-spawn an extra unstyled window.
///
///  • iOS — Keeps the original single-window stacked layout from
///    `ContentView` / `WinampLayout`. iOS doesn't support the same
///    free-floating multi-window metaphor (and doesn't need snap/dock),
///    so the multi-window code is compiled out entirely.
@main
struct WinampPlayerApp: App {

    #if os(macOS)
    @NSApplicationDelegateAdaptor(WinampAppDelegate.self) private var appDelegate
    #else
    @StateObject private var playerManager = AudioPlayerManager()
    @StateObject private var libraryManager = MusicLibraryManager()
    #endif

    var body: some Scene {
        #if os(macOS)
        // The delegate opens its own NSWindows; we just need a placeholder
        // scene so the SwiftUI App isn't empty. `Settings` is the only
        // built-in scene that doesn't auto-show a window.
        Settings {
            EmptyView()
        }
        #else
        WindowGroup {
            ContentView()
                .environmentObject(playerManager)
                .environmentObject(libraryManager)
        }
        #endif
    }
}
