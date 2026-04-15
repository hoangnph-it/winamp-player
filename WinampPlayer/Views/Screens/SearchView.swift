import SwiftUI

/// Search tracks in the music library
struct SearchView: View {
    @EnvironmentObject var playerManager: AudioPlayerManager
    @EnvironmentObject var libraryManager: MusicLibraryManager
    @State private var searchQuery: String = ""

    private var searchResults: [Track] {
        libraryManager.searchTracks(query: searchQuery)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search header
            HStack {
                Text("SEARCH")
                    .font(WinampTheme.buttonFont)
                    .foregroundColor(WinampTheme.lcdGreenDim)

                Spacer()

                if !searchQuery.isEmpty {
                    Text("\(searchResults.count) RESULTS")
                        .font(WinampTheme.buttonFont)
                        .foregroundColor(WinampTheme.lcdGreenDim)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(WinampTheme.panelBackground)

            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(WinampTheme.lcdGreenDim)

                TextField("Search tracks, artists, albums...", text: $searchQuery)
                    .font(WinampTheme.playlistFont)
                    .foregroundColor(WinampTheme.lcdGreen)
                    #if os(iOS)
                    .autocapitalization(.none)
                    #endif
                    .disableAutocorrection(true)

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(WinampTheme.buttonText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(WinampTheme.displayBackground)
            .overlay(
                Rectangle()
                    .stroke(WinampTheme.displayBorder, lineWidth: 0.5)
            )

            // Results
            if searchQuery.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(WinampTheme.lcdGreenDim)

                    Text("Search your music library")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.lcdGreenDim)

                    Text("Type to search by title, artist, or album")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.buttonText)

                    Spacer()
                }
            } else if searchResults.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("No results for \"\(searchQuery)\"")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.lcdGreenDim)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, track in
                            SearchResultRow(track: track, index: index, searchQuery: searchQuery)
                                .onTapGesture {
                                    // Add to playlist and play
                                    if !playerManager.playlist.tracks.contains(where: { $0.fileURL == track.fileURL }) {
                                        playerManager.addToPlaylist([track])
                                    }
                                    if let playIndex = playerManager.playlist.tracks.firstIndex(where: { $0.fileURL == track.fileURL }) {
                                        playerManager.playTrackAtIndex(playIndex)
                                    }
                                }
                                .contextMenu {
                                    Button("Add to Playlist") {
                                        playerManager.addToPlaylist([track])
                                    }
                                    Button("Play All Results") {
                                        playerManager.replacePlaylist(with: searchResults)
                                    }
                                }
                        }
                    }
                }
                .background(WinampTheme.displayBackground)
            }
        }
    }
}

struct SearchResultRow: View {
    let track: Track
    let index: Int
    let searchQuery: String

    var body: some View {
        HStack(spacing: 8) {
            // Format badge
            Text(track.fileFormat.rawValue.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(track.fileFormat == .mp3 ? WinampTheme.accentBlue : WinampTheme.accentOrange)
                .frame(width: 28)

            // Track info
            VStack(alignment: .leading, spacing: 1) {
                Text(track.title)
                    .font(WinampTheme.playlistFont)
                    .foregroundColor(WinampTheme.playlistText)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(track.artist)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(WinampTheme.playlistTextDim)
                        .lineLimit(1)

                    if track.album != "Unknown Album" {
                        Text("| \(track.album)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(WinampTheme.playlistTextDim)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Text(track.formattedDuration)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(WinampTheme.playlistTextDim)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(index % 2 == 0 ? Color.clear : WinampTheme.panelBackground.opacity(0.3))
        .contentShape(Rectangle())
    }
}
