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

        // Install the SwiftUI content. The layering is deliberate:
        //
        //   • `DragContainerView` (the window's contentView) sits BENEATH
        //     the SwiftUI hosting view and has
        //     `mouseDownCanMoveWindow = true`. It only receives mouse
        //     events for pixels that SwiftUI explicitly declines to hit
        //     (via `.allowsHitTesting(false)` on ornamental sprites).
        //     When it does, AppKit initiates a classic Winamp "chrome
        //     drag" exactly as if the user had clicked the system
        //     titlebar of a normal window.
        //
        //   • `FirstMouseHostingView` (the NSHostingView wrapping the
        //     SwiftUI content) sits ABOVE the DragContainerView and
        //     handles all interactive clicks. Its ONLY AppKit-level
        //     tweak is `acceptsFirstMouse(for:) = true`, so the first
        //     click on an inactive window doesn't get silently swallowed
        //     during app activation. We intentionally do NOT override
        //     `mouseDownCanMoveWindow` or `hitTest` on the hosting view
        //     — SwiftUI gestures (`.gesture(...)`, `.onTapGesture`, etc.)
        //     are implemented as NSGestureRecognizers attached to the
        //     hosting view, and tampering with hit-testing there breaks
        //     every button and slider inside.
        //
        //   • The title bar has an explicit `WindowDragArea`
        //     (NSViewRepresentable wrapping an NSView with
        //     `mouseDownCanMoveWindow = true`) for the obvious drag
        //     handle.
        //
        // For chrome drag-in-dead-region to work on the main window, its
        // ornamental sprite layers (time digits, song title, bitrate,
        // mono/stereo indicators, etc.) must be marked
        // `.allowsHitTesting(false)` — otherwise those non-interactive
        // SwiftUI views silently capture the clicks and neither the
        // window nor the controls move. See `WinampMainWindowSkinned`.
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

/// `NSHostingView` subclass whose only job is to accept first-mouse
/// events so inactive-window clicks aren't silently swallowed just to
/// activate the app.
///
/// We intentionally do NOT override `hitTest(_:)` or
/// `mouseDownCanMoveWindow` on the hosting view itself — both have
/// previously been tried and both break interactive SwiftUI controls on
/// the main window. Here's why:
///
/// SwiftUI on macOS implements `.gesture(...)` via NSGestureRecognizer
/// instances attached to the NSHostingView, NOT to deeper per-control
/// NSViews. When AppKit's hit-test resolves a click to the NSHostingView
/// (which it does whenever the click lands on a SwiftUI region that
/// doesn't register its own NSView — this is the common case for sprite
/// buttons and the .contentShape+.gesture pattern in SkinnedSlider,
/// SpriteButton, etc.), the NSHostingView's gesture-recognizer machinery
/// is what routes the event into SwiftUI. So:
///
///   • Making `hitTest` return `nil` when the hit is the hosting view
///     tells AppKit "no responder here" — the gesture recognizers never
///     see the event, and every SpriteButton / SkinnedSlider / toggle
///     stops responding. That was what made the *entire* main window
///     feel unclickable.
///
///   • Making `mouseDownCanMoveWindow` return `true` on the hosting view
///     tells AppKit "any click here is a window-drag" — same failure
///     mode, gestures never fire.
///
/// The main window has many more ornamental sprites stacked on top of
/// its chrome than EQ or Playlist, so those hits resolve to the hosting
/// view far more often — which is why the symptom was asymmetric.
///
/// The correct split of responsibilities:
///   • Interactive controls handle their own clicks via SwiftUI gestures
///     that live on the hosting view.
///   • Ornamental sprites are marked `.allowsHitTesting(false)` in
///     SwiftUI, so clicks on them fall *through* the SwiftUI layer and
///     land on the underlying `DragContainerView`.
///   • `DragContainerView.mouseDownCanMoveWindow = true` makes those
///     fall-through clicks start a window drag.
///   • The title bar has an explicit `WindowDragArea` (a dedicated
///     NSViewRepresentable with `mouseDownCanMoveWindow = true`) for the
///     obvious click-and-drag gesture.
private final class FirstMouseHostingView: NSHostingView<AnyView> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
#endif
