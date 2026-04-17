import SwiftUI

/// Classic Winamp 2.x transport control strip — single row matching the
/// reference video:
///
///   [◄◄] [▶] [▐▐] [■] [▶▶]  [▲]   [ SHUFFLE ] [ R ]      [⚡]
///
/// (Volume, balance, EQ, PL buttons live in WinampDisplay's right column.)
struct WinampControlStrip: View {
    @EnvironmentObject var player: AudioPlayerManager

    var body: some View {
        HStack(spacing: 2) {
            // Transport buttons — grouped
            HStack(spacing: 1) {
                TransportBtn(icon: "backward.end.fill", sz: 9) { player.previous() }
                TransportBtn(icon: "play.fill", sz: 11,
                             active: player.playbackState == .playing) { player.play() }
                TransportBtn(icon: "pause.fill", sz: 9,
                             active: player.playbackState == .paused) { player.pause() }
                TransportBtn(icon: "stop.fill", sz: 9,
                             active: player.playbackState == .stopped) { player.stop() }
                TransportBtn(icon: "forward.end.fill", sz: 9) { player.next() }
            }

            Spacer().frame(width: 4)

            // Eject (decorative)
            TransportBtn(icon: "eject.fill", sz: 9, width: 21) { /* eject */ }

            Spacer().frame(width: 8)

            // Shuffle (wide bordered text button)
            ShuffleButton(active: player.isShuffleEnabled) {
                player.toggleShuffle()
            }

            Spacer().frame(width: 3)

            // Repeat (small R toggle)
            RepeatButton(mode: player.repeatMode) {
                player.cycleRepeatMode()
            }

            Spacer()

            // Winamp logo / lightning bolt (classic decoration)
            WinampLightning()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }
}

// MARK: - Transport Button (prev/play/pause/stop/next/eject)
private struct TransportBtn: View {
    let icon: String
    var sz: CGFloat = 10
    var active: Bool = false
    var width: CGFloat = 23
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: sz, weight: .bold))
        }
        .buttonStyle(WinampTransportStyle(isActive: active, width: width))
    }
}

// MARK: - Shuffle
private struct ShuffleButton: View {
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("SHUFFLE")
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundColor(active ? WinampTheme.btnActive : WinampTheme.btnText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .frame(height: 16)
                .background(active ? WinampTheme.frameDark : WinampTheme.btnFace)
                .overlay(BevelBorder(pressed: active))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Repeat (R) with mode indicator
private struct RepeatButton: View {
    let mode: RepeatMode
    let action: () -> Void

    private var label: String {
        switch mode {
        case .off: return "R"
        case .all: return "R"
        case .one: return "R1"
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(mode != .off ? WinampTheme.btnActive : WinampTheme.btnText)
                .frame(width: 26, height: 16)
                .background(mode != .off ? WinampTheme.frameDark : WinampTheme.btnFace)
                .overlay(BevelBorder(pressed: mode != .off))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Winamp lightning logo
private struct WinampLightning: View {
    var body: some View {
        Image(systemName: "bolt.fill")
            .font(.system(size: 13, weight: .heavy))
            .foregroundColor(Color(red: 0.88, green: 0.70, blue: 0.0))
            .shadow(color: Color(red: 0.88, green: 0.70, blue: 0.0).opacity(0.6), radius: 1)
            .padding(.trailing, 2)
    }
}

// MARK: - Orange horizontal volume slider (volume.bmp style — graduated)
/// Classic Winamp 2.x volume bar: a long orange-filled groove with tiny
/// vertical graduated pip marks along its length and a small grey thumb.
struct GraduatedVolume: View {
    @Binding var value: Float
    /// How many graduated pip marks to draw along the slider.
    var pipCount: Int = 28

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let grooveH: CGFloat = max(7, h - 3)
            let thumbW: CGFloat = 11
            let thumbH: CGFloat = max(7, h - 1)
            let filledW = max(0, min(w, w * CGFloat(value)))

            ZStack(alignment: .leading) {
                // Dark recessed groove with top/bottom bevel
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(WinampTheme.sliderTrack)
                        .frame(height: grooveH)

                    // Orange fill (graduated portion)
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.62, blue: 0.10),
                            Color(red: 0.78, green: 0.38, blue: 0.0)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(width: filledW, height: grooveH)

                    // Graduated pip marks — tiny vertical dark ticks across
                    // the full groove, giving it the classic ruler look.
                    GraduatedPips(count: pipCount, height: grooveH)

                    // Bevel
                    VStack(spacing: 0) {
                        Rectangle().fill(WinampTheme.frameShadow).frame(height: 1)
                        Spacer()
                        Rectangle().fill(WinampTheme.frameHighlight.opacity(0.30)).frame(height: 1)
                    }
                    .frame(height: grooveH)
                    .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: 1))

                // Thumb knob
                SliderThumb()
                    .frame(width: thumbW, height: thumbH)
                    .offset(x: max(0, min(w - thumbW, filledW - thumbW / 2)))
            }
            .frame(height: h)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        value = Float(max(0, min(1, v.location.x / w)))
                    }
            )
        }
    }
}

