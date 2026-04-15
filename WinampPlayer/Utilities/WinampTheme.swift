import SwiftUI

/// Classic Winamp color scheme and styling
struct WinampTheme {
    // MARK: - Colors (Classic Winamp palette)
    static let background = Color(red: 0.14, green: 0.14, blue: 0.16)         // #232428 dark base
    static let panelBackground = Color(red: 0.10, green: 0.10, blue: 0.12)    // #1A1A1E darker panel
    static let displayBackground = Color(red: 0.0, green: 0.0, blue: 0.0)     // #000000 display
    static let displayBorder = Color(red: 0.22, green: 0.22, blue: 0.25)      // #383840

    // Green LCD text (classic Winamp)
    static let lcdGreen = Color(red: 0.0, green: 1.0, blue: 0.0)             // #00FF00
    static let lcdGreenDim = Color(red: 0.0, green: 0.5, blue: 0.0)          // #008000
    static let lcdGreenFaint = Color(red: 0.0, green: 0.25, blue: 0.0)       // #004000

    // Accent colors
    static let accentBlue = Color(red: 0.3, green: 0.5, blue: 0.9)           // #4D80E6
    static let accentOrange = Color(red: 0.9, green: 0.6, blue: 0.2)         // #E69933
    static let accentRed = Color(red: 0.9, green: 0.2, blue: 0.2)            // #E63333

    // Visualization bar colors (gradient from green to yellow to red)
    static let vizLow = Color(red: 0.0, green: 0.8, blue: 0.0)
    static let vizMid = Color(red: 0.8, green: 0.8, blue: 0.0)
    static let vizHigh = Color(red: 0.9, green: 0.2, blue: 0.1)

    // Button colors
    static let buttonFace = Color(red: 0.25, green: 0.25, blue: 0.28)
    static let buttonHighlight = Color(red: 0.35, green: 0.35, blue: 0.38)
    static let buttonShadow = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let buttonText = Color(red: 0.75, green: 0.75, blue: 0.78)

    // Playlist colors
    static let playlistSelected = Color(red: 0.0, green: 0.0, blue: 0.5)
    static let playlistText = Color(red: 0.0, green: 0.85, blue: 0.0)
    static let playlistTextDim = Color(red: 0.0, green: 0.55, blue: 0.0)
    static let playlistNowPlaying = Color(red: 1.0, green: 1.0, blue: 1.0)

    // Scrollbar
    static let scrollbarTrack = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let scrollbarThumb = Color(red: 0.3, green: 0.3, blue: 0.33)

    // MARK: - Fonts
    static let displayFont = Font.system(size: 28, weight: .bold, design: .monospaced)
    static let infoFont = Font.system(size: 11, weight: .medium, design: .monospaced)
    static let playlistFont = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let buttonFont = Font.system(size: 10, weight: .bold, design: .monospaced)
    static let titleFont = Font.system(size: 11, weight: .bold, design: .monospaced)

    // MARK: - Dimensions
    static let cornerRadius: CGFloat = 2
    static let buttonCornerRadius: CGFloat = 3
    static let panelPadding: CGFloat = 4
    static let borderWidth: CGFloat = 1
}

// MARK: - Winamp Button Style
struct WinampButtonStyle: ButtonStyle {
    var isActive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WinampTheme.buttonFont)
            .foregroundColor(isActive ? WinampTheme.lcdGreen : WinampTheme.buttonText)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: WinampTheme.buttonCornerRadius)
                    .fill(configuration.isPressed ? WinampTheme.buttonShadow : WinampTheme.buttonFace)
            )
            .overlay(
                RoundedRectangle(cornerRadius: WinampTheme.buttonCornerRadius)
                    .stroke(
                        configuration.isPressed ? WinampTheme.buttonShadow : WinampTheme.buttonHighlight,
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Winamp Transport Button Style (larger, for play/pause/stop)
struct WinampTransportButtonStyle: ButtonStyle {
    var isActive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isActive ? WinampTheme.lcdGreen : WinampTheme.buttonText)
            .frame(width: 36, height: 28)
            .background(
                RoundedRectangle(cornerRadius: WinampTheme.buttonCornerRadius)
                    .fill(configuration.isPressed ? WinampTheme.buttonShadow : WinampTheme.buttonFace)
            )
            .overlay(
                RoundedRectangle(cornerRadius: WinampTheme.buttonCornerRadius)
                    .stroke(
                        isActive ? WinampTheme.lcdGreenDim : WinampTheme.buttonHighlight,
                        lineWidth: 1
                    )
            )
    }
}
