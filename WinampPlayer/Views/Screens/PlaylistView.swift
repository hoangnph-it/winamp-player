import SwiftUI

/// Classic Winamp playlist editor view
struct PlaylistView: View {
    @EnvironmentObject var playerManager: AudioPlayerManager
    @EnvironmentObject var libraryManager: MusicLibraryManager

    var body: some View {
        VStack(spacing: 0) {
            // Playlist header
            HStack {
                Text("PLAYLIST EDITOR")
                    .font(WinampTheme.buttonFont)
                    .foregroundColor(WinampTheme.lcdGreenDim)

                Spacer()

                Text("\(playerManager.playlist.tracks.count) TRACKS")
                    .font(WinampTheme.buttonFont)
                    .foregroundColor(WinampTheme.lcdGreenDim)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(WinampTheme.panelBackground)

            // Track list
            if playerManager.playlist.tracks.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 32))
                        .foregroundColor(WinampTheme.lcdGreenDim)

                    Text("Playlist is empty")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.lcdGreenDim)

                    Text("Add tracks from the Library tab")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.buttonText)

                    // Quick add all button
                    if !libraryManager.tracks.isEmpty {
                        Button(action: {
                            playerManager.addToPlaylist(libraryManager.tracks)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("ADD ALL (\(libraryManager.tracks.count) TRACKS)")
                            }
                        }
                        .buttonStyle(WinampButtonStyle())
                        .padding(.top, 8)
                    }

                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(playerManager.playlist.tracks.enumerated()), id: \.element.id) { index, track in
                            PlaylistRow(
                                track: track,
                                index: index,
                                isCurrentTrack: playerManager.playlist.currentIndex == index && playerManager.playbackState != .stopped,
                                isPlaying: playerManager.playlist.currentIndex == index && playerManager.playbackState == .playing
                            )
                            .onTapGesture {
                                playerManager.playTrackAtIndex(index)
                            }
                            .contextMenu {
                                Button("Remove from Playlist") {
                                    playerManager.playlist.removeTrack(at: index)
                                }
                            }
                        }
                    }
                }
                .background(WinampTheme.displayBackground)
            }

            // Playlist controls footer
            HStack(spacing: 6) {
                Button(action: {
                    playerManager.addToPlaylist(libraryManager.tracks)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 9))
                        Text("ADD ALL")
                    }
                }
                .buttonStyle(WinampButtonStyle())

                Button(action: {
                    playerManager.clearPlaylist()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "trash")
                            .font(.system(size: 9))
                        Text("CLEAR")
                    }
                }
                .buttonStyle(WinampButtonStyle())

                Spacer()

                // Total duration
                Text("TOTAL: \(playerManager.playlist.formattedTotalDuration)")
                    .font(WinampTheme.buttonFont)
                    .foregroundColor(WinampTheme.lcdGreenDim)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(WinampTheme.panelBackground)
        }
    }
}

// MARK: - Playlist Row
struct PlaylistRow: View {
    let track: Track
    let index: Int
    let isCurrentTrack: Bool
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 6) {
            // Track number / play indicator
            ZStack {
                if isPlaying {
                    Image(systemName: "play.fill")
                        .font(.system(size: 8))
                        .foregroundColor(WinampTheme.playlistNowPlaying)
                } else {
                    Text("\(index + 1).")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(WinampTheme.playlistTextDim)
                }
            }
            .frame(width: 28, alignment: .trailing)

            // Track title
            Text(track.formattedTitle)
                .font(WinampTheme.playlistFont)
                .foregroundColor(isCurrentTrack ? WinampTheme.playlistNowPlaying : WinampTheme.playlistText)
                .lineLimit(1)

            Spacer()

            // Duration
            Text(track.formattedDuration)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(WinampTheme.playlistTextDim)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            isCurrentTrack
                ? WinampTheme.playlistSelected.opacity(0.6)
                : Color.clear
        )
        .contentShape(Rectangle())
    }
}
