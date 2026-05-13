import SwiftUI

/// The hairline strip + meta row that lives at the very top of the window.
/// The strip's *style* is the entire chrome — it tells you what the app is
/// doing without any words. The meta row underneath carries the playback
/// time, file name, progress %, and export links contextually.
///
///   • **Idle:**         dotted 3pt hairline (no track yet)
///   • **Transcribing:** cyan→violet gradient sweeping left-to-right
///   • **Ready:**        solid ink fill showing playback progress
struct TopStripChrome<Left: View, Right: View>: View {
    let phase: ScribePhase
    let playbackProgress: Double
    @ViewBuilder var left: () -> Left
    @ViewBuilder var right: () -> Right

    var body: some View {
        VStack(spacing: 0) {
            stripView
                .frame(height: 3)

            HStack(spacing: 14) {
                left()
                    .lineLimit(1)
                    .layoutPriority(0)
                Spacer(minLength: 16)
                right()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 10)
            .frame(minHeight: 42)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(ScribeTheme.rule)
                    .frame(height: 1)
            }
        }
    }

    @ViewBuilder
    private var stripView: some View {
        switch phase {
        case .idle:
            DottedHairline()
        case .transcribing:
            SweepingHairline()
        case .ready:
            PlaybackProgressHairline(progress: playbackProgress)
        }
    }
}

// MARK: – Hairline styles

private struct DottedHairline: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let y = geo.size.height / 2
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: geo.size.width, y: y))
            }
            .stroke(
                ScribeTheme.ink.opacity(0.18),
                style: StrokeStyle(lineWidth: 3, lineCap: .butt, dash: [4, 6])
            )
        }
    }
}

private struct SweepingHairline: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(ScribeTheme.hairline)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear,           location: 0.00),
                                    .init(color: ScribeTheme.accent, location: 0.35),
                                    .init(color: ScribeTheme.cyan,   location: 0.60),
                                    .init(color: .clear,           location: 1.00),
                                ],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .offset(x: phase * geo.size.width)
                )
                .clipped()
                .onAppear {
                    withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        }
    }
}

private struct PlaybackProgressHairline: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(ScribeTheme.hairline)
                Rectangle()
                    .fill(ScribeTheme.ink)
                    .frame(width: max(0, geo.size.width * min(max(progress, 0), 1)))
            }
        }
    }
}
