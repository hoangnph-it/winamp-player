import SwiftUI

/// Parsed non-bitmap configuration from the bundled skin — the `pledit.txt`
/// playlist palette and the 24-color `viscolor.txt` visualizer palette.
///
/// Both files are plaintext. We tolerate missing files and malformed lines
/// by falling back to webamp's hard-coded base-skin defaults, so the app
/// still renders correctly even with a broken or partial skin archive.
final class SkinConfig {
    static let shared = SkinConfig()

    // MARK: - Playlist (pledit.txt)
    let playlistNormal:     Color
    let playlistCurrent:    Color
    let playlistNormalBG:   Color
    let playlistSelectedBG: Color
    let playlistFont:       String

    // MARK: - Visualizer (viscolor.txt — 24 entries)
    /// Index reference (from viscolor.txt comments):
    ///   0 = background
    ///   1 = grid/dots
    ///   2..17 = analyzer gradient top→bottom
    ///   18..22 = oscilloscope colors
    ///   23 = analyzer peak dots
    let visPalette: [Color]

    private init() {
        let plEditValues = SkinConfig.parsePledit()
        playlistNormal     = plEditValues["Normal"].flatMap(SkinConfig.parseHex)
            ?? Color(red: 0, green: 1, blue: 0)
        playlistCurrent    = plEditValues["Current"].flatMap(SkinConfig.parseHex)
            ?? .white
        playlistNormalBG   = plEditValues["NormalBG"].flatMap(SkinConfig.parseHex)
            ?? .black
        playlistSelectedBG = plEditValues["SelectedBG"].flatMap(SkinConfig.parseHex)
            ?? Color(red: 0, green: 0, blue: 0.78)
        playlistFont       = plEditValues["Font"] ?? "Arial"

        let parsed = SkinConfig.parseViscolor()
        visPalette = parsed.count == 24 ? parsed : SkinConfig.fallbackVisPalette
    }

    // MARK: - File loading

    private static func loadText(_ fileName: String) -> String? {
        let candidates: [String?] = [SkinAssets.defaultSubdirectory, nil]
        for subdir in candidates {
            if let url = Bundle.main.url(
                forResource: fileName,
                withExtension: nil,
                subdirectory: subdir
            ), let s = try? String(contentsOf: url, encoding: .utf8) {
                return s
            }
        }
        return nil
    }

    // MARK: - pledit.txt parser

    /// Parses a simple INI-style key=value list. Comment lines starting
    /// with ';' or '#' and section headers in [brackets] are skipped.
    private static func parsePledit() -> [String: String] {
        var out: [String: String] = [:]
        guard let text = loadText("PLEDIT.TXT") ?? loadText("pledit.txt") else { return out }
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if line.hasPrefix(";") || line.hasPrefix("#") { continue }
            if line.hasPrefix("[") && line.hasSuffix("]") { continue }
            guard let eq = line.firstIndex(of: "=") else { continue }
            let key   = String(line[..<eq]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
            if !key.isEmpty { out[key] = value }
        }
        return out
    }

    // MARK: - viscolor.txt parser

    /// Parses 24 "R,G,B  // comment" lines. Stops (returns what it has) at
    /// the first unparseable line so a short file doesn't explode.
    private static func parseViscolor() -> [Color] {
        var out: [Color] = []
        guard let text = loadText("VISCOLOR.TXT") ?? loadText("viscolor.txt") else { return [] }
        for raw in text.components(separatedBy: .newlines) {
            let beforeComment = raw.components(separatedBy: "//").first ?? ""
            let parts = beforeComment
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            guard parts.count >= 3,
                  let r = Int(parts[0]),
                  let g = Int(parts[1]),
                  let b = Int(parts[2]) else { continue }
            out.append(Color(
                red:   Double(r) / 255.0,
                green: Double(g) / 255.0,
                blue:  Double(b) / 255.0
            ))
            if out.count == 24 { break }
        }
        return out
    }

    // MARK: - Color helpers

    /// Parses `#RRGGBB` or `RRGGBB` hex strings.
    private static func parseHex(_ hex: String) -> Color? {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        return Color(
            red:   Double((v >> 16) & 0xFF) / 255.0,
            green: Double((v >>  8) & 0xFF) / 255.0,
            blue:  Double( v        & 0xFF) / 255.0
        )
    }

    // MARK: - Fallback palette (used if viscolor.txt is missing/malformed)

    /// Webamp's base-skin fallback — matches the classic green analyzer
    /// gradient plus muted white/gray oscilloscope colors.
    private static let fallbackVisPalette: [Color] = [
        Color(r: 0,   g: 0,   b: 0),    // 0 bg
        Color(r: 24,  g: 33,  b: 41),   // 1 grid
        Color(r: 239, g: 49,  b: 16),   // 2 top of spec
        Color(r: 206, g: 41,  b: 16),
        Color(r: 214, g: 90,  b: 0),
        Color(r: 214, g: 102, b: 0),
        Color(r: 214, g: 115, b: 0),
        Color(r: 198, g: 123, b: 8),
        Color(r: 222, g: 165, b: 24),
        Color(r: 214, g: 181, b: 33),
        Color(r: 189, g: 222, b: 41),
        Color(r: 148, g: 222, b: 33),
        Color(r: 41,  g: 206, b: 16),
        Color(r: 50,  g: 190, b: 16),
        Color(r: 57,  g: 181, b: 16),
        Color(r: 49,  g: 156, b: 8),
        Color(r: 41,  g: 148, b: 0),
        Color(r: 24,  g: 132, b: 8),    // 17 bottom of spec
        Color(r: 255, g: 255, b: 255),  // 18 osc 1
        Color(r: 214, g: 214, b: 222),
        Color(r: 181, g: 189, b: 189),
        Color(r: 160, g: 170, b: 175),
        Color(r: 148, g: 156, b: 165),
        Color(r: 150, g: 150, b: 150)   // 23 analyzer peak
    ]
}

// MARK: - Color shorthand
private extension Color {
    /// Build a Color from 0-255 RGB ints to keep the fallback table readable.
    init(r: Int, g: Int, b: Int) {
        self.init(
            red:   Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue:  Double(b) / 255.0
        )
    }
}
