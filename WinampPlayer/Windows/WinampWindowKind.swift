import CoreGraphics

/// Identifies one of Winamp's three classic top-level windows.
///
/// Coordinates, snap tolerance, and shade height are kept here as the
/// single source of truth so `WindowCoordinator`, `WinampWindowController`,
/// and the content views never disagree about dimensions.
///
/// All pixel values are at 1x; the user's preferred "doublesize" is applied
/// at the `NSWindow` level by multiplying content size by the scale factor.
enum WinampWindowKind: String, CaseIterable, Codable {
    case main       // transport + display + seek + viz (275x116)
    case equalizer  // eqmain.bmp                       (275x116)
    case playlist   // pledit.bmp                       (275x232 default)
    case library    // extra window for our music library (resizable)

    /// Unique NSWindow identifier — used by NSWindow.restorationClass and
    /// by the coordinator's `save(layout:)` / `load(layout:)` dictionary.
    var identifier: String { "winamp.\(rawValue)" }

    /// Native 1x content size of the window when fully expanded.
    var defaultContentSize: CGSize {
        switch self {
        case .main:      return CGSize(width: 275, height: 116)
        case .equalizer: return CGSize(width: 275, height: 116)
        case .playlist:  return CGSize(width: 275, height: 232)
        case .library:   return CGSize(width: 520, height: 420)
        }
    }

    /// Width allowed to resize. Only playlist is resizable classically
    /// (in 25-pixel horizontal chunks, 29-pixel vertical chunks — enforced
    /// at resize time by the controller).
    var isHorizontallyResizable: Bool {
        switch self {
        case .playlist, .library: return true
        default:                  return false
        }
    }

    /// Only playlist/library resize vertically.
    var isVerticallyResizable: Bool {
        switch self {
        case .playlist, .library: return true
        default:                  return false
        }
    }

    /// Classic Winamp playlist resizes in 25-px horizontal × 29-px vertical
    /// chunks so the 9-slice seams stay on exact pixel boundaries.
    var resizeIncrement: CGSize {
        switch self {
        case .playlist: return CGSize(width: 25, height: 29)
        default:        return CGSize(width: 1,  height: 1)
        }
    }

    /// Height when shaded. Only main/eq/playlist support shade mode;
    /// library stays normal.
    var shadedHeight: CGFloat {
        switch self {
        case .main:      return 14
        case .equalizer: return 14
        case .playlist:  return 14
        case .library:   return defaultContentSize.height
        }
    }

    var supportsShade: Bool {
        switch self {
        case .library: return false
        default:       return true
        }
    }

    /// Z-order / startup order. Main opens first and always renders
    /// topmost when the cluster is focused.
    var stackingOrder: Int {
        switch self {
        case .main:      return 0
        case .equalizer: return 1
        case .playlist:  return 2
        case .library:   return 3
        }
    }
}

/// Pixel snap tolerance matching classic Winamp (and webamp).
/// Two windows "snap" when any of their edges are within this distance.
enum WindowSnap {
    /// Maximum distance (in points/pixels at 1x) at which a window edge
    /// aligns automatically to a neighboring window's edge.
    static let distance: CGFloat = 15
}

/// Default opening rectangle for each window, applied the first time the
/// app runs before any layout has been persisted. Coordinates are in AppKit
/// (origin bottom-left) screen space; the coordinator re-anchors them to
/// the main screen's visible frame at load time.
enum WinampWindowDefaults {
    /// Relative top-left offset inside the main screen's visible frame.
    /// The coordinator converts these to AppKit bottom-left origins.
    static func topLeftOffset(for kind: WinampWindowKind) -> CGPoint {
        switch kind {
        case .main:      return CGPoint(x: 40,  y: 40)
        case .equalizer: return CGPoint(x: 40,  y: 156)    // docked under main
        case .playlist:  return CGPoint(x: 40,  y: 272)    // docked under eq
        case .library:   return CGPoint(x: 340, y: 40)
        }
    }
}
