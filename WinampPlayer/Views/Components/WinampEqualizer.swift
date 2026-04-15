import SwiftUI

/// Classic Winamp Equalizer panel — compact layout matching original proportions
/// ┌─────────────────────────────────────┐
/// │ WINAMP EQUALIZER (title bar)        │
/// │ [ON]              [PRESETS]         │
/// │ PRE │ 60 170 310 600 1K 3K 6K 12K… │
/// │ AMP │ ▌▌ ▌▌  ▌▌  ▌▌  ▌▌ ▌▌ ▌▌ ▌▌  │
/// └─────────────────────────────────────┘
struct WinampEqualizer: View {
    @State private var eqEnabled = true
    @State private var preamp: Double = 0.5
    @State private var bands: [Double] = [0.5, 0.55, 0.6, 0.65, 0.55, 0.45, 0.5, 0.4, 0.45, 0.5]

    private let bandLabels = ["60", "170", "310", "600", "1K", "3K", "6K", "12K", "14K", "16K"]

    var body: some View {
        VStack(spacing: 0) {
            // ── Title bar ──
            WinampTitleBar(title: "WINAMP EQUALIZER")

            // ── Control row: ON / PRESETS ──
            HStack(spacing: 4) {
                EQToggle(label: "ON", active: $eqEnabled)

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
            .padding(.vertical, 2)

            // ── Graph line (the +12 / 0 / -12 dB scale) ──
            HStack(spacing: 0) {
                Text("+12")
                    .font(.system(size: 6, design: .monospaced))
                    .foregroundColor(WinampTheme.lcdGreenDim)
                Spacer()
                Text("0")
                    .font(.system(size: 6, design: .monospaced))
                    .foregroundColor(WinampTheme.lcdGreenDim)
                Spacer()
                Text("-12")
                    .font(.system(size: 6, design: .monospaced))
                    .foregroundColor(WinampTheme.lcdGreenDim)
            }
            .padding(.horizontal, 5)

            // ── Sliders area ──
            HStack(alignment: .bottom, spacing: 0) {
                // Preamp
                VStack(spacing: 1) {
                    Text("PRE")
                        .font(.system(size: 6, weight: .bold, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreenDim)

                    EQSlider(value: $preamp)
                        .frame(width: 14)

                    Text("AMP")
                        .font(.system(size: 6, weight: .bold, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreenDim)
                }
                .frame(width: 24)
                .padding(.trailing, 2)

                // Separator
                Rectangle()
                    .fill(WinampTheme.frameShadow)
                    .frame(width: 1)
                    .padding(.vertical, 2)

                // 10 band sliders
                HStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { i in
                        VStack(spacing: 1) {
                            EQSlider(value: $bands[i])
                                .frame(width: 14)

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
            .padding(.horizontal, 4)
            .padding(.bottom, 3)
            .frame(height: 90)
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

// MARK: - EQ toggle button (ON)
private struct EQToggle: View {
    let label: String
    @Binding var active: Bool
    var body: some View {
        Button { active.toggle() } label: {
            Text(label)
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundColor(active ? WinampTheme.btnActive : WinampTheme.btnText)
                .frame(width: 22, height: 12)
                .background(active ? WinampTheme.frameDark : WinampTheme.btnFace)
                .overlay(BevelBorder(pressed: active))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vertical EQ slider
private struct EQSlider: View {
    @Binding var value: Double   // 0 (bottom) … 1 (top)

    var body: some View {
        GeometryReader { g in
            let h = g.size.height
            let thumbH: CGFloat = 6
            let trackH = h - thumbH

            ZStack {
                // Groove with colored fill
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(fillColor)
                        .frame(height: max(0, trackH * (1 - value)))
                    Rectangle()
                        .fill(WinampTheme.eqSliderBg)
                        .frame(height: max(0, trackH * value))
                }
                .frame(width: 5)
                .clipShape(RoundedRectangle(cornerRadius: 1))
                .overlay(RoundedRectangle(cornerRadius: 1).stroke(WinampTheme.frameShadow, lineWidth: 0.5))

                // Centre notch
                Rectangle()
                    .fill(WinampTheme.lcdGreenDim.opacity(0.4))
                    .frame(width: 8, height: 1)

                // Thumb
                RoundedRectangle(cornerRadius: 1)
                    .fill(WinampTheme.sliderThumb)
                    .frame(width: 12, height: thumbH)
                    .overlay(RoundedRectangle(cornerRadius: 1).stroke(WinampTheme.sliderThumbHighlight, lineWidth: 0.5))
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

    private var fillColor: Color {
        if value > 0.7 { return WinampTheme.eqRed }
        if value > 0.55 { return WinampTheme.eqYellow }
        return WinampTheme.eqGreen
    }
}
