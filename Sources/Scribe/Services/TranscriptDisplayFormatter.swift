import Foundation

struct TranscriptDisplayParagraph: Identifiable, Equatable, Sendable {
    let id: UUID
    let paragraph: TranscriptParagraph
    let timestamp: String?
}

enum TranscriptDisplayFormatter {
    static func displayParagraphs(
        from paragraphs: [TranscriptParagraph],
        totalDuration: TimeInterval
    ) -> [TranscriptDisplayParagraph] {
        guard let first = paragraphs.first else { return [] }

        let interval = timestampInterval(for: totalDuration)
        var lastShownTime = first.startTime

        return paragraphs.enumerated().map { index, paragraph in
            let shouldShowTimestamp: Bool
            if index == 0 {
                shouldShowTimestamp = true
            } else {
                shouldShowTimestamp = paragraph.startTime - lastShownTime >= interval
            }

            if shouldShowTimestamp {
                lastShownTime = paragraph.startTime
            }

            return TranscriptDisplayParagraph(
                id: paragraph.id,
                paragraph: paragraph,
                timestamp: shouldShowTimestamp ? ScribeTimeFormatter.playback(paragraph.startTime) : nil
            )
        }
    }

    static func copyText(
        from document: TranscriptDocument,
        totalDuration: TimeInterval
    ) -> String {
        displayParagraphs(from: document.paragraphs, totalDuration: totalDuration)
            .map { item in
                if let timestamp = item.timestamp {
                    return "[\(timestamp)] \(item.paragraph.text)"
                }

                return item.paragraph.text
            }
            .joined(separator: "\n\n")
    }

    private static func timestampInterval(for totalDuration: TimeInterval) -> TimeInterval {
        totalDuration >= 3600 ? 600 : 300
    }
}
