import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Phase-5 pixel-accurate rebuild of the Winamp 2.x playlist window, using
/// real `PLEDIT.BMP` skin sprites as a 9-slice frame.
///
/// Classic pledit chrome slices:
///
///   ┌─[TopLeft 25×20]─[TopTile ×N (25×20)]─[TopRight 25×20]─┐
///   │                                                        │
///   │ [L                                                   R]│
///   │ [t   track list (existing `PlaylistView`)            t]│
///   │ [12×29]                                       [20×29] │
///   │                                                        │
///   ├─[BottomLeft 125×38]─[BottomTile ×N (25×38)]─[BottomRight 150×38]─┤
///
/// The window is resizable in 25-px horizontal × 29-px vertical increments
/// (enforced by `WinampWindowKind.resizeIncrement`) so every tile seam lands
/// on an exact pixel boundary.
///
/// Inside the frame we embed the existing `PlaylistView` (track list +
/// status bar). The opaque SwiftUI status bar at the bottom of
/// `PlaylistView` covers the underlying `bottomLeft / bottomTile /
/// bottomRight` chrome — this is an intentional trade-off: the SwiftUI
/// toolbar (ADD/REM/SEL/MISC, mini transport, LIST OPTS) provides richer
/// functionality than the tiny baked-in pledit buttons would, while the
/// top bar, side tiles, and title overlay still give the authentic look.
struct WinampPlaylistSkinned: View {
    /// Pixel-doubling factor. 1 = authentic 1x.
    var scale: CGFloat = 1

    /// Whether this window currently has focus — used to pick focused vs.
    /// unfocused title-bar sprites. The macOS path updates this from
    /// `NSWindow` key-window notifications; everywhere else it's just `true`.
    #if os(macOS)
    @StateObject private var focus = WindowFocusObserver()
    #endif

    /// Minimum content size the skinned layout needs to render usefully.
    private let minWidth: CGFloat = 275
    private let minHeight: CGFloat = 116

    var body: some View {
        GeometryReader { geo in
            let w = max(minWidth * scale, geo.size.width)
            let h = max(minHeight * scale, geo.size.height)

            ZStack(alignment: .topLeading) {
                // ── 9-slice chrome (drawn edge-to-edge) ──
                PlaylistChrome(
                    size: CGSize(width: w, height: h),
                    focused: currentFocus,
                    scale: scale
                )
                .allowsHitTesting(false)

                // ── Title bar overlay (drag area + buttons + title text) ──
                PlaylistTitleBarOverlay(
                    width: w,
                    scale: scale
                )

                // ── Playlist content: list + SwiftUI status bar ──
                PlaylistView()
                    .frame(
                        width: max(0, w - (12 + 20) * scale),
                        height: max(0, h - 20 * scale)
                    )
                    .offset(x: 12 * scale, y: 20 * scale)
            }
            .frame(width: w, height: h, alignment: .topLeading)
            .background(WinampTheme.frameBg)
        }
        .frame(
            minWidth: minWidth * scale,
            minHeight: minHeight * scale
        )
    }

    private var currentFocus: Bool {
        #if os(macOS)
        return focus.isKey
        #else
        return true
        #endif
    }
}

// MARK: - 9-slice pledit chrome

/// Tiles the PLEDIT.BMP sprites edge-to-edge to fill the given size.
///
/// Height layout:
///   • 0..20  → top row (3 sprites, center tiled)
///   • 20..H-38 → side rows (leftTile on x=0..12, rightTile on x=W-20..W),
///                vertically tiled in 29-px steps
///   • H-38..H → bottom row (3 sprites, center tiled)
///
/// `SpriteView` reuses the same underlying `CGImage` for every call so the
/// per-tile cost is basically a SwiftUI `.offset` + `.clipped()`.
private struct PlaylistChrome: View {
    let size: CGSize
    let focused: Bool
    var scale: CGFloat = 1

