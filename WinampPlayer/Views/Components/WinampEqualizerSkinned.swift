import SwiftUI

/// Phase-4 pixel-accurate rebuild of the Winamp 2.x equalizer window, drawn
/// from the real `EQMAIN.BMP` skin sheet plus its button / slider sprites.
///
/// Canvas is a fixed 275×116 at 1x (matches `WinampWindowKind.equalizer`).
/// The base background sprite (`Sprites.EQMAIN.background`) contains every
/// baked-in decoration — the dB-scale labels, the slider-track columns, the
/// band-frequency numbers, and the dotted graph grid. All we do on top is:
///   • overlay the title bar (`titleSelected`),
///   • overlay the ON / AUTO toggles and PRESETS dropdown,
///   • place the 11 slider thumbs (1 preamp + 10 bands),
///   • stroke a green EQ curve across the small graph preview.
///
/// Layout follows the original Nullsoft spec (cross-checked against webamp's
/// `EQ_MAIN_WINDOW_POSITIONS`):
///
///   ┌──────────────── 275 × 14 title bar ────────────────┐
///   │               W I N A M P  E Q U A L I Z E R        │  y=0..13
///   ├─────────────────────────────────────────────────────┤
///   │ [ON][AUTO]   ┌─curve preview─┐          [PRESETS]   │  y=17..29
///   │              │(113 × 19)      │                      │
///   │              └────────────────┘                      │
///   │                                                     │
///   │  |P|     |60|170|310|600|1K|3K|6K|12K|14K|16K|      │  y=38..100
///   │  |.|     |. |.  |.  |.  |. |. |. |.  |.  |.  |      │   11 thumbs
///   └─────────────────────────────────────────────────────┘
struct WinampEqualizerSkinned: View {
    @Binding var eqEnabled: Bool
    @Binding var autoEQ: Bool
    @Binding var preamp: Double
    @Binding var bands: [Double]
    let onPresetApply: (EQPresets.Preset) -> Void

    /// Integer pixel-doubling factor. 1 = authentic 1x.
    var scale: CGFloat = 1

    // Canvas dimensions at 1x.
    private let canvasWidth: CGFloat = 275
    private let canvasHeight: CGFloat = 116

    // Slider layout constants.
    private let sliderTrackHeight: CGFloat = 63
    private let thumbWidth: CGFloat = 11
    private let thumbHeight: CGFloat = 11
    private let preampX: CGFloat = 21
    private let firstBandX: CGFloat = 78
    private let bandSpacing: CGFloat = 18
    private let sliderY: CGFloat = 38

    var body: some View {
        ZStack(alignment: .topLeading) {
            // ── Base chrome ──
            SpriteView(
                sheet: .eqmain,
                rect: Sprites.EQMAIN.background,
                scale: scale
            )
            .allowsHitTesting(false)

            // ── Title bar overlay ──
            SkinnedEQTitleBar(scale: scale)
                .frame(width: 275 * scale, height: 14 * scale)

            // ── Controls row ──

            // ON button (26×12 at x=14, y=18)
            SpriteToggle(
                sheet: .eqmain,
                offNormal:  Sprites.EQMAIN.onOff,
                offPressed: Sprites.EQMAIN.onOffPressed,
                onNormal:   Sprites.EQMAIN.onOn,
                onPressed:  Sprites.EQMAIN.onOnPressed,
                isOn: eqEnabled,
                scale: scale,
                action: { eqEnabled.toggle() }
            )
            .offset(x: 14 * scale, y: 18 * scale)

            // AUTO button (32×12 at x=40, y=18)
            SpriteToggle(
                sheet: .eqmain,
                offNormal:  Sprites.EQMAIN.autoOff,
                offPressed: Sprites.EQMAIN.autoOffPressed,
                onNormal:   Sprites.EQMAIN.autoOn,
                onPressed:  Sprites.EQMAIN.autoOnPressed,
                isOn: autoEQ,
                scale: scale,
                action: { autoEQ.toggle() }
            )
            .offset(x: 40 * scale, y: 18 * scale)

            // Graph preview (113×19 at x=86, y=17). The EQMAIN background
            // already has the dotted grid — we stroke a live curve on top.
            EQGraphCurve(preamp: preamp, bands: bands, scale: scale)
                .frame(width: 113 * scale, height: 19 * scale)
                .offset(x: 86 * scale, y: 17 * scale)
                .allowsHitTesting(false)

            // PRESETS dropdown button (44×12 at x=217, y=18)
            EQPresetsDropdown(
                onPresetApply: onPresetApply,
                scale: scale
            )
            .offset(x: 217 * scale, y: 18 * scale)

            // ── Sliders ──

            // Preamp (column at x=21). Visually identical to band sliders.
            EQBandSlider(
                value: $preamp,
                scale: scale
            )
            .offset(x: preampX * scale, y: sliderY * scale)

            // 10 band sliders, starting at x=78 with 18-px spacing.
            ForEach(0..<10, id: \.self) { i in
                EQBandSlider(
                    value: $bands[i],
                    scale: scale
                )
                .offset(
                    x: (firstBandX + CGFloat(i) * bandSpacing) * scale,
                    y: sliderY * scale
                )
            }
        }
        .frame(width: canvasWidth * scale, height: canvasHeight * scale, alignment: .topLeading)
    }
}

