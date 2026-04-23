import Foundation

enum ParagraphGrouper {
    static func group(
        segments: [TranscriptSegmentModel],
        pauseThreshold: TimeInterval = 1.8,
        maxWords: Int = 140
    ) -> [TranscriptParagraph] {
        guard segments.isEmpty == false else { return [] }

        var paragraphs: [TranscriptParagraph] = []
        var buffer: [TranscriptSegmentModel] = []

        func flushBuffer() {
            guard buffer.isEmpty == false else { return }

            let text = buffer
                .map { TranscriptFormatter.cleanSegment($0.text) }
                .joined(separator: " ")
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let first = buffer.first, let last = buffer.last, text.isEmpty == false else {
                buffer.removeAll()
                return
            }

            paragraphs.append(
                TranscriptParagraph(
                    text: text,
                    startTime: first.startTime,
                    endTime: last.endTime,
                    segmentIDs: buffer.map(\.id)
                )
            )

            buffer.removeAll()
        }

        for segment in segments {
            if let previous = buffer.last {
                let pauseGap = max(0, segment.startTime - previous.endTime)
                let bufferedWordCount = buffer.reduce(0) { count, item in
                    count + item.text.split(whereSeparator: \.isWhitespace).count
                }

                if pauseGap >= pauseThreshold || bufferedWordCount >= maxWords {
                    flushBuffer()
                }
            }

            buffer.append(segment)
        }

        flushBuffer()
        return paragraphs
    }
}
