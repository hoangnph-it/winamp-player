import SwiftUI

/// Classic Winamp Playlist window — numbered green text, blue highlight, and
/// a bottom status bar matching the reference video:
///
///   [ADD][REM][SEL][MISC]   artist - title (mm:ss)   ◄◄ ▶ ▐▐ ■ ▶▶   [LIST OPTS]
struct PlaylistView: View {
    @EnvironmentObject var player: AudioPlayerManager
    @EnvironmentObject var library: MusicLibraryManager

    // Multi-selection — synced with a single @State here. Could be lifted.
    @State private var selection = Set<Int>()

    var body: some View {
        VStack(spacing: 0) {
            // ── Track list ──
            if player.playlist.tracks.isEmpty {
                emptyState
            } else {
                trackList
            }

            // ── Bottom status bar ──
            PlaylistStatusBar(selection: $selection)
        }
    }

    // MARK: - Empty state — minimal dark panel matching the video
    private var emptyState: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WinampTheme.plBg)
    }

    // MARK: - Track list
    private var trackList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(player.playlist.tracks.enumerated()), id: \.element.id) { idx, track in
                        PLRow(
                            track: track,
                            index: idx,
                            isCurrent: player.playlist.currentIndex == idx && player.playbackState != .stopped,
                            isPlaying: player.playlist.currentIndex == idx && player.playbackState == .playing,
                            isSelected: selection.contains(idx)
                        )
                        .id(idx)
                        .onTapGesture(count: 2) { player.playTrackAtIndex(idx) }
                        .onTapGesture {
                            if selection.contains(idx) {
                                selection.remove(idx)
                            } else {
                                selection.insert(idx)
                            }
                        }
                        .contextMenu {
                            Button("Play")   { player.playTrackAtIndex(idx) }
                            Button("Remove") { player.playlist.removeTrack(at: idx) }
                        }
                    }
                }
            }
            .background(WinampTheme.plBg)
            .onChange(of: player.playlist.currentIndex) { newIdx in
                withAnimation { proxy.scrollTo(newIdx, anchor: .center) }
            }
        }
    }
}

// MARK: - Playlist row
private struct PLRow: View {
    let track: Track
    let index: Int
    let isCurrent: Bool
    let isPlaying: Bool
    let isSelected: Bool

    private var rowColor: Color {
        if isCurrent { return WinampTheme.plNowPlaying }
        return WinampTheme.plText
    }

    private var rowBg: Color {
        if isCurrent { return WinampTheme.plSelected }
        if isSelected { return WinampTheme.plSelected.opacity(0.5) }
        return .clear
    }

    var body: some View {
        HStack(spacing: 4) {
            // Number
            Text("\(index + 1).")
                .font(WinampTheme.plFont)
                .foregroundColor(rowColor)
                .frame(width: 24, alignment: .trailing)

            // Artist - Title
            Text(track.formattedTitle)
                .font(WinampTheme.plFont)
                .foregroundColor(rowColor)
                .lineLimit(1)

            Spacer(minLength: 4)

            // Duration
            Text(track.formattedDuration)
                .font(WinampTheme.plFont)
                .foregroundColor(rowColor.opacity(0.9))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(rowBg)
        .contentShape(Rectangle())
    }
}

// MARK: - Bottom status bar (ADD REM SEL MISC | info + mini transport | LIST OPTS)
private struct PlaylistStatusBar: View {
    @EnvironmentObject var player: AudioPlayerManager
    @EnvironmentObject var library: MusicLibraryManager
    @Binding var selection: Set<Int>

    var body: some View {
        HStack(spacing: 4) {
            // Left group: ADD / REM / SEL / MISC
            HStack(spacing: 1) {
                PLMenuBtn(label: "ADD") {
                    Button("Add all from library") {
                        player.addToPlaylist(library.tracks)
                    }
                    if !library.tracks.isEmpty {
                        Button("Add first 10 tracks") {
                            player.addToPlaylist(Array(library.tracks.prefix(10)))
                        }
                    }
                }
                PLMenuBtn(label: "REM") {
                    Button("Remove selected") {
                        for idx in selection.sorted(by: >) {
                            player.playlist.removeTrack(at: idx)
                        }
                        selection.removeAll()
                    }
                    Button("Remove all") {
                        player.clearPlaylist()
                        selection.removeAll()
                    }
                }
                PLMenuBtn(label: "SEL") {
                    Button("Select all") {
                        selection = Set(0..<player.playlist.tracks.count)
                    }
                    Button("Select none") { selection.removeAll() }
                    Button("Invert selection") {
                        let all = Set(0..<player.playlist.tracks.count)
                        selection = all.symmetricDifference(selection)
                    }
                }
                PLMenuBtn(label: "MISC") {
                    Button("Shuffle playlist") { player.toggleShuffle() }
                    Button("Clear playlist") {
                        player.clearPlaylist()
                        selection.removeAll()
                    }
                }
            }

            Spacer(minLength: 6)

            // Center: tiny song info text
            Text(tinyInfoText)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(WinampTheme.lcdGreenDim)
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(0)

            Spacer(minLength: 4)

            // Time 0:05/0:05
            Text(timeText)
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundColor(WinampTheme.lcdGreen)

            Spacer().frame(width: 4)

            // Mini transport buttons
            HStack(spacing: 1) {
                MiniBtn(icon: "backward.end.fill") { player.previous() }
                MiniBtn(icon: "play.fill")        { player.play() }
                MiniBtn(icon: "pause.fill")       { player.pause() }
                MiniBtn(icon: "stop.fill")        { player.stop() }
                MiniBtn(icon: "forward.end.fill") { player.next() }
            }

            Spacer(minLength: 6)

            // Right: LIST OPTS
            PLMenuBtn(label: "LIST OPTS") {
                Button("Sort by title") {
                    player.playlist.tracks.sort { $0.title < $1.title }
                }
                Button("Sort by artist") {
                    player.playlist.tracks.sort { $0.artist < $1.artist }
                }
                Button("Reverse order") {
                    player.playlist.tracks.reverse()
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(WinampTheme.frameBg)
        .overlay(BevelBorder())
    }

    private var tinyInfoText: String {
        if let t = player.currentTrack {
            return "\(t.artist.uppercased()) - \(t.title.uppercased())"
        }
        let count = player.playlist.tracks.count
        return "\(count) TRACK\(count == 1 ? "" : "S")"
    }

    private var timeText: String {
        let cur = formatTime(player.currentTime)
        let dur = formatTime(player.duration)
        return "\(cur)/\(dur)"
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let total = Int(t)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Small beveled menu-button (ADD / REM / SEL / MISC / LIST OPTS)
private struct PLMenuBtn<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(WinampTheme.btnText)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .frame(minWidth: 28, minHeight: 14)
                .background(WinampTheme.btnFace)
                .overlay(BevelBorder())
        }
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

// MARK: - Mini transport button for playlist footer
private struct MiniBtn: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(WinampTheme.btnText)
                .frame(width: 14, height: 10)
                .background(WinampTheme.btnFace)
                .overlay(BevelBorder())
        }
        .buttonStyle(.plain)
    }
}
