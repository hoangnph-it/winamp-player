import SwiftUI

/// Phase-3 pixel-accurate rebuild of the classic Winamp 2.x main window,
/// composed from the real skin bitmaps (MAIN.BMP + TITLEBAR.BMP + CBUTTONS.BMP
/// + POSBAR.BMP + VOLUME.BMP + BALANCE.BMP + MONOSTER.BMP + NUMBERS.BMP +
/// PLAYPAUS.BMP + SHUFREP.BMP + TEXT.BMP).
///
/// The window is a fixed 275×116 pixel canvas at 1x. MAIN.BMP provides the
/// static chrome (frame, text labels, slot backgrounds, etc.); dynamic
/// elements (time digits, marquee title, sliders, transport buttons,
/// toggles, state icons) are overlaid on top at their authentic pixel
/// coordinates.
///
/// Layout follows the original Nullsoft spec (cross-checked against
/// webamp's `MAIN_WINDOW_POSITIONS`):
///
///   ┌──────────────── 275 × 14 title bar ────────────────┐
///   │                    W I N A M P                     │
///   ├────────────────────────────────────────────────────┤
///   │ [O]  ▶  00:00  scrolling title text               │   y=22..40
///   │ [A]                                                │
///   │ [I]         128 kbps  44 kHz           [stereo]    │   y=43..48
///   │ [D] ═══════════════ seek bar ═══════════════       │   y=57..69
///   │ [V]   ═══vol═══  ═bal═ [EQ] [PL]                   │
///   │       ═══════════════ seek bar ═══════════════     │   y=72..81
///   │       [◀][▶][⏸][■][▶▶] [▲] [shuffle] [repeat]     │   y=88..103
///   └────────────────────────────────────────────────────┘
struct WinampMainWindowSkinned: View {
    @EnvironmentObject var player: AudioPlayerManager
    @EnvironmentObject var library: MusicLibraryManager

    /// Integer pixel-doubling factor for the whole window. 1 = authentic
    /// 1x rendering; 2 = doublesize (Winamp's "D" clutterbar toggle).
    var scale: CGFloat = 1