    var body: some View {
        let w = size.width
        let h = size.height

        // Resolve focused vs. unfocused sprite variants once per render.
        let topLeft  = focused ? Sprites.PLEDIT.topLeftFocused  : Sprites.PLEDIT.topLeftUnfocused
        let topTile  = focused ? Sprites.PLEDIT.topTileFocused  : Sprites.PLEDIT.topTileUnfocused
        let topRight = focused ? Sprites.PLEDIT.topRightFocused : Sprites.PLEDIT.topRightUnfocused

        // Pre-compute tile counts so we can emit the whole chrome as a
        // single flat ZStack of absolutely-positioned SpriteViews.
        let topStartX: CGFloat  = 25 * scale
        let topEndX: CGFloat    = w - 25 * scale
        let topTileStep: CGFloat = max(1, topTile.width * scale)
        let topTileCount = max(0, Int(ceil(max(0, topEndX - topStartX) / topTileStep)))

        let sideStartY: CGFloat = 20 * scale
        let sideEndY: CGFloat   = h - 38 * scale
        let sideTileStep: CGFloat = max(1, Sprites.PLEDIT.leftTile.height * scale)
        let sideTileCount = max(0, Int(ceil(max(0, sideEndY - sideStartY) / sideTileStep)))

        let botStartX: CGFloat  = 125 * scale
        let botEndX: CGFloat    = w - 150 * scale
        let botTileStep: CGFloat = max(1, Sprites.PLEDIT.bottomTile.width * scale)
        let botTileCount = max(0, Int(ceil(max(0, botEndX - botStartX) / botTileStep)))

        ZStack(alignment: .topLeading) {
            // ── Top row ──
            SpriteView(sheet: .pledit, rect: topLeft, scale: scale)

            ForEach(0..<topTileCount, id: \.self) { i in
                SpriteView(sheet: .pledit, rect: topTile, scale: scale)
                    .offset(x: topStartX + CGFloat(i) * topTileStep, y: 0)
            }

            SpriteView(sheet: .pledit, rect: topRight, scale: scale)
                .offset(x: w - 25 * scale, y: 0)

            // ── Side tiles (repeat every 29 px from y=20 to y=H-38) ──
            ForEach(0..<sideTileCount, id: \.self) { i in
                SpriteView(sheet: .pledit, rect: Sprites.PLEDIT.leftTile, scale: scale)
                    .offset(x: 0, y: sideStartY + CGFloat(i) * sideTileStep)
            }
            ForEach(0..<sideTileCount, id: \.self) { i in
                SpriteView(sheet: .pledit, rect: Sprites.PLEDIT.rightTile, scale: scale)
                    .offset(x: w - 20 * scale, y: sideStartY + CGFloat(i) * sideTileStep)
            }

            // ── Bottom row ──
            SpriteView(sheet: .pledit, rect: Sprites.PLEDIT.bottomLeft, scale: scale)
                .offset(x: 0, y: h - 38 * scale)

            ForEach(0..<botTileCount, id: \.self) { i in
                SpriteView(sheet: .pledit, rect: Sprites.PLEDIT.bottomTile, scale: scale)
                    .offset(x: botStartX + CGFloat(i) * botTileStep, y: h - 38 * scale)
            }

            SpriteView(sheet: .pledit, rect: Sprites.PLEDIT.bottomRight, scale: scale)
                .offset(x: w - 150 * scale, y: h - 38 * scale)
        }
        .frame(width: w, height: h, alignment: .topLeading)
        .clipped()
    }
}

// MARK: - Title bar overlay

