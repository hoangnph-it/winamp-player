import SwiftUI

/// The outer frame chrome (classic Winamp texture)
struct WinampBackground: View {
    var body: some View {
        WinampTheme.frameBg.ignoresSafeArea()
    }
}

/// Horizontal ridge separator (between sections)
struct WinampRidge: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(WinampTheme.frameShadow).frame(height: 1)
            Rectangle().fill(WinampTheme.frameHighlight).frame(height: 1)
        }
    }
}

/// Section frame with beveled inset border
struct WinampSectionFrame<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .background(WinampTheme.frameBg)
            .overlay(
                Rectangle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [WinampTheme.frameHighlight, WinampTheme.frameShadow],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}
