import SwiftUI

/// Browse music library from iCloud Drive or any user-selected folder
struct LibraryBrowserView: View {
    @EnvironmentObject var playerManager: AudioPlayerManager
    @EnvironmentObject var libraryManager: MusicLibraryManager
    @State private var showFolderPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with folder picker
            HStack {
                Text("MUSIC LIBRARY")
                    .font(WinampTheme.buttonFont)
                    .foregroundColor(WinampTheme.lcdGreenDim)

                Spacer()

                // Scan status
                if libraryManager.isScanning {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                            #if os(macOS)
                            .controlSize(.small)
                            #endif
                        Text(libraryManager.scanProgress)
                            .font(WinampTheme.buttonFont)
                            .foregroundColor(WinampTheme.accentOrange)
                    }
                } else {
                    Text(libraryManager.scanProgress)
                        .font(WinampTheme.buttonFont)
                        .foregroundColor(WinampTheme.lcdGreenDim)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(WinampTheme.panelBackground)

            // Folder selection button
            Button(action: { showFolderPicker = true }) {
                HStack {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 11))
                    Text(folderDisplayName)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                }
                .font(WinampTheme.buttonFont)
                .foregroundColor(WinampTheme.buttonText)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(WinampTheme.buttonFace.opacity(0.5))
            }
            .buttonStyle(.plain)

            // Track list or empty state
            if libraryManager.needsFolderSelection || (libraryManager.tracks.isEmpty && !libraryManager.isScanning) {
                // Onboarding / empty state
                VStack(spacing: 12) {
                    Spacer()

                    Image(systemName: libraryManager.needsFolderSelection ? "icloud.and.arrow.down" : "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(WinampTheme.lcdGreenDim)

                    Text(libraryManager.needsFolderSelection
                         ? "Select your music folder"
                         : "No MP3 or WAV files found")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.lcdGreen)

                    Text(libraryManager.needsFolderSelection
                         ? "Pick a folder from iCloud Drive or your device\nthat contains MP3 or WAV files"
                         : "Try selecting a different folder")
                        .font(WinampTheme.infoFont)
                        .foregroundColor(WinampTheme.buttonText)
                        .multilineTextAlignment(.center)

                    if libraryManager.needsFolderSelection {
                        // Prominent iCloud folder button
                        Button(action: { showFolderPicker = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "icloud")
                                    .font(.system(size: 14))
                                Text("OPEN ICLOUD DRIVE")
                            }
                            .font(WinampTheme.buttonFont)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(WinampTheme.lcdGreen)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)

                        Text("Tip: In the picker, tap \"Browse\" and navigate\nto iCloud Drive to find your music")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(WinampTheme.lcdGreenDim.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    } else {
                        Button(action: { showFolderPicker = true }) {
                            HStack {
                                Image(systemName: "folder")
                                Text("SELECT DIFFERENT FOLDER")
                            }
                        }
                        .buttonStyle(WinampButtonStyle())
                        .padding(.top, 8)
                    }

                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(libraryManager.tracks.enumerated()), id: \.element.id) { index, track in
                            LibraryTrackRow(track: track, index: index)
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
                                    Button("Play Now") {
                                        playerManager.replacePlaylist(with: libraryManager.tracks, startIndex: index)
                                    }
                                }
                        }
                    }
                }
                .background(WinampTheme.displayBackground)
            }

            // Footer actions
            HStack(spacing: 6) {
                Button(action: {
                    playerManager.replacePlaylist(with: libraryManager.tracks)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                        Text("PLAY ALL")
                    }
                }
                .buttonStyle(WinampButtonStyle())
                .disabled(libraryManager.tracks.isEmpty)

                Button(action: {
                    playerManager.addToPlaylist(libraryManager.tracks)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 9))
                        Text("ENQUEUE ALL")
                    }
                }
                .buttonStyle(WinampButtonStyle())
                .disabled(libraryManager.tracks.isEmpty)

                Spacer()

                // Change folder
                Button(action: {
                    libraryManager.clearSavedFolder()
                    showFolderPicker = true
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 9))
                        Text("CHANGE")
                    }
                }
                .buttonStyle(WinampButtonStyle())

                Button(action: {
                    libraryManager.startScanning()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9))
                        Text("RESCAN")
                    }
                }
                .buttonStyle(WinampButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(WinampTheme.panelBackground)
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // Start security-scoped access for scanning
                    _ = url.startAccessingSecurityScopedResource()
                    libraryManager.scanFolder(at: url)
                }
            case .failure(let error):
                print("Folder selection failed: \(error)")
                libraryManager.errorMessage = "Could not access the selected folder."
            }
        }
    }

    private var folderDisplayName: String {
        if let url = libraryManager.selectedFolderURL {
            return url.lastPathComponent
        }
        return "No folder selected — tap to choose"
    }
}

// MARK: - Library Track Row
struct LibraryTrackRow: View {
    let track: Track
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            // File format badge
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

                Text(track.artist)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(WinampTheme.playlistTextDim)
                    .lineLimit(1)
            }

            Spacer()

            // Duration
            Text(track.formattedDuration)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(WinampTheme.playlistTextDim)

            // Add button
            Image(systemName: "plus.circle")
                .font(.system(size: 14))
                .foregroundColor(WinampTheme.lcdGreenDim)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(index % 2 == 0 ? Color.clear : WinampTheme.panelBackground.opacity(0.3))
        .contentShape(Rectangle())
    }
}
