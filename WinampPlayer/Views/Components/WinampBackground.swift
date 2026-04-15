import SwiftUI

/// Classic Winamp metallic/textured background
struct WinampBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.16, green: 0.16, blue: 0.18),
                    Color(red: 0.12, green: 0.12, blue: 0.14),
                    Color(red: 0.10, green: 0.10, blue: 0.12)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            // Subtle texture overlay
            Canvas { context, size in
                for y in stride(from: 0, to: size.height, by: 2) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(.black.opacity(0.05)), lineWidth: 1)
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Divider styled for Winamp
struct WinampDivider: View {
    var isHorizontal: Bool = false

    var body: some View {
        if isHorizontal {
            VStack(spacing: 0) {
                Rectangle().fill(WinampTheme.buttonShadow).frame(height: 1)
                Rectangle().fill(WinampTheme.buttonHighlight).frame(height: 1)
            }
        } else {
            HStack(spacing: 0) {
                Rectangle().fill(WinampTheme.buttonShadow).frame(width: 1)
                Rectangle().fill(WinampTheme.buttonHighlight).frame(width: 1)
            }
        }
    }
}
