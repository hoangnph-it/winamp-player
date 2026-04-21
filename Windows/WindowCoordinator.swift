#if os(macOS)
import AppKit
import Combine

/// Coordinates the three (or four) Winamp floating windows:
///   • edge snapping (within `WindowSnap.distance` of another window's edge)
///   • group drag  (docked children follow when their parent moves)
///   • cluster focus (clicking any one brings all to the front)
///   • layout persistence to UserDefaults across launches
///
/// All math here is expressed in AppKit's screen coordinate space
/// (origin bottom-left, y grows upward).
final class WindowCoordinator: ObservableObject {

    // MARK: - Storage

    private var controllers: [WinampWindowKind: WinampWindowController] = [:]

    /// Last-known frame for each window. Used to compute the delta on move
    /// so we can carry docked children along.
    private var lastFrames: [WinampWindowKind: NSRect] = [:]

    /// Dock graph: for each window, the set of siblings whose edges are
    /// currently touching it (within 1 pixel). A docked sibling moves
    /// along when its host moves.
    private var dockedNeighbors: [WinampWindowKind: Set<WinampWindowKind>] = [:]

    /// True while we're programmatically dragging children — suppresses
    /// re-entrant snap calculations.
    private var isGroupMoving = false

    // MARK: - Registration

    func register(_ controller: WinampWindowController) {
        controllers[controller.kind] = controller
        controller.coordinator = self
        lastFrames[controller.kind] = controller.window.frame
    }

    func controller(for kind: WinampWindowKind) -> WinampWindowController? {
        controllers[kind]
    }

    var allControllers: [WinampWindowController] {
        WinampWindowKind.allCases.compactMap { controllers[$0] }
    }

    /// Call after bulk-showing or bulk-hiding windows to rebuild the dock
    /// graph and re-sync `lastFrames`. Cheap — O(n²) over at most 4 windows.
    func refreshLayout() {
        for (kind, controller) in controllers {
            lastFrames[kind] = controller.window.frame
        }
        recomputeDocking()
    }

    // MARK: - First-launch placement

    /// Applies default positions (or restores the last-saved layout) the
    /// first time each window is shown. Also stores those frames in
    /// `lastFrames` so subsequent moves have a correct baseline.
    func placeWindows() {
        loadLayout()

        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame

        for kind in WinampWindowKind.allCases {
            guard let controller = controllers[kind] else { continue }
            let frame = controller.window.frame

            // If the window was never placed (still at 0,0), use defaults.
            if frame.origin == .zero {
                let offset = WinampWindowDefaults.topLeftOffset(for: kind)
                // Flip y: offset is measured from top of visible frame.
                let origin = NSPoint(
                    x: visible.minX + offset.x,
                    y: visible.maxY - offset.y - frame.size.height
                )
                var newFrame = frame
                newFrame.origin = origin
                controller.applyFrame(newFrame)
            }
            lastFrames[kind] = controller.window.frame
        }
        recomputeDocking()
    }

    // MARK: - NSWindowDelegate callbacks (called from controllers)

    func windowDidMove(_ controller: WinampWindowController) {
        guard !isGroupMoving else {
            lastFrames[controller.kind] = controller.window.frame
            return
        }

        let kind = controller.kind
        let oldFrame = lastFrames[kind] ?? controller.window.frame
        let currentFrame = controller.window.frame

        // Snap the moving window to neighbors first, then drag along any
        // windows that were docked to it so the cluster moves as one unit.
        let snapped = snapFrame(for: kind, to: currentFrame)
        if snapped != currentFrame {
            controller.applyFrame(snapped)
        }

        let realDx = snapped.origin.x - oldFrame.origin.x
        let realDy = snapped.origin.y - oldFrame.origin.y

        if realDx != 0 || realDy != 0 {
            carryDockedSiblings(of: kind, dx: realDx, dy: realDy)
        }

        lastFrames[kind] = controller.window.frame
        recomputeDocking()
        saveLayoutDebounced()
    }

    func windowDidResize(_ controller: WinampWindowController) {
        lastFrames[controller.kind] = controller.window.frame
        recomputeDocking()
        saveLayoutDebounced()
    }

