import CoreGraphics

/// Rectangular region (in source-bitmap pixel coordinates) of a skin sheet.
struct SpriteRect: Equatable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
}

/// Central registry of sprite coordinates, transcribed from webamp's
/// `packages/webamp/js/skinSprites.ts`.
///
/// Keeping these as raw numeric constants (rather than a giant dictionary)
/// means the compiler verifies every reference and lets us delete dead
/// entries over time. All coordinates assume a classic 1x Winamp 2.x layout.
enum Sprites {

    // MARK: - cbuttons.bmp (main transport row)
    enum CBUTTONS {
        static let prev         = SpriteRect(x:   0, y:  0, width: 23, height: 18)
        static let prevPressed  = SpriteRect(x:   0, y: 18, width: 23, height: 18)
        static let play         = SpriteRect(x:  23, y:  0, width: 23, height: 18)
        static let playPressed  = SpriteRect(x:  23, y: 18, width: 23, height: 18)
        static let pause        = SpriteRect(x:  46, y:  0, width: 23, height: 18)
        static let pausePressed = SpriteRect(x:  46, y: 18, width: 23, height: 18)
        static let stop         = SpriteRect(x:  69, y:  0, width: 23, height: 18)
        static let stopPressed  = SpriteRect(x:  69, y: 18, width: 23, height: 18)
        static let next         = SpriteRect(x:  92, y:  0, width: 22, height: 18)
        static let nextPressed  = SpriteRect(x:  92, y: 18, width: 22, height: 18)
        static let eject        = SpriteRect(x: 114, y:  0, width: 22, height: 16)
        static let ejectPressed = SpriteRect(x: 114, y: 16, width: 22, height: 16)
    }

    // MARK: - titlebar.bmp
    enum TITLEBAR {
        // Full main title bar (275x14) — four focus/shade combinations
        static let mainSelected    = SpriteRect(x: 27, y:  0, width: 275, height: 14)
        static let mainUnfocused   = SpriteRect(x: 27, y: 15, width: 275, height: 14)
        static let shadeSelected   = SpriteRect(x: 27, y: 29, width: 275, height: 14)
        static let shadeUnfocused  = SpriteRect(x: 27, y: 42, width: 275, height: 14)
        // Easter-egg: "nullsoft" title (active when dragging options-menu)
        static let eggSelected     = SpriteRect(x: 27, y: 57, width: 275, height: 14)
        static let eggUnfocused    = SpriteRect(x: 27, y: 72, width: 275, height: 14)

        // Small window-control buttons (9x9)
        static let menuNormal     = SpriteRect(x:  0, y:  0, width: 9, height: 9)
        static let menuPressed    = SpriteRect(x:  0, y:  9, width: 9, height: 9)
        static let minimize       = SpriteRect(x:  9, y:  0, width: 9, height: 9)
        static let minimizePressed = SpriteRect(x: 9, y:  9, width: 9, height: 9)
        static let shade          = SpriteRect(x:  0, y: 18, width: 9, height: 9)
        static let shadePressed   = SpriteRect(x:  0, y: 27, width: 9, height: 9)
        static let close          = SpriteRect(x: 18, y:  0, width: 9, height: 9)
        static let closePressed   = SpriteRect(x: 18, y:  9, width: 9, height: 9)

        // Shade-mode position bar (tiny seek in collapsed title)
        static let shadePosbarBg    = SpriteRect(x:  0, y: 36, width: 17, height: 7)
        static let shadePosbarThumb = SpriteRect(x: 20, y: 36, width:  3, height: 7)

        // Clutterbar (left edge, 5 small letters)
        static let clutterBg = SpriteRect(x: 304, y:  0, width: 8, height: 43)
        static let clutterO  = SpriteRect(x: 304, y: 47, width: 8, height: 8) // Options
        static let clutterA  = SpriteRect(x: 312, y: 55, width: 8, height: 7) // Agent
        static let clutterI  = SpriteRect(x: 320, y: 62, width: 8, height: 7) // Info
        static let clutterD  = SpriteRect(x: 328, y: 69, width: 8, height: 8) // Doublesize
        static let clutterV  = SpriteRect(x: 336, y: 77, width: 8, height: 7) // Visualization
    }

    // MARK: - posbar.bmp (main seek bar)
    enum POSBAR {
        static let background    = SpriteRect(x:   0, y: 0, width: 248, height: 10)
        static let thumb         = SpriteRect(x: 248, y: 0, width:  29, height: 10)
        static let thumbPressed  = SpriteRect(x: 278, y: 0, width:  29, height: 10)
    }

