import SwiftUI
import UniformTypeIdentifiers

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

    // MARK: - Track list with classic Winamp right-side scrollbar
    private var trackList: some View {
        ScrollViewReader { proxy in
            HStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Identify rows by enumerated offset only — avoids a
                        // conflict between ForEach's `id:` and an explicit
                        // `.id()` modifier (which triggered a "multiple child
                        // views use the same ID" runtime warning whenever
                        // duplicate tracks appeared in the playlist).
                        ForEach(Array(player.playlist.tracks.enumerated()), id: \.offset) { idx, track in
                            PLRow(
                                track: track,
                                index: idx,
                                isCurrent: player.playlist.currentIndex == idx && player.playbackState != .stopped,
                                isPlaying: player.playlist.currentIndex == idx && player.playbackState == .playing,
                                isSelected: selection.contains(idx)
                            )
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

                // Classic Winamp right-side scrollbar (decorative thumb)
                ClassicScrollbar(
                    position: scrollPosition,
                    count: player.playlist.tracks.count
                )
            }
            .onChange(of: player.playlist.currentIndex) { newIdx in
                withAnimation { proxy.scrollTo(newIdx, anchor: .center) }
            }
        }
    }

    /// Normalized scroll position (0…1) — current track as a fraction of list.
    private var scrollPosition: Double {
        let total = max(1, player.playlist.tracks.count)
        return Double(max(0, player.playlist.currentIndex)) / Double(total)
    }
}

// MARK: - Classic Winamp right-side scrollbar (thin gray beveled thumb)
private struct ClassicScrollbar: View {
    let position: Double   // 0…1 (where the thumb sits)
    let count: Int

    var body: some View {
        GeometryReader { g in
            let h = g.size.height
            let thumbH: CGFloat = count > 0 ? max(20, h * 0.35) : h * 0.95
            let maxOffset = max(0, h - thumbH)
            let y = maxOffset * CGFloat(position)

            ZStack(alignment: .top) {
                // Dark recessed track
                Rectangle()
                    .fill(WinampTheme.frameDark)

                // Gray beveled thumb
                Rectangle()
                    .fill(WinampTheme.plScrollbar)
                    .frame(height: thumbH)
                    .overlay(BevelBorder())
                    .offset(y: y)
            }
            .overlay(
                // Left edge inner shadow
                HStack(spacing: 0) {
                    Rectangle().fill(WinampTheme.frameShadow).frame(width: 1)
                    Spacer()
                }
                .allowsHitTesting(false)
            )
        }
        .frame(width: 9)
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
        HStack(spacing: 3) {
            // Number "N." — right-aligned in a fixed column
            Text("\(index + 1).")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(rowColor)
                .frame(width: 22, alignment: .trailing)

            // Artist - Title
            Text(track.formattedTitle)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(rowColor)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            // Duration m:ss
            Text(track.formattedDuration)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(rowColor.opacity(0.9))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(rowBg)
        .contentShape(Rectangle())
    }
}

// MARK: - Bottom status bar (ADD REM SEL MISC | info + mini transport | LIST OPTS)
private struct PlaylistStatusBar: View {
    @EnvironmentObject var player: AudioPlayerManager
    @EnvironmentObject var library: MusicLibraryManager
    @Binding var selection: Set<Int>

    // Single picker driven by a mode enum.
    // (Two separate .fileImporter modifiers on the same view is a known
    // SwiftUI bug — only one ever fires. We multiplex instead.)
    private enum PickerMode { case folder, file }
    @State private var pickerMode: PickerMode = .file
    @State private var showPicker = false

