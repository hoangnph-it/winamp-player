import SwiftUI

/// Displays a rectangular slice of a `SkinSheet` bitmap at natural pixel size.
///
/// Uses the clip-and-offset technique: the full source image is laid out
/// behind a frame sized to the sprite rect, with an offset that scrolls the
/// correct region into view, and a `clipped()` that hides the rest.
/// SwiftUI/`Image` reuses the same underlying `CGImage` across call sites so
/// we don't pay to reallocate sprites per view.
///
/// `interpolation(.none)` preserves the hard pixel edges of the classic skin
/// when the view gets drawn on a retina display.
struct SpriteView: View {
    let sheet: SkinSheet
    let rect: SpriteRect
    /// Integer pixel-doubling factor. 1 = authentic 1x; 2 = "double size"
    /// mode (Winamp's built-in "D" toggle in the clutterbar).
    var scale: CGFloat = 1

    var body: some View {
        Group {
            if let source = SkinAssets.shared.image(for: sheet) {
                backedImage(source)
            } else {
                MissingSpritePlaceholder(
                    width: rect.width * scale,
                    height: rect.height * scale
                )
            }
        }
        .frame(
            width: rect.width * scale,
            height: rect.height * scale
        )
    }

    @ViewBuilder
    private func backedImage(_ source: PlatformImage) -> some View {
        let w = source.size.width * scale
        let h = source.size.height * scale

        #if os(macOS)
        Image(nsImage: source)
            .interpolation(.none)
            .resizable()
            .frame(width: w, height: h)
            .offset(x: -rect.x * scale, y: -rect.y * scale)
            .frame(
                width: rect.width * scale,
                height: rect.height * scale,
                alignment: .topLeading
            )
            .clipped()
        #else
        Image(uiImage: source)
            .interpolation(.none)
            .resizable()
            .frame(width: w, height: h)
            .offset(x: -rect.x * scale, y: -rect.y * scale)
            .frame(
                width: rect.width * scale,
                height: rect.height * scale,
                alignment: .topLeading
            )
            .clipped()
        #endif
    }
}

/// Dashed-red placeholder rendered when a sprite can't be found (missing
/// skin file, wrong key, etc.). Intended to be visible during development;
/// should never ship into a user-facing window.
private struct MissingSpritePlaceholder: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Rectangle()
            .strokeBorder(
                Color.red.opacity(0.6),
                style: StrokeStyle(lineWidth: 1, dash: [2, 2])
            )
            .background(Color.black.opacity(0.3))
            .frame(width: width, height: height)
    }
}
