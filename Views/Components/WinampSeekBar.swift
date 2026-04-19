import SwiftUI

/// Classic Winamp 2.x position bar (posbar.bmp) — a thin recessed groove with
/// subtle graduated tick marks and a small rectangular thumb.
struct WinampSeekBar: View {
    @EnvironmentObject var player: AudioPlayerManager
    @State private var dragging = false
    @State private var dragPct: Double = 0

    private var pct: Double {
        guard player.duration > 0 else { return 0 }
        return dragging ? dragPct : player.currentTime / player.duration
    }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let thumbW: CGFloat = 29
            let thumbH: CGFloat = 10
            let grooveH: CGFloat = 3

            ZStack(alignment: .leading) {
                // Groove (recessed look) with classic top/bottom bevel
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(WinampTheme.sliderTrack)
                        .frame(height: grooveH)

                    // Graduated tick marks — tiny dim vertical pips along the
                    // groove at regular intervals, emulating the classic
                    // position-bar ruler look.
                    GraduatedTicks(count: 28)
                        .frame(height: grooveH)

                    // Top shadow + bottom highlight for recessed bevel
                    VStack(spacing: 0) {
                        Rectangle().fill(WinampTheme.frameShadow).frame(height: 1)
                        Spacer()
                        Rectangle().fill(WinampTheme.frameHighlight.opacity(0.30)).frame(height: 1)
                    }
                    .frame(height: grooveH)
                    .allowsHitTesting(false)
                }

                // Thumb (classic small rectangular knob with bevel)
                SeekThumb()
                    .frame(width: thumbW, height: thumbH)
                    .offset(x: max(0, min(w - thumbW, w * pct - thumbW / 2)))
            }
            .frame(height: max(grooveH, thumbH))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        dragging = true
                        dragPct = max(0, min(1, v.location.x / w))
                    }
                    .onEnded { v in
                        let p = max(0, min(1, v.location.x / w))
                        player.seekToPercentage(p)
                        dragging = false
                    }
            )
        }
        .frame(height: 10)
    }
}

// MARK: - Graduated tick marks along the groove
private struct GraduatedTicks: View {
    let count: Int

    var body: some View {
        GeometryReader { g in
            HStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white.opacity(i % 4 == 0 ? 0.18 : 0.08))
                        .frame(width: 1)
                    if i < count - 1 {
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(width: g.size.width)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Classic Winamp position-bar thumb (posbar_knob)
private struct SeekThumb: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(WinampTheme.sliderThumb)

            // 3 vertical grip lines down the middle
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(WinampTheme.frameShadow.opacity(0.8))
                        .frame(width: 1, height: 6)
                }
            }

            // Bevel
            VStack(spacing: 0) {
                Rectangle().fill(WinampTheme.sliderThumbHighlight).frame(height: 1)
                Spacer()
                Rectangle().fill(WinampTheme.frameShadow).frame(height: 1)
            }
            HStack(spacing: 0) {
                Rectangle().fill(WinampTheme.sliderThumbHighlight).frame(width: 1)
                Spacer()
                Rectangle().fill(WinampTheme.frameShadow).frame(width: 1)
            }
        }
    }
}
