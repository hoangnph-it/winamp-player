import SwiftUI

/// Winamp-style volume slider
struct WinampVolumeControl: View {
    @EnvironmentObject var playerManager: AudioPlayerManager

    var body: some View {
        HStack(spacing: 6) {
            // Volume icon
            Button(action: {
                if playerManager.volume > 0 {
                    playerManager.setVolume(0)
                } else {
                    playerManager.setVolume(0.75)
                }
            }) {
                Image(systemName: volumeIcon)
                    .font(.system(size: 12))
                    .foregroundColor(WinampTheme.lcdGreenDim)
                    .frame(width: 20)
            }
            .buttonStyle(.plain)

            // Volume slider
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(WinampTheme.displayBackground)
                        .frame(height: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(WinampTheme.displayBorder, lineWidth: 0.5)
                        )

                    // Fill
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
                        .frame(width: geo.size.width * CGFloat(playerManager.volume), height: 6)

                    // Thumb
                    RoundedRectangle(cornerRadius: 2)
                        .fill(WinampTheme.buttonFace)
                        .frame(width: 10, height: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(WinampTheme.buttonHighlight, lineWidth: 0.5)
                        )
                        .offset(x: max(0, min(geo.size.width - 10, geo.size.width * CGFloat(playerManager.volume) - 5)))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let volume = Float(max(0, min(1, value.location.x / geo.size.width)))
                            playerManager.setVolume(volume)
                        }
                )
            }
            .frame(height: 14)
            .frame(maxWidth: 120)

            // Volume percentage
            Text("\(Int(playerManager.volume * 100))%")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(WinampTheme.lcdGreenDim)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private var volumeIcon: String {
        if playerManager.volume == 0 {
            return "speaker.slash.fill"
        } else if playerManager.volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if playerManager.volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
}
