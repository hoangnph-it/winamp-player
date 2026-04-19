import SwiftUI

/// Renders digits (0-9) and basic time punctuation using `numbers.bmp`
/// — the large 9x13 green LCD numerals shown in the main-window display.
///
/// Colons and spaces are rendered as blank gaps (no sprite) so the time
/// display lines up like "05:23" with a visible gap between mm and ss.
struct NumberDisplayView: View {
    /// Text to render — typically something like "  5:23" or "-0:42".
    let text: String
    /// Pixel-doubling factor (1x = 9px digit width).
    var scale: CGFloat = 1
    /// Inter-digit spacing (defaults to the skin's authentic 0-pixel gap).
    var spacing: CGFloat = 0

    var body: some View {
        let chars = Array(text)
        HStack(spacing: spacing) {
            ForEach(chars.indices, id: \.self) { i in
                glyph(for: chars[i])
            }
        }
        .frame(height: Sprites.NUMBERS.digitHeight * scale)
    }

    @ViewBuilder
    private func glyph(for ch: Character) -> some View {
        if let d = ch.wholeNumberValue, d >= 0, d <= 9 {
            SpriteView(sheet: .numbers, rect: Sprites.NUMBERS.digit(d), scale: scale)
        } else if ch == "-" {
            // Minus sprite is a single horizontal line — centre it vertically
            // within a digit-sized cell so layout stays aligned.
            ZStack {
                Color.clear
                SpriteView(sheet: .numbers, rect: Sprites.NUMBERS.minus, scale: scale)
            }
            .frame(
                width: Sprites.NUMBERS.digitWidth * scale,
                height: Sprites.NUMBERS.digitHeight * scale
            )
        } else {
            // Colon, space, anything else → fixed-width blank
            Color.clear
                .frame(
                    width: Sprites.NUMBERS.digitWidth * scale,
                    height: Sprites.NUMBERS.digitHeight * scale
                )
        }
    }
}

// MARK: - Time formatting helpers

extension NumberDisplayView {
    /// Formats an elapsed / remaining time into the classic " M:SS" layout
    /// used by the main window's digital readout.
    ///
    /// - remaining: prepend "-" (renders via `Sprites.NUMBERS.minus`).
    /// - totalSeconds: clamped to non-negative before formatting.
    static func timeString(totalSeconds: TimeInterval, remaining: Bool = false) -> String {
        let secs = Int(max(0, totalSeconds))
        let m = secs / 60
        let s = secs % 60
        let minStr = String(format: "%2d", m)    // right-aligned with a leading space
        let secStr = String(format: "%02d", s)
        let body = "\(minStr):\(secStr)"
        return remaining ? "-\(body)" : body
    }
}