// MARK: - EQ title bar

/// 275×14 equalizer title bar. Uses `Sprites.EQMAIN.titleSelected` as the
/// background and reserves the central region for `WindowDragArea` so the
/// window can be moved. Minimize / shade / close hotspots sit at the same
/// x-offsets as the main window (TITLEBAR.BMP sprites work here too — they
/// live in a different sheet but the same pixel dimensions).
private struct SkinnedEQTitleBar: View {
    var scale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            SpriteView(sheet: .eqmain, rect: Sprites.EQMAIN.titleSelected, scale: scale)
                .allowsHitTesting(false)

            #if os(macOS)
            HStack(spacing: 0) {
                Color.clear.frame(width: 10 * scale, height: 14 * scale).allowsHitTesting(false)
                WindowDragArea()
                    .frame(height: 14 * scale)
                Color.clear.frame(width: 55 * scale, height: 14 * scale).allowsHitTesting(false)
            }
            .frame(width: 275 * scale, height: 14 * scale)
            #endif

            // Minimize / shade / close window-control hotspots.
            // The TITLEBAR.BMP buttons (9×9) are the same sprites Winamp
            // classic layers on top of the equalizer title — their hotspot
            // positions match the main window exactly.
            SpriteButton(
                sheet: .titlebar,
                normal: Sprites.TITLEBAR.minimize,
                pressed: Sprites.TITLEBAR.minimizePressed,
                scale: scale,
                action: {
                    #if os(macOS)
                    NSApp.keyWindow?.miniaturize(nil)
                    #endif
                }
            )
            .offset(x: 244 * scale, y: 3 * scale)

            SpriteButton(
                sheet: .titlebar,
                normal: Sprites.TITLEBAR.shade,
                pressed: Sprites.TITLEBAR.shadePressed,
                scale: scale,
                action: {
                    #if os(macOS)
                    if let del = NSApp.delegate as? WinampAppDelegate {
                        del.coordinator.controller(for: .equalizer)?.toggleShade()
                    }
                    #endif
                }
            )
            .offset(x: 254 * scale, y: 3 * scale)

            SpriteButton(
                sheet: .titlebar,
                normal: Sprites.TITLEBAR.close,
                pressed: Sprites.TITLEBAR.closePressed,
                scale: scale,
                action: {
                    #if os(macOS)
                    if let del = NSApp.delegate as? WinampAppDelegate {
                        del.coordinator.controller(for: .equalizer)?.hide()
                    } else {
                        NSApp.keyWindow?.performClose(nil)
                    }
                    #endif
                }
            )
            .offset(x: 264 * scale, y: 3 * scale)
        }
        .frame(width: 275 * scale, height: 14 * scale, alignment: .topLeading)
    }
}

// MARK: - Vertical EQ band slider

/// One vertical EQ slider — places the 11×11 `sliderThumb` sprite at the
/// correct y inside the baked-in 14×63 track drawn by the EQMAIN background.
///
///   value = 1.0 → thumb at top    (y offset = 0)
///   value = 0.0 → thumb at bottom (y offset = 63 - 11 = 52)
///   value = 0.5 → thumb at center (y offset ≈ 26)
///
/// Drag gesture updates the binding live; while held down, the pressed
/// thumb variant is shown.
struct EQBandSlider: View {
    @Binding var value: Double
    var scale: CGFloat = 1

