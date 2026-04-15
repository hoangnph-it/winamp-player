import SwiftUI

/// Winamp-style seek/progress bar
struct WinampSeekBar: View {
    @EnvironmentObject var playerManager: AudioPlayerManager
    @State private var isDragging = false
    @State private var dragValue: Double = 0

    private var progress: Double {
        guard playerManager.duration > 0 else { return 0 }
        return isDragging ? dragValue : (playerManager.currentTime / playerManager.duration)
    }

    var body: some View {
        VStack(spacing: 2) {
            // Time labels
            HStack {
                Text(formatTime(playerManager.currentTime))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(WinampTheme.lcdGreenDim)
                Spacer()
                Text("-\(formatTime(max(0, playerManager.duration - playerManager.currentTime)))")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(WinampTheme.lcdGreenDim)
            }

            // Seek bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(WinampTheme.displayBackground)
                        .frame(height: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(WinampTheme.displayBorder, lineWidth: 0.5)
                        )

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    WinampTheme.lcdGreenDim,
                                    WinampTheme.lcdGreen
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * progress), height: 8)

                    // Thumb
                    Circle()
                        .fill(WinampTheme.lcdGreen)
                        .frame(width: 14, height: 14)
                        .shadow(color: WinampTheme.lcdGreenDim.opacity(0.5), radius: 3)
                        .offset(x: max(0, min(geo.size.width - 14, geo.size.width * progress - 7)))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let percentage = max(0, min(1, value.location.x / geo.size.width))
                            dragValue = percentage
                        }
                        .onEnded { value in
                            let percentage = max(0, min(1, value.location.x / geo.size.width))
                            playerManager.seekToPercentage(percentage)
                            isDragging = false
                        }
                )
            }
            .frame(height: 14)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
