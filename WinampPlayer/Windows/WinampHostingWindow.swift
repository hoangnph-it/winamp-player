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
        //
        // We use `FirstMouseHostingView` (a tiny NSHostingView subclass)
        // instead of NSHostingView directly so the view returns `true` from
        // `acceptsFirstMouse(for:)`. AppKit hit-tests depth-first — clicks
        // reach the hosting view *before* our DragContainerView underneath —
        // and the default NSHostingView swallows the first click on an
        // inactive window just to activate it. That's the root cause of
        // "I can click EQ and Playlist but not the main window": whichever
        // window is currently non-key loses its first click entirely.
        let host = FirstMouseHostingView(rootView: AnyView(rootView()))
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

/// `NSHostingView` subclass that (1) accepts first-mouse events and
/// (2) makes every "dead" (non-interactive) SwiftUI region drag the
/// window, matching classic Winamp's "any chrome click = drag" feel.
///
/// Two AppKit-vs-SwiftUI impedance mismatches bite us here:
///
/// 1. **First-mouse swallow.** Stock `NSHostingView.acceptsFirstMouse(for:)`
///    returns `false`, so AppKit swallows the first click on any window
///    that isn't already key. Because clicks never make it into SwiftUI
///    on that first event, the user sees interactive controls as
///    unresponsive until they click a second time. Returning `true`
///    routes that first click through SwiftUI's hit-test immediately.
///
/// 2. **Dead-region swallow.** `NSHostingView.hitTest(_:)` resolves most
///    "chrome" clicks to the hosting view (or to one of SwiftUI's own
///    internal container NSViews) rather than to a deeper
///    gesture-bearing subview. By default, AppKit delivers `mouseDown`
///    to that target but its `mouseDownCanMoveWindow` is `false`, so
///    the click is silently eaten and the window stays put. Previously
///    we tried to patch this by returning `nil` from `hitTest` whenever
///    `super.hitTest(point) === self` — but that check only catches the
///    hosting view itself, and **misses** the case where SwiftUI
///    returns an internal (non-`self`, non-interactive) hosting
///    subview. That's why the main window — which has more overlaid
///    sprite layers than Equalizer/Playlist — had lots of chrome
///    regions that felt "transparent and unclickable" while the
///    simpler windows worked.
///
///    The more reliable fix is structural: override
///    `mouseDownCanMoveWindow` on the hosting view itself to return
///    `true`. AppKit consults `mouseDownCanMoveWindow` on the
///    final hit target, so **any** click that lands on the hosting
///    view (including its internal container descendants that inherit
///    the NSView default of `false`, unless they override it) still
///    ends up starting a window drag because the property is resolved
///    via the normal key-value lookup on the NSView subclass — and
///    the drag-activation code walks up the responder chain from the
///    hit view to find a target that wants the drag.
///
///    This works alongside the hosting window's
///    `isMovableByWindowBackground` and the underlying
///    `DragContainerView`, which remain as backstops.
///
///    Interactive SwiftUI controls (buttons, sliders, toggles) are
///    backed by *deeper* NSView instances created by SwiftUI's
///    gesture-recognition machinery. Their `hitTest` returns those
///    views rather than the hosting view, AppKit delivers the
///    `mouseDown` to them, and SwiftUI's gesture recognizers run
///    normally — so the controls still work.
private final class FirstMouseHostingView: NSHostingView<AnyView> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Make the entire hosting-view background a drag handle. See the
    /// long comment above for why this replaces the previous
    /// `hitTest`-returning-`nil` trick.
    override var mouseDownCanMoveWindow: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        // Belt-and-braces: if SwiftUI's own hit-testing lands on the
        // hosting view (no deeper subview claimed the point), fall back
        // to the container NSView beneath so AppKit's background-drag
        // path fires even on systems where `mouseDownCanMoveWindow` on
        // an NSHostingView isn't honored.
        return hit === self ? nil : hit
    }
}
#endif
