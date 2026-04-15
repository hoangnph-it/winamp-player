import SwiftUI

/// Classic Winamp 2.x LCD display panel — pixel-accurate layout
/// ┌──────────────────────────────────────────┐
/// │ ▶ │  3:42  │ ▌▌▌▌▌▌▌▌ │                │
/// │   │        │ (mini viz)│                │
/// │   │────────│───────────│ scrolling text  │
/// │   │ kbps kHz  stereo   │                │
/// └──────────────────────────────────────────┘
struct WinampDisplay: View {
    @EnvironmentObject var player: AudioPlayerManager
    @State private var titleOffset: CGFloat = 0
    @State private var scrollID = UUID()

    var body: some View {
        VStack(spacing: 0) {
            // ── Main area: status | time | viz | scroller ──
            HStack(spacing: 0) {
                // Play/Pause/Stop status indicator
                PlayStatusIndicator(state: player.playbackState)
                    .frame(width: 18, height: 36)
                    .padding(.leading, 4)

                // Big segmented LCD time
                SegmentedTime(time: player.currentTime)
                    .frame(height: 36)
                    .padding(.leading, 2)

                // Mini spectrum visualizer
                MiniViz(levels: player.audioLevels)
                    .frame(width: 38, height: 36)
                    .padding(.horizontal, 4)

                // Right side: scrolling text + info
                VStack(alignment: .leading, spacing: 1) {
                    // Scrolling track title (ticker)
                    ScrollingTicker(
                        text: tickerText,
                        scrollID: scrollID
                    )
                    .frame(height: 12)

                    // Track # of total
                    let idx = player.playlist.currentIndex + 1
                    let total = max(player.playlist.tracks.count, 1)
                    Text("\(idx)/\(total)")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreenDim)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 4)
            }
            .padding(.top, 4)

            // ── Bottom info row: kbps | kHz | mono/stereo ──
            HStack(spacing: 0) {
                // Bitrate
                HStack(spacing: 1) {
                    Text(player.currentTrack != nil ? "128" : "---")
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreen)
                    Text("kbps")
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreenDim)
                }
                .padding(.leading, 6)

                Spacer().frame(width: 10)

                // Sample rate
                HStack(spacing: 1) {
                    Text(player.sampleRate > 0 ? "\(player.sampleRate / 1000)" : "--")
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreen)
                    Text("kHz")
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundColor(WinampTheme.lcdGreenDim)
                }

                Spacer()

                // Mono / Stereo indicators
                HStack(spacing: 4) {
                    MonoStereoIndicator(label: "MONO", active: false)
                    MonoStereoIndicator(label: "STEREO", active: player.currentTrack != nil)
                }
                .padding(.trailing, 6)
            }
            .padding(.vertical, 3)
        }
        .background(WinampTheme.displayBg)
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .strokeBorder(WinampTheme.displayBorder, lineWidth: 1)
        )
        .onChange(of: player.currentTrack?.id) { _ in
            scrollID = UUID()
        }
    }

    private var tickerText: String {
        if let track = player.currentTrack {
            return "\(track.artist) - \(track.title)"
        }
        return "WINAMP 2.x - THE CLASSIC PLAYER"
    }
}

// MARK: - Play/Pause/Stop Status Indicator (like playpaus.bmp)
private struct PlayStatusIndicator: View {
    let state: PlaybackState

    var body: some View {
        ZStack {
            // Outer glow
            switch state {
            case .playing:
                // Animated play arrow
                PlayingArrow()
            case .paused:
                // Pause bars
                HStack(spacing: 2) {
                    Rectangle().fill(WinampTheme.lcdGreen)
                        .frame(width: 3, height: 10)
                    Rectangle().fill(WinampTheme.lcdGreen)
                        .frame(width: 3, height: 10)
                }
            case .stopped:
                // Stop square
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
        // Classic triangular play indicator
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
            // Minutes (up to 2 digits)
            LCDDigit(value: minutes / 10)
            LCDDigit(value: minutes % 10)

            // Colon
            LCDColon()

            // Seconds
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
        let w: CGFloat = 12
        let h: CGFloat = 24
        let t: CGFloat = 2.5  // segment thickness
        let g: CGFloat = 1    // gap

        Canvas { ctx, size in
            // Draw each segment as a small rectangle
            // top
            drawH(ctx: ctx, x: g, y: 0, w: w - 2*g, t: t,
                  color: segs[0] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            // top-right
            drawV(ctx: ctx, x: w - t, y: g, h: h/2 - g, t: t,
                  color: segs[1] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            // bottom-right
            drawV(ctx: ctx, x: w - t, y: h/2 + g, h: h/2 - g, t: t,
                  color: segs[2] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            // bottom
            drawH(ctx: ctx, x: g, y: h - t, w: w - 2*g, t: t,
                  color: segs[3] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            // bottom-left
            drawV(ctx: ctx, x: 0, y: h/2 + g, h: h/2 - g, t: t,
                  color: segs[4] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            // top-left
            drawV(ctx: ctx, x: 0, y: g, h: h/2 - g, t: t,
                  color: segs[5] ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
            // middle
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
        VStack(spacing: 6) {
            Circle()
                .fill(blink ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
                .frame(width: 3, height: 3)
            Circle()
                .fill(blink ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
                .frame(width: 3, height: 3)
        }
        .frame(width: 6, height: 24)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                blink.toggle()
            }
        }
    }
}

// MARK: - Mini Spectrum Visualizer (inside display, right of time)
private struct MiniViz: View {
    let levels: [Float]

    var body: some View {
        HStack(alignment: .bottom, spacing: 1) {
            ForEach(0..<min(12, levels.count), id: \.self) { i in
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

// MARK: - Mono/Stereo Indicator (like monoster.bmp)
private struct MonoStereoIndicator: View {
    let label: String
    let active: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 7, weight: .heavy, design: .monospaced))
            .foregroundColor(active ? WinampTheme.lcdGreen : WinampTheme.lcdGreenFaint)
    }
}

// MARK: - Scrolling Ticker (like text.bmp area)
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
