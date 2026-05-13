import SwiftUI

/// The finished transcript view. Paragraphs are anchored by sparse,
/// click-to-seek timestamps in a left gutter; the paragraph the playhead
/// is currently inside has its timestamp coloured with brand violet so the
/// user always knows where they are.
struct ReadyTranscriptView: View {
    @Bindable var workspace: ScribeWorkspace

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let document = workspace.transcriptDocument {
                    finishedTranscript(document)
                } else if workspace.draftTranscriptText.isEmpty == false {
                    // A failed transcription that preserved its partial draft.
                    Text(workspace.draftTranscriptText)
                        .font(.system(size: 17, design: .serif))
                        .foregroundColor(ScribeTheme.ink)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 48)
            .padding(.vertical, 38)
        }
    }

    @ViewBuilder
    private func finishedTranscript(_ document: TranscriptDocument) -> some View {
        let items = TranscriptDisplayFormatter.displayParagraphs(
            from: document.paragraphs,
            totalDuration: workspace.playback.duration
        )
        let currentTime = workspace.playback.currentTime
        let activeID = document.paragraphs.last { $0.startTime <= currentTime }?.id

        ForEach(items) { item in
            TranscriptRow(
                item: item,
                isActive: activeID == item.paragraph.id,
                onSeek: { workspace.seekToParagraph(item.paragraph) }
            )
        }
    }
}

private struct TranscriptRow: View {
    let item: TranscriptDisplayParagraph
    let isActive: Bool
    let onSeek: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            Group {
                if let timestamp = item.timestamp {
                    Button(action: onSeek) {
                        Text(timestamp)
                            .font(.system(
                                size: 10.5,
                                weight: isActive ? .semibold : .regular,
                                design: .monospaced
                            ))
                            .foregroundColor(isActive ? ScribeTheme.accent : ScribeTheme.inkSoft)
                            .monospacedDigit()
                            .frame(width: 50, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 50, height: 1)
                }
            }

            Text(item.paragraph.text)
                .font(.system(size: 17, design: .serif))
                .foregroundColor(ScribeTheme.ink)
                .lineSpacing(4)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