/// Tiny vertical pip marks spaced evenly along a slider groove — gives the
/// classic "graduated ruler" appearance of the Winamp volume/balance bars.
private struct GraduatedPips: View {
    let count: Int
    let height: CGFloat

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let step = w / CGFloat(max(1, count - 1))
            ZStack(alignment: .leading) {
                ForEach(0..<count, id: \.self) { i in
                    let x = CGFloat(i) * step
                    Rectangle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 1, height: height - 2)
                        .offset(x: x)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Orange horizontal balance slider (balance.bmp style — graduated)
/// Same orange slider look as volume but center-zero: filled outward from the
/// middle toward whichever side is biased, with graduated pip marks.
struct GraduatedBalance: View {
    @Binding var value: Float
    var pipCount: Int = 9

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let grooveH: CGFloat = max(7, h - 3)
            let thumbW: CGFloat = 11
            let thumbH: CGFloat = max(7, h - 1)
            let center = w / 2
            let pos = w * CGFloat(value)

            // Fill starts at center, extends toward pos
            let fillStart = min(center, pos)
            let fillWidth = abs(pos - center)

            ZStack(alignment: .leading) {
                ZStack(alignment: .leading) {
                    // Dark groove
                    Rectangle()
                        .fill(WinampTheme.sliderTrack)
                        .frame(height: grooveH)

                    // Orange fill from center outward
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.62, blue: 0.10),
                            Color(red: 0.78, green: 0.38, blue: 0.0)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(width: fillWidth, height: grooveH)
                    .offset(x: fillStart)

                    // Graduated pips
                    GraduatedPips(count: pipCount, height: grooveH)

                    // Brighter center tick
                    Rectangle()
                        .fill(WinampTheme.lcdGreenDim.opacity(0.8))
                        .frame(width: 1, height: grooveH - 1)
                        .offset(x: center - 0.5)

                    // Bevel
                    VStack(spacing: 0) {
                        Rectangle().fill(WinampTheme.frameShadow).frame(height: 1)
                        Spacer()
                        Rectangle().fill(WinampTheme.frameHighlight.opacity(0.30)).frame(height: 1)
                    }
                    .frame(height: grooveH)
                    .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: 1))

                // Thumb
                SliderThumb()
                    .frame(width: thumbW, height: thumbH)
                    .offset(x: max(0, min(w - thumbW, pos - thumbW / 2)))
            }
            .frame(height: h)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        value = Float(max(0, min(1, v.location.x / w)))
                    }
            )
        }
    }
}

// MARK: - Classic Winamp slider thumb (small grey bevelled knob)
struct SliderThumb: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1)
                .fill(LinearGradient(
                    colors: [
                        WinampTheme.sliderThumbHighlight,
                        WinampTheme.sliderThumb,
                        Color(red: 0.36, green: 0.38, blue: 0.40)
                    ],
                    startPoint: .top, endPoint: .bottom
                ))
            // Horizontal notch
            Rectangle()
                .fill(WinampTheme.frameShadow)
                .frame(height: 1)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .stroke(WinampTheme.frameShadow, lineWidth: 0.5)
        )
    }
}

// MARK: - Legacy VolumeSlider (kept for WinampVolumeControl.swift compatibility)
struct VolumeSlider: View {
    @Binding var value: Float

    var body: some View {
        GraduatedVolume(value: $value)
            .frame(height: 14)
    }
}
