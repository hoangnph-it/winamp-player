import Foundation

/// Represents the current state of the audio player
enum PlaybackState: String {
    case stopped
    case playing
    case paused
}

/// Repeat mode options
enum RepeatMode: String {
    case off
    case all
    case one

    var next: RepeatMode {
        switch self {
        case .off: return .all
        case .all: return .one
        case .one: return .off
        }
    }

    var icon: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    var label: String {
        switch self {
        case .off: return "OFF"
        case .all: return "ALL"
        case .one: return "ONE"
        }
    }
}
