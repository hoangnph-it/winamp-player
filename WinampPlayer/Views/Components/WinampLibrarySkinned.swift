import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Phase-6 pixel-accurate Media Library window, wrapped in `GEN.BMP`'s
/// generic 9-slice chrome.
///
/// `GEN.BMP` is the classic Winamp skin sheet reserved for "generic" plugin
/// windows — the media browser, mini-browser, and preferences panels all
/// share this chrome. Visually it's a lighter, more muted variant of the
/// playlist's `PLEDIT.BMP` frame: same 25×20 corners + tiled middle pattern
/// on top, but with a thinner 14-px bottom strip instead of pledit's 38-px
/// bottom toolbar row (the library has its own SwiftUI toolbar inside).
///
///   ┌─[TopLeft 25×20]─[TopTile ×N]─[TopRight 25×20]─┐
///   │                                                │
///   │ [L   LibraryBrowserView (tabs / tables)    R] │
///   │ [12×29]                              [20×29]  │
///   │                                                │
///   ├─[BottomLeft 25×14]─[BottomTile×N]─[BottomRight 25×14]─┤
///
/// Resize increments follow `WinampWindowKind.library` (1 px × 1 px) so the
/// library feels like a regular document window; the 9-slice chrome tolerates
/// arbitrary widths and heights because middle tiles truncate-clip on the
/// right and bottom edges.
struct WinampLibrarySkinned: View {
    var scale: CGFloat = 1

    #if os(macOS)
    @StateObject private var focus = LibraryFocusObserver()
    #endif

    private let minWidth: CGFloat  = 300
    private let minHeight: CGFloat = 200

