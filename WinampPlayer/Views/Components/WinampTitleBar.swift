import SwiftUI

/// Classic Winamp 2.x dark-blue title bar with horizontal pinstripes on both
/// sides of the centered title text (titlebar.bmp).
struct WinampTitleBar: View {
    let title: String
    var isActive: Bool = true

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: isActive
                    ? [WinampTheme.titleBarLeft, WinampTheme.titleBarRight]
                    : [WinampTheme.frameDark, WinampTheme.frameShadow],
                startPoint: .leading, endPoint: .trailing
            )

            // Pinstripes — horizontal hatching lines on both sides of title.
            // Drawn across the full width; the title text overlays the middle
            // band so the stripes only show on the sides.
            Pinstripes()
                .opacity(isActive ? 0.45 : 0.25)
                .allowsHitTesting(false)

            // Title text (covers the pinstripes in the middle)
            HStack(spacing: 0) {
                Spacer(minLength: 2)

                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(isActive ? .white : WinampTheme.btnText)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .background(
                        // Same gradient background to "mask" the pinstripes
                        // beneath the title text.
                        LinearGradient(
                            colors: isActive
                                ? [WinampTheme.titleBarLeft, WinampTheme.titleBarRight]
                                : [WinampTheme.frameDark, WinampTheme.frameShadow],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )

                Spacer(minLength: 2)
            }

            // Window buttons (minimize, shade, close) — decorative, right side
            HStack {
                Spacer()
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
