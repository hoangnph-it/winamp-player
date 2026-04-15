import Foundation
import AVFoundation

/// Represents a single audio track (MP3 or WAV)
struct Track: Identifiable, Hashable, Codable {
    let id: UUID
    let fileURL: URL
    let fileName: String
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var fileFormat: AudioFormat

    enum AudioFormat: String, Codable {
        case mp3
        case wav
        case unknown

        init(from extension: String) {
            switch `extension`.lowercased() {
            case "mp3": self = .mp3
            case "wav": self = .wav
            default: self = .unknown
            }
        }
    }

    init(fileURL: URL) {
        self.id = UUID()
        self.fileURL = fileURL
        self.fileName = fileURL.lastPathComponent
        self.title = fileURL.deletingPathExtension().lastPathComponent
        self.artist = "Unknown Artist"
        self.album = "Unknown Album"
        self.duration = 0
        self.fileFormat = AudioFormat(from: fileURL.pathExtension)
    }

    /// Extract metadata from the audio file
    mutating func loadMetadata() async {
        let asset = AVURLAsset(url: fileURL)

        do {
            let duration = try await asset.load(.duration)
            self.duration = CMTimeGetSeconds(duration)

            let metadata = try await asset.load(.commonMetadata)

            for item in metadata {
                guard let commonKey = item.commonKey else { continue }

                switch commonKey {
                case .commonKeyTitle:
                    if let value = try? await item.load(.stringValue) {
                        self.title = value
                    }
                case .commonKeyArtist:
                    if let value = try? await item.load(.stringValue) {
                        self.artist = value
                    }
                case .commonKeyAlbumName:
                    if let value = try? await item.load(.stringValue) {
                        self.album = value
                    }
                default:
                    break
                }
            }
        } catch {
            print("Failed to load metadata for \(fileName): \(error)")
        }
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
}

/// Formatted duration display
extension Track {
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedTitle: String {
        if artist != "Unknown Artist" {
            return "\(artist) - \(title)"
        }
        return title
    }
}