    var body: some View {
        HStack(spacing: 2) {
            // Left group: ADD / REM / SEL / MISC
            HStack(spacing: 1) {
                PLMenuBtn(label: "ADD") {
                    Button("Add folder") {
                        pickerMode = .folder
                        showPicker = true
                    }
                    Button("Add file") {
                        pickerMode = .file
                        showPicker = true
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

            Spacer(minLength: 4)

            // Right group — compact: list info | mini transport | elapsed | LIST OPTS
            HStack(spacing: 4) {
                // Total list time "cur/total"
                Text(totalListTimeText)
                    .font(.system(size: 7, weight: .heavy, design: .monospaced))
                    .foregroundColor(WinampTheme.lcdGreen)
                    .padding(.horizontal, 3)
                    .frame(height: 13)
                    .background(WinampTheme.displayBg)
                    .overlay(
                        Rectangle().stroke(WinampTheme.displayBorder, lineWidth: 0.5)
                    )

                // Mini transport buttons
                HStack(spacing: 1) {
                    MiniBtn(icon: "backward.end.fill") { player.previous() }
                    MiniBtn(icon: "play.fill")        { player.play() }
                    MiniBtn(icon: "pause.fill")       { player.pause() }
                    MiniBtn(icon: "stop.fill")        { player.stop() }
                    MiniBtn(icon: "forward.end.fill") { player.next() }
                }

                // Elapsed time of current track
                Text(elapsedText)
                    .font(.system(size: 7, weight: .heavy, design: .monospaced))
                    .foregroundColor(WinampTheme.lcdGreen)
                    .padding(.horizontal, 3)
                    .frame(height: 13)
                    .background(WinampTheme.displayBg)
                    .overlay(
                        Rectangle().stroke(WinampTheme.displayBorder, lineWidth: 0.5)
                    )

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
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .background(WinampTheme.frameBg)
        .overlay(BevelBorder())
        .fileImporter(
            isPresented: $showPicker,
            allowedContentTypes: pickerMode == .folder
                ? [.folder]
                : [.mp3, .wav, .audio],
            allowsMultipleSelection: pickerMode == .file
        ) { result in
            guard case .success(let urls) = result else { return }
            switch pickerMode {
            case .folder:
                if let url = urls.first { addFolder(url) }
            case .file:
                addFiles(urls)
            }
        }
    }

    // MARK: - Folder / file import helpers

    /// Recursively scan the picked folder for MP3/WAV and append to the
    /// playlist. Runs off the main actor so we can `await` metadata loading.
    ///
    /// Feedback is surfaced via `library.scanProgress` / `library.errorMessage`
    /// so the user sees something even if the folder was empty, unreadable,
    /// or contained only cloud-only Google Drive placeholders.
    private func addFolder(_ folderURL: URL) {
        // File Provider paths (Google Drive / Dropbox / OneDrive under
        // ~/Library/CloudStorage, iCloud Drive under ~/Library/Mobile
        // Documents) don't use security-scoped bookmarks. Calling
        // startAccessing* on them returns false, which is expected — we
        // still have read access granted by the picker.
        let path = folderURL.path
        let isFileProvider =
            path.contains("/Library/CloudStorage/")
            || path.contains("/Library/Mobile Documents/")

        // Start access synchronously (in the picker callback scope) so the
        // grant from fileImporter is extended before we hop onto a Task.
        let started = folderURL.startAccessingSecurityScopedResource()

        // Show immediate feedback so user knows the scan is running.
        library.scanProgress = "Scanning \(folderURL.lastPathComponent)…"
        library.errorMessage = nil

        Task {
            defer {
                if started { folderURL.stopAccessingSecurityScopedResource() }
            }

            let fm = FileManager.default
            let supported: Set<String> = ["mp3", "wav"]

            guard let enumerator = fm.enumerator(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                await MainActor.run {
                    library.scanProgress = "Add folder failed"
                    library.errorMessage = "Cannot read '\(folderURL.lastPathComponent)'. "
                        + (isFileProvider
                           ? "Try right-clicking the folder in Finder → Make Available Offline."
                           : "Check folder permissions.")
                }
                return
            }

            var tracks: [Track] = []
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                guard supported.contains(ext) else { continue }

                // For iCloud / Drive placeholders, nudge a download so the
                // file becomes playable. Non-ubiquitous items just ignore it.
                if let rv = try? fileURL.resourceValues(
                    forKeys: [.ubiquitousItemDownloadingStatusKey]
                ), let status = rv.ubiquitousItemDownloadingStatus,
                   status != .current {
                    try? fm.startDownloadingUbiquitousItem(at: fileURL)
                }

                var track = Track(fileURL: fileURL)
                await track.loadMetadata()
                tracks.append(track)
            }

            let sorted = tracks.sorted {
                $0.title.lowercased() < $1.title.lowercased()
            }
            await MainActor.run {
                if sorted.isEmpty {
                    library.scanProgress =
                        "No MP3 or WAV files found in '\(folderURL.lastPathComponent)'"
                    if isFileProvider {
                        library.errorMessage =
                            "Google Drive folders show cloud-only placeholders. "
                            + "Right-click the folder in Finder → Make Available Offline, "
                            + "then try again."
                    }
                } else {
                    player.addToPlaylist(sorted)
                    library.scanProgress =
                        "Added \(sorted.count) track\(sorted.count == 1 ? "" : "s") "
                        + "from '\(folderURL.lastPathComponent)'"
                }
            }
        }
    }

    /// Add one or more individually-picked audio files to the playlist.
    private func addFiles(_ urls: [URL]) {
        Task {
            var tracks: [Track] = []
            for url in urls {
                let started = url.startAccessingSecurityScopedResource()
                var track = Track(fileURL: url)
                await track.loadMetadata()
                tracks.append(track)
                if started { url.stopAccessingSecurityScopedResource() }
            }
            await MainActor.run {
                player.addToPlaylist(tracks)
            }
        }
    }

    // Total list duration "currentTrackTime/totalListTime" in m:ss format
    private var totalListTimeText: String {
        let totalListSec = player.playlist.tracks.reduce(0) { $0 + $1.duration }
        let cur = formatTime(player.currentTime)
        let tot = formatTime(totalListSec)
        return "\(cur)/\(tot)"
    }

    // Elapsed time of the current track
    private var elapsedText: String {
        formatTime(player.currentTime)
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
