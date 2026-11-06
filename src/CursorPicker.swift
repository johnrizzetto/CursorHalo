import SwiftUI

struct CursorGlyph: Shape {
    let style: CursorStyle
    func path(in rect: CGRect) -> Path {
        let size = min(rect.width, rect.height) - 3
        var transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: rect.midX, ty: rect.midY)
        let path = CursorArtwork.path(for: style, size: size)
        return Path(path.copy(using: &transform) ?? path)
    }
}

struct CursorChoiceRow: View {
    let title: String
    let choices: [CursorStyle]
    @Binding var selection: CursorStyle
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(HaloTheme.caption).foregroundStyle(HaloTheme.secondary)
            HStack(spacing: 8) {
                ForEach(choices, id: \.self) { style in
                    Button { selection = style } label: {
                        HStack(spacing: 5) {
                            ZStack {
                                if style.isFilled { CursorGlyph(style: style).fill(color) }
                                CursorGlyph(style: style).stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                            }
                            .frame(width: 19, height: 19)
                            Text(style.rawValue).font(HaloTheme.caption).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 27)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(selection == style ? HaloTheme.accent : .clear, lineWidth: 2))
                    .accessibilityLabel(style.rawValue)
                    .accessibilityValue(selection == style ? "Selected" : "Not selected")
                    .help(style.isPlayful ? "Sits beside the native cursor" : "Centered on the click point")
                }
            }
        }
    }
}
