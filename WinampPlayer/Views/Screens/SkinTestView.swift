import SwiftUI

/// Temporary smoke-test view for Phase 1 of the skin-based rebuild.
///
/// Open this file in Xcode and use the Canvas preview to confirm every
/// bitmap sheet from the bundled `base-2.91.wsz` loads and every sprite
/// renderer (SpriteView / BitmapFontView / NumberDisplayView) draws the
/// correct pixels. Once Phase 3 lands this file can be deleted.
struct SkinTestView: View {
    @State private var scale: CGFloat = 2

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                section("Main window background (MAIN.BMP, 275x116)") {
                    SpriteView(
                        sheet: .main,
                        rect: SpriteRect(x: 0, y: 0, width: 275, height: 116),
                        scale: scale
                    )
                }

                section("Transport buttons (CBUTTONS.BMP)") {
                    HStack(spacing: 0) {
                        SpriteView(sheet: .cbuttons, rect: Sprites.CBUTTONS.prev,  scale: scale)
                        SpriteView(sheet: .cbuttons, rect: Sprites.CBUTTONS.play,  scale: scale)
                        SpriteView(sheet: .cbuttons, rect: Sprites.CBUTTONS.pause, scale: scale)
                        SpriteView(sheet: .cbuttons, rect: Sprites.CBUTTONS.stop,  scale: scale)
                        SpriteView(sheet: .cbuttons, rect: Sprites.CBUTTONS.next,  scale: scale)
                        SpriteView(sheet: .cbuttons, rect: Sprites.CBUTTONS.eject, scale: scale)
                    }
                }

                section("Title bar (TITLEBAR.BMP) — focused / unfocused") {
                    VStack(spacing: 2) {
                        SpriteView(sheet: .titlebar, rect: Sprites.TITLEBAR.mainSelected,  scale: scale)
                        SpriteView(sheet: .titlebar, rect: Sprites.TITLEBAR.mainUnfocused, scale: scale)
                    }
                }

                section("Seek bar (POSBAR.BMP)") {
                    VStack(alignment: .leading, spacing: 2) {
                        SpriteView(sheet: .posbar, rect: Sprites.POSBAR.background, scale: scale)
                        HStack(spacing: 4) {
                            SpriteView(sheet: .posbar, rect: Sprites.POSBAR.thumb,        scale: scale)
                            SpriteView(sheet: .posbar, rect: Sprites.POSBAR.thumbPressed, scale: scale)
                        }
                    }
                }

