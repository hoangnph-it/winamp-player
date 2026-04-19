#if os(macOS)
import AppKit
import SwiftUI
import Combine

/// Thin `NSWindowController` wrapper around one `WinampHostingWindow`.
///
/// Responsibilities:
///   • Own the NSWindow (keeps it alive since `isReleasedWhenClosed = false`).
///   • Broadcast move/resize events to the `WindowCoordinator` so sibling
///     windows can snap or tag along.
///   • Maintain the current `shade` state and animate transitions between
///     the full content height and the 14px shaded title bar.
///   • Forward key-window changes to the coordinator so clicking any
///     window brings the whole cluster forward.
///
/// This controller is intentionally *dumb* about layout math — the
/// coordinator computes snapped frames and then calls `apply(frame:)` here.
final class WinampWindowController: NSObject, NSWindowDelegate {

    let kind: WinampWindowKind
    let window: WinampHostingWindow

    /// Weak reference back to the coordinator. Set right after construction.
    weak var coordinator: WindowCoordinator?

    /// Emits shade changes to SwiftUI content (so the title bar can flip
    /// its shade button icon).
    @Published private(set) var isShaded: Bool = false

    /// The full (un-shaded) content height we snap back to when un-shading.
    /// Updated whenever the user finishes a resize while not shaded.
    private var lastFullHeight: CGFloat

    /// Tracks whether the current frame change originated from our own
    /// coordinator (to avoid feedback loops while snapping).
    private var isApplyingCoordinatorFrame = false

    init<Content: View>(
        kind: WinampWindowKind,
        @ViewBuilder content: () -> Content
    ) {
        self.kind = kind
        let size = kind.defaultContentSize
        self.lastFullHeight = size.height
        self.window = WinampHostingWindow(
            kind: kind,
            initialContentSize: size,
            rootView: content
        )
        super.init()
        self.window.delegate = self
    }

    // MARK: - Placement

    /// Move the window to a new frame without triggering snap feedback.
    func applyFrame(_ frame: NSRect, animate: Bool = false) {
        isApplyingCoordinatorFrame = true
        window.setFrame(frame, display: true, animate: animate)
        isApplyingCoordinatorFrame = false
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
    }

    func hide() {
        window.orderOut(nil)
    }

    var isVisible: Bool { window.isVisible }

    // MARK: - Shade mode

    /// Toggles between full-height and the 14px shaded bar.
    func toggleShade() {
        guard kind.supportsShade else { return }
        setShaded(!isShaded, animate: true)
    }

    func setShaded(_ shaded: Bool, animate: Bool) {
        guard kind.supportsShade, shaded != isShaded else { return }
        if !isShaded {
            // About to shade — remember current height so we can restore.
            lastFullHeight = window.frame.size.height
        }
        isShaded = shaded
        let newHeight = shaded ? kind.shadedHeight : lastFullHeight

        // Compute the new frame so the window's top edge stays put (matches
        // classic Winamp — body collapses upward).
        var frame = window.frame
        let delta = newHeight - frame.size.height
        frame.size.height = newHeight
        frame.origin.y -= delta

        // Route through `applyFrame` so the coordinator won't interpret the
        // height change as a drag and try to snap against neighbors.
        applyFrame(frame, animate: animate)
    }

    // MARK: - NSWindowDelegate

    func windowDidMove(_ notification: Notification) {
        guard !isApplyingCoordinatorFrame else { return }
        coordinator?.windowDidMove(self)
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        // Classic Winamp never lets the main or EQ window resize.
        if !kind.isHorizontallyResizable && !kind.isVerticallyResizable {
            return sender.frame.size
        }
        var size = frameSize
        if !kind.isHorizontallyResizable { size.width = sender.frame.size.width }
        if !kind.isVerticallyResizable   { size.height = sender.frame.size.height }
        return size
    }

    func windowDidResize(_ notification: Notification) {
        if !isShaded {
            lastFullHeight = window.frame.size.height
        }
        coordinator?.windowDidResize(self)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        coordinator?.windowDidBecomeKey(self)
    }

    func windowWillClose(_ notification: Notification) {
        coordinator?.windowWillClose(self)
    }
}
#endif
