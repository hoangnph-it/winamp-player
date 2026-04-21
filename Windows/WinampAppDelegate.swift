#if os(macOS)
import AppKit
import SwiftUI

/// Application delegate that bootstraps the multi-window cluster on macOS.
///
/// Owns the shared `AudioPlayerManager` + `MusicLibraryManager` so every
/// window observes the same playback state and library. Creates the
/// `WindowCoordinator` and four `WinampWindowController`s (main, equalizer,
/// playlist, library) and shows the first three on launch. The library
/// window is hidden by default and is toggled from the main window's
/// clutterbar in Phase 3 (temporarily via the `Window` menu entry below).
final class WinampAppDelegate: NSObject, NSApplicationDelegate {

    // Kept alive for the entire app lifetime — every window references them.
    let player = AudioPlayerManager()
    let library = MusicLibraryManager()
    let coordinator = WindowCoordinator()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildControllers()
        coordinator.placeWindows()

        // Main + EQ + Playlist come up on launch. The library window is
        // only shown when the user asks for it (from the `Window` menu or
        // the clutterbar); it stays hidden otherwise.
        //
        // Show order matters: each `show()` calls `makeKeyAndOrderFront`
        // under the hood, so whichever window is shown LAST becomes the
        // key window (and, after the coordinator's deferred cluster-raise
        // runs, the topmost window too). Classic Winamp always wants the
        // main window to be key+topmost at launch — so we show the
        // auxiliaries first (playlist, then EQ), and main last.
        coordinator.controller(for: .playlist)?.show()
        coordinator.controller(for: .equalizer)?.show()
        coordinator.controller(for: .main)?.show()
        coordinator.refreshLayout()

        // Kick off library scanning once on launch (mirrors the original
        // ContentView.onAppear behavior).
        if !library.needsFolderSelection {
            library.startScanning()
        }

        installMenuShortcuts()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            coordinator.controller(for: .main)?.show()
        }
        return true
    }

    // MARK: - Window construction

    private func buildControllers() {
        // Each controller hosts the existing SwiftUI view for now. Phases
        // 3-5 replace these bodies with the skin-sprite rebuilds.
        let mainController = WinampWindowController(kind: .main) {
            WinampMainWindow()
                .environmentObject(self.player)
                .environmentObject(self.library)
        }
        coordinator.register(mainController)

        let eqController = WinampWindowController(kind: .equalizer) {
            WinampEqualizer()
                .environmentObject(self.player)
                .environmentObject(self.library)
        }
        coordinator.register(eqController)

        let plController = WinampWindowController(kind: .playlist) {
            WinampPlaylistWindow()
                .environmentObject(self.player)
                .environmentObject(self.library)
        }
        coordinator.register(plController)

        let libController = WinampWindowController(kind: .library) {
            LibraryBrowserView()
                .environmentObject(self.player)
                .environmentObject(self.library)
        }
        coordinator.register(libController)
    }

    // MARK: - Menu shortcuts for toggling auxiliary windows

    /// Adds a minimal `Window` submenu so users can re-open EQ / Playlist /
    /// Library without a clutterbar (the clutterbar arrives in Phase 3).
    private func installMenuShortcuts() {
        guard let mainMenu = NSApp.mainMenu else { return }

        // Find or create the "Window" menu.
        let windowMenuItem: NSMenuItem = {
            if let item = mainMenu.items.first(where: { $0.title == "Window" }) {
                return item
            }
            let item = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
            item.submenu = NSMenu(title: "Window")
            mainMenu.addItem(item)
            return item
        }()
        guard let submenu = windowMenuItem.submenu else { return }

        // Remove any previously-installed Winamp items so we don't duplicate.
        submenu.items
            .filter { $0.representedObject as? String == "winamp" }
            .forEach { submenu.removeItem($0) }

        submenu.addItem(NSMenuItem.separator())

        func addItem(_ title: String,
                     key: String,
                     mods: NSEvent.ModifierFlags = [.command],
                     action: Selector) {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
            item.keyEquivalentModifierMask = mods
            item.target = self
            item.representedObject = "winamp"
            submenu.addItem(item)
        }

        addItem("Show/Hide Main",      key: "1", action: #selector(toggleMain(_:)))
        addItem("Show/Hide Equalizer", key: "2", action: #selector(toggleEqualizer(_:)))
        addItem("Show/Hide Playlist",  key: "3", action: #selector(togglePlaylist(_:)))
        addItem("Show/Hide Library",   key: "4", action: #selector(toggleLibrary(_:)))
        submenu.addItem(NSMenuItem.separator())
        addItem("Toggle Shade (Main)",     key: "d", action: #selector(shadeMain(_:)))
        addItem("Toggle Shade (Equalizer)", key: "d", mods: [.command, .shift], action: #selector(shadeEqualizer(_:)))
    }

    // MARK: - Menu actions

    @objc private func toggleMain(_ sender: Any?)      { toggle(.main) }
    @objc private func toggleEqualizer(_ sender: Any?) { toggle(.equalizer) }
    @objc private func togglePlaylist(_ sender: Any?)  { toggle(.playlist) }
    @objc private func toggleLibrary(_ sender: Any?)   { toggle(.library) }

    @objc private func shadeMain(_ sender: Any?) {
        coordinator.controller(for: .main)?.toggleShade()
    }
    @objc private func shadeEqualizer(_ sender: Any?) {
        coordinator.controller(for: .equalizer)?.toggleShade()
    }

    private func toggle(_ kind: WinampWindowKind) {
        guard let c = coordinator.controller(for: kind) else { return }
        if c.isVisible { c.hide() } else { c.show() }
    }
}
#endif