/// Transparent overlay sitting on top of the pledit top-chrome row. Hosts
/// the window-drag area, the centered "WINAMP PLAYLIST" title, and the
/// three standard window-control buttons (close, shade, expand).
///
/// The chrome sprites already ship with the title text baked in for the
/// 275-px default width; we overlay a `BitmapFontView` on top so that as
/// the window grows the title stays centered — it lands on the tiled
/// region of the top row, which is a flat blue-gradient pattern.
private struct PlaylistTitleBarOverlay: View {
    let width: CGFloat
    var scale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            #if os(macOS)
            // Full-width drag handle so every pixel of the title bar
            // triggers cluster-raise on click (see `WindowDragArea`). The
            // window-control buttons on the right are drawn later in the
            // ZStack, so their clicks are consumed before reaching this
            // drag layer.
            WindowDragArea()
                .frame(width: width, height: 20 * scale)
            #endif

            // Centered title text (raw bitmap font). Drawn at y=4 so it
            // sits on the brighter middle pixel row of the title gradient.
            let title = "WINAMP PLAYLIST"
            BitmapFontView(text: title, scale: scale)
                .frame(width: width, height: 6 * scale, alignment: .center)
                .offset(y: 7 * scale)
                .allowsHitTesting(false)

            // ── Right-edge window-control buttons ──
            // x-offsets mirror the pattern the main window uses: the three
            // buttons sit in the rightmost 40 px of the top row.
            SpriteButton(
                sheet: .pledit,
                normal: Sprites.PLEDIT.expandBtn,
                pressed: Sprites.PLEDIT.expandBtn,
                scale: scale,
                action: expandAction
            )
            .offset(x: width - 31 * scale, y: 3 * scale)

            SpriteButton(
                sheet: .pledit,
                normal: Sprites.PLEDIT.shadeBtn,
                pressed: Sprites.PLEDIT.shadeBtn,
                scale: scale,
                action: shadeAction
            )
            .offset(x: width - 21 * scale, y: 3 * scale)

            SpriteButton(
                sheet: .pledit,
                normal: Sprites.PLEDIT.closeBtn,
                pressed: Sprites.PLEDIT.closeBtn,
                scale: scale,
                action: closeAction
            )
            .offset(x: width - 11 * scale, y: 3 * scale)
        }
        .frame(width: width, height: 20 * scale, alignment: .topLeading)
    }

    // MARK: - Button actions

    private func expandAction() {
        // No direct equivalent in our rebuild — classic Winamp uses this
        // button to toggle the "info scroll" popup. For now, route it to
        // the macOS window's zoom (maximize) action.
        #if os(macOS)
        NSApp.keyWindow?.zoom(nil)
        #endif
    }

    private func shadeAction() {
        #if os(macOS)
        if let del = NSApp.delegate as? WinampAppDelegate {
            del.coordinator.controller(for: .playlist)?.toggleShade()
        }
        #endif
    }

    private func closeAction() {
        #if os(macOS)
        if let del = NSApp.delegate as? WinampAppDelegate {
            del.coordinator.controller(for: .playlist)?.hide()
        } else {
            NSApp.keyWindow?.performClose(nil)
        }
        #endif
    }
}

// MARK: - Focus observer (macOS)

#if os(macOS)
/// Tracks whether the hosting `NSWindow` is currently the key window so the
/// chrome can flip between focused / unfocused sprite sets. Keyed off the
/// nearest `NSWindow` at render time — the observer rebinds automatically
/// if the view moves to a different window.
private final class WindowFocusObserver: ObservableObject {
    @Published var isKey: Bool = true

    private var becameKeyObserver: NSObjectProtocol?
    private var resignedKeyObserver: NSObjectProtocol?

    init() {
        let nc = NotificationCenter.default
        becameKeyObserver = nc.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let win = note.object as? NSWindow,
                  win.identifier?.rawValue == WinampWindowKind.playlist.identifier
            else { return }
            self?.isKey = true
        }
        resignedKeyObserver = nc.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let win = note.object as? NSWindow,
                  win.identifier?.rawValue == WinampWindowKind.playlist.identifier
            else { return }
            self?.isKey = false
        }
    }

    deinit {
        if let o = becameKeyObserver  { NotificationCenter.default.removeObserver(o) }
        if let o = resignedKeyObserver { NotificationCenter.default.removeObserver(o) }
    }
}
#endif
