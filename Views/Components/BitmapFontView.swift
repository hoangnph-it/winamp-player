import SwiftUI

/// Renders a string using the classic 5x6 Winamp bitmap font from `text.bmp`.
///
/// The classic skin's font supports ASCII letters (case-insensitive, always
/// rendered in lowercase-style glyphs), digits, a handful of punctuation and
/// a few special Latin characters. Unknown glyphs degrade gracefully to a
/// blank space so we never show broken boxes.
struct BitmapFontView: View {
    let text: String
    /// Pixel-doubling factor. 1 = native 1x (5px wide glyphs).
    var scale: CGFloat = 1
    /// Optional cap on character count — used for the main display's scrolling
    /// marquee region which shows ~31 visible glyphs at a time.
    var maxChars: Int? = nil
    /// Inter-character spacing (defaults to the authentic zero-gap pixel font).
    var tracking: CGFloat = 0

    var body: some View {
        let chars = Array(text)
        let visible: [Character] = {
            if let n = maxChars { return Array(chars.prefix(n)) }
            return chars
        }()

        HStack(spacing: tracking) {
            ForEach(visible.indices, id: \.self) { i in
                glyph(for: visible[i])
            }
        }
        .frame(height: Sprites.TEXT.charHeight * scale)
    }

    @ViewBuilder
    private func glyph(for ch: Character) -> some View {
        let (row, col) = Sprites.TEXT.lookup[ch] ?? (0, 30)
        SpriteView(
            sheet: .text,
            rect: Sprites.TEXT.rect(row: row, col: col),
            scale: scale
        )
    }
}

// MARK: - Marquee (scrolling one-line text)

/// Scrolling title text used in the main-window display. Text longer than
/// the visible width scrolls right-to-left; shorter text renders static.
///
/// Classic Winamp scrolls one pixel every ~60ms and wraps with a "  ***  "
/// separator. We approximate with a continuously-offset double-rendered line.
struct BitmapMarquee: View {
    let text: String
    /// Visible pixel width (post-scale).
    let pixelWidth: CGFloat
    var scale: CGFloat = 1
    var separator: String = "  ***  "
    /// Pixels per second of scroll speed.
    var speed: CGFloat = 30

    @State private var offset: CGFloat = 0
    @State private var timer: Timer?

    private var combined: String { text + separator }
    private var combinedPixelWidth: CGFloat {
        CGFloat(combined.count) * Sprites.TEXT.charWidth * scale
    }
    private var shouldScroll: Bool {
        CGFloat(text.count) * Sprites.TEXT.charWidth * scale > pixelWidth
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color.clear
            if shouldScroll {
                HStack(spacing: 0) {
                    BitmapFontView(text: combined, scale: scale)
                    BitmapFontView(text: combined, scale: scale)
                }
                .offset(x: -offset)
            } else {
                BitmapFontView(text: text, scale: scale)
            }
        }
        .frame(width: pixelWidth, height: Sprites.TEXT.charHeight * scale)
        .clipped()
        .onAppear { if shouldScroll { startTimer() } }
        .onDisappear { stopTimer() }
        .onChange(of: text) { _ in
            offset = 0
            stopTimer()
            if shouldScroll { startTimer() }
        }
    }

    private func startTimer() {
        stopTimer()
        let step: CGFloat = 1
        let interval = Double(step / max(1, speed))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            offset += step
            if offset >= combinedPixelWidth {
                offset = 0
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
