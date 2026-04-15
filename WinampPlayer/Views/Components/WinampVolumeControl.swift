import SwiftUI

// This file is intentionally minimal — volume is now integrated into
// WinampControlStrip (WinampTransportControls.swift).
// Kept for backward compatibility; the VolumeSlider struct lives in
// WinampTransportControls.swift.

/// Standalone volume control (used only if needed outside the control strip)
struct WinampVolumeControl: View {
    @EnvironmentObject var player: AudioPlayerManager
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: volumeIcon)
                .font(.system(size: 10))
                .foregroundColor(WinampTheme.lcdGreenDim)
                .frame(width: 14)

            VolumeSlider(value: Binding(
                get: { player.volume },
                set: { player.setVolume($0) }
            ))

            Text("\(Int(player.volume * 100))%")
                .font(WinampTheme.badgeFont)
                .foregroundColor(WinampTheme.lcdGreenDim)
                .frame(width: 26, alignment: .trailing)
        }
    }

    private var volumeIcon: String {
        if player.volume == 0 { return "speaker.slash.fill" }
        if player.volume < 0.33 { return "speaker.wave.1.fill" }
        if player.volume < 0.66 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }
}