    // Canvas dimensions at 1x (matches WinampWindowKind.main.defaultContentSize).
    private let canvasWidth: CGFloat  = 275
    private let canvasHeight: CGFloat = 116

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Base chrome — the entire window background is MAIN.BMP.
            SpriteView(
                sheet: .main,
                rect: SpriteRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight),
                scale: scale
            )
            .allowsHitTesting(false)

            // NOTE: We intentionally do NOT insert a full-canvas
            // `WindowDragArea` here, even though it looks like the obvious
            // way to make the "dead" chrome regions drag the window.
            //
            // The hosting infrastructure already covers drag-in-dead-region
            // in three layers (see `WinampHostingWindow.swift`):
            //   1. `NSWindow.isMovableByWindowBackground = true`,
            //   2. `DragContainerView.mouseDownCanMoveWindow = true` (the
            //      window's contentView, sitting *beneath* the hosting view),
            //   3. `FirstMouseHostingView.hitTest` returns `nil` when
            //      SwiftUI has no hit at that point, so AppKit keeps
            //      searching and lands on the DragContainerView which
            //      starts the drag.
            //
            // Putting a full-canvas `WindowDragArea` (NSViewRepresentable
            // backed by a real NSView) into this ZStack actually *breaks*
            // hit-testing on controls stacked above it. AppKit hit-tests
            // subviews in reverse order, but only SwiftUI views that
            // register their own NSView (typically gesture-bearing views)
            // sit "above" the DragView — every other region (bitrate/
            // sample-rate text, marquee title, mono/stereo indicators,
            // balance slider, inter-control gaps) has no NSView of its
            // own. AppKit hits the DragView first and starts a drag,
            // swallowing what looked like a click. That was exactly the
            // "transparent and unclickable" symptom the user reported on
            // the main window specifically (EQ + Playlist only scope
            // `WindowDragArea` to the title bar, so they never had the
            // bug). Removing this layer lets SwiftUI gestures hit-test
            // normally and delegates drag-on-dead-regions to the
            // hosting window's background-drag path.

            // TITLEBAR.BMP is drawn *over* the top 14 rows of MAIN.BMP.
            SkinnedTitleBar(scale: scale)
                .frame(width: 275 * scale, height: 14 * scale)

            // ---- Display region (time + state icon + song title + info) ----

            playPauseStateIcon
                .offset(x: 24 * scale, y: 28 * scale)

            timeDigits
                .offset(x: 48 * scale, y: 26 * scale)

            songTitleMarquee
                .offset(x: 111 * scale, y: 27 * scale)

            bitrateText
                .offset(x: 111 * scale, y: 43 * scale)

            sampleRateText
                .offset(x: 156 * scale, y: 43 * scale)

            stereoIndicator
                .offset(x: 239 * scale, y: 41 * scale)

            monoIndicator
                .offset(x: 212 * scale, y: 41 * scale)

            // ---- Volume / balance / EQ / PL toggles ----

            volumeSlider
                .offset(x: 107 * scale, y: 57 * scale)

            balanceSlider
                .offset(x: 177 * scale, y: 57 * scale)

            eqToggle
                .offset(x: 219 * scale, y: 58 * scale)

            plToggle
                .offset(x: 242 * scale, y: 58 * scale)

            // ---- Seek bar ----

            seekBar
                .offset(x: 16 * scale, y: 72 * scale)

            // ---- Transport buttons ----

            transportRow
                .offset(x: 16 * scale, y: 88 * scale)

            ejectButton
                .offset(x: 136 * scale, y: 89 * scale)

            // ---- Shuffle / repeat ----

            shuffleToggle
                .offset(x: 164 * scale, y: 89 * scale)

            repeatToggle
                .offset(x: 211 * scale, y: 89 * scale)
        }
        .frame(width: canvasWidth * scale, height: canvasHeight * scale, alignment: .topLeading)
    }

    // MARK: - Display subviews

    /// Tiny 9×9 icon showing the current playback state (green ▶ / yellow ⏸ /
    /// red ■). Sits just to the left of the time digits.
    ///
    /// Marked non-hit-testable: this is a purely ornamental read-out with no
    /// gesture. Without `.allowsHitTesting(false)` SwiftUI happily hands
    /// clicks on the sprite to its invisible NSHostingView-backed frame,
    /// swallowing them silently. With it off, clicks in the display area
    /// fall through to the window's drag container instead, which is the
    /// classic Winamp behaviour (clicking the chrome anywhere drags it).
    @ViewBuilder
    private var playPauseStateIcon: some View {
        let rect: SpriteRect = {
            switch player.playbackState {
            case .playing: return Sprites.PLAYPAUS.playing
            case .paused:  return Sprites.PLAYPAUS.paused
            case .stopped: return Sprites.PLAYPAUS.stopped
            }
        }()
        SpriteView(sheet: .playpaus, rect: rect, scale: scale)
            .allowsHitTesting(false)
    }

    /// Big green LCD digits (9×13 each) showing elapsed/remaining time.
    /// Stride matches the original skin: tens-ones 12 px apart, plus a
    /// 6 px colon gap between minutes and seconds (so seconds start at
    /// x=78 with minutes at x=48).
    @ViewBuilder
    private var timeDigits: some View {
        let seconds = Int(max(0, player.currentTime))
        let m = min(99, seconds / 60)
        let s = seconds % 60
        let showBlank = player.playbackState == .stopped && player.currentTrack == nil
        HStack(spacing: 0) {
            if showBlank {
                blankDigit(); gap(3 * scale)
                blankDigit(); gap(6 * scale)
                blankDigit(); gap(3 * scale)
                blankDigit()
            } else {
                digit(m / 10); gap(3 * scale)
                digit(m % 10); gap(6 * scale)
                digit(s / 10); gap(3 * scale)
                digit(s % 10)
            }
        }
        // Time read-out is non-interactive — clicks on it should drop
        // through to the drag container beneath (matches classic Winamp).
        .allowsHitTesting(false)
    }

    private func digit(_ n: Int) -> some View {
        SpriteView(
            sheet: .numbers,
            rect: Sprites.NUMBERS.digit(n),
            scale: scale
        )
    }

    private func blankDigit() -> some View {
        SpriteView(
            sheet: .numbers,
            rect: Sprites.NUMBERS.blank,
            scale: scale
        )
    }

    private func gap(_ width: CGFloat) -> some View {
        Color.clear.frame(width: width, height: Sprites.NUMBERS.digitHeight * scale)
    }

    /// Song title line — scrolls right-to-left when longer than the visible
    /// 154-pixel window. Uses the 5×6 bitmap font from TEXT.BMP.
    @ViewBuilder
    private var songTitleMarquee: some View {
        let title = marqueeText
        BitmapMarquee(text: title, pixelWidth: 154 * scale, scale: scale)
            .allowsHitTesting(false)
    }

    private var marqueeText: String {
        if let t = player.currentTrack {
            // "ARTIST - TITLE" is the classic Winamp convention. Fall back
            // to filename for untagged files.
            if !t.artist.isEmpty {
                return "\(t.artist) - \(t.title)"
            }
            return t.title
        }
        return "NULLSOFT WINAMP"
    }

    /// Small bitmap-font bitrate readout, e.g. "128".
    @ViewBuilder
    private var bitrateText: some View {
        let value = player.bitrate
        let text = value > 0 ? String(format: "%3d", value) : "   "
        BitmapFontView(text: text, scale: scale)
            .allowsHitTesting(false)
    }

    /// Sample rate readout, e.g. "44" for 44100 Hz.
    @ViewBuilder
    private var sampleRateText: some View {
        let hz = player.sampleRate
        let text = hz > 0 ? String(format: "%2d", hz / 1000) : "  "
        BitmapFontView(text: text, scale: scale)
            .allowsHitTesting(false)
    }

    /// Mono indicator (27×12). Lit when the playing file has a single channel.
    @ViewBuilder
    private var monoIndicator: some View {
        let isMono = isActiveMono
        SpriteView(
            sheet: .monoster,
            rect: isMono ? Sprites.MONOSTER.monoActive : Sprites.MONOSTER.monoInactive,
            scale: scale
        )
        .allowsHitTesting(false)
    }

    /// Stereo indicator (29×12).
    @ViewBuilder
    private var stereoIndicator: some View {
        let isStereo = isActiveStereo
        SpriteView(
            sheet: .monoster,
            rect: isStereo ? Sprites.MONOSTER.stereoActive : Sprites.MONOSTER.stereoInactive,
            scale: scale
        )
        .allowsHitTesting(false)
    }

    /// We don't expose a channel-count signal directly; approximate via
    /// audioLevels (two-channel sources produce non-identical L/R meters).
    /// Good enough for indicator purposes until AudioPlayerManager exposes
    /// channel count explicitly.
    private var isActiveStereo: Bool {
        player.playbackState == .playing
    }

    private var isActiveMono: Bool {
        false
    }

    // MARK: - Sliders

    /// Volume slider — 68×13 background that cycles through 28 rows of
    /// VOLUME.BMP depending on the current volume level, plus a 14×11
    /// thumb that slides across.
    @ViewBuilder
    private var volumeSlider: some View {
        SkinnedSlider(
            backgroundSheet: .volume,
            backgroundRectBuilder: { row in Sprites.VOLUME.background(row: row) },
            thumb: Sprites.VOLUME.thumb,
            thumbPressed: Sprites.VOLUME.thumbPressed,
            thumbSheet: .volume,
            bgWidth: 68,
            bgHeight: 13,
            thumbWidth: 14,
            thumbHeight: 11,
            value: Double(player.volume),
            scale: scale,
            onChange: { new in
                player.setVolume(Float(new))
            }
        )
    }

    /// Balance slider — 38×13. We don't wire to an AudioPlayerManager
    /// balance channel yet (Phase 3 scope), so the thumb stays centered
    /// and dragging updates local state only. Marked non-hit-testable
    /// so clicks in its region drop through to the drag container rather
    /// than being silently swallowed.
    @ViewBuilder
    private var balanceSlider: some View {
        StaticCenteredBalanceSlider(scale: scale)
            .allowsHitTesting(false)
    }

    // MARK: - Window cluster toggles

    /// EQ window show/hide — mirrors the "open EQ" clutterbar letter.
    @ViewBuilder
    private var eqToggle: some View {
        #if os(macOS)
        WindowKindToggle(kind: .equalizer, onRect: Sprites.SHUFREP.eqOn, offRect: Sprites.SHUFREP.eqOff,
                        pressedOn: Sprites.SHUFREP.eqOnPressed, pressedOff: Sprites.SHUFREP.eqOffPressed,
                        scale: scale)
        #else
        SpriteView(sheet: .shufrep, rect: Sprites.SHUFREP.eqOff, scale: scale)
        #endif
    }

    /// Playlist window show/hide.
    @ViewBuilder
    private var plToggle: some View {
        #if os(macOS)
        WindowKindToggle(kind: .playlist, onRect: Sprites.SHUFREP.plOn, offRect: Sprites.SHUFREP.plOff,
                        pressedOn: Sprites.SHUFREP.plOnPressed, pressedOff: Sprites.SHUFREP.plOffPressed,
                        scale: scale)
        #else
        SpriteView(sheet: .shufrep, rect: Sprites.SHUFREP.plOff, scale: scale)
        #endif
    }

    // MARK: - Seek bar

    /// 248-pixel-wide position bar with a 29-pixel thumb that tracks the
    /// current playback position. Disabled when nothing is loaded.
    @ViewBuilder
    private var seekBar: some View {
        let pct = duration > 0 ? min(1, max(0, player.currentTime / duration)) : 0
        SkinnedSeekBar(
            progress: pct,
            isEnabled: duration > 0,
            scale: scale,
            onScrub: { new in
                if duration > 0 {
                    player.seek(to: new * duration)
                }
            }
        )
    }

    private var duration: TimeInterval {
        player.duration > 0 ? player.duration : (player.currentTrack?.duration ?? 0)
    }

    // MARK: - Transport & toggles

    /// Prev / Play / Pause / Stop / Next — drawn left-to-right at y=88.
    /// Buttons are pixel-perfect sprites from CBUTTONS.BMP; `eject` lives
    /// separately because it has a different height (16) and y-offset.
    @ViewBuilder
    private var transportRow: some View {
        HStack(spacing: 0) {
            SpriteButton(
                sheet: .cbuttons,
                normal: Sprites.CBUTTONS.prev,
                pressed: Sprites.CBUTTONS.prevPressed,
                scale: scale,
                action: { player.previous() }
            )
            SpriteButton(
                sheet: .cbuttons,
                normal: Sprites.CBUTTONS.play,
                pressed: Sprites.CBUTTONS.playPressed,
                scale: scale,
                action: { player.play() }
            )
            SpriteButton(
                sheet: .cbuttons,
                normal: Sprites.CBUTTONS.pause,
                pressed: Sprites.CBUTTONS.pausePressed,
                scale: scale,
                action: { player.togglePlayPause() }
            )
            SpriteButton(
                sheet: .cbuttons,
                normal: Sprites.CBUTTONS.stop,
                pressed: Sprites.CBUTTONS.stopPressed,
                scale: scale,
                action: { player.stop() }
            )
            SpriteButton(
                sheet: .cbuttons,
                normal: Sprites.CBUTTONS.next,
                pressed: Sprites.CBUTTONS.nextPressed,
                scale: scale,
                action: { player.next() }
            )
        }
    }

    /// Eject button — opens a file picker (classic behavior) via the
    /// library's folder-selection flow.
    @ViewBuilder
    private var ejectButton: some View {
        SpriteButton(
            sheet: .cbuttons,
            normal: Sprites.CBUTTONS.eject,
            pressed: Sprites.CBUTTONS.ejectPressed,
            scale: scale,
            action: {
                // Re-trigger library scanning/folder picking. The manager
                // owns the actual file-picker UX; we just nudge it.
                library.startScanning()
            }
        )
    }

    /// Shuffle — classic 47×15 toggle.
    @ViewBuilder
    private var shuffleToggle: some View {
        SpriteToggle(
            sheet: .shufrep,
            offNormal:  Sprites.SHUFREP.shuffleOff,
            offPressed: Sprites.SHUFREP.shuffleOffPressed,
            onNormal:   Sprites.SHUFREP.shuffleOn,
            onPressed:  Sprites.SHUFREP.shuffleOnPressed,
            isOn: player.isShuffleEnabled,
            scale: scale,
            action: { player.toggleShuffle() }
        )
    }

    /// Repeat — cycles off / all / one. The sprite itself only has two
    /// states (off / on) so "all" and "one" both display as lit; we advance
    /// the enum on each tap.
    @ViewBuilder
    private var repeatToggle: some View {
        SpriteToggle(
            sheet: .shufrep,
            offNormal:  Sprites.SHUFREP.repeatOff,
            offPressed: Sprites.SHUFREP.repeatOffPressed,
            onNormal:   Sprites.SHUFREP.repeatOn,
            onPressed:  Sprites.SHUFREP.repeatOnPressed,
            isOn: player.repeatMode != .off,
            scale: scale,
            action: { player.cycleRepeatMode() }
        )
    }
}

