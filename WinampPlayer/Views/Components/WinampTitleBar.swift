import SwiftUI

/// Classic Winamp 2.x dark-blue title bar with yellow horizontal pinstripes
/// and a centered "WINAMP" title. Layout:
///
///   [•]  ========   WINAMP   ========  [_][▭][×]
///   LED  yellow    centered   yellow    window ctrls
///        pinstripes  title    pinstripes
///
/// The title is anchored to the true center of the bar via a ZStack so the
/// LED indicator on the left and the window buttons on the right can't shift
/// it off-center.
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

            // Horizontal yellow pinstripe pattern across full width
            Pinstripes(isActive: isActive)
                .opacity(isActive ? 0.9 : 0.35)
                .allowsHitTesting(false)

            // Centered title — background gradient masks the stripes under it
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(isActive ? .white : WinampTheme.btnText)
                .tracking(1) // slight letter spacing for the classic look
                .lineLimit(1)
                .padding(.horizontal, 10)
                .background(
                    LinearGradient(
                        colors: isActive
                            ? [WinampTheme.titleBarLeft, WinampTheme.titleBarRight]
                            : [WinampTheme.frameDark, WinampTheme.frameShadow],
                        startPoint: .leading, endPoint: .trailing
                    )
                )

            // Left-edge LED indicator
            HStack(spacing: 0) {
                Circle()
                    .fill(isActive
                          ? WinampTheme.lcdGreen
                          : WinampTheme.lcdGreenFaint)
                    .frame(width: 3, height: 3)
                    .shadow(color: isActive ? WinampTheme.lcdGreen.opacity(0.8) : .clear,
                            radius: 1)
                    .padding(.leading, 6)
                Spacer()
            }

            // Right-edge window control buttons
            HStack(spacing: 0) {
                Spacer()
                HStack(spacing: 1) {
                    TitleBarBtn(icon: "minus")
                    TitleBarBtn(icon: "square")
                    TitleBarBtn(icon: "xmark")
                }
                .padding(.trailing, 3)
            }

            // Drag handle (macOS only). The `WindowDragArea`'s underlying
            // `DragView` intercepts `mouseDown` to both raise the classic
            // Winamp cluster *and* call `performDrag(with:)` so the window
            // still drags. Stretching it across the entire title bar makes
            // every pixel clickable for cluster-raise. Any controls drawn
            // on top in the parent ZStack consume their clicks first.
            #if os(macOS)
            WindowDragArea()
            #endif
        }
        .frame(height: 14)
    }
}

// MARK: - Pinstripes (horizontal alternating yellow lines)
private struct Pinstripes: View {
    var isActive: Bool
    var body: some View {
        GeometryReader { g in
            let lineH: CGFloat = 1
            let gap: CGFloat = 1
            let total = lineH + gap
            let count = Int(g.size.height / total)

            VStack(spacing: gap) {
                ForEach(0..<count, id: \.self) { _ in
                    Rectangle()
                        .fill(isActive
                              ? WinampTheme.titleBarStripe
                              : Color.gray)
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
