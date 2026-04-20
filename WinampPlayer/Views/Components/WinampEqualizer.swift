import SwiftUI

/// Classic Winamp Equalizer panel — Phase 4 rebuild on top of the real
/// `EQMAIN.BMP` skin sheet.
///
/// The visual composition is implemented in `WinampEqualizerSkinned.swift`.
/// This wrapper keeps the legacy `WinampEqualizer` type name so the window
/// cluster built by `WinampAppDelegate` (and the iOS / preview paths in
/// `WinampLayout`) resolves without changes, and it owns the `@State` that
/// backs the eleven sliders + two toggles.
struct WinampEqualizer: View {
    @State private var eqEnabled: Bool = true
    @State private var autoEQ: Bool = false
    @State private var preamp: Double = 0.5
    @State private var bands: [Double] = Array(repeating: 0.5, count: 10)

    var body: some View {
        WinampEqualizerSkinned(
            eqEnabled: $eqEnabled,
            autoEQ: $autoEQ,
            preamp: $preamp,
            bands: $bands,
            onPresetApply: applyPreset
        )
    }

    // MARK: - Preset handling

    private func applyPreset(_ preset: EQPresets.Preset) {
        withAnimation(.easeInOut(duration: 0.15)) {
            preamp = preset.preamp
            bands = preset.bands
        }
    }
}

// MARK: - Classic Winamp EQ presets
///
/// Values are normalized 0…1 (0.5 = 0 dB center, 1.0 = +20 dB,
/// 0.0 = -20 dB). These match the original Winamp 2.x default presets.
enum EQPresets {
    struct Preset {
        let name: String
        let preamp: Double
        let bands: [Double]   // 10 values — 70 Hz → 16 kHz
    }

    static let all: [Preset] = [
        Preset(name: "Flat",
               preamp: 0.50,
               bands: [0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50]),
        Preset(name: "Rock",
               preamp: 0.55,
               bands: [0.72, 0.65, 0.58, 0.45, 0.40, 0.48, 0.62, 0.70, 0.72, 0.70]),
        Preset(name: "Pop",
               preamp: 0.52,
               bands: [0.42, 0.50, 0.60, 0.68, 0.70, 0.62, 0.50, 0.42, 0.40, 0.40]),
        Preset(name: "Classical",
               preamp: 0.50,
               bands: [0.55, 0.55, 0.52, 0.50, 0.50, 0.50, 0.42, 0.42, 0.42, 0.40]),
        Preset(name: "Jazz",
               preamp: 0.52,
               bands: [0.58, 0.55, 0.52, 0.55, 0.48, 0.48, 0.50, 0.52, 0.58, 0.60]),
        Preset(name: "Dance",
               preamp: 0.55,
               bands: [0.75, 0.68, 0.58, 0.50, 0.48, 0.40, 0.40, 0.55, 0.65, 0.70]),
        Preset(name: "Techno",
               preamp: 0.55,
               bands: [0.70, 0.65, 0.52, 0.42, 0.45, 0.55, 0.68, 0.72, 0.70, 0.68]),
        Preset(name: "Full Bass",
               preamp: 0.55,
               bands: [0.78, 0.75, 0.70, 0.60, 0.50, 0.40, 0.35, 0.32, 0.30, 0.30]),
        Preset(name: "Full Treble",
               preamp: 0.52,
               bands: [0.30, 0.30, 0.32, 0.40, 0.50, 0.62, 0.75, 0.82, 0.85, 0.85]),
        Preset(name: "Full Bass & Treble",
               preamp: 0.55,
               bands: [0.72, 0.68, 0.55, 0.40, 0.42, 0.50, 0.65, 0.78, 0.82, 0.82]),
        Preset(name: "Live",
               preamp: 0.52,
               bands: [0.40, 0.52, 0.58, 0.62, 0.62, 0.62, 0.58, 0.55, 0.55, 0.52]),
        Preset(name: "Party",
               preamp: 0.55,
               bands: [0.68, 0.68, 0.52, 0.50, 0.50, 0.50, 0.50, 0.52, 0.68, 0.68]),
        Preset(name: "Soft",
               preamp: 0.52,
               bands: [0.60, 0.52, 0.45, 0.42, 0.48, 0.58, 0.68, 0.70, 0.72, 0.75]),
        Preset(name: "Ska",
               preamp: 0.52,
               bands: [0.38, 0.32, 0.35, 0.45, 0.55, 0.58, 0.65, 0.68, 0.70, 0.68]),
        Preset(name: "Reggae",
               preamp: 0.50,
               bands: [0.50, 0.50, 0.50, 0.38, 0.50, 0.65, 0.65, 0.50, 0.50, 0.50]),
    ]
}
