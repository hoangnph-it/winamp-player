import SwiftUI

/// Classic Winamp 2.x LCD display — matching the reference video layout:
///
///  ┌──────────────────────────────────────────────────────────────┐
///  │ ┌──────────┐ │ ▸ Scrolling title (ticker)         1/113      │
///  │ │ ▸  0:00  │ │ ──────────────────────────────────────────    │
///  │ │          │ │ 128 kbps   44 kHz          mono   stereo      │
///  │ │  ▌▌▌▌▌▌  │ │ ──────────────────────────────────────────    │
///  │ │ (mini-viz│ │ [========vol========]  [bal]   [EQ] [PL]      │
///  │ └──────────┘ │                                               │
///  └──────────────────────────────────────────────────────────────┘
///
/// Left column = "Playbar": play-status + 7-seg time + mini visualizer.
/// Right column = 3 stacked info rows.
struct WinampDisplay: View {
    @EnvironmentObject var player: AudioPlayerManager
    @State private var scrollID = UUID()
    @State private var balance: Float = 0.5
    @State private var eqOn: Bool = true
    @State private var plOn: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            // ── LEFT: "Playbar" column ───────────────────────────
            Playbar()
                .frame(width: 85)

            // ── RIGHT: 3-row info stack ──────────────────────────
            VStack(spacing: 1) {
                titleRow
                infoRow
                controlsRow
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.trailing, 4)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 3)
        .background(WinampTheme.displayBg)
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .strokeBorder(WinampTheme.displayBorder, lineWidth: 1)
        )
        .onChange(of: player.currentTrack?.id) { _ in
            scrollID = UUID()
        }
    }

    // MARK: Right column — row 1: scrolling title + track index
    private var titleRow: some View {
        HStack(spacing: 4) {
            // Bordered ticker box — classic Winamp framed song-title area
            ScrollingTicker(text: tickerText, scrollID: scrollID)
                .frame(height: 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 3)
                .background(WinampTheme.displayBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .strokeBorder(WinampTheme.displayBorder.opacity(0.8),
                                      lineWidth: 0.5)
                )

            let idx = player.playlist.currentIndex + 1
            let total = max(player.playlist.tracks.count, 1)
            Text("\(idx)/\(total)")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(WinampTheme.lcdGreenDim)
        }
        .frame(height: 12)
    }

    // MARK: Right column — row 2: kbps | kHz | mono | stereo
    private var infoRow: some View {
        HStack(spacing: 0) {
            // Bitrate
            HStack(spacing: 2) {
                Text(player.bitrate > 0 ? "\(player.bitrate)" : (player.currentTrack != nil ? "128" : "---"))
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundColor(WinampTheme.lcdGreen)
                    .frame(minWidth: 18, alignment: .trailing)
                Text("kbps")
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .foregroundColor(WinampTheme.lcdGreenDim)
            }

            Spacer().frame(width: 10)

            // Sample rate
            HStack(spacing: 2) {
                Text(player.sampleRate > 0 ? "\(player.sampleRate / 1000)" : "--")
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundColor(WinampTheme.lcdGreen)
                    .frame(minWidth: 14, alignment: .trailing)
                Text("kHz")
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .foregroundColor(WinampTheme.lcdGreenDim)
            }

            Spacer()

            // Mono / Stereo indicators
            HStack(spacing: 8) {
                MonoStereoIndicator(label: "mono", active: false)
                MonoStereoIndicator(label: "stereo", active: player.currentTrack != nil)
            }
        }
        .frame(height: 12)
    }

    // MARK: Right column — row 3: volume slider | balance | EQ | PL
    private var controlsRow: some View {
        HStack(spacing: 4) {
            // Volume bar (graduated)
            GraduatedVolume(value: Binding(
                get: { player.volume },
                set: { player.setVolume($0) }
            ))
            .frame(height: 12)
            .frame(maxWidth: .infinity)

            // Balance bar
            GraduatedBalance(value: $balance)
                .frame(width: 42, height: 12)

            // EQ button
            DisplayToggleBtn(label: "EQ", active: $eqOn)
            // PL button
            DisplayToggleBtn(label: "PL", active: $plOn)
        }
        .frame(height: 14)
    }

    private var tickerText: String {
        if let track = player.currentTrack {
            return "\(track.artist) - \(track.title)"
        }
        return "WINAMP 2.x - THE CLASSIC PLAYER"
    }
}

