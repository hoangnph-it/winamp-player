import SwiftUI

/// Classic Winamp Playlist window — numbered green text, blue highlight, status bar
struct PlaylistView: View {
    @EnvironmentObject var player: AudioPlayerManager
    @EnvironmentObject var library: MusicLibraryManager

    var body: some View {
        VStack(spacing: 0) {
            // ── Track list ──
            if player.playlist.tracks.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Spacer()
                    Text("Playlist is empty")
                        .font(WinampTheme.plFont)
                        .foregroundColor(WinampTheme.plTextDim)
                    Text("Add tracks from the LIBRARY tab")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.plTextDim)

                    if !library.tracks.isEmpty {
                        Button {
                            player.addToPlaylist(library.tracks)
                        } label: {
                            Text("+ ADD ALL (\(library.tracks.count))")
                        }
                        .buttonStyle(WinampButtonStyle())
                        .padding(.top, 4)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(WinampTheme.plBg)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(player.playlist.tracks.enumerated()), id: \.element.id) { idx, track in
                                PLRow(track: track, index: idx,
                                      isCurrent: player.playlist.currentIndex == idx && player.playbackState != .stopped,
                                      isPlaying: player.playlist.currentIndex == idx && player.playbackState == .playing)
                                    .id(idx)
                                    .onTapGesture { player.playTrackAtIndex(idx) }
                                    .contextMenu {
                                        Button("Remove") { player.playlist.removeTrack(at: idx) }
                                    }
                            }
                        }
                    }
                    .background(WinampTheme.plBg)
                }
            }

            // ── Status bar ──
            HStack(spacing: 0) {
                // Manage buttons
                HStack(spacing: 2) {
                    PLBtn(label: "+ADD") { player.addToPlaylist(library.tracks) }
                    PLBtn(label: "CLR") { player.clearPlaylist() }
                }

                Spacer()

                // Track count + total time
                let count = player.playlist.tracks.count
                Text("\(count) track\(count == 1 ? "" : "s")")
                    .font(WinampTheme.badgeFont)
                    .foregroundColor(WinampTheme.plTextDim)

                Text("  \(player.playlist.formattedTotalDuration)")
                    .font(WinampTheme.badgeFont)
                    .foregroundColor(WinampTheme.plTextDim)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(WinampTheme.frameBg)
            .overlay(BevelBorder())
        }
    }
}

// MARK: - Playlist row
private struct PLRow: View {
    let track: Track
    let index: Int
    let isCurrent: Bool
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 4) {
            // Number
            Text("\(index + 1).")
                .font(WinampTheme.plFont)
                .foregroundColor(isCurrent ? WinampTheme.plNowPlaying : WinampTheme.plTextDim)
                .frame(width: 24, alignment: .trailing)

            // Artist - Title
            Text(track.formattedTitle)
                .font(WinampTheme.plFont)
                .foregroundColor(isCurrent ? WinampTheme.plNowPlaying : WinampTheme.plText)
                .lineLimit(1)

            Spacer(minLength: 4)

            // Duration
            Text(track.formattedDuration)
                .font(WinampTheme.plFont)
                .foregroundColor(WinampTheme.plTextDim)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(isCurrent ? WinampTheme.plSelected : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Tiny playlist button
private struct PLBtn: View {
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(WinampTheme.btnText)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(WinampTheme.btnFace)
                .overlay(BevelBorder())
        }
        .buttonStyle(.plain)
    }
}
