import SwiftUI

/// Classic Winamp 2.x dark-blue gradient title bar (titlebar.bmp)
/// Left: Winamp logo area / text, Right: minimize | shade | close buttons
struct WinampTitleBar: View {
    let title: String
    var isActive: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            // Classic "grip" marks (left edge)
            HStack(spacing: 1) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .fill(WinampTheme.lcdGreenDim.opacity(0.5))
                        .frame(width: 1, height: 8)
                }
            }
            .padding(.leading, 4)

            // Title text
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(isActive ? .white : WinampTheme.btnText)
                .lineLimit(1)
                .padding(.leading, 4)

            Spacer(minLength: 4)

            // Window buttons (minimize, shade, close) — decorative
            HStack(spacing: 1) {
                TitleBarBtn(icon: "minus")
                TitleBarBtn(icon: "square")
                TitleBarBtn(icon: "xmark")
            }
            .padding(.trailing, 3)
        }
        .frame(height: 16)
        .background(
            LinearGradient(
                colors: isActive
                    ? [WinampTheme.titleBarLeft, WinampTheme.titleBarRight]
                    : [WinampTheme.frameDark, WinampTheme.frameShadow],
                startPoint: .leading, endPoint: .trailing
            )
        )
    }
}

private struct TitleBarBtn: View {
    let icon: String
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 5, weight: .bold))
            .foregroundColor(WinampTheme.btnText)
            .frame(width: 10, height: 10)
            .background(WinampTheme.btnFace)
            .overlay(BevelBorder())
    }
}
