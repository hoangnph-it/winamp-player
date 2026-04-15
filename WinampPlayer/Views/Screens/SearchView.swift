import SwiftUI

/// Search tracks in the music library
struct SearchView: View {
    @EnvironmentObject var player: AudioPlayerManager
    @EnvironmentObject var library: MusicLibraryManager
    @State private var query: String = ""

    private var results: [Track] {
        library.searchTracks(query: query)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(WinampTheme.lcdGreenDim)

                TextField("Search…", text: $query)
                    .font(WinampTheme.plFont)
                    .foregroundColor(WinampTheme.lcdGreen)
                    #if os(iOS)
                    .autocapitalization(.none)
                    #endif
                    .disableAutocorrection(true)

                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(WinampTheme.btnText)
                    }
                    .buttonStyle(.plain)

                    Text("\(results.count)")
                        .font(WinampTheme.badgeFont)
                        .foregroundColor(WinampTheme.lcdGreenDim)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(WinampTheme.displayBg)
            .overlay(Rectangle().stroke(WinampTheme.displayBorder, lineWidth: 0.5))

            // Results
            if query.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("Type to search by title, artist, or album")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.plTextDim)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(WinampTheme.plBg)
            } else if results.isEmpty {
                VStack {
                    Spacer()
                    Text("No results for \"\(query)\"")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.plTextDim)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(WinampTheme.plBg)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { idx, track in
                            SRow(track: track, index: idx)
                                .onTapGesture {
                                    if !player.playlist.tracks.contains(where: { $0.fileURL == track.fileURL }) {
                                        player.addToPlaylist([track])
                                    }
                                    if let pi = player.playlist.tracks.firstIndex(where: { $0.fileURL == track.fileURL }) {
                                        player.playTrackAtIndex(pi)
                                    }
                                }
                                .contextMenu {
                                    Button("Add to Playlist") { player.addToPlaylist([track]) }
                                    Button("Play All Results") { player.replacePlaylist(with: results) }
                                }
                        }
                    }
                }
                .background(WinampTheme.plBg)
            }
        }
    }
}

private struct SRow: View {
    let track: Track; let index: Int
    var body: some View {
        HStack(spacing: 4) {
            Text(track.fileFormat.rawValue.uppercased())
                .font(WinampTheme.badgeFont)
                .foregroundColor(WinampTheme.lcdYellow)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(track.title).font(WinampTheme.plFont).foregroundColor(WinampTheme.plText).lineLimit(1)
                Text(track.artist).font(.system(size: 9, design: .monospaced)).foregroundColor(WinampTheme.plTextDim).lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(track.formattedDuration).font(WinampTheme.plFont).foregroundColor(WinampTheme.plTextDim)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(index % 2 == 0 ? Color.clear : WinampTheme.frameDark.opacity(0.3))
        .contentShape(Rectangle())
    }
}
