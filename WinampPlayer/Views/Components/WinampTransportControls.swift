import SwiftUI

/// Classic Winamp 2.x control strip — pixel-accurate layout:
/// Row 1: [Prev][Play][Pause][Stop][Next]  |  [graduated volume]  [balance]
/// Row 2: [EQ][PL]  [SHUF][REP]
struct WinampControlStrip: View {
    @EnvironmentObject var player: AudioPlayerManager
    @State private var balance: Float = 0.5  // 0=left, 0.5=center, 1=right

    var body: some View {
        VStack(spacing: 2) {
            // ── Row 1: Transport + Volume + Balance ──
            HStack(spacing: 0) {
                // Transport buttons (cbuttons.bmp style)
                HStack(spacing: 1) {
                    TransportBtn(icon: "backward.end.fill", sz: 9) { player.previous() }
                    TransportBtn(icon: "play.fill", sz: 11, active: player.playbackState == .playing) { player.play() }
                    TransportBtn(icon: "pause.fill", sz: 9, active: player.playbackState == .paused) { player.pause() }
                    TransportBtn(icon: "stop.fill", sz: 9, active: player.playbackState == .stopped) { player.stop() }
                    TransportBtn(icon: "forward.end.fill", sz: 9) { player.next() }
                    // Eject button
                    TransportBtn(icon: "eject.fill", sz: 8) {
                        // Eject is decorative — no action
                    }
                }

                Spacer(minLength: 6)

                // Graduated volume bars (volume.bmp style)
                GraduatedVolume(value: Binding(
                    get: { player.volume },
                    set: { player.setVolume($0) }
                ))
                .frame(width: 72, height: 14)

                Spacer(minLength: 6)

                // Balance slider (smaller graduated bars)
                GraduatedBalance(value: $balance)
                    .frame(width: 42, height: 14)
            }
            .padding(.horizontal, 6)

            // ── Row 2: EQ/PL toggles + Shuffle/Repeat ──
            HStack(spacing: 0) {
                // EQ and PL toggle buttons (shufrep.bmp area)
                HStack(spacing: 2) {
                    SmallToggle(label: "EQ", active: true) { }
                    SmallToggle(label: "PL", active: true) { }
                }

                Spacer()

                // Shuffle and Repeat
                HStack(spacing: 2) {
                    SmallToggle(label: "S", active: player.isShuffleEnabled) {
                        player.toggleShuffle()
                    }
                    SmallToggle(label: "R", active: player.repeatMode != .off) {
                        player.cycleRepeatMode()
                    }
                }
            }
            .padding(.horizontal, 6)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Transport Button (prev/play/pause/stop/next/eject)
private struct TransportBtn: View {
    let icon: String
    var sz: CGFloat = 10
    var active: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: sz, weight: .bold))
        }
        .buttonStyle(WinampTransportStyle(isActive: active, width: 23))
    }
}

// MARK: - Graduated Volume Bars (like volume.bmp)
/// Classic Winamp volume: a row of thin vertical bars that fill green→yellow
struct GraduatedVolume: View {
    @Binding var value: Float
    private let barCount = 28

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let barW: CGFloat = max(1.5, (w - CGFloat(barCount - 1)) / CGFloat(barCount))
            let spacing: CGFloat = 1

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 1)
                    .fill(WinampTheme.sliderTrack)

                // Graduated bars
                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(0..<barCount, id: \.self) { i in
                        let barRatio = CGFloat(i) / CGFloat(barCount - 1)
                        let barH = 3 + barRatio * (h - 5) // graduated height
                        let filled = barRatio <= CGFloat(value)

                        Rectangle()
                            .fill(filled ? barColor(barRatio) : WinampTheme.frameDark.opacity(0.3))
                            .frame(width: barW, height: barH)
                    }
                }
                .padding(.horizontal, 1)

                // Invisible drag area
                Color.clear
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

    private func barColor(_ ratio: CGFloat) -> Color {
        if ratio > 0.75 { return WinampTheme.lcdYellow }
        if ratio > 0.5 { return Color(red: 0.2, green: 0.8, blue: 0.0) }
        return WinampTheme.vizLow
    }
}

// MARK: - Graduated Balance (smaller version of volume)
private struct GraduatedBalance: View {
    @Binding var value: Float
    private let barCount = 16

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let barW: CGFloat = max(1, (w - CGFloat(barCount - 1)) / CGFloat(barCount))
            let spacing: CGFloat = 1
            let center = barCount / 2

            ZStack {
                RoundedRectangle(cornerRadius: 1)
                    .fill(WinampTheme.sliderTrack)

                HStack(alignment: .center, spacing: spacing) {
                    ForEach(0..<barCount, id: \.self) { i in
                        let barRatio = CGFloat(i) / CGFloat(barCount - 1)
                        // Bars are taller at center, shorter at edges
                        let distFromCenter = abs(CGFloat(i) - CGFloat(center)) / CGFloat(center)
                        let barH = max(3, (h - 4) * (1 - distFromCenter * 0.5))

                        let litLeft = barRatio <= CGFloat(value) && i <= center
                        let litRight = barRatio >= CGFloat(1 - value) && i >= center
                        let lit = CGFloat(value) < 0.45 ? (i < center && barRatio >= CGFloat(value))
                            : CGFloat(value) > 0.55 ? (i > center && barRatio <= CGFloat(value))
                            : abs(i - center) <= 1

                        Rectangle()
                            .fill(lit || abs(i - center) <= 1
                                  ? WinampTheme.vizLow
                                  : WinampTheme.frameDark.opacity(0.3))
                            .frame(width: barW, height: barH)
                    }
                }
                .padding(.horizontal, 1)

                Color.clear
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
}

// MARK: - Small Toggle Button (EQ/PL/S/R)
private struct SmallToggle: View {
    let label: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(active ? WinampTheme.btnActive : WinampTheme.btnText)
                .frame(width: 22, height: 14)
                .background(active ? WinampTheme.frameDark : WinampTheme.btnFace)
                .overlay(BevelBorder(pressed: active))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Volume slider (legacy - kept for WinampVolumeControl.swift compatibility)
struct VolumeSlider: View {
    @Binding var value: Float

    var body: some View {
        GraduatedVolume(value: $value)
            .frame(height: 14)
    }
}
