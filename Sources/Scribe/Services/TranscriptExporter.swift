import Foundation

enum TranscriptExportFormat: String, CaseIterable, Identifiable {
    case plainText
    case markdown
    case subtitle

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .plainText:
            "txt"
        case .markdown:
            "md"
        case .subtitle:
            "srt"
        }
    }

    var title: String {
        switch self {
        case .plainText:
            "Save .txt"
        case .markdown:
            "Save .md"
        case .subtitle:
            "Save .srt"
        }
    }
}

enum TranscriptExporter {
    static func contents(for document: TranscriptDocument, format: TranscriptExportFormat) -> String {
        let totalDuration = max(
            document.paragraphs.last?.endTime ?? 0,
            document.segments.last?.endTime ?? 0
        )

        switch format {
        case .plainText:
            return TranscriptDisplayFormatter.copyText(from: document, totalDuration: totalDuration)
        case .markdown:
            return markdown(document)
        case .subtitle:
            return srt(document)
        }
    }

    static func markdown(_ document: TranscriptDocument) -> String {
        document.paragraphs
            .map { paragraph in
                "[\(ScribeTimeFormatter.playback(paragraph.startTime))] \(paragraph.text)"
            }
            .joined(separator: "\n\n")
    }

    static func srt(_ document: TranscriptDocument) -> String {
        document.segments.enumerated().map { index, segment in
            """
            \(index + 1)
            \(ScribeTimeFormatter.subtitle(segment.startTime)) --> \(ScribeTimeFormatter.subtitle(segment.endTime))
            \(segment.text.trimmingCharacters(in: .whitespacesAndNewlines))
            """
        }
        .joined(separator: "\n\n")
    }
}
