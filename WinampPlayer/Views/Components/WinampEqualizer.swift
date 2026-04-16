import SwiftUI

/// Classic Winamp Equalizer panel — pixel-accurate layout matching Winamp 2.x
/// ┌───────────────────────────────────────┐
/// │ WINAMP EQUALIZER (title bar)          │
/// │ [ON][AUTO]   ─curve line─  [PRESETS]  │
/// │ +20db ┌──────────────────────────┐    │
/// │ +0db  │ PREAMP │ 60 170 … 14K 16K│   │
/// │ -20db └──────────────────────────┘    │
/// └───────────────────────────────────────┘
struct WinampEqualizer: View {
    @State private var eqEnabled = true
    @State private var autoEQ = false
    @State private var preamp: Double = 0.5
    @State private var bands: [Double] = [0.5, 0.55, 0.6, 0.65, 0.55, 0.45, 0.5, 0.4, 0.45, 0.5]

    private let bandLabels = ["60", "170", "310", "600", "1K", "3K", "6K", "12K", "14K", "16K"]

    var body: some View {
        VStack(spacing: 0) {
            // ── Title bar ──
            WinampTitleBar(title: "WINAMP EQUALIZER")

            // ── Control row: ON / AUTO / curve / PRESETS ──
            HStack(spacing: 4) {
                EQToggle(label: "ON", active: $eqEnabled)
                EQToggle(label: "AUTO", active: $autoEQ)

                Spacer()

                // EQ curve line preview
                EQCurveLine(preamp: preamp, bands: bands)
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)

                Spacer()

                Button(action: {}) {
                    Text("PRESETS")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(WinampTheme.btnText)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(WinampTheme.btnFace)
                        .overlay(BevelBorder())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)

            // ── Sliders area with dB scale on left ──
            HStack(alignment: .center, spacing: 0) {
                // dB scale labels (vertical, left side)
                VStack(spacing: 0) {
                    Text("+20db")
                        .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreenDim)
                    Spacer()
                    Text("+0db")
                        .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreenDim)
                    Spacer()
                    Text("-20db")
                        .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreenDim)
                }
                .frame(width: 26, height: 76)
                .padding(.bottom, 10) // offset for band labels at bottom

                // Slider grid area (dark navy background with gridlines)
                ZStack {
                    // Dark navy background
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.08, green: 0.08, blue: 0.16))

                    // Horizontal grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { i in
                            if i > 0 { Spacer() }
                            Rectangle()
                                .fill(Color(red: 0.18, green: 0.20, blue: 0.30).opacity(0.6))
                                .frame(height: 0.5)
                            if i < 4 { Spacer() }
                        }
                    }
                    .padding(.vertical, 4)

                    // Sliders
                    HStack(alignment: .bottom, spacing: 0) {
                        // Preamp slider
                        VStack(spacing: 1) {
                            EQSlider(value: $preamp)
                                .frame(width: 16)

                            Text("PREAMP")
                                .font(.system(size: 5, weight: .bold, design: .monospaced))
                                .foregroundColor(WinampTheme.lcdGreenDim)
                                .frame(height: 8)
                        }
                        .frame(width: 28)

                        // Thin separator
                        Rectangle()
                            .fill(Color(red: 0.18, green: 0.20, blue: 0.30))
                            .frame(width: 1)
                            .padding(.vertical, 4)

                        // 10 band sliders
                        HStack(spacing: 0) {
                            ForEach(0..<10, id: \.self) { i in
                                VStack(spacing: 1) {
                                    EQSlider(value: $bands[i])
                                        .frame(width: 16)

                                    Text(bandLabels[i])
                                        .font(.system(size: 5.5, weight: .semibold, design: .monospaced))
                                        .foregroundColor(WinampTheme.lcdGreenDim)
                                        .frame(height: 8)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.leading, 2)
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
                .padding(.trailing, 4)
            }
            .padding(.leading, 4)
            .padding(.bottom, 3)
            .frame(height: 100)
        }
        .background(WinampTheme.frameBg)
        .overlay(
            Rectangle().strokeBorder(
                LinearGradient(colors: [WinampTheme.frameHighlight, WinampTheme.frameShadow],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 1
            )
        )
    }
}