    func windowDidBecomeKey(_ controller: WinampWindowController) {
        // Classic Winamp cluster-raise: clicking any window brings all
        // currently-visible cluster windows to the front in their natural
        // stacking order (main on top).
        //
        // IMPORTANT: This runs on the next run-loop tick, NOT inline. Doing
        // the ordering inline (during AppKit's own becomeKey processing)
        // has been observed to leave the main window in a state where the
        // very first click after launch works, but every subsequent click
        // on the same window gets silently swallowed — AppKit's mouse-
        // event routing and key-window bookkeeping both race with our
        // `orderFront` / `orderFrontRegardless` calls. Deferring by one
        // tick lets AppKit finish flipping key status first, then we
        // adjust z-order; the user never sees the transient ordering.
        let keyedKind = controller.kind
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let keyed = self.controllers[keyedKind],
                  keyed.window.isKeyWindow else { return }
            self.raiseCluster(focus: keyedKind)
        }
    }

    /// Brings every currently-visible cluster window (main + EQ + playlist)
    /// to the front, with `focus` rendered topmost. Public so dead-region
    /// click handlers inside the SwiftUI content can trigger the classic
    /// Winamp "click anywhere on any window → raise all three" behavior
    /// even when the target window is already key (in which case the
    /// `windowDidBecomeKey` path does not fire).
    func raiseCluster(focus: WinampWindowKind = .main) {
        let clusterKinds: [WinampWindowKind] = [.playlist, .equalizer, .main]
        for k in clusterKinds {
            if let c = controllers[k], c.window.isVisible, k != focus {
                c.window.orderFront(nil)
            }
        }
        if let focused = controllers[focus], focused.window.isVisible {
            focused.window.orderFrontRegardless()
        }
    }

    func windowWillClose(_ controller: WinampWindowController) {
        // Main window close = quit (classic behavior). EQ/playlist/library
        // close just hides them; they're reopened from the main window's
        // clutterbar in phase 3.
        if controller.kind == .main {
            NSApp.terminate(nil)
        }
    }

    // MARK: - Snap

    /// Returns a frame snapped to the nearest neighbor edge (within
    /// `WindowSnap.distance`) on each axis independently.
    private func snapFrame(for kind: WinampWindowKind,
                           to frame: NSRect) -> NSRect {
        var result = frame
        let others = otherVisibleFrames(excluding: kind)
        if others.isEmpty { return result }

        // X-axis snap: left-to-left, left-to-right, right-to-left, right-to-right.
        var bestDX: CGFloat = .greatestFiniteMagnitude
        for other in others {
            for candidate in [
                other.minX - result.width,  // our right aligns with their left
                other.maxX,                 // our left aligns with their right
                other.minX,                 // left edges flush
                other.maxX - result.width,  // right edges flush
            ] {
                let d = abs(candidate - result.minX)
                if d < WindowSnap.distance && d < abs(bestDX) {
                    bestDX = candidate - result.minX
                }
            }
        }
        if bestDX != .greatestFiniteMagnitude {
            result.origin.x += bestDX
        }

        // Y-axis snap.
        var bestDY: CGFloat = .greatestFiniteMagnitude
        for other in others {
            for candidate in [
                other.minY - result.height, // our top aligns with their bottom
                other.maxY,                 // our bottom aligns with their top
                other.minY,                 // bottom edges flush
                other.maxY - result.height, // top edges flush
            ] {
                let d = abs(candidate - result.minY)
                if d < WindowSnap.distance && d < abs(bestDY) {
                    bestDY = candidate - result.minY
                }
            }
        }
        if bestDY != .greatestFiniteMagnitude {
            result.origin.y += bestDY
        }
        return result
    }

    private func otherVisibleFrames(excluding kind: WinampWindowKind) -> [NSRect] {
        controllers
            .filter { $0.key != kind && $0.value.window.isVisible }
            .map { $0.value.window.frame }
    }

    // MARK: - Group drag (carry docked siblings)

    /// Any sibling that shares a flush edge with `kind` gets translated by
    /// `(dx, dy)` — the classic Winamp "stuck windows move together" rule.
    private func carryDockedSiblings(of kind: WinampWindowKind,
                                     dx: CGFloat, dy: CGFloat) {
        guard dx != 0 || dy != 0 else { return }
        let siblings = dockedNeighbors[kind] ?? []
        guard !siblings.isEmpty else { return }

        isGroupMoving = true
        defer { isGroupMoving = false }

        var moved: Set<WinampWindowKind> = [kind]
        var queue: [WinampWindowKind] = Array(siblings)

        while let next = queue.first {
            queue.removeFirst()
            if moved.contains(next) { continue }
            guard let controller = controllers[next] else { continue }

            var frame = controller.window.frame
            frame.origin.x += dx
            frame.origin.y += dy
            controller.applyFrame(frame)
            lastFrames[next] = frame
            moved.insert(next)

            // Continue walking the dock graph so chained docks follow, too.
            if let neighbors = dockedNeighbors[next] {
                for n in neighbors where !moved.contains(n) {
                    queue.append(n)
                }
            }
        }
    }

    // MARK: - Dock graph

    /// Rebuilds `dockedNeighbors` by checking which visible windows share a
    /// flush edge (within 1 pixel) and also overlap along the perpendicular
    /// axis (otherwise "touching corners" would dock).
    private func recomputeDocking() {
        var graph: [WinampWindowKind: Set<WinampWindowKind>] = [:]
        let visible = controllers.filter { $0.value.window.isVisible }
        let kinds = visible.keys.map { $0 }

        for a in kinds {
            guard let af = visible[a]?.window.frame else { continue }
            var set: Set<WinampWindowKind> = []
            for b in kinds where b != a {
                guard let bf = visible[b]?.window.frame else { continue }
                if areDocked(af, bf) { set.insert(b) }
            }
            graph[a] = set
        }
        dockedNeighbors = graph
    }

    private func areDocked(_ a: NSRect, _ b: NSRect) -> Bool {
        let eps: CGFloat = 1
        // Horizontal touch: right-of-a ≈ left-of-b (or vice versa) AND
        // vertical ranges overlap.
        let horizontalTouch =
            (abs(a.maxX - b.minX) <= eps || abs(b.maxX - a.minX) <= eps) &&
            (a.minY < b.maxY && b.minY < a.maxY)

        // Vertical touch: top-of-a ≈ bottom-of-b (or vice versa) AND
        // horizontal ranges overlap.
        let verticalTouch =
            (abs(a.maxY - b.minY) <= eps || abs(b.maxY - a.minY) <= eps) &&
            (a.minX < b.maxX && b.minX < a.maxX)

        return horizontalTouch || verticalTouch
    }

    // MARK: - Layout persistence

    private let defaultsKey = "winamp.windowLayout.v1"

    private struct SavedFrame: Codable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        let shaded: Bool
    }

    private var saveWorkItem: DispatchWorkItem?

    private func saveLayoutDebounced() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveLayout() }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.4,
            execute: work
        )
    }

    func saveLayout() {
        var out: [String: SavedFrame] = [:]
        for (kind, controller) in controllers {
            let f = controller.window.frame
            out[kind.rawValue] = SavedFrame(
                x: Double(f.origin.x),
                y: Double(f.origin.y),
                width: Double(f.size.width),
                height: Double(f.size.height),
                shaded: controller.isShaded
            )
        }
        if let data = try? JSONEncoder().encode(out) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func loadLayout() {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let saved = try? JSONDecoder().decode([String: SavedFrame].self, from: data)
        else { return }

        for (key, saved) in saved {
            guard
                let kind = WinampWindowKind(rawValue: key),
                let controller = controllers[kind]
            else { continue }

            let frame = NSRect(
                x: CGFloat(saved.x),
                y: CGFloat(saved.y),
                width: CGFloat(saved.width),
                height: CGFloat(saved.height)
            )

            // Bail if the saved frame lands off every screen — use default.
            if NSScreen.screens.contains(where: { $0.visibleFrame.intersects(frame) }) {
                controller.applyFrame(frame)
                if saved.shaded { controller.setShaded(true, animate: false) }
            }
        }
    }
}
#endif
