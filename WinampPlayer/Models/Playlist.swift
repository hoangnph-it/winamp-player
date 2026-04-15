import Foundation

/// A named playlist containing tracks
class Playlist: Identifiable, ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var tracks: [Track]
    @Published var currentIndex: Int

    init(name: String, tracks: [Track] = []) {
        self.id = UUID()
        self.name = name
        self.tracks = tracks
        self.currentIndex = 0
    }

    var currentTrack: Track? {
        guard !tracks.isEmpty, currentIndex >= 0, currentIndex < tracks.count else {
            return nil
        }
        return tracks[currentIndex]
    }

    var totalDuration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }

    var formattedTotalDuration: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Playlist Operations

    func addTrack(_ track: Track) {
        tracks.append(track)
    }

    func addTracks(_ newTracks: [Track]) {
        tracks.append(contentsOf: newTracks)
    }

    func removeTrack(at index: Int) {
        guard index >= 0, index < tracks.count else { return }
        tracks.remove(at: index)
        if currentIndex >= tracks.count {
            currentIndex = max(0, tracks.count - 1)
        }
    }

    func moveTrack(from source: IndexSet, to destination: Int) {
        tracks.move(fromOffsets: source, toOffset: destination)
    }

    func clear() {
        tracks.removeAll()
        currentIndex = 0
    }

    func nextTrack(shuffle: Bool) -> Track? {
        guard !tracks.isEmpty else { return nil }

        if shuffle {
            let randomIndex = Int.random(in: 0..<tracks.count)
            currentIndex = randomIndex
        } else {
            currentIndex = (currentIndex + 1) % tracks.count
        }
        return currentTrack
    }

    func previousTrack() -> Track? {
        guard !tracks.isEmpty else { return nil }
        currentIndex = (currentIndex - 1 + tracks.count) % tracks.count
        return currentTrack
    }

    func selectTrack(at index: Int) -> Track? {
        guard index >= 0, index < tracks.count else { return nil }
        currentIndex = index
        return currentTrack
    }
}