                section("Volume / Balance (VOLUME.BMP / BALANCE.BMP)") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            SpriteView(sheet: .volume, rect: Sprites.VOLUME.background(row: 0),  scale: scale)
                            SpriteView(sheet: .volume, rect: Sprites.VOLUME.background(row: 14), scale: scale)
                            SpriteView(sheet: .volume, rect: Sprites.VOLUME.background(row: 27), scale: scale)
                        }
                        HStack(spacing: 4) {
                            SpriteView(sheet: .balance, rect: Sprites.BALANCE.background(row: 0),  scale: scale)
                            SpriteView(sheet: .balance, rect: Sprites.BALANCE.background(row: 14), scale: scale)
                            SpriteView(sheet: .balance, rect: Sprites.BALANCE.background(row: 27), scale: scale)
                        }
                    }
                }

                section("Mono/Stereo + Play/Pause indicators") {
                    HStack(spacing: 12) {
                        SpriteView(sheet: .monoster, rect: Sprites.MONOSTER.stereoActive, scale: scale)
                        SpriteView(sheet: .monoster, rect: Sprites.MONOSTER.monoActive,   scale: scale)
                        SpriteView(sheet: .playpaus, rect: Sprites.PLAYPAUS.playing,      scale: scale)
                        SpriteView(sheet: .playpaus, rect: Sprites.PLAYPAUS.paused,       scale: scale)
                        SpriteView(sheet: .playpaus, rect: Sprites.PLAYPAUS.stopped,      scale: scale)
                    }
                }

                section("Shuffle / Repeat / EQ / PL (SHUFREP.BMP)") {
                    HStack(spacing: 4) {
                        SpriteView(sheet: .shufrep, rect: Sprites.SHUFREP.shuffleOn, scale: scale)
                        SpriteView(sheet: .shufrep, rect: Sprites.SHUFREP.repeatOn,  scale: scale)
                        SpriteView(sheet: .shufrep, rect: Sprites.SHUFREP.eqOn,      scale: scale)
                        SpriteView(sheet: .shufrep, rect: Sprites.SHUFREP.plOn,      scale: scale)
                    }
                }

                section("Digit display (NUMBERS.BMP)") {
                    HStack(alignment: .center, spacing: 10) {
                        NumberDisplayView(text: " 3:14", scale: scale)
                        NumberDisplayView(text: "-0:42", scale: scale)
                        NumberDisplayView(text: "12:05", scale: scale)
                    }
                }

                section("Bitmap font (TEXT.BMP)") {
                    VStack(alignment: .leading, spacing: 4) {
                        BitmapFontView(text: "WINAMP 2.91 CLASSIC", scale: scale)
                        BitmapFontView(text: "0123456789 - [] ** hi!", scale: scale)
                    }
                }

                section("Equalizer (EQMAIN.BMP) — bg + thumbs + buttons") {
                    VStack(alignment: .leading, spacing: 4) {
                        SpriteView(sheet: .eqmain, rect: Sprites.EQMAIN.background, scale: scale)
                        HStack(spacing: 4) {
                            SpriteView(sheet: .eqmain, rect: Sprites.EQMAIN.sliderThumb, scale: scale)
                            SpriteView(sheet: .eqmain, rect: Sprites.EQMAIN.onOn,         scale: scale)
                            SpriteView(sheet: .eqmain, rect: Sprites.EQMAIN.autoOn,       scale: scale)
                            SpriteView(sheet: .eqmain, rect: Sprites.EQMAIN.presets,      scale: scale)
                        }
                    }
                }

                section("Visualizer palette (VISCOLOR.TXT)") {
                    HStack(spacing: 1) {
                        ForEach(SkinConfig.shared.visPalette.indices, id: \.self) { i in
                            Rectangle()
                                .fill(SkinConfig.shared.visPalette[i])
                                .frame(width: 10, height: 24)
                        }
                    }
                }

                section("Playlist palette (PLEDIT.TXT)") {
                    HStack(spacing: 0) {
                        swatch("Normal",      SkinConfig.shared.playlistNormal)
                        swatch("Current",     SkinConfig.shared.playlistCurrent)
                        swatch("NormalBG",    SkinConfig.shared.playlistNormalBG)
                        swatch("SelectedBG",  SkinConfig.shared.playlistSelectedBG)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.gray.opacity(0.15))
    }

    // MARK: - Header / chrome

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Skin Smoke-Test (Phase 1)")
                .font(.title2).bold()
            Text("Every preview below should render crisp pixels. Red dashed boxes = sprite failed to load.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text("Scale:")
                Stepper(value: $scale, in: 1...4, step: 1) {
                    Text(String(format: "%.0fx", scale))
                }
                .labelsHidden()
                Text(String(format: "%.0fx", scale))
            }
            Text("Bundle status: " + bundleStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var bundleStatus: String {
        let status = SkinAssets.shared.preload()
        let missing = status.filter { !$0.value }.map { $0.key.rawValue }
        if missing.isEmpty { return "all \(status.count) sheets loaded ✓" }
        return "missing: \(missing.joined(separator: ", "))"
    }

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption).bold()
                .foregroundStyle(.secondary)
            content()
                .padding(6)
                .background(Color.black.opacity(0.25))
        }
    }

    private func swatch(_ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(color)
                .frame(width: 60, height: 28)
                .overlay(Rectangle().stroke(Color.white.opacity(0.25), lineWidth: 1))
            Text(label).font(.caption2)
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    SkinTestView()
        .frame(width: 900, height: 700)
}