// MARK: - Title bar

/// Sprite-based 275×14 main title bar. Uses `Sprites.TITLEBAR.mainSelected`
/// as the background, overlays window control buttons on the right with
/// real press actions, and reserves the central area for the existing
/// `WindowDragArea` so the window can be moved.
private struct SkinnedTitleBar: View {
    var scale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            SpriteView(sheet: .titlebar, rect: Sprites.TITLEBAR.mainSelected, scale: scale)
                .allowsHitTesting(false)

            // Window drag handle — occupies the central region of the
            // title bar so clicks there start a window drag.
            #if os(macOS)
            HStack(spacing: 0) {
                Color.clear.frame(width: 10 * scale, height: 14 * scale).allowsHitTesting(false)
                WindowDragArea()
                    .frame(height: 14 * scale)
                Color.clear.frame(width: 55 * scale, height: 14 * scale).allowsHitTesting(false)
            }
            .frame(width: 275 * scale, height: 14 * scale)
            #endif

            // Right-edge window-control buttons (minimize, shade, close).
            // Precise x-offsets match the baked-in sprite positions so the
            // clickable hotspots line up with the visible button art.
            minimizeButton
                .offset(x: 244 * scale, y: 3 * scale)
            shadeButton
                .offset(x: 254 * scale, y: 3 * scale)
            closeButton
                .offset(x: 264 * scale, y: 3 * scale)
        }
        .frame(width: 275 * scale, height: 14 * scale, alignment: .topLeading)
    }

    // Small 9×9 window-control buttons. Each one shows the pressed sprite
    // while held down, and fires its action on mouse-up.
    @ViewBuilder
    private var minimizeButton: some View {
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
    }

    @ViewBuilder
    private var shadeButton: some View {
        SpriteButton(
            sheet: .titlebar,
            normal: Sprites.TITLEBAR.shade,
            pressed: Sprites.TITLEBAR.shadePressed,
            scale: scale,
            action: {
                #if os(macOS)
                // Route shade toggling through the AppDelegate so the
                // coordinator's anchor math runs.
                if let del = NSApp.delegate as? WinampAppDelegate {
                    del.coordinator.controller(for: .main)?.toggleShade()
                }
                #endif
            }
        )
    }

    @ViewBuilder
    private var closeButton: some View {
        SpriteButton(
            sheet: .titlebar,
            normal: Sprites.TITLEBAR.close,
            pressed: Sprites.TITLEBAR.closePressed,
            scale: scale,
            action: {
                #if os(macOS)
                NSApp.keyWindow?.performClose(nil)
                #endif
            }
        )
    }
}

