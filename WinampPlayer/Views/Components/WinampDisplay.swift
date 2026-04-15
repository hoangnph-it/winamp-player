import SwiftUI

/// The main LCD-style display showing track info, time, and status
struct WinampDisplay: View {
    @EnvironmentObject var playerManager: AudioPlayerManager

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                // Left: Playback status & time
                VStack(alignment: .leading, spacing: 4) {
                    // Status indicator
                    HStack(spacing: 4) {
                        PlaybackStatusIcon(state: playerManager.playbackState)
                        Text(playerManager.playbackState.rawValue.uppercased())
                            .font(WinampTheme.infoFont)
                            .foregroundColor(WinampTheme.lcdGreenDim)
                    }

                    // Large time display
                    Text(formatTime(playerManager.currentTime))
                        .font(WinampTheme.displayFont)
                        .foregroundColor(WinampTheme.lcdGreen)
                        .monospacedDigit()
                        .shadow(color: WinampTheme.lcdGreenDim.opacity(0.5), radius: 4)
                }

                Spacer()

                // Right: Track info
                VStack(alignment: .trailing, spacing: 4) {
                    // Format & quality info
                    HStack(spacing: 8) {
                        InfoBadge(label: playerManager.currentTrack?.fileFormat.rawValue.uppercased() ?? "---")
                        InfoBadge(label: playerManager.sampleRate > 0 ? "\(playerManager.sampleRate / 1000)kHz" : "---")
                    }

                    // Track title (scrolling)
                    Text(playerManager.currentTrack?.title ?? "No Track Loaded")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.lcdGreen)
                        .lineLimit(1)

                    // Artist
                    Text(playerManager.currentTrack?.artist ?? "---")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.lcdGreenDim)
                        .lineLimit(1)

                    // Duration
                    Text(playerManager.currentTrack?.formattedDuration ?? "0:00")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.lcdGreenDim)
                }
            }
            .padding(10)
        }
        .background(WinampTheme.displayBackground)
        .cornerRadius(WinampTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: WinampTheme.cornerRadius)
                .stroke(WinampTheme.displayBorder, lineWidth: 1)
        )
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Subviews

struct PlaybackStatusIcon: View {
    let state: PlaybackState

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 10))
            .foregroundColor(state == .playing ? WinampTheme.lcdGreen : WinampTheme.lcdGreenDim)
    }

    private var iconName: String {
        switch state {
        case .playing: return "play.fill"
        case .paused: return "pause.fill"
        case .stopped: return "stop.fill"
        }
    }
}

struct InfoBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(WinampTheme.accentOrange)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(WinampTheme.accentOrange.opacity(0.3), lineWidth: 0.5)
                    )
            )
    }
}
