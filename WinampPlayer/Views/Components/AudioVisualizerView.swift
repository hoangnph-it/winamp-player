import SwiftUI

/// Classic Winamp spectrum analyzer visualization
struct AudioVisualizerView: View {
    @EnvironmentObject var playerManager: AudioPlayerManager

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: WinampTheme.cornerRadius)
                    .fill(WinampTheme.displayBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: WinampTheme.cornerRadius)
                            .stroke(WinampTheme.displayBorder, lineWidth: 0.5)
                    )

                // Spectrum bars
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<playerManager.audioLevels.count, id: \.self) { index in
                        SpectrumBar(
                            level: CGFloat(playerManager.audioLevels[index]),
                            maxHeight: geo.size.height - 8
                        )
                    }
                }
                .padding(4)
            }
        }
    }
}

struct SpectrumBar: View {
    let level: CGFloat
    let maxHeight: CGFloat

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 1) {
                Spacer()

                // Draw segmented bar
                let barHeight = max(2, level * maxHeight)
                let segmentCount = max(1, Int(barHeight / 4))

                VStack(spacing: 1) {
                    ForEach(0..<segmentCount, id: \.self) { i in
                        let ratio = CGFloat(i) / CGFloat(max(1, segmentCount - 1))
                        Rectangle()
                            .fill(barColor(for: ratio))
                            .frame(height: 3)
                    }
                }
                .frame(height: barHeight)
            }
        }
    }

    private func barColor(for ratio: CGFloat) -> Color {
        if ratio > 0.8 {
            return WinampTheme.vizHigh
        } else if ratio > 0.5 {
            return WinampTheme.vizMid
        } else {
            return WinampTheme.vizLow
        }
    }
}