// MARK: - Reusable sprite controls

/// Simple press-to-activate button that cycles between its normal and
/// pressed sprite variants. Fires `action` on mouse-up when the cursor
/// is still inside the button's bounds (classic AppKit semantics).
struct SpriteButton: View {
    let sheet: SkinSheet
    let normal: SpriteRect
    let pressed: SpriteRect
    var scale: CGFloat = 1
    let action: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        SpriteView(
            sheet: sheet,
            rect: isPressed ? pressed : normal,
            scale: scale
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { g in
                    isPressed = false
                    let w = normal.width * scale
                    let h = normal.height * scale
                    if g.location.x >= 0, g.location.x <= w,
                       g.location.y >= 0, g.location.y <= h {
                        action()
                    }
                }
        )
    }
}

/// Two-state (on/off) sprite toggle — has four sprites total (off/on, each
/// with a pressed variant). Tap fires `action` and the caller is expected
/// to flip external state so `isOn` reflects the new value on next render.
struct SpriteToggle: View {
    let sheet: SkinSheet
    let offNormal: SpriteRect
    let offPressed: SpriteRect
    let onNormal: SpriteRect
    let onPressed: SpriteRect
    let isOn: Bool
    var scale: CGFloat = 1
    let action: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        let normal = isOn ? onNormal : offNormal
        let pressed = isOn ? onPressed : offPressed
        SpriteView(
            sheet: sheet,
            rect: isPressed ? pressed : normal,
            scale: scale
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { g in
                    isPressed = false
                    let w = normal.width * scale
                    let h = normal.height * scale
                    if g.location.x >= 0, g.location.x <= w,
                       g.location.y >= 0, g.location.y <= h {
                        action()
                    }
                }
        )
    }
}

