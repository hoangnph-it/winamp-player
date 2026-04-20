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

    /// Global key-down monitor that guarantees our shortcuts work even
    /// when SwiftUI temporarily overrides the menu bar during setup.
    private var keyMonitor: Any?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Promote the app to a regular foreground app with menu bar + Dock
        // icon, and activate it so the borderless windows we're about to
        // open are actually clickable. Without this, macOS leaves the app
        // in an ambiguous activation state (our only SwiftUI scene is a
        // `Settings` placeholder, so SwiftUI itself never triggers
        // foreground activation), and clicks on our windows get swallowed
        // just to bring the app to the front — which looks like "the
        // windows are transparent / unclickable" to the user.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        buildControllers()
        coordinator.placeWindows()

        // Main + EQ + Playlist come up on launch. The library window is
        // only shown when the user asks for it (from the `Window` menu or
        // the clutterbar); it stays hidden otherwise.
        coordinator.controller(for: .main)?.show()
        coordinator.controller(for: .equalizer)?.show()
        coordinator.controller(for: .playlist)?.show()
        coordinator.refreshLayout()

        // Kick off library scanning once on launch (mirrors the original
        // ContentView.onAppear behavior).
        if !library.needsFolderSelection {
            library.startScanning()
        }

        // SwiftUI may rebuild the main menu after this delegate method
        // completes, wiping anything we insert now. Defer to the next
        // run-loop tick so our shortcuts land *after* SwiftUI's own pass.
        DispatchQueue.main.async { [weak self] in
            self?.installMenuShortcuts()
        }

        installKeyMonitor()
    }

    /// Re-install shortcuts each time the app becomes active — this is
    /// idempotent (we remove any pre-existing `winamp`-tagged items first)
    /// and it covers the rare case where SwiftUI regenerates the menu bar
    /// when another app returns focus.
    ///
    /// Also force every visible cluster window to the front. Borderless
    /// `NSWindow`s at `level = .normal` do not automatically reorder above
    /// other applications' windows when our app becomes frontmost — which
    /// is why clicking the Dock icon previously *activated* the app but
    /// left the Winamp windows hidden behind whatever app the user was
    /// looking at. Ordering them front here is the reliable hook; it fires
    /// for every activation path (Dock click, Cmd-Tab, relaunch, etc.)
    /// whereas `applicationShouldHandleReopen` only fires on some of them.
    func applicationDidBecomeActive(_ notification: Notification) {
        installMenuShortcuts()
        bringClusterToFront()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// Fired once, synchronously, just before the app exits. Flush the
    /// debounced layout save so the last move/resize actually lands in
    /// UserDefaults — otherwise a quick drag-then-Cmd+Q loses the update.
    func applicationWillTerminate(_ notification: Notification) {
        coordinator.saveLayout()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows flag: Bool) -> Bool {
        // Clicking the Dock icon (or double-clicking the app bundle) should
        // always bring the Winamp cluster to the front. If no cluster
        // window is currently visible, unhide the main window first — the
        // user can bring up the EQ / Playlist / Library from the clutterbar.
        let anyVisible = WinampWindowKind.allCases.contains {
            coordinator.controller(for: $0)?.isVisible == true
        }
        if !anyVisible {
            coordinator.controller(for: .main)?.show()
        }
        NSApp.activate(ignoringOtherApps: true)
        bringClusterToFront()
        return true
    }

    /// Re-orders every currently-visible cluster window above other apps.
    /// Uses `orderFrontRegardless` because our windows live at `.normal`
    /// level — plain `orderFront(nil)` won't lift them above another app's
    /// frontmost window, which is exactly the "Dock icon does nothing"
    /// symptom the user sees.
    private func bringClusterToFront() {
        // Order bottom-up so the natural cluster stacking ends with main
        // on top (matches classic Winamp). Skip library if it's hidden.
        let stack: [WinampWindowKind] = [.library, .playlist, .equalizer, .main]
        for kind in stack {
            if let c = coordinator.controller(for: kind), c.isVisible {
                c.window.orderFrontRegardless()
            }
        }
        // Make the main window key if nothing else currently is — so
        // keyboard shortcuts route correctly after activation.
        if NSApp.keyWindow == nil,
           let main = coordinator.controller(for: .main),
           main.isVisible {
            main.window.makeKey()
        }
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
            WinampLibrarySkinned()
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
        submenu.addItem(NSMenuItem.separator())
        addItem("Reset Window Positions", key: "0", action: #selector(resetLayout(_:)))
    }

    // MARK: - Global key monitor (fallback shortcut router)

    /// Installs a local monitor that catches Cmd+{1,2,3,4,D,Shift+D} and
    /// routes them to the same actions the menu uses. This guarantees the
    /// shortcuts work even before the Window menu is fully installed and
    /// regardless of which Winamp window currently has focus.
    private func installKeyMonitor() {
        if let existing = keyMonitor {
            NSEvent.removeMonitor(existing)
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            guard event.modifierFlags.contains(.command) else { return event }

            let hasShift = event.modifierFlags.contains(.shift)
            let key = event.charactersIgnoringModifiers?.lowercased() ?? ""

            switch (key, hasShift) {
            case ("1", false): self.toggle(.main);              return nil
            case ("2", false): self.toggle(.equalizer);         return nil
            case ("3", false): self.toggle(.playlist);          return nil
            case ("4", false): self.toggle(.library);           return nil
            case ("0", false): self.coordinator.resetLayout();  return nil
            case ("d", false):
                self.coordinator.controller(for: .main)?.toggleShade()
                return nil
            case ("d", true):
                self.coordinator.controller(for: .equalizer)?.toggleShade()
                return nil
            default:
                return event
            }
        }
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

    @objc private func resetLayout(_ sender: Any?) {
        coordinator.resetLayout()
    }

    private func toggle(_ kind: WinampWindowKind) {
        guard let c = coordinator.controller(for: kind) else { return }
        if c.isVisible { c.hide() } else { c.show() }
    }
}
#endif
