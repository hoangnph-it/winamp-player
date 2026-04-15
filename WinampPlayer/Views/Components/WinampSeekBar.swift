import SwiftUI

/// Classic Winamp 2.x position bar (posbar.bmp)
/// A thin groove with a small rectangular thumb that slides along it
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
            let thumbW: CGFloat = 14
            let thumbH: CGFloat = 8
            let grooveH: CGFloat = 3

            ZStack(alignment: .leading) {
                // Groove (recessed look)
                RoundedRectangle(cornerRadius: 1)
                    .fill(WinampTheme.sliderTrack)
                    .frame(height: grooveH)
                    .overlay(
                        // Inner shadow for depth
                        VStack(spacing: 0) {
                            Rectangle().fill(WinampTheme.frameShadow).frame(height: 1)
                            Spacer()
                            Rectangle().fill(WinampTheme.frameHighlight.opacity(0.3)).frame(height: 1)
                        }
                        .frame(height: grooveH)
                    )

                // Filled portion
                RoundedRectangle(cornerRadius: 1)
                    .fill(WinampTheme.sliderFill)
                    .frame(width: max(0, w * pct), height: grooveH)

                // Thumb (classic small rectangular knob)
                RoundedRectangle(cornerRadius: 1)
                    .fill(WinampTheme.sliderThumb)
                    .frame(width: thumbW, height: thumbH)
                    .overlay(
                        // Bevel on thumb
                        ZStack {
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
                    )
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