    // MARK: - shufrep.bmp (shuffle/repeat + EQ/PL toggles)
    enum SHUFREP {
        // Repeat (28x15)
        static let repeatOff        = SpriteRect(x: 0, y:  0, width: 28, height: 15)
        static let repeatOffPressed = SpriteRect(x: 0, y: 15, width: 28, height: 15)
        static let repeatOn         = SpriteRect(x: 0, y: 30, width: 28, height: 15)
        static let repeatOnPressed  = SpriteRect(x: 0, y: 45, width: 28, height: 15)
        // Shuffle (47x15)
        static let shuffleOff        = SpriteRect(x: 28, y:  0, width: 47, height: 15)
        static let shuffleOffPressed = SpriteRect(x: 28, y: 15, width: 47, height: 15)
        static let shuffleOn         = SpriteRect(x: 28, y: 30, width: 47, height: 15)
        static let shuffleOnPressed  = SpriteRect(x: 28, y: 45, width: 47, height: 15)
        // EQ toggle (23x12)
        static let eqOff        = SpriteRect(x:  0, y: 61, width: 23, height: 12)
        static let eqOn         = SpriteRect(x:  0, y: 73, width: 23, height: 12)
        static let eqOffPressed = SpriteRect(x: 46, y: 61, width: 23, height: 12)
        static let eqOnPressed  = SpriteRect(x: 46, y: 73, width: 23, height: 12)
        // Playlist toggle (23x12)
        static let plOff        = SpriteRect(x: 23, y: 61, width: 23, height: 12)
        static let plOn         = SpriteRect(x: 23, y: 73, width: 23, height: 12)
        static let plOffPressed = SpriteRect(x: 69, y: 61, width: 23, height: 12)
        static let plOnPressed  = SpriteRect(x: 69, y: 73, width: 23, height: 12)
    }

    // MARK: - monoster.bmp
    enum MONOSTER {
        static let stereoActive   = SpriteRect(x:  0, y:  0, width: 29, height: 12)
        static let stereoInactive = SpriteRect(x:  0, y: 12, width: 29, height: 12)
        static let monoActive     = SpriteRect(x: 29, y:  0, width: 27, height: 12)
        static let monoInactive   = SpriteRect(x: 29, y: 12, width: 27, height: 12)
    }

    // MARK: - playpaus.bmp  (tiny state icons inside the display)
    enum PLAYPAUS {
        static let playing    = SpriteRect(x:  0, y: 0, width: 9, height: 9)
        static let paused     = SpriteRect(x:  9, y: 0, width: 9, height: 9)
        static let stopped    = SpriteRect(x: 18, y: 0, width: 9, height: 9)
        static let notWorking = SpriteRect(x: 36, y: 0, width: 9, height: 9)
        static let working    = SpriteRect(x: 39, y: 0, width: 3, height: 9)
    }

    // MARK: - numbers.bmp (9x13 digits)
    enum NUMBERS {
        static let digitWidth: CGFloat  = 9
        static let digitHeight: CGFloat = 13
        static func digit(_ n: Int) -> SpriteRect {
            let clamped = max(0, min(9, n))
            return SpriteRect(x: CGFloat(clamped) * 9, y: 0, width: 9, height: 13)
        }
        /// A small gap glyph — same dimensions as a digit but blank.
        static let blank = SpriteRect(x: 90, y: 0, width: 9, height: 13)
        /// Minus sign for "remaining" time mode (single row from nums_ex layout).
        static let minus = SpriteRect(x: 20, y: 6, width: 5, height: 1)
    }

    // MARK: - volume.bmp
    /// Sheet is 68x452. 28 background rows (one per 3.57% step) stacked at y=0..419,
    /// followed by the thumb pair at y=422.
    enum VOLUME {
        /// `row` is 0...27 mapped from volume 0%...100%.
        static func background(row: Int) -> SpriteRect {
            let r = max(0, min(27, row))
            return SpriteRect(x: 0, y: CGFloat(r) * 15, width: 68, height: 13)
        }
        static let thumb        = SpriteRect(x: 15, y: 422, width: 14, height: 11)
        static let thumbPressed = SpriteRect(x:  0, y: 422, width: 14, height: 11)
    }

    // MARK: - balance.bmp
    /// Same sheet shape as volume but only the middle 38px column is used.
    enum BALANCE {
        static func background(row: Int) -> SpriteRect {
            let r = max(0, min(27, row))
            return SpriteRect(x: 9, y: CGFloat(r) * 15, width: 38, height: 13)
        }
        static let thumb        = SpriteRect(x: 15, y: 422, width: 14, height: 11)
        static let thumbPressed = SpriteRect(x:  0, y: 422, width: 14, height: 11)
    }

    // MARK: - eqmain.bmp
    enum EQMAIN {
        static let background     = SpriteRect(x: 0, y:   0, width: 275, height: 116)
        static let titleSelected  = SpriteRect(x: 0, y: 134, width: 275, height: 14)
        static let titleUnfocused = SpriteRect(x: 0, y: 149, width: 275, height: 14)

        // One EQ band slider column is 14x63
        static let sliderBg            = SpriteRect(x: 13, y: 164, width: 14, height: 63)
        static let sliderThumb         = SpriteRect(x:  0, y: 164, width: 11, height: 11)
        static let sliderThumbPressed  = SpriteRect(x:  0, y: 176, width: 11, height: 11)