// MARK: - EQ toggle button (ON / AUTO)
private struct EQToggle: View {
    let label: String
    @Binding var active: Bool
    var body: some View {
        Button { active.toggle() } label: {
            Text(label)
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundColor(active ? WinampTheme.btnActive : WinampTheme.btnText)
                .frame(minWidth: 22, height: 12)
                .padding(.horizontal, 2)
                .background(active ? WinampTheme.frameDark : WinampTheme.btnFace)
                .overlay(BevelBorder(pressed: active))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EQ Curve Line (spline connecting band values)
private struct EQCurveLine: View {
    let preamp: Double
    let bands: [Double]

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let allValues = bands
            let count = allValues.count
            let stepX = w / CGFloat(max(1, count - 1))

            Path { path in
                for i in 0..<count {
                    let x = CGFloat(i) * stepX
                    let y = h * (1 - allValues[i]) // 1=top, 0=bottom
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        // Smooth curve using quadratic bezier
                        let prevX = CGFloat(i - 1) * stepX
                        let prevY = h * (1 - allValues[i - 1])
                        let midX = (prevX + x) / 2
                        path.addQuadCurve(
                            to: CGPoint(x: x, y: y),
                            control: CGPoint(x: midX, y: (prevY + y) / 2)
                        )
                    }
                }
            }
            .stroke(WinampTheme.lcdGreen, lineWidth: 1)

            // Small dots at each band point
            ForEach(0..<count, id: \.self) { i in
                let x = CGFloat(i) * stepX
                let y = h * (1 - allValues[i])
                Circle()
                    .fill(WinampTheme.lcdGreen)
                    .frame(width: 3, height: 3)
                    .position(x: x, y: y)
            }

            // Center reference line (0 dB)
            Path { path in
                path.move(to: CGPoint(x: 0, y: h / 2))
                path.addLine(to: CGPoint(x: w, y: h / 2))
            }
            .stroke(WinampTheme.lcdGreenDim.opacity(0.3), lineWidth: 0.5)
        }
    }
}

// MARK: - Vertical EQ slider (classic Winamp style with gradient fill)
private struct EQSlider: View {
    @Binding var value: Double   // 0 (bottom) … 1 (top)

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let thumbH: CGFloat = 8
            let thumbW: CGFloat = w
            let trackW: CGFloat = 6
            let trackH = h - thumbH

            ZStack {
                // Groove with gradient colored fill
                // The fill shows green at bottom, yellow in middle, orange/red at top
                ZStack(alignment: .bottom) {
                    // Dark background
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.10))
                        .frame(width: trackW)

                    // Gradient fill from bottom to current value
                    // Below center = green fill from bottom up to thumb
                    // Above center = colored fill
                    LinearGradient(
                        colors: [
                            WinampTheme.eqGreen,
                            WinampTheme.eqGreen,
                            WinampTheme.eqYellow,
                            Color(red: 0.90, green: 0.55, blue: 0.0),
                            WinampTheme.eqRed
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(width: trackW, height: max(0, trackH * value))
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                }
                .frame(width: trackW, height: trackH)
                .overlay(RoundedRectangle(cornerRadius: 1).stroke(Color(red: 0.15, green: 0.15, blue: 0.22), lineWidth: 0.5))

                // Centre notch (0 dB reference line)
                Rectangle()
                    .fill(WinampTheme.lcdGreenDim.opacity(0.5))
                    .frame(width: w - 2, height: 1)

                // Thumb (small square handle)
                ZStack {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(LinearGradient(
                            colors: [
                                WinampTheme.sliderThumbHighlight,
                                WinampTheme.sliderThumb,
                                Color(red: 0.36, green: 0.38, blue: 0.40)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: thumbW, height: thumbH)
                    // Notch lines on thumb
                    VStack(spacing: 1.5) {
                        Rectangle().fill(WinampTheme.frameShadow).frame(width: thumbW - 4, height: 0.5)
                        Rectangle().fill(WinampTheme.sliderThumbHighlight).frame(width: thumbW - 4, height: 0.5)
                        Rectangle().fill(WinampTheme.frameShadow).frame(width: thumbW - 4, height: 0.5)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(WinampTheme.frameShadow, lineWidth: 0.5)
                        .frame(width: thumbW, height: thumbH)
                )
                .offset(y: (0.5 - value) * trackH)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let pct = 1 - (v.location.y / h)
                        value = max(0, min(1, pct))
                    }
            )
        }
    }
}