// MARK: - Playbar (the LCD group on the left)
private struct Playbar: View {
    @EnvironmentObject var player: AudioPlayerManager

    var body: some View {
        HStack(spacing: 3) {
            // Play/pause/stop status indicator
            PlayStatusIndicator(state: player.playbackState)
                .frame(width: 8, height: 22)

            // 7-segment LCD time
            SegmentedTime(time: player.currentTime)
                .frame(height: 22)

            // Mini spectrum visualizer
            MiniViz(levels: player.audioLevels)
                .frame(width: 20, height: 22)
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - Display-area beveled toggle (EQ / PL)
private struct DisplayToggleBtn: View {
    let label: String
    @Binding var active: Bool
    var body: some View {
        Button { active.toggle() } label: {
            Text(label)
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundColor(active ? WinampTheme.btnActive : WinampTheme.btnText)
                .frame(width: 18, height: 12)
                .background(active ? WinampTheme.frameDark : WinampTheme.btnFace)
                .overlay(BevelBorder(pressed: active))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Play/Pause/Stop Status Indicator
private struct PlayStatusIndicator: View {
    let state: PlaybackState

    var body: some View {
        ZStack {
            switch state {
            case .playing:
                PlayingArrow()
            case .paused:
                HStack(spacing: 2) {
                    Rectangle().fill(WinampTheme.lcdGreen)
                        .frame(width: 3, height: 10)
                    Rectangle().fill(WinampTheme.lcdGreen)
                        .frame(width: 3, height: 10)
                }
            case .stopped:
                Rectangle()
                    .fill(WinampTheme.lcdGreenDim)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

private struct PlayingArrow: View {
    @State private var phase: Bool = false
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 2, y: 3))
            p.addLine(to: CGPoint(x: 12, y: 9))
            p.addLine(to: CGPoint(x: 2, y: 15))
            p.closeSubpath()
        }
        .fill(WinampTheme.lcdGreen)
        .frame(width: 14, height: 18)
        .opacity(phase ? 1.0 : 0.7)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                phase = true
            }
        }
    }
}

// MARK: - Segmented LCD Time Digits
private struct SegmentedTime: View {
    let time: TimeInterval

    private var minutes: Int { Int(time) / 60 }
    private var seconds: Int { Int(time) % 60 }

    var body: some View {
        HStack(spacing: 1) {
            LCDDigit(value: minutes / 10)
            LCDDigit(value: minutes % 10)
            LCDColon()
            LCDDigit(value: seconds / 10)
            LCDDigit(value: seconds % 10)
        }
    }
}

/// A single 7-segment LCD digit
private struct LCDDigit: View {
    let value: Int

    // 7-segment encoding: [top, topRight, botRight, bottom, botLeft, topLeft, middle]
    private static let segments: [[Bool]] = [
        [true,  true,  true,  true,  true,  true,  false], // 0
        [false, true,  true,  false, false, false, false], // 1
        [true,  true,  false, true,  true,  false, true],  // 2
        [true,  true,  true,  true,  false, false, true],  // 3
        [false, true,  true,  false, false, true,  true],  // 4
        [true,  false, true,  true,  false, true,  true],  // 5
        [true,  false, true,  true,  true,  true,  true],  // 6
        [true,  true,  true,  false, false, false, false], // 7
        [true,  true,  true,  true,  true,  true,  true],  // 8
        [true,  true,  true,  true,  false, true,  true],  // 9
    ]

    var body: some View {
        let segs = value >= 0 && value <= 9 ? LCDDigit.segments[value] : LCDDigit.segments[0]
        let w: CGFloat = 9
        let h: CGFloat = 18
        let t: CGFloat = 2
        let g: CGFloat = 1

        Canvas { ctx, size in
            drawH(ctx: ctx, x: g, y: 0, w: w - 2*g, t: t,
                  color: segs[0] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            drawV(ctx: ctx, x: w - t, y: g, h: h/2 - g, t: t,
                  color: segs[1] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            drawV(ctx: ctx, x: w - t, y: h/2 + g, h: h/2 - g, t: t,
                  color: segs[2] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            drawH(ctx: ctx, x: g, y: h - t, w: w - 2*g, t: t,
                  color: segs[3] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            drawV(ctx: ctx, x: 0, y: h/2 + g, h: h/2 - g, t: t,
                  color: segs[4] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            drawV(ctx: ctx, x: 0, y: g, h: h/2 - g, t: t,
                  color: segs[5] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            drawH(ctx: ctx, x: g, y: h/2 - t/2, w: w - 2*g, t: t,
                  color: segs[6] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
        }
        .frame(width: w, height: h)
    }

    private func drawH(ctx: GraphicsContext, x: CGFloat, y: CGFloat, w: CGFloat, t: CGFloat, color: Color) {
        ctx.fill(Path(CGRect(x: x, y: y, width: w, height: t)), with: .color(color))
    }

    private func drawV(ctx: GraphicsContext, x: CGFloat, y: CGFloat, h: CGFloat, t: CGFloat, color: Color) {
        ctx.fill(Path(CGRect(x: x, y: y, width: t, height: h)), with: .color(color))
    }
}

/// LCD colon between minutes and seconds
private struct LCDColon: View {
    @State private var blink = true

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(blink ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
                .frame(width: 2.5, height: 2.5)
            Circle()
                .fill(blink ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
                .frame(width: 2.5, height: 2.5)
        }
        .frame(width: 5, height: 18)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                blink.toggle()
            }
        }
    }
}

// MARK: - Mini Spectrum Visualizer
private struct MiniViz: View {
    let levels: [Float]

    var body: some View {
        HStack(alignment: .bottom, spacing: 1) {
            ForEach(0..<min(10, levels.count), id: \.self) { i in
                VizBar(level: CGFloat(levels[i]))
            }
        }
        .padding(2)
    }
}

private struct VizBar: View {
    let level: CGFloat

    var body: some View {
        GeometryReader { g in
            let maxH = g.size.height
            let segCount = 8
            let segH: CGFloat = max(1, (maxH - CGFloat(segCount - 1)) / CGFloat(segCount))
            let litCount = Int(level * CGFloat(segCount))

            VStack(spacing: 1) {
                ForEach((0..<segCount).reversed(), id: \.self) { i in
                    let lit = i < litCount
                    Rectangle()
                        .fill(lit ? vizColor(seg: i, total: segCount) : WinampTheme.lcdGreenFaint.opacity(0.3))
                        .frame(height: segH)
                }
            }
        }
    }

    private func vizColor(seg: Int, total: Int) -> Color {
        let ratio = CGFloat(seg) / CGFloat(max(1, total - 1))
        if ratio > 0.8 { return WinampTheme.vizHigh }
        if ratio > 0.5 { return WinampTheme.vizMid }
        return WinampTheme.vizLow
    }
}

// MARK: - Mono / Stereo indicator
private struct MonoStereoIndicator: View {
    let label: String
    let active: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(active ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
    }
}

// MARK: - Scrolling Ticker
private struct ScrollingTicker: View {
    let text: String
    let scrollID: UUID
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let display = "  \(text.uppercased())  ***  \(text.uppercased())  ***  "
            Text(display)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(WinampTheme.lcdGreen)
                .fixedSize()
                .offset(x: -offset)
                .onAppear { startScroll(geo.size.width) }
                .onChange(of: scrollID) { _ in
                    offset = 0
                    startScroll(geo.size.width)
                }
        }
        .clipped()
    }

    private func startScroll(_ w: CGFloat) {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            offset = w + 200
        }
    }
}