        // ON button (26x12)
        static let onOff         = SpriteRect(x:  10, y: 119, width: 26, height: 12)
        static let onOn          = SpriteRect(x:  69, y: 119, width: 26, height: 12)
        static let onOffPressed  = SpriteRect(x: 128, y: 119, width: 26, height: 12)
        static let onOnPressed   = SpriteRect(x: 187, y: 119, width: 26, height: 12)
        // AUTO button (32x12)
        static let autoOff        = SpriteRect(x:  36, y: 119, width: 32, height: 12)
        static let autoOn         = SpriteRect(x:  95, y: 119, width: 32, height: 12)
        static let autoOffPressed = SpriteRect(x: 154, y: 119, width: 32, height: 12)
        static let autoOnPressed  = SpriteRect(x: 213, y: 119, width: 32, height: 12)
        // Presets dropdown
        static let presets        = SpriteRect(x: 224, y: 164, width: 44, height: 12)
        static let presetsPressed = SpriteRect(x: 224, y: 176, width: 44, height: 12)

        // Graph preview panel
        static let graphBg     = SpriteRect(x:   0, y: 294, width: 113, height: 19)
        static let graphColors = SpriteRect(x: 115, y: 294, width:   1, height: 19)
        static let preampLine  = SpriteRect(x:   0, y: 314, width: 113, height:  1)
    }

    // MARK: - pledit.bmp (9-slice + toolbar + scroll thumb + small buttons)
    enum PLEDIT {
        // Top row
        static let topLeftFocused    = SpriteRect(x:   0, y:  0, width:  25, height: 20)
        static let topLeftUnfocused  = SpriteRect(x:   0, y: 21, width:  25, height: 20)
        static let topTileFocused    = SpriteRect(x:  26, y:  0, width:  25, height: 20)
        static let topTileUnfocused  = SpriteRect(x: 127, y:  0, width:  25, height: 20)
        static let topRightFocused   = SpriteRect(x: 153, y:  0, width:  25, height: 20)
        static let topRightUnfocused = SpriteRect(x: 153, y: 21, width:  25, height: 20)
        // Side tiles
        static let leftTile  = SpriteRect(x:  0, y: 42, width: 12, height: 29)
        static let rightTile = SpriteRect(x: 31, y: 42, width: 20, height: 29)
        // Bottom bar (status/time + toolbar row)
        static let bottomLeft  = SpriteRect(x:   0, y: 72, width: 125, height: 38)
        static let bottomRight = SpriteRect(x: 126, y: 72, width: 150, height: 38)
        static let bottomTile  = SpriteRect(x: 179, y:  0, width:  25, height: 38)
        // Scroll handle (right-edge scrollbar thumb)
        static let scrollHandle         = SpriteRect(x: 52, y: 53, width: 8, height: 18)
        static let scrollHandleSelected = SpriteRect(x: 61, y: 53, width: 8, height: 18)
        // Small window buttons in top-right of the title
        static let closeBtn  = SpriteRect(x:  52, y: 42, width: 9, height: 9)
        static let shadeBtn  = SpriteRect(x:  62, y: 42, width: 9, height: 9)
        static let expandBtn = SpriteRect(x: 150, y: 42, width: 9, height: 9)
    }

    // MARK: - text.bmp (classic 5x6 bitmap font — 3 rows of 31 glyphs)
    enum TEXT {
        static let charWidth: CGFloat  = 5
        static let charHeight: CGFloat = 6

        static func rect(row: Int, col: Int) -> SpriteRect {
            SpriteRect(
                x: CGFloat(col) * charWidth,
                y: CGFloat(row) * charHeight,
                width: charWidth, height: charHeight
            )
        }

        /// Lookup table from webamp's `FONT_LOOKUP`. Glyphs not in the map
        /// render as a blank space (row 0, col 30).
        static let lookup: [Character: (row: Int, col: Int)] = {
            var map: [Character: (Int, Int)] = [:]

            // Row 0: a..z (0..25), " (26), @ (27), spaces (28, 29), space (30)
            let row0 = Array("abcdefghijklmnopqrstuvwxyz\"@")
            for (i, ch) in row0.enumerated() { map[ch] = (0, i) }
            map[" "] = (0, 30)

            // Row 1: 0..9, ellipsis, . : ( ) - ' ! _ + \ / [ ] ^ & % , = $ #
            let row1: [Character] = [
                "0","1","2","3","4","5","6","7","8","9",
                "…",".",":","(",")","-","'","!","_","+",
                "\\","/","[","]","^","&","%",",","=","$","#"
            ]
            for (i, ch) in row1.enumerated() { map[ch] = (1, i) }

            // Row 2: Å Ö Ä ? *
            let row2: [Character] = ["Å","Ö","Ä","?","*"]
            for (i, ch) in row2.enumerated() { map[ch] = (2, i) }

            // Uppercase fallback → reuse lowercase sprites
            for code in 65...90 {
                let upper = Character(UnicodeScalar(code)!)
                let lower = Character(UnicodeScalar(code + 32)!)
                if let p = map[lower] { map[upper] = p }
            }

            // Brace / angle-bracket fallbacks
            if let lb = map["["] { map["<"] = lb; map["{"] = lb }
            if let rb = map["]"] { map[">"] = rb; map["}"] = rb }

            return map
        }()
    }
}
