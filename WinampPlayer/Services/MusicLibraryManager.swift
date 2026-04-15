import Foundation
import Combine

/// Scans user-selected folders (including iCloud Drive) for MP3 and WAV files.
///
/// Key insight: `NSMetadataQuery` with ubiquitous scopes only searches the app's
/// OWN iCloud container — NOT the user's general iCloud Drive. To read music from
/// iCloud Drive (or any folder), we must use `fileImporter` / document picker to
/// get a security-scoped URL, then scan with FileManager.
/// We persist the granted access via security-scoped bookmarks so the folder is
/// remembered across app launches.
class MusicLibraryManager: ObservableObject {
    // MARK: - Published State
    @Published var tracks: [Track] = []
    @Published var isScanning: Bool = false
    @Published var scanProgress: String = ""
    @Published var iCloudAvailable: Bool = false
    @Published var selectedFolderURL: URL?
    @Published var errorMessage: String?
    @Published var needsFolderSelection: Bool = true

    // Supported file extensions
    private let supportedExtensions: Set<String> = ["mp3", "wav"]

    private let fileManager = FileManager.default

    // UserDefaults key for the saved bookmark
    private let bookmarkKey = "SavedMusicFolderBookmark"

    // MARK: - Initialization

    init() {
        restoreBookmark()
    }

    /// Check if iCloud is available
    func checkiCloudAvailability() {
        iCloudAvailable = fileManager.ubiquityIdentityToken != nil
    }

    // MARK: - Bookmark Persistence

    /// Save a security-scoped bookmark so we can re-access the folder next launch
    func saveBookmark(for url: URL) {
        do {
            #if os(macOS)
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            #else
            let bookmarkData = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            #endif
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
        } catch {
            print("Failed to save bookmark: \(error)")
        }
    }

    /// Restore a previously saved bookmark on launch
    private func restoreBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            needsFolderSelection = true
            return
        }

        do {
            var isStale = false
            #if os(macOS)
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            #else
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            #endif

            if isStale {
                // Bookmark is stale — re-save if we still have access
                print("Bookmark is stale, attempting to refresh...")
                if url.startAccessingSecurityScopedResource() {
                    saveBookmark(for: url)
                    url.stopAccessingSecurityScopedResource()
                } else {
                    needsFolderSelection = true
                    return
                }
            }

            selectedFolderURL = url
            needsFolderSelection = false
        } catch {
            print("Failed to restore bookmark: \(error)")
            needsFolderSelection = true
        }
    }

    // MARK: - Scanning

    /// Start scanning — uses the saved folder, or signals that a folder is needed
    func startScanning() {
        checkiCloudAvailability()

        if let folderURL = selectedFolderURL {
            scanFolder(at: folderURL)
        } else {
            // No folder saved — tell the UI to show the folder picker
            needsFolderSelection = true
            scanProgress = "Select a music folder to get started"
        }
    }

    /// Scan a specific folder selected by the user via fileImporter
    func scanFolder(at url: URL) {
        selectedFolderURL = url
        needsFolderSelection = false
        saveBookmark(for: url)
        scanLocalFolder(url)
    }

    /// Recursively scan a folder for MP3/WAV files
    private func scanLocalFolder(_ folderURL: URL) {
        isScanning = true
        tracks = []
        scanProgress = "Scanning folder..."
        errorMessage = nil

        Task {
            var discoveredTracks: [Track] = []

            // Start security-scoped access (required for iCloud Drive / sandboxed folders)
            let didStartAccess = folderURL.startAccessingSecurityScopedResource()

            defer {
                if didStartAccess {
                    folderURL.stopAccessingSecurityScopedResource()
                }
            }

            guard let enumerator = fileManager.enumerator(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey, .nameKey, .isUbiquitousItemKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                await MainActor.run {
                    self.isScanning = false
                    self.errorMessage = "Cannot read the selected folder. Please select again."
                    self.scanProgress = "Scan failed"
                }
                return
            }

            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                guard supportedExtensions.contains(ext) else { continue }

                // For iCloud files, check if they need to be downloaded
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]) {
                    if let status = resourceValues.ubiquitousItemDownloadingStatus,
                       status != .current {
                        // File is in iCloud but not downloaded locally — trigger download
                        try? fileManager.startDownloadingUbiquitousItem(at: fileURL)
                        // Still add the track — it will play once downloaded
                    }
                }

                var track = Track(fileURL: fileURL)
                await track.loadMetadata()
                discoveredTracks.append(track)

                await MainActor.run {
                    self.scanProgress = "Found \(discoveredTracks.count) tracks..."
                }
            }

            await MainActor.run {
                self.tracks = discoveredTracks.sorted { $0.title.lowercased() < $1.title.lowercased() }
                self.isScanning = false
                if discoveredTracks.isEmpty {
                    self.scanProgress = "No MP3 or WAV files found in this folder"
                } else {
                    self.scanProgress = "Found \(discoveredTracks.count) tracks"
                }
            }
        }
    }

    // MARK: - Filtering & Search

    func searchTracks(query: String) -> [Track] {
        guard !query.isEmpty else { return tracks }
        let lowercasedQuery = query.lowercased()
        return tracks.filter {
            $0.title.lowercased().contains(lowercasedQuery) ||
            $0.artist.lowercased().contains(lowercasedQuery) ||
            $0.album.lowercased().contains(lowercasedQuery) ||
            $0.fileName.lowercased().contains(lowercasedQuery)
        }
    }

    func tracksByArtist() -> [String: [Track]] {
        Dictionary(grouping: tracks, by: { $0.artist })
    }

    func tracksByAlbum() -> [String: [Track]] {
        Dictionary(grouping: tracks, by: { $0.album })
    }

    // MARK: - Reset

    func clearSavedFolder() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        selectedFolderURL = nil
        tracks = []
        needsFolderSelection = true
        scanProgress = ""
    }
}
