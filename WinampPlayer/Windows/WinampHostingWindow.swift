#if os(macOS)
import AppKit
import SwiftUI

/// Borderless `NSWindow` subclass that hosts one Winamp window (main, EQ,
/// playlist, or library).
///
/// Classic Winamp doesn't use the system titlebar — the entire window is
/// the skin bitmap and drags start anywhere in the chrome. We achieve that
/// with `.borderless`, a transparent background, and `isMovableByWindowBackground`.
///
/// We still want the window to act like a real first-class citizen:
///   • it can become key + main (so keystrokes/menus route to it),
///   • it's part of the window cycle,
///   • it deposits a proper restoration identifier.
///
/// The SwiftUI content is supplied by the caller and wrapped in an
/// `NSHostingView`. The host view is sized to the window's content rect
/// and resizes together with it.
final class WinampHostingWindow: NSWindow {

    let kind: WinampWindowKind

    init<Content: View>(
        kind: WinampWindowKind,
        initialContentSize: CGSize,
        @ViewBuilder rootView: () -> Content
    ) {
        self.kind = kind

        let contentRect = NSRect(
            origin: .zero,
            size: initialContentSize
        )

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.identifier = NSUserInterfaceItemIdentifier(kind.identifier)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isReleasedWhenClosed = false   // we keep a strong ref in the controller
        self.collectionBehavior = [.fullScreenAuxiliary, .managed]
        self.level = .normal
        self.animationBehavior = .documentWindow

        // Restrict default resize handles — the coordinator enforces the
        // 25×29 increment for the playlist and blocks resize for main/eq.
        if !kind.isHorizontallyResizable && !kind.isVerticallyResizable {
            self.styleMask.remove(.resizable)
            self.minSize = initialContentSize
            self.maxSize = initialContentSize
        } else {
            self.minSize = kind.defaultContentSize
            self.contentResizeIncrements = kind.resizeIncrement
        }

        // Install the SwiftUI content. The container uses a custom NSView
        // subclass whose `mouseDownCanMoveWindow` returns `true`, so any
        // click that lands on a SwiftUI dead zone (a gradient background,
        // a padded gap between controls, etc.) still starts a window drag
        // instead of being swallowed silently. Interactive SwiftUI controls
        // still take precedence — their own hit-test regions get the events
        // first, and only "background" clicks ever reach this layer.
        let host = NSHostingView(rootView: AnyView(rootView()))
        host.translatesAutoresizingMaskIntoConstraints = false
        let container = DragContainerView(frame: contentRect)
        container.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.topAnchor.constraint(equalTo: container.topAnchor),
            host.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        self.contentView = container
    }

    // MARK: - Key / main window eligibility
    //
    // Borderless windows by default refuse keyboard focus. We override so
    // the user can actually interact with controls inside our windows
    // (volume sliders, playlist rows, etc.)
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // MARK: - Focus-cluster coordination
    //
    // Classic Winamp brings all cluster windows forward together. The
    // coordinator installs itself as delegate and listens to `windowDidBecomeKey`
    // to orchestrate that; we just make sure the window *can* become key.
    //
    // Height changes (shade-mode collapse/expand) are driven by the
    // `WinampWindowController`, which anchors the top edge so the title
    // bar stays put.
}

/// Content-view container that also acts as a drag handle.
///
/// Our borderless windows already have `isMovableByWindowBackground = true`
/// but that only fires when a click actually *reaches* the window's content
/// view background. The SwiftUI `NSHostingView` on top eagerly claims hit
/// tests for almost every region (backgrounds, padding, stacks), so those
/// clicks never hit the background. Making the container itself return
/// `mouseDownCanMoveWindow = true` means AppKit treats any click the
/// hosting view lets through — i.e. anywhere SwiftUI has no interactive
/// target — as a drag gesture on the window.
private final class DragContainerView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    /// Accept the first mouse-down even when the window (or the app) is
    /// inactive. By default AppKit swallows the first click on an
    /// inactive borderless window just to activate it, which makes every
    /// control in our window feel like it needs two clicks. Returning
    /// `true` here routes the click to SwiftUI's hit-test normally and
    /// AppKit still handles activation as a side effect.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
#endif
