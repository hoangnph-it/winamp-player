#if os(macOS)
import SwiftUI
import AppKit

/// A zero-cost SwiftUI layer that marks its region as a click-and-drag
/// handle for the surrounding `NSWindow`.
///
/// It's backed by an empty `NSView` whose `mouseDownCanMoveWindow` returns
/// `true`. AppKit's built-in `isMovableByWindowBackground` logic then
/// treats a click in this area exactly like a click on a system title
/// bar — the window begins a drag automatically, with correct snapping
/// and modifier-key behavior, without us having to handle `mouseDown` or
/// manage drag state by hand.
///
/// Place one over any SwiftUI region you want to be draggable (e.g. the
/// Winamp title bar). It's transparent — the views *below* still render
/// normally. The only thing it changes is mouse event semantics.
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DragView()
    }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }
}
#endif
