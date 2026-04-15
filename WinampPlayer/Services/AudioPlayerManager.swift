import Foundation
import AVFoundation
import Combine
import SwiftUI

/// Core audio player manager using AVFoundation
/// Supports MP3 and WAV playback with full transport controls
class AudioPlayerManager: ObservableObject {
    // MARK: - Published State
    @Published var playbackState: PlaybackState = .stopped
    @Published var currentTrack: Track?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.75
    @Published var isShuffleEnabled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var audioLevels: [Float] = Array(repeating: 0, count: 20)
    @Published var playlist: Playlist = Playlist(name: "Now Playing")
    @Published var bitrate: Int = 0
    @Published var sampleRate: Int = 0

    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var levelTimer: Timer?
    /// The URL we currently hold a security-scoped access on (must be released on stop/next)
    private var accessedURL: URL?

    // MARK: - Initialization
    init() {
        #if os(iOS)
        setupAudioSession()
        #endif
    }

    #if os(iOS)
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    #endif

    // MARK: - Playback Controls

    func play(track: Track? = nil) {
        if let track = track {
            loadAndPlay(track)
        } else if let currentTrack = currentTrack, playbackState == .paused {
            audioPlayer?.play()
            playbackState = .playing
            startTimers()
        } else if let firstTrack = playlist.currentTrack {
            loadAndPlay(firstTrack)
        }
    }

    func pause() {
        audioPlayer?.pause()
        playbackState = .paused
        stopTimers()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        audioPlayer = nil
        currentTime = 0
        playbackState = .stopped
        audioLevels = Array(repeating: 0, count: 20)
        stopTimers()
        releaseSecurityAccess()
    }

    func togglePlayPause() {
        switch playbackState {
        case .playing:
            pause()
        case .paused:
            play()
        case .stopped:
            play()
        }
    }

    func next() {
        guard let nextTrack = playlist.nextTrack(shuffle: isShuffleEnabled) else { return }
        loadAndPlay(nextTrack)
    }

    func previous() {
        // If more than 3 seconds in, restart current track
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        guard let prevTrack = playlist.previousTrack() else { return }
        loadAndPlay(prevTrack)
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }

    func seekToPercentage(_ percentage: Double) {
        let targetTime = duration * percentage
        seek(to: targetTime)
    }

    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        audioPlayer?.volume = volume
    }

    func toggleShuffle() {
        isShuffleEnabled.toggle()
    }

    func cycleRepeatMode() {
        repeatMode = repeatMode.next
    }

    // MARK: - Playlist Operations

    func playTrackAtIndex(_ index: Int) {
        guard let track = playlist.selectTrack(at: index) else { return }
        loadAndPlay(track)
    }

    func addToPlaylist(_ tracks: [Track]) {
        playlist.addTracks(tracks)
        if currentTrack == nil, let first = playlist.currentTrack {
            currentTrack = first
        }
    }

    func replacePlaylist(with tracks: [Track], startIndex: Int = 0) {
        playlist.clear()
        playlist.addTracks(tracks)
        if let track = playlist.selectTrack(at: startIndex) {
            loadAndPlay(track)
        }
    }

    func clearPlaylist() {
        stop()
        playlist.clear()
        currentTrack = nil
    }

    // MARK: - Private Methods

    private func loadAndPlay(_ track: Track) {
        stop()  // also releases any previous security-scoped access

        do {
            // Start security-scoped access and KEEP it alive while playing.
            // AVAudioPlayer reads from the file throughout playback, so we
            // must not call stopAccessingSecurityScopedResource() until we
            // stop or switch tracks.
            let didStartAccess = track.fileURL.startAccessingSecurityScopedResource()
            if didStartAccess {
                accessedURL = track.fileURL
            }

            audioPlayer = try AVAudioPlayer(contentsOf: track.fileURL)
            audioPlayer?.delegate = AudioPlayerDelegateHandler.shared
            audioPlayer?.volume = volume
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.prepareToPlay()

            // Extract audio info
            if let settings = audioPlayer?.settings {
                sampleRate = Int(settings[AVSampleRateKey] as? Double ?? 0)
            }
            duration = audioPlayer?.duration ?? 0
            currentTime = 0

            // Update track with actual duration
            var updatedTrack = track
            updatedTrack.duration = duration
            currentTrack = updatedTrack

            audioPlayer?.play()
            playbackState = .playing
            startTimers()

            // Set up completion handler
            AudioPlayerDelegateHandler.shared.onFinish = { [weak self] in
                self?.handleTrackFinished()
            }
        } catch {
            print("Failed to play track: \(error.localizedDescription)")
            // Release access if we failed to play
            releaseSecurityAccess()
            playbackState = .stopped
        }
    }

    /// Release the security-scoped resource we're currently holding
    private func releaseSecurityAccess() {
        if let url = accessedURL {
            url.stopAccessingSecurityScopedResource()
            accessedURL = nil
        }
    }

    private func handleTrackFinished() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch self.repeatMode {
            case .one:
                self.seek(to: 0)
                self.audioPlayer?.play()
            case .all:
                self.next()
            case .off:
                if self.playlist.currentIndex < self.playlist.tracks.count - 1 {
                    self.next()
                } else {
                    self.stop()
                }
            }
        }
    }

    private func startTimers() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            DispatchQueue.main.async {
                self.currentTime = player.currentTime
            }
        }

        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            player.updateMeters()

            DispatchQueue.main.async {
                var levels: [Float] = []
                let channelCount = max(1, player.numberOfChannels)
                for i in 0..<20 {
                    let channel = i % channelCount
                    let power = player.averagePower(forChannel: channel)
                    // Normalize from dB (-160...0) to 0...1 with some variation
                    let normalizedBase = max(0, (power + 50) / 50)
                    let variation = Float.random(in: -0.1...0.1)
                    let level = max(0, min(1, normalizedBase + variation))
                    levels.append(level)
                }
                self.audioLevels = levels
            }
        }
    }

    private func stopTimers() {
        timer?.invalidate()
        timer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }
}

// MARK: - AVAudioPlayer Delegate Handler
class AudioPlayerDelegateHandler: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerDelegateHandler()
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            onFinish?()
        }
    }
}