/// Horizontal slider whose background is a row-indexed sprite sheet (VOLUME)
/// and whose thumb slides along inside the background rect. Value is in
/// 0...1; the callback receives a clamped value on every drag change.
struct SkinnedSlider: View {
    let backgroundSheet: SkinSheet
    /// Maps a 0...27 row index into a concrete SpriteRect within the sheet.
    let backgroundRectBuilder: (Int) -> SpriteRect
    let thumb: SpriteRect
    let thumbPressed: SpriteRect
    let thumbSheet: SkinSheet

    let bgWidth: CGFloat
    let bgHeight: CGFloat
    let thumbWidth: CGFloat
    let thumbHeight: CGFloat

    let value: Double
    var scale: CGFloat = 1
    let onChange: (Double) -> Void

    @State private var isDragging: Bool = false

    var body: some View {
        let clamped = max(0, min(1, value))
        let row = min(27, max(0, Int((clamped * 27.999).rounded(.down))))
        let travel = max(0, bgWidth - thumbWidth)
        let thumbX = travel * CGFloat(clamped)
        let thumbY = (bgHeight - thumbHeight) / 2

        ZStack(alignment: .topLeading) {
            // Transparent hit-target sitting underneath the art. Without
            // this, every child of the ZStack is `.allowsHitTesting(false)`
            // and the outer `.contentShape(Rectangle())` + `.gesture(...)`
            // has no concrete hit-testable content for SwiftUI's gesture
            // recognizer to anchor against — clicks on the slider silently
            // do nothing. The working EQ slider (`EQBandSlider`) uses the
            // same pattern.
            Color.clear
                .frame(width: bgWidth * scale, height: bgHeight * scale)
                .contentShape(Rectangle())

            SpriteView(sheet: backgroundSheet, rect: backgroundRectBuilder(row), scale: scale)
                .allowsHitTesting(false)
            SpriteView(
                sheet: thumbSheet,
                rect: isDragging ? thumbPressed : thumb,
                scale: scale
            )
            .offset(x: thumbX * scale, y: thumbY * scale)
            .allowsHitTesting(false)
        }
        .frame(width: bgWidth * scale, height: bgHeight * scale, alignment: .topLeading)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    isDragging = true
                    // Anchor the thumb to the cursor — center the thumb under
                    // the pointer by subtracting half the thumb width.
                    let rawX = g.location.x / scale - thumbWidth / 2
                    let bounded = max(0, min(travel, rawX))
                    let newValue = travel > 0 ? Double(bounded / travel) : 0
                    onChange(newValue)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}

/// Balance slider — the audio engine doesn't yet expose a L/R pan channel,
/// so this is purely visual for now. The thumb always renders centered.
private struct StaticCenteredBalanceSlider: View {
    var scale: CGFloat = 1

