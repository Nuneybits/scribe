import SwiftUI

/// The Start screen body. A floating drop disc, a serif headline, and a
/// quiet `choose file…` pill. Bottom corners carry model-status and the
/// keyboard hint. The whole window is also a drop target — see ContentView.
struct IdleHeroView: View {
    @Bindable var workspace: ScribeWorkspace

    var body: some View {
        ZStack {
            // Centred hero
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                DropDisc()
                    .frame(width: 180, height: 180)
                    .padding(.bottom, 32)

                Text("Drop an audio file")
                    .font(.system(size: 42, weight: .regular, design: .serif))
                    .foregroundColor(ScribeTheme.ink)
                    .tracking(-0.5)
                    .padding(.bottom, 14)

                Text("Up to one hour. Transcribed locally, on this Mac.\nNothing leaves your machine.")
                    .font(.system(size: 17, design: .serif))
                    .italic()
                    .foregroundColor(ScribeTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                HStack(spacing: 12) {
                    Button {
                        Task { await workspace.selectAudioWithOpenPanel() }
                    } label: {
                        Text("choose file…")
                            .font(.system(size: 12, design: .monospaced))
                            .tracking(0.4)
                            .foregroundColor(ScribeTheme.paper)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(ScribeTheme.ink))
                            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("o", modifiers: .command)

                    Text("or drag here")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ScribeTheme.inkSoft)
                }
                .padding(.bottom, 36)

                AcceptedFormatsLine()

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 56)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: 8) {
                Circle()
                    .fill(ScribeTheme.success)
                    .frame(width: 6, height: 6)
                Text("whisperkit · large-v3 · ready on device")
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(ScribeTheme.inkSoft)
                    .tracking(0.4)
            }
            .padding(.leading, 32)
            .padding(.bottom, 16)
        }
        .overlay(alignment: .bottomTrailing) {
            Text("⌘O to open")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundColor(ScribeTheme.inkSoft)
                .tracking(0.4)
                .padding(.trailing, 32)
                .padding(.bottom, 16)
        }
    }
}

private struct AcceptedFormatsLine: View {
    private let extensions = ["mp3", "wav", "m4a", "mp4", "mov", "aiff"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(extensions.enumerated()), id: \.offset) { index, ext in
                if index > 0 {
                    Text("·")
                        .foregroundColor(ScribeTheme.inkSoft)
                        .padding(.horizontal, 8)
                }
                Text(".\(ext)")
            }
        }
        .font(.system(size: 10.5, design: .monospaced))
        .foregroundColor(ScribeTheme.inkSoft)
        .tracking(0.6)
    }
}

// MARK: – Animated drop disc

private struct DropDisc: View {
    var body: some View {
        ZStack {
            PulsingRings()
            CoreSphere()
        }
    }
}

private struct PulsingRings: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(ScribeTheme.accent, lineWidth: 1)
                    .scaleEffect(animate ? 1.45 : 0.92)
                    .opacity(animate ? 0 : 0.55)
                    .animation(
                        .easeOut(duration: 2.4)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.8),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

private struct CoreSphere: View {
    @State private var floating = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [ScribeTheme.cyan, ScribeTheme.accent, ScribeTheme.navy],
                    center: UnitPoint(x: 0.3, y: 0.25),
                    startRadius: 4,
                    endRadius: 70
                )
            )
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
            )
            .overlay(
                DownArrowGlyph()
                    .foregroundColor(ScribeTheme.paper)
            )
            .frame(width: 108, height: 108)
            .shadow(color: ScribeTheme.accent.opacity(0.30), radius: 22, x: 0, y: 16)
            .offset(y: floating ? -4 : 0)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: floating)
            .onAppear { floating = true }
    }
}

private struct DownArrowGlyph: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(width: 4, height: 30)
            DownTriangle()
                .frame(width: 28, height: 18)
        }
    }
}

private struct DownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