    var body: some View {
        GeometryReader { geo in
            let w = max(minWidth * scale, geo.size.width)
            let h = max(minHeight * scale, geo.size.height)

            ZStack(alignment: .topLeading) {
                GenChrome(
                    size: CGSize(width: w, height: h),
                    focused: currentFocus,
                    scale: scale
                )
                .allowsHitTesting(false)

                LibraryTitleBarOverlay(
                    width: w,
                    scale: scale
                )

                // Library content — lives inside the chrome's inner region
                LibraryBrowserView()
                    .frame(
                        width: max(0, w - (12 + 20) * scale),
                        height: max(0, h - (20 + 14) * scale)
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

// MARK: - 9-slice gen.bmp chrome

private struct GenChrome: View {
    let size: CGSize
    let focused: Bool
    var scale: CGFloat = 1

    var body: some View {
        let w = size.width
        let h = size.height

        let topLeft  = focused ? Sprites.GEN.topLeftFocused  : Sprites.GEN.topLeftUnfocused
        let topTile  = focused ? Sprites.GEN.topTileFocused  : Sprites.GEN.topTileUnfocused
        let topRight = focused ? Sprites.GEN.topRightFocused : Sprites.GEN.topRightUnfocused

        let topStartX: CGFloat  = 25 * scale
        let topEndX: CGFloat    = w - 25 * scale
        let topTileStep: CGFloat = max(1, topTile.width * scale)
        let topTileCount = max(0, Int(ceil(max(0, topEndX - topStartX) / topTileStep)))

        let sideStartY: CGFloat = 20 * scale
        let sideEndY: CGFloat   = h - 14 * scale
        let sideTileStep: CGFloat = max(1, Sprites.GEN.leftTile.height * scale)
        let sideTileCount = max(0, Int(ceil(max(0, sideEndY - sideStartY) / sideTileStep)))

        let botStartX: CGFloat  = 25 * scale
        let botEndX: CGFloat    = w - 25 * scale
        let botTileStep: CGFloat = max(1, Sprites.GEN.bottomTile.width * scale)
        let botTileCount = max(0, Int(ceil(max(0, botEndX - botStartX) / botTileStep)))

        ZStack(alignment: .topLeading) {
            // Top row
            SpriteView(sheet: .gen, rect: topLeft, scale: scale)

            ForEach(0..<topTileCount, id: \.self) { i in
                SpriteView(sheet: .gen, rect: topTile, scale: scale)
                    .offset(x: topStartX + CGFloat(i) * topTileStep, y: 0)
            }

            SpriteView(sheet: .gen, rect: topRight, scale: scale)
                .offset(x: w - 25 * scale, y: 0)

            // Side tiles
            ForEach(0..<sideTileCount, id: \.self) { i in
                SpriteView(sheet: .gen, rect: Sprites.GEN.leftTile, scale: scale)
                    .offset(x: 0, y: sideStartY + CGFloat(i) * sideTileStep)
            }
            ForEach(0..<sideTileCount, id: \.self) { i in
                SpriteView(sheet: .gen, rect: Sprites.GEN.rightTile, scale: scale)
                    .offset(x: w - 20 * scale, y: sideStartY + CGFloat(i) * sideTileStep)
            }

            // Bottom row
            SpriteView(sheet: .gen, rect: Sprites.GEN.bottomLeft, scale: scale)
                .offset(x: 0, y: h - 14 * scale)

            ForEach(0..<botTileCount, id: \.self) { i in
                SpriteView(sheet: .gen, rect: Sprites.GEN.bottomTile, scale: scale)
                    .offset(x: botStartX + CGFloat(i) * botTileStep, y: h - 14 * scale)
            }

            SpriteView(sheet: .gen, rect: Sprites.GEN.bottomRight, scale: scale)
                .offset(x: w - 25 * scale, y: h - 14 * scale)
        }
        .frame(width: w, height: h, alignment: .topLeading)
        .clipped()
    }
}

// MARK: - Title bar overlay

/// Top 20-px strip: drag area + centered "WINAMP LIBRARY" title + a close
/// button on the right. The generic library window doesn't support shade
/// mode (see `WinampWindowKind.library.supportsShade`) and has no expand
/// affordance, so we only render a single window-control hotspot.
private struct LibraryTitleBarOverlay: View {
    let width: CGFloat
    var scale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            #if os(macOS)
            HStack(spacing: 0) {
                Color.clear.frame(width: 25 * scale, height: 20 * scale)
                    .allowsHitTesting(false)
                WindowDragArea()
                    .frame(height: 20 * scale)
                Color.clear.frame(width: 25 * scale, height: 20 * scale)
                    .allowsHitTesting(false)
            }
            .frame(width: width, height: 20 * scale)
            #endif

            // Centered title (bitmap font)
            BitmapFontView(text: "WINAMP LIBRARY", scale: scale)
                .frame(width: width, height: 6 * scale, alignment: .center)
                .offset(y: 7 * scale)
                .allowsHitTesting(false)

            // Close button (reuse the familiar TITLEBAR.BMP close sprite)
            SpriteButton(
                sheet: .titlebar,
                normal: Sprites.TITLEBAR.close,
                pressed: Sprites.TITLEBAR.closePressed,
                scale: scale,
                action: closeAction
            )
            .offset(x: width - 11 * scale, y: 3 * scale)
        }
        .frame(width: width, height: 20 * scale, alignment: .topLeading)
    }

    private func closeAction() {
        #if os(macOS)
        if let del = NSApp.delegate as? WinampAppDelegate {
            del.coordinator.controller(for: .library)?.hide()
        } else {
            NSApp.keyWindow?.performClose(nil)
        }
        #endif
    }
}

// MARK: - Focus observer (macOS)

#if os(macOS)
/// Mirror of `WindowFocusObserver` in `WinampPlaylistSkinned.swift`, but
/// keyed off the library window's identifier so the two observers don't
/// see each other's key-window changes.
private final class LibraryFocusObserver: ObservableObject {
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
                  win.identifier?.rawValue == WinampWindowKind.library.identifier
            else { return }
            self?.isKey = true
        }
        resignedKeyObserver = nc.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let win = note.object as? NSWindow,
                  win.identifier?.rawValue == WinampWindowKind.library.identifier
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
