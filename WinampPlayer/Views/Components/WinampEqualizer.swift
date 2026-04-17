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
    @State private var bands: [Double] = Array(repeating: 0.5, count: 10)
    @State private var presetName: String = "Flat"

    // Band labels matching the reference video
    private let bandLabels = ["70", "180", "320", "600", "1K", "3K", "6K", "12K", "14K", "16K"]

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

                PresetsMenu(applyPreset: applyPreset)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)

            // ── Sliders area with dB scale on left ──
            HStack(alignment: .center, spacing: 0) {
                // dB scale labels (vertical, left side)
                VStack(spacing: 0) {
                    Text("+12db")
                        .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreenDim)
                    Spacer()
                    Text("0db")
                        .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreenDim)
                    Spacer()
                    Text("-12db")
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

    // MARK: - Preset handling
    private func applyPreset(_ preset: EQPresets.Preset) {
        presetName = preset.name
        // Animate the slider transition
        withAnimation(.easeInOut(duration: 0.15)) {
            preamp = preset.preamp
            bands = preset.bands
        }
    }
}

// MARK: - PRESETS button with dropdown (cross-platform)
private struct PresetsMenu: View {
    let applyPreset: (EQPresets.Preset) -> Void

    var body: some View {
        Menu {
            ForEach(EQPresets.all, id: \.name) { preset in
                Button(preset.name) { applyPreset(preset) }
            }
        } label: {
            Text("PRESETS")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(WinampTheme.btnText)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(WinampTheme.btnFace)
                .overlay(BevelBorder())
        }
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

// MARK: - Classic Winamp EQ presets
/// The preset values are normalized 0…1 (0.5 = 0 dB center, 1.0 = +20 dB, 0.0 = -20 dB).
/// These match the original Winamp 2.x default presets.
enum EQPresets {
    struct Preset {
        let name: String
        let preamp: Double
        let bands: [Double]   // 10 values — 70 Hz → 16 kHz
    }

    static let all: [Preset] = [
        Preset(name: "Flat",
               preamp: 0.50,
               bands: [0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50]),
        Preset(name: "Rock",
               preamp: 0.55,
               bands: [0.72, 0.65, 0.58, 0.45, 0.40, 0.48, 0.62, 0.70, 0.72, 0.70]),
        Preset(name: "Pop",
               preamp: 0.52,
               bands: [0.42, 0.50, 0.60, 0.68, 0.70, 0.62, 0.50, 0.42, 0.40, 0.40]),
        Preset(name: "Classical",
               preamp: 0.50,
               bands: [0.55, 0.55, 0.52, 0.50, 0.50, 0.50, 0.42, 0.42, 0.42, 0.40]),
        Preset(name: "Jazz",
               preamp: 0.52,
               bands: [0.58, 0.55, 0.52, 0.55, 0.48, 0.48, 0.50, 0.52, 0.58, 0.60]),
        Preset(name: "Dance",
               preamp: 0.55,
               bands: [0.75, 0.68, 0.58, 0.50, 0.48, 0.40, 0.40, 0.55, 0.65, 0.70]),
        Preset(name: "Techno",
               preamp: 0.55,
               bands: [0.70, 0.65, 0.52, 0.42, 0.45, 0.55, 0.68, 0.72, 0.70, 0.68]),
        Preset(name: "Full Bass",
               preamp: 0.55,
               bands: [0.78, 0.75, 0.70, 0.60, 0.50, 0.40, 0.35, 0.32, 0.30, 0.30]),
        Preset(name: "Full Treble",
               preamp: 0.52,
               bands: [0.30, 0.30, 0.32, 0.40, 0.50, 0.62, 0.75, 0.82, 0.85, 0.85]),
        Preset(name: "Full Bass & Treble",
               preamp: 0.55,
               bands: [0.72, 0.68, 0.55, 0.40, 0.42, 0.50, 0.65, 0.78, 0.82, 0.82]),
        Preset(name: "Live",
               preamp: 0.52,
               bands: [0.40, 0.52, 0.58, 0.62, 0.62, 0.62, 0.58, 0.55, 0.55, 0.52]),
        Preset(name: "Party",
               preamp: 0.55,
               bands: [0.68, 0.68, 0.52, 0.50, 0.50, 0.50, 0.50, 0.52, 0.68, 0.68]),
        Preset(name: "Soft",
               preamp: 0.52,
               bands: [0.60, 0.52, 0.45, 0.42, 0.48, 0.58, 0.68, 0.70, 0.72, 0.75]),
        Preset(name: "Ska",
               preamp: 0.52,
               bands: [0.38, 0.32, 0.35, 0.45, 0.55, 0.58, 0.65, 0.68, 0.70, 0.68]),
        Preset(name: "Reggae",
               preamp: 0.50,
               bands: [0.50, 0.50, 0.50, 0.38, 0.50, 0.65, 0.65, 0.50, 0.50, 0.50]),
    ]
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
                .frame(height: 12)
                .frame(minWidth: 22)
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

// MARK: - Vertical EQ slider — classic Winamp yellow/orange fill + horizontal thumb
private struct EQSlider: View {
    @Binding var value: Double   // 0 (bottom) … 1 (top)

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let thumbH: CGFloat = 4          // slim horizontal bar thumb
            let thumbW: CGFloat = max(10, w - 1)
            let trackW: CGFloat = 5
            let trackH = h - thumbH

            ZStack {
                // Dark recessed groove
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color(red: 0.06, green: 0.06, blue: 0.10))
                    .frame(width: trackW, height: trackH)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0.5)
                            .stroke(Color(red: 0.15, green: 0.15, blue: 0.22), lineWidth: 0.5)
                            .frame(width: trackW, height: trackH)
                    )

                // Solid yellow/orange fill from bottom up to current value
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.75, blue: 0.05),
                                Color(red: 0.85, green: 0.55, blue: 0.0)
                            ],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: trackW, height: max(0, trackH * value))
                }
                .frame(width: trackW, height: trackH)

                // Centre notch (0 dB reference line)
                Rectangle()
                    .fill(WinampTheme.lcdGreenDim.opacity(0.5))
                    .frame(width: w - 2, height: 0.5)

                // Horizontal bar thumb
                ZStack {
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(LinearGradient(
                            colors: [
                                WinampTheme.sliderThumbHighlight,
                                WinampTheme.sliderThumb,
                                Color(red: 0.36, green: 0.38, blue: 0.40)
                            ],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: thumbW, height: thumbH)
                    // Single dark notch line
                    Rectangle()
                        .fill(WinampTheme.frameShadow)
                        .frame(width: thumbW - 2, height: 0.5)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 0.5)
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
