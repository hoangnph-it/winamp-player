import SwiftUI

/// Classic Winamp transport controls: Previous, Play, Pause, Stop, Next
struct WinampTransportControls: View {
    @EnvironmentObject var playerManager: AudioPlayerManager

    var body: some View {
        HStack(spacing: 6) {
            // Previous
            Button(action: { playerManager.previous() }) {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(WinampTransportButtonStyle())

            // Play
            Button(action: { playerManager.play() }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
            }
            .buttonStyle(WinampTransportButtonStyle(isActive: playerManager.playbackState == .playing))

            // Pause
            Button(action: { playerManager.pause() }) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(WinampTransportButtonStyle(isActive: playerManager.playbackState == .paused))

            // Stop
            Button(action: { playerManager.stop() }) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(WinampTransportButtonStyle(isActive: playerManager.playbackState == .stopped))

            // Next
            Button(action: { playerManager.next() }) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(WinampTransportButtonStyle())
        }
    }
}

/// Shuffle and Repeat toggles
struct WinampShuffleRepeatControls: View {
    @EnvironmentObject var playerManager: AudioPlayerManager

    var body: some View {
        HStack(spacing: 6) {
            // Shuffle
            Button(action: { playerManager.toggleShuffle() }) {
                HStack(spacing: 3) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 10))
                    Text("SHUF")
                }
            }
            .buttonStyle(WinampButtonStyle(isActive: playerManager.isShuffleEnabled))

            // Repeat
            Button(action: { playerManager.cycleRepeatMode() }) {
                HStack(spacing: 3) {
                    Image(systemName: playerManager.repeatMode.icon)
                        .font(.system(size: 10))
                    Text("REP \(playerManager.repeatMode.label)")
                }
            }
            .buttonStyle(WinampButtonStyle(isActive: playerManager.repeatMode != .off))
        }
    }
}