    private let trackHeight: CGFloat = 63
    private let thumbWidth: CGFloat = 11
    private let thumbHeight: CGFloat = 11
    /// 14-wide track in EQMAIN background; the thumb is 11, so center it.
    private let thumbXOffset: CGFloat = 2

    @State private var isDragging: Bool = false

    var body: some View {
        let clamped = max(0, min(1, value))
        let travel = max(0, trackHeight - thumbHeight)
        let thumbY = travel * (1 - CGFloat(clamped))

        ZStack(alignment: .topLeading) {
            // Transparent hit-target frame covering the full slider column.
            Color.clear
                .frame(width: 14 * scale, height: trackHeight * scale)
                .contentShape(Rectangle())

            // Thumb sprite — pressed variant while dragging.
            SpriteView(
                sheet: .eqmain,
                rect: isDragging
                    ? Sprites.EQMAIN.sliderThumbPressed
                    : Sprites.EQMAIN.sliderThumb,
                scale: scale
            )
            .offset(x: thumbXOffset * scale, y: thumbY * scale)
            .allowsHitTesting(false)
        }
        .frame(width: 14 * scale, height: trackHeight * scale, alignment: .topLeading)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    isDragging = true
                    // Anchor the thumb to the cursor — center the thumb under
                    // the pointer by subtracting half the thumb height.
                    let rawY = g.location.y / scale - thumbHeight / 2
                    let bounded = max(0, min(travel, rawY))
                    let newValue = travel > 0
                        ? Double(1 - bounded / travel)
                        : 0.5
                    value = newValue
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}

// MARK: - Graph preview curve

/// Draws a green polyline across the 113×19 graph area showing the current
/// curve of the 10 band values. Horizontal position of each band matches
/// the preview's baked-in background layout (11 evenly-spaced slots across
/// 113 px). The preamp value is drawn as a horizontal reference line.
private struct EQGraphCurve: View {
    let preamp: Double
    let bands: [Double]
    var scale: CGFloat = 1

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let count = bands.count
            // Evenly spread the 10 bands across the graph width.
            let stepX = count > 1 ? w / CGFloat(count - 1) : 0

            // Preamp horizontal reference line.
            let preampY = h * CGFloat(1 - preamp)
            Path { p in
                p.move(to: CGPoint(x: 0, y: preampY))
                p.addLine(to: CGPoint(x: w, y: preampY))
            }
            .stroke(WinampTheme.lcdGreenFaint, lineWidth: max(0.5, scale * 0.5))

            // Smoothed band curve.
            Path { p in
                for i in 0..<count {
                    let x = CGFloat(i) * stepX
                    let y = h * CGFloat(1 - bands[i])
                    if i == 0 {
                        p.move(to: CGPoint(x: x, y: y))
                    } else {
                        let prevX = CGFloat(i - 1) * stepX
                        let prevY = h * CGFloat(1 - bands[i - 1])
                        let midX = (prevX + x) / 2
                        p.addQuadCurve(
                            to: CGPoint(x: x, y: y),
                            control: CGPoint(x: midX, y: (prevY + y) / 2)
                        )
                    }
                }
            }
            .stroke(WinampTheme.lcdGreen, lineWidth: max(1, scale))
        }
    }
}

// MARK: - Presets dropdown

/// Sprite-driven PRESETS button. Uses the `presets` / `presetsPressed`
/// sprites from EQMAIN.BMP as the Menu's label so the classic look carries
/// into the native macOS popup.
private struct EQPresetsDropdown: View {
    let onPresetApply: (EQPresets.Preset) -> Void
    var scale: CGFloat = 1

    var body: some View {
        Menu {
            ForEach(EQPresets.all, id: \.name) { preset in
                Button(preset.name) { onPresetApply(preset) }
            }
        } label: {
            SpriteView(
                sheet: .eqmain,
                rect: Sprites.EQMAIN.presets,
                scale: scale
            )
            .frame(width: 44 * scale, height: 12 * scale)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 44 * scale, height: 12 * scale)
        .fixedSize()
    }
}
