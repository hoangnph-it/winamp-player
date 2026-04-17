import SwiftUI

/// Classic Winamp 2.x dark-blue title bar with horizontal pinstripes.
/// Layout (matching reference video):
///   [•]  ==============  WINAMP  ==============  [_][▭][×]
///   LED  pinstripes       title   pinstripes      window controls
struct WinampTitleBar: View {
    let title: String
    var isActive: Bool = true

    var body: some View {
        ZStack {
            // Background gradient (active = blue, inactive = dark gray)
            LinearGradient(
                colors: isActive
                    ? [WinampTheme.titleBarLeft, WinampTheme.titleBarRight]
                    : [WinampTheme.frameDark, WinampTheme.frameShadow],
                startPoint: .leading, endPoint: .trailing
            )

            // Horizontal pinstripe pattern across full width
            Pinstripes()
                .opacity(isActive ? 0.45 : 0.25)
                .allowsHitTesting(false)

            // Foreground row: LED — TITLE (left) — pinstripes fill — WINDOW CTRLS
            HStack(spacing: 0) {
                // Left-edge LED indicator (classic Winamp shade/mini button)
                Circle()
                    .fill(isActive
                          ? WinampTheme.lcdGreen
                          : WinampTheme.lcdGreenFaint)
                    .frame(width: 3, height: 3)
                    .padding(.leading, 6)
                    .padding(.trailing, 6)

                // Title text — LEFT-aligned. Classic Winamp places the
                // title near the left with pinstripes filling the rest.
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(isActive ? .white : WinampTheme.btnText)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .background(
                        // Mask the pinstripes beneath the title with the
                        // same gradient for readability.
                        LinearGradient(
                            colors: isActive
                                ? [WinampTheme.titleBarLeft, WinampTheme.titleBarRight]
                                : [WinampTheme.frameDark, WinampTheme.frameShadow],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )

                Spacer(minLength: 0)

                // Right-side window controls
                HStack(spacing: 1) {
                    TitleBarBtn(icon: "minus")
                    TitleBarBtn(icon: "square")
                    TitleBarBtn(icon: "xmark")
                }
                .padding(.trailing, 3)
            }
        }
        .frame(height: 14)
    }
}

// MARK: - Pinstripes (horizontal alternating lines)
private struct Pinstripes: View {
    var body: some View {
        GeometryReader { g in
            let lineH: CGFloat = 1
            let gap: CGFloat = 1
            let total = lineH + gap
            let count = Int(g.size.height / total)

            VStack(spacing: gap) {
                ForEach(0..<count, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.35))
                        .frame(height: lineH)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Small window-control button on the right (decorative)
private struct TitleBarBtn: View {
    let icon: String
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 5, weight: .bold))
            .foregroundColor(WinampTheme.btnText)
            .frame(width: 9, height: 9)
            .background(WinampTheme.btnFace)
            .overlay(BevelBorder())
    }
}
