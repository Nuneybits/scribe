import SwiftUI

/// Top-level orchestrator for the redesigned Top Strip UI.
///
/// The window is split into three parts, top to bottom:
///   1. A buffer for the traffic lights (we hid the title bar)
///   2. `TopStripChrome` — the hairline strip + a contextual meta row
///   3. The phase-specific body view (`IdleHeroView`, `TranscribingView`,
///      `ReadyTranscriptView`)
///
/// The entire window is a drop target. Errors and warnings float in as a
/// banner pinned just below the meta row.
struct ContentView: View {
    @Bindable var workspace: ScribeWorkspace

    var body: some View {
        VStack(spacing: 0) {
            // Reserve room for the traffic lights — `.hiddenTitleBar` lets
            // them overlay our content, so we leave the top ~28pt clear.
            Color.clear.frame(height: 28)

            TopStripChrome(
                phase: workspace.phase,
                playbackProgress: playbackProgress
            ) {
                MetaLeft(workspace: workspace)
            } right: {
                MetaRight(workspace: workspace)
            }

            ZStack {
                switch workspace.phase {
                case .idle:
                    IdleHeroView(workspace: workspace)
                        .transition(.opacity)
                case .transcribing:
                    TranscribingView(workspace: workspace)
                        .transition(.opacity)
                case .ready:
                    ReadyTranscriptView(workspace: workspace)
                        .transition(.opacity)
                }

                if workspace.isTargeted {
                    DropTargetOverlay()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: workspace.phase)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(ScribeTheme.paper)
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                if let warning = workspace.warningMessage {
                    Banner(text: warning, tint: ScribeTheme.warning)
                }
                if let error = workspace.errorMessage {
                    Banner(text: error, tint: ScribeTheme.danger)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 80)
            .frame(maxWidth: 560)
        }
        .dropDestination(for: URL.self) { items, _ in
            Task { await workspace.importAudio(from: items) }
            return true
        } isTargeted: { isTargeted in
            workspace.isTargeted = isTargeted
        }
    }

    private var playbackProgress: Double {
        let duration = workspace.playback.duration
        guard duration > 0 else { return 0 }
        return workspace.playback.currentTime / duration
    }
}

// ──────────────────────────────────────────────────────────────────────
// MARK: – Meta row content (left and right of the strip)
// ──────────────────────────────────────────────────────────────────────

private struct MetaLeft: View {
    @Bindable var workspace: ScribeWorkspace

    var body: some View {
        HStack(spacing: 10) {
            switch workspace.phase {
            case .idle:
                Text("READY")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(ScribeTheme.inkSoft)
                    .tracking(0.6)
                Text("· no file loaded")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(ScribeTheme.inkSoft)

            case .transcribing:
                LiveWaveBars()
                    .frame(width: 22, height: 14)
                Text("TRANSCRIBING")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(ScribeTheme.ink)
                    .tracking(0.6)
                if let audio = workspace.selectedAudio {
                    Text("· \(audio.url.lastPathComponent)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ScribeTheme.inkSoft)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

            case .ready:
                PlayPauseButton(workspace: workspace)
                if workspace.playback.duration > 0 {
                    Text(playbackLabel)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ScribeTheme.ink)
                        .monospacedDigit()
                }
                if let audio = workspace.selectedAudio {
                    Text("· \(audio.url.lastPathComponent)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ScribeTheme.inkSoft)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    private var playbackLabel: String {
        "\(ScribeTimeFormatter.playback(workspace.playback.currentTime)) / \(ScribeTimeFormatter.playback(workspace.playback.duration))"
    }
}

private struct MetaRight: View {
    @Bindable var workspace: ScribeWorkspace

    var body: some View {
        HStack(spacing: 14) {
            switch workspace.phase {
            case .idle:
                ExportRow(workspace: workspace, enabled: false)
            case .transcribing:
                if let progress = workspace.progressFraction {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(ScribeTheme.accent)
                        .monospacedDigit()
                }
            case .ready:
                ExportRow(workspace: workspace, enabled: true)
            }
        }
    }
}

private struct ExportRow: View {
    @Bindable var workspace: ScribeWorkspace
    let enabled: Bool

    var body: some View {
        HStack(spacing: 0) {
            ExportLink(label: "copy", enabled: enabled) {
                workspace.copyTranscript()
            }
            dotSeparator
            ExportLink(label: ".txt", enabled: enabled) {
                workspace.exportTranscript(.plainText)
            }
            dotSeparator
            ExportLink(label: ".md", enabled: enabled) {
                workspace.exportTranscript(.markdown)
            }
            dotSeparator
            ExportLink(label: ".srt", enabled: enabled) {
                workspace.exportTranscript(.subtitle)
            }
        }
        .font(.system(size: 11, design: .monospaced))
    }

    private var dotSeparator: some View {
        Text("·")
            .foregroundColor(ScribeTheme.inkSoft.opacity(enabled ? 1 : 0.5))
            .padding(.horizontal, 7)
    }
}

private struct ExportLink: View {
    let label: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .foregroundColor(enabled ? ScribeTheme.inkSoft : ScribeTheme.ink.opacity(0.25))
        }
        .buttonStyle(.plain)
        .disabled(enabled == false)
    }
}

private struct PlayPauseButton: View {
    @Bindable var workspace: ScribeWorkspace

    var body: some View {
        Button {
            if workspace.playback.isPlaying {
                workspace.playback.pause()
            } else {
                workspace.playback.play()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(ScribeTheme.ink)
                    .frame(width: 18, height: 18)
                Image(systemName: workspace.playback.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(ScribeTheme.paper)
            }
        }
        .buttonStyle(.plain)
        .disabled(workspace.playback.isLoaded == false)
        .keyboardShortcut(.space, modifiers: [])
    }
}

private struct LiveWaveBars: View {
    @State private var animate = false
    private let bars = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<bars, id: \.self) { i in
                Rectangle()
                    .fill(ScribeTheme.ink)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(y: animate ? 1 : 0.35, anchor: .center)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.12),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

// ──────────────────────────────────────────────────────────────────────
// MARK: – Drop feedback + banners
// ──────────────────────────────────────────────────────────────────────

private struct DropTargetOverlay: View {
    var body: some View {
        ZStack {
            ScribeTheme.accent.opacity(0.05)
            Rectangle()
                .strokeBorder(
                    ScribeTheme.accent,
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .padding(10)
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

private struct Banner: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(ScribeTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(tint.opacity(0.25), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}
