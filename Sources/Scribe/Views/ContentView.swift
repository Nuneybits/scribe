import SwiftUI

struct ContentView: View {
    @Bindable var workspace: ScribeWorkspace

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 18) {
                topPanel
                transportPanel
                transcriptPanel
                footerPanel
            }
            .padding(24)
        }
        .background(ScribeTheme.background)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Scribe")
                    .font(.system(size: 66, weight: .black, design: .default))
                    .tracking(-2.4)
                    .foregroundStyle(ScribeTheme.text)

                Text("Private transcription for people who work with words.")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundStyle(ScribeTheme.secondaryText)
            }

            Spacer()

            statusBadge
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    private var topPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ScribeTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(workspace.isTargeted ? ScribeTheme.accent : ScribeTheme.border, lineWidth: workspace.isTargeted ? 2 : 1)
                    )

                VStack(spacing: 12) {
                    Text(workspace.selectedAudio == nil ? "Drop an audio file" : "Drop another audio file to replace the current one")
                        .font(.system(size: 26, weight: .bold, design: .default))
                        .foregroundStyle(ScribeTheme.text)

                    Text("Voice Memos, MP3s, WAVs, interviews, and field recordings.")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundStyle(ScribeTheme.secondaryText)

                    HStack(spacing: 12) {
                        Button("Load Audio") {
                            Task {
                                await workspace.selectAudioWithOpenPanel()
                            }
                        }
                        .buttonStyle(ScribePrimaryButtonStyle())

                        if workspace.selectedAudio != nil {
                            Button(workspace.isTranscribing ? "Transcribing…" : "Retranscribe") {
                                Task {
                                    await workspace.transcribeSelectedAudio()
                                }
                            }
                            .buttonStyle(ScribeSecondaryButtonStyle())
                            .disabled(workspace.isTranscribing)
                        }
                    }
                }
                .padding(30)
            }
            .frame(minHeight: 150)
            .dropDestination(for: URL.self) { items, _ in
                Task {
                    await workspace.importAudio(from: items)
                }
                return true
            } isTargeted: { isTargeted in
                workspace.isTargeted = isTargeted
            }

            if let selectedAudio = workspace.selectedAudio {
                HStack(spacing: 14) {
                    metadataChip(selectedAudio.url.lastPathComponent)
                    metadataChip(selectedAudio.durationDescription)
                    metadataChip(selectedAudio.fileSizeDescription)
                    metadataChip(selectedAudio.formatDescription)
                }
            }
        }
    }

    private var transportPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(ScribeTimeFormatter.playback(workspace.playback.currentTime)) / \(ScribeTimeFormatter.playback(workspace.playback.duration))")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(ScribeTheme.secondaryText)

                Spacer()

                statusLineView
            }

            HStack(spacing: 12) {
                Button {
                    workspace.playback.play()
                } label: {
                    Image(systemName: "play.fill")
                }
                .buttonStyle(ScribeIconButtonStyle())
                .disabled(workspace.playback.isLoaded == false)

                Button {
                    workspace.playback.pause()
                } label: {
                    Image(systemName: "pause.fill")
                }
                .buttonStyle(ScribeIconButtonStyle())
                .disabled(workspace.playback.isLoaded == false)

                Button {
                    workspace.playback.stop()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(ScribeIconButtonStyle())
                .disabled(workspace.playback.isLoaded == false)

                PlaybackScrubber(
                    value: Binding(
                        get: { workspace.playback.currentTime },
                        set: { workspace.playback.seek(to: $0) }
                    ),
                    duration: max(1, workspace.playback.duration),
                    isEnabled: workspace.playback.isLoaded
                )
                .frame(height: 36)
            }

            if workspace.isTranscribing, let selectedAudio = workspace.selectedAudio {
                Text("Working locally on a \(selectedAudio.durationDescription) recording. This can take a few minutes.")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(ScribeTheme.secondaryText)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(ScribeTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(ScribeTheme.border, lineWidth: 1)
                )
        )
    }

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let warningMessage = workspace.warningMessage {
                banner(text: warningMessage, tint: ScribeTheme.warning)
            }

            if let errorMessage = workspace.errorMessage {
                banner(text: errorMessage, tint: ScribeTheme.danger)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let transcriptDocument = workspace.transcriptDocument {
                        let displayParagraphs = TranscriptDisplayFormatter.displayParagraphs(
                            from: transcriptDocument.paragraphs,
                            totalDuration: workspace.playback.duration
                        )

                        ForEach(displayParagraphs) { item in
                            transcriptRow(item)
                        }
                    } else if workspace.draftTranscriptText.isEmpty == false {
                        VStack(alignment: .leading, spacing: 16) {
                            draftPreviewHeader

                            Text(workspace.draftTranscriptText)
                                .font(.system(size: 16, weight: .regular, design: .serif))
                                .foregroundStyle(ScribeTheme.text)
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        Text("Your transcript will appear here as soon as the audio is ready.")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(ScribeTheme.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ScribeTheme.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(ScribeTheme.border, lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footerPanel: some View {
        Group {
            if workspace.isTranscribing == false {
                HStack(spacing: 12) {
                    Button("Copy") {
                        workspace.copyTranscript()
                    }
                    .buttonStyle(ScribeSecondaryButtonStyle())
                    .disabled(workspace.transcriptDocument == nil)

                    Button("Save .txt") {
                        workspace.exportTranscript(.plainText)
                    }
                    .buttonStyle(ScribeSecondaryButtonStyle())
                    .disabled(workspace.transcriptDocument == nil)

                    Button("Save .md") {
                        workspace.exportTranscript(.markdown)
                    }
                    .buttonStyle(ScribeSecondaryButtonStyle())
                    .disabled(workspace.transcriptDocument == nil)

                    Button("Save .srt") {
                        workspace.exportTranscript(.subtitle)
                    }
                    .buttonStyle(ScribeSecondaryButtonStyle())
                    .disabled(workspace.transcriptDocument == nil)

                    Spacer()

                    if let lastTranscriptDate = workspace.lastTranscriptDate {
                        Text("Updated \(lastTranscriptDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(ScribeTheme.secondaryText)
                    }
                }
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var statusLineView: some View {
        if workspace.isTranscribing, let startedAt = workspace.transcriptionStartedAt {
            TimelineView(.periodic(from: startedAt, by: 1)) { context in
                HStack(spacing: 8) {
                    PulsingStatusDot()

                    Text("\(workspace.statusLine) • \(elapsedLabel(since: startedAt, now: context.date)) elapsed")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(ScribeTheme.secondaryText)
                }
            }
        } else {
            Text(workspace.statusLine)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(ScribeTheme.secondaryText)
        }
    }

    private var statusBadge: some View {
        Text("Apple Silicon")
            .font(.system(size: 12, weight: .bold, design: .default))
            .foregroundStyle(ScribeTheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(ScribeTheme.accentSoft)
            )
    }

    private func metadataChip(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(ScribeTheme.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
    }

    private func banner(text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ScribeTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(tint.opacity(0.25), lineWidth: 1)
                    )
            )
    }

    private func transcriptRow(_ item: TranscriptDisplayParagraph) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            Group {
                if let timestamp = item.timestamp {
                    Button(timestamp) {
                        workspace.seekToParagraph(item.paragraph)
                    }
                    .buttonStyle(ScribeTimestampButtonStyle())
                } else {
                    Text("")
                        .frame(width: 58)
                }
            }

            Text(item.paragraph.text)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundStyle(ScribeTheme.text)
                .lineSpacing(4)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    private var draftPreviewHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live Draft Preview")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(ScribeTheme.text)

            Text("The transcript appears here in order while Scribe works.")
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundStyle(ScribeTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func elapsedLabel(since start: Date, now: Date) -> String {
        let elapsed = max(0, Int(now.timeIntervalSince(start)))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct ScribePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .default))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(configuration.isPressed ? ScribeTheme.accent.opacity(0.8) : ScribeTheme.accent)
            )
    }
}

private struct ScribeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .default))
            .foregroundStyle(ScribeTheme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(configuration.isPressed ? ScribeTheme.border : ScribeTheme.mutedSurface)
            )
    }
}

private struct ScribeIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(ScribeTheme.text)
            .frame(width: 34, height: 34)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(configuration.isPressed ? ScribeTheme.border : ScribeTheme.mutedSurface)
            )
    }
}