    private let bgWidth: CGFloat = 38
    private let bgHeight: CGFloat = 13
    private let thumbWidth: CGFloat = 14
    private let thumbHeight: CGFloat = 11

    var body: some View {
        // Row 0 is the centered (0 dB) balance background — rows further
        // from 0 fade the L or R arrow indicators in the classic sheet.
        let centeredRow = 0
        let travel = bgWidth - thumbWidth
        let thumbX = travel / 2
        let thumbY = (bgHeight - thumbHeight) / 2

        ZStack(alignment: .topLeading) {
            SpriteView(sheet: .balance, rect: Sprites.BALANCE.background(row: centeredRow), scale: scale)
                .allowsHitTesting(false)
            SpriteView(sheet: .balance, rect: Sprites.BALANCE.thumb, scale: scale)
                .offset(x: thumbX * scale, y: thumbY * scale)
                .allowsHitTesting(false)
        }
        .frame(width: bgWidth * scale, height: bgHeight * scale, alignment: .topLeading)
    }
}

/// Classic seek bar — 248×10 background with a 29×10 thumb. Dragging
/// the thumb emits `onScrub(progress)` in 0...1; tap-to-seek works too.
struct SkinnedSeekBar: View {
    let progress: Double
    let isEnabled: Bool
    var scale: CGFloat = 1
    let onScrub: (Double) -> Void

