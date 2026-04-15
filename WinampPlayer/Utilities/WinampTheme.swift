import SwiftUI

/// Classic Winamp 2.x color scheme — pixel-accurate palette
struct WinampTheme {
    // MARK: - Frame / Chrome
    static let frameBg = Color(red: 0.22, green: 0.24, blue: 0.26)            // main window chrome
    static let frameHighlight = Color(red: 0.33, green: 0.36, blue: 0.38)     // top/left bevel
    static let frameShadow = Color(red: 0.10, green: 0.11, blue: 0.12)        // bottom/right bevel
    static let frameDark = Color(red: 0.14, green: 0.15, blue: 0.17)          // recessed areas

    // MARK: - Title bar (dark blue gradient)
    static let titleBarLeft = Color(red: 0.0, green: 0.0, blue: 0.45)
    static let titleBarRight = Color(red: 0.0, green: 0.0, blue: 0.22)

    // MARK: - LCD Display
    static let displayBg = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let displayBorder = Color(red: 0.10, green: 0.12, blue: 0.14)

    // Green LCD text
    static let lcdGreen = Color(red: 0.0, green: 1.0, blue: 0.0)             // #00FF00
    static let lcdGreenDim = Color(red: 0.0, green: 0.55, blue: 0.0)         // dim labels
    static let lcdGreenFaint = Color(red: 0.0, green: 0.20, blue: 0.0)       // ghost segments
    static let lcdYellow = Color(red: 0.85, green: 0.85, blue: 0.0)          // khz / kbps

    // MARK: - Visualization
    static let vizLow = Color(red: 0.13, green: 0.70, blue: 0.13)
    static let vizMid = Color(red: 0.75, green: 0.78, blue: 0.0)
    static let vizHigh = Color(red: 0.85, green: 0.18, blue: 0.10)
    static let vizPeak = Color(red: 1.0, green: 0.15, blue: 0.10)

    // MARK: - Buttons (beveled 3-D)
    static let btnFace = Color(red: 0.28, green: 0.30, blue: 0.33)
    static let btnHighlight = Color(red: 0.42, green: 0.44, blue: 0.47)
    static let btnShadow = Color(red: 0.12, green: 0.13, blue: 0.15)
    static let btnText = Color(red: 0.78, green: 0.80, blue: 0.82)
    static let btnActive = Color(red: 0.0, green: 0.85, blue: 0.0)

    // MARK: - Sliders
    static let sliderTrack = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let sliderFill = Color(red: 0.22, green: 0.50, blue: 0.22)
    static let sliderThumb = Color(red: 0.52, green: 0.54, blue: 0.56)
    static let sliderThumbHighlight = Color(red: 0.66, green: 0.68, blue: 0.70)

    // MARK: - Equalizer
    static let eqSliderBg = Color(red: 0.08, green: 0.10, blue: 0.06)
    static let eqGreen = Color(red: 0.30, green: 0.72, blue: 0.15)
    static let eqYellow = Color(red: 0.82, green: 0.82, blue: 0.0)
    static let eqRed = Color(red: 0.82, green: 0.20, blue: 0.10)

    // MARK: - Playlist
    static let plBg = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let plText = Color(red: 0.0, green: 0.85, blue: 0.0)
    static let plTextDim = Color(red: 0.0, green: 0.50, blue: 0.0)
    static let plSelected = Color(red: 0.0, green: 0.0, blue: 0.50)
    static let plNowPlaying = Color.white
    static let plHeaderBg = Color(red: 0.16, green: 0.05, blue: 0.05)

    // MARK: - Fonts
    static let timeFont = Font.system(size: 32, weight: .bold, design: .monospaced)
    static let infoFont = Font.system(size: 10, weight: .semibold, design: .monospaced)
    static let plFont = Font.system(size: 11, weight: .regular, design: .monospaced)
    static let btnFont = Font.system(size: 9, weight: .bold, design: .monospaced)
    static let titleFont = Font.system(size: 10, weight: .bold, design: .monospaced)
    static let badgeFont = Font.system(size: 8, weight: .heavy, design: .monospaced)
}

// MARK: - Classic beveled button (small)
struct WinampButtonStyle: ButtonStyle {
    var isActive = false
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(WinampTheme.btnFont)
            .foregroundColor(isActive ? WinampTheme.btnActive : WinampTheme.btnText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(pressed ? WinampTheme.btnShadow : WinampTheme.btnFace)
            .overlay(
                BevelBorder(pressed: pressed)
            )
    }
}

// MARK: - Transport button (prev / play / pause / stop / next)
struct WinampTransportStyle: ButtonStyle {
    var isActive = false
    var width: CGFloat = 24
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundColor(isActive ? WinampTheme.btnActive : WinampTheme.btnText)
            .frame(width: width, height: 18)
            .background(pressed ? WinampTheme.btnShadow : WinampTheme.btnFace)
            .overlay(BevelBorder(pressed: pressed))
    }
}

// MARK: - Bevel border helper (classic Win32 look)
struct BevelBorder: View {
    var pressed: Bool = false
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            Path { p in
                // top edge
                p.move(to: .zero)
                p.addLine(to: CGPoint(x: w, y: 0))
                // left edge
                p.move(to: .zero)
                p.addLine(to: CGPoint(x: 0, y: h))
            }
            .stroke(pressed ? WinampTheme.btnShadow : WinampTheme.btnHighlight, lineWidth: 1)

            Path { p in
                // bottom edge
                p.move(to: CGPoint(x: 0, y: h))
                p.addLine(to: CGPoint(x: w, y: h))
                // right edge
                p.move(to: CGPoint(x: w, y: 0))
                p.addLine(to: CGPoint(x: w, y: h))
            }
            .stroke(pressed ? WinampTheme.btnHighlight : WinampTheme.btnShadow, lineWidth: 1)
        }
    }
}
