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

    // UserDefaults keys for the saved bookmark
    private let bookmarkKey = "SavedMusicFolderBookmark"
    /// Whether the saved bookmark was created with `.withSecurityScope` (true)
    /// or as a plain bookmark (false, for File Provider URLs like Google Drive).
    private let bookmarkIsScopedKey = "SavedMusicFolderBookmarkIsScoped"

    /// The folder URL we currently hold security-scoped access on.
    ///
    /// Crucial for iOS playback: when the user picks a folder via
    /// `fileImporter`, iOS grants scoped read access to that folder URL
    /// (and, transitively, its children) ONLY while we keep its scope
    /// active with `startAccessingSecurityScopedResource()`. Child URLs
    /// enumerated from the folder do not individually inherit the scope —
    /// they can only be read while the parent folder's scope is held.
    ///
    /// We therefore activate access once (on pick or on bookmark restore)
    /// and keep it alive for the entire app lifetime so that
    /// `AVAudioPlayer(contentsOf:)` can open individual track files
    /// without per-file scope juggling. Without this, iOS refuses the
    /// file read with `OSStatus -54 (permErr)`.
    private var accessedFolderURL: URL?

    /// Additional URLs picked ad-hoc from the Playlist's ADD menu
    /// (individual files or extra folders) whose security-scoped access
    /// we retain for the lifetime of this manager. Same iOS playback
    /// rationale as `accessedFolderURL`: we must hold the scope that
    /// was granted by the picker for the `AVAudioPlayer` read to succeed.
    private var extraAccessedURLs: Set<URL> = []

    // MARK: - Initialization

    init() {
        restoreBookmark()
    }

    deinit {
        releaseFolderAccess()
        for url in extraAccessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        extraAccessedURLs.removeAll()
    }

    /// Retain security-scoped access to an ad-hoc URL picked from the
    /// Playlist's ADD menu. Idempotent — safe to call multiple times
    /// with the same URL. Access stays alive until the manager is
    /// deallocated (i.e. app termination).
    func retainAccess(to url: URL) {
        if extraAccessedURLs.contains(url) { return }
        if url.startAccessingSecurityScopedResource() {
            extraAccessedURLs.insert(url)
        }
        // If start returned false (File Provider URLs) we don't insert,
        // but read access may still work through the picker's implicit
        // grant; nothing to release in that case.
    }

    // MARK: - Folder-level security-scoped access

    /// Activate and hold security-scoped access on `url`. No-op if we're
    /// already holding this exact URL.
    private func activateFolderAccess(_ url: URL) {
        if accessedFolderURL == url { return }
        releaseFolderAccess()
        if url.startAccessingSecurityScopedResource() {
            accessedFolderURL = url
        } else {
            // For File Provider URLs (iCloud Drive, Google Drive) the call
            // may return false but access may still succeed — proceed.
            accessedFolderURL = nil
        }
    }

    /// Release whatever folder scope we're currently holding.
    private func releaseFolderAccess() {
        if let url = accessedFolderURL {
            url.stopAccessingSecurityScopedResource()
            accessedFolderURL = nil
        }
    }

    /// Check if iCloud is available
    func checkiCloudAvailability() {
        iCloudAvailable = fileManager.ubiquityIdentityToken != nil
    }

    // MARK: - Bookmark Persistence

    /// Heuristic: is this URL served by a File Provider that typically refuses
    /// security-scoped bookmarks (Google Drive / Dropbox / OneDrive under
    /// `~/Library/CloudStorage/`, or iCloud Drive under `~/Library/Mobile
    /// Documents/`)?
    private func isFileProviderURL(_ url: URL) -> Bool {
        let path = url.path
        return path.contains("/Library/CloudStorage/")
            || path.contains("/Library/Mobile Documents/")
    }

    /// Save a bookmark so we can re-access the folder next launch.
    ///
    /// For regular user-selected folders we use `.withSecurityScope` (the
    /// standard sandbox pattern).
    ///
    /// For File Provider URLs (Google Drive, Dropbox, etc.) `.withSecurityScope`
    /// reliably fails with `NSCocoaErrorDomain Code=256 "Operation not
    /// permitted"` — macOS can't serialize a scoped bookmark for those paths.
    /// We fall back to a plain bookmark and note that fact so `restoreBookmark`
    /// can resolve it correctly.
    ///
    /// This method never throws — bookmark persistence is a "nice to have";
    /// if it fails, the user just has to re-pick their folder next launch.
    func saveBookmark(for url: URL) {
        #if os(macOS)
        // Ensure security-scoped access is active while we serialize the
        // bookmark. fileImporter gives implicit access to the returned URL,
        // but that access is scoped to the callback; calling start/stop
        // explicitly here keeps things deterministic.
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess { url.stopAccessingSecurityScopedResource() }
        }

        let isProvider = isFileProviderURL(url)
        let scopedOpts: URL.BookmarkCreationOptions = [.withSecurityScope]
        let plainOpts: URL.BookmarkCreationOptions = []

        // Try scoped first for regular folders; for File Provider paths,
        // skip straight to the plain-bookmark fallback.
        if !isProvider {
            if let data = try? url.bookmarkData(
                options: scopedOpts,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                UserDefaults.standard.set(data, forKey: bookmarkKey)
                UserDefaults.standard.set(true, forKey: bookmarkIsScopedKey)
                return
            }
        }

        // Fallback: plain bookmark (works for File Provider paths).
        do {
            let data = try url.bookmarkData(
                options: plainOpts,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: bookmarkKey)
            UserDefaults.standard.set(false, forKey: bookmarkIsScopedKey)
            // Plain bookmark is expected for File Provider paths — no log needed.
        } catch {
            // Both options failed — we can still use the folder for this
            // session (via startAccessingSecurityScopedResource from the
            // picker), but won't remember it across launches.
            print("⚠️ Could not persist bookmark for \(url.lastPathComponent); " +
                  "folder will need to be re-selected on next launch. Error: \(error.localizedDescription)")
        }
        #else
        do {
            let data = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: bookmarkKey)
            UserDefaults.standard.set(false, forKey: bookmarkIsScopedKey)
        } catch {
            print("⚠️ Could not persist bookmark: \(error.localizedDescription)")
        }
        #endif
    }

    /// Restore a previously saved bookmark on launch
    private func restoreBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            needsFolderSelection = true
            return
        }

        #if os(macOS)
        // Match the option set that was used when the bookmark was saved.
        let wasScoped = UserDefaults.standard.object(forKey: bookmarkIsScopedKey) as? Bool ?? true
        let resolveOpts: URL.BookmarkResolutionOptions = wasScoped ? [.withSecurityScope] : []
        #else
        let resolveOpts: URL.BookmarkResolutionOptions = []
        #endif

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: resolveOpts,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // Bookmark is stale — re-save if we still have access
                print("Bookmark is stale, attempting to refresh…")
                if url.startAccessingSecurityScopedResource() {
                    saveBookmark(for: url)
                    // Don't stop — we want to keep holding the scope.
                    accessedFolderURL = url
                } else {
                    needsFolderSelection = true
                    return
                }
            } else {
                // Acquire and hold the folder's security scope so that
                // playback of individual tracks (child URLs) succeeds
                // on iOS. See `accessedFolderURL` comment above.
                activateFolderAccess(url)
            }

            selectedFolderURL = url
            needsFolderSelection = false
        } catch {
            print("Failed to restore bookmark: \(error.localizedDescription)")
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
        // Acquire and hold the folder's security scope for the app's
        // lifetime so subsequent playback reads of individual tracks
        // (child URLs) succeed on iOS. Must happen before scanning or
        // saving the bookmark so File Provider URLs resolve correctly.
        activateFolderAccess(url)
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

            // Security-scoped access is already held by `activateFolderAccess`
            // (see caller paths) — no need to acquire/release here. That
            // scope persists for the app's lifetime so later playback of
            // individual tracks can read through it. If scope acquisition
            // failed earlier we still attempt the scan; some File Provider
            // URLs grant access without needing explicit scope activation.

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
        releaseFolderAccess()
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: bookmarkIsScopedKey)
        selectedFolderURL = nil
        tracks = []
        needsFolderSelection = true
        scanProgress = ""
    }
}
