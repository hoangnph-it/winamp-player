import SwiftUI

/// Browse music library from iCloud Drive or any user-selected folder
struct LibraryBrowserView: View {
    @EnvironmentObject var player: AudioPlayerManager
    @EnvironmentObject var library: MusicLibraryManager
    @State private var showFolderPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                // Scan status
                if library.isScanning {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.5)
                            #if os(macOS)
                            .controlSize(.small)
                            #endif
                        Text(library.scanProgress)
                            .font(WinampTheme.badgeFont)
                            .foregroundColor(WinampTheme.lcdYellow)
                    }
                } else {
                    Text(library.scanProgress)
                        .font(WinampTheme.badgeFont)
                        .foregroundColor(WinampTheme.plTextDim)
                }

                Spacer()

                // Folder picker button
                Button { showFolderPicker = true } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "folder")
                            .font(.system(size: 9))
                        Text(folderDisplayName)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(WinampButtonStyle())
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(WinampTheme.frameBg)

            // Content
            if library.needsFolderSelection || (library.tracks.isEmpty && !library.isScanning) {
                // Onboarding / empty
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: library.needsFolderSelection ? "icloud.and.arrow.down" : "music.note")
                        .font(.system(size: 30))
                        .foregroundColor(WinampTheme.lcdGreenDim)

                    Text(library.needsFolderSelection ? "Select your music folder" : "No MP3 or WAV files found")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.lcdGreen)

                    Text(library.needsFolderSelection
                         ? "Pick a folder from iCloud Drive\nor your device"
                         : "Try a different folder")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.btnText)
                        .multilineTextAlignment(.center)

                    Button { showFolderPicker = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "icloud").font(.system(size: 11))
                            Text("OPEN FOLDER")
                        }
                        .font(WinampTheme.btnFont)
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(WinampTheme.lcdGreen)
                        .cornerRadius(3)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(WinampTheme.plBg)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(library.tracks.enumerated()), id: \.element.id) { idx, track in
                            LibRow(track: track, index: idx)
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
                                    Button("Play All from Here") {
                                        player.replacePlaylist(with: library.tracks, startIndex: idx)
                                    }
                                }
                        }
                    }
                }
                .background(WinampTheme.plBg)
            }

            // Footer
            HStack(spacing: 2) {
                FBtn(label: "PLAY ALL") { player.replacePlaylist(with: library.tracks) }
                FBtn(label: "+ALL") { player.addToPlaylist(library.tracks) }
                Spacer()
                FBtn(label: "CHANGE") {
                    library.clearSavedFolder()
                    showFolderPicker = true
                }
                FBtn(label: "RESCAN") { library.startScanning() }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(WinampTheme.frameBg)
            .overlay(BevelBorder())
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                // Balance start/stop around the synchronous bookmark save
                // inside scanFolder(at:). The async scanner in scanLocalFolder
                // starts its own independent access refcount for the enumeration.
                let started = url.startAccessingSecurityScopedResource()
                defer {
                    if started { url.stopAccessingSecurityScopedResource() }
                }
                library.scanFolder(at: url)
            }
        }
    }

    private var folderDisplayName: String {
        library.selectedFolderURL?.lastPathComponent ?? "Choose…"
    }
}

// MARK: - Library row
private struct LibRow: View {
    let track: Track; let index: Int
    var body: some View {
        HStack(spacing: 4) {
            Text(track.fileFormat.rawValue.uppercased())
                .font(WinampTheme.badgeFont)
                .foregroundColor(track.fileFormat == .mp3 ? WinampTheme.lcdYellow : WinampTheme.lcdGreenDim)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(track.title)
                    .font(WinampTheme.plFont)
                    .foregroundColor(WinampTheme.plText)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(WinampTheme.plTextDim)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(track.formattedDuration)
                .font(WinampTheme.plFont)
                .foregroundColor(WinampTheme.plTextDim)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(index % 2 == 0 ? Color.clear : WinampTheme.frameDark.opacity(0.3))
        .contentShape(Rectangle())
    }
}

// MARK: - Footer button
private struct FBtn: View {
    let label: String; let action: () -> Void
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
