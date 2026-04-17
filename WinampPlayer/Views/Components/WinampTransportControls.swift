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

// MARK: - Orange horizontal volume slider (volume.bmp style)
/// Thin dark groove with an orange-filled portion and a small grey thumb knob,
/// matching the reference video's volume bar.
struct GraduatedVolume: View {
    @Binding var value: Float

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let grooveH: CGFloat = max(4, h - 4)
            let thumbW: CGFloat = 8
            let thumbH: CGFloat = max(6, h - 2)
            let filledW = max(0, min(w, w * CGFloat(value)))

            ZStack(alignment: .leading) {
                // Dark recessed groove
                RoundedRectangle(cornerRadius: 1)
                    .fill(WinampTheme.sliderTrack)
                    .frame(height: grooveH)
                    .overlay(
                        VStack(spacing: 0) {
                            Rectangle().fill(WinampTheme.frameShadow).frame(height: 1)
                            Spacer()
                            Rectangle().fill(WinampTheme.frameHighlight.opacity(0.35)).frame(height: 1)
                        }
                        .frame(height: grooveH)
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                    )

                // Orange fill
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.55, blue: 0.05),
                        Color(red: 0.80, green: 0.42, blue: 0.0)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(width: filledW, height: grooveH)
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

// MARK: - Orange horizontal balance slider (balance.bmp style)
/// Same orange slider look as volume but center-zero: filled outward from the
/// middle toward whichever side is biased.
struct GraduatedBalance: View {
    @Binding var value: Float

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let grooveH: CGFloat = max(4, h - 4)
            let thumbW: CGFloat = 8
            let thumbH: CGFloat = max(6, h - 2)
            let center = w / 2
            let pos = w * CGFloat(value)

            // Fill starts at center, extends toward pos
            let fillStart = min(center, pos)
            let fillWidth = abs(pos - center)

            ZStack(alignment: .leading) {
                // Groove
                RoundedRectangle(cornerRadius: 1)
                    .fill(WinampTheme.sliderTrack)
                    .frame(height: grooveH)
                    .overlay(
                        VStack(spacing: 0) {
                            Rectangle().fill(WinampTheme.frameShadow).frame(height: 1)
                            Spacer()
                            Rectangle().fill(WinampTheme.frameHighlight.opacity(0.35)).frame(height: 1)
                        }
                        .frame(height: grooveH)
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                    )

                // Orange fill from center outward
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.55, blue: 0.05),
                        Color(red: 0.80, green: 0.42, blue: 0.0)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(width: fillWidth, height: grooveH)
                .offset(x: fillStart)
                .clipShape(RoundedRectangle(cornerRadius: 1))

                // Small center tick mark
                Rectangle()
                    .fill(WinampTheme.frameHighlight.opacity(0.45))
                    .frame(width: 1, height: grooveH - 1)
                    .offset(x: center - 0.5)

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