private struct ScribeTimestampButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(ScribeTheme.accent)
            .frame(width: 58, alignment: .leading)
    }
}

private struct PlaybackScrubber: View {
    @Binding var value: Double
    let duration: Double
    let isEnabled: Bool

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = max(geometry.size.width - 18, 1)
            let progress = min(max(value / max(duration, 1), 0), 1)
            let knobOffset = trackWidth * progress

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ScribeTheme.border.opacity(isEnabled ? 0.75 : 0.35))
                    .frame(height: 4)

                Capsule()
                    .fill(isEnabled ? ScribeTheme.accent : ScribeTheme.border.opacity(0.4))
                    .frame(width: max(progress * trackWidth, isEnabled && progress > 0 ? 10 : 0), height: 4)

                Circle()
                    .fill(isEnabled ? Color.white : ScribeTheme.mutedSurface)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(isEnabled ? ScribeTheme.border.opacity(0.7) : ScribeTheme.border.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(isEnabled ? 0.08 : 0), radius: 1.5, x: 0, y: 1)
                    .offset(x: knobOffset)
            }
            .padding(.trailing, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard isEnabled else { return }

                        let location = min(max(gesture.location.x, 0), trackWidth)
                        let normalized = location / trackWidth
                        value = normalized * max(duration, 1)
                    }
            )
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Playback timeline")
    }
}

private struct PulsingStatusDot: View {
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(ScribeTheme.accent)
            .frame(width: 8, height: 8)
            .scaleEffect(animate ? 1 : 0.72)
            .opacity(animate ? 1 : 0.4)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: animate)
            .onAppear {
                animate = true
            }
    }
}
