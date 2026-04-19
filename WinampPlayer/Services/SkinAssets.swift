import SwiftUI
#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

/// Identifies the bitmap sheets that make up a classic Winamp 2.x skin.
/// File names on disk use uppercase .BMP suffixes to match the archive.
enum SkinSheet: String, CaseIterable {
    case main     = "MAIN"
    case cbuttons = "CBUTTONS"
    case titlebar = "TITLEBAR"
    case posbar   = "POSBAR"
    case volume   = "VOLUME"
    case balance  = "BALANCE"
    case monoster = "MONOSTER"
    case numbers  = "NUMBERS"
    case playpaus = "PLAYPAUS"
    case shufrep  = "SHUFREP"
    case eqmain   = "EQMAIN"
    case eqEx     = "EQ_EX"
    case text     = "TEXT"
    case pledit   = "PLEDIT"
    case gen      = "GEN"
    case genex    = "GENEX"
    case video    = "VIDEO"
    case mb       = "MB"
}

/// Central loader for bundled skin bitmaps.
///
/// On first access the sheet BMPs are resolved from
/// `Bundle.main/Skins/Classic/<NAME>.BMP` (folder reference) and cached
/// in-process. If a skin file is missing, accessor methods return nil so
/// call sites can fall back to placeholder rendering.
///
/// In later phases this will be swappable — loadable from any .wsz on disk.
final class SkinAssets {
    static let shared = SkinAssets()

    /// Relative path inside the bundle where the default skin lives.
    static let defaultSubdirectory = "Skins/Classic"

    private var cache: [SkinSheet: PlatformImage] = [:]
    private let lock = NSLock()

    private init() {}

    /// Returns the full source sheet image, or nil if not bundled.
    func image(for sheet: SkinSheet) -> PlatformImage? {
        lock.lock(); defer { lock.unlock() }
        if let cached = cache[sheet] { return cached }
        guard let img = loadSheetImage(named: sheet.rawValue) else { return nil }
        cache[sheet] = img
        return img
    }

    /// Pixel-size of the sheet image.
    func size(for sheet: SkinSheet) -> CGSize {
        image(for: sheet)?.size ?? .zero
    }

    /// Best-effort load — tries the default skin subdirectory first, then
    /// the bundle root, in both `.BMP` and `.bmp` casing.
    private func loadSheetImage(named base: String) -> PlatformImage? {
        let candidates = [
            (base + ".BMP", SkinAssets.defaultSubdirectory),
            (base + ".bmp", SkinAssets.defaultSubdirectory),
            (base + ".BMP", nil as String?),
            (base + ".bmp", nil as String?),
        ]
        for (name, subdir) in candidates {
            if let url = Bundle.main.url(
                forResource: name,
                withExtension: nil,
                subdirectory: subdir
            ) {
                #if os(macOS)
                if let img = NSImage(contentsOf: url) { return img }
                #else
                if let data = try? Data(contentsOf: url),
                   let img = UIImage(data: data) { return img }
                #endif
            }
        }
        return nil
    }

    /// Returns a newly cropped sub-image for the given sprite rect.
    ///
    /// Most callers should use `SpriteView` directly — this helper exists for
    /// cases that need a raw PlatformImage (e.g. NSCursor, drag proxies).
    func slice(_ sheet: SkinSheet, rect: SpriteRect) -> PlatformImage? {
        guard let src = image(for: sheet) else { return nil }
        let cgRect = CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
        #if os(macOS)
        let dest = NSImage(size: CGSize(width: rect.width, height: rect.height))
        dest.lockFocus()
        src.draw(at: .zero, from: cgRect, operation: .copy, fraction: 1.0)
        dest.unlockFocus()
        return dest
        #else
        guard let cg = src.cgImage?.cropping(to: cgRect) else { return nil }
        return UIImage(cgImage: cg, scale: src.scale, orientation: src.imageOrientation)
        #endif
    }

    /// Forces every sheet to load. Call at app start to surface missing-asset
    /// errors early instead of silently lazy-loading later.
    @discardableResult
    func preload() -> [SkinSheet: Bool] {
        var status: [SkinSheet: Bool] = [:]
        for sheet in SkinSheet.allCases {
            status[sheet] = (image(for: sheet) != nil)
        }
        return status
    }
}