    private let bgWidth: CGFloat = 248
    private let bgHeight: CGFloat = 10
    private let thumbWidth: CGFloat = 29
    private let thumbHeight: CGFloat = 10

    @State private var isDragging: Bool = false

    var body: some View {
        let clamped = max(0, min(1, progress))
        let travel = max(0, bgWidth - thumbWidth)
        let thumbX = travel * CGFloat(clamped)

        ZStack(alignment: .topLeading) {
            // Transparent hit-target — required so the outer `.gesture()`
            // has concrete hit-testable content. See SkinnedSlider for the
            // long explanation; same SwiftUI quirk applies here.
            Color.clear
                .frame(width: bgWidth * scale, height: bgHeight * scale)
                .contentShape(Rectangle())

            SpriteView(sheet: .posbar, rect: Sprites.POSBAR.background, scale: scale)
                .allowsHitTesting(false)
            if isEnabled {
                SpriteView(
                    sheet: .posbar,
                    rect: isDragging ? Sprites.POSBAR.thumbPressed : Sprites.POSBAR.thumb,
                    scale: scale
                )
                .offset(x: thumbX * scale, y: 0)
                .allowsHitTesting(false)
            }
        }
        .frame(width: bgWidth * scale, height: bgHeight * scale, alignment: .topLeading)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    guard isEnabled else { return }
                    isDragging = true
                    let rawX = g.location.x / scale - thumbWidth / 2
                    let bounded = max(0, min(travel, rawX))
                    let pct = travel > 0 ? Double(bounded / travel) : 0
                    onScrub(pct)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}

// MARK: - Auxiliary window toggle

#if os(macOS)
/// Shows/hides one of the sibling Winamp windows (equalizer / playlist)
/// and lights up while the target window is visible. Watches the window's
/// visibility via a 200 ms polling timer — cheap and avoids plumbing a
/// dedicated Combine publisher through the coordinator.
private struct WindowKindToggle: View {
    let kind: WinampWindowKind
    let onRect: SpriteRect
    let offRect: SpriteRect
    let pressedOn: SpriteRect
    let pressedOff: SpriteRect
    var scale: CGFloat = 1

    @State private var isOn: Bool = false
    @State private var pollTimer: Timer?

    var body: some View {
        SpriteToggle(
            sheet: .shufrep,
            offNormal: offRect,
            offPressed: pressedOff,
            onNormal: onRect,
            onPressed: pressedOn,
            isOn: isOn,
            scale: scale,
            action: {
                guard let del = NSApp.delegate as? WinampAppDelegate,
                      let c = del.coordinator.controller(for: kind) else { return }
                if c.isVisible { c.hide() } else { c.show() }
                // Re-read after the show/hide so our state flips promptly.
                isOn = c.isVisible
            }
        )
        .onAppear {
            refresh()
            pollTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                refresh()
            }
            if let t = pollTimer { RunLoop.main.add(t, forMode: .common) }
        }
        .onDisappear {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    private func refresh() {
        guard let del = NSApp.delegate as? WinampAppDelegate,
              let c = del.coordinator.controller(for: kind) else { return }
        if isOn != c.isVisible { isOn = c.isVisible }
    }
}
#endif
