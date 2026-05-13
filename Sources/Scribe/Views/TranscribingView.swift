import SwiftUI

/// Shows the live draft while the model is working. The last paragraph
/// carries a blinking violet caret; a few faint placeholder bars below
/// suggest there is more transcript still to arrive. A quiet status footer
/// names the model and offers a cancel shortcut.
struct TranscribingView: View {
    @Bindable var workspace: ScribeWorkspace

    private var paragraphs: [String] {
        workspace.draftTranscriptText
            .components(separatedBy: "\n\n")
            .filter { $0.isEmpty == false }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if paragraphs.isEmpty {
                        PreparingPlaceholder()
                    } else {
                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, text in
                            let isLast = index == paragraphs.count - 1
                            if isLast {
                                LiveCaretText(text: text)
                            } else {
                                Text(text)
                                    .font(.system(size: 17, design: .serif))
                                    .foregroundColor(ScribeTheme.ink)
                                    .lineSpacing(4)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        GhostLines()
                            .padding(.top, 16)
                    }
                }
                .frame(maxWidth: 600, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 48)
                .padding(.vertical, 38)
            }

            TranscribingFooter(workspace: workspace)
        }
    }
}

// MARK: – Live caret

private struct LiveCaretText: View {
    let text: String

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            // ▎ when "on", figure-space when "off" — same width either way so
            // the line doesn't reflow as the caret blinks.
            let isOn = Int(context.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
            let caretText = isOn ? " ▎" : " \u{2007}"
            let body = Text(text) + Text(caretText).foregroundColor(ScribeTheme.accent)
            body
                .font(.system(size: 17, design: .serif))
                .foregroundColor(ScribeTheme.ink)
                .lineSpacing(4)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: – Placeholders

private struct PreparingPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PREPARING")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundColor(ScribeTheme.inkSoft)
                .tracking(0.6)
                .padding(.bottom, 8)

            ForEach([0.92, 0.78, 0.55, 0.85, 0.40], id: \.self) { width in
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ScribeTheme.ink.opacity(0.06))
                        .frame(width: max(0, geo.size.width * width), height: 14)
                }
                .frame(height: 14)
            }
        }
        .padding(.top, 8)
    }
}

private struct GhostLines: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach([0.92, 0.78, 0.55], id: \.self) { width in
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ScribeTheme.ink.opacity(0.06))
                        .frame(width: max(0, geo.size.width * width), height: 12)
                }
                .frame(height: 12)
            }
        }
    }
}

// MARK: – Footer

private struct TranscribingFooter: View {
    @Bindable var workspace: ScribeWorkspace

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                PulsingDot(color: ScribeTheme.accent)
                Text(workspace.statusLine)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(ScribeTheme.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            Text("⌘. to cancel")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundColor(ScribeTheme.inkSoft)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 10)
        .background(ScribeTheme.ink.opacity(0.015))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ScribeTheme.rule)
                .frame(height: 1)
        }
    }
}

private struct PulsingDot: View {
    let color: Color
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .overlay(
                Circle()
                    .stroke(color.opacity(0.25), lineWidth: 3)
                    .scaleEffect(animate ? 2.2 : 1)
                    .opacity(animate ? 0 : 0.5)
                    .animation(
                        .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                        value: animate
                    )
            )
            .onAppear { animate = true }
    }
}
