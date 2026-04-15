import SwiftUI

/// Full-width Winamp spectrum analyzer (shown inside the EQ section or standalone)
struct AudioVisualizerView: View {
    @EnvironmentObject var player: AudioPlayerManager

    var body: some View {
        GeometryReader { g in
            let barCount = player.audioLevels.count
            let spacing: CGFloat = 1.5
            let totalSpacing = spacing * CGFloat(barCount - 1)
            let barW = max(2, (g.size.width - totalSpacing) / CGFloat(barCount))
            let maxH = g.size.height - 2

            ZStack {
                WinampTheme.displayBg

                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(0..<barCount, id: \.self) { i in
                        SpectrumColumn(level: CGFloat(player.audioLevels[i]),
                                       barWidth: barW, maxHeight: maxH)
                    }
                }
                .padding(1)
            }
            .overlay(Rectangle().stroke(WinampTheme.displayBorder, lineWidth: 0.5))
        }
    }
}

/// Single spectrum column — segmented blocks green → yellow → red
private struct SpectrumColumn: View {
    let level: CGFloat
    let barWidth: CGFloat
    let maxHeight: CGFloat

    private let segH: CGFloat = 2.5
    private let gap: CGFloat = 1

    var body: some View {
        let totalSegs = max(1, Int(maxHeight / (segH + gap)))
        let litSegs = max(0, Int(level * CGFloat(totalSegs)))

        VStack(spacing: gap) {
            ForEach((0..<totalSegs).reversed(), id: \.self) { i in
                let lit = i < litSegs
                Rectangle()
                    .fill(lit ? color(for: i, of: totalSegs) : WinampTheme.displayBg.opacity(0.3))
                    .frame(width: barWidth, height: segH)
            }
        }
    }

    private func color(for seg: Int, of total: Int) -> Color {
        let ratio = CGFloat(seg) / CGFloat(max(1, total - 1))
        if ratio > 0.82 { return WinampTheme.vizPeak }
        if ratio > 0.65 { return WinampTheme.vizHigh }
        if ratio > 0.40 { return WinampTheme.vizMid }
        return WinampTheme.vizLow
    }
}
