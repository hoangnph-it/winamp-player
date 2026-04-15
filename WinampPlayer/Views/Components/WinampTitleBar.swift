import SwiftUI

/// Classic Winamp title bar with scrolling text
struct WinampTitleBar: View {
    let title: String
    @State private var scrollOffset: CGFloat = 0
    @State private var textWidth: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            // Winamp "logo" area
            HStack(spacing: 4) {
                // Classic Winamp bolt icon (simplified)
                ZStack {
                    Circle()
                        .fill(WinampTheme.lcdGreenDim)
                        .frame(width: 14, height: 14)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.black)
                }

                Text("WINAMP")
                    .font(WinampTheme.titleFont)
                    .foregroundColor(WinampTheme.lcdGreen)
            }
            .padding(.leading, 8)

            Spacer()

            // Scrolling title
            GeometryReader { geo in
                let displayText = "  ***  \(title.uppercased())  ***  \(title.uppercased())  ***  "

                Text(displayText)
                    .font(WinampTheme.titleFont)
                    .foregroundColor(WinampTheme.lcdGreen)
                    .fixedSize()
                    .offset(x: -scrollOffset)
                    .onAppear {
                        startScrolling(width: geo.size.width)
                    }
                    .onChange(of: title) { _ in
                        scrollOffset = 0
                        startScrolling(width: geo.size.width)
                    }
            }
            .frame(height: 16)
            .clipped()
            .padding(.horizontal, 8)

            Spacer()

            // Window controls placeholder
            HStack(spacing: 4) {
                WinampMiniButton(symbol: "minus")
                WinampMiniButton(symbol: "square")
                WinampMiniButton(symbol: "xmark")
            }
            .padding(.trailing, 8)
        }
        .frame(height: 28)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.0, green: 0.0, blue: 0.35),
                    Color(red: 0.0, green: 0.0, blue: 0.20)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private func startScrolling(width: CGFloat) {
        withAnimation(
            .linear(duration: 12)
            .repeatForever(autoreverses: false)
        ) {
            scrollOffset = width + 200
        }
    }
}

struct WinampMiniButton: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 7, weight: .bold))
            .foregroundColor(WinampTheme.buttonText)
            .frame(width: 16, height: 14)
            .background(WinampTheme.buttonFace)
            .cornerRadius(2)
    }
}
